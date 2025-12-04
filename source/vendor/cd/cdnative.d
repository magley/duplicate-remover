module vendor.cd.cdnative;

import vendor.cd;

extern (C)
{
    cdContext* cdContextNativeWindow();
    alias CD_NATIVEWINDOW = cdContextNativeWindow;

    void cdGetScreenSize(int* width, int* height, double* width_mm, double* height_mm);
    int cdGetScreenColorPlanes();
}
