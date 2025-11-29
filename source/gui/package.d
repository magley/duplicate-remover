module gui;

import std.stdio;
import std.conv;
import std.string;
import std.datetime.stopwatch;
import core.thread.osthread;
import std.algorithm;

import vendor.iup;

import finder;
import hasher;

const int MIN_THREADS = 1;
const int MAX_THREADS = 8;

class ProgramState
{
    string directory = "";
    int worker_count = 4;
    FinderAndRemoverThread worker = null;
}

ProgramState P;

void main_gui()
{
    P = new ProgramState();

    IupOpen(null, null);

    Ihandle* dir_pick_label = IupText(null);
    IupSetAttribute(dir_pick_label, "ACTIVE", "NO");
    IupSetAttribute(dir_pick_label, "EXPAND", "HORIZONTAL");
    IupSetHandle("dir_pick_label", dir_pick_label);

    Ihandle* dir_pick_btn = IupButton("Select...", null);
    IupSetCallback(dir_pick_btn, "ACTION", &cb_open_directory_picker_dialog);
    IupSetHandle("dir_pick_btn", dir_pick_btn);

    Ihandle* dir_pick_container = IupHbox(dir_pick_label, dir_pick_btn, null);
    IupSetHandle("dir_pick_container", dir_pick_container);

    Ihandle* dir_info_label = IupLabel("Open a directory to get started");
    IupSetHandle("dir_info_label", dir_info_label);
    IupSetAttribute(dir_info_label, "EXPAND", "HORIZONTAL");

    Ihandle* params_workern_label = IupLabel("Threads:");
    IupSetHandle("params_workern_label", params_workern_label);

    Ihandle* params_workern_text = IupText(null);
    IupSetHandle("params_workern_text", params_workern_text);
    IupSetCallback(params_workern_text, "SPIN_CB", cast(Icallback)&cb_params_workern_spinner_changed);
    IupSetCallback(params_workern_text, "VALUECHANGED_CB", &cb_params_workern_value_changed);
    IupSetAttribute(params_workern_text, "FILTER", "NUMBER ");
    IupSetAttribute(params_workern_text, "SPIN", "YES");
    IupSetAttribute(params_workern_text, "SPINVALUE", "4");
    IupSetAttribute(params_workern_text, "SPINMIN", to!string(MIN_THREADS).toStringz);
    IupSetAttribute(params_workern_text, "SPINMAX", to!string(MAX_THREADS).toStringz);

    Ihandle* params_hbox = IupHbox(params_workern_label, params_workern_text, null);
    IupSetHandle("params_hbox", params_hbox);
    IupSetAttribute(params_hbox, "GAP", "50");

    Ihandle* setup_vbox = IupVbox(dir_pick_container, dir_info_label, params_hbox);
    IupSetHandle("setup_vbox", setup_vbox);

    Ihandle* setup_frame = IupFrame(setup_vbox);
    IupSetHandle("setup_frame", setup_frame);
    IupSetAttribute(setup_frame, "TITLE", "Configuration");
    IupSetAttribute(setup_frame, "SUNKEN", "YES");

    Ihandle* btn_run = IupButton("Begin", null);
    IupSetAttribute(btn_run, "PADDING", "12x5");
    IupSetCallback(btn_run, "ACTION", &cb_btn_run_clicked);
    IupSetHandle("btn_run", btn_run);

    Ihandle* run_progress = IupProgressBar();
    IupSetAttribute(run_progress, "EXPAND", "HORIZONTAL");
    IupSetAttribute(run_progress, "DASHED", "NO");
    IupSetAttribute(run_progress, "MAX", "100");
    IupSetAttribute(run_progress, "VALUE", "0");
    IupSetHandle("run_progress", run_progress);

    Ihandle* run_time = IupLabel("");
    IupSetAttribute(run_time, "EXPAND", "HORIZONTAL");
    IupSetHandle("run_time", run_time);

    Ihandle* run_container = IupVbox(btn_run, run_progress, run_time, null);
    IupSetHandle("run_container", run_container);

    Ihandle* main_vbox = IupVbox(setup_frame, run_container, null);
    IupSetHandle("main_vbox", main_vbox);

    Ihandle* main_dlg = IupDialog(main_vbox);
    IupSetAttribute(main_dlg, "TITLE", "Duplicate Remover");
    IupSetAttribute(main_dlg, "MINSIZE", "200x200");
    IupSetAttribute(main_dlg, "MARGIN", "3x3");
    IupSetHandle("main", main_dlg);

    IupShowXY(main_dlg, IUP_CENTER, IUP_CENTER);

    IupSetAttribute(main_dlg, "RASTERSIZE", "300x300");
    IupRefresh(main_dlg);
    IupSetAttribute(main_dlg, "RASTERSIZE", null);

    IupMainLoop();
    IupClose();
}

extern (C) int cb_open_directory_picker_dialog(Ihandle* self)
{
    Ihandle* file_dlg = IupFileDlg();

    IupSetAttribute(file_dlg, "DIALOGTYPE", "DIR");
    IupSetStrAttribute(file_dlg, "DIRECTORY", P.directory.toStringz());
    IupSetAttribute(file_dlg, "TITLE", "Open Directory");

    IupPopup(file_dlg, IUP_CURRENT, IUP_CURRENT);

    if (IupGetInt(file_dlg, "STATUS") != -1)
    {
        const char* dir_cstr = IupGetAttribute(file_dlg, "VALUE");

        // Update program state
        P.directory = to!string(dir_cstr);

        // Show opened directory
        Ihandle* dir_pick_label = IupGetHandle("dir_pick_label");
        IupSetStrAttribute(dir_pick_label, "VALUE", dir_cstr);

        // Show directory info
        {
            import std.file;
            import std.format;

            DirectoryInfo dirinfo = get_directory_info(P.directory);
            string dir_info = format(
                "Size: %s, Files: %d, Folders: %d",
                to_size_byte_unit(dirinfo.size),
                dirinfo.files,
                dirinfo.folders
            );
            IupSetStrAttribute(IupGetHandle("dir_info_label"), "TITLE", dir_info.toStringz());
        }
    }
    IupDestroy(file_dlg);

    return IUP_DEFAULT;
}

