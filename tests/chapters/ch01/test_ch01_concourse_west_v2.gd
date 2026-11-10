extends "res://tests/support/ch01_real_input.gd"

## TLF-080: Concourse West v2 Room-Specific Validation & Probe Suite
## Tests:
## 1. Door sweep: holding left, up, or down for 3s from arrival never triggers door_entry_west.
## 2. Staff door sweep: with staff door closed, player approaches never enter east door.
## 3. Every canonical stand spot reachable within 2.6 px with real physics capsule.
## 4. Camera view bounds clamped at arrival, gate, dials, and east door.
## 5. Checkpoint autosave and continue restore player and camera in Concourse West v2.
## 6. TEST-AU-08: Courier unlocks Rewind with real room colliders.
## 7. Mutation check: sweep detects trigger when door aperture is moved onto the walking line.

const CONCOURSE := &"ch01.concourse_west"
const ARRIVAL_SPAWN := Vector2(224, 144)
const GATE_APPROACH := Vector2(298, 198)
const EAST_DOOR_APPROACH := Vector2(608, 336)


func _init() -> void:
	timeout_frames = 3600


func test_door_sweep_arrival_never_triggers_door_entry_west() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	_assert_eq(player.global_position, ARRIVAL_SPAWN, "player spawned at arrival (224, 144)")

	# Sweep 1: Hold LEFT for 3 seconds (180 physics ticks)
	hold_moves([&"move_left"])
	await physics_frames(180)
	hold_moves([])
	_assert_eq(router.current_room_id, CONCOURSE, "holding left for 3s never leaves concourse_west")
	_assert_true(player.global_position.x < ARRIVAL_SPAWN.x, "player moved left against west boundary")

	# Reset to arrival spawn
	player.global_position = ARRIVAL_SPAWN
	player.velocity = Vector2.ZERO
	await physics_frames(2)

	# Sweep 2: Hold UP for 3 seconds (180 physics ticks)
	hold_moves([&"move_up"])
	await physics_frames(180)
	hold_moves([])
	_assert_eq(router.current_room_id, CONCOURSE, "holding up for 3s never leaves concourse_west")

	# Reset to arrival spawn
	player.global_position = ARRIVAL_SPAWN
	player.velocity = Vector2.ZERO
	await physics_frames(2)

	# Sweep 3: Hold DOWN for 3 seconds (180 physics ticks)
	hold_moves([&"move_down"])
	await physics_frames(180)
	hold_moves([])
	_assert_eq(router.current_room_id, CONCOURSE, "holding down for 3s never leaves concourse_west")

	stop()


func test_door_sweep_staff_door_closed_never_enters_east_door() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	# Probe approach from west towards east door (640, 352)
	player.global_position = Vector2(600, 352)
	player.velocity = Vector2.ZERO
	await physics_frames(2)
	hold_moves([&"move_right", &"move_down"])
	await physics_frames(120)
	hold_moves([])
	_assert_eq(router.current_room_id, CONCOURSE, "closed staff door blocks approach from west")

	# Probe approach from north (640, 308) towards east door
	player.global_position = Vector2(640, 308)
	player.velocity = Vector2.ZERO
	await physics_frames(2)
	hold_moves([&"move_down"])
	await physics_frames(120)
	hold_moves([])
	_assert_eq(router.current_room_id, CONCOURSE, "closed staff door blocks approach from north")

	# Probe approach from south-west (600, 378) towards east door
	player.global_position = Vector2(600, 378)
	player.velocity = Vector2.ZERO
	await physics_frames(2)
	hold_moves([&"move_right", &"move_up"])
	await physics_frames(120)
	hold_moves([])
	_assert_eq(router.current_room_id, CONCOURSE, "closed staff door blocks approach from south-west")

	stop()


