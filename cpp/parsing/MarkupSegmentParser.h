/**
 * MarkupSegmentParser.h
 *
 * Core markup parsing to text segments.
 * Parses markup into styled text segments with formatting, links, and RTL support.
 */

#pragma once

#include "DirectionContext.h"
#include "TextNormalizer.h"

#include <react/renderer/attributedstring/AttributedString.h>

#include <string>
#include <vector>

namespace facebook::react::parsing {

// Segment of text with its associated style
struct FabricRichTextSegment {
  std::string text;
  float fontScale;
  bool isBold;
  bool isItalic;
  bool isUnderline;           // True if inside <u> tag
  bool isStrikethrough;       // True if inside <s> tag
  bool isLink;                // True if inside <a> tag with href attribute
  bool followsInlineElement;  // True if this segment follows </strong>, </em>, etc.
  std::string parentTag;      // The innermost formatting tag (e.g., "strong", "em")
  std::string linkUrl;        // The href URL if this segment is inside an <a> tag

  // RTL Support fields
  WritingDirection writingDirection = WritingDirection::Natural;
  bool isBdiIsolated = false;   // Content wrapped in <bdi> tag
  bool isBdoOverride = false;   // Content wrapped in <bdo> tag
};

/**
 * Get heading scale factor for h1-h6 tags.
 */
float getHeadingScale(const std::string& tag);

/**
 * Parse markup into styled text segments.
 * Each segment represents a run of text with consistent styling.
 * @param markup Markup string to parse
 * @return Vector of text segments with style information
 */
std::vector<FabricRichTextSegment> parseMarkupToSegments(const std::string& markup);

/**
 * Extract link URLs from segments.
 * Returns a vector of URLs indexed by segment position (empty string for non-links).
 * @param segments Parsed segments
 * @return Vector of URLs matching segment indices
 */
std::vector<std::string> extractLinkUrlsFromSegments(
    const std::vector<FabricRichTextSegment>& segments);

/**
 * Check if a URL scheme is allowed (blocks javascript:, vbscript:, data:).
 * @param url URL to validate
 * @return true if URL scheme is safe
 */
bool isAllowedUrlScheme(const std::string& url);

/**
 * Extract href URL from a tag string.
 * @param fullTag Full tag string including attributes (e.g., "a href=\"url\"")
 * @return Extracted URL or empty string if not found or blocked
 */
std::string extractHrefUrl(const std::string& fullTag);

/**
 * Extract dir attribute from a tag string.
 * @param fullTag Full tag string including attributes
 * @return dir attribute value or empty string
 */
std::string extractDirAttr(const std::string& fullTag);

} // namespace facebook::react::parsing
