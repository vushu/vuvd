module vuv.graphics.renderer;
import vuv.graphics.vulkan;
import vuv.graphics.window;

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
