"""Ability wheel art (TLF-053, ADR-021): watch face, pointer, 6 segments x {normal, selected, locked},
16x16 ability icons (also the HUD slot icons), '?' icon, lock glyph. Palette TLF-CH01-32 only, binary alpha.

Wheel canvas 160 x 160, centre (80, 80). Segment i (0 Trace, 1 Rewind, 2 Freeze, 3 Echo, 4 Fast-Forward,
5 unknown) is centred at angle -90 + 60*i degrees (screen coordinates, y down): 0 top, 1 upper right, 2 lower right,
3 bottom, 4 lower left, 5 upper left. Every piece is a tight crop; LAYOUT gives its top-left in the 160 x 160 canvas."""
import math, os
from lib import *

S = 160
C = 80.0
R_IN, R_OUT = 42.0, 80.0
HALF = 28.0                       # half angular width of a segment (56 deg wide, 4 deg gaps)
NAMES = ['trace', 'rewind', 'freeze', 'echo', 'fast_forward', 'unknown']
LABELS = ['TRACE', 'REWIND', 'FREEZE', 'ECHO', 'FAST-FWD', '?']
ANG = [-90 + 60 * i for i in range(6)]


def polar(x, y):
    dx, dy = x + 0.5 - C, y + 0.5 - C
    return math.hypot(dx, dy), math.degrees(math.atan2(dy, dx))


def adiff(a, b):
    d = (a - b + 180) % 360 - 180
    return abs(d)


def seg_mask(i):
    m = set()
    for y in range(S):
        for x in range(S):
            r, a = polar(x, y)
            if R_IN <= r <= R_OUT and adiff(a, ANG[i]) <= HALF:
                m.add((x, y))
    return m


def bbox(m):
    xs = [p[0] for p in m]; ys = [p[1] for p in m]
    return min(xs), min(ys), max(xs), max(ys)


