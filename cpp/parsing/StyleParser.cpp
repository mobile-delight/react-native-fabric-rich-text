/**
 * StyleParser.cpp
 *
 * Style parsing utilities implementation.
 */

#include "StyleParser.h"
#include <cctype>
#include <cmath>
#include <stdexcept>

namespace facebook::react::parsing {

int32_t parseHexColor(const std::string& colorStr) {
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

std::string getStringValueFromStyleObj(
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

float getNumericValueFromStyleObj(
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

FabricRichTagStyle getStyleFromTagStyles(
    const std::string& tagStyles,
    const std::string& tagName) {
  FabricRichTagStyle result;

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

} // namespace facebook::react::parsing
