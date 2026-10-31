"""Tier 2 hero set-pieces (subset): turnstile, fire shutter, counterweight gear, surge capacitor, pressure switch."""
import math
from props import *


def brackets(L, x0, y0, x1, y1, c=31):
    """2px L-brackets on four corners (Freeze language, bible §7)."""
    for (cx, cy, sx, sy) in ((x0, y0, 1, 1), (x1, y0, -1, 1), (x0, y1, 1, -1), (x1, y1, -1, -1)):
        for k in range(4):
            for t in range(2):
                L.put(cx + sx * k, cy + sy * t, c)
                L.put(cx + sx * t, cy + sy * k, c)


# ---------------------------------------------------------------- turnstile gate 32x40, pivot (16,34)
def turnstile(state):
    L = Layer(32, 40, 'Pedestal'); A = Layer(32, 40, 'Arm_And_Lamp')
    iso = Iso(L, (16, 34))
    iso.box(-0.3, -0.3, 0, 0.3, 0.3, 4, 12, 12, 11)
    iso.box(-0.22, -0.22, 4, 0.22, 0.22, 20, 14, 13, 12)
    iso.box(-0.26, -0.26, 20, 0.26, 0.26, 23, 15, 14, 13)
    t = iso.P(0, 0, 23)
    if state == 'open':
        # arm folded up along the housing, lamp lit
        for k in range(0, 13):
            A.put(t[0], t[1] - k, 15); A.put(t[0] + 1, t[1] - k, 13)
        A.rect(t[0] - 1, t[1] - 15, t[0] + 2, t[1] - 13, 25); A.put(t[0], t[1] - 15, 26)
        lamp = (26, 25)
    else:
        # collapsed: arm snapped, hanging to the floor, bent; lamp dead
        A.line(t[0] + 1, t[1], t[0] + 6, t[1] + 7, 13); A.line(t[0] + 2, t[1], t[0] + 7, t[1] + 7, 12)
        A.line(t[0] + 6, t[1] + 7, t[0] + 11, t[1] + 9, 12); A.line(t[0] + 6, t[1] + 8, t[0] + 11, t[1] + 10, 11)
        A.put(t[0] + 11, t[1] + 9, 24); A.put(t[0] + 12, t[1] + 9, 22)
        lamp = (22, 22)
    la = iso.P(-0.05, 0.22, 14)
    A.put(la[0], la[1], lamp[0]); A.put(la[0] - 1, la[1], lamp[1])
    ring(A, A.mask() | L.mask(), 0)
    return [L, A]


