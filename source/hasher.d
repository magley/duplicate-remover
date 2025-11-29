module hasher;

import std.stdio;
import std.file;
import std.digest.sha;
import core.thread.osthread;
import util;
import finder;
import xxhash3;

alias ProgressFunc = void delegate(int, int);

class GroupsHasher
{
    // Input
    string[][] groups;
    int worker_count;

    // State
    string[][] collisions;
    GroupHasherThread[] workers;
    GroupWithSize[][] groups_split;

    // Redundant state
    float progress = 0;
    bool finished = false;

    this(string[][] groups, int worker_count)
    {
        this.groups = groups;
        this.worker_count = worker_count;
        this.groups_split = split_groups_distribute_size_evenly(this.groups, this.worker_count);
    }

    void run()
    {
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

        finished = true;
    }

    float get_progress()
    {
        float p = 0;
        foreach (w; workers)
        {
            p += w.get_progress();
        }
        p /= workers.length;
        return p;
    }
}

/// Single worker running in its own thread. 
class GroupHasherThread : Thread
{
    string[][] groups;
    string[][] collisions;

    int total = 1;
    int current = 0;

    this(GroupWithSize[] groups_with_size)
    {
        foreach (GroupWithSize g; groups_with_size)
        {
            this.groups ~= g.group;
        }
        this.isDaemon(true);

        super(&run);
    }

    private void run()
    {
        int[] k = [1, 4, 64, 128];
        k = [-1];

        current = 0;
        total = 0;
        foreach (g; groups)
        {
            total += g.length;
        }

        collisions = hash_groups_partial_recursive(groups, k, &on_progress);
    }

    void on_progress(int curr, int total)
    {
        current++;
        //writeln(curr, " ", total);
        //this.current = curr;
        //this.total = total;
    }

    float get_progress()
    {
        return cast(float) current / cast(float) total;
    }
}

/// Prefer to use GroupsHasher directly, especially if you need to track state.
string[][] hash_groups_parallel(string[][] groups, int nthreads)
{
    GroupsHasher g = new GroupsHasher(groups, nthreads);
    g.run();
    return g.collisions;
}

private string[][] hash_groups_partial_recursive(string[][] groups, int[] partial_k, ProgressFunc progress_cb)
{
    string[][] G = groups;

    foreach (int k; partial_k)
    {
        string[][] collisions;

        foreach (size_t i, string[] group; G)
        {
            string[] group_collisions = hash_group_partial(group, k, progress_cb);
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

private string[][] hash_groups(string[][] groups, ProgressFunc progress_cb)
{
    string[][] collisions;

    foreach (size_t i, string[] group; groups)
    {
        string[] group_collisions = hash_group(group, progress_cb);
        if (group_collisions.length < 2)
            continue;

        collisions ~= group_collisions;
    }

    return collisions;
}

private string[] hash_group(string[] group, ProgressFunc progress_cb)
{
    return hash_group_partial(group, -1, progress_cb);
}

private string[] hash_group_partial(string[] group, int k, ProgressFunc progress_cb)
{
    string[] collisions;

    int total = cast(int) group.length;
    int completed = 0;

    string[][string] hash_dict;
    foreach (string filename; group)
    {
        string hash = hash_file_partial(filename, k);
        completed++;
        if (progress_cb !is null)
            progress_cb(completed, total);
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

    // SHA256 h;
    XXH_32 h;

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
