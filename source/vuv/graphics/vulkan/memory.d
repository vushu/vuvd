module vuv.graphics.vulkan.memory;
import erupted;
import std.stdio : writeln;
import unit_threaded : Tags;
import vuv.graphics.vertexstore;
import core.stdc.string : memcpy;

version (unittest)
{
    import vuv.graphics.vulkan;
    import unit_threaded : writelnUt;
    import vuv.graphics.vulkan.commandbuffer;
    import std.typecons : RefCounted;
    import vuv.graphics.vertexstore;

    struct TestMemoryFixture
    {
        VkDevice device;
        VkPhysicalDevice physicalDevice;
        VkBuffer[] vertexBuffers;
        VertexStore vertexStore;
        RefCounted!TestCommandBufferFixture commandBufferFixture;
        ~this()
        {
            foreach (buffer; vertexBuffers)
            {
                vkDestroyBuffer(device, buffer, null);
            }
        }
    }

    TestMemoryFixture getMemoryFixture()
    {
        auto fixture = getRefCountedCommandBufferFixture;
        auto vertexStore = getTriangleVertexStore;

        VkBuffer vertexBuffer;
        assert(createVertexBuffer(fixture.device, vertexStore.getSize,
                VkBufferUsageFlagBits.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, vertexBuffer));
        VkBuffer[] vertexBuffers;
        vertexBuffers ~= vertexBuffer;
        return TestMemoryFixture(fixture.device, fixture.physicalDevice,
                vertexBuffers, vertexStore, fixture);
    }

}
@Tags("getMemoryRequirements")
@("Testing getMemoryRequirements")
unittest
{
    auto fixture = getMemoryFixture;
    VkMemoryRequirements memoryRequirements;
    getMemoryRequirements(fixture.device, fixture.vertexBuffers[0], memoryRequirements);
}

void getMemoryRequirements(ref VkDevice device, ref VkBuffer vertexBuffer,
        out VkMemoryRequirements memoryRequirements)
{
    vkGetBufferMemoryRequirements(device, vertexBuffer, &memoryRequirements);
}

@Tags("findMemoryType")
@("Testing findMemoryType")
unittest
{
    auto fixture = getMemoryFixture;
    VkMemoryRequirements memoryRequirements;
    getMemoryRequirements(fixture.device, fixture.vertexBuffers[0], memoryRequirements);
    uint result = findMemoryType(fixture.physicalDevice, memoryRequirements.memoryTypeBits,
            VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT
            | VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    writelnUt("result is: ", result);
    assert(result > 0);

}

uint findMemoryType(ref VkPhysicalDevice physicalDevice, uint typeFilter,
        VkMemoryPropertyFlags properties)
{
    VkPhysicalDeviceMemoryProperties memoryProperties;
    vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memoryProperties);
    for (uint32_t i = 0; i < memoryProperties.memoryTypeCount; i++)
    {
        if (typeFilter & (1 << i) && (memoryProperties.memoryTypes[i].propertyFlags & properties))
        {
            return i;
        }
    }

    debug writeln("Failed to find memory type!");
    return -1;
}

