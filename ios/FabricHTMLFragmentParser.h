/**
 * FabricHTMLFragmentParser.h
 *
 * Converts C++ AttributedString fragments to NSAttributedString.
 *
 * This enables the iOS view to render using the same parsed data
 * that C++ used for measurement, eliminating duplicate HTML parsing
 * and ensuring perfect measurement/rendering alignment.
 */

#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef __cplusplus
#include <react/renderer/attributedstring/AttributedString.h>
#include <vector>
#include <string>

NS_ASSUME_NONNULL_BEGIN

/**
 * Parses C++ AttributedString into NSAttributedString.
 *
 * The C++ AttributedString contains fragments with text and TextAttributes.
 * This class iterates through those fragments and builds an equivalent
 * NSAttributedString with the appropriate attributes.
 */
@interface FabricHTMLFragmentParser : NSObject

/**
 * Build an NSAttributedString from a C++ AttributedString.
 *
 * @param attributedString The C++ AttributedString from state
 * @return NSAttributedString with equivalent styling
 */
+ (NSAttributedString *)buildAttributedStringFromCppAttributedString:
    (const facebook::react::AttributedString &)attributedString;

/**
 * Build an NSAttributedString from a C++ AttributedString with link URLs.
 *
 * @param attributedString The C++ AttributedString from state
 * @param linkUrls Vector of link URLs indexed by fragment position (empty string for non-links)
 * @return NSAttributedString with equivalent styling and clickable links
 */
+ (NSAttributedString *)buildAttributedStringFromCppAttributedString:
    (const facebook::react::AttributedString &)attributedString
    withLinkUrls:(const std::vector<std::string> &)linkUrls;

@end

NS_ASSUME_NONNULL_END

#endif // __cplusplus
