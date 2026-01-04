/**
 * FabricHTMLTextShadowNode.mm
 *
 * Custom ShadowNode for FabricHTMLText with measureContent() implementation.
 * Uses the shared HTMLParser module for cross-platform HTML parsing.
 */

#import "FabricHTMLTextShadowNode.h"
#import "../cpp/FabricHTMLParser.h"

#import <react/renderer/components/view/ViewShadowNode.h>
#import <react/renderer/textlayoutmanager/TextLayoutManager.h>

#if __has_include(<FabricHtmlText/FabricHtmlText-Swift.h>)
#import <FabricHtmlText/FabricHtmlText-Swift.h>
#elif __has_include("NativeTestHarness-Swift.h")
#import "NativeTestHarness-Swift.h"
#else
#import "FabricHtmlText-Swift.h"
#endif

namespace facebook::react {

extern const char FabricHTMLTextComponentName[] = "FabricHTMLText";

FabricHTMLTextShadowNode::FabricHTMLTextShadowNode(
    const ShadowNode& sourceShadowNode,
    const ShadowNodeFragment& fragment)
    : ConcreteViewShadowNode(sourceShadowNode, fragment) {}

std::string FabricHTMLTextShadowNode::stripHtmlTags(const std::string& html) {
    // Delegate to shared parser
    return FabricHTMLParser::stripHtmlTags(html);
}

AttributedString FabricHTMLTextShadowNode::parseHtmlToAttributedString(
    const std::string& html,
    Float fontSizeMultiplier) const {

    if (html.empty()) {
        _linkUrls.clear();
        return AttributedString{};
    }

    const auto& props = getConcreteProps();

    // Sanitize HTML using Swift bridge to SwiftSoup
    NSString *rawHtml = [[NSString alloc] initWithUTF8String:html.c_str()];
    FabricHTMLSanitizer *sanitizer = [[FabricHTMLSanitizer alloc] init];
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

    // Call shared parser with all props - get link URLs too
    auto parseResult = FabricHTMLParser::parseHtmlWithLinkUrls(
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
    return parseResult.attributedString;
}

Size FabricHTMLTextShadowNode::measureContent(
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
    paragraphAttributes.maximumNumberOfLines = 0;
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

void FabricHTMLTextShadowNode::layout(LayoutContext layoutContext) {
    ensureUnsealed();

    // Create paragraph attributes for state
    auto paragraphAttributes = ParagraphAttributes{};
    paragraphAttributes.maximumNumberOfLines = 0;
    paragraphAttributes.ellipsizeMode = EllipsizeMode::Tail;

    // Set state with the parsed AttributedString and link URLs
    // This passes the C++ parsed fragments to the iOS view,
    // eliminating the need for duplicate HTML parsing in the view layer.
    setStateData(FabricHTMLTextStateData{_attributedString, _linkUrls});

    ConcreteViewShadowNode::layout(layoutContext);
}

} // namespace facebook::react
