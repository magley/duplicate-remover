import std.stdio;
import std.array;
import std.string;
import std.datetime.stopwatch;

import finder;
import hasher;

void main()
{
	writeln("Enter directory:");
	string dir = readln().strip().replace("\\", "/");

	StopWatch sw;
	sw.start();

	writeln("Scanning directory...");
	string[][] groups = group_files(dir);
	writeln("Found ", groups.length, " groups");

	writeln("Computing collisions...");
	string[][] collisions = hash_groups_parallel(groups, 4);
	uint conflicing_files = 0;
	foreach (c; collisions)
	{
		foreach (f; c)
			conflicing_files++;
	}

	long exec_ms = sw.peek().total!"msecs"();

	writeln("Found ", collisions.length, " collision groups with ", conflicing_files, " colliding files in total");
	writeln("Total time: ", exec_ms, "ms (", exec_ms / 1000.0, "s)");

}
