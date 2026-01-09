/**
 * FabricRichParserLibxml2.cpp
 *
 * libxml2 SAX-based HTML parser implementation.
 * Provides identical output to FabricRichParser for side-by-side comparison.
 */

#include "FabricRichParserLibxml2.h"

#include <react/renderer/graphics/Color.h>
#include <cmath>
#include <cctype>
#include <sstream>
#include <algorithm>
#include <cstring>

namespace facebook::react {

// Static member definitions - same as original parser
const std::unordered_set<std::string> FabricRichParserLibxml2::BLOCK_LEVEL_TAGS = {
    "p", "div", "h1", "h2", "h3", "h4", "h5", "h6",
    "ul", "ol", "li", "blockquote", "pre", "hr", "br",
    "table", "thead", "tbody", "tr", "th", "td",
    "header", "footer", "section", "article", "nav", "aside"
};

const std::unordered_set<std::string> FabricRichParserLibxml2::INLINE_FORMATTING_TAGS = {
    "strong", "b", "em", "i", "u", "s", "mark", "small", "sub", "sup", "code", "span", "a",
    "bdi", "bdo"
};

// =============================================================================
// Helper functions - same logic as original parser
// =============================================================================

bool FabricRichParserLibxml2::isBlockLevelTag(const std::string& tag) {
  return BLOCK_LEVEL_TAGS.count(tag) > 0;
}

bool FabricRichParserLibxml2::isInlineFormattingTag(const std::string& tag) {
  return INLINE_FORMATTING_TAGS.count(tag) > 0;
}

Float FabricRichParserLibxml2::getHeadingScale(const std::string& tag) {
  if (tag == "h1") return 2.0f;
  if (tag == "h2") return 1.5f;
  if (tag == "h3") return 1.17f;
  if (tag == "h4") return 1.0f;
  if (tag == "h5") return 0.83f;
  if (tag == "h6") return 0.67f;
  return 1.0f;
}

int32_t FabricRichParserLibxml2::parseHexColor(const std::string& colorStr) {
  if (colorStr.empty() || colorStr[0] != '#') {
    return 0;
  }
  std::string hex = colorStr.substr(1);
  if (hex.size() == 3) {
    // Expand shorthand (#RGB -> #RRGGBB)
    std::string expanded;
    for (char c : hex) {
      expanded += c;
      expanded += c;
    }
    hex = expanded;
  }
  if (hex.size() != 6) {
    return 0;
  }
  try {
    unsigned int rgb = std::stoul(hex, nullptr, 16);
    return static_cast<int32_t>(0xFF000000 | rgb);
  } catch (...) {
    return 0;
  }
}

std::string FabricRichParserLibxml2::getStringValueFromStyleObj(
    const std::string& styleObj,
    const std::string& key) {
  std::string searchKey = "\"" + key + "\"";
  size_t keyPos = styleObj.find(searchKey);
  if (keyPos == std::string::npos) {
    return "";
  }
  size_t colonPos = styleObj.find(':', keyPos + searchKey.size());
  if (colonPos == std::string::npos) {
    return "";
  }
  size_t valueStart = styleObj.find_first_not_of(" \t\n\r", colonPos + 1);
  if (valueStart == std::string::npos) {
    return "";
  }
  if (styleObj[valueStart] == '"') {
    size_t valueEnd = styleObj.find('"', valueStart + 1);
    if (valueEnd != std::string::npos) {
      return styleObj.substr(valueStart + 1, valueEnd - valueStart - 1);
    }
  }
  return "";
}

Float FabricRichParserLibxml2::getNumericValueFromStyleObj(
    const std::string& styleObj,
    const std::string& key) {
  std::string searchKey = "\"" + key + "\"";
  size_t keyPos = styleObj.find(searchKey);
  if (keyPos == std::string::npos) {
    return NAN;
  }
  size_t colonPos = styleObj.find(':', keyPos + searchKey.size());
  if (colonPos == std::string::npos) {
    return NAN;
  }
  size_t valueStart = styleObj.find_first_not_of(" \t\n\r", colonPos + 1);
  if (valueStart == std::string::npos) {
    return NAN;
  }
  size_t valueEnd = styleObj.find_first_of(",}", valueStart);
  if (valueEnd == std::string::npos) {
    valueEnd = styleObj.size();
  }
  std::string valueStr = styleObj.substr(valueStart, valueEnd - valueStart);
  // Trim whitespace
  while (!valueStr.empty() && std::isspace(static_cast<unsigned char>(valueStr.back()))) {
    valueStr.pop_back();
  }
  try {
    return std::stof(valueStr);
  } catch (...) {
    return NAN;
  }
}

FabricRichTagStyle FabricRichParserLibxml2::getStyleFromTagStyles(
    const std::string& tagStyles,
    const std::string& tagName) {
  FabricRichTagStyle style;
  if (tagStyles.empty() || tagName.empty()) {
    return style;
  }
  // Find the style object for this tag
  std::string searchKey = "\"" + tagName + "\"";
  size_t keyPos = tagStyles.find(searchKey);
  if (keyPos == std::string::npos) {
    return style;
  }
  // Find the opening brace
  size_t bracePos = tagStyles.find('{', keyPos);
  if (bracePos == std::string::npos) {
    return style;
  }
  // Find matching closing brace
  int braceCount = 1;
  size_t endPos = bracePos + 1;
  while (endPos < tagStyles.size() && braceCount > 0) {
    if (tagStyles[endPos] == '{') braceCount++;
    if (tagStyles[endPos] == '}') braceCount--;
    endPos++;
  }
  std::string styleObj = tagStyles.substr(bracePos, endPos - bracePos);

  // Extract properties
  std::string colorStr = getStringValueFromStyleObj(styleObj, "color");
  if (!colorStr.empty()) {
    style.color = parseHexColor(colorStr);
  }
  style.fontSize = getNumericValueFromStyleObj(styleObj, "fontSize");
  style.fontWeight = getStringValueFromStyleObj(styleObj, "fontWeight");
  style.fontStyle = getStringValueFromStyleObj(styleObj, "fontStyle");
  style.textDecorationLine = getStringValueFromStyleObj(styleObj, "textDecorationLine");

  return style;
}

std::string FabricRichParserLibxml2::normalizeSegmentText(
    const std::string& text,
    bool preserveNewlines,
    bool preserveLeadingSpace) {
  if (text.empty()) return "";

  std::string result;
  result.reserve(text.size());
  bool lastWasSpace = !preserveLeadingSpace;

  for (char c : text) {
    if (c == '\n') {
      if (preserveNewlines) {
        result += '\n';
        lastWasSpace = true;
      } else {
        if (!lastWasSpace) {
          result += ' ';
          lastWasSpace = true;
        }
      }
    } else if (std::isspace(static_cast<unsigned char>(c))) {
      if (!lastWasSpace) {
        result += ' ';
        lastWasSpace = true;
      }
    } else {
      result += c;
      lastWasSpace = false;
    }
  }
  return result;
}

bool FabricRichParserLibxml2::isParagraphBreak(const std::string& text) {
  for (char c : text) {
    if (c != '\n' && !std::isspace(static_cast<unsigned char>(c))) {
      return false;
    }
  }
  return !text.empty() && text.find('\n') != std::string::npos;
}

bool FabricRichParserLibxml2::isAllowedUrlScheme(const std::string& url) {
  std::string lowerUrl = url;
  for (char& c : lowerUrl) {
    c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  }
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
}

std::string FabricRichParserLibxml2::extractAttribute(const xmlChar** attrs, const char* name) {
  if (attrs == nullptr) {
    return "";
  }
  for (int i = 0; attrs[i] != nullptr; i += 2) {
    if (attrs[i + 1] != nullptr) {
      const char* attrName = reinterpret_cast<const char*>(attrs[i]);
      // Case-insensitive comparison
      std::string lowerAttr = attrName;
      for (char& c : lowerAttr) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
      }
      if (lowerAttr == name) {
        return std::string(reinterpret_cast<const char*>(attrs[i + 1]));
      }
    }
  }
  return "";
}

