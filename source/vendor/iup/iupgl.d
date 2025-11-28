module vendor.iup.iupgl;

import vendor.iup;

extern (C)
{
    enum
    {
        IUP_BUFFER = "BUFFER",
        IUP_STEREO = "STEREO",
        IUP_BUFFER_SIZE = "BUFFER_SIZE",
        IUP_RED_SIZE = "RED_SIZE",
        IUP_GREEN_SIZE = "GREEN_SIZE",
        IUP_BLUE_SIZE = "BLUE_SIZE",
        IUP_ALPHA_SIZE = "ALPHA_SIZE",
        IUP_DEPTH_SIZE = "DEPTH_SIZE",
        IUP_STENCIL_SIZE = "STENCIL_SIZE",
        IUP_ACCUM_RED_SIZE = "ACCUM_RED_SIZE",
        IUP_ACCUM_GREEN_SIZE = "ACCUM_GREEN_SIZE",
        IUP_ACCUM_BLUE_SIZE = "ACCUM_BLUE_SIZE",
        IUP_ACCUM_ALPHA_SIZE = "ACCUM_ALPHA_SIZE",
    }

    enum
    {
        IUP_DOUBLE = "DOUBLE",
        IUP_SINGLE = "SINGLE",
        IUP_INDEX = "INDEX",
        IUP_RGBA = "RGBA",
        IUP_YES = "YES",
        IUP_NO = "NO",
    }

    void IupGLCanvasOpen();

    Ihandle* IupGLCanvas(const char* action);
    Ihandle* IupGLBackgroundBox(Ihandle* child);

    void IupGLMakeCurrent(Ihandle* ih);
    int IupGLIsCurrent(Ihandle* ih);
    void IupGLSwapBuffers(Ihandle* ih);
    void IupGLPalette(Ihandle* ih, int index, float r, float g, float b);
    void IupGLUseFont(Ihandle* ih, int first, int count, int list_base);
    void IupGLWait(int gl);
}
