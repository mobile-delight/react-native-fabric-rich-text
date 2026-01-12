/**
 * FabricRichDebugDrawingHelper.m
 *
 * Implementation of debug visualization for text layout.
 */

#import "FabricRichDebugDrawingHelper.h"

#if DEBUG
/// Set to YES to enable debug visualization of line bounds
static BOOL kDebugDrawLineBounds = NO;
#endif

@implementation FabricRichDebugDrawingHelper {
    NSArray<NSDictionary *> *_debugLineInfo;
}

#pragma mark - Debug Flag

+ (BOOL)isDebugDrawingEnabled {
#if DEBUG
    return kDebugDrawLineBounds;
#else
    return NO;
#endif
}

#pragma mark - Debug Drawing

- (void)drawDebugLineBounds:(CTFrameRef)frame
                  inContext:(CGContextRef)context
                 viewBounds:(CGRect)viewBounds
             attributedText:(NSAttributedString *)attributedText {
#if DEBUG
    if (!kDebugDrawLineBounds) {
        return;
    }

    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);

    if (lineCount == 0) {
        _debugLineInfo = @[];
        return;
    }

    CGPoint *lineOrigins = malloc(sizeof(CGPoint) * lineCount);
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);

    // Colors for alternating lines
    CGColorRef colors[] = {
        [[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.2] CGColor], // Red
        [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.2] CGColor], // Blue
        [[UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:0.2] CGColor], // Green
        [[UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.2] CGColor], // Orange
    };

    NSLog(@"[DEBUG] Total lines: %ld, bounds height: %.1f", (long)lineCount, viewBounds.size.height);

    NSMutableArray *lineInfoArray = [NSMutableArray arrayWithCapacity:lineCount];

    for (CFIndex i = 0; i < lineCount; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGPoint origin = lineOrigins[i];

        CGFloat ascent, descent, leading;
        CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

        // Line rect in CoreText coordinates (for hit testing, convert to UIKit coords)
        CGRect lineRectCT = CGRectMake(origin.x, origin.y - descent, lineWidth, ascent + descent);

        // Convert to UIKit coordinates for hit testing
        CGRect lineRectUIKit = CGRectMake(origin.x, viewBounds.size.height - origin.y - ascent,
                                          lineWidth, ascent + descent);

        // Get the string range for this line
        CFRange stringRange = CTLineGetStringRange(line);
        NSRange nsRange = NSMakeRange(stringRange.location, stringRange.length);
        NSString *lineText = [attributedText.string substringWithRange:nsRange];
        NSString *escapedText = [lineText stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];

        // Collect paragraph style info
        NSMutableString *styleInfo = [NSMutableString string];
        [attributedText enumerateAttribute:NSParagraphStyleAttributeName
                                   inRange:nsRange
                                   options:0
                                usingBlock:^(id value, NSRange range, BOOL *stop) {
            NSString *rangeText = [attributedText.string substringWithRange:range];
            rangeText = [rangeText stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            if ([value isKindOfClass:[NSParagraphStyle class]]) {
                NSParagraphStyle *style = (NSParagraphStyle *)value;
                [styleInfo appendFormat:@"  [%lu-%lu] '%@'\n    headIndent=%.1f "
                                         @"firstLine=%.1f\n    spacing=%.1f "
                                         @"spacingBefore=%.1f\n",
                                         (unsigned long)range.location,
                                         (unsigned long)(range.location + range.length - 1),
                                         rangeText, style.headIndent,
                                         style.firstLineHeadIndent,
                                         style.paragraphSpacing,
                                         style.paragraphSpacingBefore];
            } else {
                [styleInfo appendFormat:@"  [%lu-%lu] '%@' NO PARAGRAPH STYLE\n",
                                         (unsigned long)range.location,
                                         (unsigned long)(range.location + range.length - 1),
                                         rangeText];
            }
        }];

        // Store debug info for this line
        NSDictionary *info = @{
            @"index" : @(i),
            @"text" : escapedText,
            @"rect" : [NSValue valueWithCGRect:lineRectUIKit],
            @"origin" : [NSValue valueWithCGPoint:origin],
            @"ascent" : @(ascent),
            @"descent" : @(descent),
            @"leading" : @(leading),
            @"styleInfo" : styleInfo ?: @"(none)"
        };
        [lineInfoArray addObject:info];

        NSLog(@"[DEBUG] Line %ld: origin=(%.1f, %.1f) ascent=%.1f descent=%.1f "
              @"leading=%.1f height=%.1f text='%@'",
              (long)i, origin.x, origin.y, ascent, descent, leading,
              ascent + descent, escapedText);

        // Draw filled rect for line bounds
        CGContextSetFillColorWithColor(context, colors[i % 4]);
        CGContextFillRect(context, lineRectCT);

        // Draw stroke around line bounds
        CGContextSetStrokeColorWithColor(
            context, [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] CGColor]);
        CGContextSetLineWidth(context, 0.5);
        CGContextStrokeRect(context, lineRectCT);

        // Draw baseline
        CGContextSetStrokeColorWithColor(context, [[UIColor redColor] CGColor]);
        CGContextSetLineWidth(context, 1.0);
        CGContextMoveToPoint(context, origin.x, origin.y);
        CGContextAddLineToPoint(context, origin.x + lineWidth, origin.y);
        CGContextStrokePath(context);
    }

    _debugLineInfo = [lineInfoArray copy];
    free(lineOrigins);
#endif
}

#pragma mark - Tap-to-Inspect

- (NSDictionary *)debugLineInfoAtPoint:(CGPoint)point {
#if DEBUG
    for (NSDictionary *info in _debugLineInfo) {
        CGRect rect = [info[@"rect"] CGRectValue];
        // Expand rect slightly for easier tapping
        CGRect expandedRect = CGRectInset(rect, -5, -5);
        if (CGRectContainsPoint(expandedRect, point)) {
            return info;
        }
    }
#endif
    return nil;
}

- (void)showDebugAlertForLineInfo:(NSDictionary *)info fromView:(UIView *)view {
#if DEBUG
    NSInteger index = [info[@"index"] integerValue];
    NSString *text = info[@"text"];
    CGPoint origin = [info[@"origin"] CGPointValue];
    CGFloat ascent = [info[@"ascent"] floatValue];
    CGFloat descent = [info[@"descent"] floatValue];
    CGFloat leading = [info[@"leading"] floatValue];
    NSString *styleInfo = info[@"styleInfo"];

    NSString *message =
        [NSString stringWithFormat:@"Line %ld\n\n"
                                   @"Text: '%@'\n\n"
                                   @"Metrics:\n"
                                   @"  origin: (%.1f, %.1f)\n"
                                   @"  ascent: %.1f\n"
                                   @"  descent: %.1f\n"
                                   @"  leading: %.1f\n"
                                   @"  height: %.1f\n\n"
                                   @"Paragraph Styles:\n%@",
                                   (long)index, text, origin.x, origin.y, ascent,
                                   descent, leading, ascent + descent, styleInfo];

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Line Debug Info"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];

    // Find the presenting view controller
    UIViewController *presenter = [self findViewControllerForView:view];
    if (presenter) {
        [presenter presentViewController:alert animated:YES completion:nil];
    } else {
        NSLog(@"[DEBUG] Could not find view controller to present alert. Info:\n%@", message);
    }
#endif
}

#if DEBUG
- (UIViewController *)findViewControllerForView:(UIView *)view {
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}
#endif

@end
