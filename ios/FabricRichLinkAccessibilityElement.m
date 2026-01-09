#import "FabricRichLinkAccessibilityElement.h"

/// Accessibility debug logging - disabled in production
#ifdef DEBUG
#define A11Y_DEBUG 1
#else
#define A11Y_DEBUG 0
#endif

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

#pragma mark - URL Scheme Validation

/**
 * Validates that a URL has an allowed scheme.
 * Uses a whitelist approach to only allow safe protocols.
 * Blocks dangerous schemes like javascript:, data:, file:, vbscript:, etc.
 */
+ (BOOL)isSchemeAllowed:(NSURL *)url
{
    if (!url || !url.scheme) {
        return NO;
    }

    NSString *scheme = [url.scheme lowercaseString];
    NSSet<NSString *> *allowedSchemes = [NSSet setWithObjects:@"http", @"https", @"mailto", @"tel", nil];
    return [allowedSchemes containsObject:scheme];
}

#pragma mark - UIAccessibilityAction

- (BOOL)accessibilityActivate
{
    A11Y_LOG(@">>> accessibilityActivate: link[%lu] '%@' url='%@'",
             (unsigned long)self.linkIndex, self.linkText, self.url.absoluteString);

    // Don't activate placeholder URLs
    if (!self.url || [self.url.absoluteString isEqualToString:@"about:blank"]) {
        A11Y_LOG(@">>> accessibilityActivate: invalid or placeholder URL, returning NO");
        return NO;
    }

    // Validate URL scheme - block dangerous protocols
    if (![[self class] isSchemeAllowed:self.url]) {
        A11Y_LOG(@">>> accessibilityActivate: blocked unsafe URL scheme: %@", self.url.scheme);
        return NO;
    }

    // Get the parent view to trigger the link activation
    id container = self.accessibilityContainer;
    if ([container isKindOfClass:[FabricRichCoreTextView class]]) {
        FabricRichCoreTextView *coreTextView = (FabricRichCoreTextView *)container;

        // Only return YES if delegate is set and responds to selector
        if ([coreTextView.delegate respondsToSelector:@selector(coreTextView:didTapLinkWithURL:type:)]) {
            A11Y_LOG(@">>> accessibilityActivate: calling delegate");
            [coreTextView.delegate coreTextView:coreTextView
                              didTapLinkWithURL:self.url
                                           type:self.contentType];
            return YES;
        } else {
            A11Y_LOG(@">>> accessibilityActivate: no delegate or delegate doesn't respond");
            return NO;
        }
    }
    A11Y_LOG(@">>> accessibilityActivate: container is not FabricRichCoreTextView");
    return NO;
}

@end
