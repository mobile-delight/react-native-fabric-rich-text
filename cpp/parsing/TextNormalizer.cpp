/**
 * TextNormalizer.cpp
 *
 * Text normalization utilities implementation.
 */

#include "TextNormalizer.h"
#include <cctype>

namespace facebook::react::parsing {

// Static member definitions
const std::unordered_set<std::string> BLOCK_LEVEL_TAGS = {
    "p", "div", "h1", "h2", "h3", "h4", "h5", "h6",
    "ul", "ol", "li", "blockquote", "pre", "hr", "br",
    "table", "thead", "tbody", "tr", "th", "td",
    "header", "footer", "section", "article", "nav", "aside"
};

const std::unordered_set<std::string> INLINE_FORMATTING_TAGS = {
    "strong", "b", "em", "i", "u", "s", "mark", "small", "sub", "sup", "code", "span", "a",
    "bdi", "bdo"  // Bidirectional text elements
};

bool isBlockLevelTag(const std::string& tag) {
  return BLOCK_LEVEL_TAGS.find(tag) != BLOCK_LEVEL_TAGS.end();
}

bool isInlineFormattingTag(const std::string& tag) {
  return INLINE_FORMATTING_TAGS.find(tag) != INLINE_FORMATTING_TAGS.end();
}

std::string normalizeInterTagWhitespace(const std::string& html) {
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

std::string stripHtmlTags(const std::string& html) {
  std::string result;
  result.reserve(html.size());

  bool inTag = false;
  bool inScript = false;
  bool inStyle = false;
  std::vector<FabricRichListContext> listStack;
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
        listStack.push_back({FabricRichListType::Unordered, 0, nestingLevel});
      } else if (lowerTag == "ol") {
        int nestingLevel = static_cast<int>(listStack.size()) + 1;
        listStack.push_back({FabricRichListType::Ordered, 0, nestingLevel});
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
          if (currentList.type == FabricRichListType::Ordered) {
            result += std::to_string(currentList.itemCounter) + ". ";
          } else {
            result += "\xE2\x80\xA2 ";  // UTF-8 bullet character
          }
        } else {
          result += "\xE2\x80\xA2 ";  // UTF-8 bullet character
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

bool isParagraphBreak(const std::string& text) {
  for (char c : text) {
    if (c != '\n' && !std::isspace(static_cast<unsigned char>(c))) {
      return false;
    }
  }
  return !text.empty();
}

std::string normalizeSegmentText(
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

} // namespace facebook::react::parsing
