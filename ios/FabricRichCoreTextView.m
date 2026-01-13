/**
 * FabricRichCoreTextView.m
 *
 * Custom view that renders NSAttributedString using CoreText.
 * This is the main orchestrator that coordinates specialized helper classes:
 * - FabricRichLinkDetectionManager: Auto-detection of links, phones, emails
 * - FabricRichTextTruncationEngine: Word-boundary truncation for numberOfLines
 * - FabricRichTextAccessibilityHelper: VoiceOver accessibility support
 * - FabricRichTouchHandler: Touch/tap handling for links
 * - FabricRichDebugDrawingHelper: Debug visualization
 */

#import "FabricRichCoreTextView.h"
#import "FabricRichLinkDetectionManager.h"
#import "FabricRichTextTruncationEngine.h"
#import "FabricRichTextAccessibilityHelper.h"
#import "FabricRichTouchHandler.h"
#import "FabricRichDebugDrawingHelper.h"
#import "FabricRichLinkAccessibilityElement.h"
#import <CoreText/CoreText.h>

/// Accessibility debug logging - set to 0 for production
#define A11Y_DEBUG 0

#if A11Y_DEBUG
#define A11Y_LOG(fmt, ...) NSLog(@"[A11Y_FHTMLCTV] " fmt, ##__VA_ARGS__)
#else
#define A11Y_LOG(fmt, ...) do { } while(0)
#endif

@implementation FabricRichCoreTextView {
    // CoreText frame management
    CTFrameRef _ctFrame;
    NSAttributedString *_processedAttributedText;

    // Height animation
    CGFloat _previousContentHeight;
    BOOL _hasInitializedHeight;

    // Accessibility
    NSArray *_accessibilityElements;

    // Line measurement
    NSInteger _lastReportedMeasuredLineCount;
    NSInteger _lastReportedVisibleLineCount;

    // Helper classes
    FabricRichLinkDetectionManager *_linkDetectionManager;
    FabricRichTextTruncationEngine *_truncationEngine;
    FabricRichTextAccessibilityHelper *_accessibilityHelper;
    FabricRichTouchHandler *_touchHandler;
    FabricRichDebugDrawingHelper *_debugDrawingHelper;
}

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        _previousContentHeight = 0;
        _hasInitializedHeight = NO;
        _animationDuration = 0.2;
        _lastReportedMeasuredLineCount = -1;
        _lastReportedVisibleLineCount = -1;

        // Initialize helper classes
        _linkDetectionManager = [[FabricRichLinkDetectionManager alloc] init];
        _truncationEngine = [[FabricRichTextTruncationEngine alloc] initWithView:self];
        _accessibilityHelper = [[FabricRichTextAccessibilityHelper alloc] init];
        _touchHandler = [[FabricRichTouchHandler alloc] init];
        _debugDrawingHelper = [[FabricRichDebugDrawingHelper alloc] init];
    }
    return self;
}

- (void)dealloc {
    if (_ctFrame) {
        CFRelease(_ctFrame);
    }
}

#pragma mark - Property Setters

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (_attributedText == attributedText ||
        [_attributedText isEqualToAttributedString:attributedText]) {
        return;
    }
    _attributedText = [attributedText copy];
    _processedAttributedText = [_linkDetectionManager processAttributedText:_attributedText];
    [self invalidateFrame];
    [self setNeedsDisplay];
}

- (void)setDetectLinks:(BOOL)detectLinks {
    if (_detectLinks == detectLinks) {
        return;
    }
    _detectLinks = detectLinks;
    _linkDetectionManager.detectLinks = detectLinks;
    _processedAttributedText = [_linkDetectionManager processAttributedText:_attributedText];
    [self invalidateFrame];
    [self setNeedsDisplay];
}

