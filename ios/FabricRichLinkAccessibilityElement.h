#import <UIKit/UIKit.h>
#import "FabricRichCoreTextView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Accessibility element representing a single link within FabricRichCoreTextView.
 *
 * This element exposes individual links to VoiceOver as focusable, actionable elements.
 * Each link gets its own accessibility frame, label, hint, and can be activated.
 *
 * WCAG 2.1 Level AA Compliance:
 * - 2.4.4 Link Purpose: Label includes link text
 * - 4.1.2 Name, Role, Value: Exposes link trait and activation
 */
@interface FabricRichLinkAccessibilityElement : UIAccessibilityElement

/**
 * Zero-based index of this link in the parent view's link array.
 */
@property (nonatomic, assign, readonly) NSUInteger linkIndex;

/**
 * Total number of links in the parent view (for "link X of Y" announcement).
 */
@property (nonatomic, assign, readonly) NSUInteger totalLinkCount;

/**
 * The URL this link points to.
 */
@property (nonatomic, copy, readonly) NSURL *url;

/**
 * The type of content this link represents (link, email, phone).
 */
@property (nonatomic, assign, readonly) HTMLDetectedContentType contentType;

/**
 * The visible text of the link.
 */
@property (nonatomic, copy, readonly) NSString *linkText;

/**
 * The bounding rect of the link in the container view's local coordinate system.
 * Used for dynamic accessibilityFrame calculation.
 */
@property (nonatomic, assign, readonly) CGRect boundingRect;

/**
 * Weak reference to the container view for coordinate conversion.
 * Used to dynamically compute accessibilityFrame when VoiceOver requests it.
 */
@property (nonatomic, weak, readonly, nullable) UIView *containerView;

/**
 * Initialize a new link accessibility element.
 *
 * @param container The parent accessibility container (FabricRichCoreTextView)
 * @param linkIndex Zero-based index of this link
 * @param totalLinkCount Total number of links in the container
 * @param url The URL this link points to
 * @param contentType The type of content (link, email, phone)
 * @param linkText The visible text of the link
 * @param boundingRect The link bounds in local view coordinates (not screen coordinates)
 * @param containerView The view used for coordinate conversion to screen space
 */
- (instancetype)initWithAccessibilityContainer:(id)container
                                     linkIndex:(NSUInteger)linkIndex
                                totalLinkCount:(NSUInteger)totalLinkCount
                                           url:(NSURL *)url
                                   contentType:(HTMLDetectedContentType)contentType
                                      linkText:(NSString *)linkText
                                   boundingRect:(CGRect)boundingRect
                                  containerView:(UIView *)containerView;

@end

NS_ASSUME_NONNULL_END
