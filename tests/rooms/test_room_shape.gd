extends "res://tests/support/base_test.gd"

## RoomShape (ADR-023 R2/R3, TLF-065): floor, collision, wall segments and bounds from a tile outline.
## Review Focus 4 (concave corner) and 5 (winding / collinear points) are covered here.

## 12 x 12 with the south-east 6 x 6 quarter cut away: the inner corner (6, 6) joins two low faces.
const L_SOUTH_EAST: Array = [Vector2(0, 0), Vector2(12, 0), Vector2(12, 6), Vector2(6, 6), Vector2(6, 12), Vector2(0, 12)]
## 12 x 12 with the north-east quarter cut away: the inner corner (6, 6) joins a tall N face and a low E face.
const L_NORTH_EAST: Array = [Vector2(0, 0), Vector2(6, 0), Vector2(6, 6), Vector2(12, 6), Vector2(12, 12), Vector2(0, 12)]


func _shape(points: Array) -> RoomShape:
	var shape := RoomShape.new()
	shape.outline = PackedVector2Array(points)
	return shape


## StringNames as alphabetically sorted Strings (Array.sort() does not order StringNames by text).
func _sorted_names(names: Array) -> Array:
	var out: Array = names.map(func(n: StringName) -> String: return String(n))
	out.sort()
	return out


func _faces_of(shape: RoomShape, kind: StringName) -> Array:
	return shape.wall_segments().filter(func(s: Dictionary) -> bool: return s["kind"] == kind)


## 25 x 16 (Maintenance Bay v2): ADR-003 / ROOM_GRAPH §1 math, and the same tiles, tile positions
## and wall-module positions as the room scene in the project.
func test_rectangle_matches_adr003_math() -> void:
	var shape := RoomShape.rectangle(26, 16)
	_assert_eq(shape.floor_cells().size(), 416, "26 x 16 = 416 floor tiles")
	_assert_eq(shape.perimeter_polygon_px(), PackedVector2Array([Vector2(320, 64), Vector2(736, 272), Vector2(480, 400), Vector2(64, 192)]),
		"diamond corners: N (320,64), E, S, W")
	var bounds := shape.bounds_px()
	_assert_eq(bounds.size.x, (26 + 16) * 16 + 2 * RoomShape.MARGIN_SIDE, "bounds width = (W+H)*16 = 672 + margins")
	_assert_eq(bounds.size.y, (26 + 16) * 8 + RoomShape.MARGIN_TOP + RoomShape.MARGIN_BOTTOM, "bounds height = (W+H)*8 = 336 + margins")
	_assert_eq(bounds.position, Vector2(64 - RoomShape.MARGIN_SIDE, 64 - RoomShape.MARGIN_TOP), "bounds origin")
	_assert_true(RoomCamera.view_size().x >= bounds.size.x and RoomCamera.view_size().y >= bounds.size.y, "a 26 x 16 room fits the 960 x 540 screen area")

	var room: Node = load("res://scenes/chapters/ch01/rooms/maintenance_bay.tscn").instantiate()
	var floor_layer := room.get_node("TileMapLayer_Floor") as TileMapLayer
	var used: Array[Vector2i] = floor_layer.get_used_cells()
	used.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	_assert_eq(used, shape.floor_cells(), "same 416 tiles as the maintenance bay's floor layer")
	for t in [Vector2i(0, 0), Vector2i(25, 0), Vector2i(0, 15), Vector2i(25, 15), Vector2i(13, 8)]:
		_assert_eq(floor_layer.position + floor_layer.map_to_local(t), RoomShape.tile_to_px(Vector2(t) + Vector2(0.5, 0.5)),
			"tile %s centre: TileMapLayer == tile_to_px(t + 0.5)" % t)
	var n_walls := shape.wall_segments().filter(func(s: Dictionary) -> bool: return s["kind"] == &"straight" and s["face"] == &"N")
	_assert_eq(n_walls.size(), 1, "one straight N segment")
	_assert_eq([n_walls[0]["from"], n_walls[0]["to"]], [Vector2i(0, 0), Vector2i(26, 0)], "N segment along y = 0")
	for k in 13:
		_assert_eq(room.get_node("YSort_Walls/WallN_%d" % k).position, RoomShape.tile_to_px(Vector2(2 * k + 1, 0)),
			"WallN_%d sits on the middle of its two-tile edge" % k)
	for j in 8:
		_assert_eq(room.get_node("YSort_Walls/WallW_%d" % j).position, RoomShape.tile_to_px(Vector2(0, 2 * j + 1)),
			"WallW_%d sits on the middle of its two-tile edge" % j)
	room.free()
	_assert_eq(shape.hidden_floor_cells(), [], "a rectangle hides no floor behind its walls")


