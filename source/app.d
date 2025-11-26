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
	string[][] collisions = hash_groups(groups);
	writeln("Found ", collisions.length, " collisions");

	foreach (coll; collisions)
	{
		writeln(coll);
	}
}
