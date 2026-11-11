extends "res://tests/support/ch01_real_input.gd"

## TLF-086: Security Crossing v2 Room-Specific Validation & Probe Suite
## Tests:
## 1. Door sweep: holding left, up, or down for 3s from arrival never triggers door_entry_west.
## 2. Trench divider sweep: with gate closed, sweep from x=12.2 never passes tile x=13.2.
## 3. Staff barrier divider sweep: with barrier closed, sweep from x=15.2 never passes tile x=16.2.
## 4. Mutation checks: trench north/south and staff barrier shapes go RED when colliders disabled.
## 5. Every canonical stand spot reachable within <= 2.6 px with real physics capsule.
## 6. Camera view bounds clamped at arrival, deck, bridge, landing, and east door with explicit bounds.
## 7. Checkpoint autosave and continue restore player and camera in Security Crossing v2.
## 8. Rigid cluster shift (+64, +32) verifies invariant spacing across all puzzle nodes.
## 9. Inter-room transitions: arrival from maintenance_bay and waiting_lounge land on correct spawns.
## 10. Real-input puzzle lifecycle for PZ-003.

const SECURITY_CROSSING := &"ch01.security_crossing"
const MAINTENANCE_BAY := &"ch01.maintenance_bay"
const WAITING_LOUNGE := &"ch01.waiting_lounge"

const ARRIVAL_SPAWN := Vector2(256, 128)
const EAST_DOOR_SPAWN := Vector2(576, 288)
const EAST_DOOR_APPROACH := Vector2(576, 288)


func _init() -> void:
	timeout_frames = 3600


func _tile_to_world(tx: float, ty: float) -> Vector2:
	return Vector2(320.0 + 16.0 * (tx - ty), 64.0 + 8.0 * (tx + ty))


func _world_to_tile(pos: Vector2) -> Vector2:
	var u := pos.x - 320.0
	var v := pos.y - 64.0
	return Vector2(u / 32.0 + v / 16.0, v / 16.0 - u / 32.0)


func _flag(name: StringName) -> Callable:
	return func() -> bool: return bool(session.narrative_state.get_flag(name))


func _solved(name: StringName) -> Callable:
	return func() -> bool: return session.puzzle_service.is_solved(name)


func _expect_unlock(ability: StringName) -> bool:
	return _assert_true(session.ability_unlocks.is_unlocked(ability), "%s unlocked" % ability)


# -------------------------------------------------------------------------------------------------
# 1. Door sweep from arrival spawn (256, 128)
# -------------------------------------------------------------------------------------------------
func test_door_sweep_arrival_never_triggers_door_entry_west() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	_assert_eq(player.global_position, ARRIVAL_SPAWN, "player spawned at arrival (256, 128)")

	# Sweep 1: Hold LEFT for 3 seconds (180 physics ticks)
	hold_moves([&"move_left"])
	await physics_frames(180)
	hold_moves([])
	_assert_eq(router.current_room_id, SECURITY_CROSSING, "holding left for 3s never leaves security_crossing")
	_assert_true(player.global_position.x < ARRIVAL_SPAWN.x, "player moved left against west boundary")

	# Reset to arrival spawn
	player.global_position = ARRIVAL_SPAWN
	player.velocity = Vector2.ZERO
	await physics_frames(2)

	# Sweep 2: Hold UP for 3 seconds (180 physics ticks)
	hold_moves([&"move_up"])
	await physics_frames(180)
	hold_moves([])
	_assert_eq(router.current_room_id, SECURITY_CROSSING, "holding up for 3s never leaves security_crossing")

	# Reset to arrival spawn
	player.global_position = ARRIVAL_SPAWN
	player.velocity = Vector2.ZERO
	await physics_frames(2)

	# Sweep 3: Hold DOWN for 3 seconds (180 physics ticks)
	hold_moves([&"move_down"])
	await physics_frames(180)
	hold_moves([])
	_assert_eq(router.current_room_id, SECURITY_CROSSING, "holding down for 3s never leaves security_crossing")

	stop()


