"""TLF-073 — Sheared 2:1 isometric wall-mount plaque variants (follow-up of TLF-063 / TLF-069 review).

Sol's visual review of Arrival Platform v2 (`docs/reviews/TLF-069_2b5c0b1_visual_review.md`) found that
wide rectangular frontal plaques cannot sit flush on sloped 2:1 isometric walls (`160x32` spans `80 px`
of vertical wall slope; `80x16` spans `40 px` of vertical wall slope).

Deliverables (2 registered .pxo + .png assets in assets/props/ch01/ + assets/source/ch01/, plus
two 640x360 wall-module mockups and a colour + luminance greyscale proof in design/art/mockups/):
  1. ch01_prop_departure_board_nowhere_w_idle (160x112, pivot (0, 80), Wall_Fixtures z=7):
     Sheared for the W wall face (slope runs down-left: 1 px vertical shift per 2 px horizontal,
     y(x, z) = 80 - (x // 2) + z for x in 0..159, z in 0..31). Displays "DESTINATION:" / "NOWHERE - 23:59"
     in 5x7 pixel font with rows sheared 2:1 along the W wall slope.
  2. ch01_prop_notice_closed_track_n_idle (80x56, pivot (0, 0), Wall_Fixtures z=7):
     Sheared for the N wall face (slope runs down-right: 1 px vertical shift per 2 px horizontal,
     y(x, z) = (x // 2) + z for x in 0..79, z in 0..15). Displays "CLOSED TRACK" in 5x7 pixel font
     with rows sheared 2:1 along the N wall slope and one diagonal closure slash.
"""
import os
from PIL import Image
from lib import Layer, PAL, REPO, composite, to_image
from tlf068_shape_kit import FONT5X7, _draw_text_img


