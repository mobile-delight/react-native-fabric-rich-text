/**
 * Custom ShadowNodes.cpp for FabricHTMLTextSpec
 *
 * This provides the FabricHTMLTextShadowNode implementation with
 * measureContent() for proper Yoga layout measurement.
 *
 * Uses the shared FabricHTMLParser module for cross-platform HTML parsing.
 */

#include "ShadowNodes.h"
#include "FabricHTMLTextState.h"
#include "FabricHTMLParser.h"

#include <react/renderer/components/view/ViewShadowNode.h>
#include <android/log.h>

// Debug flag for verbose measurement logging.
// Set to 1 to enable detailed logging for HTML parsing and layout measurement.
#define DEBUG_CPP_MEASUREMENT 0

// Android NDK logging - outputs to logcat with tag "FabricHTMLText_CPP"
// Use: adb logcat | grep FabricHTMLText_CPP
#define HTML_LOG_TAG "FabricHTMLText_CPP"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, HTML_LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, HTML_LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, HTML_LOG_TAG, __VA_ARGS__)

namespace facebook::react {

// Component name definition
extern const char FabricHTMLTextComponentName[] = "FabricHTMLText";

// Static initialization to verify custom ShadowNodes are loaded
namespace {
  struct CustomShadowNodesInitializer {
    CustomShadowNodesInitializer() {
      __android_log_print(ANDROID_LOG_INFO, "FabricHTMLText_CPP",
        "Custom ShadowNodes.cpp loaded");
    }
  };
  static CustomShadowNodesInitializer _customInitializer;
}

// FabricHTMLTextShadowNode implementation

FabricHTMLTextShadowNode::FabricHTMLTextShadowNode(
    const ShadowNode& sourceShadowNode,
    const ShadowNodeFragment& fragment)
    : ConcreteViewShadowNode(sourceShadowNode, fragment) {}

std::string FabricHTMLTextShadowNode::stripHtmlTags(const std::string& html) {
  // Delegate to shared parser
  return FabricHTMLParser::stripHtmlTags(html);
}

// NOTE: This method modifies _linkUrls. It must only be called while holding _mutex.
AttributedString FabricHTMLTextShadowNode::parseHtmlToAttributedString(
    const std::string& html,
    Float fontSizeMultiplier) const {

  if (html.empty()) {
    _linkUrls.clear();
    return AttributedString{};
  }

  const auto& props = getConcreteProps();

  // Extract props for the shared parser
  Float baseFontSize = 14.0f;
  if (!std::isnan(props.fontSize) && props.fontSize > 0) {
    baseFontSize = props.fontSize;
  }

  bool allowFontScaling = props.allowFontScaling;
  Float maxFontSizeMultiplier = props.maxFontSizeMultiplier;
  Float lineHeight = props.lineHeight;
  int32_t color = props.color;

  if (DEBUG_CPP_MEASUREMENT) {
    LOGD("Props: fontSize=%f lineHeight=%f allowFontScaling=%d",
         props.fontSize, props.lineHeight, allowFontScaling ? 1 : 0);
    LOGD("Props: color=0x%08X (decimal=%d)", props.color, props.color);
    LOGD("Props: tagStyles='%s'", props.tagStyles.substr(0, 100).c_str());
  }

  // Call shared parser with all props - get link URLs too
  auto parseResult = FabricHTMLParser::parseHtmlWithLinkUrls(
      html,
      baseFontSize,
      fontSizeMultiplier,
      allowFontScaling,
      maxFontSizeMultiplier,
      lineHeight,
      props.fontWeight,
      props.fontFamily,
      props.fontStyle,
      props.letterSpacing,
      color,
      props.tagStyles);

  _linkUrls = std::move(parseResult.linkUrls);
  return parseResult.attributedString;
}

Size FabricHTMLTextShadowNode::measureContent(
    const LayoutContext& layoutContext,
    const LayoutConstraints& layoutConstraints) const {

  const auto& props = getConcreteProps();

  Float fontSizeMultiplier = 1.0;
  if (layoutContext.fontSizeMultiplier > 0) {
    fontSizeMultiplier = layoutContext.fontSizeMultiplier;
  }

  if (DEBUG_CPP_MEASUREMENT) {
    LOGD("========== measureContent START ==========");
    LOGD("HTML length: %zu", props.html.length());
    LOGD("fontSizeMultiplier: %f", fontSizeMultiplier);
    LOGD("Constraints: minW=%f maxW=%f minH=%f maxH=%f",
         layoutConstraints.minimumSize.width, layoutConstraints.maximumSize.width,
         layoutConstraints.minimumSize.height, layoutConstraints.maximumSize.height);
  }

  // Parse HTML and cache result under mutex protection.
  // Use local variable for measurement to minimize lock duration.
  AttributedString localAttributedString;
  {
    std::lock_guard<std::mutex> lock(_mutex);
    localAttributedString = parseHtmlToAttributedString(props.html, fontSizeMultiplier);
    _attributedString = localAttributedString;
  }

  if (localAttributedString.isEmpty()) {
    if (DEBUG_CPP_MEASUREMENT) {
      LOGD("Empty attributed string, returning 0x0");
    }
    return Size{0, 0};
  }

  if (DEBUG_CPP_MEASUREMENT) {
    // Log fragment info
    const auto& fragments = localAttributedString.getFragments();
    LOGD("AttributedString has %zu fragments", fragments.size());
    size_t totalTextLen = 0;
    int lineBreakCount = 0;
    for (size_t i = 0; i < fragments.size(); ++i) {
      const auto& frag = fragments[i];
      totalTextLen += frag.string.length();
      for (char c : frag.string) {
        if (c == '\n') lineBreakCount++;
      }
      LOGD("Fragment %zu: len=%zu fontSize=%f bold=%d",
           i, frag.string.length(), frag.textAttributes.fontSize,
           frag.textAttributes.fontWeight == FontWeight::Bold ? 1 : 0);
    }
    LOGD("Total text length: %zu, line breaks: %d", totalTextLen, lineBreakCount);
  }

  auto paragraphAttributes = ParagraphAttributes{};
  // Use numberOfLines from props (0 or negative = no limit)
  int numberOfLines = props.numberOfLines;
  paragraphAttributes.maximumNumberOfLines = (numberOfLines > 0) ? numberOfLines : 0;
  paragraphAttributes.ellipsizeMode = EllipsizeMode::Tail;

  if (DEBUG_CPP_MEASUREMENT) {
    LOGD("numberOfLines prop: %d, maximumNumberOfLines: %d",
         props.numberOfLines, paragraphAttributes.maximumNumberOfLines);
  }

  TextLayoutContext textLayoutContext{};
  textLayoutContext.pointScaleFactor = layoutContext.pointScaleFactor;

  if (DEBUG_CPP_MEASUREMENT) {
    LOGD("pointScaleFactor: %f", layoutContext.pointScaleFactor);
  }

  const auto textLayoutManager = std::make_shared<const TextLayoutManager>(
      getContextContainer());

  auto measuredSize = textLayoutManager->measure(
      AttributedStringBox{localAttributedString},
      paragraphAttributes,
      textLayoutContext,
      layoutConstraints);

  if (DEBUG_CPP_MEASUREMENT) {
    LOGW("TextLayoutManager result: %f x %f",
         measuredSize.size.width, measuredSize.size.height);
  }

  return measuredSize.size;
}

void FabricHTMLTextShadowNode::layout(LayoutContext layoutContext) {
  ensureUnsealed();

  const auto& props = getConcreteProps();

  // Create paragraph attributes for state
  auto paragraphAttributes = ParagraphAttributes{};
  int numberOfLines = props.numberOfLines;
  paragraphAttributes.maximumNumberOfLines = (numberOfLines > 0) ? numberOfLines : 0;
  paragraphAttributes.ellipsizeMode = EllipsizeMode::Tail;

  // Copy cached data under mutex protection to avoid data races.
  AttributedString localAttributedString;
  std::vector<std::string> localLinkUrls;
  {
    std::lock_guard<std::mutex> lock(_mutex);
    localAttributedString = _attributedString;
    localLinkUrls = _linkUrls;
  }

  // Get effective values for state
  int effectiveNumberOfLines = (props.numberOfLines > 0) ? props.numberOfLines : 0;
  Float animationDuration = (props.animationDuration > 0) ? props.animationDuration : 0.0f;

  // Parse writingDirection from props (string: "ltr" or "rtl", defaults to LTR)
  WritingDirectionState writingDirection = WritingDirectionState::LTR;
  if (!props.writingDirection.empty()) {
    if (props.writingDirection == "rtl") {
      writingDirection = WritingDirectionState::RTL;
    }
    // "ltr" or any other value defaults to LTR
  }

  // Set state with the parsed AttributedString, link URLs, and layout props
  // This passes the C++ parsed fragments to Kotlin via MapBuffer serialization,
  // eliminating the need for duplicate HTML parsing in the view layer.
  setStateData(FabricHTMLTextState{
      localAttributedString,
      paragraphAttributes,
      localLinkUrls,
      effectiveNumberOfLines,
      animationDuration,
      writingDirection});

  if (DEBUG_CPP_MEASUREMENT) {
    LOGD("layout() - State set with %zu fragments, %zu linkUrls, numberOfLines=%d, writingDirection=%s",
         localAttributedString.getFragments().size(), localLinkUrls.size(),
         effectiveNumberOfLines, props.writingDirection.c_str());
  }
}

} // namespace facebook::react
