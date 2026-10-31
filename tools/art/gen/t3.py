"""TLF-042 (art batch 3): remaining puzzle props, pocket watch, lever badges, PA horn."""
import math
from props import *


# ---------------------------------------------------------------- route board 48x56, pivot (24,50)
# State is derived from the two JunctionLever.relay_state values (scripts/puzzle/objects/junction_lever.gd):
#   state 0 = A:`loop`      + B:`niche`   (initial)      -> N-W and E-S pairings
#   state 1 = A:`uncoupled` + B:`niche`                  -> W-E and N-niche pairings
#   state 2 = A:`uncoupled` + B:`atrium`  (solved)       -> N-atrium straight through
def route_board(state):
    L = Layer(48, 56, 'Posts_And_Bezel'); S = Layer(48, 56, 'Index_Display')
    iso = Iso(L, (24, 50))
    for x in (-0.5, 0.5):
        iso.box(x - 0.05, -0.05, 0, x + 0.05, 0.05, 22, 13, 13, 12)       # posts
    iso.box(-0.72, -0.06, 20, 0.72, 0.06, 44, 15, 12, 13)                 # board housing (front = left face)
    face = lambda u, v: iso.P(u, 0.06, v)
    # dark screen inset
    poly = [face(-0.62, 23), face(0.62, 23), face(0.62, 41), face(-0.62, 41)]
    fill_poly(S, poly, lambda x, y: 0)
    nodes = {'N': (0.0, 39), 'W': (-0.42, 32), 'E': (0.42, 32), 'S': (0.0, 25)}
    links = {0: [('N', 'W'), ('E', 'S')], 1: [('W', 'E'), ('N', 'S')], 2: [('N', 'S')]}[state]
    for a, b in links:
        pa, pb = face(*nodes[a]), face(*nodes[b])
        S.line(pa[0], pa[1], pb[0], pb[1], 25)
    for k, (u, v) in nodes.items():
        p = face(u, v)
        on = any(k in l for l in links)
        S.rect(p[0] - 1, p[1] - 1, p[0] + 1, p[1], 26 if on else 13)
    # state pips (shape + count cue): state k lights k+1 of 3 squares
    for i in range(3):
        p = face(-0.5 + i * 0.12, 42.2)
        S.rect(p[0], p[1] - 1, p[0] + 1, p[1], 25 if i <= state else 12)
    ring(S, S.mask() | L.mask(), 0)
    return [L, S]