func test_every_stand_spot_reachable_within_2_6_px() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], [&"ch01.npc.n05.traced"]):
		stop()
		return

	var spots: Array[Dictionary] = [
		{"name": "checkpoint", "pos": Vector2(240, 152), "target_id": &""},
		{"name": "call_box_09", "pos": Vector2(280, 100), "target_id": &"ch01.concourse_west.call_box_09"},
		{"name": "conduit_01", "pos": Vector2(160, 168), "target_id": &"ch01.concourse_west.conduit_01"},
		{"name": "doc_ticket_terms", "pos": Vector2(104, 196), "target_id": &"ch01.concourse_west.doc_ticket_terms"},
		{"name": "safe_anchor_east", "pos": Vector2(304, 184), "target_id": &""},
		{"name": "turnstile_gate", "pos": Vector2(298, 198), "target_id": &"ch01.concourse_west.turnstile_gate"},
		{"name": "safe_anchor_west", "pos": Vector2(352, 208), "target_id": &""},
		{"name": "ConcourseBench", "pos": Vector2(496, 200), "target_id": &""},
		{"name": "reset_anchor_02", "pos": Vector2(544, 200), "target_id": &""},
		{"name": "dial_line", "pos": Vector2(544, 200), "target_id": &"ch01.concourse_west.dial_line"},
		{"name": "dial_platform", "pos": Vector2(576, 216), "target_id": &"ch01.concourse_west.dial_platform"},
		{"name": "dial_time", "pos": Vector2(608, 232), "target_id": &"ch01.concourse_west.dial_time"},
		{"name": "ticket_validator", "pos": Vector2(608, 248), "target_id": &"ch01.concourse_west.ticket_validator"},
		{"name": "doc_evac_notice", "pos": Vector2(416, 272), "target_id": &"ch01.concourse_west.doc_evac_notice"},
		{"name": "n09_teen", "pos": Vector2(432, 336), "target_id": &"ch01.concourse_west.n09_teen"},
		{"name": "n08_father", "pos": Vector2(480, 360), "target_id": &"ch01.concourse_west.n08_father"},
		{"name": "n07_briefcase", "pos": Vector2(512, 344), "target_id": &"ch01.concourse_west.n07_briefcase"},
		{"name": "n06_red_coat", "pos": Vector2(544, 328), "target_id": &"ch01.concourse_west.n06_red_coat"},
		{"name": "door_exit_east approach", "pos": Vector2(608, 336), "target_id": &""}
	]

	for entry in spots:
		var pos: Vector2 = entry["pos"]
		var label: String = entry["name"]
		if label == "n09_teen":
			await walk_to(player, "waypoint corridor before queue", Vector2(400, 290))
		elif label == "n08_father":
			await walk_to(player, "waypoint south of N-08", Vector2(452, 366))
		elif label == "door_exit_east approach":
			await walk_to(player, "waypoint corridor east", Vector2(576, 300))

		await walk_to(player, "reach spot %s" % label, pos, Callable(), 300, true)
		for step in 10:
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
				# Check interaction focus or watch ability targeting
				var ok_focus: bool = (focused == target_node or player.pocket_watch.current_target == target_node)
				_assert_true(ok_focus, "spot %s resolves focus or watch target to %s" % [label, tid])

	stop()


