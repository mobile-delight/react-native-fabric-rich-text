/**
 * DirectionContext.cpp
 *
 * BiDi state machine implementation.
 */

#include "DirectionContext.h"
#include "UnicodeUtils.h"
#include <cctype>

namespace facebook::react::parsing {

void DirectionContext::enterElement(const std::string& tag,
                                    const std::string& dirAttr,
                                    const std::string& textContent) {
  // Save current state to stack
  directionStack.push_back(currentDirection);

  bool isBdi = (tag == "bdi");
  bool isBdo = (tag == "bdo");

  isBdiStack.push_back(isBdi);
  isBdoStack.push_back(isBdo);

  if (isBdi) {
    isolationDepth++;
  }
  if (isBdo) {
    overrideDepth++;
  }

  // Handle dir attribute
  if (!dirAttr.empty()) {
    std::string lowerDir = dirAttr;
    for (char& c : lowerDir) {
      c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }

    if (lowerDir == "rtl") {
      currentDirection = WritingDirection::RightToLeft;
    } else if (lowerDir == "ltr") {
      currentDirection = WritingDirection::LeftToRight;
    } else if (lowerDir == "auto") {
      // For dir="auto", detect from text content
      if (!textContent.empty()) {
        currentDirection = detectDirectionFromText(textContent);
      }
      // If no text content, keep current direction
    }
  } else if (isBdi) {
    // <bdi> without dir attribute defaults to dir="auto" behavior
    if (!textContent.empty()) {
      currentDirection = detectDirectionFromText(textContent);
    }
  }
  // <bdo> without dir attribute has no directional effect (per HTML5 spec)
  // Other elements inherit the current direction
}

void DirectionContext::exitElement(const std::string& tag) {
  if (directionStack.empty()) {
    return;
  }

  // Pop bdi/bdo tracking
  if (!isBdiStack.empty()) {
    if (isBdiStack.back()) {
      isolationDepth--;
    }
    isBdiStack.pop_back();
  }
  if (!isBdoStack.empty()) {
    if (isBdoStack.back()) {
      overrideDepth--;
    }
    isBdoStack.pop_back();
  }

  // Restore previous direction
  currentDirection = directionStack.back();
  directionStack.pop_back();
}

WritingDirection DirectionContext::getEffectiveDirection() const {
  return currentDirection;
}

} // namespace facebook::react::parsing
