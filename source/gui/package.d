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
import gui.results_canvas;

import util;
import finder;
import hasher;

const int MIN_THREADS = 1;
const int MAX_THREADS = 8;

class ProgramState
{
    // ========== Input =======================================================
    string directory = "";
    int worker_count = 4;

    // ========== Scanner =====================================================

    ScannerThread worker = null;

    // ========== Results =====================================================

    ResultsUI results_ui = null;

    // ========== Deleting ====================================================

    ConfirmDeleteData delete_data = null;
}

class ConfirmDeleteData
{
    bool do_delete;
    bool permanently;
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
    return;
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
    IupSetAttribute(btn_run, "ACTIVE", "NO");
    IupSetCallback(btn_run, "ACTION", &cb_btn_run_clicked);
    IupSetHandle("btn_run", btn_run);

    Ihandle* btn_cancel = IupButton("Cancel", null);
    IupSetAttribute(btn_cancel, "ACTIVE", "NO");
    IupSetStrAttribute(btn_cancel, "IMAGE", "IUP_ActionCancel");
    IupSetCallback(btn_cancel, "ACTION", &cb_btn_cancel_clicked);
    IupSetHandle("btn_cancel", btn_cancel);

    Ihandle* run_progress = IupGauge();
    IupSetAttribute(run_progress, "EXPAND", "YES");
    IupSetAttribute(run_progress, "DASHED", "NO");
    IupSetAttribute(run_progress, "MAX", "100");
    IupSetAttribute(run_progress, "VALUE", "0");
    IupSetHandle("run_progress", run_progress);

    Ihandle* run_hbox = IupHbox(
        btn_run, //btn_cancel,
        run_progress,
        null
    );
    IupSetAttribute(run_hbox, "GAP", "4");
    IupSetAttribute(run_hbox, "EXPAND", "HORIZONTAL");
    IupSetHandle("run_hbox", run_hbox);

    Ihandle* run_time = IupLabel("");
    IupSetAttribute(run_time, "EXPAND", "HORIZONTAL");
    IupSetHandle("run_time", run_time);

    Ihandle* run_container = IupVbox(run_hbox, run_time, null);
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

    Ihandle* quick_select_list = IupList(null);
    // --- Order must match the order defined in ResultsUI.QuickSelect ---
    IupSetStrAttribute(quick_select_list, "1", "All but largest");
    IupSetStrAttribute(quick_select_list, "2", "All but smallest");
    IupSetStrAttribute(quick_select_list, "3", "Only largest");
    IupSetStrAttribute(quick_select_list, "4", "Only smallest");
    IupSetStrAttribute(quick_select_list, "5", "All");
    IupSetStrAttribute(quick_select_list, "6", "None");
    IupSetStrAttribute(quick_select_list, "7", null);
    IupSetAttribute(quick_select_list, "DROPDOWN", "YES");
    IupSetAttribute(quick_select_list, "VALUE", "1");
    IupSetHandle("quick_select_list", quick_select_list);

    Ihandle* quick_select_lbl = IupLabel("Select:");

    Ihandle* quick_select_btn = iup_button("Go", "IUP_MediaPlay", null, "quick_select_btn", &cb_btn_quick_select);

    Ihandle* results_toolbar = IupHbox(
        iup_button(null, "IUP_ToolsSortAscend", "Sort by ID", "res_sort_id", &cb_btn_sort_results_id),
        iup_button(null, "IUP_FileProperties", "Sort by size", "res_sort_size", &cb_btn_sort_results_size),
        iup_button(null, "IUP_EditCopy", "Sort by file count", "res_sort_file_count", &cb_btn_sort_results_file_count),
        IupSetAttributes(IupLabel(null), "SEPARATOR=VERTICAL"),
        quick_select_lbl,
        quick_select_list,
        quick_select_btn,
        null
    );
    IupSetAttribute(results_toolbar, "EXPAND", "HORIZONTAL");
    IupSetAttribute(results_toolbar, "GAP", "4");
    IupSetHandle("results_toolbar", results_toolbar);

