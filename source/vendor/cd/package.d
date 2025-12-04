module vendor.cd;

public import vendor.cd.old;
public import vendor.cd.cdnative;
public import vendor.cd.cdiup;

extern (C)
{
    enum
    {
        CD_NAME = "CD - A 2D Graphics Library",
        CD_DESCRIPTION = "Vector Graphics Toolkit with Device Independent Output",
        CD_COPYRIGHT = "Copyright (C) 1994-2020 Tecgraf/PUC-Rio",
        CD_VERSION = "5.14",
        CD_VERSION_NUMBER = 514_000,
        CD_VERSION_DATE = "2020/07/30",
    }

    alias cdContext = void;
    alias cdCanvas = void;
    alias cdState = void;
    alias cdImage = void;

    struct cdBitmap
    {
        int w;
        int h;
        int type;
        void* data;
    }

    /* library */
    char* cdVersion();
    char* cdVersionDate();
    int cdVersionNumber();

    /* canvas init */
    cdCanvas* cdCreateCanvas(cdContext* context, void* data);
    cdCanvas* cdCreateCanvasf(cdContext* context, const char* format, ...);
    void cdKillCanvas(cdCanvas* canvas);

    cdContext* cdCanvasGetContext(cdCanvas* canvas);
    int cdCanvasActivate(cdCanvas* canvas);
    void cdCanvasDeactivate(cdCanvas* canvas);
    int cdUseContextPlus(int use);
    void cdInitContextPlus(); /* need an external library */
    void cdFinishContextPlus(); /* need an external library */

    /* context */
    alias cdCallback = int function(cdCanvas* canvas, ...);
    int cdContextRegisterCallback(cdContext* context, int cb, cdCallback func);
    ulong cdContextCaps(cdContext* context);
    int cdContextIsPlus(cdContext* context);
    int cdContextType(cdContext* context);

    /* control */
    int cdCanvasSimulate(cdCanvas* canvas, int mode);
    void cdCanvasFlush(cdCanvas* canvas);
    void cdCanvasClear(cdCanvas* canvas);
    cdState* cdCanvasSaveState(cdCanvas* canvas);
    void cdCanvasRestoreState(cdCanvas* canvas, cdState* state);
    void cdReleaseState(cdState* state);
    void cdCanvasSetAttribute(cdCanvas* canvas, const char* name, char* data);
    void cdCanvasSetfAttribute(cdCanvas* canvas, const char* name, const char* format, ...);
    char* cdCanvasGetAttribute(cdCanvas* canvas, const char* name);

    /* primitives */
    void cdCanvasPixel(cdCanvas* canvas, int x, int y, long color);
    void cdCanvasMark(cdCanvas* canvas, int x, int y);
    void cdfCanvasPixel(cdCanvas* canvas, double x, double y, long color);
    void cdfCanvasMark(cdCanvas* canvas, double x, double y);

    void cdCanvasBegin(cdCanvas* canvas, int mode);
    void cdCanvasPathSet(cdCanvas* canvas, int action);
    void cdCanvasEnd(cdCanvas* canvas);

    void cdCanvasLine(cdCanvas* canvas, int x1, int y1, int x2, int y2);
    void cdCanvasVertex(cdCanvas* canvas, int x, int y);
    void cdCanvasRect(cdCanvas* canvas, int xmin, int xmax, int ymin, int ymax);
    void cdCanvasBox(cdCanvas* canvas, int xmin, int xmax, int ymin, int ymax);
    void cdCanvasArc(cdCanvas* canvas, int xc, int yc, int w, int h, double angle1, double angle2);
    void cdCanvasSector(cdCanvas* canvas, int xc, int yc, int w, int h, double angle1, double angle2);
    void cdCanvasChord(cdCanvas* canvas, int xc, int yc, int w, int h, double angle1, double angle2);
    void cdCanvasText(cdCanvas* canvas, int x, int y, const char* s);

    void cdfCanvasLine(cdCanvas* canvas, double x1, double y1, double x2, double y2);
    void cdfCanvasVertex(cdCanvas* canvas, double x, double y);
    void cdfCanvasRect(cdCanvas* canvas, double xmin, double xmax, double ymin, double ymax);
    void cdfCanvasBox(cdCanvas* canvas, double xmin, double xmax, double ymin, double ymax);
    void cdfCanvasArc(cdCanvas* canvas, double xc, double yc, double w, double h, double angle1, double angle2);
    void cdfCanvasSector(cdCanvas* canvas, double xc, double yc, double w, double h, double angle1, double angle2);
    void cdfCanvasChord(cdCanvas* canvas, double xc, double yc, double w, double h, double angle1, double angle2);
    void cdfCanvasText(cdCanvas* canvas, double x, double y, const char* s);

    /* attributes */
    void cdCanvasSetBackground(cdCanvas* canvas, long color);
    void cdCanvasSetForeground(cdCanvas* canvas, long color);
    long cdCanvasBackground(cdCanvas* canvas, long color);
    long cdCanvasForeground(cdCanvas* canvas, long color);
    int cdCanvasBackOpacity(cdCanvas* canvas, int opacity);
    int cdCanvasWriteMode(cdCanvas* canvas, int mode);
    int cdCanvasLineStyle(cdCanvas* canvas, int style);
    void cdCanvasLineStyleDashes(cdCanvas* canvas, const int* dashes, int count);
    int cdCanvasLineWidth(cdCanvas* canvas, int width);
    int cdCanvasLineJoin(cdCanvas* canvas, int join);
    int cdCanvasLineCap(cdCanvas* canvas, int cap);
    int cdCanvasInteriorStyle(cdCanvas* canvas, int style);
    int cdCanvasHatch(cdCanvas* canvas, int style);
    void cdCanvasStipple(cdCanvas* canvas, int w, int h, const ubyte* stipple);
    ubyte* cdCanvasGetStipple(cdCanvas* canvas, int* n, int* m);
    void cdCanvasPattern(cdCanvas* canvas, int w, int h, const long* pattern);
    long* cdCanvasGetPattern(cdCanvas* canvas, int* n, int* m);
    int cdCanvasFillMode(cdCanvas* canvas, int mode);
    int cdCanvasFont(cdCanvas* canvas, const char* type_face, int style, int size);
    void cdCanvasGetFont(cdCanvas* canvas, char* type_face, int* style, int* size);
    char* cdCanvasNativeFont(cdCanvas* canvas, const char* font);
    int cdCanvasTextAlignment(cdCanvas* canvas, int alignment);
    double cdCanvasTextOrientation(cdCanvas* canvas, double angle);
    int cdCanvasMarkType(cdCanvas* canvas, int type);
    int cdCanvasMarkSize(cdCanvas* canvas, int size);

    /* coordinate transformation */
    void cdCanvasGetSize(cdCanvas* canvas, int* width, int* height, double* width_mm, double* height_mm);
    int cdCanvasUpdateYAxis(cdCanvas* canvas, int* y);
    double cdfCanvasUpdateYAxis(cdCanvas* canvas, double* y);
    int cdCanvasInvertYAxis(cdCanvas* canvas, int y);
    double cdfCanvasInvertYAxis(cdCanvas* canvas, double y);
    void cdCanvasMM2Pixel(cdCanvas* canvas, double mm_dx, double mm_dy, int* dx, int* dy);
    void cdCanvasPixel2MM(cdCanvas* canvas, int dx, int dy, double* mm_dx, double* mm_dy);
    void cdfCanvasMM2Pixel(cdCanvas* canvas, double mm_dx, double mm_dy, double* dx, double* dy);
    void cdfCanvasPixel2MM(cdCanvas* canvas, double dx, double dy, double* mm_dx, double* mm_dy);
    void cdCanvasOrigin(cdCanvas* canvas, int x, int y);
    void cdfCanvasOrigin(cdCanvas* canvas, double x, double y);
    void cdCanvasGetOrigin(cdCanvas* canvas, int* x, int* y);
    void cdfCanvasGetOrigin(cdCanvas* canvas, double* x, double* y);
    void cdCanvasTransform(cdCanvas* canvas, const double* matrix);
    double* cdCanvasGetTransform(cdCanvas* canvas);
    void cdCanvasTransformMultiply(cdCanvas* canvas, const double* matrix);
    void cdCanvasTransformRotate(cdCanvas* canvas, double angle);
    void cdCanvasTransformScale(cdCanvas* canvas, double sx, double sy);
    void cdCanvasTransformTranslate(cdCanvas* canvas, double dx, double dy);
    void cdCanvasTransformPoint(cdCanvas* canvas, int x, int y, int* tx, int* ty);
    void cdfCanvasTransformPoint(cdCanvas* canvas, double x, double y, double* tx, double* ty);

    enum
    {
        /* some predefined colors for convenience */
        CD_RED = 0xFF0000L, /* 255,  0,  0 */
        CD_DARK_RED = 0x800000L, /* 128,  0,  0 */
        CD_GREEN = 0x00FF00L, /*   0,255,  0 */
        CD_DARK_GREEN = 0x008000L, /*   0,128,  0 */
        CD_BLUE = 0x0000FFL, /*   0,  0,255 */
        CD_DARK_BLUE = 0x000080L, /*   0,  0,128 */
        CD_YELLOW = 0xFFFF00L, /* 255,255,  0 */
        CD_DARK_YELLOW = 0x808000L, /* 128,128,  0 */
        CD_MAGENTA = 0xFF00FFL, /* 255,  0,255 */
        CD_DARK_MAGENTA = 0x800080L, /* 128,  0,128 */
        CD_CYAN = 0x00FFFFL, /*   0,255,255 */
        CD_DARK_CYAN = 0x008080L, /*   0,128,128 */
        CD_WHITE = 0xFFFFFFL, /* 255,255,255 */
        CD_BLACK = 0x000000L, /*   0,  0,  0 */
        CD_DARK_GRAY = 0x808080L, /* 128,128,128 */
        CD_GRAY = 0xC0C0C0L,
    }

    /* CD Values */
    enum
    {
        CD_QUERY = -1
    }

    enum
    { /* bitmap type */
        CD_RGB, /* these definitions are compatible with the IM library */
        CD_MAP,
        CD_RGBA = 0x100
    }

    enum
    { /* bitmap data */
        CD_IRED,
        CD_IGREEN,
        CD_IBLUE,
        CD_IALPHA,
        CD_INDEX,
        CD_COLORS
    }

    enum
    { /* status report */
        CD_ERROR = -1,
        CD_OK = 0
    }

    enum
    { /* clip mode */
        CD_CLIPOFF,
        CD_CLIPAREA,
        CD_CLIPPOLYGON,
        CD_CLIPREGION,
        CD_CLIPPATH
    }

    enum
    { /* region combine mode */
        CD_UNION,
        CD_INTERSECT,
        CD_DIFFERENCE,
        CD_NOTINTERSECT
    }

    enum
    { /* polygon mode (begin...end) */
        CD_FILL,
        CD_OPEN_LINES,
        CD_CLOSED_LINES,
        CD_CLIP,
        CD_BEZIER,
        CD_REGION,
        CD_PATH
    }

    enum
    {
        CD_POLYCUSTOM = 10
    }

    enum
    { /* path actions */
        CD_PATH_NEW,
        CD_PATH_MOVETO,
        CD_PATH_LINETO,
        CD_PATH_ARC,
        CD_PATH_CURVETO,
        CD_PATH_CLOSE,
        CD_PATH_FILL,
        CD_PATH_STROKE,
        CD_PATH_FILLSTROKE,
        CD_PATH_CLIP
    }

    enum
    { /* fill mode */
        CD_EVENODD,
        CD_WINDING
    }

    enum
    { /* line join  */
        CD_MITER,
        CD_BEVEL,
        CD_ROUND
    }

    enum
    { /* line cap  */
        CD_CAPFLAT,
        CD_CAPSQUARE,
        CD_CAPROUND
    }

    enum
    { /* background opacity mode */
        CD_OPAQUE,
        CD_TRANSPARENT
    }

    enum
    { /* write mode */
        CD_REPLACE,
        CD_XOR,
        CD_NOT_XOR
    }

    enum
    { /* color allocation mode (palette) */
        CD_POLITE,
        CD_FORCE
    }

    enum
    { /* line style */
        CD_CONTINUOUS,
        CD_DASHED,
        CD_DOTTED,
        CD_DASH_DOT,
        CD_DASH_DOT_DOT,
        CD_CUSTOM
    }

    enum
    { /* marker type */
        CD_PLUS,
        CD_STAR,
        CD_CIRCLE,
        CD_X,
        CD_BOX,
        CD_DIAMOND,
        CD_HOLLOW_CIRCLE,
        CD_HOLLOW_BOX,
        CD_HOLLOW_DIAMOND
    }

    enum
    { /* hatch type */
        CD_HORIZONTAL,
        CD_VERTICAL,
        CD_FDIAGONAL,
        CD_BDIAGONAL,
        CD_CROSS,
        CD_DIAGCROSS
    }

    enum
    { /* interior style */
        CD_SOLID,
        CD_HATCH,
        CD_STIPPLE,
        CD_PATTERN,
        CD_HOLLOW,
        CD_CUSTOMPATTERN
    }

    enum
    { /* text alignment */
        CD_NORTH,
        CD_SOUTH,
        CD_EAST,
        CD_WEST,
        CD_NORTH_EAST,
        CD_NORTH_WEST,
        CD_SOUTH_EAST,
        CD_SOUTH_WEST,
        CD_CENTER,
        CD_BASE_LEFT,
        CD_BASE_CENTER,
        CD_BASE_RIGHT
    }

    enum
    { /* style */
        CD_PLAIN = 0,
        CD_BOLD = 1,
        CD_ITALIC = 2,
        CD_UNDERLINE = 4,
        CD_STRIKEOUT = 8
    }

}
