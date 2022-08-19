module vuv.graphics.window;
import bindbc.sdl;
import std.exception;
import vuv.graphics.sdlhelper;

debug
{
    import std.stdio;
}

struct Window
{
@nogc @safe nothrow:
    this(string title, int width, int height)
    {
        this.title = title;
        this.width = width;
        this.height = height;
        initWindow(this);
    }

    string title;
    int width;
    int height;
    // package:
    SDL_Window* _sdlWindow;
}

void destroyWindow(ref Window window)
{
    SDL_DestroyWindow(window._sdlWindow);
}

void handleEvent(ref Window window, ref SDL_Event event, void delegate(int width, int height) resizeCallback)
{
    if (event.type != SDL_EventType.SDL_WINDOWEVENT)
        return;
    switch (event.window.event)
    {
    case SDL_WindowEventID.SDL_WINDOWEVENT_SIZE_CHANGED:
        window.width = event.window.data1;
        window.height = event.window.data2;
        // SDL_SetWindowSize(window._sdlWindow, window.width, window.height);
        // resizeCallback(event.window.data1, event.window.data2);
        resizeCallback(event.window.data1, event.window.data2);
        break;
    case SDL_WindowEventID.SDL_WINDOWEVENT_EXPOSED:
        // resizeCallback(event.window.data1, event.window.data2);
        // debug writeln("hererere");
        // resizeCallback(event.window.data1, event.window.data2);
        break;

    default:
        break;
    }

}

@safe @nogc private nothrow:

void initWindow(ref Window window)
{
    window._sdlWindow = createSDLWindow(window.title, window.width, window.height);
}
