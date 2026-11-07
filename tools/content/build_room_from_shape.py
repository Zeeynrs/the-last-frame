#!/usr/bin/env python3
"""Build a room scene's floor, perimeter collision, N/W wall modules and RoomShape from an outline.

ADR-023 R3: a room is authored as a floor outline in tile coordinates (the RoomShape resource,
scripts/rooms/room_shape.gd) plus objects. This tool writes what follows from the outline into a
room .tscn (TLF-065, completed in TLF-071 so a rebuild needs no hand work):

  * TileMapLayer_Floor tile_map_data: one cell per floor tile, minus --holes (cells left empty, e.g.
    a trench drawn by an underlay below the floor). A cell that stays keeps its source and atlas
    tile; a new cell gets --tile-source (default per room: 4 concrete_service for maintenance_bay,
    security_crossing and signal_control, else 0 terrazzo).
  * --edge-strip SRC[,FACES]: paints SRC (2 = tactile_amber, the platform-edge strip) on every
    boundary cell along the low S and/or E faces of the new outline, except --door cells, and puts
    the room's base source back on strip cells that were on the old S/E edge and no longer are.
    Only the named faces are painted and cleared (a strip on the other face is left as it is).
  * PerimeterWalls/CollisionPolygon2D polygon: the outline in pixels, pushed out by --outset tiles
    (default 0.25, the hand-built rooms' N/W margin, TLF-065 ROUNDTRIP_REPORT).
  * YSort_Walls WallN_* / WallW_*: one 2-tile wall module per two tile edges of every N / W face,
    at the middle of its edges (ROOM_GRAPH §1, CH01_PLACEMENT_SHEET §0.3). A module with an
    archway sprite exactly on its pivot (an N/W --door at an odd offset along its run) is left to
    the archway; a door whose archway straddles two modules is reported, not cut (that needs
    1-tile wall ends, TLF-068).
  * metadata/room_shape on the room root: a RoomShape sub-resource with the canonical outline, so
    RoomRouter hands the real bounds to the follow camera.

It does NOT draw corner pieces, low S/E partitions or 1-tile wall ends (that art is TLF-068); it
lists them, and the floor tiles a tall wall would hide (R2), so the layout can deal with them.

The math is the same as RoomShape.gd (canonical outline, tile centre in polygon, faces by floor
side); tests/rooms/test_room_shape.gd is the reference, tools/content/test_build_room_from_shape.py
the builder's tests.

Usage:
  python tools/content/build_room_from_shape.py SHAPE.json ROOM.tscn            # dry run: summary + diff
  python tools/content/build_room_from_shape.py SHAPE.json ROOM.tscn --write    # edit the scene
  python tools/content/build_room_from_shape.py SHAPE.json ROOM.tscn --out NEW.tscn

SHAPE.json: {"outline": [[x, y], ...], "holes": [[x, y], ...], "doors": [["E", x, y], ...]}
  (tile coordinates; the outline rectilinear, any winding; holes and doors optional and added to
  the command-line ones)
Cells (--holes): "x,y" items separated by ";" or spaces, either coordinate may be a range a..b,
  e.g. --holes "9,0..11" is column 9, rows 0 to 11.
Doors (--door, repeatable): FACE,x,y with the door's boundary tile, as in ROOM_GRAPH §2,
  e.g. --door E,13,5.
Exit code: 0 ok, 1 R2 violation (hidden floor) unless --allow-hidden, 2 bad input.
"""
import argparse
import difflib
import json
import math
import os
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


STRIP_FACES = ("S", "E")
FACE_STEP = {"N": (0, -1), "W": (-1, 0), "S": (0, 1), "E": (1, 0)}
# Floor source for new cells when --tile-source is not given (ch01_tileset.tres: 0 terrazzo_dark,
# 4 concrete_service), by room scene file name.
ROOM_TILE_SOURCE = {"maintenance_bay": 4, "security_crossing": 4, "signal_control": 4}
DEFAULT_TILE_SOURCE = 0
ROOM_SHAPE_SCRIPT = "res://scripts/rooms/room_shape.gd"
ROOM_SHAPE_SUB_ID = "room_shape"
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def default_tile_source(room_path):
    return ROOM_TILE_SOURCE.get(os.path.splitext(os.path.basename(room_path))[0], DEFAULT_TILE_SOURCE)


