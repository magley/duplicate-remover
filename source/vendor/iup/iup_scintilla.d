module vendor.iup.iup_scintilla;

import vendor.iup;

extern (C)
{
    void IupScintillaOpen();
    Ihandle* IupScintilla();
    Ihandle* IupScintillaDlg();
    void* IupScintillaSendMessage(Ihandle* ih, uint iMessage, void* wParam, void* lParam);
}
