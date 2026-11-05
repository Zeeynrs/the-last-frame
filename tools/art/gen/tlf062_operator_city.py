"""TLF-062 — Operator sighting sprite + Beat 10 frozen city plate & silent Mira broadcast (ADR-022, ART_BIBLE.md §C.3–C.5).

All art is authored pixel-by-pixel in TLF-CH01-32 (32 colours, binary alpha 0/255).
"""
import os
from PIL import Image
from lib import Layer, PAL, REPO, composite, outline_mask, sheet_image, to_image

# 5x7 bitmap font for 23:59 clocks and mockup labels
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
    '.': ["00000", "00000", "00000", "00000", "00000", "00110", "00110"],
    '/': ["00001", "00010", "00100", "00100", "01000", "10000", "10000"],
    '(': ["00010", "00100", "01000", "01000", "01000", "00100", "00010"],
    ')': ["01000", "00100", "00010", "00010", "00010", "00100", "01000"],
    '+': ["00000", "00100", "00100", "11111", "00100", "00100", "00000"],
    '=': ["00000", "00000", "11111", "00000", "11111", "00000", "00000"],
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
# 1. OPERATOR SIGHTING SPRITE (128x48 = 4 frames of 32x48, pivot (16, 44))
#    ART_BIBLE.md §C.3 & §C.5
#    Layers: Contact_Shadow, Robe, Hood_Mask, Scarf, Hand_Watch
# ============================================================================

OPERATOR_LAYER_NAMES = ['Contact_Shadow', 'Robe', 'Hood_Mask', 'Scarf', 'Hand_Watch']
OPERATOR_DURATIONS = [2.0, 2.0, 8.0, 2.0]   # @ 8.0 FPS => 0.25s, 0.25s, 1.00s, 0.25s


def _build_operator_frame(frame_idx):
    """frame_idx in 0..3 corresponding to F1 (rest), F2 (lift), F3 (check), F4 (lower)."""
    w, h = 32, 48
    shadow = Layer(w, h, 'Contact_Shadow')
    robe = Layer(w, h, 'Robe')
    hood = Layer(w, h, 'Hood_Mask')
    # Per ADR-022 A3 & Sol review cb2acbd: retain populated Scarf layer (22/23) in .pxo, disabled by default for Ch1 export
    scarf = Layer(w, h, 'Scarf', visible=False)
    hand_watch = Layer(w, h, 'Hand_Watch')

    # 1. Contact_Shadow: compact down-right floor ellipse around foot pivot (16, 44)
    for y, (x0, x1) in [(43, (8, 23)), (44, (7, 25)), (45, (9, 24))]:
        shadow.hline(x0, x1, y, 1)

    # 2. Robe: continuous ankle-length silhouette (peaked shoulders -> broad lower hem, boot soles at y=44)
    # Matches C.5 Operator column geometry (x=5..27 at hem, boots at x=11..14 and x=18..21 on y=44)
    robe_spans = [
        (13, 9, 23),
        (14, 9, 23),
        (15, 9, 23),
        (16, 9, 23),
        (17, 9, 23),
        (18, 9, 23),
        (19, 9, 23),
        (20, 8, 25),
        (21, 8, 25),
        (22, 8, 25),
        (23, 8, 26),
        (24, 8, 24),
        (25, 8, 24),
        (26, 8, 24),
        (27, 7, 25),
        (28, 7, 25),
        (29, 7, 25),
        (30, 7, 25),
        (31, 7, 25),
        (32, 7, 25),
        (33, 7, 25),
        (34, 6, 26),
        (35, 6, 26),
        (36, 6, 26),
        (37, 6, 26),
        (38, 6, 26),
        (39, 6, 26),
        (40, 6, 26),
        (41, 5, 27),
        (42, 5, 27),
        (43, 6, 26),
    ]
    body_fill = Layer(w, h, '_robe_fill')
    for y, x0, x1 in robe_spans:
        for x in range(x0 + 1, x1):
            # Top-left (315 deg) lighting across back-three-quarter robe folds
            if x <= x0 + 3 and y <= 34:
                col = 4 if (x == x0 + 1 and y <= 24) else 3
            elif x <= 14:
                col = 3 if (x in (11, 14) and y < 39) else 2
            elif x in (16, 20) and 17 <= y <= 41:
                # Vertical pleat ridges catching faint top-left light
                col = 3 if y < 30 else 2
            elif x >= x1 - 3 or y >= 41:
                col = 1
            else:
                col = 2
            body_fill.put(x, y, col)
    # Lower hem trim (subtle dark fold line at y=41..42, no gold filigree)
    for x in range(7, 26):
        if x % 4 != 0:
            body_fill.put(x, 42, 1)
    # Boot heels at y=44 (matching C.5: 11..14 and 18..21)
    for x in range(11, 15):
        body_fill.put(x, 43, 1)
        robe.put(x, 44, 0)
    for x in range(18, 22):
        body_fill.put(x, 43, 1)
        robe.put(x, 44, 0)

    outline_mask(body_fill.mask(), 0, robe, w, h)
    robe.blit(body_fill)

    # 3. Hood_Mask: peaked cowl higher/wider than Elias's hair; closed slate mask rim under right hood edge
    # In F3 (frame_idx == 2), head/hood inclines 1 px downward toward the pocket watch.
    hy = 1 if frame_idx == 2 else 0
    hood_spans = [
        (2 + hy, 15, 17),
        (3 + hy, 15, 17),
        (4 + hy, 14, 18),
        (5 + hy, 13, 19),
        (6 + hy, 13, 19),
        (7 + hy, 12, 20),
        (8 + hy, 11, 21),
        (9 + hy, 10, 22),
        (10 + hy, 10, 22),
        (11 + hy, 10, 22),
        (12 + hy, 10, 22),
        (13 + hy, 9, 23),
    ]
    hood_fill = Layer(w, h, '_hood_fill')
    for y, x0, x1 in hood_spans:
        for x in range(x0 + 1, x1):
            if x <= x0 + 2 and y <= 10 + hy:
                col = 4
            elif x <= 16:
                col = 3
            elif x >= x1 - 2:
                col = 1
            else:
                col = 2
            hood_fill.put(x, y, col)
    # Closed side mask plate tucked beneath the right hood opening (indices 12/13/14, zero face/skin/eyes)
    hood_fill.put(20, 8 + hy, 13)
    hood_fill.put(20, 9 + hy, 14)
    hood_fill.put(21, 9 + hy, 12)
    hood_fill.put(20, 10 + hy, 13)
    hood_fill.put(21, 10 + hy, 12)
    hood_fill.put(20, 11 + hy, 12)
    outline_mask(hood_fill.mask(), 0, hood, w, h)
    hood.blit(hood_fill)

    # 4. Scarf: separate layer (22 shadow #4A1C14, 23 mid #8C2D19) under the hood/collar on the right shoulder
    # Matches C.5 rows y=13..14 (x=17..21) so toggling Scarf off leaves the complete Robe/Hood underneath.
    for x in range(17, 22):
        scarf.put(x, 13, 23 if x < 20 else 22)
        scarf.put(x, 14, 22 if x in (17, 21) else 23)
    scarf.put(19, 15, 22)
    scarf.put(20, 15, 23)

    # 5. Hand_Watch: right sleeve/gloved hand + Elias's 3x3 brass pocket watch (25/26, hollow 00 centre, 1px 26 crown)
    # Frame-specific watch top-left (wx, wy) of the 3x3 watch case:
    #   F1 (rest):  (25, 26) — low at hip
    #   F2 (lift):  (25, 23) — rising
    #   F3 (check): (26, 20) — outside robe contour at lower-chest (exact C.5 rows y=20..22, cols x=26..28!)
    #   F4 (lower): (25, 24) — descending
    watch_pos = [(25, 26), (25, 23), (26, 20), (25, 24)][frame_idx]
    wx, wy = watch_pos

    hw_fill = Layer(w, h, '_hw_fill')
    # Right sleeve & gloved hand reaching to hold the watch
    sleeve_y0 = wy - 2
    for sy in range(sleeve_y0, wy + 3):
        hw_fill.put(wx - 3, sy, 2)
        hw_fill.put(wx - 2, sy, 3 if sy == sleeve_y0 else 1)
    # Gloved hand (indices 12/13)
    hw_fill.put(wx - 1, wy, 13)
    hw_fill.put(wx - 1, wy + 1, 12)
    # Short brass watch chain (25) linking waist/sleeve to watch
    hw_fill.put(wx - 2, wy + 2, 25)
    hw_fill.put(wx - 1, wy + 2, 25)

    # 1px crown above watch centre (wx + 1, wy - 1)
    hw_fill.put(wx + 1, wy - 1, 26)
    # 3x3 brass pocket watch case with hollow 00 centre (matching C.5: www / w.w / www)
    for dy in range(3):
        for dx in range(3):
            if dx == 1 and dy == 1:
                hw_fill.put(wx + dx, wy + dy, 0)   # hollow dark dial centre
            elif dx == 0 or dy == 0:
                hw_fill.put(wx + dx, wy + dy, 26)  # top-left bright gold highlight
            else:
                hw_fill.put(wx + dx, wy + dy, 25)  # warm brass body

    outline_mask(hw_fill.mask(), 0, hand_watch, w, h)
    hand_watch.blit(hw_fill)

    return [shadow, robe, hood, scarf, hand_watch]


