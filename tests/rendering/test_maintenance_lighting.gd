extends "res://tests/support/base_test.gd"

## TLF-085 Maintenance Bay v2 lighting (ADR-026 maintenance, ADR-027 round 2). The dark stress test at
## A 3 failed (decision objects and doorways merge into 00, the lift-2 Elias zone draws a floor
## capsule; docs/handoffs/TLF-085/light), so the room ships at the ADR-026 fallback A 2 with the
## standard 1/0 Elias zone. One purposeful cue: a floor pool at the fire shutter's casting spot and a
## body region over the fire shutter and the counterweight gear (steel/actor indices only, never the
## wall ramp behind them). The concrete floor is in the floor ramp (TLF-085 recolour), so the fill and
## the shade reach it.

const BAY := "res://scenes/chapters/ch01/rooms/maintenance_bay.tscn"
const CONCRETE := "res://assets/environments/ch01/ch01_env_tile_concrete_service_idle.png"
const FLOOR_RAMP := [0, 1, 2, 3, 4, 5]
const BODY_INDICES := [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]


func _bay(s: Node) -> Node2D:
	var room := (load(BAY) as PackedScene).instantiate() as Node2D
	s.add_child(room)
	return room


func test_maintenance_bay_is_lit_at_the_a2_fallback() -> void:
	var s := make_session()
	var room := _bay(s)
	var lit := room.get_meta(&"lighting") as RoomLighting
	_assert_true(lit != null, "maintenance_bay has metadata/lighting")
	_assert_eq(lit.ambient_steps, 2, "A 2: the ADR-026 fallback after the failed A 3 stress test")
	_assert_eq(lit.exempt_from, 25, "exempt from 25")
	_assert_true(lit.shadows, "shadows on (ADR-027)")
	_assert_eq(lit.fill_lift, 1, "fill 1")
	_assert_eq(lit.effective_fill(), 1, "the fill applies at A 2")
	_assert_eq(lit.fill_mode, RoomLighting.FillMode.ADD, "fill mode ADD")
	_assert_true(lit.elias_zone, "Elias zone on")
	_assert_eq(Vector2i(lit.elias_lift_inner, lit.elias_lift_outer), Vector2i(1, 0), "Elias zone 1/0 (body at k 1; no floor capsule against fill 1)")
	_assert_eq(lit.elias_radius, Vector2(18, 28), "Elias zone radius (covers every body pixel inside 0.85)")
	_assert_true(lit.elias_inner >= 0.85, "Elias zone inner band 0.85")
	var bounds := (room.get_meta(&"room_shape") as RoomShape).bounds_px()
	_assert_eq(LightingPass.validate_room(room, lit, bounds), PackedStringArray(), "the room's lighting validates")
	free_session(s)


func test_one_cue_at_the_fire_shutter_and_gear() -> void:
	var s := make_session()
	var room := _bay(s)
	var lights := LightingPass.room_lights(room)
	_assert_eq(lights.size(), 2, "two RoomLight entries: one cue (floor pool + body region)")
	var floor_light := room.get_node("Lighting/ShutterFloor") as RoomLight
	var body := room.get_node("Lighting/ShutterGearBody") as RoomLight
	_assert_eq(floor_light.shape, RoomLight.Shape.ELLIPSE, "floor pool: ellipse")
	_assert_eq(Vector2i(floor_light.lift_inner, floor_light.lift_outer), Vector2i(2, 1), "floor pool 2/1 (Sol: one cue 2/1)")
	_assert_eq(Array(floor_light.only_indices), FLOOR_RAMP, "floor pool lifts the floor ramp only")
	var d := func(p: Vector2) -> float:
		return ((p - floor_light.global_position) / floor_light.radius).length()
	_assert_true(d.call(Vector2(480, 208)) < floor_light.inner, "the casting spot (480,208) is in the pool's core (%.2f)" % d.call(Vector2(480, 208)))
	_assert_true(d.call(Vector2(512, 224)) < 1.0, "the fire shutter aperture (512,224) is in the pool")
	_assert_true(d.call(Vector2(560, 248)) >= 1.0, "the inner shutter (560,248) is not: one cue only")
	_assert_eq(body.shape, RoomLight.Shape.QUAD, "body region: quad")
	_assert_eq(body.lift_inner, 2, "body region lift 2")
	_assert_eq(Array(body.only_indices), BODY_INDICES, "body region lifts steel/actor indices 11-24 only")
	for i in range(6, 11):
		_assert_false(i in body.only_indices, "the wall ramp index %02d behind the gear is never lifted (no spill on the wall)" % i)
	var quad := PackedVector2Array()
	for q in body.quad:
		quad.append(body.global_transform * q)
	for path in ["counterweight_gear/Presenter", "fire_shutter/Presenter"]:
		var spr := room.get_node(path) as Sprite2D
		await physics_frames(1)
		var r := spr.get_global_transform() * spr.get_rect()
		for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			_assert_true(Geometry2D.is_point_in_polygon(corner, quad) or quad.has(corner), "%s corner %s inside the body region" % [path, corner])
	free_session(s)


func test_the_concrete_floor_takes_the_fill_and_the_shade() -> void:
	var img := (load(CONCRETE) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	var used := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				used[TlfPalette.nearest_index(c)] = true
	var indices := used.keys()
	indices.sort()
	_assert_eq(indices, [1, 3, 4], "concrete_service is drawn in the floor ramp 01/03/04 (TLF-085 recolour; was steel 11/12/13)")
	for i in indices:
		_assert_true(((LightingPass.RECEIVERS >> i) & 1) == 1, "concrete index %02d is a floor receiver" % i)
	var s := make_session()
	var room := _bay(s)
	var shape := room.get_meta(&"room_shape") as RoomShape
	var r := ShadeBaker.bake(room)
	var count := 0
	for v in (r["floor"] as Image).get_data():
		count += v
	var area := shape.floor_cells().size() * 256
	_assert_eq(shape.floor_cells().size(), 416, "26 x 16 floor cells")
	_assert_true(absf(count - area) < 0.02 * area, "the floor mask covers the whole floor: %d px vs %d" % [count, area])
	free_session(s)