// =============================================================================
// SAX Context Methods
// =============================================================================

void Libxml2SAXContext::reset() {
  tagStack.clear();
  linkUrlStack.clear();
  linkDepth = 0;
  dirContext = DirectionContext{};
  listStack.clear();
  currentText.clear();
  currentScale = 1.0f;
  currentBold = false;
  currentItalic = false;
  currentUnderline = false;
  currentStrikethrough = false;
  currentLink = false;
  currentParentTag.clear();
  currentLinkUrl.clear();
  currentDirection = WritingDirection::Natural;
  currentBdiIsolated = false;
  currentBdoOverride = false;
  followsInlineElement = false;
  inScript = false;
  inStyle = false;
}

void Libxml2SAXContext::flushSegment(bool closingInlineElement) {
  if (!currentText.empty() && segments != nullptr) {
    FabricRichTextSegment segment;
    segment.text = currentText;
    segment.fontScale = currentScale;
    segment.isBold = currentBold;
    segment.isItalic = currentItalic;
    segment.isUnderline = currentUnderline;
    segment.isStrikethrough = currentStrikethrough;
    segment.isLink = currentLink;
    segment.followsInlineElement = followsInlineElement;  // Use CURRENT state
    segment.parentTag = currentParentTag;
    segment.linkUrl = currentLinkUrl;
    segment.writingDirection = dirContext.getEffectiveDirection();
    segment.isBdiIsolated = dirContext.isIsolated();
    segment.isBdoOverride = dirContext.isOverride();
    segments->push_back(std::move(segment));
    currentText.clear();
  }
  // Set state for NEXT segment (like original parser's nextFollowsInline pattern)
  followsInlineElement = closingInlineElement;
}