def build_operator_sighting_frames():
    return [_build_operator_frame(i) for i in range(4)]


def operator_tags():
    return [{
        "color": "9e7bffff",
        "from": 1,
        "name": "check_watch_ne",
        "to": 4,
        "user_data": "8fps_0.25_0.25_1.00_0.25s",
    }]


# ============================================================================
# 2. OPERATOR RESTRAINED TRACE GROUND SIGNATURE (32x48, pivot (16, 44))
#    ART_BIBLE.md §C.3: separate effect layer/export, never inside body or over watch
# ============================================================================

def build_operator_trace_ring():
    w, h = 32, 48
    out_l = Layer(w, h, 'Ring_Outline')
    violet_l = Layer(w, h, 'Trace_Violet')
    gold_l = Layer(w, h, 'Trace_Gold_Ticks')

    # Restrained isometric ground diamond/ellipse around foot pivot (16, 44), strictly y >= 41
    ring_pts = [
        # Outer isometric diamond rim around feet (x=3..28, y=42..46)
        (4, 44), (5, 43), (6, 43), (7, 42), (8, 42),
        (27, 44), (26, 43), (25, 43), (24, 42), (23, 42),
        (5, 45), (6, 45), (7, 46), (8, 46), (9, 46), (10, 46),
        (11, 47), (12, 47), (13, 47), (14, 47), (15, 47), (16, 47), (17, 47), (18, 47), (19, 47), (20, 47),
        (26, 45), (25, 45), (24, 46), (23, 46), (22, 46), (21, 46),
    ]
    gold_pts = [(4, 44), (27, 44), (15, 47), (16, 47)]
    for (x, y) in ring_pts:
        if (x, y) in gold_pts:
            gold_l.put(x, y, 26)
        else:
            violet_l.put(x, y, 30)
    mask = violet_l.mask() | gold_l.mask()
    outline_mask(mask, 0, out_l, w, h)
    return [out_l, violet_l, gold_l]


# ============================================================================
# 3. SILENT MIRA BROADCAST PORTRAIT (32x48, ART_BIBLE.md §C.4 & §C.5)
#    Single static, silent broadcast image on its own 32x48 source composition.
#    Palette: 13/15 desaturated hair, small 30 lavender accent, 3x3 flower in 30/31 + 25 centre,
#             20/21 skin, 11/12 garment shadow, 14/15 lapel.
# ============================================================================

MIRA_LAYER_NAMES = ['Screen_Recess', 'Silhouette_Outline', 'Jacket_And_Shoulders', 'Face_And_Hair', 'Temple_Flower']


def build_mira_broadcast_portrait():
    """32x48 silent broadcast portrait framing Mira's face, temple flower, hair contour, and shoulder/jacket line (ART_BIBLE.md §C.4)."""
    w, h = 32, 48
    recess = Layer(w, h, 'Screen_Recess')
    outline = Layer(w, h, 'Silhouette_Outline')
    jacket = Layer(w, h, 'Jacket_And_Shoulders')
    face_hair = Layer(w, h, 'Face_And_Hair')
    flower = Layer(w, h, 'Temple_Flower')

    # Screen_Recess: dark broadcast monitor frame & subtle scanline backdrop (32x48)
    recess.rect(0, 0, 31, 47, 0)
    recess.rect(1, 1, 30, 46, 11)
    recess.rect(2, 2, 29, 45, 1)
    for y in range(3, 45, 2):
        recess.hline(3, 28, y, 2)
    recess.hline(1, 30, 1, 13)
    recess.vline(1, 1, 46, 13)

    # 1) Open shoulders & fitted jacket lapels (y=26..44, x=5..26)
    shoulder_spans = [
        (26, 11, 20),
        (27, 9, 22),
        (28, 7, 24),
        (29, 6, 25),
        (30, 6, 25),
        (31, 5, 26),
        (32, 5, 26),
        (33, 5, 26),
        (34, 5, 26),
        (35, 5, 26),
        (36, 5, 26),
        (37, 6, 25),
        (38, 6, 25),
        (39, 6, 25),
        (40, 7, 24),
        (41, 7, 24),
        (42, 7, 24),
        (43, 8, 23),
        (44, 8, 23),
    ]
    for y, x0, x1 in shoulder_spans:
        for x in range(x0, x1 + 1):
            # Open collar/neck skin V-notch at y=26..30, x=14..17
            if y <= 28 and 14 <= x <= 17:
                jacket.put(x, y, 21 if x <= 15 else 20)
            elif y <= 30 and 15 <= x <= 16:
                jacket.put(x, y, 20)
            # Open-shoulder subtle collarbone highlight at y=27..28
            elif y in (27, 28) and (10 <= x <= 12 or 19 <= x <= 21):
                jacket.put(x, y, 20)
            # Light fitted jacket lapels (14/15) framing the centre bodice
            elif 11 <= x <= 13 and 29 <= y <= 41:
                jacket.put(x, y, 15 if x <= 12 else 14)
            elif 18 <= x <= 20 and 29 <= y <= 41:
                jacket.put(x, y, 14)
            # Dark inner bodice & waist seam (11/12)
            elif 14 <= x <= 17 and y >= 31:
                jacket.put(x, y, 14 if y == 39 else 11)
            # Outer sleeve/shoulder shading (top-left light 13/14, right shadow 11/12)
            elif x <= x0 + 2 and y <= 36:
                jacket.put(x, y, 14 if x == x0 else 13)
            elif x >= x1 - 2 or y >= 41:
                jacket.put(x, y, 11)
            else:
                jacket.put(x, y, 12)

    # 2) Head, calm face (20/21 skin) & shoulder-length desaturated lavender hair (13/14/15 + small 30 accent)
    hair_spans = [
        (6, 12, 19),
        (7, 10, 21),
        (8, 9, 22),
        (9, 8, 23),
        (10, 8, 23),
        (11, 7, 23),
        (12, 7, 24),
        (13, 7, 24),
        (14, 7, 24),
        (15, 7, 24),
        (16, 8, 23),
        (17, 8, 23),
        (18, 8, 23),
        (19, 8, 23),
        (20, 8, 23),
        (21, 8, 23),
        (22, 8, 23),
        (23, 9, 22),
        (24, 9, 22),
        (25, 10, 21),
    ]
    for y, x0, x1 in hair_spans:
        for x in range(x0, x1 + 1):
            # Oval face interior at y=11..22, x=11..20
            in_face = (
                (11 <= y <= 19 and 11 <= x <= 20)
                or (y == 20 and 12 <= x <= 19)
                or (y == 21 and 13 <= x <= 18)
                or (y == 22 and 14 <= x <= 17)
            )
            # Forehead bangs dipping across y=11..13
            is_bang = (
                (y == 11 and x in (11, 12, 15, 16, 19, 20))
                or (y == 12 and x in (11, 15, 20))
                or (y == 13 and x in (11, 20))
            )
            if in_face and not is_bang:
                # Calm, warm eyes (dark umber 16, no stark white flood) at y=15..16
                if y == 14 and x in (12, 13, 18, 19):
                    face_hair.put(x, y, 13)   # soft eyebrows
                elif y in (15, 16) and x in (12, 13, 18, 19):
                    face_hair.put(x, y, 16 if (y == 15 or x in (13, 18)) else 20)
                # Subtle nose/mouth shadow at y=18, 20
                elif y == 18 and x == 16:
                    face_hair.put(x, y, 20)
                elif y == 20 and x in (15, 16):
                    face_hair.put(x, y, 20)
                else:
                    face_hair.put(x, y, 21 if (x <= 17 and y <= 19) else 20)
            else:
                # Desaturated lavender hair (13/14/15) + small 30 lavender accent on left locks
                if (x, y) in [(10, 9), (9, 10), (9, 14), (9, 15), (9, 18), (10, 19)]:
                    face_hair.put(x, y, 30)
                elif x <= 14 and y <= 14:
                    face_hair.put(x, y, 15)
                elif x >= 20 or y >= 21:
                    face_hair.put(x, y, 13)
                else:
                    face_hair.put(x, y, 14)

    # Neck at y=23..25, x=14..17
    for y in range(23, 26):
        for x in range(14, 18):
            face_hair.put(x, y, 21 if x <= 15 else 20)

    # 3) Temple_Flower: 3x3 stepped petal mark in 30/31 with a 25 gold centre at left temple (x=7..9, y=11..13)
    flower.put(8, 11, 31)
    flower.put(7, 12, 31)
    flower.put(8, 12, 25)   # gold centre
    flower.put(9, 12, 30)
    flower.put(8, 13, 30)

    fig_mask = jacket.mask() | face_hair.mask() | flower.mask()
    outline_mask(fig_mask, 0, outline, w, h)
    return [recess, outline, jacket, face_hair, flower]


