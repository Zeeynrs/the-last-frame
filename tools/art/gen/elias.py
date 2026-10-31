"""Elias 32x48 sheet builder v2. 5 authored dirs (s, se, e, ne, n) x (4 idle + 6 walk); 3 dirs mirrored by flip_h."""
from lib import *

W, H = 32, 48
O, SH = 0, 1
TR_D, TR_L = 2, 3                 # trousers (dark slate / mid)
CD, CS, CM, CL = 16, 17, 18, 19   # coat crease, shadow, mid, light
BD, BM = 16, 17                   # boot dark / highlight
SK_S, SK_L = 20, 21
BR, GOLD = 25, 26
HEM = 35
SYM = {'0': O, 'g': 16, 'h': 17, 'H': 18, 'l': 21, 'k': 20, '.': None}

HEADS = {
 's': [
  ".00000000.",
  "0HHHhhhhg0",
  "0HHhhhhhg0",
  "0hhhhhhgg0",
  "0hhllllggg"[:10],
  "0lllllkkk0",
  "0l0lllk0k0",
  "0lllllkkk0",
  "0llllkkkk0",
  ".0lllllkk.",
  "..000000..",
 ],
 'se': [
  ".00000000.",
  "0HHHhhhhg0",
  "0HHhhhhhg0",
  "0hhhhhhgg0",
  "0hhllllkg0",
  "0glllllkk0",
  "0kll0ll0k0",
  "0glllllkk0",
  "0glllllkk0",
  ".0gllllk0.",
  "..000000..",
 ],
 'e': [
  ".00000000.",
  "0HHHhhhhg0",
  "0HHhhhhhg0",
  "0hhhhhhhg0",
  "0hhhgllllk",
  "0hhhgll0lk",
  "0ghhgllllk",
  "0gghglllk0",
  "0ggggllk0.",
  ".0gggglk0.",
  "..000000..",
 ],
 'ne': [
  ".00000000.",
  "0HHHhhhhg0",
  "0HHhhhhhg0",
  "0hhhhhhhg0",
  "0hhhhhhhgk",
  "0hhhhhhggk",
  "0ghhhhgggk",
  "0gghhgggkk",
  "0ggggggkk0",
  ".0gggggk0.",
  "..000000..",
 ],
 'n': [
  ".00000000.",
  "0HHHhhhhg0",
  "0HHhHhhhg0",
  "0hhhhhhhg0",
  "0hhhhhhhg0",
  "0hhhhhhgg0",
  "0ghhhhhgg0",
  "0gghhhhgg0",
  "0ggggggggg"[:10],
  ".0gggggg0.",
  "..0kkkk0..",
 ],
}
for k, rows in HEADS.items():
    assert len(rows) == 11, k
    for r in rows:
        assert len(r) == 10, (k, r)


def stamp_head(layer, view, x0, y0):
    for j, row in enumerate(HEADS[view]):
        for i, ch in enumerate(row):
            c = SYM[ch]
            if c is not None:
                layer.put(x0 + i, y0 + j, c)


def part(layer, pix, outline=True):
    if outline:
        for (x, y) in pix:
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if (nx, ny) not in pix:
                    layer.put(nx, ny, O)
    for (x, y), c in pix.items():
        layer.put(x, y, c)


def rows_to_pix(rows, colfn):
    pix = {}
    for (y, x0, x1) in rows:
        for x in range(x0, x1 + 1):
            pix[(x, y)] = colfn(x, y, x0, x1)
    return pix


def coat_col(x, y, x0, x1):
    n = x1 - x0 + 1
    u = (x - x0) / max(1, n - 1)
    if u < 0.2: return CL
    if u < 0.6: return CM
    if u < 0.9: return CS
    return CD


def shadow_ellipse(layer, cx, cy, rx, ry, c=SH):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                layer.put(x, y, c)


