module vuv.debugutilities;

import std.stdio : writeln;

struct testname
{
    string title;
}

private void linePrint()
{
    return writeln("----------------------------------------------");
}

void printTestTitle(string title)
{
    linePrint();
    writeln(title);
    linePrint();
}

void printTestResult(bool result, string title = "")
{
    import std.stdio : writeln;
    import std.array : empty;

    string text = result ? "Test successfully passed ✅" : "Test failed ❌";
    if (!title.empty)
    {
        linePrint();
        writeln(title);
    }
    linePrint();
    writeln(text);
    linePrint();
}
