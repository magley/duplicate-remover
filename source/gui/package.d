module gui;

import vendor.iup;

import finder;
import hasher;

void main_gui()
{
    IupOpen(null, null);

    Ihandle* dlg;
    dlg = IupDialog(IupVbox(IupLabel("Hello world from IUP."), null));
    IupSetAttribute(dlg, "TITLE", "Hello World 2");
    IupSetAttribute(dlg, "SIZE", "300x150");

    IupShowXY(dlg, IUP_CENTER, IUP_CENTER);
    IupMainLoop();
    IupClose();
}
