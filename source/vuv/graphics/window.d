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

@safe @nogc package nothrow:
void destroyWindow(ref Window window) @trusted
{
    debug writeln("Manual destroying window");
    SDL_DestroyWindow(window._sdlWindow);
}

@safe @nogc private nothrow:

void initWindow(ref Window window)
{
    window._sdlWindow = createSDLWindow(window.title, window.width, window.height);
}
