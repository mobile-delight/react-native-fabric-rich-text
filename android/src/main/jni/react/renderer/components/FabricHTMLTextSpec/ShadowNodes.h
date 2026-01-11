/**
 * Custom ShadowNodes.h for FabricHTMLTextSpec
 *
 * This file overrides the codegen-generated ShadowNodes.h to provide
 * custom ShadowNode implementations with measureContent() support.
 *
 * The include path for this file must have precedence over the codegen path.
 */

#pragma once

#include <react/renderer/components/FabricHTMLTextSpec/EventEmitters.h>
#include <react/renderer/components/FabricHTMLTextSpec/Props.h>
#include <react/renderer/components/FabricHTMLTextSpec/FabricHTMLTextState.h>
#include <react/renderer/core/StateData.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/textlayoutmanager/TextLayoutManager.h>
#include <react/renderer/attributedstring/AttributedString.h>
#include <react/renderer/core/LayoutContext.h>
#include <react/renderer/core/ShadowNode.h>
#include <jsi/jsi.h>
#include <mutex>

namespace facebook::react {

// Component name (must match codegen expectations)
JSI_EXPORT extern const char FabricHTMLTextComponentName[];

/**
 * Custom ShadowNode for FabricHTMLText with measureContent support.
 *
 * This enables proper Yoga layout by:
 * 1. Setting LeafYogaNode trait (no child layout)
 * 2. Setting MeasurableYogaNode trait (custom measurement)
 * 3. Overriding measureContent() to measure HTML text content
 *
 * Uses FabricHTMLTextState to pass parsed fragments to Kotlin via MapBuffer.
 * This ensures the view renders using the same data that was used for measurement,
 * eliminating measurement/rendering misalignment caused by duplicate parsing.
 */
class FabricHTMLTextShadowNode final : public ConcreteViewShadowNode<
    FabricHTMLTextComponentName,
    FabricHTMLTextProps,
    FabricHTMLTextEventEmitter,
    FabricHTMLTextState> {
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
  AttributedString parseHtmlToAttributedString(
      const std::string& html,
      Float fontSizeMultiplier) const;

  static std::string stripHtmlTags(const std::string& html);

  // Mutex protecting mutable members from concurrent access.
  // measureContent() may be called concurrently by Fabric's layout system.
  mutable std::mutex _mutex;
  mutable AttributedString _attributedString;
  mutable std::vector<std::string> _linkUrls;
  mutable std::string _accessibilityLabel;
};

} // namespace facebook::react