func test_camera_view_bounds_clamped() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	var cam := router.camera as RoomCamera
	_assert_true(cam != null, "RoomCamera active")
	var bounds: Rect2 = router.current_room_bounds()
	_assert_true(bounds.has_area(), "Concourse room bounds derived from room_shape: %s" % bounds)
	var view: Vector2 = RoomCamera.view_size()

	var test_points := [
		{"name": "arrival", "pos": ARRIVAL_SPAWN},
		{"name": "gate", "pos": Vector2(320, 192)},
		{"name": "dials", "pos": Vector2(576, 216)},
		{"name": "east door", "pos": EAST_DOOR_APPROACH}
	]

	for pt in test_points:
		player.global_position = pt["pos"]
		cam.snap_now()
		var center := cam.position
		# Whole-pixel camera centre assertion
		_assert_eq(center, center.round(), "camera center %s is whole-pixel" % pt["name"])

		# View rect clamping
		if bounds.size.x >= view.x:
			_assert_true(center.x - view.x / 2.0 >= bounds.position.x - 1.0, "%s camera left edge within bounds" % pt["name"])
			_assert_true(center.x + view.x / 2.0 <= bounds.end.x + 1.0, "%s camera right edge within bounds" % pt["name"])
		else:
			_assert_eq(center.x, roundf(bounds.get_center().x), "%s camera x centered on bounds" % pt["name"])

		if bounds.size.y >= view.y:
			_assert_true(center.y - view.y / 2.0 >= bounds.position.y - 1.0, "%s camera top edge within bounds" % pt["name"])
			_assert_true(center.y + view.y / 2.0 <= bounds.end.y + 1.0, "%s camera bottom edge within bounds" % pt["name"])
		else:
			_assert_eq(center.y, roundf(bounds.get_center().y), "%s camera y centered on bounds" % pt["name"])

	stop()


func test_checkpoint_saveload_restores_player_and_camera() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	var cp_zone := Vector2(240, 152)
	var outside := Vector2(280, 100)
	if not await save_at_checkpoint(&"ch01.cp.concourse_west", cp_zone, outside):
		stop()
		return

	# Move player away to dials
	player.global_position = Vector2(576, 216)
	await physics_frames(2)
	_assert_true(player.global_position != ARRIVAL_SPAWN, "player moved away before continue")

	# Continue from autosave
	if not await continue_from_autosave():
		stop()
		return

	_assert_eq(router.current_room_id, CONCOURSE, "continue restored concourse_west")
	# Restored to safe_anchor_east at (304, 184)
	var expected_spawn := Vector2(304, 184)
	_assert_true(player.global_position.distance_to(expected_spawn) < 2.0,
		"player restored to safe anchor east %s (got %s)" % [expected_spawn, player.global_position])

	stop()


func test_au08_courier_unlocks_rewind_with_real_colliders() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	_assert_false(player.pocket_watch.is_ability_unlocked(&"rewind"), "Rewind initially locked")
	_assert_true(player.pocket_watch.is_ability_unlocked(&"trace"), "Trace unlocked")

	player.pocket_watch.selected_ability = &"trace"
	player.pocket_watch.update_targeting()
	await physics_frames(1)

	var courier := resolve(&"ch01.concourse_west.n05_courier")
	_assert_true(courier != null, "n05_courier exists")
	_assert_eq(player.pocket_watch.current_target, courier, "n05_courier is auto-targeted by Trace from arrival")

	# Trace courier with watch
	await tap(&"watch")
	var flag_done = func() -> bool: return bool(session.narrative_state.get_flag(&"ch01.npc.n05.traced"))
	_assert_true(await until(flag_done, 60), "n05 traced flag set")
	await dismiss_blocking_ui()
	var rewind_done = func() -> bool: return player.pocket_watch.is_ability_unlocked(&"rewind")
	_assert_true(await until(rewind_done, 60), "Rewind unlocked by courier Trace")

	stop()


func test_mutation_check_sweep_fails_when_stubbed() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	# Wait past arrival grace ticks (12 ticks)
	await physics_frames(15)

	var door := resolve(&"ch01.concourse_west.door_entry_west") as Area2D
	_assert_true(door != null, "door_entry_west found")
	var original_pos := door.global_position

	# Stub: move the door trigger directly onto the walking line (210, 144)
	door.global_position = Vector2(210, 144)
	await physics_frames(2)

	hold_moves([&"move_left"])
	await physics_frames(60)
	hold_moves([])

	# A door placed on the walking line must be triggered by walking left
	var triggered: bool = (router.current_room_id != CONCOURSE)
	_assert_true(triggered, "stubbed door on walking path is caught by left movement")

	# Restore
	if is_instance_valid(door):
		door.global_position = original_pos
	stop()
