/**
 * FabricRichDebugDrawingHelper.h
 *
 * Debug visualization for text layout bounds and metrics.
 * Only active when debug flags are enabled. Provides visual overlays
 * for line bounds, baselines, and tap-to-inspect functionality.
 *
 * This is the iOS equivalent of Android's DebugDrawingHelper.
 * Responsibility: Single-purpose class for debug visualization.
 */

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FabricRichDebugDrawingHelper : NSObject

#pragma mark - Debug Flag

/**
 * Check if debug drawing is enabled.
 * Set kDebugDrawLineBounds to YES in the implementation to enable.
 */
+ (BOOL)isDebugDrawingEnabled;

#pragma mark - Debug Drawing

/**
 * Draw debug visualization of line bounds over the rendered text.
 * Shows colored rectangles for each line, baselines, and logs metrics.
 *
 * @param frame The CoreText frame to visualize.
 * @param context The graphics context (should be in CoreText coordinates).
 * @param viewBounds The bounds of the containing view.
 * @param attributedText The attributed text being rendered.
 *
 * @note Only draws if isDebugDrawingEnabled returns YES.
 * @note Caches debug info for later tap-to-inspect functionality.
 */
- (void)drawDebugLineBounds:(CTFrameRef)frame
                  inContext:(CGContextRef)context
                 viewBounds:(CGRect)viewBounds
             attributedText:(NSAttributedString *)attributedText;

#pragma mark - Tap-to-Inspect

/**
 * Get debug info for the line at the given point.
 * Used for tap-to-inspect functionality.
 *
 * @param point The tap point in UIKit coordinates.
 * @return Dictionary with line info (index, text, metrics), or nil if no line at point.
 */
- (nullable NSDictionary *)debugLineInfoAtPoint:(CGPoint)point;

/**
 * Show a debug alert with line information.
 * Presents a UIAlertController with detailed metrics for the tapped line.
 *
 * @param info The debug info dictionary from debugLineInfoAtPoint:.
 * @param view The view to present the alert from.
 */
- (void)showDebugAlertForLineInfo:(NSDictionary *)info fromView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
