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


def _png(cat, stem):
    """Load an actual delivered runtime PNG from `assets/<cat>/ch01/<stem>.png` (zero proof-only synthesis)."""
    return Image.open(os.path.join(REPO, 'assets', cat, 'ch01', stem + '.png')).convert('RGBA')


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
    """Render Room 1 (640 x 360 px) strictly from delivered runtime PNGs:
    - Living Elias at (6, 5) beside N-01..N-04 at spec positions (`ch01_char_statue_commuter_<slug>_{idle,read}.png`)
    - SO-01 selector panels + release lever mounted on the North wall (`Wall_Fixtures`, z=7)
    - Floor plates A (`empty` and `pressed`) and B (`pressed`) lying on the 2:1 floor diamonds (`YSort_Props`, z=8)
    - Platform gate (`closed`) aligned in the actual East archway (`door_exit_east` at (448, 208)), plus an inset vignette
      in the top-left corner showing the actual East archway with `platform_gate_open` and floor diamonds with plates."""
    r1 = pl_mod.build_rooms()[0]
    elias_pos = pl_mod.px(6, 5)  # (336, 152)
    pcs = list(pl_mod.pieces(r1, anchor=elias_pos))

    # 1. Wall-mounted SO-01 selectors & release lever on the North wall (`Wall_Fixtures`, z_index = 7)
    so01_wall_mounts = [
        (_png('props', 'ch01_prop_selector_line_pos1'),     (16, 40), pl_mod.mount_pivot(r1, ('N', 1, -8)),  7),
        (_png('props', 'ch01_prop_selector_platform_pos1'), (16, 40), pl_mod.mount_pivot(r1, ('N', 3, -8)),  7),
        (_png('props', 'ch01_prop_selector_car_pos2'),      (16, 40), pl_mod.mount_pivot(r1, ('N', 4, -8)),  7),
        (_png('props', 'ch01_prop_release_lever_accepted'), (12, 32), pl_mod.mount_pivot(r1, ('N', 6, -10)), 7),
    ]
    for im, piv, pos, zz in so01_wall_mounts:
        pcs.append((zz, pos[1], im, (int(pos[0] - piv[0]), int(pos[1] - piv[1]))))

    # 2. Floor plates on 2:1 floor diamonds (`YSort_Props`, z_index = 8, pivot (16, 8) at tile diamond centre `px(tx, ty) + (0, 8)`)
    floor_plates_in_room = [
        (_png('props', 'ch01_prop_floor_plate_a_empty'),   (16, 8), (pl_mod.px(7, 5)[0], pl_mod.px(7, 5)[1] + 8), 8),
        (_png('props', 'ch01_prop_floor_plate_a_pressed'), (16, 8), (pl_mod.px(8, 5)[0], pl_mod.px(8, 5)[1] + 8), 8),
        (_png('props', 'ch01_prop_floor_plate_b_pressed'), (16, 8), (pl_mod.px(8, 6)[0], pl_mod.px(8, 6)[1] + 8), 8),
    ]
    for im, piv, pos, zz in floor_plates_in_room:
        pcs.append((zz, pos[1], im, (int(pos[0] - piv[0]), int(pos[1] - piv[1]))))

    # 3. Platform gate (`closed`) in the East archway (`door_exit_east` at (448, 208), pivot (16, 56))
    gate_closed_im = _png('props', 'ch01_prop_platform_gate_closed')
    pcs.append((10, 208, gate_closed_im, (448 - 16, 208 - 56)))

    # 4. Commuter statues loaded directly from delivered `ch01_char_statue_commuter_<slug>_{idle,read}.png`
    shimmer_sheet = _png('props', 'ch01_prop_trace_shimmer_ring_loop')
    shimmer_f0 = shimmer_sheet.crop((0, 0, 24, 12))
    glyph_im = _png('props', 'ch01_prop_trace_timestamp_glyph_idle')

    r1_commuters = [
        ('N-01', (352, 208), 'n01_conductor', 'idle', True),
        ('N-02', (272, 168), 'n02_student',   'idle', False),
        ('N-03', (348, 122), 'n03_old_man',   'read', False),
        ('N-04', (400, 216), 'n04_cleaner',   'idle', False),
    ]
    for cid, pos, slug, mode, has_shimmer in r1_commuters:
        if has_shimmer:
            pcs.append((8, pos[1] - 0.1, shimmer_f0, (pos[0] - 12, pos[1] - 6)))
        st_im = _png('characters', f'ch01_char_statue_commuter_{slug}_{mode}')
        sort_y = pos[1] + (1.0 if cid == 'N-03' else 0.0)
        pcs.append((10, sort_y, st_im, (pos[0] - 8, pos[1] - 36)))
        if has_shimmer:
            pcs.append((11, pos[1] + 0.2, glyph_im, (pos[0] - 3, pos[1] - 39)))

    bg = PAL[0] + (255,)
    cv = Image.new('RGBA', (640, 360), bg)
    for z, y, im, o in sorted(pcs, key=lambda t: (t[0], t[1])):
        _paste_safe(cv, im, o)

    # Top-left inset proof (x=6..188, y=6..94) showing East Archway + Gate (CLOSED vs OPEN) & Floor Diamonds + Plates A/B
    tile_dark = _png('environments', 'ch01_env_tile_terrazzo_dark_idle')
    tile_amber = _png('environments', 'ch01_env_tile_tactile_amber_idle')
    arch_e = _png('environments', 'ch01_env_archway_frame_e_idle')
    gate_open_im = _png('props', 'ch01_prop_platform_gate_open')
    pa_emp = _png('props', 'ch01_prop_floor_plate_a_empty')
    pa_prs = _png('props', 'ch01_prop_floor_plate_a_pressed')

    # Draw inset border box using palette colours (PAL[1] fill, PAL[13] border)
    for yy in range(4, 96):
        for xx in range(4, 186):
            c = PAL[13] + (255,) if (xx in (4, 185) or yy in (4, 95)) else PAL[1] + (255,)
            cv.putpixel((xx, yy), c)
    # Left mini-vignette (x=14..86): Floor diamonds + Archway_E + Gate CLOSED + Plate A empty
    for (tx, ty, tim) in ((0, 0, tile_dark), (1, 0, tile_amber), (0, 1, tile_dark), (1, 1, tile_amber)):
        _paste_safe(cv, tim, (26 + (tx - ty) * 16, 62 + (tx + ty) * 8))
    _paste_safe(cv, pa_emp, (26 - 16, 70))
    _paste_safe(cv, arch_e, (42, 14))
    _paste_safe(cv, gate_closed_im, (42, 14))

    # Right mini-vignette (x=104..176): Floor diamonds + Archway_E + Gate OPEN + Plate A pressed
    for (tx, ty, tim) in ((0, 0, tile_dark), (1, 0, tile_amber), (0, 1, tile_dark), (1, 1, tile_amber)):
        _paste_safe(cv, tim, (116 + (tx - ty) * 16, 62 + (tx + ty) * 8))
    _paste_safe(cv, pa_prs, (116 - 16, 70))
    _paste_safe(cv, arch_e, (132, 14))
    _paste_safe(cv, gate_open_im, (132, 14))

    return cv