# ---------------------------------------------------------------- legs
def leg_front(x0, y_top, y_sole, toe=0, lit=True):
    """Front/back view leg: 3px trouser column + boot with optional toe widening. y_sole = ground-line row."""
    pix = {}
    y_boot = y_sole - 3
    for y in range(y_top, y_boot):
        for i in range(3):
            pix[(x0 + i, y)] = TR_L if (i == 0 and lit) else TR_D
    for y in range(y_boot, y_sole):
        for i in range(3 + toe):
            c = BD
            if y == y_boot: c = BM
            elif i == 0 and lit: c = BM
            pix[(x0 + i, y)] = c
    return pix


def leg_side(hx, y_top, ax, y_sole, far=False, boot_len=5):
    """Side/diagonal leg: trouser line hip->ankle, boot extending toward +x."""
    pix = {}
    y_boot = y_sole - 3
    n = max(1, y_boot - y_top)
    for y in range(y_top, y_boot):
        t = (y - y_top) / n
        cx = round(hx + (ax - hx) * t)
        for i in (-1, 0, 1):
            pix[(cx + i, y)] = TR_L if (i == -1 and not far) else TR_D
    for y in range(y_boot, y_sole):
        for i in range(boot_len):
            c = BD
            if y == y_boot: c = BM
            elif i == 0 and not far: c = BM
            pix[(ax - 1 + i, y)] = c
    return pix


def arm_pix(sx, sy, hx, hy, far=False, hand_lit=True):
    pix = {}
    n = max(1, hy - sy)
    for y in range(sy, hy):
        t = (y - sy) / n
        cx = round(sx + (hx - sx) * t)
        for i in range(2):
            if far:
                c = CS if i == 0 else CD
            else:
                c = CL if i == 0 else CM
            if y == hy - 1: c = CD if far else CS    # cuff
            pix[(cx + i, y)] = c
    for y in range(hy, hy + 3):
        pix[(hx, y)] = SK_L if hand_lit else SK_S
        pix[(hx + 1, y)] = SK_S
    return pix


def finish(sh, bc, ha):
    """Auto 1px silhouette outline (4-neighbour) around everything opaque, on the body layer."""
    m = {p for p in (bc.mask() | ha.mask()) if (bc.get(*p) != O and ha.get(*p) != O) or (ha.get(*p) not in (None, O)) or (bc.get(*p) not in (None, O))}
    m = {p for p in m if (ha.get(*p) if ha.get(*p) is not None else bc.get(*p)) != O}
    for (x, y) in m:
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in m and 0 <= nx < W and 0 <= ny < H:
                bc.put(nx, ny, O)


def render(view, pose):
    sh = Layer(W, H, 'Cast_Shadow')
    bc = Layer(W, H, 'Boots_And_Coat')
    ha = Layer(W, H, 'Head_Arms_And_Watch_Chain')
    shadow_ellipse(sh, 17.0, 44.5, 7.0, 2.6)
    fn = {'s': _front, 'n': _front, 'e': _side, 'se': _diag, 'ne': _diag}[view]
    fn(view, pose, sh, bc, ha, pose.get('bob', 0))
    finish(sh, bc, ha)
    return sh, bc, ha


def _hem_line(coat, rows, b):
    y = HEM + b
    for x in range(rows[-1][1], rows[-1][2] + 1):
        coat[(x, y)] = CD


def _top_plane(coat, b, x0, x1):
    for x in range(x0, x1 + 1):
        if (x, 14 + b) in coat:
            coat[(x, 14 + b)] = CL if x < (x0 + x1) / 2 else CM