- (void)setDetectPhoneNumbers:(BOOL)detectPhoneNumbers {
    if (_detectPhoneNumbers == detectPhoneNumbers) {
        return;
    }
    _detectPhoneNumbers = detectPhoneNumbers;
    _linkDetectionManager.detectPhoneNumbers = detectPhoneNumbers;
    _processedAttributedText = [_linkDetectionManager processAttributedText:_attributedText];
    [self invalidateFrame];
    [self setNeedsDisplay];
}

- (void)setDetectEmails:(BOOL)detectEmails {
    if (_detectEmails == detectEmails) {
        return;
    }
    _detectEmails = detectEmails;
    _linkDetectionManager.detectEmails = detectEmails;
    _processedAttributedText = [_linkDetectionManager processAttributedText:_attributedText];
    [self invalidateFrame];
    [self setNeedsDisplay];
}

- (void)setNumberOfLines:(NSInteger)numberOfLines {
#if DEBUG
    NSLog(@"[FabricRichText] setNumberOfLines: %ld -> %ld", (long)_numberOfLines, (long)numberOfLines);
#endif
    if (_numberOfLines == numberOfLines) {
        return;
    }
    _numberOfLines = numberOfLines;
    [self setNeedsDisplay];
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

#pragma mark - Computed Properties

- (BOOL)isContentTruncated {
    return [_truncationEngine isContentTruncatedWithFrame:[self ctFrame]
                                            numberOfLines:_numberOfLines
                                           attributedText:_processedAttributedText ?: _attributedText];
}

- (NSString *)visibleTextForAccessibility {
    return [_truncationEngine visibleTextWithFrame:[self ctFrame]
                                     numberOfLines:_numberOfLines
                                    attributedText:_processedAttributedText ?: _attributedText
                         resolvedAccessibilityLabel:_resolvedAccessibilityLabel];
}

- (NSInteger)visibleLinkCount {
    return [_accessibilityHelper visibleLinkCountWithFrame:[self ctFrame]
                                             numberOfLines:_numberOfLines
                                            attributedText:_processedAttributedText ?: _attributedText];
}

- (CGRect)boundsForLinkAtIndex:(NSUInteger)index {
    return [_accessibilityHelper boundsForLinkAtIndex:index
                                              inFrame:[self ctFrame]
                                       attributedText:_processedAttributedText ?: _attributedText
                                           viewBounds:self.bounds];
}

#pragma mark - Frame Management

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
    if (UIAccessibilityIsVoiceOverRunning()) {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
}

- (void)invalidateFrame {
    if (_ctFrame) {
        CFRelease(_ctFrame);
        _ctFrame = NULL;
    }
    _accessibilityElements = nil;
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

        _ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);

        CGPathRelease(path);
        CFRelease(framesetter);
    }
    return _ctFrame;
}

#pragma mark - RTL/Text Alignment

/**
 * Apply base writing direction to attributed string via paragraph style.
 */
