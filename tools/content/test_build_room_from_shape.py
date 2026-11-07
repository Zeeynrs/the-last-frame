"""Tests for build_room_from_shape.py (TLF-071).

  python -m unittest discover -s tools/content -p "test_*.py" -v

Godot side: tests/rooms/test_room_builder_output.gd loads the scene this file keeps current
(tests/rooms/fixtures/builder_l_room.tscn) and checks it against RoomShape and RoomRouter.
"""
import contextlib
import io
import os
import re
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import build_room_from_shape as B  # noqa: E402

ROOMS_DIR = os.path.join(REPO, "scenes", "chapters", "ch01", "rooms")
FIXTURES = os.path.join(REPO, "tests", "rooms", "fixtures")

# W x H from design/ch01/ROOM_GRAPH.md §2, and the options that reproduce today's hand-built art:
# arrival's platform-edge strip skips its east-door row; security_crossing's trench column is empty.
ROOMS = {
    "arrival_platform": (14, 10, {"strip": (2, ("S", "E")), "doors": [("E", (13, 5))]}),
    "concourse_west": (16, 12, {}),
    "maintenance_bay": (14, 10, {}),
    "security_crossing": (16, 12, {"holes": B.parse_cells("9,0..11")}),
    "waiting_lounge": (12, 10, {}),
    "signal_control": (16, 12, {}),
    "upper_vestibule": (14, 14, {}),
    "vestibule_niche": (6, 6, {}),
    "station_atrium": (16, 14, {}),
    "street_exit": (12, 10, {}),
}

WALL_RE = r'\[node name="Wall[NW]_\d+" type="Sprite2D" parent="YSort_Walls"\]\n(?:(?!\[).*\n?)*'


def read(path):
    with open(path, encoding="utf-8", newline="") as fh:
        return fh.read()


def rect(w, h):
    return B.canonical([[0, 0], [w, 0], [w, h], [0, h]])


def floor_data(text):
    return re.search(r"tile_map_data = PackedByteArray\(([^)]*)\)", B.node_block(text, "TileMapLayer_Floor").group(0)).group(1)


def polygon(text):
    s = re.search(r"polygon = PackedVector2Array\(([^)]*)\)", B.node_block(text, "CollisionPolygon2D", "PerimeterWalls").group(0)).group(1)
    v = [float(x) for x in s.split(",")]
    return [(v[i], v[i + 1]) for i in range(0, len(v), 2)]


def build_room(name, **override):
    w, h, opts = ROOMS[name]
    opts = dict(opts, **override)
    path = os.path.join(ROOMS_DIR, name + ".tscn")
    return read(path), B.build(read(path), rect(w, h), holes=opts.get("holes", ()), doors=opts.get("doors", ()),
                               strip=opts.get("strip"), room_path=path)


def run_cli(*argv):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = B.main(list(argv))
    return code, out.getvalue()


