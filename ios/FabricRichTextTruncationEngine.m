/**
 * FabricRichTextTruncationEngine.m
 *
 * Implementation of smart word-boundary text truncation.
 */

#import "FabricRichTextTruncationEngine.h"

/// Debug logging for truncation - set to 0 for production
#define TRUNCATION_DEBUG 0

#if TRUNCATION_DEBUG
#define TRUNCATION_LOG(fmt, ...) NSLog(@"[Truncation] " fmt, ##__VA_ARGS__)
#else
#define TRUNCATION_LOG(fmt, ...) do { } while(0)
#endif

@implementation FabricRichTextTruncationEngine {
    __weak UIView *_view;
}

#pragma mark - Initialization

- (instancetype)initWithView:(UIView *)view {
    self = [super init];
    if (self) {
        _view = view;
    }
    return self;
}

#pragma mark - Private Helpers

/**
 * Extract text attributes from the last line to use for the ellipsis character.
 * This ensures the ellipsis matches the style of the surrounding text.
 */
- (NSDictionary *)attributesForTruncationToken:(CTLineRef)line {
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    if (CFArrayGetCount(runs) == 0) {
        return @{};
    }

    // Get the last run to match the end of the line
    CTRunRef lastRun = CFArrayGetValueAtIndex(runs, CFArrayGetCount(runs) - 1);
    CFDictionaryRef runAttributes = CTRunGetAttributes(lastRun);

    if (runAttributes) {
        return (__bridge NSDictionary *)runAttributes;
    }

    return @{};
}

/**
 * Adjusts a truncation index to the nearest word boundary if the text was cut mid-word.
 * Returns the adjusted index (which may be the same if no adjustment needed).
 *
 * @param text The full text being truncated
 * @param truncationIndex The index where truncation occurred
 * @return The adjusted index at the last word boundary, or truncationIndex if no adjustment needed
 */
- (NSUInteger)adjustTruncationIndexToWordBoundary:(NSString *)text atIndex:(NSUInteger)truncationIndex {
    if (truncationIndex == 0 || truncationIndex >= text.length) {
        return truncationIndex;
    }

    unichar lastVisibleChar = [text characterAtIndex:truncationIndex - 1];
    unichar firstHiddenChar = [text characterAtIndex:truncationIndex];

    NSCharacterSet *alphanumeric = [NSCharacterSet alphanumericCharacterSet];
    BOOL lastVisibleIsAlpha = [alphanumeric characterIsMember:lastVisibleChar];
    BOOL firstHiddenIsAlpha = [alphanumeric characterIsMember:firstHiddenChar];
    BOOL cutMidWord = lastVisibleIsAlpha && firstHiddenIsAlpha;

    if (!cutMidWord) {
        return truncationIndex;
    }

    // Find the last space to get the last complete word
    NSString *textBeforeTruncation = [text substringToIndex:truncationIndex];
    NSRange lastSpace = [textBeforeTruncation rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]
                                                               options:NSBackwardsSearch];

    if (lastSpace.location != NSNotFound && lastSpace.location > 0) {
        return lastSpace.location;
    }

    return truncationIndex;
}

#pragma mark - Public Methods

- (BOOL)isContentTruncatedWithFrame:(CTFrameRef)frame
                      numberOfLines:(NSInteger)numberOfLines
                     attributedText:(NSAttributedString *)attributedText {
    if (numberOfLines <= 0) {
        return NO;
    }

    if (!frame) {
        return NO;
    }

    if (!attributedText || attributedText.length == 0) {
        return NO;
    }

    CFRange visibleRange = CTFrameGetVisibleStringRange(frame);
    return (visibleRange.location + visibleRange.length) < (CFIndex)attributedText.length;
}

