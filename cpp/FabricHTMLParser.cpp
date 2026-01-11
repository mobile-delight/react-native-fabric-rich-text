/**
 * FabricHTMLParser.cpp
 *
 * Shared C++ HTML parsing implementation for cross-platform HTML rendering.
 * Extracted from platform-specific implementations to eliminate code duplication.
 */

#include "FabricHTMLParser.h"

#include <react/renderer/graphics/Color.h>
#include <cmath>
#include <cctype>
#include <sstream>

namespace facebook::react {

// Static member definitions
const std::unordered_set<std::string> FabricHTMLParser::BLOCK_LEVEL_TAGS = {
    "p", "div", "h1", "h2", "h3", "h4", "h5", "h6",
    "ul", "ol", "li", "blockquote", "pre", "hr", "br",
    "table", "thead", "tbody", "tr", "th", "td",
    "header", "footer", "section", "article", "nav", "aside"
};

const std::unordered_set<std::string> FabricHTMLParser::INLINE_FORMATTING_TAGS = {
    "strong", "b", "em", "i", "u", "s", "mark", "small", "sub", "sup", "code", "span", "a",
    "bdi", "bdo"  // Bidirectional text elements
};

// =============================================================================
// RTL Support Functions
// =============================================================================

bool isStrongRTL(char32_t codepoint) {
  // Hebrew: U+0590–U+05FF
  if (codepoint >= 0x0590 && codepoint <= 0x05FF) return true;
  // Arabic: U+0600–U+06FF
  if (codepoint >= 0x0600 && codepoint <= 0x06FF) return true;
  // Arabic Supplement: U+0750–U+077F
  if (codepoint >= 0x0750 && codepoint <= 0x077F) return true;
  // Arabic Extended-A: U+08A0–U+08FF
  if (codepoint >= 0x08A0 && codepoint <= 0x08FF) return true;
  // Syriac: U+0700–U+074F
  if (codepoint >= 0x0700 && codepoint <= 0x074F) return true;
  // Thaana: U+0780–U+07BF
  if (codepoint >= 0x0780 && codepoint <= 0x07BF) return true;
  // N'Ko: U+07C0–U+07FF
  if (codepoint >= 0x07C0 && codepoint <= 0x07FF) return true;
  // Hebrew Presentation Forms: U+FB1D–U+FB4F
  if (codepoint >= 0xFB1D && codepoint <= 0xFB4F) return true;
  // Arabic Presentation Forms-A: U+FB50–U+FDFF
  if (codepoint >= 0xFB50 && codepoint <= 0xFDFF) return true;
  // Arabic Presentation Forms-B: U+FE70–U+FEFF
  if (codepoint >= 0xFE70 && codepoint <= 0xFEFF) return true;
  return false;
}

bool isStrongLTR(char32_t codepoint) {
  // Basic Latin letters: U+0041–U+005A (A-Z), U+0061–U+007A (a-z)
  if (codepoint >= 0x0041 && codepoint <= 0x005A) return true;
  if (codepoint >= 0x0061 && codepoint <= 0x007A) return true;
  // Latin Extended-A/B: U+00C0–U+024F
  if (codepoint >= 0x00C0 && codepoint <= 0x024F) return true;
  // Latin Extended Additional: U+1E00–U+1EFF
  if (codepoint >= 0x1E00 && codepoint <= 0x1EFF) return true;
  // Greek: U+0370–U+03FF
  if (codepoint >= 0x0370 && codepoint <= 0x03FF) return true;
  // Cyrillic: U+0400–U+04FF
  if (codepoint >= 0x0400 && codepoint <= 0x04FF) return true;
  // Georgian: U+10A0–U+10FF
  if (codepoint >= 0x10A0 && codepoint <= 0x10FF) return true;
  return false;
}

WritingDirection detectDirectionFromText(const std::string& text) {
  // UTF-8 decode and check first strong directional character
  size_t i = 0;
  while (i < text.size()) {
    char32_t codepoint = 0;
    unsigned char c = static_cast<unsigned char>(text[i]);

    // UTF-8 decoding
    if (c < 0x80) {
      // ASCII
      codepoint = c;
      i += 1;
    } else if ((c & 0xE0) == 0xC0) {
      // 2-byte sequence
      if (i + 1 >= text.size()) break;
      codepoint = ((c & 0x1F) << 6) |
                  (static_cast<unsigned char>(text[i + 1]) & 0x3F);
      i += 2;
    } else if ((c & 0xF0) == 0xE0) {
      // 3-byte sequence
      if (i + 2 >= text.size()) break;
      codepoint = ((c & 0x0F) << 12) |
                  ((static_cast<unsigned char>(text[i + 1]) & 0x3F) << 6) |
                  (static_cast<unsigned char>(text[i + 2]) & 0x3F);
      i += 3;
    } else if ((c & 0xF8) == 0xF0) {
      // 4-byte sequence
      if (i + 3 >= text.size()) break;
      codepoint = ((c & 0x07) << 18) |
                  ((static_cast<unsigned char>(text[i + 1]) & 0x3F) << 12) |
                  ((static_cast<unsigned char>(text[i + 2]) & 0x3F) << 6) |
                  (static_cast<unsigned char>(text[i + 3]) & 0x3F);
      i += 4;
    } else {
      // Invalid UTF-8, skip byte
      i += 1;
      continue;
    }

    // Check for strong directional character
    if (isStrongRTL(codepoint)) {
      return WritingDirection::RightToLeft;
    }
    if (isStrongLTR(codepoint)) {
      return WritingDirection::LeftToRight;
    }
    // Skip neutral characters (numbers, punctuation, whitespace) and continue
  }

  // Default to LTR if no strong character found
  return WritingDirection::LeftToRight;
}

WritingDirection parseDirectionAttribute(const std::string& dirAttr) {
  if (dirAttr.empty()) {
    return WritingDirection::Natural;
  }

  // Convert to lowercase for case-insensitive comparison
  std::string lower = dirAttr;
  for (char& c : lower) {
    c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  }

  if (lower == "rtl") {
    return WritingDirection::RightToLeft;
  }
  if (lower == "ltr") {
    return WritingDirection::LeftToRight;
  }
  if (lower == "auto") {
    // "auto" requires text content to detect - return Natural as a marker
    // The caller should use detectDirectionFromText() for actual detection
    return WritingDirection::Natural;
  }

  // Invalid value - ignore and use inherited direction
  return WritingDirection::Natural;
}

// DirectionContext implementation

void DirectionContext::enterElement(const std::string& tag,
                                    const std::string& dirAttr,
                                    const std::string& textContent) {
  // Save current state to stack
  directionStack.push_back(currentDirection);

  bool isBdi = (tag == "bdi");
  bool isBdo = (tag == "bdo");

  isBdiStack.push_back(isBdi);
  isBdoStack.push_back(isBdo);

  if (isBdi) {
    isolationDepth++;
  }
  if (isBdo) {
    overrideDepth++;
  }

  // Handle dir attribute
  if (!dirAttr.empty()) {
    std::string lowerDir = dirAttr;
    for (char& c : lowerDir) {
      c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }

    if (lowerDir == "rtl") {
      currentDirection = WritingDirection::RightToLeft;
    } else if (lowerDir == "ltr") {
      currentDirection = WritingDirection::LeftToRight;
    } else if (lowerDir == "auto") {
      // For dir="auto", detect from text content
      if (!textContent.empty()) {
        currentDirection = detectDirectionFromText(textContent);
      }
      // If no text content, keep current direction
    }
  } else if (isBdi) {
    // <bdi> without dir attribute defaults to dir="auto" behavior
    if (!textContent.empty()) {
      currentDirection = detectDirectionFromText(textContent);
    }
  }
  // <bdo> without dir attribute has no directional effect (per HTML5 spec)
  // Other elements inherit the current direction
}

void DirectionContext::exitElement(const std::string& tag) {
  if (directionStack.empty()) {
    return;
  }

  // Pop bdi/bdo tracking
  if (!isBdiStack.empty()) {
    if (isBdiStack.back()) {
      isolationDepth--;
    }
    isBdiStack.pop_back();
  }
  if (!isBdoStack.empty()) {
    if (isBdoStack.back()) {
      overrideDepth--;
    }
    isBdoStack.pop_back();
  }

  // Restore previous direction
  currentDirection = directionStack.back();
  directionStack.pop_back();
}

WritingDirection DirectionContext::getEffectiveDirection() const {
  return currentDirection;
}

bool FabricHTMLParser::isBlockLevelTag(const std::string& tag) {
  return BLOCK_LEVEL_TAGS.find(tag) != BLOCK_LEVEL_TAGS.end();
}

bool FabricHTMLParser::isInlineFormattingTag(const std::string& tag) {
  return INLINE_FORMATTING_TAGS.find(tag) != INLINE_FORMATTING_TAGS.end();
}

Float FabricHTMLParser::getHeadingScale(const std::string& tag) {
  if (tag == "h1") return 2.0f;
  if (tag == "h2") return 1.5f;
  if (tag == "h3") return 1.17f;
  if (tag == "h4") return 1.0f;
  if (tag == "h5") return 0.83f;
  if (tag == "h6") return 0.67f;
  return 1.0f;
}

int32_t FabricHTMLParser::parseHexColor(const std::string& colorStr) {
  if (colorStr.empty() || colorStr[0] != '#') {
    return 0;
  }

  std::string hex = colorStr.substr(1);
  if (hex.length() == 3) {
    // Expand #RGB to #RRGGBB
    hex = std::string(1, hex[0]) + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
  }

  if (hex.length() != 6) {
    return 0;
  }

  try {
    unsigned long rgb = std::stoul(hex, nullptr, 16);
    // Validate that the parsed value fits in 24 bits (valid RGB range)
    if (rgb > 0xFFFFFF) {
      return 0;
    }
    // Combine with full alpha (0xFF) and safely cast to int32_t
    uint32_t argb = 0xFF000000u | static_cast<uint32_t>(rgb);
    return static_cast<int32_t>(argb);
  } catch (const std::exception&) {
    return 0;
  }
}

std::string FabricHTMLParser::getStringValueFromStyleObj(
    const std::string& styleObj,
    const std::string& key) {
  std::string searchKey = "\"" + key + "\"";
  size_t keyPos = styleObj.find(searchKey);
  if (keyPos == std::string::npos) {
    return "";
  }

  size_t colonPos = styleObj.find(':', keyPos);
  if (colonPos == std::string::npos) {
    return "";
  }

  size_t valueStart = colonPos + 1;
  while (valueStart < styleObj.size() &&
         std::isspace(static_cast<unsigned char>(styleObj[valueStart]))) {
    valueStart++;
  }

  if (valueStart >= styleObj.size()) {
    return "";
  }

  if (styleObj[valueStart] == '"') {
    size_t quoteEnd = styleObj.find('"', valueStart + 1);
    if (quoteEnd == std::string::npos) {
      return "";
    }
    return styleObj.substr(valueStart + 1, quoteEnd - valueStart - 1);
  }

  return "";
}

Float FabricHTMLParser::getNumericValueFromStyleObj(
    const std::string& styleObj,
    const std::string& key) {
  std::string searchKey = "\"" + key + "\"";
  size_t keyPos = styleObj.find(searchKey);
  if (keyPos == std::string::npos) {
    return NAN;
  }

  size_t colonPos = styleObj.find(':', keyPos);
  if (colonPos == std::string::npos) {
    return NAN;
  }

  size_t valueStart = colonPos + 1;
  while (valueStart < styleObj.size() &&
         std::isspace(static_cast<unsigned char>(styleObj[valueStart]))) {
    valueStart++;
  }

  if (valueStart >= styleObj.size()) {
    return NAN;
  }

  std::string numStr;
  while (valueStart < styleObj.size()) {
    char c = styleObj[valueStart];
    if (std::isdigit(static_cast<unsigned char>(c)) || c == '.' || c == '-') {
      numStr += c;
      valueStart++;
    } else {
      break;
    }
  }

  if (numStr.empty()) {
    return NAN;
  }

  try {
    return std::stof(numStr);
  } catch (...) {
    return NAN;
  }
}

FabricHTMLTagStyle FabricHTMLParser::getStyleFromTagStyles(
    const std::string& tagStyles,
    const std::string& tagName) {
  FabricHTMLTagStyle result;

  if (tagStyles.empty() || tagName.empty()) {
    return result;
  }

  std::string searchPattern = "\"" + tagName + "\"";
  size_t tagPos = tagStyles.find(searchPattern);
  if (tagPos == std::string::npos) {
    return result;
  }

  size_t braceStart = tagStyles.find('{', tagPos);
  if (braceStart == std::string::npos) {
    return result;
  }

  // String-aware brace matching: skip braces inside quoted strings
  int braceCount = 1;
  size_t braceEnd = braceStart + 1;
  bool inString = false;
  char stringDelimiter = '\0';
  while (braceEnd < tagStyles.size() && braceCount > 0) {
    char ch = tagStyles[braceEnd];
    // Handle string delimiters to skip braces inside quoted strings
    if (!inString && (ch == '"' || ch == '\'')) {
      inString = true;
      stringDelimiter = ch;
    } else if (inString && ch == stringDelimiter) {
      // Check for escaped quotes (look back for backslash)
      if (braceEnd == 0 || tagStyles[braceEnd - 1] != '\\') {
        inString = false;
      }
    }
    // Only count braces outside of quoted strings
    if (!inString) {
      if (ch == '{') braceCount++;
      else if (ch == '}') braceCount--;
    }
    braceEnd++;
  }
  if (braceCount != 0) {
    return result;
  }

  std::string styleObj = tagStyles.substr(braceStart, braceEnd - braceStart);

  // Parse color
  std::string colorValue = getStringValueFromStyleObj(styleObj, "color");
  if (!colorValue.empty()) {
    result.color = parseHexColor(colorValue);
  }

  // Parse fontSize
  result.fontSize = getNumericValueFromStyleObj(styleObj, "fontSize");

  // Parse fontWeight
  result.fontWeight = getStringValueFromStyleObj(styleObj, "fontWeight");

  // Parse fontStyle
  result.fontStyle = getStringValueFromStyleObj(styleObj, "fontStyle");

  // Parse textDecorationLine
  result.textDecorationLine = getStringValueFromStyleObj(styleObj, "textDecorationLine");

  return result;
}

std::string FabricHTMLParser::normalizeInterTagWhitespace(const std::string& html) {
  std::string result;
  result.reserve(html.size());

  bool afterBlockClose = false;
  bool beforeFirstTag = true;
  std::string lastClosedTag;

  for (size_t i = 0; i < html.size(); ++i) {
    char c = html[i];

    // Skip all leading whitespace before the first tag
    if (beforeFirstTag && std::isspace(static_cast<unsigned char>(c))) {
      continue;
    }

    if (c == '<') {
      beforeFirstTag = false;
      // Check if this is a closing tag and capture the tag name
      if (i + 1 < html.size() && html[i + 1] == '/') {
        size_t tagStart = i + 2;
        size_t tagEnd = tagStart;
        while (tagEnd < html.size() && html[tagEnd] != '>' &&
               !std::isspace(static_cast<unsigned char>(html[tagEnd]))) {
          tagEnd++;
        }
        lastClosedTag = html.substr(tagStart, tagEnd - tagStart);
        for (char& ch : lastClosedTag) {
          ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
        }
      } else {
        lastClosedTag.clear();
      }
      result += c;
      afterBlockClose = false;
    } else if (c == '>') {
      result += c;
      afterBlockClose = !lastClosedTag.empty() && isBlockLevelTag(lastClosedTag);
    } else if (afterBlockClose && std::isspace(static_cast<unsigned char>(c))) {
      continue;
    } else {
      beforeFirstTag = false;  // Content found - no longer before first tag
      result += c;
      afterBlockClose = false;
    }
  }

  return result;
}

std::string FabricHTMLParser::stripHtmlTags(const std::string& html) {
  std::string result;
  result.reserve(html.size());

  bool inTag = false;
  bool inScript = false;
  bool inStyle = false;
  std::vector<FabricHTMLListContext> listStack;
  std::string tagName;

  for (size_t i = 0; i < html.size(); ++i) {
    char c = html[i];

    if (c == '<') {
      inTag = true;
      tagName.clear();
      continue;
    }

    if (c == '>') {
      inTag = false;

      std::string lowerTag = tagName;
      for (char& ch : lowerTag) {
        ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
      }

      if (lowerTag == "script") {
        inScript = true;
      } else if (lowerTag == "/script") {
        inScript = false;
      } else if (lowerTag == "style") {
        inStyle = true;
      } else if (lowerTag == "/style") {
        inStyle = false;
      } else if (lowerTag == "br" || lowerTag == "br/" || lowerTag == "br /") {
        result += '\n';
      } else if (lowerTag == "/p" || lowerTag == "/div" ||
                 lowerTag == "/h1" || lowerTag == "/h2" || lowerTag == "/h3" ||
                 lowerTag == "/h4" || lowerTag == "/h5" || lowerTag == "/h6") {
        result += "\n\n";
      } else if (lowerTag == "ul") {
        int nestingLevel = static_cast<int>(listStack.size()) + 1;
        listStack.push_back({FabricHTMLListType::Unordered, 0, nestingLevel});
      } else if (lowerTag == "ol") {
        int nestingLevel = static_cast<int>(listStack.size()) + 1;
        listStack.push_back({FabricHTMLListType::Ordered, 0, nestingLevel});
      } else if (lowerTag == "/ul" || lowerTag == "/ol") {
        if (!listStack.empty()) {
          listStack.pop_back();
        }
        if (listStack.empty()) {
          result += "\n\n";
        }
      } else if (lowerTag == "li") {
        if (!result.empty() && result.back() != '\n') {
          result += '\n';
        }
        if (!listStack.empty()) {
          auto& currentList = listStack.back();
          currentList.itemCounter++;
          int indentLevel = static_cast<int>(listStack.size()) - 1;
          if (indentLevel > 0) {
            result += std::string(indentLevel * 4, ' ');
          }
          if (currentList.type == FabricHTMLListType::Ordered) {
            result += std::to_string(currentList.itemCounter) + ". ";
          } else {
            result += "• ";
          }
        } else {
          result += "• ";
        }
      }

      tagName.clear();
      continue;
    }

    if (inTag) {
      if (!std::isspace(static_cast<unsigned char>(c))) {
        tagName += c;
      }
      continue;
    }

    if (!inScript && !inStyle) {
      result += c;
    }
  }

  // Decode common HTML entities
  std::string decoded;
  decoded.reserve(result.size());

  for (size_t i = 0; i < result.size(); ++i) {
    if (result[i] == '&') {
      size_t end = result.find(';', i);
      if (end != std::string::npos && end - i < 10) {
        std::string entity = result.substr(i, end - i + 1);
        if (entity == "&amp;") {
          decoded += '&';
        } else if (entity == "&lt;") {
          decoded += '<';
        } else if (entity == "&gt;") {
          decoded += '>';
        } else if (entity == "&quot;") {
          decoded += '"';
        } else if (entity == "&apos;") {
          decoded += '\'';
        } else if (entity == "&nbsp;") {
          decoded += ' ';
        } else {
          decoded += entity;
        }
        i = end;
        continue;
      }
    }
    decoded += result[i];
  }

  // Normalize whitespace
  std::string normalized;
  normalized.reserve(decoded.size());
  bool lastWasSpace = true;

  for (char c : decoded) {
    if (std::isspace(static_cast<unsigned char>(c))) {
      if (c == '\n') {
        if (!lastWasSpace) {
          normalized += '\n';
          lastWasSpace = true;
        }
      } else if (!lastWasSpace) {
        normalized += ' ';
        lastWasSpace = true;
      }
    } else {
      normalized += c;
      lastWasSpace = false;
    }
  }

  while (!normalized.empty() &&
         std::isspace(static_cast<unsigned char>(normalized.back()))) {
    normalized.pop_back();
  }

  return normalized;
}

bool FabricHTMLParser::isParagraphBreak(const std::string& text) {
  for (char c : text) {
    if (c != '\n' && !std::isspace(static_cast<unsigned char>(c))) {
      return false;
    }
  }
  return !text.empty();
}

std::string FabricHTMLParser::normalizeSegmentText(
    const std::string& text,
    bool preserveNewlines,
    bool preserveLeadingSpace) {
  if (preserveNewlines) {
    std::string result;
    for (char c : text) {
      if (c == '\n') {
        result += '\n';
      }
    }
    return result;
  }

  std::string result;
  result.reserve(text.size());
  bool lastWasSpace = !preserveLeadingSpace;
  bool hasContent = preserveLeadingSpace;

  for (char c : text) {
    if (std::isspace(static_cast<unsigned char>(c))) {
      if (c == '\n') {
        if (hasContent) {
          result += '\n';
          lastWasSpace = false;
        }
      } else if (!lastWasSpace) {
        result += ' ';
        lastWasSpace = true;
      }
    } else {
      result += c;
      lastWasSpace = false;
      hasContent = true;
    }
  }

  return result;
}

std::vector<std::string> FabricHTMLParser::extractLinkUrlsFromSegments(
    const std::vector<FabricHTMLTextSegment>& segments) {
  std::vector<std::string> linkUrls;
  linkUrls.reserve(segments.size());
  for (const auto& segment : segments) {
    linkUrls.push_back(segment.linkUrl);
  }
  return linkUrls;
}

std::vector<FabricHTMLTextSegment> FabricHTMLParser::parseHtmlToSegments(const std::string& html) {
  std::vector<FabricHTMLTextSegment> segments;

  if (html.empty()) {
    return segments;
  }

  std::string currentText;
  Float currentScale = 1.0f;
  bool currentBold = false;
  bool currentItalic = false;
  bool currentUnderline = false;
  bool currentStrikethrough = false;
  bool currentLink = false;
  std::string currentParentTag;
  std::string currentLinkUrl;  // Track the href URL of the current link
  bool nextFollowsInline = false;
  std::vector<std::string> tagStack;
  std::vector<FabricHTMLListContext> listStack;
  std::vector<std::string> linkUrlStack;  // Stack of link URLs for nested <a> tags
  int linkDepth = 0;  // Track nested depth inside <a href="..."> tags

  // RTL Support: Direction context for tracking writing direction
  DirectionContext dirContext;

  bool inTag = false;
  bool inScript = false;
  bool inStyle = false;
  std::string tagName;

  auto flushSegment = [&](bool closingInlineElement = false) {
    if (!currentText.empty()) {
      FabricHTMLTextSegment segment;
      segment.text = currentText;
      segment.fontScale = currentScale;
      segment.isBold = currentBold;
      segment.isItalic = currentItalic;
      segment.isUnderline = currentUnderline;
      segment.isStrikethrough = currentStrikethrough;
      segment.isLink = currentLink;
      segment.followsInlineElement = nextFollowsInline;
      segment.parentTag = currentParentTag;
      segment.linkUrl = currentLinkUrl;
      // RTL Support: Add direction info
      segment.writingDirection = dirContext.getEffectiveDirection();
      segment.isBdiIsolated = dirContext.isIsolated();
      segment.isBdoOverride = dirContext.isOverride();
      segments.push_back(std::move(segment));
      currentText.clear();
    }
    nextFollowsInline = closingInlineElement;
  };

  auto updateStyleFromStack = [&]() {
    currentScale = 1.0f;
    currentBold = false;
    currentItalic = false;
    currentUnderline = false;
    currentStrikethrough = false;
    currentLink = linkDepth > 0;
    currentLinkUrl = linkUrlStack.empty() ? "" : linkUrlStack.back();
    currentParentTag = "";
    for (const auto& tag : tagStack) {
      if (tag[0] == 'h' && tag.size() == 2 && tag[1] >= '1' && tag[1] <= '6') {
        currentScale = getHeadingScale(tag);
        currentBold = true;
      }
      if (tag == "strong" || tag == "b") {
        currentBold = true;
      }
      if (tag == "em" || tag == "i") {
        currentItalic = true;
      }
      if (tag == "u") {
        currentUnderline = true;
      }
      // Links get underline only if they have href (tracked by linkDepth)
      if (tag == "a" && linkDepth > 0) {
        currentUnderline = true;
      }
      if (tag == "s") {
        currentStrikethrough = true;
      }
      if (isInlineFormattingTag(tag)) {
        currentParentTag = tag;
      }
    }
  };

  // Helper to check if a URL scheme is allowed (blocks javascript:, vbscript:, data:)
  auto isAllowedUrlScheme = [](const std::string& url) -> bool {
    std::string lowerUrl = url;
    for (char& c : lowerUrl) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    // Trim leading whitespace
    size_t start = lowerUrl.find_first_not_of(" \t\n\r");
    if (start != std::string::npos) {
      lowerUrl = lowerUrl.substr(start);
    }
    // Block dangerous schemes
    if (lowerUrl.rfind("javascript:", 0) == 0 ||
        lowerUrl.rfind("vbscript:", 0) == 0 ||
        lowerUrl.rfind("data:", 0) == 0) {
      return false;
    }
    return true;
  };

  // Helper to extract href URL from a tag (returns empty string if not found or blocked)
  auto extractHrefUrl = [&isAllowedUrlScheme](const std::string& fullTag) -> std::string {
    // Look for href=" or href=' in the tag
    size_t hrefPos = fullTag.find("href=");
    if (hrefPos == std::string::npos) {
      return "";
    }
    // Make sure there's a value after href=
    size_t valueStart = hrefPos + 5;
    if (valueStart >= fullTag.size()) {
      return "";
    }
    char quote = fullTag[valueStart];
    if (quote == '"' || quote == '\'') {
      size_t valueEnd = fullTag.find(quote, valueStart + 1);
      if (valueEnd != std::string::npos && valueEnd > valueStart + 1) {
        std::string url = fullTag.substr(valueStart + 1, valueEnd - valueStart - 1);
        // Validate URL scheme - reject dangerous protocols
        if (!isAllowedUrlScheme(url)) {
          return "";
        }
        return url;
      }
    }
    return "";
  };

  // Helper to extract dir attribute from a tag
  auto extractDirAttr = [](const std::string& fullTag) -> std::string {
    // Look for dir=" or dir=' in the tag
    size_t dirPos = fullTag.find("dir=");
    if (dirPos == std::string::npos) {
      return "";
    }
    // Make sure there's a value after dir=
    size_t valueStart = dirPos + 4;
    if (valueStart >= fullTag.size()) {
      return "";
    }
    char quote = fullTag[valueStart];
    if (quote == '"' || quote == '\'') {
      size_t valueEnd = fullTag.find(quote, valueStart + 1);
      if (valueEnd != std::string::npos && valueEnd > valueStart + 1) {
        return fullTag.substr(valueStart + 1, valueEnd - valueStart - 1);
      }
    }
    return "";
  };

  // Helper to extract text content from position until the closing tag (for dir="auto" detection)
  // This looks ahead in the HTML without modifying the parse state
  auto extractTextForAutoDetection = [&html](size_t startPos, const std::string& tagToClose) -> std::string {
    std::string textContent;
    bool inNestedTag = false;
    int nestedDepth = 0;
    std::string closingPattern = "</" + tagToClose;

    for (size_t j = startPos; j < html.size(); ++j) {
      char ch = html[j];

      if (ch == '<') {
        inNestedTag = true;
        // Check if this is our closing tag
        std::string remaining = html.substr(j, closingPattern.size() + 1);
        // Convert to lowercase for comparison
        std::string lowerRemaining = remaining;
        for (char& c : lowerRemaining) {
          c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        }
        if (lowerRemaining.find(closingPattern) == 0) {
          // Found closing tag at our level
          if (nestedDepth == 0) {
            break;
          }
          nestedDepth--;
        }
        continue;
      }

      if (ch == '>') {
        inNestedTag = false;
        continue;
      }

      // Collect text content (not inside tags)
      if (!inNestedTag) {
        textContent += ch;
      }
    }

    return textContent;
  };

  for (size_t i = 0; i < html.size(); ++i) {
    char c = html[i];

    if (c == '<') {
      inTag = true;
      tagName.clear();
      continue;
    }

    if (c == '>') {
      inTag = false;

      std::string lowerTag = tagName;
      for (char& ch : lowerTag) {
        ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
      }

      // Remove attributes from tag name
      size_t spacePos = lowerTag.find(' ');
      if (spacePos != std::string::npos) {
        lowerTag = lowerTag.substr(0, spacePos);
      }

      bool isClosing = !lowerTag.empty() && lowerTag[0] == '/';
      std::string cleanTag = isClosing ? lowerTag.substr(1) : lowerTag;

      if (cleanTag == "script") {
        inScript = !isClosing;
      } else if (cleanTag == "style") {
        inStyle = !isClosing;
      } else if (cleanTag == "br") {
        currentText += '\n';
      } else if (isClosing && (cleanTag == "p" || cleanTag == "div" ||
                               cleanTag == "h1" || cleanTag == "h2" || cleanTag == "h3" ||
                               cleanTag == "h4" || cleanTag == "h5" || cleanTag == "h6")) {
        currentText += '\n';
        flushSegment();
        if (!tagStack.empty() && tagStack.back() == cleanTag) {
          tagStack.pop_back();
          // RTL Support: Exit element
          dirContext.exitElement(cleanTag);
          updateStyleFromStack();
        }
        // SECURITY BOUNDARY: Clear any unclosed link state when closing block elements.
        // This prevents malformed HTML like <a href="...">text</p> from making
        // subsequent text clickable. Without this cleanup, an attacker could craft
        // HTML that makes unrelated text appear as a link to a malicious URL.
        linkDepth = 0;
        linkUrlStack.clear();
      } else if (!isClosing && (cleanTag == "h1" || cleanTag == "h2" || cleanTag == "h3" ||
                                cleanTag == "h4" || cleanTag == "h5" || cleanTag == "h6" ||
                                cleanTag == "p" || cleanTag == "div")) {
        flushSegment();
        tagStack.push_back(cleanTag);
        // RTL Support: Extract dir attribute and enter element
        std::string dirAttr = extractDirAttr(tagName);
        // For dir="auto", look ahead to extract text content for direction detection
        std::string textForDetection;
        if (!dirAttr.empty()) {
          std::string lowerDir = dirAttr;
          for (char& ch : lowerDir) {
            ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
          }
          if (lowerDir == "auto") {
            textForDetection = extractTextForAutoDetection(i + 1, cleanTag);
          }
        }
        dirContext.enterElement(cleanTag, dirAttr, textForDetection);
        updateStyleFromStack();
      } else if (!isClosing && isInlineFormattingTag(cleanTag)) {
        flushSegment();
        tagStack.push_back(cleanTag);
        // Track links with href attribute (check original tagName which still has attributes)
        if (cleanTag == "a") {
          std::string url = extractHrefUrl(tagName);
          if (!url.empty()) {
            linkDepth++;
            linkUrlStack.push_back(url);
          }
        }
        // RTL Support: Extract dir attribute and enter element
        std::string dirAttr = extractDirAttr(tagName);
        // For dir="auto" or <bdi> without dir, look ahead to extract text content for direction detection
        std::string textForDetection;
        bool needsAutoDetection = false;
        if (!dirAttr.empty()) {
          std::string lowerDir = dirAttr;
          for (char& ch : lowerDir) {
            ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
          }
          needsAutoDetection = (lowerDir == "auto");
        } else if (cleanTag == "bdi") {
          // <bdi> defaults to dir="auto" behavior
          needsAutoDetection = true;
        }
        if (needsAutoDetection) {
          textForDetection = extractTextForAutoDetection(i + 1, cleanTag);
        }
        dirContext.enterElement(cleanTag, dirAttr, textForDetection);

        // Unicode BiDi control characters for <bdi> and <bdo>
        // Insert isolation/override control characters before content
        if (cleanTag == "bdi") {
          // FSI (U+2068) - First Strong Isolate
          currentText += "\xE2\x81\xA8";  // UTF-8 encoding of U+2068
        } else if (cleanTag == "bdo") {
          // Get effective direction from context for <bdo>
          std::string lowerDir = dirAttr;
          for (char& ch : lowerDir) {
            ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
          }
          if (lowerDir == "rtl") {
            // RLO (U+202E) - Right-to-Left Override
            currentText += "\xE2\x80\xAE";  // UTF-8 encoding of U+202E
          } else if (lowerDir == "ltr") {
            // LRO (U+202D) - Left-to-Right Override
            currentText += "\xE2\x80\xAD";  // UTF-8 encoding of U+202D
          }
          // Note: <bdo> without dir attribute has no directional effect per HTML5 spec
        }

        updateStyleFromStack();
      } else if (isClosing && isInlineFormattingTag(cleanTag)) {
        // Unicode BiDi control characters: close isolation/override before flushing
        if (cleanTag == "bdi") {
          // PDI (U+2069) - Pop Directional Isolate
          currentText += "\xE2\x81\xA9";  // UTF-8 encoding of U+2069
        } else if (cleanTag == "bdo") {
          // Check if the bdo had a dir attribute (we need to look at tag stack)
          // PDF (U+202C) - Pop Directional Format
          // We insert PDF regardless - it's harmless if no override was started
          currentText += "\xE2\x80\xAC";  // UTF-8 encoding of U+202C
        }
        flushSegment(true);
        if (!tagStack.empty() && tagStack.back() == cleanTag) {
          tagStack.pop_back();
          // Pop link URL when closing an <a> tag
          if (cleanTag == "a" && linkDepth > 0) {
            linkDepth--;
            if (!linkUrlStack.empty()) {
              linkUrlStack.pop_back();
            }
          }
          // RTL Support: Exit element
          dirContext.exitElement(cleanTag);
          updateStyleFromStack();
        }
      } else if (!isClosing && cleanTag == "li") {
        if (!currentText.empty() && currentText.back() != '\n') {
          currentText += '\n';
        }
        if (!listStack.empty()) {
          auto& currentList = listStack.back();
          currentList.itemCounter++;
          int indentLevel = static_cast<int>(listStack.size()) - 1;
          if (indentLevel > 0) {
            currentText += std::string(indentLevel * 4, ' ');
          }
          if (currentList.type == FabricHTMLListType::Ordered) {
            currentText += std::to_string(currentList.itemCounter) + ". ";
          } else {
            currentText += "• ";
          }
        } else {
          currentText += "• ";
        }
      } else if (isClosing && cleanTag == "li") {
        // Add period for screen reader pause if content doesn't end with punctuation
        if (!currentText.empty()) {
          char lastChar = currentText.back();
          if (lastChar != '.' && lastChar != '!' && lastChar != '?' && lastChar != ':' && lastChar != ';') {
            currentText += '.';
          }
        }
      } else if (!isClosing && cleanTag == "ul") {
        int nestingLevel = static_cast<int>(listStack.size()) + 1;
        listStack.push_back({FabricHTMLListType::Unordered, 0, nestingLevel});
      } else if (!isClosing && cleanTag == "ol") {
        int nestingLevel = static_cast<int>(listStack.size()) + 1;
        listStack.push_back({FabricHTMLListType::Ordered, 0, nestingLevel});
      } else if (isClosing && (cleanTag == "ul" || cleanTag == "ol")) {
        if (!listStack.empty()) {
          listStack.pop_back();
        }
        if (listStack.empty()) {
          currentText += '\n';
          flushSegment();
        }
      }

      tagName.clear();
      continue;
    }

    if (inTag) {
      tagName += c;
      continue;
    }

    if (!inScript && !inStyle) {
      currentText += c;
    }
  }

  flushSegment();

  return segments;
}

FabricHTMLParser::ParseResult FabricHTMLParser::parseHtmlWithLinkUrls(
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

  auto segments = parseHtmlToSegments(normalizedHtml);

  if (segments.empty()) {
    return result;
  }

  // Trim trailing paragraph break segments
  while (!segments.empty()) {
    const auto& last = segments.back();
    if (isParagraphBreak(last.text)) {
      segments.pop_back();
    } else {
      break;
    }
  }

  if (segments.empty()) {
    return result;
  }

  // Apply font scaling with max multiplier cap
  Float effectiveMultiplier = fontSizeMultiplier;
  if (allowFontScaling) {
    if (!std::isnan(maxFontSizeMultiplier) && maxFontSizeMultiplier > 0) {
      effectiveMultiplier = std::min(fontSizeMultiplier, maxFontSizeMultiplier);
    }
  } else {
    effectiveMultiplier = 1.0f;
  }

  for (size_t segIdx = 0; segIdx < segments.size(); ++segIdx) {
    const auto& segment = segments[segIdx];
    bool isBreak = isParagraphBreak(segment.text);
    std::string normalizedText = normalizeSegmentText(
        segment.text, isBreak, segment.followsInlineElement);

    // Trim trailing whitespace from the last segment
    if (segIdx == segments.size() - 1) {
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
    FabricHTMLTagStyle tagStyle;
    if (!segment.parentTag.empty() && !tagStyles.empty()) {
      tagStyle = getStyleFromTagStyles(tagStyles, segment.parentTag);
    }

    // Calculate fontSize - tagStyles overrides segment fontSize
    Float segmentFontSize = baseFontSize * segment.fontScale * effectiveMultiplier;
    if (!std::isnan(tagStyle.fontSize) && tagStyle.fontSize > 0) {
      segmentFontSize = tagStyle.fontSize * effectiveMultiplier;
    }
    textAttributes.fontSize = segmentFontSize;

    // Apply lineHeight
    Float minLineHeight = segmentFontSize + LINE_HEIGHT_BUFFER_DEFAULT;
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

  // Add periods before list item markers for screen reader pauses
  // This modifies the accessibility label without changing the rendered text
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

  result.accessibilityLabel = std::move(a11yLabel);

  return result;
}

AttributedString FabricHTMLParser::parseHtmlToAttributedString(
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
