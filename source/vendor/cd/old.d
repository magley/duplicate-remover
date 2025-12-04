module vendor.cd.old;

import vendor.cd;

extern (C)
{
    /* canvas control */
    int cdActivate(cdCanvas* canvas);
    cdCanvas* cdActiveCanvas();
    int cdSimulate(int mode);
    void cdFlush();
    void cdClear();
    cdState* cdSaveState();
    void cdRestoreState(cdState* state);
    void cdSetAttribute(const char* name, char* data);
    void cdSetfAttribute(const char* name, const char* format, ...);
    char* cdGetAttribute(const char* name);
    cdContext* cdGetContext(cdCanvas* canvas);

    /* primitives */
    void cdPixel(int x, int y, long color);
    void cdMark(int x, int y);
    void cdLine(int x1, int y1, int x2, int y2);
    void cdBegin(int mode);
    void cdVertex(int x, int y);
    void cdEnd();
    void cdRect(int xmin, int xmax, int ymin, int ymax);
    void cdBox(int xmin, int xmax, int ymin, int ymax);
    void cdArc(int xc, int yc, int w, int h, double angle1, double angle2);
    void cdSector(int xc, int yc, int w, int h, double angle1, double angle2);
    void cdChord(int xc, int yc, int w, int h, double angle1, double angle2);
    void cdText(int x, int y, const char* s);

    /* attributes */
    long cdBackground(long color);
    long cdForeground(long color);
    int cdBackOpacity(int opacity);
    int cdWriteMode(int mode);
    int cdLineStyle(int style);
    void cdLineStyleDashes(const int* dashes, int count);
    int cdLineWidth(int width);
    int cdLineJoin(int join);
    int cdLineCap(int cap);
    int cdInteriorStyle(int style);
    int cdHatch(int style);
    void cdStipple(int w, int h, const ubyte* stipple);
    ubyte* cdGetStipple(int* n, int* m);
    void cdPattern(int w, int h, const long* pattern);
    long* cdGetPattern(int* n, int* m);
    int cdFillMode(int mode);
    void cdFont(int type_face, int style, int size);
    void cdGetFont(int* type_face, int* style, int* size);
    char* cdNativeFont(const char* font);
    int cdTextAlignment(int alignment);
    double cdTextOrientation(double angle);
    int cdMarkType(int type);
    int cdMarkSize(int size);
}
