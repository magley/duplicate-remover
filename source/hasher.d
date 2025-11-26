module hasher;

import std.stdio;
import std.file;
import std.digest.sha;

string[][] hash_groups(string[][] groups)
{
    string[][] collisions;

    foreach (string[] group; groups)
    {
        string[] group_collisions = hash_group(group);
        if (group_collisions.length < 2)
            continue;

        collisions ~= group_collisions;
    }

    return collisions;
}

private string[] hash_group(string[] group)
{
    string[] collisions;

    string[][string] hash_dict;
    foreach (string filename; group)
    {
        string hash = hash_file(filename);
        hash_dict[hash] ~= filename;
    }

    foreach (string[] collision_group; hash_dict)
    {
        if (collision_group.length < 2)
            continue;

        collisions ~= collision_group;
    }

    return collisions;
}

private string hash_file(string path)
{
    const uint chunk_size = 128 * 1024;

    SHA256 h;

    auto f = File(path, "rb");
    foreach (chunk; f.byChunk(chunk_size))
    {
        h.put(chunk);
    }

    auto hash = h.finish();
    string result = toHexString(hash).dup;

    return result;
}
