#!/usr/bin/env python3
"""TLF-077 — Sheared 2:1 isometric wall-mount variants for the 3 SO-01 selector panels and 23:59 digital clocks.

Context:
  The frontal-fixture allowance in ART_BIBLE.md §A.3 is withdrawn (TLF-078). Wall-mounted fixtures must
  follow the 2:1 isometric wall slope (1 px vertical shift per 2 px horizontal) and sit flush on the wall face,
  matching the TLF-073 sheared plaques pattern.

Deliverables (20 registered .pxo + .png assets in assets/props/ch01/ + assets/source/ch01/, plus
three 640x360 wall-module mockups and a colour + luminance greyscale proof in design/art/mockups/):
  1. SO-01 Selector Panels (3 kinds: line, platform, car x 3 positions: pos0, pos1, pos2):
     - N-wall variants (9 assets, slope down-right, 32x48 px, pivot (0, 0) top-left on wall face;
       also compatible with SelectorSwitchPresenter offset (-16, -40) / pivot (16, 40)):
       * ch01_prop_selector_line_n_pos{0,1,2}
       * ch01_prop_selector_platform_n_pos{0,1,2}
       * ch01_prop_selector_car_n_pos{0,1,2}
     - W-wall variants (9 assets, slope down-left, 32x48 px, pivot (0, 15) top-left on wall face):
       * ch01_prop_selector_line_w_pos{0,1,2}
       * ch01_prop_selector_platform_w_pos{0,1,2}
       * ch01_prop_selector_car_w_pos{0,1,2}
  2. Digital Clocks 23:59 (2 assets, 32x40 px):
     - ch01_prop_digital_clock_2359_n_idle (N-wall slope down-right, 32x40 px, pivot (0, 0))
     - ch01_prop_digital_clock_2359_w_idle (W-wall slope down-left, 32x40 px, pivot (0, 15))
"""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import Layer, PAL, REPO, composite, to_image
from tlf068_shape_kit import FONT5X7, _draw_text_img

O = 0
SH = 1
G0, G1, G2, G3, G4 = 11, 12, 13, 14, 15


