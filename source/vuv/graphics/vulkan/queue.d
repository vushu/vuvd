module vuv.graphics.vulkan.queue;
import erupted;

enum RecreateSwapchain
{
    yes,
    no,
    error
}

RecreateSwapchain present(ref VkQueue presentQueue, ref VkSemaphore[] signalSemaphores, ref VkSwapchainKHR swapchain,
    uint imageIndex, bool frameBufferResized)
{
    VkPresentInfoKHR presentInfo;
    presentInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;

    presentInfo.waitSemaphoreCount = 1;
    presentInfo.pWaitSemaphores = signalSemaphores.ptr;

    VkSwapchainKHR[] swapchains;
    swapchains ~= swapchain;
    presentInfo.swapchainCount = 1;
    presentInfo.pSwapchains = swapchains.ptr;
    presentInfo.pImageIndices = &imageIndex;
    presentInfo.pResults = null;
    VkResult result = vkQueuePresentKHR(presentQueue, &presentInfo);
    if (result == VkResult.VK_ERROR_OUT_OF_DATE_KHR || result == VkResult.VK_SUBOPTIMAL_KHR
        || frameBufferResized)
    {
        // frameBufferResized = false;
        return RecreateSwapchain.yes;
    }
    else if (result != VK_SUCCESS)
    {
        return RecreateSwapchain.error;
    }
    return RecreateSwapchain.no;
}
