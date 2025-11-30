module vendor.iup;

public import vendor.iup.iupgl;
public import vendor.iup.iup_scintilla;
public import vendor.iup.iupdef;
public import vendor.iup.iupkey;
public import vendor.iup.iupcontrols;

extern (C)
{
    alias Ihandle = void;
    alias Icallback = int function(Ihandle*);

    enum
    {
        IUP_MASK_FLOAT = "[+/-]?(/d+/.?/d*|/./d+)",
        IUP_MASK_UFLOAT = "(/d+/.?/d*|/./d+)",
        IUP_MASK_INT = "[+/-]?/d+",
        IUP_MASK_UINT = "/d+",
    }

    /************************************************************************/
    /*                        Main API                                      */
    /************************************************************************/

    int IupOpen(int* argc, char*** argv);
    void IupClose();
    int IupIsOpened();

    void IupImageLibOpen();

    int IupMainLoop();
    int IupLoopStep();
    int IupLoopStepWait();
    int IupMainLoopLevel();
    void IupFlush();
    void IupExitLoop();
    void IupPostMessage(Ihandle* ih, const char* s, int i, double d, void* p);

    int IupRecordInput(const char* filename, int mode);
    int IupPlayInput(const char* filename);

    void IupUpdate(Ihandle* ih);
    void IupUpdateChildren(Ihandle* ih);
    void IupRedraw(Ihandle* ih, int children);
    void IupRefresh(Ihandle* ih);
    void IupRefreshChildren(Ihandle* ih);

    int IupExecute(const char* filename, const char* parameters);
    int IupExecuteWait(const char* filename, const char* parameters);
    int IupHelp(const char* url);
    void IupLog(const char* type, const char* format, ...);

    char* IupLoad(const char* filename);
    char* IupLoadBuffer(const char* buffer);

    char* IupVersion();
    char* IupVersionDate();
    int IupVersionNumber();
    void IupVersionShow();

    void IupSetLanguage(const char* lng);
    char* IupGetLanguage();
    void IupSetLanguageString(const char* name, const char* str);
    void IupStoreLanguageString(const char* name, const char* str);
    char* IupGetLanguageString(const char* name);
    void IupSetLanguagePack(Ihandle* ih);

    void IupDestroy(Ihandle* ih);
    void IupDetach(Ihandle* child);
    Ihandle* IupAppend(Ihandle* ih, Ihandle* child);
    Ihandle* IupInsert(Ihandle* ih, Ihandle* ref_child, Ihandle* child);
    Ihandle* IupGetChild(Ihandle* ih, int pos);
    int IupGetChildPos(Ihandle* ih, Ihandle* child);
    int IupGetChildCount(Ihandle* ih);
    Ihandle* IupGetNextChild(Ihandle* ih, Ihandle* child);
    Ihandle* IupGetBrother(Ihandle* ih);
    Ihandle* IupGetParent(Ihandle* ih);
    Ihandle* IupGetDialog(Ihandle* ih);
    Ihandle* IupGetDialogChild(Ihandle* ih, const char* name);
    int IupReparent(Ihandle* ih, Ihandle* new_parent, Ihandle* ref_child);

    int IupPopup(Ihandle* ih, int x, int y);
    int IupShow(Ihandle* ih);
    int IupShowXY(Ihandle* ih, int x, int y);
    int IupHide(Ihandle* ih);
    int IupMap(Ihandle* ih);
    void IupUnmap(Ihandle* ih);

    void IupResetAttribute(Ihandle* ih, const char* name);
    int IupGetAllAttributes(Ihandle* ih, char** names, int n);
    void IupCopyAttributes(Ihandle* src_ih, Ihandle* dst_ih);
    Ihandle* IupSetAtt(const char* handle_name, Ihandle* ih, const char* name, ...);
    Ihandle* IupSetAttributes(Ihandle* ih, const char* str);
    char* IupGetAttributes(Ihandle* ih);

    void IupSetAttribute(Ihandle* ih, const char* name, const char* value);
    void IupSetStrAttribute(Ihandle* ih, const char* name, const char* value);
    void IupSetStrf(Ihandle* ih, const char* name, const char* format, ...);
    void IupSetInt(Ihandle* ih, const char* name, int value);
    void IupSetFloat(Ihandle* ih, const char* name, float value);
    void IupSetDouble(Ihandle* ih, const char* name, double value);
    void IupSetRGB(Ihandle* ih, const char* name, ubyte r, ubyte g, ubyte b);
    void IupSetRGBA(Ihandle* ih, const char* name, ubyte r, ubyte g, ubyte b, ubyte a);

    char* IupGetAttribute(Ihandle* ih, const char* name);
    int IupGetInt(Ihandle* ih, const char* name);
    int IupGetInt2(Ihandle* ih, const char* name);
    int IupGetIntInt(Ihandle* ih, const char* name, int* i1, int* i2);
    float IupGetFloat(Ihandle* ih, const char* name);
    double IupGetDouble(Ihandle* ih, const char* name);
    void IupGetRGB(Ihandle* ih, const char* name, ubyte* r, ubyte* g, ubyte* b);
    void IupGetRGBA(Ihandle* ih, const char* name, ubyte* r, ubyte* g, ubyte* b, ubyte* a);

    void IupSetAttributeId(Ihandle* ih, const char* name, int id, const char* value);
    void IupSetStrAttributeId(Ihandle* ih, const char* name, int id, const char* value);
    void IupSetStrfId(Ihandle* ih, const char* name, int id, const char* format, ...);
    void IupSetIntId(Ihandle* ih, const char* name, int id, int value);
    void IupSetFloatId(Ihandle* ih, const char* name, int id, float value);
    void IupSetDoubleId(Ihandle* ih, const char* name, int id, double value);
    void IupSetRGBId(Ihandle* ih, const char* name, int id, ubyte r, ubyte g, ubyte b);

    char* IupGetAttributeId(Ihandle* ih, const char* name, int id);
    int IupGetIntId(Ihandle* ih, const char* name, int id);
    float IupGetFloatId(Ihandle* ih, const char* name, int id);
    double IupGetDoubleId(Ihandle* ih, const char* name, int id);
    void IupGetRGBId(Ihandle* ih, const char* name, int id, ubyte* r, ubyte* g, ubyte* b);

    void IupSetAttributeId2(Ihandle* ih, const char* name, int lin, int col, const char* value);
    void IupSetStrAttributeId2(Ihandle* ih, const char* name, int lin, int col, const char* value);
    void IupSetStrfId2(Ihandle* ih, const char* name, int lin, int col, const char* format, ...);
    void IupSetIntId2(Ihandle* ih, const char* name, int lin, int col, int value);
    void IupSetFloatId2(Ihandle* ih, const char* name, int lin, int col, float value);
    void IupSetDoubleId2(Ihandle* ih, const char* name, int lin, int col, double value);
    void IupSetRGBId2(Ihandle* ih, const char* name, int lin, int col, ubyte r, ubyte g, ubyte b);

    char* IupGetAttributeId2(Ihandle* ih, const char* name, int lin, int col);
    int IupGetIntId2(Ihandle* ih, const char* name, int lin, int col);
    float IupGetFloatId2(Ihandle* ih, const char* name, int lin, int col);
    double IupGetDoubleId2(Ihandle* ih, const char* name, int lin, int col);
    void IupGetRGBId2(Ihandle* ih, const char* name, int lin, int col, ubyte* r, ubyte* g, ubyte* b);

    void IupSetGlobal(const char* name, const char* value);
    void IupSetStrGlobal(const char* name, const char* value);
    char* IupGetGlobal(const char* name);

    Ihandle* IupSetFocus(Ihandle* ih);
    Ihandle* IupGetFocus();
    Ihandle* IupPreviousField(Ihandle* ih);
    Ihandle* IupNextField(Ihandle* ih);

    Icallback IupGetCallback(Ihandle* ih, const char* name);
    Icallback IupSetCallback(Ihandle* ih, const char* name, Icallback func);
    Ihandle* IupSetCallbacks(Ihandle* ih, const char* name, Icallback func, ...);

    Icallback IupGetFunction(const char* name);
    Icallback IupSetFunction(const char* name, Icallback func);

    Ihandle* IupGetHandle(const char* name);
    Ihandle* IupSetHandle(const char* name, Ihandle* ih);
    int IupGetAllNames(char** names, int n);
    int IupGetAllDialogs(char** names, int n);
    char* IupGetName(Ihandle* ih);

    void IupSetAttributeHandle(Ihandle* ih, const char* name, Ihandle* ih_named);
    Ihandle* IupGetAttributeHandle(Ihandle* ih, const char* name);
    void IupSetAttributeHandleId(Ihandle* ih, const char* name, int id, Ihandle* ih_named);
    Ihandle* IupGetAttributeHandleId(Ihandle* ih, const char* name, int id);
    void IupSetAttributeHandleId2(Ihandle* ih, const char* name, int lin, int col, Ihandle* ih_named);
    Ihandle* IupGetAttributeHandleId2(Ihandle* ih, const char* name, int lin, int col);

    char* IupGetClassName(Ihandle* ih);
    char* IupGetClassType(Ihandle* ih);
    int IupGetAllClasses(char** names, int n);
    int IupGetClassAttributes(const char* classname, char** names, int n);
    int IupGetClassCallbacks(const char* classname, char** names, int n);
    void IupSaveClassAttributes(Ihandle* ih);
    void IupCopyClassAttributes(Ihandle* src_ih, Ihandle* dst_ih);
    void IupSetClassDefaultAttribute(const char* classname, const char* name, const char* value);
    int IupClassMatch(Ihandle* ih, const char* classname);

    Ihandle* IupCreate(const char* classname);
    Ihandle* IupCreatev(const char* classname, void** params);
    Ihandle* IupCreatep(const char* classname, void* first, ...);

    /************************************************************************/
    /*                        Elements                                      */
    /************************************************************************/

    Ihandle* IupFill();
    Ihandle* IupSpace();

    Ihandle* IupRadio(Ihandle* child);
    Ihandle* IupVbox(Ihandle* child, ...);
    Ihandle* IupVboxv(Ihandle** children);
    Ihandle* IupZbox(Ihandle* child, ...);
    Ihandle* IupZboxv(Ihandle** children);
    Ihandle* IupHbox(Ihandle* child, ...);
    Ihandle* IupHboxv(Ihandle** children);

    Ihandle* IupNormalizer(Ihandle* ih_first, ...);
    Ihandle* IupNormalizerv(Ihandle** ih_list);

    Ihandle* IupCbox(Ihandle* child, ...);
    Ihandle* IupCboxv(Ihandle** children);
    Ihandle* IupSbox(Ihandle* child);
    Ihandle* IupSplit(Ihandle* child1, Ihandle* child2);
    Ihandle* IupScrollBox(Ihandle* child);
    Ihandle* IupFlatScrollBox(Ihandle* child);
    Ihandle* IupGridBox(Ihandle* child, ...);
    Ihandle* IupGridBoxv(Ihandle** children);
    Ihandle* IupMultiBox(Ihandle* child, ...);
    Ihandle* IupMultiBoxv(Ihandle** children);
    Ihandle* IupExpander(Ihandle* child);
    Ihandle* IupDetachBox(Ihandle* child);
    Ihandle* IupBackgroundBox(Ihandle* child);

    Ihandle* IupFrame(Ihandle* child);
    Ihandle* IupFlatFrame(Ihandle* child);

    Ihandle* IupImage(int width, int height, const ubyte* pixels);
    Ihandle* IupImageRGB(int width, int height, const ubyte* pixels);
    Ihandle* IupImageRGBA(int width, int height, const ubyte* pixels);

    Ihandle* IupItem(const char* title, const char* action);
    Ihandle* IupSubmenu(const char* title, Ihandle* child);
    Ihandle* IupSeparator();
    Ihandle* IupMenu(Ihandle* child, ...);
    Ihandle* IupMenuv(Ihandle** children);

    Ihandle* IupButton(const char* title, const char* action);
    Ihandle* IupFlatButton(const char* title);
    Ihandle* IupFlatToggle(const char* title);
    Ihandle* IupDropButton(Ihandle* dropchild);
    Ihandle* IupFlatLabel(const char* title);
    Ihandle* IupFlatSeparator();
    Ihandle* IupCanvas(const char* action);
    Ihandle* IupDialog(Ihandle* child);
    Ihandle* IupUser();
    Ihandle* IupThread();
    Ihandle* IupLabel(const char* title);
    Ihandle* IupList(const char* action);
    Ihandle* IupFlatList();
    Ihandle* IupText(const char* action);
    Ihandle* IupMultiLine(const char* action);
    Ihandle* IupToggle(const char* title, const char* action);
    Ihandle* IupTimer();
    Ihandle* IupClipboard();
    Ihandle* IupProgressBar();
    Ihandle* IupVal(const char* type);
    Ihandle* IupFlatVal(const char* type);
    Ihandle* IupFlatTree();
    Ihandle* IupTabs(Ihandle* child, ...);
    Ihandle* IupTabsv(Ihandle** children);
    Ihandle* IupFlatTabs(Ihandle* first, ...);
    Ihandle* IupFlatTabsv(Ihandle** children);
    Ihandle* IupTree();
    Ihandle* IupLink(const char* url, const char* title);
    Ihandle* IupAnimatedLabel(Ihandle* animation);
    Ihandle* IupDatePick();
    Ihandle* IupCalendar();
    Ihandle* IupColorbar();
    Ihandle* IupGauge();
    Ihandle* IupDial(const char* type);
    Ihandle* IupColorBrowser();

    /* Old controls, use SPIN attribute of IupText */
    Ihandle* IupSpin();
    Ihandle* IupSpinbox(Ihandle* child);

    /************************************************************************/
    /*                      Utilities                                       */
    /************************************************************************/

    /* IupTree and IupFlatTree utilities (work for both) */
    int IupTreeSetUserId(Ihandle* ih, int id, void* userid);
    void* IupTreeGetUserId(Ihandle* ih, int id);
    int IupTreeGetId(Ihandle* ih, void* userid);
    void IupTreeSetAttributeHandle(Ihandle* ih, const char* name, int id, Ihandle* ih_named); /* deprecated, use IupSetAttributeHandleId */
    /************************************************************************/
    /*                      Pre-defined dialogs                           */
    /************************************************************************/

    Ihandle* IupFileDlg();
    Ihandle* IupMessageDlg();
    Ihandle* IupColorDlg();
    Ihandle* IupFontDlg();
    Ihandle* IupProgressDlg();

    int IupGetFile(char* arq);
    void IupMessage(const char* title, const char* msg);
    void IupMessagef(const char* title, const char* format, ...);
    void IupMessageError(Ihandle* parent, const char* message);
    int IupMessageAlarm(Ihandle* parent, const char* title, const char* message, const char* buttons);
    int IupAlarm(const char* title, const char* msg, const char* b1, const char* b2, const char* b3);
    int IupScanf(const char* format, ...);
    int IupListDialog(int type, const char* title, int size, const char** list,
        int op, int max_col, int max_lin, int* marks);
    int IupGetText(const char* title, char* text, int maxsize);
    int IupGetColor(int x, int y, ubyte* r, ubyte* g, ubyte* b);

    alias Iparamcb = int function(Ihandle* dialog, int param_index, void* user_data);
    int IupGetParam(const char* title, Iparamcb action, void* user_data, const char* format, ...);
    int IupGetParamv(const char* title, Iparamcb action, void* user_data, const char* format, int param_count, int param_extra, void** param_data);
    Ihandle* IupParam(const char* format);
    Ihandle* IupParamBox(Ihandle* param, ...);
    Ihandle* IupParamBoxv(Ihandle** param_array);

    Ihandle* IupLayoutDialog(Ihandle* dialog);
    Ihandle* IupElementPropertiesDialog(Ihandle* parent, Ihandle* elem);
    Ihandle* IupGlobalsDialog();
    Ihandle* IupClassInfoDialog(Ihandle* parent);

    /************************************************************************/
    /*                   Common Flags and Return Values                     */
    /************************************************************************/
    enum
    {
        IUP_ERROR = 1,
        IUP_NOERROR = 0,
        IUP_OPENED = -1,
        IUP_INVALID = -1,
        IUP_INVALID_ID = -10,
    }

    /************************************************************************/
    /*                   Callback Return Values                             */
    /************************************************************************/
    enum
    {
        IUP_IGNORE = -1,
        IUP_DEFAULT = -2,
        IUP_CLOSE = -3,
        IUP_CONTINUE = -4,
    }
    /************************************************************************/
    /*           IupPopup and IupShowXY Parameter Values                    */
    /************************************************************************/
    enum
    {
        IUP_CENTER = 0xFFFF, /* 65535 */
        IUP_LEFT = 0xFFFE, /* 65534 */
        IUP_RIGHT = 0xFFFD, /* 65533 */
        IUP_MOUSEPOS = 0xFFFC, /* 65532 */
        IUP_CURRENT = 0xFFFB, /* 65531 */
        IUP_CENTERPARENT = 0xFFFA, /* 65530 */
        IUP_LEFTPARENT = 0xFFF9, /* 65529 */
        IUP_RIGHTPARENT = 0xFFF8, /* 65528 */
        IUP_TOP = IUP_LEFT,
        IUP_BOTTOM = IUP_RIGHT,
        IUP_TOPPARENT = IUP_LEFTPARENT,
        IUP_BOTTOMPARENT = IUP_RIGHTPARENT,
    }

    /************************************************************************/
    /*               Mouse Button Values and Macros                         */
    /************************************************************************/
    enum
    {
        IUP_BUTTON1 = '1',
        IUP_BUTTON2 = '2',
        IUP_BUTTON3 = '3',
        IUP_BUTTON4 = '4',
        IUP_BUTTON5 = '5',
    }
}
