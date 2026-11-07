extends "res://tests/support/base_test.gd"

## TLF-071: a room scene written by tools/content/build_room_from_shape.py agrees with RoomShape.
## The fixture is the builder's output for a 26 x 16 L (south-east 6 x 6 cut) over the Arrival
## Platform's 14 x 10 floor, with 3 hole cells over an underlay, doors W (0,5), N (8,0), E (25,4),
## S (8,15) and --edge-strip 2. tools/content/test_build_room_from_shape.py keeps it current.

const BUILT := "res://tests/rooms/fixtures/builder_l_room.tscn"
const OUTLINE := [Vector2(0, 0), Vector2(26, 0), Vector2(26, 10), Vector2(20, 10), Vector2(20, 16), Vector2(0, 16)]
const HOLES: Array[Vector2i] = [Vector2i(3, 12), Vector2i(3, 13), Vector2i(3, 14)]
const DOOR_TILES: Array[Vector2i] = [Vector2i(0, 5), Vector2i(8, 0), Vector2i(25, 4), Vector2i(8, 15)]
const STRIP_SOURCE := 2


func _room() -> Node2D:
	return (load(BUILT) as PackedScene).instantiate() as Node2D


func _by_row(cells: Array[Vector2i]) -> Array[Vector2i]:
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return cells


func test_built_room_carries_its_room_shape() -> void:
	var room := _room()
	_assert_true(room.has_meta(&"room_shape"), "metadata/room_shape on the room root")
	var shape := room.get_meta(&"room_shape") as RoomShape
	_assert_true(shape != null and shape.is_valid(), "it is a valid RoomShape")
	_assert_eq(shape.outline, PackedVector2Array(OUTLINE), "with the builder's (canonical) outline")
	# Worked by hand from the outline corners: x 64..736, y 64..352, plus the side/top/bottom margins.
	_assert_eq(shape.bounds_px(), Rect2(48, 0, 704, 368), "bounds")
	_assert_true(shape.bounds_px().size.x > RoomCamera.view_size().x and shape.bounds_px().size.y > RoomCamera.view_size().y,
		"larger than the 640 x 360 view on both axes: the camera scrolls")
	room.free()


func test_floor_is_the_shape_minus_holes_with_the_underlay_below() -> void:
	var room := _room()
	var shape := room.get_meta(&"room_shape") as RoomShape
	var floor_layer := room.get_node("TileMapLayer_Floor") as TileMapLayer
	var expected: Array[Vector2i] = []
	for c in shape.floor_cells():
		if not HOLES.has(c):
			expected.append(c)
	_assert_eq(_by_row(floor_layer.get_used_cells()), expected, "floor = RoomShape.floor_cells() minus the holes (377)")
	_assert_eq(expected.size(), 377, "26 x 16 - 36 - 3")
	for c in HOLES:
		_assert_true(shape.contains_tile(c), "hole %s is inside the outline" % c)
		_assert_eq(floor_layer.get_cell_source_id(c), -1, "hole %s has no floor tile" % c)
	var underlay := room.get_node("Underlay") as Polygon2D
	_assert_true(underlay != null and underlay.z_index < floor_layer.z_index, "the underlay is kept and draws below the floor")
	for t in [Vector2i(0, 0), Vector2i(25, 9), Vector2i(19, 15), Vector2i(10, 12)]:
		_assert_eq(floor_layer.position + floor_layer.map_to_local(t), RoomShape.tile_to_px(Vector2(t) + Vector2(0.5, 0.5)),
			"tile %s centre: TileMapLayer == tile_to_px(t + 0.5)" % t)
	room.free()


## The strip is on exactly the cells whose S or E neighbour is outside the outline, door tiles
## excepted; the old 14 x 10 strip (x = 13, y = 9) is gone and kept cells keep their tile.
func test_edge_strip_follows_the_new_south_and_east_edges() -> void:
	var room := _room()
	var shape := room.get_meta(&"room_shape") as RoomShape
	var floor_layer := room.get_node("TileMapLayer_Floor") as TileMapLayer
	var expected: Array[Vector2i] = []
	for c in shape.floor_cells():
		var edge := not shape.contains_tile(c + Vector2i(0, 1)) or not shape.contains_tile(c + Vector2i(1, 0))
		if edge and not DOOR_TILES.has(c) and not HOLES.has(c):
			expected.append(c)
	var strip: Array[Vector2i] = floor_layer.get_used_cells_by_id(STRIP_SOURCE)
	_assert_eq(_by_row(strip), expected, "strip cells")
	_assert_eq(strip.size(), 38, "38 strip cells")
	for c in [Vector2i(13, 0), Vector2i(13, 8), Vector2i(0, 9), Vector2i(12, 9)]:
		_assert_eq(floor_layer.get_cell_source_id(c), 0, "old strip cell %s back to terrazzo" % c)
	for c in [Vector2i(6, 1), Vector2i(11, 0), Vector2i(4, 8)]:
		_assert_eq(floor_layer.get_cell_source_id(c), 1, "kept cell %s keeps its cracked-terrazzo tile" % c)
	room.free()


func test_collision_is_the_outline_outset_a_quarter_tile() -> void:
	var room := _room()
	var shape := room.get_meta(&"room_shape") as RoomShape
	var poly := (room.get_node("PerimeterWalls/CollisionPolygon2D") as CollisionPolygon2D).polygon
	_assert_eq(poly, shape.perimeter_polygon_px(0.25), "PerimeterWalls = perimeter_polygon_px(0.25)")
	for c in shape.floor_cells():
		if not Geometry2D.is_point_in_polygon(RoomShape.tile_to_px(Vector2(c) + Vector2(0.5, 0.5)), poly):
			_assert_true(false, "tile %s centre is inside the collision" % c)
	room.free()


## One module per two tile edges of each straight N / W face, on the middle of its edges; the W
## door at (0, 5) has its archway exactly on WallW_2's pivot, so that module is left to it. The N
## door at (8, 0) straddles WallN_3 / WallN_4, which stay.
func test_wall_modules_follow_the_tall_faces_and_leave_the_aligned_archway() -> void:
	var room := _room()
	var shape := room.get_meta(&"room_shape") as RoomShape
	var walls := room.get_node("YSort_Walls")
	var expected := {}
	var count := {&"N": 0, &"W": 0}
	for s in shape.wall_segments():
		if s["kind"] != &"straight" or not (s["face"] == &"N" or s["face"] == &"W"):
			continue
		var from := Vector2(s["from"])
		var step := (Vector2(s["to"]) - from).sign()
		for k in range(0, int((Vector2(s["to"]) - from).length()) - 1, 2):
			expected["Wall%s_%d" % [s["face"], count[s["face"]]]] = RoomShape.tile_to_px(from + step * (k + 1))
			count[s["face"]] += 1
	expected.erase("WallW_2")
	var actual := {}
	for child in walls.get_children():
		if String(child.name).begins_with("WallN_") or String(child.name).begins_with("WallW_"):
			actual[String(child.name)] = child.position
	_assert_eq(actual, expected, "13 N and 7 W modules at their pivots, WallW_2 left to the archway")
	_assert_eq(walls.get_node("Archway_door_w").position, RoomShape.tile_to_px(Vector2(0, 5)), "the W archway on the left-out pivot")
	_assert_true(walls.has_node("WallN_3") and walls.has_node("WallN_4"), "modules under the straddling N archway stay")
	_assert_eq(shape.hidden_floor_cells(), [], "no tall wall hides floor in this L (cut on the low side)")
	room.free()
