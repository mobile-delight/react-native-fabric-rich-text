#import "FabricRichLinkAccessibilityElement.h"
#import "FabricRichCoreTextView.h"

/// Accessibility debug logging - set to 0 for production
#define A11Y_DEBUG 1

#if A11Y_DEBUG
#define A11Y_LOG(fmt, ...) NSLog(@"[A11Y_FHLinkElem] " fmt, ##__VA_ARGS__)
#else
#define A11Y_LOG(fmt, ...) do { } while(0)
#endif

@implementation FabricRichLinkAccessibilityElement

#pragma mark - Dynamic Accessibility Frame

/**
 * Dynamically computes the accessibility frame in screen coordinates.
 * This is called by VoiceOver each time it needs the frame, ensuring
 * the frame stays accurate even when the view moves (scrolling, layout changes, etc.).
 *
 * This pattern follows TTTAttributedLabel's approach for handling accessibility
 * frames in attributed text views with links.
 */
- (CGRect)accessibilityFrame
{
    if (self.containerView) {
        CGRect screenFrame = UIAccessibilityConvertFrameToScreenCoordinates(self.boundingRect, self.containerView);
        A11Y_LOG(@"accessibilityFrame: boundingRect=%@ -> screenFrame=%@",
                 NSStringFromCGRect(self.boundingRect), NSStringFromCGRect(screenFrame));
        return screenFrame;
    }
    A11Y_LOG(@"accessibilityFrame: containerView is nil, returning super");
    return [super accessibilityFrame];
}

#pragma mark - Localization Helpers

/**
 * Gets the resource bundle for localized strings.
 * The bundle is created by CocoaPods from ios/Resources/*.lproj files.
 */
+ (NSBundle *)resourceBundle
{
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Try to find the resource bundle created by CocoaPods
        NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
        NSURL *bundleURL = [mainBundle URLForResource:@"FabricHtmlTextResources"
                                        withExtension:@"bundle"];
        if (bundleURL) {
            bundle = [NSBundle bundleWithURL:bundleURL];
            A11Y_LOG(@"Found resource bundle at: %@", bundleURL.path);
        } else {
            // Fallback to main bundle (for development)
            bundle = mainBundle;
            A11Y_LOG(@"Resource bundle not found, using main bundle");
        }
    });
    return bundle;
}

/**
 * Gets a localized string from the resource bundle.
 * Falls back to the provided default if not found.
 */
+ (NSString *)localizedStringForKey:(NSString *)key fallback:(NSString *)fallback
{
    NSBundle *bundle = [self resourceBundle];
    NSString *result = [bundle localizedStringForKey:key value:fallback table:@"Localizable"];
    return result ?: fallback;
}

/**
 * Gets the localized role description for the given content type.
 */
+ (NSString *)roleDescriptionForContentType:(HTMLDetectedContentType)contentType
{
    switch (contentType) {
        case HTMLDetectedContentTypeEmail:
            return [self localizedStringForKey:@"a11y_link_email" fallback:@"email address"];
        case HTMLDetectedContentTypePhone:
            return [self localizedStringForKey:@"a11y_link_phone" fallback:@"phone number"];
        case HTMLDetectedContentTypeLink:
        default:
            // Detect web vs generic link from URL scheme
            return [self localizedStringForKey:@"a11y_link_web" fallback:@"web link"];
    }
}

/**
 * Gets the localized position string (e.g., "1 of 2").
 */
+ (NSString *)positionStringForIndex:(NSUInteger)index total:(NSUInteger)total
{
    NSString *format = [self localizedStringForKey:@"a11y_link_position" fallback:@"%1$lu of %2$lu"];
    return [NSString stringWithFormat:format, (unsigned long)(index + 1), (unsigned long)total];
}

- (instancetype)initWithAccessibilityContainer:(id)container
                                     linkIndex:(NSUInteger)linkIndex
                                totalLinkCount:(NSUInteger)totalLinkCount
                                           url:(NSURL *)url
                                   contentType:(HTMLDetectedContentType)contentType
                                      linkText:(NSString *)linkText
                                   boundingRect:(CGRect)boundingRect
                                  containerView:(UIView *)containerView
{
    A11Y_LOG(@"init: linkIndex=%lu/%lu, text='%@', url='%@', boundingRect=%@",
             (unsigned long)linkIndex, (unsigned long)totalLinkCount,
             linkText, url.absoluteString, NSStringFromCGRect(boundingRect));
    self = [super initWithAccessibilityContainer:container];
    if (self) {
        _linkIndex = linkIndex;
        _totalLinkCount = totalLinkCount;
        _url = [url copy];
        _contentType = contentType;
        _linkText = [linkText copy];
        _boundingRect = boundingRect;
        _containerView = containerView;

        // Note: accessibilityFrame is now computed dynamically in the getter
        // using boundingRect and containerView. This ensures the frame stays
        // accurate even when the view moves (scrolling, layout changes, etc.)

        // Configure accessibility properties
        [self configureAccessibilityProperties];
    }
    return self;
}

- (void)configureAccessibilityProperties
{
    // Set traits to indicate this is a link - VoiceOver will provide
    // localized "link" announcement and "double tap to open" hint
    self.accessibilityTraits = UIAccessibilityTraitLink;

    // Build accessibility label with link text and position
    // Format: "Link text, 1 of 3" - properly localized
    NSString *positionInfo = [[self class] positionStringForIndex:self.linkIndex
                                                            total:self.totalLinkCount];

    if (self.linkText.length > 0) {
        // Include position info only when there are multiple links
        if (self.totalLinkCount > 1) {
            self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@",
                                       self.linkText, positionInfo];
        } else {
            self.accessibilityLabel = self.linkText;
        }
    } else {
        // Fallback if no link text
        self.accessibilityLabel = positionInfo;
    }

    // Set the role description to provide more context about the link type
    // VoiceOver will announce this as a hint after the label
    // e.g., "Example Site, 1 of 3. web link"
    NSString *roleDescription = [[self class] roleDescriptionForContentType:self.contentType];
    self.accessibilityHint = roleDescription;

    A11Y_LOG(@"configureAccessibilityProperties: label='%@', hint='%@'",
             self.accessibilityLabel, self.accessibilityHint);
}

#pragma mark - UIAccessibilityAction

- (BOOL)accessibilityActivate
{
    A11Y_LOG(@">>> accessibilityActivate: link[%lu] '%@' url='%@'",
             (unsigned long)self.linkIndex, self.linkText, self.url.absoluteString);
    // Get the parent view to trigger the link activation
    id container = self.accessibilityContainer;
    if ([container isKindOfClass:[FabricRichCoreTextView class]]) {
        FabricRichCoreTextView *coreTextView = (FabricRichCoreTextView *)container;

        // Check if delegate responds to link tap
        if ([coreTextView.delegate respondsToSelector:@selector(coreTextView:didTapLinkWithURL:type:)]) {
            A11Y_LOG(@">>> accessibilityActivate: calling delegate");
            [coreTextView.delegate coreTextView:coreTextView
                              didTapLinkWithURL:self.url
                                           type:self.contentType];
        } else {
            A11Y_LOG(@">>> accessibilityActivate: no delegate or delegate doesn't respond");
        }
        // Return YES to indicate this element is activatable, even if no delegate is set
        // This tells VoiceOver that the element can be activated
        return YES;
    }
    A11Y_LOG(@">>> accessibilityActivate: container is not FabricRichCoreTextView");
    return NO;
}

@end
