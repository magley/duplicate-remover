module gui.results_canvas;

import std.stdio;
import std.conv;
import std.string;
import std.datetime.stopwatch;
import std.file;
import std.path;
import std.algorithm;
import core.thread.osthread;

import vendor.iup;
import vendor.cd;

import gui.exporter;

import util;
import finder;
import hasher;

static cdCanvas* canvas;

Ihandle* create_results_canvas(string handle)
{
    cdInitContextPlus();
    cdUseContextPlus(1);

    Ihandle* self = IupCanvas(null);

    // IupSetAttribute(self, "SIZE", "300x300");
    IupSetAttribute(self, "EXPAND", "YES");
    IupSetAttribute(self, "CANFOCUS", "YES");

    IupSetCallback(self, "BUTTON_CB", cast(Icallback)&mouse_cb);
    IupSetCallback(self, "MAP_CB", cast(Icallback)&map_cb);
    IupSetCallback(self, "ACTION", cast(Icallback)&redraw_cb);

    IupSetHandle(handle.toStringz(), self);
    return self;
}

extern (C) int map_cb(Ihandle* self)
{
    canvas = cdCreateCanvas(CD_IUP, self);
    TRANSFORM(canvas);
    return IUP_DEFAULT;
}

extern (C) int redraw_cb(Ihandle* self, float x, float y)
{
    cdCanvasActivate(canvas);
    TRANSFORM(canvas);

    cdCanvasClear(canvas);

    cdCanvasForeground(canvas, CD_BLUE);
    cdCanvasBox(canvas, 10, 100, 10, 100);

    cdCanvasForeground(canvas, CD_RED);
    cdCanvasRect(canvas, 10, 100, 10, 100);

    return IUP_DEFAULT;
}

extern (C) int mouse_cb(Ihandle* ih, int button, int pressed, int x, int y, char* status)
{
    writeln("AAA");
    return IUP_DEFAULT;
}

private void TRANSFORM(cdCanvas* canvas)
{
    int width, height;
    cdCanvasGetSize(canvas, &width, &height, null, null);

    double[6] m = [
        1, 0, // a, b (X axis unchanged)
        0, -1, // c, d (Y inverted)
        0,
        cast(double) height // e, f (translation)
    ];

    cdCanvasTransform(canvas, m.ptr);
}
