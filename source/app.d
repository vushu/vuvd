import std.stdio;
import vuv.graphics;
import vuv.graphics.vulkan;

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
    void main()
    {
        auto win = Window("title", 600, 300);
        Vulkan vulkan = Vulkan("title", win._sdlWindow);
    }
}
