module vuv.graphics.vulkan.imageview;
import erupted;
import std.typecons : RefCounted;
import vuv.graphics.vulkan.physicaldevice : QueueFamilyIndices;
import vuv.graphics.vulkan.swapchain;

version (unittest)
{
    import vuv.graphics.vulkan.swapchain;

    struct TestImageViewFixture
    {
        @disable this(this);

        VkSwapchainKHR swapchain;
        VkImage[] swapchainImages;
        SwapchainData swapchainData;
        RefCounted!TestSwapchainFixture swapchainFixture;
    }

    RefCounted!TestImageViewFixture getImageViewFixture()
    {
        synchronized
        {
            if (_fixture.refCountedStore.isInitialized)
            {
                return _fixture;
            }

            auto fixture = getSwapchainFixture;
            VkSwapchainKHR swapchain;
            SwapchainData swapchainData;
            QueueFamilyIndices indices = fixture.queueFamilyIndices;
            assert(createSwapchain(fixture.device, fixture.physicalDevice, fixture.surface, fixture.window, swapchain,
                    swapchainData, indices.graphicsFamily.get, indices.presentFamily.get));
            auto swapchainImages = getSwapchainImages(fixture.device, swapchain);
            _fixture = RefCounted!TestImageViewFixture(swapchain, swapchainImages, swapchainData, fixture);
            return _fixture;
        }
    }

    static RefCounted!TestImageViewFixture _fixture;
}

VkImageView[] createImageViews(ref VkImage[] swapchainImages, ref SwapchainData swapchainData)
{
    VkImageView[] swapchainImageViews = new VkImageView[swapchainImages.length];
    foreach (i, swapchainImage; swapchainImages)
    {
        VkImageViewCreateInfo createInfo;

        createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
        createInfo.image = swapchainImages[i];
        createInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
        createInfo.format = swapchainData.swapChainImageFormat;

    }
    return swapchainImageViews;
    // VkImageViewCreateInfo createInfo;
    // return createInfo;
}
