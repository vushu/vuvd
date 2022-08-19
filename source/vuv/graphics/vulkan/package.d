module vuv.graphics.vulkan;
import vuv.graphics.window;
import bindbc.sdl;
import erupted;
import vuv.graphics.sdlhelper;
import vuv.graphics.vulkan.staticvalues;
import vuv.graphics.vulkan.physicaldevice;
import vuv.graphics.vulkan.logicaldevice;
import vuv.graphics.vulkan.surface;
import vuv.graphics.vulkan.swapchain;
import vuv.graphics.vulkan.imageview;
import erupted.vulkan_lib_loader;
import vuv.graphics.vulkan.commandbuffer;
import vuv.graphics.vulkan.graphicspipelines.trianglepipeline;
import vuv.graphics.vulkan.graphicspipelines.common;
import vuv.graphics.vulkan.graphicspipelines.pipelinelayout;
import vuv.graphics.vulkan.graphicspipelines.renderpass;
import vuv.graphics.vulkan.framebuffer;
import vuv.graphics.vulkan.semaphore;
import vuv.graphics.vulkan.queue;

import unit_threaded : Tags;

debug import std.stdio : writeln;

debug import unit_threaded;

@Tags("vulkanstruct")
@("Test create Vulkan struct")
unittest
{
    auto sdlWindowFixture = getSDLWindowFixture();
    Vulkan vulkan = Vulkan("Test", sdlWindowFixture.window);
    vulkan.cleanup();
}

public:
import vuv.graphics.vulkan.instance;

struct Vulkan
{
    this(string title, SDL_Window* sdlWindow, bool waitForImage = false)
    {
        assert(initializeVkInstance(_instance, _debugMessenger, getSDLVulkanExtensions(sdlWindow)));

        assert(createSurface(sdlWindow, _instance, _surface));

        assert(getPhysicalDevice(_instance, _physicalDevice, _surface, _queueFamilyIndices));

        loadDeviceLevelFunctions(_instance);

        assert(instantiateDevice(_physicalDevice, _device, getRequiredValidationLayers,
                getRequiredDeviceExtensions, _queueFamilyIndices));

        _graphicsQueue = getQueue(_device, _queueFamilyIndices.graphicsFamily.get);
        _presentQueue = getQueue(_device, _queueFamilyIndices.presentFamily.get);

        assert(createSwapchain(_device, _physicalDevice, _surface, sdlWindow, _swapchain, _swapchainData,
                _queueFamilyIndices.graphicsFamily.get, _queueFamilyIndices.presentFamily.get));
        _swapchainImages = getSwapchainImages(_device, _swapchain);

        _imageViews = createImageViews(_device, _swapchainImages, _swapchainData);
        assert(_imageViews.length > 0);

        //Creating renderpass
        auto colorAttachmentDescription = createAttachmentDescription(
            _swapchainData.swapChainImageFormat);
        auto colorAttachmentRefence = createColorAttachmentReference();
        auto subPass = createSubpassDescription(colorAttachmentRefence);
        auto renderPassCreateInfo = createRenderPassInfo(colorAttachmentDescription, subPass, waitForImage);

        assert(createRenderPass(_device, renderPassCreateInfo, _renderPass));

        assert(createCommandPool(_device, _queueFamilyIndices.graphicsFamily.get, _commandPool));

        assert(createCommandBuffer(_device, _commandPool, getMaxFramesInFlight, _commandBuffers));

        ShadersModules shaderModules;
        auto stages = createTriangleShaderStages(_device, shaderModules);

        auto colorBlendAttachment = createColorBlendAttachment();

        assert(createPipelineLayout(_device, _pipelineLayout));

        auto graphicsCreateInfos = createGraphicsPipelineCreateInfos(_device,
            _swapchainData, colorBlendAttachment, _renderPass, _pipelineLayout, stages);

        assert(createGraphicsPipeline(_device, graphicsCreateInfos, _graphicsPipeline));
        _swapchainFramebuffers = createSwapchainFramebuffers(_device, _imageViews, _renderPass, _swapchainData
                .swapChainExtent);

        writeln("Created GraphicsPipeline!");
        cleanupShaderModules(_device, shaderModules);

        writeln("Successfully created vulkan context");

        _recordData = CommandRecordData(_commandBuffers, _renderPass, _swapchainFramebuffers, _swapchainData
                .swapChainExtent);
        _syncObjects = createSyncObjects(_device, getMaxFramesInFlight);

    }

