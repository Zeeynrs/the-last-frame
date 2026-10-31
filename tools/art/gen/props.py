"""Walls + props (batch 2). Iso box helper: tile-space (x along down-right axis, y along down-left axis, z up in px)."""
from lib import *
from tiles import hash2


def inside(poly, px, py):
    n, c = len(poly), False
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]; xj, yj = poly[j]
        if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi:
            c = not c
        j = i
    return c


def fill_poly(L, poly, colfn):
    xs = [p[0] for p in poly]; ys = [p[1] for p in poly]
    for y in range(int(min(ys)), int(max(ys)) + 1):
        for x in range(int(min(xs)), int(max(xs)) + 1):
            if inside(poly, x + 0.5, y + 0.5):
                c = colfn(x, y)
                if c is not None: L.put(x, y, c)


class Iso:
    """pivot=(px,py) is the screen position of the footprint centre at z=0; footprint centre = tile-space (0,0)."""
    def __init__(self, L, pivot):
        self.L, self.p = L, pivot

    def P(self, x, y, z):
        return (int(round(self.p[0] + (x - y) * 16)), int(round(self.p[1] + (x + y) * 8 - z)))

    def box(self, x0, y0, z0, x1, y1, z1, top, left, right, outline=True, pat=None):
        """top/left/right: colour or fn(x,y)->colour. left = +y face (SW), right = +x face (SE)."""
        P = self.P
        faces = {
            'right': [P(x1, y0, z0), P(x1, y1, z0), P(x1, y1, z1), P(x1, y0, z1)],
            'left': [P(x0, y1, z0), P(x1, y1, z0), P(x1, y1, z1), P(x0, y1, z1)],
            'top': [P(x0, y0, z1), P(x1, y0, z1), P(x1, y1, z1), P(x0, y1, z1)],
        }
        mask = {}
        for nm, col in (('left', left), ('right', right), ('top', top)):
            tmp = Layer(self.L.w, self.L.h, 't')
            fill_poly(tmp, faces[nm], col if callable(col) else (lambda x, y, c=col: c))
            for (x, y) in tmp.mask():
                self.L.put(x, y, tmp.p[y][x]); mask[(x, y)] = 1
        if outline:
            ring(self.L, set(mask), 0)

    def vline_edges(self, x, y, z0, z1, c):
        a, b = self.P(x, y, z0), self.P(x, y, z1)
        self.L.line(int(a[0]), int(a[1]), int(b[0]), int(b[1]), c)


def ring(L, mask, col):
    for (x, y) in list(mask):
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in mask and 0 <= nx < L.w and 0 <= ny < L.h and L.p[ny][nx] is None:
                L.p[ny][nx] = col


