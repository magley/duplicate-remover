import std.stdio;
import std.array;
import std.string;

import finder;
import hasher;

void main()
{
	writeln("Enter directory:");
	string dir = readln().strip().replace("\\", "/");

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

	writeln("Found ", collisions.length, " collision groups with ", conflicing_files, " colliding files in total");
}
