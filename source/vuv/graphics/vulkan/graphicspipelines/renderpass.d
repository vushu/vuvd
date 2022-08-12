module vuv.graphics.vulkan.graphicspipelines.renderpass;
import erupted;
import unit_threaded;

version (unittest)
{
    import unit_threaded;
    import vuv.graphics.vulkan.imageview : getImageViewFixture;
    import vuv.graphics.vulkan.graphicspipelines.fileutils;

    struct TestRenderPassFixture
    {
        VkDevice device;
        ~this()
        {
            //vkDestroyRenderPass(device, renderPass, null);
        }
    }
}

VkRenderPassCreateInfo createRenderPassInfo(
        ref VkAttachmentDescription colorAttachment, ref VkSubpassDescription subpass)
{
    VkRenderPassCreateInfo renderPassInfo;
    renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
    renderPassInfo.attachmentCount = 1;
    renderPassInfo.pAttachments = &colorAttachment;
    renderPassInfo.subpassCount = 1;
    renderPassInfo.pSubpasses = &subpass;
    return renderPassInfo;
}

VkAttachmentDescription createAttachmentDescription(ref VkFormat swapChainImageFormat)
{
    VkAttachmentDescription colorAttachment;
    colorAttachment.format = swapChainImageFormat;
    colorAttachment.samples = VkSampleCountFlagBits.VK_SAMPLE_COUNT_1_BIT;
    colorAttachment.loadOp = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_CLEAR;
    colorAttachment.storeOp = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_STORE;
    colorAttachment.stencilLoadOp = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    colorAttachment.stencilStoreOp = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_DONT_CARE;
    colorAttachment.initialLayout = VkImageLayout.VK_IMAGE_LAYOUT_UNDEFINED;
    colorAttachment.finalLayout = VkImageLayout.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
    return colorAttachment;
}

VkAttachmentReference createColorAttachmentReference()
{
    VkAttachmentReference colorAttachmentReference;
    colorAttachmentReference.attachment = 0;
    colorAttachmentReference.layout = VkImageLayout.VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL;
    return colorAttachmentReference;
}

VkSubpassDescription createSubpassDescription(ref VkAttachmentReference colorAttacmentReference)
{
    VkSubpassDescription subpass;
    subpass.pipelineBindPoint = VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.colorAttachmentCount = 1;
    subpass.pColorAttachments = &colorAttacmentReference;
    return subpass;
}

@Tags("createRenderPass")
@("Testing createRenderPass")
unittest
{

    auto fixture = getImageViewFixture;
    assert(fixture.swapchainData.swapChainImageFormat != VK_FORMAT_UNDEFINED);
    writelnUt("imageFormat", fixture.swapchainData.swapChainImageFormat);

    auto colorAttachmentDescription = createAttachmentDescription(
            fixture.swapchainData.swapChainImageFormat);
    auto colorAttachmentRefence = createColorAttachmentReference();
    auto subPass = createSubpassDescription(colorAttachmentRefence);
    auto createInfo = createRenderPassInfo(colorAttachmentDescription, subPass);
    VkRenderPass renderPass;
    assert(createRenderPass(fixture.device, createInfo, renderPass));
    scope (exit)
    {
        vkDestroyRenderPass(fixture.device, renderPass, null);
    }

}

bool createRenderPass(ref VkDevice device,
        ref VkRenderPassCreateInfo renderPassCreateInfo, ref VkRenderPass renderPass)
{
    return vkCreateRenderPass(device, &renderPassCreateInfo, null, &renderPass) == VkResult
        .VK_SUCCESS;
}