class TenRoomsRoundTrip(unittest.TestCase):
    def test_floor_and_walls_equal_the_hand_built_rooms(self):
        for name in ROOMS:
            with self.subTest(room=name):
                old, (new, _) = build_room(name)
                self.assertEqual(floor_data(new), floor_data(old), "floor tile_map_data (cells, sources, order)")
                self.assertEqual(re.findall(WALL_RE, new), re.findall(WALL_RE, old), "WallN_* / WallW_* nodes")

    def test_security_crossing_needs_the_trench_hole(self):
        old, (new, notes) = build_room("security_crossing", holes=())
        cells = B.decode_tiles(floor_data(new))
        self.assertEqual(len(cells), 192)
        self.assertEqual({cells[(9, y)][0] for y in range(12)}, {4}, "without --holes the trench is filled with the room's base source")
        self.assertIn("12 new with source 4", notes[0])

    def test_new_tiles_use_the_room_default_source(self):
        self.assertEqual({r: B.default_tile_source(r + ".tscn") for r in ROOMS},
                         {r: (4 if r in ("maintenance_bay", "security_crossing", "signal_control") else 0) for r in ROOMS})
        self.assertEqual(B.default_tile_source("scenes/chapters/ch01/rooms/signal_control.tscn"), 4)

    def test_collision_is_the_outline_outset_a_quarter_tile(self):
        for name, (w, h, _) in ROOMS.items():
            with self.subTest(room=name):
                _, (new, _) = build_room(name)
                expected = [B.tile_to_px(-0.25, -0.25), B.tile_to_px(w + 0.25, -0.25),
                            B.tile_to_px(w + 0.25, h + 0.25), B.tile_to_px(-0.25, h + 0.25)]
                self.assertEqual(polygon(new), expected)

    def test_room_shape_metadata_on_the_root(self):
        for name, (w, h, _) in ROOMS.items():
            with self.subTest(room=name):
                _, (new, _) = build_room(name)
                self.assertEqual(new.count('path="res://scripts/rooms/room_shape.gd"'), 1)
                self.assertIn('[sub_resource type="Resource" id="room_shape"]\nscript = ExtResource("room_shape_script")\n'
                              'outline = PackedVector2Array(0, 0, %d, 0, %d, %d, 0, %d)\n' % (w, w, h, h), new)
                root = re.search(r'^\[node name="[^"]+" type="Node2D"\]\n((?:(?!\[).*\n?)*)', new, re.M).group(1)
                self.assertIn('metadata/room_shape = SubResource("room_shape")', root)
                self.assertLess(new.index("[sub_resource type=\"Resource\" id=\"room_shape\"]"), new.index("[node "))

    def test_rebuild_is_idempotent(self):
        for name, (w, h, opts) in ROOMS.items():
            with self.subTest(room=name):
                _, (once, _) = build_room(name)
                twice, _ = B.build(once, rect(w, h), holes=opts.get("holes", ()), doors=opts.get("doors", ()),
                                   strip=opts.get("strip"), room_path=name + ".tscn")
                self.assertEqual(twice, once)

    def test_only_floor_collision_walls_and_metadata_change(self):
        """Nothing else in the scene moves: removing the touched parts leaves the scene identical."""
        for name in ROOMS:
            with self.subTest(room=name):
                old, (new, _) = build_room(name)

                def rest(t):
                    t = re.sub(r"tile_map_data = PackedByteArray\([^)]*\)", "", t)
                    t = re.sub(WALL_RE, "", t)
                    t = re.sub(r'\[ext_resource type="Script"[^\n]*room_shape\.gd[^\n]*\]\n', "", t)
                    t = re.sub(r'\[sub_resource type="Resource" id="room_shape"\]\n(?:(?!\[).*\n?)*', "", t)
                    t = t.replace('metadata/room_shape = SubResource("room_shape")\n', "")
                    coll = B.node_block(t, "CollisionPolygon2D", "PerimeterWalls")
                    return t[:coll.start()] + re.sub(r"polygon = PackedVector2Array\([^)]*\)", "", coll.group(0)) + t[coll.end():]
                self.assertEqual(rest(new), rest(old))


