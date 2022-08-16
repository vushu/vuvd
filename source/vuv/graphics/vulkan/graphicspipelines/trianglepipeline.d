module vuv.graphics.vulkan.graphicspipelines.trianglepipeline;
import vuv.graphics.vulkan.graphicspipelines.fileutils;
import erupted;
import vuv.graphics.vulkan.graphicspipelines.common;
import vuv.graphics.vulkan.staticvalues;

debug import std.stdio : writeln;

struct ShadersModules
{
    VkShaderModule vertexShaderModule;
    VkShaderModule fragmentShaderModule;
}

void createTriangleGraphicsPipeline(ref VkDevice device)
{

    auto dynamicStageCreateInfo = createDynamicStates(getDynamicStates);
}

VkPipelineShaderStageCreateInfo[] createTriangleShaderStages(ref VkDevice device, out ShadersModules shaderModules)
{
    auto vertexShaderCode = readFile("shaders/triangle/vert.spv");
    auto fragmentShaderCode = readFile("shaders/triangle/frag.spv");

    shaderModules.vertexShaderModule = createShaderModule(device, vertexShaderCode);
    shaderModules.fragmentShaderModule = createShaderModule(device, fragmentShaderCode);

    auto fragmentShaderStageInfo = createFragmentShaderPipeline(shaderModules.fragmentShaderModule);
    auto vertexShaderStageInfo = createVertexShaderPipeline(shaderModules.vertexShaderModule);

    VkPipelineShaderStageCreateInfo[] shaderStages = [
        fragmentShaderStageInfo, vertexShaderStageInfo
    ];

    return shaderStages;
}

void cleanupShaderModules(ref VkDevice device, ref ShadersModules shaderModules)
{
    debug writeln("Destroying shader modules");
    vkDestroyShaderModule(device, shaderModules.vertexShaderModule, null);
    vkDestroyShaderModule(device, shaderModules.fragmentShaderModule, null);
}