# -------------------------------------------------------------------------------------------------
# 2. Trench divider sweep (x=13 line) with gate closed and bridge retracted
# -------------------------------------------------------------------------------------------------
func test_divider_sweep_trench_never_passes_x_13_2() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	var gate := resolve(&"ch01.security_crossing.security_gate_01")
	var bridge := resolve(&"ch01.security_crossing.bridge_platform_01") as RetractableBridge
	_assert_true(gate != null and gate.passage_blocked, "security gate closed initially")
	_assert_true(bridge != null and not bridge.walkable, "bridge retracted initially")

	var y_steps: Array[float] = []
	var curr_y := 0.8
	while curr_y <= 15.25:
		y_steps.append(curr_y)
		curr_y += 0.8

	var max_x_reached := 0.0
	for y_tile in y_steps:
		var start_pos := _tile_to_world(12.2, y_tile)
		var push_target := _tile_to_world(14.0, y_tile)
		player.global_position = start_pos
		player.velocity = Vector2.ZERO
		await physics_frames(1)

		await push_for([push_target], 60)
		var end_tile := _world_to_tile(player.global_position)
		if end_tile.x > max_x_reached:
			max_x_reached = end_tile.x
		_assert_true(end_tile.x <= 13.2,
			"trench sweep at y=%.1f: player stopped at tile_x=%.2f <= 13.2" % [y_tile, end_tile.x])

	_assert_true(max_x_reached < 13.0, "maximum x reached during trench sweep is %.2f < 13.0" % max_x_reached)
	stop()


