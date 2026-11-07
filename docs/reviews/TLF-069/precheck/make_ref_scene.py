"""TLF-069 review tooling: a reference Arrival Platform v2 scene from the approved layout table.

Runs tools/content/build_room_from_shape.py on the current arrival scene (outline, outset 0.25,
edge strip 2 on S/E, door E,29,4 so the doorway tile stays unpainted), then moves the existing
nodes to the layout tiles. Positions only: no low partitions, corners, new props or art. The
result is for probing (capsule reach, door sweep, statue clearance, camera); it is not Flash's
scene and is never committed as the room.

usage: python make_ref_scene.py <repo> <out.tscn> [--set node=x,y ...] [--no-door]
  --set n04_cleaner=25,7   overrides a layout tile (tile coordinates, may be fractional)
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

OUTLINE = [[0, 0], [30, 0], [30, 8], [12, 8], [12, 18], [0, 18]]

# node path (as in the .tscn: name or parent/name) -> layout tile (vertex), design/ch01/rooms_v2/arrival_platform.md 2
LAYOUT = {
    "safe_anchor_spawn": (5, 15),
    "checkpoint": (6, 14),
    "pocket_watch_pickup": (8, 13),
    "operator_sighting": (9, 10),
    "n02_student": (3, 10),
    "n03_old_man": (10, 2),
    "n01_conductor": (14, 3),
    "n04_cleaner": (23, 7),
    "doc_last_service": (6, 1),
    "selector_line": (21, 1),
    "selector_platform": (23, 1),
    "selector_car": (25, 1),
    "release_lever": (29, 2),
    "door_exit_east": (29, 4),
    "platform_gate": (29, 4),
    "YSort_Walls/Archway_door_exit_east": (29, 4),
    "YSort_Actors/StalledTransitCar": (22, 12),
}
# px offsets kept from today's scene (relative to another node's layout tile)
FOLLOW = {
    "YSort_Actors/PlatformBench": ("n03_old_man", (0, 8)),      # bench beside n03, as today
}
# N wall clocks: today 38 px above the wall vertex (5,0) and (11,0); the layout puts them at (5,0), (17,0)
FIXED_PX = {
    "Wall_Fixtures/Clock_2": lambda: px((5, 0), (0, -38)),
    "Wall_Fixtures/Clock_5": lambda: px((17, 0), (0, -38)),
}


def px(t, off=(0, 0)):
    x, y = t
    return (320 + (x - y) * 16 + off[0], 64 + (x + y) * 8 + off[1])


def fmt(v):
    return "Vector2(%s, %s)" % tuple(("%g" % c) for c in v)


def set_position(text, path, pos):
    name, parent = (path.split("/")[-1], path.rsplit("/", 1)[0]) if "/" in path else (path, ".")
    head = '[node name="%s" type="' % name
    i = 0
    while True:
        i = text.find(head, i)
        if i < 0:
            raise SystemExit("node %s not found" % path)
        line_end = text.index("\n", i)
        if ('parent="%s"' % parent) in text[i:line_end]:
            break
        i = line_end
    block_end = text.find("\n[", line_end)
    block_end = len(text) if block_end < 0 else block_end
    block = text[line_end:block_end]
    if re.search(r"^position = .*$", block, re.M):
        block = re.sub(r"^position = .*$", "position = " + fmt(pos), block, count=1, flags=re.M)
    else:
        block = "\nposition = " + fmt(pos) + block
    return text[:line_end] + block + text[block_end:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("repo")
    ap.add_argument("out")
    ap.add_argument("--set", action="append", default=[])
    ap.add_argument("--no-door", action="store_true", help="build without --door E,29,4 (as the task text says)")
    a = ap.parse_args()
    layout = dict(LAYOUT)
    for s in a.set:
        k, v = s.split("=")
        layout[k] = tuple(float(c) for c in v.split(","))
    room = os.path.join(a.repo, "scenes/chapters/ch01/rooms/arrival_platform.tscn")
    with tempfile.TemporaryDirectory() as tmp:
        shape = os.path.join(tmp, "shape.json")
        json.dump({"outline": OUTLINE}, open(shape, "w"))
        built = os.path.join(tmp, "built.tscn")
        door = [] if a.no_door else ["--door", "E,%d,%d" % tuple(int(c) for c in layout["door_exit_east"])]
        r = subprocess.run([sys.executable, os.path.join(a.repo, "tools/content/build_room_from_shape.py"),
                            "--edge-strip", "2,S,E", *door, "--out", built, shape, room],
                           capture_output=True, text=True)
        sys.stderr.write(r.stdout.split("diff:")[0])
        if r.returncode != 0:
            sys.stderr.write(r.stderr)
            raise SystemExit("builder exit %d" % r.returncode)
        text = open(built, encoding="utf-8").read()
    for path, tile in layout.items():
        text = set_position(text, path, px(tile))
    for path, (ref, off) in FOLLOW.items():
        text = set_position(text, path, px(layout[ref], off))
    for path, f in FIXED_PX.items():
        text = set_position(text, path, f())
    open(a.out, "w", encoding="utf-8", newline="\n").write(text)
    print("wrote %s" % a.out)
    for path, tile in sorted(layout.items()):
        print("  %-36s tile %-12s px %s" % (path, tile, px(tile)))


if __name__ == "__main__":
    main()