# ------------------------------------------------------------------ segments
def segment(i, state):
    m = seg_mask(i)
    x0, y0, x1, y1 = bbox(m)
    w, h = x1 - x0 + 1, y1 - y0 + 1
    fill, edge = Layer(w, h, 'Plate_Fill'), Layer(w, h, 'Plate_Border')
    local = {(x - x0, y - y0) for (x, y) in m}
    border = {(x, y) for (x, y) in local if any((x + dx, y + dy) not in local for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    inner2 = {(x, y) for (x, y) in local if (x, y) not in border and any((x + dx, y + dy) in border for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    base_fill = {'normal': 0, 'selected': 27, 'locked': 1}[state]
    for (x, y) in local:
        fill.put(x, y, base_fill)
    if state == 'locked':
        for (x, y) in local:                               # diagonal hatch (shape cue, not only grey)
            if (x + y) % 5 == 0:
                fill.put(x, y, 12)
    for (x, y) in border:
        light = ((x - 1, y) not in local) or ((x, y - 1) not in local)   # light from the top left
        if state == 'normal':
            edge.put(x, y, 14 if light else 13)
        elif state == 'selected':
            edge.put(x, y, 29)
        else:                                              # dashed border
            edge.put(x, y, 13 if (x + y) % 6 < 3 else None)
    if state == 'selected':
        for (x, y) in inner2:
            edge.put(x, y, 31)                             # second, white line: selected is also a thicker frame
    return [fill, edge], (x0, y0, w, h)


# ------------------------------------------------------------------ watch face
FACE_W, FACE_H, FACE_CX, FACE_CY = 52, 56, 26.0, 30.0


def face():
    L0 = Layer(FACE_W, FACE_H, 'Bezel_And_Crown')
    L1 = Layer(FACE_W, FACE_H, 'Dial_And_Hands')
    for y in range(FACE_H):
        for x in range(FACE_W):
            dx, dy = x + 0.5 - FACE_CX, y + 0.5 - FACE_CY
            r = math.hypot(dx, dy)
            if r <= 24.5:
                if r > 21.0:                               # bezel
                    a = math.degrees(math.atan2(dy, dx))
                    L0.put(x, y, 15 if adiff(a, -135) <= 50 else (12 if adiff(a, 45) <= 50 else 13))
                elif r > 19.0:
                    L0.put(x, y, 14)                       # chrome inner lip
                else:
                    L1.put(x, y, 31)                       # dial
    L0.rect(22, 0, 29, 5, 14); L0.rect(23, 1, 28, 4, 13); L0.rect(24, 2, 27, 3, 15)   # crown
    L0.rect(22, 5, 29, 5, 12)
    outline = {(x, y) for y in range(FACE_H) for x in range(FACE_W) if L0.p[y][x] is not None or L1.p[y][x] is not None}
    ring_edge = Layer(FACE_W, FACE_H, 'x')
    outline_mask(outline, 0, ring_edge, FACE_W, FACE_H)
    for y in range(FACE_H):
        for x in range(FACE_W):
            if ring_edge.p[y][x] is not None and L0.p[y][x] is None:
                L0.p[y][x] = 0
    for k in range(12):                                    # ticks
        a = math.radians(-90 + 30 * k)
        long = k % 3 == 0
        for t in range(15 if long else 16, 18):
            px = int(FACE_CX + math.cos(a) * t - 0.0 + (0.5 if math.cos(a) >= 0 else -0.5)) if False else int(math.floor(FACE_CX + math.cos(a) * t))
            py = int(math.floor(FACE_CY + math.sin(a) * t))
            L1.put(px, py, 0 if long else 14)
            if long:
                L1.put(px + (1 if abs(math.cos(a)) < 0.5 else 0), py + (1 if abs(math.sin(a)) < 0.5 else 0), 0)
    L1.line(26, 30, 26, 14, 0); L1.line(25, 30, 24, 15, 0)         # 23:59: minute hand just left of 12, hour hand under it
    L1.line(27, 30, 27, 21, 23); L1.line(28, 30, 28, 23, 23)
    L1.rect(25, 29, 28, 32, 25); L1.put(25, 29, 26); L1.rect(26, 30, 27, 31, 0)         # hub
    for (x, y) in ((38, 14), (37, 16), (36, 18), (34, 20), (33, 23), (31, 26)):          # crack across the crystal
        L1.put(x, y, 14)
    return [L0, L1]


def hub_ring():
    L = Layer(10, 10, 'Ring')
    for y in range(10):
        for x in range(10):
            r = math.hypot(x + 0.5 - 5, y + 0.5 - 5)
            if 3.6 <= r <= 5.0:
                L.put(x, y, 26)
    return [L]


# ------------------------------------------------------------------ pointer (6 snapped directions)
PTR = 18


def pointer(i):
    """Orientation-free pointer: a diamond bead on the bezel ring at the segment's direction, with a short tail towards the
    dial. The shape is identical for all six directions (only its position changes), so it is pixel-clean at 60 deg steps
    where a rotated arrow would not be."""
    L = Layer(PTR, PTR, 'Bead')
    a = math.radians(ANG[i])
    ux, uy = math.cos(a), math.sin(a)
    cx, cy = PTR // 2, PTR // 2                              # bead centre pixel (9, 9)
    rc = 34.0                                              # distance of the bead centre from the wheel centre
    m = set()
    for y in range(PTR):
        for x in range(PTR):
            if abs(x - cx) + abs(y - cy) <= 3:
                m.add((x, y))
    tail = set()
    for t in range(1, 6):                                  # tail towards the dial (r 29 .. 25)
        tail.add((int(round(cx - ux * (3.0 + t))), int(round(cy - uy * (3.0 + t)))))
    for (x, y) in tail:
        L.put(x, y, 26)
    for (x, y) in m:
        L.put(x, y, 26)
    for (x, y) in m:
        if abs(x - cx) + abs(y - cy) == 3 and (x >= cx or y >= cy):
            L.put(x, y, 25)                                # amber lower-right edge (light from the top left)
    L.put(cx - 1, cy - 1, 31)                              # specular dot
    allm = m | tail
    ring = Layer(PTR, PTR, 'x')
    outline_mask(allm, 0, ring, PTR, PTR)
    for y in range(PTR):
        for x in range(PTR):
            if ring.p[y][x] is not None:
                L.put(x, y, 0)
    return [L], (int(round(C + ux * rc - cx - 0.5)), int(round(C + uy * rc - cy - 0.5)))


# ------------------------------------------------------------------ icons 16 x 16
def disc(L, cx, cy, r, c):
    for y in range(L.h):
        for x in range(L.w):
            if math.hypot(x + 0.5 - cx, y + 0.5 - cy) <= r:
                L.put(x, y, c)


def icon_trace():
    L = Layer(16, 16, 'Reticle')
    for y in range(16):
        for x in range(16):
            d = abs(x + 0.5 - 8) + abs(y + 0.5 - 8)
            if d == 8:
                L.put(x, y, 30)
            elif d == 4:
                L.put(x, y, 26)
            elif d <= 2:
                L.put(x, y, 31)
    for (x, y) in ((8, 0), (7, 0), (8, 15), (7, 15), (0, 8), (0, 7), (15, 8), (15, 7)):
        L.put(x, y, 30)                                    # reticle ticks at the four points
    return [L]


def art(rows, cmap, w=16, h=16, name='Art'):
    L = Layer(w, h, name)
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            c = cmap.get(ch)
            if c is not None:
                L.put(i, j, c)
    return L


def icon_rewind():
    # three-quarter ring (arrow head at the upper left, pointing counter-clockwise) with a double chevron "<<" inside
    L = Layer(16, 16, 'Ring_And_Chevrons')
    for y in range(16):
        for x in range(16):
            dx, dy = x + 0.5 - 8, y + 0.5 - 8
            r = math.hypot(dx, dy)
            a = math.degrees(math.atan2(dy, dx))
            if 5.7 <= r <= 7.5 and adiff(a, -135) > 24:
                L.put(x, y, 29)
    for (x, y) in ((0, 3), (1, 3), (2, 3), (3, 3), (1, 4), (2, 4), (3, 4), (2, 5), (3, 5), (3, 6)):    # arrow head (tip down-left)
        L.put(x, y, 31)
    for ox, c in ((0, 31), (4, 29)):                                                                # "<<"
        for (x, y) in ((8 - ox, 5), (7 - ox, 6), (6 - ox, 7), (5 - ox, 8), (6 - ox, 9), (7 - ox, 10), (8 - ox, 11)):
            L.put(x + 3, y, c)
    return [L]


def icon_freeze():
    # hexagonal crystal (flat top) with six spokes and four L brackets clamping the corners
    L = art([
        'bb............bb',
        'b..............b',
        '....wwwwwwww....',
        '...wttttttttw...',
        '..wttwtttwtttw..',
        '.wtttwtttwtttttw',
        'wtttttwtwttttttw',
        'wwwwwwwwwwwwwwww',
        'wtttttwtwtttttw.',
        '.wtttwtttwtttw..',
        '..wttwtttwtttw..',
        '...wttttttttw...',
        '....wwwwwwww....',
        '................',
        'b..............b',
        'bb............bb',
    ], {'w': 31, 't': 27, 'b': 29})
    return [L]


def _figure(L, ox, rim, core):
    f = set()
    for y in range(16):
        for x in range(16):
            px_ = x - ox
            head = math.hypot(px_ + 0.5 - 6.5, y + 0.5 - 4.0) <= 2.8
            body = 8 <= y <= 14 and abs(px_ + 0.5 - 6.5) <= 2.3 + (y - 8) * 0.55
            if head or body:
                f.add((x, y))
    edge = {(x, y) for (x, y) in f if any((x + dx, y + dy) not in f for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    for (x, y) in f:
        if 0 <= x < 16:
            L.put(x, y, core)
    for (x, y) in edge:
        if 0 <= x < 16:
            L.put(x, y, rim)


def icon_echo():
    # the figure (bright rim, hollow core) and, offset behind it, its echo in mid cyan
    L = Layer(16, 16, 'Silhouettes')
    _figure(L, 5, 28, 28)
    _figure(L, 0, 29, 1)
    L.put(5, 2, 31); L.put(6, 2, 31); L.put(5, 3, 31)       # highlight on the head
    return [L]


def icon_fast_forward():
    # two solid right-pointing triangles and a stop bar at the right
    L = art([
        '................',
        '.#.......#......',
        '.##......##.....',
        '.###.....###....',
        '.####....####...',
        '.#####...#####..',
        '.######..######.',
        '.#######.#######',
        '.#######.#######',
        '.######..######.',
        '.#####...#####..',
        '.####....####...',
        '.###.....###....',
        '.##......##.....',
        '.#.......#......',
        '................',
    ], {'#': 25})
    for y in range(16):
        for x in range(8, 16):
            if L.p[y][x] is not None:
                L.put(x, y, 26)
    return [L]


def icon_unknown():
    L = Layer(16, 16, 'Question')
    disc(L, 8, 8, 7.6, 12)
    m = L.mask()
    for (x, y) in list(m):
        if any((x + dx, y + dy) not in m for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            L.put(x, y, 13)
    Q = [
        '..####..',
        '.##..##.',
        '.##..##.',
        '....##..',
        '...##...',
        '...##...',
        '........',
        '...##...',
        '...##...',
    ]
    for j, row in enumerate(Q):
        for i, ch in enumerate(row):
            if ch == '#':
                L.put(4 + i, 3 + j, 15)
    return [L]


LOCK_W, LOCK_H = 12, 14


def lock_glyph():
    L = Layer(LOCK_W, LOCK_H, 'Padlock')
    for (x0, x1, y) in ((4, 7, 0), (3, 8, 1), (2, 3, 2), (8, 9, 2), (2, 3, 3), (8, 9, 3), (2, 3, 4), (8, 9, 4), (2, 3, 5), (8, 9, 5)):
        L.hline(x0, x1, y, 15)                              # shackle
    L.rect(0, 6, 11, 13, 14)                                # body
    L.rect(1, 7, 10, 12, 15)
    L.hline(1, 10, 12, 13); L.vline(10, 7, 12, 13)          # shade (light from the top left)
    L.rect(5, 8, 6, 9, 0); L.rect(5, 10, 6, 11, 0); L.put(4, 8, 0); L.put(7, 8, 0)   # keyhole
    m = L.mask()
    edge = Layer(LOCK_W, LOCK_H, 'x')
    outline_mask(m, 0, edge, LOCK_W, LOCK_H)
    big = Layer(LOCK_W + 2, LOCK_H + 2, 'Padlock')
    big.blit(L, 1, 1)
    e2 = Layer(LOCK_W + 2, LOCK_H + 2, 'x')
    outline_mask(big.mask(), 0, e2, LOCK_W + 2, LOCK_H + 2)
    for y in range(big.h):
        for x in range(big.w):
            if e2.p[y][x] is not None:
                big.put(x, y, 0)
    return [big]


def icon_locked(name):
    base = {'trace': icon_trace, 'rewind': icon_rewind, 'freeze': icon_freeze, 'echo': icon_echo,
            'fast_forward': icon_fast_forward, 'unknown': icon_unknown}[name]()[0]
    L = Layer(16, 16, 'Dimmed_Shape')
    for y in range(16):
        for x in range(16):
            c = base.p[y][x]
            if c is not None:                                  # keep the structure, drop the colour: three greys by brightness
                lum = sum(PAL[c])
                L.put(x, y, 14 if lum > 420 else (13 if lum > 200 else 12))
    O = Layer(16, 16, 'Lock_Overlay')
    ART = [
        '.0000.',
        '05..50',
        '05..50',
        '000000',
        '055550',
        '050550',
        '055550',
        '000000',
    ]
    col = {'0': 0, '5': 15}
    for j, row in enumerate(ART):
        for i, ch in enumerate(row):
            c = col.get(ch)
            if c is not None:
                O.put(10 + i, 8 + j, c)
    return [L, O]


# ------------------------------------------------------------------ registry data
def assets():
    """list of (stem, w, h, layer_names, frame_layers, meta) in a fixed order."""
    out = []
    fl = face()
    out.append(('ch01_ui_wheel_face', FACE_W, FACE_H, ['Bezel_And_Crown', 'Dial_And_Hands'], fl,
                dict(x=int(C - FACE_CX), y=int(C - FACE_CY), use='watch face, centred on the wheel centre; pivot = dial centre (26,30)')))
    hr = hub_ring()
    out.append(('ch01_ui_wheel_pointer_rest', 10, 10, ['Ring'], hr, dict(x=75, y=75, use='no direction (dead zone): ring over the dial hub')))
    for i in range(6):
        layers, (px0, py0) = pointer(i)
        out.append(('ch01_ui_wheel_pointer_%d' % i, PTR, PTR, ['Bead'], layers, dict(x=px0, y=py0, use='bead pointer at segment %d (%s)' % (i, NAMES[i]))))
    for i in range(6):
        for st in ('normal', 'selected', 'locked'):
            layers, (x0, y0, w, h) = segment(i, st)
            out.append(('ch01_ui_wheel_seg%d_%s' % (i, st), w, h, ['Plate_Fill', 'Plate_Border'], layers,
                        dict(x=x0, y=y0, use='segment %d (%s) background, %s' % (i, NAMES[i], st))))
    for name, fn in (('trace', icon_trace), ('rewind', icon_rewind), ('freeze', icon_freeze), ('echo', icon_echo), ('fast_forward', icon_fast_forward)):
        lay = fn()
        out.append(('ch01_ui_icon_%s' % name, 16, 16, [lay[0].name], lay, dict(use='%s icon 16x16 (wheel and HUD slot)' % name)))
    for name in ('trace', 'rewind', 'freeze', 'echo', 'fast_forward', 'unknown'):
        lay = icon_locked(name)
        out.append(('ch01_ui_icon_%s_locked' % name, 16, 16, ['Dimmed_Shape', 'Lock_Overlay'], lay, dict(use='%s icon, locked variant (dim silhouette + lock)' % name)))
    lay = icon_unknown()
    out.append(('ch01_ui_icon_unknown', 16, 16, ['Question'], lay, dict(use='unknown slot "?" silhouette')))
    lg = lock_glyph()
    out.append(('ch01_ui_lock_glyph', LOCK_W + 2, LOCK_H + 2, ['Padlock'], lg, dict(use='lock glyph overlay for locked segments')))
    return out




# ------------------------------------------------------------------ mockups (640 x 360) and the greyscale proof
MOCK_DIR = os.path.join(REPO, 'design', 'art', 'mockups')
WX, WY = 240, 100                      # top-left of the 160 x 160 wheel canvas: the wheel is centred at (320, 180)
STATES = [
    ('a_trace_only', 'Only Trace unlocked (Trace selected)', {0}, 0),
    ('b_all_four', 'All four abilities unlocked (Trace selected)', {0, 1, 2, 3}, 0),
    ('c_rewind_selected', 'All four unlocked, Rewind selected', {0, 1, 2, 3}, 1),
]
FONT = os.path.join(REPO, 'assets', 'ui', 'fonts', 'tlf_pixel_mono.ttf')


def _text(cv, cx, y, s, col):
    from PIL import ImageFont, ImageDraw
    f = ImageFont.truetype(FONT, 8)
    w = max(1, int(f.getlength(s)))
    im = Image.new('L', (w + 2, 12), 0)
    d = ImageDraw.Draw(im)
    d.fontmode = '1'
    d.text((0, 0), s, font=f, fill=255)
    x0 = cx - w // 2
    for yy in range(12):
        for xx in range(w + 2):
            if im.getpixel((xx, yy)):
                cv.put(x0 + xx, y + yy, col)


def compose(unlocked, selected, title=None):
    by = {a[0]: a for a in assets()}
    cv = Layer(640, 360, 'Mockup')
    cv.rect(0, 0, 639, 359, 0)
    for gx in range(0, 640, 20):
        for gy in range(0, 360, 20):
            cv.put(gx, gy, 1)
    for x in range(12, 628):                                 # 12 px safe margin, dotted
        if x % 4 < 2:
            cv.put(x, 12, 12); cv.put(x, 347, 12)
    for y in range(12, 348):
        if y % 4 < 2:
            cv.put(12, y, 12); cv.put(627, y, 12)
    for i in range(6):
        st = 'selected' if i == selected else ('normal' if i in unlocked else 'locked')
        stem, w, h, names, layers, m = by['ch01_ui_wheel_seg%d_%s' % (i, st)]
        cv.blit(composite(layers), WX + m['x'], WY + m['y'])
    for key in ('ch01_ui_wheel_face',):
        stem, w, h, names, layers, m = by[key]
        cv.blit(composite(layers), WX + m['x'], WY + m['y'])
    key = 'ch01_ui_wheel_pointer_%d' % selected if selected is not None else 'ch01_ui_wheel_pointer_rest'
    stem, w, h, names, layers, m = by[key]
    cv.blit(composite(layers), WX + m['x'], WY + m['y'])
    for i in range(6):
        a = math.radians(ANG[i])
        cx, cy = WX + 80 + int(round(math.cos(a) * 62)), WY + 80 + int(round(math.sin(a) * 62))
        unl = i in unlocked
        nm = NAMES[i]
        stem = 'ch01_ui_icon_%s' % nm if unl else 'ch01_ui_icon_%s_locked' % nm
        layers = by[stem][4]
        cv.blit(composite(layers), cx - 8, cy - 14)
        label = LABELS[i] if unl else ('LOCKED' if i != 5 else '')
        if label:
            lx = cx + (4 if math.cos(a) > 0.5 else (-4 if math.cos(a) < -0.5 else 0))
            _text(cv, lx, cy + 4, label, 31 if (unl and i != selected) else (29 if unl else 13))
    if title:
        _text(cv, 320, 20, title, 31)
    return cv


def mockup_path(key, outdir=None):
    return os.path.join(outdir or MOCK_DIR, 'ch01_ability_wheel_%s_mockup.png' % key)


def proof_path(outdir=None):
    return os.path.join(outdir or MOCK_DIR, 'ch01_ability_wheel_greyscale_proof.png')


def greyscale_proof():
    ims = []
    for key, title, unl, sel in STATES:
        im = to_image(compose(unl, sel)).crop((WX - 4, WY - 4, WX + 164, WY + 164))
        ims.append(im.resize((336, 336), Image.NEAREST))
    by = {a[0]: a for a in assets()}
    strip = []
    for suffix in ('', '_locked'):
        for nm in NAMES:
            stem = 'ch01_ui_icon_%s%s' % (nm, suffix)
            if stem in by:
                strip.append(to_image(composite(by[stem][4])).resize((64, 64), Image.NEAREST))
    W, H = 3 * 336 + 4 * 8, 336 + 2 * 64 + 4 * 8
    out = Image.new('RGBA', (W, H), (10, 13, 20, 255))
    for k, im in enumerate(ims):
        out.alpha_composite(im, (8 + k * (336 + 8), 8))
    for k, im in enumerate(strip):
        row, col = divmod(k, 6)
        out.alpha_composite(im, (8 + col * 72 + (0 if row == 0 else 0), 8 + 336 + 8 + row * 72))
    g = out.convert('L').convert('RGBA')                     # luminance only: the colour is gone, the shapes must remain
    return g


def write_mockups(outdir=None):
    os.makedirs(outdir or MOCK_DIR, exist_ok=True)
    for key, title, unl, sel in STATES:
        to_image(compose(unl, sel)).save(mockup_path(key, outdir))
    greyscale_proof().save(proof_path(outdir))