## Arrival Platform v2: 30x18 L-shape room matches metadata/room_shape, 360 floor tiles,
## 15 N and 9 W modules, zero hidden floor cells.
func test_arrival_platform_v2_shape_matches_scene() -> void:
	var room: Node = load("res://scenes/chapters/ch01/rooms/arrival_platform.tscn").instantiate()
	var shape: RoomShape = room.get_meta("room_shape", null)
	_assert_true(shape != null, "arrival_platform has metadata/room_shape")
	_assert_eq(shape.floor_cells().size(), 360, "360 floor tiles")
	_assert_eq(shape.hidden_floor_cells(), [], "hidden_floor_cells is empty (Rule R2)")

	var floor_layer := room.get_node("TileMapLayer_Floor") as TileMapLayer
	var used: Array[Vector2i] = floor_layer.get_used_cells()
	used.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	_assert_eq(used, shape.floor_cells(), "scene floor cells match shape.floor_cells()")

	for k in 15:
		_assert_eq(room.get_node("YSort_Walls/WallN_%d" % k).position, RoomShape.tile_to_px(Vector2(2 * k + 1, 0)),
			"WallN_%d sits on the middle of its two-tile edge" % k)
	for j in 9:
		_assert_eq(room.get_node("YSort_Walls/WallW_%d" % j).position, RoomShape.tile_to_px(Vector2(0, 2 * j + 1)),
			"WallW_%d sits on the middle of its two-tile edge" % j)
	room.free()


func test_l_shape_floor_and_collision_agree() -> void:
	var shape := _shape(L_SOUTH_EAST)
	var cells := shape.floor_cells()
	_assert_eq(cells.size(), 144 - 36, "12 x 12 minus the 6 x 6 cut-out")
	var poly := shape.perimeter_polygon_px()
	var outside := 0
	for t in cells:
		if not Geometry2D.is_point_in_polygon(RoomShape.tile_to_px(Vector2(t) + Vector2(0.5, 0.5)), poly):
			outside += 1
	_assert_eq(outside, 0, "every floor tile centre is inside the collision polygon")
	for t in [Vector2i(6, 6), Vector2i(9, 9), Vector2i(11, 11), Vector2i(6, 11)]:
		_assert_false(shape.contains_tile(t), "tile %s in the cut-out is not floor" % t)
		_assert_false(Geometry2D.is_point_in_polygon(RoomShape.tile_to_px(Vector2(t) + Vector2(0.5, 0.5)), poly),
			"tile %s in the cut-out is outside the collision polygon" % t)
	for t in [Vector2i(5, 5), Vector2i(11, 5), Vector2i(5, 11)]:
		_assert_true(shape.contains_tile(t), "tile %s next to the cut-out is floor" % t)
	var outset := shape.perimeter_polygon_px(0.25)
	for i in poly.size():
		_assert_false(Geometry2D.is_point_in_polygon(outset[i], poly), "outset corner %d lies outside the floor" % i)
	_assert_eq(outset.size(), poly.size(), "outset keeps the corner count")


func test_winding_and_collinear_points_are_equivalent() -> void:
	var reference := _shape(L_SOUTH_EAST)
	var reversed := L_SOUTH_EAST.duplicate()
	reversed.reverse()
	var rotated := L_SOUTH_EAST.slice(3) + L_SOUTH_EAST.slice(0, 3)
	var collinear := [Vector2(0, 0), Vector2(4, 0), Vector2(12, 0), Vector2(12, 3), Vector2(12, 6), Vector2(6, 6),
		Vector2(6, 6), Vector2(6, 12), Vector2(3, 12), Vector2(0, 12), Vector2(0, 5), Vector2(0, 0)]
	for variant in [["counter-clockwise", reversed], ["other start vertex", rotated], ["collinear, repeated and closing points", collinear]]:
		var shape := _shape(variant[1])
		_assert_eq(shape.canonical_outline(), reference.canonical_outline(), "%s: same canonical outline" % variant[0])
		_assert_eq(shape.floor_cells(), reference.floor_cells(), "%s: same floor" % variant[0])
		_assert_eq(shape.perimeter_polygon_px(), reference.perimeter_polygon_px(), "%s: same collision" % variant[0])
		_assert_eq(shape.wall_segments(), reference.wall_segments(), "%s: same wall segments" % variant[0])
		_assert_eq(shape.bounds_px(), reference.bounds_px(), "%s: same bounds" % variant[0])
	var diagonal := _shape([Vector2(0, 0), Vector2(4, 0), Vector2(0, 4)])
	_assert_false(diagonal.is_valid(), "a non-rectilinear outline is refused")
	_assert_eq(diagonal.floor_cells(), [], "no floor from an invalid outline")


