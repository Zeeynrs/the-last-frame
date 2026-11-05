"""Step 1 mockups & greyscale proofs for TLF-057 (Sol visual review package, Appendix B).

Produces 5 files in `design/art/mockups/`:
1. `ch01_step1_room_statues_mockup.png` (640 x 360 px native Room 1 mockup with Elias, N-01..N-04, shimmer, read outline, SO-01 props)
2. `ch01_step1_room_statues_x3_proof.png` (1920 x 1080 px nearest x3 upscale of the Room 1 mockup)
3. `ch01_step1_room_statues_greyscale_proof.png` (1920 x 1080 px nearest x3 luminance greyscale proof of Room 1)
4. `ch01_step1_statues_all13_greyscale_proof.png` (contact sheet in colour + greyscale at x3 + native 1x strip, with legends outside
   sprite bounds: Elias vs effects-hidden statue, all 13 assembled commuters, 6 base bodies + 4 specific poses in idle & static read
   on both dark wall and lit floor backgrounds, reduced_effects view, 14 overlays, 4 shimmer frames, 6x6 timestamp glyph)
5. `ch01_step1_props_greyscale_proof.png` (contact sheet in colour + greyscale at x3 + native 1x strip, with legends outside sprite
   bounds: all 57 Section B props grouped by family & state, plus 2x tiled bulkhead wall proof)
"""
import os
from PIL import Image, ImageDraw, ImageFont
from lib import *
import step1_statues as st_mod
import step1_props as pr_mod
import placement_render as pl_mod

MOCK_DIR = os.path.join(REPO, 'design', 'art', 'mockups')
FONT_PATH = os.path.join(REPO, 'assets', 'ui', 'fonts', 'tlf_pixel_mono.ttf')

MOCKUP_FILES = [
    'ch01_step1_room_statues_mockup.png',
    'ch01_step1_room_statues_x3_proof.png',
    'ch01_step1_room_statues_greyscale_proof.png',
    'ch01_step1_statues_all13_greyscale_proof.png',
    'ch01_step1_props_greyscale_proof.png',
]


def mockup_path(fname, out_dir=None):
    return os.path.join(out_dir or MOCK_DIR, fname)


def _to_greyscale_rgba(im):
    """Convert an RGBA image to pure luminance greyscale while preserving alpha."""
    g = im.convert('L')
    r, g_ch, b, a = im.split()
    return Image.merge('RGBA', (g, g, g, a))


def _paste_safe(cv, im, xy):
    """Alpha-composite `im` onto `cv` at `xy`, clipping to canvas bounds."""
    pl_mod.paste_clip(cv, im, xy)


def _draw_label(im, xy, text, col_idx=15):
    """Render crisp 1-bit pixel font text (`tlf_pixel_mono.ttf` @ 8px) onto `im` at `xy` using palette index `col_idx`."""
    fnt = ImageFont.truetype(FONT_PATH, 8)
    mask = Image.new('1', im.size, 0)
    d = ImageDraw.Draw(mask)
    d.text(xy, text, fill=1, font=fnt)
    rgba = PAL[col_idx] + (255,)
    px = mask.load()
    out_px = im.load()
    w, h = im.size
    for y in range( max(0, xy[1] - 2), min(h, xy[1] + 12) ):
        for x in range( max(0, xy[0] - 2), min(w, xy[0] + len(text) * 7 + 4) ):
            if px[x, y]:
                out_px[x, y] = rgba


