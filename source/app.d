import std.stdio;
import vuv.graphics;
import vuv.graphics.vulkan;
import vuv.graphics.window;

import bindbc.sdl;

version (unittest)
{
    // mixin runTestsMain!("vuv.graphics.vulkan", "vuv.graphics.vulkan.instance");
    mixin runTestsMain!("vuv.graphics.renderer", "vuv.graphics.vulkan.instance",
        "vuv.graphics.sdlhelper", "vuv.graphics.vulkan.physicaldevice",
        "vuv.graphics.vulkan.logicaldevice",
        "vuv.graphics.vulkan.surface",
        "vuv.graphics.vulkan.graphicspipelines.fileutils"
    );
}
else
{

    void mainLoop(ref Window window)
    {
        SDL_Event event;
        bool running = true;
        while (running)
        {
            while (SDL_PollEvent(&event))
            {
                switch (event.type)
                {
                case SDL_KEYDOWN:
                    switch (event.key.keysym.sym)
                    {
                    case SDLK_ESCAPE:
                        running = false;
                        break;
                    default:
                        break;
                    }

                    break;
                case SDL_KEYUP:
                    break;
                case SDL_QUIT:
                    running = false;
                    break;
                default:
                    break;

                }
            }
            SDL_Delay(1 / 60);
        }
    }

    void main()
    {
        auto win = Window("title", 600, 300);
        Vulkan vulkan = Vulkan("title", win._sdlWindow);
        mainLoop(win);
        destroy(vulkan);
        destroyWindow(win);
        SDL_Vulkan_UnloadLibrary();
        SDL_Quit();

    }

}