@Tags("allocateMemory")
@("Testing allocateMemory")
unittest
{
    auto fixture = getMemoryFixture;
    VkMemoryRequirements memoryRequirements;
    getMemoryRequirements(fixture.device, fixture.vertexBuffers[0], memoryRequirements);
    uint result = findMemoryType(fixture.physicalDevice, memoryRequirements.memoryTypeBits,
            VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT
            | VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    writelnUt("result is: ", result);
    assert(result > 0);
    VkDeviceMemory vertexBufferMemory;
    assert(allocateMemory(fixture.device, fixture.physicalDevice,
            memoryRequirements, vertexBufferMemory));
    bindMemory(fixture.device, fixture.vertexBuffers[0], vertexBufferMemory);
    scope (exit)
    {
        vkFreeMemory(fixture.device, vertexBufferMemory, null);
    }
    mapVertexDataToVertexBuffer(fixture.device, fixture.vertexStore, vertexBufferMemory);

}

bool allocateMemory(ref VkDevice device, ref VkPhysicalDevice physicalDevice,
        ref VkMemoryRequirements memoryRequirements, out VkDeviceMemory vertexBufferMemory)
{
    VkMemoryAllocateInfo allocInfo;
    allocInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    allocInfo.allocationSize = memoryRequirements.size;
    allocInfo.memoryTypeIndex = findMemoryType(physicalDevice, memoryRequirements.memoryTypeBits,
            VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT
            | VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    return vkAllocateMemory(device, &allocInfo, null, &vertexBufferMemory) == VK_SUCCESS;
}

@Tags("bindMemory")
@("Testing bindMemory")
unittest
{
    auto fixture = getMemoryFixture;

    VkMemoryRequirements memoryRequirements;
    getMemoryRequirements(fixture.device, fixture.vertexBuffers[0], memoryRequirements);
    uint result = findMemoryType(fixture.physicalDevice, memoryRequirements.memoryTypeBits,
            VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT
            | VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    writelnUt("result is: ", result);
    assert(result > 0);
    VkDeviceMemory vertexBufferMemory;
    assert(allocateMemory(fixture.device, fixture.physicalDevice,
            memoryRequirements, vertexBufferMemory));
    // binding test
    bindMemory(fixture.device, fixture.vertexBuffers[0], vertexBufferMemory);
    scope (exit)
    {
        vkFreeMemory(fixture.device, vertexBufferMemory, null);
    }

}

@Tags("mapVertexDataToVertexBuffer")
@("Testing mapVertexDataToVertexBuffer")
unittest
{
    auto fixture = getMemoryFixture;

    VkMemoryRequirements memoryRequirements;
    // getMemoryRequirements(fixture.device, fixture.vertexBuffer, memoryRequirements);
    // uint result = findMemoryType(fixture.physicalDevice, memoryRequirements.memoryTypeBits,
    //     VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VkMemoryPropertyFlagBits
    //         .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    // writelnUt("result is: ", result);
    // assert(result > 0);
    // VkDeviceMemory vertexBufferMemory;
    // assert(allocateMemory(fixture.device, fixture.physicalDevice, memoryRequirements, vertexBufferMemory));
    // binding test

    // VkBuffer vertexBuffer;
    // assert(createVertexBuffer(fixture.vertexStore, fixture.device, vertexBuffer));
    // bindMemory(fixture.device, vertexBuffer, vertexBufferMemory);
    // scope (exit)
    // {
    //     vkFreeMemory(fixture.device, vertexBufferMemory, null);
    // }
    // mapVertexDataToVertexBuffer(fixture.device, fixture.vertexStore, vertexBuffer, vertexBufferMemory);
    // scope (exit)
    // {
    //     vkDestroyBuffer(fixture.device, vertexBufferMemory, null);
    // }
}
/** 
 * Connecting cpu buffer to gpu memory 
 * Params:
 *   device = gpu device
 *   vertexBuffer = cpu buffer
 *   vertexBufferMemory = gpu memory
 */
void bindMemory(ref VkDevice device, ref VkBuffer vertexBuffer, ref VkDeviceMemory vertexBufferMemory)
{
    vkBindBufferMemory(device, vertexBuffer, vertexBufferMemory, 0);
}

void mapVertexDataToVertexBuffer(ref VkDevice device, ref VertexStore vertexStore,
        ref VkDeviceMemory vertexBufferMemory)
{
    void* data;
    vkMapMemory(device, vertexBufferMemory, 0, vertexStore.getSize, 0, &data);
    memcpy(data, cast(void*) vertexStore.vertices, cast(size_t) vertexStore.getSize);
    vkUnmapMemory(device, vertexBufferMemory);
}

package:

void createVertexBufferHighPerformance(ref VkPhysicalDevice physicalDevice,
        ref VkDevice device, ref VertexStore vertexStore, ref VkBuffer vertexBuffer,
        ref VkDeviceMemory vertexBufferMemory, ref VkCommandPool commandPool,
        ref VkQueue graphicsQueue)
{
    VkBuffer stagingBuffer;
    VkDeviceMemory stagingBufferMemory;

    auto memProperties = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;

    createBuffer(physicalDevice, device, vertexStore.getSize, stagingBuffer,
            VkBufferUsageFlagBits.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
            memProperties, stagingBufferMemory);

    mapVertexDataToVertexBuffer(device, vertexStore, stagingBufferMemory);

    auto stagingBufferUsage = VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;

    createBuffer(physicalDevice, device, vertexStore.getSize, vertexBuffer,
            stagingBufferUsage, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, vertexBufferMemory);

    copyBuffer(device, commandPool, stagingBuffer, vertexBuffer,
            vertexStore.getSize, graphicsQueue);

    vkDestroyBuffer(device, stagingBuffer, null);
    vkFreeMemory(device, stagingBufferMemory, null);

}

void createBuffer(ref VkPhysicalDevice physicalDevice, ref VkDevice device, VkDeviceSize size, ref VkBuffer vertexBuffer,
        VkBufferUsageFlags usage, VkMemoryPropertyFlags memoryProperties,
        ref VkDeviceMemory vertexBufferMemory)
{

    assert(createVertexBuffer(device, size, usage, vertexBuffer));
    VkMemoryRequirements memoryRequirements;
    getMemoryRequirements(device, vertexBuffer, memoryRequirements);
    uint result = findMemoryType(physicalDevice,
            memoryRequirements.memoryTypeBits, memoryProperties);
    assert(result > 0);
    assert(allocateMemory(device, physicalDevice, memoryRequirements, vertexBufferMemory));
    bindMemory(device, vertexBuffer, vertexBufferMemory);
}

void copyBuffer(ref VkDevice device, ref VkCommandPool commandPool, ref VkBuffer srcBuffer,
        ref VkBuffer dstBuffer, VkDeviceSize size, ref VkQueue graphicsQueue)
{
    VkCommandBufferAllocateInfo allocInfo;
    allocInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocInfo.commandPool = commandPool;
    allocInfo.commandBufferCount = 1;

    VkCommandBuffer commandBuffer;
    vkAllocateCommandBuffers(device, &allocInfo, &commandBuffer);
    VkCommandBufferBeginInfo beginInfo;
    beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    beginInfo.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;

    vkBeginCommandBuffer(commandBuffer, &beginInfo);

    VkBufferCopy copyRegion;
    copyRegion.size = size;
    vkCmdCopyBuffer(commandBuffer, srcBuffer, dstBuffer, 1, &copyRegion);

    vkEndCommandBuffer(commandBuffer);

    VkSubmitInfo submitInfo;
    submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    submitInfo.commandBufferCount = 1;
    submitInfo.pCommandBuffers = &commandBuffer;

    vkQueueSubmit(graphicsQueue, 1, &submitInfo, VK_NULL_HANDLE);
    vkQueueWaitIdle(graphicsQueue);
    vkFreeCommandBuffers(device, commandPool, 1, &commandBuffer);

}

void cleanupMemory(ref VkDevice device, ref VkDeviceMemory[] deviceMemories)
{

    foreach (memory; deviceMemories)
    {
        vkFreeMemory(device, memory, null);
    }
}
