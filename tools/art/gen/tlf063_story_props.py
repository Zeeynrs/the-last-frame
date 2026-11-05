"""TLF-063 — Chapter 1 environmental storytelling props (ADR-022 A5, ART_BIBLE.md §C.6).

Deliverables (5 registered .pxo + .png assets covering all 4 TLF-063 items + 2 mockup/greyscale proof sheets):
  1. ch01_prop_departure_board_nowhere_idle (160x32, Wall_Fixtures z=7): "DESTINATION:" / "NOWHERE - 23:59"
  2. ch01_prop_sign_a1_research_idle        (96x16,  Wall_Fixtures z=7): "A1 -> RESEARCH"
  3. ch01_prop_door_rd_access_sealed_idle   (32x64,  Wall_Fixtures z=7): 2:1 isometric sealed "R&D ACCESS" bulkhead/door dressing
  4. ch01_prop_pillar_mark_sector_a_idle    (16x16,  Wall_Fixtures z=7): civic Sector A stencil decal for existing corner pillars
  5. ch01_prop_notice_closed_track_idle     (80x16,  Wall_Fixtures z=7): "CLOSED TRACK" plaque with diagonal closure stroke
"""
import os
from PIL import Image
from lib import Layer, PAL, REPO, composite, outline_mask, to_image

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
    '>': ["10000", "01000", "00100", "00010", "00100", "01000", "10000"],
    '&': ["01100", "10010", "10100", "01000", "10101", "10010", "01101"],
    '/': ["00001", "00010", "00100", "00100", "01000", "10000", "10000"],
    '(': ["00010", "00100", "01000", "01000", "01000", "00100", "00010"],
    ')': ["01000", "00100", "00010", "00010", "00010", "00100", "01000"],
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
    'K': ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    'L': ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    'M': ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    'N': ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    'O': ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    'P': ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    'R': ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    'S': ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    'T': ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    'U': ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    'V': ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    'W': ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
    'X': ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    'Y': ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
}


def draw_text_layer(layer, x, y, text, col, scale=1):
    cx = x
    for ch in text.upper():
        rows = FONT5X7.get(ch, FONT5X7[' '])
        for ry, rstr in enumerate(rows):
            for rx, bit in enumerate(rstr):
                if bit == '1':
                    for sy in range(scale):
                        for sx in range(scale):
                            layer.put(cx + rx * scale + sx, y + ry * scale + sy, col)
        cx += 6 * scale


# ============================================================================
# 1. DEPARTURE BOARD "DESTINATION: / NOWHERE - 23:59" (160x32, pivot (80, 28))
#    ART_BIBLE.md §C.6: 160x32 wall board, two lines, native 5x7 font at 8 px;
#    steel 11-15, recessed 00, restrained 24/25 digits. Static state.
# ============================================================================

def build_departure_board_nowhere():
    w, h = 160, 32
    shadow = Layer(w, h, 'Mount_Shadow')
    housing = Layer(w, h, 'Steel_Housing')
    recess = Layer(w, h, 'Recessed_Screen')
    text_l = Layer(w, h, 'Display_Text')

    # Down-right wall shadow + suspension rods at top
    shadow.rect(4, 5, 157, 30, 1)
    housing.rect(28, 0, 31, 4, 0)
    housing.rect(29, 0, 30, 4, 13)
    housing.rect(128, 0, 131, 4, 0)
    housing.rect(129, 0, 130, 4, 13)

    # Outer 1px 00 silhouette + bevelled steel housing (11..15)
    housing.rect(2, 3, 156, 29, 0)
    housing.rect(3, 4, 155, 28, 12)
    housing.hline(3, 155, 4, 15)
    housing.hline(3, 155, 5, 14)
    housing.vline(3, 4, 28, 14)
    housing.hline(3, 155, 28, 11)
    housing.vline(155, 4, 28, 11)
    # Corner rivets
    for rx, ry in [(5, 6), (153, 6), (5, 26), (153, 26)]:
        housing.put(rx, ry, 15 if rx == 5 else 11)

    # Recessed 00 display cavity (x=7..151, y=7..25) with subtle scanline/flap divider at y=16
    recess.rect(7, 7, 151, 25, 0)
    recess.hline(7, 151, 7, 11)
    recess.hline(7, 151, 25, 13)
    recess.hline(8, 150, 16, 1)

    # Line 1 (y=8..14): "DESTINATION:" (12 chars * 6 - 1 = 71 px -> x=12)
    draw_text_layer(text_l, 12, 8, "DESTINATION:", 24, scale=1)
    for x in range(12, 84):
        for y in (8, 9):
            if text_l.get(x, y) == 24:
                text_l.put(x, y, 25)
    # Subtle route status pips on top-right of Line 1 (steel/amber static indicator)
    text_l.rect(136, 10, 146, 12, 22)
    text_l.rect(140, 10, 142, 12, 24)

    # Line 2 (y=17..23): "NOWHERE - 23:59" (15 chars * 6 - 1 = 89 px -> x=12)
    draw_text_layer(text_l, 12, 17, "NOWHERE - 23:59", 24, scale=1)
    for x in range(12, 104):
        for y in (17, 18, 19):
            if text_l.get(x, y) == 24:
                text_l.put(x, y, 25)

    return [shadow, housing, recess, text_l]


