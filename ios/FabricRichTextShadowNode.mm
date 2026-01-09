/**
 * FabricRichTextShadowNode.mm
 *
 * Custom ShadowNode for FabricRichText with measureContent() implementation.
 * Uses the shared HTMLParser module for cross-platform HTML parsing.
 */

#import "FabricRichTextShadowNode.h"
#import "../cpp/FabricRichParser.h"
#import "../cpp/FabricRichParserLibxml2.h"

// ============================================================================
// Parser Selection Flags
// Set USE_LIBXML2_PARSER to 1 to use libxml2 parser instead of hand-rolled
// Set COMPARE_PARSERS to 1 to run both parsers and log differences (debug only)
// ============================================================================
#define USE_LIBXML2_PARSER 0
#define COMPARE_PARSERS 0

#if COMPARE_PARSERS
#import <os/log.h>

static void compareParseResults(
    const facebook::react::FabricRichParser::ParseResult& result1,
    const facebook::react::FabricRichParser::ParseResult& result2,
    const std::string& html) {

  bool hasDifferences = false;

  // Compare fragment counts
  auto frags1 = result1.attributedString.getFragments();
  auto frags2 = result2.attributedString.getFragments();

  if (frags1.size() != frags2.size()) {
    os_log_error(OS_LOG_DEFAULT, "PARSER_COMPARE: Fragment count mismatch - original: %zu, libxml2: %zu",
                 frags1.size(), frags2.size());
    hasDifferences = true;
  }

  // Compare link URLs
  if (result1.linkUrls.size() != result2.linkUrls.size()) {
    os_log_error(OS_LOG_DEFAULT, "PARSER_COMPARE: Link URL count mismatch - original: %zu, libxml2: %zu",
                 result1.linkUrls.size(), result2.linkUrls.size());
    hasDifferences = true;
  } else {
    for (size_t i = 0; i < result1.linkUrls.size(); ++i) {
      if (result1.linkUrls[i] != result2.linkUrls[i]) {
        os_log_error(OS_LOG_DEFAULT, "PARSER_COMPARE: Link URL mismatch at index %zu", i);
        hasDifferences = true;
      }
    }
  }

  // Compare accessibility labels
  if (result1.accessibilityLabel != result2.accessibilityLabel) {
    os_log_error(OS_LOG_DEFAULT, "PARSER_COMPARE: Accessibility label mismatch");
    hasDifferences = true;
  }

  if (!hasDifferences) {
    os_log_info(OS_LOG_DEFAULT, "PARSER_COMPARE: Results match for HTML length %zu", html.size());
  }
}
#endif

#import <react/renderer/components/view/ViewShadowNode.h>
#import <react/renderer/textlayoutmanager/TextLayoutManager.h>

#if __has_include(<FabricRichText/FabricRichText-Swift.h>)
#import <FabricRichText/FabricRichText-Swift.h>
#elif __has_include("NativeTestHarness-Swift.h")
#import "NativeTestHarness-Swift.h"
#else
#import "FabricRichText-Swift.h"
#endif