void Libxml2SAXContext::updateStyleFromStack() {
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
      currentScale = FabricRichParserLibxml2::getHeadingScale(tag);
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
    if (tag == "a" && linkDepth > 0) {
      currentUnderline = true;
    }
    if (tag == "s") {
      currentStrikethrough = true;
    }
    if (FabricRichParserLibxml2::isInlineFormattingTag(tag)) {
      currentParentTag = tag;
    }
  }
}

// =============================================================================
// SAX Callbacks
// =============================================================================

void libxml2StartElement(void* ctx, const xmlChar* name, const xmlChar** attrs) {
  auto* context = static_cast<Libxml2SAXContext*>(ctx);
  if (context == nullptr) return;

  std::string tagName = reinterpret_cast<const char*>(name);
  // Convert to lowercase
  for (char& c : tagName) {
    c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  }

  // Handle script/style
  if (tagName == "script") {
    context->inScript = true;
    return;
  }
  if (tagName == "style") {
    context->inStyle = true;
    return;
  }

  // Skip content processing if in script/style
  if (context->inScript || context->inStyle) {
    return;
  }

  // Handle br
  if (tagName == "br") {
    context->currentText += '\n';
    return;
  }

  // Handle hr
  if (tagName == "hr") {
    context->currentText += '\n';
    return;
  }

  // Block-level opening tags
  if (tagName == "h1" || tagName == "h2" || tagName == "h3" ||
      tagName == "h4" || tagName == "h5" || tagName == "h6" ||
      tagName == "p" || tagName == "div") {
    context->flushSegment();
    context->tagStack.push_back(tagName);

    // RTL Support: Extract dir attribute
    std::string dirAttr = FabricRichParserLibxml2::extractAttribute(attrs, "dir");
    context->dirContext.enterElement(tagName, dirAttr, "");
    context->updateStyleFromStack();
    return;
  }

  // Inline formatting tags
  if (FabricRichParserLibxml2::isInlineFormattingTag(tagName)) {
    context->flushSegment();
    context->tagStack.push_back(tagName);

    // Track links with href attribute
    if (tagName == "a") {
      std::string url = FabricRichParserLibxml2::extractAttribute(attrs, "href");
      if (!url.empty() && FabricRichParserLibxml2::isAllowedUrlScheme(url)) {
        context->linkDepth++;
        context->linkUrlStack.push_back(url);
      }
    }

    // RTL Support
    std::string dirAttr = FabricRichParserLibxml2::extractAttribute(attrs, "dir");
    context->dirContext.enterElement(tagName, dirAttr, "");

    // Unicode BiDi control characters
    if (tagName == "bdi") {
      // FSI (U+2068)
      context->currentText += "\xE2\x81\xA8";
    } else if (tagName == "bdo") {
      std::string lowerDir = dirAttr;
      for (char& c : lowerDir) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
      }
      if (lowerDir == "rtl") {
        // RLO (U+202E)
        context->currentText += "\xE2\x80\xAE";
      } else if (lowerDir == "ltr") {
        // LRO (U+202D)
        context->currentText += "\xE2\x80\xAD";
      }
    }

    context->updateStyleFromStack();
    return;
  }

  // List handling
  if (tagName == "ul") {
    int nestingLevel = static_cast<int>(context->listStack.size()) + 1;
    context->listStack.push_back({FabricRichListType::Unordered, 0, nestingLevel});
    return;
  }
  if (tagName == "ol") {
    int nestingLevel = static_cast<int>(context->listStack.size()) + 1;
    context->listStack.push_back({FabricRichListType::Ordered, 0, nestingLevel});
    return;
  }
  if (tagName == "li") {
    if (!context->currentText.empty() && context->currentText.back() != '\n') {
      context->currentText += '\n';
    }
    if (!context->listStack.empty()) {
      auto& currentList = context->listStack.back();
      currentList.itemCounter++;
      int indentLevel = static_cast<int>(context->listStack.size()) - 1;
      if (indentLevel > 0) {
        context->currentText += std::string(indentLevel * 4, ' ');
      }
      if (currentList.type == FabricRichListType::Ordered) {
        context->currentText += std::to_string(currentList.itemCounter) + ". ";
      } else {
        context->currentText += "• ";
      }
    } else {
      context->currentText += "• ";
    }
    return;
  }
}