def _span(text):
    if ".." in text:
        a, b = text.split("..", 1)
        a, b = int(a), int(b)
        return range(min(a, b), max(a, b) + 1)
    return [int(text)]


def parse_cells(text):
    """'9,0..11; 3,4' -> [(9, 0), ..., (9, 11), (3, 4)]."""
    cells = []
    for item in re.split(r"[;\s]+", (text or "").strip()):
        if not item:
            continue
        parts = item.split(",")
        if len(parts) != 2:
            raise ValueError("cell '%s' is not x,y" % item)
        for y in _span(parts[1]):
            for x in _span(parts[0]):
                cells.append((x, y))
    return cells


def parse_door(text):
    """'E,13,5' -> ('E', (13, 5))."""
    parts = [str(p).strip() for p in (text if isinstance(text, (list, tuple)) else str(text).split(","))]
    if len(parts) != 3 or str(parts[0]).upper() not in FACE_STEP:
        raise ValueError("door '%s' is not FACE,x,y (FACE one of N, W, S, E)" % (text,))
    return (str(parts[0]).upper(), (int(parts[1]), int(parts[2])))


def parse_strip(text):
    """'2' -> (2, ('S', 'E')); '2,S' / '2,SE' / '2,S,E' -> the named faces."""
    if text is None:
        return None
    parts = [p.strip().upper() for p in str(text).split(",") if p.strip()]
    if not parts:
        raise ValueError("--edge-strip needs a tile source")
    faces = []
    for p in parts[1:]:
        for f in p:
            if f not in STRIP_FACES:
                raise ValueError("--edge-strip faces are S and/or E, not '%s'" % f)
            if f not in faces:
                faces.append(f)
    return (int(parts[0]), tuple(faces or STRIP_FACES))


def check_doors(poly, doors):
    """Every door tile must be floor on the boundary of its face."""
    cells = set(floor_cells(poly))
    for f, (x, y) in doors:
        dx, dy = FACE_STEP[f]
        if (x, y) not in cells or (x + dx, y + dy) in cells:
            raise ValueError("door %s,%d,%d is not a floor tile on the %s boundary of the outline" % (f, x, y, f))


def strip_cells(poly, faces, holes, doors):
    """Boundary cells along the outline's low S / low E edges (the face names S, E), minus holes
    and door tiles (a door tile never gets the strip, whichever face its door is on)."""
    cells = set()
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        f = face(a, b)
        if f == "low_S" and "S" in faces:
            y = int(a[1]) - 1
            cells.update((x, y) for x in range(int(min(a[0], b[0])), int(max(a[0], b[0]))))
        elif f == "low_E" and "E" in faces:
            x = int(a[0]) - 1
            cells.update((x, y) for y in range(int(min(a[1], b[1])), int(max(a[1], b[1]))))
    return cells - set(holes) - {t for _, t in doors}


def old_edge_cells(old, holes, faces):
    """Cells of the old floor that were on its S / E edge (a neighbour that is neither floor nor a
    hole); a cell next to a hole (a trench) is not an edge."""
    around = set(old) | set(holes)
    out = set()
    for (x, y) in old:
        for f in faces:
            dx, dy = FACE_STEP[f]
            if (x + dx, y + dy) not in around:
                out.add((x, y))
    return out


def archway_px(tile):
    """Archway sprite pivot for a door (scene convention: the door tile's corner point,
    e.g. W (0,5) -> (240, 104), E (13,5) -> (448, 208))."""
    return tile_to_px(tile[0], tile[1])


