/**
 * StyleParser.h
 *
 * Style parsing utilities for extracting colors and text styles
 * from JSON-like tagStyles objects.
 */

#pragma once

#include <string>
#include <cstdint>
#include <cmath>

namespace facebook::react::parsing {

/**
 * TagStyle struct to hold all supported TextStyle properties from tagStyles.
 */
struct FabricRichTagStyle {
  int32_t color = 0;           // ARGB color, 0 means not set
  float fontSize = NAN;        // NAN means not set
  std::string fontWeight;      // empty means not set ("bold", "700", etc.)
  std::string fontStyle;       // empty means not set ("italic", "normal")
  std::string textDecorationLine;  // empty means not set ("underline", "line-through")
};

/**
 * Parse a hex color string like "#CC0000" to ARGB int.
 * Supports both #RGB and #RRGGBB formats.
 * @param colorStr Hex color string (e.g., "#FF0000" or "#F00")
 * @return ARGB int32_t with full alpha, or 0 if invalid
 */
int32_t parseHexColor(const std::string& colorStr);

/**
 * Extract a string value from a JSON-like style object.
 * @param styleObj JSON-like object string
 * @param key Key to look for
 * @return Value as string, or empty if not found
 */
std::string getStringValueFromStyleObj(
    const std::string& styleObj,
    const std::string& key);

/**
 * Extract a numeric value from a JSON-like style object.
 * @param styleObj JSON-like object string
 * @param key Key to look for
 * @return Value as float, or NAN if not found
 */
float getNumericValueFromStyleObj(
    const std::string& styleObj,
    const std::string& key);

/**
 * Parse all TextStyle properties for a specific tag from tagStyles JSON.
 * @param tagStyles Full tagStyles JSON string
 * @param tagName Tag name to look for
 * @return FabricRichTagStyle with parsed values
 */
FabricRichTagStyle getStyleFromTagStyles(
    const std::string& tagStyles,
    const std::string& tagName);

} // namespace facebook::react::parsing