void libxml2EndElement(void* ctx, const xmlChar* name) {
  auto* context = static_cast<Libxml2SAXContext*>(ctx);
  if (context == nullptr) return;

  std::string tagName = reinterpret_cast<const char*>(name);
  // Convert to lowercase
  for (char& c : tagName) {
    c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  }

  // Handle script/style
  if (tagName == "script") {
    context->inScript = false;
    return;
  }
  if (tagName == "style") {
    context->inStyle = false;
    return;
  }

  // Skip content processing if in script/style
  if (context->inScript || context->inStyle) {
    return;
  }

  // Block-level closing tags
  if (tagName == "p" || tagName == "div" ||
      tagName == "h1" || tagName == "h2" || tagName == "h3" ||
      tagName == "h4" || tagName == "h5" || tagName == "h6") {
    context->currentText += '\n';
    context->flushSegment();
    if (!context->tagStack.empty() && context->tagStack.back() == tagName) {
      context->tagStack.pop_back();
      context->dirContext.exitElement(tagName);
      context->updateStyleFromStack();
    }
    // SECURITY BOUNDARY: Clear any unclosed link state
    context->linkDepth = 0;
    context->linkUrlStack.clear();
    return;
  }

  // Inline formatting closing tags
  if (FabricRichParserLibxml2::isInlineFormattingTag(tagName)) {
    // Unicode BiDi control characters
    if (tagName == "bdi") {
      // PDI (U+2069)
      context->currentText += "\xE2\x81\xA9";
    } else if (tagName == "bdo") {
      // PDF (U+202C)
      context->currentText += "\xE2\x80\xAC";
    }

    // Flush with closingInlineElement=true so NEXT segment preserves leading space
    context->flushSegment(true);

    if (!context->tagStack.empty() && context->tagStack.back() == tagName) {
      context->tagStack.pop_back();
      if (tagName == "a" && context->linkDepth > 0) {
        context->linkDepth--;
        if (!context->linkUrlStack.empty()) {
          context->linkUrlStack.pop_back();
        }
      }
      context->dirContext.exitElement(tagName);
      context->updateStyleFromStack();
    }
    return;
  }

  // List handling
  if (tagName == "li") {
    // Add period for screen reader pause
    if (!context->currentText.empty()) {
      char lastChar = context->currentText.back();
      if (lastChar != '.' && lastChar != '!' && lastChar != '?' &&
          lastChar != ':' && lastChar != ';') {
        context->currentText += '.';
      }
    }
    return;
  }
  if (tagName == "ul" || tagName == "ol") {
    if (!context->listStack.empty()) {
      context->listStack.pop_back();
    }
    if (context->listStack.empty()) {
      context->currentText += '\n';
      context->flushSegment();
    }
    return;
  }
}

