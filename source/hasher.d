module hasher;

import std.stdio;
import std.file;
import std.digest.sha;
import core.thread.osthread;
import util;
import finder;

class GroupHasherThread : Thread
{
    string[][] groups;
    string[][] collisions;

    this(GroupWithSize[] groups_with_size)
    {
        foreach (GroupWithSize g; groups_with_size)
        {
            this.groups ~= g.group;
        }

        super(&run);
    }

    private void run()
    {
        int[] k = [1, 4, 64, 128];
        //k = [-1];
        collisions = hash_groups_partial_recursive(groups, k);
    }
}

string[][] hash_groups_parallel(string[][] groups, int nthreads)
{
    string[][] collisions;
    GroupHasherThread[] workers;

    //string[][][] groups_split = split_evenly(groups, nthreads);
    GroupWithSize[][] groups_split = split_groups_distribute_size_evenly(groups, nthreads);

    foreach (g; groups_split)
    {
        GroupHasherThread worker = new GroupHasherThread(g);
        workers ~= worker;
        worker.start();
    }

    foreach (GroupHasherThread worker; workers)
    {
        worker.join();
    }

    foreach (GroupHasherThread worker; workers)
    {
        foreach (collision; worker.collisions)
        {
            collisions ~= collision;
        }
    }

    return collisions;
}

private string[][] hash_groups_partial_recursive(string[][] groups, int[] partial_k)
{
    string[][] G = groups;

    foreach (int k; partial_k)
    {
        string[][] collisions;

        foreach (size_t i, string[] group; G)
        {
            string[] group_collisions = hash_group_partial(group, k);
            if (group_collisions.length < 2)
                continue;

            collisions ~= group_collisions;
        }

        G = collisions;
        if (G.length == 0)
        {
            break;
        }
    }

    return G;
}

private string[][] hash_groups(string[][] groups)
{
    string[][] collisions;

    foreach (size_t i, string[] group; groups)
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
    return hash_group_partial(group, -1);
}

private string[] hash_group_partial(string[] group, int k)
{
    string[] collisions;

    string[][string] hash_dict;
    foreach (string filename; group)
    {
        string hash = hash_file_partial(filename, k);
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
    return hash_file_partial(path, -1);
}

private string hash_file_partial(string path, int k)
{
    const uint chunk_size = 1 * 1024;

    SHA256 h;

    auto f = File(path, "rb");
    int chunk_index = 0;
    foreach (chunk; f.byChunk(chunk_size))
    {
        h.put(chunk);
        chunk_index++;
        if (k > 0 && chunk_index > k)
        {
            break;
        }
    }

    auto hash = h.finish();
    string result = toHexString(hash).dup;

    return result;
}
