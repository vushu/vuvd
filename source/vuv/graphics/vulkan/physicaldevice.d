module vuv.graphics.vulkan.physicaldevice;
import erupted;
import std.typecons : RefCounted, refCounted;

import std.algorithm.searching : maxElement;

debug import unit_threaded;
import std.typecons : Nullable;

struct QueueFamilyIndices
{
    Nullable!uint graphicsFamily;
    Nullable!uint presentFamily;

    bool isComplete()
    {
        // return !graphicsFamily.isNull && !presentFamily.isNull;
        return !graphicsFamily.isNull;
    }
}

version (unittest)
{

    import unit_threaded;
    import vuv.graphics.vulkan.instance : initializeVkInstance, destroyDebugUtilMessengerExt;
    import bindbc.sdl;
    import vuv.graphics.sdlhelper;
    import std.algorithm.mutation : move;
    import vuv.graphics.vulkan.windowsurface;

    struct TestVkInstanceFixture
    {
        @disable this(this);

        ~this()
        {

            writelnUt("Destroyed TestVkInstanceFixture");
            debug destroyDebugUtilMessengerExt(instance, debugMessenger, null);
            vkDestroySurfaceKHR(instance, surface, null);
            vkDestroyInstance(instance, null);
        }

        VkInstance instance;
        VkDebugUtilsMessengerEXT debugMessenger;
        VkSurfaceKHR surface;
        RefCounted!TestSDLWindowFixture sdlWindowFixture;

    }

    RefCounted!TestVkInstanceFixture getVkInstanceFixture()
    {
        synchronized
        {
            if (_fixture.refCountedStore.isInitialized)
            {
                return _fixture;
            }
            writelnUt("Initializing TestVkInstanceFixture");
            auto sdlWindowFixture = getSDLWindowFixture();
            auto enabledExtensions = getSDLVulkanExtensions(sdlWindowFixture.window);

            VkInstance instance;

            VkDebugUtilsMessengerEXT debugMessenger;

            VkSurfaceKHR surface;

            assert(initializeVkInstance(instance, debugMessenger, enabledExtensions));
            assert(createSurface(sdlWindowFixture.window, instance, surface));

            _fixture = RefCounted!TestVkInstanceFixture(instance, debugMessenger, surface, sdlWindowFixture);
            return _fixture;
        }

    }

    static RefCounted!TestVkInstanceFixture _fixture;

}
@Tags("getPhysicalDevice")
@("Test getPhysicalDevice")
unittest
{
    auto fixture = getVkInstanceFixture();
    VkPhysicalDevice device;

    // VkSurfaceKHR surface;
    // assert(createSurface(fixture.sdlWindowFixture.window, fixture.instance, surface));
    getPhysicalDevice(fixture.instance, device, fixture.surface).shouldBeTrue;

}

//Graphics card
bool getPhysicalDevice(ref VkInstance instance,
    ref VkPhysicalDevice physicalDevice, ref VkSurfaceKHR surface)
{
    uint numberOfDevices = 0;

    vkEnumeratePhysicalDevices(instance, &numberOfDevices, null);

    if (numberOfDevices == 0)
    {
        return false;
    }

    VkPhysicalDevice[] physicalDevices = new VkPhysicalDevice[numberOfDevices];

    vkEnumeratePhysicalDevices(instance, &numberOfDevices, physicalDevices.ptr);

    VkPhysicalDevice[int] useableDevices;

    foreach (VkPhysicalDevice device; physicalDevices)
    {
        int score = rateDeviceSuitability(device);
        if (score > 0 && hasGraphicsFamily(device, surface))
        {
            //debug writelnUt("devices score which are suitable!: ", score);
            useableDevices[score] = device;
        }
    }

    if (useableDevices.length == 0)
    {
        debug writelnUt("No devices are suitable!");
        return false;
    }
    physicalDevice = useableDevices[useableDevices.keys.maxElement];
    return true;
}

int rateDeviceSuitability(ref VkPhysicalDevice physicalDevice)
{
    VkPhysicalDeviceProperties deviceProperties;
    VkPhysicalDeviceFeatures deviceFeatures;

    vkGetPhysicalDeviceProperties(physicalDevice, &deviceProperties);
    vkGetPhysicalDeviceFeatures(physicalDevice, &deviceFeatures);

    int score = 0;
    if (deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU)
    {
        score += 1000;
    }

    score += deviceProperties.limits.maxImageDimension2D;

    if (!deviceFeatures.geometryShader)
    {
        return 0;
    }

    return score;
}

QueueFamilyIndices findQueueFamilies(ref VkPhysicalDevice device, ref VkSurfaceKHR surface)
{
    uint queueFamilyCount = 0;

    QueueFamilyIndices indices;

    // FindQueueFamily
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, null);
    VkQueueFamilyProperties[] queueFamilies = new VkQueueFamilyProperties[queueFamilyCount];
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, queueFamilies.ptr);

    uint i = 0;

    foreach (queueFamily; queueFamilies)
    {
        if (queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT)
        {
            indices.graphicsFamily = i;
        }

        VkBool32 presentSupport = false;
        // vkGetPhysicalDeviceSurfaceSupportKHR(device, i, surface, &presentSupport);

        // if (presentSupport)
        // {
        //     indices.presentFamily = i;
        // }

        if (indices.isComplete)
        {
            break;
        }
        i++;
    }

    return indices;
}

bool hasGraphicsFamily(ref VkPhysicalDevice physicalDevice, ref VkSurfaceKHR surface)
{
    return findQueueFamilies(physicalDevice, surface).isComplete;
}

VkDeviceQueueCreateInfo[] createUniqueQueueFamilies(uint queueFamily,
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