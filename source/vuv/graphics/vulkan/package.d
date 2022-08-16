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

import unit_threaded : Tags;

debug import std.stdio : writeln;

debug import unit_threaded;

@Tags("vulkanstruct")
@("Test create Vulkan struct")
unittest
{
    auto sdlWindowFixture = getSDLWindowFixture();
    Vulkan vulkan = Vulkan("Test", sdlWindowFixture.window);
}

public:
import vuv.graphics.vulkan.instance;

struct Vulkan
{
    this(string title, SDL_Window* sdlWindow)
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
        auto renderPassCreateInfo = createRenderPassInfo(colorAttachmentDescription, subPass);

        assert(createRenderPass(_device, renderPassCreateInfo, _renderPass));

        assert(createCommandPool(_device, _queueFamilyIndices.graphicsFamily.get, _commandPool));

        assert(createCommandBuffer(_device, _commandPool, _commandBuffer));

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

        _syncObjects = createSyncObjects(_device);

    }

    nothrow @nogc @trusted ~this()
    {
        vkDestroyCommandPool(_device, _commandPool, null);

        cleanupSwapchainFramebuffers(_swapchainFramebuffers, _device);

        vkDestroyPipeline(_device, _graphicsPipeline, null);
        vkDestroyPipelineLayout(_device, _pipelineLayout, null);
        vkDestroyRenderPass(_device, _renderPass, null);

        cleanupImageView(_imageViews, _device);

        vkDestroySwapchainKHR(_device, _swapchain, null);

        cleanupSyncObjects(_syncObjects, _device);
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
    VkCommandBuffer _commandBuffer;
    VkPipelineLayout _pipelineLayout;
    VkPipeline _graphicsPipeline;
    VkFramebuffer[] _swapchainFramebuffers;
    SyncObjects _syncObjects;

}

void drawFrame(ref Vulkan vulkan)
{
    uint imageIndex;
    vkAcquireNextImageKHR(vulkan._device, vulkan._swapchain, Uint64.max, vulkan
            ._syncObjects.imageAvailableSemaphore, VK_NULL_HANDLE, &imageIndex);

    vkResetCommandBuffer(vulkan._commandBuffer, 0);

    vkWaitForFences(vulkan._device, 1, &vulkan._syncObjects.inFlightFence, VK_TRUE, Uint64.max);
    vkResetFences(vulkan._device, 1, &vulkan._syncObjects.inFlightFence);
}
