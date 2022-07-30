module vuv.graphics.vulkan.graphicspipelines.fileutils;

import std.stdio;
import unit_threaded : Tags;

@Tags("loadVertexShader")
@("Testing loading vertex shader")
unittest
{
    auto file = readFile("shaders/triangle/vert.spv");
    assert(file.length > 0);
}

@Tags("loadFragmentShader")
@("Testing loading fragment shader")
unittest
{
    auto file = readFile("shaders/triangle/frag.spv");
    assert(file.length > 0);
}

byte[] readFile(string filename)
{
    byte[] data;
    auto f = File(filename, "r");
    scope (exit)
    {
        f.close();
        debug writeln("File ", filename, " is closed now");
    }
    if (f.isOpen)
    {
        debug writeln("File size ", f.size);
        data = new byte[f.size];
        f.rawRead(data);
    }
    else
    {
        debug writeln("Failed to open file");
    }
    return data;
}