    Ihandle* results_canvas = create_results_canvas("results_canvas");
    IupSetCallback(results_canvas, "POSTMESSAGE_CB", cast(Icallback)&cb_results_canvas_msg);

    Ihandle* results_container = IupVbox(
        res_groups_lbl,
        res_filecnt_lbl,
        result_btn_box,
        results_toolbar,
        results_canvas,
        null
    );
    IupSetHandle("results_container", results_container);

    Ihandle* results_frame = IupFrame(results_container);
    IupSetHandle("results_frame", results_frame);
    IupSetAttribute(results_frame, "TITLE", "Results");
    IupSetAttribute(results_frame, "SUNKEN", "YES");
    IupSetAttribute(results_frame, "ACTIVE", "NO");

    // ========================================================================
    // Main
    // ========================================================================

    Ihandle* main_vbox = IupVbox(setup_frame, runner_frame, results_frame, null);
    IupSetHandle("main_vbox", main_vbox);

    Ihandle* main_dlg = IupDialog(main_vbox);
    IupSetAttribute(main_dlg, "TITLE", "Duplicate Remover");
    IupSetAttribute(main_dlg, "MINSIZE", "400x500");
    IupSetAttribute(main_dlg, "MARGIN", "3x3");
    IupSetHandle("main", main_dlg);

    IupShowXY(main_dlg, IUP_CENTER, IUP_CENTER);

    IupSetAttribute(main_dlg, "RASTERSIZE", "400x500");
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
            IupSetAttribute(IupGetHandle("btn_run"), "ACTIVE", "YES");
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
    P.worker = new ScannerThread(P.directory, P.worker_count);
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
    string[] selected_files = [];

    if (P.results_ui !is null)
    {
        selected_files = P.results_ui.get_checked_files();
    }

    ulong file_count = selected_files.length;
    ulong file_size = 0;
    foreach (string f; selected_files)
    {
        file_size += getSize(safepath(f));
    }

    confirm_delete_dialog(file_count, file_size);
    assert(P.delete_data !is null);

    if (!P.delete_data.do_delete)
        return IUP_DEFAULT;

    delete_selected_files(
        selected_files,
        !P.delete_data.permanently,
        P.worker_count
    );

    return IUP_DEFAULT;
}

private void confirm_delete_dialog(ulong file_count, ulong bytes_to_remove)
{
    string warning_message = format(
        "This will delete %d files (%s) from your disk.\nProceed?",
        file_count,
        to_size_byte_unit(bytes_to_remove)
    );

    P.delete_data = new ConfirmDeleteData();

    Ihandle* msg = IupLabel(warning_message.toStringz());
    Ihandle* checkbox = IupToggle("Delete permanently", null);
    IupSetCallback(checkbox, "ACTION", &cb_confirm_delete_dialog_permanently_check);
    Ihandle* btn_yes = IupButton("Delete", null);
    IupSetAttribute(btn_yes, "PADDING", "11x5");
    IupSetAttribute(btn_yes, "IMAGE", "IUP_EditErase");
    IupSetCallback(btn_yes, "ACTION", &cb_confirm_delete_dialog_delete);
    Ihandle* btn_no = IupButton("Cancel", null);
    IupSetAttribute(btn_no, "PADDING", "11x5");
    IupSetAttribute(btn_no, "IMAGE", "IUP_EditUndo");
    IupSetCallback(btn_no, "ACTION", &cb_confirm_delete_dialog_cancel);
    Ihandle* buttons = IupHbox(btn_yes, IupFill(), btn_no, null);
    IupSetAttribute(buttons, "MARGIN", "11x0");

    Ihandle* contain = IupVbox(msg, checkbox, IupFill(), buttons, null);
    IupSetAttribute(contain, "EXPAND", "YES");
    IupSetAttribute(contain, "GAP", "8");
    Ihandle* dlg = IupDialog(contain);

    IupSetAttribute(dlg, "TITLE", "Delete files");
    IupSetAttribute(dlg, "SIMULATEMODAL", "YES");
    IupSetAttribute(dlg, "MINSIZE", "300x150");
    IupSetAttribute(dlg, "MARGIN", "11x8");
    IupSetAttribute(dlg, "RESIZE", "NO");

    IupPopup(dlg, IUP_CURRENT, IUP_CURRENT);
    IupDestroy(dlg);
}