# ---------------------------------------------------------------- fire shutter 64x64, pivot (32,56)
def shutter(state):
    L = Layer(64, 64, 'Frame'); S = Layer(64, 64, 'Slats')
    iso = Iso(L, (32, 56))
    X = 0.82; Y = 0.08
    iso.box(-X - 0.1, -Y, 0, -X, Y, 54, 14, 13, 12)             # left post
    iso.box(X, -Y, 0, X + 0.1, Y, 54, 14, 13, 12)               # right post
    iso.box(-X - 0.1, -Y - 0.04, 42, X + 0.1, Y + 0.04, 54, 15, 14, 13)   # lintel / roller housing
    if state == 'closed':
        P = iso.P
        poly = [P(-X, Y, 0), P(X, Y, 0), P(X, Y, 42), P(-X, Y, 42)]
        def col(x, y):
            z = (poly[0][1] + (poly[1][1] - poly[0][1]) * ((x - poly[0][0]) / max(1, poly[1][0] - poly[0][0])) - y)
            if z < 5: return 24 if ((x + y) // 3) % 2 == 0 else 11     # hazard band
            c = 13 if int(z) % 4 else 11
            if x < poly[0][0] + 3: c = 14
            return c
        fill_poly(S, poly, col)
        ring(S, S.mask() | L.mask(), 0)
        # handle plate
        h = P(0.0, Y, 14); S.rect(h[0] - 2, h[1] - 1, h[0] + 2, h[1] + 1, 12); S.put(h[0], h[1], 25)
    else:
        # raised: slats rolled into the housing; only a hazard-striped bottom bar hangs under the lintel
        P = iso.P
        poly = [P(-X, Y, 36), P(X, Y, 36), P(X, Y, 42), P(-X, Y, 42)]
        fill_poly(S, poly, lambda x, y: 24 if ((x + y) // 3) % 2 == 0 else 11)
        ring(S, S.mask() | L.mask(), 0)
    return [L, S]


# ---------------------------------------------------------------- counterweight gear 64x64, pivot (32,56)
def gear(state):
    L = Layer(64, 64, 'Housing'); G = Layer(64, 64, 'Gear_And_Weight'); F = Layer(64, 64, 'State_Overlay')
    iso = Iso(L, (32, 56))
    iso.box(-0.9, -0.1, 0, 0.9, 0.1, 6, 12, 12, 11)               # base rail
    iso.box(-0.9, -0.1, 6, -0.75, 0.1, 50, 14, 13, 12)            # left upright
    iso.box(0.75, -0.1, 6, 0.9, 0.1, 50, 14, 13, 12)              # right upright
    iso.box(-0.9, -0.1, 50, 0.9, 0.1, 54, 15, 14, 13)             # top beam
    P = iso.P
    yp = 0.1
    cu, cz, R = 0.0, 30, 11
    rot = {'idle': 0.0, 'slipping': 0.35, 'frozen': 0.0}[state]
    pts = []
    N = 96
    for i in range(N):
        t = i / N * 2 * math.pi
        rr = R + (3 if (int(i / 4 + rot * 3) % 2 == 0) else 0)       # 12 teeth
        pts.append((cu + (rr / 16.0) * math.cos(t + rot) * 1.0, cz + rr * math.sin(t + rot)))
    poly = [P(u, yp + 0.02, z) for (u, z) in pts]
    body = 14 if state != 'frozen' else 15
    fill_poly(G, poly, lambda x, y: body)
    # hub + spokes
    hub = P(0, yp + 0.02, cz)
    G.rect(hub[0] - 2, hub[1] - 1, hub[0] + 2, hub[1] + 1, 12)
    for k in range(4):
        a = k * math.pi / 2 + rot
        e = P(0.6 * math.cos(a) * 0.6, yp + 0.02, cz + 9 * math.sin(a))
        G.line(hub[0], hub[1], e[0], e[1], 11)
    G.put(hub[0] - 1, hub[1] - 1, 15)
    # counterweight block hanging on the right upright
    drop = {'idle': 0, 'slipping': 6, 'frozen': 3}[state]
    w0 = P(0.82, yp + 0.04, 0)
    iso.box(0.62, -0.12, 14 - drop, 0.92, 0.14, 30 - drop, 14, 12, 11)
    zc = P(0.77, 0.1, 30 - drop)
    G.line(zc[0], zc[1], P(0.77, 0.1, 50)[0], P(0.77, 0.1, 50)[1], 11)
    if state == 'slipping':
        for (dx, dy) in ((-18, -4), (-21, 1), (-16, 6), (19, -6), (22, 0)):
            F.put(hub[0] + dx, hub[1] + dy, 26); F.put(hub[0] + dx + 1, hub[1] + dy + 1, 25)
        for k in range(3):     # slip marks on the teeth
            F.put(hub[0] + 14 - k * 2, hub[1] - 13 + k, 24)
    if state == 'frozen':
        brackets(F, 2, 6, 61, 61, 31)
        for k in range(0, 60, 4):
            F.put(2 + k, 5, 27); F.put(2 + k, 62, 27)
        F.put(hub[0], hub[1], 31)
    ring(G, G.mask() | L.mask(), 0)
    return [L, G, F]


# ---------------------------------------------------------------- surge capacitor 64x64, pivot (32,56)
def capacitor(state):
    L = Layer(64, 64, 'Base_And_Cabinet'); C = Layer(64, 64, 'Capacitor_Cells'); F = Layer(64, 64, 'State_Overlay')
    iso = Iso(L, (32, 56))
    iso.box(-0.85, -0.55, 0, 0.85, 0.55, 8, 13, 12, 11)           # plinth
    iso.box(-0.8, -0.5, 8, 0.8, -0.2, 40, 14, 13, 12)             # back cabinet wall
    cols = {'discharged': (12, 13, 11), 'charged': (13, 14, 12), 'frozen': (13, 14, 12),
            'frozen_charged': (13, 14, 12), 'frozen_discharged': (13, 14, 12)}[state]
    fz = state.startswith('frozen_')
    for k, x in enumerate((-0.52, 0.0, 0.52)):
        iso.box(x - 0.16, -0.12, 8, x + 0.16, 0.2, 38, cols[1], cols[0], cols[2])
        # terminal cap
        t = iso.P(x, 0.04, 38)
        C.rect(t[0] - 1, t[1] - 2, t[0] + 1, t[1], 15)
        if fz:
            # fill-level gauge on the SW face of each cell (TLF-044): the charge reads from the FILL HEIGHT,
            # not from colour. Dark inset tube; frost fill rises from the bottom: full (charged) vs a 2 px sliver.
            top_fill = 34 if state == 'frozen_charged' else 11
            tube = [iso.P(x - 0.12, 0.2, 10), iso.P(x + 0.12, 0.2, 10), iso.P(x + 0.12, 0.2, 35), iso.P(x - 0.12, 0.2, 35)]
            fill_poly(C, tube, lambda xx, yy: 1)
            lvl = [iso.P(x - 0.12, 0.2, 10), iso.P(x + 0.12, 0.2, 10), iso.P(x + 0.12, 0.2, top_fill), iso.P(x - 0.12, 0.2, top_fill)]
            fill_poly(C, lvl, lambda xx, yy: 31 if xx % 2 == 0 else 15)
            for z in (16, 22, 28):                      # gauge ticks (same in both states)
                a = iso.P(x - 0.16, 0.2, z)
                C.put(a[0], a[1], 15)
            continue
        # glow bands
        for z in (16, 26, 34):
            a = iso.P(x - 0.16, 0.2, z); b = iso.P(x + 0.16, 0.2, z)
            if state == 'charged':
                C.line(a[0], a[1], b[0], b[1], 25); C.put(a[0] + 2, a[1] + 1, 26)
            else:
                C.line(a[0], a[1], b[0], b[1], 22 if state == 'discharged' else 27)
    if state == 'charged':
        # arc between terminals (non-colour cue: jagged line, plus lit bands)
        a = iso.P(-0.52, 0.04, 40); b = iso.P(0.0, 0.04, 40); c = iso.P(0.52, 0.04, 40)
        for p0, p1 in ((a, b), (b, c)):
            mx = (p0[0] + p1[0]) // 2
            F.line(p0[0], p0[1], mx, p0[1] - 4, 26); F.line(mx, p0[1] - 4, p1[0], p1[1], 26)
            F.put(mx, p0[1] - 5, 31)
    if state in ('frozen', 'frozen_charged', 'frozen_discharged'):
        brackets(F, 2, 6, 61, 61, 31)
        for k in range(0, 60, 4):
            F.put(2 + k, 5, 27); F.put(2 + k, 62, 27)
    if fz:
        # crystal glyph above the terminals: SOLID hexagon = stabilised (charged), HOLLOW outline = empty
        cx, cy = 32, 12
        hexv = [(cx - 6, cy), (cx - 3, cy - 5), (cx + 3, cy - 5), (cx + 6, cy), (cx + 3, cy + 5), (cx - 3, cy + 5)]
        if state == 'frozen_charged':
            fill_poly(F, [(a + 0.0, b + 0.0) for a, b in hexv], lambda xx, yy: 31)
            F.put(cx, cy, 27); F.put(cx - 1, cy, 27)
        for i in range(6):
            p0, p1 = hexv[i], hexv[(i + 1) % 6]
            F.line(p0[0], p0[1], p1[0], p1[1], 31)
        # bridge between the terminals: RIGID straight bar when charged, none (open gap) when discharged
        if state == 'frozen_charged':
            a = iso.P(-0.52, 0.04, 40); b = iso.P(0.0, 0.04, 40); c = iso.P(0.52, 0.04, 40)
            F.line(a[0], a[1], c[0], c[1], 31); F.line(a[0], a[1] + 1, c[0], c[1] + 1, 15)
    ring(C, C.mask() | L.mask(), 0)
    return [L, C, F]


# ---------------------------------------------------------------- pressure switch 32x20, pivot (16,12)
def pswitch(state):
    L = Layer(32, 20, 'Plate'); A = Layer(32, 20, 'Lamp_Ring')
    iso = Iso(L, (16, 12))
    if state == 'released':
        iso.box(-0.42, -0.42, 0, 0.42, 0.42, 3, 14, 13, 12)
        A.put(16, 5, 22)
    else:
        iso.box(-0.42, -0.42, 0, 0.42, 0.42, 1, 13, 12, 11)
        A.put(16, 8, 26)
    c = iso.P(0, 0, 3 if state == 'released' else 1)
    for y in range(-2, 3):
        for x in range(-7, 8):
            if abs(x) / 7.5 + abs(y) / 3.2 <= 1.0 and abs(x) / 7.5 + abs(y) / 3.2 > 0.55:
                A.put(c[0] + x, c[1] + y, 24 if state == 'pressed' else 12)
    if state == 'pressed':
        for x in (-4, 0, 4): A.put(c[0] + x, c[1], 25)
    ring(L, L.mask() | A.mask(), 0)
    return [L, A]


T2 = {
    'prop_turnstile_gate#collapsed': (lambda: turnstile('collapsed'), ['Pedestal', 'Arm_And_Lamp'], 32, 40, 'props', 'collapsed'),
    'prop_turnstile_gate#open': (lambda: turnstile('open'), ['Pedestal', 'Arm_And_Lamp'], 32, 40, 'props', 'open'),
    'prop_fire_shutter#closed': (lambda: shutter('closed'), ['Frame', 'Slats'], 64, 64, 'props', 'closed'),
    'prop_fire_shutter#raised': (lambda: shutter('raised'), ['Frame', 'Slats'], 64, 64, 'props', 'raised'),
    'prop_counterweight_gear#idle': (lambda: gear('idle'), ['Housing', 'Gear_And_Weight', 'State_Overlay'], 64, 64, 'props', 'idle'),
    'prop_counterweight_gear#slipping': (lambda: gear('slipping'), ['Housing', 'Gear_And_Weight', 'State_Overlay'], 64, 64, 'props', 'slipping'),
    'prop_counterweight_gear#frozen': (lambda: gear('frozen'), ['Housing', 'Gear_And_Weight', 'State_Overlay'], 64, 64, 'props', 'frozen'),
    'prop_surge_capacitor#discharged': (lambda: capacitor('discharged'), ['Base_And_Cabinet', 'Capacitor_Cells', 'State_Overlay'], 64, 64, 'props', 'discharged'),
    'prop_surge_capacitor#charged': (lambda: capacitor('charged'), ['Base_And_Cabinet', 'Capacitor_Cells', 'State_Overlay'], 64, 64, 'props', 'charged'),
    'prop_surge_capacitor#frozen_charged': (lambda: capacitor('frozen_charged'), ['Base_And_Cabinet', 'Capacitor_Cells', 'State_Overlay'], 64, 64, 'props', 'frozen_charged'),
    'prop_surge_capacitor#frozen_discharged': (lambda: capacitor('frozen_discharged'), ['Base_And_Cabinet', 'Capacitor_Cells', 'State_Overlay'], 64, 64, 'props', 'frozen_discharged'),
    'prop_surge_capacitor#frozen': (lambda: capacitor('frozen'), ['Base_And_Cabinet', 'Capacitor_Cells', 'State_Overlay'], 64, 64, 'props', 'frozen'),
    'prop_pressure_switch#released': (lambda: pswitch('released'), ['Plate', 'Lamp_Ring'], 32, 20, 'props', 'released'),
    'prop_pressure_switch#pressed': (lambda: pswitch('pressed'), ['Plate', 'Lamp_Ring'], 32, 20, 'props', 'pressed'),
}

if __name__ == '__main__':
    ims = [to_image(composite(fn())) for (fn, *_rest) in T2.values()]
    preview(ims, SCR + r'\t2_prev.png', zoom=4)
    print('ok')
