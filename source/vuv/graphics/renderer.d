module vuv.graphics.renderer;
import vuv.graphics.vulkan;
import vuv.graphics.window;
import unit_threaded;

struct Renderer
{
    this(ref Window window)
    {
        initializeRenderer(this, window);
    }

private:
    Vulkan _vulkan;
}

private:

void initializeRenderer(ref Renderer renderer, ref Window window)
{
    renderer._vulkan = Vulkan(window.title, window._sdlWindow, true);
}

@Tags("github-actions", "Test renderer")
@("Testing Renderer")
unittest
{
    writelnUt("Testing Renderer");
    assert(1 + 1 == 2);
}
