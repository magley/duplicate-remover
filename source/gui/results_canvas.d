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
import gui;

import util;
import finder;
import hasher;
import std.checkedint;

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
    IupSetCallback(self, "WHEEL_CB", cast(Icallback)&wheel_cb);
    IupSetCallback(self, "MAP_CB", cast(Icallback)&map_cb);
    IupSetCallback(self, "ACTION", cast(Icallback)&redraw_cb);

    IupSetHandle(handle.toStringz(), self);
    return self;
}

class Checkbox
{
    string path_full;
    string path;
    bool checked;

    this(string path_full, string path, bool checked)
    {
        this.path_full = path_full;
        this.path = path;
        this.checked = checked;
    }
}

struct Vec2
{
    int x;
    int y;
}

class ResultsUI
{
    Checkbox[][] checkboxes;
    int scroll_y = 0;

    string[] get_checked_files()
    {
        string[] res;
        foreach (g; checkboxes)
        {
            foreach (c; g)
            {
                if (c.checked)
                    res ~= c.path_full;
            }
        }

        return res;
    }

    void update(string[][] collisions)
    {
        checkboxes = [];
        reserve(checkboxes, collisions.length);
        foreach (g; collisions)
        {
            Checkbox[] group;
            reserve(group, g.length);

            foreach (string s; g)
            {
                string path_rel = relativePath(s, P.directory);
                group ~= new Checkbox(s, path_rel, false);
            }

            checkboxes ~= group;
        }
    }

    Vec2 get_pos_of_checkbox(size_t group, size_t checkbox)
    {
        int x = 6;
        int y = 6 + scroll_y;

        for (int i = 0; i < group; i++)
        {
            y += 24 * checkboxes[i].length;
        }
        y += 24 * checkbox;
        y += 8 * group;

        return Vec2(x, y);
    }

    void draw()
    {
        foreach (size_t j, group; checkboxes)
        {
            foreach (size_t i, Checkbox c; group)
            {
                Vec2 pos = get_pos_of_checkbox(j, i);

                if (pos.y < -50)
                    continue;
                if (pos.y >= H() + 50)
                    return;

                draw_checkbox(pos.x, pos.y, c.path, c.checked);
            }
        }
    }

    void force_redraw()
    {
        Ihandle* canvas = IupGetHandle("results_canvas");
        IupUpdate(canvas);
        IupRefresh(canvas);
    }

    void on_mouse_click(int x, int y)
    {
        foreach (size_t j, group; checkboxes)
        {
            foreach (size_t i, Checkbox c; group)
            {
                Vec2 pos = get_pos_of_checkbox(j, i);

                if (y >= pos.y && y <= pos.y + 20)
                {
                    c.checked ^= true;
                    force_redraw();
                    return;
                }
            }
        }
    }

    void on_scroll(int delta_y)
    {
        const int SCROLL_SPEED = 20 + H() / 10;

        int scroll_y_max = get_pos_of_checkbox(
            checkboxes.length - 1U, // Last group
            checkboxes[$ - 1].length - 1U + 1U).y; // Last checkbox + 1 
        scroll_y_max -= scroll_y; // Undo scroll
        scroll_y_max -= H(); // Clamp to bottom of the canvas

        const int scroll_y_before = scroll_y;

        scroll_y += SCROLL_SPEED * delta_y;
        if (scroll_y < -scroll_y_max)
            scroll_y = -scroll_y_max;
        if (scroll_y > 0)
            scroll_y = 0;

        if (scroll_y_before != scroll_y)
        {
            force_redraw();
        }
    }
}

// ========================================================================================
// Draw functions
// ========================================================================================

private void draw_checkbox(int x, int y, string text, bool checked)
{
    cdCanvasForeground(canvas, CD_BLACK);
    draw_rect(x, y, 18, 18, false);

    if (checked)
    {
        cdCanvasForeground(canvas, CD_BLACK);
        draw_rect(x + 4, y + 4, 18 - 8, 18 - 8, true);
        // draw_arc(x + 9, y + 9, 14, 14, 0, 360);
    }

    cdCanvasForeground(canvas, CD_BLACK);
    cdCanvasFont(canvas, "System", CD_PLAIN, 10);
    draw_text(x + 24, y + 14, text);

}

private void draw_rect(int x, int y, int w, int h, bool fill)
{
    if (fill)
    {
        cdCanvasBox(canvas, x, x + (w), H - y, H - (y + h));
    }
    else
    {
        cdCanvasRect(canvas, x, x + (w), H - y, H - (y + h));
    }
}

private void draw_arc(int cx, int cy, int w, int h, float angle0, float angle1)
{
    cdCanvasBegin(canvas, CD_FILL);
    cdCanvasArc(canvas, cx, H - cy, w, h, angle0, angle1);
    cdCanvasEnd(canvas);
}

private void draw_text(int x, int y, string text)
{
    cdCanvasText(canvas, x, H - y, text.toStringz());
}

private int H()
{
    int h;
    cdCanvasGetSize(canvas, null, &h, null, null);
    return h;
}

// ========================================================================================
// Callbacks
// ========================================================================================

extern (C) int map_cb(Ihandle* self)
{
    canvas = cdCreateCanvas(CD_IUP, self);
    return IUP_DEFAULT;
}

extern (C) int redraw_cb(Ihandle* self, float x, float y)
{
    cdCanvasActivate(canvas);
    cdCanvasClear(canvas);

    if (P.results_ui !is null)
    {
        P.results_ui.draw();
    }

    return IUP_DEFAULT;
}

extern (C) int mouse_cb(Ihandle* ih, int button, int pressed, int x, int y, char* status)
{
    if (button == IUP_BUTTON1 && pressed == 1)
    {
        if (P.results_ui !is null)
        {
            P.results_ui.on_mouse_click(x, y);
        }
    }
    return IUP_DEFAULT;
}

extern (C) int wheel_cb(Ihandle* ih, float delta, int, int, char*)
{
    if (P.results_ui !is null)
    {
        P.results_ui.on_scroll(cast(int) delta);
    }

    return IUP_DEFAULT;
}
