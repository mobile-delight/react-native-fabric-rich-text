/**
 * FabricRichTextAccessibilityHelper.m
 *
 * Implementation of accessibility calculations for VoiceOver support.
 */

#import "FabricRichTextAccessibilityHelper.h"
#import "FabricRichLinkAccessibilityElement.h"

/// Debug logging for accessibility - set to 0 for production
#define A11Y_HELPER_DEBUG 0

#if A11Y_HELPER_DEBUG && defined(DEBUG)
#define A11Y_HELPER_LOG(fmt, ...) NSLog(@"[A11Y_Helper] " fmt, ##__VA_ARGS__)
#else
#define A11Y_HELPER_LOG(fmt, ...) do { } while(0)
#endif

#pragma mark - Dynamic Text Accessibility Element

/**
 * Simple accessibility element that dynamically computes its frame.
 * Used for the text content element so its frame stays accurate
 * when the view moves (scrolling, layout changes, etc.).
 */
@interface FabricRichDynamicTextAccessibilityElement : UIAccessibilityElement
@property (nonatomic, weak) UIView *containerView;
@end

@implementation FabricRichDynamicTextAccessibilityElement

- (CGRect)accessibilityFrame {
    if (self.containerView) {
        // Use the container view's full bounds for the text element
        return UIAccessibilityConvertFrameToScreenCoordinates(self.containerView.bounds, self.containerView);
    }
    return [super accessibilityFrame];
}

@end

#pragma mark - FabricRichTextAccessibilityHelper

@implementation FabricRichTextAccessibilityHelper

#pragma mark - Link Range Queries

- (NSArray<NSValue *> *)allLinkRangesInText:(NSAttributedString *)attributedText {
    if (!attributedText || attributedText.length == 0) {
        return @[];
    }

    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    [attributedText enumerateAttribute:NSLinkAttributeName
                               inRange:NSMakeRange(0, attributedText.length)
                               options:0
                            usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            [ranges addObject:[NSValue valueWithRange:range]];
        }
    }];

    return ranges;
}

- (NSInteger)lineForCharacterAtIndex:(NSUInteger)charIndex
                             inFrame:(CTFrameRef)frame {
    if (!frame) {
        return -1;
    }

    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);

    for (CFIndex i = 0; i < lineCount; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange lineRange = CTLineGetStringRange(line);
        NSUInteger lineStart = (NSUInteger)lineRange.location;
        NSUInteger lineEnd = lineStart + (NSUInteger)lineRange.length;

        if (charIndex >= lineStart && charIndex < lineEnd) {
            return (NSInteger)i;
        }
    }

    return -1;
}

- (NSInteger)visibleLinkCountWithFrame:(CTFrameRef)frame
                         numberOfLines:(NSInteger)numberOfLines
                        attributedText:(NSAttributedString *)attributedText {
    NSArray<NSValue *> *allLinks = [self allLinkRangesInText:attributedText];
    if (allLinks.count == 0) {
        return 0;
    }

    // If no truncation, all links are visible
    if (numberOfLines <= 0) {
        return (NSInteger)allLinks.count;
    }

    if (!frame) {
        return 0;
    }

    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    NSInteger visibleLines = MIN(lineCount, numberOfLines);

    // Count links that start on visible lines
    NSInteger count = 0;
    for (NSValue *rangeValue in allLinks) {
        NSRange linkRange = rangeValue.rangeValue;
        NSInteger linkLine = [self lineForCharacterAtIndex:linkRange.location inFrame:frame];

        if (linkLine >= 0 && linkLine < visibleLines) {
            count++;
        }
    }

    return count;
}

#pragma mark - Link Bounds

