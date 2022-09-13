module vuv.graphics.vulkan.commandbuffer;
import erupted;
import vuv.graphics.vulkan.physicaldevice;
import std.algorithm.mutation : move;
import std.typecons : Nullable, RefCounted, refCounted, Unique;
import vuv.graphics.vulkan.semaphore;
import vuv.graphics.vulkan.queue;
import std.stdio : writeln;
import vuv.graphics.vertexstore;
import unit_threaded : Tags;

struct CommandRecordData
{
    VkCommandBuffer[] commandBuffers;
    VkRenderPass renderPass;
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
    import vuv.graphics.vulkan.imageview;
    import vuv.graphics.vulkan.staticvalues;

    import unit_threaded;

    struct TestCommandBufferFixture
    {
        // @disable
        // this(this);
        VkDevice device;
        VkPhysicalDevice physicalDevice;
        VkSwapchainKHR swapchain;
        SwapchainData swapchainData;
        VkRenderPass renderPass;
        VkImageView[] swapchainImageViews;
        VkCommandPool commandPool;
        VkCommandBuffer[] commandBuffers;
        VkPipelineLayout pipelineLayout;
        VkPipeline graphicsPipeline;
        VkQueue graphicsQueue;
        VkQueue presentQueue;
        CommandRecordData commandRecordData;
        RefCounted!TestFramebufferFixture framebufferFixture;
        ~this()
        {
            debug writeln("Destroying this");
            commandRecordData.swapchainFramebuffers.cleanupSwapchainFramebuffers(device);
            vkDestroyPipelineLayout(device, pipelineLayout, null);
        }
    }

