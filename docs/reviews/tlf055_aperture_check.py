# TLF-055 aperture check (Opus, 2026-11-05). Static, conservative: player capsule vs. wall
# segments, ignoring move_and_slide. Reproduces the table in docs/tasks/TLF-055.md section G.
# Static passability check: player capsule (radius 6, height 16, rotated 90 deg, offset (0,-4))
# through a wall gap. Config-space flood fill on a 0.25 px grid; free = capsule core segment
# keeps distance > radius + margin from every obstacle segment.
import math
from collections import deque
R, HALF, OFF, MARGIN = 6.0, 2.0, -4.0, 0.08   # core segment (x-2,y-4)-(x+2,y-4)

def seg_dist(p1, p2, q1, q2):
    def pt_seg(p, a, b):
        ax, ay = a; bx, by = b; px, py = p
        dx, dy = bx-ax, by-ay; L = dx*dx+dy*dy
        t = 0 if L == 0 else max(0, min(1, ((px-ax)*dx+(py-ay)*dy)/L))
        return math.hypot(px-ax-t*dx, py-ay-t*dy)
    def inter(a, b, c, d):
        def cr(o, p, q): return (p[0]-o[0])*(q[1]-o[1])-(p[1]-o[1])*(q[0]-o[0])
        return cr(a,b,c)*cr(a,b,d) < 0 and cr(c,d,a)*cr(c,d,b) < 0
    if inter(p1, p2, q1, q2): return 0
    return min(pt_seg(p1,q1,q2), pt_seg(p2,q1,q2), pt_seg(q1,p1,p2), pt_seg(q2,p1,p2))

def rect(cx, cy, w, h):
    a, b, c, d = (cx-w/2, cy-h/2), (cx+w/2, cy-h/2), (cx+w/2, cy+h/2), (cx-w/2, cy+h/2)
    return [(a,b),(b,c),(c,d),(d,a)]

def passable(name, obstacles, start, goal, centre, half=48, step=0.25):
    def free(x, y):
        p1, p2 = (x-HALF, y+OFF), (x+HALF, y+OFF)
        return all(seg_dist(p1, p2, a, b) > R + MARGIN for a, b in obstacles)
    cx, cy = centre
    n = int(2*half/step)
    def idx(x, y): return (round((x-(cx-half))/step), round((y-(cy-half))/step))
    s, g = idx(*start), idx(*goal)
    ok_s = free(*start); ok_g = free(*goal)
    seen = {s}; q = deque([s]) if ok_s else deque()
    cache = {}
    def f(i, j):
        if (i, j) not in cache:
            cache[(i, j)] = free(cx-half+i*step, cy-half+j*step)
        return cache[(i, j)]
    found = False
    while q:
        i, j = q.popleft()
        if (i, j) == g: found = True; break
        for di, dj in ((1,0),(-1,0),(0,1),(0,-1)):
            ni, nj = i+di, j+dj
            if 0 <= ni <= n and 0 <= nj <= n and (ni, nj) not in seen and f(ni, nj):
                seen.add((ni, nj)); q.append((ni, nj))
    print(f"{name:58s} start free={ok_s} goal free={ok_g} -> {'PASSABLE' if found else 'BLOCKED'}")

# Reference: existing fire-shutter gap (real-input tests walk (384,146)->(384,176) through it)
passable("existing fire_shutter gap (396,154)-(372,166) [reference]",
         [((448,128),(396,154)), ((372,166),(304,200))], (384,140), (384,180), (384,160))
# SO-02 hatch, spec geometry, without and with the n11 statue footprint 12x8 at (304,104)
bulk = [((368,88),(328,108)), ((312,116),(224,160))]
passable("hatch_01 gap (328,108)-(312,116), no statue", bulk, (296,96), (344,128), (320,112))
passable("hatch_01 gap + n11 statue footprint at (304,104)", bulk + rect(304,104,12,8), (288,124), (344,128), (320,112))
passable("inner_shutter gap (440,180)-(424,188)",
         [((496,152),(440,180)), ((424,188),(352,224))], (416,172), (448,196), (432,184))
passable("staff_barrier gap (440,196)-(424,204)",
         [((512,160),(440,196)), ((424,204),(336,248))], (416,188), (448,212), (432,200))
# Same gaps widened to the existing shutter gap (26.8 px, 1.5 tiles) for comparison
passable("hatch_01 gap widened to 26.8 px + statue", [((368,88),(332,106)), ((308,118),(224,160))] + rect(304,104,12,8), (288,124), (344,128), (320,112))

# Negative controls: the check must report these as BLOCKED.
passable("control: gap narrowed to 8.9 px (expect BLOCKED)", [((368,88),(324,110)), ((316,114),(224,160))], (296,96), (344,128), (320,112))
passable("control: continuous wall (expect BLOCKED)", [((368,88),(224,160))], (296,96), (344,128), (320,112))

# Straight-line clearance (px beyond the capsule radius) for straight-down and 45-degree input.
def clearance(obs, a, b, n=200):
    best = 1e9
    for i in range(n + 1):
        t = i / n; x = a[0] + (b[0]-a[0])*t; y = a[1] + (b[1]-a[1])*t
        p1, p2 = (x-HALF, y+OFF), (x+HALF, y+OFF)
        best = min(best, min(seg_dist(p1, p2, q1, q2) for q1, q2 in obs) - R)
    return best

def table_row(name, obs, cx, cy):
    down = max((clearance(obs, (x/4, cy-30), (x/4, cy+30)), x/4) for x in range(int((cx-8)*4), int((cx+8)*4)))
    dr = max(clearance(obs, (cx+k/4-24, cy-24), (cx+k/4+24, cy+24)) for k in range(-40, 41))
    dl = max(clearance(obs, (cx+k/4+24, cy-24), (cx+k/4-24, cy+24)) for k in range(-40, 41))
    fmt = lambda v: f"{v:5.2f}" if v > MARGIN else "BLOCKED"
    print(f"{name:44s} down {fmt(down[0])} (x={down[1]})  down-right {fmt(dr)}  down-left {fmt(dl)}")

statue = rect(304, 104, 12, 8)
table_row("fire_shutter (existing, 26.8 px)", [((448,128),(396,154)), ((372,166),(304,200))], 384, 160)
table_row("hatch (spec, 17.9 px)", bulk, 320, 112)
table_row("inner_shutter (spec, 17.9 px)", [((496,152),(440,180)), ((424,188),(352,224))], 432, 184)
table_row("staff_barrier (spec, 17.9 px)", [((512,160),(440,196)), ((424,204),(336,248))], 432, 200)
table_row("hatch (spec) + N-11 footprint", bulk + statue, 320, 112)
table_row("hatch widened to 26.8 px + N-11", [((368,88),(332,106)), ((308,118),(224,160))] + statue, 320, 112)
