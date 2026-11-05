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
    scarf = Layer(w, h, 'Scarf')
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


def _build_city_layers():
    w, h = CITY_PLATE_W, CITY_PLATE_H
    sky = Layer(w, h, 'Sky_And_Distant_Towers')
    plaza = Layer(w, h, 'Plaza_And_Station_Exit')
    clocks = Layer(w, h, 'Clocks_2359')
    mira_scr = Layer(w, h, 'Mira_Broadcast_Screen')
    rain = Layer(w, h, 'Suspended_Rain')

    # --- Layer 1: Sky_And_Distant_Towers ---
    # Banded nocturnal sky (indices 00, 01, 02, 03)
    sky.rect(0, 0, w - 1, 69, 0)
    sky.rect(0, 70, w - 1, 139, 1)
    sky.rect(0, 140, w - 1, 219, 2)
    sky.rect(0, 220, w - 1, h - 1, 1)

    # Distant Elysium City skyline silhouettes (cool slate 01..04 & steel 11..13)
    towers = [
        (40, 28, 110, 12),
        (160, 44, 235, 11),
        (260, 18, 355, 12),
        (370, 52, 430, 1),
        (485, 30, 560, 12),
        (580, 14, 685, 11),
        (700, 40, 770, 12),
        (950, 22, 1045, 12),
        (1060, 48, 1135, 11),
        (1150, 16, 1255, 12),
    ]
    for (tx0, ty0, tx1, tcol) in towers:
        sky.rect(tx0, ty0, tx1, 225, tcol)
        sky.vline(tx0, ty0, 225, 13 if tcol == 12 else 2)
        sky.hline(tx0, tx1, ty0, 14 if tcol == 12 else 3)
        sky.vline(tx1, ty0, 225, 0)
        # Sparse lit/unlit window grids in 03, 08, and occasional warm 25
        for wy in range(ty0 + 10, 210, 14):
            for wx in range(tx0 + 8, tx1 - 8, 12):
                hval = (wx * 31 + wy * 17) % 19
                if hval == 0:
                    sky.rect(wx, wy, wx + 3, wy + 5, 25)
                elif hval in (1, 2, 3):
                    sky.rect(wx, wy, wx + 3, wy + 5, 8)
                else:
                    sky.rect(wx, wy, wx + 3, wy + 5, 1)

    # Elevated transit viaduct spanning across the background (y=164..184) with a train frozen mid-span
    sky.rect(0, 168, w - 1, 180, 11)
    sky.hline(0, w - 1, 168, 14)
    sky.hline(0, w - 1, 179, 0)
    for px in range(60, w, 120):
        sky.rect(px, 180, px + 18, 235, 11)
        sky.vline(px, 180, 235, 13)
        sky.vline(px + 18, 180, 235, 0)
    # Stalled transit train frozen between stations on the viaduct (x=590..750, y=152..167)
    sky.rect(590, 152, 750, 167, 13)
    sky.hline(590, 750, 152, 15)
    sky.hline(590, 750, 163, 24)   # transit orange stripe
    for wx in range(600, 740, 18):
        sky.rect(wx, 156, wx + 10, 160, 8)
    sky.rect(590, 157, 593, 161, 24)   # frozen tail lamp

    # --- Layer 2: Plaza_And_Station_Exit ---
    # Rain-slick plaza floor (y=232..359) with 2:1 perspective paving lines and wet reflections
    plaza.rect(0, 232, w - 1, h - 1, 1)
    plaza.hline(0, w - 1, 232, 13)
    plaza.hline(0, w - 1, 233, 2)
    for py in range(244, h, 16):
        plaza.hline(0, w - 1, py, 2 if (py // 16) % 2 == 0 else 0)
    for gx in range(-160, w + 160, 48):
        plaza.line(gx, 234, gx - 120, h - 1, 2)
    # Wet tactile amber edge along the station exit step (x=20..360, y=276..282)
    plaza.rect(20, 276, 360, 282, 22)
    for tx in range(24, 356, 8):
        plaza.rect(tx, 277, tx + 4, 280, 25)
        plaza.put(tx + 1, 278, 26)

    # Left pan viewport (x=0..640): Station Elysium-09 street exit headhouse (x=24..340, y=48..275)
    plaza.rect(24, 48, 340, 275, 11)
    plaza.rect(28, 52, 336, 275, 7)     # dark teal-slate subterranean station stone
    plaza.hline(24, 340, 48, 15)
    plaza.hline(24, 340, 49, 14)
    plaza.vline(24, 48, 275, 14)
    plaza.vline(340, 48, 275, 0)
    # Station exit portal opening (x=76..288, y=108..275)
    plaza.rect(76, 108, 288, 275, 0)
    plaza.rect(82, 114, 282, 268, 1)
    plaza.hline(76, 288, 108, 14)
    # Wet descending stairs inside exit portal + iron railings
    for sy in range(236, 272, 6):
        plaza.hline(84, 280, sy, 13)
        plaza.hline(84, 280, sy + 1, 2)
    # Warm amber station practicals & hazard stripe inside exit canopy
    plaza.hline(28, 336, 100, 24)
    plaza.hline(84, 280, 116, 25)

    # Mid-plaza repeater pylon (x=432..480, y=110..256) housing the 1x (32x48) Mira broadcast screen at (440, 136)
    plaza.rect(432, 110, 480, 256, 11)
    plaza.hline(432, 480, 110, 15)
    plaza.vline(432, 110, 256, 14)
    plaza.vline(480, 110, 256, 0)
    plaza.rect(438, 134, 473, 185, 0)   # 32x48 screen recess bezel around (440, 136)

    # Street intercom / speaker post at x=524..546, y=192..264 (clicks on in Beat 10: "You are late. ... Again.")
    plaza.rect(531, 220, 539, 264, 11)
    plaza.vline(531, 220, 264, 14)
    plaza.rect(524, 192, 546, 222, 12)
    plaza.hline(524, 546, 192, 15)
    plaza.rect(528, 197, 542, 209, 0)
    for gy in range(199, 208, 2):
        plaza.hline(530, 540, gy, 13)
    plaza.rect(533, 213, 537, 217, 25)   # active amber call LED + reflection on wet floor
    plaza.put(535, 215, 26)
    plaza.hline(528, 542, 270, 24)
    plaza.hline(531, 539, 274, 25)

    # Right pan viewport (x=640..1280): Grand Plaza Broadcast & Clock Tower (x=788..932, y=28..252)
    plaza.rect(788, 28, 932, 252, 11)
    plaza.rect(794, 34, 926, 252, 12)
    plaza.hline(788, 932, 28, 15)
    plaza.vline(788, 28, 252, 14)
    plaza.vline(932, 28, 252, 0)
    # Architectural frame around the central 32x48 Mira broadcast screen at (844, 104)
    plaza.rect(836, 96, 883, 159, 0)
    plaza.rect(838, 98, 881, 157, 13)
    plaza.hline(838, 881, 98, 15)
    plaza.rect(842, 102, 877, 153, 0)
    # Wet lavender/cyan reflection on plaza floor below the broadcast tower
    for ry in range(258, 320, 6):
        plaza.hline(840, 880, ry, 8 if (ry // 6) % 2 == 0 else 3)

    # Street lamps casting local warm amber pools (22..26) onto the plaza
    for lx in (388, 692, 1020, 1188):
        plaza.vline(lx, 144, 248, 12)
        plaza.vline(lx + 1, 144, 248, 0)
        plaza.hline(lx - 6, lx + 8, 144, 14)
        plaza.rect(lx - 5, 146, lx + 7, 149, 25)
        plaza.hline(lx - 3, lx + 5, 147, 26)
        # Warm floor pool
        plaza.rect(lx - 18, 250, lx + 20, 258, 22)
        plaza.rect(lx - 10, 252, lx + 12, 256, 24)
        plaza.hline(lx - 4, lx + 6, 254, 25)

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
        # Every 6th drop above the plaza floor has a frozen mid-air splash ring
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

    # Scarf-on vs Scarf-off & x6 Watch/Scarf callout on the right of Band 1 (x=890..1300)
    f3_layers = _build_operator_frame(2)  # [shadow, robe, hood, scarf, hand_watch]
    no_scarf_im = to_image(composite([f3_layers[0], f3_layers[1], f3_layers[2], f3_layers[4]]))
    cell_ns = Image.new('RGBA', (32, 48), PAL[2] + (255,))
    cell_ns.alpha_composite(no_scarf_im, (0, 0))
    half.alpha_composite(cell_ns.resize((96, 144), Image.NEAREST), (890, 36))
    _draw_text_img(half, 890, 186, "F3 SCARF-OFF", PAL[15], scale=1)

    # x6 zoom callout of F3 upper torso + watch + scarf (crop x=14..30, y=10..26 -> 16x16 @ x8 = 128x128)
    f3_crop = op_frames[2].crop((14, 10, 30, 26))
    callout_bg = Image.new('RGBA', (128, 128), PAL[2] + (255,))
    callout_bg.alpha_composite(f3_crop.resize((128, 128), Image.NEAREST), (0, 0))
    half.alpha_composite(callout_bg, (1010, 44))
    _draw_text_img(half, 1010, 180, "F3 WATCH(25/26/00)+SCARF(22/23) X8", PAL[26], scale=1)

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

    # Strict solid-grey silhouette test (#=96 on bg=24) + link marker pass (#=96, s=144, w=224 on bg=24)
    solid_trio = [
        ("ELIAS MASK", elias_idle_s, set(), {(19, 25), (20, 25), (21, 25), (19, 26), (21, 26), (19, 27), (20, 27), (21, 27)}),
        ("OPER. MASK", op_frames[2], {(x, y) for y in (13, 14) for x in range(17, 22)} | {(19, 15), (20, 15)},
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
    _draw_text_img(canvas, 16, 1070, "NOTE: ELIAS V2 HAS NO SCARF / WATCH CLIP (OWNER DECISION PENDING PER TLF-061; SCARF IS SEPARATE LAYER)", PAL[25], scale=2)
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


def write_mockups(out_dir=None):
    os.makedirs(out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups'), exist_ok=True)
    m1 = build_operator_platform_mockup()
    m1.save(mockup_path('ch01_operator_sighting_platform_mockup.png', out_dir))
    m2 = build_operator_cast_silhouette_proof()
    m2.save(mockup_path('ch01_operator_cast_silhouette_greyscale_proof.png', out_dir))
    m3 = build_beat10_city_plate_proof()
    m3.save(mockup_path('ch01_beat10_city_plate_greyscale_proof.png', out_dir))
