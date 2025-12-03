module gui;

import std.stdio;
import std.conv;
import std.string;
import std.datetime.stopwatch;
import std.file;
import std.path;
import std.algorithm;
import core.thread.osthread;

import vendor.iup;

import gui.exporter;

import util;
import finder;
import hasher;

const int MIN_THREADS = 1;
const int MAX_THREADS = 8;

class ProgramState
{
    string directory = "";
    int worker_count = 4;
    FinderAndRemoverThread worker = null;

    string[] files_selected = [];
}

ProgramState P;

extern (C) int on_results_list_add_items(Ihandle* ih, char* s, int i, double d, void* p)
{
    add_items(P.worker.collisions);
    return IUP_DEFAULT;
}

extern (C) int cb_on_export_btn_clicked(Ihandle* self)
{
    open_export_dialog();
    return IUP_DEFAULT;
}

void add_items(string[][] collisions)
{
    Ihandle* list = IupGetHandle("results_list");

    // 1 Delete old items.

    int child_count = IupGetChildCount(list);
    for (int i = child_count - 1; i >= 0; i--)
    {
        Ihandle* c = IupGetChild(list, i);
        IupDetach(c);
        IupDestroy(c);
    }

    // 2 Append new items.

    P.files_selected = [];
    foreach (size_t i, string[] group; collisions)
    {
        Ihandle*[] children;

        foreach (size_t j, string file; group)
        {
            const ulong size = getSize(safepath(file));
            const string size_str = to_size_byte_unit(size);
            const string path_rel = relativePath(file, P.directory);
            const string label = format("(%s) %s", size_str, path_rel);

            Ihandle* checkbox = IupToggle(label.toStringz(), null);
            IupSetAttribute(checkbox, "EXPAND", "HORIZONTAL");
            if (j == 0)
            {
                P.files_selected ~= file;
                IupSetAttribute(checkbox, "VALUE", "ON");
            }

            Ihandle* item = IupHbox(checkbox, null);
            IupSetAttribute(item, "EXPAND", "HORIZONTAL");

            children ~= item;
        }

        children ~= null;
        Ihandle* vbox = IupVboxv(children.ptr);
        IupSetAttribute(vbox, "EXPAND", "HORIZONTAL");

        Ihandle* frame = IupFrame(vbox);
        IupSetStrAttribute(frame, "TITLE", format("Group #%d", i + 1).toStringz());
        IupSetAttribute(frame, "EXPAND", "HORIZONTAL");

        IupAppend(list, frame);
        IupMap(frame);
    }

    IupRefresh(list);
}