- (NSAttributedString *)applyBaseWritingDirection:(NSAttributedString *)attributedText isRTL:(BOOL)isRTL {
    if (!attributedText || attributedText.length == 0) {
        return attributedText;
    }

    NSMutableAttributedString *mutableText = [attributedText mutableCopy];
    NSRange fullRange = NSMakeRange(0, mutableText.length);

    // Determine text alignment based on textAlign prop and RTL mode
    NSTextAlignment alignment = NSTextAlignmentNatural;
    if (_textAlign) {
        if ([_textAlign isEqualToString:@"center"]) {
            alignment = NSTextAlignmentCenter;
        } else if ([_textAlign isEqualToString:@"justify"]) {
            alignment = NSTextAlignmentJustified;
        } else if ([_textAlign isEqualToString:@"left"]) {
            alignment = isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;
        } else if ([_textAlign isEqualToString:@"right"]) {
            alignment = isRTL ? NSTextAlignmentLeft : NSTextAlignmentRight;
        }
    } else if (isRTL) {
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

        style.baseWritingDirection = isRTL ? NSWritingDirectionRightToLeft : NSWritingDirectionLeftToRight;

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

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
#if DEBUG
    NSLog(@"[FabricRichText] drawRect called, numberOfLines=%ld, textLength=%lu",
          (long)_numberOfLines, (unsigned long)_attributedText.length);
#endif

    if (_attributedText.length == 0) {
#if DEBUG
        NSLog(@"[FabricRichText] drawRect: empty text, returning");
#endif
        return;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
#if DEBUG
        NSLog(@"[FabricRichText] drawRect: no context, returning");
#endif
        return;
    }

    // CoreText uses a flipped coordinate system (origin at bottom-left)
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CTFrameRef frame = [self ctFrame];
    if (frame) {
        NSAttributedString *textToRender = _processedAttributedText ?: _attributedText;

        if (_numberOfLines > 0) {
#if DEBUG
            NSLog(@"[FabricRichText] drawRect: calling drawTruncatedFrame with maxLines=%ld", (long)_numberOfLines);
#endif
            [_truncationEngine drawTruncatedFrame:frame
                                        inContext:context
                                         maxLines:_numberOfLines
                                   attributedText:textToRender];
        } else {
#if DEBUG
            NSLog(@"[FabricRichText] drawRect: no truncation, calling CTFrameDraw");
#endif
            CTFrameDraw(frame, context);
        }

        // Debug visualization
        if ([FabricRichDebugDrawingHelper isDebugDrawingEnabled]) {
            [_debugDrawingHelper drawDebugLineBounds:frame
                                           inContext:context
                                          viewBounds:self.bounds
                                      attributedText:textToRender];
        }
    }

    CGContextRestoreGState(context);

    // Report line count measurements to delegate
    [self reportLineMeasurementsIfNeeded];
}

#pragma mark - Line Measurement Reporting

- (void)reportLineMeasurementsIfNeeded {
    NSAttributedString *textToRender = _processedAttributedText ?: _attributedText;
    if (textToRender.length == 0) {
        return;
    }

    CTFrameRef frame = [self ctFrame];
    if (!frame) {
        return;
    }

    CFArrayRef visibleLines = CTFrameGetLines(frame);
    NSInteger visibleLineCount = (NSInteger)CFArrayGetCount(visibleLines);

    // Compute measured line count (total lines without truncation)
    NSInteger measuredLineCount = visibleLineCount;

    NSAttributedString *directedText = textToRender;
    if (_isRTL) {
        directedText = [self applyBaseWritingDirection:textToRender isRTL:YES];
    }

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(
        (__bridge CFAttributedStringRef)directedText);

    if (framesetter) {
        CGRect unconstrainedBounds = CGRectMake(0, 0, self.bounds.size.width, CGFLOAT_MAX);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, unconstrainedBounds);

        CTFrameRef unconstrainedFrame = CTFramesetterCreateFrame(
            framesetter, CFRangeMake(0, 0), path, NULL);

        if (unconstrainedFrame) {
            CFArrayRef allLines = CTFrameGetLines(unconstrainedFrame);
            measuredLineCount = (NSInteger)CFArrayGetCount(allLines);
            CFRelease(unconstrainedFrame);
        }

        CGPathRelease(path);
        CFRelease(framesetter);
    }

    // Only notify delegate if values changed
    if (measuredLineCount != _lastReportedMeasuredLineCount ||
        visibleLineCount != _lastReportedVisibleLineCount) {
        _lastReportedMeasuredLineCount = measuredLineCount;
        _lastReportedVisibleLineCount = visibleLineCount;

        if ([_delegate respondsToSelector:@selector(coreTextView:didMeasureWithLineCount:visibleLineCount:)]) {
            [_delegate coreTextView:self
                didMeasureWithLineCount:measuredLineCount
                     visibleLineCount:visibleLineCount];
        }
    }
}

