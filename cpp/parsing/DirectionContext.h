/**
 * DirectionContext.h
 *
 * BiDi (bidirectional text) state machine for tracking writing direction
 * during HTML parsing. Manages direction stacks for nested elements.
 */

#pragma once

#include <react/renderer/attributedstring/primitives.h>
#include <string>
#include <vector>

namespace facebook::react::parsing {

/**
 * Context for tracking direction during HTML parsing.
 * Implements a state machine that handles:
 * - dir attribute on any element
 * - <bdi> isolation (FSI/PDI characters)
 * - <bdo> override (RLO/LRO/PDF characters)
 */
struct DirectionContext {
  WritingDirection baseDirection = WritingDirection::Natural;
  WritingDirection currentDirection = WritingDirection::Natural;
  int isolationDepth = 0;  // Nesting level of <bdi> tags
  int overrideDepth = 0;   // Nesting level of <bdo> tags

  // Stack to track direction for each element level
  std::vector<WritingDirection> directionStack;
  std::vector<bool> isBdiStack;   // Track if current level is bdi
  std::vector<bool> isBdoStack;   // Track if current level is bdo

  /**
   * Enter an HTML element, updating direction context.
   * @param tag Element tag name (lowercase)
   * @param dirAttr Value of dir attribute, or empty string if not present
   * @param textContent Text content for dir="auto" detection (optional)
   */
  void enterElement(const std::string& tag, const std::string& dirAttr,
                    const std::string& textContent = "");

  /**
   * Exit an HTML element, restoring previous direction context.
   * @param tag Element tag name (lowercase)
   */
  void exitElement(const std::string& tag);

  /**
   * Get the effective direction for current context.
   */
  WritingDirection getEffectiveDirection() const;

  /**
   * Check if currently inside a bdi isolation scope.
   */
  bool isIsolated() const { return isolationDepth > 0; }

  /**
   * Check if currently inside a bdo override scope.
   */
  bool isOverride() const { return overrideDepth > 0; }
};

} // namespace facebook::react::parsing
