module vuv.graphics.vulkan.commandbuffer;
import erupted;
import vuv.graphics.vulkan.physicaldevice;
import std.typecons : Nullable, RefCounted, Unique;
import vuv.graphics.vulkan.semaphore;
import vuv.graphics.vulkan.queue;
import std.stdio : writeln;

struct CommandRecordData
{
    VkCommandBuffer commandBuffer;
    VkRenderPass renderPass;
    uint imageIndex;
    VkFramebuffer[] swapchainFramebuffers;
    VkExtent2D swapchainExtent;

}

version (unittest)
{

    import vuv.graphics.vulkan.logicaldevice : getQueue;
    import vuv.graphics.vulkan.swapchain;
    import vuv.graphics.vulkan.framebuffer;
    import vuv.graphics.vulkan.graphicspipelines.common;
    import vuv.graphics.vulkan.framebuffer;
    import vuv.graphics.vulkan.graphicspipelines.trianglepipeline;
    import vuv.graphics.vulkan.framebuffer;
    import vuv.graphics.vulkan.graphicspipelines.pipelinelayout;
    import unit_threaded;

    struct TestCommandBufferFixture
    {
        // @disable
        // this(this);
        VkDevice device;
        VkSwapchainKHR swapchain;
        SwapchainData swapchainData;
        VkRenderPass renderPass;
        VkImageView[] swapchainImageViews;
        VkCommandPool commandPool;
        VkCommandBuffer commandBuffer;
        VkPipelineLayout pipelineLayout;
        VkPipeline graphicsPipeline;
        VkQueue graphicsQueue;
        VkQueue presentQueue;
        CommandRecordData commandRecordData;
        RefCounted!TestFramebufferFixture framebufferFixture;
        ~this()
        {
            commandRecordData.swapchainFramebuffers.cleanupSwapchainFramebuffers(device);
            vkDestroyPipelineLayout(device, pipelineLayout, null);
        }
    }

    TestCommandBufferFixture getCommandBufferFixture()
    {
        synchronized
        {
            auto fixture = getRefcountedFramebufferFixture();
            VkCommandPool commandPool;
            VkCommandBuffer commandBuffer;
            assert(createCommandPool(fixture.device,
                    fixture.imageViewFixture.indices.graphicsFamily.get,
                    commandPool));
            assert(createCommandBuffer(fixture.device, commandPool, commandBuffer));
            ShadersModules shaderModules;
            auto stages = createTriangleShaderStages(fixture.device, shaderModules);

            auto colorBlendAttachment = createColorBlendAttachment();

            VkPipelineLayout pipelineLayout;

            assert(createPipelineLayout(fixture.device, pipelineLayout));

            auto graphicsCreateInfos = createGraphicsPipelineCreateInfos(fixture.device,
                fixture.swapchainData, colorBlendAttachment, fixture.renderPass, pipelineLayout, stages);

            VkPipeline graphicsPipeline;
            assert(createGraphicsPipeline(fixture.device, graphicsCreateInfos, graphicsPipeline));
            cleanupShaderModules(fixture.device, shaderModules);

            auto swapchainBuffers = createSwapchainFramebuffers(fixture.device, fixture.swapchainImageViews, fixture
                    .renderPass, fixture.swapchainData.swapChainExtent);
            swapchainBuffers.length.shouldBeGreaterThan(0);

            CommandRecordData recordData = CommandRecordData(commandBuffer, fixture.renderPass, fixture
                    .imageViewFixture.indices.graphicsFamily.get, swapchainBuffers, fixture
                    .swapchainData.swapChainExtent);

            auto graphicsQueue = getQueue(fixture.device, fixture
                    .imageViewFixture.indices.graphicsFamily.get);

            auto presentQueue = getQueue(fixture.device, fixture
                    .imageViewFixture.indices.presentFamily.get);
            return TestCommandBufferFixture(fixture.device, fixture.swapchain, fixture.swapchainData, fixture.renderPass,
                fixture.swapchainImageViews, commandPool, commandBuffer, pipelineLayout,
                graphicsPipeline, graphicsQueue, presentQueue, recordData, fixture);
        }
    }

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

bool createCommandBufferBegin(ref VkCommandBuffer commandBuffer)
{
    VkCommandBufferBeginInfo bufferBeginInfo;
    bufferBeginInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    bufferBeginInfo.flags = 0;
    bufferBeginInfo.pInheritanceInfo = null;
    return vkBeginCommandBuffer(commandBuffer, &bufferBeginInfo) == VkResult.VK_SUCCESS;
}

void createRenderPassBegin(
    ref VkCommandBuffer commandBuffer,
    ref VkRenderPass renderPass,
    uint imageIndex,
    ref VkFramebuffer[] swapchainFramebuffers,
    ref VkExtent2D swapchainExtent)
{
    VkRenderPassBeginInfo renderPassBeginInfo;
    renderPassBeginInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    renderPassBeginInfo.renderPass = renderPass;
    renderPassBeginInfo.framebuffer = swapchainFramebuffers[imageIndex];
    renderPassBeginInfo.renderArea.offset = VkOffset2D(0, 0);
    renderPassBeginInfo.renderArea.extent = swapchainExtent;
    VkClearValue[2] clearValues;
    VkClearColorValue color = {float32: [0.0f, 0.0f, 0.0f, 1.0f]};
    VkClearDepthStencilValue depthStencil = {depth: 1.0f, stencil: 0};
    clearValues[0].color = color;
    clearValues[1].depthStencil = depthStencil;

    renderPassBeginInfo.clearValueCount = clearValues.length;
    renderPassBeginInfo.pClearValues = clearValues.ptr;

    vkCmdBeginRenderPass(commandBuffer, &renderPassBeginInfo, VK_SUBPASS_CONTENTS_INLINE);
}

void setCommandViewport(ref VkCommandBuffer commandBuffer, ref VkExtent2D swapchainExtent)
{

    VkViewport viewport;
    viewport.x = 0.0f;
    viewport.y = 0.0f;
    viewport.width = cast(float) swapchainExtent.width;
    viewport.height = cast(float) swapchainExtent.height;
    viewport.minDepth = 0.0f;
    viewport.maxDepth = 1.0f;
    vkCmdSetViewport(commandBuffer, 0, 1, &viewport);
}

void setCommandScissor(ref VkCommandBuffer commandBuffer, ref VkExtent2D swapchainExtent)
{
    VkRect2D scissor;
    scissor.offset.x = 0;
    scissor.offset.y = 0;
    scissor.extent = swapchainExtent;
    vkCmdSetScissor(commandBuffer, 0, 1, &scissor);
}

@("Testing recordCommandBuffer")
unittest
{
    auto fixture = getCommandBufferFixture;
    assert(recordCommandBuffer(fixture.commandRecordData, fixture.graphicsPipeline));
}

@("Testing submitCommandBuffer")
unittest
{
    auto fixture = getCommandBufferFixture;

    auto syncObjects = createSyncObjects(fixture.device);
    uint imageIndex;
    vkAcquireNextImageKHR(fixture.device, fixture.swapchain, uint64_t.max, syncObjects.imageAvailableSemaphore,
        VK_NULL_HANDLE, &imageIndex);

    vkResetCommandBuffer(fixture.commandBuffer, 0);

    vkWaitForFences(fixture.device, 1, &syncObjects.inFlightFence, VK_TRUE, uint64_t.max);
    vkResetFences(fixture.device, 1, &syncObjects.inFlightFence);

    assert(recordCommandBuffer(fixture.commandRecordData, fixture.graphicsPipeline, imageIndex));
    assert(submitCommandBuffer(fixture.graphicsQueue, fixture.presentQueue, syncObjects, fixture.commandBuffer, fixture
            .swapchain, imageIndex));

}

bool recordCommandBuffer(ref CommandRecordData commandRecordData, ref VkPipeline graphicsPipeline, uint imageIndex)
{
    assert(createCommandBufferBegin(commandRecordData.commandBuffer));

    createRenderPassBegin(commandRecordData.commandBuffer,
        commandRecordData.renderPass, imageIndex, commandRecordData
            .swapchainFramebuffers, commandRecordData.swapchainExtent);

    vkCmdBindPipeline(commandRecordData.commandBuffer,
        VK_PIPELINE_BIND_POINT_GRAPHICS, graphicsPipeline);
    setCommandViewport(commandRecordData.commandBuffer, commandRecordData.swapchainExtent);

    setCommandScissor(commandRecordData.commandBuffer, commandRecordData.swapchainExtent);

    vkCmdDraw(commandRecordData.commandBuffer, 3, 1, 0, 0);

    vkCmdEndRenderPass(commandRecordData.commandBuffer);

    return vkEndCommandBuffer(commandRecordData.commandBuffer) == VkResult.VK_SUCCESS;
}

bool submitCommandBuffer(ref VkQueue graphicsQueue, ref VkQueue presentQueue, ref SyncObjects syncObjects, ref VkCommandBuffer commandBuffer,
    ref VkSwapchainKHR swapchain, uint32_t imageIndex)
{
    VkSubmitInfo submitCreateInfo;
    submitCreateInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;

    VkSemaphore[] waitSemaphores;
    waitSemaphores ~= syncObjects.imageAvailableSemaphore;

    VkPipelineStageFlags[] waitStages;
    waitStages ~= VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

    submitCreateInfo.waitSemaphoreCount = 1;
    submitCreateInfo.pWaitSemaphores = waitSemaphores.ptr;
    submitCreateInfo.pWaitDstStageMask = waitStages.ptr;
    submitCreateInfo.commandBufferCount = 1;
    submitCreateInfo.pCommandBuffers = &commandBuffer;

    VkSemaphore[] signalSemaphores;
    signalSemaphores ~= syncObjects.renderFinishedSemaphore;
    submitCreateInfo.signalSemaphoreCount = 1;
    submitCreateInfo.pSignalSemaphores = signalSemaphores.ptr;

    if (vkQueueSubmit(graphicsQueue, 1, &submitCreateInfo, syncObjects.inFlightFence) == VkResult
        .VK_SUCCESS)
    {
        present(presentQueue, signalSemaphores, swapchain, imageIndex);
        return true;
    }
    return false;

}
