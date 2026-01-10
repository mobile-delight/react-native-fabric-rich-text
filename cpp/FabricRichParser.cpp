/**
 * FabricRichParser.cpp
 *
 * Shared C++ HTML parsing implementation for cross-platform HTML rendering.
 * Extracted from platform-specific implementations to eliminate code duplication.
 */

#include "FabricRichParser.h"
#include "parsing/HtmlSegmentParser.h"
#include "parsing/AttributedStringBuilder.h"
#include "parsing/TextNormalizer.h"

namespace facebook::react {

std::string FabricRichParser::stripHtmlTags(const std::string& html) {
  return parsing::stripHtmlTags(html);
}

std::string FabricRichParser::normalizeInterTagWhitespace(const std::string& html) {
  return parsing::normalizeInterTagWhitespace(html);
}

std::vector<std::string> FabricRichParser::extractLinkUrlsFromSegments(
    const std::vector<FabricRichTextSegment>& segments) {
  return parsing::extractLinkUrlsFromSegments(segments);
}

std::vector<FabricRichTextSegment> FabricRichParser::parseHtmlToSegments(const std::string& html) {
  return parsing::parseHtmlToSegments(html);
}

FabricRichParser::ParseResult FabricRichParser::parseHtmlWithLinkUrls(
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
    const std::string& tagStyles) {

  ParseResult result;

  if (html.empty()) {
    return result;
  }

  // Normalize inter-tag whitespace before parsing
  std::string normalizedHtml = normalizeInterTagWhitespace(html);

  auto segments = parsing::parseHtmlToSegments(normalizedHtml);

  if (segments.empty()) {
    return result;
  }

  // Delegate to AttributedStringBuilder
  auto buildResult = parsing::buildAttributedString(
      segments, baseFontSize, fontSizeMultiplier, allowFontScaling,
      maxFontSizeMultiplier, lineHeight, fontWeight, fontFamily,
      fontStyle, letterSpacing, color, tagStyles);

  result.attributedString = std::move(buildResult.attributedString);
  result.linkUrls = std::move(buildResult.linkUrls);
  result.accessibilityLabel = std::move(buildResult.accessibilityLabel);

  return result;
}

AttributedString FabricRichParser::parseHtmlToAttributedString(
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
    const std::string& tagStyles) {

  auto result = parseHtmlWithLinkUrls(
      html, baseFontSize, fontSizeMultiplier, allowFontScaling,
      maxFontSizeMultiplier, lineHeight, fontWeight, fontFamily,
      fontStyle, letterSpacing, color, tagStyles);
  return result.attributedString;
}

} // namespace facebook::react