# ---------------------------------------------------------------- security gate 40x52, pivot (20,42)
def sec_gate(state):
    L = Layer(40, 52, 'Posts'); B = Layer(40, 52, 'Barrier_And_Lamp')
    iso = Iso(L, (20, 42))
    for y in (-0.85, 0.85):
        iso.box(-0.07, y - 0.07, 0, 0.07, y + 0.07, 30, 14, 13, 12)
        iso.box(-0.09, y - 0.09, 30, 0.09, y + 0.09, 33, 15, 14, 13)
    stripe = lambda x, y: 24 if ((x + y) // 3) % 2 == 0 else 11
    bi = Iso(B, (20, 42))
    if state == 'closed':
        for z in (8, 17, 26):
            bi.box(-0.04, -0.78, z, 0.04, 0.78, z + 3, 15, 13, stripe)
        lamp = (22, 24)
    else:
        for y0, y1 in ((-0.78, -0.55), (0.55, 0.78)):
            for z in (8, 17, 26):
                bi.box(-0.04, y0, z, 0.04, y1, z + 3, 15, 13, stripe)
        lamp = (25, 26)
    t = iso.P(0.0, 0.85, 33)
    B.rect(t[0] - 1, t[1] - 3, t[0] + 1, t[1] - 2, lamp[0]); B.put(t[0], t[1] - 3, lamp[1])
    ring(B, B.mask() | L.mask(), 0)
    return [L, B]


# ---------------------------------------------------------------- bridge platform 48x32, pivot (24,18)
def bridge(state):
    L = Layer(48, 32, 'Deck'); A = Layer(48, 32, 'Edge_And_Lamps')
    iso = Iso(L, (24, 18))
    stripe = lambda x, y: 24 if ((x + y) // 3) % 2 == 0 else 11
    if state == 'extended':
        iso.box(-0.95, -0.5, 0, 0.95, 0.5, 4,
                lambda x, y: 14 if (x // 4) % 2 else 13, 13, 12)
        for k in range(5):
            p = iso.P(-0.7 + 0.35 * k, 0.5, 2)
            A.put(p[0], p[1], 25)                                   # guide lights along the near edge
        for xs in (-0.95, 0.75):
            a = iso.P(xs, -0.5, 4); b = iso.P(xs + 0.2, -0.5, 4)
            c = iso.P(xs, 0.5, 4)
            A.line(a[0], a[1], c[0], c[1], 24); A.line(b[0], b[1], iso.P(xs + 0.2, 0.5, 4)[0], iso.P(xs + 0.2, 0.5, 4)[1], 24)
    else:
        for x0, x1 in ((-0.95, -0.55), (0.55, 0.95)):
            iso.box(x0, -0.5, 0, x1, 0.5, 4, stripe, 13, 12)
        for x in (-0.75, 0.75):
            p = iso.P(x, 0.5, 2); A.put(p[0], p[1], 22)
    ring(A, A.mask() | L.mask(), 0)
    return [L, A]


# ---------------------------------------------------------------- stalled transit car 128x80, pivot (64,52)
def transit_car():
    L = Layer(128, 80, 'Car_Body'); D = Layer(128, 80, 'Windows_And_Livery')
    iso = Iso(L, (64, 52))
    X, Y = 2.5, 0.65
    iso.box(-X + 0.2, -Y + 0.1, 0, X - 0.2, Y - 0.1, 6, 12, 12, 11)         # skirt / bogie housing
    iso.box(-X, -Y, 6, X, Y, 26, 15, 13, 12)                                  # main body
    P = iso.P
    # SW (long) face livery + windows
    def sw(u, v): return P(u, Y, v)
    for u0 in (-2.1, -1.2, -0.3, 0.6, 1.5):
        poly = [sw(u0, 14), sw(u0 + 0.7, 14), sw(u0 + 0.7, 22), sw(u0, 22)]
        fill_poly(D, poly, lambda x, y: 0)
        inner = [sw(u0 + 0.05, 15), sw(u0 + 0.65, 15), sw(u0 + 0.65, 21), sw(u0 + 0.05, 21)]
        fill_poly(D, inner, lambda x, y: 27 if (x + y) % 5 else 28)
    for z in (9, 10):
        a, b = sw(-X + 0.05, z), sw(X - 0.05, z)
        D.line(a[0], a[1], b[0], b[1], 24)                                    # emergency stripe
    for u in (-2.2, 0.0, 2.2):
        a, b = sw(u, 6), sw(u, 26)
        D.line(a[0], a[1], b[0], b[1], 11)                                    # door/panel seams
    # SE (front, +x) face: windshield + dead headlights + destination board
    def se(v, z): return P(X, v, z)
    fill_poly(D, [se(-0.5, 13), se(0.5, 13), se(0.5, 23), se(-0.5, 23)], lambda x, y: 0)
    fill_poly(D, [se(-0.45, 14), se(0.45, 14), se(0.45, 22), se(-0.45, 22)], lambda x, y: 27 if (x + y) % 4 else 1)
    for v in (-0.5, 0.5):
        p = se(v, 8); D.rect(p[0] - 1, p[1] - 1, p[0] + 1, p[1], 22)
    p = se(0.0, 25); D.rect(p[0] - 3, p[1] - 1, p[0] + 3, p[1], 23)           # destination board, dark amber
    ring(D, D.mask() | L.mask(), 0)
    return [L, D]


# ---------------------------------------------------------------- dispatch terminal 64x64, pivot (32,56)
def dispatch(state):
    L = Layer(64, 64, 'Cabinet'); S = Layer(64, 64, 'Screen_And_Seal')
    iso = Iso(L, (32, 56))
    iso.box(-0.6, -0.3, 0, 0.6, 0.3, 24, 14, 13, 12)                          # cabinet
    iso.box(-0.5, -0.24, 24, 0.5, 0.24, 44, 13, 12, 11)                       # upper screen unit
    iso.box(-0.56, -0.28, 44, 0.56, 0.28, 47, 15, 14, 13)                     # cap
    P = iso.P
    fy = 0.24
    fill_poly(S, [P(-0.42, fy, 27), P(0.42, fy, 27), P(0.42, fy, 41), P(-0.42, fy, 41)], lambda x, y: 0)
    on = (state == 'active')
    rows = [(38, 0.36), (35, 0.30), (32, 0.34), (29, 0.22)]
    for v, ln in rows:
        a, b = P(-0.36, fy, v), P(-0.36 + ln, fy, v)
        S.line(a[0], a[1], b[0], b[1], 25 if on else 22)
    if on:
        p = P(-0.36, fy, 38); S.put(p[0], p[1], 26)
    # biometric seal pad on the cabinet top (concentric diamonds; lit teal when active)
    c = P(0.0, -0.05, 24)
    for r_, col in ((4, 29 if on else 12), (2, 31 if on else 11)):
        v = [(c[0] - 2 * r_, c[1]), (c[0], c[1] - r_), (c[0] + 2 * r_, c[1]), (c[0], c[1] + r_)]
        for i in range(4):
            S.line(v[i][0], v[i][1], v[(i + 1) % 4][0], v[(i + 1) % 4][1], col)
    S.put(c[0], c[1], 31 if on else 13)
    # keyboard strip on the SW face of the cabinet
    for k in range(6):
        p = P(-0.4 + k * 0.16, 0.3, 14)
        S.put(p[0], p[1], 15 if k % 2 else 14)
    ring(S, S.mask() | L.mask(), 0)
    return [L, S]


# ---------------------------------------------------------------- pocket watch pickup 16x16, pivot (8,12)
def pocket_watch():
    L = Layer(16, 16, 'Watch')
    c = (8, 10)
    for y in range(16):
        for x in range(16):
            dx, dy = (x + 0.5 - c[0]) / 5.6, (y + 0.5 - c[1]) / 3.3
            d = dx * dx + dy * dy
            if d <= 1.0:
                L.put(x, y, 25 if d > 0.52 else 26)
    L.put(7, 9, 0); L.put(8, 9, 0); L.put(8, 8, 0); L.put(9, 10, 0); L.put(10, 10, 0)     # hands
    for (x, y) in ((5, 9), (6, 10), (6, 11)): L.put(x, y, 22)                              # crack (damaged)
    L.put(12, 7, 25); L.put(13, 6, 25); L.put(13, 7, 26)                                    # crown
    for (x, y) in ((3, 12), (2, 13), (3, 14), (5, 14), (7, 14)): L.put(x, y, 26)           # loose chain
    ring(L, L.mask(), 0)
    return [L]


# ---------------------------------------------------------------- lever badges 5x7 overlays, pivot (2,3)
GLYPH = {'a': ['.#.', '#.#', '###', '#.#', '#.#'], 'b': ['##.', '#.#', '##.', '#.#', '##.']}


def badge(which):
    L = Layer(5, 7, 'Badge')
    L.rect(0, 0, 4, 6, 11)
    for j, row in enumerate(GLYPH[which]):
        for i, ch in enumerate(row):
            if ch == '#': L.put(1 + i, 1 + j, 26)
    return [L]


# ---------------------------------------------------------------- PA horn 16x16 (wall fixture), pivot (8,12)
def pa_horn():
    L = Layer(16, 16, 'Horn')
    L.rect(2, 12, 13, 13, 12)                                   # wall bracket
    L.rect(6, 9, 9, 11, 13)                                     # neck
    for y in range(2, 10):                                      # flared horn (frontal)
        half = 2 + (9 - y) // 2 + 1
        for x in range(8 - half, 8 + half):
            L.put(x, y, 14 if x < 8 else 13)
    for x in range(3, 13): L.put(x, 2, 15)
    for x in range(5, 11): L.put(x, 5, 11)                      # dark mouth
    ring(L, L.mask(), 0)
    return [L]


T3 = {
    'prop_route_board#0': (lambda: route_board(0), ['Posts_And_Bezel', 'Index_Display'], 48, 56, 'props', 'state0'),
    'prop_route_board#1': (lambda: route_board(1), ['Posts_And_Bezel', 'Index_Display'], 48, 56, 'props', 'state1'),
    'prop_route_board#2': (lambda: route_board(2), ['Posts_And_Bezel', 'Index_Display'], 48, 56, 'props', 'state2'),
    'prop_security_gate#closed': (lambda: sec_gate('closed'), ['Posts', 'Barrier_And_Lamp'], 40, 52, 'props', 'closed'),
    'prop_security_gate#open': (lambda: sec_gate('open'), ['Posts', 'Barrier_And_Lamp'], 40, 52, 'props', 'open'),
    'prop_bridge_platform#retracted': (lambda: bridge('retracted'), ['Deck', 'Edge_And_Lamps'], 48, 32, 'props', 'retracted'),
    'prop_bridge_platform#extended': (lambda: bridge('extended'), ['Deck', 'Edge_And_Lamps'], 48, 32, 'props', 'extended'),
    'prop_transit_car_stalled#x': (transit_car, ['Car_Body', 'Windows_And_Livery'], 128, 80, 'props', 'idle'),
    'prop_dispatch_terminal#idle': (lambda: dispatch('idle'), ['Cabinet', 'Screen_And_Seal'], 64, 64, 'props', 'idle'),
    'prop_dispatch_terminal#active': (lambda: dispatch('active'), ['Cabinet', 'Screen_And_Seal'], 64, 64, 'props', 'active'),
    'prop_pocket_watch#x': (pocket_watch, ['Watch'], 16, 16, 'props', 'idle'),
    'prop_lever_badge_a#x': (lambda: badge('a'), ['Badge'], 5, 7, 'props', 'idle'),
    'prop_lever_badge_b#x': (lambda: badge('b'), ['Badge'], 5, 7, 'props', 'idle'),
    'prop_pa_speaker#x': (pa_horn, ['Horn'], 16, 16, 'props', 'idle'),
}

if __name__ == '__main__':
    ims = [to_image(composite(fn())) for (fn, *_r) in T3.values()]
    preview(ims, os.path.join(SCR, 't3_prev.png'), zoom=4)
    print('ok')
