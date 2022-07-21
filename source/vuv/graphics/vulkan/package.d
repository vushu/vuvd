module vuv.graphics.vulkan;
import vuv.graphics.window;
import bindbc.sdl;
import erupted;
import vuv.graphics.sdlhelper;

debug import std.stdio : writeln;
public:
import vuv.graphics.vulkan.instance;

struct Vulkan
{
    nothrow this(string title, SDL_Window* sdlWindow)
    {
        assert(initializeVkInstance(_instance, _debugMessenger, getSDLVulkanExtensions(sdlWindow)));
    }

    nothrow @nogc @trusted ~this()
    {
        debug destroyDebugUtilMessengerExt(_instance, _debugMessenger, null);
        vkDestroyInstance(_instance, null);
    }

private:
    // static const(char)*[] _validationLayers = ["VK_LAYER_KHRONOS_validation"];
    VkInstance _instance;
    VkDebugUtilsMessengerEXT _debugMessenger;
}
