module vuv.graphics.vulkan.swapchain;
import erupted;
import bindbc.sdl;
import std.algorithm.comparison : clamp, max;
import vuv.graphics.vulkan.physicaldevice : findQueueFamilies, QueueFamilyIndices;
import std.typecons : RefCounted;
import unit_threaded : Tags;

debug import std.stdio : writeln;

struct SwapchainSupportDetails
{
    VkSurfaceCapabilitiesKHR capabilities;
    VkSurfaceFormatKHR[] formats;
    VkPresentModeKHR[] presentModes;
}

struct SwapchainData
{
    VkFormat swapChainImageFormat;
    VkExtent2D swapChainExtent;
}

void enforceVk(VkResult res)
{
    import std.exception;
    import std.conv;

    enforce(res is VkResult.VK_SUCCESS, res.to!string);
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
        SwapchainData swapchainData;
        QueueFamilyIndices queueFamilyIndices;
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
            auto instance = deviceFixture.instanceFixture.instance;
            auto queueFamilyIndices = deviceFixture.queueFamilyIndices;

            loadDeviceLevelFunctions(instance);

            VkDevice device;
            SwapchainData swapchainData;

            instantiateDevice(physicalDevice, device, getRequiredValidationLayers, getRequiredDeviceExtensions, queueFamilyIndices)
                .shouldBeTrue;

            // important
            _fixture = RefCounted!TestSwapchainFixture(device, physicalDevice, surface,
                swapchainData,
                queueFamilyIndices,
                window, deviceFixture);
            return _fixture;
        }

    }

    static RefCounted!TestSwapchainFixture _fixture;
}

@("Testing querySwapChainSupport") unittest
{
    auto fixture = getSwapchainFixture();
    auto details = querySwapChainSupport(fixture.physicalDevice, fixture.surface);
    details.isSwapchainAdequate.shouldBeTrue;
    details.formats.length.shouldBeGreaterThan(0);
    details.presentModes.length.shouldBeGreaterThan(0);

    foreach (format; details.formats)
    {
        writelnUt("format: ", format);
    }
    foreach (presentMode; details.presentModes)
    {
        writelnUt("format: ", presentMode);
    }

}

