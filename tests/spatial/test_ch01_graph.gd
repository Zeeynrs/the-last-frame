extends "res://tests/support/base_test.gd"

## Chapter 1 ChapterGraphDef (TLF-026), generated from design/ch01/ROOM_GRAPH.md + CH1-PZ-005 §4.2.

const DEF_PATH := "res://data/chapters/ch01/ch01_graph.tres"
const ARRIVAL := &"ch01.arrival_platform"
const VEST := &"ch01.upper_vestibule"
const NICHE := &"ch01.vestibule_niche"
const ATRIUM := &"ch01.station_atrium"
const STREET := &"ch01.street_exit"
const LEVER_A_TO_B := [[VEST, &"door_west", VEST, &"door_east"], [VEST, &"door_north", NICHE, &"door_in"]]
const LEVER_B_TO_B := [[VEST, &"door_north", ATRIUM, &"door_entry_south"], [NICHE, &"door_in", NICHE, &"door_out", false]]
const OPPOSITE := {"E": "W", "W": "E", "N": "S", "S": "N"}


func _def() -> ChapterGraphDef:
	return load(DEF_PATH) as ChapterGraphDef


func test_definition_builds_a_valid_graph() -> void:
	var def := _def()
	_assert_true(def != null, "definition loads")
	_assert_eq(def.rooms.size(), 10, "10 rooms")
	var doors := 0
	for room in def.rooms:
		doors += room["doors"].size()
	_assert_eq(doors, 20, "20 doorways")
	_assert_true(def.build_graph() != null, "every doorway paired exactly once, critical pairs hold")


func test_state0_reachability_and_the_grille() -> void:
	var g := _def().build_graph()
	var unreachable := g.get_unreachable_rooms(ARRIVAL)
	_assert_eq(unreachable, [ATRIUM, STREET], "only atrium + street are behind the grille in State 0")


func test_solving_pz005_opens_the_rest_of_the_chapter_and_backtracking_works() -> void:
	var g := _def().build_graph()
	_assert_true(g.apply(LEVER_A_TO_B)["ok"], "lever A")
	_assert_true(g.apply(LEVER_B_TO_B)["ok"], "lever B")
	_assert_true(g.is_reachable(ARRIVAL, STREET), "street exit reachable from the start")
	_assert_true(g.is_reachable(STREET, ARRIVAL), "backtrack from the street to the start (ROOM_GRAPH §4.3)")
	_assert_eq(g.get_unreachable_rooms(ARRIVAL), [NICHE], "only the sealed niche is cut off in State 2")


func test_static_edges_connect_opposite_sides() -> void:
	var def := _def()
	var dynamic_rooms := [VEST, NICHE, ATRIUM]
	for pair in def.initial_pairs:
		var a := def.get_door(StringName(pair[0]), StringName(pair[1]))
		var b := def.get_door(StringName(pair[2]), StringName(pair[3]))
		var is_dynamic := StringName(pair[0]) in dynamic_rooms and StringName(pair[2]) in dynamic_rooms
		if is_dynamic:
			continue
		_assert_eq(OPPOSITE[a["side"]], b["side"], "%s:%s <-> %s:%s opposite sides" % pair.slice(0, 4))


func test_every_door_sits_on_its_boundary_wall() -> void:
	for room in _def().rooms:
		var w: int = room["width"]
		var h: int = room["height"]
		for door in room["doors"]:
			var x: int = door["x"]
			var y: int = door["y"]
			var ok := false
			match door["side"]:
				"W": ok = x == 0 and y >= 1 and y <= h - 2
				"E":
					if StringName(room["room_id"]) in [&"ch01.concourse_west", &"ch01.maintenance_bay"]:
						ok = (x == w or x == w - 1) and y >= 1 and y <= h - 2
					else:
						ok = x == w - 1 and y >= 1 and y <= h - 2
				"N": ok = y == 0 and x >= 1 and x <= w - 2
				"S": ok = y == h - 1 and x >= 1 and x <= w - 2
			_assert_true(ok, "%s:%s (%s @ %d,%d) on its wall in %dx%d" % [room["room_id"], door["door_id"], door["side"], x, y, w, h])


func test_every_room_fits_the_fixed_camera() -> void:
	for room in _def().rooms:
		if StringName(room["room_id"]) in [ARRIVAL, &"ch01.concourse_west", &"ch01.maintenance_bay"]:
			# ADR-023: arrival_platform v2 (30x18) and concourse_west v2 (28x16) use RoomCamera follow framing;
			# maintenance_bay v2 (26x16) fits 960x540 (camera fixed, not follow; tested explicitly in probe suite, not legacy 640x360).
			continue
		var w: int = room["width"]
		var h: int = room["height"]
		var left := ChapterGraphDef.tile_to_px(0, h)        # west corner of the floor diamond
		var right := ChapterGraphDef.tile_to_px(w, 0)       # east corner
		var bottom := ChapterGraphDef.tile_to_px(w, h)      # south corner
		# Rooms without metadata/room_shape use the old 640 x 360 screen area as camera bounds.
		var legacy := RoomCamera.LEGACY_SCREEN
		_assert_true(left.x >= legacy.position.x and right.x <= legacy.end.x, "%s fits horizontally (%d..%d)" % [room["room_id"], left.x, right.x])
		_assert_true(bottom.y <= legacy.end.y, "%s fits vertically (floor to y=%d)" % [room["room_id"], bottom.y])


func test_relocation_anchors_are_declared_safe_anchors() -> void:
	var def := _def()
	var declared := {}
	for room in def.rooms:
		for anchor in room["safe_anchors"]:
			declared[anchor["id"]] = true
	_assert_eq(def.relocation_anchors[String(NICHE)], "ch01.upper_vestibule.safe_anchor_center", "niche -> vestibule (PZ-005 §5)")
	for room_id in def.relocation_anchors.keys():
		_assert_true(declared.has(def.relocation_anchors[room_id]), "%s anchor is a declared SafeAnchor" % room_id)


func test_apply_to_configures_the_session_and_relocates_from_the_sealed_niche() -> void:
	var s := make_session()
	_assert_true(_def().apply_to(s.spatial_service), "applied")
	var moves: Array = []
	s.spatial_service.relocate_requested.connect(func(actor, anchor): moves.append([actor, anchor]))
	s.spatial_service.apply_transform(LEVER_A_TO_B)
	s.spatial_service.set_actor_room(&"player", NICHE)
	s.spatial_service.apply_transform(LEVER_B_TO_B)
	_assert_eq(moves, [[&"player", &"ch01.upper_vestibule.safe_anchor_center"]], "relocated out of the niche")
	free_session(s)


func test_cutting_the_start_off_the_vestibule_is_refused() -> void:
	var s := make_session()
	_def().apply_to(s.spatial_service)
	var cut := [[&"ch01.signal_control", &"door_exit_north", &"ch01.signal_control", &"door_exit_north"],
		[VEST, &"door_south", VEST, &"door_north"], [VEST, &"door_west", VEST, &"door_west"]]
	_assert_eq(s.spatial_service.validate_transform(cut).reason, &"critical_path_unreachable", "critical pair holds")
	free_session(s)
