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
import vuv.graphics.vertexstore;
import vuv.graphics.vulkan.memory;

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
        _sdlWindow = sdlWindow;
        assert(initializeVkInstance(_instance, _debugMessenger, getSDLVulkanExtensions(sdlWindow)));

        assert(createSurface(_sdlWindow, _instance, _surface));

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

        createLayoutNGraphicsPipeline();

        //creating framebuffers
        _swapchainFramebuffers = createSwapchainFramebuffers(_device, _imageViews, _renderPass, _swapchainData
                .swapChainExtent);

        assert(createCommandPool(_device, _queueFamilyIndices.graphicsFamily.get, _commandPool));

        createVertexBufferData();

        assert(createCommandBuffer(_device, _commandPool, getMaxFramesInFlight, _commandBuffers));

        writeln("Successfully created vulkan context");

        _recordData = CommandRecordData(_commandBuffers, _renderPass, _swapchainFramebuffers, _swapchainData
                .swapChainExtent);
        _syncObjects = createSyncObjects(_device, getMaxFramesInFlight);

    }

    void createVertexBufferData()
    {
        _vertexStore = getTriangleVertexStore;
        _vertexBuffers.length = 1;
        assert(createVertexBuffer(_vertexStore, _device, _vertexBuffers[0]));
        // memory
        VkMemoryRequirements memoryRequirements;
        getMemoryRequirements(_device, _vertexBuffers[0], memoryRequirements);
        uint result = findMemoryType(_physicalDevice, memoryRequirements.memoryTypeBits,
            VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VkMemoryPropertyFlagBits
                .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
        assert(result > 0);
        assert(allocateMemory(_device, _physicalDevice, memoryRequirements, _vertexBufferMemory));
        // binding test
        bindMemory(_device, _vertexBuffers[0], _vertexBufferMemory);
        mapVertexDataToVertexBuffer(_device, _vertexStore, _vertexBuffers[0], _vertexBufferMemory);

    }

    void createLayoutNGraphicsPipeline()
    {
        ShadersModules shaderModules;
        auto stages = createTriangleShaderStages(_device, shaderModules);

        auto colorBlendAttachment = createColorBlendAttachment();

        assert(createPipelineLayout(_device, _pipelineLayout));

        auto graphicsCreateInfos = createGraphicsPipelineCreateInfos(_device,
            _swapchainData, colorBlendAttachment, _renderPass, _pipelineLayout, stages);

        assert(createGraphicsPipeline(_device, graphicsCreateInfos, _graphicsPipeline));

        writeln("Created GraphicsPipeline!");
        cleanupShaderModules(_device, shaderModules);

    }

    void cleanup()
    {
        cleanupSwapchain();
        vkDestroyCommandPool(_device, _commandPool, null);

        // cleanupSwapchainFramebuffers(_swapchainFramebuffers, _device);

        vkDestroyPipeline(_device, _graphicsPipeline, null);
        vkDestroyPipelineLayout(_device, _pipelineLayout, null);
        vkDestroyRenderPass(_device, _renderPass, null);

        vkDestroyBuffer(_device, _vertexBuffers[0], null);
        vkFreeMemory(_device, _vertexBufferMemory, null);

        cleanupSyncObjects(_syncObjects, _device);
        // cleanupImageView(_imageViews, _device);

        // vkDestroySwapchainKHR(_device, _swapchain, null);

        vkDestroyDevice(_device, null);

        debug destroyDebugUtilMessengerExt(_instance, _debugMessenger, null);

        vkDestroySurfaceKHR(_instance, _surface, null);

        vkDestroyInstance(_instance, null);

        debug writeln("Destroyed vulkan");
    }

    void recreateSwapchain()
    {

        vkDeviceWaitIdle(_device);

        cleanupSwapchain();
        vkDestroyBuffer(_device, _vertexBuffers[0], null);

        assert(createSwapchain(_device, _physicalDevice, _surface, _sdlWindow, _swapchain, _swapchainData,
                _queueFamilyIndices.graphicsFamily.get, _queueFamilyIndices.presentFamily.get));
        _swapchainImages = getSwapchainImages(_device, _swapchain);
        _imageViews = createImageViews(_device, _swapchainImages, _swapchainData);
        _swapchainFramebuffers = createSwapchainFramebuffers(_device, _imageViews, _renderPass, _swapchainData
                .swapChainExtent);

        assert(_imageViews.length > 0);

        _recordData = CommandRecordData(_commandBuffers, _renderPass, _swapchainFramebuffers, _swapchainData
                .swapChainExtent);

    }

    void cleanupSwapchain()
    {
        cleanupSwapchainFramebuffers(_swapchainFramebuffers, _device);
        cleanupImageView(_imageViews, _device);
        vkDestroySwapchainKHR(_device, _swapchain, null);
    }

private:
    SDL_Window* _sdlWindow;
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
    bool _frameBufferResized = false;
    uint _currentFrame = 0;
    VertexStore _vertexStore;
    VkBuffer[] _vertexBuffers;
    VkDeviceMemory _vertexBufferMemory;
}

