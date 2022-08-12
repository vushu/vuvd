module vuv.graphics.vulkan.graphicspipelines.trianglepipeline;
import vuv.graphics.vulkan.graphicspipelines.fileutils;
import erupted;
import vuv.graphics.vulkan.graphicspipelines.common;
import vuv.graphics.vulkan.staticvalues;

void createTriangleGraphicsPipeline(ref VkDevice device)
{

    auto dynamicStageCreateInfo = createDynamicStates(getDynamicStates);
}

VkPipelineShaderStageCreateInfo[] createTriangleShaderStages(ref VkDevice device)
{
    auto vertexShaderCode = readFile("shaders/triangle/vert.spv");
    auto fragmentShaderCode = readFile("shaders/triangle/frag.spv");

    VkShaderModule vertShaderModule = createShaderModule(device, vertexShaderCode);
    VkShaderModule fragmentShaderModule = createShaderModule(device, fragmentShaderCode);

    auto fragmentShaderStageInfo = createFragmentShaderPipeline(fragmentShaderModule);
    auto vertexShaderStageInfo = createVertexShaderPipeline(vertShaderModule);

    VkPipelineShaderStageCreateInfo[] shaderStages = [
        fragmentShaderStageInfo, vertexShaderStageInfo
    ];

    return shaderStages;
}





