module vuv.graphics.vulkan.graphicspipelines.common;
import erupted;
import std.stdio;
import unit_threaded : Tags;

version (unittest)
{
    import unit_threaded;
    import vuv.graphics.vulkan.swapchain : getSwapchainFixture;
    import vuv.graphics.vulkan.graphicspipelines.fileutils;
}

@Tags("createShaderModule")
@("Testing createShaderModule")
unittest
{
    auto fixture = getSwapchainFixture;

    auto code = readFile("shaders/triangle/vert.spv");
    assert(code.length > 0);

    VkShaderModule shaderModule = createShaderModule(fixture.device, code);
    shaderModule.shouldNotBeNull;
    scope (exit)
    {
        vkDestroyShaderModule(fixture.device, shaderModule, null);
    }

}

VkShaderModule createShaderModule(ref VkDevice device, const ref byte[] code)
{

    VkShaderModuleCreateInfo createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    createInfo.codeSize = code.length;
    createInfo.pCode = cast(const(uint32_t)*) code.ptr;
    VkShaderModule shaderModule;
    if (vkCreateShaderModule(device, &createInfo, null, &shaderModule) != VkResult.VK_SUCCESS)
    {
        debug writeln("Failed to create shader module");
        return null;
    }
    debug writeln("Succesfully to created a shader module");
    return shaderModule;

}
