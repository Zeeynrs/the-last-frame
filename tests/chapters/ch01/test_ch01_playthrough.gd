extends "res://tests/support/base_test.gd"

## Chapter 1 Rooms 1-10 & Playthrough Test Suite (TLF-009 / TLF-025).
## Verifies all 10 room scenes, IDs, door spawns, SpatialGraph configuration,
## passage collision blockers, PZ-004 switchback route, PZ-005 spatial levers/resetter,
## readables, intercom warning, and full scripted playthrough solving PZ-001..005 to outro.

const DEF_PATH := "res://data/chapters/ch01/ch01_graph.tres"
const ROOM_PATHS := {
	&"ch01.arrival_platform": "res://scenes/chapters/ch01/rooms/arrival_platform.tscn",
	&"ch01.concourse_west": "res://scenes/chapters/ch01/rooms/concourse_west.tscn",
	&"ch01.maintenance_bay": "res://scenes/chapters/ch01/rooms/maintenance_bay.tscn",
	&"ch01.security_crossing": "res://scenes/chapters/ch01/rooms/security_crossing.tscn",
	&"ch01.waiting_lounge": "res://scenes/chapters/ch01/rooms/waiting_lounge.tscn",
	&"ch01.signal_control": "res://scenes/chapters/ch01/rooms/signal_control.tscn",
	&"ch01.upper_vestibule": "res://scenes/chapters/ch01/rooms/upper_vestibule.tscn",
	&"ch01.vestibule_niche": "res://scenes/chapters/ch01/rooms/vestibule_niche.tscn",
	&"ch01.station_atrium": "res://scenes/chapters/ch01/rooms/station_atrium.tscn",
	&"ch01.street_exit": "res://scenes/chapters/ch01/rooms/street_exit.tscn"
}
const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_ch01_saves"
const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"


func _record_real_save_state() -> Dictionary:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	var mtime := FileAccess.get_modified_time(REAL_SAVE_SLOT_0) if exists else 0
	return {"exists": exists, "mtime": mtime}


func _assert_real_save_unchanged(before: Dictionary, context: String) -> void:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	_assert_eq(exists, before["exists"], "%s: real save existence unchanged" % context)
	if before["exists"]:
		var mtime := FileAccess.get_modified_time(REAL_SAVE_SLOT_0)
		_assert_eq(mtime, before["mtime"], "%s: real save modified time unchanged" % context)


func _cleanup_test_save_dir() -> void:
	var dir := DirAccess.open(TEST_SAVE_ROOT)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
		for sub_dir in dir.get_directories():
			dir.remove(sub_dir)
	if DirAccess.dir_exists_absolute(TEST_SAVE_ROOT):
		DirAccess.remove_absolute(TEST_SAVE_ROOT)


func _make_ch01() -> Node2D:
	_cleanup_test_save_dir()
	var ch01_scene := load(CH01_SCENE_PATH) as PackedScene
	var ch01 := ch01_scene.instantiate() as Node2D
	var router := ch01.get_node_or_null("RoomRouter") as RoomRouter
	if router != null:
		# Inject an isolated test SaveStore so real player saves in user://saves are never touched
		var store := SaveStore.new()
		store.name = "TestSaveStore"
		store.save_root = TEST_SAVE_ROOT
		router.add_child(store)
		router.save_service = store
	_tree().root.add_child(ch01)
	return ch01


func _cleanup_ch01(ch01: Node) -> void:
	if ch01 == null:
		return
	var router: RoomRouter = ch01.get_node_or_null("RoomRouter")
	if router != null and router.current_room != null:
		router._unload_current()
	if ch01.get_parent() != null:
		ch01.get_parent().remove_child(ch01)
	ch01.free()
	_cleanup_test_save_dir()


func _graph_def() -> ChapterGraphDef:
	return load(DEF_PATH) as ChapterGraphDef


func _descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		out.append(node)
		for child in node.get_children():
			stack.append(child)
	return out


func _has_journal_entry(journal: Array, key: String) -> bool:
	for entry in journal:
		if entry.get("key") == key:
			return true
	return false


