module vuv.graphics.vulkan.graphicspipelines.pipelinelayout;
import erupted;

version (unittest)
{
    import unit_threaded;
    import vuv.graphics.vulkan.imageview : getImageViewFixture;
    import vuv.graphics.vulkan.graphicspipelines.fileutils;
    import vuv.graphics.vulkan.graphicspipelines.renderpass;
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
