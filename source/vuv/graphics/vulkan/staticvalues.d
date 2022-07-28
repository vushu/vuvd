module vuv.graphics.vulkan.staticvalues;
import erupted;

static const(char)*[] getRequiredValidationLayers = [
    "VK_LAYER_KHRONOS_validation"
];

static const(char)*[] getRequiredDeviceExtensions = [
    VK_KHR_SWAPCHAIN_EXTENSION_NAME
];

bool[string] getRequiredDeviceExtensionsAsSet()
{
    static bool[string] requireddDeviceExtensions;
    requireddDeviceExtensions["VK_KHR_swapchain"] = false;
    return requireddDeviceExtensions;
}
