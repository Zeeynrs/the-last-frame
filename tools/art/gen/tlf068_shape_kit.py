"""TLF-068 — Shape art kit for larger non-rectangular Chapter 1 rooms (ADR-023 + R2b addendum).

Deliverables (12 registered .pxo + .png assets in assets/environments/ch01/ + assets/source/ch01/,
plus 640x360 L-shaped room mockup and greyscale proof sheet in design/art/mockups/):

  1. Tall N/W Corner Pieces (32x64, pivot (16, 56), YSort_Walls z_index=5):
     - ch01_env_wall_subterranean_corner_nw_outer_idle     : convex (W, N) outer_corner at top room apex
     - ch01_env_wall_subterranean_corner_nw_inner_idle     : concave (N, W) inner_corner jutting into room
     - ch01_env_wall_subterranean_corner_n_turn_outer_idle : convex (N, low_E) outer_corner at East apex (N-turn)
     - ch01_env_wall_subterranean_corner_n_turn_inner_idle : concave (low_E, N) inner_corner at NE cut (N-turn)
     - ch01_env_wall_subterranean_corner_w_turn_outer_idle : convex (low_S, W) outer_corner at West apex (W-turn)
     - ch01_env_wall_subterranean_corner_w_turn_inner_idle : concave (W, low_S) inner_corner at SW cut (W-turn)

  2. Low S/E Partition Pieces (32x32, pivot (16, 24), vertical height 16 px <= 20 px per Rule R2, YSort_Walls z_index=5):
     - ch01_env_wall_partition_low_s_idle                  : straight 2-tile low_S partition run
     - ch01_env_wall_partition_low_e_idle                  : straight 2-tile low_E partition run
     - ch01_env_wall_partition_low_corner_inner_idle       : concave (low_S, low_E) inner_corner at SE L-cut (Rule R2b)
     - ch01_env_wall_partition_low_corner_outer_idle       : convex (low_E, low_S) outer_corner at South room apex

  3. Low End Cap Pieces for Tall N/W Wall Terminations & Odd 1-Tile Ends (32x64, pivot (16, 56), Rule R2b):
     - ch01_env_wall_subterranean_n_endcap_low_idle        : tall N wall stepping down to 16 px low end-cap bollard
     - ch01_env_wall_subterranean_w_endcap_low_idle        : tall W wall stepping down to 16 px low end-cap bollard
"""
import os
from PIL import Image
from lib import Layer, PAL, REPO, composite, to_image

FONT5X7 = {
    '0': ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
    '1': ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    '2': ["01110", "10001", "00001", "00110", "01000", "10000", "11111"],
    '3': ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    '4': ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    '5': ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
    '6': ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
    '7': ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    '8': ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    '9': ["01110", "10001", "10001", "01111", "00001", "00001", "01110"],
    ':': ["00000", "00100", "00100", "00000", "00100", "00100", "00000"],
    '-': ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    '_': ["00000", "00000", "00000", "00000", "00000", "00000", "11111"],
    '.': ["00000", "00000", "00000", "00000", "00000", "01100", "01100"],
    ',': ["00000", "00000", "00000", "00000", "00100", "00100", "01000"],
    '>': ["10000", "01000", "00100", "00010", "00100", "01000", "10000"],
    '<': ["00001", "00010", "00100", "01000", "00100", "00010", "00001"],
    '/': ["00001", "00010", "00100", "00100", "01000", "10000", "10000"],
    '(': ["00010", "00100", "01000", "01000", "01000", "00100", "00010"],
    ')': ["01000", "00100", "00010", "00010", "00010", "00100", "01000"],
    '=': ["00000", "00000", "11111", "00000", "11111", "00000", "00000"],
    '+': ["00000", "00100", "00100", "11111", "00100", "00100", "00000"],
    ' ': ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
    'A': ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    'B': ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    'C': ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
    'D': ["11100", "10010", "10001", "10001", "10001", "10010", "11100"],
    'E': ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    'F': ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    'G': ["01110", "10001", "10000", "10111", "10001", "10001", "01110"],
    'H': ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    'I': ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
    'J': ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
    'K': ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    'L': ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    'M': ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    'N': ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    'O': ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    'P': ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    'Q': ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
    'R': ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    'S': ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    'T': ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    'U': ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    'V': ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    'W': ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
    'X': ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    'Y': ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    'Z': ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
}


def _draw_text_img(im, x, y, text, rgba, scale=1):
    cx = x
    w, h = im.size
    col = rgba if len(rgba) == 4 else rgba + (255,)
    for ch in text.upper():
        pat = FONT5X7.get(ch, FONT5X7[' '])
        for ry, row in enumerate(pat):
            for rx, bit in enumerate(row):
                if bit == '1':
                    for sy in range(scale):
                        for sx in range(scale):
                            px, py = cx + rx * scale + sx, y + ry * scale + sy
                            if 0 <= px < w and 0 <= py < h:
                                im.putpixel((px, py), col)
        cx += 6 * scale


# ---------------------------------------------------------------------------
# Shared Tall Wall & Low Partition Column Helpers (exact match to wall sprites)
# ---------------------------------------------------------------------------

def _paint_tall_n_col(l0, l1, l2, x, y_top):
    """Paint one column of a tall N wall face (Step -1 Mid-Dark: 07 body, 06 grout, 24 amber dado)."""
    for z_down in range(0, 49):
        y = y_top + z_down
        if not (0 <= y < l0.h):
            continue
        if z_down == 0:
            l0.put(x, y, 8)
        elif z_down == 1:
            l0.put(x, y, 9)
        elif z_down == 2:
            l0.put(x, y, 6)
        else:
            l0.put(x, y, 7)

        if 3 <= z_down <= 45:
            if z_down % 6 == 0:
                l1.put(x, y, 6)
            else:
                brick_row = z_down // 6
                gx = (x + (brick_row % 2) * 4) % 8
                if gx == 0:
                    l1.put(x, y, 6)
                elif (x * 3 + z_down) % 19 == 0:
                    l1.put(x, y, 8)
                else:
                    l1.put(x, y, 7)

        if z_down == 35:
            l2.put(x, y, 12)
        elif z_down == 36:
            l2.put(x, y, 24)
        elif z_down == 37:
            l2.put(x, y, 6)
        elif z_down in (46, 47):
            l2.put(x, y, 11)
        elif z_down == 48:
            l2.put(x, y, 0)


