module vuv.graphics.vulkan.imageview;
import erupted;
import vuv.graphics.vulkan.physicaldevice : QueueFamilyIndices;
import vuv.graphics.vulkan.swapchain;

debug import std.stdio;

version (unittest)
{
    import vuv.graphics.vulkan.swapchain;
    import unit_threaded;

    struct TestImageViewFixture
    {

        VkDevice device;
        VkSwapchainKHR swapchain;
        VkImage[] swapchainImages;
        SwapchainData swapchainData;
        ~this()
        {
            writeln("HEJ");
            vkDestroySwapchainKHR(device, swapchain, null);
        }
    }

    TestImageViewFixture getImageViewFixture()
    {
        synchronized
        {

            auto fixture = getSwapchainFixture;
            VkSwapchainKHR swapchain;
            SwapchainData swapchainData;
            QueueFamilyIndices indices = fixture.queueFamilyIndices;
            assert(createSwapchain(fixture.device, fixture.physicalDevice, fixture.surface, fixture.window, swapchain,
                    swapchainData, indices.graphicsFamily.get, indices.presentFamily.get));
            auto swapchainImages = getSwapchainImages(fixture.device, swapchain);
            auto testFixture = TestImageViewFixture(fixture.device, swapchain,
                    swapchainImages, swapchainData);
            return testFixture;
        }
    }

}

@("Testing createImageViews")
unittest
{
    auto fixture = getImageViewFixture;

    auto imageViews = createImageViews(fixture.device, fixture.swapchainImages,
            fixture.swapchainData);
    imageViews.length.shouldEqual(fixture.swapchainImages.length);
    scope (exit)
    {
        cleanupImageView(fixture.device, imageViews);
    }

}

VkImageView[] createImageViews(ref VkDevice device, ref VkImage[] swapchainImages,
        ref SwapchainData swapchainData)
{
    VkImageView[] swapchainImageViews = new VkImageView[swapchainImages.length];
    foreach (i, swapchainImage; swapchainImages)
    {
        VkImageViewCreateInfo createInfo;

        createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
        createInfo.image = swapchainImages[i];
        createInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
        createInfo.format = swapchainData.swapChainImageFormat;
        createInfo.components.r = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_IDENTITY;
        createInfo.components.g = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_IDENTITY;
        createInfo.components.b = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_IDENTITY;
        createInfo.components.a = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_IDENTITY;
        createInfo.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        createInfo.subresourceRange.baseMipLevel = 0;
        createInfo.subresourceRange.levelCount = 1;
        createInfo.subresourceRange.baseArrayLayer = 0;
        createInfo.subresourceRange.layerCount = 1;
        if (vkCreateImageView(device, &createInfo, null,
                &swapchainImageViews[i]) == VkResult.VK_SUCCESS)
        {
            debug writeln("Failed to create swaphainImagesViews");
            break;
        }

    }

    return swapchainImageViews;
}

void cleanupImageView(ref VkDevice device, ref VkImageView[] imageViews)
{
    foreach (imageview; imageViews)
    {
        vkDestroyImageView(device, imageview, null);
    }
}
