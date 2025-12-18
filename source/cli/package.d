module cli;
import common.hasher;

// dfmt off
version (cli)
{
// dfmt on

import std.algorithm;
import std.array;
import std.conv;
import std.datetime.stopwatch;
import std.stdio;
import std.string;
import std.traits;

import common;
import vendor.clyd;

const int MIN_THREADS = 1;
const int MAX_THREADS = 8;

import cli.exporter;

private string[] modes = [EnumMembers!FileType];
private string[] select_modes = [
    EnumMembers!ResultQuickSelect_String, null
];
private string[] export_json_quick_include = [
    EnumMembers!ExportSettings_JSON_QuickInclude_CmdString
];

private string[] hash_functions = ["xxhash32", "sha256", "sha1", "md5"];

private HashFunction get_hash_func(string s)
{
    switch (s)
    {
    case "xxhash32":
        return HashFunction.XXHash3;
    case "sha256":
        return HashFunction.SHA256;
    case "sha1":
        return HashFunction.SHA1;
    case "md5":
        return HashFunction.MD5;
    default:
        return HashFunction.XXHash3;
    }
}

void main_cli(string[] args)
{
    Command root = new Command("duplicate-remover", "Find and remove duplicate files")
        .arg(Arg.single("dir", "d", "Directory to scan", null))
        .arg(Arg.single("workers", "w", "Number of workers", "4"))
        .arg(Arg.single("export-type", null, "Type of export", "JSON", modes))
        .arg(Arg.single("export-file", null, "Export desination", ""))
        .arg(Arg.single("export-json-quick-include", null, "(JSON export) Explicitly add list of files from each group", ExportSettings_JSON_QuickInclude_CmdString.None, export_json_quick_include))
        .arg(Arg.single("select", "sel", "Selection mode", null, select_modes))
        .arg(Arg.single("hashfunc", null, "Hash function to use", hash_functions[0], hash_functions))
        .arg(Arg.flag("trash", null, "Move select deuplicates to trash", false))
        .arg(Arg.flag("delete", null, "Remove selected duplicates permanently", false))
        .set_longer_desc(
            `Duplicate remover scans a directory for identical files based
on their hash. You must either pass export or removal arguments.
Both work on selected files which are a subset of duplicates
chosen through the selection strategy (--select). 
Depending on the export type, you may pass additional settings,
like --export-json-quick-include which is supported by the JSON
exporter.
You may delete files permanently (--delete) or move them to the
Trash (--trash) if suported. 
`).set_callback((Command cmd) { cb_scan(cmd); });

    handle(root, args, "duplicate-remover");
}

void cb_scan(Command cmd)
{
    string dir;
    int worker_count;
    HashFunction hash_func;
    string[][] groups;
    string[][] collisions;
    StopWatch sw;
    long scan_time_ms = 0;
    long collision_time_ms = 0;
    GroupsHasher worker;

    FileType export_type;
    string export_file;
    ResultQuickSelect_String select_mode;
    bool move_to_trash;
    bool remove_permanently;
    bool wanna_delete; // Computed argument.

    // -------------------------------------------------
    // COMPUTE ARGUMENTS

    dir = cmd.args["dir"].value();
    worker_count = cmd.args["workers"].integer(MIN_THREADS, MAX_THREADS);
    hash_func = get_hash_func(cmd.args["hashfunc"].value());
    export_type = cmd.args["export-type"].enumval!FileType;
    export_file = cmd.args["export-file"].value_or(null);
    select_mode = cmd.args["select"].enumval_or!ResultQuickSelect_String(null);
    move_to_trash = cmd.args["trash"].is_set_flag();
    remove_permanently = cmd.args["delete"].is_set_flag();
    if (export_file !is null && strip(export_file).empty())
        export_file = null;
    wanna_delete = move_to_trash || remove_permanently;

    version (Windows)
    {
        dir = dir.replace("/", "\\");
        if (export_file !is null)
            export_file = export_file.replace("/", "\\");
    }

    if (move_to_trash && remove_permanently)
    {
        throw new ArgException("trash", "Cannot set both trash and delete flags");
        return;
    }

    if (!wanna_delete && export_file is null)
    {
        writeln(CERR ~ "You must either delete or export the results" ~ CCLEAR);
        return;
    }

    // -------------------------------------------------
    // SCAN

    writefln("Begin scanning %s with %d workers...", dir, worker_count);
    if (export_file != null)
    {
        writefln("Export results as %s to %s", export_type, export_file);
    }

    sw.start();

    groups = group_files(dir);
    scan_time_ms = sw.peek().total!"msecs"();
    sw.reset();

    writeln("Grouped in ", time_to_string(scan_time_ms));

    worker = new GroupsHasher(groups, worker_count, hash_func);

    worker.run();

    collisions = worker.collisions;

    collision_time_ms = sw.peek().total!"msecs"();
    sw.reset();

    uint conflicing_files = 0;
    foreach (c; collisions)
    {
        foreach (f; c)
            conflicing_files++;
    }

    writeln("Found collisions in ", time_to_string(collision_time_ms));
    writeln("Total time: ", time_to_string(scan_time_ms + collision_time_ms));
    writeln("Found ", collisions.length, " groups");
    writeln("Found ", conflicing_files, " conflicting files");

    // -------------------------------------------------
    // EXPORT

    if (export_file !is null && export_file)
    {
        writefln("Exporting results as %s to %s", export_type, export_file);

        ExportSettings settings = get_export_settings(export_type, cmd);
        export_results(export_file, export_type, collisions, settings);
    }

    // -------------------------------------------------
    // DELETE

    if (collisions.length == 0)
    {
        writeln("Nothing to remove");
    }
    else if (wanna_delete)
    {
        // Select files

        ResultGroup[] result_groups = build_results(collisions, dir);
        foreach (ResultGroup g; result_groups)
        {
            g.quick_select(select_mode);
        }

        // Extract filenames to delete

        string[] files_to_delete;
        foreach (ResultGroup g; result_groups)
        {
            files_to_delete ~= g.arr
                .filter!((Result r) => r.checked)
                .map!((Result r) => r.path_full)
                .array();
        }

        // Log

        if (move_to_trash)
            writefln("Moving %d files to trash...", files_to_delete.length);
        else
            writefln("Removing %d files from disk...", files_to_delete.length);

        // Delete

        delete_selected_files(files_to_delete, move_to_trash, worker_count);
    }
}
}
