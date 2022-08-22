module vuv.graphics.vulkan.memory;
import erupted;
import std.stdio : writeln;
import unit_threaded : Tags;

version (unittest)
{
    import unit_threaded : writelnUt;
    import vuv.graphics.vulkan.commandbuffer;
    import std.typecons : RefCounted;
    import vuv.graphics.vertexstore;

    struct TestMemoryFixture
    {
        VkDevice device;
        VkPhysicalDevice physicalDevice;
        VkBuffer vertexBuffer;
        VertexStore vertexStore;
        RefCounted!TestCommandBufferFixture commandBufferFixture;
        ~this()
        {
            vkDestroyBuffer(device, vertexBuffer, null);
        }
    }

    TestMemoryFixture getMemoryFixture()
    {
        auto fixture = getRefCountedCommandBufferFixture;
        auto vertexStore = getTriangleVertexStore;

        VkBuffer vertexBuffer;
        assert(createVertexBuffer(vertexStore, fixture.device, vertexBuffer));
        return TestMemoryFixture(fixture.device, fixture.physicalDevice, vertexBuffer, vertexStore, fixture);
    }

}
@Tags("getMemoryRequirements")
@("Testing getMemoryRequirements")
unittest
{
    auto fixture = getMemoryFixture;
    VkMemoryRequirements memoryRequirements;
    getMemoryRequirements(fixture.device, fixture.vertexBuffer, memoryRequirements);
}

void getMemoryRequirements(ref VkDevice device, ref VkBuffer vertexBuffer, out VkMemoryRequirements memoryRequirements)
{
    vkGetBufferMemoryRequirements(device, vertexBuffer, &memoryRequirements);
}

@Tags("findMemoryType")
@("Testing findMemoryType")
unittest
{
    auto fixture = getMemoryFixture;
    VkMemoryRequirements memoryRequirements;
    getMemoryRequirements(fixture.device, fixture.vertexBuffer, memoryRequirements);
    uint result = findMemoryType(fixture.physicalDevice, memoryRequirements.memoryTypeBits,
        VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VkMemoryPropertyFlagBits
            .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    writelnUt("result is: ", result);
    assert(result > 0);

}

uint findMemoryType(ref VkPhysicalDevice physicalDevice, uint typeFilter, VkMemoryPropertyFlags properties)
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
    getMemoryRequirements(fixture.device, fixture.vertexBuffer, memoryRequirements);
    uint result = findMemoryType(fixture.physicalDevice, memoryRequirements.memoryTypeBits,
        VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VkMemoryPropertyFlagBits
            .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    writelnUt("result is: ", result);
    assert(result > 0);
    VkDeviceMemory vertexBufferMemory;
    assert(allocateMemory(fixture.device, fixture.physicalDevice, memoryRequirements, vertexBufferMemory));
}

bool allocateMemory(ref VkDevice device, ref VkPhysicalDevice physicalDevice, ref VkMemoryRequirements memoryRequirements, out VkDeviceMemory vertexBufferMemory)
{
    VkMemoryAllocateInfo allocInfo;
    allocInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO;
    allocInfo.allocationSize = memoryRequirements.size;
    allocInfo.memoryTypeIndex = findMemoryType(physicalDevice, memoryRequirements.memoryTypeBits,
        VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VkMemoryPropertyFlagBits
            .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    return vkAllocateMemory(device, &allocInfo, null, &vertexBufferMemory) == VK_SUCCESS;
}

@Tags("bindMemory")
@("Testing bindMemory")
unittest
{
    auto fixture = getMemoryFixture;
    VkMemoryRequirements memoryRequirements;
    getMemoryRequirements(fixture.device, fixture.vertexBuffer, memoryRequirements);
    uint result = findMemoryType(fixture.physicalDevice, memoryRequirements.memoryTypeBits,
        VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VkMemoryPropertyFlagBits
            .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    writelnUt("result is: ", result);
    assert(result > 0);
    VkDeviceMemory vertexBufferMemory;
    assert(allocateMemory(fixture.device, fixture.physicalDevice, memoryRequirements, vertexBufferMemory));
    // binding test
    bindMemory(fixture.device, fixture.vertexBuffer, vertexBufferMemory);
    scope (exit)
    {
        vkFreeMemory(fixture.device, vertexBufferMemory, null);
    }

}

void bindMemory(ref VkDevice device, ref VkBuffer vertexBuffer, ref VkDeviceMemory vertexBufferMemory)
{

    vkBindBufferMemory(device, vertexBuffer, vertexBufferMemory, 0);
}