func _segments_cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var ccw = func(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
		return (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
	var d1: float = ccw.call(c, d, a)
	var d2: float = ccw.call(c, d, b)
	var d3: float = ccw.call(a, b, c)
	var d4: float = ccw.call(a, b, d)
	return ((d1 > 0.0 and d2 < 0.0) or (d1 < 0.0 and d2 > 0.0)) and ((d3 > 0.0 and d4 < 0.0) or (d3 < 0.0 and d4 > 0.0))


func test_room_scenes_exist_and_instantiate() -> void:
	for room_id in ROOM_PATHS.keys():
		var path: String = ROOM_PATHS[room_id]
		_assert_true(ResourceLoader.exists(path), "Scene exists: %s" % path)
		var packed := load(path) as PackedScene
		_assert_true(packed != null, "Scene loads as PackedScene: %s" % path)
		var inst := packed.instantiate()
		_assert_true(inst != null, "Scene instantiates: %s" % path)
		inst.free()

	_assert_true(ResourceLoader.exists(CH01_SCENE_PATH), "Chapter01 scene exists")
	var ch01_packed := load(CH01_SCENE_PATH) as PackedScene
	_assert_true(ch01_packed != null, "Chapter01 loads as PackedScene")
	var ch01_inst := ch01_packed.instantiate()
	_assert_true(ch01_inst != null, "Chapter01 instantiates")
	ch01_inst.free()


func test_room_object_ids_are_valid_and_unique() -> void:
	var all_ids: Dictionary = {}
	for room_id in ROOM_PATHS.keys():
		var path: String = ROOM_PATHS[room_id]
		var inst := (load(path) as PackedScene).instantiate()
		var room_id_str := String(room_id)

		for node in _descendants(inst):
			var oid: StringName = &""
			if "object_id" in node:
				oid = node.get("object_id")
			if String(oid).is_empty():
				continue

			var sid := String(oid)
			_assert_true(sid.begins_with(room_id_str + ".") or sid == "global.pocket_watch", "ID '%s' follows prefix '%s.' or is global" % [sid, room_id_str])
			_assert_false(all_ids.has(sid), "ID '%s' is unique across all rooms" % sid)
			all_ids[sid] = true

		inst.free()


func test_every_door_has_spawn_outside_presenter_shape() -> void:
	for room_id in ROOM_PATHS.keys():
		var path: String = ROOM_PATHS[room_id]
		var inst := (load(path) as PackedScene).instantiate()

		for node in _descendants(inst):
			if node is DoorwayPresenter:
				var presenter := node as DoorwayPresenter
				var spawn := presenter.get_node_or_null("Spawn") as Node2D
				_assert_true(spawn != null, "%s:%s has Spawn child" % [room_id, presenter.door_id])
				if spawn != null:
					var col := presenter.get_node_or_null("CollisionShape2D") as CollisionShape2D
					_assert_true(col != null and col.shape != null, "%s:%s has collision shape" % [room_id, presenter.door_id])
					var threshold_radius: float = 10.0
					if col != null and col.shape is CircleShape2D:
						threshold_radius = (col.shape as CircleShape2D).radius
					var offset_dist: float = spawn.position.length()
					_assert_true(offset_dist > threshold_radius,
						"%s:%s Spawn offset (%.1f px) is outside presenter shape radius (%.1f px)" % [
							room_id, presenter.door_id, offset_dist, threshold_radius])

		inst.free()


func test_doorways_match_chapter_graph_def() -> void:
	var def := _graph_def()
	for room_id in ROOM_PATHS.keys():
		var path: String = ROOM_PATHS[room_id]
		var inst := (load(path) as PackedScene).instantiate()
		var room_def := def.get_room(room_id)
		_assert_false(room_def.is_empty(), "Room found in ChapterGraphDef: %s" % room_id)

		var declared_doors: Dictionary = {}
		for d in room_def.get("doors", []):
			declared_doors[StringName(d["door_id"])] = d

		for node in _descendants(inst):
			if node is DoorwayPresenter:
				var presenter := node as DoorwayPresenter
				_assert_true(declared_doors.has(presenter.door_id),
					"Doorway '%s' declared in graph def for '%s'" % [presenter.door_id, room_id])
				var d = declared_doors[presenter.door_id]
				var expected_px := ChapterGraphDef.tile_to_px(d["x"], d["y"])
				_assert_true((presenter.position - expected_px).length() < 1.0,
					"%s:%s position %s matches tile (%d,%d) -> %s" % [
						room_id, presenter.door_id, presenter.position, d["x"], d["y"], expected_px])

		inst.free()


func test_safe_anchors_and_checkpoints_match_specs() -> void:
	var def := _graph_def()
	for room_id in ROOM_PATHS.keys():
		var path: String = ROOM_PATHS[room_id]
		var inst := (load(path) as PackedScene).instantiate()
		var room_def := def.get_room(room_id)

		var declared_anchors: Dictionary = {}
		for a in room_def.get("safe_anchors", []):
			declared_anchors[a["id"]] = a

		var checkpoint_found := false
		for node in _descendants(inst):
			if node is SafeAnchor:
				var anchor := node as SafeAnchor
				var sid := String(anchor.object_id)
				_assert_true(declared_anchors.has(sid), "SafeAnchor '%s' declared in graph def" % sid)
				if declared_anchors.has(sid):
					var a = declared_anchors[sid]
					var expected_px := ChapterGraphDef.tile_to_px(a["x"], a["y"])
					_assert_true((anchor.position - expected_px).length() < 1.0,
						"Anchor %s position %s matches tile (%d,%d)" % [sid, anchor.position, a["x"], a["y"]])
			elif node is CheckpointZone:
				checkpoint_found = true
				var cp := node as CheckpointZone
				_assert_false(String(cp.checkpoint_id).is_empty(), "CheckpointZone has checkpoint_id in %s" % room_id)
				_assert_false(String(cp.spawn_anchor_id).is_empty(), "CheckpointZone has spawn_anchor_id in %s" % room_id)

		if room_id != &"ch01.vestibule_niche":
			_assert_true(checkpoint_found, "CheckpointZone present in %s" % room_id)
		inst.free()


func test_puzzle_objects_configured_with_correct_exports() -> void:
	# Concourse West: TurnstileGate
	var concourse := (load(ROOM_PATHS[&"ch01.concourse_west"]) as PackedScene).instantiate()
	var gate = concourse.get_node_or_null("turnstile_gate") as TurnstileGate
	_assert_true(gate != null, "turnstile_gate exists")
	_assert_eq(gate.puzzle_id, &"CH1-PZ-001", "gate puzzle_id is CH1-PZ-001")
	_assert_eq(gate.footprint_zone_id, &"ch01.concourse_west.turnstile_footprint", "gate footprint_zone_id")
	_assert_eq(gate.safe_anchor_id, &"ch01.concourse_west.safe_anchor_east", "gate safe_anchor_id")
	_assert_true(gate.get_node_or_null("Blocker") is CollisionObject2D, "gate has Blocker child")
	concourse.free()

	# Maintenance Bay: FireShutter & CounterweightGear
	var bay := (load(ROOM_PATHS[&"ch01.maintenance_bay"]) as PackedScene).instantiate()
	var shutter = bay.get_node_or_null("fire_shutter") as FireShutter
	var gear = bay.get_node_or_null("counterweight_gear") as CounterweightGear
	_assert_true(shutter != null, "fire_shutter exists")
	_assert_true(gear != null, "counterweight_gear exists")
	_assert_eq(shutter.puzzle_id, &"CH1-PZ-002", "shutter puzzle_id is CH1-PZ-002")
	_assert_eq(shutter.gear_id, &"ch01.maintenance_bay.counterweight_gear", "shutter gear_id")
	_assert_eq(shutter.threshold_zone_id, &"ch01.maintenance_bay.shutter_threshold_trigger", "shutter threshold_zone_id")
	_assert_eq(gear.shutter_id, &"ch01.maintenance_bay.fire_shutter", "gear shutter_id")
	_assert_true(shutter.get_node_or_null("Blocker") is CollisionObject2D, "shutter has Blocker child")
	bay.free()

	# Security Crossing: Gate, Bridge & Pickup
	var crossing := (load(ROOM_PATHS[&"ch01.security_crossing"]) as PackedScene).instantiate()
	var sgate = crossing.get_node_or_null("security_gate_01") as PlateLinkedGate
	var bridge = crossing.get_node_or_null("bridge_platform_01") as RetractableBridge
	var pickup = crossing.get_node_or_null("transit_pass_pickup") as ProgressionPickup
	_assert_true(sgate != null, "security_gate_01 exists")
	_assert_true(bridge != null, "bridge_platform_01 exists")
	_assert_true(pickup != null, "transit_pass_pickup exists")
	_assert_eq(sgate.plate_id, &"ch01.security_crossing.pressure_switch_01", "sgate plate_id")
	_assert_eq(bridge.plate_id, &"ch01.security_crossing.pressure_switch_01", "bridge plate_id")
	_assert_eq(bridge.bridge_zone_id, &"ch01.security_crossing.bridge_walk_zone", "bridge zone_id")
	_assert_eq(pickup.flag_id, &"ch01.flag.transit_pass", "pickup flag_id")
	_assert_true(sgate.get_node_or_null("Blocker") is CollisionObject2D, "sgate has Blocker child")
	_assert_true(bridge.get_node_or_null("Blocker") is CollisionObject2D, "bridge has Blocker child")
	crossing.free()

	# Signal Control: PZ-004 objects
	var sig := (load(ROOM_PATHS[&"ch01.signal_control"]) as PackedScene).instantiate()
	var cap = sig.get_node_or_null("surge_capacitor") as SurgeCapacitor
	var ba = sig.get_node_or_null("breaker_a") as TimedBreaker
	var bb = sig.get_node_or_null("breaker_b") as TimedBreaker
	var grid = sig.get_node_or_null("substation_grid") as SubstationGrid
	var vdoor = sig.get_node_or_null("vestibule_door") as PoweredDoor
	_assert_true(cap != null, "surge_capacitor exists")
	_assert_true(ba != null and bb != null, "breaker_a and breaker_b exist")
	_assert_true(grid != null, "substation_grid exists")
	_assert_true(vdoor != null, "vestibule_door exists")
	_assert_eq(cap.puzzle_id, &"CH1-PZ-004", "cap puzzle_id")
	_assert_eq(ba.puzzle_id, &"CH1-PZ-004", "ba puzzle_id")
	_assert_eq(bb.puzzle_id, &"CH1-PZ-004", "bb puzzle_id")
	_assert_eq(grid.puzzle_id, &"CH1-PZ-004", "grid puzzle_id")
	_assert_eq(vdoor.puzzle_id, &"CH1-PZ-004", "vdoor puzzle_id")
	_assert_eq(ba.capacitor_id, &"ch01.signal_control.surge_capacitor", "ba capacitor_id")
	_assert_eq(bb.capacitor_id, &"ch01.signal_control.surge_capacitor", "bb capacitor_id")
	_assert_eq(grid.capacitor_id, &"ch01.signal_control.surge_capacitor", "grid capacitor_id")
	_assert_eq(grid.breaker_a_id, &"ch01.signal_control.breaker_a", "grid breaker_a_id")
	_assert_eq(grid.breaker_b_id, &"ch01.signal_control.breaker_b", "grid breaker_b_id")
	_assert_eq(vdoor.grid_id, &"ch01.signal_control.substation_grid", "vdoor grid_id")
	_assert_true(vdoor.get_node_or_null("Blocker") is CollisionObject2D, "vdoor has Blocker child")
	sig.free()

	# Upper Vestibule: PZ-005 objects
	var vest := (load(ROOM_PATHS[&"ch01.upper_vestibule"]) as PackedScene).instantiate()
	var la = vest.get_node_or_null("junction_lever_a") as JunctionLever
	var lb = vest.get_node_or_null("junction_lever_b") as JunctionLever
	var resetter = vest.get_node_or_null("spatial_resetter") as SpatialStateResetter
	var board = vest.get_node_or_null("route_board") as Interactable
	_assert_true(la != null and lb != null, "junction levers exist")
	_assert_true(resetter != null, "spatial_resetter exists")
	_assert_true(board != null and board.traceable, "route_board exists and is traceable")
	_assert_eq(la.puzzle_id, &"CH1-PZ-005", "la puzzle_id")
	_assert_eq(lb.puzzle_id, &"CH1-PZ-005", "lb puzzle_id")
	_assert_eq(resetter.puzzle_id, &"CH1-PZ-005", "resetter puzzle_id")
	vest.free()


func test_passage_blockers_toggle_with_puzzle_state() -> void:
	var s := make_session()

	# 1. TurnstileGate starts blocked; rewind unblocks it
	var concourse := (load(ROOM_PATHS[&"ch01.concourse_west"]) as PackedScene).instantiate()
	s.add_child(concourse)
	var gate := concourse.get_node_or_null("turnstile_gate") as TurnstileGate
	_assert_true(gate.passage_blocked, "turnstile initially blocked")
	var gate_col := gate.get_node("Blocker/CollisionShape2D") as CollisionShape2D
	_assert_false(gate_col.disabled, "blocker shape initially active")
	gate.apply_state({"arm_state": &"open", "passage_blocked": false})
	_assert_false(gate.passage_blocked, "turnstile open after apply_state")
	s.remove_child(concourse)
	concourse.free()

	# 2. FireShutter starts blocked; rewound unblocks it
	var bay := (load(ROOM_PATHS[&"ch01.maintenance_bay"]) as PackedScene).instantiate()
	s.add_child(bay)
	var shutter := bay.get_node_or_null("fire_shutter") as FireShutter
	_assert_true(shutter.passage_blocked, "shutter initially blocked")
	shutter.apply_state({"shutter_state": &"raised", "hold_ticks": 180, "passage_blocked": false})
	_assert_false(shutter.passage_blocked, "shutter unblocked when raised")
	s.remove_child(bay)
	bay.free()

	# 3. RetractableBridge starts retracted; extended when plate occupied
	var crossing := (load(ROOM_PATHS[&"ch01.security_crossing"]) as PackedScene).instantiate()
	s.add_child(crossing)
	var bridge := crossing.get_node_or_null("bridge_platform_01") as RetractableBridge
	_assert_false(bridge.walkable, "bridge initially retracted")
	s.remove_child(crossing)
	crossing.free()

	# 4. PoweredDoor in signal_control starts blocked; unblocked when opened
	var sig := (load(ROOM_PATHS[&"ch01.signal_control"]) as PackedScene).instantiate()
	s.add_child(sig)
	var vdoor := sig.get_node_or_null("vestibule_door") as PoweredDoor
	_assert_true(vdoor.passage_blocked, "vestibule door initially blocked")
	vdoor._open()
	_assert_false(vdoor.passage_blocked, "vestibule door unblocked when open")
	s.remove_child(sig)
	sig.free()

	free_session(s)


func test_pz004_route_is_at_least_600_px() -> void:
	var sig := (load(ROOM_PATHS[&"ch01.signal_control"]) as PackedScene).instantiate() as Node2D
	var perim_node := sig.get_node("PerimeterWalls/CollisionPolygon2D") as CollisionPolygon2D
	var perim_poly := perim_node.polygon
	var south_col := sig.get_node("TrenchRailings/SouthRailingCollision") as CollisionShape2D
	var s_seg := south_col.shape as SegmentShape2D
	var north_col := sig.get_node("TrenchRailings/NorthRailingCollision") as CollisionShape2D
	var n_seg := north_col.shape as SegmentShape2D
	var barrier_col := sig.get_node_or_null("TrenchRailings/NorthBarrierCollision") as CollisionPolygon2D
	var barrier_poly: PackedVector2Array = barrier_col.polygon if barrier_col != null else PackedVector2Array()

	var w0 := Vector2(176, 152)  # Breaker A standing spot (1, 10)
	var w3 := Vector2(528, 184)  # Breaker B standing spot (14, 1)

	var cell_size := 4
	var min_x := 100
	var max_x := 600
	var min_y := 40
	var max_y := 320
	var cols := (max_x - min_x) / cell_size
	var rows := (max_y - min_y) / cell_size

	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, cols, rows)
	grid.cell_size = Vector2(cell_size, cell_size)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	grid.update()

	var player_radius := 6.0

	var is_walkable := func(pos: Vector2) -> bool:
		if not Geometry2D.is_point_in_polygon(pos, perim_poly):
			return false
		var n := perim_poly.size()
		for i in n:
			var p1 := perim_poly[i]
			var p2 := perim_poly[(i + 1) % n]
			if Geometry2D.get_closest_point_to_segment(pos, p1, p2).distance_to(pos) < player_radius:
				return false
		if Geometry2D.get_closest_point_to_segment(pos, s_seg.a, s_seg.b).distance_to(pos) < player_radius:
			return false
		if Geometry2D.get_closest_point_to_segment(pos, n_seg.a, n_seg.b).distance_to(pos) < player_radius:
			return false
		if barrier_poly.size() > 2:
			if Geometry2D.is_point_in_polygon(pos, barrier_poly):
				return false
			for i in barrier_poly.size():
				var p1 := barrier_poly[i]
				var p2 := barrier_poly[(i + 1) % barrier_poly.size()]
				if Geometry2D.get_closest_point_to_segment(pos, p1, p2).distance_to(pos) < player_radius:
					return false
		return true

	for c in cols:
		for r in rows:
			var pos := Vector2(min_x + c * cell_size + cell_size / 2.0, min_y + r * cell_size + cell_size / 2.0)
			if not is_walkable.call(pos):
				grid.set_point_solid(Vector2i(c, r), true)

	var start_coord := Vector2i(int((w0.x - min_x) / cell_size), int((w0.y - min_y) / cell_size))
	var goal_coord := Vector2i(int((w3.x - min_x) / cell_size), int((w3.y - min_y) / cell_size))

	_assert_false(grid.is_point_solid(start_coord), "W0 standing spot is walkable")
	_assert_false(grid.is_point_solid(goal_coord), "W3 standing spot is walkable")

	var path := grid.get_point_path(start_coord, goal_coord)
	_assert_true(path.size() > 1, "Walkable switchback path exists between W0 and W3")

	var total_path_length := 0.0
	for i in path.size() - 1:
		total_path_length += path[i].distance_to(path[i + 1])

	_assert_true(total_path_length >= 600.0,
		"Shortest walkable path on room collision (%.1f px) is >= 600.0 px (exceeds 300 ticks)" % total_path_length)

	# Assert breaker B's interaction area cannot be overlapped from any point south of the north railing
	var breaker_b := sig.get_node("breaker_b") as Area2D
	var b_pos := breaker_b.global_position
	var b_col := breaker_b.get_node("CollisionShape2D") as CollisionShape2D
	var b_radius: float = (b_col.shape as CircleShape2D).radius
	var max_interact_reach := b_radius + 36.0 # breaker shape radius + player detector radius

	var min_dist_south := INF
	var vulnerable_cells := 0
	for c in cols:
		for r in rows:
			if grid.is_point_solid(Vector2i(c, r)):
				continue
			var pos := Vector2(min_x + c * cell_size + cell_size / 2.0, min_y + r * cell_size + cell_size / 2.0)
			# North railing line: x - 2y - 96 = 0; south of railing means x - 2y < 96
			if (pos.x - 2.0 * pos.y) < 96.0:
				var dist := pos.distance_to(b_pos)
				if dist < min_dist_south:
					min_dist_south = dist
				if dist <= max_interact_reach:
					vulnerable_cells += 1

	_assert_eq(vulnerable_cells, 0, "Zero points south of north railing can reach breaker B")
	_assert_true(min_dist_south > max_interact_reach,
		"Min distance south of railing (%.1f px) is > interact reach (%.1f px)" % [min_dist_south, max_interact_reach])

	sig.free()


func test_pz005_levers_and_resetter_configuration() -> void:
	var s := make_session()
	var vestibule := (load(ROOM_PATHS[&"ch01.upper_vestibule"]) as PackedScene).instantiate()
	s.add_child(vestibule)

	var lever_a := vestibule.get_node_or_null("junction_lever_a") as JunctionLever
	var lever_b := vestibule.get_node_or_null("junction_lever_b") as JunctionLever
	var resetter := vestibule.get_node_or_null("spatial_resetter") as SpatialStateResetter
	var board := vestibule.get_node_or_null("route_board") as Interactable

	_assert_true(lever_a != null, "junction_lever_a exists")
	_assert_true(lever_b != null, "junction_lever_b exists")
	_assert_true(resetter != null, "spatial_resetter exists")
	_assert_true(board != null and board.traceable, "route_board exists and is traceable")

	_assert_eq(lever_a.state_a, &"loop", "lever_a state_a is loop")
	_assert_eq(lever_a.state_b, &"uncoupled", "lever_a state_b is uncoupled")
	_assert_eq(lever_b.state_a, &"niche", "lever_b state_a is niche")
	_assert_eq(lever_b.state_b, &"atrium", "lever_b state_b is atrium")

	# Verify pairs match test_ch01_puzzles.gd::_pz5 spec
	var expected_a_b := [["ch01.upper_vestibule", "door_west", "ch01.upper_vestibule", "door_east"], ["ch01.upper_vestibule", "door_north", "ch01.vestibule_niche", "door_in"]]
	var expected_b_b := [["ch01.upper_vestibule", "door_north", "ch01.station_atrium", "door_entry_south"], ["ch01.vestibule_niche", "door_in", "ch01.vestibule_niche", "door_out", false]]
	_assert_eq(lever_a.pairs_to_b, expected_a_b, "lever_a pairs_to_b matches spec")
	_assert_eq(lever_b.pairs_to_b, expected_b_b, "lever_b pairs_to_b matches spec")

	# Verify resetter has State 0 initial pairs
	var expected_reset := [["ch01.upper_vestibule", "door_north", "ch01.upper_vestibule", "door_west"], ["ch01.upper_vestibule", "door_east", "ch01.vestibule_niche", "door_in"], ["ch01.vestibule_niche", "door_out", "ch01.station_atrium", "door_entry_south", false]]
	_assert_eq(resetter.initial_pairs, expected_reset, "resetter initial_pairs matches State 0")

	s.remove_child(vestibule)
	vestibule.free()
	free_session(s)


func test_readables_apply_flags_fragments_and_journal() -> void:
	var s := make_session()

	# 1. Waiting Lounge: audio_mira_01
	var lounge := (load(ROOM_PATHS[&"ch01.waiting_lounge"]) as PackedScene).instantiate()
	s.add_child(lounge)
	var mira_log := lounge.get_node_or_null("audio_mira_01") as ReadableDocument
	_assert_true(mira_log != null, "audio_mira_01 exists")
	var res1 := s.interaction_service.request(&"player", &"ch01.waiting_lounge.audio_mira_01", &"use")
	_assert_true(res1.ok, "read audio_mira_01 ok")
	_assert_true(s.narrative_state.get_flag(&"ch01.flag.mira_trace_seen"), "mira_trace_seen flag set")
	_assert_eq(s.narrative_state.export_fragments(), ["ch01.fragment.mira_departure"], "mira_departure fragment acquired")
	_assert_true(_has_journal_entry(s.narrative_state.get_journal(), "JRN_CH1_MIRA_PLEA"), "JRN_CH1_MIRA_PLEA journal added")
	s.remove_child(lounge)
	lounge.free()

	# 2. Vestibule Niche: doc_index_plaque
	var niche := (load(ROOM_PATHS[&"ch01.vestibule_niche"]) as PackedScene).instantiate()
	s.add_child(niche)
	var plaque := niche.get_node_or_null("doc_index_plaque") as ReadableDocument
	_assert_true(plaque != null, "doc_index_plaque exists")
	var res2 := s.interaction_service.request(&"player", &"ch01.vestibule_niche.doc_index_plaque", &"use")
	_assert_true(res2.ok, "read doc_index_plaque ok")
	_assert_true(_has_journal_entry(s.narrative_state.get_journal(), "JRN_CH1_THRESHOLDS"), "JRN_CH1_THRESHOLDS journal added")
	s.remove_child(niche)
	niche.free()

	# 3. Station Atrium: dispatch_terminal (Beat 09 revelation)
	var atrium := (load(ROOM_PATHS[&"ch01.station_atrium"]) as PackedScene).instantiate()
	s.add_child(atrium)
	var term := atrium.get_node_or_null("dispatch_terminal") as ReadableDocument
	_assert_true(term != null, "dispatch_terminal exists")
	var res3 := s.interaction_service.request(&"player", &"ch01.station_atrium.dispatch_terminal", &"use")
	_assert_true(res3.ok, "read dispatch_terminal ok")
	_assert_true(s.narrative_state.get_flag(&"ch01.flag.ledger_2359_revealed"), "ledger_2359_revealed flag set")
	_assert_true(_has_journal_entry(s.narrative_state.get_journal(), "JRN_CH1_SEAL_ELIAS"), "JRN_CH1_SEAL_ELIAS journal added")
	s.remove_child(atrium)
	atrium.free()

	free_session(s)


func test_intercom_adds_operator_warning_after_pz004() -> void:
	var s := make_session()
	var sig := (load(ROOM_PATHS[&"ch01.signal_control"]) as PackedScene).instantiate()
	s.add_child(sig)

	var intercom := sig.get_node_or_null("intercom") as SignalControlIntercom
	_assert_true(intercom != null, "intercom exists in signal_control")
	_assert_false(_has_journal_entry(s.narrative_state.get_journal(), "JRN_CH1_OPERATOR_WARNING"), "no warning initially")

	# Solving PZ-004 triggers intercom hook
	s.puzzle_service.mark_solved(&"CH1-PZ-004")
	_assert_true(_has_journal_entry(s.narrative_state.get_journal(), "JRN_CH1_OPERATOR_WARNING"), "JRN_CH1_OPERATOR_WARNING added after PZ-004")
	_assert_true(s.narrative_state.get_flag(&"ch01.flag.operator_substation_warn"), "operator_substation_warn flag set")

	s.remove_child(sig)
	sig.free()
	free_session(s)


func test_street_exit_trigger_outro_completes_chapter() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()

	_assert_false(ch01.chapter_complete, "chapter initially incomplete")
	_assert_false(ch01.session.narrative_state.get_flag(&"ch01.flag.chapter_complete"), "no chapter_complete flag initially")

	# Walk player into outro trigger in street_exit
	ch01.session.interaction_service.trigger_enter(&"player", &"ch01.street_exit.trigger_outro")

	# Complete Beat 10 outro dialogue if active
	var diag = ch01.get_dialogue_box()
	while diag != null and diag.is_active:
		diag.advance_line()

	_assert_true(ch01.chapter_complete, "chapter_complete marked true")
	_assert_true(ch01.session.narrative_state.get_flag(&"ch01.flag.chapter_complete"), "chapter_complete narrative flag set")
	_assert_true(ch01.get_node_or_null("ChapterCompleteOverlay") != null, "ChapterCompleteOverlay displayed")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_street_exit_trigger_outro_completes_chapter")


func test_chapter01_scene_initialization_and_graph_validation() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	_assert_true(ch01 != null, "Chapter01 instantiates")

	var session: GameSession = ch01.get_node_or_null("GameSession")
	var router: RoomRouter = ch01.get_node_or_null("RoomRouter")
	var player: Player = ch01.get_node_or_null("Player")
	_assert_true(session != null, "GameSession exists")
	_assert_true(router != null, "RoomRouter exists")
	_assert_true(player != null, "Player exists")

	# Graph is applied and valid across all 10 rooms
	_assert_true(session.spatial_service != null and session.spatial_service.graph != null, "SpatialGraph active")
	var room_ids = session.spatial_service.graph.get_room_ids()
	for r_id in ROOM_PATHS.keys():
		_assert_true(room_ids.has(r_id), "Room '%s' in graph" % r_id)

	# Initial room entered
	_assert_eq(router.current_room_id, &"ch01.arrival_platform", "current room is arrival_platform")
	_assert_true(session.id_registry.has_id(&"ch01.arrival_platform.safe_anchor_spawn"), "safe anchor registered")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_chapter01_scene_initialization_and_graph_validation")


func test_scripted_playthrough_rooms_1_to_4() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()

	var session: GameSession = ch01.get_node_or_null("GameSession")
	var router: RoomRouter = ch01.get_node_or_null("RoomRouter")
	var player: Player = ch01.get_node_or_null("Player")

	# 1. Arrival Platform: spawned at safe_anchor_spawn (352, 160)
	_assert_eq(router.current_room_id, &"ch01.arrival_platform", "starts in arrival_platform")
	_assert_true((player.global_position - Vector2(352, 160)).length() < 2.0, "spawned at safe_anchor_spawn")
	# Checkpoint reached at spawn
	session.interaction_service.trigger_enter(&"player", &"ch01.arrival_platform.checkpoint")

	# Walk to door_exit_east (448, 208) using real input
	Input.action_press("move_right")
	Input.action_press("move_down")
	for i in range(30):
		player._physics_process(1.0 / 60.0)
	Input.action_release("move_right")
	Input.action_release("move_down")

	# Step through door_exit_east
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.arrival_platform.door_exit_east")
	router.process_pending()

	# 2. Concourse West: arrived at door_entry_west spawn (256, 112)
	_assert_eq(router.current_room_id, &"ch01.concourse_west", "transitioned to concourse_west")
	_assert_true((player.global_position - Vector2(256, 112)).length() < 2.0, "spawned at concourse door_entry_west")

	# Turnstile gate is blocked initially
	var gate := session.id_registry.resolve(&"ch01.concourse_west.turnstile_gate") as TurnstileGate
	_assert_true(gate != null and gate.passage_blocked, "turnstile gate blocked")

	# Rewind turnstile gate using PocketWatch action
	player.pocket_watch.selected_ability = &"rewind"
	session.sim_clock.step(10)
	var rewind_res := session.interaction_service.request(&"player", &"ch01.concourse_west.turnstile_gate", &"rewind")
	_assert_true(rewind_res.ok, "rewind turnstile succeeded")
	_assert_false(gate.passage_blocked, "turnstile opened")

	# Walk across turnstile to exit trigger (304, 136)
	Input.action_press("move_right")
	Input.action_press("move_down")
	for i in range(25):
		player._physics_process(1.0 / 60.0)
	Input.action_release("move_right")
	Input.action_release("move_down")

	session.interaction_service.trigger_enter(&"player", &"ch01.concourse_west.exit_trigger_concourse")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-001"), "PZ-001 is SOLVED")

	# Walk east to door_exit_east (480, 224)
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.concourse_west.door_exit_east")
	router.process_pending()

	# 3. Maintenance Bay: arrived at door_entry_west spawn (256, 112)
	_assert_eq(router.current_room_id, &"ch01.maintenance_bay", "transitioned to maintenance_bay")
	_assert_true((player.global_position - Vector2(256, 112)).length() < 2.0, "spawned at bay door_entry_west")

	var shutter := session.id_registry.resolve(&"ch01.maintenance_bay.fire_shutter") as FireShutter
	var gear := session.id_registry.resolve(&"ch01.maintenance_bay.counterweight_gear") as CounterweightGear
	_assert_true(shutter != null and shutter.passage_blocked, "shutter blocked")

	# Rewind shutter and freeze gear
	var sh_res := session.interaction_service.request(&"player", &"ch01.maintenance_bay.fire_shutter", &"rewind")
	_assert_true(sh_res.ok, "rewind shutter succeeded")
	session.sim_clock.step(10)
	var freeze_res := session.interaction_service.request(&"player", &"ch01.maintenance_bay.counterweight_gear", &"freeze")
	_assert_true(freeze_res.ok, "freeze gear succeeded")
	_assert_true(gear.is_frozen(), "gear is frozen")

	# Advance clock 300 ticks to verify freeze halts the timer
	session.sim_clock.step(300)
	_assert_false(shutter.passage_blocked, "shutter remained raised after 300 ticks")

	# Walk through shutter into exit trigger (416, 176)
	session.interaction_service.trigger_enter(&"player", &"ch01.maintenance_bay.exit_trigger_east")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-002"), "PZ-002 is SOLVED")

	# Walk to door_exit_east (464, 200)
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.maintenance_bay.door_exit_east")
	router.process_pending()

	# 4. Security Crossing: arrived at door_entry_west spawn (240, 120)
	_assert_eq(router.current_room_id, &"ch01.security_crossing", "transitioned to security_crossing")
	_assert_true((player.global_position - Vector2(240, 120)).length() < 2.0, "spawned at crossing door_entry_west")

	var bridge := session.id_registry.resolve(&"ch01.security_crossing.bridge_platform_01") as RetractableBridge
	var plate_id := &"ch01.security_crossing.pressure_switch_01"
	_assert_false(bridge.walkable, "bridge is retracted")

	# Record Echo walking to and holding switch
	session.echo_service.start_recording()
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", plate_id)
	session.sim_clock.step(40)
	session.echo_service.stop_recording()

	# Step off plate
	session.sim_clock.step(10)
	session.interaction_service.trigger_exit(&"player", plate_id)
	_assert_false(bridge.walkable, "bridge retracted when player stepped off")

	# Playback Echo
	session.echo_service.start_playback()
	session.sim_clock.step(40)
	_assert_true(bridge.walkable, "bridge extended while echo holds switch")

	# Cross bridge and reach exit trigger (432, 216)
	session.interaction_service.trigger_enter(&"player", &"ch01.security_crossing.exit_trigger_lounge")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-003"), "PZ-003 is SOLVED")

	# Confirm all three puzzles are solved
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-001"), "CH1-PZ-001 solved")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-002"), "CH1-PZ-002 solved")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-003"), "CH1-PZ-003 solved")

	# Confirm autosave exists in isolated test root
	_assert_true(router.save_service != null, "SaveService active")
	_assert_true(router.save_service.has_slot(router.autosave_slot), "Autosave slot exists in test folder")
	_assert_true(FileAccess.file_exists(TEST_SAVE_ROOT.path_join("slot_%d.json" % router.autosave_slot)), "Autosave file in test root")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_scripted_playthrough_rooms_1_to_4")
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root cleaned up")


