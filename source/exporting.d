module exporting;

import std.json;
import std.file;
import std.stdio;
import std.string;
import std.algorithm;
import std.array;
import util;

enum FileType
{
    JSON = "JSON",
    JSON_Simple = "JSON Simple",
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
    case JSON_Simple:
        export_json_simple(fname, collisions);
        return;
    case XML:
        break;
    case CSV:
        break;
    }
}

private struct FileWithSize
{
    string filename;
    ulong size;

    this(string filename)
    {
        this.filename = filename;
        this.size = getSize(safepath(filename));
    }

    JSONValue toJson()
    {
        JSONValue j;

        j["path"] = filename;
        j["size"] = size;
        return j;
    }
}

private void export_json(string fname, string[][] collisions)
{
    JSONValue j;
    j["groups"] = JSONValue.emptyArray;

    foreach (size_t i, string[] group; collisions)
    {
        FileWithSize[] files_with_size;
        reserve(files_with_size, group.length);

        ulong size_total = 0;
        foreach (string f; group)
        {
            FileWithSize file_with_size = FileWithSize(f);
            files_with_size ~= file_with_size;
            size_total += file_with_size.size;
        }

        JSONValue o;

        o["files"] = files_with_size
            .sort!("a.size < b.size")
            .map!(f => f.toJson)
            .array;
        o["totalSize"] = size_total;
        j["groups"].array() ~= o;
    }

    std.file.write(fname, j.toPrettyString(JSONOptions.preserveObjectOrder));
}

private void export_json_simple(string fname, string[][] collisions)
{
    JSONValue j = collisions;
    std.file.write(fname, j.toPrettyString(JSONOptions.preserveObjectOrder));
}
