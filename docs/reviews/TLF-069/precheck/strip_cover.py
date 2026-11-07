"""How much of the amber edge-strip row stays visible behind the TLF-068 low partitions (pixels).
Floor tile t: 32x16 diamond centred at tile_to_px(t + 0.5). Low pieces: 32x32 PNG, pivot (16, 24), at
tile_to_px(anchor) per ASSET_METADATA 10.2. Counts the strip-cell diamond pixels under an opaque
partition pixel. usage: python strip_cover.py <repo>"""
import sys
from PIL import Image
repo = sys.argv[1]
A = repo + "/assets/environments/ch01/"
def px(x, y): return (320 + (x - y) * 16, 64 + (x + y) * 8)
def load(n): return Image.open(A + n).convert("RGBA")
low_s, low_e = load("ch01_env_wall_partition_low_s_idle.png"), load("ch01_env_wall_partition_low_e_idle.png")
c_in, c_out = load("ch01_env_wall_partition_low_corner_inner_idle.png"), load("ch01_env_wall_partition_low_corner_outer_idle.png")
opaque = set()
def place(img, anchor):
    ax, ay = px(*anchor)
    for j in range(img.height):
        for i in range(img.width):
            if img.getpixel((i, j))[3] > 0:
                opaque.add((ax - 16 + i, ay - 24 + j))
# pit edge y = 8 (x 12..30) and arm edge x = 12 (y 8..18): modules at the odd midpoints, corners at the ends
for u in range(13, 30, 2): place(low_s, (u, 8))
for v in range(9, 18, 2): place(low_e, (12, v))
place(c_in, (12, 8)); place(c_out, (30, 8))
def diamond(t):
    cx, cy = (int(v) for v in px(t[0] + 0.5, t[1] + 0.5))
    return {(x, y) for x in range(cx - 16, cx + 16) for y in range(cy - 8, cy + 8)
            if abs(x + 0.5 - cx) / 16 + abs(y + 0.5 - cy) / 8 <= 1}
for label, cells in (("pit edge row y=7, x 13..28", [(x, 7) for x in range(13, 29)]),
                     ("arm edge column x=11, y 9..16", [(11, y) for y in range(9, 17)]),
                     ("row behind it, y=6, x 13..28", [(x, 6) for x in range(13, 29)])):
    tot = cov = 0
    for c in cells:
        d = diamond(c); tot += len(d); cov += len(d & opaque)
    print("%-32s %5d px, %5d under a partition = %.0f%% hidden" % (label, tot, cov, 100.0 * cov / tot))
print("partition piece opaque rows: low_s y %s..%s of 32 (pivot y 24)" % (
    min(j for j in range(32) for i in range(32) if low_s.getpixel((i, j))[3]), max(j for j in range(32) for i in range(32) if low_s.getpixel((i, j))[3])))
