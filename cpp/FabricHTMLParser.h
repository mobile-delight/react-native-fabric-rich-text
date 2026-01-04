/**
 * FabricHTMLParser.h
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

#include <string>
#include <vector>
#include <unordered_set>

namespace facebook::react {

// List type enum for tracking ordered vs unordered lists
enum class FabricHTMLListType { Ordered, Unordered };

// Context for tracking list state during HTML parsing
struct FabricHTMLListContext {
  FabricHTMLListType type;
  int itemCounter;
  int nestingLevel;
};

// TagStyle struct to hold all supported TextStyle properties from tagStyles
struct FabricHTMLTagStyle {
  int32_t color = 0;           // ARGB color, 0 means not set
  Float fontSize = NAN;        // NAN means not set
  std::string fontWeight;      // empty means not set ("bold", "700", etc.)
  std::string fontStyle;       // empty means not set ("italic", "normal")
  std::string textDecorationLine;  // empty means not set ("underline", "line-through")
};

// Segment of text with its associated style
struct FabricHTMLTextSegment {
  std::string text;
  Float fontScale;
  bool isBold;
  bool isItalic;
  bool isUnderline;           // True if inside <u> tag
  bool isStrikethrough;       // True if inside <s> tag
  bool isLink;                // True if inside <a> tag with href attribute
  bool followsInlineElement;  // True if this segment follows </strong>, </em>, etc.
  std::string parentTag;      // The innermost formatting tag (e.g., "strong", "em")
  std::string linkUrl;        // The href URL if this segment is inside an <a> tag
};

/**
 * Shared HTML parser for cross-platform use.
 *
 * Provides HTML parsing functionality that produces React Native's
 * AttributedString format, which can then be used for both measurement
 * (via TextLayoutManager) and rendering (via platform-specific builders).
 */
class FabricHTMLParser {
 public:
  /**
   * Result of parsing HTML, containing both the attributed string and link URLs.
   */
  struct ParseResult {
    AttributedString attributedString;
    std::vector<std::string> linkUrls;  // URLs indexed by fragment position
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
  static std::vector<FabricHTMLTextSegment> parseHtmlToSegments(const std::string& html);

  /**
   * Extract link URLs from segments.
   * Returns a vector of URLs indexed by segment position (empty string for non-links).
   */
  static std::vector<std::string> extractLinkUrlsFromSegments(
      const std::vector<FabricHTMLTextSegment>& segments);

 private:
  // Block-level HTML tags - whitespace between these can be collapsed
  static const std::unordered_set<std::string> BLOCK_LEVEL_TAGS;

  // Inline formatting tags that don't break text flow
  static const std::unordered_set<std::string> INLINE_FORMATTING_TAGS;

  // Default buffer added to fontSize when lineHeight is not specified
  static constexpr float LINE_HEIGHT_BUFFER_DEFAULT = 4.0f;

  // Default link color (standard blue, matches iOS UIColor.linkColor)
  // ARGB format: 0xFF007AFF (iOS system blue)
  static constexpr int32_t DEFAULT_LINK_COLOR = 0xFF007AFF;

  /**
   * Check if a tag is block-level.
   */
  static bool isBlockLevelTag(const std::string& tag);

  /**
   * Check if a tag is an inline formatting tag.
   */
  static bool isInlineFormattingTag(const std::string& tag);

  /**
   * Get heading scale factor for h1-h6 tags.
   */
  static Float getHeadingScale(const std::string& tag);

  /**
   * Parse a hex color string like "#CC0000" to ARGB int.
   */
  static int32_t parseHexColor(const std::string& colorStr);

  /**
   * Extract a string value from a JSON-like style object.
   */
  static std::string getStringValueFromStyleObj(
      const std::string& styleObj,
      const std::string& key);

  /**
   * Extract a numeric value from a JSON-like style object.
   */
  static Float getNumericValueFromStyleObj(
      const std::string& styleObj,
      const std::string& key);

  /**
   * Parse all TextStyle properties for a specific tag from tagStyles JSON.
   */
  static FabricHTMLTagStyle getStyleFromTagStyles(
      const std::string& tagStyles,
      const std::string& tagName);

  /**
   * Normalize a single segment's text (whitespace handling).
   */
  static std::string normalizeSegmentText(
      const std::string& text,
      bool preserveNewlines = false,
      bool preserveLeadingSpace = false);

  /**
   * Check if a segment is purely paragraph spacing (newlines only).
   */
  static bool isParagraphBreak(const std::string& text);
};

} // namespace facebook::react