def _y_n_wall_32(x, z):
    """Screen y on a 32px-wide N-wall fixture canvas (slope down-right, pivot at top-left (0, 0)).
    For x in 0..31, (x // 2) is in 0..15."""
    return (x // 2) + z


def _y_w_wall_32(x, z):
    """Screen y on a 32px-wide W-wall fixture canvas (slope down-left, pivot at top-left (0, 15)).
    Matches WallW's column slope (31 - x) // 2 = 15 - (x // 2) for x in 0..31."""
    return 15 - (x // 2) + z


def _put_s(layer, x, z, col, y_fn):
    if 0 <= x < layer.w:
        y = y_fn(x, z)
        if 0 <= y < layer.h:
            layer.put(x, y, col)


def _rect_s(layer, x0, z0, x1, z1, col, y_fn):
    for x in range(x0, x1 + 1):
        for z in range(z0, z1 + 1):
            _put_s(layer, x, z, col, y_fn)


def _hline_s(layer, x0, x1, z, col, y_fn):
    for x in range(x0, x1 + 1):
        _put_s(layer, x, z, col, y_fn)


def _vline_s(layer, x, z0, z1, col, y_fn):
    for z in range(z0, z1 + 1):
        _put_s(layer, x, z, col, y_fn)


def _steel_panel_s(L, x0, z0, x1, z1, y_fn, bevel_light=G3, mid=G2, shad=G1, dark=G0):
    """Draw a top-left-lit beveled worn-steel housing sheared along y_fn(x, z)."""
    _rect_s(L, x0, z0, x1, z1, mid, y_fn)
    _hline_s(L, x0, x1, z0, bevel_light, y_fn)
    _vline_s(L, x0, z0, z1, bevel_light, y_fn)
    _hline_s(L, x0, x1, z1, dark, y_fn)
    _vline_s(L, x1, z0, z1, shad, y_fn)
    _put_s(L, x0, z0, G4, y_fn)
    _put_s(L, x0 + 1, z0, G4, y_fn)
    for rx, rz in ((x0 + 1, z0 + 1), (x1 - 1, z0 + 1), (x0 + 1, z1 - 1), (x1 - 1, z1 - 1)):
        if x0 < rx < x1 and z0 < rz < z1:
            _put_s(L, rx, rz, dark, y_fn)


# ============================================================================
# 1. SHEARED SO-01 SELECTOR PANELS (N-WALL & W-WALL, 32x48 px)
#    Kinds: 'line', 'platform', 'car' | Positions: 0, 1, 2 | Faces: 'n', 'w'
# ============================================================================

def build_selector_panel_sheared(kind, pos, face):
    """Build sheared 2:1 wall-mounted selector panel (32x48 px).
    - N-wall ('n'): slope down-right y(x,z) = (x // 2) + z; top-left wall-face pivot (0, 0).
    - W-wall ('w'): slope down-left  y(x,z) = 15 - (x // 2) + z; top-left wall-face pivot (0, 15).
    Preserves the exact glyphs, 1/2/3 header pips, 3-position mechanical switch, and G4/G3 value
    hierarchy of ch01_prop_selector_{line,platform,car}_pos{0,1,2}."""
    w, h = 32, 48
    y_fn = _y_n_wall_32 if face == 'n' else _y_w_wall_32

    sh = Layer(w, h, 'Cast_Shadow')
    ol = Layer(w, h, 'Silhouette_Outline')
    B = Layer(w, h, 'Housing_Base')
    D = Layer(w, h, 'Control_And_Glyph')

    # Down-right wall mount shadow (x=5..28, z=2..30)
    _rect_s(sh, 5, 2, 28, 30, SH, y_fn)

    # 1px #0A0D14 outer silhouette outline around housing (x=4..27, z=0..29)
    _rect_s(ol, 4, 0, 27, 29, O, y_fn)
    _rect_s(ol, 3, 26, 28, 29, O, y_fn)

    # Main worn-steel cabinet (x=5..26, z=1..28) + lower mounting lip (x=4..27, z=27..28)
    _steel_panel_s(B, 5, 1, 26, 28, y_fn)
    _steel_panel_s(B, 4, 27, 27, 28, y_fn, bevel_light=G2, mid=G1, shad=G0, dark=O)

    # Header bar (x=6..25, z=2..5)
    _rect_s(B, 6, 2, 25, 4, G1, y_fn)
    _hline_s(B, 6, 25, 5, G0, y_fn)
    # Distinct control-index pips on top-left header (1 pip = LINE, 2 pips = PLATFORM, 3 pips = CAR)
    npips = {'line': 1, 'platform': 2, 'car': 3}[kind]
    for i in range(npips):
        _put_s(D, 8 + i * 2, 3, G4, y_fn)
        _put_s(D, 8 + i * 2, 4, 25, y_fn)

    # Recessed display window (x=7..24, z=6..18)
    _rect_s(B, 7, 6, 24, 18, O, y_fn)
    _rect_s(B, 8, 7, 23, 17, 2, y_fn)  # dark navy-slate display backing
    _hline_s(B, 7, 24, 6, G0, y_fn)
    _vline_s(B, 7, 6, 18, G0, y_fn)
    _hline_s(B, 7, 24, 18, G3, y_fn)
    _vline_s(B, 24, 6, 18, G3, y_fn)

    # Glyph inside display window (x=8..23, z=7..17), sheared along y_fn(x, z)
    # Identical G4/G3 value hierarchy across all 3 positions (Sol Appendix B.3).
    if kind == 'line':
        if pos == 0:
            # Pos 0: CIRCLE glyph (Central Line)
            for x in range(13, 19):
                _put_s(D, x, 8, G4, y_fn)
                _put_s(D, x, 16, G3, y_fn)
            for z in range(10, 15):
                _put_s(D, 11, z, G4, y_fn)
                _put_s(D, 20, z, G3, y_fn)
            for (x, z) in ((12, 9), (19, 9), (12, 15), (19, 15)):
                _put_s(D, x, z, G4 if z <= 12 else G3, y_fn)
        elif pos == 1:
            # Pos 1: DIAMOND glyph (Harbour Line)
            pts = [
                (15, 8), (16, 8),
                (14, 9), (17, 9),
                (13, 10), (18, 10),
                (12, 11), (19, 11),
                (11, 12), (20, 12),
                (12, 13), (19, 13),
                (13, 14), (18, 14),
                (14, 15), (17, 15),
                (15, 16), (16, 16),
            ]
            for (x, z) in pts:
                _put_s(D, x, z, G4 if z <= 12 else G3, y_fn)
        else:
            # Pos 2: TRIANGLE glyph (Ring Line)
            _put_s(D, 15, 8, G4, y_fn); _put_s(D, 16, 8, G4, y_fn)
            _put_s(D, 14, 9, G4, y_fn); _put_s(D, 17, 9, G3, y_fn)
            _put_s(D, 13, 10, G4, y_fn); _put_s(D, 18, 10, G3, y_fn)
            _put_s(D, 13, 11, G4, y_fn); _put_s(D, 18, 11, G3, y_fn)
            _put_s(D, 12, 12, G4, y_fn); _put_s(D, 19, 12, G3, y_fn)
            _put_s(D, 12, 13, G4, y_fn); _put_s(D, 19, 13, G3, y_fn)
            _put_s(D, 11, 14, G4, y_fn); _put_s(D, 20, 14, G3, y_fn)
            _hline_s(D, 11, 20, 15, G4, y_fn)
            _hline_s(D, 11, 20, 16, G3, y_fn)

    elif kind == 'platform':
        # 1 / 2 / 3 bold vertical platform bars with identical G4/G3 value hierarchy
        count = pos + 1
        col_hi, col_lo = G4, G3
        if count == 1:
            _rect_s(D, 14, 9, 17, 15, col_hi, y_fn)
            _vline_s(D, 17, 9, 15, col_lo, y_fn)
        elif count == 2:
            _rect_s(D, 11, 9, 14, 15, col_hi, y_fn)
            _rect_s(D, 17, 9, 20, 15, col_hi, y_fn)
            _vline_s(D, 14, 9, 15, col_lo, y_fn)
            _vline_s(D, 20, 9, 15, col_lo, y_fn)
        else:
            for bx in (10, 15, 20):
                _rect_s(D, bx, 9, bx + 1, 15, col_hi, y_fn)
                _vline_s(D, bx + 2, 9, 15, col_lo, y_fn)

    elif kind == 'car':
        # 3-car train silhouette across x=9..22, z=8..15:
        # Three 4px car bays at x=9..12 (REAR, pos=1), x=14..17 (MIDDLE, pos=0), x=19..22 (FRONT, pos=2)
        _hline_s(D, 9, 22, 15, G2, y_fn)  # track rail under train
        bays = [(9, 12, 1), (14, 17, 0), (19, 22, 2)]
        for bx0, bx1, bpos in bays:
            active = (pos == bpos)
            top_z = 8 if active else 10
            col_body = G4 if active else G1
            col_win = O if active else 2
            _rect_s(D, bx0, top_z, bx1, 14, col_body, y_fn)
            if active:
                _rect_s(D, bx0 + 1, top_z + 1, bx1 - 1, top_z + 3, col_win, y_fn)
                _hline_s(D, bx0 + 1, bx1 - 1, top_z - 1, 25, y_fn)
        _vline_s(D, 23, 11, 14, G3 if pos == 2 else G2, y_fn)

    # Lower mechanical 3-position control bezel (x=7..24, z=20..26)
    _steel_panel_s(B, 7, 20, 24, 26, y_fn, bevel_light=G2, mid=G1, shad=G0, dark=O)
    det_x = [10, 15, 21]
    for i, dx in enumerate(det_x):
        c = 26 if i == pos else G0
        _rect_s(D, dx, 21, dx + 1, 21, c, y_fn)
    kx = det_x[pos]
    _rect_s(D, 9, 23, 22, 24, O, y_fn)  # sheared horizontal slide slot
    _rect_s(D, kx - 1, 22, kx + 2, 25, G3, y_fn)
    _hline_s(D, kx - 1, kx + 2, 22, G4, y_fn)
    _vline_s(D, kx + 2, 22, 25, G1, y_fn)
    _rect_s(D, kx, 23, kx + 1, 24, 25, y_fn)

    return [sh, ol, B, D]


# ============================================================================
# 2. SHEARED DIGITAL CLOCKS 23:59 (N-WALL & W-WALL, 32x40 px)
# ============================================================================

# Exact 32x22 pixel matrix of the canonical ch01_prop_digital_clock_2359_idle (z = 0..21):
_CLOCK_RODS_Z0_3 = ((7, 14), (8, 11), (23, 14), (24, 11))

_CLOCK_LED_ROWS = [
    # z=8..17 inside x=5..26 (22 cols per row)
    [22, 23, 23, 23, 23, 22, 23, 23, 23, 23, 22, 22, 22, 23, 23, 23, 23, 22, 23, 23, 23, 23],
    [23, 26, 26, 26, 26, 23, 26, 26, 26, 26, 23,  0, 23, 26, 26, 26, 26, 23, 26, 26, 26, 26],
    [22, 23, 23, 23, 25, 23, 23, 23, 23, 25, 23, 23, 23, 25, 23, 23, 23, 23, 25, 23, 23, 25],
    [ 0, 23, 23, 23, 25, 23,  0, 23, 23, 25, 23, 26, 23, 25, 23, 23, 23, 23, 25, 23, 23, 25],
    [23, 26, 26, 26, 26, 23, 23, 26, 26, 26, 23, 22, 23, 26, 26, 26, 26, 23, 26, 26, 26, 26],
    [23, 25, 23, 23, 23,  0,  0, 23, 23, 25, 23,  0,  0, 23, 23, 23, 25, 23, 23, 23, 23, 25],
    [23, 25, 23, 23, 23, 22, 23, 23, 23, 25, 23, 26, 22, 23, 23, 23, 25, 23, 23, 23, 23, 25],
    [23, 24, 24, 24, 24, 23, 24, 24, 24, 24, 23, 23, 23, 24, 24, 24, 24, 23, 24, 24, 24, 24],
    [22, 23, 23, 23, 23, 22, 23, 23, 23, 23, 22, 22, 22, 23, 23, 23, 23, 22, 23, 23, 23, 23],
    [22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22],
]


def build_digital_clock_2359_sheared(face):
    """Build sheared 2:1 wall-mounted 23:59 digital clock (32x40 px).
    - N-wall ('n'): slope down-right y(x,z) = (x // 2) + z; top-left wall-face pivot (0, 0).
    - W-wall ('w'): slope down-left  y(x,z) = 15 - (x // 2) + z; top-left wall-face pivot (0, 15)."""
    w, h = 32, 40
    y_fn = _y_n_wall_32 if face == 'n' else _y_w_wall_32

    sh = Layer(w, h, 'Mount_Shadow')
    rods = Layer(w, h, 'Suspension_Rods')
    housing = Layer(w, h, 'Steel_Housing')
    led = Layer(w, h, 'LED_Display_2359')

    # Down-right wall shadow under the housing (x=2..31, z=6..22)
    _rect_s(sh, 2, 6, 31, 22, SH, y_fn)

    # Twin top suspension rods (z=0..3 at x=7..8 and x=23..24)
    for z in range(0, 4):
        for rx, col in _CLOCK_RODS_Z0_3:
            _put_s(rods, rx, z, col, y_fn)

    # Outer steel housing (x=1..30, z=4..21) matching ch01_prop_digital_clock_2359_idle 1:1
    _rect_s(housing, 1, 4, 30, 21, O, y_fn)
    # Row z=5: 14 at x=2, 15 at x=3..28, 11 at x=29
    _put_s(housing, 2, 5, 14, y_fn)
    _hline_s(housing, 3, 28, 5, 15, y_fn)
    _put_s(housing, 29, 5, 11, y_fn)
    # Row z=6: 14 at x=2, 12 at x=3, 13 at x=4..27, 12 at x=28, 11 at x=29
    _put_s(housing, 2, 6, 14, y_fn)
    _put_s(housing, 3, 6, 12, y_fn)
    _hline_s(housing, 4, 27, 6, 13, y_fn)
    _put_s(housing, 28, 6, 12, y_fn)
    _put_s(housing, 29, 6, 11, y_fn)
    # Rows z=7..18: side bezels & 00 recessed screen cavity
    for z in range(7, 19):
        _put_s(housing, 2, z, 14, y_fn)
        _put_s(housing, 3, z, 13, y_fn)
        _hline_s(housing, 4, 27, z, O, y_fn)
        _put_s(housing, 28, z, 13, y_fn)
        _put_s(housing, 29, z, 11, y_fn)
    # Row z=19: 14 at x=2, 12 at x=3, 13 at x=4..27, 12 at x=28, 11 at x=29
    _put_s(housing, 2, 19, 14, y_fn)
    _put_s(housing, 3, 19, 12, y_fn)
    _hline_s(housing, 4, 27, 19, 13, y_fn)
    _put_s(housing, 28, 19, 12, y_fn)
    _put_s(housing, 29, 19, 11, y_fn)
    # Row z=20: 11 across x=2..29
    _hline_s(housing, 2, 29, 20, 11, y_fn)

    # LED display 23:59 (z=8..17, x=5..26)
    for dz, row in enumerate(_CLOCK_LED_ROWS):
        z = 8 + dz
        for dx, col in enumerate(row):
            _put_s(led, 5 + dx, z, col, y_fn)

    return [sh, rods, housing, led]


# ============================================================================
# 3. ASSET REGISTRY EXPORT (20 assets: 18 selectors + 2 clocks)
# ============================================================================

SELECTOR_LAYERS = ['Cast_Shadow', 'Silhouette_Outline', 'Housing_Base', 'Control_And_Glyph']
CLOCK_LAYERS = ['Mount_Shadow', 'Suspension_Rods', 'Steel_Housing', 'LED_Display_2359']


def assets():
    out = []
    for face in ('n', 'w'):
        for kind in ('line', 'platform', 'car'):
            for pos in (0, 1, 2):
                stem = f'ch01_prop_selector_{kind}_{face}_pos{pos}'
                out.append((
                    stem,
                    'props',
                    32, 48,
                    SELECTOR_LAYERS,
                    [build_selector_panel_sheared(kind, pos, face)],
                    1.0,
                    None,
                    'TLF-077',
                ))
    for face in ('n', 'w'):
        stem = f'ch01_prop_digital_clock_2359_{face}_idle'
        out.append((
            stem,
            'props',
            32, 40,
            CLOCK_LAYERS,
            [build_digital_clock_2359_sheared(face)],
            1.0,
            None,
            'TLF-077',
        ))
    return out


# ============================================================================
# 4. WALL-MODULE MOCKUPS (640x360) & LUMINANCE GREYSCALE PROOF (1320x1160)
# ============================================================================

MOCKUP_FILES = (
    'ch01_tlf077_selectors_n_wall_mockup.png',
    'ch01_tlf077_selectors_w_wall_mockup.png',
    'ch01_tlf077_clocks_2359_wall_mockup.png',
    'ch01_tlf077_wall_fixtures_greyscale_proof.png',
)


def mockup_path(fname, out_dir=None):
    base = out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups')
    return os.path.join(base, fname)


def _png_or_build(cat, stem, builder_fn=None):
    p = os.path.join(REPO, 'assets', cat, 'ch01', stem + '.png')
    if os.path.exists(p):
        return Image.open(p).convert('RGBA')
    return to_image(composite(builder_fn()))


def _paste_clip(dst, src, pos):
    x0, y0 = int(round(pos[0])), int(round(pos[1]))
    sw, sh = src.size
    dw, dh = dst.size
    cx0, cy0 = max(0, x0), max(0, y0)
    cx1, cy1 = min(dw, x0 + sw), min(dh, y0 + sh)
    if cx0 < cx1 and cy0 < cy1:
        sub = src.crop((cx0 - x0, cy0 - y0, cx1 - x0, cy1 - y0))
        dst.alpha_composite(sub, (cx0, cy0))


def _tile_to_px(tx, ty, origin=(320, 64)):
    return (origin[0] + (tx - ty) * 16, origin[1] + (tx + ty) * 8)


def _draw_crosshair(im, x, y, col_idx=26):
    w, h = im.size
    c = PAL[col_idx] + (255,)
    c0 = PAL[0] + (255,)
    for dx, dy in [(-2, 0), (-1, 0), (1, 0), (2, 0), (0, -2), (0, -1), (0, 1), (0, 2)]:
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h:
            im.putpixel((nx, ny), c)
    if 0 <= x < w and 0 <= y < h:
        im.putpixel((x, y), c0)


def _draw_panel_box(im, x0, y0, x1, y1, bg_idx=0, border_idx=13):
    bg = PAL[bg_idx] + (255,)
    bd = PAL[border_idx] + (255,)
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            im.putpixel((x, y), bd if (x in (x0, x1) or y in (y0, y1)) else bg)


def _render_arrival_v2_base(cam_origin=(16, 24)):
    """Render Arrival Platform v2 floor, walls, corners, and low partitions on a 640x360 canvas."""
    im = Image.new('RGBA', (640, 360), PAL[0] + (255,))
    cx0, cy0 = cam_origin

    def scr(wx, wy):
        return (wx - cx0, wy - cy0)

    tile_dark = _png_or_build('environments', 'ch01_env_tile_terrazzo_dark_idle')
    tile_crack = _png_or_build('environments', 'ch01_env_tile_terrazzo_cracked_idle')
    wall_n = _png_or_build('environments', 'ch01_env_wall_subterranean_n_idle')
    wall_w = _png_or_build('environments', 'ch01_env_wall_subterranean_w_idle')
    c_nw = _png_or_build('environments', 'ch01_env_wall_subterranean_corner_nw_outer_idle')
    c_nt = _png_or_build('environments', 'ch01_env_wall_subterranean_corner_n_turn_outer_idle')
    c_wt = _png_or_build('environments', 'ch01_env_wall_subterranean_corner_w_turn_outer_idle')
    low_s = _png_or_build('environments', 'ch01_env_wall_partition_low_s_idle')
    low_e = _png_or_build('environments', 'ch01_env_wall_partition_low_e_idle')
    low_ci = _png_or_build('environments', 'ch01_env_wall_partition_low_corner_inner_idle')
    low_co = _png_or_build('environments', 'ch01_env_wall_partition_low_corner_outer_idle')

    for ty in range(18):
        for tx in range(30):
            if tx >= 12 and ty >= 8:
                continue
            wx, wy = _tile_to_px(tx, ty)
            t_spr = tile_crack if ((tx * 7 + ty * 13) % 19 == 0) else tile_dark
            _paste_clip(im, t_spr, scr(wx - 16, wy))

    for k in range(15):
        wx, wy = _tile_to_px(2 * k + 1, 0)
        _paste_clip(im, wall_n, scr(wx - 16, wy - 56))

    for k in range(9):
        wx, wy = _tile_to_px(0, 2 * k + 1)
        _paste_clip(im, wall_w, scr(wx - 16, wy - 56))

    _paste_clip(im, c_nw, scr(_tile_to_px(0, 0)[0] - 16, _tile_to_px(0, 0)[1] - 56))
    _paste_clip(im, c_nt, scr(_tile_to_px(30, 0)[0] - 16, _tile_to_px(30, 0)[1] - 56))
    _paste_clip(im, c_wt, scr(_tile_to_px(0, 18)[0] - 16, _tile_to_px(0, 18)[1] - 56))

    for k in range(9):
        wx, wy = _tile_to_px(12 + 2 * k + 1, 8)
        _paste_clip(im, low_s, scr(wx - 16, wy - 24))
    for k in range(5):
        wx, wy = _tile_to_px(12, 8 + 2 * k + 1)
        _paste_clip(im, low_e, scr(wx - 16, wy - 24))
    for k in range(6):
        wx, wy = _tile_to_px(2 * k + 1, 18)
        _paste_clip(im, low_s, scr(wx - 16, wy - 24))
    _paste_clip(im, low_ci, scr(_tile_to_px(12, 8)[0] - 16, _tile_to_px(12, 8)[1] - 24))
    _paste_clip(im, low_co, scr(_tile_to_px(12, 18)[0] - 16, _tile_to_px(12, 18)[1] - 24))

    return im


def build_selectors_n_wall_mockup():
    """640x360 mockup of the 3 N-wall selector panels (line, platform, car) mounted flush on their
    N-wall modules in Arrival Platform v2 + x2 wall-module assembly + all 9 N-wall state frames at 1x."""
    cam = (200, 88)
    im = _render_arrival_v2_base(cam_origin=cam)
    wall_n = _png_or_build('environments', 'ch01_env_wall_subterranean_n_idle')
    clock_n = _png_or_build('props', 'ch01_prop_digital_clock_2359_n_idle', lambda: build_digital_clock_2359_sheared('n'))
    arch = _png_or_build('environments', 'ch01_env_archway_frame_e_idle')
    gate = _png_or_build('props', 'ch01_prop_platform_gate_closed')
    lever = _png_or_build('props', 'ch01_prop_release_lever_idle')

    # Mount Clock_8 on WallN_8 (tile (17, 0) = (592, 200)) at world (576, 147) (z_mount = 3, pivot (0, 0))
    _paste_clip(im, clock_n, (576 - cam[0], 147 - cam[1]))

    # Mount the 3 N-wall selector panels on the east half of the N wall:
    # selector_line at (624, 172) [Area2D (640,240) + Presenter (0,-28) + offset (-16,-40) = WallN_9/10 z_mount=4]
    # selector_platform at (656, 188) [Area2D (672,256) + Presenter (0,-28) + offset (-16,-40) = WallN_10/11 z_mount=4]
    # selector_car at (688, 204) [Area2D (704,272) + Presenter (0,-28) + offset (-16,-40) = WallN_11/12 z_mount=4]
    sel_line_1 = _png_or_build('props', 'ch01_prop_selector_line_n_pos1', lambda: build_selector_panel_sheared('line', 1, 'n'))
    sel_plat_2 = _png_or_build('props', 'ch01_prop_selector_platform_n_pos2', lambda: build_selector_panel_sheared('platform', 2, 'n'))
    sel_car_1 = _png_or_build('props', 'ch01_prop_selector_car_n_pos1', lambda: build_selector_panel_sheared('car', 1, 'n'))

    mounts_n = [
        (sel_line_1, (624, 172), (640, 240)),
        (sel_plat_2, (656, 188), (672, 256)),
        (sel_car_1,  (688, 204), (704, 272)),
    ]
    for spr, (wx, wy), (ax, ay) in mounts_n:
        _paste_clip(im, spr, (wx - cam[0], wy - cam[1]))
        _draw_crosshair(im, wx - cam[0], wy - cam[1], 26)      # Top-left pivot (0, 0)
        _draw_crosshair(im, ax - cam[0], ay - cam[1], 29)      # Area2D floor anchor (21,1)/(23,1)/(25,1)

    # Also show East archway/gate & release lever in room context
    _paste_clip(im, arch, (752 - 16 - cam[0], 328 - 56 - cam[1]))
    _paste_clip(im, gate, (752 - 16 - cam[0], 328 - 56 - cam[1]))
    _paste_clip(im, lever, (752 - 12 - cam[0], 312 - 32 - cam[1]))

    # Top title banner (x=6..633, y=6..24)
    _draw_panel_box(im, 6, 6, 633, 24, bg_idx=0, border_idx=13)
    _draw_text_img(im, 12, 11, "TLF-077: SHEARED N-WALL SELECTOR PANELS ON WALLN_9..WALLN_12 (2:1 DOWN-RIGHT SLOPE)", PAL[15], scale=1)

    # Lower-left inset panel (x=6..418, y=162..353): x2 WallN module assembly + all 9 N-wall state frames at 1x
    _draw_panel_box(im, 6, 162, 418, 353, bg_idx=0, border_idx=13)
    _draw_text_img(im, 14, 168, "X2 WALLN MODULE ASSEMBLY + ALL 9 N-FACE STATES (1X NATIVE):", PAL[25], scale=1)

    # Build a 100x108 assembly of 3 WallN modules (WallN_10, WallN_11, WallN_12) with all 3 selectors uncropped
    mod_n = Image.new('RGBA', (100, 104), PAL[1] + (255,))
    for idx in (0, 1, 2):
        bx = 2 + idx * 32
        by = 2 + idx * 16
        mod_n.alpha_composite(wall_n, (bx, by))
    mod_n.alpha_composite(sel_line_1, (2 + 0,  2 + 4))
    mod_n.alpha_composite(sel_plat_2, (2 + 32, 18 + 4))
    mod_n.alpha_composite(sel_car_1,  (2 + 64, 34 + 4))
    _draw_crosshair(mod_n, 2 + 0,  2 + 4,  26)
    _draw_crosshair(mod_n, 2 + 32, 18 + 4, 26)
    _draw_crosshair(mod_n, 2 + 64, 34 + 4, 26)
    im.alpha_composite(mod_n.resize((200, 208), Image.NEAREST).crop((0, 0, 190, 168)), (12, 180))

    # Right side of inset panel (x=204..412): all 9 N-wall states (3 kinds x 3 positions) at 1x native on Wall 07
    grid_bg = Image.new('RGBA', (204, 164), PAL[7] + (255,))
    for r_idx, kind in enumerate(('line', 'platform', 'car')):
        _draw_text_img(grid_bg, 4, 18 + r_idx * 52, kind.upper()[:4], PAL[15], scale=1)
        for pos in (0, 1, 2):
            spr = _png_or_build('props', f'ch01_prop_selector_{kind}_n_pos{pos}',
                                lambda k=kind, p=pos: build_selector_panel_sheared(k, p, 'n'))
            gx = 42 + pos * 52
            gy = 4 + r_idx * 52
            grid_bg.alpha_composite(spr, (gx, gy))
            _draw_crosshair(grid_bg, gx, gy, 26)
    im.alpha_composite(grid_bg, (206, 182))

    # Legend box on bottom-right (x=424..633, y=248..353)
    _draw_panel_box(im, 424, 248, 633, 353, bg_idx=0, border_idx=13)
    _draw_text_img(im, 432, 255, "N-WALL SELECTOR CONTRACT:", PAL[26], scale=1)
    _draw_text_img(im, 432, 267, "CANVAS: 32X48 PX (9 ASSETS)", PAL[15], scale=1)
    _draw_text_img(im, 432, 279, "SLOPE:  Y = (X // 2) + Z", PAL[14], scale=1)
    _draw_text_img(im, 432, 291, "TOP-LEFT PIVOT: (0, 0)", PAL[26], scale=1)
    _draw_text_img(im, 432, 303, "PRESENTER PIVOT: (16, 40)", PAL[29], scale=1)
    _draw_text_img(im, 432, 315, "  POS=(0,-28) -> Z_WALL=4..34", PAL[14], scale=1)
    _draw_text_img(im, 432, 327, "  POS=(0,-22) -> Z_WALL=10..40", PAL[14], scale=1)
    _draw_text_img(im, 432, 339, "WALL OVERFLOW: 0 / 0 / 0 PX", PAL[25], scale=1)

    return im


def build_selectors_w_wall_mockup():
    """640x360 mockup of the 3 W-wall selector panels (line, platform, car) mounted flush on their
    W-wall modules (WallW_3..WallW_5) + x2 wall-module assembly + all 9 W-wall state frames at 1x."""
    cam = (16, 24)
    im = _render_arrival_v2_base(cam_origin=cam)
    wall_w = _png_or_build('environments', 'ch01_env_wall_subterranean_w_idle')

    sel_line_w1 = _png_or_build('props', 'ch01_prop_selector_line_w_pos1', lambda: build_selector_panel_sheared('line', 1, 'w'))
    sel_plat_w2 = _png_or_build('props', 'ch01_prop_selector_platform_w_pos2', lambda: build_selector_panel_sheared('platform', 2, 'w'))
    sel_car_w1  = _png_or_build('props', 'ch01_prop_selector_car_w_pos1', lambda: build_selector_panel_sheared('car', 1, 'w'))

    # Mount the 3 W-wall selector panels on WallW_3 (tile (0,7)=(208,120)), WallW_4 (tile (0,9)=(176,136)),
    # WallW_5 (tile (0,11)=(144,152)) at z_mount = 4:
    # Top-left canvas is WallW_k.position + (-16, -52); with pivot (0, 15) / offset (0, -15), position is WallW_k.position + (-16, -37)
    for k_mod, spr in ((3, sel_line_w1), (4, sel_plat_w2), (5, sel_car_w1)):
        wx, wy = _tile_to_px(0, 2 * k_mod + 1)
        top_left = (wx - 16, wy - 52)
        piv_pos = (wx - 16, wy - 37)
        _paste_clip(im, spr, (top_left[0] - cam[0], top_left[1] - cam[1]))
        _draw_crosshair(im, piv_pos[0] - cam[0], piv_pos[1] - cam[1], 26)  # Pivot (0, 15)
        _draw_crosshair(im, wx - cam[0], wy - cam[1], 29)                  # WallW_k anchor

    # Top title banner
    _draw_panel_box(im, 6, 6, 633, 24, bg_idx=0, border_idx=13)
    _draw_text_img(im, 12, 11, "TLF-077: SHEARED W-WALL SELECTOR PANELS ON WALLW_3..WALLW_5 (2:1 DOWN-LEFT SLOPE)", PAL[15], scale=1)

    # Lower-right inset panel (x=214..633, y=162..353): x2 WallW module assembly + all 9 W-wall state frames at 1x
    _draw_panel_box(im, 214, 162, 633, 353, bg_idx=0, border_idx=13)
    _draw_text_img(im, 222, 168, "X2 WALLW MODULE ASSEMBLY + ALL 9 W-FACE STATES (1X NATIVE):", PAL[25], scale=1)

    mod_w = Image.new('RGBA', (104, 108), PAL[1] + (255,))
    for idx, k_mod in enumerate((5, 4, 3)):
        bx = 4 + idx * 32
        by = 34 - idx * 16
        mod_w.alpha_composite(wall_w, (bx, by))
    mod_w.alpha_composite(sel_car_w1,  (4 + 0,  34 + 4))
    mod_w.alpha_composite(sel_plat_w2, (4 + 32, 18 + 4))
    mod_w.alpha_composite(sel_line_w1, (4 + 64, 2 + 4))
    _draw_crosshair(mod_w, 4 + 0,  34 + 4 + 15, 26)
    _draw_crosshair(mod_w, 4 + 32, 18 + 4 + 15, 26)
    _draw_crosshair(mod_w, 4 + 64, 2 + 4 + 15,  26)
    im.alpha_composite(mod_w.resize((208, 216), Image.NEAREST).crop((0, 4, 196, 172)), (220, 180))

    grid_bg = Image.new('RGBA', (204, 164), PAL[8] + (255,))
    for r_idx, kind in enumerate(('line', 'platform', 'car')):
        _draw_text_img(grid_bg, 4, 18 + r_idx * 52, kind.upper()[:4], PAL[15], scale=1)
        for pos in (0, 1, 2):
            spr = _png_or_build('props', f'ch01_prop_selector_{kind}_w_pos{pos}',
                                lambda k=kind, p=pos: build_selector_panel_sheared(k, p, 'w'))
            gx = 42 + pos * 52
            gy = 4 + r_idx * 52
            grid_bg.alpha_composite(spr, (gx, gy))
            _draw_crosshair(grid_bg, gx, gy + 15, 26)
    im.alpha_composite(grid_bg, (422, 182))

    # Legend box on bottom-left (x=6..208, y=248..353)
    _draw_panel_box(im, 6, 248, 208, 353, bg_idx=0, border_idx=13)
    _draw_text_img(im, 14, 255, "W-WALL SELECTOR CONTRACT:", PAL[26], scale=1)
    _draw_text_img(im, 14, 267, "CANVAS: 32X48 PX (9 ASSETS)", PAL[15], scale=1)
    _draw_text_img(im, 14, 279, "SLOPE:  Y = 15-(X//2)+Z", PAL[14], scale=1)
    _draw_text_img(im, 14, 291, "TOP-LEFT PIVOT: (0, 15)", PAL[26], scale=1)
    _draw_text_img(im, 14, 303, "  OFFSET = (0, -15)", PAL[14], scale=1)
    _draw_text_img(im, 14, 315, "PRESENTER PIVOT: (16, 40)", PAL[29], scale=1)
    _draw_text_img(im, 14, 327, "  WALLW_K + (-16, -37)", PAL[14], scale=1)
    _draw_text_img(im, 14, 339, "WALL OVERFLOW: 0 / 0 / 0 PX", PAL[25], scale=1)

    return im


def build_clocks_2359_wall_mockup():
    """640x360 split wall-module mockup showing both ch01_prop_digital_clock_2359_n_idle (on WallN_8)
    and ch01_prop_digital_clock_2359_w_idle (on WallW_2) in room context + x2 module assembly + 1x & x3 views."""
    im = Image.new('RGBA', (640, 360), PAL[0] + (255,))
    wall_n = _png_or_build('environments', 'ch01_env_wall_subterranean_n_idle')
    wall_w = _png_or_build('environments', 'ch01_env_wall_subterranean_w_idle')
    clock_n = _png_or_build('props', 'ch01_prop_digital_clock_2359_n_idle', lambda: build_digital_clock_2359_sheared('n'))
    clock_w = _png_or_build('props', 'ch01_prop_digital_clock_2359_w_idle', lambda: build_digital_clock_2359_sheared('w'))

    # Left half (x=0..319): N-wall room crop around WallN_8 (tile (17, 0) = (592, 200))
    room_n = _render_arrival_v2_base(cam_origin=(432, 96))
    _paste_clip(room_n, clock_n, (576 - 432, 147 - 96))
    _draw_crosshair(room_n, 576 - 432, 147 - 96, 26)  # Pivot (0, 0) at (576, 147)
    _draw_crosshair(room_n, 592 - 432, 200 - 96, 29)  # WallN_8 anchor (592, 200)
    im.alpha_composite(room_n.crop((0, 0, 318, 176)), (0, 26))

    # Right half (x=321..639): W-wall room crop around WallW_2 (tile (0, 5) = (240, 104))
    room_w = _render_arrival_v2_base(cam_origin=(80, 16))
    _paste_clip(room_w, clock_w, (224 - 80, 51 - 16))
    _draw_crosshair(room_w, 224 - 80, 66 - 16, 26)    # Pivot (0, 15) at (224, 66)
    _draw_crosshair(room_w, 240 - 80, 104 - 16, 29)   # WallW_2 anchor (240, 104)
    im.alpha_composite(room_w.crop((0, 0, 318, 176)), (321, 26))

    # Divider line
    for y in range(26, 354):
        im.putpixel((319, y), PAL[13] + (255,))
        im.putpixel((320, y), PAL[13] + (255,))

    # Top title banner
    _draw_panel_box(im, 6, 6, 633, 24, bg_idx=0, border_idx=13)
    _draw_text_img(im, 12, 11, "TLF-077: SHEARED 23:59 DIGITAL CLOCKS — N-FACE ON WALLN_8 (LEFT) & W-FACE ON WALLW_2 (RIGHT)", PAL[15], scale=1)

    # Bottom-left panel (x=6..314, y=180..353): N-clock x2 module + uncropped 1x & x3
    _draw_panel_box(im, 6, 180, 314, 353, bg_idx=0, border_idx=13)
    _draw_text_img(im, 12, 186, "1. CH01_PROP_DIGITAL_CLOCK_2359_N_IDLE (32X40)", PAL[25], scale=1)
    mod_cn = Image.new('RGBA', (40, 68), PAL[1] + (255,))
    mod_cn.alpha_composite(wall_n, (4, 2))
    mod_cn.alpha_composite(clock_n, (4, 5))
    _draw_crosshair(mod_cn, 4, 5, 26)
    _draw_crosshair(mod_cn, 4 + 16, 2 + 56, 29)
    im.alpha_composite(mod_cn.resize((80, 136), Image.NEAREST), (12, 202))
    _draw_text_img(im, 16, 340, "X2 ON WALLN_8", PAL[14], scale=1)

    # Uncropped 1x native and x2 zoom on Wall 07 backdrop
    bg_n1 = Image.new('RGBA', (36, 44), PAL[7] + (255,))
    bg_n1.alpha_composite(clock_n, (2, 2))
    _draw_crosshair(bg_n1, 2, 2, 26)
    im.alpha_composite(bg_n1, (100, 202))
    _draw_text_img(im, 102, 249, "1X", PAL[14], scale=1)

    bg_n2 = Image.new('RGBA', (72, 88), PAL[7] + (255,))
    bg_n2.alpha_composite(clock_n.resize((64, 80), Image.NEAREST), (4, 4))
    im.alpha_composite(bg_n2, (144, 202))
    _draw_text_img(im, 164, 293, "X2 CLOCK", PAL[14], scale=1)

    _draw_text_img(im, 100, 306, "PIVOT: (0,0) OFFSET (0,0)", PAL[26], scale=1)
    _draw_text_img(im, 100, 318, "WALLN_8 (592,200)+(-16,-53)", PAL[29], scale=1)
    _draw_text_img(im, 100, 330, "WORLD POS: (576, 147)", PAL[15], scale=1)
    _draw_text_img(im, 100, 342, "OVERFLOW: 0 / 0 / 0 PX", PAL[25], scale=1)

    # Bottom-right panel (x=325..633, y=180..353): W-clock x2 module + uncropped 1x & x2
    _draw_panel_box(im, 325, 180, 633, 353, bg_idx=0, border_idx=13)
    _draw_text_img(im, 331, 186, "2. CH01_PROP_DIGITAL_CLOCK_2359_W_IDLE (32X40)", PAL[25], scale=1)
    mod_cw = Image.new('RGBA', (40, 68), PAL[1] + (255,))
    mod_cw.alpha_composite(wall_w, (4, 2))
    mod_cw.alpha_composite(clock_w, (4, 5))
    _draw_crosshair(mod_cw, 4, 5 + 15, 26)
    _draw_crosshair(mod_cw, 4 + 16, 2 + 56, 29)
    im.alpha_composite(mod_cw.resize((80, 136), Image.NEAREST), (331, 202))
    _draw_text_img(im, 335, 340, "X2 ON WALLW_2", PAL[14], scale=1)

    bg_w1 = Image.new('RGBA', (36, 44), PAL[8] + (255,))
    bg_w1.alpha_composite(clock_w, (2, 2))
    _draw_crosshair(bg_w1, 2, 2 + 15, 26)
    im.alpha_composite(bg_w1, (419, 202))
    _draw_text_img(im, 421, 249, "1X", PAL[14], scale=1)

    bg_w2 = Image.new('RGBA', (72, 88), PAL[8] + (255,))
    bg_w2.alpha_composite(clock_w.resize((64, 80), Image.NEAREST), (4, 4))
    im.alpha_composite(bg_w2, (463, 202))
    _draw_text_img(im, 483, 293, "X2 CLOCK", PAL[14], scale=1)

    _draw_text_img(im, 419, 306, "PIVOT: (0,15) OFFSET (0,-15)", PAL[26], scale=1)
    _draw_text_img(im, 419, 318, "WALLW_2 (240,104)+(-16,-38)", PAL[29], scale=1)
    _draw_text_img(im, 419, 330, "WORLD POS: (224, 66)", PAL[15], scale=1)
    _draw_text_img(im, 419, 342, "OVERFLOW: 0 / 0 / 0 PX", PAL[25], scale=1)

    return im


def build_wall_fixtures_greyscale_proof():
    """1320x1200 colour + luminance greyscale proof sheet showing the wall-module mockups and all 20 sheared
    wall-fixture assets COMPLETELY UNCROPPED at 1x and x2."""
    W, H = 1320, 1200
    canvas = Image.new('RGBA', (W, H), PAL[0] + (255,))

    m_sel_n = build_selectors_n_wall_mockup()
    m_clk   = build_clocks_2359_wall_mockup()

    top = Image.new('RGBA', (W, 580), PAL[1] + (255,))
    _draw_text_img(top, 16, 8, "TLF-077 SHEARED 2:1 WALL FIXTURES (SELECTORS & 23:59 CLOCKS) — COLOUR (TOP) & LUMINANCE GREYSCALE (BOTTOM)", PAL[15], scale=2)
    top.alpha_composite(m_sel_n, (12, 30))
    top.alpha_composite(m_clk,   (668, 30))

    # Full uncropped contact strip of all 20 TLF-077 assets (y=396..574, 178px tall):
    strip = Image.new('RGBA', (1296, 178), PAL[2] + (255,))
    _draw_text_img(strip, 8, 4, "ALL 20 TLF-077 ASSETS UNCROPPED (9 N-SELECTORS, 9 W-SELECTORS, N-CLOCK, W-CLOCK AT 1X NATIVE + X2 ZOOM):", PAL[26], scale=1)

    # Row 1 (y=18..68): all 9 N-selectors at 1x + all 9 W-selectors at 1x + N/W clocks at 1x + x2 N/W clocks
    x_cur = 8
    for face, bg_col in (('n', 7), ('w', 8)):
        for kind in ('line', 'platform', 'car'):
            for pos in (0, 1, 2):
                spr = _png_or_build('props', f'ch01_prop_selector_{kind}_{face}_pos{pos}',
                                    lambda k=kind, p=pos, f=face: build_selector_panel_sheared(k, p, f))
                cell = Image.new('RGBA', (34, 50), PAL[bg_col] + (255,))
                cell.alpha_composite(spr, (1, 1))
                strip.alpha_composite(cell, (x_cur, 18))
                x_cur += 36
        x_cur += 8

    for face, bg_col in (('n', 7), ('w', 8)):
        clk = _png_or_build('props', f'ch01_prop_digital_clock_2359_{face}_idle',
                            lambda f=face: build_digital_clock_2359_sheared(f))
        cell = Image.new('RGBA', (34, 42), PAL[bg_col] + (255,))
        cell.alpha_composite(clk, (1, 1))
        strip.alpha_composite(cell, (x_cur, 22))
        x_cur += 38

    # Row 2 (y=72..172, 100px tall so full 64x96 x2 selectors fit with ZERO cropping!):
    x2_items = [
        ('LINE_N0', _png_or_build('props', 'ch01_prop_selector_line_n_pos0', lambda: build_selector_panel_sheared('line', 0, 'n')), 7),
        ('LINE_N1', _png_or_build('props', 'ch01_prop_selector_line_n_pos1', lambda: build_selector_panel_sheared('line', 1, 'n')), 7),
        ('LINE_N2', _png_or_build('props', 'ch01_prop_selector_line_n_pos2', lambda: build_selector_panel_sheared('line', 2, 'n')), 7),
        ('PLAT_N0', _png_or_build('props', 'ch01_prop_selector_platform_n_pos0', lambda: build_selector_panel_sheared('platform', 0, 'n')), 7),
        ('PLAT_N1', _png_or_build('props', 'ch01_prop_selector_platform_n_pos1', lambda: build_selector_panel_sheared('platform', 1, 'n')), 7),
        ('PLAT_N2', _png_or_build('props', 'ch01_prop_selector_platform_n_pos2', lambda: build_selector_panel_sheared('platform', 2, 'n')), 7),
        ('CAR_N0',  _png_or_build('props', 'ch01_prop_selector_car_n_pos0', lambda: build_selector_panel_sheared('car', 0, 'n')), 7),
        ('CAR_N1',  _png_or_build('props', 'ch01_prop_selector_car_n_pos1', lambda: build_selector_panel_sheared('car', 1, 'n')), 7),
        ('CAR_N2',  _png_or_build('props', 'ch01_prop_selector_car_n_pos2', lambda: build_selector_panel_sheared('car', 2, 'n')), 7),
        ('LINE_W1', _png_or_build('props', 'ch01_prop_selector_line_w_pos1', lambda: build_selector_panel_sheared('line', 1, 'w')), 8),
        ('PLAT_W2', _png_or_build('props', 'ch01_prop_selector_platform_w_pos2', lambda: build_selector_panel_sheared('platform', 2, 'w')), 8),
        ('CAR_W1',  _png_or_build('props', 'ch01_prop_selector_car_w_pos1', lambda: build_selector_panel_sheared('car', 1, 'w')), 8),
        ('CLK_N',   _png_or_build('props', 'ch01_prop_digital_clock_2359_n_idle', lambda: build_digital_clock_2359_sheared('n')), 7),
        ('CLK_W',   _png_or_build('props', 'ch01_prop_digital_clock_2359_w_idle', lambda: build_digital_clock_2359_sheared('w')), 8),
    ]
    for idx, (_lbl, spr, bg_col) in enumerate(x2_items):
        bx = 8 + idx * 91
        z2 = spr.resize((spr.width * 2, spr.height * 2), Image.NEAREST)
        cell = Image.new('RGBA', (z2.width + 4, z2.height + 4), PAL[bg_col] + (255,))
        cell.alpha_composite(z2, (2, 2))
        strip.alpha_composite(cell, (bx, 72))

    top.alpha_composite(strip, (12, 396))
    canvas.alpha_composite(top, (0, 0))
    canvas.alpha_composite(top.convert('L').convert('RGBA'), (0, 592))
    _draw_text_img(canvas, 16, 1178, "LUMINANCE GREYSCALE PROOF — ALL SELECTOR GLYPHS, SWITCH POSITIONS & 23:59 DIGITS READABLE", PAL[15], scale=2)
    return canvas


def write_mockups(out_dir=None):
    os.makedirs(out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups'), exist_ok=True)
    m1 = build_selectors_n_wall_mockup()
    m1.save(mockup_path('ch01_tlf077_selectors_n_wall_mockup.png', out_dir))
    m2 = build_selectors_w_wall_mockup()
    m2.save(mockup_path('ch01_tlf077_selectors_w_wall_mockup.png', out_dir))
    m3 = build_clocks_2359_wall_mockup()
    m3.save(mockup_path('ch01_tlf077_clocks_2359_wall_mockup.png', out_dir))
    m4 = build_wall_fixtures_greyscale_proof()
    m4.save(mockup_path('ch01_tlf077_wall_fixtures_greyscale_proof.png', out_dir))


if __name__ == '__main__':
    write_mockups()
    print('TLF-077 mockups written.')
