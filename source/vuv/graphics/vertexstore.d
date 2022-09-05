module vuv.graphics.vertexstore;
import erupted;
import unit_threaded : Tags;

import dplug.math;

version (unittest)
{
    import vuv.graphics.vulkan.commandbuffer;
    import unit_threaded;
}

struct Vector2
{
    float x, y;
}

struct Vector3
{
    float x, y, z;
}

struct Vertex
{
    float[2] position;
    float[3] color;
    // Vector2 position;
    // Vector2 position;
    // Vector3 color;
}

struct VertexStore
{
    Vertex[] vertices;
}

void add(ref VertexStore vertexStore, Vertex vertex)
{
    vertexStore.vertices ~= vertex;
}

void addVertex(ref VertexStore vertexStore, Vector2 position, Vector3 color)
{
    vertexStore.vertices ~= Vertex([position.x, position.y], [
            color.x, color.y, color.z
        ]);
}

@Tags("getSize")
@("Testing getSize")
unittest
{
    auto store = getTriangleVertexStore();
    // writelnUt("Size OF Vertex: ", Vertex.sizeof);

    // writelnUt("Size OF VERTEXSTORE: ", store.sizeof - 12);
    // writelnUt("Size OF VEC2: ", vec2f.sizeof);
    // writelnUt("Size OF VEC3: ", vec3f.sizeof);
    assert(store.getSize == (vec2f.sizeof + vec3f.sizeof) * 3);
    // writelnUt("Size of VertexStore ", cast(size_t)(vec2f.sizeof + vec3f.sizeof) * 3);

}

ulong getSize(ref VertexStore vertexStore)
{
    return Vertex.sizeof * vertexStore.vertices.length;
}

VertexStore getTriangleVertexStore()
{
    VertexStore vertexStore;
    vertexStore.add(Vertex([0.0f, -0.5f], [1.0f, 0.0f, 0.0f]));
    vertexStore.add(Vertex([0.5f, 0.5f], [0.0f, 1.0f, 0.0f]));
    vertexStore.add(Vertex([-0.5f, 0.5f], [0.0f, 0.0f, 1.0f]));
    // vertexStore.addVertex(Vector2(0.0f, -0.5f), Vector3(1.0f, 0.0f, 0.0f));
    // vertexStore.addVertex(Vector2(0.5f, 0.5f), Vector3(0.0f, 1.0f, 0.0f));
    // vertexStore.addVertex(Vector2(-0.5f, 0.5f), Vector3(0.0f, 0.0f, 1.0f));
    return vertexStore;
}

@Tags("createVertexBuffer")
@("Testing createVertexBuffer")
unittest
{
    auto fixture = getRefCountedCommandBufferFixture;
    auto store = getTriangleVertexStore();
    VkBuffer buffer;
    createVertexBuffer(fixture.device, store.getSize, VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, buffer)
        .shouldBeTrue;
    vkDestroyBuffer(fixture.device, buffer, null);
}

bool createVertexBuffer(ref VkDevice device, VkDeviceSize size,
    VkBufferUsageFlags usage, out VkBuffer vertexBuffer)
{
    VkBufferCreateInfo bufferInfo;
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = size;
    bufferInfo.usage = usage;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    return vkCreateBuffer(device, &bufferInfo, null, &vertexBuffer) == VK_SUCCESS;
}