def _paint_tall_w_col(l0, l1, l2, x, y_top):
    """Paint one column of a tall W wall face (Step 0 Mid-Light: 08 body, 07 grout, 25 amber dado)."""
    for z_down in range(0, 49):
        y = y_top + z_down
        if not (0 <= y < l0.h):
            continue
        if z_down == 0:
            l0.put(x, y, 9)
        elif z_down == 1:
            l0.put(x, y, 10)
        elif z_down == 2:
            l0.put(x, y, 7)
        else:
            l0.put(x, y, 8)

        if 3 <= z_down <= 45:
            if z_down % 6 == 0:
                l1.put(x, y, 7)
            else:
                brick_row = z_down // 6
                gx = (x + (brick_row % 2) * 4) % 8
                if gx == 0:
                    l1.put(x, y, 7)
                elif (x * 5 + z_down) % 17 == 0:
                    l1.put(x, y, 9)
                else:
                    l1.put(x, y, 8)

        if z_down == 35:
            l2.put(x, y, 13)
        elif z_down == 36:
            l2.put(x, y, 25)
        elif z_down == 37:
            l2.put(x, y, 7)
        elif z_down in (46, 47):
            l2.put(x, y, 12)
        elif z_down == 48:
            l2.put(x, y, 0)


def _paint_low_s_col(l0, l1, l2, x, y_top):
    """Paint one 16 px vertical column (z_down=0..16) of a low_S partition (Step -1 Mid-Dark)."""
    for z_down in range(0, 17):
        y = y_top + z_down
        if not (0 <= y < l0.h):
            continue
        if z_down == 0:
            l0.put(x, y, 9)
        elif z_down == 1:
            l0.put(x, y, 8)
        elif z_down == 2:
            l0.put(x, y, 6)
        else:
            l0.put(x, y, 7)

        if 3 <= z_down <= 13:
            if z_down in (6, 12):
                l1.put(x, y, 6)
            else:
                brick_row = z_down // 6
                gx = (x + (brick_row % 2) * 4) % 8
                if gx == 0:
                    l1.put(x, y, 6)
                elif (x * 3 + z_down) % 13 == 0:
                    l1.put(x, y, 8)
                else:
                    l1.put(x, y, 7)

        if z_down == 4:
            l2.put(x, y, 12)
        elif z_down == 5:
            l2.put(x, y, 24)
        elif z_down == 6:
            l2.put(x, y, 6)
        elif z_down in (14, 15):
            l2.put(x, y, 11)
        elif z_down == 16:
            l2.put(x, y, 0)

        if x in (7, 23) and 2 <= z_down <= 15:
            if z_down not in (5,):
                l2.put(x, y, 13 if z_down < 14 else 12)
        elif x in (8, 24) and 2 <= z_down <= 15:
            if z_down not in (5,):
                l2.put(x, y, 11)


def _paint_low_e_col(l0, l1, l2, x, y_top):
    """Paint one 16 px vertical column (z_down=0..16) of a low_E partition (Step 0 Mid-Light)."""
    for z_down in range(0, 17):
        y = y_top + z_down
        if not (0 <= y < l0.h):
            continue
        if z_down == 0:
            l0.put(x, y, 10)
        elif z_down == 1:
            l0.put(x, y, 9)
        elif z_down == 2:
            l0.put(x, y, 7)
        else:
            l0.put(x, y, 8)

        if 3 <= z_down <= 13:
            if z_down in (6, 12):
                l1.put(x, y, 7)
            else:
                brick_row = z_down // 6
                gx = (x + (brick_row % 2) * 4) % 8
                if gx == 0:
                    l1.put(x, y, 7)
                elif (x * 5 + z_down) % 13 == 0:
                    l1.put(x, y, 9)
                else:
                    l1.put(x, y, 8)

        if z_down == 4:
            l2.put(x, y, 13)
        elif z_down == 5:
            l2.put(x, y, 25)
        elif z_down == 6:
            l2.put(x, y, 7)
        elif z_down in (14, 15):
            l2.put(x, y, 12)
        elif z_down == 16:
            l2.put(x, y, 0)

        if x in (7, 23) and 2 <= z_down <= 15:
            if z_down not in (5,):
                l2.put(x, y, 14 if z_down < 14 else 13)
        elif x in (8, 24) and 2 <= z_down <= 15:
            if z_down not in (5,):
                l2.put(x, y, 12)


# ---------------------------------------------------------------------------
# (1) TALL N/W CORNER PIECES (32x64, pivot (16, 56))
# ---------------------------------------------------------------------------