- (NSString *)visibleTextWithFrame:(CTFrameRef)frame
                     numberOfLines:(NSInteger)numberOfLines
                    attributedText:(NSAttributedString *)attributedText
         resolvedAccessibilityLabel:(NSString *)resolvedAccessibilityLabel {

    if (!attributedText || attributedText.length == 0) {
        TRUNCATION_LOG(@"visibleText: no text, returning empty");
        return resolvedAccessibilityLabel ?: @"";
    }

    // If not truncating, return the full resolved label or text
    if (numberOfLines <= 0) {
        TRUNCATION_LOG(@"visibleText: numberOfLines=%ld, returning full text", (long)numberOfLines);
        return resolvedAccessibilityLabel ?: attributedText.string;
    }

    if (!frame) {
        TRUNCATION_LOG(@"visibleText: no CTFrame, returning full text");
        return resolvedAccessibilityLabel ?: attributedText.string;
    }

    CFRange visibleRange = CTFrameGetVisibleStringRange(frame);
    NSString *fullText = attributedText.string;

    TRUNCATION_LOG(@"visibleText: numberOfLines=%ld, visibleRange=(%ld, %ld), fullTextLength=%lu",
             (long)numberOfLines, (long)visibleRange.location, (long)visibleRange.length,
             (unsigned long)fullText.length);

    // Check if content is actually truncated
    if ((visibleRange.location + visibleRange.length) >= (CFIndex)fullText.length) {
        // Not truncated - return full text
        TRUNCATION_LOG(@"visibleText: not truncated, returning full text");
        return resolvedAccessibilityLabel ?: fullText;
    }

    // Text is truncated - we need to calculate the actual visible text
    // accounting for the ellipsis that replaces part of the last line
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);

    TRUNCATION_LOG(@"visibleText: content IS truncated, lineCount=%ld, numberOfLines=%ld",
             (long)lineCount, (long)numberOfLines);

    if (lineCount == 0) {
        return resolvedAccessibilityLabel ?: @"";
    }

    UIView *view = _view;
    if (!view) {
        return resolvedAccessibilityLabel ?: fullText;
    }

    // Get text from all lines except the last one
    NSMutableString *visibleText = [NSMutableString string];

    for (CFIndex i = 0; i < lineCount - 1; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange lineRange = CTLineGetStringRange(line);
        if (lineRange.location != kCFNotFound && lineRange.length > 0) {
            NSUInteger start = (NSUInteger)lineRange.location;
            NSUInteger length = MIN((NSUInteger)lineRange.length, fullText.length - start);
            [visibleText appendString:[fullText substringWithRange:NSMakeRange(start, length)]];
        }
    }

    // For the last line, calculate what text is visible after truncation
    CTLineRef lastLine = CFArrayGetValueAtIndex(lines, lineCount - 1);
    CFRange lastLineRange = CTLineGetStringRange(lastLine);
    NSUInteger lastLineStart = (NSUInteger)lastLineRange.location;

    if (lastLineStart < fullText.length) {
        // Get all remaining text from this line to end (like drawTruncatedFrame does)
        NSRange remainingRange = NSMakeRange(lastLineStart, fullText.length - lastLineStart);
        NSAttributedString *remainingText = [attributedText attributedSubstringFromRange:remainingRange];

        // Replace newlines with spaces (like drawTruncatedFrame does)
        NSMutableAttributedString *continuousText = [remainingText mutableCopy];
        NSCharacterSet *newlineSet = [NSCharacterSet newlineCharacterSet];
        NSString *plainText = continuousText.string;
        for (NSInteger i = plainText.length - 1; i >= 0; i--) {
            unichar c = [plainText characterAtIndex:i];
            if ([newlineSet characterIsMember:c]) {
                [continuousText replaceCharactersInRange:NSMakeRange(i, 1) withString:@" "];
            }
        }

        // Create a line and truncate it to get the actual visible range
        CTLineRef continuousLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)continuousText);
        if (continuousLine) {
            CGFloat availableWidth = view.bounds.size.width;

            // Create ellipsis token
            NSDictionary *attributes = [self attributesForTruncationToken:lastLine];
            NSAttributedString *ellipsisString = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:attributes];
            CTLineRef ellipsisLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)ellipsisString);

            CTLineRef truncatedLine = CTLineCreateTruncatedLine(continuousLine, availableWidth, kCTLineTruncationEnd, ellipsisLine);

            if (truncatedLine) {
                // Calculate the width of the ellipsis to determine actual visible text width
                CGFloat ellipsisWidth = CTLineGetTypographicBounds(ellipsisLine, NULL, NULL, NULL);
                CGFloat truncatedLineWidth = CTLineGetTypographicBounds(truncatedLine, NULL, NULL, NULL);
                CGFloat textOnlyWidth = truncatedLineWidth - ellipsisWidth;

                TRUNCATION_LOG(@"visibleText: truncatedLine created, ellipsisWidth=%.1f, truncatedLineWidth=%.1f, textOnlyWidth=%.1f",
                         ellipsisWidth, truncatedLineWidth, textOnlyWidth);

                // Use the original (non-truncated) line to find the character index at the truncation point
                // This gives us the exact number of characters visible before the ellipsis
                CFIndex truncationIndex = CTLineGetStringIndexForPosition(continuousLine, CGPointMake(textOnlyWidth, 0));

                TRUNCATION_LOG(@"visibleText: truncationIndex=%ld, continuousTextLength=%lu",
                         (long)truncationIndex, (unsigned long)continuousText.length);

                if (truncationIndex > 0 && truncationIndex <= (CFIndex)continuousText.length) {
                    NSUInteger truncatedEnd = (NSUInteger)truncationIndex;

                    TRUNCATION_LOG(@"visibleText: before word boundary adjustment, truncatedEnd=%lu, continuousLength=%lu",
                             (unsigned long)truncatedEnd, (unsigned long)continuousText.length);

                    // Adjust to word boundary if we cut mid-word
                    NSUInteger adjustedEnd = [self adjustTruncationIndexToWordBoundary:continuousText.string atIndex:truncatedEnd];

                    TRUNCATION_LOG(@"visibleText: after word boundary adjustment, adjustedEnd=%lu (was %lu)",
                             (unsigned long)adjustedEnd, (unsigned long)truncatedEnd);

                    NSString *lastLineVisible = [[continuousText.string substringToIndex:adjustedEnd]
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                    TRUNCATION_LOG(@"visibleText: lastLineVisible='%@'", lastLineVisible);
                    [visibleText appendString:lastLineVisible];
                }
                CFRelease(truncatedLine);
            } else {
                // Truncation returned NULL - line fits, use full last line range
                NSUInteger length = MIN((NSUInteger)lastLineRange.length, fullText.length - lastLineStart);
                NSString *lastLineText = [fullText substringWithRange:NSMakeRange(lastLineStart, length)];
                [visibleText appendString:[lastLineText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            }

            if (ellipsisLine) CFRelease(ellipsisLine);
            CFRelease(continuousLine);
        }
    }

    NSString *result = [visibleText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    TRUNCATION_LOG(@"visibleText: RESULT length=%lu, first100='%@'",
             (unsigned long)result.length, [result substringToIndex:MIN(100, result.length)]);
    return result;
}

- (void)drawTruncatedFrame:(CTFrameRef)frame
                 inContext:(CGContextRef)context
                  maxLines:(NSInteger)maxLines
            attributedText:(NSAttributedString *)attributedText {

    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);

    NSUInteger totalTextLength = attributedText.length;

    // Check if there's text beyond what's visible in the frame.
    // The shadow node constrains the frame height, so lineCount may equal maxLines
    // even when there's more content. We detect this by checking visible range.
    CFRange visibleRange = CTFrameGetVisibleStringRange(frame);
    BOOL hasMoreContent = (visibleRange.location + visibleRange.length) < (CFIndex)totalTextLength;

    UIView *view = _view;
    CGFloat boundsWidth = view ? view.bounds.size.width : 0;

    TRUNCATION_LOG(@"drawTruncatedFrame: maxLines=%ld, lineCount=%ld, boundsWidth=%.1f",
          (long)maxLines, (long)lineCount, boundsWidth);
    TRUNCATION_LOG(@"visibleRange: loc=%ld len=%ld, totalLength=%lu, hasMoreContent=%d",
          (long)visibleRange.location, (long)visibleRange.length, (unsigned long)totalTextLength, hasMoreContent);

    if (lineCount == 0) {
        TRUNCATION_LOG(@"No lines to draw, returning");
        return;
    }

    // If all content is visible, draw normally (no truncation needed)
    if (!hasMoreContent) {
        TRUNCATION_LOG(@"All content visible, drawing normally");
        CTFrameDraw(frame, context);
        return;
    }

    TRUNCATION_LOG(@"Content is truncated, will add ellipsis");

    // Get line origins for all lines
    CGPoint *lineOrigins = malloc(sizeof(CGPoint) * lineCount);
    if (!lineOrigins) {
        TRUNCATION_LOG(@"drawTruncatedFrame: malloc failed for lineOrigins, falling back to CTFrameDraw");
        CTFrameDraw(frame, context);
        return;
    }
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);

    // Draw all lines except the last one normally
    for (CFIndex i = 0; i < lineCount - 1; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGPoint origin = lineOrigins[i];
        CGContextSetTextPosition(context, origin.x, origin.y);
        CTLineDraw(line, context);
    }

    // Draw the last visible line with ellipsis truncation
    if (lineCount > 0) {
        CTLineRef lastVisibleLine = CFArrayGetValueAtIndex(lines, lineCount - 1);
        CGPoint lastOrigin = lineOrigins[lineCount - 1];
        CGFloat availableWidth = boundsWidth;

        // Get the string range of the last visible line
        CFRange lastLineRange = CTLineGetStringRange(lastVisibleLine);
        NSUInteger startLocation = (NSUInteger)lastLineRange.location;

        if (startLocation < attributedText.length) {
            // Get all remaining text from this line to end of content
            NSRange remainingRange = NSMakeRange(startLocation, attributedText.length - startLocation);
            NSAttributedString *remainingText = [attributedText attributedSubstringFromRange:remainingRange];

            TRUNCATION_LOG(@"Last line range: loc=%lu len=%ld, remaining text length=%lu",
                  (unsigned long)startLocation, (long)lastLineRange.length, (unsigned long)remainingText.length);
            TRUNCATION_LOG(@"Remaining text (first 100 chars): '%@'",
                  [remainingText.string substringToIndex:MIN(100, remainingText.string.length)]);

            // Replace newlines with spaces so CTLine sees it as continuous text.
            // We must preserve attributes, so replace character-by-character.
            NSMutableAttributedString *continuousText = [remainingText mutableCopy];
            NSCharacterSet *newlineSet = [NSCharacterSet newlineCharacterSet];
            NSString *plainText = continuousText.string;

            // Replace newlines from end to start to preserve indices
            for (NSInteger i = plainText.length - 1; i >= 0; i--) {
                unichar c = [plainText characterAtIndex:i];
                if ([newlineSet characterIsMember:c]) {
                    // Replace with space, preserving attributes at that location
                    [continuousText replaceCharactersInRange:NSMakeRange(i, 1) withString:@" "];
                }
            }

            TRUNCATION_LOG(@"Continuous text (first 100 chars): '%@'",
                  [continuousText.string substringToIndex:MIN(100, continuousText.string.length)]);

            // Create a line from the continuous text
            CTLineRef continuousLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)continuousText);
            if (!continuousLine) {
                // Fall back to drawing the original line if line creation fails
                CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
                CTLineDraw(lastVisibleLine, context);
                free(lineOrigins);
                return;
            }

            // Get the width of the continuous line (used for debug logging)
            CGFloat continuousLineWidth __unused = CTLineGetTypographicBounds(continuousLine, NULL, NULL, NULL);
            TRUNCATION_LOG(@"Continuous line width=%.1f, available width=%.1f, needs truncation=%d",
                  continuousLineWidth, availableWidth, continuousLineWidth > availableWidth);

            // Create the truncation token (ellipsis) with matching attributes
            NSDictionary *attributes = [self attributesForTruncationToken:lastVisibleLine];
            TRUNCATION_LOG(@"Ellipsis attributes: %@", attributes);
            NSAttributedString *ellipsisString = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:attributes];
            CTLineRef ellipsisLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)ellipsisString);
            if (!ellipsisLine) {
                // Fall back to drawing the continuous line without truncation
                CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
                CTLineDraw(continuousLine, context);
                CFRelease(continuousLine);
                free(lineOrigins);
                return;
            }

            // Create a truncated line with word-boundary awareness
            // First, we use CTLineCreateTruncatedLine to find the truncation point,
            // then we check if it cut mid-word and adjust accordingly.
            CTLineRef truncatedLine = CTLineCreateTruncatedLine(continuousLine, availableWidth, kCTLineTruncationEnd, ellipsisLine);

            TRUNCATION_LOG(@"CTLineCreateTruncatedLine result: %@", truncatedLine ? @"SUCCESS" : @"NULL");

            if (truncatedLine) {
                // Calculate the width of text only (without ellipsis) to find truncation point
                CGFloat ellipsisWidth = CTLineGetTypographicBounds(ellipsisLine, NULL, NULL, NULL);
                CGFloat truncatedLineWidth = CTLineGetTypographicBounds(truncatedLine, NULL, NULL, NULL);
                CGFloat textOnlyWidth = truncatedLineWidth - ellipsisWidth;

                // Find the character index at the truncation point
                CFIndex truncationIndex = CTLineGetStringIndexForPosition(continuousLine, CGPointMake(textOnlyWidth, 0));
                TRUNCATION_LOG(@"truncationIndex=%ld, textOnlyWidth=%.1f", (long)truncationIndex, textOnlyWidth);

                // Adjust to word boundary if we cut mid-word
                NSUInteger adjustedTruncationIndex = [self adjustTruncationIndexToWordBoundary:continuousText.string
                                                                                       atIndex:(NSUInteger)truncationIndex];
                BOOL needsWordBoundaryAdjustment = (adjustedTruncationIndex != (NSUInteger)truncationIndex);

                TRUNCATION_LOG(@"Word boundary adjustment: original=%ld, adjusted=%lu, needsAdjustment=%d",
                      (long)truncationIndex, (unsigned long)adjustedTruncationIndex, needsWordBoundaryAdjustment);

                if (needsWordBoundaryAdjustment) {
                    // Create a new line with text trimmed to word boundary plus ellipsis
                    NSString *wordBoundaryText = [[continuousText.string substringToIndex:adjustedTruncationIndex]
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                    // Get attributes from the original text for the trimmed portion
                    NSRange trimmedRange = NSMakeRange(0, MIN(adjustedTruncationIndex, continuousText.length));
                    NSMutableAttributedString *wordBoundaryAttrString = [[continuousText attributedSubstringFromRange:trimmedRange] mutableCopy];

                    // Trim whitespace while preserving attributes
                    NSUInteger trimmedLength = wordBoundaryText.length;
                    if (trimmedLength < wordBoundaryAttrString.length) {
                        [wordBoundaryAttrString deleteCharactersInRange:NSMakeRange(trimmedLength, wordBoundaryAttrString.length - trimmedLength)];
                    }

                    // Append ellipsis
                    [wordBoundaryAttrString appendAttributedString:ellipsisString];

                    CTLineRef wordBoundaryLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)wordBoundaryAttrString);
                    if (wordBoundaryLine) {
                        CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
                        CTLineDraw(wordBoundaryLine, context);
                        TRUNCATION_LOG(@"Drew word-boundary truncated line: '%@'", wordBoundaryAttrString.string);
                        CFRelease(wordBoundaryLine);
                    } else {
                        // Fallback to original truncated line
                        CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
                        CTLineDraw(truncatedLine, context);
                    }
                } else {
                    CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
                    CTLineDraw(truncatedLine, context);
                    TRUNCATION_LOG(@"Drew truncated line at origin (%.1f, %.1f)", lastOrigin.x, lastOrigin.y);
                }
                CFRelease(truncatedLine);
            } else {
                // CTLineCreateTruncatedLine returns NULL if line fits - but we know there's more content.
                // Manually append ellipsis to indicate truncation.
                TRUNCATION_LOG(@"FALLBACK: CTLineCreateTruncatedLine returned NULL, manually appending ellipsis");

                NSMutableAttributedString *lineWithEllipsis = [[attributedText attributedSubstringFromRange:
                    NSMakeRange(startLocation, MIN((NSUInteger)lastLineRange.length, attributedText.length - startLocation))] mutableCopy];

                // Trim trailing whitespace/newlines and append ellipsis
                NSString *trimmed = [lineWithEllipsis.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                TRUNCATION_LOG(@"FALLBACK: Original text='%@', trimmed='%@'", lineWithEllipsis.string, trimmed);
                [lineWithEllipsis replaceCharactersInRange:NSMakeRange(0, lineWithEllipsis.length) withString:trimmed];

                NSAttributedString *ellipsis = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:attributes];
                [lineWithEllipsis appendAttributedString:ellipsis];
                TRUNCATION_LOG(@"FALLBACK: Text with ellipsis='%@'", lineWithEllipsis.string);

                CTLineRef fallbackLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)lineWithEllipsis);
                if (fallbackLine) {
                    // Truncate the fallback line if it's too wide
                    CTLineRef finalLine = CTLineCreateTruncatedLine(fallbackLine, availableWidth, kCTLineTruncationEnd, ellipsisLine);
                    CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
                    if (finalLine) {
                        TRUNCATION_LOG(@"FALLBACK: Drew finalLine (truncated fallback)");
                        CTLineDraw(finalLine, context);
                        CFRelease(finalLine);
                    } else {
                        TRUNCATION_LOG(@"FALLBACK: Drew fallbackLine (untruncated)");
                        CTLineDraw(fallbackLine, context);
                    }
                    CFRelease(fallbackLine);
                } else {
                    // Ultimate fallback: just draw the original line
                    TRUNCATION_LOG(@"FALLBACK: Ultimate fallback - drew original lastVisibleLine");
                    CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
                    CTLineDraw(lastVisibleLine, context);
                }
            }

            CFRelease(continuousLine);
            CFRelease(ellipsisLine);
        } else {
            // Edge case: no remaining text, just draw the line
            CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
            CTLineDraw(lastVisibleLine, context);
        }
    }

    free(lineOrigins);
}

@end
