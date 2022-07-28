module vuv.graphics.vulkan.physicaldevice;
import vuv.graphics.vulkan.staticvalues;
import erupted;
import std.typecons : RefCounted, refCounted;

import std.algorithm.searching : maxElement;
import vuv.graphics.vulkan.swapchain;

debug import unit_threaded;
import std.typecons : Nullable;

struct QueueFamilyIndices
{
    Nullable!uint graphicsFamily;
    Nullable!uint presentFamily;

    bool isComplete()
    {
        return !graphicsFamily.isNull && !presentFamily.isNull;
    }
}

version (unittest)
{

    import unit_threaded;
    import vuv.graphics.vulkan.instance : initializeVkInstance, destroyDebugUtilMessengerExt;
    import erupted.vulkan_lib_loader;
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
            // writelnUt("Initializing TestVkInstanceFixture");
            auto sdlWindowFixture = getSDLWindowFixture();
            auto enabledExtensions = getSDLVulkanExtensions(sdlWindowFixture.window);

            VkInstance instance;

            VkDebugUtilsMessengerEXT debugMessenger;

            VkSurfaceKHR surface;

            assert(initializeVkInstance(instance, debugMessenger, enabledExtensions));
            assert(createSurface(sdlWindowFixture.window, instance, surface));

            _fixture = RefCounted!TestVkInstanceFixture(instance,
                debugMessenger, surface, sdlWindowFixture);
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
        if (score > 0 && isDeviceSuitable(device, surface))
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
        vkGetPhysicalDeviceSurfaceSupportKHR(device, i, surface, &presentSupport);

        if (presentSupport)
        {
            indices.presentFamily = i;
        }

        if (indices.isComplete)
        {
            break;
        }
        i++;
    }

    return indices;
}

bool isDeviceSuitable(ref VkPhysicalDevice physicalDevice, ref VkSurfaceKHR surface)
{
    import vuv.graphics.vulkan;

    bool deviceExtensionSupported = checkDeviceExtensionSupport(physicalDevice, getRequiredDeviceExtensionsAsSet);
    if (!deviceExtensionSupported)
    {
        return false;
    }
    auto swapChainDetails = querySwapChainSupport(physicalDevice, surface);
    return findQueueFamilies(physicalDevice, surface).isComplete && deviceExtensionSupported && swapChainDetails
        .isSwapChainAdequate;
}

bool checkDeviceExtensionSupport(ref VkPhysicalDevice device, bool[string] requiredDeviceExtentions)
{
    import std.conv : to;

    uint extensionCount;

    vkEnumerateDeviceExtensionProperties(device, null, &extensionCount, null);

    if (extensionCount == 0)
    {
        return false;
    }

    VkExtensionProperties[] availableDeviceExtensions = new VkExtensionProperties[extensionCount];

    vkEnumerateDeviceExtensionProperties(device, null, &extensionCount,
        availableDeviceExtensions.ptr);

    import core.stdc.string : strcmp;

    // debug writelnUt("extensionCount count: ", extensionCount);

    foreach (availableExtension; availableDeviceExtensions)
    {
        requiredDeviceExtentions.remove(to!string(availableExtension.extensionName.ptr));
    }

    // debug writelnUt("required length: ", requiredDeviceExtentions.length);
    // debug writelnUt("availableDeviceExtensions length: ", availableDeviceExtensions.length);
    return requiredDeviceExtentions.length == 0;

}
