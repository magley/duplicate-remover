module util;

import std.algorithm;

T[][] split_evenly(T)(T[] arr, ulong parts)
{
    T[][] result;
    result.length = parts;

    ulong part_size = max(1, arr.length / parts);

    foreach (i; 0 .. parts)
    {
        size_t start = i * part_size;
        if (start >= arr.length)
            break;

        size_t end = start + part_size;
        if (end >= arr.length)
            end = arr.length;

        result[i] ~= arr[start .. end];
    }

    return result;
}

string safepath(string path)
{
    version (Windows)
    {
        const static string PREFIX = `\\?\`;
        if (path.startsWith(PREFIX))
            return path;

        return PREFIX ~ path;
    }
    else
    {
        return path;
    }
}
