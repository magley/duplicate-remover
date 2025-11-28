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

    Ihandle* main_vbox = IupVbox(dir_pick_container, null);
    IupSetHandle("main_vbox", main_vbox);

    Ihandle* main_dlg = IupDialog(main_vbox);
    IupSetAttribute(main_dlg, "TITLE", "Duplicate Remover");
    IupSetAttribute(main_dlg, "MINSIZE", "200x125");
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

        P.directory = to!string(dir_cstr);

        Ihandle* dir_pick_label = IupGetHandle("dir_pick_label");
        IupSetAttribute(dir_pick_label, "VALUE", dir_cstr);
    }
    IupDestroy(file_dlg);

    return IUP_DEFAULT;
}
