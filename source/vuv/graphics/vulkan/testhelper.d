module vuv.graphics.vulkan.testhelper;

import vuv.graphics.window;
import erupted;
import erupted.vulkan_lib_loader;
import unit_threaded;
import std.stdio;
import vuv.graphics.sdlhelper;
import bindbc.sdl;
import core.sync.mutex;
import vuv.graphics.vulkan.instance;

struct TestFixture
{

    static TestFixture opCall()
    {
        //_mtx.lock_nothrow();
        TestFixture t;
        // loadGlobalLevelFunctions();

        auto appInfo = createVkApplicationInfo("TestTitle");
        t.createInfo = createInstanceVkCreateInfo(appInfo);
        //writelnUt("Creating SDL_Window");
        return t;
    }

    ~this()
    {
        //writelnUt("Freeing SDL");
        SDL_DestroyWindow(_sdlWindow);

    }

    SDL_Window* getSDLWindow()
    {
        synchronized
        {
            if (!_sdlWindow)
                _sdlWindow = createSDLWindow("VulkanTestWindow", 800, 600);
            return _sdlWindow;
        }
    }

    VkInstanceCreateInfo createInfo;
private:

    SDL_Window* _sdlWindow;

}