namespace facebook::react {

extern const char FabricRichTextComponentName[] = "FabricRichText";

FabricRichTextShadowNode::FabricRichTextShadowNode(
    const ShadowNode& sourceShadowNode,
    const ShadowNodeFragment& fragment)
    : ConcreteViewShadowNode(sourceShadowNode, fragment) {}

std::string FabricRichTextShadowNode::stripHtmlTags(const std::string& html) {
    // Delegate to shared parser
    return FabricRichParser::stripHtmlTags(html);
}

AttributedString FabricRichTextShadowNode::parseHtmlToAttributedString(
    const std::string& html,
    Float fontSizeMultiplier) const {

    if (html.empty()) {
        _linkUrls.clear();
        _accessibilityLabel.clear();
        return AttributedString{};
    }

    const auto& props = getConcreteProps();

    // Sanitize HTML using Swift bridge to SwiftSoup
    NSString *rawHtml = [[NSString alloc] initWithUTF8String:html.c_str()];
    FabricRichSanitizer *sanitizer = [[FabricRichSanitizer alloc] init];
    NSString *sanitizedHtml = [sanitizer sanitize:rawHtml];
    std::string sanitizedHtmlStr = [sanitizedHtml UTF8String] ?: "";

    // Extract props for the shared parser
    Float baseFontSize = 14.0f;
    if (!std::isnan(props.fontSize) && props.fontSize > 0) {
        baseFontSize = props.fontSize;
    }

    bool allowFontScaling = props.allowFontScaling;
    Float maxFontSizeMultiplier = props.maxFontSizeMultiplier;
    Float lineHeight = props.lineHeight;
    int32_t color = props.color;

    // Call parser with all props - get link URLs too
#if COMPARE_PARSERS
    // Run both parsers and compare results
    auto originalResult = FabricRichParser::parseHtmlWithLinkUrls(
        sanitizedHtmlStr,
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

    auto libxml2Result = FabricRichParserLibxml2::parseHtmlWithLinkUrls(
        sanitizedHtmlStr,
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

    compareParseResults(originalResult, libxml2Result, sanitizedHtmlStr);

    // Use the result based on USE_LIBXML2_PARSER flag
    #if USE_LIBXML2_PARSER
    auto& parseResult = libxml2Result;
    #else
    auto& parseResult = originalResult;
    #endif
#elif USE_LIBXML2_PARSER
    // Use libxml2 parser only
    auto parseResult = FabricRichParserLibxml2::parseHtmlWithLinkUrls(
        sanitizedHtmlStr,
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
#else
    // Use original hand-rolled parser
    auto parseResult = FabricRichParser::parseHtmlWithLinkUrls(
        sanitizedHtmlStr,
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
#endif

    _linkUrls = std::move(parseResult.linkUrls);
    _accessibilityLabel = std::move(parseResult.accessibilityLabel);
    return parseResult.attributedString;
}

Size FabricRichTextShadowNode::measureContent(
    const LayoutContext& layoutContext,
    const LayoutConstraints& layoutConstraints) const {

    const auto& props = getConcreteProps();

    if (props.html.empty()) {
        return Size{0, 0};
    }

    // Calculate font size multiplier for accessibility scaling
    Float fontSizeMultiplier = 1.0;
    if (layoutContext.fontSizeMultiplier > 0) {
        fontSizeMultiplier = layoutContext.fontSizeMultiplier;
    }

    // Parse HTML to AttributedString using shared parser
    _attributedString = parseHtmlToAttributedString(props.html, fontSizeMultiplier);

    if (_attributedString.isEmpty()) {
        return Size{0, 0};
    }

    // Set up paragraph attributes
    auto paragraphAttributes = ParagraphAttributes{};
    // Use numberOfLines from props (0 or negative = no limit)
    int numberOfLines = props.numberOfLines;
    paragraphAttributes.maximumNumberOfLines = (numberOfLines > 0) ? numberOfLines : 0;
    paragraphAttributes.ellipsizeMode = EllipsizeMode::Tail;

    // Set up text layout context
    TextLayoutContext textLayoutContext{};
    textLayoutContext.pointScaleFactor = layoutContext.pointScaleFactor;

    // Use TextLayoutManager for measurement (same as Android)
    const auto textLayoutManager = std::make_shared<const TextLayoutManager>(
        getContextContainer());

    auto measuredSize = textLayoutManager->measure(
        AttributedStringBox{_attributedString},
        paragraphAttributes,
        textLayoutContext,
        layoutConstraints);

    return measuredSize.size;
}

void FabricRichTextShadowNode::layout(LayoutContext layoutContext) {
    ensureUnsealed();

    const auto& props = getConcreteProps();

    // Create paragraph attributes for state
    auto paragraphAttributes = ParagraphAttributes{};
    int numberOfLines = props.numberOfLines;
    paragraphAttributes.maximumNumberOfLines = (numberOfLines > 0) ? numberOfLines : 0;
    paragraphAttributes.ellipsizeMode = EllipsizeMode::Tail;

    // Set state with the parsed AttributedString, link URLs, and numberOfLines/animationDuration
    // This passes the C++ parsed fragments to the iOS view,
    // eliminating the need for duplicate HTML parsing in the view layer.
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

    setStateData(FabricRichTextStateData{_attributedString, _linkUrls, effectiveNumberOfLines, animationDuration, writingDirection, _accessibilityLabel});

    ConcreteViewShadowNode::layout(layoutContext);
}

} // namespace facebook::react