void main_gui()
{
    P = new ProgramState();

    IupOpen(null, null);
    IupImageLibOpen();
    IupControlsOpen();

    // ========================================================================
    // Configure
    // ========================================================================

    Ihandle* dir_pick_label = IupText(null);
    IupSetAttribute(dir_pick_label, "ACTIVE", "NO");
    IupSetAttribute(dir_pick_label, "EXPAND", "YES");
    IupSetHandle("dir_pick_label", dir_pick_label);

    Ihandle* dir_pick_btn = IupButton("", null);
    IupSetCallback(dir_pick_btn, "ACTION", &cb_open_directory_picker_dialog);
    IupSetStrAttribute(dir_pick_btn, "IMAGE", "IUP_FileOpen");
    IupSetHandle("dir_pick_btn", dir_pick_btn);

    Ihandle* dir_pick_container = IupHbox(dir_pick_label, dir_pick_btn, null);
    IupSetAttribute(dir_pick_container, "EXPAND", "HORIZONTAL");
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

    // ========================================================================
    // Run
    // ========================================================================

    Ihandle* btn_run = IupButton("Begin", null);
    IupSetStrAttribute(btn_run, "IMAGE", "IUP_ActionOk");
    IupSetCallback(btn_run, "ACTION", &cb_btn_run_clicked);
    IupSetHandle("btn_run", btn_run);

    Ihandle* btn_cancel = IupButton("Cancel", null);
    IupSetAttribute(btn_cancel, "ACTIVE", "NO");
    IupSetStrAttribute(btn_cancel, "IMAGE", "IUP_ActionCancel");
    IupSetCallback(btn_cancel, "ACTION", &cb_btn_cancel_clicked);
    IupSetHandle("btn_cancel", btn_cancel);

    Ihandle* run_hbox = IupHbox(
        btn_run, //btn_cancel,
        null
    );
    IupSetHandle("run_hbox", run_hbox);

    Ihandle* run_progress = IupGauge();
    IupSetAttribute(run_progress, "EXPAND", "HORIZONTAL");
    IupSetAttribute(run_progress, "DASHED", "NO");
    IupSetAttribute(run_progress, "MAX", "100");
    IupSetAttribute(run_progress, "VALUE", "0");
    IupSetHandle("run_progress", run_progress);

    Ihandle* run_time = IupLabel("");
    IupSetAttribute(run_time, "EXPAND", "HORIZONTAL");
    IupSetHandle("run_time", run_time);

    Ihandle* run_container = IupVbox(run_hbox, run_progress, run_time, null);
    IupSetHandle("run_container", run_container);

    Ihandle* runner_frame = IupFrame(run_container);
    IupSetHandle("runner_frame", runner_frame);
    IupSetAttribute(runner_frame, "TITLE", "Run");
    IupSetAttribute(runner_frame, "SUNKEN", "YES");

    // ========================================================================
    // Results
    // ========================================================================

    Ihandle* res_groups_lbl = IupLabel("Collision groups:");
    IupSetAttribute(res_groups_lbl, "EXPAND", "HORIZONTAL");
    IupSetHandle("res_groups_lbl", res_groups_lbl);

    Ihandle* res_filecnt_lbl = IupLabel("Conflicting files:");
    IupSetAttribute(res_filecnt_lbl, "EXPAND", "HORIZONTAL");
    IupSetHandle("res_filecnt_lbl", res_filecnt_lbl);

    Ihandle* export_btn = IupButton("Export...", null);
    IupSetCallback(export_btn, "ACTION", &cb_on_export_btn_clicked);
    IupSetAttribute(export_btn, "IMAGE", "IUP_EditCopy");

    Ihandle* delete_btn = IupButton("Delete", null);
    IupSetCallback(delete_btn, "ACTION", &cb_on_delete_btn_clicked);
    IupSetAttribute(delete_btn, "IMAGE", "IUP_EditErase");

    Ihandle* result_btn_box = IupHbox(export_btn, delete_btn, null);
    IupSetAttribute(result_btn_box, "EXPAND", "HORIZONTAL");
    IupSetHandle("result_btn_box", result_btn_box);

    Ihandle* results_list = IupVbox(null);
    IupSetAttribute(results_list, "EXPAND", "HORIZONTAL");
    IupSetHandle("results_list", results_list);
    IupSetCallback(results_list, "POSTMESSAGE_CB", cast(Icallback)&on_results_list_add_items);

    Ihandle* results_list_scroll = IupScrollBox(results_list);

    Ihandle* results_container = IupVbox(res_groups_lbl, res_filecnt_lbl, result_btn_box, results_list_scroll, null);
    IupSetHandle("results_container", results_container);

    Ihandle* results_frame = IupFrame(results_container);
    IupSetHandle("results_frame", results_frame);
    IupSetAttribute(results_frame, "TITLE", "Results");
    IupSetAttribute(results_frame, "SUNKEN", "YES");

    // ========================================================================
    // Main
    // ========================================================================

    Ihandle* main_vbox = IupVbox(setup_frame, runner_frame, results_frame, null);
    IupSetHandle("main_vbox", main_vbox);

    Ihandle* main_dlg = IupDialog(main_vbox);
    IupSetAttribute(main_dlg, "TITLE", "Duplicate Remover");
    IupSetAttribute(main_dlg, "MINSIZE", "400x400");
    IupSetAttribute(main_dlg, "MARGIN", "3x3");
    IupSetHandle("main", main_dlg);

    IupShowXY(main_dlg, IUP_CENTER, IUP_CENTER);

    IupSetAttribute(main_dlg, "RASTERSIZE", "400x400");
    IupRefresh(main_dlg);
    IupSetAttribute(main_dlg, "RASTERSIZE", null);

    IupRefresh(results_list);

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

extern (C) int cb_btn_cancel_clicked(Ihandle* self)
{
    if (P.worker !is null)
    {
        //
    }
    return IUP_DEFAULT;
}

extern (C) int cb_on_delete_btn_clicked(Ihandle* self)
{
    ulong file_count = P.files_selected.length;
    ulong file_size = 0;
    foreach (string f; P.files_selected)
    {
        file_size += getSize(safepath(f));
    }

    string warning_message = format(
        "This will delete %d files (%s) from your disk.\nProceed?",
        file_count,
        to_size_byte_unit(file_size)
    );

    Ihandle* dlg = IupMessageDlg();
    IupSetAttribute(dlg, "DIALOGTYPE", "WARNING");
    IupSetAttribute(dlg, "TITLE", "Delete files");
    IupSetAttribute(dlg, "BUTTONS", "OKCANCEL");
    IupSetStrAttribute(dlg, "VALUE", warning_message.toStringz());
    IupPopup(dlg, IUP_CURRENT, IUP_CURRENT);
    bool clicked_ok = to!string(IupGetAttribute(dlg, "BUTTONRESPONSE")) == "1";

    if (clicked_ok)
    {
        delete_selected_files(P.files_selected, true, P.worker_count);
    }

    IupDestroy(dlg);

    return IUP_DEFAULT;
}

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
        IupSetAttribute(IupGetHandle("btn_cancel"), "ACTIVE", "YES");
        IupSetStrAttribute(IupGetHandle("run_progress"), "VALUE", "0");
        IupSetStrAttribute(IupGetHandle("run_time"), "TITLE", "");
        IupSetStrAttribute(IupGetHandle("res_groups_lbl"), "TITLE", "Collision groups:");
        IupSetStrAttribute(IupGetHandle("res_filecnt_lbl"), "TITLE", "Conflicting files:");

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

        uint conflicing_files = 0;
        foreach (c; collisions)
        {
            foreach (f; c)
                conflicing_files++;
        }

        IupSetAttribute(IupGetHandle("dir_pick_btn"), "ACTIVE", "YES");
        IupSetAttribute(IupGetHandle("params_workern_text"), "ACTIVE", "YES");
        IupSetAttribute(IupGetHandle("btn_run"), "ACTIVE", "YES");
        IupSetAttribute(IupGetHandle("btn_cancel"), "ACTIVE", "NO");
        IupSetStrAttribute(IupGetHandle("run_progress"), "VALUE", "100");
        IupSetStrAttribute(IupGetHandle("run_time"), "TITLE",
            format("Time: %s", time_to_string(total_time_ms)).toStringz()
        );
        IupSetStrAttribute(IupGetHandle("res_groups_lbl"), "TITLE",
            format("Collision groups: %d", collisions.length).toStringz()
        );
        IupSetStrAttribute(IupGetHandle("res_filecnt_lbl"), "TITLE",
            format("Conflicting files: %d", conflicing_files).toStringz()
        );

        IupPostMessage(IupGetHandle("results_list"), null, 0, 0.0, null);
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
            IupSetStrAttribute(
                IupGetHandle("run_time"),
                "TITLE",
                ("Time: " ~ time_to_string(t_msecs)).toStringz()
            );
        }

        ulong t_msecs = context.sw.peek().total!"msecs"();
        IupSetStrAttribute(
            IupGetHandle("run_time"),
            "TITLE",
            ("Time: " ~ time_to_string(t_msecs)).toStringz()
        );
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