def build_room1_step1_mockup():
    """Render Room 1 (640 x 360 px) with living Elias, N-01..N-04 at spec positions,
    Trace shimmer + timestamp glyph on N-01, static 'read' outline on N-03 (seated on the existing bench),
    half-turned trolley on N-04, and SO-01 selectors, release lever, and platform gate."""
    r1 = pl_mod.build_rooms()[0]
    # Place living Elias at tile (6, 5) -> (336, 152) in the centre of R1 for clear side-by-side comparison
    elias_pos = pl_mod.px(6, 5)  # (336, 152)
    pcs = list(pl_mod.pieces(r1, anchor=elias_pos))

    # Add SO-01 props at their exact `step1_placement_check.py` coordinates:
    so01_placements = [
        (pr_mod.build_selector_panel('line', 1),     (16, 40), pl_mod.px(7, 1),  10),
        (pr_mod.build_selector_panel('platform', 1), (16, 40), pl_mod.px(9, 1),  10),
        (pr_mod.build_selector_panel('car', 2),      (16, 40), pl_mod.px(11, 1), 10),
        (pr_mod.build_release_lever('accepted'),     (12, 32), pl_mod.px(13, 2), 10),
        (pr_mod.build_platform_gate('closed'),       (16, 56), (448, 208),       10),
    ]
    for layers, piv, pos, zz in so01_placements:
        im = to_image(composite(layers))
        pcs.append((zz, pos[1], im, (int(pos[0] - piv[0]), int(pos[1] - piv[1]))))

    shimmer_f0 = to_image(composite(st_mod.build_shimmer_ring_frames()[0]))
    glyph_im = to_image(composite(st_mod.build_timestamp_glyph()))

    r1_commuters = [
        ('N-01', (352, 208), 'body_a_pose2',       ['whistle'],   'idle', True),
        ('N-02', (272, 168), 'body_a_pose1',       ['phone'],     'idle', False),
        ('N-03', (348, 122), 'n03_old_man_seated', ['paper_bag'], 'read', False),
        ('N-04', (400, 216), 'n04_cleaner',        ['trolley'],   'idle', False),
    ]
    for cid, pos, pk, ovs, mode, has_shimmer in r1_commuters:
        if has_shimmer:
            pcs.append((9, pos[1] - 0.1, shimmer_f0, (pos[0] - 12, pos[1] - 6)))
        st_im = to_image(st_mod.assemble_commuter(pk, ovs, mode=mode))
        sort_y = pos[1] + (1.0 if cid == 'N-03' else 0.0)
        pcs.append((10, sort_y, st_im, (pos[0] - 8, pos[1] - 36)))
        if has_shimmer:
            pcs.append((11, pos[1] + 0.2, glyph_im, (pos[0] - 3, pos[1] - 39)))

    bg = PAL[0] + (255,)
    cv = Image.new('RGBA', (640, 360), bg)
    for z, y, im, o in sorted(pcs, key=lambda t: (t[0], t[1])):
        _paste_safe(cv, im, o)
    return cv


