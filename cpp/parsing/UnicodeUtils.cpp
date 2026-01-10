/**
 * UnicodeUtils.cpp
 *
 * Unicode utilities for RTL/LTR direction detection.
 */

#include "UnicodeUtils.h"
#include <cctype>

namespace facebook::react::parsing {

bool isStrongRTL(char32_t codepoint) {
  // Hebrew: U+0590-U+05FF
  if (codepoint >= 0x0590 && codepoint <= 0x05FF) return true;
  // Arabic: U+0600-U+06FF
  if (codepoint >= 0x0600 && codepoint <= 0x06FF) return true;
  // Arabic Supplement: U+0750-U+077F
  if (codepoint >= 0x0750 && codepoint <= 0x077F) return true;
  // Arabic Extended-A: U+08A0-U+08FF
  if (codepoint >= 0x08A0 && codepoint <= 0x08FF) return true;
  // Syriac: U+0700-U+074F
  if (codepoint >= 0x0700 && codepoint <= 0x074F) return true;
  // Thaana: U+0780-U+07BF
  if (codepoint >= 0x0780 && codepoint <= 0x07BF) return true;
  // N'Ko: U+07C0-U+07FF
  if (codepoint >= 0x07C0 && codepoint <= 0x07FF) return true;
  // Hebrew Presentation Forms: U+FB1D-U+FB4F
  if (codepoint >= 0xFB1D && codepoint <= 0xFB4F) return true;
  // Arabic Presentation Forms-A: U+FB50-U+FDFF
  if (codepoint >= 0xFB50 && codepoint <= 0xFDFF) return true;
  // Arabic Presentation Forms-B: U+FE70-U+FEFF
  if (codepoint >= 0xFE70 && codepoint <= 0xFEFF) return true;
  return false;
}

bool isStrongLTR(char32_t codepoint) {
  // Basic Latin letters: U+0041-U+005A (A-Z), U+0061-U+007A (a-z)
  if (codepoint >= 0x0041 && codepoint <= 0x005A) return true;
  if (codepoint >= 0x0061 && codepoint <= 0x007A) return true;
  // Latin Extended-A/B: U+00C0-U+024F
  if (codepoint >= 0x00C0 && codepoint <= 0x024F) return true;
  // Latin Extended Additional: U+1E00-U+1EFF
  if (codepoint >= 0x1E00 && codepoint <= 0x1EFF) return true;
  // Greek: U+0370-U+03FF
  if (codepoint >= 0x0370 && codepoint <= 0x03FF) return true;
  // Cyrillic: U+0400-U+04FF
  if (codepoint >= 0x0400 && codepoint <= 0x04FF) return true;
  // Georgian: U+10A0-U+10FF
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

} // namespace facebook::react::parsing
