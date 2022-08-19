module vuv.graphics.vulkan.semaphore;
import erupted;

struct SyncObjects
{
    VkSemaphore[] waitSemaphores;
    VkSemaphore[] signalSemaphores;
    VkFence[] inFlightFences;
    uint numberOfSemaphores;
}

version (unittest)
{
    import vuv.graphics.vulkan.swapchain : getSwapchainFixture;
    import vuv.graphics.vulkan.staticvalues;
}

@("Testing createSyncObjects")
unittest
{
    auto fixture = getSwapchainFixture;
    SyncObjects syncObject = createSyncObjects(fixture.device, getMaxFramesInFlight);

}

SyncObjects createSyncObjects(VkDevice device, uint numberOfSemaphores)
{
    SyncObjects syncObjects;
    syncObjects.numberOfSemaphores = numberOfSemaphores;
    syncObjects.signalSemaphores.length = numberOfSemaphores;
    syncObjects.waitSemaphores.length = numberOfSemaphores;
    syncObjects.inFlightFences.length = numberOfSemaphores;
    for (uint i = 0; i < numberOfSemaphores; i++)
    {
        assert(createSemaphore(device, syncObjects.waitSemaphores[i]));
        assert(createSemaphore(device, syncObjects.signalSemaphores[i]));
        assert(createFence(device, true, syncObjects.inFlightFences[i]));
    }
    return syncObjects;
}

bool createSemaphore(ref VkDevice device, ref VkSemaphore semaphore)
{
    VkSemaphoreCreateInfo semaphoreCreateInfo;
    semaphoreCreateInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    return vkCreateSemaphore(device, &semaphoreCreateInfo, null, &semaphore) == VkResult.VK_SUCCESS;
}

bool createFence(ref VkDevice device, bool signaled, ref VkFence fence)
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
    for (uint i = 0; i < syncObjects.numberOfSemaphores; i++)
    {
        vkDestroySemaphore(device, syncObjects.waitSemaphores[i], null);
        vkDestroySemaphore(device, syncObjects.signalSemaphores[i], null);
        vkDestroyFence(device, syncObjects.inFlightFences[i], null);
    }
}
