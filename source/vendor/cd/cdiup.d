module vendor.cd.cdiup;

import vendor.cd;

extern (C)
{
    cdContext* cdContextIup();
    cdContext* cdContextIupDBuffer();
    cdContext* cdContextIupDBufferRGB();

    alias CD_IUP = cdContextIup;
    alias CD_IUPDBUFFER = cdContextIupDBuffer;
    alias CD_IUPDBUFFERRGB = cdContextIupDBufferRGB;

}
