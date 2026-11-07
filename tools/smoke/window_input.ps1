# TLF-060: keyboard input and screenshots for a game window, without focusing it.
# Dot-source it: . tools\smoke\window_input.ps1
# Keys are posted as WM_KEYDOWN / WM_KEYUP to the window (with the scan code, which Godot maps to
# the physical keycode), so nothing goes to whatever window has the focus. Screenshots use
# PrintWindow with PW_RENDERFULLCONTENT, which works while the window is covered.

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class TlfWindowInput {
    [DllImport("user32.dll")] static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);
    [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }

    const uint WM_KEYDOWN = 0x0100, WM_KEYUP = 0x0101, PW_CLIENTONLY = 1, PW_RENDERFULLCONTENT = 2;

    static IntPtr KeyParam(uint vk, bool up) {
        uint scan = MapVirtualKey(vk, 0);
        uint lParam = 1u | (scan << 16);
        if (up) lParam |= (1u << 30) | (1u << 31);
        return (IntPtr)(long)lParam;
    }

    public static void KeyDown(IntPtr hWnd, uint vk) { PostMessage(hWnd, WM_KEYDOWN, (IntPtr)vk, KeyParam(vk, false)); }
    public static void KeyUp(IntPtr hWnd, uint vk) { PostMessage(hWnd, WM_KEYUP, (IntPtr)vk, KeyParam(vk, true)); }

    // Saves the client area as PNG; returns the share of pixels that are not near-black (0..1).
    public static double Capture(IntPtr hWnd, string path) {
        RECT r;
        GetClientRect(hWnd, out r);
        int w = Math.Max(1, r.Right - r.Left), h = Math.Max(1, r.Bottom - r.Top);
        using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
            using (var g = Graphics.FromImage(bmp)) {
                IntPtr hdc = g.GetHdc();
                PrintWindow(hWnd, hdc, PW_CLIENTONLY | PW_RENDERFULLCONTENT);
                g.ReleaseHdc(hdc);
            }
            bmp.Save(path, ImageFormat.Png);
            int lit = 0, total = 0;
            for (int y = 0; y < h; y += 8) for (int x = 0; x < w; x += 8) {
                Color c = bmp.GetPixel(x, y);
                total++;
                if (c.R + c.G + c.B > 60) lit++;
            }
            return total == 0 ? 0 : (double)lit / total;
        }
    }

    // Share of the title menu's "selected" yellow (title_screen.gd COLOR_SELECTED 1.0, 0.85, 0.4) in
    // a horizontal band of a saved screenshot, y0..y1 as fractions of its height.
    public static double YellowShare(string path, double y0, double y1) {
        using (var bmp = new Bitmap(path)) {
            int from = (int)(bmp.Height * y0), to = (int)(bmp.Height * y1), hit = 0, total = 0;
            for (int y = from; y < to; y += 2) for (int x = 0; x < bmp.Width; x += 2) {
                Color c = bmp.GetPixel(x, y);
                total++;
                if (c.R > 200 && c.G > 170 && c.B < 150) hit++;
            }
            return total == 0 ? 0 : (double)hit / total;
        }
    }
}
'@

# Virtual-key codes for the keys the InputMap binds (project.godot [input], physical keycodes).
$TlfKeys = @{ Enter = 0x0D; E = 0x45; W = 0x57; A = 0x41; S = 0x53; D = 0x44 }

function Send-TlfKey([IntPtr]$hwnd, [string]$key, [int]$holdMs = 80) {
    [TlfWindowInput]::KeyDown($hwnd, $TlfKeys[$key])
    Start-Sleep -Milliseconds $holdMs
    [TlfWindowInput]::KeyUp($hwnd, $TlfKeys[$key])
}

function Hold-TlfKeys([IntPtr]$hwnd, [string[]]$keys, [int]$holdMs) {
    foreach ($k in $keys) { [TlfWindowInput]::KeyDown($hwnd, $TlfKeys[$k]) }
    # Windows repeats WM_KEYDOWN while a real key is held; Godot only needs the first one.
    Start-Sleep -Milliseconds $holdMs
    foreach ($k in $keys) { [TlfWindowInput]::KeyUp($hwnd, $TlfKeys[$k]) }
}