    void cleanup()
    {
        cleanupSyncObjects(_syncObjects, _device);
        vkDestroyCommandPool(_device, _commandPool, null);

        cleanupSwapchainFramebuffers(_swapchainFramebuffers, _device);

        vkDestroyPipeline(_device, _graphicsPipeline, null);
        vkDestroyPipelineLayout(_device, _pipelineLayout, null);
        vkDestroyRenderPass(_device, _renderPass, null);

        cleanupImageView(_imageViews, _device);

        vkDestroySwapchainKHR(_device, _swapchain, null);

        vkDestroyDevice(_device, null);

        debug destroyDebugUtilMessengerExt(_instance, _debugMessenger, null);

        vkDestroySurfaceKHR(_instance, _surface, null);

        vkDestroyInstance(_instance, null);

        debug writeln("Destroyed vulkan");
    }

private:
    VkInstance _instance;
    VkPhysicalDevice _physicalDevice;
    VkDebugUtilsMessengerEXT _debugMessenger;
    VkDevice _device;
    VkSurfaceKHR _surface;
    VkQueue _graphicsQueue, _presentQueue;
    VkSwapchainKHR _swapchain;
    QueueFamilyIndices _queueFamilyIndices;
    SwapchainData _swapchainData;
    VkRenderPass _renderPass;
    VkImage[] _swapchainImages;
    VkImageView[] _imageViews;
    VkCommandPool _commandPool;
    VkCommandBuffer[] _commandBuffers;
    VkPipelineLayout _pipelineLayout;
    VkPipeline _graphicsPipeline;
    VkFramebuffer[] _swapchainFramebuffers;
    CommandRecordData _recordData;
    SyncObjects _syncObjects;
    uint _currentFrame = 0;

}

void drawFrame(ref Vulkan vulkan)
{

    vkWaitForFences(vulkan._device, 1, &vulkan._syncObjects.inFlightFences[vulkan._currentFrame], VK_TRUE, uint
            .max);
    vkResetFences(vulkan._device, 1, &vulkan._syncObjects.inFlightFences[vulkan._currentFrame]);

    uint imageIndex;
    VkResult result = vkAcquireNextImageKHR(vulkan._device, vulkan._swapchain, size_t.max, vulkan
            ._syncObjects.waitSemaphores[vulkan._currentFrame], VK_NULL_HANDLE, &imageIndex);
    debug
    {
        if (result == VkResult.VK_ERROR_OUT_OF_DATE_KHR)
        {
            writeln("WHAT out of date!");
        }
    }

    vkResetCommandBuffer(vulkan._recordData.commandBuffers[vulkan._currentFrame], 0);

    recordCommandBuffer(vulkan._recordData, vulkan._graphicsPipeline, imageIndex, vulkan
            ._currentFrame);
    if (submitCommandBuffer(vulkan._graphicsQueue, vulkan._presentQueue, vulkan._syncObjects, vulkan
            ._recordData.commandBuffers[vulkan._currentFrame], vulkan
            ._swapchain, vulkan._currentFrame))
    {

        VkSemaphore[] signalSemaphores;
        signalSemaphores.reserve(0);
        signalSemaphores ~= vulkan._syncObjects.signalSemaphores[vulkan._currentFrame];
        present(vulkan._presentQueue, signalSemaphores, vulkan._swapchain, imageIndex);

        vulkan._currentFrame = (vulkan._currentFrame + 1) % getMaxFramesInFlight;
    }

}

void waitIdle(ref Vulkan vulkan)
{
    vkDeviceWaitIdle(vulkan._device);
}
