/**
 * FabricRichTextTruncationEngine.h
 *
 * Handles smart word-boundary text truncation for numberOfLines feature.
 * Provides ellipsis rendering and visible text calculation for accessibility.
 *
 * This is the iOS equivalent of Android's TextTruncationEngine.
 * Responsibility: Single-purpose class for text truncation logic.
 */

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FabricRichTextTruncationEngine : NSObject

#pragma mark - Initialization

/**
 * Initialize the truncation engine with a reference to the containing view.
 * @param view The view whose bounds are used for truncation calculations.
 */
- (instancetype)initWithView:(UIView *)view;

#pragma mark - Truncation Detection

/**
 * Check if content is truncated based on visible string range.
 * Uses CTFrameGetVisibleStringRange to accurately detect truncation,
 * even when the shadow node constrains the frame height.
 *
 * @param frame The CoreText frame to check.
 * @param numberOfLines Maximum number of lines (0 = no limit).
 * @param attributedText The attributed text being rendered.
 * @return YES if content is truncated, NO otherwise.
 */
- (BOOL)isContentTruncatedWithFrame:(CTFrameRef)frame
                      numberOfLines:(NSInteger)numberOfLines
                     attributedText:(NSAttributedString *)attributedText;

#pragma mark - Visible Text for Accessibility

/**
 * Get the visible text for accessibility when content is truncated.
 * Returns only the portion of text that is actually visible on screen,
 * accounting for ellipsis truncation on the last line.
 *
 * @param frame The CoreText frame.
 * @param numberOfLines Maximum number of lines (0 = no limit).
 * @param attributedText The attributed text being rendered.
 * @param resolvedAccessibilityLabel Optional explicit accessibility label that takes precedence.
 * @return The visible text string for VoiceOver to announce.
 */
- (NSString *)visibleTextWithFrame:(CTFrameRef)frame
                     numberOfLines:(NSInteger)numberOfLines
                    attributedText:(NSAttributedString *)attributedText
         resolvedAccessibilityLabel:(nullable NSString *)resolvedAccessibilityLabel;

#pragma mark - Truncated Drawing

/**
 * Draw the frame with truncation at the specified number of lines.
 * If the content exceeds maxLines, the last visible line is truncated with ellipsis.
 * Uses word-boundary awareness to avoid cutting mid-word.
 *
 * @param frame The CoreText frame to draw.
 * @param context The graphics context for drawing.
 * @param maxLines Maximum number of lines to display.
 * @param attributedText The attributed text being rendered.
 *
 * @note The context should already have the CoreText coordinate transform applied
 *       (flipped Y-axis with origin at bottom-left).
 */
- (void)drawTruncatedFrame:(CTFrameRef)frame
                 inContext:(CGContextRef)context
                  maxLines:(NSInteger)maxLines
            attributedText:(NSAttributedString *)attributedText;

@end

NS_ASSUME_NONNULL_END
