module exporting;

import std.json;
import std.file;
import std.stdio;
import std.string;
import util;

enum FileType
{
    JSON = "JSON",
    XML = "XML",
    CSV = "CSV"
}

void export_results(string fname, FileType mode, string[][] collisions)
{
    final switch (mode) with (FileType)
    {
    case JSON:
        export_json(fname, collisions);
        return;
    case XML:
        break;
    case CSV:
        break;
    }
}

private void export_json(string fname, string[][] collisions)
{
    JSONValue j;
    j["groups"] = JSONValue.emptyArray;

    foreach (size_t i, string[] group; collisions)
    {
        uint size = 0;
        foreach (string f; group)
        {
            size += getSize(safepath(f));
        }

        JSONValue o;
        o["files"] = group;
        o["totalSize"] = size;
        j["groups"].array() ~= o;
    }

    std.file.write(fname, j.toPrettyString(JSONOptions.preserveObjectOrder));
}
