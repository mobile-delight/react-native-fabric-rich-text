#import "FabricHTMLCoreTextView.h"
#import "FabricHTMLLinkAccessibilityElement.h"
#import <CoreText/CoreText.h>

/// Custom attribute key to store the detected content type
static NSString *const HTMLDetectedContentTypeKey = @"HTMLDetectedContentType";

#pragma mark - Dynamic Text Accessibility Element

/**
 * Simple accessibility element that dynamically computes its frame.
 * Used for the text content element so its frame stays accurate
 * when the view moves (scrolling, layout changes, etc.).
 *
 * This follows the same pattern as FabricHTMLLinkAccessibilityElement.
 */
@interface FabricHTMLDynamicTextAccessibilityElement : UIAccessibilityElement
@property (nonatomic, weak) UIView *containerView;
@end

@implementation FabricHTMLDynamicTextAccessibilityElement

- (CGRect)accessibilityFrame
{
    if (self.containerView) {
        // Use the container view's full bounds for the text element
        return UIAccessibilityConvertFrameToScreenCoordinates(self.containerView.bounds, self.containerView);
    }
    return [super accessibilityFrame];
}

@end

/// Accessibility debug logging - set to 0 for production
#define A11Y_DEBUG 1

#if A11Y_DEBUG
#define A11Y_LOG(fmt, ...) NSLog(@"[A11Y_FHTMLCTV] " fmt, ##__VA_ARGS__)
#else
#define A11Y_LOG(fmt, ...) do { } while(0)
#endif

@implementation FabricHTMLCoreTextView {
  CTFrameRef _ctFrame;
  NSAttributedString *_processedAttributedText; // With detected links added
  CGFloat _previousContentHeight; // Track height for animation
  BOOL _hasInitializedHeight; // Flag for first layout
  NSArray<FabricHTMLLinkAccessibilityElement *> *_accessibilityElements; // Cached accessibility elements
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
      A11Y_LOG(@"PHONE DETECTION: matched phone='%@' at range=(%lu, %lu)",
               phoneNumber, (unsigned long)range.location, (unsigned long)range.length);
      if (phoneNumber) {
        // Create tel: URL - remove all non-digit characters, keep + for international
        NSMutableCharacterSet *allowedChars = [NSMutableCharacterSet decimalDigitCharacterSet];
        [allowedChars addCharactersInString:@"+"];
        NSString *cleanedPhone = [[phoneNumber componentsSeparatedByCharactersInSet:
                                   [allowedChars invertedSet]] componentsJoinedByString:@""];

        if (cleanedPhone.length > 0) {
          // URL-encode the phone number to handle any edge cases
          NSString *encodedPhone = [cleanedPhone stringByAddingPercentEncodingWithAllowedCharacters:
                                    [NSCharacterSet URLPathAllowedCharacterSet]];
          NSString *telString = [NSString stringWithFormat:@"tel:%@", encodedPhone ?: cleanedPhone];
          url = [NSURL URLWithString:telString];
          contentType = HTMLDetectedContentTypePhone;
          A11Y_LOG(@"PHONE DETECTION: created tel URL='%@' from cleaned='%@'", url, cleanedPhone);

          if (!url) {
            A11Y_LOG(@"PHONE DETECTION: WARNING - failed to create URL from telString='%@'", telString);
          }
        } else {
          A11Y_LOG(@"PHONE DETECTION: WARNING - cleaned phone number is empty for input='%@'", phoneNumber);
        }
      } else {
        A11Y_LOG(@"PHONE DETECTION: WARNING - phone number is nil!");
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
            A11Y_LOG(@"EMAIL DETECTION: found mailto: but detectEmails=NO, skipping");
            continue;
          }
          contentType = HTMLDetectedContentTypeEmail;
          A11Y_LOG(@"EMAIL DETECTION: detected email='%@'", url.absoluteString);
        } else {
          if (!_detectLinks) {
            continue;
          }
          contentType = HTMLDetectedContentTypeLink;
          A11Y_LOG(@"LINK DETECTION: detected link='%@'", url.absoluteString);
        }
      }
    }

    if (url) {
      [mutableText addAttribute:NSLinkAttributeName value:url range:range];
      [mutableText addAttribute:HTMLDetectedContentTypeKey value:@(contentType) range:range];

      // Add link styling (blue color, underline)
      [mutableText addAttribute:NSForegroundColorAttributeName value:[UIColor systemBlueColor] range:range];
      [mutableText addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];

      NSString *matchedText = [plainText substringWithRange:range];
      A11Y_LOG(@"DETECTION: Added %@ link '%@' -> '%@'",
               contentType == HTMLDetectedContentTypePhone ? @"PHONE" :
               contentType == HTMLDetectedContentTypeEmail ? @"EMAIL" : @"WEB",
               matchedText, url.absoluteString);
    } else {
      A11Y_LOG(@"DETECTION WARNING: URL is nil for match at range=(%lu, %lu)",
               (unsigned long)range.location, (unsigned long)range.length);
    }
  }

  A11Y_LOG(@"DETECTION COMPLETE: Total matches processed=%lu", (unsigned long)matches.count);
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

