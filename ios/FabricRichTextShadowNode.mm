/**
 * FabricRichTextShadowNode.mm
 *
 * Custom ShadowNode for FabricRichText with measureContent() implementation.
 * Uses the shared HTMLParser module for cross-platform HTML parsing.
 */

#import "FabricRichTextShadowNode.h"
#import "../cpp/FabricRichParser.h"

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
