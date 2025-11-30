module vendor.iup.iupcontrols;

import vendor.iup;

extern (C)
{
    int IupControlsOpen();

    Ihandle* IupCells();
    Ihandle* IupMatrix(const char* action);
    Ihandle* IupMatrixList();
    Ihandle* IupMatrixEx();

    /* available only when linking with "iupluamatrix" */
    void IupMatrixSetFormula(Ihandle* ih, int col, const char* formula, const char* init);
    void IupMatrixSetDynamic(Ihandle* ih, const char* init);
}