void libxml2Characters(void* ctx, const xmlChar* ch, int len) {
  auto* context = static_cast<Libxml2SAXContext*>(ctx);
  if (context == nullptr) return;

  // Skip if in script or style
  if (context->inScript || context->inStyle) {
    return;
  }

  std::string text(reinterpret_cast<const char*>(ch), len);
  context->currentText += text;
}

// =============================================================================
// Main Parser Functions
// =============================================================================

std::vector<FabricRichTextSegment> FabricRichParserLibxml2::parseHtmlToSegments(
    const std::string& html) {
  std::vector<FabricRichTextSegment> segments;

  if (html.empty()) {
    return segments;
  }

  // Initialize SAX handler
  htmlSAXHandler saxHandler;
  memset(&saxHandler, 0, sizeof(saxHandler));
  saxHandler.startElement = libxml2StartElement;
  saxHandler.endElement = libxml2EndElement;
  saxHandler.characters = libxml2Characters;

  // Initialize context
  Libxml2SAXContext context;
  context.reset();
  context.segments = &segments;

  // Parse HTML using libxml2's HTML parser (lenient, handles malformed HTML)
  // Note: htmlSAXParseDoc is deprecated in libxml2 2.12+ but is the correct API for
  // SAX-based HTML parsing. The replacement htmlCtxtReadDoc doesn't support SAX callbacks.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  htmlDocPtr doc = htmlSAXParseDoc(
      reinterpret_cast<const xmlChar*>(html.c_str()),
      "UTF-8",
      &saxHandler,
      &context);
#pragma GCC diagnostic pop

  // Flush any remaining text
  context.flushSegment();

  // Free document if created
  if (doc != nullptr) {
    xmlFreeDoc(doc);
  }

  return segments;
}

std::string FabricRichParserLibxml2::stripHtmlTags(const std::string& html) {
  auto segments = parseHtmlToSegments(html);
  std::string result;
  for (const auto& segment : segments) {
    result += segment.text;
  }
  // Normalize whitespace
  std::string normalized;
  bool lastWasSpace = true;
  for (char c : result) {
    if (c == '\n') {
      if (!normalized.empty() && normalized.back() != '\n') {
        normalized += '\n';
      }
      lastWasSpace = true;
    } else if (std::isspace(static_cast<unsigned char>(c))) {
      if (!lastWasSpace) {
        normalized += ' ';
        lastWasSpace = true;
      }
    } else {
      normalized += c;
      lastWasSpace = false;
    }
  }
  return normalized;
}