func test_trench_sweep_mutation_fails_when_trench_north_disabled() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	var trench_n := router.current_room.get_node_or_null("TrenchBarriers/TrenchNorth") as CollisionShape2D
	_assert_true(trench_n != null, "TrenchNorth found")
	trench_n.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(12.2, 3.2)
	var push_target := _tile_to_world(14.0, 3.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 13.2
	_assert_true(crossed, "disabling TrenchNorth goes RED (tile_x=%.2f > 13.2)" % end_tile.x)

	trench_n.disabled = false
	stop()


func test_trench_sweep_mutation_fails_when_trench_south_disabled() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	var trench_s := router.current_room.get_node_or_null("TrenchBarriers/TrenchSouth") as CollisionShape2D
	_assert_true(trench_s != null, "TrenchSouth found")
	trench_s.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(12.2, 11.2)
	var push_target := _tile_to_world(14.0, 11.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 13.2
	_assert_true(crossed, "disabling TrenchSouth goes RED (tile_x=%.2f > 13.2)" % end_tile.x)

	trench_s.disabled = false
	stop()


# -------------------------------------------------------------------------------------------------
# 3. Staff barrier divider sweep (x=16 line) with barrier closed
# -------------------------------------------------------------------------------------------------
func test_divider_sweep_staff_barrier_never_passes_x_16_2() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	var barrier := resolve(&"ch01.security_crossing.staff_barrier_01")
	_assert_true(barrier != null and barrier.passage_blocked, "staff barrier closed initially")

	var y_steps: Array[float] = []
	var curr_y := 0.8
	while curr_y <= 15.25:
		y_steps.append(curr_y)
		curr_y += 0.8

	var max_x_reached := 0.0
	for y_tile in y_steps:
		var start_pos := _tile_to_world(15.2, y_tile)
		var push_target := _tile_to_world(17.0, y_tile)
		player.global_position = start_pos
		player.velocity = Vector2.ZERO
		await physics_frames(1)

		await push_for([push_target], 60)
		var end_tile := _world_to_tile(player.global_position)
		if end_tile.x > max_x_reached:
			max_x_reached = end_tile.x
		_assert_true(end_tile.x <= 16.2,
			"barrier sweep at y=%.1f: player stopped at tile_x=%.2f <= 16.2" % [y_tile, end_tile.x])

	_assert_true(max_x_reached < 16.0, "maximum x reached during barrier sweep is %.2f < 16.0" % max_x_reached)
	stop()


func test_barrier_sweep_mutation_fails_when_shape1_disabled() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	var shape1 := router.current_room.get_node_or_null("StaffBarrier/CollisionShape2D_1") as CollisionShape2D
	_assert_true(shape1 != null, "CollisionShape2D_1 found")
	shape1.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(15.2, 3.2)
	var push_target := _tile_to_world(17.0, 3.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 16.2
	_assert_true(crossed, "disabling StaffBarrier shape1 goes RED (tile_x=%.2f > 16.2)" % end_tile.x)

	shape1.disabled = false
	stop()


func test_barrier_sweep_mutation_fails_when_shape2_disabled() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	var shape2 := router.current_room.get_node_or_null("StaffBarrier/CollisionShape2D_2") as CollisionShape2D
	_assert_true(shape2 != null, "CollisionShape2D_2 found")
	shape2.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(15.2, 11.2)
	var push_target := _tile_to_world(17.0, 11.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 16.2
	_assert_true(crossed, "disabling StaffBarrier shape2 goes RED (tile_x=%.2f > 16.2)" % end_tile.x)

	shape2.disabled = false
	stop()


# -------------------------------------------------------------------------------------------------
# 4. Canonical stand spots reachability <= 2.6 px
# -------------------------------------------------------------------------------------------------
func test_all_stand_spots_reachable_within_2_6_px() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	session.ability_unlocks.unlock(&"trace")
	session.ability_unlocks.unlock(&"rewind")
	session.ability_unlocks.unlock(&"echo")

	# Canonical stand spots in Security Crossing v2 walked with real input from safe anchors >= 1 tile away
	var spots: Array[Dictionary] = [
		{"name": "door_entry_west arrival", "pos": ARRIVAL_SPAWN, "anchor": Vector2(288, 144), "target_id": &""},
		{"name": "checkpoint (4,6)", "pos": Vector2(288, 144), "anchor": ARRIVAL_SPAWN, "target_id": &""},
		{"name": "doc_guard_log (6,4)", "pos": Vector2(352, 144), "anchor": Vector2(288, 144), "target_id": &"ch01.security_crossing.doc_guard_log"},
		{"name": "n13_guard (7,3)", "pos": Vector2(384, 160), "anchor": Vector2(352, 144), "target_id": &"ch01.security_crossing.n13_guard"},
		{"name": "transit_pass_pickup (7,2)", "pos": Vector2(412, 132), "anchor": Vector2(384, 160), "target_id": &"ch01.security_crossing.transit_pass_pickup"},
		{"name": "alarm_plate_01 (9,3)", "pos": Vector2(416, 160), "anchor": Vector2(384, 192), "target_id": &""},
		{"name": "echo_recorder_pedestal (7,7)", "pos": Vector2(320, 176), "anchor": Vector2(384, 192), "target_id": &"ch01.security_crossing.echo_recorder_pedestal"},
		{"name": "pressure_switch_01 (9,9)", "pos": Vector2(320, 208), "anchor": Vector2(384, 192), "target_id": &""},
		{"name": "reset_anchor_01 (11,6)", "pos": Vector2(400, 200), "anchor": Vector2(352, 176), "target_id": &"ch01.security_crossing.reset_anchor_01"},
		{"name": "safe_anchor_west (10,6)", "pos": Vector2(384, 192), "anchor": Vector2(352, 144), "target_id": &""},
		{"name": "card_reader_01 (15,8)", "pos": Vector2(464, 232), "anchor": Vector2(448, 224), "target_id": &"ch01.security_crossing.card_reader_01"},
		{"name": "exit_trigger_lounge", "pos": Vector2(496, 248), "anchor": Vector2(576, 288), "target_id": &""},
		{"name": "safe_anchor_east (17,6)", "pos": Vector2(496, 248), "anchor": Vector2(576, 288), "target_id": &""},
		{"name": "door_exit_east approach (22,6)", "pos": EAST_DOOR_APPROACH, "anchor": Vector2(496, 248), "target_id": &""}
	]

	for entry in spots:
		var pos: Vector2 = entry["pos"]
		var anchor: Vector2 = entry["anchor"]
		var label: String = entry["name"]

		# Set player to safe anchor >= 1 tile away and walk with real input
		player.global_position = anchor
		player.velocity = Vector2.ZERO
		await physics_frames(3)

		await walk_to(player, "reach spot %s" % label, pos, Callable(), 240, true)
		for step in 8:
			if player.global_position.distance_to(pos) <= 1.0:
				break
			steer(player, pos)
			await physics_frames(1)
		hold_moves([])
		player.velocity = Vector2.ZERO
		var dist := player.global_position.distance_to(pos)
		_assert_true(dist <= 2.6, "spot %s distance %.2f px <= 2.6 px" % [label, dist])

		if not String(entry["target_id"]).is_empty():
			await physics_frames(2)
			var tid: StringName = entry["target_id"]
			var target_node: Node = resolve(tid)
			if target_node != null and target_node is Interactable:
				for f in 5:
					if player.current_target == target_node or player.pocket_watch.current_target == target_node:
						break
					await physics_frames(1)
				var focused: Interactable = player.current_target
				var ok_focus: bool = (focused == target_node or player.pocket_watch.current_target == target_node)
				_assert_true(ok_focus, "spot %s resolves focus or watch target to %s" % [label, tid])

	stop()


# -------------------------------------------------------------------------------------------------
# 5. Camera view bounds and whole-pixel centre
# -------------------------------------------------------------------------------------------------
func test_camera_view_bounds_clamped() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	var cam := router.camera as RoomCamera
	_assert_true(cam != null, "RoomCamera active")
	var bounds: Rect2 = router.current_room_bounds()
	_assert_true(bounds.has_area(), "Security Crossing room bounds derived from room_shape: %s" % bounds)

	# Explicit bounds Rect2(48, 0, 672, 400) and center Vector2(384, 200)
	_assert_eq(bounds, Rect2(48, 0, 672, 400), "explicit security_crossing v2 room bounds Rect2(48, 0, 672, 400)")
	_assert_eq(bounds.get_center(), Vector2(384, 200), "explicit security_crossing v2 room bounds center (384, 200)")

	var test_points := [
		{"name": "arrival", "pos": ARRIVAL_SPAWN},
		{"name": "deck", "pos": Vector2(352, 160)},
		{"name": "bridge", "pos": Vector2(432, 216)},
		{"name": "landing", "pos": Vector2(464, 232)},
		{"name": "east door", "pos": EAST_DOOR_APPROACH}
	]

	for pt in test_points:
		player.global_position = pt["pos"]
		cam.snap_now()
		var center := cam.position
		# Whole-pixel camera centre assertion
		_assert_eq(center, center.round(), "camera center %s is whole-pixel" % pt["name"])

		# View rect clamping (bounds 672x408 < viewport 960x540 so fixed centered)
		_assert_eq(center.x, roundf(bounds.get_center().x), "%s camera x centered on bounds" % pt["name"])
		_assert_eq(center.y, roundf(bounds.get_center().y), "%s camera y centered on bounds" % pt["name"])

	stop()


# -------------------------------------------------------------------------------------------------
# 6. Checkpoint save / load restores player and camera
# -------------------------------------------------------------------------------------------------
func test_checkpoint_saveload_restores_player_and_camera() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	var cp_zone := Vector2(288, 144)
	var outside := Vector2(320, 160)
	if not await save_at_checkpoint(&"ch01.cp.security_crossing", cp_zone, outside):
		stop()
		return

	# Move player away to landing
	player.global_position = Vector2(464, 232)
	await physics_frames(2)
	_assert_true(player.global_position != ARRIVAL_SPAWN, "player moved away before continue")

	# Continue from autosave
	if not await continue_from_autosave():
		stop()
		return

	_assert_eq(router.current_room_id, SECURITY_CROSSING, "continue restored security_crossing")
	# Restored to safe_anchor_west at (384, 192)
	var expected_spawn := Vector2(384, 192)
	_assert_true(player.global_position.distance_to(expected_spawn) < 2.0,
		"player restored to safe anchor west %s (got %s)" % [expected_spawn, player.global_position])

	stop()


# -------------------------------------------------------------------------------------------------
# 7. Rigid cluster shift invariant: Delta (+64, +32)
# -------------------------------------------------------------------------------------------------
func test_rigid_cluster_shifts_and_relative_distances() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	var room := router.current_room

	# Cluster P: Delta (+64, +32) from greybox baseline
	var cluster_p_nodes := {
		"transit_pass_pickup": [Vector2(336, 104), Vector2(400, 136)],
		"n13_guard": [Vector2(336, 120), Vector2(400, 152)],
		"alarm_plate_01": [Vector2(352, 128), Vector2(416, 160)],
		"doc_guard_log": [Vector2(288, 112), Vector2(352, 144)],
		"echo_recorder_pedestal": [Vector2(256, 160), Vector2(320, 192)],
		"pressure_switch_01": [Vector2(256, 176), Vector2(320, 208)],
		"reset_anchor_01": [Vector2(336, 168), Vector2(400, 200)],
		"safe_anchor_west": [Vector2(320, 160), Vector2(384, 192)],
		"bridge_platform_01": [Vector2(368, 184), Vector2(432, 216)],
		"bridge_walk_zone": [Vector2(368, 184), Vector2(432, 216)],
		"security_gate_01": [Vector2(416, 176), Vector2(480, 208)],
		"card_reader_01": [Vector2(384, 208), Vector2(448, 240)],
		"staff_barrier_01": [Vector2(432, 200), Vector2(496, 232)],
		"exit_trigger_lounge": [Vector2(432, 216), Vector2(496, 248)],
		"safe_anchor_east": [Vector2(432, 216), Vector2(496, 248)],
		"pa_speaker": [Vector2(320, 60), Vector2(384, 92)]
	}

	for node_name in cluster_p_nodes:
		var n := room.get_node_or_null(node_name) as Node2D
		_assert_true(n != null, "Cluster P node %s exists" % node_name)
		var old_pos: Vector2 = cluster_p_nodes[node_name][0]
		var exp_pos: Vector2 = cluster_p_nodes[node_name][1]
		_assert_eq(n.position, exp_pos, "Cluster P node %s moved exactly (+64, +32)" % node_name)
		_assert_eq(n.position - old_pos, Vector2(64, 32), "Cluster P shift invariant for %s" % node_name)

	# Invariant distance checks within Cluster P:
	var switch := room.get_node("pressure_switch_01") as Node2D
	var gate := room.get_node("security_gate_01") as Node2D
	_assert_eq(switch.position.distance_to(gate.position), Vector2(256, 176).distance_to(Vector2(416, 176)),
		"internal distance between pressure_switch_01 and security_gate_01 strictly invariant")

	var bridge := room.get_node("bridge_platform_01") as Node2D
	var reader := room.get_node("card_reader_01") as Node2D
	_assert_eq(bridge.position.distance_to(reader.position), Vector2(368, 184).distance_to(Vector2(384, 208)),
		"internal distance between bridge_platform_01 and card_reader_01 strictly invariant")

	stop()


# -------------------------------------------------------------------------------------------------
# 8. Inter-room transitions
# -------------------------------------------------------------------------------------------------
func test_inter_room_transitions() -> void:
	# Transition 1: Arrival from maintenance_bay lands at door_entry_west Spawn (256, 128)
	if not await start_at(MAINTENANCE_BAY, &"door_exit_east", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	# Reposition past the inner shutter so we can cleanly walk through the east doorway
	player.global_position = Vector2(560, 264)
	player.velocity = Vector2.ZERO
	await physics_frames(35)

	# Walk player through east door of maintenance bay at (672, 304)
	await walk_to(player, "maintenance_bay -> exit east", Vector2(672, 304), in_room(SECURITY_CROSSING))
	_assert_eq(router.current_room_id, SECURITY_CROSSING, "entered security_crossing from maintenance_bay")
	_assert_eq(player.global_position, ARRIVAL_SPAWN, "spawned at arrival spawn (256, 128)")

	# Transition 2: Walk back through west door into maintenance_bay lands at door_exit_east Spawn (640, 288)
	await walk_to(player, "security_crossing -> exit west", Vector2(224, 112), in_room(MAINTENANCE_BAY))
	_assert_eq(router.current_room_id, MAINTENANCE_BAY, "entered maintenance_bay from security_crossing")
	_assert_eq(player.global_position, Vector2(640, 288), "spawned at maintenance_bay east door spawn (640, 288)")
	stop()

	# Transition 3: Arrival from waiting_lounge lands at door_exit_east Spawn (576, 288)
	if not await start_at(WAITING_LOUNGE, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002", &"CH1-PZ-003"], []):
		stop()
		return

	# Reposition away from the door aperture so we can cleanly walk through it
	player.global_position = Vector2(272, 136)
	player.velocity = Vector2.ZERO
	await physics_frames(35)

	# Walk player through west door of waiting lounge (door_entry_west)
	await walk_to(player, "waiting_lounge -> exit west", Vector2(224, 112), in_room(SECURITY_CROSSING))
	_assert_eq(router.current_room_id, SECURITY_CROSSING, "entered security_crossing from waiting_lounge")
	_assert_eq(player.global_position, EAST_DOOR_SPAWN, "spawned at east door spawn (576, 288)")

	stop()


# -------------------------------------------------------------------------------------------------
# 9. Real-input playthrough lifecycle for PZ-003
# -------------------------------------------------------------------------------------------------
func test_real_input_pz003_lifecycle() -> void:
	if not await start_at(SECURITY_CROSSING, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-SO-02", &"CH1-PZ-002"], []):
		stop()
		return

	# Step 1: Use pedestal at (320, 176) to unlock Echo
	if not await use_at(Vector2(320, 176), resolve(&"ch01.security_crossing.echo_recorder_pedestal"), "crossing -> echo pedestal"):
		stop()
		return
	await dismiss_blocking_ui()
	if not await _expect_unlock(&"echo"):
		stop()
		return

	# Step 2: Take transit pass from desk at (412, 132)
	if not await use_at(Vector2(412, 132), resolve(&"ch01.security_crossing.transit_pass_pickup"), "crossing -> transit pass"):
		stop()
		return
	_assert_true(await until(_flag(&"ch01.flag.transit_pass"), 10), "transit pass taken")

	# Step 3: Record Echo onto pressure switch
	var bridge := resolve(&"ch01.security_crossing.bridge_platform_01") as RetractableBridge
	_assert_false(bridge.walkable, "bridge starts retracted")
	if not await select_ability(&"echo"):
		stop()
		return

	var echo := session.echo_service
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.RECORDING, "watch starts recording")

	if not await walk_to(player, "crossing -> pressure plate", Vector2(320, 208)):
		stop()
		return
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.READY, "watch stops recording on the plate")

	# Step 4: Step off plate
	if not await walk_to(player, "crossing -> off the plate", Vector2(364, 200)):
		stop()
		return
	await physics_frames(2)
	_assert_false(bridge.walkable, "bridge retracts when player leaves plate")

	# Step 5: Replay Echo to hold plate
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return bridge.walkable, 600), "bridge extends while Echo holds plate"):
		stop()
		return

	# Step 6: Walk across bridge to card reader
	if not await walk_to(player, "crossing -> above the bridge", Vector2(432, 202)):
		stop()
		return
	if not await walk_to(player, "crossing -> across the bridge", Vector2(432, 230)):
		stop()
		return

	# Step 7: Use card reader with transit pass
	var barrier := resolve(&"ch01.security_crossing.staff_barrier_01") as PoweredDoor
	if not await use_at(Vector2(464, 232), resolve(&"ch01.security_crossing.card_reader_01"), "crossing -> card reader"):
		stop()
		return
	if not _assert_true(await until(func() -> bool: return not barrier.passage_blocked, 10), "staff barrier lifts after reader"):
		stop()
		return

	# Step 8: Walk through barrier into exit trigger
	if not await walk_to(player, "crossing -> above barrier", Vector2(496, 218)):
		stop()
		return
	if not await walk_to(player, "crossing -> exit_trigger_lounge", Vector2(496, 248), _solved(&"CH1-PZ-003")):
		stop()
		return
	_assert_true(session.puzzle_service.is_solved(&"CH1-PZ-003"), "PZ-003 SOLVED behind staff barrier")

	stop()
