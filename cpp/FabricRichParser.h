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

#include <string>
#include <vector>
#include <unordered_set>

namespace facebook::react {

// List type enum for tracking ordered vs unordered lists
enum class FabricRichListType { Ordered, Unordered };

// Note: We use React Native's WritingDirection enum from primitives.h
// which has: Natural, LeftToRight, RightToLeft

// Context for tracking list state during HTML parsing
struct FabricRichListContext {
  FabricRichListType type;
  int itemCounter;
  int nestingLevel;
};

// TagStyle struct to hold all supported TextStyle properties from tagStyles
struct FabricRichTagStyle {
  int32_t color = 0;           // ARGB color, 0 means not set
  Float fontSize = NAN;        // NAN means not set
  std::string fontWeight;      // empty means not set ("bold", "700", etc.)
  std::string fontStyle;       // empty means not set ("italic", "normal")
  std::string textDecorationLine;  // empty means not set ("underline", "line-through")
};

// Segment of text with its associated style
struct FabricRichTextSegment {
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

  // RTL Support fields
  WritingDirection writingDirection = WritingDirection::Natural;
  bool isBdiIsolated = false;   // Content wrapped in <bdi> tag
  bool isBdoOverride = false;   // Content wrapped in <bdo> tag
};

// Context for tracking direction during HTML parsing
struct DirectionContext {
  WritingDirection baseDirection = WritingDirection::Natural;
  WritingDirection currentDirection = WritingDirection::Natural;
  int isolationDepth = 0;  // Nesting level of <bdi> tags
  int overrideDepth = 0;   // Nesting level of <bdo> tags

  // Stack to track direction for each element level
  std::vector<WritingDirection> directionStack;
  std::vector<bool> isBdiStack;   // Track if current level is bdi
  std::vector<bool> isBdoStack;   // Track if current level is bdo

  /**
   * Enter an HTML element, updating direction context.
   * @param tag Element tag name (lowercase)
   * @param dirAttr Value of dir attribute, or empty string if not present
   * @param textContent Text content for dir="auto" detection (optional)
   */
  void enterElement(const std::string& tag, const std::string& dirAttr,
                    const std::string& textContent = "");

  /**
   * Exit an HTML element, restoring previous direction context.
   * @param tag Element tag name (lowercase)
   */
  void exitElement(const std::string& tag);

  /**
   * Get the effective direction for current context.
   */
  WritingDirection getEffectiveDirection() const;

  /**
   * Check if currently inside a bdi isolation scope.
   */
  bool isIsolated() const { return isolationDepth > 0; }

  /**
   * Check if currently inside a bdo override scope.
   */
  bool isOverride() const { return overrideDepth > 0; }
};

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
  static FabricRichTagStyle getStyleFromTagStyles(
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
