/**
 * UnicodeUtils.h
 *
 * Unicode utilities for RTL/LTR direction detection.
 * Implements first-strong-directional character algorithm per Unicode UAX #9.
 */

#pragma once

#include <react/renderer/attributedstring/primitives.h>
#include <string>

namespace facebook::react::parsing {

/**
 * Check if a Unicode code point is a strong RTL character.
 * Includes Hebrew, Arabic, Syriac, Thaana, N'Ko ranges.
 * @param codepoint Unicode code point
 * @return true if strong RTL character
 */
bool isStrongRTL(char32_t codepoint);

/**
 * Check if a Unicode code point is a strong LTR character.
 * Includes Latin, Greek, Cyrillic, and other LTR script ranges.
 * @param codepoint Unicode code point
 * @return true if strong LTR character
 */
bool isStrongLTR(char32_t codepoint);

/**
 * Detect writing direction from text content.
 * Implements first strong directional character algorithm per Unicode UAX #9.
 * @param text UTF-8 encoded text to analyze
 * @return Detected direction, or LTR if no strong character found
 */
WritingDirection detectDirectionFromText(const std::string& text);

/**
 * Parse dir attribute value to WritingDirection.
 * @param dirAttr Attribute value (case-insensitive: "ltr", "rtl", "auto")
 * @return Parsed direction, or Natural if invalid/empty
 */
WritingDirection parseDirectionAttribute(const std::string& dirAttr);

} // namespace facebook::react::parsing
