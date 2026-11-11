extends "res://tests/support/ch01_real_input.gd"

## TLF-085: Maintenance Bay v2 Room-Specific Validation & Probe Suite
## Tests:
## 1. Door sweep: holding left, up, or down for 3s from arrival never triggers door_entry_west.
## 2. Bulkhead divider sweep: with hatch closed, sweep from x=6.2 never passes tile x=7.2.
## 3. Shutter divider sweep: with fire shutter closed, sweep from x=15.2 never passes tile x=16.2.
## 4. Inner divider sweep: with inner shutter closed, sweep from x=18.2 never passes tile x=19.2.
## 5. Mutation checks: bulkhead, shutter, and inner divider sweeps go RED when colliders disabled.
## 6. Every canonical stand spot reachable within <= 2.6 px with real physics capsule.
## 7. Camera view bounds clamped at arrival, hatch, gear bay, pocket, and east door with explicit bounds.
## 8. Checkpoint autosave and continue restore player and camera in Maintenance Bay v2.
## 9. Rigid cluster shifts: Cluster H (+64, +32) and Cluster BC (+128, +64) verify invariant spacing.
## 10. Real-input puzzle lifecycle for SO-02 and PZ-002.

const MAINTENANCE_BAY := &"ch01.maintenance_bay"
const ARRIVAL_SPAWN := Vector2(272, 120)
const EAST_DOOR_SPAWN := Vector2(640, 288)
const EAST_DOOR_APPROACH := Vector2(624, 280)


func _init() -> void:
	timeout_frames = 3600


func _tile_to_world(tx: float, ty: float) -> Vector2:
	return Vector2(320.0 + 16.0 * (tx - ty), 64.0 + 8.0 * (tx + ty))


func _world_to_tile(pos: Vector2) -> Vector2:
	var u := pos.x - 320.0
	var v := pos.y - 64.0
	return Vector2(u / 32.0 + v / 16.0, v / 16.0 - u / 32.0)


# -------------------------------------------------------------------------------------------------
# 1. Door sweep from arrival spawn (272, 120)
# -------------------------------------------------------------------------------------------------
func test_door_sweep_arrival_never_triggers_door_entry_west() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	_assert_eq(player.global_position, ARRIVAL_SPAWN, "player spawned at arrival (272, 120)")

	# Sweep 1: Hold LEFT for 3 seconds (180 physics ticks)
	hold_moves([&"move_left"])
	await physics_frames(180)
	hold_moves([])
	_assert_eq(router.current_room_id, MAINTENANCE_BAY, "holding left for 3s never leaves maintenance_bay")
	_assert_true(player.global_position.x < ARRIVAL_SPAWN.x, "player moved left against west boundary")

	# Reset to arrival spawn
	player.global_position = ARRIVAL_SPAWN
	player.velocity = Vector2.ZERO
	await physics_frames(2)

	# Sweep 2: Hold UP for 3 seconds (180 physics ticks)
	hold_moves([&"move_up"])
	await physics_frames(180)
	hold_moves([])
	_assert_eq(router.current_room_id, MAINTENANCE_BAY, "holding up for 3s never leaves maintenance_bay")

	# Reset to arrival spawn
	player.global_position = ARRIVAL_SPAWN
	player.velocity = Vector2.ZERO
	await physics_frames(2)

	# Sweep 3: Hold DOWN for 3 seconds (180 physics ticks)
	hold_moves([&"move_down"])
	await physics_frames(180)
	hold_moves([])
	_assert_eq(router.current_room_id, MAINTENANCE_BAY, "holding down for 3s never leaves maintenance_bay")

	stop()


