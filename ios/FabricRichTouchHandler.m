/**
 * FabricRichTouchHandler.m
 *
 * Implementation of touch handling and link hit testing.
 */

#import "FabricRichTouchHandler.h"

@implementation FabricRichTouchHandler

- (NSURL *)linkAtPoint:(CGPoint)point
               inFrame:(CTFrameRef)frame
        attributedText:(NSAttributedString *)attributedText
            viewBounds:(CGRect)viewBounds
          detectedType:(HTMLDetectedContentType *)outType {

    if (!frame) {
        return nil;
    }

    if (!attributedText || attributedText.length == 0) {
        return nil;
    }

    // Convert point to CoreText coordinate system (flip Y)
    CGPoint ctPoint = CGPointMake(point.x, viewBounds.size.height - point.y);

    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);

    if (lineCount == 0) {
        return nil;
    }

    CGPoint *lineOrigins = malloc(sizeof(CGPoint) * lineCount);
    if (!lineOrigins) {
        return nil;
    }
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);

    NSURL *foundURL = nil;

    for (CFIndex i = 0; i < lineCount; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGPoint lineOrigin = lineOrigins[i];

        // Get line bounds
        CGFloat ascent, descent, leading;
        CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

        // Check if point is within this line's vertical bounds
        if (ctPoint.y >= lineOrigin.y - descent &&
            ctPoint.y <= lineOrigin.y + ascent) {
            // Check if point is within horizontal bounds
            if (ctPoint.x >= lineOrigin.x && ctPoint.x <= lineOrigin.x + lineWidth) {
                // Get character index at this position
                CFIndex charIndex = CTLineGetStringIndexForPosition(
                    line,
                    CGPointMake(ctPoint.x - lineOrigin.x, ctPoint.y - lineOrigin.y));

                if (charIndex != kCFNotFound &&
                    charIndex < (CFIndex)attributedText.length) {
                    // Check for link attribute at this index
                    id linkValue = [attributedText attribute:NSLinkAttributeName
                                                      atIndex:charIndex
                                               effectiveRange:NULL];
                    if (linkValue) {
                        if ([linkValue isKindOfClass:[NSURL class]]) {
                            foundURL = linkValue;
                        } else if ([linkValue isKindOfClass:[NSString class]]) {
                            foundURL = [NSURL URLWithString:linkValue];
#if DEBUG
                            if (!foundURL) {
                                NSLog(@"[FabricRichTouchHandler] Failed to convert string to NSURL at charIndex=%ld, linkValue='%@'",
                                      (long)charIndex, linkValue);
                            }
#endif
                        }

                        // Get the detected content type if available
                        if (outType) {
                            NSNumber *typeValue = [attributedText attribute:FabricRichDetectedContentTypeKey
                                                                     atIndex:charIndex
                                                              effectiveRange:NULL];
                            if (typeValue) {
                                *outType = (HTMLDetectedContentType)[typeValue integerValue];
                            } else {
                                // Default to link for explicit <a> tags (no FabricRichDetectedContentTypeKey)
                                *outType = HTMLDetectedContentTypeLink;
                            }
                        }
                    }
                }
            }
        }

        if (foundURL) {
            break;
        }
    }

    free(lineOrigins);

    // Defense-in-depth: Validate URL scheme before returning
    // This provides a safety backstop even if earlier validation fails
    if (foundURL) {
        static NSSet *allowedSchemes = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            allowedSchemes = [NSSet setWithObjects:@"http", @"https", @"mailto", @"tel", nil];
        });

        NSString *scheme = foundURL.scheme.lowercaseString;
        if (![allowedSchemes containsObject:scheme]) {
            foundURL = nil;  // Block dangerous URL schemes (javascript:, data:, vbscript:, etc.)
        }
    }

    return foundURL;
}

@end
