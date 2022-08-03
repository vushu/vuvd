module vuv.graphics.vulkan.graphicspipelines.common;
import erupted;
import std.stdio;
import unit_threaded : Tags;
import vuv.graphics.vulkan.swapchain : SwapchainData;

version (unittest)
{
    import unit_threaded;
    import vuv.graphics.vulkan.imageview : getImageViewFixture;
    import vuv.graphics.vulkan.graphicspipelines.fileutils;
}

struct GraphicsPipelineCreateInfos
{
    VkPipelineShaderStageCreateInfo[] shaderStages;
    VkPipelineVertexInputStateCreateInfo vertexInputCreateInfo;
    VkPipelineInputAssemblyStateCreateInfo vertexInputAssemblyCreateInfo;
    VkPipelineViewportStateCreateInfo viewportStateCreateInfo;
    VkPipelineRasterizationStateCreateInfo rasterizationCreateInfo;
    VkPipelineMultisampleStateCreateInfo multisampleCreateInfo;
    VkPipelineColorBlendStateCreateInfo colorBlendStateCreateInfo;
    VkPipelineDynamicStateCreateInfo dynamicStateCreateInfo;
}

@Tags("createShaderModule")
@("Testing createShaderModule")
unittest
{
    auto fixture = getImageViewFixture;

    auto code = readFile("shaders/triangle/vert.spv");
    assert(code.length > 0);

    VkShaderModule shaderModule = createShaderModule(fixture.device, code);
    shaderModule.shouldNotBeNull;
    scope (exit)
    {
        vkDestroyShaderModule(fixture.device, shaderModule, null);
    }

}

VkShaderModule createShaderModule(ref VkDevice device, const ref byte[] code)
{

    VkShaderModuleCreateInfo createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    createInfo.codeSize = code.length;
    createInfo.pCode = cast(const(uint32_t)*) code.ptr;
    VkShaderModule shaderModule;
    if (vkCreateShaderModule(device, &createInfo, null, &shaderModule) != VkResult.VK_SUCCESS)
    {
        debug writeln("Failed to create shader module");
        return null;
    }
    debug writeln("Succesfully created a shader module");
    return shaderModule;
}

VkPipelineShaderStageCreateInfo createVertexShaderPipeline(ref VkShaderModule vertexShaderModule)
{
    VkPipelineShaderStageCreateInfo vertShaderStageInfo;
    vertShaderStageInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    vertShaderStageInfo.stage = VK_SHADER_STAGE_VERTEX_BIT;
    vertShaderStageInfo.Module = vertexShaderModule;
    vertShaderStageInfo.pName = "main";
    return vertShaderStageInfo;
}

VkPipelineShaderStageCreateInfo createFragmentShaderPipeline(ref VkShaderModule framentShaderModule)
{
    VkPipelineShaderStageCreateInfo fragmentStageInfo;
    fragmentStageInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    fragmentStageInfo.stage = VK_SHADER_STAGE_FRAGMENT_BIT;
    fragmentStageInfo.Module = framentShaderModule;
    fragmentStageInfo.pName = "main";
    return fragmentStageInfo;

}

VkPipelineDynamicStateCreateInfo createDynamicStates(ref VkDynamicState[] dynamicStates)
{
    VkPipelineDynamicStateCreateInfo dynamicStateCreateInfo;
    dynamicStateCreateInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
    dynamicStateCreateInfo.dynamicStateCount = cast(uint) dynamicStates.length;
    dynamicStateCreateInfo.pDynamicStates = dynamicStates.ptr;
    return dynamicStateCreateInfo;
}

VkPipelineVertexInputStateCreateInfo createVertexInput()
{
    VkPipelineVertexInputStateCreateInfo vertexInputInfo;
    vertexInputInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    vertexInputInfo.vertexBindingDescriptionCount = 0;
    vertexInputInfo.pVertexBindingDescriptions = null; // Optional
    vertexInputInfo.vertexAttributeDescriptionCount = 0;
    vertexInputInfo.pVertexAttributeDescriptions = null; // Optional
    return vertexInputInfo;
}

VkPipelineInputAssemblyStateCreateInfo createInputAssemblyWithTriangle()
{
    VkPipelineInputAssemblyStateCreateInfo inputAssembly;
    inputAssembly.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    inputAssembly.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
    inputAssembly.primitiveRestartEnable = VK_FALSE;
    return inputAssembly;
}

