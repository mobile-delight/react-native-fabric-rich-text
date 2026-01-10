/**
 * TextNormalizer.h
 *
 * Text normalization utilities for HTML parsing.
 * Handles whitespace normalization, HTML stripping, and entity decoding.
 */

#pragma once

#include <string>
#include <unordered_set>
#include <vector>

namespace facebook::react::parsing {

// List type enum for tracking ordered vs unordered lists
enum class FabricRichListType { Ordered, Unordered };

// Context for tracking list state during HTML parsing
struct FabricRichListContext {
  FabricRichListType type;
  int itemCounter;
  int nestingLevel;
};

// Block-level HTML tags - whitespace between these can be collapsed
extern const std::unordered_set<std::string> BLOCK_LEVEL_TAGS;

// Inline formatting tags that don't break text flow
extern const std::unordered_set<std::string> INLINE_FORMATTING_TAGS;

/**
 * Check if a tag is block-level.
 */
bool isBlockLevelTag(const std::string& tag);

/**
 * Check if a tag is an inline formatting tag.
 */
bool isInlineFormattingTag(const std::string& tag);

/**
 * Normalize inter-tag whitespace from source formatting.
 * Removes whitespace between block elements while preserving
 * significant whitespace after inline elements.
 * @param html Raw HTML string
 * @return Normalized HTML string
 */
std::string normalizeInterTagWhitespace(const std::string& html);

/**
 * Strip HTML tags from a string, returning plain text content.
 * Handles lists, line breaks, and basic formatting.
 * Also decodes common HTML entities.
 * @param html HTML string to strip
 * @return Plain text content
 */
std::string stripHtmlTags(const std::string& html);

/**
 * Normalize a single segment's text (whitespace handling).
 * @param text Text to normalize
 * @param preserveNewlines If true, only preserve newlines
 * @param preserveLeadingSpace If true, preserve leading whitespace
 * @return Normalized text
 */
std::string normalizeSegmentText(
    const std::string& text,
    bool preserveNewlines = false,
    bool preserveLeadingSpace = false);

/**
 * Check if a segment is purely paragraph spacing (newlines only).
 * @param text Text to check
 * @return true if text contains only whitespace/newlines
 */
bool isParagraphBreak(const std::string& text);

} // namespace facebook::react::parsing
