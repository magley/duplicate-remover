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

struct ExportSettings_JSON
{
    enum QuickInclude
    {
        None,
        LargestInEachGroup,
        SmallestInEachGroup,
        AllButLargestInEachGroup,
        AllButSmallestInEachGroup,
    }

    QuickInclude quick_include = QuickInclude.LargestInEachGroup;
}

struct ExportSettings
{
    ExportSettings_JSON json;
}

void export_results(string fname, FileType mode, string[][] collisions, ExportSettings settings)
{
    final switch (mode) with (FileType)
    {
    case JSON:
        export_json(fname, collisions, settings.json);
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

private void export_json(string fname, string[][] collisions, ExportSettings_JSON settings)
{
    JSONValue j;
    j["groups"] = JSONValue.emptyArray;

    FileWithSize[][] groups_with_size;

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
        groups_with_size ~= files_with_size;
    }

    final switch (settings.quick_include) with (ExportSettings_JSON.QuickInclude)
    {
    case None:
        break;
    case LargestInEachGroup:
        j["quick_include"] = groups_with_size.map!(g => g[0].filename).array;
        break;
    case SmallestInEachGroup:
        j["quick_include"] = groups_with_size.map!(g => g[$ - 1].filename).array;
        break;
    case AllButLargestInEachGroup:
        string[] s;
        foreach (group; groups_with_size)
        {
            foreach (size_t i, f; group)
            {
                if (i == 0)
                    continue;
                s ~= f.filename;
            }
        }
        j["quick_include"] = s;
        break;
    case AllButSmallestInEachGroup:
        string[] s;
        foreach (group; groups_with_size)
        {
            foreach (size_t i, f; group)
            {
                if (i == group.length - 1U)
                    continue;
                s ~= f.filename;
            }
        }
        j["quick_include"] = s;
        break;
    }

    std.file.write(fname, j.toPrettyString(JSONOptions.preserveObjectOrder));
}

private void export_json_simple(string fname, string[][] collisions)
{
    JSONValue j = collisions;
    std.file.write(fname, j.toPrettyString(JSONOptions.preserveObjectOrder));
}
