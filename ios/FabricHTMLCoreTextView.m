#import "FabricHTMLCoreTextView.h"
#import <CoreText/CoreText.h>

/// Custom attribute key to store the detected content type
static NSString *const HTMLDetectedContentTypeKey = @"HTMLDetectedContentType";

@implementation FabricHTMLCoreTextView {
  CTFrameRef _ctFrame;
  NSAttributedString *_processedAttributedText; // With detected links added
  CGFloat _previousContentHeight; // Track height for animation
  BOOL _hasInitializedHeight; // Flag for first layout
#if DEBUG
  NSArray<NSDictionary *> *_debugLineInfo; // Cached debug info for each line
#endif
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.contentMode = UIViewContentModeRedraw;
    _previousContentHeight = 0;
    _hasInitializedHeight = NO;
    _animationDuration = 0.2; // Default animation duration
  }
  return self;
}

- (void)dealloc {
  if (_ctFrame) {
    CFRelease(_ctFrame);
  }
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
  if (_attributedText == attributedText ||
      [_attributedText isEqualToAttributedString:attributedText]) {
    return;
  }
  _attributedText = [attributedText copy];
  _processedAttributedText = [self processAttributedTextWithDetection:_attributedText];
  [self invalidateFrame];
  [self updateAccessibilityForTruncation];
  [self setNeedsDisplay];
}

- (void)setDetectLinks:(BOOL)detectLinks {
  if (_detectLinks == detectLinks) {
    return;
  }
  _detectLinks = detectLinks;
  _processedAttributedText = [self processAttributedTextWithDetection:_attributedText];
  [self invalidateFrame];
  [self setNeedsDisplay];
}

- (void)setDetectPhoneNumbers:(BOOL)detectPhoneNumbers {
  if (_detectPhoneNumbers == detectPhoneNumbers) {
    return;
  }
  _detectPhoneNumbers = detectPhoneNumbers;
  _processedAttributedText = [self processAttributedTextWithDetection:_attributedText];
  [self invalidateFrame];
  [self setNeedsDisplay];
}

- (void)setDetectEmails:(BOOL)detectEmails {
  if (_detectEmails == detectEmails) {
    return;
  }
  _detectEmails = detectEmails;
  _processedAttributedText = [self processAttributedTextWithDetection:_attributedText];
  [self invalidateFrame];
  [self setNeedsDisplay];
}

- (void)setNumberOfLines:(NSInteger)numberOfLines {
  NSLog(@"[FabricHTMLText] setNumberOfLines: %ld -> %ld", (long)_numberOfLines, (long)numberOfLines);
  if (_numberOfLines == numberOfLines) {
    return;
  }
  _numberOfLines = numberOfLines;
  [self updateAccessibilityForTruncation];
  [self setNeedsDisplay];
}

/**
 * Update accessibility label to indicate truncation if content is truncated.
 */
- (void)updateAccessibilityForTruncation {
  if (_numberOfLines > 0 && _attributedText.length > 0) {
    // Create a CTFrame to check if content is truncated
    CTFrameRef frame = [self ctFrame];
    if (frame) {
      CFArrayRef lines = CTFrameGetLines(frame);
      CFIndex lineCount = CFArrayGetCount(lines);

      if (lineCount > _numberOfLines) {
        // Content is truncated
        self.accessibilityHint = NSLocalizedString(@"Content is truncated. Double-tap for more options.", @"Accessibility hint for truncated text");
      } else {
        self.accessibilityHint = nil;
      }
    }
  } else {
    self.accessibilityHint = nil;
  }
}

- (void)setAnimationDuration:(CGFloat)animationDuration {
  if (_animationDuration == animationDuration) {
    return;
  }
  _animationDuration = animationDuration;
}

- (void)setIsRTL:(BOOL)isRTL {
  if (_isRTL == isRTL) {
    return;
  }
  _isRTL = isRTL;
  [self invalidateFrame];
  [self setNeedsDisplay];
}