std::string FabricRichParserLibxml2::normalizeInterTagWhitespace(const std::string& html) {
  // Same implementation as original parser
  if (html.empty()) return html;

  std::string result;
  result.reserve(html.size());

  bool inTag = false;
  bool lastWasBlockClose = false;
  std::string whitespaceBuffer;

  for (size_t i = 0; i < html.size(); ++i) {
    char c = html[i];

    if (c == '<') {
      inTag = true;
      if (lastWasBlockClose && !whitespaceBuffer.empty()) {
        // Skip whitespace between block elements
        whitespaceBuffer.clear();
      } else if (!whitespaceBuffer.empty()) {
        result += whitespaceBuffer;
        whitespaceBuffer.clear();
      }
      result += c;
      lastWasBlockClose = false;
      continue;
    }

    if (c == '>') {
      inTag = false;
      result += c;
      // Check if this was a block-level closing tag
      size_t tagStart = result.rfind('<');
      if (tagStart != std::string::npos) {
        std::string tag = result.substr(tagStart);
        std::string lowerTag = tag;
        for (char& ch : lowerTag) {
          ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
        }
        if (lowerTag.find("</p>") != std::string::npos ||
            lowerTag.find("</div>") != std::string::npos ||
            lowerTag.find("</h") != std::string::npos) {
          lastWasBlockClose = true;
        }
      }
      continue;
    }

    if (inTag) {
      result += c;
      continue;
    }

    if (std::isspace(static_cast<unsigned char>(c))) {
      whitespaceBuffer += c;
    } else {
      if (!whitespaceBuffer.empty()) {
        if (!lastWasBlockClose) {
          result += whitespaceBuffer;
        }
        whitespaceBuffer.clear();
      }
      result += c;
      lastWasBlockClose = false;
    }
  }

  return result;
}

std::vector<std::string> FabricRichParserLibxml2::extractLinkUrlsFromSegments(
    const std::vector<FabricRichTextSegment>& segments) {
  std::vector<std::string> urls;
  urls.reserve(segments.size());
  for (const auto& segment : segments) {
    urls.push_back(segment.isLink ? segment.linkUrl : "");
  }
  return urls;
}

