module vuv.graphics.vulkan.imageview;
import erupted;
import vuv.graphics.vulkan.physicaldevice : QueueFamilyIndices;
import vuv.graphics.vulkan.swapchain;
import unit_threaded : Tags;
import std.typecons : RefCounted, Unique;

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
        QueueFamilyIndices indices;
        // RefCounted!TestSwapchainFixture swapchainFixture;
        ~this()
        {
            debug writeln("noooooo destroyed ");
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
                swapchainImages, swapchainData, indices);
            return testFixture;
        }
    }

    RefCounted!TestImageViewFixture getRefCountedImageViewFixture()
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
            return RefCounted!TestImageViewFixture(fixture.device, swapchain,
                swapchainImages, swapchainData, indices);
        }
    }

}

@Tags("createImageViews")
@("Testing createImageViews")
unittest
{
    auto fixture = getImageViewFixture;

    VkImageView[] swapchainImageViews = createImageViews(fixture.device,
        fixture.swapchainImages, fixture.swapchainData);
    swapchainImageViews.length.shouldEqual(fixture.swapchainImages.length);

    scope (exit)
    {

        swapchainImageViews.cleanupImageView(fixture.device);
    }

}

VkImageView[] createImageViews(ref VkDevice device, ref VkImage[] swapchainImages,
    ref SwapchainData swapchainData)
{
    debug writeln("SwapchainImages: ", swapchainImages.length);
    VkImageView[] swapchainImageViews;
    swapchainImageViews.reserve(swapchainImages.length);

    foreach (i, swapchainImage; swapchainImages)
    {
        VkImageViewCreateInfo createInfo;

        createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
        createInfo.image = swapchainImage;
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
        VkImageView imageView;

        if (vkCreateImageView(device, &createInfo, null, &imageView) != VkResult.VK_SUCCESS)
        {
            debug writeln("Failed to create SwapchainImageViews");
            break;
        }
        swapchainImageViews ~= imageView;

    }

    debug writeln("SwapchainImageViews Length: ", swapchainImageViews.length);

    return swapchainImageViews;

}

void cleanupImageView(ref VkImageView[] imageViews, ref VkDevice device) nothrow @nogc
{
    foreach (imageview; imageViews)
    {
        vkDestroyImageView(device, imageview, null);
    }
}

bool getNextImage(ref VkDevice device, ref VkSwapchainKHR swapchain, ref VkSemaphore waitSemaphore, out uint imageIndex)
{
    VkResult result = vkAcquireNextImageKHR(device, swapchain, size_t.max, waitSemaphore, VK_NULL_HANDLE, &imageIndex);
    return result == VkResult.VK_SUCCESS;
}
