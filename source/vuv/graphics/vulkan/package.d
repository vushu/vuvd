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
import erupted.vulkan_lib_loader;

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

        assert(instantiateDevice(_physicalDevice, _device,
                getRequiredValidationLayers, getRequiredDeviceExtensions, _surface));

        _graphicsQueue = getQueue(_device, _queueFamilyIndices.graphicsFamily.get);
        _presentQueue = getQueue(_device, _queueFamilyIndices.presentFamily.get);

        assert(createSwapchain(_device, _physicalDevice, _surface, sdlWindow, _swapchain, _swapchainData, _queueFamilyIndices
                .graphicsFamily.get, _queueFamilyIndices.presentFamily.get));

    }

    nothrow @nogc @trusted ~this()
    {
        vkDestroySwapchainKHR(_device, _swapchain, null);
        vkDestroyDevice(_device, null);

        debug destroyDebugUtilMessengerExt(_instance, _debugMessenger, null);

        vkDestroySurfaceKHR(_instance, _surface, null);

        vkDestroyInstance(_instance, null);
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
}
