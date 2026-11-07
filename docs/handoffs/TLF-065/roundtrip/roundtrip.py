"""TLF-065 round-trip: build_room_from_shape.py (dry run, W x H rectangle) vs the hand-built rooms."""
import json, math, re, sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "tools", "content"))
import build_room_from_shape as B

ROOT = sys.argv[1]
ROOMS = [l.split() for l in open(sys.argv[2]) if l.strip()]
VIEW = (640.0, 360.0)
CAP_R, CAP_HALF, CAP_DY = 6.0, 2.0, -4.0   # Player.tscn: capsule r 6 h 16, rotated 90 deg, at (0,-4)


def px_to_tile(p):
    a = (p[0] - 320) / 16.0
    b = (p[1] - 64) / 8.0
    return ((a + b) / 2, (b - a) / 2)


def parse(path):
    text = open(path, encoding="utf-8").read()
    ext = {m.group(2): m.group(1) for m in re.finditer(r'\[ext_resource [^\]]*path="([^"]+)"[^\]]*id="([^"]+)"\]', text)}
    subs = {}
    for m in re.finditer(r'\[sub_resource type="(\w+)" id="([^"]+)"\]\n((?:(?!\[).*\n?)*)', text):
        subs[m.group(2)] = (m.group(1), dict(re.findall(r'^(\w+) = (.*)$', m.group(3), re.M)))
    nodes = []
    for m in re.finditer(r'\[node name="([^"]+)" type="(\w+)"(?: parent="([^"]*)")?[^\]]*\]\n((?:(?!\[).*\n?)*)', text):
        props = dict(re.findall(r'^([\w/]+) = (.*)$', m.group(4), re.M))
        n = {"name": m.group(1), "type": m.group(2), "parent": m.group(3), "props": props, "start": m.start(), "body": m.group(4)}
        n["path"] = "" if n["parent"] is None else (n["name"] if n["parent"] == "." else n["parent"] + "/" + n["name"])
        nodes.append(n)
    by = {n["path"]: n for n in nodes}

    def vec(s):
        m = re.match(r"Vector2\(([^,]+), ([^)]+)\)", s or "")
        return (float(m.group(1)), float(m.group(2))) if m else (0.0, 0.0)

    for n in nodes:
        n["local"] = vec(n["props"].get("position"))

    def glob(n):
        if n["parent"] is None:
            return (0.0, 0.0)
        p = glob(by[n["parent"] if n["parent"] != "." else ""])
        return (p[0] + n["local"][0], p[1] + n["local"][1])

    for n in nodes:
        n["global"] = glob(n)
    return text, ext, subs, nodes, by, vec


def pt_seg(x, s, e):
    dx, dy = e[0] - s[0], e[1] - s[1]
    L = dx * dx + dy * dy
    t = 0 if L == 0 else max(0, min(1, ((x[0] - s[0]) * dx + (x[1] - s[1]) * dy) / L))
    return math.hypot(x[0] - s[0] - t * dx, x[1] - s[1] - t * dy)


def seg_dist(p, q, a, b):
    d = lambda u, v, w: (v[0] - u[0]) * (w[1] - u[1]) - (v[1] - u[1]) * (w[0] - u[0])
    if d(p, q, a) * d(p, q, b) < 0 and d(a, b, p) * d(a, b, q) < 0:
        return 0.0
    return min(pt_seg(p, a, b), pt_seg(q, a, b), pt_seg(a, p, q), pt_seg(b, p, q))


def inside_px(pt, poly):
    x, y = pt
    hit = False
    for i in range(len(poly)):
        (x1, y1), (x2, y2) = poly[i], poly[(i + 1) % len(poly)]
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
            hit = not hit
    return hit


def edge_dist(pt, poly):
    d = min(pt_seg(pt, poly[i], poly[(i + 1) % len(poly)]) for i in range(len(poly)))
    return d if inside_px(pt, poly) else -d


def body_fits(p, poly):
    a, b = (p[0] - CAP_HALF, p[1] + CAP_DY), (p[0] + CAP_HALF, p[1] + CAP_DY)
    if not inside_px((p[0], p[1] + CAP_DY), poly):
        return False
    return all(seg_dist(a, b, poly[i], poly[(i + 1) % len(poly)]) > CAP_R for i in range(len(poly)))


