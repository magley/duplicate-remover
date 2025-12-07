module cli;

import std.stdio;
import std.array;
import std.string;
import std.datetime.stopwatch;

import finder;
import hasher;
import util;

import vendor.clyd;

void main_cli(string[] args)
{
    Command root = new Command("duplicate-remover", "Find and remove duplicate files")
        .arg(Arg.single("dir", "d", "Directory to scan", null))
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

    // -------------------------------------------------

    dir = cmd.args["dir"].value();
    worker_count = 4;

    version (Windows)
    {
        dir = dir.replace("/", "\\");
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
}