def _y_w_wall(x, z):
    """Screen y on the 160x112 W-wall board canvas (slope down-left, pivot at plaque top-left (0, 80)).
    For x in 0..159 and z in 0..31, y(0, 0) = 80, y(0, 31) = 111, y(159, 0) = 1, y(159, 31) = 32."""
    return 80 - (x // 2) + z


def _y_n_wall(x, z):
    """Screen y on the 80x56 N-wall plaque canvas (slope down-right, pivot at plaque top-left (0, 0)).
    For x in 0..79 and z in 0..15, y(0, 0) = 0, y(0, 15) = 15, y(79, 0) = 39, y(79, 15) = 54."""
    return (x // 2) + z


def _put_sheared(layer, x, z, col, y_fn):
    if 0 <= x < layer.w:
        y = y_fn(x, z)
        if 0 <= y < layer.h:
            layer.put(x, y, col)


def _rect_sheared(layer, x0, z0, x1, z1, col, y_fn):
    for x in range(x0, x1 + 1):
        for z in range(z0, z1 + 1):
            _put_sheared(layer, x, z, col, y_fn)


def _hline_sheared(layer, x0, x1, z, col, y_fn):
    for x in range(x0, x1 + 1):
        _put_sheared(layer, x, z, col, y_fn)


def _vline_sheared(layer, x, z0, z1, col, y_fn):
    for z in range(z0, z1 + 1):
        _put_sheared(layer, x, z, col, y_fn)


def _draw_text_sheared(layer, x0, z0, text, col_top, col_bot, top_rows, y_fn, space_advance=6):
    """Render 5x7 pixel-font text sheared by rows along the 2:1 wall slope (1 px vertical shift per 2 px horizontal).
    Vertical strokes stay vertical (aligned with wall columns x); horizontal rows follow y_fn(x, z0 + ry)."""
    cx = x0
    for ch in text.upper():
        if ch == ' ' and space_advance != 6:
            cx += space_advance
            continue
        rows = FONT5X7.get(ch, FONT5X7[' '])
        for ry, rstr in enumerate(rows):
            col = col_top if ry < top_rows else col_bot
            for rx, bit in enumerate(rstr):
                if bit == '1':
                    _put_sheared(layer, cx + rx, z0 + ry, col, y_fn)
        cx += 6


# ============================================================================
# 1. SHEARED W-WALL DEPARTURE BOARD: ch01_prop_departure_board_nowhere_w_idle
#    Canvas: 160x112 px (160x32 plaque sheared across 80 px of 2:1 down-left W wall slope)
#    Pivot:  (0, 80) — plaque top-left on the W wall face
# ============================================================================

def build_departure_board_nowhere_w():
    w, h = 160, 112
    shadow = Layer(w, h, 'Mount_Shadow')
    housing = Layer(w, h, 'Steel_Housing')
    recess = Layer(w, h, 'Recessed_Screen')
    text_l = Layer(w, h, 'Display_Text')

    # Down-right cast shadow on the W wall plane (u=2..159, z=2..31)
    _rect_sheared(shadow, 2, 2, 159, 31, 1, _y_w_wall)

    # Flush wall-mount steel housing (u=0..157, z=0..29) with 1px 00 outer silhouette outline
    # Pivot (0, 80) is at (u=0, z=0), the exact top-left corner of the plaque on the W wall face.
    _rect_sheared(housing, 0, 0, 157, 29, 0, _y_w_wall)
    _rect_sheared(housing, 1, 1, 156, 28, 12, _y_w_wall)
    # Top-left key-lit bevels (15 specular top ridge z=1, 14 light bevel z=2 and left edge u=1..2)
    _hline_sheared(housing, 1, 156, 1, 15, _y_w_wall)
    _hline_sheared(housing, 1, 156, 2, 14, _y_w_wall)
    _vline_sheared(housing, 1, 1, 28, 15, _y_w_wall)
    _vline_sheared(housing, 2, 2, 27, 14, _y_w_wall)
    # Bottom-right shadow bevels (11 Cast Iron Dark along z=28 and u=156)
    _hline_sheared(housing, 1, 156, 28, 11, _y_w_wall)
    _vline_sheared(housing, 156, 1, 28, 11, _y_w_wall)
    _vline_sheared(housing, 155, 2, 27, 11, _y_w_wall)

    # Corner & mid-span wall-mount bolts/rivets
    for rx, rz in [(4, 4), (78, 3), (153, 4), (4, 25), (78, 26), (153, 25)]:
        _put_sheared(housing, rx, rz, 15 if rx <= 78 else 11, _y_w_wall)
        _put_sheared(housing, rx + 1, rz, 11, _y_w_wall)

    # Recessed 00 display cavity (u=6..152, z=5..24) with top/left shadow lip (11), bottom/right rim (13),
    # and split-flap row divider at z=14 (01)
    _rect_sheared(recess, 6, 5, 152, 24, 0, _y_w_wall)
    _hline_sheared(recess, 6, 152, 5, 11, _y_w_wall)
    _vline_sheared(recess, 6, 5, 24, 11, _y_w_wall)
    _hline_sheared(recess, 6, 152, 24, 13, _y_w_wall)
    _vline_sheared(recess, 152, 5, 24, 13, _y_w_wall)
    _hline_sheared(recess, 7, 151, 14, 1, _y_w_wall)

    # Line 1 (z=6..12): "DESTINATION:" (12 chars * 6 - 1 = 71 px -> u=11..81)
    _draw_text_sheared(text_l, 11, 6, "DESTINATION:", 25, 24, top_rows=2, y_fn=_y_w_wall)
    # Subtle route status pips on top-right of Line 1 (u=136..146, z=8..10)
    _rect_sheared(text_l, 136, 8, 146, 10, 22, _y_w_wall)
    _rect_sheared(text_l, 140, 8, 142, 10, 24, _y_w_wall)

    # Line 2 (z=16..22): "NOWHERE - 23:59" (15 chars * 6 - 1 = 89 px -> u=11..99)
    _draw_text_sheared(text_l, 11, 16, "NOWHERE - 23:59", 25, 24, top_rows=3, y_fn=_y_w_wall)

    return [shadow, housing, recess, text_l]


# ============================================================================
# 2. SHEARED N-WALL NOTICE PLAQUE: ch01_prop_notice_closed_track_n_idle
#    Canvas: 80x56 px (80x16 plaque sheared across 40 px of 2:1 down-right N wall slope)
#    Pivot:  (0, 0) — plaque top-left on the N wall face
# ============================================================================

def build_notice_closed_track_n():
    w, h = 80, 56
    shadow = Layer(w, h, 'Mount_Shadow')
    plaque = Layer(w, h, 'Plaque_Housing')
    text_l = Layer(w, h, 'Notice_Text')
    stroke = Layer(w, h, 'Closure_Stroke')

    # Down-right cast shadow on the N wall plane (u=2..79, z=2..15)
    _rect_sheared(shadow, 2, 2, 79, 15, 1, _y_n_wall)

    # Flush wall-mount steel plaque housing (u=0..77, z=0..14) with 1px 00 outer silhouette outline
    # Pivot (0, 0) is at (u=0, z=0), the exact top-left corner of the plaque on the N wall face.
    _rect_sheared(plaque, 0, 0, 77, 14, 0, _y_n_wall)
    _rect_sheared(plaque, 1, 1, 76, 13, 13, _y_n_wall)
    # Top-left key-lit bevels (15 top ridge z=1, 14 left edge u=1)
    _hline_sheared(plaque, 1, 76, 1, 15, _y_n_wall)
    _vline_sheared(plaque, 1, 1, 13, 14, _y_n_wall)
    # Bottom-right shadow bevels (11 along z=13 and u=76)
    _hline_sheared(plaque, 1, 76, 13, 11, _y_n_wall)
    _vline_sheared(plaque, 76, 1, 13, 11, _y_n_wall)

    # Inner notice board face (worn slate/steel 12 with dark 01 inset border)
    _rect_sheared(plaque, 3, 2, 74, 12, 1, _y_n_wall)
    _rect_sheared(plaque, 4, 3, 73, 11, 12, _y_n_wall)

    # "CLOSED TRACK" in native 5x7 font sheared 2:1 by rows (3px space -> fits u=5..72, z=4..10)
    _draw_text_sheared(text_l, 5, 4, "CLOSED TRACK", 15, 14, top_rows=3, y_fn=_y_n_wall, space_advance=3)

    # Bold 2px diagonal closure slash from bottom-left (u=5, z=10) to top-right (u=72, z=3):
    # continuous 00 dark core on bottom row + 23/24 crimson-amber upper rim
    for u in range(5, 73):
        z_mid = 10 - ((u - 5) * 7) // 67
        y_top = _y_n_wall(u, z_mid)
        _put_sheared(stroke, u, z_mid, 24 if text_l.get(u, y_top) is not None else 23, _y_n_wall)
        _put_sheared(stroke, u, z_mid + 1, 0, _y_n_wall)

    return [shadow, plaque, text_l, stroke]


# ============================================================================
# 3. ASSET REGISTRY FOR TLF-073 (2 .pxo + .png assets)
# ============================================================================

def assets():
    return [
        (
            'ch01_prop_departure_board_nowhere_w_idle',
            'props',
            160, 112,
            ['Mount_Shadow', 'Steel_Housing', 'Recessed_Screen', 'Display_Text'],
            [build_departure_board_nowhere_w()],
            1.0,
            [],
            {
                'pivot': '(0, 80)',
                'z': 'Wall_Fixtures (z_index = 7)',
                'wall_mount': 'W wall face (slope down-left); mounts to WallW_5 (tile (0,11), anchor (144,152)) at offset (-80,-4) -> world (64,148), or WallW_7 (tile (0,15), anchor (80,184)) at offset (-16,-36)',
            },
        ),
        (
            'ch01_prop_notice_closed_track_n_idle',
            'props',
            80, 56,
            ['Mount_Shadow', 'Plaque_Housing', 'Notice_Text', 'Closure_Stroke'],
            [build_notice_closed_track_n()],
            1.0,
            [],
            {
                'pivot': '(0, 0)',
                'z': 'Wall_Fixtures (z_index = 7)',
                'wall_mount': 'N wall face (slope down-right); mounts to WallN_6 (tile (13,0), anchor (528,168)) at offset (-40,-52) -> world (488,116), or WallN_5 (tile (11,0), anchor (496,152)) at offset (-8,-36)',
            },
        ),
    ]


# ============================================================================
# 4. MOCKUPS & GREYSCALE PROOFS (built strictly from delivered runtime PNGs)
# ============================================================================

MOCKUP_FILES = [
    'ch01_tlf073_departure_board_w_wall_mockup.png',
    'ch01_tlf073_notice_closed_track_n_wall_mockup.png',
    'ch01_tlf073_sheared_plaques_greyscale_proof.png',
]


def mockup_path(fname, out_dir=None):
    base = out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups')
    return os.path.join(base, fname)


def _png(cat, stem):
    return Image.open(os.path.join(REPO, 'assets', cat, 'ch01', stem + '.png')).convert('RGBA')


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
    """Render the Arrival Platform v2 floor, walls, corners, and low partitions from committed runtime PNGs
    with camera top-left at cam_origin = (cx0, cy0) on a 640x360 canvas."""
    im = Image.new('RGBA', (640, 360), PAL[0] + (255,))
    cx0, cy0 = cam_origin

    def scr(wx, wy):
        return (wx - cx0, wy - cy0)

    tile_dark = _png('environments', 'ch01_env_tile_terrazzo_dark_idle')
    tile_crack = _png('environments', 'ch01_env_tile_terrazzo_cracked_idle')
    wall_n = _png('environments', 'ch01_env_wall_subterranean_n_idle')
    wall_w = _png('environments', 'ch01_env_wall_subterranean_w_idle')
    c_nw = _png('environments', 'ch01_env_wall_subterranean_corner_nw_outer_idle')
    c_nt = _png('environments', 'ch01_env_wall_subterranean_corner_n_turn_outer_idle')
    c_wt = _png('environments', 'ch01_env_wall_subterranean_corner_w_turn_outer_idle')
    low_s = _png('environments', 'ch01_env_wall_partition_low_s_idle')
    low_e = _png('environments', 'ch01_env_wall_partition_low_e_idle')
    low_ci = _png('environments', 'ch01_env_wall_partition_low_corner_inner_idle')
    low_co = _png('environments', 'ch01_env_wall_partition_low_corner_outer_idle')

    # Floor tiles for L-shape [[0,0],[30,0],[30,8],[12,8],[12,18],[0,18]]
    for ty in range(18):
        for tx in range(30):
            if tx >= 12 and ty >= 8:
                continue
            wx, wy = _tile_to_px(tx, ty)
            t_spr = tile_crack if ((tx * 7 + ty * 13) % 19 == 0) else tile_dark
            _paste_clip(im, t_spr, scr(wx - 16, wy))

    # Tall N walls: WallN_0..WallN_14 at tile (2k+1, 0), pivot (16, 56)
    for k in range(15):
        wx, wy = _tile_to_px(2 * k + 1, 0)
        _paste_clip(im, wall_n, scr(wx - 16, wy - 56))

    # Tall W walls: WallW_0..WallW_8 at tile (0, 2k+1), pivot (16, 56)
    for k in range(9):
        wx, wy = _tile_to_px(0, 2 * k + 1)
        _paste_clip(im, wall_w, scr(wx - 16, wy - 56))

    # Tall corners at (0,0), (30,0), (0,18)
    _paste_clip(im, c_nw, scr(*(_tile_to_px(0, 0)[0] - 16, _tile_to_px(0, 0)[1] - 56)))
    _paste_clip(im, c_nt, scr(*(_tile_to_px(30, 0)[0] - 16, _tile_to_px(30, 0)[1] - 56)))
    _paste_clip(im, c_wt, scr(*(_tile_to_px(0, 18)[0] - 16, _tile_to_px(0, 18)[1] - 56)))

    # Low partitions along pit y=8 (x=12..30), arm E x=12 (y=8..18), arm S y=18 (x=0..12)
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


def build_departure_board_w_wall_mockup():
    """640x360 mockup of ch01_prop_departure_board_nowhere_w_idle mounted on its W wall module (WallW_5)."""
    cam = (16, 24)
    im = _render_arrival_v2_base(cam_origin=cam)

    board_w = _png('props', 'ch01_prop_departure_board_nowhere_w_idle')
    wall_w = _png('environments', 'ch01_env_wall_subterranean_w_idle')
    elias_sh = _png('characters', 'ch01_char_elias_base_sheet')
    elias_se = elias_sh.crop((10 * 32, 0, 11 * 32, 48))
    student = _png('characters', 'ch01_char_statue_commuter_n02_student_idle')
    watch = _png('props', 'ch01_prop_pocket_watch_idle')

    # Mount ch01_prop_departure_board_nowhere_w_idle on WallW_5 (tile (0,11), anchor (144,152)):
    # Plaque top-left on wall face is at world (64, 148) = WallW_5.anchor + (-80, -4) = WallW_7.anchor + (-16, -36).
    # With pivot (0, 80) (offset = (0, -80)), canvas top-left is at world (64, 68).
    _paste_clip(im, board_w, (64 - cam[0], 68 - cam[1]))

    # Actors & props in the W arm for scale & context
    _paste_clip(im, student, (208 - 8 - cam[0], 168 - 36 - cam[1]))
    _paste_clip(im, watch, (240 - 8 - cam[0], 232 - 12 - cam[1]))
    _paste_clip(im, elias_se, (160 - 16 - cam[0], 224 - 44 - cam[1]))

    # Highlight crosshair on in-room plaque pivot (64, 148) -> screen (48, 124) and WallW_5 anchor (144, 152) -> screen (128, 128)
    _draw_crosshair(im, 64 - cam[0], 148 - cam[1], 26)
    _draw_crosshair(im, 144 - cam[0], 152 - cam[1], 29)

    # Top-left header banner
    _draw_panel_box(im, 6, 6, 633, 24, bg_idx=0, border_idx=13)
    _draw_text_img(im, 12, 11, "TLF-073: CH01_PROP_DEPARTURE_BOARD_NOWHERE_W_IDLE ON W WALL MODULE (WALLW_5)", PAL[15], scale=1)

    # Right-side technical & zoom inset panel (x=312..633, y=30..353)
    _draw_panel_box(im, 312, 30, 633, 353, bg_idx=0, border_idx=13)
    _draw_text_img(im, 320, 37, "1X MODULE ASSEMBLY (WALLW_7..WALLW_3) + PIVOT:", PAL[25], scale=1)

    # Assemble the 5 W-wall modules (WallW_7..WallW_3) in a clean diagram box (x=320..500, y=50..202)
    mod_box = Image.new('RGBA', (180, 152), PAL[1] + (255,))
    # In mod_box, place WallW_3..WallW_7 so world wx=64 maps to bx=10, world wy=64 maps to by=8
    for k, m_idx in enumerate([3, 4, 5, 6, 7]):
        wx, wy = _tile_to_px(0, 2 * m_idx + 1)
        bx = (wx - 16) - 64 + 10
        by = (wy - 56) - 64 + 8
        mod_box.alpha_composite(wall_w, (bx, by))
    # Mount board_w at world (64, 68) -> mod_box (10, 12), pivot (0, 80) at mod_box (10, 92)
    mod_box.alpha_composite(board_w, (10, 12))
    _draw_crosshair(mod_box, 10, 92, 26)         # Pivot (0, 80) = world (64, 148)
    _draw_crosshair(mod_box, 10 + 80, 96, 29)    # WallW_5 anchor (144, 152)
    _draw_crosshair(mod_box, 10 + 16, 128, 29)   # WallW_7 anchor (80, 184)
    im.alpha_composite(mod_box, (320, 50))

    # Standalone 1x sprite on Wall 08 backdrop (x=508..626, y=50..202)
    _draw_text_img(im, 508, 52, "PIVOT & ANCHORS:", PAL[15], scale=1)
    _draw_text_img(im, 508, 66, "GOLD + : PIVOT", PAL[26], scale=1)
    _draw_text_img(im, 508, 76, "  (0, 80) TOP-L", PAL[26], scale=1)
    _draw_text_img(im, 508, 90, "CYAN + : MODULE", PAL[29], scale=1)
    _draw_text_img(im, 508, 100, "  WALLW_5 (144,152)", PAL[29], scale=1)
    _draw_text_img(im, 508, 110, "  OFFSET (-80,-4)", PAL[14], scale=1)
    _draw_text_img(im, 508, 124, "  WALLW_7 (80,184)", PAL[29], scale=1)
    _draw_text_img(im, 508, 134, "  OFFSET (-16,-36)", PAL[14], scale=1)
    _draw_text_img(im, 508, 150, "SILHOUETTE FIT:", PAL[15], scale=1)
    _draw_text_img(im, 508, 162, "  ABOVE WALL: 0 PX", PAL[25], scale=1)
    _draw_text_img(im, 508, 172, "  BELOW FOOT: 0 PX", PAL[25], scale=1)
    _draw_text_img(im, 508, 182, "  OUTSIDE:    0 PX", PAL[25], scale=1)

    # Bottom x2 zoomed crop of the left/text section of the board on WallW_7..WallW_5 (x=320..625, y=210..346)
    _draw_text_img(im, 320, 208, "X2 ZOOM ON WALLW_7..WALLW_5 (2:1 SHEARED 5X7 FONT):", PAL[25], scale=1)
    crop_src = mod_box.crop((4, 54, 156, 118))  # 152x64 -> x2 = 304x128
    im.alpha_composite(crop_src.resize((304, 128), Image.NEAREST), (320, 220))

    return im


def build_notice_closed_track_n_wall_mockup():
    """640x360 mockup of ch01_prop_notice_closed_track_n_idle mounted on its N wall module (WallN_6)."""
    cam = (120, 24)
    im = _render_arrival_v2_base(cam_origin=cam)

    notice_n = _png('props', 'ch01_prop_notice_closed_track_n_idle')
    wall_n = _png('environments', 'ch01_env_wall_subterranean_n_idle')
    clock = _png('props', 'ch01_prop_digital_clock_2359_idle')
    bench = _png('props', 'ch01_prop_station_bench_idle')
    old_man = _png('characters', 'ch01_char_statue_commuter_n03_old_man_idle')
    conductor = _png('characters', 'ch01_char_statue_commuter_n01_conductor_idle')
    car = _png('props', 'ch01_prop_transit_car_stalled_idle')
    elias_sh = _png('characters', 'ch01_char_elias_base_sheet')
    elias_ne = elias_sh.crop((30 * 32, 0, 31 * 32, 48))

    # Mount ch01_prop_notice_closed_track_n_idle on WallN_6 (tile (13,0), anchor (528,168)):
    # Plaque top-left on wall face is at world (488, 116) = WallN_6.anchor + (-40, -52) = WallN_5.anchor + (-8, -36).
    # With pivot (0, 0) (offset = (0, 0)), canvas top-left is at world (488, 116).
    _paste_clip(im, notice_n, (488 - cam[0], 116 - cam[1]))

    # Clocks & actors along the N strip for scale & context
    _paste_clip(im, clock, (400 - 16 - cam[0], 66 - 20 - cam[1]))
    _paste_clip(im, clock, (592 - 16 - cam[0], 162 - 20 - cam[1]))
    _paste_clip(im, old_man, (448 - 8 - cam[0], 160 - 36 - cam[1]))
    _paste_clip(im, bench, (448 - 24 - cam[0], 168 - 26 - cam[1]))
    _paste_clip(im, conductor, (496 - 8 - cam[0], 200 - 36 - cam[1]))
    _paste_clip(im, elias_ne, (464 - 16 - cam[0], 208 - 44 - cam[1]))
    _paste_clip(im, car, (480 - 64 - cam[0], 336 - 52 - cam[1]))

    # Highlight crosshairs on in-room plaque pivot (488, 116) and WallN_6 anchor (528, 168)
    _draw_crosshair(im, 488 - cam[0], 116 - cam[1], 26)
    _draw_crosshair(im, 528 - cam[0], 168 - cam[1], 29)

    # Top header banner
    _draw_panel_box(im, 6, 6, 633, 24, bg_idx=0, border_idx=13)
    _draw_text_img(im, 12, 11, "TLF-073: CH01_PROP_NOTICE_CLOSED_TRACK_N_IDLE ON N WALL MODULE (WALLN_6)", PAL[15], scale=1)

    # Lower-left technical & x3 zoom inset panel (x=6..366, y=156..353)
    _draw_panel_box(im, 6, 156, 366, 353, bg_idx=0, border_idx=13)
    _draw_text_img(im, 14, 163, "X2 MODULE ASSEMBLY (WALLN_5..WALLN_7) + X3 PLAQUE:", PAL[25], scale=1)

    # Assemble WallN_5, WallN_6, WallN_7 (spanning world wx=480..575, wy=96..191 -> 96x96 box)
    mod_box = Image.new('RGBA', (104, 96), PAL[1] + (255,))
    for m_idx in (5, 6, 7):
        wx, wy = _tile_to_px(2 * m_idx + 1, 0)
        bx = (wx - 16) - 480 + 4
        by = (wy - 56) - 96 + 0
        mod_box.alpha_composite(wall_n, (bx, by))
    # Mount notice_n at world (488, 116) -> mod_box (4 + 8, 20) = (12, 20)
    mod_box.alpha_composite(notice_n, (12, 20))
    _draw_crosshair(mod_box, 12, 20, 26)         # Pivot (0, 0) at world (488, 116)
    _draw_crosshair(mod_box, 4 + 48, 72, 29)     # WallN_6 anchor (528, 168)
    _draw_crosshair(mod_box, 4 + 16, 56, 29)     # WallN_5 anchor (496, 152)
    im.alpha_composite(mod_box.resize((208, 192), Image.NEAREST).crop((0, 16, 208, 188)), (14, 175))

    # Right column of inset panel: metadata & 1x native on Wall 07 backdrop
    _draw_text_img(im, 228, 177, "CANVAS: 80X56 PX", PAL[15], scale=1)
    _draw_text_img(im, 228, 187, "SLOPE:  2:1 DOWN-R", PAL[14], scale=1)
    _draw_text_img(im, 228, 199, "GOLD + : PIVOT", PAL[26], scale=1)
    _draw_text_img(im, 228, 209, "  (0, 0) TOP-LEFT", PAL[26], scale=1)
    _draw_text_img(im, 228, 221, "CYAN + : MODULE", PAL[29], scale=1)
    _draw_text_img(im, 228, 231, "  WALLN_6 (528,168)", PAL[29], scale=1)
    _draw_text_img(im, 228, 241, "  OFFSET (-40,-52)", PAL[14], scale=1)
    _draw_text_img(im, 228, 253, "  WALLN_5 (496,152)", PAL[29], scale=1)
    _draw_text_img(im, 228, 263, "  OFFSET (-8,-36)", PAL[14], scale=1)
    _draw_text_img(im, 228, 275, "SILHOUETTE FIT:", PAL[15], scale=1)
    _draw_text_img(im, 228, 285, "  OUTSIDE: 0 PX", PAL[25], scale=1)

    nat_bg = Image.new('RGBA', (88, 60), PAL[7] + (255,))
    nat_bg.alpha_composite(notice_n, (4, 2))
    _draw_crosshair(nat_bg, 4, 2, 26)
    im.alpha_composite(nat_bg, (228, 293))

    return im


def build_sheared_plaques_greyscale_proof():
    """1320x1040 colour + luminance greyscale proof sheet of both TLF-073 sheared wall plaques and mockups."""
    W, H = 1320, 1040
    canvas = Image.new('RGBA', (W, H), PAL[0] + (255,))

    m_w = build_departure_board_w_wall_mockup()
    m_n = build_notice_closed_track_n_wall_mockup()
    board_w = _png('props', 'ch01_prop_departure_board_nowhere_w_idle')
    notice_n = _png('props', 'ch01_prop_notice_closed_track_n_idle')

    top = Image.new('RGBA', (W, 500), PAL[1] + (255,))
    _draw_text_img(top, 16, 8, "TLF-073 SHEARED 2:1 WALL-MOUNT PLAQUES — COLOUR (TOP) & LUMINANCE GREYSCALE PROOF (BOTTOM)", PAL[15], scale=2)
    top.alpha_composite(m_w, (12, 30))
    top.alpha_composite(m_n, (668, 30))

    # Bottom strip of top half (y=396..494): standalone 1x + x2/x3 comparison on Wall 08 / Wall 07
    strip = Image.new('RGBA', (1296, 98), PAL[8] + (255,))
    strip.alpha_composite(board_w.crop((0, 16, 160, 112)), (12, 1))
    strip.alpha_composite(notice_n, (192, 20))
    strip.alpha_composite(notice_n.resize((160, 112), Image.NEAREST).crop((0, 8, 160, 104)), (296, 1))
    _draw_text_img(strip, 480, 14, "1. CH01_PROP_DEPARTURE_BOARD_NOWHERE_W_IDLE (160X112, PIVOT (0,80)) — W WALL DOWN-LEFT SLOPE", PAL[25], scale=1)
    _draw_text_img(strip, 480, 32, "   MOUNT: WALLW_5 (TILE (0,11), ANCHOR (144,152)) + (-80,-4) = WORLD (64,148) [0 PX OUTSIDE WALL]", PAL[15], scale=1)
    _draw_text_img(strip, 480, 54, "2. CH01_PROP_NOTICE_CLOSED_TRACK_N_IDLE (80X56, PIVOT (0,0)) — N WALL DOWN-RIGHT SLOPE", PAL[25], scale=1)
    _draw_text_img(strip, 480, 72, "   MOUNT: WALLN_6 (TILE (13,0), ANCHOR (528,168)) + (-40,-52) = WORLD (488,116) [0 PX OUTSIDE WALL]", PAL[15], scale=1)
    top.alpha_composite(strip, (12, 396))

    canvas.alpha_composite(top, (0, 0))
    canvas.alpha_composite(top.convert('L').convert('RGBA'), (0, 512))
    _draw_text_img(canvas, 16, 1016, "LUMINANCE GREYSCALE PROOF (.CONVERT('L')) — ALL GLYPHS, BEVELS & CLOSURE STROKE READABLE WITHOUT COLOUR", PAL[15], scale=2)
    return canvas


def write_mockups(out_dir=None):
    os.makedirs(out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups'), exist_ok=True)
    m1 = build_departure_board_w_wall_mockup()
    m1.save(mockup_path('ch01_tlf073_departure_board_w_wall_mockup.png', out_dir))
    m2 = build_notice_closed_track_n_wall_mockup()
    m2.save(mockup_path('ch01_tlf073_notice_closed_track_n_wall_mockup.png', out_dir))
    m3 = build_sheared_plaques_greyscale_proof()
    m3.save(mockup_path('ch01_tlf073_sheared_plaques_greyscale_proof.png', out_dir))