FabricRichParser::ParseResult FabricRichParserLibxml2::parseHtmlWithLinkUrls(
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

  FabricRichParser::ParseResult result;

  if (html.empty()) {
    return result;
  }

  // Normalize inter-tag whitespace
  std::string normalizedHtml = normalizeInterTagWhitespace(html);

  auto segments = parseHtmlToSegments(normalizedHtml);

  if (segments.empty()) {
    return result;
  }

  // Trim trailing paragraph breaks
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

  // Apply font scaling
  Float effectiveMultiplier = fontSizeMultiplier;
  if (allowFontScaling) {
    if (!std::isnan(maxFontSizeMultiplier) && maxFontSizeMultiplier > 0) {
      effectiveMultiplier = std::min(fontSizeMultiplier, maxFontSizeMultiplier);
    }
  } else {
    effectiveMultiplier = 1.0f;
  }

  // Build accessibility label
  std::string accessibilityLabel;

  for (size_t segIdx = 0; segIdx < segments.size(); ++segIdx) {
    const auto& segment = segments[segIdx];
    bool isBreak = isParagraphBreak(segment.text);
    std::string normalizedText = normalizeSegmentText(
        segment.text, isBreak, segment.followsInlineElement);

    // Trim trailing whitespace from last segment
    if (segIdx == segments.size() - 1) {
      while (!normalizedText.empty() &&
             std::isspace(static_cast<unsigned char>(normalizedText.back()))) {
        normalizedText.pop_back();
      }
    }

    if (normalizedText.empty()) {
      continue;
    }

    // Build accessibility label
    accessibilityLabel += normalizedText;

    auto fragment = AttributedString::Fragment{};
    auto textAttributes = TextAttributes::defaultTextAttributes();

    textAttributes.allowFontScaling = allowFontScaling;

    // Get tagStyles for this segment
    FabricRichTagStyle tagStyle;
    if (!segment.parentTag.empty() && !tagStyles.empty()) {
      tagStyle = getStyleFromTagStyles(tagStyles, segment.parentTag);
    }

    // Calculate fontSize
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
    if (!fontWeight.empty()) {
      if (fontWeight == "bold" || fontWeight == "700" ||
          fontWeight == "800" || fontWeight == "900") {
        textAttributes.fontWeight = isBold ? FontWeight::Black : FontWeight::Bold;
      } else {
        textAttributes.fontWeight = isBold ? FontWeight::Bold : FontWeight::Regular;
      }
    } else {
      textAttributes.fontWeight = isBold ? FontWeight::Bold : FontWeight::Regular;
    }

    // Apply fontStyle
    bool isItalic = segment.isItalic;
    if (!tagStyle.fontStyle.empty()) {
      isItalic = (tagStyle.fontStyle == "italic");
    }
    if (!fontStyle.empty() && fontStyle == "italic") {
      isItalic = true;
    }
    textAttributes.fontStyle = isItalic ? FontStyle::Italic : FontStyle::Normal;

    // Apply fontFamily
    if (!fontFamily.empty()) {
      textAttributes.fontFamily = fontFamily;
    }

    // Apply letterSpacing
    if (!std::isnan(letterSpacing)) {
      textAttributes.letterSpacing = letterSpacing;
    }

    // Apply text decorations
    bool hasUnderline = segment.isUnderline;
    bool hasStrikethrough = segment.isStrikethrough;
    if (!tagStyle.textDecorationLine.empty()) {
      hasUnderline = (tagStyle.textDecorationLine.find("underline") != std::string::npos);
      hasStrikethrough = (tagStyle.textDecorationLine.find("line-through") != std::string::npos);
    }

    if (hasUnderline && hasStrikethrough) {
      textAttributes.textDecorationLineType = TextDecorationLineType::UnderlineStrikethrough;
    } else if (hasUnderline) {
      textAttributes.textDecorationLineType = TextDecorationLineType::Underline;
    } else if (hasStrikethrough) {
      textAttributes.textDecorationLineType = TextDecorationLineType::Strikethrough;
    } else {
      textAttributes.textDecorationLineType = TextDecorationLineType::None;
    }

    // Apply color
    int32_t segmentColor = color;
    if (tagStyle.color != 0) {
      segmentColor = tagStyle.color;
    }
    if (segment.isLink && segmentColor == 0) {
      segmentColor = DEFAULT_LINK_COLOR;
    }
    if (segmentColor != 0) {
      textAttributes.foregroundColor = colorFromComponents({
          static_cast<float>((segmentColor >> 16) & 0xFF) / 255.0f,
          static_cast<float>((segmentColor >> 8) & 0xFF) / 255.0f,
          static_cast<float>(segmentColor & 0xFF) / 255.0f,
          static_cast<float>((segmentColor >> 24) & 0xFF) / 255.0f
      });
    }

    fragment.string = normalizedText;
    fragment.textAttributes = textAttributes;
    result.attributedString.appendFragment(std::move(fragment));
    result.linkUrls.push_back(segment.isLink ? segment.linkUrl : "");
  }

  // Post-process accessibility label to add periods before list markers for screen reader pauses
  // This matches the original parser's behavior
  std::string a11yLabel;
  a11yLabel.reserve(accessibilityLabel.size() + 20);

  for (size_t i = 0; i < accessibilityLabel.size(); ++i) {
    char c = accessibilityLabel[i];

    // Check for newline followed by list item marker (digit+period or bullet)
    if (c == '\n' && i + 1 < accessibilityLabel.size()) {
      char next = accessibilityLabel[i + 1];
      bool isListMarker = (std::isdigit(static_cast<unsigned char>(next)) ||
                           // Check for bullet character (UTF-8: E2 80 A2)
                           (i + 3 < accessibilityLabel.size() &&
                            static_cast<unsigned char>(next) == 0xE2 &&
                            static_cast<unsigned char>(accessibilityLabel[i + 2]) == 0x80 &&
                            static_cast<unsigned char>(accessibilityLabel[i + 3]) == 0xA2));

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

AttributedString FabricRichParserLibxml2::parseHtmlToAttributedString(
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
