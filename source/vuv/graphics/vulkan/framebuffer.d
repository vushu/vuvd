module vuv.graphics.vulkan.framebuffer;
import erupted;
import std.typecons : RefCounted, Unique;
import std.algorithm : move;

debug import std.stdio;

version (unittest)
{
    import vuv.graphics.vulkan.graphicspipelines.renderpass;
    import vuv.graphics.vulkan.swapchain : SwapchainData;
    import vuv.graphics.vulkan.imageview;
    import unit_threaded;

    struct TestFramebufferFixture
    {
        // @disable
        // this(this);
        VkDevice device;
        VkAttachmentDescription colorAttachmentDescription;
        VkAttachmentReference colorAttachmentRefence;
        SwapchainData swapchainData;
        VkRenderPass renderPass;
        VkImageView[] swapchainImageViews;
        RefCounted!TestImageViewFixture imageViewFixture;
        ~this()
        {
            vkDestroyRenderPass(device, renderPass, null);
            cleanupImageView(swapchainImageViews, device);
        }
    }

    TestFramebufferFixture getFramebufferFixture()
    {
        synchronized
        {
            auto fixture = getRefCountedImageViewFixture();
            auto colorAttachmentDescription = createAttachmentDescription(
                fixture.swapchainData.swapChainImageFormat);
            auto colorAttachmentRefence = createColorAttachmentReference();
            auto subPass = createSubpassDescription(colorAttachmentRefence);
            auto createInfo = createRenderPassInfo(colorAttachmentDescription, subPass);
            VkRenderPass renderPass;
            VkImageView[] swapchainImageViews;
            fixture.swapchainImages.length.shouldBeGreaterThan(0);
            swapchainImageViews = createImageViews(fixture.device,
                fixture.swapchainImages, fixture.swapchainData);
            swapchainImageViews.length.shouldBeGreaterThan(0);
            assert(createRenderPass(fixture.device, createInfo, renderPass));
            return TestFramebufferFixture(fixture.device, colorAttachmentDescription,
                colorAttachmentRefence, fixture.swapchainData, renderPass,
                swapchainImageViews, fixture);
        }
    }
}

@("Testing createSwapchainFramebuffers")
unittest
{
    auto fixture = getFramebufferFixture();
    auto swapchainbuffers = createSwapchainFramebuffers(fixture.device, fixture.swapchainImageViews,
        fixture.renderPass, fixture.swapchainData.swapChainExtent);
    swapchainbuffers.length.shouldBeGreaterThan(0);
    scope (exit)
    {
        cleanupSwapchainFramebuffers(swapchainbuffers, fixture.device);
    }

}

VkFramebuffer[] createSwapchainFramebuffers(ref VkDevice device,
    ref VkImageView[] imageViews, ref VkRenderPass renderPass, ref VkExtent2D swapchainExtent)
{
    VkFramebuffer[] swapchainFramebuffers;
    swapchainFramebuffers.reserve(imageViews.length);
    foreach (imageView; imageViews)
    {
        VkImageView[] attachments;
        attachments ~= imageView;
        VkFramebufferCreateInfo framebufferCreateInfo;
        framebufferCreateInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
        framebufferCreateInfo.renderPass = renderPass;
        framebufferCreateInfo.attachmentCount = 1;
        framebufferCreateInfo.pAttachments = attachments.ptr;
        framebufferCreateInfo.width = swapchainExtent.width;
        framebufferCreateInfo.height = swapchainExtent.height;
        framebufferCreateInfo.layers = 1;
        VkFramebuffer buffer;
        if (vkCreateFramebuffer(device, &framebufferCreateInfo, null,
                &buffer) != VkResult.VK_SUCCESS)
        {
            debug writeln("Failed to create SwapchainImageViews");
            break;
        }
        swapchainFramebuffers ~= buffer;
    }
    return swapchainFramebuffers;

}

void cleanupSwapchainFramebuffers(ref VkFramebuffer[] swapchainFramebuffers, ref VkDevice device)
{
    foreach (VkFramebuffer framebuffer; swapchainFramebuffers)
    {
        vkDestroyFramebuffer(device, framebuffer, null);
    }
}
