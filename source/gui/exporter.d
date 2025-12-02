module gui.exporter;

import std.stdio;
import std.string;
import std.conv;
import vendor.iup;
import gui;
import exporting;
import std.traits;
import util;

private class ExportState
{
    FileType mode = FileType.JSON;
    string[][] collisions = [];
    ExportSettings settings;
}

private ExportState E;

private const(FileType[]) modes = [EnumMembers!FileType];

void open_export_dialog()
{
    if (P is null)
    {
        writeln("Program state is null");
        return;
    }
    if (P.worker is null)
    {
        writeln("Worker is null");
        return;
    }
    E = new ExportState();
    E.collisions = P.worker.collisions;

    Ihandle* lbl_select_format = IupLabel("Export as:");

    Ihandle* modes_list = IupList(null);
    IupSetAttribute(modes_list, "DROPDOWN", "YES");
    IupSetAttribute(modes_list, "EXPAND", "HORIZONTAL");
    IupSetAttribute(modes_list, "VALUE", "1");
    IupSetCallback(modes_list, "VALUECHANGED_CB", &modes_list_VALUECHANGED_CB);
    E.mode = modes[0];
    foreach (size_t i, string mode; modes)
    {
        string k = format("%d", i + 1);
        string v = format(mode);
        IupSetStrAttribute(modes_list, k.toStringz, v.toStringz);
    }

    Ihandle* export_btn = IupButton("Export", null);
    IupSetAttribute(export_btn, "SIZE", "30x20");
    IupSetAttribute(export_btn, "EXPAND", "HORIZONTAL");
    IupSetAttribute(export_btn, "IMAGE", "IUP_EditCopy");
    IupSetAttribute(export_btn, "MARGIN", "5x5");
    IupSetCallback(export_btn, "ACTION", &cb_open_export_save_dialog);

    Ihandle* settins_json = create_gui_settings_json();

    Ihandle* vbox = IupVbox(
        lbl_select_format,
        modes_list,
        settins_json,
        IupFill(),
        export_btn,
        null
    );
    Ihandle* dlg = IupDialog(vbox);

    IupSetAttribute(dlg, "TITLE", "Export results");
    IupSetAttribute(dlg, "SIMULATEMODAL", "YES");
    IupSetAttribute(dlg, "MINSIZE", "300x300");
    IupSetAttribute(dlg, "MARGIN", "3x3");

    IupPopup(dlg, IUP_CENTER, IUP_CENTER);
    IupDestroy(dlg);
}

private Ihandle* create_gui_settings_json()
{
    Ihandle*[] buttons;

    buttons ~= IupToggle("None", null);
    buttons ~= IupToggle("Largest file in each group", null);
    buttons ~= IupToggle("Smallest file in each group", null);
    buttons ~= IupToggle("All expect largest file in each group", null);
    buttons ~= IupToggle("All expect smallest file in each group", null);

    buttons ~= null;
    Ihandle* radio_vbox = IupVboxv(buttons.ptr);
    Ihandle* radio = IupRadio(radio_vbox);
    IupSetHandle("json__include_list_radio", radio);
    Ihandle* settings_vbox = IupVbox(radio, null);
    Ihandle* settings_json = IupFrame(settings_vbox);
    IupSetAttribute(settings_json, "TITLE", "Also include list:");
    IupSetHandle("settings_json", settings_json);
    return settings_json;
}

private int get_radio_index(string radio_handle)
{
    Ihandle* radio = IupGetHandle(radio_handle.toStringz());
    string n = to!string(IupGetAttribute(radio, "VALUE"));
    Ihandle* selected = IupGetHandle(n.toStringz());
    return IupGetChildPos(IupGetChild(radio, 0), selected);
}

private T get_radio_enum(T)(string radio_handle)
{
    return [EnumMembers!T][get_radio_index(radio_handle)];
}

extern (C) int modes_list_VALUECHANGED_CB(Ihandle* self)
{
    string s = to!string(IupGetAttribute(self, "VALUESTRING"));
    try
    {
        FileType val = stringValToEnum!FileType(s);
        E.mode = val;
    }
    catch (Exception e)
    {
        writeln(e);
    }
    return IUP_DEFAULT;
}

extern (C) int cb_open_export_save_dialog(Ihandle* self)
{
    string[2][] filters_arr = get_filters(E.mode);
    string filters = filters_to_filterstring(filters_arr);
    string file_name = format("Untitled.%s", filters_arr[0][0][2 .. $]); // skip '*.'

    Ihandle* dlg = IupFileDlg();

    IupSetStrAttribute(dlg, "DIALOGTYPE", "SAVE");
    IupSetStrAttribute(dlg, "TITLE", "Save to file");
    IupSetStrAttribute(dlg, "EXTFILTER", filters.toStringz());
    IupSetStrAttribute(dlg, "FILE", file_name.toStringz());
    IupPopup(dlg, IUP_CURRENT, IUP_CURRENT);

    if (IupGetInt(dlg, "STATUS") != -1)
    {
        string path = to!string(IupGetAttribute(dlg, "VALUE"));
        do_export(path);
    }

    IupDestroy(dlg);
    return IUP_DEFAULT;
}

private void do_export(string fname)
{
    E.settings.json.quick_include = get_radio_enum!(
        ExportSettings_JSON.QuickInclude
    )("json__include_list_radio");

    export_results(fname, E.mode, E.collisions, E.settings);
}

private string[2][] get_filters(FileType mode)
{
    string[2][] result;

    final switch (mode) with (FileType)
    {
    case JSON:
        result ~= [["*.json", "JSON (*.json)"]];
        break;
    case JSON_Simple:
        result ~= [["*.json", "JSON (*.json)"]];
        break;
    case XML:
        result ~= [["*.xml", "XML (*.xml)"]];
        break;
    case CSV:
        result ~= [["*.csv", "Comma separated values (*.csv)"]];
        break;
    }

    result ~= [["*.*", "All Files (*)"]];
    return result;
}

private string filters_to_filterstring(string[2][] filters)
{
    string result = "";
    foreach (string[2] filter; filters)
    {
        result ~= format("%s|%s|", filter[1], filter[0]);
    }
    return result;
}
