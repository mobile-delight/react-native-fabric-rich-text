/**
 * FabricRichLinkDetectionManager.h
 *
 * Manages auto-detection of links, phone numbers, and email addresses
 * in attributed text using NSDataDetector.
 *
 * This is the iOS equivalent of Android's LinkDetectionManager.
 * Responsibility: Single-purpose class for content detection.
 */

#import <Foundation/Foundation.h>
#import "FabricRichTextTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface FabricRichLinkDetectionManager : NSObject

#pragma mark - Detection Flags

/** Enable automatic URL/link detection. When true, URLs in the text will be tappable. Defaults to NO. */
@property (nonatomic, assign) BOOL detectLinks;

/** Enable automatic phone number detection. When true, phone numbers will be tappable. Defaults to NO. */
@property (nonatomic, assign) BOOL detectPhoneNumbers;

/** Enable automatic email address detection. When true, emails will be tappable. Defaults to NO. */
@property (nonatomic, assign) BOOL detectEmails;

#pragma mark - Detection Methods

/**
 * Check if any detection mode is enabled.
 * @return YES if at least one detection type is enabled.
 */
- (BOOL)isDetectionEnabled;

/**
 * Process attributed text to add detected links, emails, and phone numbers.
 * Applies blue color and underline styling to detected items.
 * Adds NSLinkAttributeName and FabricRichDetectedContentTypeKey attributes.
 *
 * @param attributedText The input attributed string to process.
 * @return A new attributed string with detected content marked, or the original if no detection is enabled.
 *
 * @note Explicit anchor tags take precedence - if a range already has NSLinkAttributeName, detection is skipped for that range.
 * @note Only safe URL schemes are allowed (http, https, mailto, tel). Others are rejected for security.
 */
- (NSAttributedString *)processAttributedText:(NSAttributedString *)attributedText;

@end

NS_ASSUME_NONNULL_END
