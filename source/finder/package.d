module finder;

import std.stdio;
import std.file;
import std.path;
import std.algorithm;
import std.array;

string[][] group_files(string path)
{
    string[][] result;

    result = group_files_by_size(path);

    result = result.filter!(a => a.length >= 2)().array;
    return result;
}

private string[][] group_files_by_size(string path)
{
    string[][] result;

    string[][ulong] size_groups;
    foreach (DirEntry f; dirEntries(path, SpanMode.depth))
    {
        if (f.isDir())
        {
            continue;
        }

        ulong f_size = f.size();
        string f_name = f.name();

        size_groups[f_size] ~= f_name;
    }

    foreach (string[] size_group; size_groups)
    {
        result ~= size_group;
    }

    return result;
}