def build_statues_all13_contact_sheet():
    """Build contact sheet (colour top half + greyscale bottom half at x3 + native 1x inset strip) strictly from delivered runtime PNGs:
    - Band 1: Living Elias + All 13 assembled Step 1 commuters (`ch01_char_statue_commuter_<slug>_idle.png`) + Active Trace + Read on dark/lit + Lit comparison.
    - Band 2: All 13 assembled Step 1 commuters in static `_read` mode (`ch01_char_statue_commuter_<slug>_read.png`) on alternating dark wall & lit floor swatches,
      showing the complete person + held prop silhouette outline (trolley, crank, courier bag, suitcase+map, etc.).
    - Band 3: All 10 modular statue poses (6 base bodies + 4 specific poses) in `_idle` and static `_read`.
    - Band 4: All 14 modular prop overlays (`_idle` and `_read`) + 4 stepped Trace shimmer ring frames (24x12) + 6x6 timestamp glyph + N-03 seated on bench."""
    nw, nh = 440, 236
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

    # --- Band 1 (y=2..60): Living Elias + 13 Assembled Commuters (`_idle`) + Trace Active vs Reduced-Effects (Dark & Lit)
    box(3, 2, nw - 4, 60)
    _draw_label(half, (6, 4), 'ELIAS  N01..N21 ASSEMBLED IDLE (13)         TRACE   READ:DK/LT  LIT-CMP', 15)

    sheet_elias = _png('characters', 'ch01_char_elias_base_sheet')
    elias_se = sheet_elias.crop((10 * 32, 0, 11 * 32, 48))
    _paste_safe(half, elias_se, (5, 12))

    for i, (cid, slug, rm, tile, px_pos, pk, ovs, tstr, role) in enumerate(st_mod.COMMUTER_ASSEMBLIES):
        cx = 40 + i * 21
        im_c = _png('characters', f'ch01_char_statue_commuter_{slug}_idle')
        _paste_safe(half, im_c, (cx, 18))

    sh_sheet = _png('props', 'ch01_prop_trace_shimmer_ring_loop')
    sh_f0 = sh_sheet.crop((0, 0, 24, 12))
    gl_im = _png('props', 'ch01_prop_trace_timestamp_glyph_idle')
    n01_idle = _png('characters', 'ch01_char_statue_commuter_n01_conductor_idle')
    _paste_safe(half, sh_f0, (318, 44))
    _paste_safe(half, n01_idle, (322, 18))
    _paste_safe(half, gl_im, (327, 12))

    box(352, 13, 374, 58, fill=PAL[1] + (255,))
    box(376, 13, 398, 58, fill=lit_floor_bg)
    box(400, 13, 434, 58, fill=lit_floor_bg)
    n01_read = _png('characters', 'ch01_char_statue_commuter_n01_conductor_read')
    _paste_safe(half, n01_read, (355, 18))
    _paste_safe(half, n01_read, (379, 18))
    _paste_safe(half, elias_se, (398, 12))
    _paste_safe(half, n01_idle, (418, 18))

    # --- Band 2 (y=63..118): All 13 Assembled Commuters in static `_read` mode (`ch01_char_statue_commuter_<slug>_read.png`)
    #     with lit-floor half-swatches so person + prop read outline (trolley, crank, bags) is verified on dark & lit!
    box(3, 63, nw - 4, 118)
    _draw_label(half, (6, 65), 'N01..N21 ASSEMBLED STATIC READ (13 DELIVERED PNGS: DARK/LIT SPLIT)', 15)
    for i, (cid, slug, rm, tile, px_pos, pk, ovs, tstr, role) in enumerate(st_mod.COMMUTER_ASSEMBLIES):
        cx = 8 + i * 32
        box(cx + 8, 74, cx + 19, 116, fill=lit_floor_bg)
        im_r = _png('characters', f'ch01_char_statue_commuter_{slug}_read')
        _paste_safe(half, im_r, (cx, 76))

    # --- Band 3 (y=121..177): 6 Base Bodies + 4 Specific Poses in `_idle` and static `_read`
    box(3, 121, nw - 4, 177)
    _draw_label(half, (6, 123), '6 BASE BODIES (A1..C2) + 4 POSES (N03 N04 N05 N11) : IDLE & READ', 15)
    pose_keys = [
        'body_a_pose1', 'body_a_pose2',
        'body_b_pose1', 'body_b_pose2',
        'body_c_pose1', 'body_c_pose2',
        'n03_old_man_seated', 'n04_cleaner', 'n05_courier_vault', 'n11_tech_crank',
    ]
    for i, pk in enumerate(pose_keys):
        px0 = 6 + i * 43
        box(px0 + 25, 132, px0 + 36, 175, fill=lit_floor_bg)
        im_idle = _png('characters', f'ch01_char_statue_{pk}_idle')
        im_read = _png('characters', f'ch01_char_statue_{pk}_read')
        _paste_safe(half, im_idle, (px0, 135))
        _paste_safe(half, im_read, (px0 + 19, 135))

    # --- Band 4 (y=180..233): 14 Overlays (`_idle` & `_read`) + 4 Shimmer Frames (F1..F4) + 6x6 Glyph + N-03 Seated on Bench
    box(3, 180, nw - 4, 233)
    _draw_label(half, (6, 182), '14 OVERLAYS (IDLE+READ)                     SHIMMER F1..F4  GL  N03+BENCH', 15)
    ov_keys = [
        'suitcase', 'paper_bag', 'whistle', 'trolley', 'phone', 'red_coat', 'briefcase',
        'sleeping_child', 'headphones', 'hatch_crank', 'gate_lever', 'breaker_handle', 'map', 'courier_bag',
    ]
    for i, ok in enumerate(ov_keys):
        ox = 6 + i * 19
        im_ov_r = _png('props', f'ch01_prop_statue_ov_{ok}_read')
        _paste_safe(half, im_ov_r, (ox, 191))

    for fi in range(4):
        fx = 278 + (fi % 2) * 28
        fy = 197 + (fi // 2) * 16
        _paste_safe(half, sh_sheet.crop((fi * 24, 0, (fi + 1) * 24, 12)), (fx, fy))
    _paste_safe(half, gl_im, (342, 205))

    bench_im = _png('props', 'ch01_prop_station_bench_idle')
    n03_comp = _png('characters', 'ch01_char_statue_commuter_n03_old_man_idle')
    _paste_safe(half, bench_im, (366, 197))
    _paste_safe(half, n03_comp, (382, 189))

    # Upscale x3 (1320 x 1416) + embed native 1x comparison strip at bottom!
    grey_half = _to_greyscale_rgba(half)
    top_x3 = half.resize((nw * 3, nh * 3), Image.NEAREST)
    bot_x3 = grey_half.resize((nw * 3, nh * 3), Image.NEAREST)
    total_h = nh * 6 + nh + 12
    full = Image.new('RGBA', (nw * 3, total_h), bg_col)
    full.paste(top_x3, (0, 0))
    full.paste(bot_x3, (0, nh * 3))
    full.paste(half, (16, nh * 6 + 6))
    full.paste(grey_half, (nw + 48, nh * 6 + 6))
    return full


def build_props_contact_sheet():
    """Build contact sheet (colour top half + greyscale bottom half at x3 + native 1x inset strip + in-room archway/floor-plate proof)
    strictly from delivered runtime PNGs."""
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
            im = _png('props', f'ch01_prop_selector_{kind}_pos{pos}')
            _paste_safe(half, im, (6 + idx * 33, 14))
            idx += 1
    box(309, 2, 436, 66)
    _draw_label(half, (312, 4), 'LEVER(3)  CONDUIT(2)', 15)
    for i, st in enumerate(('idle', 'buzzing', 'accepted')):
        im = _png('props', f'ch01_prop_release_lever_{st}')
        _paste_safe(half, im, (311 + i * 24, 22))
    _paste_safe(half, _png('props', 'ch01_prop_conduit_mounted'), (385, 11))
    _paste_safe(half, _png('props', 'ch01_prop_conduit_fallen'), (385, 34))

    # Row 2 (y=69..148): All thirteen 32x64 Doorways / Portals / Hatches / Bulkhead / Shutters / Barriers (full 33px spacing, zero overlap!)
    box(3, 69, 436, 148)
    _draw_label(half, (6, 71), 'GATE(2) STAFF(2) HATCH(C/O/FO/FC)   BULKHEAD SHUTTER(2) BARRIER(2)', 15)
    portal_stems = [
        ('props', 'ch01_prop_platform_gate_closed'),
        ('props', 'ch01_prop_platform_gate_open'),
        ('props', 'ch01_prop_staff_door_closed'),
        ('props', 'ch01_prop_staff_door_open'),
        ('props', 'ch01_prop_service_hatch_closed'),
        ('props', 'ch01_prop_service_hatch_open'),
        ('props', 'ch01_prop_service_hatch_frozen_open'),
        ('props', 'ch01_prop_service_hatch_frozen_closed'),
        ('environments', 'ch01_env_wall_bulkhead_module_idle'),
        ('props', 'ch01_prop_inner_shutter_closed'),
        ('props', 'ch01_prop_inner_shutter_raised'),
        ('props', 'ch01_prop_staff_barrier_closed'),
        ('props', 'ch01_prop_staff_barrier_open'),
    ]
    for i, (cat, stem) in enumerate(portal_stems):
        _paste_safe(half, _png(cat, stem), (5 + i * 33, 81))

    # Row 3 (y=151..220):
    box(3, 151, 436, 220)
    _draw_label(half, (6, 153), 'FLAP DIALS(6)          PLATES A/B/ALARM/STBY(8)   NOTE BELL READER(3)', 15)
    flap_stems = [
        'ch01_prop_flap_dial_line_idle',
        'ch01_prop_flap_dial_line_jammed',
        'ch01_prop_flap_dial_platform_idle',
        'ch01_prop_flap_dial_platform_jammed',
        'ch01_prop_flap_dial_time_idle',
        'ch01_prop_flap_dial_time_jammed',
    ]
    for i, stem in enumerate(flap_stems):
        _paste_safe(half, _png('props', stem), (5 + i * 32, 162))

    plate_stems = [
        'ch01_prop_floor_plate_a_empty',
        'ch01_prop_floor_plate_a_pressed',
        'ch01_prop_floor_plate_b_empty',
        'ch01_prop_floor_plate_b_pressed',
        'ch01_prop_alarm_plate_idle',
        'ch01_prop_alarm_plate_ringing',
        'ch01_prop_standby_plate_empty',
        'ch01_prop_standby_plate_held',
    ]
    for i, stem in enumerate(plate_stems):
        px0 = 198 + (i % 4) * 33
        py0 = 160 + (i // 4) * 14
        _paste_safe(half, _png('props', stem), (px0, py0))

    _paste_safe(half, _png('props', 'ch01_prop_ticket_terms_notice_idle'), (332, 161))
    _paste_safe(half, _png('props', 'ch01_prop_bell_icon_idle'), (350, 163))
    _paste_safe(half, _png('props', 'ch01_prop_bell_icon_ringing'), (360, 163))
    for i, st in enumerate(('idle', 'denied', 'accepted')):
        _paste_safe(half, _png('props', f'ch01_prop_card_reader_{st}'), (372 + i * 20, 161))

    _draw_label(half, (6, 194), 'VALIDATOR(3) ECHO(2) ->', 15)
    _draw_label(half, (6, 206), 'BREAKER_C(3) RELAY_C(2)', 15)
    tall_small_stems = [
        'ch01_prop_ticket_validator_idle',
        'ch01_prop_ticket_validator_rejecting',
        'ch01_prop_ticket_validator_accepted',
        'ch01_prop_echo_pedestal_idle',
        'ch01_prop_echo_pedestal_used',
        'ch01_prop_breaker_c_idle',
        'ch01_prop_breaker_c_engaged',
        'ch01_prop_breaker_c_browned_out',
        'ch01_prop_dead_relay_c_idle',
        'ch01_prop_dead_relay_c_shake',
    ]
    for i, stem in enumerate(tall_small_stems):
        _paste_safe(half, _png('props', stem), (196 + i * 24, 184))

    grey_half = _to_greyscale_rgba(half)
    top_x3 = half.resize((nw * 3, nh * 3), Image.NEAREST)
    bot_x3 = grey_half.resize((nw * 3, nh * 3), Image.NEAREST)
    total_h = nh * 6 + nh + 12
    full = Image.new('RGBA', (nw * 3, total_h), bg_col)
    full.paste(top_x3, (0, 0))
    full.paste(bot_x3, (0, nh * 3))
    # Native 1x strip at bottom (colour + greyscale + in-room Archway+Gate & Floor+Plates & Tiled Bulkhead proof in colour & greyscale)
    full.paste(half, (16, nh * 6 + 6))
    full.paste(grey_half, (nw + 32, nh * 6 + 6))

    # Build a 200x108 mini proof vignette of:
    # (1) East Archway + Platform Gate CLOSED & OPEN over floor diamonds
    # (2) 2x Tiled Bulkhead + Service Hatch Frozen-Open
    # (3) Floor Plates A/B/Alarm/Standby on floor diamonds
    vig = Image.new('RGBA', (196, 108), panel_bg)
    _draw_label(vig, (4, 2), 'ARCH+GATE(C/O) BULKHEAD+PLATES', 15)
    tile_dark = _png('environments', 'ch01_env_tile_terrazzo_dark_idle')
    tile_conc = _png('environments', 'ch01_env_tile_concrete_service_idle')
    arch_e = _png('environments', 'ch01_env_archway_frame_e_idle')
    gate_c = _png('props', 'ch01_prop_platform_gate_closed')
    gate_o = _png('props', 'ch01_prop_platform_gate_open')
    bh_im = _png('environments', 'ch01_env_wall_bulkhead_module_idle')
    hatch_fo = _png('props', 'ch01_prop_service_hatch_frozen_open')

    # Archway + Gate Closed (x=8) & Open (x=52) over floor diamonds
    for ox, gim in ((8, gate_c), (52, gate_o)):
        _paste_safe(vig, tile_dark, (ox, 62))
        _paste_safe(vig, tile_dark, (ox - 16, 70))
        _paste_safe(vig, arch_e, (ox, 14))
        _paste_safe(vig, gim, (ox, 14))
    # 2x Tiled Bulkhead + Service Hatch Frozen Open along 2:1 down-left slope (x=104..168)
    _paste_safe(vig, bh_im, (148, 10))
    _paste_safe(vig, bh_im, (116, 26))
    _paste_safe(vig, hatch_fo, (84, 42))
    # Floor plates on concrete floor diamonds at bottom (y=82..98)
    for i, pstem in enumerate(('ch01_prop_floor_plate_a_empty', 'ch01_prop_floor_plate_a_pressed', 'ch01_prop_floor_plate_b_pressed', 'ch01_prop_alarm_plate_ringing')):
        _paste_safe(vig, tile_conc, (8 + i * 44, 88))
        _paste_safe(vig, _png('props', pstem), (8 + i * 44, 88))

    vig_grey = _to_greyscale_rgba(vig)
    full.paste(vig, (nw * 2 + 56, nh * 6 + 6))
    full.paste(vig_grey, (nw * 2 + 56, nh * 6 + 120))
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