def door_walls(poly, doors, sprite_positions):
    """For N/W doors: {module index in wall_modules order: archway name} of modules left to an archway,
    and report lines. A module is left out only when the archway sprite sits exactly on its
    pivot (same 2 tile edges); an archway between two modules is reported."""
    modules, _ = wall_modules(poly)
    skip, notes = {}, []
    for f, tile in doors:
        if f not in ("N", "W"):
            continue
        px = archway_px(tile)
        hit = [i for i, (mf, p) in enumerate(modules) if mf == f and p == px]
        if hit and px in sprite_positions:
            skip[hit[0]] = sprite_positions[px]
            notes.append("door %s %s: module at %s left to the archway %s" % (f, tile, fmt_px(px), sprite_positions[px]))
        elif hit:
            notes.append("door %s %s: KEPT module at %s, no archway sprite at that pivot in YSort_Walls" % (f, tile, fmt_px(px)))
        else:
            along = [i for i, (mf, p) in enumerate(modules) if mf == f and abs(p[0] - px[0]) <= 16 and abs(p[1] - px[1]) <= 8]
            notes.append("door %s %s: NOT CUT, its archway at %s spans the joint of 2 modules (%s); cutting needs 1-tile wall ends (TLF-068)"
                         % (f, tile, fmt_px(px), ", ".join(fmt_px(modules[i][1]) for i in along) or "none"))
    return skip, notes


def fmt_px(p):
    return "(%s, %s)" % (num(p[0]), num(p[1]))


def _sprite_positions(text):
    """{(x, y): name} of the YSort_Walls sprites other than Wall[NW]_<n>."""
    out = {}
    for m in re.finditer(r'\[node name="([^"]+)" type="Sprite2D" parent="YSort_Walls"\]\n((?:(?!\[).*\n?)*)', text):
        if re.match(r"Wall[NW]_\d+$", m.group(1)):
            continue
        pos = re.search(r"position = Vector2\(([^,]+), ([^)]+)\)", m.group(2))
        if pos:
            out[(float(pos.group(1)), float(pos.group(2)))] = m.group(1)
    return out


def _room_shape_uid():
    try:
        with open(os.path.join(REPO_ROOT, "scripts", "rooms", "room_shape.gd.uid"), encoding="utf-8") as fh:
            uid = fh.read().strip()
        return uid if uid.startswith("uid://") else None
    except OSError:
        return None


def set_room_shape_meta(text, poly):
    """Adds or updates metadata/room_shape (a RoomShape sub-resource with the canonical outline)
    on the scene's root node."""
    outline = "outline = PackedVector2Array(%s)" % ", ".join("%s, %s" % (num(x), num(y)) for x, y in poly)
    m = re.search(r'\[ext_resource [^\]]*path="%s"[^\]]*id="([^"]+)"\]' % re.escape(ROOM_SHAPE_SCRIPT), text)
    if m:
        script_id = m.group(1)
    else:
        script_id = "room_shape_script"
        while 'id="%s"' % script_id in text:
            script_id += "_"
        uid = _room_shape_uid()
        line = '[ext_resource type="Script"%s path="%s" id="%s"]' % (' uid="%s"' % uid if uid else "", ROOM_SHAPE_SCRIPT, script_id)
        last = None
        for last in re.finditer(r"^\[ext_resource [^\n]*\]\n", text, re.M):
            pass
        if last is not None:
            text = text[:last.end()] + line + "\n" + text[last.end():]
        else:
            head = re.search(r"^\[gd_scene[^\n]*\]\n", text, re.M)
            if not head:
                raise ValueError("no [gd_scene] header")
            text = text[:head.end()] + "\n" + line + "\n" + text[head.end():]
    block = '[sub_resource type="Resource" id="%s"]\nscript = ExtResource("%s")\n%s\n' % (ROOM_SHAPE_SUB_ID, script_id, outline)
    sub = re.search(r'\[sub_resource type="Resource" id="%s"\]\n(?:(?!\[).*\n?)*' % ROOM_SHAPE_SUB_ID, text)
    if sub:
        text = text[:sub.start()] + block + "\n" + text[sub.end():].lstrip("\n")
    else:
        first = re.search(r"^\[node ", text, re.M)
        if not first:
            raise ValueError("no nodes in the scene")
        text = text[:first.start()] + block + "\n" + text[first.start():]
    root = re.search(r'^\[node name="[^"]+" type="[^"]+"(?![^\]]*parent=)[^\]]*\]\n((?:(?!\[).*\n?)*)', text, re.M)
    if not root:
        raise ValueError("no root node")
    body = root.group(1)
    meta = 'metadata/room_shape = SubResource("%s")' % ROOM_SHAPE_SUB_ID
    if re.search(r"^metadata/room_shape = .*$", body, re.M):
        new_body = re.sub(r"^metadata/room_shape = .*$", lambda _: meta, body, flags=re.M)
    else:
        props = body.rstrip("\n")
        trail = body[len(props):]
        new_body = (props + "\n" + meta + "\n" + trail[1:]) if props else (meta + "\n" + trail)
    return text[:root.start(1)] + new_body + text[root.end(1):]


