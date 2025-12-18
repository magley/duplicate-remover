module common.util;

import std.algorithm;
import std.format;
import std.traits;
import std.utf;

/// Uniformly split array into subarrays.
///
/// Params:
///   - `arr` The array to split.
///   - `parts` How many subarrays to create.
///
/// Returns: The result as an array of arrays.
T[][] split_evenly(T)(T[] arr, ulong parts)
{
    if (parts == 0)
    {
        return [];
    }

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

unittest
{
    int[] arr = [];
    int[][] split = split_evenly(arr, 5);
    assert(split.length == 5);
    foreach (int[] chunk; split)
    {
        assert(chunk.length == 0);
    }
}

unittest
{
    int[] arr = [1, 2, 3];
    int[][] split = split_evenly(arr, 0);
    assert(split.length == 0);
}

unittest
{
    import std.math;

    int[] arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

    for (int i = 1; i <= arr.length; i++)
    {
        int[][] split = split_evenly(arr, i);

        int[] sizes;
        foreach (int[] chunk; split)
        {
            sizes ~= cast(int) chunk.length;
        }

        assert(abs(maxElement(sizes) - minElement(sizes)) <= 1);
    }
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

T stringValToEnum(T)(string s)
{
    foreach (member; __traits(allMembers, T))
    {
        enum value = __traits(getMember, T, member);
        static if (is(typeof(value) == T))
            if (value == s)
                return value;
    }
    throw new Exception("Unknown " ~ T.stringof ~ ": " ~ s);
}

T stringValToEnum(T)(string s, T fallback)
{
    foreach (member; __traits(allMembers, T))
    {
        enum value = __traits(getMember, T, member);
        static if (is(typeof(value) == T))
            if (value == s)
                return value;
    }
    return fallback;
}

void moveToTrash(string path)
{
    version (Windows)
    {
        import core.sys.windows.shellapi;

        const uint FOF_NO_UI = FOF_SILENT | FOF_NOCONFIRMATION | FOF_NOERRORUI | FOF_NOCONFIRMMKDIR;
        wstring wFileName = (path ~ "\0\0").toUTF16();

        SHFILEOPSTRUCTW fileOp;
        fileOp.wFunc = FO_DELETE;
        fileOp.fFlags = FOF_NO_UI | FOF_ALLOWUNDO;
        fileOp.pFrom = wFileName.ptr;

        int error = SHFileOperation(&fileOp);

        if (error)
        {
            // https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shfileoperationa#return-value
            throw new Exception(format("Could not move %s to trash. Error code %d", path, error));
        }
    }
    else
    {
        throw new Exception("Not implemented");
    }
}

string time_to_string(ulong milisecs)
{
    ulong S = 1000;
    ulong M = 60 * S;
    ulong H = 60 * M;

    ulong h = milisecs / H;
    ulong m = (milisecs - (h * H)) / M;
    ulong s = (milisecs - (m * M)) / S;
    ulong ms = (milisecs - (s * S)) / 1;

    if (milisecs < S)
    {
        return format("%dms", ms);
    }
    if (milisecs < M)
    {
        return format("%02ds", s);
    }
    if (milisecs < H)
    {
        return format("%02d:%02d", m, s);
    }
    return format("%02d:%02d:%02d", h, m, s);
}

string to_size_byte_unit(ulong size_bytes)
{
    import std.format;

    const ulong KB = 1024;
    const ulong MB = 1_048_576;
    const ulong GB = 1_073_741_824;

    if (size_bytes < KB)
    {
        return format("%dB", size_bytes);
    }
    if (size_bytes < MB)
    {
        return format("%.2fKB", cast(float) size_bytes / KB);
    }
    if (size_bytes < GB)
    {
        return format("%.2fMB", cast(float) size_bytes / MB);
    }
    return format("%.2fGB", cast(float) size_bytes / GB);
}