#pragma mark - Touch Handling

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];

    // Debug mode: show line info when tapped
    if ([FabricRichDebugDrawingHelper isDebugDrawingEnabled]) {
        NSDictionary *lineInfo = [_debugDrawingHelper debugLineInfoAtPoint:point];
        if (lineInfo) {
            [_debugDrawingHelper showDebugAlertForLineInfo:lineInfo fromView:self];
            return;
        }
    }

    HTMLDetectedContentType detectedType = HTMLDetectedContentTypeLink;
    NSAttributedString *textToCheck = _processedAttributedText ?: _attributedText;

    NSURL *url = [_touchHandler linkAtPoint:point
                                    inFrame:[self ctFrame]
                             attributedText:textToCheck
                                 viewBounds:self.bounds
                               detectedType:&detectedType];

    if (url && [self.delegate respondsToSelector:@selector(coreTextView:didTapLinkWithURL:type:)]) {
        [self.delegate coreTextView:self didTapLinkWithURL:url type:detectedType];
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

#pragma mark - UIAccessibilityContainer Protocol

- (void)buildAccessibilityElementsIfNeeded {
    if (_accessibilityElements) {
        A11Y_LOG(@"buildAccessibilityElementsIfNeeded: using cached elements");
        return;
    }

    NSAttributedString *textToCheck = _processedAttributedText ?: _attributedText;
    NSString *visibleText = [self visibleTextForAccessibility];

    _accessibilityElements = [_accessibilityHelper buildAccessibilityElementsWithFrame:[self ctFrame]
                                                                         numberOfLines:_numberOfLines
                                                                        attributedText:textToCheck
                                                                         containerView:self
                                                                           visibleText:visibleText];
}

- (BOOL)isAccessibilityElement {
    NSInteger linkCount = self.visibleLinkCount;
    BOOL isElement = (linkCount == 0);
    A11Y_LOG(@"isAccessibilityElement: linkCount=%ld, returning %@", (long)linkCount, isElement ? @"YES" : @"NO");
    return isElement;
}

- (NSString *)accessibilityLabel {
    if (![self isAccessibilityElement]) {
        A11Y_LOG(@"accessibilityLabel: acting as container, returning nil");
        return nil;
    }
    NSString *label = [self visibleTextForAccessibility];
    A11Y_LOG(@"accessibilityLabel: '%@...'", [label substringToIndex:MIN(50, label.length)]);
    return label;
}

- (UIAccessibilityTraits)accessibilityTraits {
    if (![self isAccessibilityElement]) {
        A11Y_LOG(@"accessibilityTraits: acting as container, returning UIAccessibilityTraitNone");
        return UIAccessibilityTraitNone;
    }
    A11Y_LOG(@"accessibilityTraits: returning UIAccessibilityTraitStaticText");
    return UIAccessibilityTraitStaticText;
}

- (NSInteger)accessibilityElementCount {
    [self buildAccessibilityElementsIfNeeded];
    A11Y_LOG(@"accessibilityElementCount: returning %ld", (long)_accessibilityElements.count);
    return (NSInteger)_accessibilityElements.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    [self buildAccessibilityElementsIfNeeded];

    if (index < 0 || index >= (NSInteger)_accessibilityElements.count) {
        A11Y_LOG(@">>> accessibilityElementAtIndex:%ld - OUT OF BOUNDS", (long)index);
        return nil;
    }

    id element = _accessibilityElements[(NSUInteger)index];
    A11Y_LOG(@">>> accessibilityElementAtIndex:%ld - returning element", (long)index);
    return element;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    [self buildAccessibilityElementsIfNeeded];

    if (![element isKindOfClass:[UIAccessibilityElement class]]) {
        A11Y_LOG(@"indexOfAccessibilityElement: not a UIAccessibilityElement, returning NSNotFound");
        return NSNotFound;
    }

    NSUInteger index = [_accessibilityElements indexOfObject:element];
    A11Y_LOG(@"indexOfAccessibilityElement: found at index %lu", (unsigned long)index);
    return (index != NSNotFound) ? (NSInteger)index : NSNotFound;
}

- (UIAccessibilityContainerType)accessibilityContainerType {
    return UIAccessibilityContainerTypeSemanticGroup;
}

@end