def build(text, poly, outset=0.25, tile_source=None, holes=(), doors=(), strip=None, room_path=""):
    """Returns (new scene text, report notes). `strip` is (source, faces) or None."""
    notes = []
    base = default_tile_source(room_path) if tile_source is None else tile_source
    holes = sorted(set(holes))
    check_doors(poly, doors)
    shape_cells = set(floor_cells(poly))
    stray = [c for c in holes if c not in shape_cells]
    if stray:
        notes.append("holes outside the floor (ignored): %s" % stray)

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
        if c not in holes:
            new_cells[c] = old_cells.get(c, (base, 0, 0, 0))
    kept = len(set(old_cells) & set(new_cells))
    notes.append("floor: %d tiles (%d kept with their tile, %d new with source %d, %d removed, %d holes)" % (
        len(new_cells), kept, len(new_cells) - kept, base, len(set(old_cells) - set(new_cells)), len(holes)))
    if strip is not None:
        src, faces = strip
        want = strip_cells(poly, faces, holes, doors)
        painted = sum(1 for c in want if new_cells[c][0] != src)
        for c in want:
            new_cells[c] = (src, 0, 0, 0)
        cleared = sorted(c for c in old_edge_cells(old_cells, holes, faces)
                         if c in new_cells and c not in want and new_cells[c][0] == src)
        for c in cleared:
            new_cells[c] = (base, 0, 0, 0)
        notes.append("edge strip: source %d on %d %s boundary cells (%d repainted), %d old strip cells back to source %d"
                     % (src, len(want), "/".join(faces), painted, len(cleared), base))
        if cleared:
            notes.append("  strip cleared from %s" % cleared)
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
    if re.search(r"polygon = PackedVector2Array\([^)]*\)", coll.group(0)):
        new_coll = re.sub(r"polygon = PackedVector2Array\([^)]*\)", lambda _: polygon, coll.group(0))
    else:
        new_coll = coll.group(0).replace("\n", "\n%s\n" % polygon, 1)
    notes.append("collision: %d corners, outset %s tile" % (len(pts), num(outset)))
    text = text[:coll.start()] + new_coll + text[coll.end():]

    # N/W wall modules.
    tex = {"N": ext_id(text, "wall_subterranean_n_idle.png"), "W": ext_id(text, "wall_subterranean_w_idle.png")}
    if not tex["N"] or not tex["W"]:
        raise ValueError("wall textures (ch01_env_wall_subterranean_n/w_idle.png) are not ext_resources of this scene")
    skip, door_notes = door_walls(poly, doors, _sprite_positions(text))
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
    placed = {"N": 0, "W": 0}
    blocks = []
    for i, (f, (x, y)) in enumerate(modules):
        if i not in skip:
            blocks.append('[node name="Wall%s_%d" type="Sprite2D" parent="YSort_Walls"]\nposition = Vector2(%s, %s)\n'
                          'offset = Vector2(-16, -56)\ncentered = false\ntexture = ExtResource("%s")\n' % (f, count[f], num(x), num(y), tex[f]))
            placed[f] += 1
        count[f] += 1
    text = text[:first] + "".join(blocks) + text[first:]
    notes.append("walls: %d N and %d W modules%s" % (placed["N"], placed["W"],
                 " (%d left to archways)" % len(skip) if skip else ""))
    notes.extend(door_notes)
    for f, t in odd:
        notes.append("NOT DRAWN: 1-tile %s wall end at tile edge %s (needs a TLF-068 piece)" % (f, t))
    for s in wall_segments(poly):
        if s["kind"] != "straight":
            notes.append("NOT DRAWN: %s %s at %s (faces %s, TLF-068 kit)" % (s["kind"], s["face"], s["from"], "/".join(s["faces"])))
        elif s["face"].startswith("low_"):
            notes.append("NOT DRAWN: %s partition %s -> %s (open today; TLF-068 low piece if needed)" % (s["face"], s["from"], s["to"]))

    # RoomShape metadata (camera bounds).
    text = set_room_shape_meta(text, poly)
    notes.append("metadata/room_shape: outline %s" % [[int(x), int(y)] for x, y in poly])
    return text, notes


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("shape", help="JSON file with {\"outline\": [[x, y], ...]} (optional \"holes\", \"doors\")")
    ap.add_argument("room", help="room scene (.tscn) to rebuild")
    ap.add_argument("--write", action="store_true", help="edit the scene (default: dry run)")
    ap.add_argument("--out", help="write the result to this file instead (the room scene is not changed)")
    ap.add_argument("--outset", type=float, default=0.25, help="push the collision outline out by this many tiles (default 0.25)")
    ap.add_argument("--tile-source", type=int, default=None,
                    help="tile source id for new floor tiles (default: 4 for maintenance_bay, security_crossing, signal_control, else 0)")
    ap.add_argument("--holes", default="", help="cells to leave empty, e.g. \"9,0..11\"")
    ap.add_argument("--door", action="append", default=[], help="FACE,x,y door boundary tile (repeatable)")
    ap.add_argument("--edge-strip", default=None, help="SRC[,FACES]: paint SRC on the new S/E boundary cells (default faces S,E)")
    ap.add_argument("--allow-hidden", action="store_true", help="exit 0 even if a tall wall hides floor (R2)")
    args = ap.parse_args(argv)
    try:
        with open(args.shape, encoding="utf-8") as fh:
            spec = json.load(fh)
        poly = canonical(spec["outline"])
        holes = [tuple(map(int, c)) for c in spec.get("holes", [])] + parse_cells(args.holes)
        doors = [parse_door(d) for d in spec.get("doors", [])] + [parse_door(d) for d in args.door]
        strip = parse_strip(args.edge_strip)
        with open(args.room, encoding="utf-8", newline="") as fh:
            old = fh.read()
        new, notes = build(old, poly, args.outset, args.tile_source, holes, doors, strip, args.room)
    except (ValueError, KeyError, TypeError, OSError, json.JSONDecodeError) as e:
        print("ERROR: %s" % e)
        return 2
    print("shape: %s" % [list(map(num, p)) for p in poly])
    for n in notes:
        print("  " + n)
    hidden = hidden_cells(poly)
    if hidden:
        print("R2: a tall wall would hide floor tiles %s" % hidden)
    target = args.out or (args.room if args.write else None)
    diff = list(difflib.unified_diff(old.splitlines(), new.splitlines(), args.room, (target or args.room + " (built)"), lineterm="", n=1))
    print("diff: %d changed line(s)%s" % (sum(1 for d in diff if d[:1] in "+-" and d[:3] not in ("+++", "---")), "" if target else " (dry run)"))
    for d in diff:
        print(d if len(d) <= 220 else d[:220] + " ...")
    if target:
        with open(target, "w", encoding="utf-8", newline="") as fh:
            fh.write(new)
        print("written: %s" % target)
    return 1 if hidden and not args.allow_hidden else 0


if __name__ == "__main__":
    sys.exit(main())
