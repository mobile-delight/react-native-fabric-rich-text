/**
 * FabricRichTouchHandler.h
 *
 * Handles touch events and link hit testing for tap detection.
 * Provides coordinate conversion between UIKit and CoreText coordinate systems.
 *
 * Responsibility: Single-purpose class for touch/hit testing logic.
 */

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import "FabricRichTextTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface FabricRichTouchHandler : NSObject

/**
 * Find the link at a given point in the view.
 * Converts from UIKit coordinates to CoreText coordinates and performs hit testing.
 *
 * @param point The touch point in UIKit coordinates (origin at top-left).
 * @param frame The CoreText frame to search.
 * @param attributedText The attributed text containing potential links.
 * @param viewBounds The bounds of the containing view.
 * @param outType Optional pointer to receive the detected content type (link, email, phone).
 * @return The URL at the point, or nil if no link was found.
 *
 * @note Only returns URLs with safe schemes (http, https, mailto, tel).
 *       Dangerous schemes like javascript: are blocked for security.
 */
- (nullable NSURL *)linkAtPoint:(CGPoint)point
                        inFrame:(CTFrameRef)frame
                 attributedText:(NSAttributedString *)attributedText
                     viewBounds:(CGRect)viewBounds
                   detectedType:(nullable HTMLDetectedContentType *)outType;

@end

NS_ASSUME_NONNULL_END