func test_scripted_playthrough_full_chapter_rooms_1_to_10() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()

	var session: GameSession = ch01.get_node_or_null("GameSession")
	var router: RoomRouter = ch01.get_node_or_null("RoomRouter")
	var player: Player = ch01.get_node_or_null("Player")

	# 1. Arrival Platform -> Concourse West
	_assert_eq(router.current_room_id, &"ch01.arrival_platform", "starts in arrival_platform")
	session.interaction_service.trigger_enter(&"player", &"ch01.arrival_platform.checkpoint")
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.arrival_platform.door_exit_east")
	router.process_pending()

	# 2. Concourse West -> Solve PZ-001 -> Maintenance Bay
	_assert_eq(router.current_room_id, &"ch01.concourse_west", "in concourse_west")
	player.pocket_watch.selected_ability = &"rewind"
	session.sim_clock.step(10)
	session.interaction_service.request(&"player", &"ch01.concourse_west.turnstile_gate", &"rewind")
	session.interaction_service.trigger_enter(&"player", &"ch01.concourse_west.exit_trigger_concourse")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-001"), "PZ-001 solved")
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.concourse_west.door_exit_east")
	router.process_pending()

	# 3. Maintenance Bay -> Solve PZ-002 -> Security Crossing
	_assert_eq(router.current_room_id, &"ch01.maintenance_bay", "in maintenance_bay")
	session.interaction_service.request(&"player", &"ch01.maintenance_bay.fire_shutter", &"rewind")
	session.sim_clock.step(10)
	session.interaction_service.request(&"player", &"ch01.maintenance_bay.counterweight_gear", &"freeze")
	session.interaction_service.trigger_enter(&"player", &"ch01.maintenance_bay.exit_trigger_east")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-002"), "PZ-002 solved")
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.maintenance_bay.door_exit_east")
	router.process_pending()

	# 4. Security Crossing -> Solve PZ-003 -> Waiting Lounge
	_assert_eq(router.current_room_id, &"ch01.security_crossing", "in security_crossing")
	var plate_id := &"ch01.security_crossing.pressure_switch_01"
	session.echo_service.start_recording()
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", plate_id)
	session.sim_clock.step(40)
	session.echo_service.stop_recording()
	session.sim_clock.step(10)
	session.interaction_service.trigger_exit(&"player", plate_id)
	session.echo_service.start_playback()
	session.sim_clock.step(40)
	session.interaction_service.trigger_enter(&"player", &"ch01.security_crossing.exit_trigger_lounge")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-003"), "PZ-003 solved")
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.security_crossing.door_exit_east")
	router.process_pending()

	# 5. Waiting Lounge (Beat 06): Read Mira log -> Signal Control
	_assert_eq(router.current_room_id, &"ch01.waiting_lounge", "in waiting_lounge")
	var mira_read := session.interaction_service.request(&"player", &"ch01.waiting_lounge.audio_mira_01", &"use")
	_assert_true(mira_read.ok, "read audio_mira_01 ok")
	_assert_true(session.narrative_state.get_flag(&"ch01.flag.mira_trace_seen"), "mira flag set")
	_assert_eq(session.narrative_state.export_fragments(), ["ch01.fragment.mira_departure"], "mira fragment acquired")
	_assert_true(_has_journal_entry(session.narrative_state.get_journal(), "JRN_CH1_MIRA_PLEA"), "mira journal logged")
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.waiting_lounge.door_exit_north")
	router.process_pending()

	# 6. Signal Control (Beat 07): Solve PZ-004 -> Operator Warning -> Upper Vestibule
	_assert_eq(router.current_room_id, &"ch01.signal_control", "in signal_control")
	# Step 1: Rewind + Freeze capacitor
	session.interaction_service.request(&"player", &"ch01.signal_control.surge_capacitor", &"rewind")
	session.sim_clock.step(10)
	session.interaction_service.request(&"player", &"ch01.signal_control.surge_capacitor", &"freeze")
	var cap := session.id_registry.resolve(&"ch01.signal_control.surge_capacitor") as SurgeCapacitor
	_assert_true(cap.is_stabilized(), "capacitor stabilized")

	# Step 2: Echo pulls breaker A, player pulls breaker B
	session.echo_service.start_recording()
	session.sim_clock.step(20)
	session.interaction_service.request(&"player", &"ch01.signal_control.breaker_a", &"use")
	session.sim_clock.step(20)
	session.echo_service.stop_recording()
	session.sim_clock.step(200) # wait for breaker A to open
	session.echo_service.start_playback()
	session.sim_clock.step(20)
	session.interaction_service.request(&"player", &"ch01.signal_control.breaker_b", &"use")
	var vdoor := session.id_registry.resolve(&"ch01.signal_control.vestibule_door") as PoweredDoor
	_assert_false(vdoor.passage_blocked, "vestibule door opened")

	# Cross exit trigger -> PZ-004 SOLVED + Intercom warning
	session.interaction_service.trigger_enter(&"player", &"ch01.signal_control.exit_trigger_vestibule")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-004"), "PZ-004 is SOLVED")
	_assert_true(_has_journal_entry(session.narrative_state.get_journal(), "JRN_CH1_OPERATOR_WARNING"), "intercom warning journal added")
	_assert_true(session.narrative_state.get_flag(&"ch01.flag.operator_substation_warn"), "operator warning flag set")

	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.signal_control.door_exit_north")
	router.process_pending()

	# 7. Upper Vestibule (Beat 08): Visit Niche (Room 8) -> Solve PZ-005 -> Station Atrium
	_assert_eq(router.current_room_id, &"ch01.upper_vestibule", "in upper_vestibule")
	# Route board is traceable
	var trace_board := session.interaction_service.request(&"player", &"ch01.upper_vestibule.route_board", &"trace")
	_assert_true(trace_board.ok, "trace route board ok")

	# Inspect Niche through door_east
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.upper_vestibule.door_east")
	router.process_pending()
	_assert_eq(router.current_room_id, &"ch01.vestibule_niche", "in vestibule_niche")
	var plaque_res := session.interaction_service.request(&"player", &"ch01.vestibule_niche.doc_index_plaque", &"use")
	_assert_true(plaque_res.ok, "read doc_index_plaque ok")
	_assert_true(_has_journal_entry(session.narrative_state.get_journal(), "JRN_CH1_THRESHOLDS"), "thresholds journal added")

	# Return to Upper Vestibule through door_in
	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.vestibule_niche.door_in")
	router.process_pending()
	_assert_eq(router.current_room_id, &"ch01.upper_vestibule", "returned to upper_vestibule")

	# Pull levers to route door_north to Station Atrium
	session.interaction_service.request(&"player", &"ch01.upper_vestibule.junction_lever_a", &"use")
	session.interaction_service.request(&"player", &"ch01.upper_vestibule.junction_lever_b", &"use")

	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.upper_vestibule.door_north")
	router.process_pending()

	# 9. Station Atrium (Beat 09): Solve PZ-005 -> Major Revelation -> Street Exit
	_assert_eq(router.current_room_id, &"ch01.station_atrium", "in station_atrium")
	session.interaction_service.trigger_enter(&"player", &"ch01.station_atrium.entry_trigger_atrium")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-005"), "PZ-005 is SOLVED")

	# Inspect dispatch terminal
	var dispatch_res := session.interaction_service.request(&"player", &"ch01.station_atrium.dispatch_terminal", &"use")
	_assert_true(dispatch_res.ok, "read dispatch_terminal ok")
	_assert_true(session.narrative_state.get_flag(&"ch01.flag.ledger_2359_revealed"), "ledger flag set")
	_assert_true(_has_journal_entry(session.narrative_state.get_journal(), "JRN_CH1_SEAL_ELIAS"), "seal elias journal added")

	session.sim_clock.step(20)
	session.interaction_service.trigger_enter(&"player", &"ch01.station_atrium.door_exit_north")
	router.process_pending()

	# 10. Street Exit (Beat 10): Outro trigger -> Chapter Complete
	_assert_eq(router.current_room_id, &"ch01.street_exit", "in street_exit")
	session.interaction_service.trigger_enter(&"player", &"ch01.street_exit.trigger_outro")

	var outro_diag = ch01.get_dialogue_box()
	while outro_diag != null and outro_diag.is_active:
		outro_diag.advance_line()

	_assert_true(ch01.chapter_complete, "Chapter 1 completed")
	_assert_true(session.narrative_state.get_flag(&"ch01.flag.chapter_complete"), "chapter complete flag set")

	# Confirm all 5 puzzles are solved
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-001"), "PZ-001 solved")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-002"), "PZ-002 solved")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-003"), "PZ-003 solved")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-004"), "PZ-004 solved")
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-005"), "PZ-005 solved")

	# Confirm autosave exists in isolated test root
	_assert_true(router.save_service != null, "SaveService active")
	_assert_true(router.save_service.has_slot(router.autosave_slot), "Autosave slot exists in test folder")
	_assert_true(FileAccess.file_exists(TEST_SAVE_ROOT.path_join("slot_%d.json" % router.autosave_slot)), "Autosave file in test root")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_scripted_playthrough_full_chapter_rooms_1_to_10")
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root cleaned up")
