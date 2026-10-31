extends "res://tests/support/base_test.gd"

## Chapter 1 Rooms 1-4 & Playthrough Test Suite (TLF-009).
## Verifies room scenes, IDs, door spawns, SpatialGraph configuration,
## passage collision blockers, and end-to-end scripted playthrough solving PZ-001..003.

const DEF_PATH := "res://data/chapters/ch01/ch01_graph.tres"
const ROOM_PATHS := {
	&"ch01.arrival_platform": "res://scenes/chapters/ch01/rooms/arrival_platform.tscn",
	&"ch01.concourse_west": "res://scenes/chapters/ch01/rooms/concourse_west.tscn",
	&"ch01.maintenance_bay": "res://scenes/chapters/ch01/rooms/maintenance_bay.tscn",
	&"ch01.security_crossing": "res://scenes/chapters/ch01/rooms/security_crossing.tscn"
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
			_assert_true(sid.begins_with(room_id_str + "."), "ID '%s' follows prefix '%s.'" % [sid, room_id_str])
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
					# presenter collision shape radius/extent
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

	free_session(s)


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

	# Graph is applied and valid
	_assert_true(session.spatial_service != null and session.spatial_service.graph != null, "SpatialGraph active")
	var room_ids = session.spatial_service.graph.get_room_ids()
	_assert_true(room_ids.has(&"ch01.arrival_platform"), "arrival_platform in graph")
	_assert_true(room_ids.has(&"ch01.concourse_west"), "concourse_west in graph")
	_assert_true(room_ids.has(&"ch01.maintenance_bay"), "maintenance_bay in graph")
	_assert_true(room_ids.has(&"ch01.security_crossing"), "security_crossing in graph")

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