# ------------------------------------------------------------------ wall corner pillar 32x64, pivot (16,56)
def corner_pillar():
    L = Layer(32, 64, 'Pillar_Faces')
    T = Layer(32, 64, 'Trim_And_Stripe')
    # footprint: 24x24-px-wide column centred on pivot; faces ceramic ramp like the walls
    iso = Iso(L, (16, 56))
    h = 48
    def left(x, y):    # SW-facing, Mid-Dark (like wall N): bricks ramp 2
        row, col = (y + (x // 2) * 0) // 4, x
        c = 7
        if (y % 8) == 3: c = 6
        if ((x + (4 if (y // 8) % 2 else 0)) % 8) == 0 and (y % 8) != 3: c = 6
        return c
    def right(x, y):   # SE-facing, Mid-Light (like wall W)
        c = 8
        if (y % 8) == 3: c = 7
        if ((x + (4 if (y // 8) % 2 else 0)) % 8) == 0 and (y % 8) != 3: c = 7
        return c
    iso.box(-0.375, -0.375, 0, 0.375, 0.375, h, 15, left, right)
    # top cap: steel
    # vertical corner strip + top plate
    p0 = iso.P(0.375, 0.375, 0); p1 = iso.P(0.375, 0.375, h)
    for y in range(p1[1], p0[1] + 1):
        T.put(p0[0], y, 14); T.put(p0[0] - 1, y, 13)
    # emergency stripe band at dado height (ramp 5), follows each face's slope
    for z in (14, 15):
        a = iso.P(-0.375, 0.375, z); b = iso.P(0.375, 0.375, z); c = iso.P(0.375, -0.375, z)
        T.line(int(a[0]), int(a[1]), int(b[0]), int(b[1]) - 1, 24)
        T.line(int(b[0]), int(b[1]), int(c[0]), int(c[1]) - 1, 25)
    # kick plate at base
    for z in (0, 1, 2):
        a = iso.P(-0.375, 0.375, z); b = iso.P(0.375, 0.375, z); c = iso.P(0.375, -0.375, z)
        T.line(int(a[0]), int(a[1]) - 1, int(b[0]), int(b[1]) - 1, 11)
        T.line(int(b[0]), int(b[1]) - 1, int(c[0]), int(c[1]) - 1, 12)
    # keep trim inside silhouette
    m = L.mask()
    for (x, y) in list(T.mask()):
        if (x, y) not in m: T.p[y][x] = None
    return [L, T]


# ------------------------------------------------------------------ archway N (down-right slope): mirror of batch-1 'e'
def archway_n():
    src = Image.open(os.path.join(REPO, 'assets', 'environments', 'ch01', 'ch01_env_archway_frame_e_idle.png')).convert('RGBA')
    L = Layer(32, 64, 'Steel_Arch_Jambs')
    for y in range(64):
        for x in range(32):
            r, g, b, a = src.getpixel((31 - x, y))     # flip_h
            if a: L.put(x, y, RGB2IDX[(r, g, b)])
    # re-light: batch-1 jamb ramp is lit on the screen-left; after flip the lit edge sits on the right.
    # swap the light/dark edge colours (14<->11) inside the two 6px jamb columns so the NW-lit convention holds.
    swap = {14: 11, 11: 14}
    for y in range(64):
        for x in list(range(0, 7)) + list(range(25, 32)):
            c = L.get(x, y)
            if c in swap and 0 < y < 63:
                L.put(x, y, swap[c])
    return [L]


# ------------------------------------------------------------------ railing 32x48, pivot (16,40)
def railing():
    L = Layer(32, 48, 'Iron_Rail')
    def base_y(x): return 32 + x // 2        # floor line along the down-right axis
    # balusters + posts
    for x in range(1, 31):
        by = base_y(x)
        top = by - 22
        if x in (2, 3, 14, 15, 27, 28):      # posts (2px)
            for y in range(top - 1, by + 1):
                L.put(x, y, 14 if x in (2, 14, 27) else 12)
            L.put(x, top - 2, 15 if x in (2, 14, 27) else 13)
        elif x % 4 == 0:                      # thin balusters
            for y in range(top + 3, by - 2):
                L.put(x, y, 11)
    for x in range(1, 31):                    # rails
        by = base_y(x)
        for dy, c in ((-23, 15), (-22, 14), (-21, 13), (-12, 12), (-11, 11)):
            L.put(x, by + dy, c)
        L.put(x, by - 1, 12); L.put(x, by, 11)          # kick rail on the floor
    # amber reflector caps on end posts
    L.put(2, base_y(2) - 25, 25); L.put(27, base_y(27) - 25, 25)
    ring(L, L.mask(), 0)
    return [L]


# ------------------------------------------------------------------ bench 48x32, pivot (24,26)
def bench():
    L = Layer(48, 32, 'Bench')
    iso = Iso(L, (24, 26))
    # 1.5 x 0.5 tiles along the down-right axis: legs, seat slab, backrest on the far (-y) side
    for lx in (-0.62, 0.62):
        iso.box(lx - 0.07, -0.18, 0, lx + 0.07, 0.18, 8, 12, 12, 11)
    iso.box(-0.75, -0.25, 8, 0.75, 0.25, 10, 15, 14, 13)                       # seat slab
    iso.box(-0.75, -0.25, 10, 0.75, -0.17, 22, 14, 13, 12)                     # backrest
    # slat lines on seat top
    for k in range(1, 4):
        a, b = iso.P(-0.75 + 0.375 * k, -0.25, 10), iso.P(-0.75 + 0.375 * k, 0.25, 10)
        L.line(int(a[0]), int(a[1]), int(b[0]), int(b[1]), 13)
    return [L]


# ------------------------------------------------------------------ call box 24x36, pivot (12,32) frontal wall fixture
def call_box(ringing=False):
    L = Layer(24, 36, 'Casing')
    D = Layer(24, 36, 'Handset_And_Lamp')
    L.rect(2, 4, 21, 31, 13)            # casing body
    L.rect(2, 4, 21, 5, 15)             # top specular
    L.rect(2, 6, 3, 31, 14)             # NW lit edge
    L.rect(20, 6, 21, 31, 12)           # shaded edge
    L.rect(2, 30, 21, 31, 11)           # base
    L.rect(5, 8, 18, 15, 11)            # speaker/grille recess
    for yy in (9, 11, 13):
        L.hline(6, 17, yy, 12)
    L.rect(5, 17, 12, 27, 12)           # handset cradle recess
    L.rect(14, 17, 18, 27, 12)          # keypad plate
    for i in range(3):
        for j in range(4):
            L.put(14 + i + (1 if i else 0) if False else 14 + i, 18 + j * 2, 14)
    # handset
    D.rect(6, 18, 11, 19, 15); D.rect(6, 25, 11, 26, 15); D.rect(7, 20, 9, 24, 14); D.rect(9, 20, 10, 24, 13)
    # cord
    D.put(12, 22, 11); D.put(13, 23, 11)
    # lamp
    if ringing:
        D.rect(16, 7, 18, 8, 25); D.put(17, 7, 26)
        # ring marks (shape cue)
        for (x, y) in ((1, 2), (0, 4), (22, 2), (23, 4), (1, 0), (22, 0)):
            D.put(x, y, 26)
    else:
        D.rect(16, 7, 18, 8, 22)
    ring(L, L.mask() | D.mask(), 0)
    return [L, D]


# ------------------------------------------------------------------ reset console 32x36, pivot (16,30)
def reset_console():
    L = Layer(32, 36, 'Console_Body')
    P = Layer(32, 36, 'Panel_And_Button')
    iso = Iso(L, (16, 30))
    iso.box(-0.4, -0.4, 0, 0.4, 0.4, 5, 12, 12, 11)                    # plinth
    iso.box(-0.34, -0.34, 5, 0.34, 0.34, 16, 14, 13, 12)               # cabinet
    iso.box(-0.38, -0.38, 16, 0.38, 0.38, 19, 15, 14, 13)              # top lip
    # panel inset on the top face: dark plate + big amber reset button
    c = iso.P(0, 0, 19)
    cx, cy = int(c[0]), int(c[1])
    for y in range(-2, 3):
        for x in range(-6, 7):
            if abs(x) / 6 + abs(y) / 2.6 <= 1.0: P.put(cx + x, cy + y, 11)
    for y in range(-1, 2):
        for x in range(-3, 4):
            if abs(x) / 3.4 + abs(y) / 1.6 <= 1.0: P.put(cx + x, cy + y, 24)
    P.put(cx - 1, cy - 1, 26); P.put(cx, cy - 1, 25); P.put(cx - 2, cy, 25)
    # status lamps on the SW face
    a = iso.P(-0.2, 0.34, 11)
    for k in range(3):
        P.put(int(a[0]) + k * 3, int(a[1]) + k // 2 * 0 + (k * 1), (22, 25, 22)[k])
    return [L, P]


# ------------------------------------------------------------------ lever switch 24x32, pivot (12,28)
def lever(on):
    L = Layer(24, 32, 'Base_Housing')
    A = Layer(24, 32, 'Lever_And_Lamp')
    iso = Iso(L, (12, 28))
    iso.box(-0.3, -0.3, 0, 0.3, 0.3, 6, 13, 13, 12)                    # base plate
    iso.box(-0.2, -0.2, 6, 0.2, 0.2, 14, 14, 13, 12)                   # housing
    # slot on the top face (dark) then lever
    t = iso.P(0, 0, 14)
    cx, cy = int(t[0]), int(t[1])
    for x in range(-3, 4): A.put(cx + x, cy, 11)
    # lever stick: OFF = tilted back-left (down), ON = tilted forward-right (up)
    if on:
        tip = (cx + 5, cy - 11)
    else:
        tip = (cx - 5, cy - 6)
    A.line(cx, cy, tip[0], tip[1], 15); A.line(cx + 1, cy, tip[0] + 1, tip[1], 14)
    for dx in range(-1, 3):
        for dy in range(-2, 1):
            A.put(tip[0] + dx, tip[1] + dy, 24 if on else 22)
    A.put(tip[0], tip[1] - 1, 26 if on else 23)
    # indicator lamp on the SW face of the housing
    la = iso.P(-0.05, 0.2, 10)
    A.put(int(la[0]), int(la[1]), 26 if on else 22); A.put(int(la[0]) - 1, int(la[1]), 25 if on else 22)
    # blank badge plate on the SE face
    bp = iso.P(0.2, 0.0, 10)
    for k in range(3): A.put(int(bp[0]) - k // 2, int(bp[1]) - 1 + k, 12)
    ring(A, A.mask() | L.mask(), 0)
    # remove the ring cells that landed over base pixels (they belong to A layer only where empty in composite)
    return [L, A]


# ------------------------------------------------------------------ document clipboard 16x16, pivot (8,12)
def clipboard():
    L = Layer(16, 16, 'Board')
    P = Layer(16, 16, 'Paper')
    iso = Iso(L, (8, 12))
    iso.box(-0.2, -0.3, 0, 0.2, 0.3, 1, 13, 12, 11)     # board
    t = iso.P(0, 0, 1)
    cx, cy = int(t[0]), int(t[1])
    for y in range(-2, 3):
        for x in range(-5, 6):
            if abs(x) / 5.5 + abs(y) / 2.7 <= 1.0: P.put(cx + x, cy + y, 31)
    for x in range(-3, 3): P.put(cx + x, cy, 15)
    P.put(cx - 3, cy - 1, 14); P.put(cx - 1, cy + 1, 14)
    P.put(cx - 4, cy - 1, 25); P.put(cx - 5, cy, 25)   # clip
    ring(L, L.mask() | P.mask(), 0)
    return [L, P]


ASSETS = {
    # name -> (builder, layer names, w, h, category dir, state)
    'wall_corner_pillar': (corner_pillar, ['Pillar_Faces', 'Trim_And_Stripe'], 32, 64, 'environments', 'idle'),
    'archway_frame_n': (archway_n, ['Steel_Arch_Jambs'], 32, 64, 'environments', 'idle'),
    'wall_railing_iron': (railing, ['Iron_Rail'], 32, 48, 'environments', 'idle'),
    'prop_station_bench': (bench, ['Bench'], 48, 32, 'props', 'idle'),
    'prop_call_box_phone': (lambda: call_box(False), ['Casing', 'Handset_And_Lamp'], 24, 36, 'props', 'idle'),
    'prop_call_box_phone#ringing': (lambda: call_box(True), ['Casing', 'Handset_And_Lamp'], 24, 36, 'props', 'ringing'),
    'prop_reset_console': (reset_console, ['Console_Body', 'Panel_And_Button'], 32, 36, 'props', 'idle'),
    'prop_lever_switch#off': (lambda: lever(False), ['Base_Housing', 'Lever_And_Lamp'], 24, 32, 'props', 'off'),
    'prop_lever_switch#on': (lambda: lever(True), ['Base_Housing', 'Lever_And_Lamp'], 24, 32, 'props', 'on'),
    'prop_document_clipboard': (clipboard, ['Board', 'Paper'], 16, 16, 'props', 'idle'),
}

if __name__ == '__main__':
    ims = []
    for n, (fn, names, w, h, cat, st) in ASSETS.items():
        ims.append(to_image(composite(fn())))
    preview(ims, SCR + r'\props_prev.png', zoom=5)
    print('ok')
