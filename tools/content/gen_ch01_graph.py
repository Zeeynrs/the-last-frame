"""Generate data/chapters/ch01/ch01_graph.tres (ChapterGraphDef) from the reviewed design docs.

Sources (single source of truth, never retyped):
  - design/ch01/ROOM_GRAPH.md  §2 room table (footprints, doors with side + tile, safe anchors)
                               §3.2 static edges E1..E7
  - design/ch01/puzzles/CH1-PZ-005.md §4.2 State 0 column (dynamic doorway pairs)
Run from the repo root:  python tools/content/gen_ch01_graph.py
"""
import io
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ROOM_GRAPH = os.path.join(ROOT, "design", "ch01", "ROOM_GRAPH.md")
PZ005 = os.path.join(ROOT, "design", "ch01", "puzzles", "CH1-PZ-005.md")
OUT = os.path.join(ROOT, "data", "chapters", "ch01", "ch01_graph.tres")

ANCHOR_ROOM = "ch01.arrival_platform"
CRITICAL_PAIRS = [["ch01.signal_control", "ch01.upper_vestibule"], ["ch01.arrival_platform", "ch01.upper_vestibule"]]
# Rooms that can be sealed off by a transform -> where stranded actors go (CH1-PZ-005 §5).
RELOCATION_OVERRIDES = {"ch01.vestibule_niche": "ch01.upper_vestibule.safe_anchor_center"}


def gd(value):
    """Python value -> Godot text-resource literal."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        return '"%s"' % value
    if isinstance(value, list):
        return "[" + ", ".join(gd(v) for v in value) + "]"
    if isinstance(value, dict):
        return "{\n" + ",\n".join('"%s": %s' % (k, gd(v)) for k, v in value.items()) + "\n}"
    raise TypeError(value)


def main():
    rg = io.open(ROOM_GRAPH, encoding="utf-8").read()
    rooms = []
    for line in rg.splitlines():
        m = re.match(r"^\| \*\*\d+\*\* \| `(ch01\.[a-z0-9_]+)` \|(.*)$", line)
        if not m:
            continue
        cells = [c.strip() for c in m.group(2).split("|")]
        # cells: beats, purpose, footprint, camera, doorways, puzzles, checkpoint, safe anchors
        w, h = map(int, re.search(r"`(\d+) × (\d+)`", cells[2]).groups())
        doors = [{"door_id": d, "side": s, "x": int(x), "y": int(y)}
                 for d, s, x, y in re.findall(r"`(door_[a-z_]+)` \(\*\*([NSEW])\*\*, `\((\d+), (\d+)\)`", cells[4])]
        anchors = [{"id": a, "x": int(x), "y": int(y)}
                   for a, x, y in re.findall(r"`(ch01\.[a-z0-9_.]+)` @ `\((\d+), (\d+)\)`", cells[7])]
        rooms.append({"room_id": m.group(1), "width": w, "height": h, "doors": doors, "safe_anchors": anchors})

    pairs = []
    for a_room, a_door, b_room, b_door in re.findall(
            r"^\| \*\*E\d\*\* \| Static \| `(ch01\.[a-z_]+):(door_[a-z_]+)`.*?\| `(ch01\.[a-z_]+):(door_[a-z_]+)`", rg, re.M):
        pairs.append([a_room, a_door, b_room, b_door, True])

    spec = io.open(PZ005, encoding="utf-8").read()
    for row in re.findall(r"^\| \*\*Edge \d[^|]*\*\* \| (.+?) \|", spec, re.M):
        ends = re.findall(r"`(ch01\.[a-z_]+):(door_[a-z_]+)`", row)
        pair = [ends[0][0], ends[0][1], ends[1][0], ends[1][1], "Grille" not in row]
        key = sorted([f"{pair[0]}:{pair[1]}", f"{pair[2]}:{pair[3]}"])
        if not any(sorted([f"{p[0]}:{p[1]}", f"{p[2]}:{p[3]}"]) == key for p in pairs):
            pairs.append(pair)

    relocation = {r["room_id"]: r["safe_anchors"][0]["id"] for r in rooms if r["safe_anchors"]}
    relocation.update(RELOCATION_OVERRIDES)

    declared = sum(len(r["doors"]) for r in rooms)
    paired = {f"{p[0]}:{p[1]}" for p in pairs} | {f"{p[2]}:{p[3]}" for p in pairs}
    problems = []
    if len(rooms) != 10:
        problems.append(f"expected 10 rooms, parsed {len(rooms)}")
    if declared != len(paired):
        problems.append(f"{declared} doorways declared, {len(paired)} paired")
    if problems:
        print("\n".join(problems))
        sys.exit(1)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    text = (
        '[gd_resource type="Resource" script_class="ChapterGraphDef" load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" path="res://scripts/spatial/chapter_graph_def.gd" id="1_def"]\n\n'
        "[resource]\n"
        'script = ExtResource("1_def")\n'
        'chapter_id = "ch01"\n'
        f'anchor_room = &"{ANCHOR_ROOM}"\n'
        f"rooms = {gd(rooms)}\n"
        f"initial_pairs = {gd(pairs)}\n"
        f"critical_pairs = {gd(CRITICAL_PAIRS)}\n"
        f"relocation_anchors = {gd(relocation)}\n"
    )
    io.open(OUT, "w", encoding="utf-8", newline="\n").write(text)
    print(f"ok: {len(rooms)} rooms, {declared} doorways, {len(pairs)} pairs -> {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
