module common.ini;

import std.algorithm.iteration;
import std.array;
import std.stdio;
import std.string;

struct IniData
{
    string programVersion;

    void load(string text)
    {
        string[] lines = text.split("\n");
        foreach (string line; lines)
        {
            string[] parts = text.split("=").map!(s => s.strip)().array;

            if (parts.length == 0)
                continue;
            if (parts[0].startsWith('#'))
                continue;
            if (parts.length != 2)
            {
                writeln("Warning: bad INI line: " ~ line);
                continue;
            }
            string k = parts[0];
            string v = parts[1];

            mapKV(k, v);
        }
    }

    private void mapKV(string key, string value)
    {
        if (key == "version")
        {
            programVersion = value;
        }
    }
}