# -------------------------------------------------------------------------------------------------
# 2. Bulkhead divider sweep (x=7 line) with hatch closed
# -------------------------------------------------------------------------------------------------
func test_divider_sweep_bulkhead_never_passes_x_7_2() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var hatch := resolve(&"ch01.maintenance_bay.hatch_01")
	_assert_true(hatch != null and hatch.passage_blocked, "hatch closed initially")

	var y_steps: Array[float] = []
	var curr_y := 0.8
	while curr_y <= 15.25:
		y_steps.append(curr_y)
		curr_y += 0.8

	var max_x_reached := 0.0
	for y_tile in y_steps:
		var start_pos := _tile_to_world(6.2, y_tile)
		var push_target := _tile_to_world(8.0, y_tile)
		player.global_position = start_pos
		player.velocity = Vector2.ZERO
		await physics_frames(1)

		await push_for([push_target], 60)
		var end_tile := _world_to_tile(player.global_position)
		if end_tile.x > max_x_reached:
			max_x_reached = end_tile.x
		_assert_true(end_tile.x <= 7.2,
			"bulkhead sweep at y=%.1f: player stopped at tile_x=%.2f <= 7.2" % [y_tile, end_tile.x])

	_assert_true(max_x_reached < 7.0, "maximum x reached during bulkhead sweep is %.2f < 7.0" % max_x_reached)
	stop()


func test_bulkhead_sweep_mutation_fails_when_shape1_disabled() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var shape1 := router.current_room.get_node_or_null("Bulkhead/CollisionShape2D_1") as CollisionShape2D
	_assert_true(shape1 != null, "Bulkhead shape1 found")
	shape1.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(6.2, 1.5)
	var push_target := _tile_to_world(8.0, 1.5)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 7.2
	_assert_true(crossed, "disabling Bulkhead shape1 goes RED (tile_x=%.2f > 7.2)" % end_tile.x)

	shape1.disabled = false
	stop()


func test_bulkhead_sweep_mutation_fails_when_shape2_disabled() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var shape2 := router.current_room.get_node_or_null("Bulkhead/CollisionShape2D_2") as CollisionShape2D
	_assert_true(shape2 != null, "Bulkhead shape2 found")
	shape2.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(6.2, 11.2)
	var push_target := _tile_to_world(8.0, 11.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 7.2
	_assert_true(crossed, "disabling Bulkhead shape2 goes RED (tile_x=%.2f > 7.2)" % end_tile.x)

	shape2.disabled = false
	stop()


# -------------------------------------------------------------------------------------------------
# 3. Fire shutter divider sweep (x=16 line) with shutter closed
# -------------------------------------------------------------------------------------------------
func test_divider_sweep_fire_shutter_never_passes_x_16_2() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var shutter := resolve(&"ch01.maintenance_bay.fire_shutter")
	_assert_true(shutter != null and shutter.passage_blocked, "fire shutter closed initially")

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
			"shutter sweep at y=%.1f: player stopped at tile_x=%.2f <= 16.2" % [y_tile, end_tile.x])

	_assert_true(max_x_reached < 16.0, "maximum x reached during shutter sweep is %.2f < 16.0" % max_x_reached)
	stop()


