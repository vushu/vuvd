module vuv.graphics.vulkan.instance;
import erupted;
import bindbc.sdl;
import std.string : toStringz;
import std.conv;
import std.exception;

debug import vuv.debugutilities;

debug import std.stdio : writeln;

@safe package:

version (unittest)
{
    import vuv.graphics.window;
    import erupted.vulkan_lib_loader;
    import unit_threaded;
    import std.stdio;
    import vuv.graphics.sdlhelper;
    import vuv.graphics.vulkan;

}

@("Test create vulkan instance with debug")
@trusted unittest
{
    //Arrange
    VkInstance instance;
    VkDebugUtilsMessengerEXT debugMessenger;
    static const(char)*[] validationLayers = ["VK_LAYER_KHRONOS_validation"];
    auto appInfo = createVkApplicationInfo("TestApp");
    auto createInfo = createInstanceVkCreateInfo(appInfo);

    auto debugCreateInfo = createVulkanDebug();
    auto fixture = getFixture();
    auto enabledExtensions = getSDLVulkanExtensions(fixture.window);
    //Adding vulkan Debug extension
    enabledExtensions = enabledExtensions ~ VK_EXT_DEBUG_UTILS_EXTENSION_NAME;

    addExtentions(createInfo, enabledExtensions);
    checkValidationLayerSupport(validationLayers).shouldBeTrue;
    addValidationLayers(createInfo, validationLayers);
    addDebug(createInfo, debugCreateInfo);

    instantiateVkInstance(createInfo, instance).shouldBeTrue;
    instantiateDebugFeature(instance, debugCreateInfo, debugMessenger).shouldBeTrue;

    //important to load functions
    loadInstanceLevelFunctions(instance);

    scope (exit)
    {
        destroyDebugUtilMessengerExt(instance, debugMessenger, null);
        vkDestroyInstance(instance, null);
        writelnUt("Done destroying");
    }

}

@("Test initializeVkInstance")
@trusted
unittest
{
    import erupted;

    VkInstance instance;
    VkDebugUtilsMessengerEXT debugMessenger;
    initializeVkInstance(instance, debugMessenger, getSDLVulkanExtensions(getFixture.window)).shouldBeTrue;
}

bool initializeVkInstance(ref VkInstance instance, ref VkDebugUtilsMessengerEXT debugMessenger, const(
        char)*[] enabledExtensions) @trusted nothrow
{
    static const(char)*[] validationLayers = ["VK_LAYER_KHRONOS_validation"];
    auto appInfo = createVkApplicationInfo("TestApp");
    auto createInfo = createInstanceVkCreateInfo(appInfo);

    debug auto debugCreateInfo = createVulkanDebug();
    //Adding vulkan Debug extension
    debug enabledExtensions ~= VK_EXT_DEBUG_UTILS_EXTENSION_NAME;

    addExtentions(createInfo, enabledExtensions);
    if (!checkValidationLayerSupport(validationLayers))
    {
        import std.stdio : writeln;

        debug writeln("Failed to validate layers");
        return false;
    }
    addValidationLayers(createInfo, validationLayers);
    debug addDebug(createInfo, debugCreateInfo);

    if (!instantiateVkInstance(createInfo, instance))
    {
        debug writeln("Failed to instantiate vk instance!");
        return false;
    }
    debug
    {

        if (!instantiateDebugFeature(instance, debugCreateInfo, debugMessenger))
        {

            writeln("Failed to instantiate vk debug feature!");
            return false;
        }
    }

    //important to load functions
    loadInstanceLevelFunctions(instance);
    return true;

}

@("Test getVulkanExtensions")
@trusted
unittest
{
    loadGlobalLevelFunctions();
    getVulkanExtensions().length.shouldBeGreaterThan(0);
}

VkExtensionProperties[] getVulkanExtensions() @trusted
{
    import std.conv : to;
    import std.stdio;

    uint numberOfExtensions = 0;
    vkEnumerateInstanceExtensionProperties(null, &numberOfExtensions, null);
    VkExtensionProperties[] vkProperties = new VkExtensionProperties[numberOfExtensions];
    vkEnumerateInstanceExtensionProperties(null, &numberOfExtensions, vkProperties.ptr);

    foreach (VkExtensionProperties prop; vkProperties)
    {
        debug writeln(prop.extensionName);
    }
    return vkProperties;

}

VkApplicationInfo createVkApplicationInfo(string title) @trusted nothrow
{
    VkApplicationInfo appInfo;
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = title.ptr;
    appInfo.applicationVersion = VK_MAKE_API_VERSION(0, 1, 0, 0);
    appInfo.pEngineName = "VuvEngine";
    appInfo.engineVersion = VK_MAKE_API_VERSION(0, 1, 0, 0);
    appInfo.apiVersion = VK_API_VERSION_1_0;
    appInfo.pNext = null;
    return appInfo;

}

VkInstanceCreateInfo createInstanceVkCreateInfo(ref VkApplicationInfo appInfo) @trusted @nogc nothrow
{
    //createInfo
    VkInstanceCreateInfo createInfo = {};
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    createInfo.pNext = null;
    createInfo.enabledLayerCount = 0;
    createInfo.pApplicationInfo = &appInfo;
    return createInfo;

}

