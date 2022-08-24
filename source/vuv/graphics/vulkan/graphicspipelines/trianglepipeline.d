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

VkPipelineShaderStageCreateInfo[] createTriangleShaderStages(ref VkDevice device, string vertexFile, string fragmentFile, out ShadersModules shaderModules)
{
    auto vertexShaderCode = readFile(vertexFile);
    auto fragmentShaderCode = readFile(fragmentFile);

    shaderModules.vertexShaderModule = createShaderModule(device, vertexShaderCode);
    shaderModules.fragmentShaderModule = createShaderModule(device, fragmentShaderCode);

    auto fragmentShaderStageInfo = createFragmentShaderPipeline(shaderModules.fragmentShaderModule);
    auto vertexShaderStageInfo = createVertexShaderPipeline(shaderModules.vertexShaderModule);

    VkPipelineShaderStageCreateInfo[] shaderStages = [
        fragmentShaderStageInfo, vertexShaderStageInfo
    ];

    return shaderStages;
}

VkPipelineShaderStageCreateInfo[] createTriangleShaderStages(ref VkDevice device, out ShadersModules shaderModules)
{
    return createTriangleShaderStages(device, "shaders/triangle/vert.spv", "shaders/triangle/frag.spv", shaderModules);
    // return createTriangleShaderStages(device, "shaders/triangle/defaultvert.spv", "shaders/triangle/defaultfrag.spv", shaderModules);
}

void cleanupShaderModules(ref VkDevice device, ref ShadersModules shaderModules)
{
    debug writeln("Destroying shader modules");
    vkDestroyShaderModule(device, shaderModules.vertexShaderModule, null);
    vkDestroyShaderModule(device, shaderModules.fragmentShaderModule, null);
}
