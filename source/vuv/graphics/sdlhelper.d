module vuv.graphics.sdlhelper;
import bindbc.sdl;
import bindbc.sdl.image;
import std.stdio;
import std.conv;
import std.string : toStringz;
import std.typecons;

version (unittest)
{
    import unit_threaded;

    struct TestFixture
    {
        @disable this(this);

        ~this()
        {
            debug writelnUt("Destroying TESTFIXTURE");
            SDL_DestroyWindow(window);
            SDL_Quit();
        }

        SDL_Window* window;

    }

    RefCounted!TestFixture getFixture()
    {
        synchronized
        {
            if (_initialized)
            {
                return _fixture;
            }
            _initialized = true;

            _fixture = RefCounted!TestFixture(createSDLWindow("TestFixture", 600, 300));
            return _fixture;
        }

    }

    static bool _initialized;
    static RefCounted!TestFixture _fixture;

}

@safe package:
bool loadSDLLibrary() nothrow @trusted @nogc
{
    const SDLSupport ret = loadSDL();
    bool success = ret == sdlSupport;
    if (!success)
    {
        SDL_Log("Error loading SDL dll");
        return success;
    }

    if (loadSDLImage() != sdlImageSupport)
    {
        SDL_Log("Error loading SDL Image dll %s", SDL_GetError());
    }
    return success;
}

bool initializeSDLImage() nothrow @trusted @nogc
{
    const flags = IMG_INIT_PNG | IMG_INIT_JPG;
    if ((IMG_Init(flags) & flags) != flags)
    {
        SDL_Log("IMG_Init: %s", IMG_GetError());
        return false;
    }
    return true;
}

bool initializeSDL() nothrow @trusted @nogc
{
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        debug writeln("Failed to initialize loading SDL Image dll ", to!string(SDL_GetError()));
        return false;
    }
    return true;
}

SDL_Window* createWindow(string title, int width, int height) nothrow @trusted @nogc
{
    const windowFlags = SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE
        | SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_SHOWN;
    SDL_Window* window = SDL_CreateWindow(cast(char*) title,
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, windowFlags);

    if (window is null)
    {
        debug writefln("SDL_CreateWindow: ", SDL_GetError());
        return null;
    }
    return window;
}

SDL_Window* createSDLWindow(string title, int width, int height) nothrow @nogc
{

    if (loadSDLLibrary() && initializeSDL() && initializeSDLImage())
    {
        if (SDL_Window* sdlWindow = createWindow(title, width, height))
        {
            return sdlWindow;
        }
    }
    return null;
}

@("Test getSDLVulkanExtensions")
@trusted unittest
{
    getSDLVulkanExtensions(getFixture().window).length.shouldBeGreaterThan(1);
    writelnUt("refcount: ", getFixture().refCountedStore.refCount);
}

const(char)*[] getSDLVulkanExtensions(SDL_Window* sdlWindow) @trusted nothrow
{
    import std.conv : to;

    uint numberOfExtensions = 0;
    SDL_Vulkan_GetInstanceExtensions(sdlWindow, &numberOfExtensions, null);

    const(char)*[] extensionNames = new const(char)*[numberOfExtensions];
    SDL_Vulkan_GetInstanceExtensions(sdlWindow, &numberOfExtensions, extensionNames.ptr);

    return extensionNames;
}
/*
const(char)*[] getVulkanExtensions(SDL_Window* sdlWindow) @nogc @trusted nothrow
{
    import core.stdc.stdlib : alloca, malloc, free;

    uint numberOfExtensions = 0;
    const(char)*[] extensionNames;
    SDL_Vulkan_GetInstanceExtensions(sdlWindow, &numberOfExtensions, null);

    debug numberOfExtensions += 1;

    size_t size = numberOfExtensions * const(char*).sizeof;
    void* mem = malloc(size);
    extensionNames = cast(const(char)*[]) mem[0 .. size];
    SDL_Vulkan_GetInstanceExtensions(sdlWindow, &numberOfExtensions, extensionNames.ptr);

    debug extensionNames[numberOfExtensions] = VK_EXT_DEBUG_UTILS_EXTENSION_NAME;

    return extensionNames;
}
*/