VkViewport createViewport(float swapchainExtentWidth, float swapchainExtentHeight)
{
    VkViewport viewport;
    viewport.x = 0.0f;
    viewport.y = 0.0f;
    viewport.width = swapchainExtentWidth;
    viewport.height = swapchainExtentHeight;
    viewport.minDepth = 0.0f;
    viewport.maxDepth = 1.0f;
    return viewport;
}

VkPipelineViewportStateCreateInfo createViewportState()
{
    VkPipelineViewportStateCreateInfo viewportState;
    viewportState.sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    viewportState.viewportCount = 1;
    viewportState.scissorCount = 1;
    return viewportState;
}

VkPipelineRasterizationStateCreateInfo createRasterizerInfo()
{
    VkPipelineRasterizationStateCreateInfo rasterizeInfo;
    rasterizeInfo.sType = VkStructureType
        .VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    rasterizeInfo.depthClampEnable = VK_FALSE;
    rasterizeInfo.rasterizerDiscardEnable = VK_FALSE;
    rasterizeInfo.polygonMode = VK_POLYGON_MODE_FILL;
    rasterizeInfo.lineWidth = 1.0f;
    rasterizeInfo.cullMode = VK_CULL_MODE_BACK_BIT;
    rasterizeInfo.frontFace = VK_FRONT_FACE_CLOCKWISE;
    rasterizeInfo.depthBiasEnable = VK_FALSE;
    return rasterizeInfo;
}

VkPipelineMultisampleStateCreateInfo createMultisampling()
{
    VkPipelineMultisampleStateCreateInfo multisamplingCreateInfo;
    multisamplingCreateInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    multisamplingCreateInfo.sampleShadingEnable = VK_FALSE;
    multisamplingCreateInfo.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;
    return multisamplingCreateInfo;
}

VkPipelineColorBlendAttachmentState createColorBlendAttacment()
{
    VkPipelineColorBlendAttachmentState colorBlendAttacmentInfo;
    colorBlendAttacmentInfo.colorWriteMask = VK_COLOR_COMPONENT_R_BIT
        | VK_COLOR_COMPONENT_G_BIT | VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;
    colorBlendAttacmentInfo.blendEnable = VK_FALSE;
    return colorBlendAttacmentInfo;
}

VkPipelineColorBlendStateCreateInfo createColorBleding(
    ref VkPipelineColorBlendAttachmentState colorBlendAttachment)
{
    VkPipelineColorBlendStateCreateInfo colorBlending;

    colorBlending.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    colorBlending.logicOpEnable = VK_FALSE;
    colorBlending.logicOp = VK_LOGIC_OP_COPY;
    colorBlending.attachmentCount = 1;
    colorBlending.pAttachments = &colorBlendAttachment;
    colorBlending.blendConstants[0] = 0.0f;
    colorBlending.blendConstants[1] = 0.0f;
    colorBlending.blendConstants[2] = 0.0f;
    colorBlending.blendConstants[3] = 0.0f;
    return colorBlending;
}

@("Testing createPipelineLayout")
unittest
{
    auto fixture = getImageViewFixture;
    VkPipelineLayout pipelineLayout;
    scope (exit)
    {
        vkDestroyPipelineLayout(fixture.device, pipelineLayout, null);
    }
    assert(createPipelineLayout(fixture.device, pipelineLayout));
}

bool createPipelineLayout(ref VkDevice device, ref VkPipelineLayout pipelineLayout)
{
    VkPipelineLayoutCreateInfo pipelineLayoutInfo;
    pipelineLayoutInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    pipelineLayoutInfo.setLayoutCount = 0;
    pipelineLayoutInfo.pushConstantRangeCount = 0;

    return vkCreatePipelineLayout(device, &pipelineLayoutInfo, null, &pipelineLayout) == VkResult
        .VK_SUCCESS;
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

bool createRenderPass(ref VkDevice device, ref VkRenderPassCreateInfo renderPassCreateInfo, ref VkRenderPass renderPass)
{
    return vkCreateRenderPass(device, &renderPassCreateInfo, null, &renderPass) == VkResult
        .VK_SUCCESS;
}

bool createGraphicsPipeline(
    ref GraphicsPipelineCreateInfos createInfos
)
{
    VkGraphicsPipelineCreateInfo pipelineCreateInfo;
    pipelineCreateInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
    pipelineCreateInfo.stageCount = cast(uint) createInfos.shaderStages.length;
    return true;
}