# ============================================================================
# 2. WALL SIGN "A1 -> RESEARCH" (96x16, pivot (48, 14))
#    ART_BIBLE.md §C.6: 96x16, native 5x7 font; transit fed an ELYSIUM research route.
# ============================================================================

def build_sign_a1_research():
    w, h = 96, 16
    shadow = Layer(w, h, 'Mount_Shadow')
    frame = Layer(w, h, 'Sign_Housing')
    text_l = Layer(w, h, 'Sign_Glyphs')

    shadow.rect(3, 3, 94, 15, 1)
    frame.rect(1, 1, 93, 14, 0)
    frame.rect(2, 2, 92, 13, 12)
    frame.hline(2, 92, 2, 15)
    frame.vline(2, 2, 13, 14)
    frame.hline(2, 92, 13, 11)
    frame.vline(92, 2, 13, 11)

    # Dark recessed enamel sign face (x=4..90, y=3..12) with left sector colour bar
    frame.rect(4, 3, 90, 12, 0)
    frame.rect(4, 3, 20, 12, 22)
    frame.vline(21, 3, 12, 13)

    # "A1" on the left badge (x=6, y=4), "-> RESEARCH" on the right panel (x=24, y=4)
    draw_text_layer(text_l, 6, 4, "A1", 25, scale=1)
    draw_text_layer(text_l, 24, 4, "-> RESEARCH", 15, scale=1)
    # Highlight arrow "->" in warm amber 25 so the wayfinding direction pops cleanly
    draw_text_layer(text_l, 24, 4, "->", 25, scale=1)

    return [shadow, frame, text_l]


# ============================================================================
# 3. SEALED "R&D ACCESS" DOOR DRESSING (32x64, pivot (16, 56))
#    ART_BIBLE.md §C.6: 32x64 matching the existing 2:1 archway axis, visible
#    sealed seam and small "R&D ACCESS" plaque; non-traversable, no glowing prompt.
# ============================================================================

def _y_iso(x, z):
    return (31 - x) // 2 + z