# ---- front / back
def _front(view, pose, sh, bc, ha, b):
    back = (view == 'n')
    Ls, Rs = pose['L'], pose['R']
    fl_l, fl_r = pose.get('fl', (0, 0))
    ahl, ahr = pose.get('arms', (0, 0))
    for y in range(HEM + 1 + b, 41):
        for x in range(14, 18):
            bc.put(x, y, SH)
    left = leg_front(11, HEM + 1 + b - 1, Ls, toe=1 if Ls >= 45 else 0, lit=True)
    right = leg_front(18, HEM + 1 + b - 1, Rs, toe=1 if Rs >= 45 else 0, lit=False)
    for pix in ((right, left) if Ls >= Rs else (left, right)):
        pass
    # draw the lifted (further back) foot first
    first, second = (right, left) if Ls >= Rs else (left, right)
    part(bc, first)
    part(bc, second)
    rows = [(14 + b, 11, 20)]
    for y in range(15, 27): rows.append((y + b, 10, 21))
    flare = [(27, 10, 21), (28, 10, 21), (29, 10, 21), (30, 9, 22), (31, 9, 22),
             (32, 9, 22), (33, 9, 22), (34, 8, 23), (35, 8, 23)]
    for (y, x0, x1) in flare:
        t = (y - 27) / 8.0
        rows.append((y + b, x0 - round(fl_l * t), x1 + round(fl_r * t)))
    coat = rows_to_pix(rows, coat_col)
    for x in range(10, 22): coat[(x, 25 + b)] = CS if x < 15 else CD       # belt
    _hem_line(coat, rows, b)
    for y in range(19 + b, HEM + b):
        if y != 25 + b and (16, y) in coat: coat[(16, y)] = CD         # front seam / back seam
    if back:
        for x in range(10, 22): coat[(x, 19 + b)] = CS                 # yoke
        for y in range(28 + b, HEM + b): coat[(15, y)] = CD; coat[(16, y)] = CS   # vent
        for y in range(15 + b, 19 + b): coat[(15, y)] = CS
    else:
        for x in range(13, 19): coat[(x, 14 + b)] = 2
        for x in range(14, 18): coat[(x, 15 + b)] = 2
        for y in range(16, 20): coat[(15, y + b)] = 2; coat[(16, y + b)] = 2
        coat[(13, 15 + b)] = CL; coat[(12, 16 + b)] = CL; coat[(12, 17 + b)] = CM; coat[(13, 18 + b)] = CM
        coat[(18, 15 + b)] = CM; coat[(19, 16 + b)] = CS; coat[(19, 17 + b)] = CS; coat[(18, 18 + b)] = CS
    if not back:
        _top_plane(coat, b, 11, 20)
    else:
        _top_plane(coat, b, 11, 20)
    part(bc, coat)
    la = arm_pix(9, 15 + b, 9, 25 + b + ahl, hand_lit=True)
    ra = arm_pix(21, 15 + b, 21, 25 + b + ahr, hand_lit=False)
    for k, c in list(ra.items()):
        if c == CL: ra[k] = CS
        elif c == CM: ra[k] = CD
    part(ha, la)
    part(ha, ra)
    if not back:
        ha.put(12, 25 + b, BR); ha.put(13, 26 + b, GOLD); ha.put(14, 26 + b, BR); ha.put(15, 25 + b, GOLD)
    stamp_head(ha, view, 11, 3 + b)