class Doors(unittest.TestCase):
    def test_module_under_an_aligned_archway_is_left_to_it(self):
        old, (new, notes) = build_room("concourse_west", doors=[("W", (0, 5)), ("E", (15, 5))])
        self.assertNotIn('[node name="WallW_2"', new)
        self.assertIn('[node name="WallW_3"', new, "the other modules keep their names")
        self.assertIn('[node name="Archway_door_entry_west"', new)
        self.assertEqual(len(re.findall(WALL_RE, new)), len(re.findall(WALL_RE, old)) - 1)
        self.assertTrue(any("left to the archway Archway_door_entry_west" in n for n in notes))

    def test_archway_across_two_modules_is_reported_not_cut(self):
        old, (new, notes) = build_room("security_crossing", doors=[("W", (0, 6)), ("E", (15, 6))])
        self.assertEqual(re.findall(WALL_RE, new), re.findall(WALL_RE, old))
        self.assertTrue(any(n.startswith("door W (0, 6): NOT CUT") and "(240, 104), (208, 120)" in n for n in notes), notes)

    def test_north_doors_in_today_s_rooms(self):
        """Odd offset = aligned (vestibule N (7,0), niche N (3,0)); even = across two modules
        (lounge (6,0), signal (8,0), atrium (8,0))."""
        cases = {"upper_vestibule": (7, True), "vestibule_niche": (3, True), "waiting_lounge": (6, False),
                 "signal_control": (8, False), "station_atrium": (8, False)}
        for name, (x, aligned) in cases.items():
            with self.subTest(room=name):
                old, (new, notes) = build_room(name, doors=[("N", (x, 0))])
                removed = len(re.findall(WALL_RE, old)) - len(re.findall(WALL_RE, new))
                self.assertEqual(removed, 1 if aligned else 0, notes)

    def test_module_without_an_archway_sprite_is_kept(self):
        _, (new, notes) = build_room("arrival_platform", doors=[("E", (13, 5)), ("W", (0, 5))])
        self.assertIn('[node name="WallW_2"', new)
        self.assertTrue(any("KEPT module at (240, 104), no archway sprite" in n for n in notes), notes)

    def test_door_must_be_a_boundary_tile_of_its_face(self):
        shape = os.path.join(FIXTURES, "builder_l_room.json")
        room = os.path.join(FIXTURES, "builder_template.tscn")
        for bad in ("E,12,5", "W,1,5", "N,8,1", "S,24,15", "X,0,0", "E,13"):
            with self.subTest(door=bad):
                code, out = run_cli(shape, room, "--door", bad)
                self.assertEqual(code, 2, out)
                self.assertTrue(out.startswith("ERROR:"), out)


class EdgeStrip(unittest.TestCase):
    def test_parse(self):
        self.assertEqual(B.parse_strip("2"), (2, ("S", "E")))
        self.assertEqual(B.parse_strip("2,S"), (2, ("S",)))
        self.assertEqual(B.parse_strip("2,SE"), (2, ("S", "E")))
        self.assertEqual(B.parse_strip("2,e,s"), (2, ("E", "S")))
        with self.assertRaises(ValueError):
            B.parse_strip("2,N")

    def test_arrival_strip_is_reproduced_without_its_door_row(self):
        cells = B.strip_cells(rect(14, 10), ("S", "E"), (), [("E", (13, 5))])
        expected = {(13, y) for y in range(10) if y != 5} | {(x, 9) for x in range(14)}
        self.assertEqual(cells, expected)
        self.assertEqual(len(cells), 22)

    def test_strip_does_not_clear_trench_side_tactile_tiles(self):
        old, (new, notes) = build_room("security_crossing", strip=(2, ("S", "E")))
        before, after = B.decode_tiles(floor_data(old)), B.decode_tiles(floor_data(new))
        for c in [(8, y) for y in range(12)] + [(10, y) for y in range(12)]:
            if c in before and before[c][0] == 2:
                self.assertEqual(after[c][0], 2, "trench-side %s kept" % (c,))
        self.assertIn("0 old strip cells back to source 4", notes[1])

    def test_one_face_only(self):
        """Only the named faces are painted and cleared; the other face's strip is left as it is."""
        poly = B.canonical([[0, 0], [14, 0], [14, 6], [0, 6]])   # arrival cut to rows 0-5
        old = read(os.path.join(ROOMS_DIR, "arrival_platform.tscn"))
        new, _ = B.build(old, poly, strip=(2, ("S",)), doors=[("E", (13, 5))], room_path="arrival_platform.tscn")
        cells = B.decode_tiles(floor_data(new))
        self.assertEqual({c for c, v in cells.items() if v[0] == 2},
                         {(x, 5) for x in range(13)} | {(13, y) for y in range(5)},
                         "new S row 5 painted (the door cell (13,5) skipped), the E column kept")