VkDebugUtilsMessengerCreateInfoEXT createVulkanDebug() @trusted nothrow
{
    debug import std.conv : to;

    debug import std.stdio;

    VkDebugUtilsMessengerCreateInfoEXT debugCreateInfo;
    debugCreateInfo.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
    debugCreateInfo.messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT
        | VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT
        | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
    debugCreateInfo.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT
        | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT
        | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
    debugCreateInfo.pUserData = null;
    debugCreateInfo.pfnUserCallback = (VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity,
        VkDebugUtilsMessageTypeFlagsEXT messageType,
        const(VkDebugUtilsMessengerCallbackDataEXT)* pCallbackData, void* pUserData) {

        if (messageSeverity == VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT)
        {
            //debug writeln("VERBOSE ", to!string(pCallbackData.pMessage));
        }
        if (messageSeverity >= VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT)
        {
            debug writeln("VULKAN CALLBACK DEBUG");
            // Message is important enough to show
        }
        return VK_FALSE;
    };
    return debugCreateInfo;

}

VkResult createDebugUtilMessengerExt(ref VkInstance instance, const(VkDebugUtilsMessengerCreateInfoEXT)* pCreateInfo,
    const(VkAllocationCallbacks)* pAllocator, VkDebugUtilsMessengerEXT* pDebugMessenger) @trusted nothrow
{
    auto func = cast(PFN_vkCreateDebugUtilsMessengerEXT) vkGetInstanceProcAddr(instance,
        "vkCreateDebugUtilsMessengerEXT");
    if (func != null)
    {
        return func(instance, pCreateInfo, pAllocator, pDebugMessenger);
    }
    return VK_ERROR_EXTENSION_NOT_PRESENT;
}

void destroyDebugUtilMessengerExt(ref VkInstance instance,
    VkDebugUtilsMessengerEXT debugMessenger, const(VkAllocationCallbacks)* pAllocator) @trusted nothrow
{
    debug import std.stdio;

    auto func = cast(PFN_vkDestroyDebugUtilsMessengerEXT) vkGetInstanceProcAddr(
        instance, "vkDestroyDebugUtilsMessengerEXT");
    if (func != null)
    {
        func(instance, debugMessenger, pAllocator);
        debug writeln("Successfully destroyed vulkan debugging add-on");
    }
}

bool instantiateVkInstance(ref VkInstanceCreateInfo createInfo, ref VkInstance instance) @trusted nothrow
{
    VkResult result = vkCreateInstance(&createInfo, null, &instance);
    return result == VK_SUCCESS;
}

void addExtentions(ref VkInstanceCreateInfo createInfo, ref const(char)*[] extensionNames) @trusted nothrow
{
    createInfo.enabledExtensionCount = cast(uint) extensionNames.length;
    createInfo.ppEnabledExtensionNames = extensionNames.ptr;
}

void addValidationLayers(ref VkInstanceCreateInfo createInfo, ref const(char)*[] validationLayers) @trusted nothrow
{
    createInfo.enabledLayerCount = cast(uint) validationLayers.length;
    createInfo.ppEnabledLayerNames = validationLayers.ptr;
}

void addDebug(ref VkInstanceCreateInfo createInfo,
    ref VkDebugUtilsMessengerCreateInfoEXT debugCreateInfo) @trusted nothrow
{
    createInfo.pNext = cast(VkDebugUtilsMessengerCreateInfoEXT*)&debugCreateInfo;
}

bool instantiateDebugFeature(ref VkInstance instance,
    ref VkDebugUtilsMessengerCreateInfoEXT debugCreateInfo,
    ref VkDebugUtilsMessengerEXT debugMessenger) @trusted nothrow
{
    debug import std.stdio;

    if (createDebugUtilMessengerExt(instance, &debugCreateInfo, null,
            &debugMessenger) != VK_SUCCESS)
    {
        debug writeln("Failed to set up debug messenger!");
    }
    return true;
}

@("Test check availableLayers")
@trusted unittest
{
    loadGlobalLevelFunctions();
    static const(char)*[] validationLayers = ["VK_LAYER_KHRONOS_validation"];
    checkValidationLayerSupport(validationLayers).shouldBeTrue;
}

bool checkValidationLayerSupport(ref const(char)*[] checkValidationLayers) @nogc @trusted nothrow
{
    import core.stdc.stdlib : alloca;
    import core.stdc.string : strcmp;
    import std.conv : to;

    debug import std.stdio;

    uint numberOfValidationLayers;
    vkEnumerateInstanceLayerProperties(&numberOfValidationLayers, null);
    //debug writeln("number of layers:", numberOfValidationLayers);
    size_t size = numberOfValidationLayers * VkLayerProperties.sizeof;
    void* mem = alloca(size);
    VkLayerProperties[] availableLayers = cast(VkLayerProperties[]) mem[0 .. size];
    vkEnumerateInstanceLayerProperties(&numberOfValidationLayers, availableLayers.ptr);
    foreach (checkLayer; checkValidationLayers)
    {
        bool layerFound = false;
        foreach (VkLayerProperties availableLayer; availableLayers)
        {
            if (strcmp(availableLayer.layerName.ptr, checkLayer) == 0)
            {
                //debug writeln(to!string(checkLayer), " is available");
                layerFound = true;
                break;
            }
        }
        if (!layerFound)
        {
            debug writeln("No Layer: ", to!string(checkLayer), " isn't available");
            debug writeln("install it: sudo apt install vulkan-validationlayers-dev");
            return false;
        }
    }
    return true;

}