struct DirectoryInfo
{
    ulong size = 0;
    ulong folders = 0;
    ulong files = 0;
}

DirectoryInfo get_directory_info(string dir)
{
    import std.file;
    import std.stdio;

    DirectoryInfo result;

    string[] queue = [dir];
    while (queue.length > 0)
    {
        string d = queue[0];
        queue = queue[1 .. $];

        foreach (DirEntry e; dirEntries(d, SpanMode.shallow))
        {
            if (e.isFile())
            {
                result.size += e.size;
                result.files++;
            }
            else if (e.isDir())
            {
                queue ~= e.name;
                result.folders++;
            }
        }
    }

    return result;
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

extern (C) int cb_params_workern_spinner_changed(Ihandle* self, int newval)
{
    P.worker_count = newval;
    return IUP_DEFAULT;
}

extern (C) int cb_params_workern_value_changed(Ihandle* self)
{
    try
    {
        string v = to!string(IupGetAttribute(self, "VALUE"));
        uint val = parse!uint(v);
        val = min(MAX_THREADS, max(val, MIN_THREADS));
        P.worker_count = val;
    }
    catch (ConvException)
    {
        // Do nothing, keep P.worker_count
    }

    IupSetStrAttribute(self, "VALUE", to!string(P.worker_count).toStringz);

    return IUP_DEFAULT;
}

extern (C) int cb_btn_run_clicked(Ihandle* self)
{
    P.worker = new FinderAndRemoverThread(P.directory, P.worker_count);
    P.worker.start();
    return IUP_DEFAULT;
}

class FinderAndRemoverThread : Thread
{
    // Input
    string dir;
    int worker_count;

    // Results
    string[][] groups;
    string[][] collisions;

    // Timing
    StopWatch sw;
    long scan_time_ms = 0;
    long collision_time_ms = 0;
    long total_time_ms() => scan_time_ms + collision_time_ms;

    // State
    GroupsHasher worker;
    ProgressThread progress;

    this(string directory, int worker_count)
    {
        this.dir = directory;
        this.worker_count = worker_count;
        this.isDaemon(true);
        super(&run);
    }

    private void run()
    {
        IupSetAttribute(IupGetHandle("dir_pick_btn"), "ACTIVE", "NO");
        IupSetAttribute(IupGetHandle("params_workern_text"), "ACTIVE", "NO");
        IupSetAttribute(IupGetHandle("btn_run"), "ACTIVE", "NO");
        IupSetStrAttribute(IupGetHandle("run_progress"), "VALUE", "0");

        sw.start();

        groups = group_files(dir);
        scan_time_ms = sw.peek().total!"msecs"();
        sw.reset();

        worker = new GroupsHasher(groups, worker_count);
        progress = new ProgressThread(this, worker);

        progress.start();
        worker.run();

        collisions = worker.collisions;

        progress.join();

        collision_time_ms = sw.peek().total!"msecs"();
        sw.reset();

        IupSetAttribute(IupGetHandle("dir_pick_btn"), "ACTIVE", "YES");
        IupSetAttribute(IupGetHandle("params_workern_text"), "ACTIVE", "YES");
        IupSetAttribute(IupGetHandle("btn_run"), "ACTIVE", "YES");
        IupSetStrAttribute(IupGetHandle("run_progress"), "VALUE", "100");
        IupSetStrAttribute(IupGetHandle("run_time"), "TITLE", format("Time: %ds", time_to_string(
                total_time_ms)).toStringz());

        finish();
    }

    private void finish()
    {
        uint conflicing_files = 0;
        foreach (c; collisions)
        {
            foreach (f; c)
                conflicing_files++;
        }

        // writeln("Found ", collisions.length, " collision groups with ", conflicing_files, " colliding files in total");
        writeln("Total time: ", total_time_ms(), "ms (", total_time_ms() / 1000.0, "s)");
    }
}

class ProgressThread : Thread
{
    GroupsHasher worker;
    FinderAndRemoverThread context;

    this(FinderAndRemoverThread context, GroupsHasher worker)
    {
        this.context = context;
        this.worker = worker;
        this.isDaemon(true);
        super(&run);
    }

    void run()
    {
        Ihandle* run_progress = IupGetHandle("run_progress");
        int max = 100;

        while (!worker.finished)
        {
            Thread.sleep(dur!("msecs")(100));
            float p = worker.get_progress();

            int new_val = cast(int)(max * p);
            IupSetStrAttribute(run_progress, "VALUE", to!string(new_val).toStringz());

            ulong t_msecs = context.sw.peek().total!"msecs"();
            IupSetStrAttribute(IupGetHandle("run_time"), "TITLE", time_to_string(t_msecs).toStringz());
        }

        ulong t_msecs = context.sw.peek().total!"msecs"();
        IupSetStrAttribute(IupGetHandle("run_time"), "TITLE", time_to_string(t_msecs).toStringz());
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
