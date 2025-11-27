module finder;

import std.stdio;
import std.file;
import std.path;
import std.algorithm;
import std.array;

struct GroupWithSize
{
    string[] group;
    uint size;

    this(string[] group)
    {
        this.group = group;
        this.size = 0;
        foreach (string fname; group)
        {
            this.size += getSize(fname);
        }
    }
}

GroupWithSize[][] split_groups_distribute_size_evenly(string[][] groups, int buckets)
{
    GroupWithSize[] sorted_by_size = sort_groups_by_size(groups);

    // LPT algorithm: next largest object goes in the current smallest bucket,
    // increase that bucket by the object's size.

    GroupWithSize[][] result;
    size_t[] partial_size;

    result.length = buckets;
    partial_size.length = buckets;

    foreach (i; 0 .. buckets)
        partial_size[i] = 0;

    foreach (GroupWithSize g; sorted_by_size)
    {
        size_t bucket_index = minIndex(partial_size);
        result[bucket_index] ~= g;
        partial_size[bucket_index] += g.size;
    }

    return result;
}

GroupWithSize[] sort_groups_by_size(string[][] groups)
{
    GroupWithSize[] result;

    foreach (g; groups)
    {
        result ~= GroupWithSize(g);
    }

    sort!("a.size > b.size")(result);

    return result;
}

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
