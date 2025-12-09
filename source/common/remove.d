module common.remove;

import std.file;
import std.stdio;
import core.thread;
import common;

void delete_selected_files(string[] files, bool move_to_trash, int thread_count)
{
    RemoverThread[] threads;
    string[][] file_groups;
    file_groups.length = thread_count;

    foreach (size_t i, string f; files)
    {
        size_t size_j = i % thread_count;
        file_groups[size_j] ~= f;
    }

    for (int i = 0; i < thread_count; i++)
    {
        auto t = new RemoverThread(file_groups[i], move_to_trash);
        t.start();
        threads ~= t;
    }

    foreach (t; threads)
    {
        t.join();
    }
}

class RemoverThread : Thread
{
    string[] files;
    bool move_to_trash;

    this(string[] files, bool move_to_trash)
    {
        this.files = files;
        this.move_to_trash = move_to_trash;
        super(&run);
    }

    void run()
    {
        foreach (string f; files)
        {
            try
            {
                if (move_to_trash)
                {
                    moveToTrash(f);
                }
                else
                {
                    std.file.remove(safepath(f));
                }
            }
            catch (Exception e)
            {
                writeln(e);
            }
        }
    }
}
