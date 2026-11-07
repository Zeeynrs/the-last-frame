#!/usr/bin/env python3
"""Build a room scene's floor, perimeter collision and N/W wall modules from a room shape (TLF-065).

ADR-023 R3: a room is authored as a floor outline in tile coordinates (the RoomShape resource,
scripts/rooms/room_shape.gd) plus objects. This tool writes what follows from the outline into a
room .tscn:

  * TileMapLayer_Floor tile_map_data: one cell per floor tile. Tiles that stay keep their source
    and atlas tile; new tiles get --tile-source (default 0, terrazzo).
  * PerimeterWalls/CollisionPolygon2D polygon: the outline in pixels, pushed out by --outset tiles.
  * YSort_Walls WallN_* / WallW_*: one 2-tile wall module per two tile edges of every N / W face,
    at the middle of its edges (ROOM_GRAPH §1, CH01_PLACEMENT_SHEET §0.3).

It does NOT draw corner pieces, low S/E partitions or 1-tile wall ends (that art is TLF-068); it
lists them, and the floor tiles a tall wall would hide (R2), so the layout can deal with them.

The math is the same as RoomShape.gd (canonical outline, tile centre in polygon, faces by floor
side); tests/rooms/test_room_shape.gd is the reference.

Usage:
  python tools/content/build_room_from_shape.py SHAPE.json ROOM.tscn            # dry run: summary + diff
  python tools/content/build_room_from_shape.py SHAPE.json ROOM.tscn --write    # edit the scene

SHAPE.json: {"outline": [[x, y], ...]}  (tile coordinates, rectilinear, any winding)
Exit code: 0 ok, 1 R2 violation (hidden floor) unless --allow-hidden, 2 bad input.
"""
import argparse
import difflib
import json
import math
import re
import struct
import sys

ORIGIN = (320.0, 64.0)
HALF = (16.0, 8.0)
WALL_HEIGHT = 48.0
ACTOR = (32.0, 48.0)
FLOOR_LAYER_POSITION = (304.0, 64.0)   # tile (x, y) centre = tile_to_px(x + 0.5, y + 0.5)


def tile_to_px(x, y):
    return (ORIGIN[0] + (x - y) * HALF[0], ORIGIN[1] + (x + y) * HALF[1])


def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def canonical(points):
    pts = []
    for p in points:
        p = (float(p[0]), float(p[1]))
        if not pts or pts[-1] != p:
            pts.append(p)
    if len(pts) > 1 and pts[0] == pts[-1]:
        pts.pop()
    changed = True
    while changed and len(pts) >= 3:
        changed = False
        for i in range(len(pts)):
            prev, cur, nxt = pts[i - 1], pts[i], pts[(i + 1) % len(pts)]
            if cross((cur[0] - prev[0], cur[1] - prev[1]), (nxt[0] - cur[0], nxt[1] - cur[1])) == 0:
                del pts[i]
                changed = True
                break
    if len(pts) < 4:
        raise ValueError("outline needs at least 4 corners after removing collinear points")
    for i in range(len(pts)):
        a, b = pts[i], pts[(i + 1) % len(pts)]
        if a[0] != b[0] and a[1] != b[1]:
            raise ValueError("edge %s -> %s is not axis-aligned" % (a, b))
    if sum(cross(pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts))) < 0:
        pts.reverse()
    start = min(range(len(pts)), key=lambda i: (pts[i][1], pts[i][0]))
    return pts[start:] + pts[:start]


def inside(pt, poly):
    """Even-odd point in polygon (tile centres never lie on an integer outline)."""
    x, y = pt
    hit = False
    for i in range(len(poly)):
        (x1, y1), (x2, y2) = poly[i], poly[(i + 1) % len(poly)]
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
            hit = not hit
    return hit


def floor_cells(poly):
    xs = [p[0] for p in poly]
    ys = [p[1] for p in poly]
    cells = []
    for y in range(math.floor(min(ys)), math.ceil(max(ys))):
        for x in range(math.floor(min(xs)), math.ceil(max(xs))):
            if inside((x + 0.5, y + 0.5), poly):
                cells.append((x, y))
    return cells


def outward(a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy)
    return (dy / n, -dx / n)


