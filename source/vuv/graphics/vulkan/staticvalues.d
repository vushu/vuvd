module vuv.graphics.vulkan.staticvalues;
import vuv.graphics.vertexstore;
import erupted;

static const int getMaxFramesInFlight = 2;

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

static ref VkDynamicState[] getDynamicStates()
{
    return _dynamicStates;
}

static ref VkVertexInputAttributeDescription[2] getAttributeDescriptions()
{
    return _attributeDescriptions;
}

private static VkVertexInputAttributeDescription[2] _attributeDescriptions = [

    {
        binding: 0, location: 0, format: VK_FORMAT_R32G32_SFLOAT,
        offset: Vertex.position.offsetof
    },

    {

        binding: 0, location: 1, format: VK_FORMAT_R32G32B32_SFLOAT,
        offset: Vertex.color.offsetof
    }
];

static ref VkVertexInputBindingDescription[1] getBindingDescriptions()
{
    return _bindingDescription;
}

private static VkVertexInputBindingDescription[1] _bindingDescription = [
    {
        binding: 0, stride: Vertex.sizeof, inputRate: VkVertexInputRate.VK_VERTEX_INPUT_RATE_VERTEX
    }
];

private static VkDynamicState[] _dynamicStates = [
    VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR
];

VkBufferUsageFlags getVertexUsage()
{
    return VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
}

VkMemoryPropertyFlags getMemoryProperty()
{
    return VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
}
