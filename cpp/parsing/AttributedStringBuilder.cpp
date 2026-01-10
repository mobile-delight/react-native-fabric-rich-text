/**
 * AttributedStringBuilder.cpp
 *
 * Builds React Native AttributedString from parsed HTML segments.
 */

#include "AttributedStringBuilder.h"
#include "StyleParser.h"
#include "TextNormalizer.h"

#include <react/renderer/graphics/Color.h>
#include <cmath>
#include <cctype>

namespace facebook::react::parsing {

std::string buildAccessibilityLabel(const std::string& plainText) {
  std::string a11yLabel;
  a11yLabel.reserve(plainText.size() + 20);

  for (size_t i = 0; i < plainText.size(); ++i) {
    char c = plainText[i];

    // Check for newline followed by list item marker (digit+period or bullet)
    if (c == '\n' && i + 1 < plainText.size()) {
      char next = plainText[i + 1];
      bool isListMarker = (std::isdigit(static_cast<unsigned char>(next)) ||
                           // Check for bullet character (UTF-8: E2 80 A2)
                           (i + 3 < plainText.size() &&
                            static_cast<unsigned char>(next) == 0xE2 &&
                            static_cast<unsigned char>(plainText[i + 2]) == 0x80 &&
                            static_cast<unsigned char>(plainText[i + 3]) == 0xA2));

      if (isListMarker && !a11yLabel.empty()) {
        // Check if we need to add a period before the newline
        char lastChar = a11yLabel.back();
        if (lastChar != '.' && lastChar != '!' && lastChar != '?' &&
            lastChar != ':' && lastChar != ';') {
          a11yLabel += '.';
        }
      }
    }
    a11yLabel += c;
  }

  return a11yLabel;
}

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
    const std::string& tagStyles) {

  AttributedStringResult result;

  if (segments.empty()) {
    return result;
  }

  // Make a copy of segments to allow trimming
  auto workingSegments = segments;

  // Trim trailing paragraph break segments
  while (!workingSegments.empty()) {
    const auto& last = workingSegments.back();
    if (isParagraphBreak(last.text)) {
      workingSegments.pop_back();
    } else {
      break;
    }
  }

  if (workingSegments.empty()) {
    return result;
  }

  // Apply font scaling with max multiplier cap
  float effectiveMultiplier = fontSizeMultiplier;
  if (allowFontScaling) {
    if (!std::isnan(maxFontSizeMultiplier) && maxFontSizeMultiplier > 0) {
      effectiveMultiplier = std::min(fontSizeMultiplier, maxFontSizeMultiplier);
    }
  } else {
    effectiveMultiplier = 1.0f;
  }

  for (size_t segIdx = 0; segIdx < workingSegments.size(); ++segIdx) {
    const auto& segment = workingSegments[segIdx];
    bool isBreak = isParagraphBreak(segment.text);
    std::string normalizedText = normalizeSegmentText(
        segment.text, isBreak, segment.followsInlineElement);

    // Trim trailing whitespace from the last segment
    if (segIdx == workingSegments.size() - 1) {
      while (!normalizedText.empty() &&
             std::isspace(static_cast<unsigned char>(normalizedText.back()))) {
        normalizedText.pop_back();
      }
    }

    if (normalizedText.empty()) {
      continue;
    }

    auto fragment = AttributedString::Fragment{};
    auto textAttributes = TextAttributes::defaultTextAttributes();

    textAttributes.allowFontScaling = allowFontScaling;

    // Get tagStyles for this segment's parent tag
    FabricRichTagStyle tagStyle;
    if (!segment.parentTag.empty() && !tagStyles.empty()) {
      tagStyle = getStyleFromTagStyles(tagStyles, segment.parentTag);
    }

    // Calculate fontSize - tagStyles overrides segment fontSize
    float segmentFontSize = baseFontSize * segment.fontScale * effectiveMultiplier;
    if (!std::isnan(tagStyle.fontSize) && tagStyle.fontSize > 0) {
      segmentFontSize = tagStyle.fontSize * effectiveMultiplier;
    }
    textAttributes.fontSize = segmentFontSize;

    // Apply lineHeight
    float minLineHeight = segmentFontSize + LINE_HEIGHT_BUFFER_DEFAULT;
    if (!std::isnan(lineHeight) && lineHeight > 0) {
      textAttributes.lineHeight = std::max(lineHeight, minLineHeight);
    } else {
      textAttributes.lineHeight = minLineHeight;
    }

    // Apply fontWeight
    bool isBold = segment.isBold;
    if (!tagStyle.fontWeight.empty()) {
      isBold = (tagStyle.fontWeight == "bold" || tagStyle.fontWeight == "700" ||
                tagStyle.fontWeight == "800" || tagStyle.fontWeight == "900");
    }
    if (isBold) {
      textAttributes.fontWeight = FontWeight::Bold;
    } else if (!fontWeight.empty()) {
      if (fontWeight == "bold" || fontWeight == "700" ||
          fontWeight == "800" || fontWeight == "900") {
        textAttributes.fontWeight = FontWeight::Bold;
      }
    }

    // Apply fontFamily
    if (!fontFamily.empty()) {
      textAttributes.fontFamily = fontFamily;
    }

    // Apply fontStyle
    bool isItalic = segment.isItalic;
    if (!tagStyle.fontStyle.empty()) {
      isItalic = (tagStyle.fontStyle == "italic");
    }
    if (isItalic) {
      textAttributes.fontStyle = FontStyle::Italic;
    } else if (!fontStyle.empty()) {
      if (fontStyle == "italic") {
        textAttributes.fontStyle = FontStyle::Italic;
      }
    }

    // Apply letterSpacing
    if (!std::isnan(letterSpacing)) {
      textAttributes.letterSpacing = letterSpacing;
    }

    // Apply textDecorationLine
    bool hasUnderline = segment.isUnderline;
    bool hasStrikethrough = segment.isStrikethrough;

    if (!tagStyle.textDecorationLine.empty()) {
      if (tagStyle.textDecorationLine == "underline") {
        hasUnderline = true;
        hasStrikethrough = false;
      } else if (tagStyle.textDecorationLine == "line-through") {
        hasUnderline = false;
        hasStrikethrough = true;
      } else if (tagStyle.textDecorationLine == "underline line-through" ||
                 tagStyle.textDecorationLine == "line-through underline") {
        hasUnderline = true;
        hasStrikethrough = true;
      } else if (tagStyle.textDecorationLine == "none") {
        hasUnderline = false;
        hasStrikethrough = false;
      }
    }

    if (hasUnderline && hasStrikethrough) {
      textAttributes.textDecorationLineType = TextDecorationLineType::UnderlineStrikethrough;
    } else if (hasUnderline) {
      textAttributes.textDecorationLineType = TextDecorationLineType::Underline;
    } else if (hasStrikethrough) {
      textAttributes.textDecorationLineType = TextDecorationLineType::Strikethrough;
    }

    // Apply foreground color
    // Priority: tagStyle.color > default link color (for links with href) > base color
    int32_t colorToApply = tagStyle.color;
    if (colorToApply == 0) {
      if (segment.isLink) {
        colorToApply = DEFAULT_LINK_COLOR;
      } else if (color != 0) {
        colorToApply = color;
      }
    }

    if (colorToApply != 0) {
      uint8_t a = (colorToApply >> 24) & 0xFF;
      uint8_t r = (colorToApply >> 16) & 0xFF;
      uint8_t g = (colorToApply >> 8) & 0xFF;
      uint8_t b = colorToApply & 0xFF;
      textAttributes.foregroundColor = colorFromRGBA(r, g, b, a);
    }

    fragment.string = normalizedText;
    fragment.textAttributes = textAttributes;

    result.attributedString.appendFragment(std::move(fragment));
    result.linkUrls.push_back(segment.linkUrl);
  }

  // Build accessibility label with proper pauses between list items
  // Get the plain text from the attributed string
  std::string plainText;
  for (const auto& fragment : result.attributedString.getFragments()) {
    plainText += fragment.string;
  }

  result.accessibilityLabel = buildAccessibilityLabel(plainText);

  return result;
}

} // namespace facebook::react::parsing
