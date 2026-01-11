/**
 * FabricHTMLTextState.h
 *
 * Custom state for FabricHTMLText that enables C++ to Kotlin data passing.
 * This allows the Kotlin view to receive pre-parsed HTML fragments from C++,
 * eliminating the need for duplicate HTML parsing and ensuring measurement
 * and rendering use identical data.
 *
 * Pattern based on React Native's ParagraphState for Text components.
 */

#pragma once

#include <react/debug/react_native_assert.h>
#include <react/renderer/attributedstring/AttributedString.h>
#include <react/renderer/attributedstring/ParagraphAttributes.h>

#include <folly/dynamic.h>
#include <react/renderer/mapbuffer/MapBuffer.h>
#include <react/renderer/mapbuffer/MapBufferBuilder.h>

namespace facebook::react {

/**
 * Writing direction for RTL text support.
 * Maps to TextDirectionHeuristics on Android.
 */
enum class WritingDirectionState {
  LTR,   // Left-to-right (default)
  RTL    // Right-to-left
};

/**
 * State class for FabricHTMLText.
 *
 * Contains the parsed HTML content as an AttributedString, which is
 * serialized to MapBuffer for consumption by the Kotlin view layer.
 */
class FabricHTMLTextState final {
 public:
  /**
   * The parsed HTML content as an AttributedString.
   * Contains fragments with text and style attributes.
   */
  AttributedString attributedString;

  /**
   * Paragraph-level attributes for text layout.
   */
  ParagraphAttributes paragraphAttributes;

  /**
   * Link URLs indexed by fragment position.
   * Empty string for non-link fragments.
   * This enables Kotlin to create HrefClickableSpan for link detection.
   */
  std::vector<std::string> linkUrls;

  /**
   * Maximum number of lines to display (0 = no limit)
   */
  int numberOfLines{0};

  /**
   * Animation duration for height changes in seconds (0 = instant)
   */
  Float animationDuration{0.2f};

  /**
   * Base writing direction for text content
   */
  WritingDirectionState writingDirection{WritingDirectionState::LTR};

  FabricHTMLTextState() = default;

  FabricHTMLTextState(
      AttributedString attributedString,
      ParagraphAttributes paragraphAttributes,
      std::vector<std::string> linkUrls = {},
      int numberOfLines = 0,
      Float animationDuration = 0.2f,
      WritingDirectionState writingDirection = WritingDirectionState::LTR)
      : attributedString(std::move(attributedString)),
        paragraphAttributes(std::move(paragraphAttributes)),
        linkUrls(std::move(linkUrls)),
        numberOfLines(numberOfLines),
        animationDuration(animationDuration),
        writingDirection(writingDirection) {}

  /**
   * Constructor for state updates from JS (not supported for FabricHTMLText).
   */
  FabricHTMLTextState(
      const FabricHTMLTextState& /*previousState*/,
      const folly::dynamic& /*data*/) {
    react_native_assert(false && "Not supported");
  }

  folly::dynamic getDynamic() const;
  MapBuffer getMapBuffer() const;
};

} // namespace facebook::react