def body_touches(p, shape):
    a, b = (p[0] - CAP_HALF, p[1] + CAP_DY), (p[0] + CAP_HALF, p[1] + CAP_DY)
    kind, c, ext = shape
    if kind == "circle":
        return seg_dist(a, b, c, c) < CAP_R + ext
    hx, hy = ext
    if c[0] - hx <= a[0] <= c[0] + hx and c[1] - hy <= a[1] <= c[1] + hy:
        return True
    cs = [(c[0] - hx, c[1] - hy), (c[0] + hx, c[1] - hy), (c[0] + hx, c[1] + hy), (c[0] - hx, c[1] + hy)]
    return min(seg_dist(a, b, cs[i], cs[(i + 1) % 4]) for i in range(4)) < CAP_R


def reach(shape, poly):
    """Whole-pixel player positions where the body fits inside the polygon and overlaps the trigger."""
    kind, c, ext = shape
    r = int((ext if kind == "circle" else max(ext)) + CAP_R + CAP_HALF + 2)
    n = 0
    for x in range(int(c[0]) - r, int(c[0]) + r + 1):
        for y in range(int(c[1]) - r + 4, int(c[1]) + r + 5):
            if body_touches((x, y), shape) and body_fits((x, y), poly):
                n += 1
    return n


def shape_of(node, nodes, subs, vec):
    for ch in nodes:
        if ch["parent"] == node["path"] and ch["type"] == "CollisionShape2D":
            sid = re.search(r'SubResource\("([^"]+)"\)', ch["props"].get("shape", ""))
            if not sid:
                continue
            kind, props = subs[sid.group(1)]
            if kind == "CircleShape2D":
                return ("circle", ch["global"], float(props["radius"]))
            if kind == "RectangleShape2D":
                s = vec(props["size"])
                return ("rect", ch["global"], (s[0] / 2, s[1] / 2))
    return None


def camera_centre(bounds, point):
    out = []
    for i in range(2):
        lo, hi, view = bounds[0][i], bounds[0][i] + bounds[1][i], VIEW[i]
        low, high = lo + view / 2, hi - view / 2
        if high >= low:
            out.append(min(max(round(point[i]), math.ceil(low)), math.floor(high)))
        else:
            lo_i, hi_i = math.ceil(high), math.floor(low)
            out.append(round((high + low) / 2) if lo_i > hi_i else min(max(round(view / 2), lo_i), hi_i))
    return tuple(out)


def bounds_px(poly):
    px = B.perimeter_px(poly)
    xs, ys = [p[0] for p in px], [p[1] for p in px]
    return ((min(xs) - 16, min(ys) - 64), (max(xs) - min(xs) + 32, max(ys) - min(ys) + 80))


def poly_area(p):
    return abs(sum(B.cross(p[i], p[(i + 1) % len(p)]) for i in range(len(p)))) / 2


def tex_name(n, ext):
    m = re.search(r'ExtResource\("([^"]+)"\)', n["props"].get("texture", ""))
    return ext.get(m.group(1), "?").split("/")[-1] if m else ""


