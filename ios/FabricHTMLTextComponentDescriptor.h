#pragma once

#include "FabricHTMLTextShadowNode.h"

#include <react/renderer/core/ConcreteComponentDescriptor.h>
#include <react/renderer/componentregistry/ComponentDescriptorProviderRegistry.h>

namespace facebook::react {

/**
 * Custom ComponentDescriptor for FabricHTMLText.
 *
 * This descriptor uses our custom FabricHTMLTextShadowNode instead of
 * the default codegen-generated ShadowNode. This enables proper Yoga
 * layout measurement for HTML text content.
 */
using FabricHTMLTextComponentDescriptor =
    ConcreteComponentDescriptor<FabricHTMLTextShadowNode>;

} // namespace facebook::react
