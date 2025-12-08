module cli;

import std.stdio;
import std.array;
import std.conv;
import std.string;
import std.datetime.stopwatch;
import std.traits;

import finder;
import hasher;
import util;
import exporting;

import vendor.clyd;
import exporting;

const int MIN_THREADS = 1;
const int MAX_THREADS = 8;

enum SelectMode
{
    AllButLargest = "except-largest",
    AllButSmallest = "except-smallest",
    OnlyLargest = "largest",
    OnlySmallest = "smallest",
    All = "all"
}

private string[] modes = [EnumMembers!FileType];
private string[] select_modes = [EnumMembers!SelectMode];

void main_cli(string[] args)
{
    Command root = new Command("duplicate-remover", "Find and remove duplicate files")
        .arg(Arg.single("dir", "d", "Directory to scan", null))
        .arg(Arg.single("workers", "w", "Number of workers", "4"))
        .arg(Arg.single("export-type", null, "Type of export", "JSON", modes))
        .arg(Arg.single("export-file", null, "Export desination", ""))
        .arg(Arg.single("select", "sel", "Selection mode", null, select_modes))
        .arg(Arg.flag("trash", null, "Move select deuplicates to trash", false))
        .arg(Arg.flag("delete", null, "Remove selected duplicates permanently", false))
        .set_callback((Command cmd) { cb_scan(cmd); });

    handle(root, args, "duplicate-remover");
}

void cb_scan(Command cmd)
{
    string dir;
    int worker_count;
    string[][] groups;
    string[][] collisions;
    StopWatch sw;
    long scan_time_ms = 0;
    long collision_time_ms = 0;
    GroupsHasher worker;

    FileType export_type;
    string export_file;
    SelectMode select_mode;
    bool move_to_trash;
    bool remove_permanently;
    bool wanna_delete; // Computed argument.

    // -------------------------------------------------
    // COMPUTE ARGUMENTS

    dir = cmd.args["dir"].value();
    worker_count = cmd.args["workers"].integer(MIN_THREADS, MAX_THREADS);
    export_type = cmd.args["export-type"].value().stringValToEnum!FileType;
    export_file = cmd.args["export-file"].value_or(null);
    select_mode = cmd.args["select"].value_or(null).stringValToEnum!SelectMode(null);
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

    worker = new GroupsHasher(groups, worker_count);

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

        ExportSettings settings; // TODO: Implement settings through the CLI.
        export_results(export_file, export_type, collisions, settings);
    }

    // -------------------------------------------------
    // DELETE

    if (wanna_delete)
    {
        writeln(select_mode);
        // TODO: Which files to remove?
        // TODO: Use threads like in the GUI
    }
}
