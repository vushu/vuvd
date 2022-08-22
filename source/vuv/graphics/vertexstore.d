module vuv.graphics.vertexstore;
import erupted;
import unit_threaded : Tags;

import dplug.math;

version (unittest)
{
    import vuv.graphics.vulkan.commandbuffer;
    import unit_threaded;
}

struct VertexStore
{
    vec2f[] positions;
    vec3f[] colors;
    // vec2f[] textureCoordinates;
    // vec4f[] colors;
}

void addVertex(ref VertexStore vertexStore, vec2f position, vec3f color)
{
    vertexStore.positions ~= position;
    vertexStore.colors ~= color;
}

@Tags("getSize")
@("Testing getSize")
unittest
{
    auto store = getTriangleVertexStore();
    assert(store.getSize == (vec2f.sizeof + vec3f.sizeof) * 3);

}

ulong getSize(ref VertexStore vertexStore)
{
    return (vec2f.sizeof + vec3f.sizeof) * vertexStore.positions.length;
}

struct Vertex
{
    vec2f position;
    vec3f color;
}

VkVertexInputBindingDescription getBindingDescription()
{
    VkVertexInputBindingDescription bindingDescription;
    bindingDescription.binding = 0;
    bindingDescription.stride = vec3f.sizeof + vec2f.sizeof;
    bindingDescription.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

    return bindingDescription;
}

VkVertexInputAttributeDescription[2] getAttributeDescriptions()
{
    VkVertexInputAttributeDescription[2] attributesDescriptions;
    attributesDescriptions[0].binding = 0;
    attributesDescriptions[0].location = 0;
    attributesDescriptions[0].format = VkFormat.VK_FORMAT_R32G32_SFLOAT;
    attributesDescriptions[0].offset = 0;

    attributesDescriptions[1].binding = 0;
    attributesDescriptions[1].location = 1;
    attributesDescriptions[1].format = VkFormat.VK_FORMAT_R32G32B32_SFLOAT;
    attributesDescriptions[1].offset = vec2f.sizeof;
    return attributesDescriptions;
}

VertexStore getTriangleVertexStore()
{
    VertexStore vertexStore;
    vertexStore.addVertex(vec2f(0, -0.5), vec3f(1, 0, 0));
    vertexStore.addVertex(vec2f(0.5, 0.5), vec3f(0, 1, 0));
    vertexStore.addVertex(vec2f(-0.5, 0.5), vec3f(0, 0, 1));
    return vertexStore;
}

@Tags("createVertexBuffer")
@("Testing createVertexBuffer")
unittest
{
    auto fixture = getCommandBufferFixture;
    auto store = getTriangleVertexStore();
    VkBuffer buffer;
    store.createVertexBuffer(fixture.device, buffer).shouldBeTrue;
}

bool createVertexBuffer(ref VertexStore vertexStore, ref VkDevice device, out VkBuffer vertexBuffer)
{

    VkBufferCreateInfo bufferInfo;
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = vertexStore.getSize;
    bufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    return vkCreateBuffer(device, &bufferInfo, null, &vertexBuffer) == VK_SUCCESS;

}
