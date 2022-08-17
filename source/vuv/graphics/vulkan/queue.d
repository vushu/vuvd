module vuv.graphics.vulkan.queue;
import erupted;



void present(ref VkQueue presentQueue, ref VkSemaphore[] signalSemaphores, ref VkSwapchainKHR swapchain, uint imageIndex)
{
    VkPresentInfoKHR presentInfo;
    presentInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
    presentInfo.waitSemaphoreCount = 1;
    presentInfo.pWaitSemaphores = signalSemaphores.ptr;
    VkSwapchainKHR[1] swapchains = swapchain;
    presentInfo.swapchainCount = 1;
    presentInfo.pSwapchains = swapchains.ptr;
    presentInfo.pImageIndices = &imageIndex;
    vkQueuePresentKHR(presentQueue, &presentInfo);
}
