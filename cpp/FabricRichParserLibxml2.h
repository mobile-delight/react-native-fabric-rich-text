/**
 * FabricRichParserLibxml2.h
 *
 * Alternative HTML parser implementation using libxml2's SAX parser.
 * Provides identical public API to FabricRichParser for side-by-side
 * comparison and validation before migration.
 *
 * This parser uses libxml2's htmlSAXParser for:
 * - Lenient HTML parsing (handles malformed HTML like browsers)
 * - Automatic HTML entity decoding
 * - Case-insensitive tag matching
 */

#pragma once

#include "FabricRichParser.h"  // Reuse data structures

#include <libxml/HTMLparser.h>
#include <libxml/parser.h>

namespace facebook::react {

/**
 * libxml2-based HTML parser with identical API to FabricRichParser.
 *
 * Uses SAX (event-driven) parsing for efficient single-pass processing.
 * Produces the same output format as FabricRichParser for easy comparison.
 */
class FabricRichParserLibxml2 {
  // SAX callbacks need access to private helper methods
  friend void libxml2StartElement(void* ctx, const xmlChar* name, const xmlChar** attrs);
  friend void libxml2EndElement(void* ctx, const xmlChar* name);
  friend void libxml2Characters(void* ctx, const xmlChar* ch, int len);

 public:
  /**
   * Parse HTML string into an AttributedString.
   * Identical signature to FabricRichParser::parseHtmlToAttributedString.
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
   * Identical signature to FabricRichParser::parseHtmlWithLinkUrls.
   */
  static FabricRichParser::ParseResult parseHtmlWithLinkUrls(
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
   */
  static std::string stripHtmlTags(const std::string& html);

  /**
   * Normalize inter-tag whitespace from source formatting.
   */
  static std::string normalizeInterTagWhitespace(const std::string& html);

  /**
   * Parse HTML into styled text segments using libxml2 SAX parser.
   */
  static std::vector<FabricRichTextSegment> parseHtmlToSegments(const std::string& html);

  /**
   * Extract link URLs from segments.
   */
  static std::vector<std::string> extractLinkUrlsFromSegments(
      const std::vector<FabricRichTextSegment>& segments);

  // Block-level HTML tags
  static const std::unordered_set<std::string> BLOCK_LEVEL_TAGS;

  // Inline formatting tags
  static const std::unordered_set<std::string> INLINE_FORMATTING_TAGS;

  // Default buffer added to fontSize when lineHeight is not specified
  static constexpr float LINE_HEIGHT_BUFFER_DEFAULT = 4.0f;

  // Default link color (iOS system blue)
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
   * Check if a URL scheme is allowed (blocks javascript:, vbscript:, data:).
   */
  static bool isAllowedUrlScheme(const std::string& url);

  /**
   * Extract attribute value from libxml2 attribute array.
   */
  static std::string extractAttribute(const xmlChar** attrs, const char* name);

 private:
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

/**
 * SAX parser context for tracking state during HTML parsing.
 */
struct Libxml2SAXContext {
  // Output
  std::vector<FabricRichTextSegment>* segments;

  // Tag tracking
  std::vector<std::string> tagStack;
  std::vector<std::string> linkUrlStack;
  int linkDepth;

  // RTL/BiDi context
  DirectionContext dirContext;

  // List tracking
  std::vector<FabricRichListContext> listStack;

  // Current segment state
  std::string currentText;
  Float currentScale;
  bool currentBold;
  bool currentItalic;
  bool currentUnderline;
  bool currentStrikethrough;
  bool currentLink;
  std::string currentParentTag;
  std::string currentLinkUrl;
  WritingDirection currentDirection;
  bool currentBdiIsolated;
  bool currentBdoOverride;
  bool followsInlineElement;

  // Script/style skipping
  bool inScript;
  bool inStyle;

  // Helper methods
  void flushSegment(bool closingInlineElement = false);
  void updateStyleFromStack();
  void reset();
};

// SAX callback function declarations
void libxml2StartElement(void* ctx, const xmlChar* name, const xmlChar** attrs);
void libxml2EndElement(void* ctx, const xmlChar* name);
void libxml2Characters(void* ctx, const xmlChar* ch, int len);

} // namespace facebook::react
