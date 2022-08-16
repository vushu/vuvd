module vuv.graphics.vulkan.semaphore;
import erupted;

struct SyncObjects
{
    VkSemaphore imageAvailableSemaphore;
    VkSemaphore renderFinishedSemaphore;
    VkFence inFlightFence;
}

version (unittest)
{
    import vuv.graphics.vulkan.swapchain : getSwapchainFixture;
}

@("Testing createSyncObjects")
unittest
{
    auto fixture = getSwapchainFixture;
    SyncObjects syncObject = createSyncObjects(fixture.device);

}

SyncObjects createSyncObjects(VkDevice device)
{
    SyncObjects syncObjects;
    assert(createSemaphore(device, syncObjects.imageAvailableSemaphore));
    assert(createSemaphore(device, syncObjects.renderFinishedSemaphore));
    assert(createFence(device, true, syncObjects.inFlightFence));
    return syncObjects;
}

bool createSemaphore(ref VkDevice device, out VkSemaphore semaphore)
{
    VkSemaphoreCreateInfo semaphoreCreateInfo;
    semaphoreCreateInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    return vkCreateSemaphore(device, &semaphoreCreateInfo, null, &semaphore) == VkResult.VK_SUCCESS;
}

bool createFence(ref VkDevice device, bool signaled, out VkFence fence)
{
    VkFenceCreateInfo fenceCreateInfo;
    fenceCreateInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    if (signaled)
    {
        fenceCreateInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;
    }

    return vkCreateFence(device, &fenceCreateInfo, null, &fence) == VkResult.VK_SUCCESS;
}

void cleanupSyncObjects(ref SyncObjects syncObjects, ref VkDevice device) @nogc nothrow
{
    vkDestroySemaphore(device, syncObjects.imageAvailableSemaphore, null);
    vkDestroySemaphore(device, syncObjects.renderFinishedSemaphore, null);
    vkDestroyFence(device, syncObjects.inFlightFence, null);
}
