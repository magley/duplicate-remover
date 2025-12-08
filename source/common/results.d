module common.results;

import std.array;
import std.algorithm;
import std.file;
import std.path;
import std.conv;
import util;
import std.traits;

enum ResultQuickSelect
{
    AllButLargest,
    AllButSmallest,
    OnlyLargest,
    OnlySmallest,
    All,
    None,
}

enum ResultQuickSelect_String
{
    AllButLargest = "except-largest",
    AllButSmallest = "except-smallest",
    OnlyLargest = "largest",
    OnlySmallest = "smallest",
    All = "all",
    None = "none",
}

ResultQuickSelect to(ResultQuickSelect_String e)
{
    final switch (e) with (ResultQuickSelect_String)
    {
    case AllButLargest:
        return ResultQuickSelect.AllButLargest;
    case AllButSmallest:
        return ResultQuickSelect.AllButSmallest;
    case OnlyLargest:
        return ResultQuickSelect.OnlyLargest;
    case OnlySmallest:
        return ResultQuickSelect.OnlySmallest;
    case All:
        return ResultQuickSelect.All;
    case None:
        return ResultQuickSelect.None;
    }
}

class Result
{
    string path_full;
    string path;
    bool checked;
    ulong size_bytes;

    this(string path_full, string path, bool checked)
    {
        this.path_full = path_full;
        this.path = path;
        this.checked = checked;
        this.size_bytes = getSize(safepath(path_full));
    }
}

class ResultGroup
{
    Result[] arr;
    ulong size_bytes;
    string size_str;

    /// Externally used to order groups within an array.
    size_t index = 0;

    this(string[] filenames, string directory)
    {
        foreach (string p; filenames)
        {
            string path_rel = relativePath(p, directory);
            arr ~= new Result(p, path_rel, false);
        }

        compute_params();
    }

    private void compute_params()
    {
        size_bytes = 0;
        foreach (c; arr)
            size_bytes += c.size_bytes;
        size_str = to_size_byte_unit(size_bytes);
    }

    size_t length() const
    {
        return arr.length;
    }

    void quick_select(ResultQuickSelect_String strategy)
    {
        quick_select(to(strategy));
    }

    void quick_select(ResultQuickSelect strategy)
    {
        foreach (c; arr)
            c.checked = false;

        final switch (strategy) with (ResultQuickSelect)
        {
        case AllButLargest:
            foreach (c; arr.dup.sort!"a.size_bytes < b.size_bytes"[1 .. $])
                c.checked = true;
            break;
        case AllButSmallest:
            foreach (c; arr.dup.sort!"a.size_bytes > b.size_bytes"[1 .. $])
                c.checked = true;
            break;
        case OnlyLargest:
            arr.maxElement!"a.size_bytes".checked = true;
            break;
        case OnlySmallest:
            arr.minElement!"a.size_bytes".checked = true;
            break;
        case All:
            foreach (c; arr)
                c.checked = true;
            break;
        case None:
            break;
        }
    }
}