@trusted
SwapchainSupportDetails querySwapChainSupport(ref VkPhysicalDevice physicalDevice, ref VkSurfaceKHR surface)
{
    SwapchainSupportDetails details;
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physicalDevice, surface, &details.capabilities);

    uint formatCount;

    vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, &formatCount, null);

    if (formatCount > 0)
    {
        // details.formats = new VkSurfaceFormatKHR[formatCount];
        // setting length allocates on the heap as above
        details.formats.length = formatCount;
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

bool isSwapchainAdequate(ref SwapchainSupportDetails details)
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

@("Testing chooseSwapPresentMode") unittest
{
    auto fixture = getSwapchainFixture();
    auto details = querySwapChainSupport(fixture.physicalDevice, fixture.surface);
    details.isSwapchainAdequate.shouldBeTrue;
    auto choosenPresentMode = chooseSwapPresentMode(details.presentModes);
    debug writelnUt("Chosen presentMode: ", choosenPresentMode);

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

@("Testing chooseSwapExtent") unittest
{
    auto fixture = getSwapchainFixture;
    auto details = querySwapChainSupport(fixture.physicalDevice, fixture.surface);
    details.isSwapchainAdequate.shouldBeTrue;
    details.capabilities.currentExtent.width = uint32_t.max;
    auto extent = chooseSwapExtent(details.capabilities, fixture.window);

    extent.width.should.be == 600;
    extent.height.should.be == details.capabilities.minImageExtent.height;

}

@trusted
VkExtent2D chooseSwapExtent(ref VkSurfaceCapabilitiesKHR capabilities, SDL_Window* sdlWindow)
{
    debug import unit_threaded;

    debug writelnUt("current extent width: ", capabilities.currentExtent.width);
    if (capabilities.currentExtent.width != uint32_t.max)
    {
        debug writelnUt("Returning current extent");
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
        writelnUt("minHeight: ", capabilities.minImageExtent.height);
    }

    actualExtent.width = clamp(actualExtent.width, capabilities.minImageExtent.width, capabilities
            .maxImageExtent.width);
    actualExtent.height = clamp(actualExtent.height, capabilities.minImageExtent.height, capabilities
            .maxImageExtent.height);
    return actualExtent;
}

@Tags("createSwapchain")
@("Testing createSwapchain")
unittest
{
    auto fixture = getSwapchainFixture;
    VkSwapchainKHR swapchain;
    SwapchainData swapchainData;
    uint graphicsFamily = fixture.queueFamilyIndices.graphicsFamily.get;
    uint presentFamily = fixture.queueFamilyIndices.presentFamily.get;

    createSwapchain(fixture.device, fixture.physicalDevice, fixture.surface, fixture.window, swapchain, swapchainData,
        graphicsFamily, presentFamily).shouldBeTrue;
    scope (exit)
    {
        vkDestroySwapchainKHR(fixture.device, swapchain, null);
    }
}

bool createSwapchain(ref VkDevice device, ref VkPhysicalDevice physicalDevice, ref VkSurfaceKHR surface,
    SDL_Window* window, ref VkSwapchainKHR swapchain, ref SwapchainData swapchainData,
    uint graphicsFamilyIndex,
    uint presentFamilyIndex)
{
    auto swapChainDetails = querySwapChainSupport(physicalDevice, surface);
    auto swapchainCreateInfo = createSwapchainInfo(physicalDevice, swapChainDetails,
        surface,
        swapchainData,
        window,
        graphicsFamilyIndex,
        presentFamilyIndex);
    return vkCreateSwapchainKHR(device, &swapchainCreateInfo, null, &swapchain) == VkResult
        .VK_SUCCESS;

}

VkSwapchainCreateInfoKHR createSwapchainInfo(
    ref VkPhysicalDevice physicalDevice,
    ref SwapchainSupportDetails defails,
    ref VkSurfaceKHR surface,
    ref SwapchainData swapchainData,
    SDL_Window* window,
    uint graphicsFamilyIndex, uint presentFamilyIndex)
{

    SwapchainSupportDetails swapChainSupport = querySwapChainSupport(physicalDevice, surface);
    VkSurfaceFormatKHR surfaceFormat = chooseSwapSurfaceFormat(swapChainSupport.formats);
    VkPresentModeKHR presentMode = chooseSwapPresentMode(swapChainSupport.presentModes);
    VkExtent2D extent = chooseSwapExtent(swapChainSupport.capabilities, window);
    uint imageCount = getImageCount(swapChainSupport.capabilities.minImageCount, swapChainSupport
            .capabilities.maxImageCount);

    swapchainData.swapChainExtent = extent;
    swapchainData.swapChainImageFormat = surfaceFormat.format;

    VkSwapchainCreateInfoKHR createInfo;

    createInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    createInfo.surface = surface;
    createInfo.minImageCount = cast(uint32_t) imageCount;
    createInfo.imageFormat = surfaceFormat.format;
    createInfo.imageColorSpace = surfaceFormat.colorSpace;
    createInfo.imageExtent = extent;
    createInfo.imageArrayLayers = 1;
    createInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;

    // auto indices = findQueueFamilies(physicalDevice, surface);

    if (graphicsFamilyIndex != presentFamilyIndex)
    {
        debug writeln("Using VK_SHARING_MODE_CONCURRENT");
        createInfo.imageSharingMode = VK_SHARING_MODE_CONCURRENT;
        createInfo.queueFamilyIndexCount = 2;

        uint32_t[] queueFamilyIndices = new uint32_t[2];
        queueFamilyIndices[0] = graphicsFamilyIndex;
        queueFamilyIndices[1] = presentFamilyIndex;

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

@("Testing getImageCount") unittest
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

@("Testing getSwapchainImages") unittest
{
    auto fixture = getSwapchainFixture;
    VkSwapchainKHR swapchain;
    SwapchainData swapchainData;
    uint graphicsFamily = fixture.queueFamilyIndices.graphicsFamily.get;
    uint presentFamily = fixture.queueFamilyIndices.presentFamily.get;
    createSwapchain(fixture.device, fixture.physicalDevice,
        fixture.surface, fixture.window,
        swapchain, swapchainData,
        graphicsFamily, presentFamily).shouldBeTrue;

    scope (exit)
    {
        vkDestroySwapchainKHR(fixture.device, swapchain, null);
    }

    auto swapchainImages = getSwapchainImages(fixture.device, swapchain);
    swapchainImages.length.shouldBeGreaterThan(0);

}

VkImage[] getSwapchainImages(ref VkDevice device, ref VkSwapchainKHR swapchain)
{
    uint imageCount;
    vkGetSwapchainImagesKHR(device, swapchain, &imageCount, null);
    VkImage[] swapchainImages = new VkImage[imageCount];
    vkGetSwapchainImagesKHR(device, swapchain, &imageCount, swapchainImages.ptr);
    return swapchainImages;
}
