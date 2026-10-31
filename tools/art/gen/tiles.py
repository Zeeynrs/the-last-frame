"""Floor tiles 32x16 (batch 2). Same diamond mask / 2px edge bands as batch 1."""
from lib import *
import math


def diamond_rows():
    """yield (y, xl, xr) inclusive for the 32x16 diamond (batch-1 shape)."""
    for y in range(16):
        yy = y if y < 8 else 15 - y
        xl = 14 - 2 * yy
        yield y, xl, 31 - xl


def uv(x, y):
    """iso axis coords of pixel centre: u along +x tile axis (down-right), v along +y (down-left); 0..1 inside."""
    dx, dy = (x + 0.5 - 16) / 16.0, (y + 0.5 - 8) / 8.0
    return (dx + dy) / 2 + 0.5, (dy - dx) / 2 + 0.5


def base_tile(name, fill, rim=(4, 3, 1, 1)):
    """fill(x,y,u,v)->palette idx. rim=(NW band, NE band, SW band, SE band) colours (None = keep fill)."""
    L = Layer(32, 16, name)
    for y, xl, xr in diamond_rows():
        for x in range(xl, xr + 1):
            u, v = uv(x, y)
            c = fill(x, y, u, v)
            top = y < 8
            if x - xl < 2:
                r = rim[0] if top else rim[2]
                if r is not None: c = r
            elif xr - x < 2:
                r = rim[1] if top else rim[3]
                if r is not None: c = r
            L.put(x, y, c)
    return L


def hash2(x, y, s=0):
    n = (x * 374761393 + y * 668265263 + s * 2147483647) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return (n ^ (n >> 16)) & 0xFFFF


# ---- 1. industrial grating (rooms 3, 4, 6)
def grating():
    def fill(x, y, u, v):
        fu, fv = (u * 4) % 1.0, (v * 4) % 1.0
        bar_u, bar_v = fu < 0.30, fv < 0.30
        if bar_u and bar_v: return 14                  # crossing node, brightest
        if bar_u or bar_v:
            return 13 if (bar_u and fv > 0.5) or (bar_v and fu > 0.5) else 12
        return 0 if hash2(x, y) % 5 else 1             # void below the grate
    L = base_tile('Grating', fill, rim=(14, 13, 11, 11))
    return [L]


# ---- 2. concrete service (rooms 3, 4, 6)
def concrete():
    def fill(x, y, u, v):
        h = hash2(x, y, 3) % 23
        c = 12
        if h == 0: c = 13
        elif h == 1: c = 11
        elif h == 2 and (u + v) < 1.0: c = 13
        # expansion joint across the middle (along v axis)
        if abs(u - 0.5) < 0.035: c = 11
        # faded floor stencil: dashed hazard line along u axis near v=0.78
        if abs(v - 0.78) < 0.04 and int(u * 8) % 2 == 0: c = 13
        return c
    L = base_tile('Concrete_Slab', fill, rim=(13, 12, 11, 11))
    return [L]


# ---- 3/4. cable conduit (rooms 3, 4, 6, 7): steel cover plate along the u axis with [>>>] chevrons
def conduit(on):
    def chev_d(u, v, k):
        uc = 0.24 + 0.26 * k
        dv = abs(v - 0.5)
        if dv > 0.15: return None
        return (uc + 0.09 - 1.0 * dv) - u
    def fill(x, y, u, v):
        c = 2
        if hash2(x, y, 5) % 19 == 0: c = 3
        dv = abs(v - 0.5)
        if dv < 0.2:
            c = 11 if on else 13
            if dv > 0.16: c = 14 if v < 0.5 else 11     # plate bevel, NW side lit
            elif dv < 0.2 and not on and hash2(x, y, 2) % 11 == 0: c = 12
            for k in range(3):
                d = chev_d(u, v, k)
                if d is not None and 0 <= d < 0.075:
                    c = (25 if d > 0.02 else 26) if on else 11
        return c
    L = base_tile('Conduit_Plate', fill, rim=(4, 3, 1, 1))
    return [L]


# ---- 5. wet stone step (rooms 9, 10)
def stone_step():
    def fill(x, y, u, v):
        c = 3
        h = hash2(x, y, 9) % 17
        if h == 0: c = 4
        elif h == 1: c = 2
        # step nosing: lit lip along the NW (v~0) and NE (u~0) edges
        if v < 0.16: c = 4
        # mortar joint between slabs
        if abs(u - 0.55) < 0.03: c = 1
        # wet sheen: horizontal glint streaks
        if (y in (5, 9)) and 8 < x < 15: c = 5
        if (y == 7) and 20 < x < 25: c = 5
        if (y == 11) and 12 < x < 16: c = 4
        return c
    L = base_tile('Wet_Stone_Step', fill, rim=(5, 4, 1, 1))
    return [L]


TILES = {
    'tile_industrial_grating': (grating, ['Grating']),
    'tile_concrete_service': (concrete, ['Concrete_Slab']),
    'tile_cable_conduit_off': (lambda: conduit(False), ['Conduit_Plate']),
    'tile_cable_conduit_on': (lambda: conduit(True), ['Conduit_Plate']),
    'tile_stone_step_wet': (stone_step, ['Wet_Stone_Step']),
}

if __name__ == '__main__':
    ims = []
    for n, (fn, names) in TILES.items():
        ls = fn()
        ims.append(to_image(composite(ls)))
    # add existing for comparison
    for e in ['terrazzo_dark', 'terrazzo_cracked', 'tactile_amber']:
        ims.append(Image.open(REPO + rf'\assets\environments\ch01\ch01_env_tile_{e}_idle.png').convert('RGBA'))
    preview(ims, SCR + r'\tiles_prev.png', zoom=8)
    # assembled 6x4 floor
    sh = Image.new('RGBA', (640, 200), (10, 13, 20, 255))
    order = ['tile_industrial_grating', 'tile_concrete_service', 'tile_cable_conduit_off', 'tile_cable_conduit_on', 'tile_stone_step_wet']
    for ty in range(6):
        for tx in range(6):
            n = order[(tx + ty) % 5]
            fn, _ = TILES[n]
            im = to_image(composite(fn()))
            sh.alpha_composite(im, (320 + (tx - ty) * 16 - 16, 10 + (tx + ty) * 8))
    sh.resize((1280, 400), Image.NEAREST).save(SCR + r'\tiles_area.png')
    print('ok')
