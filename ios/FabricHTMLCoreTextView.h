#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Type of content detected when a link is pressed.
 */
typedef NS_ENUM(NSInteger, HTMLDetectedContentType) {
    HTMLDetectedContentTypeLink,
    HTMLDetectedContentTypeEmail,
    HTMLDetectedContentTypePhone
};

@protocol FabricHTMLCoreTextViewDelegate <NSObject>
@optional
/**
 * Called when a link, email, or phone number is tapped.
 * @param view The view that detected the tap
 * @param url The URL, email address (mailto:), or phone number (tel:)
 * @param type The type of content that was detected
 */
- (void)coreTextView:(id)view didTapLinkWithURL:(NSURL *)url type:(HTMLDetectedContentType)type;
@end

/**
 * Custom view that renders NSAttributedString using CoreText (CTFrameDraw).
 * This ensures measurement (CTFramesetterSuggestFrameSizeWithConstraints)
 * and rendering use the exact same engine, eliminating size mismatches.
 */
@interface FabricHTMLCoreTextView : UIView

@property (nonatomic, copy, nullable) NSAttributedString *attributedText;
@property (nonatomic, weak, nullable) id<FabricHTMLCoreTextViewDelegate> delegate;

/// Enable automatic URL/link detection. When true, URLs in the text will be tappable. Defaults to NO.
@property (nonatomic, assign) BOOL detectLinks;

/// Enable automatic phone number detection. When true, phone numbers will be tappable. Defaults to NO.
@property (nonatomic, assign) BOOL detectPhoneNumbers;

/// Enable automatic email address detection. When true, emails will be tappable. Defaults to NO.
@property (nonatomic, assign) BOOL detectEmails;

/// Maximum number of lines to display (0 = no limit). When exceeded, truncates with trailing ellipsis.
@property (nonatomic, assign) NSInteger numberOfLines;

/// Animation duration for height changes in seconds (0 = instant).
@property (nonatomic, assign) CGFloat animationDuration;

/// Whether to use right-to-left text direction. Defaults to NO.
@property (nonatomic, assign) BOOL isRTL;

/// Text alignment ("left", "right", "center", "justify", or nil for natural). Defaults to nil.
/// In RTL mode, "left" and "right" are swapped automatically (left → end, right → start).
@property (nonatomic, copy, nullable) NSString *textAlign;

@end

NS_ASSUME_NONNULL_END
