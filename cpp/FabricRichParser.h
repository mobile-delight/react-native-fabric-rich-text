/**
 * FabricRichParser.h
 *
 * Shared C++ HTML parsing module for cross-platform HTML rendering.
 * Used by both Android and iOS shadow nodes to parse HTML into
 * AttributedString fragments for measurement and rendering.
 *
 * This eliminates duplicate parsing logic between platforms and ensures
 * consistent behavior across iOS and Android.
 */

#pragma once

#include <react/renderer/attributedstring/AttributedString.h>
#include <react/renderer/attributedstring/ParagraphAttributes.h>
#include <react/renderer/textlayoutmanager/TextLayoutManager.h>

#include "parsing/UnicodeUtils.h"
#include "parsing/DirectionContext.h"
#include "parsing/StyleParser.h"
#include "parsing/TextNormalizer.h"
#include "parsing/HtmlSegmentParser.h"
#include "parsing/AttributedStringBuilder.h"

#include <string>
#include <vector>
#include <unordered_set>

namespace facebook::react {

// Re-export types from parsing namespace for backward compatibility
using parsing::FabricRichListType;
using parsing::FabricRichListContext;
using parsing::FabricRichTagStyle;
using parsing::FabricRichTextSegment;

// Re-export from parsing namespace for backward compatibility
using parsing::DirectionContext;
using parsing::detectDirectionFromText;
using parsing::parseDirectionAttribute;
using parsing::isStrongRTL;
using parsing::isStrongLTR;

/**
 * Shared HTML parser for cross-platform use.
 *
 * Provides HTML parsing functionality that produces React Native's
 * AttributedString format, which can then be used for both measurement
 * (via TextLayoutManager) and rendering (via platform-specific builders).
 */
class FabricRichParser {
 public:
  /**
   * Result of parsing HTML, containing both the attributed string and link URLs.
   */
  struct ParseResult {
    AttributedString attributedString;
    std::vector<std::string> linkUrls;  // URLs indexed by fragment position
    std::string accessibilityLabel;     // Screen reader friendly version with pauses between list items
  };

  /**
   * Parse HTML string into an AttributedString.
   *
   * @param html The HTML string to parse (should be pre-sanitized)
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
   * @return Parsed AttributedString with styled fragments
   */
  static AttributedString parseHtmlToAttributedString(
      const std::string& html,
      Float baseFontSize,
      Float fontSizeMultiplier,
      bool allowFontScaling,
      Float maxFontSizeMultiplier,
      Float lineHeight,
      const std::string& fontWeight,
      const std::string& fontFamily,
      const std::string& fontStyle,
      Float letterSpacing,
      int32_t color,
      const std::string& tagStyles);

  /**
   * Parse HTML string with full results including link URLs.
   * Same as parseHtmlToAttributedString but also returns link URLs for each fragment.
   */
  static ParseResult parseHtmlWithLinkUrls(
      const std::string& html,
      Float baseFontSize,
      Float fontSizeMultiplier,
      bool allowFontScaling,
      Float maxFontSizeMultiplier,
      Float lineHeight,
      const std::string& fontWeight,
      const std::string& fontFamily,
      const std::string& fontStyle,
      Float letterSpacing,
      int32_t color,
      const std::string& tagStyles);

  /**
   * Strip HTML tags from a string, returning plain text content.
   * Handles lists, line breaks, and basic formatting.
   */
  static std::string stripHtmlTags(const std::string& html);

  /**
   * Normalize inter-tag whitespace from source formatting.
   * Removes whitespace between block elements while preserving
   * significant whitespace after inline elements.
   */
  static std::string normalizeInterTagWhitespace(const std::string& html);

  /**
   * Parse HTML into styled text segments.
   * Each segment represents a run of text with consistent styling.
   */
  static std::vector<FabricRichTextSegment> parseHtmlToSegments(const std::string& html);

  /**
   * Extract link URLs from segments.
   * Returns a vector of URLs indexed by segment position (empty string for non-links).
   */
  static std::vector<std::string> extractLinkUrlsFromSegments(
      const std::vector<FabricRichTextSegment>& segments);

};

} // namespace facebook::react
