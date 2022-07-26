module vuv.graphics.vulkan.logicaldevice;
import vuv.graphics.vulkan.physicaldevice;
import std.typecons : RefCounted;
import erupted;

debug import unit_threaded : writelnUt;

version (unittest)
{
    import unit_threaded;
    import vuv.graphics.vulkan.physicaldevice;
    import vuv.graphics.vulkan.windowsurface;
    import bindbc.sdl;

    struct TestVkDeviceFixture
    {
        @disable this(this);

        VkPhysicalDevice physicalDevice;
        SDL_Window* window;

        RefCounted!TestVkInstanceFixture instanceFixture;
    }

    RefCounted!TestVkDeviceFixture getVkDeviceFixture()
    {
        synchronized
        {
            if (_fixture.refCountedStore.isInitialized)
            {
                writelnUt("TestVkDeviceFixture initialized");
                return _fixture;
            }
            writelnUt("TestVkDeviceFixture initialized");

            auto fixture = getVkInstanceFixture();
            auto window = fixture.sdlWindowFixture.window;
            VkPhysicalDevice physicalDevice;

            loadDeviceLevelFunctions(fixture.instance);

            getPhysicalDevice(fixture.instance, physicalDevice, fixture.surface).shouldBeTrue;

            _fixture = RefCounted!TestVkDeviceFixture(physicalDevice, window, fixture);

            return _fixture;
        }
    }

    static RefCounted!TestVkDeviceFixture _fixture;
}

VkDeviceQueueCreateInfo createLogicalDevice(uint graphicsFamily)
{
    VkDeviceQueueCreateInfo queueCreateInfo;
    queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queueCreateInfo.queueFamilyIndex = graphicsFamily;
    queueCreateInfo.queueCount = 1;
    return queueCreateInfo;
}

@("Test instantiateDevice")
unittest
{
    auto fixture = getVkDeviceFixture();
    static const(char)*[] validationLayers = ["VK_LAYER_KHRONOS_validation"];
    VkDevice device;

    VkSurfaceKHR surface;
    assert(createSurface(fixture.window, fixture.instanceFixture.instance, surface));
    instantiateDevice(fixture.physicalDevice, device, validationLayers, surface).shouldBeTrue;
}

bool instantiateDevice(ref VkPhysicalDevice physicalDevice, ref VkDevice device,
    ref const(char)*[] validationLayers, ref VkSurfaceKHR surface)
{
    auto foundQueueFamily = findQueueFamilies(physicalDevice, surface);
    auto queueCreateInfo = createLogicalDevice(foundQueueFamily.graphicsFamily.get);

    if (initializeDevice(physicalDevice, queueCreateInfo, 1.0, device, validationLayers))
    {
        VkQueue graphicsQueue;
        getDeviceQueue(device, foundQueueFamily.graphicsFamily.get, graphicsQueue);
    }
    return true;

}

@("Test initialize logical device")
unittest
{
    auto fixture = getVkDeviceFixture();
    VkSurfaceKHR surface;

    auto foundQueueFamily = findQueueFamilies(fixture.physicalDevice, fixture.instanceFixture.surface);

    auto queueCreateInfo = createLogicalDevice(foundQueueFamily.graphicsFamily.get);

    queueCreateInfo.queueFamilyIndex.should.be == foundQueueFamily.graphicsFamily.get;

    VkDevice device;
    static const(char)*[] validationLayers = ["VK_LAYER_KHRONOS_validation"];

    initializeDevice(fixture.physicalDevice, queueCreateInfo, 1.0, device, validationLayers)
        .shouldBeTrue;

    VkQueue graphicsQueue;
    getDeviceQueue(device, foundQueueFamily.graphicsFamily.get, graphicsQueue);
}

bool initializeDevice(ref VkPhysicalDevice physicalDevice, ref VkDeviceQueueCreateInfo queueCreateInfo,
    float queuePriority, ref VkDevice device, ref const(char)*[] validationLayers)
{
    queueCreateInfo.queueCount = 1;
    queueCreateInfo.pQueuePriorities = &queuePriority;

    VkPhysicalDeviceFeatures deviceFeatures;

    VkDeviceCreateInfo createInfo;

    createInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;

    createInfo.pQueueCreateInfos = &queueCreateInfo;
    createInfo.queueCreateInfoCount = 1;

    createInfo.pEnabledFeatures = &deviceFeatures;

    createInfo.enabledExtensionCount = 0;

    createInfo.enabledLayerCount = 0;

    debug
    {
        createInfo.enabledLayerCount = cast(uint) validationLayers.length;
        createInfo.ppEnabledLayerNames = validationLayers.ptr;
    }

    return vkCreateDevice(physicalDevice, &createInfo, null, &device) == VK_SUCCESS;

}

void getDeviceQueue(ref VkDevice device, uint graphicsFamily, ref VkQueue graphicsQueue)
{
    vkGetDeviceQueue(device, graphicsFamily, 0, &graphicsQueue);
}
