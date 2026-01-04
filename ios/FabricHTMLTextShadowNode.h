#pragma once

#include <react/renderer/components/FabricHTMLTextSpec/EventEmitters.h>
#include <react/renderer/components/FabricHTMLTextSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/textlayoutmanager/TextLayoutManager.h>
#include <react/renderer/core/LayoutContext.h>
#include <react/renderer/core/ShadowNode.h>

namespace facebook::react {

extern const char FabricHTMLTextComponentName[];

/**
 * Custom state that holds the AttributedString for the native view.
 * This is passed to the native component view after layout.
 */
class FabricHTMLTextStateData final {
 public:
  AttributedString attributedString;
  // Link URLs indexed by fragment position (empty string for non-links)
  std::vector<std::string> linkUrls;
};

/**
 * Custom ShadowNode for FabricHTMLText that implements measureContent.
 *
 * This enables proper Yoga layout by:
 * 1. Setting LeafYogaNode trait (no child layout)
 * 2. Setting MeasurableYogaNode trait (custom measurement)
 * 3. Overriding measureContent() to measure HTML text content
 * 4. Using TextLayoutManager for platform-specific text measurement
 *
 * Based on the pattern from:
 * - React Native's ParagraphShadowNode
 * - Bluesky's react-native-uitextview
 */
class FabricHTMLTextShadowNode final : public ConcreteViewShadowNode<
    FabricHTMLTextComponentName,
    FabricHTMLTextProps,
    FabricHTMLTextEventEmitter,
    FabricHTMLTextStateData> {
 public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  FabricHTMLTextShadowNode(
      const ShadowNode& sourceShadowNode,
      const ShadowNodeFragment& fragment);

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

  void layout(LayoutContext layoutContext) override;

  Size measureContent(
      const LayoutContext& layoutContext,
      const LayoutConstraints& layoutConstraints) const override;

 private:
  /**
   * Parses HTML string and builds an AttributedString for measurement.
   * This is a simplified parser that extracts text and basic styling
   * for layout measurement. The native view uses the full HTML parser
   * for actual rendering.
   */
  AttributedString parseHtmlToAttributedString(
      const std::string& html,
      Float fontSizeMultiplier) const;

  /**
   * Strips HTML tags from a string, returning plain text content.
   */
  static std::string stripHtmlTags(const std::string& html);

  mutable AttributedString _attributedString;
  mutable std::vector<std::string> _linkUrls;
};

} // namespace facebook::react
