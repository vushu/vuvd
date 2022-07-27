module vuv.graphics.vulkan.swapchain;
import erupted;
import bindbc.sdl;
import std.algorithm.comparison : clamp, max;
import vuv.graphics.vulkan.physicaldevice : findQueueFamilies;
import std.typecons : RefCounted;

debug import std.stdio : writeln;

struct SwapChainSupportDetails
{
    VkSurfaceCapabilitiesKHR capabilities;
    VkSurfaceFormatKHR[] formats;
    VkPresentModeKHR[] presentModes;
}

version (unittest)
{
    import unit_threaded;
    import vuv.graphics.vulkan.logicaldevice;
    import vuv.graphics.vulkan.staticvalues;

    struct TestSwapchainFixture
    {
        @disable this(this);
        VkDevice device;
        VkPhysicalDevice physicalDevice;
        VkSurfaceKHR surface;
        VkQueue graphicsQueue;
        VkQueue presentQueue;
        SDL_Window* window;
        RefCounted!TestVkDeviceFixture deviceFixture;
        ~this()
        {
        }
    }

    RefCounted!TestSwapchainFixture getSwapchainFixture()
    {
        synchronized
        {
            if (_fixture.refCountedStore.isInitialized)
            {
                return _fixture;
            }
            auto deviceFixture = getVkDeviceFixture();
            auto window = deviceFixture.instanceFixture.sdlWindowFixture.window;
            auto physicalDevice = deviceFixture.physicalDevice;
            auto surface = deviceFixture.instanceFixture.surface;
            VkDevice device;
            VkQueue graphicsQueue;
            VkQueue presentQueue;
            instantiateDevice(physicalDevice, device, getRequiredValidationLayers, surface, graphicsQueue, presentQueue)
                .shouldBeTrue;

            _fixture = RefCounted!TestSwapchainFixture(device, physicalDevice, surface, graphicsQueue,
                presentQueue, window, deviceFixture);
            return _fixture;
        }

    }

    static RefCounted!TestSwapchainFixture _fixture;
}

@("Testing querySwapChainSupport")
unittest
{
    auto fixture = getVkDeviceFixture();
    auto details = querySwapChainSupport(fixture.physicalDevice, fixture.instanceFixture.surface);
    details.isSwapChainAdequate.shouldBeTrue;
    foreach (format; details.formats)
    {
        writelnUt("format: ", format);
    }

}

@trusted
SwapChainSupportDetails querySwapChainSupport(ref VkPhysicalDevice physicalDevice, ref VkSurfaceKHR surface)
{
    SwapChainSupportDetails details;
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physicalDevice, surface, &details.capabilities);

    uint formatCount;

    vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, &formatCount, null);

    if (formatCount > 0)
    {
        details.formats = new VkSurfaceFormatKHR[formatCount];
        vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, &formatCount, details
                .formats.ptr);
    }

    uint presentModeCount;
    vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, &presentModeCount, null);
    if (presentModeCount > 0)
    {
        details.presentModes = new VkPresentModeKHR[presentModeCount];
        vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, &presentModeCount, details
                .presentModes.ptr);
    }

    return details;
}

bool isSwapChainAdequate(ref SwapChainSupportDetails details)
{
    return details.formats.length > 0 && details.presentModes.length > 0;
}

