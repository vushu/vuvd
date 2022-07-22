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

}

@Tags("github-actions", "Test renderer")
unittest
{
    writelnUt("Testing Renderer");
    assert(1 + 1 == 2);
}
