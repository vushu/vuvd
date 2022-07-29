module vuv.graphics.vulkan.logicaldevice;
import vuv.graphics.vulkan.physicaldevice;
import std.typecons : RefCounted;
import erupted;

debug import unit_threaded : writelnUt;

version (unittest)
{
    import unit_threaded;
    import vuv.graphics.vulkan.physicaldevice;
    import vuv.graphics.vulkan.surface;
    import vuv.graphics.vulkan.staticvalues;
    import bindbc.sdl;

    struct TestVkDeviceFixture
    {
        @disable this(this);

        VkPhysicalDevice physicalDevice;
        SDL_Window* window;
        QueueFamilyIndices queueFamilyIndices;

        RefCounted!TestVkInstanceFixture instanceFixture;
    }

    RefCounted!TestVkDeviceFixture getVkDeviceFixture()
    {
        synchronized
        {
            if (_fixture.refCountedStore.isInitialized)
            {
                // writelnUt("TestVkDeviceFixture initialized");
                return _fixture;
            }
            // writelnUt("TestVkDeviceFixture initialized");

            auto fixture = getVkInstanceFixture();
            auto window = fixture.sdlWindowFixture.window;
            VkPhysicalDevice physicalDevice;

            loadDeviceLevelFunctions(fixture.instance);

            QueueFamilyIndices queueIndices;

            getPhysicalDevice(fixture.instance, physicalDevice, fixture.surface, queueIndices)
                .shouldBeTrue;

            _fixture = RefCounted!TestVkDeviceFixture(physicalDevice, window, queueIndices, fixture);

            return _fixture;
        }
    }

    static RefCounted!TestVkDeviceFixture _fixture;
}

@("Test instantiateDevice")
unittest
{
    auto fixture = getVkDeviceFixture();
    VkDevice device;

    VkSurfaceKHR surface;
    assert(createSurface(fixture.window, fixture.instanceFixture.instance, surface));
    instantiateDevice(fixture.physicalDevice, device, getRequiredValidationLayers, getRequiredDeviceExtensions, fixture.queueFamilyIndices)
        .shouldBeTrue;
}

bool instantiateDevice(ref VkPhysicalDevice physicalDevice, ref VkDevice device,
    ref const(char)*[] validationLayers, ref const(char)*[] deviceExtentions, ref QueueFamilyIndices foundQueueFamily)
{

    float queuePriority = 1.0f;

    auto createQueueInfos = createQueueInfos(foundQueueFamily.graphicsFamily.get,
        foundQueueFamily.presentFamily.get, queuePriority);

    if (!initializeDevice(physicalDevice, createQueueInfos, device, validationLayers, deviceExtentions))
    {
        debug writelnUt("Failed to initDevice");
        return false;
    }

    loadDeviceLevelFunctions(device);

    return true;

}

@("Test initialize logical device")
unittest
{
    auto fixture = getVkDeviceFixture();

    auto foundQueueFamily = findQueueFamilies(fixture.physicalDevice, fixture
            .instanceFixture.surface);

    float priority = 1.0f;
    auto queueCreateInfos = createQueueInfos(foundQueueFamily.graphicsFamily.get, foundQueueFamily.presentFamily.get,
        priority);

    VkDevice device;

    initializeDevice(fixture.physicalDevice, queueCreateInfos, device, getRequiredValidationLayers, getRequiredDeviceExtensions)
        .shouldBeTrue;

    VkQueue graphicsQueue;
    vkGetDeviceQueue(device, foundQueueFamily.graphicsFamily.get, 0, &graphicsQueue);
}

bool initializeDevice(ref VkPhysicalDevice physicalDevice, ref VkDeviceQueueCreateInfo[] queueCreateInfos,
    ref VkDevice device, ref const(char)*[] validationLayers, ref const(char)*[] deviceExtentions)
{
    VkPhysicalDeviceFeatures deviceFeatures;

    VkDeviceCreateInfo createInfo;

    createInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;

    createInfo.queueCreateInfoCount = cast(uint) queueCreateInfos.length;
    createInfo.pQueueCreateInfos = queueCreateInfos.ptr;

    createInfo.pEnabledFeatures = &deviceFeatures;

    createInfo.enabledExtensionCount = 0;

    createInfo.enabledLayerCount = 0;

    createInfo.enabledExtensionCount = cast(uint) deviceExtentions.length;
    createInfo.ppEnabledExtensionNames = deviceExtentions.ptr;

    debug
    {
        createInfo.enabledLayerCount = cast(uint) validationLayers.length;
        createInfo.ppEnabledLayerNames = validationLayers.ptr;
    }

    return vkCreateDevice(physicalDevice, &createInfo, null, &device) == VK_SUCCESS;
}

VkDeviceQueueCreateInfo[] createQueueInfos(uint queueFamily,
    uint presentFamily, ref float queuePriority)
{
    VkDeviceQueueCreateInfo[] queueCreateInfos;
    bool[uint] uniqueQueueFamilies;
    uniqueQueueFamilies[queueFamily] = false;
    uniqueQueueFamilies[presentFamily] = false;

    foreach (key, value; uniqueQueueFamilies)
    {
        VkDeviceQueueCreateInfo queueCreateInfo;
        queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
        queueCreateInfo.queueFamilyIndex = queueFamily;
        queueCreateInfo.queueCount = 1;
        queueCreateInfo.pQueuePriorities = &queuePriority;
        queueCreateInfos ~= queueCreateInfo;
    }
    return queueCreateInfos;

}

VkQueue getQueue(ref VkDevice device, uint indexOfQueueFamily)
{
    VkQueue queue;
    vkGetDeviceQueue(device, indexOfQueueFamily, 0, &queue);
    return queue;
}
