/**
 * FabricMarkupParser.cpp
 *
 * Shared C++ markup parsing implementation for cross-platform rich text rendering.
 * Extracted from platform-specific implementations to eliminate code duplication.
 */

#include "FabricMarkupParser.h"
#include "parsing/MarkupSegmentParser.h"
#include "parsing/AttributedStringBuilder.h"
#include "parsing/TextNormalizer.h"

namespace facebook::react {

std::string FabricMarkupParser::stripMarkupTags(const std::string& markup) {
  return parsing::stripMarkupTags(markup);
}

std::string FabricMarkupParser::normalizeInterTagWhitespace(const std::string& markup) {
  return parsing::normalizeInterTagWhitespace(markup);
}

std::vector<std::string> FabricMarkupParser::extractLinkUrlsFromSegments(
    const std::vector<FabricRichTextSegment>& segments) {
  return parsing::extractLinkUrlsFromSegments(segments);
}

std::vector<FabricRichTextSegment> FabricMarkupParser::parseMarkupToSegments(const std::string& markup) {
  return parsing::parseMarkupToSegments(markup);
}

FabricMarkupParser::ParseResult FabricMarkupParser::parseMarkupWithLinkUrls(
    const std::string& markup,
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

  if (markup.empty()) {
    return result;
  }

  // Normalize inter-tag whitespace before parsing
  std::string normalizedMarkup = normalizeInterTagWhitespace(markup);

  auto segments = parsing::parseMarkupToSegments(normalizedMarkup);

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

AttributedString FabricMarkupParser::parseMarkupToAttributedString(
    const std::string& markup,
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

  auto result = parseMarkupWithLinkUrls(
      markup, baseFontSize, fontSizeMultiplier, allowFontScaling,
      maxFontSizeMultiplier, lineHeight, fontWeight, fontFamily,
      fontStyle, letterSpacing, color, tagStyles);
  return result.attributedString;
}

} // namespace facebook::react