- (CGRect)boundsForLinkAtIndex:(NSUInteger)index
                       inFrame:(CTFrameRef)frame
                attributedText:(NSAttributedString *)attributedText
                    viewBounds:(CGRect)viewBounds {
    A11Y_HELPER_LOG(@"boundsForLinkAtIndex:%lu - viewBounds=%@", (unsigned long)index, NSStringFromCGRect(viewBounds));

    NSArray<NSValue *> *allLinks = [self allLinkRangesInText:attributedText];
    if (index >= allLinks.count) {
        A11Y_HELPER_LOG(@"boundsForLinkAtIndex: index out of range");
        return CGRectZero;
    }

    if (!frame) {
        A11Y_HELPER_LOG(@"boundsForLinkAtIndex: no CTFrame");
        return CGRectZero;
    }

    NSRange linkRange = allLinks[index].rangeValue;
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    A11Y_HELPER_LOG(@"boundsForLinkAtIndex: linkRange=(%lu, %lu), lineCount=%ld",
             (unsigned long)linkRange.location, (unsigned long)linkRange.length, (long)lineCount);

    if (lineCount == 0) {
        return CGRectZero;
    }

    // Get line origins - these are in CoreText coordinates (origin at bottom-left of frame)
    CGPoint *lineOrigins = malloc(sizeof(CGPoint) * lineCount);
    if (!lineOrigins) {
        A11Y_HELPER_LOG(@"boundsForLinkAtIndex: malloc failed for lineOrigins");
        return CGRectZero;
    }
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);

    CGRect bounds = CGRectNull;

    for (CFIndex i = 0; i < lineCount; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange lineRange = CTLineGetStringRange(line);

        // Check if this line contains part of the link
        NSRange lineNSRange = NSMakeRange((NSUInteger)lineRange.location, (NSUInteger)lineRange.length);
        NSRange intersection = NSIntersectionRange(linkRange, lineNSRange);

        if (intersection.length == 0) {
            continue;
        }

        // Get typographic bounds for this line
        CGFloat ascent, descent, leading;
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

        // Get x positions for the link portion on this line
        CGFloat startOffset = CTLineGetOffsetForStringIndex(line, (CFIndex)intersection.location, NULL);
        CGFloat endOffset = CTLineGetOffsetForStringIndex(line, (CFIndex)(intersection.location + intersection.length), NULL);

        // Calculate line bounds in CoreText coordinates (origin at bottom-left)
        CGPoint lineOrigin = lineOrigins[i];

        // Convert to UIKit coordinates (origin at top-left)
        CGFloat lineTop = viewBounds.size.height - lineOrigin.y - ascent;
        CGFloat lineHeight = ascent + descent;

        A11Y_HELPER_LOG(@"boundsForLinkAtIndex: line[%ld] origin=(%f,%f) ascent=%f descent=%f -> lineTop=%f",
                 (long)i, lineOrigin.x, lineOrigin.y, ascent, descent, lineTop);
        A11Y_HELPER_LOG(@"boundsForLinkAtIndex: line[%ld] startOffset=%f endOffset=%f",
                 (long)i, startOffset, endOffset);

        CGRect lineBounds = CGRectMake(
            lineOrigin.x + startOffset,
            lineTop,
            endOffset - startOffset,
            lineHeight
        );
        A11Y_HELPER_LOG(@"boundsForLinkAtIndex: line[%ld] lineBounds=%@", (long)i, NSStringFromCGRect(lineBounds));

        if (CGRectIsNull(bounds)) {
            bounds = lineBounds;
        } else {
            bounds = CGRectUnion(bounds, lineBounds);
        }
    }

    free(lineOrigins);

    A11Y_HELPER_LOG(@"boundsForLinkAtIndex:%lu RESULT=%@", (unsigned long)index, NSStringFromCGRect(bounds));
    return CGRectIsNull(bounds) ? CGRectZero : bounds;
}

#pragma mark - Accessibility Element Building