def perimeter_px(poly, outset=0.0):
    out = []
    for i, v in enumerate(poly):
        n1 = outward(poly[i - 1], v)
        n2 = outward(v, poly[(i + 1) % len(poly)])
        out.append(tile_to_px(v[0] + (n1[0] + n2[0]) * outset, v[1] + (n1[1] + n2[1]) * outset))
    return out


def face(a, b):
    o = outward(a, b)
    if a[1] == b[1]:
        return "N" if o[1] < 0 else "low_S"
    return "W" if o[0] < 0 else "low_E"


def wall_segments(poly):
    cells = set(floor_cells(poly))
    segs, faces = [], []
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        f = face(a, b)
        faces.append(f)
        segs.append({"face": f, "from": (int(min(a[0], b[0])), int(min(a[1], b[1]))),
                     "to": (int(max(a[0], b[0])), int(max(a[1], b[1]))), "kind": "straight"})
    for i, v in enumerate(poly):
        vx, vy = int(v[0]), int(v[1])
        around = sum((vx + dx, vy + dy) in cells for dx, dy in ((-1, -1), (0, -1), (-1, 0), (0, 0)))
        pair = [faces[i - 1], faces[i]]
        tall = sorted([f for f in pair if f in ("N", "W")], key=lambda f: f != "N")
        low = sorted([f for f in pair if f in ("low_S", "low_E")], key=lambda f: f != "low_S")
        segs.append({"face": (tall or low)[0], "from": (vx, vy), "to": (vx, vy),
                     "kind": "inner_corner" if around == 3 else "outer_corner", "faces": pair})
    return segs


def clip(subject, clipper):
    """Sutherland-Hodgman: convex `subject` clipped by convex `clipper` (either winding)."""
    sign = 1 if sum(cross(clipper[i], clipper[(i + 1) % len(clipper)]) for i in range(len(clipper))) > 0 else -1
    out = subject
    for i in range(len(clipper)):
        a, b = clipper[i], clipper[(i + 1) % len(clipper)]
        side = lambda p: sign * cross((b[0] - a[0], b[1] - a[1]), (p[0] - a[0], p[1] - a[1])) >= 0
        src, out = out, []
        for j in range(len(src)):
            p, q = src[j], src[(j + 1) % len(src)]
            if side(q):
                if not side(p):
                    out.append(intersect(a, b, p, q))
                out.append(q)
            elif side(p):
                out.append(intersect(a, b, p, q))
        if not out:
            return []
    return out


def intersect(a, b, p, q):
    """Where segment p -> q crosses the line through a -> b."""
    d1 = (b[0] - a[0], b[1] - a[1])
    d2 = (q[0] - p[0], q[1] - p[1])
    t = cross((p[0] - a[0], p[1] - a[1]), d1) / cross(d1, d2)
    return (p[0] + d2[0] * t, p[1] + d2[1] * t)


def area(poly):
    return abs(sum(cross(poly[i], poly[(i + 1) % len(poly)]) for i in range(len(poly)))) / 2.0


def hidden_cells(poly, min_overlap=4.0):
    faces = []
    for s in wall_segments(poly):
        if s["kind"] != "straight" or s["face"] not in ("N", "W"):
            continue
        (fx, fy), (tx, ty) = s["from"], s["to"]
        n = max(tx - fx, ty - fy)
        sx, sy = (tx - fx) // n, (ty - fy) // n
        for i in range(n):
            p0 = tile_to_px(fx + sx * i, fy + sy * i)
            p1 = tile_to_px(fx + sx * (i + 1), fy + sy * (i + 1))
            faces.append(([p0, p1, (p1[0], p1[1] - WALL_HEIGHT), (p0[0], p0[1] - WALL_HEIGHT)], (p0[1] + p1[1]) / 2))
    hidden = []
    for (x, y) in floor_cells(poly):
        fx, fy = tile_to_px(x + 0.5, y + 0.5)
        body = [(fx - ACTOR[0] / 2, fy - ACTOR[1]), (fx + ACTOR[0] / 2, fy - ACTOR[1]), (fx + ACTOR[0] / 2, fy), (fx - ACTOR[0] / 2, fy)]
        for quad, depth in faces:
            if depth > fy:
                piece = clip(body, quad)
                if piece and area(piece) >= min_overlap:
                    hidden.append((x, y))
                    break
    return hidden