class LOutlineFixture(unittest.TestCase):
    """26 x 16 with the SE corner (x >= 20, y >= 10) cut, built over arrival's 14 x 10 floor."""
    SHAPE = os.path.join(FIXTURES, "builder_l_room.json")
    TEMPLATE = os.path.join(FIXTURES, "builder_template.tscn")
    BUILT = os.path.join(FIXTURES, "builder_l_room.tscn")
    ARGS = ["--edge-strip", "2"]

    @classmethod
    def setUpClass(cls):
        """The checks below run on a fresh build; the committed fixture must equal it."""
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "built.tscn")
            cls.code, cls.log = run_cli(cls.SHAPE, cls.TEMPLATE, *cls.ARGS, "--out", out)
            cls.text = read(out) if cls.code == 0 else ""

    def test_committed_fixture_is_the_current_builder_output(self):
        self.assertEqual(self.code, 0, self.log)
        self.assertEqual(self.text, read(self.BUILT),
                         "regenerate: python tools/content/build_room_from_shape.py %s %s %s --out %s"
                         % (self.SHAPE, self.TEMPLATE, " ".join(self.ARGS), self.BUILT))

    def test_floor_cells_sources_and_holes(self):
        cells = B.decode_tiles(floor_data(self.text))
        expected = {(x, y) for y in range(16) for x in range(26) if not (x >= 20 and y >= 10)} - {(3, 12), (3, 13), (3, 14)}
        self.assertEqual(set(cells), expected)
        self.assertEqual(len(cells), 377)
        old = B.decode_tiles(floor_data(read(self.TEMPLATE)))
        cracked = [c for c, v in old.items() if v[0] == 1]
        self.assertEqual(len(cracked), 11)
        self.assertTrue(all(cells[c][0] == 1 for c in cracked), "kept cells keep their source")
        self.assertEqual(cells[(20, 0)][0], 0, "new cells get the base source")

    def test_strip_on_the_new_edge_and_cleared_from_the_old(self):
        cells = B.decode_tiles(floor_data(self.text))
        strip = {c for c, v in cells.items() if v[0] == 2}
        expected = ({(25, y) for y in range(10) if y != 4} | {(x, 9) for x in range(20, 26)}
                    | {(19, y) for y in range(10, 16)} | {(x, 15) for x in range(20) if x != 8})
        self.assertEqual(strip, expected)
        self.assertEqual(len(strip), 38)
        self.assertEqual(cells[(13, 3)][0], 0, "old E strip cleared")
        self.assertEqual(cells[(5, 9)][0], 0, "old S strip cleared")

    def test_polygon(self):
        # The outline outset 1/4 tile, worked by hand: px = (320 + (x - y) * 16, 64 + (x + y) * 8).
        self.assertEqual(polygon(self.text), [(320, 60), (744, 272), (576, 356), (480, 308), (384, 356), (56, 192)])

    def test_walls_and_archways(self):
        text = self.text
        walls = {m.group(1): (float(m.group(2)), float(m.group(3))) for m in re.finditer(
            r'\[node name="(Wall[NW]_\d+)" type="Sprite2D" parent="YSort_Walls"\]\nposition = Vector2\(([^,]+), ([^)]+)\)', text)}
        expected = {"WallN_%d" % k: B.tile_to_px(2 * k + 1, 0) for k in range(13)}
        expected.update({"WallW_%d" % k: B.tile_to_px(0, 2 * k + 1) for k in range(8) if k != 2})
        self.assertEqual(walls, expected)
        for arch in ("Archway_door_w", "Archway_door_n", "Archway_door_e", "Archway_door_s"):
            self.assertIn('[node name="%s"' % arch, text)


class Cells(unittest.TestCase):
    def test_parse_cells(self):
        self.assertEqual(B.parse_cells("9,0..2"), [(9, 0), (9, 1), (9, 2)])
        self.assertEqual(B.parse_cells("1,2; 3,4 5..6,7"), [(1, 2), (3, 4), (5, 7), (6, 7)])
        self.assertEqual(B.parse_cells(""), [])
        with self.assertRaises(ValueError):
            B.parse_cells("1,2,3")


if __name__ == "__main__":
    unittest.main()