- (void)setTextAlign:(NSString *)textAlign {
  if (_textAlign == textAlign || [_textAlign isEqualToString:textAlign]) {
    return;
  }
  _textAlign = [textAlign copy];
  [self invalidateFrame];
  [self setNeedsDisplay];
}

/**
 * Process the attributed string to add detected links, emails, and phone numbers.
 */
- (NSAttributedString *)processAttributedTextWithDetection:(NSAttributedString *)attributedText {
  if (!attributedText || attributedText.length == 0) {
    return attributedText;
  }

  // If no detection is enabled, return the original
  if (!_detectLinks && !_detectPhoneNumbers && !_detectEmails) {
    return attributedText;
  }

  NSMutableAttributedString *mutableText = [attributedText mutableCopy];
  NSString *plainText = attributedText.string;

  // Build the data detector types based on enabled detection
  NSTextCheckingTypes checkingTypes = 0;
  if (_detectLinks) {
    checkingTypes |= NSTextCheckingTypeLink;
  }
  if (_detectPhoneNumbers) {
    checkingTypes |= NSTextCheckingTypePhoneNumber;
  }
  // Note: NSDataDetector doesn't have a separate email type; emails are detected as links
  // We'll identify emails by checking if the URL has a mailto: scheme

  if (checkingTypes == 0 && !_detectEmails) {
    return attributedText;
  }

  // If only email detection is enabled, we need to detect links to catch mailto: URLs
  if (_detectEmails && checkingTypes == 0) {
    checkingTypes = NSTextCheckingTypeLink;
  } else if (_detectEmails) {
    checkingTypes |= NSTextCheckingTypeLink;
  }

  NSError *error = nil;
  NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:checkingTypes error:&error];
  if (error) {
    return attributedText;
  }

  NSArray<NSTextCheckingResult *> *matches = [detector matchesInString:plainText
                                                               options:0
                                                                 range:NSMakeRange(0, plainText.length)];

  for (NSTextCheckingResult *match in matches) {
    NSRange range = match.range;

    // Skip if this range already has a link attribute (explicit <a> tag takes precedence)
    id existingLink = [attributedText attribute:NSLinkAttributeName atIndex:range.location effectiveRange:NULL];
    if (existingLink) {
      continue;
    }

    NSURL *url = nil;
    HTMLDetectedContentType contentType = HTMLDetectedContentTypeLink;

    if (match.resultType == NSTextCheckingTypePhoneNumber) {
      if (!_detectPhoneNumbers) {
        continue;
      }
      NSString *phoneNumber = match.phoneNumber;
      if (phoneNumber) {
        // Create tel: URL
        NSString *cleanedPhone = [[phoneNumber componentsSeparatedByCharactersInSet:
                                   [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
        url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", cleanedPhone]];
        contentType = HTMLDetectedContentTypePhone;
      }
    } else if (match.resultType == NSTextCheckingTypeLink) {
      url = match.URL;
      if (url) {
        NSString *scheme = url.scheme.lowercaseString;

        // Validate URL scheme to prevent XSS (e.g., javascript: URLs)
        // Only allow safe schemes: http, https, mailto, tel
        static NSSet *allowedSchemes = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
          allowedSchemes = [NSSet setWithObjects:@"http", @"https", @"mailto", @"tel", nil];
        });

        if (![allowedSchemes containsObject:scheme]) {
          continue;  // Skip potentially dangerous URLs
        }

        // Check if it's an email (mailto:) or a regular link
        if ([scheme isEqualToString:@"mailto"]) {
          if (!_detectEmails) {
            continue;
          }
          contentType = HTMLDetectedContentTypeEmail;
        } else {
          if (!_detectLinks) {
            continue;
          }
          contentType = HTMLDetectedContentTypeLink;
        }
      }
    }

    if (url) {
      [mutableText addAttribute:NSLinkAttributeName value:url range:range];
      [mutableText addAttribute:HTMLDetectedContentTypeKey value:@(contentType) range:range];

      // Add link styling (blue color, underline)
      [mutableText addAttribute:NSForegroundColorAttributeName value:[UIColor systemBlueColor] range:range];
      [mutableText addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
    }
  }

  return mutableText;
}

- (void)setFrame:(CGRect)frame {
  CGRect oldFrame = self.frame;
  [super setFrame:frame];
  if (!CGSizeEqualToSize(oldFrame.size, frame.size)) {
    [self invalidateFrame];
  }
}

- (void)setBounds:(CGRect)bounds {
  CGRect oldBounds = self.bounds;
  [super setBounds:bounds];
  if (!CGSizeEqualToSize(oldBounds.size, bounds.size)) {
    [self invalidateFrame];
  }
}

- (void)invalidateFrame {
  if (_ctFrame) {
    CFRelease(_ctFrame);
    _ctFrame = NULL;
  }
#if DEBUG
  _debugLineInfo = nil;
#endif
}

- (CTFrameRef)ctFrame {
  NSAttributedString *textToRender = _processedAttributedText ?: _attributedText;
  if (!_ctFrame && textToRender.length > 0) {
    // Apply base writing direction if RTL
    NSAttributedString *directedText = textToRender;
    if (_isRTL) {
      directedText = [self applyBaseWritingDirection:textToRender isRTL:YES];
    }

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(
        (__bridge CFAttributedStringRef)directedText);

    CGRect bounds = self.bounds;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, bounds);

    _ctFrame =
        CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);

    CGPathRelease(path);
    CFRelease(framesetter);
  }
  return _ctFrame;
}