def wall_modules(poly):
    """[(name_prefix, pivot_px)] for 2-tile N/W modules, and the 1-tile ends left over."""
    modules, odd_ends = [], []
    for s in wall_segments(poly):
        if s["kind"] != "straight" or s["face"] not in ("N", "W"):
            continue
        (fx, fy), (tx, ty) = s["from"], s["to"]
        length = max(tx - fx, ty - fy)
        sx, sy = (tx - fx) // length, (ty - fy) // length
        for k in range(length // 2):
            modules.append((s["face"], tile_to_px(fx + sx * (2 * k + 1), fy + sy * (2 * k + 1))))
        if length % 2:
            odd_ends.append((s["face"], (fx + sx * (length - 1), fy + sy * (length - 1))))
    return modules, odd_ends


# --- scene editing -------------------------------------------------------------------------------

def num(v):
    return str(int(v)) if float(v).is_integer() else repr(round(float(v), 4))


def decode_tiles(data):
    raw = bytes(int(x) for x in data.split(",")) if data.strip() else b""
    if len(raw) < 2:
        return {}
    cells = {}
    for i in range((len(raw) - 2) // 12):
        x, y, src, ax, ay, alt = struct.unpack("<hhHHHH", raw[2 + i * 12: 14 + i * 12])
        cells[(x, y)] = (src, ax, ay, alt)
    return cells


def encode_tiles(cells):
    raw = struct.pack("<H", 0)
    for (x, y) in sorted(cells, key=lambda c: (c[1], c[0])):
        raw += struct.pack("<hhHHHH", x, y, *cells[(x, y)])
    return ", ".join(str(b) for b in raw)


def node_block(text, name, parent=None):
    pattern = r'\[node name="%s"[^\]]*%s\]\n(?:(?!\[).*\n?)*' % (re.escape(name), r'parent="%s"' % re.escape(parent) if parent else "")
    return re.search(pattern, text)


def ext_id(text, path_suffix):
    m = re.search(r'\[ext_resource type="Texture2D"[^\]]*path="[^"]*%s"[^\]]*id="([^"]+)"\]' % re.escape(path_suffix), text)
    return m.group(1) if m else None


def build(text, poly, outset, tile_source):
    notes = []
    # Floor.
    floor = node_block(text, "TileMapLayer_Floor")
    if not floor:
        raise ValueError("no TileMapLayer_Floor node")
    pos = re.search(r"position = Vector2\(([^)]*)\)", floor.group(0))
    if not pos or tuple(float(v) for v in pos.group(1).split(",")) != FLOOR_LAYER_POSITION:
        notes.append("TileMapLayer_Floor position is %s, expected Vector2(304, 64)" % (pos.group(1) if pos else "missing"))
    data = re.search(r"tile_map_data = PackedByteArray\(([^)]*)\)", floor.group(0))
    old_cells = decode_tiles(data.group(1)) if data else {}
    new_cells = {}
    for c in floor_cells(poly):
        new_cells[c] = old_cells.get(c, (tile_source, 0, 0, 0))
    kept = len(set(old_cells) & set(new_cells))
    notes.append("floor: %d tiles (%d kept with their tile, %d new, %d removed)" % (
        len(new_cells), kept, len(new_cells) - kept, len(set(old_cells) - set(new_cells))))
    new_floor = floor.group(0)
    line = "tile_map_data = PackedByteArray(%s)" % encode_tiles(new_cells)
    new_floor = re.sub(r"tile_map_data = PackedByteArray\([^)]*\)", lambda _: line, new_floor) if data else \
        new_floor.replace("\n", "\n%s\n" % line, 1)
    text = text[:floor.start()] + new_floor + text[floor.end():]

    # Collision.
    coll = node_block(text, "CollisionPolygon2D", "PerimeterWalls")
    if not coll:
        raise ValueError("no PerimeterWalls/CollisionPolygon2D node")
    pts = perimeter_px(poly, outset)
    polygon = "polygon = PackedVector2Array(%s)" % ", ".join("%s, %s" % (num(x), num(y)) for x, y in pts)
    new_coll = re.sub(r"polygon = PackedVector2Array\([^)]*\)", lambda _: polygon, coll.group(0))
    notes.append("collision: %d corners, outset %s tile" % (len(pts), num(outset)))
    text = text[:coll.start()] + new_coll + text[coll.end():]

    # N/W wall modules.
    tex = {"N": ext_id(text, "wall_subterranean_n_idle.png"), "W": ext_id(text, "wall_subterranean_w_idle.png")}
    if not tex["N"] or not tex["W"]:
        raise ValueError("wall textures (ch01_env_wall_subterranean_n/w_idle.png) are not ext_resources of this scene")
    first = None
    for m in list(re.finditer(r'\[node name="Wall[NW]_\d+" type="Sprite2D" parent="YSort_Walls"\]\n(?:(?!\[).*\n?)*', text))[::-1]:
        first = m.start()
        text = text[:m.start()] + text[m.end():]
    if first is None:
        walls = node_block(text, "YSort_Walls")
        if not walls:
            raise ValueError("no YSort_Walls node")
        first = walls.end()
    modules, odd = wall_modules(poly)
    count = {"N": 0, "W": 0}
    blocks = []
    for f, (x, y) in modules:
        blocks.append('[node name="Wall%s_%d" type="Sprite2D" parent="YSort_Walls"]\nposition = Vector2(%s, %s)\n'
                      'offset = Vector2(-16, -56)\ncentered = false\ntexture = ExtResource("%s")\n' % (f, count[f], num(x), num(y), tex[f]))
        count[f] += 1
    text = text[:first] + "".join(blocks) + text[first:]
    notes.append("walls: %d N and %d W modules" % (count["N"], count["W"]))
    for f, t in odd:
        notes.append("NOT DRAWN: 1-tile %s wall end at tile edge %s (needs a TLF-068 piece)" % (f, t))
    for s in wall_segments(poly):
        if s["kind"] != "straight":
            notes.append("NOT DRAWN: %s %s at %s (faces %s, TLF-068 kit)" % (s["kind"], s["face"], s["from"], "/".join(s["faces"])))
        elif s["face"].startswith("low_"):
            notes.append("NOT DRAWN: %s partition %s -> %s (open today; TLF-068 low piece if needed)" % (s["face"], s["from"], s["to"]))
    return text, notes


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("shape", help="JSON file with {\"outline\": [[x, y], ...]}")
    ap.add_argument("room", help="room scene (.tscn) to rebuild")
    ap.add_argument("--write", action="store_true", help="edit the scene (default: dry run)")
    ap.add_argument("--outset", type=float, default=0.0, help="push the collision outline out by this many tiles")
    ap.add_argument("--tile-source", type=int, default=0, help="tile source id for new floor tiles")
    ap.add_argument("--allow-hidden", action="store_true", help="exit 0 even if a tall wall hides floor (R2)")
    args = ap.parse_args(argv)
    try:
        with open(args.shape, encoding="utf-8") as fh:
            poly = canonical(json.load(fh)["outline"])
        with open(args.room, encoding="utf-8", newline="") as fh:
            old = fh.read()
        new, notes = build(old, poly, args.outset, args.tile_source)
    except (ValueError, KeyError, OSError, json.JSONDecodeError) as e:
        print("ERROR: %s" % e)
        return 2
    print("shape: %s" % [list(map(num, p)) for p in poly])
    for n in notes:
        print("  " + n)
    hidden = hidden_cells(poly)
    if hidden:
        print("R2: a tall wall would hide floor tiles %s" % hidden)
    diff = list(difflib.unified_diff(old.splitlines(), new.splitlines(), args.room, args.room + " (built)", lineterm="", n=1))
    print("diff: %d changed line(s)%s" % (sum(1 for d in diff if d[:1] in "+-" and d[:3] not in ("+++", "---")), "" if args.write else " (dry run)"))
    for d in diff:
        print(d if len(d) <= 220 else d[:220] + " ...")
    if args.write:
        with open(args.room, "w", encoding="utf-8", newline="") as fh:
            fh.write(new)
        print("written: %s" % args.room)
    return 1 if hidden and not args.allow_hidden else 0


if __name__ == "__main__":
    sys.exit(main())