    RefCounted!TestCommandBufferFixture getRefCountedCommandBufferFixture()
    {
        synchronized
        {
            auto fixture = getRefcountedFramebufferFixture();
            VkCommandPool commandPool;
            VkCommandBuffer[] commandBuffers;
            assert(createCommandPool(fixture.device,
                    fixture.imageViewFixture.indices.graphicsFamily.get,
                    commandPool));
            assert(createCommandBuffer(fixture.device, commandPool, getMaxFramesInFlight, commandBuffers));
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

            CommandRecordData recordData = CommandRecordData(commandBuffers,
                fixture.renderPass,
                swapchainBuffers, fixture.swapchainData.swapChainExtent);

            auto graphicsQueue = getQueue(fixture.device, fixture
                    .imageViewFixture.indices.graphicsFamily.get);

            auto presentQueue = getQueue(fixture.device, fixture
                    .imageViewFixture.indices.presentFamily.get);
            return RefCounted!TestCommandBufferFixture(fixture.device, fixture.physicalDevice, fixture.swapchain, fixture.swapchainData, fixture.renderPass,
                fixture.swapchainImageViews, commandPool, commandBuffers, pipelineLayout,
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

    VkCommandBuffer[] commandBuffers;
    assert(createCommandBuffer(fixture.device, commandPool, getMaxFramesInFlight, commandBuffers));
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

bool createCommandBuffer(ref VkDevice device, ref VkCommandPool commandPool, uint maxFramesInFlight,
    out VkCommandBuffer[] commandBuffers)
{
    commandBuffers.length = maxFramesInFlight;
    VkCommandBufferAllocateInfo allocCreateInfo;
    allocCreateInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    allocCreateInfo.commandPool = commandPool;
    allocCreateInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocCreateInfo.commandBufferCount = maxFramesInFlight;
    return vkAllocateCommandBuffers(device, &allocCreateInfo, commandBuffers.ptr) == VK_SUCCESS;

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

@Tags("recordCommandBuffer")
@("Testing recordCommandBuffer")
unittest
{
    auto fixture = getRefCountedCommandBufferFixture;

    auto syncObjects = createSyncObjects(fixture.device, getMaxFramesInFlight);
    uint imageIndex;
    getNextImage(fixture.device, fixture.swapchain, syncObjects.waitSemaphores[0], imageIndex);

    auto vertexStore = getTriangleVertexStore;
    VkBuffer[1] vertexBuffers;
    auto usage = VkBufferUsageFlagBits.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;

    assert(createVertexBuffer(fixture.device, vertexStore.getSize, usage, vertexBuffers[0]));

    assert(recordCommandBuffer(fixture.commandRecordData,
            fixture.graphicsPipeline, vertexStore,
            vertexBuffers, imageIndex, 0));

    scope (exit)
    {
        vkDestroyBuffer(fixture.device, vertexBuffers[0], null);
    }
}

@("Testing submitCommandBuffer")
unittest
{
    auto fixture = getRefCountedCommandBufferFixture;

    auto syncObjects = createSyncObjects(fixture.device, getMaxFramesInFlight);
    uint imageIndex;
    getNextImage(fixture.device, fixture.swapchain, syncObjects.waitSemaphores[0], imageIndex);

    vkResetCommandBuffer(fixture.commandBuffers[0], 0);

    vkWaitForFences(fixture.device, 1, &syncObjects.inFlightFences[0], VK_TRUE, uint64_t.max);
    vkResetFences(fixture.device, 1, &syncObjects.inFlightFences[0]);

    auto vertexStore = getTriangleVertexStore;
    VkBuffer[1] vertexBuffers;

    auto usage = VkBufferUsageFlagBits.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
    assert(createVertexBuffer(fixture.device, vertexStore.getSize, usage, vertexBuffers[0]));

    assert(recordCommandBuffer(fixture.commandRecordData, fixture.graphicsPipeline, vertexStore, vertexBuffers, imageIndex, 0));
    assert(submitCommandBuffer(fixture.graphicsQueue, fixture.presentQueue, syncObjects, fixture.commandBuffers[0], fixture
            .swapchain, 0));

    vkWaitForFences(fixture.device, 1, &syncObjects.inFlightFences[0], VK_TRUE, uint64_t.max);
    vkResetFences(fixture.device, 1, &syncObjects.inFlightFences[0]);

}

bool recordCommandBuffer(ref CommandRecordData commandRecordData, ref VkPipeline graphicsPipeline, ref VertexStore vertexStore,
    VkBuffer[] vertexBuffers, uint imageIndex, uint currentFrame)
{
    assert(createCommandBufferBegin(commandRecordData.commandBuffers[currentFrame]));

    createRenderPassBegin(commandRecordData.commandBuffers[currentFrame],
        commandRecordData.renderPass, imageIndex, commandRecordData
            .swapchainFramebuffers, commandRecordData.swapchainExtent);

    vkCmdBindPipeline(commandRecordData.commandBuffers[currentFrame],
        VK_PIPELINE_BIND_POINT_GRAPHICS, graphicsPipeline);
    setCommandViewport(commandRecordData.commandBuffers[currentFrame], commandRecordData
            .swapchainExtent);

    setCommandScissor(commandRecordData.commandBuffers[currentFrame], commandRecordData
            .swapchainExtent);

    VkBuffer[1] numberOfvertexBuffers = vertexBuffers[0];
    VkDeviceSize[1] offsets = 0;
    vkCmdBindVertexBuffers(commandRecordData.commandBuffers[currentFrame], 0, 1,
        numberOfvertexBuffers.ptr, offsets.ptr);

    // using index buffer which is index of 1 so vertextBuffers[1]
    vkCmdBindIndexBuffer(commandRecordData.commandBuffers[currentFrame], vertexBuffers[1], 0, VK_INDEX_TYPE_UINT32);

    vkCmdDrawIndexed(commandRecordData.commandBuffers[currentFrame], cast(uint32_t) vertexStore.indices.length,
        1, 0, 0, 0);

    vkCmdEndRenderPass(commandRecordData.commandBuffers[currentFrame]);

    return vkEndCommandBuffer(commandRecordData.commandBuffers[currentFrame]) == VkResult
        .VK_SUCCESS;
}

bool submitCommandBuffer(ref VkQueue graphicsQueue, ref VkQueue presentQueue, ref SyncObjects syncObjects, ref VkCommandBuffer commandBuffer,
    ref VkSwapchainKHR swapchain, uint currentFrame)
{
    VkSemaphore[1] waitSemaphores = syncObjects.waitSemaphores[currentFrame];
    VkSubmitInfo submitCreateInfo;
    submitCreateInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;

    VkPipelineStageFlags[] waitStages;
    waitStages ~= VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

    submitCreateInfo.waitSemaphoreCount = 1;
    submitCreateInfo.pWaitSemaphores = waitSemaphores.ptr;
    submitCreateInfo.pWaitDstStageMask = waitStages.ptr;
    submitCreateInfo.commandBufferCount = 1;
    submitCreateInfo.pCommandBuffers = &commandBuffer;

    VkSemaphore[1] signalSemaphores = syncObjects.signalSemaphores[currentFrame];
    submitCreateInfo.signalSemaphoreCount = 1;
    submitCreateInfo.pSignalSemaphores = signalSemaphores.ptr;

    return vkQueueSubmit(graphicsQueue, 1, &submitCreateInfo, syncObjects
            .inFlightFences[currentFrame]) == VkResult
        .VK_SUCCESS;
}