- (NSArray<UIAccessibilityElement *> *)buildAccessibilityElementsWithFrame:(CTFrameRef)frame
                                                             numberOfLines:(NSInteger)numberOfLines
                                                            attributedText:(NSAttributedString *)attributedText
                                                             containerView:(UIView *)containerView
                                                               visibleText:(NSString *)visibleText {
    NSInteger linkCount = [self visibleLinkCountWithFrame:frame
                                            numberOfLines:numberOfLines
                                           attributedText:attributedText];
    A11Y_HELPER_LOG(@"buildAccessibilityElements: linkCount=%ld", (long)linkCount);

    if (linkCount == 0) {
        A11Y_HELPER_LOG(@"buildAccessibilityElements: no links, returning empty array");
        return @[];
    }

    A11Y_HELPER_LOG(@"buildAccessibilityElements: text='%@'", [attributedText.string substringToIndex:MIN(50, attributedText.string.length)]);

    // First element: the full text content so VoiceOver announces it
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:linkCount + 1];

    // Use dynamic text element that computes accessibilityFrame on-demand
    FabricRichDynamicTextAccessibilityElement *textElement = [[FabricRichDynamicTextAccessibilityElement alloc] initWithAccessibilityContainer:containerView];
    textElement.containerView = containerView;
    textElement.accessibilityTraits = UIAccessibilityTraitStaticText;
    textElement.accessibilityLabel = visibleText;

    A11Y_HELPER_LOG(@"TEXT ELEMENT: label='%@...', bounds=%@",
             [visibleText substringToIndex:MIN(50, visibleText.length)],
             NSStringFromCGRect(containerView.bounds));

    [elements addObject:textElement];

    NSArray<NSValue *> *allLinks = [self allLinkRangesInText:attributedText];
    A11Y_HELPER_LOG(@"buildAccessibilityElements: found %lu link ranges", (unsigned long)allLinks.count);

    for (NSUInteger i = 0; i < (NSUInteger)linkCount && i < allLinks.count; i++) {
        NSRange linkRange = allLinks[i].rangeValue;
        A11Y_HELPER_LOG(@"LINK[%lu] range: loc=%lu, len=%lu", (unsigned long)i, (unsigned long)linkRange.location, (unsigned long)linkRange.length);

        // Get the URL and content type for this link
        NSURL *url = nil;
        HTMLDetectedContentType contentType = HTMLDetectedContentTypeLink;

        id linkValue = [attributedText attribute:NSLinkAttributeName atIndex:linkRange.location effectiveRange:NULL];
        A11Y_HELPER_LOG(@"LINK[%lu] NSLinkAttributeName value: %@ (class: %@)",
                 (unsigned long)i, linkValue, NSStringFromClass([linkValue class]));

        if ([linkValue isKindOfClass:[NSURL class]]) {
            url = linkValue;
        } else if ([linkValue isKindOfClass:[NSString class]]) {
            url = [NSURL URLWithString:linkValue];
            A11Y_HELPER_LOG(@"LINK[%lu] Converted string '%@' to URL: %@", (unsigned long)i, linkValue, url);
        }

        // First check for explicit content type attribute (from auto-detection)
        NSNumber *typeValue = [attributedText attribute:FabricRichDetectedContentTypeKey atIndex:linkRange.location effectiveRange:NULL];
        if (typeValue) {
            contentType = (HTMLDetectedContentType)[typeValue integerValue];
            A11Y_HELPER_LOG(@"LINK[%lu] Found FabricRichDetectedContentTypeKey: %ld", (unsigned long)i, (long)contentType);
        } else if (url) {
            // Infer content type from URL scheme
            NSString *scheme = url.scheme.lowercaseString;
            A11Y_HELPER_LOG(@"LINK[%lu] URL scheme: '%@'", (unsigned long)i, scheme);

            if ([scheme isEqualToString:@"mailto"]) {
                contentType = HTMLDetectedContentTypeEmail;
                A11Y_HELPER_LOG(@"LINK[%lu] Detected as EMAIL from mailto: scheme", (unsigned long)i);
            } else if ([scheme isEqualToString:@"tel"]) {
                contentType = HTMLDetectedContentTypePhone;
                A11Y_HELPER_LOG(@"LINK[%lu] Detected as PHONE from tel: scheme", (unsigned long)i);
            } else {
                A11Y_HELPER_LOG(@"LINK[%lu] Using default contentType=LINK for scheme '%@'", (unsigned long)i, scheme);
            }
        } else {
            A11Y_HELPER_LOG(@"LINK[%lu] WARNING: No URL found for link!", (unsigned long)i);
        }

        // Get the link text
        NSString *linkText = [attributedText.string substringWithRange:linkRange];
        A11Y_HELPER_LOG(@"LINK[%lu] text='%@', url='%@', type=%ld", (unsigned long)i, linkText, url.absoluteString, (long)contentType);

        // Skip links without a valid URL
        if (!url) {
            A11Y_HELPER_LOG(@"LINK[%lu] Skipping - no valid URL", (unsigned long)i);
            continue;
        }

        // Get the bounds for this link in view coordinates
        CGRect linkBounds = [self boundsForLinkAtIndex:i
                                               inFrame:frame
                                        attributedText:attributedText
                                            viewBounds:containerView.bounds];
        A11Y_HELPER_LOG(@"LINK[%lu] bounds: local=%@", (unsigned long)i, NSStringFromCGRect(linkBounds));

        // Create the accessibility element with local bounds
        FabricRichLinkAccessibilityElement *element = [[FabricRichLinkAccessibilityElement alloc]
            initWithAccessibilityContainer:containerView
                                 linkIndex:i
                            totalLinkCount:(NSUInteger)linkCount
                                       url:url
                               contentType:contentType
                                  linkText:linkText
                               boundingRect:linkBounds
                              containerView:containerView];

        [elements addObject:element];
        A11Y_HELPER_LOG(@"LINK[%lu] created element with label='%@'", (unsigned long)i, element.accessibilityLabel);
    }

    A11Y_HELPER_LOG(@"buildAccessibilityElements: COMPLETE - created %lu elements (1 text + %ld links)", (unsigned long)elements.count, (long)linkCount);
    return [elements copy];
}

@end