void drawFrame(ref Vulkan vulkan)
{
    vkWaitForFences(vulkan._device, 1, &vulkan._syncObjects.inFlightFences[vulkan._currentFrame], VK_TRUE, uint
            .max);
    uint imageIndex;

    VkResult result = vkAcquireNextImageKHR(
        vulkan._device, vulkan._swapchain, size_t.max, vulkan
            ._syncObjects.waitSemaphores[vulkan._currentFrame], VK_NULL_HANDLE, &imageIndex);

    if (result == VkResult.VK_ERROR_OUT_OF_DATE_KHR)
    {
        writeln("WHAT out of date! recreate swapchain!");
        vulkan.recreateSwapchain;
        return;
    }
    else if (result != VK_SUCCESS && result != VK_SUBOPTIMAL_KHR)
    {
        writeln("Failed to vkAcquireNextImageKHR");
        return;
    }
    vkResetFences(vulkan._device, 1, &vulkan._syncObjects
            .inFlightFences[vulkan._currentFrame]);

    vkResetCommandBuffer(vulkan._recordData.commandBuffers[vulkan._currentFrame], 0);

    recordCommandBuffer(vulkan._recordData, vulkan._graphicsPipeline, vulkan._vertexStore,
        vulkan._vertexBuffers, imageIndex, vulkan._currentFrame);

    if (submitCommandBuffer(vulkan._graphicsQueue, vulkan._presentQueue, vulkan._syncObjects, vulkan
            ._recordData.commandBuffers[vulkan._currentFrame], vulkan
            ._swapchain, vulkan._currentFrame))
    {

        VkSemaphore[] signalSemaphores;
        signalSemaphores.reserve(0);
        signalSemaphores ~= vulkan
            ._syncObjects.signalSemaphores[vulkan._currentFrame];
        RecreateSwapchain shouldRecreate = present(vulkan._presentQueue, signalSemaphores, vulkan
                ._swapchain, imageIndex, vulkan._frameBufferResized);

        switch (shouldRecreate)
        {
        case RecreateSwapchain.yes:
            debug writeln("Ok we need to recreate swapchain!");
            vulkan.recreateSwapchain;
            vulkan._frameBufferResized = false;
            break;
        case RecreateSwapchain.no:
            // debug writeln("We do not need to recreate swapchain");
            break;
        case RecreateSwapchain.error:
            debug writeln("Failed to present");
            break;
        default:
            debug writeln("Unknown case");
            break;
        }
        vulkan._currentFrame = (
            vulkan._currentFrame + 1) % getMaxFramesInFlight;
    }
    else
    {
        debug writeln("Failed to submit ");
    }
}

void waitIdle(ref Vulkan vulkan)
{
    vkDeviceWaitIdle(vulkan._device);
}

void resizeCallback(ref Vulkan vulkan, int width, int height)
{
    debug writeln("resizing vulkan callback");
    debug writeln("resizing vulkan callback");
    debug writeln("resizing vulkan callback");
    debug writeln("resizing vulkan callback");
    debug writeln("width ", width);
    debug writeln("height ", height);
    // vulkan.recreateSwapchain();
    if (width == 0 || height == 0)
    {
        return;
    }
    vulkan._frameBufferResized = true;
}
