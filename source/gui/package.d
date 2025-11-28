module gui;

import std.conv;
import std.string;

import vendor.iup;

import finder;
import hasher;

class ProgramState
{
    string directory = "";
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
    IupSetHandle("dir_pick_btn", dir_pick_label);

    Ihandle* dir_pick_container = IupHbox(dir_pick_label, dir_pick_btn, null);
    IupSetHandle("dir_pick_container", dir_pick_container);

    Ihandle* dir_info_label = IupLabel("Open a directory to get started");
    IupSetHandle("dir_info_label", dir_info_label);
    IupSetAttribute(dir_info_label, "EXPAND", "HORIZONTAL");

    Ihandle* main_vbox = IupVbox(dir_pick_container, dir_info_label, null);
    IupSetHandle("main_vbox", main_vbox);

    Ihandle* main_dlg = IupDialog(main_vbox);
    IupSetAttribute(main_dlg, "TITLE", "Duplicate Remover");
    IupSetAttribute(main_dlg, "MINSIZE", "200x125");
    IupSetAttribute(main_dlg, "MARGIN", "3x3");
    IupSetHandle("main", main_dlg);

    IupShowXY(main_dlg, IUP_CENTER, IUP_CENTER);

    IupSetAttribute(main_dlg, "RASTERSIZE", "300x150");
    IupRefresh(main_dlg);
    IupSetAttribute(main_dlg, "RASTERSIZE", null);

    IupMainLoop();
    IupClose();
}

extern (C) int cb_open_directory_picker_dialog(Ihandle* self)
{
    Ihandle* file_dlg = IupFileDlg();

    IupSetAttribute(file_dlg, "DIALOGTYPE", "DIR");
    IupSetAttribute(file_dlg, "DIRECTORY", P.directory.toStringz());
    IupSetAttribute(file_dlg, "TITLE", "Open Directory");

    IupPopup(file_dlg, IUP_CURRENT, IUP_CURRENT);

    if (IupGetInt(file_dlg, "STATUS") != -1)
    {
        const char* dir_cstr = IupGetAttribute(file_dlg, "VALUE");

        // Update program state
        P.directory = to!string(dir_cstr);

        // Show opened directory
        Ihandle* dir_pick_label = IupGetHandle("dir_pick_label");
        IupSetAttribute(dir_pick_label, "VALUE", dir_cstr);

        // Show directory info
        {
            import std.file;
            import std.format;

            DirectoryInfo dirinfo = get_directory_info(P.directory);
            string info_str = format(
                "Size: %s, Files: %d, Folders: %d",
                to_size_byte_unit(dirinfo.size),
                dirinfo.files,
                dirinfo.folders
            );
            IupSetAttribute(IupGetHandle("dir_info_label"), "TITLE", info_str.toStringz());
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
