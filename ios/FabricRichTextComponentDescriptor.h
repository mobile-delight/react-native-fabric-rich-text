#pragma once

#include "FabricRichTextShadowNode.h"

#include <react/renderer/core/ConcreteComponentDescriptor.h>
#include <react/renderer/componentregistry/ComponentDescriptorProviderRegistry.h>

namespace facebook::react {

/**
 * Custom ComponentDescriptor for FabricRichText.
 *
 * This descriptor uses our custom FabricRichTextShadowNode instead of
 * the default codegen-generated ShadowNode. This enables proper Yoga
 * layout measurement for HTML text content.
 */
using FabricRichTextComponentDescriptor =
    ConcreteComponentDescriptor<FabricRichTextShadowNode>;

} // namespace facebook::react