/**
 * Apply base writing direction to attributed string via paragraph style.
 * Sets NSWritingDirection on the paragraph style for the entire string.
 *
 * Text alignment behavior in RTL mode:
 * - "left" → NSTextAlignmentRight (start of RTL text)
 * - "right" → NSTextAlignmentLeft (end of RTL text)
 * - "center" → NSTextAlignmentCenter (unchanged)
 * - "justify" → NSTextAlignmentJustified (unchanged)
 * - nil/natural → NSTextAlignmentRight (default for RTL)
 */
- (NSAttributedString *)applyBaseWritingDirection:(NSAttributedString *)attributedText isRTL:(BOOL)isRTL {
  if (!attributedText || attributedText.length == 0) {
    return attributedText;
  }

  NSMutableAttributedString *mutableText = [attributedText mutableCopy];
  NSRange fullRange = NSMakeRange(0, mutableText.length);

  // Determine text alignment based on textAlign prop and RTL mode
  // In RTL mode, "left" and "right" are swapped to maintain semantic meaning
  // (left = start, right = end)
  NSTextAlignment alignment = NSTextAlignmentNatural;
  if (_textAlign) {
    if ([_textAlign isEqualToString:@"center"]) {
      alignment = NSTextAlignmentCenter;
    } else if ([_textAlign isEqualToString:@"justify"]) {
      alignment = NSTextAlignmentJustified;
    } else if ([_textAlign isEqualToString:@"left"]) {
      // In RTL mode, "left" means "start" which is right-aligned
      alignment = isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;
    } else if ([_textAlign isEqualToString:@"right"]) {
      // In RTL mode, "right" means "end" which is left-aligned
      alignment = isRTL ? NSTextAlignmentLeft : NSTextAlignmentRight;
    }
  } else if (isRTL) {
    // Default for RTL text with no explicit alignment
    alignment = NSTextAlignmentRight;
  }

  // Get or create paragraph style for the full range
  [mutableText enumerateAttribute:NSParagraphStyleAttributeName
                          inRange:fullRange
                          options:0
                       usingBlock:^(id value, NSRange range, BOOL *stop) {
    NSMutableParagraphStyle *style;
    if (value) {
      style = [value mutableCopy];
    } else {
      style = [[NSMutableParagraphStyle alloc] init];
    }

    // Set base writing direction
    style.baseWritingDirection = isRTL ? NSWritingDirectionRightToLeft : NSWritingDirectionLeftToRight;

    // Apply alignment (natural will use the computed alignment above)
    if (alignment != NSTextAlignmentNatural) {
      style.alignment = alignment;
    } else if (isRTL && style.alignment == NSTextAlignmentNatural) {
      style.alignment = NSTextAlignmentRight;
    }

    [mutableText addAttribute:NSParagraphStyleAttributeName value:style range:range];
  }];

  // If no paragraph style was set on any range, apply to full range
  id existingStyle = [mutableText attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
  if (!existingStyle) {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.baseWritingDirection = isRTL ? NSWritingDirectionRightToLeft : NSWritingDirectionLeftToRight;
    if (alignment != NSTextAlignmentNatural) {
      style.alignment = alignment;
    } else if (isRTL) {
      style.alignment = NSTextAlignmentRight;
    }
    [mutableText addAttribute:NSParagraphStyleAttributeName value:style range:fullRange];
  }

  return mutableText;
}

#if DEBUG
// Set to YES to enable debug visualization of line bounds
static BOOL kDebugDrawLineBounds = NO;
#endif

- (void)drawRect:(CGRect)rect {
  NSLog(@"[FabricHTMLText] drawRect called, numberOfLines=%ld, textLength=%lu",
        (long)_numberOfLines, (unsigned long)_attributedText.length);

  if (_attributedText.length == 0) {
    NSLog(@"[FabricHTMLText] drawRect: empty text, returning");
    return;
  }

  CGContextRef context = UIGraphicsGetCurrentContext();
  if (!context) {
    NSLog(@"[FabricHTMLText] drawRect: no context, returning");
    return;
  }

  // CoreText uses a flipped coordinate system (origin at bottom-left)
  // UIKit uses origin at top-left, so we need to flip
  CGContextSaveGState(context);
  CGContextTranslateCTM(context, 0, self.bounds.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);

  CTFrameRef frame = [self ctFrame];
  if (frame) {
    // Check if we need to apply numberOfLines truncation
    if (_numberOfLines > 0) {
      NSLog(@"[FabricHTMLText] drawRect: calling drawTruncatedFrame with maxLines=%ld", (long)_numberOfLines);
      [self drawTruncatedFrame:frame inContext:context maxLines:_numberOfLines];
    } else {
      NSLog(@"[FabricHTMLText] drawRect: no truncation, calling CTFrameDraw");
      CTFrameDraw(frame, context);
    }

#if DEBUG
    // Debug: draw bounding boxes around each line
    if (kDebugDrawLineBounds) {
      [self drawDebugLineBounds:frame inContext:context];
    }
#endif
  }

  CGContextRestoreGState(context);
}

/**
 * Draw the frame with truncation at the specified number of lines.
 * If the content exceeds maxLines, the last visible line is truncated with ellipsis.
 */
- (void)drawTruncatedFrame:(CTFrameRef)frame inContext:(CGContextRef)context maxLines:(NSInteger)maxLines {
  CFArrayRef lines = CTFrameGetLines(frame);
  CFIndex lineCount = CFArrayGetCount(lines);

  NSAttributedString *textToRender = _processedAttributedText ?: _attributedText;
  NSUInteger totalTextLength = textToRender.length;

  // Check if there's text beyond what's visible in the frame.
  // The shadow node constrains the frame height, so lineCount may equal maxLines
  // even when there's more content. We detect this by checking visible range.
  CFRange visibleRange = CTFrameGetVisibleStringRange(frame);
  BOOL hasMoreContent = (visibleRange.location + visibleRange.length) < (CFIndex)totalTextLength;

  NSLog(@"[FabricHTMLText] drawTruncatedFrame: maxLines=%ld, lineCount=%ld, boundsWidth=%.1f",
        (long)maxLines, (long)lineCount, self.bounds.size.width);
  NSLog(@"[FabricHTMLText] visibleRange: loc=%ld len=%ld, totalLength=%lu, hasMoreContent=%d",
        (long)visibleRange.location, (long)visibleRange.length, (unsigned long)totalTextLength, hasMoreContent);

  if (lineCount == 0) {
    NSLog(@"[FabricHTMLText] No lines to draw, returning");
    return;
  }

  // If all content is visible, draw normally (no truncation needed)
  if (!hasMoreContent) {
    NSLog(@"[FabricHTMLText] All content visible, drawing normally");
    CTFrameDraw(frame, context);
    return;
  }

  NSLog(@"[FabricHTMLText] Content is truncated, will add ellipsis");

  // Get line origins for all lines
  CGPoint *lineOrigins = malloc(sizeof(CGPoint) * lineCount);
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
    CGFloat availableWidth = self.bounds.size.width;

    // Get the string range of the last visible line
    CFRange lastLineRange = CTLineGetStringRange(lastVisibleLine);
    NSAttributedString *textToRender = _processedAttributedText ?: _attributedText;
    NSUInteger startLocation = (NSUInteger)lastLineRange.location;

    if (startLocation < textToRender.length) {
      // Get all remaining text from this line to end of content
      NSRange remainingRange = NSMakeRange(startLocation, textToRender.length - startLocation);
      NSAttributedString *remainingText = [textToRender attributedSubstringFromRange:remainingRange];

      NSLog(@"[FabricHTMLText] Last line range: loc=%lu len=%ld, remaining text length=%lu",
            (unsigned long)startLocation, (long)lastLineRange.length, (unsigned long)remainingText.length);
      NSLog(@"[FabricHTMLText] Remaining text (first 100 chars): '%@'",
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

      NSLog(@"[FabricHTMLText] Continuous text (first 100 chars): '%@'",
            [continuousText.string substringToIndex:MIN(100, continuousText.string.length)]);

      // Create a line from the continuous text
      CTLineRef continuousLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)continuousText);

      // Get the width of the continuous line
      CGFloat continuousLineWidth = CTLineGetTypographicBounds(continuousLine, NULL, NULL, NULL);
      NSLog(@"[FabricHTMLText] Continuous line width=%.1f, available width=%.1f, needs truncation=%d",
            continuousLineWidth, availableWidth, continuousLineWidth > availableWidth);

      // Create the truncation token (ellipsis) with matching attributes
      NSDictionary *attributes = [self attributesForTruncationToken:lastVisibleLine];
      NSLog(@"[FabricHTMLText] Ellipsis attributes: %@", attributes);
      NSAttributedString *ellipsisString = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:attributes];
      CTLineRef ellipsisLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)ellipsisString);

      // Create a truncated line
      CTLineRef truncatedLine = CTLineCreateTruncatedLine(continuousLine, availableWidth, kCTLineTruncationEnd, ellipsisLine);

      NSLog(@"[FabricHTMLText] CTLineCreateTruncatedLine result: %@", truncatedLine ? @"SUCCESS" : @"NULL");

      if (truncatedLine) {
        CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
        CTLineDraw(truncatedLine, context);
        NSLog(@"[FabricHTMLText] Drew truncated line at origin (%.1f, %.1f)", lastOrigin.x, lastOrigin.y);
        CFRelease(truncatedLine);
      } else {
        // CTLineCreateTruncatedLine returns NULL if line fits - but we know there's more content.
        // Manually append ellipsis to indicate truncation.
        NSLog(@"[FabricHTMLText] FALLBACK: CTLineCreateTruncatedLine returned NULL, manually appending ellipsis");

        NSMutableAttributedString *lineWithEllipsis = [[textToRender attributedSubstringFromRange:
            NSMakeRange(startLocation, MIN((NSUInteger)lastLineRange.length, textToRender.length - startLocation))] mutableCopy];

        // Trim trailing whitespace/newlines and append ellipsis
        NSString *trimmed = [lineWithEllipsis.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSLog(@"[FabricHTMLText] FALLBACK: Original text='%@', trimmed='%@'", lineWithEllipsis.string, trimmed);
        [lineWithEllipsis replaceCharactersInRange:NSMakeRange(0, lineWithEllipsis.length) withString:trimmed];

        NSAttributedString *ellipsis = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:attributes];
        [lineWithEllipsis appendAttributedString:ellipsis];
        NSLog(@"[FabricHTMLText] FALLBACK: Text with ellipsis='%@'", lineWithEllipsis.string);

        CTLineRef fallbackLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)lineWithEllipsis);
        if (fallbackLine) {
          // Truncate the fallback line if it's too wide
          CTLineRef finalLine = CTLineCreateTruncatedLine(fallbackLine, availableWidth, kCTLineTruncationEnd, ellipsisLine);
          CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
          if (finalLine) {
            NSLog(@"[FabricHTMLText] FALLBACK: Drew finalLine (truncated fallback)");
            CTLineDraw(finalLine, context);
            CFRelease(finalLine);
          } else {
            NSLog(@"[FabricHTMLText] FALLBACK: Drew fallbackLine (untruncated)");
            CTLineDraw(fallbackLine, context);
          }
          CFRelease(fallbackLine);
        } else {
          // Ultimate fallback: just draw the original line
          NSLog(@"[FabricHTMLText] FALLBACK: Ultimate fallback - drew original lastVisibleLine");
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

#if DEBUG
- (void)drawDebugLineBounds:(CTFrameRef)frame inContext:(CGContextRef)context {
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
      [[UIColor colorWithRed:0.0 green:0.8 blue:0.0
                       alpha:0.2] CGColor], // Green
      [[UIColor colorWithRed:1.0 green:0.5 blue:0.0
                       alpha:0.2] CGColor], // Orange
  };

  NSLog(@"[DEBUG] Total lines: %ld, bounds height: %.1f", (long)lineCount,
        self.bounds.size.height);

  NSMutableArray *lineInfoArray = [NSMutableArray arrayWithCapacity:lineCount];

  for (CFIndex i = 0; i < lineCount; i++) {
    CTLineRef line = CFArrayGetValueAtIndex(lines, i);
    CGPoint origin = lineOrigins[i];

    CGFloat ascent, descent, leading;
    CGFloat lineWidth =
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

    // Line rect in CoreText coordinates (for hit testing, convert to UIKit
    // coords)
    CGRect lineRectCT =
        CGRectMake(origin.x, origin.y - descent, lineWidth, ascent + descent);

    // Convert to UIKit coordinates for hit testing
    CGRect lineRectUIKit =
        CGRectMake(origin.x, self.bounds.size.height - origin.y - ascent,
                   lineWidth, ascent + descent);

    // Get the string range for this line
    CFRange stringRange = CTLineGetStringRange(line);
    NSRange nsRange = NSMakeRange(stringRange.location, stringRange.length);
    NSString *lineText = [_attributedText.string substringWithRange:nsRange];
    NSString *escapedText =
        [lineText stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];

    // Collect paragraph style info
    NSMutableString *styleInfo = [NSMutableString string];
    [_attributedText
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:nsRange
                   options:0
                usingBlock:^(id value, NSRange range, BOOL *stop) {
                  NSString *rangeText =
                      [self->_attributedText.string substringWithRange:range];
                  rangeText =
                      [rangeText stringByReplacingOccurrencesOfString:@"\n"
                                                           withString:@"\\n"];
                  if ([value isKindOfClass:[NSParagraphStyle class]]) {
                    NSParagraphStyle *style = (NSParagraphStyle *)value;
                    [styleInfo
                        appendFormat:@"  [%lu-%lu] '%@'\n    headIndent=%.1f "
                                     @"firstLine=%.1f\n    spacing=%.1f "
                                     @"spacingBefore=%.1f\n",
                                     (unsigned long)range.location,
                                     (unsigned long)(range.location +
                                                     range.length - 1),
                                     rangeText, style.headIndent,
                                     style.firstLineHeadIndent,
                                     style.paragraphSpacing,
                                     style.paragraphSpacingBefore];
                  } else {
                    [styleInfo
                        appendFormat:@"  [%lu-%lu] '%@' NO PARAGRAPH STYLE\n",
                                     (unsigned long)range.location,
                                     (unsigned long)(range.location +
                                                     range.length - 1),
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
}
#endif

#pragma mark - Touch Handling for Links

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  CGPoint point = [touch locationInView:self];

#if DEBUG
  // Debug mode: show line info when tapped
  if (kDebugDrawLineBounds) {
    NSDictionary *lineInfo = [self debugLineInfoAtPoint:point];
    if (lineInfo) {
      [self showDebugAlertForLineInfo:lineInfo];
      return;
    }
  }
#endif

  HTMLDetectedContentType detectedType = HTMLDetectedContentTypeLink;
  NSURL *url = [self linkAtPoint:point detectedType:&detectedType];
  if (url && [self.delegate respondsToSelector:@selector(coreTextView:didTapLinkWithURL:type:)]) {
    [self.delegate coreTextView:self didTapLinkWithURL:url type:detectedType];
  } else {
    [super touchesEnded:touches withEvent:event];
  }
}

#if DEBUG
- (NSDictionary *)debugLineInfoAtPoint:(CGPoint)point {
  for (NSDictionary *info in _debugLineInfo) {
    CGRect rect = [info[@"rect"] CGRectValue];
    // Expand rect slightly for easier tapping
    CGRect expandedRect = CGRectInset(rect, -5, -5);
    if (CGRectContainsPoint(expandedRect, point)) {
      return info;
    }
  }
  return nil;
}

- (void)showDebugAlertForLineInfo:(NSDictionary *)info {
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
  UIViewController *presenter = [self findViewController];
  if (presenter) {
    [presenter presentViewController:alert animated:YES completion:nil];
  } else {
    NSLog(@"[DEBUG] Could not find view controller to present alert. Info:\n%@",
          message);
  }
}

- (UIViewController *)findViewController {
  UIResponder *responder = self;
  while (responder) {
    if ([responder isKindOfClass:[UIViewController class]]) {
      return (UIViewController *)responder;
    }
    responder = [responder nextResponder];
  }
  return nil;
}
#endif

- (NSURL *)linkAtPoint:(CGPoint)point detectedType:(HTMLDetectedContentType *)outType {
  CTFrameRef frame = [self ctFrame];
  if (!frame) {
    return nil;
  }

  NSAttributedString *textToCheck = _processedAttributedText ?: _attributedText;
  if (!textToCheck || textToCheck.length == 0) {
    return nil;
  }

  // Convert point to CoreText coordinate system (flip Y)
  CGPoint ctPoint = CGPointMake(point.x, self.bounds.size.height - point.y);

  CFArrayRef lines = CTFrameGetLines(frame);
  CFIndex lineCount = CFArrayGetCount(lines);

  if (lineCount == 0) {
    return nil;
  }

  CGPoint *lineOrigins = malloc(sizeof(CGPoint) * lineCount);
  CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);

  NSURL *foundURL = nil;

  for (CFIndex i = 0; i < lineCount; i++) {
    CTLineRef line = CFArrayGetValueAtIndex(lines, i);
    CGPoint lineOrigin = lineOrigins[i];

    // Get line bounds
    CGFloat ascent, descent, leading;
    CGFloat lineWidth =
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

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
            charIndex < (CFIndex)textToCheck.length) {
          // Check for link attribute at this index
          id linkValue = [textToCheck attribute:NSLinkAttributeName
                                        atIndex:charIndex
                                 effectiveRange:NULL];
          if (linkValue) {
            if ([linkValue isKindOfClass:[NSURL class]]) {
              foundURL = linkValue;
            } else if ([linkValue isKindOfClass:[NSString class]]) {
              foundURL = [NSURL URLWithString:linkValue];
            }

            // Get the detected content type if available
            if (outType) {
              NSNumber *typeValue = [textToCheck attribute:HTMLDetectedContentTypeKey
                                                   atIndex:charIndex
                                            effectiveRange:NULL];
              if (typeValue) {
                *outType = (HTMLDetectedContentType)[typeValue integerValue];
              } else {
                // Default to link for explicit <a> tags (no HTMLDetectedContentTypeKey)
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