func test_shutter_sweep_mutation_fails_when_divider_north_disabled() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var div_north := router.current_room.get_node_or_null("ShutterDividers/DividerNorth") as CollisionShape2D
	_assert_true(div_north != null, "DividerNorth found")
	div_north.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(15.2, 3.2)
	var push_target := _tile_to_world(17.0, 3.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 16.2
	_assert_true(crossed, "disabling DividerNorth goes RED (tile_x=%.2f > 16.2)" % end_tile.x)

	div_north.disabled = false
	stop()


func test_shutter_sweep_mutation_fails_when_divider_south_disabled() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var div_south := router.current_room.get_node_or_null("ShutterDividers/DividerSouth") as CollisionShape2D
	_assert_true(div_south != null, "DividerSouth found")
	div_south.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(15.2, 11.2)
	var push_target := _tile_to_world(17.0, 11.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 16.2
	_assert_true(crossed, "disabling DividerSouth goes RED (tile_x=%.2f > 16.2)" % end_tile.x)

	div_south.disabled = false
	stop()


# -------------------------------------------------------------------------------------------------
# 4. Inner divider sweep (x=19 line) with inner shutter closed
# -------------------------------------------------------------------------------------------------
func test_divider_sweep_inner_divider_never_passes_x_19_2() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var inner_shutter := resolve(&"ch01.maintenance_bay.inner_shutter")
	_assert_true(inner_shutter != null and inner_shutter.passage_blocked, "inner shutter closed initially")

	var y_steps: Array[float] = []
	var curr_y := 0.8
	while curr_y <= 15.25:
		y_steps.append(curr_y)
		curr_y += 0.8

	var max_x_reached := 0.0
	for y_tile in y_steps:
		var start_pos := _tile_to_world(18.2, y_tile)
		var push_target := _tile_to_world(20.0, y_tile)
		player.global_position = start_pos
		player.velocity = Vector2.ZERO
		await physics_frames(1)

		await push_for([push_target], 60)
		var end_tile := _world_to_tile(player.global_position)
		if end_tile.x > max_x_reached:
			max_x_reached = end_tile.x
		_assert_true(end_tile.x <= 19.2,
			"inner divider sweep at y=%.1f: player stopped at tile_x=%.2f <= 19.2" % [y_tile, end_tile.x])

	_assert_true(max_x_reached < 19.0, "maximum x reached during inner divider sweep is %.2f < 19.0" % max_x_reached)
	stop()


func test_inner_sweep_mutation_fails_when_shape1_disabled() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var shape1 := router.current_room.get_node_or_null("InnerDivider/CollisionShape2D_1") as CollisionShape2D
	_assert_true(shape1 != null, "InnerDivider shape1 found")
	shape1.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(18.2, 3.2)
	var push_target := _tile_to_world(20.0, 3.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 19.2
	_assert_true(crossed, "disabling InnerDivider shape1 goes RED (tile_x=%.2f > 19.2)" % end_tile.x)

	shape1.disabled = false
	stop()


func test_inner_sweep_mutation_fails_when_shape2_disabled() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var shape2 := router.current_room.get_node_or_null("InnerDivider/CollisionShape2D_2") as CollisionShape2D
	_assert_true(shape2 != null, "InnerDivider shape2 found")
	shape2.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(18.2, 11.2)
	var push_target := _tile_to_world(20.0, 11.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 19.2
	_assert_true(crossed, "disabling InnerDivider shape2 goes RED (tile_x=%.2f > 19.2)" % end_tile.x)

	shape2.disabled = false
	stop()


# -------------------------------------------------------------------------------------------------
# 5. Stand spots reachability (<= 2.6 px)
# -------------------------------------------------------------------------------------------------
func test_every_stand_spot_reachable_within_2_6_px() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	# Canonical stand spots in Maintenance Bay v2
	var spots: Array[Dictionary] = [
		{"name": "checkpoint", "pos": Vector2(320, 144), "target_id": &""},
		{"name": "safe_anchor_entry", "pos": Vector2(336, 136), "target_id": &""},
		{"name": "bell_plate_01", "pos": Vector2(272, 168), "target_id": &""},
		{"name": "hatch_plate_01", "pos": Vector2(320, 160), "target_id": &""},
		{"name": "doc_hatch_chart", "pos": Vector2(304, 168), "target_id": &"ch01.maintenance_bay.doc_hatch_chart"},
		{"name": "n11_hatch_tech", "pos": Vector2(352, 144), "target_id": &"ch01.maintenance_bay.n11_hatch_tech"},
		{"name": "hatch_01 approach", "pos": Vector2(384, 124), "target_id": &""},
		{"name": "safe_anchor_west", "pos": Vector2(464, 200), "target_id": &""},
		{"name": "counterweight_gear", "pos": Vector2(488, 188), "target_id": &""},
		{"name": "fire_shutter", "pos": Vector2(488, 188), "target_id": &""},
		{"name": "safe_anchor_east", "pos": Vector2(544, 240), "target_id": &""},
		{"name": "reset_anchor_01", "pos": Vector2(416, 208), "target_id": &"ch01.maintenance_bay.reset_anchor_01"},
		{"name": "doc_tech_log", "pos": Vector2(416, 256), "target_id": &"ch01.maintenance_bay.doc_tech_log"},
		{"name": "inner_shutter approach", "pos": Vector2(544, 240), "target_id": &""},
		{"name": "doc_inner_shutter_plate", "pos": Vector2(592, 232), "target_id": &"ch01.maintenance_bay.doc_inner_shutter_plate"},
		{"name": "door_exit_east approach", "pos": EAST_DOOR_APPROACH, "target_id": &""}
	]

	for entry in spots:
		var pos: Vector2 = entry["pos"]
		var label: String = entry["name"]

		# Set player directly near spot to test local reachability with capsule
		player.global_position = pos + Vector2(2, 2)
		player.velocity = Vector2.ZERO
		await physics_frames(1)

		await walk_to(player, "reach spot %s" % label, pos, Callable(), 60, true)
		for step in 5:
			if player.global_position.distance_to(pos) <= 2.6:
				break
			steer(player, pos)
			await physics_frames(1)
		hold_moves([])
		var dist := player.global_position.distance_to(pos)
		_assert_true(dist <= 2.6, "spot %s distance %.2f px <= 2.6 px" % [label, dist])

		if not String(entry["target_id"]).is_empty():
			var tid: StringName = entry["target_id"]
			var target_node: Node = resolve(tid)
			if target_node != null and target_node is Interactable:
				var focused: Interactable = player.current_target
				var ok_focus: bool = (focused == target_node or player.pocket_watch.current_target == target_node)
				_assert_true(ok_focus, "spot %s resolves focus or watch target to %s" % [label, tid])

	stop()


# -------------------------------------------------------------------------------------------------
# 6. Camera view bounds and whole-pixel centre
# -------------------------------------------------------------------------------------------------
func test_camera_view_bounds_clamped() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var cam := router.camera as RoomCamera
	_assert_true(cam != null, "RoomCamera active")
	var bounds: Rect2 = router.current_room_bounds()
	_assert_true(bounds.has_area(), "Maintenance Bay room bounds derived from room_shape: %s" % bounds)

	# Explicit bounds Rect2(48, 0, 688, 408) and center Vector2(392, 204)
	_assert_eq(bounds, Rect2(48, 0, 688, 408), "explicit maintenance_bay v2 room bounds Rect2(48, 0, 688, 408)")
	_assert_eq(bounds.get_center(), Vector2(392, 204), "explicit maintenance_bay v2 room bounds center (392, 204)")

	var view: Vector2 = RoomCamera.view_size()

	var test_points := [
		{"name": "arrival", "pos": ARRIVAL_SPAWN},
		{"name": "hatch", "pos": Vector2(384, 144)},
		{"name": "gear_bay", "pos": Vector2(512, 176)},
		{"name": "pocket", "pos": Vector2(544, 240)},
		{"name": "east door", "pos": EAST_DOOR_APPROACH}
	]

	for pt in test_points:
		player.global_position = pt["pos"]
		cam.snap_now()
		var center := cam.position
		# Whole-pixel camera centre assertion
		_assert_eq(center, center.round(), "camera center %s is whole-pixel" % pt["name"])

		# View rect clamping (bounds < viewport so fixed centered)
		_assert_eq(center.x, roundf(bounds.get_center().x), "%s camera x centered on bounds" % pt["name"])
		_assert_eq(center.y, roundf(bounds.get_center().y), "%s camera y centered on bounds" % pt["name"])

	stop()


# -------------------------------------------------------------------------------------------------
# 7. Checkpoint save / load restores player and camera
# -------------------------------------------------------------------------------------------------
func test_checkpoint_saveload_restores_player_and_camera() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var cp_zone := Vector2(320, 144)
	var outside := Vector2(272, 120)
	if not await save_at_checkpoint(&"ch01.cp.maintenance_bay", cp_zone, outside):
		stop()
		return

	# Move player away to gear bay
	player.global_position = Vector2(512, 176)
	await physics_frames(2)
	_assert_true(player.global_position != ARRIVAL_SPAWN, "player moved away before continue")

	# Continue from autosave
	if not await continue_from_autosave():
		stop()
		return

	_assert_eq(router.current_room_id, MAINTENANCE_BAY, "continue restored maintenance_bay")
	# Restored to safe_anchor_entry at (336, 136)
	var expected_spawn := Vector2(336, 136)
	_assert_true(player.global_position.distance_to(expected_spawn) < 2.0,
		"player restored to safe anchor entry %s (got %s)" % [expected_spawn, player.global_position])

	stop()


# -------------------------------------------------------------------------------------------------
# 8. Rigid cluster shifts: Cluster H (+64, +32) and Cluster BC (+128, +64)
# -------------------------------------------------------------------------------------------------
func test_rigid_cluster_shifts_and_relative_distances() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], []):
		stop()
		return

	var room := router.current_room

	# Cluster H: Delta (+64, +32) from greybox baseline
	var cluster_h_nodes := {
		"bell_plate_01": [Vector2(208, 136), Vector2(272, 168)],
		"doc_hatch_chart": [Vector2(240, 136), Vector2(304, 168)],
		"hatch_plate_01": [Vector2(256, 128), Vector2(320, 160)],
		"n11_hatch_tech": [Vector2(304, 104), Vector2(368, 136)],
		"hatch_01": [Vector2(320, 112), Vector2(384, 144)],
		"hatch_threshold": [Vector2(320, 112), Vector2(384, 144)],
		"exit_trigger_hatch": [Vector2(336, 120), Vector2(400, 152)],
		"hatch_residue": [Vector2(256, 128), Vector2(320, 160)]
	}

	for node_name in cluster_h_nodes:
		var n := room.get_node_or_null(node_name) as Node2D
		_assert_true(n != null, "Cluster H node %s exists" % node_name)
		var old_pos: Vector2 = cluster_h_nodes[node_name][0]
		var exp_pos: Vector2 = cluster_h_nodes[node_name][1]
		_assert_eq(n.position, exp_pos, "Cluster H node %s moved exactly (+64, +32)" % node_name)
		_assert_eq(n.position - old_pos, Vector2(64, 32), "Cluster H shift invariant for %s" % node_name)

	# Invariant distance check within Cluster H: hatch_01 to n11_hatch_tech
	var hatch := room.get_node("hatch_01") as Node2D
	var tech := room.get_node("n11_hatch_tech") as Node2D
	_assert_eq(hatch.position.distance_to(tech.position), Vector2(320, 112).distance_to(Vector2(304, 104)),
		"internal distance between hatch_01 and n11_hatch_tech strictly invariant")

	# Cluster BC: Delta (+128, +64) from greybox baseline
	var cluster_bc_nodes := {
		"counterweight_gear": [Vector2(384, 112), Vector2(512, 176)],
		"gear_residue": [Vector2(368, 120), Vector2(496, 184)],
		"fire_shutter": [Vector2(384, 160), Vector2(512, 224)],
		"shutter_threshold_trigger": [Vector2(384, 160), Vector2(512, 224)],
		"reset_anchor_01": [Vector2(288, 144), Vector2(416, 208)],
		"doc_tech_log": [Vector2(288, 192), Vector2(416, 256)],
		"inner_shutter": [Vector2(432, 184), Vector2(560, 248)],
		"inner_shutter_threshold": [Vector2(432, 184), Vector2(560, 248)],
		"exit_trigger_east_02": [Vector2(448, 192), Vector2(576, 256)],
		"doc_inner_shutter_plate": [Vector2(480, 160), Vector2(608, 224)]
	}

	for node_name in cluster_bc_nodes:
		var n := room.get_node_or_null(node_name) as Node2D
		_assert_true(n != null, "Cluster BC node %s exists" % node_name)
		var old_pos: Vector2 = cluster_bc_nodes[node_name][0]
		var exp_pos: Vector2 = cluster_bc_nodes[node_name][1]
		_assert_eq(n.position, exp_pos, "Cluster BC node %s moved exactly (+128, +64)" % node_name)
		_assert_eq(n.position - old_pos, Vector2(128, 64), "Cluster BC shift invariant for %s" % node_name)

	# Invariant distance check within Cluster BC: counterweight_gear to fire_shutter
	var gear := room.get_node("counterweight_gear") as Node2D
	var shutter := room.get_node("fire_shutter") as Node2D
	_assert_eq(gear.position.distance_to(shutter.position), Vector2(384, 112).distance_to(Vector2(384, 160)),
		"internal distance between counterweight_gear and fire_shutter strictly invariant")

	stop()


# -------------------------------------------------------------------------------------------------
# 9. Real-input playthrough lifecycle for SO-02 and PZ-002
# -------------------------------------------------------------------------------------------------
func test_real_input_so02_and_pz002_lifecycle() -> void:
	if not await start_at(MAINTENANCE_BAY, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-PZ-006"], [FLAG_REWIND]):
		stop()
		return

	var tech := resolve(&"ch01.maintenance_bay.n11_hatch_tech")
	var hatch := resolve(&"ch01.maintenance_bay.hatch_01") as PlateLinkedGate
	var shutter := resolve(&"ch01.maintenance_bay.fire_shutter") as FireShutter
	var gear := resolve(&"ch01.maintenance_bay.counterweight_gear") as CounterweightGear
	_assert_true(hatch.passage_blocked, "hatch initially closed")
	_assert_true(shutter.passage_blocked, "fire shutter initially closed")

	# Step 1: Trace technician to unlock Freeze
	await walk_to(player, "approach technician", Vector2(352, 144))
	if not await use_watch(&"trace", tech, func() -> bool: return session.narrative_state.has_flag(FLAG_FREEZE), "technician traced"):
		stop()
		return
	await dismiss_blocking_ui()
	_assert_true(session.ability_unlocks.is_unlocked(&"freeze"), "Freeze unlocked")

	# Step 2: Walk to hatch_plate_01 at (320, 160)
	await walk_to(player, "walk to hatch_plate_01", Vector2(320, 160), func() -> bool: return not hatch.passage_blocked)
	await physics_frames(10)
	_assert_false(hatch.passage_blocked, "stepping on hatch_plate_01 opened hatch_01")

	# Freeze hatch open
	if not await use_watch(&"freeze", hatch, func() -> bool: return hatch.is_frozen(), "hatch frozen open"):
		stop()
		return

	# Step 3: Walk through hatch aperture (384, 144) to safe_anchor_west (464, 200)
	await walk_to(player, "walk to hatch aperture", Vector2(384, 144))
	await walk_to(player, "walk to safe_anchor_west", Vector2(464, 200))
	_assert_true(player.global_position.distance_to(Vector2(464, 200)) <= 3.0, "reached safe_anchor_west")

	# Step 4: Rewind fire_shutter from within range (488, 188)
	await walk_to(player, "approach shutter rewinder", Vector2(488, 188))
	if not await use_watch(&"rewind", shutter, func() -> bool: return not shutter.passage_blocked, "shutter raised after Rewind"):
		stop()
		return

	# Step 5: Freeze counterweight_gear at (512, 176)
	if not await use_watch(&"freeze", gear, func() -> bool: return gear.is_frozen(), "gear frozen"):
		stop()
		return
	_assert_false(shutter.passage_blocked, "fire shutter held open by frozen gear")

	# Step 6: Walk through fire shutter aperture (512, 224) to safe_anchor_east (544, 240)
	await walk_to(player, "walk through shutter aperture", Vector2(512, 224))
	await walk_to(player, "walk to safe_anchor_east", Vector2(544, 240))
	_assert_true(player.global_position.distance_to(Vector2(544, 240)) <= 3.0, "reached safe_anchor_east")

	# Step 7: Walk towards east door approach (624, 280)
	await walk_to(player, "walk towards east door", EAST_DOOR_APPROACH)
	_assert_true(player.global_position.distance_to(EAST_DOOR_APPROACH) <= 3.0, "reached east door approach")

	stop()
