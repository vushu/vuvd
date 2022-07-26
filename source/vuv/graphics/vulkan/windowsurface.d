module vuv.graphics.vulkan.windowsurface;
import bindbc.sdl;
import erupted;
import unit_threaded : Tags;

version (unittest)
{
    import vuv.graphics.vulkan.physicaldevice;
}

@Tags("surfacetest")
@("Test create vulkan surface")
unittest
{
    auto fixture = getVkInstanceFixture();
    auto window = fixture.sdlWindowFixture.window;
    VkSurfaceKHR surface;

    // scope (exit)
    // {
    //     vkDestroySurfaceKHR(fixture.instance, surface, null);
    // }

    assert(createSurface(window, fixture.instance, surface));
}

bool createSurface(SDL_Window* window, ref VkInstance instance, ref VkSurfaceKHR surface)
{
    return !SDL_Vulkan_CreateSurface(window, instance, surface);
}