def build_door_rd_access_sealed():
    w, h = 32, 64
    shadow = Layer(w, h, 'Cast_Shadow')
    frame = Layer(w, h, 'Bulkhead_Frame')
    seam = Layer(w, h, 'Sealed_Door_Leaves')
    plaque = Layer(w, h, 'RD_Access_Plaque')

    # 2:1 down-left ground shadow along z=48 across x=1..30 (matching step1_props._portal_shadow)
    for x in range(1, 31):
        yb = _y_iso(x, 48)
        if yb < h:
            shadow.put(x, yb, 1)

    # Outer 2:1 isometric steel door frame matching ch01_env_archway_frame_e_idle & step1_props._door_frame_32x64
    # Left jamb x=1..5, right jamb x=26..30, top lintel header z=1..12, interior aperture x=6..25, z=13..46
    fill = Layer(w, h, '_fill')
    for x in range(1, 31):
        for z in range(1, 48):
            y = _y_iso(x, z)
            if not (0 <= y < h):
                continue
            if z <= 12:
                if z == 1:
                    col = 14 if x < 26 else 13
                elif z == 2:
                    col = 13 if x < 26 else 12
                elif z == 12:
                    col = 2
                else:
                    col = 12 if x < 24 else 11
                    if x == 1:
                        col = 13
                    elif x == 30:
                        col = 2
                fill.put(x, y, col)
            elif x <= 5 or x >= 26:
                seam_row = (z % 8 == 0)
                if z >= 45:
                    col = 12 if z == 45 else 2
                elif x in (1, 26):
                    col = 13
                elif x in (2, 3, 27, 28):
                    col = 11 if seam_row else 12
                elif x in (4, 29):
                    col = 11
                else:
                    col = 2
                fill.put(x, y, col)
            else:
                # Heavy sealed double-leaf steel bulkhead door inside aperture x=6..25, z=13..46
                if z == 13 or x == 6:
                    col = 13
                elif z == 46 or x == 25:
                    col = 2
                else:
                    col = 12 if x < 16 else 11
                fill.put(x, y, col)

    # Top header division mark (x=4..12, z=3..10) + sealed status window (x=15..26, z=3..10) matching doorway family
    for x in range(4, 13):
        for z in range(3, 11):
            fill.put(x, _y_iso(x, z), 0 if (x in (4, 12) or z in (3, 10)) else 2)
    for (mx, mz) in ((7, 5), (8, 5), (6, 6), (9, 6), (6, 7), (7, 7), (8, 7), (9, 7), (6, 8), (9, 8)):
        fill.put(mx, _y_iso(mx, mz), 14)
    for x in range(15, 27):
        for z in range(3, 11):
            fill.put(x, _y_iso(x, z), 0 if (x in (15, 26) or z in (3, 10)) else 2)
    for x in range(18, 24):
        for z in range(6, 9):
            fill.put(x, _y_iso(x, z), 23 if z == 6 else 22)

    outline_mask(fill.mask(), 0, frame, w, h)
    frame.blit(fill)

    # Heavy welded/bolted centre vertical seam (x=15..16, z=13..46) + welded clamp brackets
    for z in range(13, 47):
        seam.put(15, _y_iso(15, z), 0)
        seam.put(16, _y_iso(16, z), 14)
        if z in (16, 17, 32, 33, 38, 39):
            for bx in range(13, 19):
                seam.put(bx, _y_iso(bx, z), 13 if bx < 17 else 11)
            seam.put(13, _y_iso(13, z), 15)
            seam.put(18, _y_iso(18, z), 0)

    # Muted dark-red/amber caution stripe along lower door skirt (x=6..25, z=42..45) — unlit, worn paint (22/24)
    for x in range(6, 26):
        if x in (15, 16):
            continue
        for dz in range(42, 46):
            y = _y_iso(x, dz)
            stripe = ((x + dz) // 2) % 2 == 0
            seam.put(x, y, 22 if stripe else 11)

    # Small non-glowing "R&D ACCESS" plaque (x=7..24, z=21..28) inside the aperture
    for x in range(7, 25):
        for dz in range(21, 29):
            y = _y_iso(x, dz)
            if x in (7, 24) or dz in (21, 28):
                plaque.put(x, y, 0)
            elif dz == 22 or x == 8:
                plaque.put(x, y, 14)
            else:
                plaque.put(x, y, 1)
    # Crisp 4px tall micro-glyphs for "R&D" (z=23..26) + padlock icon on right of plaque
    rd_pts = [
        # R (x=9..11)
        (9, 23), (10, 23), (9, 24), (11, 24), (9, 25), (10, 25), (9, 26), (11, 26),
        # & / + (x=13..14)
        (13, 24), (14, 23), (14, 25), (13, 26),
        # D (x=16..18)
        (16, 23), (17, 23), (16, 24), (18, 24), (16, 25), (18, 25), (16, 26), (17, 26),
        # Padlock / sealed bar icon on right of plaque (x=20..22)
        (21, 23), (20, 24), (21, 24), (22, 24), (20, 25), (22, 25), (20, 26), (21, 26), (22, 26),
    ]
    for (px, pz) in rd_pts:
        plaque.put(px, _y_iso(px, pz), 15 if px < 19 else 24)

    return [shadow, frame, seam, plaque]


# ============================================================================
# 4. SECTOR A PILLAR MARK DECAL (16x16, pivot (8, 14))
#    ART_BIBLE.md §C.6: reuse existing pillar; small 16x16 A/sector mark decal
#    in steel/quiet amber. Away from lever A/B labels and plate glyphs.
# ============================================================================

def build_pillar_mark_sector_a():
    w, h = 16, 16
    outline = Layer(w, h, 'Decal_Outline')
    plate = Layer(w, h, 'Stencil_Plate')
    glyph = Layer(w, h, 'Sector_A_Mark')

    # Civic wayfinding plaque with quiet red/amber transit band at bottom (distinct from square floor plates & lever badges)
    plate.rect(2, 2, 13, 13, 12)
    plate.hline(2, 13, 2, 15)
    plate.vline(2, 2, 13, 14)
    plate.hline(2, 13, 13, 11)
    plate.vline(13, 2, 13, 11)
    # Quiet crimson/amber civic sector stripe along bottom (y=10..12, matching chapter1.2_map.png pillar band)
    plate.rect(3, 10, 12, 12, 22)
    plate.hline(3, 12, 10, 23)

    # Stencilled "A" above the sector band (x=6..9, y=3..8) + side wayfinding ticks
    a_rows = [
        (3, [7, 8]),
        (4, [6, 9]),
        (5, [6, 9]),
        (6, [6, 7, 8, 9]),
        (7, [6, 9]),
        (8, [6, 9]),
    ]
    for y, xs in a_rows:
        for x in xs:
            glyph.put(x, y, 25 if y <= 5 else 24)
    # Micro "SEC" dots on the crimson band (y=11)
    for x in (4, 6, 8, 11):
        glyph.put(x, 11, 15)

    outline_mask(plate.mask(), 0, outline, w, h)
    return [outline, plate, glyph]


# ============================================================================
# 5. "CLOSED TRACK" NOTICE PLAQUE (80x16, pivot (40, 14))
#    ART_BIBLE.md §C.6: 80x16 plaque, one dark diagonal closure stroke,
#    no extra dates, commands, collectibles or invented readable lore.
# ============================================================================

def build_notice_closed_track():
    w, h = 80, 16
    shadow = Layer(w, h, 'Mount_Shadow')
    plaque = Layer(w, h, 'Plaque_Housing')
    text_l = Layer(w, h, 'Notice_Text')
    stroke = Layer(w, h, 'Closure_Stroke')

    shadow.rect(3, 3, 78, 15, 1)
    plaque.rect(1, 1, 77, 14, 0)
    plaque.rect(2, 2, 76, 13, 13)
    plaque.hline(2, 76, 2, 15)
    plaque.vline(2, 2, 13, 14)
    plaque.hline(2, 76, 13, 11)
    plaque.vline(76, 2, 13, 11)

    # Inner notice board face (worn slate/steel 12 with dark 01 border)
    plaque.rect(4, 3, 74, 12, 1)
    plaque.rect(5, 4, 73, 11, 12)

    # "CLOSED TRACK" in native 5x7 font (12 chars * 6 - 1 = 71 px; use 5px pitch for space -> fits x=5..73 at y=4..10)
    cx = 6
    for ch in "CLOSED TRACK":
        if ch == ' ':
            cx += 3
            continue
        rows = FONT5X7[ch]
        for ry, rstr in enumerate(rows):
            for rx, bit in enumerate(rstr):
                if bit == '1':
                    text_l.put(cx + rx, 4 + ry, 15 if ry <= 2 else 14)
        cx += 6

    # One bold diagonal closure stroke across the plaque (dark 00 core with 22/23 muted red border)
    stroke.line(6, 11, 72, 4, 22)
    stroke.line(6, 12, 72, 5, 0)
    stroke.line(7, 11, 73, 4, 23)

    return [shadow, plaque, text_l, stroke]


# ============================================================================
# 6. ASSET REGISTRY FOR TLF-063 (5 .pxo + .png assets)
# ============================================================================

def assets():
    return [
        (
            'ch01_prop_departure_board_nowhere_idle',
            'props',
            160, 32,
            ['Mount_Shadow', 'Steel_Housing', 'Recessed_Screen', 'Display_Text'],
            [build_departure_board_nowhere()],
            1.0,
            [],
            {'pivot': '(80, 28)', 'z': 'Wall_Fixtures (z_index = 7)',
             'story': 'Arrival Platform overhead board still announcing "DESTINATION: NOWHERE - 23:59" after the 23:54 evacuation.'},
        ),
        (
            'ch01_prop_sign_a1_research_idle',
            'props',
            96, 16,
            ['Mount_Shadow', 'Sign_Housing', 'Sign_Glyphs'],
            [build_sign_a1_research()],
            1.0,
            [],
            {'pivot': '(48, 14)', 'z': 'Wall_Fixtures (z_index = 7)',
             'story': 'Corridor directional sign ("A1 -> RESEARCH") establishing that Station Elysium-09 served the ELYSIUM research facility.'},
        ),
        (
            'ch01_prop_door_rd_access_sealed_idle',
            'props',
            32, 64,
            ['Cast_Shadow', 'Bulkhead_Frame', 'Sealed_Door_Leaves', 'RD_Access_Plaque'],
            [build_door_rd_access_sealed()],
            1.0,
            [],
            {'pivot': '(16, 56)', 'z': 'Wall_Fixtures (z_index = 7)',
             'story': 'Welded/clamped non-traversable 2:1 bulkhead door dressing with "R&D ACCESS" plaque sealing the direct research wing route.'},
        ),
        (
            'ch01_prop_pillar_mark_sector_a_idle',
            'props',
            16, 16,
            ['Decal_Outline', 'Stencil_Plate', 'Sector_A_Mark'],
            [build_pillar_mark_sector_a()],
            1.0,
            [],
            {'pivot': '(8, 14)', 'z': 'Wall_Fixtures (z_index = 7)',
             'story': 'Civic Sector A stencil decal mounted on existing structural pillars to tie the transit concourse and research access wing together.'},
        ),
        (
            'ch01_prop_notice_closed_track_idle',
            'props',
            80, 16,
            ['Mount_Shadow', 'Plaque_Housing', 'Notice_Text', 'Closure_Stroke'],
            [build_notice_closed_track()],
            1.0,
            [],
            {'pivot': '(40, 14)', 'z': 'Wall_Fixtures (z_index = 7)',
             'story': 'Station wall plaque ("CLOSED TRACK" with diagonal closure slash) showing service suspension prior to the 23:59 standstill.'},
        ),
    ]


# ============================================================================
# 7. MOCKUPS & GREYSCALE PROOFS (built strictly from delivered runtime PNGs)
# ============================================================================

MOCKUP_FILES = [
    'ch01_tlf063_story_props_room_mockup.png',
    'ch01_tlf063_story_props_greyscale_proof.png',
]


def mockup_path(fname, out_dir=None):
    base = out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups')
    return os.path.join(base, fname)


def _png(cat, stem):
    return Image.open(os.path.join(REPO, 'assets', cat, 'ch01', stem + '.png')).convert('RGBA')


def _draw_text_img(im, x, y, text, col_rgb, scale=1):
    px = im.load()
    w, h = im.size
    cx = x
    for ch in text.upper():
        rows = FONT5X7.get(ch, FONT5X7[' '])
        for ry, rstr in enumerate(rows):
            for rx, bit in enumerate(rstr):
                if bit == '1':
                    for sy in range(scale):
                        for sx in range(scale):
                            nx, ny = cx + rx * scale + sx, y + ry * scale + sy
                            if 0 <= nx < w and 0 <= ny < h:
                                px[nx, ny] = col_rgb + (255,)
        cx += 6 * scale


def build_story_props_room_mockup():
    """640x360 Arrival Platform + Sector A dressing mockup showing all 5 TLF-063 storytelling props in-world."""
    import placement_render as pl_mod

    r1 = pl_mod.build_rooms()[0]
    pcs = list(pl_mod.pieces(r1, anchor=pl_mod.px(6, 5)))
    im = Image.new('RGBA', (640, 360), PAL[0] + (255,))
    for z, y, p_im, o in sorted(pcs, key=lambda t: (t[0], t[1])):
        pl_mod.paste_clip(im, p_im, o)

    board = _png('props', 'ch01_prop_departure_board_nowhere_idle')
    sign_a1 = _png('props', 'ch01_prop_sign_a1_research_idle')
    door_rd = _png('props', 'ch01_prop_door_rd_access_sealed_idle')
    decal_a = _png('props', 'ch01_prop_pillar_mark_sector_a_idle')
    closed_tr = _png('props', 'ch01_prop_notice_closed_track_idle')
    pillar = _png('environments', 'ch01_env_wall_corner_pillar_idle')
    arch_e = _png('environments', 'ch01_env_archway_frame_e_idle')

    # 1. Place structural corner pillar at the North wall apex (304, 12) with Sector A decal mounted on its front face (312, 36)
    im.alpha_composite(pillar, (304, 12))
    im.alpha_composite(decal_a, (312, 36))

    # 2. Mount Departure Board "DESTINATION: NOWHERE - 23:59" on overhead concourse gantry above NE wall (x=344, y=6)
    #    with two steel suspension rods connecting to the top gantry beam (no overlap with clocks or floor!)
    for rx in (374, 472):
        for ry in range(0, 8):
            im.putpixel((rx, ry), PAL[12] + (255,))
            im.putpixel((rx + 1, ry), PAL[0] + (255,))
    im.alpha_composite(board, (344, 6))

    # 3. Mount "CLOSED TRACK" notice directly on the NW subterranean masonry wall face above the stalled transit car (x=214, y=66)
    im.alpha_composite(closed_tr, (214, 66))

    # 4. Mount "A1 -> RESEARCH" directional sign directly on the NE subterranean masonry wall face (x=388, y=78)
    #    pointing down-right toward the East archway
    im.alpha_composite(sign_a1, (388, 78))

    # 5. Install Sealed "R&D ACCESS" 2:1 Door Dressing directly at the East archway coordinate of Room 1
    arch_pos = (432, 152)
    for _z, _y, p_im, o in pcs:
        if p_im.size == (32, 64) and o[0] > 400 and o[1] > 140:
            arch_pos = (int(round(o[0])), int(round(o[1])))
            break
    im.alpha_composite(arch_e, arch_pos)
    im.alpha_composite(door_rd, arch_pos)

    # Top-left inset vignette (x=6..210, y=6..102) showing Sealed R&D Access Door in 2:1 archway + Pillar with Sector A mark
    inset = Image.new('RGBA', (204, 96), PAL[0] + (255,))
    for x in range(204):
        inset.putpixel((x, 0), PAL[13] + (255,))
        inset.putpixel((x, 95), PAL[13] + (255,))
    for y in range(96):
        inset.putpixel((0, y), PAL[13] + (255,))
        inset.putpixel((203, y), PAL[13] + (255,))
    _draw_text_img(inset, 6, 5, "2:1 R&D DOOR & PILLAR A", PAL[15], scale=1)

    inset.alpha_composite(arch_e, (16, 20))
    inset.alpha_composite(door_rd, (16, 20))
    inset.alpha_composite(pillar, (76, 20))
    inset.alpha_composite(decal_a, (84, 44))
    _draw_text_img(inset, 120, 34, "DECORATIVE", PAL[25], scale=1)
    _draw_text_img(inset, 120, 46, "NON-INTERACT", PAL[14], scale=1)
    _draw_text_img(inset, 120, 58, "ELYSIUM LORE", PAL[14], scale=1)

    im.alpha_composite(inset, (6, 6))
    return im


def build_story_props_greyscale_proof():
    """1320x1040 colour + luminance greyscale contact sheet (x3 and 1x native) of all 5 TLF-063 props."""
    W, H = 1320, 1040
    canvas = Image.new('RGBA', (W, H), PAL[0] + (255,))

    board = _png('props', 'ch01_prop_departure_board_nowhere_idle')
    sign_a1 = _png('props', 'ch01_prop_sign_a1_research_idle')
    door_rd = _png('props', 'ch01_prop_door_rd_access_sealed_idle')
    decal_a = _png('props', 'ch01_prop_pillar_mark_sector_a_idle')
    closed_tr = _png('props', 'ch01_prop_notice_closed_track_idle')
    pillar = _png('environments', 'ch01_env_wall_corner_pillar_idle')
    arch_e = _png('environments', 'ch01_env_archway_frame_e_idle')

    half = Image.new('RGBA', (W, 480), PAL[1] + (255,))
    _draw_text_img(half, 16, 10, "TLF-063 CH1 ENVIRONMENTAL STORYTELLING PROPS (X3 COLOUR ON WALL 08 & FLOOR 02 + 1X NATIVE STRIP)", PAL[15], scale=2)

    # 1. Departure board (160x32 -> x3 = 480x96) at (16, 36)
    bg_b = Image.new('RGBA', (164, 36), PAL[8] + (255,))
    bg_b.alpha_composite(board, (2, 2))
    half.alpha_composite(bg_b.resize((492, 108), Image.NEAREST), (16, 36))
    _draw_text_img(half, 16, 150, "1. CH01_PROP_DEPARTURE_BOARD_NOWHERE_IDLE (160X32) : DESTINATION: / NOWHERE - 23:59", PAL[25], scale=1)

    # 2. Wall sign "A1 -> RESEARCH" (96x16 -> x3 = 288x48) at (16, 174)
    bg_s = Image.new('RGBA', (100, 20), PAL[8] + (255,))
    bg_s.alpha_composite(sign_a1, (2, 2))
    half.alpha_composite(bg_s.resize((300, 60), Image.NEAREST), (16, 174))
    _draw_text_img(half, 16, 240, "2A. CH01_PROP_SIGN_A1_RESEARCH_IDLE (96X16)", PAL[15], scale=1)

    # 3. Notice "CLOSED TRACK" (80x16 -> x3 = 240x48) at (340, 174)
    bg_c = Image.new('RGBA', (84, 20), PAL[8] + (255,))
    bg_c.alpha_composite(closed_tr, (2, 2))
    half.alpha_composite(bg_c.resize((252, 60), Image.NEAREST), (340, 174))
    _draw_text_img(half, 340, 240, "4. CH01_PROP_NOTICE_CLOSED_TRACK_IDLE (80X16)", PAL[15], scale=1)

    # 4. Sealed "R&D ACCESS" door dressing (32x64 -> x3 = 96x192) standalone + inside archway_frame_e at (620, 36)
    bg_d1 = Image.new('RGBA', (36, 68), PAL[8] + (255,))
    bg_d1.alpha_composite(door_rd, (2, 2))
    half.alpha_composite(bg_d1.resize((108, 204), Image.NEAREST), (620, 36))

    bg_d2 = Image.new('RGBA', (36, 68), PAL[2] + (255,))
    bg_d2.alpha_composite(arch_e, (2, 2))
    bg_d2.alpha_composite(door_rd, (2, 2))
    half.alpha_composite(bg_d2.resize((108, 204), Image.NEAREST), (744, 36))
    _draw_text_img(half, 620, 246, "2B. DOOR_RD_ACCESS_SEALED (32X64: STANDALONE & IN ARCHWAY)", PAL[25], scale=1)

    # 5. Sector A pillar decal (16x16 -> x3 = 48x48) standalone + mounted on corner_pillar at (980, 36)
    bg_p1 = Image.new('RGBA', (20, 20), PAL[8] + (255,))
    bg_p1.alpha_composite(decal_a, (2, 2))
    half.alpha_composite(bg_p1.resize((60, 60), Image.NEAREST), (980, 36))

    bg_p2 = Image.new('RGBA', (36, 68), PAL[2] + (255,))
    bg_p2.alpha_composite(pillar, (2, 2))
    bg_p2.alpha_composite(decal_a, (10, 26))
    half.alpha_composite(bg_p2.resize((108, 204), Image.NEAREST), (1060, 36))
    _draw_text_img(half, 980, 246, "3. PILLAR_MARK_SECTOR_A (16X16 & ON PILLAR)", PAL[15], scale=1)

    # Native 1x strip at bottom of half (y=276..465) + in-room preview
    _draw_text_img(half, 16, 276, "NATIVE 1X EXPORTS (WALL 08 BACKDROP):", PAL[26], scale=2)
    nat_bg = Image.new('RGBA', (600, 84), PAL[8] + (255,))
    nat_bg.alpha_composite(board, (8, 8))
    nat_bg.alpha_composite(sign_a1, (8, 52))
    nat_bg.alpha_composite(closed_tr, (116, 52))
    nat_bg.alpha_composite(decal_a, (212, 52))
    nat_bg.alpha_composite(door_rd, (248, 8))
    nat_bg.alpha_composite(arch_e, (296, 8))
    nat_bg.alpha_composite(door_rd, (296, 8))
    nat_bg.alpha_composite(pillar, (344, 8))
    nat_bg.alpha_composite(decal_a, (352, 32))
    half.alpha_composite(nat_bg, (16, 300))

    canvas.alpha_composite(half, (0, 0))
    canvas.alpha_composite(half.convert('L').convert('RGBA'), (0, 500))
    _draw_text_img(canvas, 16, 995, "LUMINANCE GREYSCALE PROOF ABOVE (CONVERT L) — ALL 5 TLF-063 PROPS READABLE WITHOUT COLOUR OR GLOW", PAL[15], scale=2)
    return canvas


def write_mockups(out_dir=None):
    os.makedirs(out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups'), exist_ok=True)
    m1 = build_story_props_room_mockup()
    m1.save(mockup_path('ch01_tlf063_story_props_room_mockup.png', out_dir))
    m2 = build_story_props_greyscale_proof()
    m2.save(mockup_path('ch01_tlf063_story_props_greyscale_proof.png', out_dir))
