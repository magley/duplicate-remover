module common.hasher;

import common;
import core.thread.osthread;
import std.digest.sha;
import std.file;
import std.stdio;

alias ProgressFunc = void delegate(int, int);

class GroupsHasher
{
    // Input
    string[][] groups;
    int worker_count;
    HashFunction hash_func;

    // State
    string[][] collisions;
    GroupHasherThread[] workers;
    GroupWithSize[][] groups_split;

    // Redundant state
    float progress = 0;
    bool finished = false;

    this(string[][] groups, int worker_count, HashFunction hash_function)
    {
        this.groups = groups;
        this.worker_count = worker_count;
        this.hash_func = hash_function;
        this.groups_split = split_groups_distribute_size_evenly(this.groups, this.worker_count);
    }

    void run()
    {
        foreach (g; groups_split)
        {
            GroupHasherThread worker = new GroupHasherThread(g, hash_func);
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
    HashFunction hash_func;

    int total = 1;
    int current = 0;

    int[] k = [1];

    this(GroupWithSize[] groups_with_size, HashFunction hash_func)
    {
        foreach (GroupWithSize g; groups_with_size)
        {
            this.groups ~= g.group;
        }
        this.isDaemon(true);
        this.hash_func = hash_func;

        super(&run);
    }

    private void run()
    {
        current = 0;
        total = 0;
        foreach (g; groups)
        {
            total += g.length;
        }

        collisions = hash_groups_partial_recursive(groups, k, hash_func, &on_progress);
    }

    void on_progress(int curr, int total)
    {
        current++;
    }

    float get_progress()
    {
        int total_real = total * 2; // *2 because of k.
        return cast(float) current / (cast(float) total_real);
    }
}

/// Prefer to use GroupsHasher directly, especially if you need to track state.
string[][] hash_groups_parallel(string[][] groups, int nthreads, HashFunction hash_function)
{
    GroupsHasher g = new GroupsHasher(groups, nthreads, hash_function);
    g.run();
    return g.collisions;
}

private string[][] hash_groups_partial_recursive(string[][] groups, int[] partial_k, HashFunction func, ProgressFunc progress_cb)
{
    string[][] G = groups;

    foreach (int k; partial_k)
    {
        string[][] collisions;

        foreach (size_t i, string[] group; G)
        {
            string[][] group_collisions = hash_group_partial(group, k, func, progress_cb);
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

private string[][] hash_groups(string[][] groups, HashFunction func, ProgressFunc progress_cb)
{
    string[][] collisions;

    foreach (size_t i, string[] group; groups)
    {
        string[][] group_collisions = hash_group(group, func, progress_cb);
        collisions ~= group_collisions;
    }

    return collisions;
}

private string[][] hash_group(string[] group, HashFunction func, ProgressFunc progress_cb)
{
    return hash_group_partial(group, -1, func, progress_cb);
}

private string[][] hash_group_partial(string[] group, int k, HashFunction func, ProgressFunc progress_cb)
{
    string[][] collisions;

    int total = cast(int) group.length;
    int completed = 0;

    string[][string] hash_dict;
    foreach (string filename; group)
    {
        try
        {
            string hash = hash_file_partial(filename, k, func);
            completed++;
            hash_dict[hash] ~= filename;
            if (progress_cb !is null)
            {
                progress_cb(completed, total);
            }
        }
        catch (Exception e)
        {
            writeln(e);
        }
    }

    foreach (string[] collision_group; hash_dict)
    {
        if (collision_group.length < 2)
            continue;

        collisions ~= collision_group;
    }

    return collisions;
}

private string hash_file(string path, HashFunction func)
{
    return hash_file_partial(path, -1, func);
}

private string hash_file_partial(string path, int k, HashFunction func)
{
    const uint chunk_size = 1 * 1024;

    Hasher h;
    h.func = func;

    h.begin();

    auto f = File(safepath(path), "rb");
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
    string result = toHexString(hash);

    return result;
}

enum HashFunction
{
    XXHash3,
    SHA256,
    SHA1,
}

struct Hasher
{
    import std.digest.sha;
    import xxhash3;

    HashFunction func;

    union
    {
        XXH_32 xxh32;
        SHA256 sha256;
        SHA1 sha1;
    }

    void begin()
    {

    }

    void put(scope const(ubyte)[] data...)
    {
        final switch (func) with (HashFunction)
        {
        case XXHash3:
            xxh32.put(data);
            break;
        case SHA256:
            sha256.put(data);
            break;
        case SHA1:
            sha1.put(data);
            break;
        }
    }

    ubyte[] finish()
    {
        final switch (func) with (HashFunction)
        {
        case XXHash3:
            return xxh32.finish().dup;
        case SHA256:
            return sha256.finish().dup;
        case SHA1:
            return sha1.finish().dup;
        }
    }
}