VkSurfaceFormatKHR chooseSwapSurfaceFormat(ref VkSurfaceFormatKHR[] availableFormats)
{
    foreach (availableFormat; availableFormats)
    {
        if (availableFormat.format == VK_FORMAT_B8G8R8A8_SRGB
            && availableFormat.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
        {
            return availableFormat;
        }
    }

    return availableFormats[0];
}

VkPresentModeKHR chooseSwapPresentMode(ref VkPresentModeKHR[] availablePresentModes)
{
    foreach (availablePresentMode; availablePresentModes)
    {
        if (availablePresentMode == VK_PRESENT_MODE_MAILBOX_KHR)
        {
            return availablePresentMode;
        }
    }

    return VK_PRESENT_MODE_FIFO_KHR;
}

@("Testing chooseSwapExtent")
unittest
{
    auto fixture = getVkDeviceFixture();
    auto details = querySwapChainSupport(fixture.physicalDevice, fixture.instanceFixture.surface);
    details.isSwapChainAdequate.shouldBeTrue;
    auto extent = chooseSwapExtent(details.capabilities, fixture.window);
    extent.width.should.be == 600;

}

@trusted
VkExtent2D chooseSwapExtent(ref VkSurfaceCapabilitiesKHR capabilities, SDL_Window* sdlWindow)
{
    debug import unit_threaded;

    debug writelnUt("current Extent", capabilities.currentExtent.width);
    if (capabilities.currentExtent.width == uint32_t.max)
    {
        return capabilities.currentExtent;
    }
    int width, height;
    SDL_GetWindowSize(sdlWindow, &width, &height);
    auto actualExtent = VkExtent2D(width, height);
    debug
    {
        import unit_threaded;

        writelnUt("sdlWidth: ", width);
        writelnUt("sdlHeight: ", height);
    }

    actualExtent.width = clamp(actualExtent.width, capabilities.minImageExtent.width, capabilities
            .maxImageExtent.width);
    actualExtent.height = clamp(actualExtent.height, capabilities.minImageExtent.height, capabilities
            .maxImageExtent.height);
    return actualExtent;
}

@("Testing createSwapchain")
unittest
{
    auto fixture = getSwapchainFixture;
    VkSwapchainKHR swapchain;
    createSwapchain(fixture.device, fixture.physicalDevice, fixture.surface, fixture.window, swapchain)
        .shouldBeTrue;
    scope (exit)
    {
        vkDestroySwapchainKHR(fixture.device, swapchain, null);
    }
}

bool createSwapchain(ref VkDevice device, ref VkPhysicalDevice physicalDevice, ref VkSurfaceKHR surface,
    SDL_Window* window, ref VkSwapchainKHR swapchain)
{
    auto swapChainDetails = querySwapChainSupport(physicalDevice, surface);

    auto swapchainCreateInfo = createSwapchainInfo(physicalDevice, swapChainDetails, surface, window);

    return vkCreateSwapchainKHR(device, &swapchainCreateInfo, null, &swapchain) == VK_SUCCESS;
}

VkSwapchainCreateInfoKHR createSwapchainInfo(
    ref VkPhysicalDevice physicalDevice,
    ref SwapChainSupportDetails defails,
    ref VkSurfaceKHR surface,
    SDL_Window* window)
{

    SwapChainSupportDetails swapChainSupport = querySwapChainSupport(physicalDevice, surface);
    VkSurfaceFormatKHR surfaceFormat = chooseSwapSurfaceFormat(swapChainSupport.formats);
    VkPresentModeKHR presentMode = chooseSwapPresentMode(swapChainSupport.presentModes);
    VkExtent2D extent = chooseSwapExtent(swapChainSupport.capabilities, window);

    VkSwapchainCreateInfoKHR createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    createInfo.surface = surface;
    createInfo.minImageCount = getImageCount(swapChainSupport.capabilities.minImageCount, swapChainSupport
            .capabilities.maxImageCount);
    createInfo.imageFormat = surfaceFormat.format;
    createInfo.imageColorSpace = surfaceFormat.colorSpace;
    createInfo.imageExtent = extent;
    createInfo.imageArrayLayers = 1;
    createInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;

    auto indices = findQueueFamilies(physicalDevice, surface);

    if (indices.graphicsFamily.get != indices.presentFamily.get)
    {
        debug writeln("Using VK_SHARING_MODE_CONCURRENT");
        createInfo.imageSharingMode = VK_SHARING_MODE_CONCURRENT;
        createInfo.queueFamilyIndexCount = 2;
        uint32_t[] queueFamilyIndices = new uint32_t[2];
        queueFamilyIndices[0] = indices.graphicsFamily.get;
        queueFamilyIndices[1] = indices.presentFamily.get;

        createInfo.pQueueFamilyIndices = queueFamilyIndices.ptr;
    }
    else
    {
        debug writeln("Using VK_SHARING_MODE_EXCLUSIVE");
        createInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
        createInfo.queueFamilyIndexCount = 0;
        createInfo.pQueueFamilyIndices = null;
    }

    createInfo.preTransform = swapChainSupport.capabilities.currentTransform;
    createInfo.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    createInfo.presentMode = presentMode;
    createInfo.clipped = VK_TRUE;
    createInfo.oldSwapchain = VK_NULL_HANDLE;

    return createInfo;

}

@("Testing getImageCount")
unittest
{
    getImageCount(6, 6).should.be == 6;
    getImageCount(6, 0).should.be == 7;
    getImageCount(4, 0).should.be == 5;
    getImageCount(4, 4).should.be == 4;
    getImageCount(0, 0).should.be == 1;
    getImageCount(0, 1).should.be == 1;
    getImageCount(2, 1).should.be == 1;
}

uint getImageCount(uint minImageCount, uint maxImageCount)
{
    uint imageCount = minImageCount + 1;
    return maxImageCount > 0 && imageCount > maxImageCount ? maxImageCount : imageCount;
}