def gen_wall_corner_nw_outer():
    """32x64 tall convex outer_corner (faces=[W, N]) at top room apex."""
    w, h = 32, 64
    l0 = Layer(w, h, 'Wall_Cornice_Backing')
    l1 = Layer(w, h, 'Ceramic_Tile_Course')
    l2 = Layer(w, h, 'Dado_Corner_And_Skirting')

    for x in range(16):
        y_top = 8 + ((15 - x) // 2)
        _paint_tall_w_col(l0, l1, l2, x, y_top)
    for x in range(16, 32):
        y_top = 8 + ((x - 16) // 2)
        _paint_tall_n_col(l0, l1, l2, x, y_top)

    for x in range(14, 18):
        y_top = 8 + (0 if x in (15, 16) else 1)
        for z_down in range(0, 49):
            y = y_top + z_down
            if not (0 <= y < h):
                continue
            if z_down == 0:
                l2.put(x, y, 10 if x <= 15 else 9)
            elif z_down == 1:
                l2.put(x, y, 14 if x == 15 else (9 if x == 14 else 8))
            elif z_down == 2:
                l2.put(x, y, 6)
            elif z_down in (35, 37):
                l2.put(x, y, 13 if x <= 15 else 12)
            elif z_down == 36:
                l2.put(x, y, 25 if x <= 15 else 24)
            elif z_down in (46, 47):
                l2.put(x, y, 12 if x <= 15 else 11)
            elif z_down == 48:
                l2.put(x, y, 0)
            else:
                if x == 14:
                    l2.put(x, y, 13 if z_down % 8 != 0 else 14)
                elif x == 15:
                    l2.put(x, y, 12)
                elif x == 16:
                    l2.put(x, y, 6)
                elif x == 17:
                    l2.put(x, y, 11 if z_down % 8 != 0 else 12)
    return [l0, l1, l2]


def gen_wall_corner_nw_inner():
    """32x64 tall concave inner_corner (faces=[N, W]) protruding into room."""
    w, h = 32, 64
    l0 = Layer(w, h, 'Wall_Cornice_Backing')
    l1 = Layer(w, h, 'Ceramic_Tile_Course')
    l2 = Layer(w, h, 'Dado_Corner_And_Skirting')

    for x in range(16):
        y_top = x // 2
        _paint_tall_n_col(l0, l1, l2, x, y_top)
    for x in range(16, 32):
        y_top = (31 - x) // 2
        _paint_tall_w_col(l0, l1, l2, x, y_top)

    for x in range(13, 19):
        y_top = 8 if x in (15, 16) else (7 if x in (14, 17) else 6)
        for z_down in range(0, 49):
            y = y_top + z_down
            if not (0 <= y < h):
                continue
            if z_down == 0:
                l2.put(x, y, 10 if x >= 15 else 9)
            elif z_down == 1:
                l2.put(x, y, 14 if x in (15, 16) else 9)
            elif z_down == 2:
                l2.put(x, y, 6)
            elif z_down == 35:
                l2.put(x, y, 14 if x in (15, 16) else 13)
            elif z_down == 36:
                l2.put(x, y, 26 if x in (15, 16) else (24 if x < 15 else 25))
            elif z_down == 37:
                l2.put(x, y, 6)
            elif z_down in (46, 47):
                l2.put(x, y, 13 if x in (15, 16) else (11 if x < 15 else 12))
            elif z_down == 48:
                l2.put(x, y, 0)
            else:
                if x == 13:
                    l2.put(x, y, 6)
                elif x == 14:
                    l2.put(x, y, 12 if z_down % 6 != 0 else 6)
                elif x == 15:
                    l2.put(x, y, 14 if z_down % 6 != 0 else 12)
                elif x == 16:
                    l2.put(x, y, 13 if z_down % 6 != 0 else 12)
                elif x == 17:
                    l2.put(x, y, 9 if z_down % 6 != 0 else 7)
                elif x == 18:
                    l2.put(x, y, 7)
    return [l0, l1, l2]


def gen_wall_corner_n_turn_outer():
    """32x64 N-turn outer_corner (faces=[N, low_E]) at East apex of room."""
    w, h = 32, 64
    l0 = Layer(w, h, 'Wall_Cornice_Backing')
    l1 = Layer(w, h, 'Ceramic_Tile_Course')
    l2 = Layer(w, h, 'Dado_Corner_And_Skirting')

    for x in range(16):
        _paint_tall_n_col(l0, l1, l2, x, x // 2)

    for x in range(16, 22):
        dx = x - 16
        y_top = 7 - (dx // 2)
        for z_down in range(0, 49):
            y = y_top + z_down
            if not (0 <= y < h):
                continue
            if z_down == 0:
                l0.put(x, y, 9 if dx < 4 else 6)
            elif z_down == 1:
                l0.put(x, y, 8)
            elif z_down == 2:
                l0.put(x, y, 6)
            else:
                l0.put(x, y, 6 if dx >= 4 else 12)

            if 3 <= z_down <= 45:
                l1.put(x, y, 13 if dx in (0, 1) else (12 if dx in (2, 3) else 11))
                if z_down % 8 == 0 and dx in (1, 2):
                    l1.put(x, y, 14)

            if z_down == 35:
                l2.put(x, y, 13)
            elif z_down == 36:
                l2.put(x, y, 24 if dx < 4 else 23)
            elif z_down == 37:
                l2.put(x, y, 6)
            elif z_down in (46, 47):
                l2.put(x, y, 11)
            elif z_down == 48:
                l2.put(x, y, 0)

    for x in range(16):
        y_top_low = 40 + ((15 - x) // 2)
        _paint_low_e_col(l0, l1, l2, x, y_top_low)

    for x in range(13, 19):
        y_top_b = 39 + (abs(x - 15) // 2)
        for z in range(0, 17):
            y = y_top_b + z
            if not (0 <= y < h):
                continue
            if z == 0:
                l2.put(x, y, 10)
            elif z == 1:
                l2.put(x, y, 14 if x in (15, 16) else 9)
            elif z == 4:
                l2.put(x, y, 13)
            elif z == 5:
                l2.put(x, y, 25 if x <= 16 else 24)
            elif z in (14, 15):
                l2.put(x, y, 12 if x <= 15 else 11)
            elif z == 16:
                l2.put(x, y, 0)
            else:
                l2.put(x, y, 13 if x in (14, 15) else (12 if x in (16, 17) else 11))
    return [l0, l1, l2]


def gen_wall_corner_n_turn_inner():
    """32x64 N-turn inner_corner (faces=[low_E, N]) at NE concave cut (Rule R2b)."""
    w, h = 32, 64
    l0 = Layer(w, h, 'Wall_Cornice_Backing')
    l1 = Layer(w, h, 'Ceramic_Tile_Course')
    l2 = Layer(w, h, 'Dado_Corner_And_Skirting')

    for x in range(16, 32):
        y_top_low = 32 + ((31 - x) // 2)
        _paint_low_e_col(l0, l1, l2, x, y_top_low)

    for x in range(16, 32):
        y_full = 8 + ((x - 16) // 2)
        if x <= 20:
            y_top_n = y_full + 32
            _paint_low_s_col(l0, l1, l2, x, y_top_n)
        elif x <= 25:
            y_top_step = y_full + 16
            y_bot = y_full + 48
            for y in range(y_top_step, y_bot + 1):
                z_down = y - y_full
                if y == y_top_step:
                    l0.put(x, y, 9)
                    l2.put(x, y, 10)
                elif y == y_top_step + 1:
                    l0.put(x, y, 8)
                    l2.put(x, y, 14 if x in (22, 23) else 13)
                elif y == y_top_step + 2:
                    l0.put(x, y, 6)
                else:
                    l0.put(x, y, 7)
                    l1.put(x, y, 12 if x in (21, 25) else 13)
                if z_down == 35:
                    l2.put(x, y, 12)
                elif z_down == 36:
                    l2.put(x, y, 24)
                elif z_down == 37:
                    l2.put(x, y, 6)
                elif z_down in (46, 47):
                    l2.put(x, y, 11)
                elif z_down == 48:
                    l2.put(x, y, 0)
        else:
            _paint_tall_n_col(l0, l1, l2, x, y_full)
            if x in (26, 27):
                for z_down in range(3, 35):
                    l2.put(x, y_full + z_down, 13 if x == 26 else 12)

    for x in range(13, 19):
        y_top_b = 39 + (abs(x - 16) // 2)
        for z in range(0, 18):
            y = y_top_b + z
            if not (0 <= y < h):
                continue
            if z == 0:
                l2.put(x, y, 10)
            elif z == 1:
                l2.put(x, y, 14 if x in (15, 16) else 9)
            elif z == 5:
                l2.put(x, y, 25 if x >= 16 else 24)
            elif z in (15, 16):
                l2.put(x, y, 12)
            elif z == 17:
                l2.put(x, y, 0)
            else:
                l2.put(x, y, 13 if x in (15, 16) else 12)
    return [l0, l1, l2]


def gen_wall_corner_w_turn_outer():
    """32x64 W-turn outer_corner (faces=[low_S, W]) at West apex of room."""
    w, h = 32, 64
    l0 = Layer(w, h, 'Wall_Cornice_Backing')
    l1 = Layer(w, h, 'Ceramic_Tile_Course')
    l2 = Layer(w, h, 'Dado_Corner_And_Skirting')

    for x in range(16, 32):
        _paint_tall_w_col(l0, l1, l2, x, (31 - x) // 2)

    for x in range(10, 16):
        dx = 15 - x
        y_top = 7 - (dx // 2)
        for z_down in range(0, 49):
            y = y_top + z_down
            if not (0 <= y < h):
                continue
            if z_down == 0:
                l0.put(x, y, 10 if dx < 4 else 7)
            elif z_down == 1:
                l0.put(x, y, 9)
            elif z_down == 2:
                l0.put(x, y, 7)
            else:
                l0.put(x, y, 7 if dx >= 4 else 13)

            if 3 <= z_down <= 45:
                l1.put(x, y, 14 if dx in (0, 1) else (13 if dx in (2, 3) else 12))
                if z_down % 8 == 0 and dx in (1, 2):
                    l1.put(x, y, 15)

            if z_down == 35:
                l2.put(x, y, 14)
            elif z_down == 36:
                l2.put(x, y, 25 if dx < 4 else 24)
            elif z_down == 37:
                l2.put(x, y, 7)
            elif z_down in (46, 47):
                l2.put(x, y, 12)
            elif z_down == 48:
                l2.put(x, y, 0)

    for x in range(16, 32):
        y_top_low = 40 + ((x - 16) // 2)
        _paint_low_s_col(l0, l1, l2, x, y_top_low)

    for x in range(13, 19):
        y_top_b = 39 + (abs(x - 16) // 2)
        for z in range(0, 17):
            y = y_top_b + z
            if not (0 <= y < h):
                continue
            if z == 0:
                l2.put(x, y, 10)
            elif z == 1:
                l2.put(x, y, 14 if x in (15, 16) else 9)
            elif z == 4:
                l2.put(x, y, 13)
            elif z == 5:
                l2.put(x, y, 25 if x <= 15 else 24)
            elif z in (14, 15):
                l2.put(x, y, 12 if x <= 15 else 11)
            elif z == 16:
                l2.put(x, y, 0)
            else:
                l2.put(x, y, 14 if x in (14, 15) else (13 if x in (16, 17) else 12))
    return [l0, l1, l2]


def gen_wall_corner_w_turn_inner():
    """32x64 W-turn inner_corner (faces=[W, low_S]) at SW concave cut (Rule R2b)."""
    w, h = 32, 64
    l0 = Layer(w, h, 'Wall_Cornice_Backing')
    l1 = Layer(w, h, 'Ceramic_Tile_Course')
    l2 = Layer(w, h, 'Dado_Corner_And_Skirting')

    for x in range(16):
        y_top_low = 32 + (x // 2)
        _paint_low_s_col(l0, l1, l2, x, y_top_low)

    for x in range(16):
        y_full = 8 + ((15 - x) // 2)
        if x >= 11:
            y_top_w = y_full + 32
            _paint_low_e_col(l0, l1, l2, x, y_top_w)
        elif x >= 6:
            y_top_step = y_full + 16
            y_bot = y_full + 48
            for y in range(y_top_step, y_bot + 1):
                z_down = y - y_full
                if y == y_top_step:
                    l0.put(x, y, 10)
                    l2.put(x, y, 10)
                elif y == y_top_step + 1:
                    l0.put(x, y, 9)
                    l2.put(x, y, 14 if x in (8, 9) else 13)
                elif y == y_top_step + 2:
                    l0.put(x, y, 7)
                else:
                    l0.put(x, y, 8)
                    l1.put(x, y, 13 if x in (6, 10) else 14)
                if z_down == 35:
                    l2.put(x, y, 13)
                elif z_down == 36:
                    l2.put(x, y, 25)
                elif z_down == 37:
                    l2.put(x, y, 7)
                elif z_down in (46, 47):
                    l2.put(x, y, 12)
                elif z_down == 48:
                    l2.put(x, y, 0)
        else:
            _paint_tall_w_col(l0, l1, l2, x, y_full)
            if x in (4, 5):
                for z_down in range(3, 35):
                    l2.put(x, y_full + z_down, 14 if x == 5 else 13)

    for x in range(13, 19):
        y_top_b = 39 + (abs(x - 15) // 2)
        for z in range(0, 18):
            y = y_top_b + z
            if not (0 <= y < h):
                continue
            if z == 0:
                l2.put(x, y, 10)
            elif z == 1:
                l2.put(x, y, 14 if x in (15, 16) else 9)
            elif z == 5:
                l2.put(x, y, 25 if x <= 15 else 24)
            elif z in (15, 16):
                l2.put(x, y, 12)
            elif z == 17:
                l2.put(x, y, 0)
            else:
                l2.put(x, y, 14 if x in (14, 15) else 13)
    return [l0, l1, l2]


# ---------------------------------------------------------------------------
# (2) LOW S & E PARTITION PIECES (32x32, pivot (16, 24), height 16 px <= 20 px)
# ---------------------------------------------------------------------------

def gen_wall_partition_low_s():
    """32x32 straight 2-tile low_S partition run (vertical height 16 px <= 20 px per Rule R2)."""
    w, h = 32, 32
    l0 = Layer(w, h, 'Partition_Coping_Backing')
    l1 = Layer(w, h, 'Ceramic_Parapet_Course')
    l2 = Layer(w, h, 'Safety_Dado_And_Skirting')
    for x in range(w):
        _paint_low_s_col(l0, l1, l2, x, x // 2)
    return [l0, l1, l2]


def gen_wall_partition_low_e():
    """32x32 straight 2-tile low_E partition run (vertical height 16 px <= 20 px per Rule R2)."""
    w, h = 32, 32
    l0 = Layer(w, h, 'Partition_Coping_Backing')
    l1 = Layer(w, h, 'Ceramic_Parapet_Course')
    l2 = Layer(w, h, 'Safety_Dado_And_Skirting')
    for x in range(w):
        _paint_low_e_col(l0, l1, l2, x, (31 - x) // 2)
    return [l0, l1, l2]


def gen_wall_partition_low_corner_inner():
    """32x32 concave low inner_corner (faces=[low_S, low_E]) at SE L-cut apex (Rule R2b)."""
    w, h = 32, 32
    l0 = Layer(w, h, 'Partition_Coping_Backing')
    l1 = Layer(w, h, 'Ceramic_Parapet_Course')
    l2 = Layer(w, h, 'Safety_Dado_And_Skirting')

    for x in range(16):
        _paint_low_e_col(l0, l1, l2, x, 8 + ((15 - x) // 2))
    for x in range(16, 32):
        _paint_low_s_col(l0, l1, l2, x, 8 + ((x - 16) // 2))

    for x in range(13, 19):
        y_top = 8 + (0 if x in (15, 16) else 1)
        for z in range(0, 17):
            y = y_top + z
            if not (0 <= y < h):
                continue
            if z == 0:
                l2.put(x, y, 10 if x <= 15 else 9)
            elif z == 1:
                l2.put(x, y, 14 if x in (15, 16) else 9)
            elif z == 2:
                l2.put(x, y, 6)
            elif z == 4:
                l2.put(x, y, 13 if x <= 15 else 12)
            elif z == 5:
                l2.put(x, y, 25 if x <= 15 else 24)
            elif z == 6:
                l2.put(x, y, 6)
            elif z in (14, 15):
                l2.put(x, y, 12 if x <= 15 else 11)
            elif z == 16:
                l2.put(x, y, 0)
            else:
                if x in (14, 15):
                    l2.put(x, y, 13)
                elif x in (16, 17):
                    l2.put(x, y, 12)
                else:
                    l2.put(x, y, 11)
    return [l0, l1, l2]


def gen_wall_partition_low_corner_outer():
    """32x32 convex low outer_corner (faces=[low_E, low_S]) at South room apex."""
    w, h = 32, 32
    l0 = Layer(w, h, 'Partition_Coping_Backing')
    l1 = Layer(w, h, 'Ceramic_Parapet_Course')
    l2 = Layer(w, h, 'Safety_Dado_And_Skirting')

    for x in range(16):
        _paint_low_s_col(l0, l1, l2, x, x // 2)
    for x in range(16, 32):
        _paint_low_e_col(l0, l1, l2, x, (31 - x) // 2)

    for x in range(13, 19):
        y_top = 8 if x in (15, 16) else (7 if x in (14, 17) else 6)
        for z in range(0, 17):
            y = y_top + z
            if not (0 <= y < h):
                continue
            if z == 0:
                l2.put(x, y, 10 if x >= 15 else 9)
            elif z == 1:
                l2.put(x, y, 14 if x in (15, 16) else 9)
            elif z == 2:
                l2.put(x, y, 6)
            elif z == 4:
                l2.put(x, y, 14 if x in (15, 16) else 13)
            elif z == 5:
                l2.put(x, y, 26 if x in (15, 16) else (24 if x < 15 else 25))
            elif z == 6:
                l2.put(x, y, 6)
            elif z in (14, 15):
                l2.put(x, y, 13 if x in (15, 16) else (11 if x < 15 else 12))
            elif z == 16:
                l2.put(x, y, 0)
            else:
                if x in (15, 16):
                    l2.put(x, y, 14)
                elif x in (14, 17):
                    l2.put(x, y, 13)
                else:
                    l2.put(x, y, 12)
    return [l0, l1, l2]


# ---------------------------------------------------------------------------
# (3) LOW END CAP PIECES FOR TALL N/W WALL TERMINATIONS (Rule R2b, 32x64, pivot (16, 56))
# ---------------------------------------------------------------------------

def gen_wall_n_endcap_low():
    """32x64 low end-cap piece where a tall N wall terminates at an opening or odd 1-tile end (Rule R2b)."""
    w, h = 32, 64
    l0 = Layer(w, h, 'Wall_Cornice_Backing')
    l1 = Layer(w, h, 'Ceramic_Tile_Course')
    l2 = Layer(w, h, 'Dado_Corner_And_Skirting')

    for x in range(16):
        _paint_tall_n_col(l0, l1, l2, x, x // 2)
        if x in (13, 14, 15):
            y_top = x // 2
            for z_down in range(2, 46):
                if z_down not in (35, 36, 37):
                    l2.put(x, y_top + z_down, 13 if x == 14 else 12)

    for x in range(16, 23):
        y_full = 8 + ((x - 16) // 2)
        y_top_step = y_full + 18
        y_bot = y_full + 48
        for y in range(y_top_step, y_bot + 1):
            z_down = y - y_full
            if y == y_top_step:
                l0.put(x, y, 9)
                l2.put(x, y, 10)
            elif y == y_top_step + 1:
                l0.put(x, y, 8)
                l2.put(x, y, 14 if x in (18, 19) else 9)
            elif y == y_top_step + 2:
                l0.put(x, y, 6)
            else:
                l0.put(x, y, 7)
                l1.put(x, y, 12 if x in (16, 22) else 13)
                if z_down in (24, 30) and x in (18, 20):
                    l2.put(x, y, 14)

            if z_down == 35:
                l2.put(x, y, 12)
            elif z_down == 36:
                l2.put(x, y, 24)
            elif z_down == 37:
                l2.put(x, y, 6)
            elif z_down in (46, 47):
                l2.put(x, y, 11)
            elif z_down == 48:
                l2.put(x, y, 0)

    for x in range(23, 32):
        y_top_low = 40 + ((x - 16) // 2)
        _paint_low_s_col(l0, l1, l2, x, y_top_low)
        if x >= 28:
            for z in range(1, 16):
                y = y_top_low + z
                if z not in (4, 5, 6, 14, 15):
                    l2.put(x, y, 13 if x in (28, 29) else 11)
    return [l0, l1, l2]


def gen_wall_w_endcap_low():
    """32x64 low end-cap piece where a tall W wall terminates at an opening or odd 1-tile end (Rule R2b)."""
    w, h = 32, 64
    l0 = Layer(w, h, 'Wall_Cornice_Backing')
    l1 = Layer(w, h, 'Ceramic_Tile_Course')
    l2 = Layer(w, h, 'Dado_Corner_And_Skirting')

    for x in range(16, 32):
        _paint_tall_w_col(l0, l1, l2, x, (31 - x) // 2)
        if x in (16, 17, 18):
            y_top = (31 - x) // 2
            for z_down in range(2, 46):
                if z_down not in (35, 36, 37):
                    l2.put(x, y_top + z_down, 14 if x == 17 else 13)

    for x in range(9, 16):
        y_full = 8 + ((15 - x) // 2)
        y_top_step = y_full + 18
        y_bot = y_full + 48
        for y in range(y_top_step, y_bot + 1):
            z_down = y - y_full
            if y == y_top_step:
                l0.put(x, y, 10)
                l2.put(x, y, 10)
            elif y == y_top_step + 1:
                l0.put(x, y, 9)
                l2.put(x, y, 14 if x in (12, 13) else 9)
            elif y == y_top_step + 2:
                l0.put(x, y, 7)
            else:
                l0.put(x, y, 8)
                l1.put(x, y, 13 if x in (9, 15) else 14)
                if z_down in (24, 30) and x in (11, 13):
                    l2.put(x, y, 15)

            if z_down == 35:
                l2.put(x, y, 13)
            elif z_down == 36:
                l2.put(x, y, 25)
            elif z_down == 37:
                l2.put(x, y, 7)
            elif z_down in (46, 47):
                l2.put(x, y, 12)
            elif z_down == 48:
                l2.put(x, y, 0)

    for x in range(0, 9):
        y_top_low = 40 + ((15 - x) // 2)
        _paint_low_e_col(l0, l1, l2, x, y_top_low)
        if x <= 3:
            for z in range(1, 16):
                y = y_top_low + z
                if z not in (4, 5, 6, 14, 15):
                    l2.put(x, y, 14 if x in (2, 3) else 12)
    return [l0, l1, l2]


ASSETS = {
    'ch01_env_wall_subterranean_corner_nw_outer_idle': (
        32, 64, ['Wall_Cornice_Backing', 'Ceramic_Tile_Course', 'Dado_Corner_And_Skirting'],
        gen_wall_corner_nw_outer, (16, 56),
    ),
    'ch01_env_wall_subterranean_corner_nw_inner_idle': (
        32, 64, ['Wall_Cornice_Backing', 'Ceramic_Tile_Course', 'Dado_Corner_And_Skirting'],
        gen_wall_corner_nw_inner, (16, 56),
    ),
    'ch01_env_wall_subterranean_corner_n_turn_outer_idle': (
        32, 64, ['Wall_Cornice_Backing', 'Ceramic_Tile_Course', 'Dado_Corner_And_Skirting'],
        gen_wall_corner_n_turn_outer, (16, 56),
    ),
    'ch01_env_wall_subterranean_corner_n_turn_inner_idle': (
        32, 64, ['Wall_Cornice_Backing', 'Ceramic_Tile_Course', 'Dado_Corner_And_Skirting'],
        gen_wall_corner_n_turn_inner, (16, 56),
    ),
    'ch01_env_wall_subterranean_corner_w_turn_outer_idle': (
        32, 64, ['Wall_Cornice_Backing', 'Ceramic_Tile_Course', 'Dado_Corner_And_Skirting'],
        gen_wall_corner_w_turn_outer, (16, 56),
    ),
    'ch01_env_wall_subterranean_corner_w_turn_inner_idle': (
        32, 64, ['Wall_Cornice_Backing', 'Ceramic_Tile_Course', 'Dado_Corner_And_Skirting'],
        gen_wall_corner_w_turn_inner, (16, 56),
    ),
    'ch01_env_wall_partition_low_s_idle': (
        32, 32, ['Partition_Coping_Backing', 'Ceramic_Parapet_Course', 'Safety_Dado_And_Skirting'],
        gen_wall_partition_low_s, (16, 24),
    ),
    'ch01_env_wall_partition_low_e_idle': (
        32, 32, ['Partition_Coping_Backing', 'Ceramic_Parapet_Course', 'Safety_Dado_And_Skirting'],
        gen_wall_partition_low_e, (16, 24),
    ),
    'ch01_env_wall_partition_low_corner_inner_idle': (
        32, 32, ['Partition_Coping_Backing', 'Ceramic_Parapet_Course', 'Safety_Dado_And_Skirting'],
        gen_wall_partition_low_corner_inner, (16, 24),
    ),
    'ch01_env_wall_partition_low_corner_outer_idle': (
        32, 32, ['Partition_Coping_Backing', 'Ceramic_Parapet_Course', 'Safety_Dado_And_Skirting'],
        gen_wall_partition_low_corner_outer, (16, 24),
    ),
    'ch01_env_wall_subterranean_n_endcap_low_idle': (
        32, 64, ['Wall_Cornice_Backing', 'Ceramic_Tile_Course', 'Dado_Corner_And_Skirting'],
        gen_wall_n_endcap_low, (16, 56),
    ),
    'ch01_env_wall_subterranean_w_endcap_low_idle': (
        32, 64, ['Wall_Cornice_Backing', 'Ceramic_Tile_Course', 'Dado_Corner_And_Skirting'],
        gen_wall_w_endcap_low, (16, 56),
    ),
}


def assets():
    out = []
    for stem, (w, h, names, fn, piv) in ASSETS.items():
        out.append((stem, 'environments', w, h, names, [fn()], 1.0, [], {'pivot': piv}))
    return out


MOCKUP_FILES = [
    'ch01_tlf068_l_room_shape_kit_mockup.png',
    'ch01_tlf068_shape_kit_greyscale_proof.png',
]


def _render_kit_img(name):
    _w, _h, _names, fn, _piv = ASSETS[name]
    return to_image(composite(fn()))


def _load_or_render_env(name):
    if name in ASSETS:
        return _render_kit_img(name)
    p = os.path.join(REPO, 'assets', 'environments', 'ch01', f'{name}.png')
    return Image.open(p).convert('RGBA')


def _load_png(cat, name):
    p = os.path.join(REPO, 'assets', cat, 'ch01', f'{name}.png')
    return Image.open(p).convert('RGBA')


def _tile_to_px(tx, ty, origin=(320, 64)):
    return (int(round(origin[0] + (tx - ty) * 16)), int(round(origin[1] + (tx + ty) * 8)))


def build_l_room_mockup():
    """640x360 mockup of an L-shaped Chapter 1 room (with connected NW/NE/SW alcoves & SE L-cut)
    built from the TLF-068 shape kit so every corner, turn, low partition, and low end cap is shown
    connected to its matching wall runs.
    """
    W, H = 640, 360
    canvas = Image.new('RGBA', (W, H), PAL[0] + (255,))
    origin = (316, 88)

    terrazzo = _load_or_render_env('ch01_env_tile_terrazzo_dark_idle')
    cracked = _load_or_render_env('ch01_env_tile_terrazzo_cracked_idle')
    grating = _load_or_render_env('ch01_env_tile_industrial_grating_idle')
    tactile = _load_or_render_env('ch01_env_tile_tactile_amber_idle')

    wall_n = _load_or_render_env('ch01_env_wall_subterranean_n_idle')
    wall_w = _load_or_render_env('ch01_env_wall_subterranean_w_idle')

    c_nw_out = _render_kit_img('ch01_env_wall_subterranean_corner_nw_outer_idle')
    c_nw_in = _render_kit_img('ch01_env_wall_subterranean_corner_nw_inner_idle')
    c_nt_out = _render_kit_img('ch01_env_wall_subterranean_corner_n_turn_outer_idle')
    c_nt_in = _render_kit_img('ch01_env_wall_subterranean_corner_n_turn_inner_idle')
    c_wt_out = _render_kit_img('ch01_env_wall_subterranean_corner_w_turn_outer_idle')
    c_wt_in = _render_kit_img('ch01_env_wall_subterranean_corner_w_turn_inner_idle')

    low_s = _render_kit_img('ch01_env_wall_partition_low_s_idle')
    low_e = _render_kit_img('ch01_env_wall_partition_low_e_idle')
    low_c_in = _render_kit_img('ch01_env_wall_partition_low_corner_inner_idle')
    low_c_out = _render_kit_img('ch01_env_wall_partition_low_corner_outer_idle')

    end_n = _render_kit_img('ch01_env_wall_subterranean_n_endcap_low_idle')
    end_w = _render_kit_img('ch01_env_wall_subterranean_w_endcap_low_idle')

    elias_sheet = _load_png('characters', 'ch01_char_elias_base_sheet')
    elias_se = elias_sheet.crop((0, 0, 32, 48))
    elias_nw = elias_sheet.crop((64, 0, 96, 48))
    bench = _load_png('props', 'ch01_prop_station_bench_idle')
    console = _load_png('props', 'ch01_prop_reset_console_idle')
    clock = _load_png('props', 'ch01_prop_digital_clock_2359_idle')

    # Outline polygon (12x10 with NW 2x2 alcove step [0..2)x[0..2), SE 4x4 L-cut [8..12)x[6..10),
    # plus N corridor mouth [6..7)x[-2..0) and W corridor mouth [-2..0)x[6..7)):
    # Every tall face is N or W; every S or E face is a 16 px low partition (100% Rule R2 + R2b compliant!).
    def in_room(tx, ty):
        if tx == 6 and -2 <= ty < 0:
            return True
        if ty == 6 and -2 <= tx < 0:
            return True
        if not (0 <= tx < 12 and 0 <= ty < 10):
            return False
        if tx < 2 and ty < 2:
            return False
        if tx >= 8 and ty >= 6:
            return False
        return True

    for ty in range(-2, 10):
        for tx in range(-2, 12):
            if not in_room(tx, ty):
                continue
            px, py = _tile_to_px(tx, ty, origin)
            if (tx, ty) in ((4, 4), (9, 3), (4, 7)):
                t_im = grating
            elif (tx + ty * 3) % 7 == 0:
                t_im = cracked
            elif (ty == 5 and 8 <= tx < 12) or (tx == 6 and ty == -1) or (ty == 6 and tx == -1):
                t_im = tactile
            else:
                t_im = terrazzo
            canvas.alpha_composite(t_im, (px - 16, py))

    draws = []

    def add_piece(img, anchor_px, pivot, z_bias=0):
        ax, ay = anchor_px
        pw, ph = pivot
        draws.append((ay + z_bias, ax, img, (ax - pw, ay - ph)))

    # 1. Back N wall (2, 0) -> (12, 0) with N corridor mouth at x=6..7:
    #    - West side of N corridor mouth: wall_n at (3, 0) + n_endcap_low at (5, 0) stepping down to opening
    #    - East side of N corridor mouth: low_E partition at (7, -1) turning into tall N wall via c_nt_in at (7, 0)
    add_piece(low_e, _tile_to_px(7, -1, origin), (16, 24), z_bias=-16)
    add_piece(wall_n, _tile_to_px(3, 0, origin), (16, 56), z_bias=-2)
    add_piece(end_n, _tile_to_px(5, 0, origin), (16, 56), z_bias=2)
    add_piece(wall_n, _tile_to_px(9, 0, origin), (16, 56), z_bias=-2)
    add_piece(wall_n, _tile_to_px(11, 0, origin), (16, 56), z_bias=-2)
    add_piece(c_nt_in, _tile_to_px(7, 0, origin), (16, 56), z_bias=2)

    # 2. NW step walls: W wall (2, 0)->(2, 2) and N wall (0, 2)->(2, 2), meeting at nw_inner (2, 2)!
    add_piece(wall_w, _tile_to_px(2, 1, origin), (16, 56), z_bias=-2)
    add_piece(wall_n, _tile_to_px(1, 2, origin), (16, 56), z_bias=-2)
    add_piece(c_nw_out, _tile_to_px(2, 0, origin), (16, 56), z_bias=10)
    add_piece(c_nw_in, _tile_to_px(2, 2, origin), (16, 56), z_bias=12)
    add_piece(c_nw_out, _tile_to_px(0, 2, origin), (16, 56), z_bias=10)

    # 3. West W wall (0, 2) -> (0, 10) with W corridor mouth at y=6..7:
    #    - North side of W corridor mouth: wall_w at (0, 3) + w_endcap_low at (0, 5) stepping down to opening
    #    - South side of W corridor mouth: low_S partition at (-1, 7) turning into tall W wall via c_wt_in at (0, 7)
    add_piece(low_s, _tile_to_px(-1, 7, origin), (16, 24), z_bias=-16)
    add_piece(wall_w, _tile_to_px(0, 3, origin), (16, 56), z_bias=-2)
    add_piece(end_w, _tile_to_px(0, 5, origin), (16, 56), z_bias=2)
    add_piece(wall_w, _tile_to_px(0, 9, origin), (16, 56), z_bias=-2)
    add_piece(c_wt_in, _tile_to_px(0, 7, origin), (16, 56), z_bias=2)

    # 4. East N-turn outer corner at (12, 0) & West W-turn outer corner at (0, 10):
    add_piece(c_nt_out, _tile_to_px(12, 0, origin), (16, 56), z_bias=10)
    add_piece(c_wt_out, _tile_to_px(0, 10, origin), (16, 56), z_bias=10)

    # 5. Low_E and Low_S partitions around the SE L-cut (8, 6):
    for ky in (1, 3, 5):
        add_piece(low_e, _tile_to_px(12, ky, origin), (16, 24), z_bias=-2)
    for kx in (9, 11):
        add_piece(low_s, _tile_to_px(kx, 6, origin), (16, 24), z_bias=-2)
    for ky in (7, 9):
        add_piece(low_e, _tile_to_px(8, ky, origin), (16, 24), z_bias=-2)
    for kx in (1, 3, 5, 7):
        add_piece(low_s, _tile_to_px(kx, 10, origin), (16, 24), z_bias=-2)

    add_piece(low_c_in, _tile_to_px(8, 6, origin), (16, 24), z_bias=10)
    add_piece(low_c_out, _tile_to_px(12, 6, origin), (16, 24), z_bias=10)
    add_piece(low_c_out, _tile_to_px(8, 10, origin), (16, 24), z_bias=10)

    # 6. Props, wall fixtures (sorted in front of walls), and Elias beside low partitions (Rule R2 proof)
    add_piece(console, _tile_to_px(10.0, 3.5, origin), (16, 30), z_bias=0)
    add_piece(bench, _tile_to_px(5.0, 4.5, origin), (24, 26), z_bias=0)
    add_piece(clock, _tile_to_px(3.5, 0, origin), (16, 48), z_bias=32)
    add_piece(clock, _tile_to_px(9.8, 0, origin), (16, 48), z_bias=32)

    add_piece(elias_se, _tile_to_px(7.4, 5.4, origin), (16, 44), z_bias=-4)
    add_piece(elias_nw, _tile_to_px(4.2, 9.3, origin), (16, 44), z_bias=-4)

    draws.sort(key=lambda item: (item[0], item[1]))
    for _y, _x, img, pos in draws:
        canvas.alpha_composite(img, pos)

    # Header & clean non-overlapping callouts
    _draw_text_img(canvas, 8, 5, "TLF-068 L-SHAPE ROOM MOCKUP (12X10 L-OUTLINE, ADR-023 R2/R2B)", PAL[15], scale=1)
    _draw_text_img(canvas, 8, 15, "ALL 12 KIT PIECES CONNECTED: NW CORNERS, N/W TURNS, END CAPS, LOW S/E (16PX <= 20PX)", PAL[25], scale=1)

    _draw_text_img(canvas, 232, 30, "NW_OUTER (2,0)", PAL[15], scale=1)
    _draw_text_img(canvas, 372, 46, "N_ENDCAP + N_TURN_IN", PAL[25], scale=1)
    _draw_text_img(canvas, 496, 122, "N_TURN_OUT (12,0)", PAL[15], scale=1)
    _draw_text_img(canvas, 504, 212, "LOW_OUTER (12,6)", PAL[15], scale=1)
    _draw_text_img(canvas, 364, 224, "LOW_INNER (8,6) + ELIAS", PAL[26], scale=1)
    _draw_text_img(canvas, 344, 304, "LOW_OUTER (8,10)", PAL[15], scale=1)
    _draw_text_img(canvas, 52, 228, "W_TURN_OUT (0,10)", PAL[15], scale=1)
    _draw_text_img(canvas, 32, 134, "W_ENDCAP + W_TURN_IN", PAL[25], scale=1)
    _draw_text_img(canvas, 108, 66, "NW_INNER (2,2)", PAL[26], scale=1)

    # Bottom-left inset: L-outline floor tileset concave-cut seam verification (Item 4)
    inset = Image.new('RGBA', (248, 72), PAL[1] + (255,))
    for x in range(248):
        inset.putpixel((x, 0), PAL[13] + (255,))
        inset.putpixel((x, 71), PAL[13] + (255,))
    for y in range(72):
        inset.putpixel((0, y), PAL[13] + (255,))
        inset.putpixel((247, y), PAL[13] + (255,))
    _draw_text_img(inset, 6, 6, "ITEM 4: L-CUT FLOOR", PAL[26], scale=1)
    _draw_text_img(inset, 6, 18, "0 GAP PX BETWEEN TILES", PAL[15], scale=1)
    _draw_text_img(inset, 6, 30, "2PX 141A26 MORTAR RIM", PAL[14], scale=1)
    _draw_text_img(inset, 6, 42, "NO EXTRA EDGE TILE", PAL[25], scale=1)
    _draw_text_img(inset, 6, 54, "NEEDED ON CONCAVE CUTS", PAL[25], scale=1)
    for fy in range(3):
        for fx in range(3):
            if (fx, fy) in ((1, 2), (2, 1), (2, 2)):
                continue
            ix = 196 + (fx - fy) * 16 - 16
            iy = 16 + (fx + fy) * 8
            inset.alpha_composite(terrazzo, (ix, iy))
    canvas.alpha_composite(inset, (6, 282))

    return canvas


def build_greyscale_proof():
    """1320x1040 colour + luminance greyscale proof of the 640x360 L-shaped room mockup
    and all 12 TLF-068 shape kit pieces (at x2 and 1x native) with pivot markers.
    """
    W, H = 1320, 1040
    canvas = Image.new('RGBA', (W, H), PAL[0] + (255,))

    l_room = build_l_room_mockup()
    l_room_grey = l_room.convert('L').convert('RGBA')

    _draw_text_img(canvas, 16, 10, "TLF-068 SHAPE ART KIT - 640X360 L-ROOM MOCKUP (LEFT: COLOUR, RIGHT: LUMINANCE GREYSCALE PROOF)", PAL[15], scale=2)
    canvas.alpha_composite(l_room, (16, 34))
    canvas.alpha_composite(l_room_grey, (664, 34))

    panel = Image.new('RGBA', (W, 276), PAL[1] + (255,))

    order = [
        ('ch01_env_wall_subterranean_corner_nw_outer_idle', '1. NW_OUTER', '(W,N) CONVEX'),
        ('ch01_env_wall_subterranean_corner_nw_inner_idle', '2. NW_INNER', '(N,W) CONCAVE'),
        ('ch01_env_wall_subterranean_corner_n_turn_outer_idle', '3. N_TURN_OUT', '(N,LOW_E)'),
        ('ch01_env_wall_subterranean_corner_n_turn_inner_idle', '4. N_TURN_IN', '(LOW_E,N)'),
        ('ch01_env_wall_subterranean_corner_w_turn_outer_idle', '5. W_TURN_OUT', '(LOW_S,W)'),
        ('ch01_env_wall_subterranean_corner_w_turn_inner_idle', '6. W_TURN_IN', '(W,LOW_S)'),
        ('ch01_env_wall_subterranean_n_endcap_low_idle', '7. N_ENDCAP', 'R2B STEP-DOWN'),
        ('ch01_env_wall_subterranean_w_endcap_low_idle', '8. W_ENDCAP', 'R2B STEP-DOWN'),
        ('ch01_env_wall_partition_low_s_idle', '9. LOW_S', '16PX STRAIGHT'),
        ('ch01_env_wall_partition_low_e_idle', '10. LOW_E', '16PX STRAIGHT'),
        ('ch01_env_wall_partition_low_corner_inner_idle', '11. LOW_IN', '(LOW_S,LOW_E)'),
        ('ch01_env_wall_partition_low_corner_outer_idle', '12. LOW_OUT', '(LOW_E,LOW_S)'),
    ]

    for idx, (name, short, sub) in enumerate(order):
        w, h, _ln, _fn, piv = ASSETS[name]
        img = _render_kit_img(name)
        card = Image.new('RGBA', (w + 4, h + 4), PAL[2] + (255,))
        card.alpha_composite(img, (2, 2))
        px, py = piv[0] + 2, piv[1] + 2
        if 0 <= px < card.width and 0 <= py < card.height:
            card.putpixel((px, py), PAL[26] + (255,))
        z2 = card.resize(((w + 4) * 2, (h + 4) * 2), Image.NEAREST)
        cx = 16 + idx * 108
        cy = 10 + (64 - h)
        panel.alpha_composite(z2, (cx, cy))
        panel.alpha_composite(img, (cx + 20, 156 + (64 - h) // 2))
        _draw_text_img(panel, cx, 230, short, PAL[15], scale=1)
        _draw_text_img(panel, cx, 242, sub, PAL[25], scale=1)
        _draw_text_img(panel, cx, 254, f"{w}X{h} P{piv[0]},{piv[1]}", PAL[14], scale=1)

    _draw_text_img(canvas, 16, 408, "ALL 12 TLF-068 KIT PIECES AT X2 + 1X NATIVE WITH PIVOT CROSSHAIR (COLOUR):", PAL[26], scale=2)
    canvas.alpha_composite(panel, (0, 430))
    _draw_text_img(canvas, 16, 720, "LUMINANCE GREYSCALE PROOF OF ALL 12 TLF-068 KIT PIECES (CONVERT L):", PAL[15], scale=2)
    canvas.alpha_composite(panel.convert('L').convert('RGBA'), (0, 742))
    return canvas


def mockup_path(name, out_dir=None):
    base = out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups')
    return os.path.join(base, name)


def write_mockups(out_dir=None):
    os.makedirs(out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups'), exist_ok=True)
    m1 = build_l_room_mockup()
    m1.save(mockup_path('ch01_tlf068_l_room_shape_kit_mockup.png', out_dir))
    m2 = build_greyscale_proof()
    m2.save(mockup_path('ch01_tlf068_shape_kit_greyscale_proof.png', out_dir))