report = {}
for room, w, h in ROOMS:
    w, h = int(w), int(h)
    path = os.path.join(ROOT, "scenes", "chapters", "ch01", "rooms", room + ".tscn")
    text, ext, subs, nodes, by, vec = parse(path)
    poly = B.canonical([[0, 0], [w, 0], [w, h], [0, h]])
    R = {"room": room, "w": w, "h": h, "root": by[""]["name"]}
    # Floor.
    tilemaps = {}
    for n in nodes:
        if n["type"] == "TileMapLayer":
            m = re.search(r"tile_map_data = PackedByteArray\(([^)]*)\)", n["body"])
            tilemaps[n["path"]] = (n["props"].get("position"), B.decode_tiles(m.group(1)) if m else {})
    pos, cells = tilemaps["TileMapLayer_Floor"]
    gen = set(B.floor_cells(poly))
    hist = {}
    for v in cells.values():
        hist[str(v[0])] = hist.get(str(v[0]), 0) + 1
    R["floor"] = {"layer_pos": pos, "hand": len(cells), "gen": len(gen),
                  "missing_in_hand": sorted(gen - set(cells)), "extra_in_hand": sorted(set(cells) - gen), "sources": hist}
    R["other_tilemaps"] = [(k, v[0], len(v[1]), sorted(v[1])) for k, v in tilemaps.items() if k != "TileMapLayer_Floor"]
    # Collision.
    coll = by["PerimeterWalls/CollisionPolygon2D"]
    nums = [float(v) for v in re.search(r"PackedVector2Array\(([^)]*)\)", coll["props"]["polygon"]).group(1).split(",")]
    hpoly = [(nums[i], nums[i + 1]) for i in range(0, len(nums), 2)]
    gpoly = B.perimeter_px(poly)
    g25 = B.perimeter_px(poly, 0.25)
    R["poly"] = {"build_mode": coll["props"].get("build_mode"), "hand_px": hpoly, "hand_tile": [px_to_tile(p) for p in hpoly],
                 "gen_px": gpoly, "gen25_px": g25, "hand_area": poly_area(hpoly), "gen_area": poly_area(gpoly),
                 "body_pos": by["PerimeterWalls"]["global"], "coll_pos": coll["global"]}
    # Walls.
    mods, odd = B.wall_modules(poly)
    hand_walls = {n["name"]: n for n in nodes if n["parent"] == "YSort_Walls" and re.match(r"Wall[NW]_\d+$", n["name"])}
    gen_walls, cnt = [], {"N": 0, "W": 0}
    for fc, p in mods:
        gen_walls.append(("Wall%s_%d" % (fc, cnt[fc]), p))
        cnt[fc] += 1
    gw = dict(gen_walls)
    diffs = []
    for nm, p in gen_walls:
        if nm not in hand_walls:
            diffs.append((nm, None, p))
        elif hand_walls[nm]["global"] != p:
            diffs.append((nm, hand_walls[nm]["global"], p))
    diffs += [(nm, n["global"], None) for nm, n in hand_walls.items() if nm not in gw]
    R["walls"] = {"hand_N": sum(1 for k in hand_walls if k.startswith("WallN")), "hand_W": sum(1 for k in hand_walls if k.startswith("WallW")),
                  "gen_N": cnt["N"], "gen_W": cnt["W"], "diffs": diffs,
                  "hand_list": [(nm, n["global"]) for nm, n in hand_walls.items()],
                  "props": sorted({"%s = %s" % (k, v if k != "texture" else tex_name(n, ext))
                                   for n in hand_walls.values() for k, v in n["props"].items() if k != "position"}),
                  "odd": odd,
                  "other": [(n["name"], n["global"], px_to_tile(n["global"]), tex_name(n, ext)) for n in nodes
                            if n["parent"] == "YSort_Walls" and not re.match(r"Wall[NW]_\d+$", n["name"])]}
    # Camera.
    gb = bounds_px(poly)
    cents = sorted({camera_centre(gb, B.tile_to_px(x + 0.5, y + 0.5)) for x, y in gen})
    R["camera"] = {"gen_bounds": gb, "centres": cents, "meta": "metadata/room_shape" in by[""]["body"]}
    # Triggers (Area2D under the root) and markers.
    trig = []
    for n in nodes:
        if n["type"] != "Area2D" or n["parent"] != ".":
            continue
        s = shape_of(n, nodes, subs, vec)
        if s is None:
            continue
        isdoor = "door_id" in n["props"]
        t = {"name": n["name"], "door": isdoor, "pos": n["global"], "tile": px_to_tile(n["global"]),
             "shape": [s[0], s[1], s[2]], "d_hand": edge_dist(s[1], hpoly), "d_gen": edge_dist(s[1], gpoly)}
        if isdoor or n["name"] == "checkpoint":
            t["reach_hand"], t["reach_gen"], t["reach_gen25"] = reach(s, hpoly), reach(s, gpoly), reach(s, g25)
            t["d_gen25"] = edge_dist(s[1], g25)
        trig.append(t)
    R["triggers"] = trig
    R["markers"] = [{"name": n["path"], "pos": n["global"], "tile": px_to_tile(n["global"]),
                     "fits_hand": body_fits(n["global"], hpoly), "fits_gen": body_fits(n["global"], gpoly),
                     "d_hand": edge_dist((n["global"][0], n["global"][1] + CAP_DY), hpoly),
                     "d_gen": edge_dist((n["global"][0], n["global"][1] + CAP_DY), gpoly)}
                    for n in nodes if n["type"] == "Marker2D"]
    if room == "arrival_platform":
        skip = {"", "PerimeterWalls", "PerimeterWalls/CollisionPolygon2D", "TileMapLayer_Floor", "RoomVisuals", "YSort_Walls", "Wall_Fixtures", "YSort_Actors"}
        objs = []
        for n in nodes:
            if n["path"] in skip or n["type"] in ("CollisionShape2D", "AudioStreamPlayer2D"):
                continue
            s = shape_of(n, nodes, subs, vec) if n["type"] in ("Area2D", "StaticBody2D") else None
            p = s[1] if (s and n["type"] == "StaticBody2D") else n["global"]
            objs.append({"path": n["path"], "type": n["type"], "pos": p, "tile": px_to_tile(p), "tex": tex_name(n, ext),
                         "shape": None if s is None else [s[0], s[2]],
                         "offset": n["props"].get("offset") or n["props"].get("sprite_offset"),
                         "z": n["props"].get("z_index")})
        R["objects"] = objs
    report[room] = R
json.dump(report, open(sys.argv[3], "w"), indent=1)
print("ok", len(report))