extern (C) int cb_confirm_delete_dialog_delete(Ihandle* self)
{
    P.delete_data.do_delete = true;
    return IUP_CLOSE;
}

extern (C) int cb_confirm_delete_dialog_cancel(Ihandle* self)
{
    P.delete_data.do_delete = false;
    return IUP_CLOSE;
}

extern (C) int cb_confirm_delete_dialog_permanently_check(Ihandle* self)
{
    P.delete_data.permanently = IupGetAttribute(self, "VALUE").to!string == "ON";
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

class ScannerThread : Thread
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
        IupSetAttribute(IupGetHandle("setup_frame"), "ACTIVE", "NO");
        IupSetAttribute(IupGetHandle("results_frame"), "ACTIVE", "NO");
        IupSetAttribute(IupGetHandle("btn_run"), "ACTIVE", "NO");
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

        IupSetAttribute(IupGetHandle("setup_frame"), "ACTIVE", "YES");
        IupSetAttribute(IupGetHandle("results_frame"), "ACTIVE", "YES");
        IupSetAttribute(IupGetHandle("btn_run"), "ACTIVE", "YES");
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

        // Calls: cb_results_canvas_msg()
        IupPostMessage(IupGetHandle("results_canvas"), null, 0, 0.0, null);
    }
}

/// Called when scanning finishes, to update the results UI.
extern (C) int cb_results_canvas_msg(Ihandle*, const char*, int, double, void*)
{
    if (P.results_ui is null)
        P.results_ui = new ResultsUI();

    P.results_ui.update(P.worker.collisions);
    P.results_ui.quick_select(ResultsUI.QuickSelect.AllButLargest);
    return IUP_DEFAULT;
}

class ProgressThread : Thread
{
    GroupsHasher worker;
    ScannerThread context;

    this(ScannerThread context, GroupsHasher worker)
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

extern (C) int cb_btn_sort_results_id(Ihandle* self)
{
    sort_results(ResultsUI.SortType.Id);
    return IUP_DEFAULT;
}

extern (C) int cb_btn_sort_results_size(Ihandle* self)
{
    sort_results(ResultsUI.SortType.Size);
    return IUP_DEFAULT;
}

extern (C) int cb_btn_sort_results_file_count(Ihandle* self)
{
    sort_results(ResultsUI.SortType.FileCount);
    return IUP_DEFAULT;
}

private void sort_results(ResultsUI.SortType t)
{
    if (P is null || P.results_ui is null)
    {
        return;
    }

    P.results_ui.sort_by(t, !P.results_ui.sort_ascending);
}

extern (C) int cb_btn_quick_select(Ihandle* self)
{
    if (P is null || P.results_ui is null)
    {
        return IUP_DEFAULT;
    }

    Ihandle* quick_select_list = IupGetHandle("quick_select_list");
    int i = IupGetInt(quick_select_list, "VALUE") - 1;
    ResultsUI.QuickSelect select_mode = cast(ResultsUI.QuickSelect) i;

    P.results_ui.quick_select(select_mode);

    return IUP_DEFAULT;
}

private Ihandle* iup_button(string text, string image, string tip, string handle, Icallback callback)
{
    Ihandle* h = IupButton(text is null ? null : text.toStringz(), null);
    IupSetStrAttribute(h, "IMAGE", image is null ? null : image.toStringz());
    IupSetStrAttribute(h, "TIP", tip is null ? null : tip.toStringz());
    IupSetCallback(h, "ACTION", callback);
    IupSetHandle(handle.toStringz(), h);
    return h;
}
