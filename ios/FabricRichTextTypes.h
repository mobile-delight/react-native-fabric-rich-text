/**
 * FabricRichTextTypes.h
 *
 * Shared type definitions for FabricRichText components.
 * This header prevents circular dependencies by providing common types
 * used across the view, helpers, and accessibility elements.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Content Type Enum

/**
 * Type of content detected when a link is pressed.
 * Used for both auto-detected content (via NSDataDetector) and
 * explicit <a> tags in the markup.
 */
typedef NS_ENUM(NSInteger, HTMLDetectedContentType) {
    /** Standard web link (http, https) */
    HTMLDetectedContentTypeLink,
    /** Email address (mailto:) */
    HTMLDetectedContentTypeEmail,
    /** Phone number (tel:) */
    HTMLDetectedContentTypePhone
};

#pragma mark - Attribute Keys

/**
 * Custom attribute key to store the detected content type on NSAttributedString.
 * This allows the touch handler and accessibility helper to determine what type
 * of content is at a given location without re-parsing the URL scheme.
 */
extern NSString *const FabricRichDetectedContentTypeKey;

NS_ASSUME_NONNULL_END