def build_statues_all13_contact_sheet():
    """Build contact sheet (colour top half + greyscale bottom half at x3 + native 1x inset strip) containing:
    - Band 1: Effects-hidden Elias vs Statue comparison + All 13 assembled Step 1 commuters (N-01..N-21) + Active Trace vs Reduced-Effects/Read on BOTH dark wall & lit floor backgrounds.
    - Band 2: All 10 statue poses (6 base bodies + 4 specific poses) in `_idle` and static `_read` (shown over dark wall AND lit floor swatches).
    - Band 3: All 14 prop overlays + 4 stepped Trace shimmer ring frames (24x12) + 6x6 timestamp glyph + N-03 seated on bench."""
    nw, nh = 440, 180
    bg_col = PAL[2] + (255,)
    panel_bg = PAL[1] + (255,)
    lit_floor_bg = PAL[13] + (255,)
    border_col = PAL[13] + (255,)

    half = Image.new('RGBA', (nw, nh), bg_col)

    def box(x0, y0, x1, y1, fill=panel_bg):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                c = border_col if (x in (x0, x1) or y in (y0, y1)) else fill
                half.putpixel((x, y), c)

    # --- Band 1 (y=2..62): Living Elias + 13 Assembled Commuters + Trace Active vs Reduced-Effects (Dark Wall & Lit Floor)
    box(3, 2, nw - 4, 62)
    _draw_label(half, (6, 4), 'ELIAS  N01..N21 (13 COMMUTERS)              TRACE   READ:DK/LT  LIT-CMP', 15)

    sheet_elias = Image.open(os.path.join(REPO, 'assets', 'characters', 'ch01', 'ch01_char_elias_base_sheet.png')).convert('RGBA')
    elias_se = sheet_elias.crop((10 * 32, 0, 11 * 32, 48))
    _paste_safe(half, elias_se, (5, 13))

    for i, (cid, slug, rm, tile, px_pos, pk, ovs, tstr, role) in enumerate(st_mod.COMMUTER_ASSEMBLIES):
        cx = 40 + i * 21
        im_c = to_image(st_mod.assemble_commuter(pk, ovs, mode='idle'))
        _paste_safe(half, im_c, (cx, 19))

    # Active Trace target (4-frame shimmer f0 + statue + overhead 6x6 clock-hand glyph) at x=316..342
    sh_f0 = to_image(composite(st_mod.build_shimmer_ring_frames()[0]))
    gl_im = to_image(composite(st_mod.build_timestamp_glyph()))
    n01_idle = to_image(st_mod.assemble_commuter('body_a_pose2', ['whistle'], mode='idle'))
    _paste_safe(half, sh_f0, (318, 45))
    _paste_safe(half, n01_idle, (322, 19))
    _paste_safe(half, gl_im, (327, 13))

    # Reduced-effects / Static 'read' 1px outline shown on (a) DARK WALL background (x=352..374) and (b) LIT FLOOR background (x=378..400),
    # plus effects-hidden Elias vs Statue on lit floor at x=404..433!
    box(352, 14, 374, 60, fill=PAL[1] + (255,))
    box(376, 14, 398, 60, fill=lit_floor_bg)
    box(400, 14, 434, 60, fill=lit_floor_bg)
    n01_read = to_image(st_mod.assemble_commuter('body_a_pose2', ['whistle'], mode='read'))
    _paste_safe(half, n01_read, (355, 19))
    _paste_safe(half, n01_read, (379, 19))
    _paste_safe(half, elias_se, (398, 13))
    _paste_safe(half, n01_idle, (418, 19))

    # --- Band 2 (y=65..123): 6 Base Bodies + 4 Specific Poses in `_idle` and static `_read` (alternating dark wall & lit floor behind `_read`)
    box(3, 65, nw - 4, 123)
    _draw_label(half, (6, 67), '6 BASE BODIES (A1..C2) + 4 POSES (N03 N04 N05 N11) : IDLE & READ', 15)
    pose_keys = [
        'body_a_pose1', 'body_a_pose2',
        'body_b_pose1', 'body_b_pose2',
        'body_c_pose1', 'body_c_pose2',
        'n03_old_man_seated', 'n04_cleaner', 'n05_courier_vault', 'n11_tech_crank',
    ]
    for i, pk in enumerate(pose_keys):
        px0 = 6 + i * 43
        # Lit floor swatch under the right half of the `_read` sprite so every `_read` pose is visible against both dark & lit backgrounds!
        box(px0 + 25, 76, px0 + 36, 121, fill=lit_floor_bg)
        im_idle = to_image(composite(st_mod.build_statue_pose(pk, mode='idle')))
        im_read = to_image(composite(st_mod.build_statue_pose(pk, mode='read')))
        _paste_safe(half, im_idle, (px0, 79))
        _paste_safe(half, im_read, (px0 + 19, 79))

    # --- Band 3 (y=126..177): 14 Overlays + 4 Shimmer Frames (F1..F4) + 6x6 Glyph + N-03 Seated on Bench
    box(3, 126, nw - 4, 177)
    _draw_label(half, (6, 128), '14 PROP OVERLAYS (OV_*)                     SHIMMER F1..F4  GL  N03+BENCH', 15)
    ov_keys = [
        'suitcase', 'paper_bag', 'whistle', 'trolley', 'phone', 'red_coat', 'briefcase',
        'sleeping_child', 'headphones', 'hatch_crank', 'gate_lever', 'breaker_handle', 'map', 'courier_bag',
    ]
    for i, ok in enumerate(ov_keys):
        ox = 6 + i * 19
        im_ov = to_image(composite(st_mod.build_overlay(ok)))
        _paste_safe(half, im_ov, (ox, 136))

    sh_frames = st_mod.build_shimmer_ring_frames()
    for fi, flayers in enumerate(sh_frames):
        fx = 278 + (fi % 2) * 28
        fy = 142 + (fi // 2) * 16
        _paste_safe(half, to_image(composite(flayers)), (fx, fy))
    _paste_safe(half, gl_im, (342, 150))

    bench_im = pl_mod.img('ch01_prop_station_bench_idle')
    n03_comp = to_image(st_mod.assemble_commuter('n03_old_man_seated', ['paper_bag'], mode='idle'))
    _paste_safe(half, bench_im, (366, 142))
    _paste_safe(half, n03_comp, (382, 134))

    # Upscale x3 (1320 x 1080) + embed native 1x comparison strip at bottom!
    grey_half = _to_greyscale_rgba(half)
    top_x3 = half.resize((nw * 3, nh * 3), Image.NEAREST)
    bot_x3 = grey_half.resize((nw * 3, nh * 3), Image.NEAREST)
    total_h = nh * 6 + nh + 12
    full = Image.new('RGBA', (nw * 3, total_h), bg_col)
    full.paste(top_x3, (0, 0))
    full.paste(bot_x3, (0, nh * 3))
    # Native 1x strip at the bottom (colour on left, greyscale on right) so Sol can judge both native 1x and x3!
    full.paste(half, (16, nh * 6 + 6))
    full.paste(grey_half, (nw + 48, nh * 6 + 6))
    return full


def build_props_contact_sheet():
    """Build contact sheet (colour top half + greyscale bottom half at x3 + native 1x inset strip) showing all 57 Section B props
    grouped clearly by hardware family and state, with legends outside runtime sprite bounds."""
    nw, nh = 440, 224
    bg_col = PAL[2] + (255,)
    panel_bg = PAL[1] + (255,)
    border_col = PAL[13] + (255,)

    half = Image.new('RGBA', (nw, nh), bg_col)

    def box(x0, y0, x1, y1):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                c = border_col if (x in (x0, x1) or y in (y0, y1)) else panel_bg
                half.putpixel((x, y), c)

    # Row 1 (y=2..66): 9 Selector Panels (32x48) + 3 Release Levers (24x36) + 2 Conduits (48x32)
    box(3, 2, 306, 66)
    _draw_label(half, (6, 4), 'SO-01 SELECTORS: LINE(0..2)  PLAT(0..2)  CAR(0..2)', 15)
    idx = 0
    for kind in ('line', 'platform', 'car'):
        for pos in (0, 1, 2):
            im = to_image(composite(pr_mod.build_selector_panel(kind, pos)))
            _paste_safe(half, im, (6 + idx * 33, 14))
            idx += 1
    box(309, 2, 436, 66)
    _draw_label(half, (312, 4), 'LEVER(3)  CONDUIT(2)', 15)
    for i, st in enumerate(('idle', 'buzzing', 'accepted')):
        im = to_image(composite(pr_mod.build_release_lever(st)))
        _paste_safe(half, im, (311 + i * 24, 22))
    _paste_safe(half, to_image(composite(pr_mod.build_conduit('mounted'))), (385, 11))
    _paste_safe(half, to_image(composite(pr_mod.build_conduit('fallen'))), (385, 34))

    # Row 2 (y=69..148): All thirteen 32x64 Doorways / Portals / Hatches / Bulkhead / Shutters / Barriers (full 33px spacing, zero overlap!)
    box(3, 69, 436, 148)
    _draw_label(half, (6, 71), 'GATE(2) STAFF(2) HATCH(C/O/FO/FC)   BULKHEAD SHUTTER(2) BARRIER(2)', 15)
    portals = [
        pr_mod.build_platform_gate('closed'),
        pr_mod.build_platform_gate('open'),
        pr_mod.build_staff_door('closed'),
        pr_mod.build_staff_door('open'),
        pr_mod.build_service_hatch('closed'),
        pr_mod.build_service_hatch('open'),
        pr_mod.build_service_hatch('frozen_open'),
        pr_mod.build_service_hatch('frozen_closed'),
        pr_mod.build_bulkhead_module(),
        pr_mod.build_inner_shutter('closed'),
        pr_mod.build_inner_shutter('raised'),
        pr_mod.build_staff_barrier('closed'),
        pr_mod.build_staff_barrier('open'),
    ]
    for i, layers in enumerate(portals):
        _paste_safe(half, to_image(composite(layers)), (5 + i * 33, 81))

    # Row 3 (y=151..220):
    box(3, 151, 436, 220)
    _draw_label(half, (6, 153), 'FLAP DIALS(6)          PLATES A/B/ALARM/STBY(8)   NOTE BELL READER(3)', 15)
    flaps = [
        pr_mod.build_flap_dial('line', 'idle'),
        pr_mod.build_flap_dial('line', 'jammed'),
        pr_mod.build_flap_dial('platform', 'idle'),
        pr_mod.build_flap_dial('platform', 'jammed'),
        pr_mod.build_flap_dial('time', 'idle'),
        pr_mod.build_flap_dial('time', 'jammed'),
    ]
    for i, layers in enumerate(flaps):
        _paste_safe(half, to_image(composite(layers)), (5 + i * 32, 162))

    plates = [
        pr_mod.build_floor_plate_ab('a', False),
        pr_mod.build_floor_plate_ab('a', True),
        pr_mod.build_floor_plate_ab('b', False),
        pr_mod.build_floor_plate_ab('b', True),
        pr_mod.build_alarm_plate('idle'),
        pr_mod.build_alarm_plate('ringing'),
        pr_mod.build_standby_plate('empty'),
        pr_mod.build_standby_plate('held'),
    ]
    for i, layers in enumerate(plates):
        px0 = 198 + (i % 4) * 33
        py0 = 160 + (i // 4) * 14
        _paste_safe(half, to_image(composite(layers)), (px0, py0))

    _paste_safe(half, to_image(composite(pr_mod.build_ticket_terms_notice())), (332, 161))
    _paste_safe(half, to_image(composite(pr_mod.build_bell_icon('idle'))), (350, 163))
    _paste_safe(half, to_image(composite(pr_mod.build_bell_icon('ringing'))), (360, 163))
    for i, st in enumerate(('idle', 'denied', 'accepted')):
        _paste_safe(half, to_image(composite(pr_mod.build_card_reader(st))), (372 + i * 20, 161))

    _draw_label(half, (6, 194), 'VALIDATOR(3) ECHO(2) ->', 15)
    _draw_label(half, (6, 206), 'BREAKER_C(3) RELAY_C(2)', 15)
    tall_smalls = [
        pr_mod.build_ticket_validator('idle'),
        pr_mod.build_ticket_validator('rejecting'),
        pr_mod.build_ticket_validator('accepted'),
        pr_mod.build_echo_pedestal('idle'),
        pr_mod.build_echo_pedestal('used'),
        pr_mod.build_breaker_c('idle'),
        pr_mod.build_breaker_c('engaged'),
        pr_mod.build_breaker_c('browned_out'),
        pr_mod.build_dead_relay_c('idle'),
        pr_mod.build_dead_relay_c('shake'),
    ]
    for i, layers in enumerate(tall_smalls):
        _paste_safe(half, to_image(composite(layers)), (196 + i * 24, 184))

    grey_half = _to_greyscale_rgba(half)
    top_x3 = half.resize((nw * 3, nh * 3), Image.NEAREST)
    bot_x3 = grey_half.resize((nw * 3, nh * 3), Image.NEAREST)
    total_h = nh * 6 + nh + 12
    full = Image.new('RGBA', (nw * 3, total_h), bg_col)
    full.paste(top_x3, (0, 0))
    full.paste(bot_x3, (0, nh * 3))
    # Native 1x strip at bottom (colour + greyscale + 2x tiled bulkhead wall seamless join proof)
    full.paste(half, (16, nh * 6 + 6))
    full.paste(grey_half, (nw + 48, nh * 6 + 6))
    bh_im = to_image(composite(pr_mod.build_bulkhead_module()))
    _paste_safe(full, bh_im, (nw * 2 + 96, nh * 6 + 20))
    _paste_safe(full, bh_im, (nw * 2 + 96 + 32, nh * 6 + 20 + 16))
    return full


def write_mockups(out_dir=None):
    """Write all 5 Step 1 mockup & greyscale proof PNGs to `out_dir` (default `design/art/mockups/`)."""
    target_dir = out_dir or MOCK_DIR
    os.makedirs(target_dir, exist_ok=True)
    r1_native = build_room1_step1_mockup()
    p1 = os.path.join(target_dir, 'ch01_step1_room_statues_mockup.png')
    r1_native.save(p1)

    r1_x3 = r1_native.resize((1920, 1080), Image.NEAREST)
    p2 = os.path.join(target_dir, 'ch01_step1_room_statues_x3_proof.png')
    r1_x3.save(p2)

    r1_grey_x3 = _to_greyscale_rgba(r1_x3)
    p3 = os.path.join(target_dir, 'ch01_step1_room_statues_greyscale_proof.png')
    r1_grey_x3.save(p3)

    st_sheet = build_statues_all13_contact_sheet()
    p4 = os.path.join(target_dir, 'ch01_step1_statues_all13_greyscale_proof.png')
    st_sheet.save(p4)

    pr_sheet = build_props_contact_sheet()
    p5 = os.path.join(target_dir, 'ch01_step1_props_greyscale_proof.png')
    pr_sheet.save(p5)
    return [p1, p2, p3, p4, p5]


if __name__ == '__main__':
    paths = write_mockups()
    for p in paths:
        print('wrote:', os.path.relpath(p, REPO))