# ---- side
def _side(view, pose, sh, bc, ha, b):
    fl = pose.get('fl', 0)
    aN, aF = pose.get('arm_near', 0), pose.get('arm_far', 0)
    (dxN, sN), (dxF, sF) = pose['near'], pose['far']
    hx = 15
    far_leg = leg_side(hx, HEM + 1 + b - 1, hx + dxF, sF, far=True)
    near_leg = leg_side(hx, HEM + 1 + b - 1, hx + dxN, sN, far=False)
    farm = arm_pix(15, 15 + b, 15 + aF, 25 + b - abs(aF) // 2, far=True, hand_lit=False)
    part(bc, farm)
    part(bc, far_leg)
    part(bc, near_leg)
    rows = [(14 + b, 12, 19)]
    for y in range(15, 27): rows.append((y + b, 11, 20))
    back_edge = [11, 11, 10, 10, 10, 9, 9, 9, 9]
    front_edge = [20, 20, 20, 20, 21, 21, 21, 21, 21]
    for k, y in enumerate(range(27, 36)):
        t = k / 8.0
        rows.append((y + b, back_edge[k] - round(fl * t), front_edge[k]))
    coat = rows_to_pix(rows, coat_col)
    for x in range(11, 21): coat[(x, 25 + b)] = CD if x > 12 else CS
    _hem_line(coat, rows, b)
    for y in range(16 + b, 23 + b): coat[(19, y)] = CS
    for x in range(15, 18): coat[(x, 28 + b)] = CS
    for y in range(29 + b, HEM + b): coat[(rows[-1][1] + 2, y)] = CS
    coat.pop((21, HEM + b), None); coat.pop((20, HEM + b), None)     # front hem notch (coat parts at the stride)
    for x in range(15, 19): coat[(x, 14 + b)] = 2
    coat[(17, 15 + b)] = 2; coat[(18, 15 + b)] = 2
    _top_plane(coat, b, 12, 19)
    part(bc, coat)
    narm = arm_pix(14, 15 + b, 14 + aN, 25 + b - abs(aN) // 2, hand_lit=True)
    part(ha, narm)
    ha.put(19, 25 + b, BR); ha.put(19, 26 + b, GOLD); ha.put(18, 26 + b, BR)
    stamp_head(ha, 'e', 11, 3 + b)


# ---- diagonals
def _diag(view, pose, sh, bc, ha, b):
    ne = (view == 'ne')
    fl = pose.get('fl', 0)
    aN, aF = pose.get('arm_near', 0), pose.get('arm_far', 0)
    (dxN, sN), (dxF, sF) = pose['near'], pose['far']
    hxN, hxF = 13, 18
    far_leg = leg_side(hxF, HEM + 1 + b - 1, hxF + dxF, sF, far=True, boot_len=4)
    near_leg = leg_side(hxN, HEM + 1 + b - 1, hxN + dxN, sN, far=False, boot_len=4)
    farm = arm_pix(20, 15 + b, 20 + aF, 25 + b - abs(aF) // 2, far=True, hand_lit=False)
    part(bc, farm)
    part(bc, far_leg)
    part(bc, near_leg)
    rows = [(14 + b, 11, 20)]
    for y in range(15, 27): rows.append((y + b, 10, 21))
    le = [10, 10, 9, 9, 9, 8, 8, 8, 8]
    re_ = [21, 21, 22, 22, 22, 22, 22, 22, 22]
    for k, y in enumerate(range(27, 36)):
        t = k / 8.0
        rows.append((y + b, le[k] - round(fl * t), re_[k]))
    coat = rows_to_pix(rows, coat_col)
    for x in range(10, 22): coat[(x, 25 + b)] = CD if x > 12 else CS
    _hem_line(coat, rows, b)
    if ne:
        for y in range(28 + b, HEM + b): coat[(15, y)] = CD; coat[(16, y)] = CS
        for x in range(10, 22): coat[(x, 19 + b)] = CS
    else:
        for y in range(19 + b, HEM + b):
            if y != 25 + b: coat[(17, y)] = CD
        for x in range(14, 19): coat[(x, 14 + b)] = 2
        coat[(16, 15 + b)] = 2; coat[(17, 15 + b)] = 2; coat[(16, 16 + b)] = 2; coat[(16, 17 + b)] = 2
        coat[(14, 15 + b)] = CL; coat[(13, 16 + b)] = CL; coat[(14, 17 + b)] = CM
    _top_plane(coat, b, 11, 20)
    part(bc, coat)
    narm = arm_pix(9, 15 + b, 9 + aN, 25 + b - abs(aN) // 2, hand_lit=True)
    part(ha, narm)
    if not ne:
        ha.put(13, 25 + b, BR); ha.put(14, 26 + b, GOLD); ha.put(15, 26 + b, BR)
    stamp_head(ha, view, 11, 3 + b)
