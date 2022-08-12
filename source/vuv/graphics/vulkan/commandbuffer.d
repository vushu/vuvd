module vuv.graphics.vulkan.commandbuffer;
import erupted;
import vuv.graphics.vulkan.physicaldevice;
import std.typecons : Nullable;

version (unittest)
{

    import vuv.graphics.vulkan.swapchain;
    import vuv.graphics.vulkan.framebuffer;

}

@("Testing createCommandPoolAndBuffer")
unittest
{
    auto fixture = getSwapchainFixture;
    VkCommandPool commandPool;
    assert(createCommandPool(fixture.device,
            fixture.queueFamilyIndices.graphicsFamily.get, commandPool));
    scope (exit)
    {
        vkDestroyCommandPool(fixture.device, commandPool, null);
    }

    VkCommandBuffer commandBuffer;
    assert(createCommandBuffer(fixture.device, commandPool, commandBuffer));
    
    //createSwapchainFramebuffers(fixture.device, fixture. )
}

bool createCommandPool(ref VkDevice device, uint graphicsFamilyIndex, out VkCommandPool commandPool)
{
    VkCommandPoolCreateInfo commandPoolCreateInfo;
    commandPoolCreateInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    commandPoolCreateInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    commandPoolCreateInfo.queueFamilyIndex = graphicsFamilyIndex;

    return vkCreateCommandPool(device, &commandPoolCreateInfo, null, &commandPool) == VkResult
        .VK_SUCCESS;
}

bool createCommandBuffer(ref VkDevice device, ref VkCommandPool commandPool,
        out VkCommandBuffer commandBuffer)
{
    VkCommandBufferAllocateInfo allocCreateInfo;
    allocCreateInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    allocCreateInfo.commandPool = commandPool;
    allocCreateInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocCreateInfo.commandBufferCount = 1;
    return vkAllocateCommandBuffers(device, &allocCreateInfo, &commandBuffer) == VK_SUCCESS;

}

bool createCommandBufferBegin(ref VkCommandBuffer commandBuffer,
        out VkCommandBufferBeginInfo bufferBeginInfo)
{
    bufferBeginInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    bufferBeginInfo.flags = 0;
    bufferBeginInfo.pInheritanceInfo = null;
    return vkBeginCommandBuffer(commandBuffer, &bufferBeginInfo) == VkResult.VK_SUCCESS;
}

bool createRenderPassBegin(ref VkCommandBuffer commandBuffer, ref VkRenderPass renderPass,
        uint imageIndex, out VkRenderPassBeginInfo renderPassBeginInfo)
{
    renderPassBeginInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    renderPassBeginInfo.renderPass = renderPass;
    return true;
    //renderPassBeginInfo.framebuffer = 
}
