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

enum DeleteStrategy
{
    MoveToTrash = "trash",
    DeleteForever = "remove"
}

private string[] modes = [EnumMembers!FileType];
private string[] delete_modes = [EnumMembers!DeleteStrategy, null];

void main_cli(string[] args)
{
    Command root = new Command("duplicate-remover", "Find and remove duplicate files")
        .arg(Arg.single("dir", "d", "Directory to scan", null))
        .arg(Arg.single("workers", "w", "Number of workers", "4"))
        .arg(Arg.single("export-type", null, "Type of export", "JSON", modes))
        .arg(Arg.single("export-file", null, "Export desination", ""))
        .arg(Arg.single("delete", "del", "Duplicate removal strategy", null, delete_modes))
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
    DeleteStrategy delete_strategy;

    // -------------------------------------------------
    // COMPUTE ARGUMENTS

    dir = cmd.args["dir"].value();
    worker_count = cmd.args["workers"].integer(MIN_THREADS, MAX_THREADS);
    export_type = cmd.args["export-type"].value().stringValToEnum!FileType;
    export_file = cmd.args["export-file"].value_or(null);
    delete_strategy = cmd.args["delete"].value().stringValToEnum!DeleteStrategy(null);
    if (export_file !is null && strip(export_file).empty())
        export_file = null;

    version (Windows)
    {
        dir = dir.replace("/", "\\");
        if (export_file !is null)
            export_file = export_file.replace("/", "\\");
    }

    if (delete_strategy == null && export_file == null)
    {
        writeln(CERR ~ "You must delete or export the results" ~ CCLEAR);
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

    if (delete_strategy != null)
    {
        writefln("Deleting duplicates using strategy: %s", delete_strategy);
        // TODO: Which files to remove?
        // TODO: Use threads like in the GUI
    }
}
