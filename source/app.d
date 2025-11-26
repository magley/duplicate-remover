import std.stdio;
import std.array;
import std.string;

import finder;

void main()
{
	writeln("Enter directory:");
	string dir = readln().strip().replace("\\", "/");

	string[][] groups = group_files(dir);

	writeln("Found ", groups.length, " groups");
}
