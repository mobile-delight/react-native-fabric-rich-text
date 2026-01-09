#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef FabricRichTextNativeComponent_h
#define FabricRichTextNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

/**
 * Fabric component view for rendering HTML content.
 *
 * This is a thin ObjC++ glue layer that delegates to RichTextRenderer (Swift).
 * The Swift renderer handles all layout, styling, and text rendering logic.
 */
@interface FabricRichText : RCTViewComponentView

/// The underlying CoreText view. Exposed for testing the rendering pipeline.
@property (nonatomic, readonly) UIView *renderer;

/// Maximum number of lines to display (0 = no limit).
@property (nonatomic, assign) NSInteger numberOfLines;

/// Animation duration for height changes in seconds (0 = instant).
@property (nonatomic, assign) CGFloat animationDuration;

/// Sets the HTML content directly. Delegates to the Swift renderer.
/// Exposed for testing prop-setting behavior without requiring the full Fabric runtime.
- (void)setHtml:(nullable NSString *)html;

@end

NS_ASSUME_NONNULL_END

#endif /* FabricRichTextNativeComponent_h */