def build_mira_look_study():
    """32x48 full-figure Mira look study (not an in-world Ch1 sprite) matching ART_BIBLE.md §C.4 & §C.5 silhouette."""
    w, h = 32, 48
    outline = Layer(w, h, 'Silhouette_Outline')
    jacket = Layer(w, h, 'Jacket_And_Skirt')
    face_hair = Layer(w, h, 'Face_And_Hair')
    flower = Layer(w, h, 'Temple_Flower')

    body_spans = [
        (17, 10, 21), (18, 10, 21), (19, 10, 21), (20, 10, 21), (21, 10, 21), (22, 10, 21),
        (23, 13, 18), (24, 13, 18), (25, 13, 18), (26, 13, 18), (27, 13, 18),
        (28, 12, 19), (29, 12, 19), (30, 12, 19),
        (31, 11, 20), (32, 11, 20), (33, 11, 20),
        (34, 10, 21), (35, 10, 21),
        (36, 9, 22), (37, 9, 22),
    ]
    for y, x0, x1 in body_spans:
        for x in range(x0, x1 + 1):
            if 17 <= y <= 22:
                if y <= 19 and x in (15, 16):
                    jacket.put(x, y, 20)
                elif x in (13, 14, 17, 18) and y <= 21:
                    jacket.put(x, y, 15 if x <= 14 else 14)
                else:
                    jacket.put(x, y, 12 if x < 16 else 11)
            elif 23 <= y <= 27:
                jacket.put(x, y, 14 if (y == 25 and x in (15, 16)) else (12 if x <= 15 else 11))
            else:
                if x <= x0 + 1:
                    jacket.put(x, y, 15 if y < 35 else 14)
                elif x in (14, 17):
                    jacket.put(x, y, 14)
                elif x >= x1 - 1:
                    jacket.put(x, y, 11)
                else:
                    jacket.put(x, y, 12 if (x + y) % 2 == 0 else 13)
    for y in range(38, 44):
        for x in (12, 13, 14):
            jacket.put(x, y, 20 if y < 42 else 12)
        for x in (17, 18, 19):
            jacket.put(x, y, 20 if y < 42 else 11)
    for x in range(11, 16):
        jacket.put(x, 44, 11)
    for x in range(17, 22):
        jacket.put(x, 44, 11)

    hair_spans = [
        (6, 12, 19), (7, 12, 19), (8, 11, 20), (9, 11, 20),
        (10, 8, 21), (11, 7, 21), (12, 8, 21),
        (13, 10, 21), (14, 10, 21), (15, 10, 21), (16, 10, 21),
    ]
    for y, x0, x1 in hair_spans:
        for x in range(x0, x1 + 1):
            if 9 <= y <= 15 and 13 <= x <= 18:
                if y == 9 and x in (13, 18):
                    face_hair.put(x, y, 14)
                elif y == 12 and x in (14, 17):
                    face_hair.put(x, y, 16)
                else:
                    face_hair.put(x, y, 21 if (x <= 16 and y <= 13) else 20)
            else:
                if (x, y) in [(11, 8), (11, 9), (10, 13), (11, 14), (11, 15)]:
                    face_hair.put(x, y, 30)
                elif x <= 14 and y <= 11:
                    face_hair.put(x, y, 15)
                elif x >= 19 or y >= 14:
                    face_hair.put(x, y, 13)
                else:
                    face_hair.put(x, y, 14)
    face_hair.put(15, 16, 21)
    face_hair.put(16, 16, 20)

    flower.put(9, 10, 31)
    flower.put(8, 11, 31)
    flower.put(9, 11, 25)
    flower.put(10, 11, 30)
    flower.put(9, 12, 30)

    fig_mask = jacket.mask() | face_hair.mask() | flower.mask()
    outline_mask(fig_mask, 0, outline, w, h)
    return [outline, jacket, face_hair, flower]


def mira_figure_mask():
    """Return the 32x48 foreground mask of Mira's C.5 full-figure look study."""
    return composite(build_mira_look_study()).mask()


# ============================================================================
# 4. BEAT 10 FROZEN CITY PLATE (1280x360, ART_BIBLE.md §C.4, TLF-059 / TLF-062)
#    Layers in ch01_env_beat10_city_plate_idle.pxo:
#      1. Sky_And_Distant_Towers
#      2. Plaza_And_Station_Exit
#      3. Clocks_2359
#      4. Mira_Broadcast_Screen
#      5. Suspended_Rain
# ============================================================================

CITY_PLATE_W, CITY_PLATE_H = 1280, 360
CITY_PLATE_LAYERS = [
    'Sky_And_Distant_Towers',
    'Plaza_And_Station_Exit',
    'Clocks_2359',
    'Mira_Broadcast_Screen',
    'Suspended_Rain',
]
MIRA_SCREEN_POSITIONS = [(440, 136), (844, 104)]


def _draw_clock_2359(layer, x0, y0, scale=1):
    """Draw a recessed digital 23:59 clock housing with #C84B31 (24) / #E09F3E (25) digits."""
    bw = 34 * scale
    bh = 11 * scale
    layer.rect(x0 - 2 * scale, y0 - 2 * scale, x0 + bw + 2 * scale - 1, y0 + bh + 2 * scale - 1, 0)
    layer.rect(x0 - 1 * scale, y0 - 1 * scale, x0 + bw + 1 * scale - 1, y0 + bh + 1 * scale - 1, 13)
    layer.hline(x0 - 1 * scale, x0 + bw + 1 * scale - 1, y0 - 1 * scale, 15)
    layer.rect(x0, y0, x0 + bw - 1, y0 + bh - 1, 0)
    draw_text_layer(layer, x0 + 2 * scale, y0 + 2 * scale, "23:59", 24, scale=scale)
    # Top-left warm amber highlight pixels on digits
    draw_text_layer(layer, x0 + 2 * scale, y0 + 2 * scale, "23:59", 25, scale=scale)
    # Restore lower rows of digits to 24 so top catches 25 and base is 24
    for y in range(y0 + 5 * scale, y0 + bh):
        for x in range(x0, x0 + bw):
            if layer.get(x, y) == 25:
                layer.put(x, y, 24)


