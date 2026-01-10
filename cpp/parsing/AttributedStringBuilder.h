/**
 * AttributedStringBuilder.h
 *
 * Builds React Native AttributedString from parsed HTML segments.
 * Handles font scaling, text decoration, color, and accessibility labels.
 */

#pragma once

#include "HtmlSegmentParser.h"
#include "StyleParser.h"
#include "TextNormalizer.h"

#include <react/renderer/attributedstring/AttributedString.h>

#include <string>
#include <vector>

namespace facebook::react::parsing {

/**
 * Result of building attributed string, containing the string, link URLs,
 * and accessibility label.
 */
struct AttributedStringResult {
  AttributedString attributedString;
  std::vector<std::string> linkUrls;  // URLs indexed by fragment position
  std::string accessibilityLabel;     // Screen reader friendly version with pauses
};

// Default buffer added to fontSize when lineHeight is not specified
constexpr float LINE_HEIGHT_BUFFER_DEFAULT = 4.0f;

// Default link color (standard blue, matches iOS UIColor.linkColor)
// ARGB format: 0xFF007AFF (iOS system blue)
constexpr int32_t DEFAULT_LINK_COLOR = 0xFF007AFF;

/**
 * Build an AttributedString from parsed HTML segments.
 *
 * @param segments Parsed HTML segments from parseHtmlToSegments
 * @param baseFontSize Base font size in points
 * @param fontSizeMultiplier Accessibility scaling multiplier
 * @param allowFontScaling Whether to apply font scaling
 * @param maxFontSizeMultiplier Maximum allowed font size multiplier (0 = no limit)
 * @param lineHeight Explicit line height (NAN = auto)
 * @param fontWeight Base font weight
 * @param fontFamily Base font family
 * @param fontStyle Base font style
 * @param letterSpacing Letter spacing
 * @param color Base text color (ARGB, 0 = default)
 * @param tagStyles JSON string of per-tag style overrides
 * @return Result containing AttributedString, link URLs, and accessibility label
 */
AttributedStringResult buildAttributedString(
    const std::vector<FabricRichTextSegment>& segments,
    float baseFontSize,
    float fontSizeMultiplier,
    bool allowFontScaling,
    float maxFontSizeMultiplier,
    float lineHeight,
    const std::string& fontWeight,
    const std::string& fontFamily,
    const std::string& fontStyle,
    float letterSpacing,
    int32_t color,
    const std::string& tagStyles);

/**
 * Build accessibility label from plain text with proper pauses between list items.
 * Inserts periods before list markers for screen reader pauses.
 * @param plainText Plain text from attributed string
 * @return Accessibility-friendly label
 */
std::string buildAccessibilityLabel(const std::string& plainText);

} // namespace facebook::react::parsing
