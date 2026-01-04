/**
 * FabricHTMLTextState.cpp
 *
 * Implementation of state serialization for FabricHTMLText.
 * Serializes AttributedString to MapBuffer for Kotlin consumption.
 */

#include "FabricHTMLTextState.h"

#include <react/renderer/attributedstring/conversions.h>
#include <android/log.h>
#include <cstdint>

// Debug flag for verbose state logging.
// Set to 1 to enable detailed logging for state serialization.
#define DEBUG_STATE_SERIALIZATION 0

#if DEBUG_STATE_SERIALIZATION
#define STATE_LOG_TAG "FabricHTMLTextState"
#define STATE_LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, STATE_LOG_TAG, __VA_ARGS__)
#else
#define STATE_LOGD(...) ((void)0)
#endif

namespace facebook::react {

// State keys for FabricHTMLText
// Using same pattern as React Native's text state (TX_STATE_KEY_*)
constexpr static MapBuffer::Key HTML_STATE_KEY_ATTRIBUTED_STRING = 0;
constexpr static MapBuffer::Key HTML_STATE_KEY_PARAGRAPH_ATTRIBUTES = 1;
constexpr static MapBuffer::Key HTML_STATE_KEY_HASH = 2;
constexpr static MapBuffer::Key HTML_STATE_KEY_LINK_URLS = 3;

folly::dynamic FabricHTMLTextState::getDynamic() const {
  // Not used for Kotlin serialization, but required by Fabric
  return folly::dynamic::object();
}

MapBuffer FabricHTMLTextState::getMapBuffer() const {
  auto builder = MapBufferBuilder();

  STATE_LOGD("getMapBuffer() called - attributedString has %zu fragments, linkUrls has %zu entries",
             attributedString.getFragments().size(), linkUrls.size());

  // Serialize the AttributedString (uses conversions.h toMapBuffer)
  auto attStringMapBuffer = toMapBuffer(attributedString);
  builder.putMapBuffer(HTML_STATE_KEY_ATTRIBUTED_STRING, attStringMapBuffer);

  // Serialize paragraph attributes
  auto paMapBuffer = toMapBuffer(paragraphAttributes);
  builder.putMapBuffer(HTML_STATE_KEY_PARAGRAPH_ATTRIBUTES, paMapBuffer);

  // Include hash for change detection
  builder.putInt(HTML_STATE_KEY_HASH, attStringMapBuffer.getInt(0)); // AS_KEY_HASH = 0

  // Serialize link URLs as a MapBuffer (index -> URL string)
  // This enables Kotlin to create HrefClickableSpan for clickable links
  STATE_LOGD("linkUrls.size()=%zu, linkUrls.empty()=%d", linkUrls.size(), linkUrls.empty() ? 1 : 0);
  if (!linkUrls.empty()) {
    STATE_LOGD("Serializing %zu linkUrls to MapBuffer", linkUrls.size());
    auto linkUrlsBuilder = MapBufferBuilder();
#if DEBUG_STATE_SERIALIZATION
    int nonEmptyCount = 0;
#endif
    for (size_t i = 0; i < linkUrls.size(); i++) {
      // MapBuffer::Key is uint16_t, so we can only store up to UINT16_MAX entries
      if (i > UINT16_MAX) {
        STATE_LOGD("Warning: linkUrls exceeds MapBuffer::Key capacity (%zu > %u), truncating", i, UINT16_MAX);
        break;
      }
      STATE_LOGD("  linkUrls[%zu] = '%s' (empty=%d)", i, linkUrls[i].c_str(), linkUrls[i].empty() ? 1 : 0);
      if (!linkUrls[i].empty()) {
        linkUrlsBuilder.putString(static_cast<MapBuffer::Key>(i), linkUrls[i]);
#if DEBUG_STATE_SERIALIZATION
        nonEmptyCount++;
#endif
      }
    }
    STATE_LOGD("Added %d non-empty linkUrls to builder", nonEmptyCount);
    builder.putMapBuffer(HTML_STATE_KEY_LINK_URLS, linkUrlsBuilder.build());
    STATE_LOGD("Serialized linkUrls to key %d", HTML_STATE_KEY_LINK_URLS);
  } else {
    STATE_LOGD("No linkUrls to serialize");
  }

  return builder.build();
}

} // namespace facebook::react