def _draw_iso_prism(layer, xN, yN, w_sw, w_se, height,
                    col_top=13, col_top_bevel=15, col_top_inner=12,
                    col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
                    draw_shadow=True):
    """Draw a coherent 2:1 isometric 3D rectangular prism grounded on the 2:1 plaza plane.
    - Back-North ground corner: (xN, yN)
    - West ground corner:       (xW, yW) = (xN - w_sw, yN + w_sw // 2)  [2:1 down-left axis, abs(dy/dx) = 1/2]
    - East ground corner:       (xE, yE) = (xN + w_se, yN + w_se // 2)  [2:1 down-right axis, abs(dy/dx) = 1/2]
    - Front-South ground corner:(xS, yS) = (xN - w_sw + w_se, yN + (w_sw + w_se) // 2)
    Follows ART_BIBLE.md top-left planar value hierarchy:
      Top roof plane (col_top / col_top_bevel) > SW left-facing wall (col_sw) > SE right-facing wall (col_se) > 00 outline & shadow.
    """
    xW, yW = xN - w_sw, yN + w_sw // 2
    xE, yE = xN + w_se, yN + w_se // 2
    xS, yS = xW + w_se, yW + w_se // 2

    # 1. Compact down-right 2:1 cast shadow along SE base edge (xS..xE)
    if draw_shadow:
        for x in range(xS, xE + 8):
            yb = yS - (x - xS) // 2 if x <= xE else yE + (x - xE) // 2
            for dy in range(1, 6):
                layer.put(x, yb + dy, 0 if dy <= 2 else 1)

    # 2. Left-facing (SW) 2:1 wall plane: x in [xW .. xS], base y_bot(x) = yW + (x - xW) // 2
    for x in range(xW, xS + 1):
        yb = yW + (x - xW) // 2
        yt = yb - height
        for y in range(yt, yb + 1):
            if y == yt:
                c = col_sw_bevel
            elif y == yb or x == xW:
                c = 0 if y == yb else col_sw_bevel
            elif (y - yt) % 12 == 0:
                c = col_se  # 2:1-sheared horizontal masonry/panel seam
            else:
                c = col_sw
            layer.put(x, y, c)

    # 3. Right-facing (SE) 2:1 wall plane: x in [xS .. xE], base y_bot(x) = yS - (x - xS) // 2
    for x in range(xS, xE + 1):
        yb = yS - (x - xS) // 2
        yt = yb - height
        for y in range(yt, yb + 1):
            if x == xS:
                c = col_sw_bevel if y < yb else 0  # front corner ridge highlight
            elif x == xS + 1:
                c = 0  # crisp vertical corner turn into shadow
            elif x == xE or y == yb:
                c = 0
            elif y == yt:
                c = col_sw
            elif (y - yt) % 12 == 0:
                c = col_se_dark  # 2:1-sheared horizontal course in shadow
            else:
                c = col_se
            layer.put(x, y, c)

    # 4. Visible Top Roof Cap (2:1 isometric diamond/parallelogram bounded by xW..xN..xE..xS at y - height)
    for x in range(xW, xE + 1):
        # Upper roof boundary (North-West edge xW..xN or North-East edge xN..xE)
        if x <= xN:
            y_roof_top = (yN - height) + (xN - x) // 2
        else:
            y_roof_top = (yN - height) + (x - xN) // 2
        # Lower roof boundary (South-West edge xW..xS or South-East edge xS..xE)
        if x <= xS:
            y_roof_bot = (yW - height) + (x - xW) // 2
        else:
            y_roof_bot = (yS - height) - (x - xS) // 2

        for y in range(y_roof_top, y_roof_bot + 1):
            if y == y_roof_top:
                c = 0
            elif y == y_roof_top + 1:
                c = col_top_bevel if x <= xN + (w_se // 2) else col_top
            elif y == y_roof_bot:
                c = col_sw_bevel if x <= xS else col_sw
            elif y_roof_top + 3 <= y <= y_roof_bot - 3 and xW + 6 <= x <= xE - 6:
                c = col_top_inner
            else:
                c = col_top
            layer.put(x, y, c)

    return (xW, yW, xS, yS, xE, yE)


def _build_city_layers():
    w, h = CITY_PLATE_W, CITY_PLATE_H
    sky = Layer(w, h, 'Sky_And_Distant_Towers')
    plaza = Layer(w, h, 'Plaza_And_Station_Exit')
    clocks = Layer(w, h, 'Clocks_2359')
    mira_scr = Layer(w, h, 'Mira_Broadcast_Screen')
    rain = Layer(w, h, 'Suspended_Rain')

    # --- Layer 1: Sky_And_Distant_Towers ---
    # Banded nocturnal sky (indices 00, 01, 02, 03) above the plaza horizon (y=196)
    sky.rect(0, 0, w - 1, 64, 0)
    sky.rect(0, 65, w - 1, 134, 1)
    sky.rect(0, 135, w - 1, 196, 2)
    sky.rect(0, 197, w - 1, h - 1, 1)

    # Distant Elysium City skyline towers rendered as 2:1 isometric prisms (visible 2:1 roof cap + lit SW face + dark SE face)
    distant_prisms = [
        # (xN, yN_base, w_sw, w_se, height, sw_col, se_col)
        (86,  204, 48, 36, 168, 12, 11),
        (198, 206, 44, 34, 152, 11, 2),
        (308, 204, 56, 42, 178, 12, 11),
        (398, 206, 36, 28, 144, 2,  1),
        (524, 204, 48, 36, 166, 12, 11),
        (632, 204, 60, 44, 182, 11, 2),
        (736, 206, 44, 32, 156, 12, 11),
        (996, 204, 56, 42, 174, 12, 11),
        (1098, 206, 44, 34, 148, 11, 2),
        (1204, 204, 56, 40, 180, 12, 11),
    ]
    for (txN, tyN, tw_sw, tw_se, th, c_sw, c_se) in distant_prisms:
        xW, yW, xS, yS, xE, yE = _draw_iso_prism(
            sky, txN, tyN, tw_sw, tw_se, th,
            col_top=13 if c_sw == 12 else 2,
            col_top_bevel=14 if c_sw == 12 else 3,
            col_top_inner=12 if c_sw == 12 else 1,
            col_sw=c_sw,
            col_sw_bevel=13 if c_sw == 12 else 2,
            col_se=c_se,
            col_se_dark=1 if c_se == 2 else 2,
            draw_shadow=False,
        )
        # Sparse 2:1-sheared window slits on the lit SW face (dy = +(x - xW) // 2)
        for dx in range(8, tw_sw - 8, 10):
            wx = xW + dx
            wy_base = (yW - th) + dx // 2
            for dz in range(14, th - 18, 14):
                hval = (wx * 31 + dz * 17) % 19
                wcol = 25 if hval == 0 else (8 if hval in (1, 2, 3) else 1)
                for sx in range(3):
                    for sy in range(4):
                        sky.put(wx + sx, wy_base + dz + sx // 2 + sy, wcol)

    # Elevated transit viaduct deck & 2:1 isometric support piers across the upper plaza edge (y=162..204)
    # Top deck plane (y=164..169, 13/14) + vertical girder face (y=170..178, 11/12)
    sky.rect(0, 164, w - 1, 169, 13)
    sky.hline(0, w - 1, 164, 14)
    sky.hline(0, w - 1, 169, 15)
    sky.rect(0, 170, w - 1, 178, 11)
    sky.hline(0, w - 1, 178, 0)
    for px in range(72, w, 144):
        _draw_iso_prism(
            sky, px, 198, 16, 12, 22,
            col_top=13, col_top_bevel=14, col_top_inner=12,
            col_sw=12, col_sw_bevel=13, col_se=11, col_se_dark=2,
            draw_shadow=False,
        )

    # Stalled transit train frozen on the viaduct deck (x=584..748, y=146..165) with visible top roof plane (14/15) & side (12/13)
    sky.rect(588, 146, 744, 150, 14)   # visible top roof cap of train
    sky.hline(588, 744, 146, 15)
    sky.rect(584, 151, 748, 165, 12)   # NW-lit side elevation
    sky.hline(584, 748, 151, 14)
    sky.hline(584, 748, 161, 24)       # transit orange stripe
    for wx in range(596, 736, 18):
        sky.rect(wx, 154, wx + 10, 158, 8)
    sky.rect(584, 155, 587, 159, 24)   # frozen tail lamp

    # --- Layer 2: Plaza_And_Station_Exit ---
    # Coherent 2:1 isometric plaza ground (y=196..359) using BOTH 2:1 ground axes:
    #   Axis A (down-left 2:1, abs(dy/dx) = 1/2):  a = x + 2 * (y - 196)
    #   Axis B (down-right 2:1, abs(dy/dx) = 1/2): b = 2 * (y - 196) - x + 1280
    # Zero horizontal floor cross-lines and zero 45-degree lines!
    for y in range(196, h):
        dy_p = y - 196
        for x in range(w):
            a = x + 2 * dy_p
            b = 2 * dy_p - x + 1280
            u_tile = a // 32
            v_tile = b // 32
            a_mod = a % 32
            b_mod = b % 32

            # 2:1 diamond mortar joints along BOTH 2:1 ground axes (abs(dy/dx) = 1/2)
            if a_mod in (0, 1) or b_mod in (0, 1):
                col = 0
            elif a_mod == 2 or b_mod == 2:
                # Top-left NW bevel edge of each 32x16 2:1 diamond tile
                col = 2 if (u_tile + v_tile) % 2 == 0 else 11
            else:
                # Checkerboard & courtyard 2:1 diamond paving in dark wet terrazzo (01 / 02 / 07)
                if (u_tile + v_tile) % 2 == 0:
                    col = 1
                else:
                    col = 2 if (u_tile % 4 != 0) else 7
                # Wet specular glint inside diamond center
                if a_mod in (14, 15, 16) and b_mod in (15, 16) and (u_tile * 7 + v_tile * 13) % 5 == 0:
                    col = 3
            plaza.put(x, y, col)

    # Raised 2:1 isometric retaining curb along the back edge of the plaza (y=194..201)
    plaza.hline(0, w - 1, 194, 14)
    plaza.hline(0, w - 1, 195, 13)
    plaza.hline(0, w - 1, 196, 0)

    # ========================================================================
    # START PAN VIEWPORT (x = 0..640):
    #   1) Station Elysium-09 Subterranean Exit Headhouse (2:1 isometric 3D volume)
    #   2) 2:1 Tactile Amber Platform Threshold & Forecourt Apron
    #   3) Mid-Plaza 2:1 Isometric Repeater Pylon (Mira screen @ (440, 136)) & Intercom Post
    # ========================================================================

    # 1a. Stepped 2:1 Isometric Forecourt Plinth under Station Exit + Tactile Amber 2:1 Band
    #     xN=168, yN=196, w_sw=144 (to xW=24, yW=268), w_se=192 (to xE=360, yE=292), height=8
    _draw_iso_prism(
        plaza, 168, 196, 144, 192, 8,
        col_top=11, col_top_bevel=14, col_top_inner=2,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=1,
        draw_shadow=True,
    )
    # 2:1 Tactile Amber Warning Strip along the SE exit apron edge (x=216..352, following 2:1 axis dy = -(x - 216)//2)
    for x in range(220, 352):
        yb = 352 - (x - 216) // 2
        for dz in range(2, 9):
            y = yb - dz
            if 0 <= y < h:
                blister = ((x + 2 * y) % 8 in (2, 3, 4)) and ((2 * y - x) % 8 in (2, 3, 4))
                plaza.put(x, y, 26 if (blister and dz <= 4) else (25 if blister else 22))

    # 1b. Main Station Elysium-09 Exit Headhouse — 2:1 Isometric 3D Building Block
    #     xN=156, yN=158, w_sw=120 (xW=36, yW=218), w_se=168 (xE=324, yE=242), xS=204, yS=302, height=118
    _draw_iso_prism(
        plaza, 156, 158, 120, 168, 118,
        col_top=13, col_top_bevel=15, col_top_inner=11,
        col_sw=8, col_sw_bevel=14, col_se=7, col_se_dark=2,
        draw_shadow=True,
    )
    # Rooftop 2:1 Isometric Ventilation / Elevator Penthouse on top of the Station Exit roof deck
    _draw_iso_prism(
        plaza, 152, 62, 52, 64, 22,
        col_top=14, col_top_bevel=15, col_top_inner=12,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=False,
    )
    # Sheared 2:1 amber transit line stripe across the lit SW wall (x=38..202) and shadowed SE wall (x=205..322)
    for x in range(38, 203):
        yb = 218 + (x - 36) // 2
        y_stripe = yb - 84
        plaza.put(x, y_stripe, 25)
        plaza.put(x, y_stripe + 1, 24)
        plaza.put(x, y_stripe + 2, 0)
    for x in range(205, 323):
        yb = 302 - (x - 204) // 2
        y_stripe = yb - 84
        plaza.put(x, y_stripe, 24)
        plaza.put(x, y_stripe + 1, 22)
        plaza.put(x, y_stripe + 2, 0)

    # Recessed 2:1 Isometric Portal Opening on the SE face of the Station Exit (x=218..308) with descending 2:1 stairs
    for x in range(218, 309):
        yb = 302 - (x - 204) // 2
        yt = yb - 72
        for y in range(yt, yb):
            if x in (218, 219) or y in (yt, yt + 1):
                plaza.put(x, y, 14 if y == yt else 12)
            elif x >= 306:
                plaza.put(x, y, 7)
            else:
                # Inside portal: dark subterranean stairwell (00/01) with 2:1 stair treads near bottom
                rel_y = yb - y
                if rel_y <= 28:
                    step_idx = rel_y // 5
                    is_riser = (rel_y % 5) in (0, 1)
                    plaza.put(x, y, 12 if (not is_riser and step_idx % 2 == 0) else (8 if not is_riser else 1))
                elif rel_y >= 64:
                    plaza.put(x, y, 25 if rel_y == 66 else 22)  # warm interior canopy soffit strip
                else:
                    plaza.put(x, y, 0 if x < 260 else 1)

    # Cantilevered 2:1 Isometric Entry Canopy projecting out from the SE portal header (xN=264, yN=192)
    _draw_iso_prism(
        plaza, 264, 192, 48, 24, 8,
        col_top=14, col_top_bevel=15, col_top_inner=13,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=False,
    )

    # 2:1 Isometric Fascia Sign Housing on the Station Exit roof brow for the (148, 68) 23:59 Clock
    # xN=172, w_sw=32 -> xW=140; w_se=88 -> xS=228 (so clock x=148..216 sits wholly on the broad SW lit face!)
    _draw_iso_prism(
        plaza, 172, 102, 32, 88, 34,
        col_top=14, col_top_bevel=15, col_top_inner=13,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=False,
    )

    # 2. Mid-Plaza 2:1 Isometric Repeater Pylon (grounds Mira broadcast screen @ (440, 136) and clock @ (439, 116))
    #    xN=452, w_sw=24 -> xW=428; w_se=60 -> xS=488, xE=512 (so clock x=439..473 & Mira x=440..472 sit wholly on SW lit face!)
    _draw_iso_prism(
        plaza, 452, 232, 32, 68, 10,
        col_top=13, col_top_bevel=15, col_top_inner=12,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=True,
    )
    _draw_iso_prism(
        plaza, 452, 224, 24, 60, 132,
        col_top=14, col_top_bevel=15, col_top_inner=13,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=True,
    )
    # Recessed screen bezel for the 32x48 Mira portrait at (440, 136)
    plaza.rect(438, 134, 473, 185, 0)
    plaza.hline(438, 473, 134, 14)
    plaza.vline(438, 134, 185, 14)

    # 3. Street Intercom / Speaker Post at x=528..568 (2:1 isometric plinth + 2:1 speaker housing box)
    #    Beat 10: a street speaker clicks on ("You are late. ... Again.")
    _draw_iso_prism(
        plaza, 546, 248, 14, 20, 8,
        col_top=13, col_top_bevel=15, col_top_inner=12,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=True,
    )
    _draw_iso_prism(
        plaza, 546, 242, 8, 10, 36,
        col_top=13, col_top_bevel=14, col_top_inner=12,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=False,
    )
    _draw_iso_prism(
        plaza, 544, 212, 12, 22, 26,
        col_top=14, col_top_bevel=15, col_top_inner=13,
        col_sw=12, col_sw_bevel=15, col_se=11, col_se_dark=2,
        draw_shadow=False,
    )
    # Speaker louvres & active amber call LED (25/26) on the SW lit face of the speaker head (x=532..554)
    for gy in range(196, 205, 2):
        plaza.hline(535, 549, gy, 0)
        plaza.hline(536, 548, gy + 1, 14)
    plaza.rect(540, 207, 544, 210, 25)
    plaza.put(541, 208, 26)
    # Warm 2:1 diamond amber reflection on the wet plaza floor below the speaker
    for dx in range(-8, 9, 2):
        plaza.hline(542 + dx // 2, 548 + dx // 2, 264 + abs(dx) // 4, 24 if abs(dx) <= 4 else 22)

    # ========================================================================
    # END PAN VIEWPORT (x = 640..1280):
    #   1) Grand Plaza Broadcast & Clock Tower (stepped 2:1 isometric 3D tower prism)
    #      housing the master 23:59 clock @ (826, 52) and Mira screen @ (844, 104)
    #   2) 2:1 Isometric Transit Ventilation Kiosk & Concourse Bench/Planter Volumes
    # ========================================================================

    # 1a. Stepped 2:1 Isometric Plaza Dais under the Grand Broadcast Tower
    _draw_iso_prism(
        plaza, 852, 210, 68, 124, 10,
        col_top=13, col_top_bevel=15, col_top_inner=11,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=True,
    )
    _draw_iso_prism(
        plaza, 852, 204, 56, 110, 12,
        col_top=14, col_top_bevel=15, col_top_inner=12,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=False,
    )
    # 1b. Main Grand Plaza Broadcast & Clock Tower — 2:1 Isometric 3D Monumental Prism
    #     xN=852, yN=196, w_sw=44 (xW=808, yW=218), w_se=96 (xS=904, yS=266, xE=948, yE=244), height=192
    #     Clock (x=826..894) and Mira screen (x=844..876) sit wholly on the 96px-wide SW lit face (x=808..904)!
    _draw_iso_prism(
        plaza, 852, 196, 44, 96, 192,
        col_top=14, col_top_bevel=15, col_top_inner=12,
        col_sw=12, col_sw_bevel=15, col_se=11, col_se_dark=2,
        draw_shadow=True,
    )
    # Upper 2:1 Isometric Crown Penthouse on top of the Broadcast Tower roof cap
    _draw_iso_prism(
        plaza, 852, 24, 28, 64, 18,
        col_top=14, col_top_bevel=15, col_top_inner=13,
        col_sw=13, col_sw_bevel=15, col_se=11, col_se_dark=2,
        draw_shadow=False,
    )
    # Sheared 2:1 recessed service louvres on the shadowed SE face of the Broadcast Tower (x=908..942)
    for dx in (8, 22):
        bx = 904 + dx
        by_bot = 266 - dx // 2
        for dz in (40, 88, 136):
            for sx in range(8):
                for sy in range(18):
                    plaza.put(bx + sx, by_bot - dz - sx // 2 - sy, 2 if sy not in (0, 17) else 0)

    # Architectural bezel around the central 32x48 Mira broadcast screen at (844, 104)
    plaza.rect(838, 98, 881, 157, 0)
    plaza.rect(840, 100, 879, 155, 13)
    plaza.hline(840, 879, 100, 15)
    plaza.rect(842, 102, 877, 153, 0)

    # Wet 2:1 diamond cyan/slate screen reflection on the plaza floor in front of the Broadcast Tower
    for dy_r in range(0, 36, 4):
        y_r = 274 + dy_r
        half_w = 24 - dy_r // 2
        plaza.hline(856 - half_w, 856 + half_w, y_r, 8 if (dy_r // 4) % 2 == 0 else 3)

    # 2. East Plaza 2:1 Isometric Transit Ventilation Kiosk & Planter Plinths (x=1036..1236)
    #    Coherent 2:1 3D volumes anchoring the right half of the End Pan Viewport (640..1280)
    _draw_iso_prism(
        plaza, 1076, 232, 44, 36, 34,
        col_top=13, col_top_bevel=15, col_top_inner=11,
        col_sw=8, col_sw_bevel=14, col_se=7, col_se_dark=2,
        draw_shadow=True,
    )
    # Sheared 2:1 amber transit band around the East Ventilation Kiosk
    for x in range(1032, 1077):
        yb = 254 + (x - 1032) // 2
        plaza.put(x, yb - 12, 24)
        plaza.put(x, yb - 11, 22)
    for x in range(1077, 1112):
        yb = 272 - (x - 1076) // 2
        plaza.put(x, yb - 12, 22)

    # Foreground 2:1 Isometric Concourse Bench / Bollard Plinth at x=692..756
    _draw_iso_prism(
        plaza, 720, 262, 28, 20, 14,
        col_top=14, col_top_bevel=15, col_top_inner=13,
        col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
        draw_shadow=True,
    )

    # 2:1 Isometric Street Lamp Pylons casting 2:1 diamond warm amber pools (22..26) onto the plaza tiles
    for (lx, ly_base) in ((384, 248), (648, 244), (984, 246), (1184, 252)):
        # 2:1 diamond lamp base plinth
        _draw_iso_prism(
            plaza, lx, ly_base, 8, 8, 8,
            col_top=13, col_top_bevel=14, col_top_inner=12,
            col_sw=12, col_sw_bevel=14, col_se=11, col_se_dark=2,
            draw_shadow=False,
        )
        plaza.vline(lx - 1, ly_base - 92, ly_base - 4, 13)
        plaza.vline(lx, ly_base - 92, ly_base - 4, 11)
        plaza.vline(lx + 1, ly_base - 92, ly_base - 4, 0)
        # 2:1 isometric lamp hood
        _draw_iso_prism(
            plaza, lx, ly_base - 92, 10, 10, 6,
            col_top=14, col_top_bevel=15, col_top_inner=13,
            col_sw=25, col_sw_bevel=26, col_se=24, col_se_dark=22,
            draw_shadow=False,
        )
        # 2:1 diamond warm amber floor pool around (lx, ly_base + 12)
        for dy_p in range(-8, 9):
            span = (8 - abs(dy_p)) * 2
            y_pool = ly_base + 12 + dy_p
            if 0 <= y_pool < h:
                for dx_p in range(-span, span + 1):
                    x_pool = lx + dx_p
                    if 0 <= x_pool < w:
                        dist = abs(dx_p) + 2 * abs(dy_p)
                        pcol = 25 if dist <= 4 else (24 if dist <= 9 else 22)
                        plaza.put(x_pool, y_pool, pcol)

    # --- Layer 3: Clocks_2359 ---
    # 1) Station exit headhouse clock (visible in initial 0..640 pan frame)
    _draw_clock_2359(clocks, 148, 68, scale=2)
    # 2) Mid-plaza pylon clock (visible across middle pan)
    _draw_clock_2359(clocks, 439, 116, scale=1)
    # 3) Grand Plaza Broadcast Tower master clock (visible in ending 640..1280 pan frame)
    _draw_clock_2359(clocks, 826, 52, scale=2)

    # --- Layer 4: Mira_Broadcast_Screen ---
    # Blit the exact 32x48 silent Mira broadcast portrait at both plaza screen housings
    mira_portrait = composite(build_mira_broadcast_portrait())
    for (mx, my) in MIRA_SCREEN_POSITIONS:
        mira_scr.blit(mira_portrait, mx, my)

    # --- Layer 5: Suspended_Rain ---
    # Deterministic field of motionless raindrops suspended in mid-air across the entire 1280x360 canvas
    for idx in range(420):
        rx = (idx * 73 + (idx // 7) * 29 + 11) % (w - 4) + 2
        ry = (idx * 53 + (idx // 5) * 19 + 7) % (h - 16) + 6
        # Keep rain droplets from obscuring the 23:59 clock digits or Mira's face/flower centre
        if (144 <= rx <= 220 and 64 <= ry <= 94) or (820 <= rx <= 900 and 48 <= ry <= 156):
            continue
        if (436 <= rx <= 476 and 112 <= ry <= 186):
            continue
        length = 2 if idx % 3 != 0 else 3
        col_top = 9 if idx % 4 == 0 else 8
        col_bot = 15 if idx % 5 == 0 else 10
        for dy in range(length - 1):
            rain.put(rx, ry + dy, col_top)
        rain.put(rx, ry + length - 1, col_bot)
        # Every 6th drop above the plaza floor has a frozen mid-air 2:1 splash ring
        if ry >= 242 and idx % 6 == 0 and rx + 2 < w - 1:
            rain.put(rx - 2, ry + 4, 8)
            rain.put(rx - 1, ry + 5, 9)
            rain.put(rx + 1, ry + 5, 9)
            rain.put(rx + 2, ry + 4, 8)

    return [sky, plaza, clocks, mira_scr, rain]


# ============================================================================
# 5. ASSET REGISTRY FOR TLF-062 (6 .pxo + .png assets)
# ============================================================================

def assets():
    """Return list of (stem, cat, w, h, layer_names, frames, fps, tags, durations, meta)."""
    op_frames = build_operator_sighting_frames()
    fx_layers = build_operator_trace_ring()
    mira_layers = build_mira_broadcast_portrait()
    sky, plaza, clocks, mira_scr, rain = _build_city_layers()

    return [
        (
            'ch01_char_operator_sighting_ne_sheet',
            'characters',
            32, 48,
            OPERATOR_LAYER_NAMES,
            op_frames,
            8.0,
            operator_tags(),
            OPERATOR_DURATIONS,
            {'pivot': '(16, 44)', 'z': 'YSort_Actors (z_index = 10)'},
        ),
        (
            'ch01_fx_operator_sighting_trace_ring_idle',
            'props',
            32, 48,
            ['Ring_Outline', 'Trace_Violet', 'Trace_Gold_Ticks'],
            [fx_layers],
            1.0,
            [],
            None,
            {'pivot': '(16, 44)', 'z': 'YSort_Props (z_index = 8)'},
        ),
        (
            'ch01_ui_mira_broadcast_portrait_idle',
            'ui',
            32, 48,
            MIRA_LAYER_NAMES,
            [mira_layers],
            1.0,
            [],
            None,
            {'pivot': '(0, 0)', 'z': 'CanvasLayer (z_index = 21)'},
        ),
        (
            'ch01_env_beat10_city_plate_idle',
            'environments',
            CITY_PLATE_W, CITY_PLATE_H,
            CITY_PLATE_LAYERS,
            [[sky, plaza, clocks, mira_scr, rain]],
            1.0,
            [],
            None,
            {'pivot': '(0, 0)', 'z': 'CanvasLayer (z_index = 20)'},
        ),
        (
            'ch01_env_beat10_city_backdrop_idle',
            'environments',
            CITY_PLATE_W, CITY_PLATE_H,
            ['Sky_And_Distant_Towers', 'Plaza_And_Station_Exit', 'Clocks_2359'],
            [[sky.copy(), plaza.copy(), clocks.copy()]],
            1.0,
            [],
            None,
            {'pivot': '(0, 0)', 'z': 'CanvasLayer (z_index = 20)'},
        ),
        (
            'ch01_env_beat10_suspended_rain_idle',
            'environments',
            CITY_PLATE_W, CITY_PLATE_H,
            ['Suspended_Rain'],
            [[rain.copy()]],
            1.0,
            [],
            None,
            {'pivot': '(0, 0)', 'z': 'CanvasLayer (z_index = 22)'},
        ),
    ]


# ============================================================================
# 6. MOCKUPS & GREYSCALE PROOFS (built strictly from delivered runtime PNGs)
# ============================================================================

MOCKUP_FILES = [
    'ch01_operator_sighting_platform_mockup.png',
    'ch01_operator_cast_silhouette_greyscale_proof.png',
    'ch01_beat10_city_plate_greyscale_proof.png',
    'ch01_beat10_city_pan_start_640x360_mockup.png',
    'ch01_beat10_city_pan_end_640x360_mockup.png',
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


def build_operator_platform_mockup():
    """640x360 native Arrival Platform mockup showing the Operator sighting at the far NE end + 4-frame inset."""
    import placement_render as pl_mod

    r1 = pl_mod.build_rooms()[0]
    pcs = list(pl_mod.pieces(r1, anchor=pl_mod.px(6, 5)))
    im = Image.new('RGBA', (640, 360), PAL[0] + (255,))
    for z, y, p_im, o in sorted(pcs, key=lambda t: (t[0], t[1])):
        pl_mod.paste_clip(im, p_im, o)

    op_sheet = _png('characters', 'ch01_char_operator_sighting_ne_sheet')
    op_frames = [op_sheet.crop((i * 32, 0, (i + 1) * 32, 48)) for i in range(4)]
    fx_ring = _png('props', 'ch01_fx_operator_sighting_trace_ring_idle')

    # Place Operator at the far NE end of the Arrival Platform (tile (9, 2) -> px (432, 152), foot pivot (16, 44))
    op_px, op_py = pl_mod.px(9, 2)
    im.alpha_composite(fx_ring, (op_px - 16, op_py - 44))
    im.alpha_composite(op_frames[2], (op_px - 16, op_py - 44))  # F3 check-watch pose

    # Top-left inset panel (x=6..244, y=6..106) showing F1..F4 on dark floor (02) & wall (08), VFX on/off
    panel = Image.new('RGBA', (238, 100), PAL[0] + (255,))
    for x in range(238):
        panel.putpixel((x, 0), PAL[13] + (255,))
        panel.putpixel((x, 99), PAL[13] + (255,))
    for y in range(100):
        panel.putpixel((0, y), PAL[13] + (255,))
        panel.putpixel((237, y), PAL[13] + (255,))
    _draw_text_img(panel, 6, 5, "OPERATOR SIGHTING F1..F4 + REDUCED FX", PAL[15], scale=1)

    for i in range(4):
        bx = 8 + i * 38
        by = 18
        bg_col = PAL[2] if i % 2 == 0 else PAL[8]
        cell = Image.new('RGBA', (34, 52), bg_col + (255,))
        if i < 3:
            cell.alpha_composite(fx_ring, (1, 2))
        cell.alpha_composite(op_frames[i], (1, 2))
        panel.alpha_composite(cell, (bx, by))
        _draw_text_img(panel, bx + 4, 74, f"F{i+1}", PAL[26] if i == 2 else PAL[15], scale=1)

    # Static F3 reduced_effects cell (no VFX ring)
    cell_rfx = Image.new('RGBA', (56, 52), PAL[2] + (255,))
    cell_rfx.alpha_composite(op_frames[2], (12, 2))
    panel.alpha_composite(cell_rfx, (168, 18))
    _draw_text_img(panel, 168, 74, "F3 NO-FX", PAL[25], scale=1)
    _draw_text_img(panel, 6, 86, "CADENCE: 0.25 / 0.25 / 1.00 / 0.25S", PAL[14], scale=1)

    im.alpha_composite(panel, (6, 6))
    return im


def build_operator_cast_silhouette_proof():
    """1320x1160 colour + greyscale proof covering C.3 (4 frames, VFX on/off, watch & scarf layers) and C.5 (32x48 cast silhouette test)."""
    W, H = 1320, 1160
    canvas = Image.new('RGBA', (W, H), PAL[0] + (255,))

    op_sheet = _png('characters', 'ch01_char_operator_sighting_ne_sheet')
    op_frames = [op_sheet.crop((i * 32, 0, (i + 1) * 32, 48)) for i in range(4)]
    fx_ring = _png('props', 'ch01_fx_operator_sighting_trace_ring_idle')
    mira_png = _png('ui', 'ch01_ui_mira_broadcast_portrait_idle')
    elias_sheet = _png('characters', 'ch01_char_elias_base_sheet')
    elias_idle_s = elias_sheet.crop((0, 0, 32, 48))
    elias_idle_ne = elias_sheet.crop((30 * 32, 0, 31 * 32, 48))

    # Build a 1320x520 top half in colour, then duplicate in luminance greyscale below, plus 1x native strip at bottom
    half = Image.new('RGBA', (W, 500), PAL[1] + (255,))
    _draw_text_img(half, 16, 10, "C.3 OPERATOR SIGHTING (F1..F4 X3) : FLOOR 02 & WALL 08, VFX ON/OFF, SCARF LAYER", PAL[15], scale=2)

    # Band 1 left: F1..F4 on Floor 02 (with Trace ring) + F1..F4 on Wall 08 (without Trace ring) + F3 Scarf-Off (from .pxo layers)
    for i in range(4):
        # Floor 02 + VFX
        cell = Image.new('RGBA', (32, 48), PAL[2] + (255,))
        cell.alpha_composite(fx_ring, (0, 0))
        cell.alpha_composite(op_frames[i], (0, 0))
        half.alpha_composite(cell.resize((96, 144), Image.NEAREST), (16 + i * 106, 36))
        _draw_text_img(half, 20 + i * 106, 186, f"F{i+1}:FL02+FX", PAL[15], scale=1)

        # Wall 08 without VFX (reduced_effects static F3 highlighted)
        cell_w = Image.new('RGBA', (32, 48), PAL[8] + (255,))
        cell_w.alpha_composite(op_frames[i], (0, 0))
        half.alpha_composite(cell_w.resize((96, 144), Image.NEAREST), (450 + i * 106, 36))
        _draw_text_img(half, 454 + i * 106, 186, f"F{i+1}:WL08-NOFX", PAL[26] if i == 2 else PAL[14], scale=1)

    # Optional Scarf-on source-layer comparison & x8 Watch callout on the right of Band 1 (x=890..1300)
    # Shipped F1..F4 on the left are SCARF-HIDDEN per ADR-022 A3 / Sol cb2acbd; this cell shows optional Scarf layer toggled on:
    f3_layers = _build_operator_frame(2)  # [shadow, robe, hood, scarf(visible=False), hand_watch]
    scarf_on_layer = f3_layers[3].copy()
    scarf_on_layer.visible = True
    scarf_on_im = to_image(composite([f3_layers[0], f3_layers[1], f3_layers[2], scarf_on_layer, f3_layers[4]]))
    cell_so = Image.new('RGBA', (32, 48), PAL[2] + (255,))
    cell_so.alpha_composite(scarf_on_im, (0, 0))
    half.alpha_composite(cell_so.resize((96, 144), Image.NEAREST), (890, 36))
    _draw_text_img(half, 890, 186, "F3 SCARF-ON(OPT)", PAL[14], scale=1)

    # x8 zoom callout of shipped F3 upper torso + watch (scarf-hidden default export, crop x=14..30, y=10..26 -> 16x16 @ x8 = 128x128)
    f3_crop = op_frames[2].crop((14, 10, 30, 26))
    callout_bg = Image.new('RGBA', (128, 128), PAL[2] + (255,))
    callout_bg.alpha_composite(f3_crop.resize((128, 128), Image.NEAREST), (0, 0))
    half.alpha_composite(callout_bg, (1010, 44))
    _draw_text_img(half, 1010, 180, "SHIPPED F3 WATCH(25/26/00) NO-SCARF X8", PAL[26], scale=1)

    # Band 2 (y=212..490): C.5 32x48 Cast Silhouette & Watch/Scarf Link Study (Elias v2, Operator F3, Mira)
    _draw_text_img(half, 16, 212, "C.5 32X48 CAST SILHOUETTE & LINK STUDY : COLOUR, SOLID MASK (#=96), LINK (S/W)", PAL[15], scale=2)

    # C.5 32x48 full-figure Mira look study + C.4 32x48 broadcast portrait
    mira_fig_im = to_image(composite(build_mira_look_study()))

    cast_items = [
        ("ELIAS V2 (S)", elias_idle_s),
        ("ELIAS V2 (NE)", elias_idle_ne),
        ("OPERATOR (F3)", op_frames[2]),
        ("MIRA (FIG)", mira_fig_im),
        ("MIRA (PORTRAIT)", mira_png),
    ]
    for idx, (label, sp) in enumerate(cast_items):
        bx = 16 + idx * 124
        # Floor 02 (left half) / Wall 08 (right half) split background
        bg = Image.new('RGBA', (32, 48), PAL[2] + (255,))
        for y in range(48):
            for x in range(16, 32):
                bg.putpixel((x, y), PAL[8] + (255,))
        bg.alpha_composite(sp, (0, 0))
        half.alpha_composite(bg.resize((96, 144), Image.NEAREST), (bx, 242))
        _draw_text_img(half, bx, 392, label, PAL[15], scale=1)

    # Strict solid-grey silhouette test (#=96 on bg=24) + link marker pass (#=96, w=224 on bg=24; scarf hidden in Ch1 per ADR-022 A3)
    solid_trio = [
        ("ELIAS MASK", elias_idle_s, set(), {(19, 25), (20, 25), (21, 25), (19, 26), (21, 26), (19, 27), (20, 27), (21, 27)}),
        ("OPER. MASK", op_frames[2], set(),
         {(26 + dx, 20 + dy) for dy in range(3) for dx in range(3) if not (dx == 1 and dy == 1)}),
        ("MIRA MASK", mira_fig_im, set(), set()),
    ]
    for idx, (label, sp, s_pts, w_pts) in enumerate(solid_trio):
        # 1) Strict solid grey (#=96)
        m_im = Image.new('RGBA', (32, 48), (24, 24, 24, 255))
        # 2) Link pass (#=96, s=144, w=224)
        l_im = Image.new('RGBA', (32, 48), (24, 24, 24, 255))
        spx = sp.load()
        for y in range(48):
            for x in range(32):
                if spx[x, y][3] > 0:
                    m_im.putpixel((x, y), (96, 96, 96, 255))
                    if (x, y) in w_pts:
                        l_im.putpixel((x, y), (224, 224, 224, 255))
                    elif (x, y) in s_pts:
                        l_im.putpixel((x, y), (144, 144, 144, 255))
                    else:
                        l_im.putpixel((x, y), (96, 96, 96, 255))
        bx_solid = 650 + idx * 106
        bx_link = 980 + idx * 106
        half.alpha_composite(m_im.resize((96, 144), Image.NEAREST), (bx_solid, 242))
        _draw_text_img(half, bx_solid, 392, label, PAL[15], scale=1)
        half.alpha_composite(l_im.resize((96, 144), Image.NEAREST), (bx_link, 242))
        _draw_text_img(half, bx_link, 392, label.replace("MASK", "LINK"), PAL[26], scale=1)

    # Native 1x strip inside half (y=414..490)
    _draw_text_img(half, 16, 416, "NATIVE 1X STRIP (FLOOR 02 / WALL 08):", PAL[14], scale=1)
    nx = 260
    for sp in op_frames + [elias_idle_s, elias_idle_ne, mira_fig_im, mira_png]:
        c1 = Image.new('RGBA', (32, 48), PAL[2] + (255,))
        c1.alpha_composite(sp, (0, 0))
        c2 = Image.new('RGBA', (32, 48), PAL[8] + (255,))
        c2.alpha_composite(sp, (0, 0))
        half.alpha_composite(c1, (nx, 416))
        half.alpha_composite(c2, (nx + 36, 416))
        nx += 78

    # Paste colour top half (y=0..500) and luminance greyscale bottom half (y=520..1020), plus native summary footer
    canvas.alpha_composite(half, (0, 0))
    gs_half = half.convert('L').convert('RGBA')
    canvas.alpha_composite(gs_half, (0, 520))
    _draw_text_img(canvas, 16, 1040, "LUMINANCE GREYSCALE PROOF ABOVE — ALL 3 CAST SILHOUETTES DISTINCT ON FLOOR 02 & WALL 08", PAL[15], scale=2)
    _draw_text_img(canvas, 16, 1070, "ADR-022 A3: OPERATOR SCARF HIDDEN IN CH1 EXPORTS (RETAINED AS SEPARATE .PXO LAYER WITH 0 GAPS)", PAL[25], scale=2)
    return canvas


def build_beat10_city_plate_proof():
    """1320x1260 colour + luminance greyscale proof of the 1280x360 Beat 10 city plate, rain layer, 23:59 clocks & Mira screen."""
    W, H = 1320, 1260
    canvas = Image.new('RGBA', (W, H), PAL[0] + (255,))

    plate = _png('environments', 'ch01_env_beat10_city_plate_idle')
    backdrop = _png('environments', 'ch01_env_beat10_city_backdrop_idle')
    rain = _png('environments', 'ch01_env_beat10_suspended_rain_idle')
    mira = _png('ui', 'ch01_ui_mira_broadcast_portrait_idle')

    _draw_text_img(canvas, 20, 10, "BEAT 10 FROZEN CITY PLATE (1280X360 COLOUR) : STATION EXIT -> PLAZA & MIRA SCREEN", PAL[15], scale=2)
    canvas.alpha_composite(plate, (20, 32))

    _draw_text_img(canvas, 20, 404, "BEAT 10 FROZEN CITY PLATE (1280X360 LUMINANCE GREYSCALE PROOF)", PAL[15], scale=2)
    plate_gs = plate.convert('L').convert('RGBA')
    canvas.alpha_composite(plate_gs, (20, 426))

    # Bottom inspection band (y=800..1245):
    # 1) Separate layers proof (Backdrop only, Suspended Rain only on dark bg, Mira 32x48 portrait at 1x and x3 in colour & greyscale)
    _draw_text_img(canvas, 20, 800, "SEPARATE LAYER EXPORTS & NATIVE/X3 MIRA BROADCAST VALIDATION (COLOUR + GREYSCALE):", PAL[26], scale=2)

    # Crop 320x180 of Backdrop (no rain, no Mira) vs Full Plate around the Plaza Broadcast Tower (x=720..1040, y=20..200)
    crop_bd = backdrop.crop((720, 20, 1040, 200))
    crop_pl = plate.crop((720, 20, 1040, 200))
    crop_rn = Image.new('RGBA', (320, 180), PAL[0] + (255,))
    crop_rn.alpha_composite(rain.crop((720, 20, 1040, 200)), (0, 0))

    canvas.alpha_composite(crop_bd, (20, 830))
    _draw_text_img(canvas, 20, 1018, "LAYER: CITY_BACKDROP (NO MIRA/RAIN)", PAL[15], scale=1)

    canvas.alpha_composite(crop_rn, (360, 830))
    _draw_text_img(canvas, 360, 1018, "LAYER: SUSPENDED_RAIN (1280X360 ALPHA)", PAL[15], scale=1)

    canvas.alpha_composite(crop_pl, (700, 830))
    _draw_text_img(canvas, 700, 1018, "COMPOSITE: BACKDROP + MIRA + RAIN (0 PX DIFF)", PAL[26], scale=1)

    # Native 1x (32x48) and x3 (96x144) Mira broadcast portrait in colour & luminance greyscale
    mira_gs = mira.convert('L').convert('RGBA')
    canvas.alpha_composite(mira, (1050, 830))
    canvas.alpha_composite(mira_gs, (1092, 830))
    _draw_text_img(canvas, 1050, 884, "MIRA 1X (32X48)", PAL[15], scale=1)

    canvas.alpha_composite(mira.resize((96, 144), Image.NEAREST), (1050, 900))
    canvas.alpha_composite(mira_gs.resize((96, 144), Image.NEAREST), (1160, 900))
    _draw_text_img(canvas, 1050, 1050, "MIRA X3 (COL / GREY)", PAL[26], scale=1)

    # Bottom row (y=1045..1240): Station Exit 23:59 clock crop (colour + greyscale) & Pan Start/End 640x360 framing summary
    exit_crop = plate.crop((60, 48, 320, 238))
    exit_crop_gs = exit_crop.convert('L').convert('RGBA')
    canvas.alpha_composite(exit_crop, (20, 1045))
    canvas.alpha_composite(exit_crop_gs, (300, 1045))
    _draw_text_img(canvas, 20, 1240, "STATION EXIT 23:59 CLOCK & CANOPY (COL + GREY)", PAL[15], scale=1)

    plaza_gs_crop = crop_pl.convert('L').convert('RGBA')
    canvas.alpha_composite(plaza_gs_crop, (580, 1045))
    _draw_text_img(canvas, 580, 1240, "PLAZA TOWER 23:59 & MIRA SCREEN (GREYSCALE)", PAL[15], scale=1)

    return canvas


def build_beat10_city_pan_start_mockup():
    """Native 640x360 start pan crop (x=0..640, y=0..360) from delivered runtime ch01_env_beat10_city_plate_idle.png."""
    plate = _png('environments', 'ch01_env_beat10_city_plate_idle')
    return plate.crop((0, 0, 640, 360))


def build_beat10_city_pan_end_mockup():
    """Native 640x360 end pan crop (x=640..1280, y=0..360) from delivered runtime ch01_env_beat10_city_plate_idle.png."""
    plate = _png('environments', 'ch01_env_beat10_city_plate_idle')
    return plate.crop((640, 0, 1280, 360))


def write_mockups(out_dir=None):
    os.makedirs(out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups'), exist_ok=True)
    m1 = build_operator_platform_mockup()
    m1.save(mockup_path('ch01_operator_sighting_platform_mockup.png', out_dir))
    m2 = build_operator_cast_silhouette_proof()
    m2.save(mockup_path('ch01_operator_cast_silhouette_greyscale_proof.png', out_dir))
    m3 = build_beat10_city_plate_proof()
    m3.save(mockup_path('ch01_beat10_city_plate_greyscale_proof.png', out_dir))
    m4 = build_beat10_city_pan_start_mockup()
    m4.save(mockup_path('ch01_beat10_city_pan_start_640x360_mockup.png', out_dir))
    m5 = build_beat10_city_pan_end_mockup()
    m5.save(mockup_path('ch01_beat10_city_pan_end_640x360_mockup.png', out_dir))
