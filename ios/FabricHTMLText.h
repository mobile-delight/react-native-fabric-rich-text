#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef FabricHTMLTextNativeComponent_h
#define FabricHTMLTextNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

/**
 * Fabric component view for rendering HTML content.
 *
 * This is a thin ObjC++ glue layer that delegates to HTMLTextRenderer (Swift).
 * The Swift renderer handles all layout, styling, and text rendering logic.
 */
@interface FabricHTMLText : RCTViewComponentView

/// The underlying CoreText view. Exposed for testing the rendering pipeline.
@property (nonatomic, readonly) UIView *renderer;

/// Sets the HTML content directly. Delegates to the Swift renderer.
/// Exposed for testing prop-setting behavior without requiring the full Fabric runtime.
- (void)setHtml:(nullable NSString *)html;

@end

NS_ASSUME_NONNULL_END

#endif /* FabricHTMLTextNativeComponent_h */
