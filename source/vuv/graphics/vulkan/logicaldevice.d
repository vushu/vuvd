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
    import vuv.graphics.vulkan.staticvalues;
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
                // writelnUt("TestVkDeviceFixture initialized");
                return _fixture;
            }
            // writelnUt("TestVkDeviceFixture initialized");

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

@("Test instantiateDevice")
unittest
{
    auto fixture = getVkDeviceFixture();
    VkDevice device;

    VkSurfaceKHR surface;
    VkQueue graphicsQueue, presentQueue;
    assert(createSurface(fixture.window, fixture.instanceFixture.instance, surface));
    instantiateDevice(fixture.physicalDevice, device, getRequiredValidationLayers, getRequiredDeviceExtensions, surface, graphicsQueue, presentQueue)
        .shouldBeTrue;
}

bool instantiateDevice(ref VkPhysicalDevice physicalDevice, ref VkDevice device,
    ref const(char)*[] validationLayers, ref const(char)*[] deviceExtentions, ref VkSurfaceKHR surface, ref VkQueue graphicsQueue, ref VkQueue presentQueue)
{
    auto foundQueueFamily = findQueueFamilies(physicalDevice, surface);

    float queuePriority = 1.0f;

    auto createQueueInfos = createQueueInfos(foundQueueFamily.graphicsFamily.get,
        foundQueueFamily.presentFamily.get, queuePriority);

    if (!initializeDevice(physicalDevice, createQueueInfos, device, validationLayers, deviceExtentions))
    {
        debug writelnUt("Failed to initDevice");
        return false;
    }

    loadDeviceLevelFunctions(device);
    vkGetDeviceQueue(device, foundQueueFamily.graphicsFamily.get, 0, &graphicsQueue);
    vkGetDeviceQueue(device, foundQueueFamily.presentFamily.get, 0, &presentQueue);
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