- (void)layoutSubviews {
  [super layoutSubviews];
  // Notify VoiceOver that accessibility frames may have changed
  // This is important because our accessibility elements compute their frames
  // dynamically based on the view's current position. When the view moves
  // (e.g., due to scrolling, keyboard appearing, or layout changes), VoiceOver
  // needs to know to re-query the accessibility frames.
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
  }
}

- (void)invalidateFrame {
  if (_ctFrame) {
    CFRelease(_ctFrame);
    _ctFrame = NULL;
  }
  _accessibilityElements = nil; // Invalidate accessibility elements when layout changes
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

#pragma mark - Accessibility Link Support

/**
 * Returns all link ranges in the attributed text.
 * A link is identified by the NSLinkAttributeName attribute.
 */
- (NSArray<NSValue *> *)allLinkRanges {
  NSAttributedString *textToCheck = _processedAttributedText ?: _attributedText;
  if (!textToCheck || textToCheck.length == 0) {
    return @[];
  }

  NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
  [textToCheck enumerateAttribute:NSLinkAttributeName
                          inRange:NSMakeRange(0, textToCheck.length)
                          options:0
                       usingBlock:^(id value, NSRange range, BOOL *stop) {
    if (value) {
      [ranges addObject:[NSValue valueWithRange:range]];
    }
  }];

  return ranges;
}

/**
 * Returns the line number (0-based) for a character at the given index.
 */
- (NSInteger)lineForCharacterAtIndex:(NSUInteger)charIndex {
  CTFrameRef frame = [self ctFrame];
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

- (NSInteger)visibleLinkCount {
  NSArray<NSValue *> *allLinks = [self allLinkRanges];
  if (allLinks.count == 0) {
    return 0;
  }

  // If no truncation, all links are visible
  if (_numberOfLines <= 0) {
    return (NSInteger)allLinks.count;
  }

  CTFrameRef frame = [self ctFrame];
  if (!frame) {
    return 0;
  }

  CFArrayRef lines = CTFrameGetLines(frame);
  CFIndex lineCount = CFArrayGetCount(lines);
  NSInteger visibleLines = MIN(lineCount, _numberOfLines);

  // Count links that start on visible lines
  NSInteger count = 0;
  for (NSValue *rangeValue in allLinks) {
    NSRange linkRange = rangeValue.rangeValue;
    NSInteger linkLine = [self lineForCharacterAtIndex:linkRange.location];

    if (linkLine >= 0 && linkLine < visibleLines) {
      count++;
    }
  }

  return count;
}

- (CGRect)boundsForLinkAtIndex:(NSUInteger)index {
  A11Y_LOG(@"boundsForLinkAtIndex:%lu - view.bounds=%@", (unsigned long)index, NSStringFromCGRect(self.bounds));
  NSArray<NSValue *> *allLinks = [self allLinkRanges];
  if (index >= allLinks.count) {
    A11Y_LOG(@"boundsForLinkAtIndex: index out of range");
    return CGRectZero;
  }

  CTFrameRef frame = [self ctFrame];
  if (!frame) {
    A11Y_LOG(@"boundsForLinkAtIndex: no CTFrame");
    return CGRectZero;
  }

  // Note: We use self.bounds for coordinate transformations to match the debug rendering
  // approach, which correctly displays link bounds
  A11Y_LOG(@"boundsForLinkAtIndex: viewBounds=%@", NSStringFromCGRect(self.bounds));

  NSRange linkRange = allLinks[index].rangeValue;
  CFArrayRef lines = CTFrameGetLines(frame);
  CFIndex lineCount = CFArrayGetCount(lines);
  A11Y_LOG(@"boundsForLinkAtIndex: linkRange=(%lu, %lu), lineCount=%ld",
           (unsigned long)linkRange.location, (unsigned long)linkRange.length, (long)lineCount);

  if (lineCount == 0) {
    return CGRectZero;
  }

  // Get line origins - these are in CoreText coordinates (origin at bottom-left of frame)
  // relative to the frame path bounds, not the view bounds
  CGPoint *lineOrigins = malloc(sizeof(CGPoint) * lineCount);
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
    // Use self.bounds.size.height directly, matching the debug rendering approach
    // that correctly displays the link bounds
    CGFloat lineTop = self.bounds.size.height - lineOrigin.y - ascent;
    CGFloat lineHeight = ascent + descent;

    A11Y_LOG(@"boundsForLinkAtIndex: line[%ld] origin=(%f,%f) ascent=%f descent=%f leading=%f -> lineTop=%f",
             (long)i, lineOrigin.x, lineOrigin.y, ascent, descent, leading, lineTop);
    A11Y_LOG(@"boundsForLinkAtIndex: line[%ld] startOffset=%f endOffset=%f",
             (long)i, startOffset, endOffset);

    CGRect lineBounds = CGRectMake(
      lineOrigin.x + startOffset,
      lineTop,
      endOffset - startOffset,
      lineHeight
    );
    A11Y_LOG(@"boundsForLinkAtIndex: line[%ld] lineBounds=%@", (long)i, NSStringFromCGRect(lineBounds));

    if (CGRectIsNull(bounds)) {
      bounds = lineBounds;
    } else {
      bounds = CGRectUnion(bounds, lineBounds);
    }
  }

  free(lineOrigins);

  A11Y_LOG(@"boundsForLinkAtIndex:%lu RESULT=%@", (unsigned long)index, NSStringFromCGRect(bounds));
  return CGRectIsNull(bounds) ? CGRectZero : bounds;
}

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

#pragma mark - UIAccessibilityContainer Protocol

/**
 * Build and cache accessibility elements for text content and links.
 * This is called lazily when VoiceOver requests accessibility information.
 *
 * The first element is always the text content (so VoiceOver reads the full text),
 * followed by individual link elements for navigation.
 */
- (void)buildAccessibilityElementsIfNeeded {
  if (_accessibilityElements) {
    A11Y_LOG(@"buildAccessibilityElementsIfNeeded: using cached elements (count=%lu)", (unsigned long)_accessibilityElements.count);
    return; // Already built
  }

  NSInteger linkCount = self.visibleLinkCount;
  A11Y_LOG(@"buildAccessibilityElementsIfNeeded: linkCount=%ld", (long)linkCount);
  if (linkCount == 0) {
    _accessibilityElements = @[];
    A11Y_LOG(@"buildAccessibilityElementsIfNeeded: no links, returning empty array");
    return;
  }

  NSAttributedString *textToCheck = _processedAttributedText ?: _attributedText;
  A11Y_LOG(@"buildAccessibilityElementsIfNeeded: text='%@'", [textToCheck.string substringToIndex:MIN(50, textToCheck.string.length)]);

  // First element: the full text content so VoiceOver announces it
  NSMutableArray *elements = [NSMutableArray arrayWithCapacity:linkCount + 1];

  // Use dynamic text element that computes accessibilityFrame on-demand
  // This ensures the frame stays accurate when the view moves (scrolling, layout changes, etc.)
  FabricHTMLDynamicTextAccessibilityElement *textElement = [[FabricHTMLDynamicTextAccessibilityElement alloc] initWithAccessibilityContainer:self];
  textElement.containerView = self;
  // Use resolved accessibility label (built by C++ parser with proper pauses for list items)
  NSString *a11yLabel = _resolvedAccessibilityLabel;
  if (!a11yLabel || a11yLabel.length == 0) {
    a11yLabel = textToCheck.string;
  }
  textElement.accessibilityLabel = a11yLabel;
  textElement.accessibilityTraits = UIAccessibilityTraitStaticText;
  // Note: accessibilityFrame is now computed dynamically in the getter
  A11Y_LOG(@"TEXT ELEMENT: label='%@...', bounds=%@", [a11yLabel substringToIndex:MIN(30, a11yLabel.length)], NSStringFromCGRect(self.bounds));
  // No hint needed - VoiceOver navigation is standard behavior

  [elements addObject:textElement];
  NSArray<NSValue *> *allLinks = [self allLinkRanges];
  A11Y_LOG(@"buildAccessibilityElementsIfNeeded: found %lu link ranges", (unsigned long)allLinks.count);

  for (NSUInteger i = 0; i < (NSUInteger)linkCount && i < allLinks.count; i++) {
    NSRange linkRange = allLinks[i].rangeValue;
    A11Y_LOG(@"LINK[%lu] range: loc=%lu, len=%lu", (unsigned long)i, (unsigned long)linkRange.location, (unsigned long)linkRange.length);

    // Get the URL and content type for this link
    NSURL *url = nil;
    HTMLDetectedContentType contentType = HTMLDetectedContentTypeLink;

    id linkValue = [textToCheck attribute:NSLinkAttributeName atIndex:linkRange.location effectiveRange:NULL];
    A11Y_LOG(@"LINK[%lu] NSLinkAttributeName value: %@ (class: %@)",
             (unsigned long)i, linkValue, NSStringFromClass([linkValue class]));

    if ([linkValue isKindOfClass:[NSURL class]]) {
      url = linkValue;
    } else if ([linkValue isKindOfClass:[NSString class]]) {
      url = [NSURL URLWithString:linkValue];
      A11Y_LOG(@"LINK[%lu] Converted string '%@' to URL: %@", (unsigned long)i, linkValue, url);
    }

    // First check for explicit content type attribute (from auto-detection)
    NSNumber *typeValue = [textToCheck attribute:HTMLDetectedContentTypeKey atIndex:linkRange.location effectiveRange:NULL];
    if (typeValue) {
      contentType = (HTMLDetectedContentType)[typeValue integerValue];
      A11Y_LOG(@"LINK[%lu] Found HTMLDetectedContentTypeKey: %ld", (unsigned long)i, (long)contentType);
    } else if (url) {
      // Infer content type from URL scheme
      NSString *scheme = url.scheme.lowercaseString;
      A11Y_LOG(@"LINK[%lu] URL scheme: '%@'", (unsigned long)i, scheme);

      if ([scheme isEqualToString:@"mailto"]) {
        contentType = HTMLDetectedContentTypeEmail;
        A11Y_LOG(@"LINK[%lu] Detected as EMAIL from mailto: scheme", (unsigned long)i);
      } else if ([scheme isEqualToString:@"tel"]) {
        contentType = HTMLDetectedContentTypePhone;
        A11Y_LOG(@"LINK[%lu] Detected as PHONE from tel: scheme", (unsigned long)i);
      } else {
        A11Y_LOG(@"LINK[%lu] Using default contentType=LINK for scheme '%@'", (unsigned long)i, scheme);
      }
    } else {
      A11Y_LOG(@"LINK[%lu] WARNING: No URL found for link!", (unsigned long)i);
    }

    // Get the link text
    NSString *linkText = [textToCheck.string substringWithRange:linkRange];
    A11Y_LOG(@"LINK[%lu] text='%@', url='%@', type=%ld", (unsigned long)i, linkText, url.absoluteString, (long)contentType);

    // Get the bounds for this link in view coordinates
    CGRect linkBounds = [self boundsForLinkAtIndex:i];
    A11Y_LOG(@"LINK[%lu] bounds: local=%@", (unsigned long)i, NSStringFromCGRect(linkBounds));

    // Create the accessibility element with local bounds
    // The element will dynamically convert to screen coordinates when VoiceOver requests
    // the accessibilityFrame. This ensures the frame stays accurate even when the view
    // moves (scrolling, layout changes, keyboard appearing, etc.)
    FabricHTMLLinkAccessibilityElement *element = [[FabricHTMLLinkAccessibilityElement alloc]
      initWithAccessibilityContainer:self
                           linkIndex:i
                      totalLinkCount:(NSUInteger)linkCount
                                 url:url ?: [NSURL URLWithString:@""]
                         contentType:contentType
                            linkText:linkText
                        boundingRect:linkBounds
                       containerView:self];

    [elements addObject:element];
    A11Y_LOG(@"LINK[%lu] created element with label='%@'", (unsigned long)i, element.accessibilityLabel);
  }

  _accessibilityElements = [elements copy];
  A11Y_LOG(@"buildAccessibilityElementsIfNeeded: COMPLETE - created %lu elements (1 text + %ld links)", (unsigned long)_accessibilityElements.count, (long)linkCount);
}

/**
 * Returns YES if this view should NOT be treated as a single accessibility element.
 * When links are present, VoiceOver should navigate through the individual links.
 */
- (BOOL)isAccessibilityElement {
  NSInteger linkCount = self.visibleLinkCount;
  BOOL isElement = (linkCount == 0);
  A11Y_LOG(@"isAccessibilityElement: linkCount=%ld, returning %@", (long)linkCount, isElement ? @"YES" : @"NO");
  // When there are links, this is a container (not an element itself)
  // When there are no links, this is a regular accessibility element
  return isElement;
}

/**
 * Returns the text content for VoiceOver to announce when this view is a single element.
 * Uses resolvedAccessibilityLabel if set (from C++ parser), otherwise falls back to plain text.
 */
- (NSString *)accessibilityLabel {
  NSString *label = _resolvedAccessibilityLabel;
  if (!label || label.length == 0) {
    // Fallback to plain text if no resolved label
    NSAttributedString *textToCheck = _processedAttributedText ?: _attributedText;
    label = textToCheck.string;
  }
  A11Y_LOG(@"accessibilityLabel: '%@...'", [label substringToIndex:MIN(30, label.length)]);
  return label;
}

/**
 * Returns static text traits for this view when it's a single element.
 */
- (UIAccessibilityTraits)accessibilityTraits {
  A11Y_LOG(@"accessibilityTraits: returning UIAccessibilityTraitStaticText");
  return UIAccessibilityTraitStaticText;
}

/**
 * Returns the number of accessibility elements (links) in this container.
 */
- (NSInteger)accessibilityElementCount {
  [self buildAccessibilityElementsIfNeeded];
  A11Y_LOG(@"accessibilityElementCount: returning %ld", (long)_accessibilityElements.count);
  return (NSInteger)_accessibilityElements.count;
}

/**
 * Returns the accessibility element at the given index.
 */
- (id)accessibilityElementAtIndex:(NSInteger)index {
  [self buildAccessibilityElementsIfNeeded];

  if (index < 0 || index >= (NSInteger)_accessibilityElements.count) {
    A11Y_LOG(@">>> accessibilityElementAtIndex:%ld - OUT OF BOUNDS (count=%ld)", (long)index, (long)_accessibilityElements.count);
    return nil;
  }

  id element = _accessibilityElements[(NSUInteger)index];
  if ([element isKindOfClass:[FabricHTMLLinkAccessibilityElement class]]) {
    FabricHTMLLinkAccessibilityElement *linkElement = (FabricHTMLLinkAccessibilityElement *)element;
    A11Y_LOG(@">>> accessibilityElementAtIndex:%ld - LINK element label='%@'", (long)index, linkElement.accessibilityLabel);
  } else {
    UIAccessibilityElement *accessElement = (UIAccessibilityElement *)element;
    A11Y_LOG(@">>> accessibilityElementAtIndex:%ld - TEXT element label='%@...'", (long)index, [accessElement.accessibilityLabel substringToIndex:MIN(30, accessElement.accessibilityLabel.length)]);
  }
  return element;
}

/**
 * Returns the index of the given accessibility element, or NSNotFound if not found.
 */
- (NSInteger)indexOfAccessibilityElement:(id)element {
  [self buildAccessibilityElementsIfNeeded];

  // Accept both UIAccessibilityElement (for text content) and FabricHTMLLinkAccessibilityElement (for links)
  if (![element isKindOfClass:[UIAccessibilityElement class]]) {
    A11Y_LOG(@"indexOfAccessibilityElement: not a UIAccessibilityElement, returning NSNotFound");
    return NSNotFound;
  }

  NSUInteger index = [_accessibilityElements indexOfObject:element];
  A11Y_LOG(@"indexOfAccessibilityElement: found at index %lu", (unsigned long)index);
  return (index != NSNotFound) ? (NSInteger)index : NSNotFound;
}

/**
 * Returns the accessibility container type for this view.
 * We use semantic group since links are semantically related.
 */
- (UIAccessibilityContainerType)accessibilityContainerType {
  return UIAccessibilityContainerTypeSemanticGroup;
}

@end
