/**
 * MarkupSegmentParser.cpp
 *
 * Core markup parsing to text segments implementation.
 */

#include "MarkupSegmentParser.h"
#include "DirectionContext.h"
#include "TextNormalizer.h"

#include <cctype>

namespace facebook::react::parsing {

float getHeadingScale(const std::string& tag) {
  if (tag == "h1") return 2.0f;
  if (tag == "h2") return 1.5f;
  if (tag == "h3") return 1.17f;
  if (tag == "h4") return 1.0f;
  if (tag == "h5") return 0.83f;
  if (tag == "h6") return 0.67f;
  return 1.0f;
}

std::vector<std::string> extractLinkUrlsFromSegments(
    const std::vector<FabricRichTextSegment>& segments) {
  std::vector<std::string> linkUrls;
  linkUrls.reserve(segments.size());
  for (const auto& segment : segments) {
    linkUrls.push_back(segment.linkUrl);
  }
  return linkUrls;
}

bool isAllowedUrlScheme(const std::string& url) {
  std::string lowerUrl = url;
  for (char& c : lowerUrl) {
    c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  }
  // Trim leading whitespace
  size_t start = lowerUrl.find_first_not_of(" \t\n\r");
  if (start != std::string::npos) {
    lowerUrl = lowerUrl.substr(start);
  }

  // Allowlist: only permit safe schemes
  // http://, https://, mailto:, tel:
  if (lowerUrl.rfind("http://", 0) == 0 ||
      lowerUrl.rfind("https://", 0) == 0 ||
      lowerUrl.rfind("mailto:", 0) == 0 ||
      lowerUrl.rfind("tel:", 0) == 0) {
    return true;
  }

  // Allow relative URLs (no scheme) and fragment-only URLs
  // These start with /, #, or contain no colon before first slash
  if (lowerUrl.empty() || lowerUrl[0] == '/' || lowerUrl[0] == '#') {
    return true;
  }

  // Check for relative URL (no scheme - colon must come after first slash)
  size_t colonPos = lowerUrl.find(':');
  size_t slashPos = lowerUrl.find('/');
  if (colonPos == std::string::npos ||
      (slashPos != std::string::npos && slashPos < colonPos)) {
    return true;  // Relative URL without scheme
  }

  return false;  // Block all other schemes
}

std::string extractHrefUrl(const std::string& fullTag) {
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
}

std::string extractDirAttr(const std::string& fullTag) {
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
}

// Helper to extract text content from position until the closing tag (for dir="auto" detection)
// This looks ahead in the HTML without modifying the parse state
static std::string extractTextForAutoDetection(
    const std::string& html,
    size_t startPos,
    const std::string& tagToClose) {
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
}

std::vector<FabricRichTextSegment> parseMarkupToSegments(const std::string& markup) {
  std::vector<FabricRichTextSegment> segments;

  if (markup.empty()) {
    return segments;
  }

  std::string currentText;
  float currentScale = 1.0f;
  bool currentBold = false;
  bool currentItalic = false;
  bool currentUnderline = false;
  bool currentStrikethrough = false;
  bool currentLink = false;
  std::string currentParentTag;
  std::string currentLinkUrl;  // Track the href URL of the current link
  bool nextFollowsInline = false;
  std::vector<std::string> tagStack;
  std::vector<FabricRichListContext> listStack;
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
      FabricRichTextSegment segment;
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

  for (size_t i = 0; i < markup.size(); ++i) {
    char c = markup[i];

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
            textForDetection = extractTextForAutoDetection(markup, i + 1, cleanTag);
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
          textForDetection = extractTextForAutoDetection(markup, i + 1, cleanTag);
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
          // Cap indent level to prevent excessive memory allocation
          if (indentLevel > 100) {
            indentLevel = 100;
          }
          if (indentLevel > 0) {
            currentText += std::string(indentLevel * 4, ' ');
          }
          if (currentList.type == FabricRichListType::Ordered) {
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
        listStack.push_back({FabricRichListType::Unordered, 0, nestingLevel});
      } else if (!isClosing && cleanTag == "ol") {
        int nestingLevel = static_cast<int>(listStack.size()) + 1;
        listStack.push_back({FabricRichListType::Ordered, 0, nestingLevel});
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

} // namespace facebook::react::parsing
