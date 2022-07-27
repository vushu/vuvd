module vuv.graphics.vulkan.staticvalues;
import erupted;

static const(char)*[] getRequiredValidationLayers = [
    "VK_LAYER_KHRONOS_validation"
];

bool[string] getRequiredDeviceExtensions()
{
    static bool[string] requireddDeviceExtensions;
    requireddDeviceExtensions["VK_KHR_swapchain"] = false;
    return requireddDeviceExtensions;
}