## R2: south/east faces are low, also around a concave corner; only N/W faces are tall.
func test_inner_corner_emits_low_south_east_faces_only() -> void:
	var shape := _shape(L_SOUTH_EAST)
	for seg in _faces_of(shape, &"straight"):
		var from: Vector2i = seg["from"]
		var to: Vector2i = seg["to"]
		var mid := (Vector2(from) + Vector2(to)) * 0.5
		var along_x := from.y == to.y
		# The floor side of the edge: probe half a tile on each side.
		var floor_south_or_east := shape.contains_tile(Vector2i((mid + (Vector2(0, 0.5) if along_x else Vector2(0.5, 0))).floor()))
		var expected: StringName = (&"N" if floor_south_or_east else &"low_S") if along_x else (&"W" if floor_south_or_east else &"low_E")
		_assert_eq(seg["face"], expected, "edge %s-%s: face %s" % [from, to, expected])
	var inner := _faces_of(shape, &"inner_corner")
	_assert_eq(inner.size(), 1, "one concave corner")
	_assert_eq(inner[0]["from"], Vector2i(6, 6), "at (6, 6)")
	_assert_eq(_sorted_names(inner[0]["faces"]), ["low_E", "low_S"], "the concave corner joins two low faces, no N/W wall")
	_assert_true(String(inner[0]["face"]).begins_with("low_"), "the corner piece is low")
	_assert_eq(_faces_of(shape, &"outer_corner").size(), 5, "five convex corners")
	var tall := shape.wall_segments().filter(func(s: Dictionary) -> bool: return s["face"] == &"N" or s["face"] == &"W")
	_assert_eq(tall.map(func(s: Dictionary) -> Array: return [s["kind"], s["from"], s["to"]]),
		[[&"straight", Vector2i(0, 0), Vector2i(12, 0)], [&"straight", Vector2i(0, 0), Vector2i(0, 12)],
			[&"outer_corner", Vector2i(0, 0), Vector2i(0, 0)], [&"outer_corner", Vector2i(12, 0), Vector2i(12, 0)],
			[&"outer_corner", Vector2i(0, 12), Vector2i(0, 12)]],
		"tall faces only on the two back edges and the three corners where they start or end")
	_assert_eq(shape.hidden_floor_cells(), [], "nothing hides floor around a low/low concave corner")


## Review Focus 4, the geometry: a concave corner where a TALL face meets a low one (an L cut on
## the north-east) puts the start of that tall wall in front of the floor diagonal behind the
## corner. hidden_floor_cells() reports those tiles so the layout or the art kit must handle them.
func test_tall_face_at_a_concave_corner_is_reported_as_hiding_floor() -> void:
	var shape := _shape(L_NORTH_EAST)
	var inner := _faces_of(shape, &"inner_corner")
	_assert_eq(inner.size(), 1, "one concave corner")
	_assert_eq(_sorted_names(inner[0]["faces"]), ["N", "low_E"], "it joins the tall N face of the south part and a low E face")
	# The tiles behind the corner in the north arm, nearest first along the diagonal. The same list
	# comes out of tools/content/build_room_from_shape.py (its R2 report) for this outline.
	_assert_eq(shape.hidden_floor_cells(), [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(4, 4), Vector2i(5, 4), Vector2i(5, 5)],
		"six tiles behind the corner are partly covered by the start of the N wall")


## Review Focus 4, the physics: the real player walks with move keys into the concave corner of a
## collision polygon generated from the shape and along both low faces; every frame it stays on
## the floor (no clipping through a low partition) and it does reach the corner.
func test_concave_corner_walk_stays_inside_collision() -> void:
	var shape := _shape(L_SOUTH_EAST)
	var poly := shape.perimeter_polygon_px()
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	walls.collision_mask = 0
	var collision := CollisionPolygon2D.new()
	collision.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	collision.polygon = poly
	walls.add_child(collision)
	_tree().root.add_child(walls)
	var player := load("res://scenes/player/Player.tscn").instantiate() as Player
	player.position = RoomShape.tile_to_px(Vector2(3.5, 3.5))
	_tree().root.add_child(player)
	await physics_frames(2)
	var corner := RoomShape.tile_to_px(Vector2(6, 6))
	var escaped := 0
	var closest := INF
	# Into the cut-out from the north (across low_S), then from the west (across low_E), then
	# diagonally into the corner itself; each push long enough to slide along the face.
	for goal in [Vector2(9, 9), Vector2(9, 3), Vector2(3, 9), Vector2(9, 9), Vector2(8, 8)]:
		var target := RoomShape.tile_to_px(goal)
		for i in 90:
			steer(player, target)
			await physics_frames(1)
			# Independent of the collision polygon: the tile under the player must be floor.
			if not shape.contains_tile(Vector2i(RoomShape.px_to_tile(player.global_position).floor())):
				escaped += 1
			closest = minf(closest, player.global_position.distance_to(corner))
	hold_moves([])
	_assert_eq(escaped, 0, "the player never stood on a tile outside the floor")
	_assert_true(closest < 24.0, "the player reached the concave corner (closest %.1f px)" % closest)
	player.free()
	walls.free()
