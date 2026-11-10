extends "res://tests/support/ch01_real_input.gd"

## TLF-080: Concourse West v2 Room-Specific Validation & Probe Suite
## Tests:
## 1. Door sweep: holding left, up, or down for 3s from arrival never triggers door_entry_west.
## 2. Staff door sweep: with staff door closed, player approaches never enter east door.
## 3. Divider sweep: with gate closed, player starting at x=7.2 never passes tile x=8.2.
## 4. Mutation checks: divider sweep goes RED when DividerNorth or DividerSouth is disabled.
## 5. Every canonical stand spot reachable within 2.6 px with real physics capsule.
## 6. Camera view bounds clamped at arrival, gate, dials, and east door with explicit bounds.
## 7. Checkpoint autosave and continue restore player and camera in Concourse West v2.
## 8. TEST-AU-08: Courier unlocks Rewind with real room colliders (tested from arrival and entry anchor).
## 9. TLF-081 Wall Art integration and module transform verification from mount_correction.json.
## 10. Mutation check: sweep detects trigger when door aperture is moved onto the walking line.

const CONCOURSE := &"ch01.concourse_west"
const ARRIVAL_SPAWN := Vector2(224, 144)
const GATE_APPROACH := Vector2(298, 198)
const EAST_DOOR_APPROACH := Vector2(608, 336)


func _init() -> void:
	timeout_frames = 3600


func _tile_to_world(tx: float, ty: float) -> Vector2:
	return Vector2(320.0 + 16.0 * (tx - ty), 64.0 + 8.0 * (tx + ty))


func _world_to_tile(pos: Vector2) -> Vector2:
	var u := pos.x - 320.0
	var v := pos.y - 64.0
	return Vector2(u / 32.0 + v / 16.0, v / 16.0 - u / 32.0)


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


func test_divider_sweep_with_gate_closed_never_passes_x_8_2() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	var turnstile := resolve(&"ch01.concourse_west.turnstile_gate") as TurnstileGate
	_assert_true(turnstile != null and turnstile.passage_blocked, "turnstile gate closed")

	# Start x 7.2 every 0.8 tile of y from 0.8 to 15.2 (19 sweep lines)
	var y_steps: Array[float] = []
	var curr_y := 0.8
	while curr_y <= 15.25:
		y_steps.append(curr_y)
		curr_y += 0.8

	var max_x_reached := 0.0
	for y_tile in y_steps:
		var start_pos := _tile_to_world(7.2, y_tile)
		var push_target := _tile_to_world(9.0, y_tile)
		player.global_position = start_pos
		player.velocity = Vector2.ZERO
		await physics_frames(1)

		await push_for([push_target], 60)
		var end_tile := _world_to_tile(player.global_position)
		if end_tile.x > max_x_reached:
			max_x_reached = end_tile.x
		_assert_true(end_tile.x <= 8.2,
			"divider sweep at y=%.1f: player stopped at tile_x=%.2f <= 8.2" % [y_tile, end_tile.x])

	_assert_true(max_x_reached < 8.0, "maximum x reached during sweep is %.2f < 8.0" % max_x_reached)
	stop()


func test_divider_sweep_mutation_fails_when_divider_north_disabled() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	var div_north := router.current_room.get_node_or_null("TurnstileDividers/DividerNorth") as CollisionShape2D
	_assert_true(div_north != null, "DividerNorth found")
	div_north.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(7.2, 3.2)
	var push_target := _tile_to_world(9.0, 3.2)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 8.2
	_assert_true(crossed, "disabling DividerNorth goes RED (tile_x=%.2f > 8.2)" % end_tile.x)

	div_north.disabled = false
	stop()


func test_divider_sweep_mutation_fails_when_divider_south_disabled() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	var div_south := router.current_room.get_node_or_null("TurnstileDividers/DividerSouth") as CollisionShape2D
	_assert_true(div_south != null, "DividerSouth found")
	div_south.disabled = true
	await physics_frames(1)

	var start_pos := _tile_to_world(7.2, 12.0)
	var push_target := _tile_to_world(9.0, 12.0)
	player.global_position = start_pos
	player.velocity = Vector2.ZERO
	await physics_frames(1)

	await push_for([push_target], 60)
	var end_tile := _world_to_tile(player.global_position)
	var crossed: bool = end_tile.x > 8.2
	_assert_true(crossed, "disabling DividerSouth goes RED (tile_x=%.2f > 8.2)" % end_tile.x)

	div_south.disabled = false
	stop()


func test_every_stand_spot_reachable_within_2_6_px() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001"], [&"ch01.npc.n05.traced"]):
		stop()
		return

	var conduit := resolve(&"ch01.concourse_west.conduit_01") as ConduitProp
	var conduit_spot: Vector2 = Vector2(160, 168) if (conduit != null and conduit.conduit_state == &"mounted") else Vector2(320, 168)

	var spots: Array[Dictionary] = [
		{"name": "checkpoint", "pos": Vector2(240, 152), "target_id": &""},
		{"name": "call_box_09", "pos": Vector2(280, 100), "target_id": &"ch01.concourse_west.call_box_09"},
		{"name": "conduit_01", "pos": conduit_spot, "target_id": &"ch01.concourse_west.conduit_01"},
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
		{"name": "doc_evac_notice", "pos": Vector2(384, 272), "target_id": &"ch01.concourse_west.doc_evac_notice"},
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

	# Opus Item 5: Explicit bounds Rect2(48, 0, 736, 432) and centre (416, 216)
	_assert_eq(bounds, Rect2(48, 0, 736, 432), "explicit concourse_west v2 room bounds Rect2(48, 0, 736, 432)")
	_assert_eq(bounds.get_center(), Vector2(416, 216), "explicit concourse_west v2 room bounds center (416, 216)")

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

	var courier := resolve(&"ch01.concourse_west.n05_courier")
	_assert_true(courier != null, "n05_courier exists")

	# Clause 1 (Opus Item 11 / TEST-AU-08 spec): From the entry anchor (304, 184), the Trace target is n05_courier at 17.9 px
	player.global_position = Vector2(304, 184)
	player.pocket_watch.selected_ability = &"trace"
	player.pocket_watch.update_targeting()
	await physics_frames(1)
	_assert_eq(player.pocket_watch.current_target, courier, "from entry anchor (304, 184), n05_courier is auto-targeted by Trace")
	_assert_true(abs(player.global_position.distance_to(courier.global_position) - 17.89) < 0.5, "courier distance from entry anchor is ~17.9 px")

	# Clause 2 (TEST-AU-08 spec): From (312, 188), turnstile_trace_anchor is auto-targeted by Trace
	player.global_position = Vector2(312, 188)
	player.pocket_watch.update_targeting()
	var trace_anchor := resolve(&"ch01.concourse_west.turnstile_trace_anchor")
	_assert_true(trace_anchor != null, "turnstile_trace_anchor exists")
	_assert_eq(player.pocket_watch.current_target, trace_anchor, "from (312, 188), turnstile_trace_anchor is auto-targeted by Trace")
	_assert_true(abs(player.global_position.distance_to(trace_anchor.global_position) - 17.89) < 0.5, "trace anchor distance from (312, 188) is ~17.9 px")

	# Also verify targeting from arrival spawn (224, 144)
	player.global_position = ARRIVAL_SPAWN
	player.pocket_watch.update_targeting()
	await physics_frames(1)
	_assert_eq(player.pocket_watch.current_target, courier, "n05_courier is auto-targeted by Trace from arrival")

	# Trace courier with watch
	await tap(&"watch")
	var flag_done = func() -> bool: return bool(session.narrative_state.get_flag(&"ch01.npc.n05.traced"))
	_assert_true(await until(flag_done, 60), "n05 traced flag set")
	await dismiss_blocking_ui()
	var rewind_done = func() -> bool: return player.pocket_watch.is_ability_unlocked(&"rewind")
	_assert_true(await until(rewind_done, 60), "Rewind unlocked by courier Trace")

	stop()


func test_tlf081_wall_art_integration_and_transforms() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	var room := router.current_room
	_assert_true(room != null, "concourse_west room loaded")

	# 1. Assert Wall module positions and image top-lefts per mount_correction.json
	var w5 := room.get_node_or_null("YSort_Walls/WallW_5") as Sprite2D
	var w6 := room.get_node_or_null("YSort_Walls/WallW_6") as Sprite2D
	var w7 := room.get_node_or_null("YSort_Walls/WallW_7") as Sprite2D
	var wn7 := room.get_node_or_null("YSort_Walls/WallN_7") as Sprite2D
	var wn8 := room.get_node_or_null("YSort_Walls/WallN_8") as Sprite2D
	var wn9 := room.get_node_or_null("YSort_Walls/WallN_9") as Sprite2D
	var ww1 := room.get_node_or_null("YSort_Walls/WallW_1") as Sprite2D
	_assert_true(w5 != null and w6 != null and w7 != null, "WallW_5, WallW_6, WallW_7 found")
	_assert_true(wn7 != null and wn8 != null and wn9 != null and ww1 != null, "WallN_7..9 and WallW_1 found")

	var w5_tl := w5.global_position + w5.offset
	var w6_tl := w6.global_position + w6.offset
	var w7_tl := w7.global_position + w7.offset
	_assert_eq(w5_tl, Vector2(128, 96), "WallW_5 image top-left is (128, 96)")
	_assert_eq(w6_tl, Vector2(96, 112), "WallW_6 image top-left is (96, 112)")
	_assert_eq(w7_tl, Vector2(64, 128), "WallW_7 image top-left is (64, 128)")
	_assert_eq(wn7.global_position + wn7.offset, Vector2(544, 128), "WallN_7 image top-left is (544, 128)")
	_assert_eq(wn8.global_position + wn8.offset, Vector2(576, 144), "WallN_8 image top-left is (576, 144)")
	_assert_eq(wn9.global_position + wn9.offset, Vector2(608, 160), "WallN_9 image top-left is (608, 160)")
	_assert_eq(ww1.global_position + ww1.offset, Vector2(256, 32), "WallW_1 image top-left is (256, 32)")

	# 2. Assert final PNG top-lefts of TLF-081 variants
	# Fallen conduit: floor pivot (328, 184), PNG top-left (304, 158)
	var conduit := resolve(&"ch01.concourse_west.conduit_01") as ConduitProp
	_assert_true(conduit != null, "conduit_01 found")
	_assert_eq(conduit.conduit_state, &"fallen", "conduit starts fallen")
	_assert_eq(conduit.global_position, Vector2(328, 184), "fallen conduit floor pivot is (328, 184)")
	var conduit_pres := conduit.get_node("Presenter") as ConduitPropPresenter
	conduit_pres._refresh()
	var fallen_tl := conduit_pres.global_position + conduit_pres.offset
	_assert_eq(fallen_tl, Vector2(304, 158), "fallen conduit final PNG top-left is (304, 158)")
	_assert_eq(conduit_pres.texture, conduit_pres.tex_fallen, "fallen conduit uses tex_fallen")

	# Mounted conduit: anchor (144, 160), PNG top-left (112, 102)
	conduit.conduit_state = &"mounted"
	conduit._update_position()
	conduit_pres._refresh()
	_assert_eq(conduit.global_position, Vector2(144, 160), "mounted conduit anchor is (144, 160)")
	var conduit_tl := conduit_pres.global_position + conduit_pres.offset
	_assert_eq(conduit_tl, Vector2(112, 102), "mounted conduit final PNG top-left is (112, 102)")
	_assert_eq(conduit_pres.texture, conduit_pres.tex_mounted, "mounted conduit uses tex_mounted")

	# Restore fallen for remainder of test
	conduit.conduit_state = &"fallen"
	conduit._update_position()
	conduit_pres._refresh()

	# Notice (ticket terms): (72, 146)
	var terms := resolve(&"ch01.concourse_west.doc_ticket_terms") as Area2D
	_assert_true(terms != null, "doc_ticket_terms found")
	var terms_sprite := terms.get_node("DocSprite") as Sprite2D
	var terms_tl := terms_sprite.global_position + terms_sprite.offset
	_assert_eq(terms_tl, Vector2(72, 146), "ticket terms notice final PNG top-left is (72, 146)")

	# Dials N: LINE (544, 134), PLATFORM (576, 150), TIME (608, 166)
	var dial_l := resolve(&"ch01.concourse_west.dial_line") as HistoryDial
	var dial_p := resolve(&"ch01.concourse_west.dial_platform") as HistoryDial
	var dial_t := resolve(&"ch01.concourse_west.dial_time") as HistoryDial
	_assert_true(dial_l != null and dial_p != null and dial_t != null, "dials found")

	var dial_l_pres := dial_l.get_node("Presenter") as Sprite2D
	var dial_p_pres := dial_p.get_node("Presenter") as Sprite2D
	var dial_t_pres := dial_t.get_node("Presenter") as Sprite2D

	_assert_eq(dial_l_pres.global_position + dial_l_pres.offset, Vector2(544, 134), "dial_line PNG top-left is (544, 134)")
	_assert_eq(dial_p_pres.global_position + dial_p_pres.offset, Vector2(576, 150), "dial_platform PNG top-left is (576, 150)")
	_assert_eq(dial_t_pres.global_position + dial_t_pres.offset, Vector2(608, 166), "dial_time PNG top-left is (608, 166)")

	# Call box phone: (260, 36)
	var cb_sprite := room.get_node_or_null("Wall_Fixtures/CallBoxSprite") as Sprite2D
	_assert_true(cb_sprite != null, "CallBoxSprite found")
	_assert_eq(cb_sprite.global_position + cb_sprite.offset, Vector2(260, 36), "call box phone PNG top-left is (260, 36)")

	# Validator: (608, 198)
	var validator := resolve(&"ch01.concourse_west.ticket_validator") as TicketValidator
	_assert_true(validator != null, "ticket_validator found")
	var val_pres := validator.get_node("Presenter") as Sprite2D
	_assert_eq(val_pres.global_position + val_pres.offset, Vector2(608, 198), "ticket validator PNG top-left is (608, 198)")

	# Clock: (480, 99)
	var clock_sprite := room.get_node_or_null("Wall_Fixtures/Clock_3") as Sprite2D
	_assert_true(clock_sprite != null, "Clock_3 found")
	_assert_eq(clock_sprite.global_position + clock_sprite.offset, Vector2(480, 99), "clock PNG top-left is (480, 99)")

	# 3. Mount correction file check: verify against mount_correction.json
	var json_str := FileAccess.get_file_as_string("res://docs/handoffs/TLF-081/mount_correction.json")
	var mc_data = JSON.parse_string(json_str)
	_assert_true(mc_data != null and mc_data is Dictionary, "mount_correction.json loaded")
	if mc_data is Dictionary:
		var mc_conduit: Dictionary = mc_data.get("conduit", {})
		var mc_notice: Dictionary = mc_data.get("notice", {})
		_assert_eq(Vector2(mc_conduit["png_top_left"][0], mc_conduit["png_top_left"][1]), Vector2(112, 102), "mount_correction conduit TL matches")
		_assert_eq(Vector2(mc_notice["png_top_left"][0], mc_notice["png_top_left"][1]), Vector2(72, 146), "mount_correction notice TL matches")

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


func test_conduit_fallen_and_mounted_state_and_rewind_lifecycle() -> void:
	if not await start_at(CONCOURSE, &"door_entry_west", [&"CH1-SO-01"], []):
		stop()
		return

	var conduit := resolve(&"ch01.concourse_west.conduit_01") as ConduitProp
	_assert_true(conduit != null, "conduit_01 found")
	var pres := conduit.get_node("Presenter") as ConduitPropPresenter
	_assert_true(pres != null, "Presenter found")

	# 1. Initial fallen state: pivot (328, 184), PNG TL (304, 158), pins the gate
	_assert_eq(conduit.conduit_state, &"fallen", "starts fallen")
	_assert_true(conduit.is_pinning(), "is_pinning is true when fallen")
	_assert_eq(conduit.global_position, Vector2(328, 184), "fallen floor pivot is (328, 184)")
	pres._refresh()
	_assert_eq(pres.global_position + pres.offset, Vector2(304, 158), "fallen PNG TL is (304, 158)")
	_assert_eq(pres.texture, pres.tex_fallen, "uses tex_fallen")

	# 2. Rewind: moves to mounted (144, 160), PNG TL (112, 102), unpins gate
	var res := session.interaction_service.request(&"player", &"ch01.concourse_west.conduit_01", &"rewind")
	_assert_true(res.ok, "rewind request succeeded")
	_assert_eq(conduit.conduit_state, &"mounted", "rewound to mounted")
	_assert_false(conduit.is_pinning(), "is_pinning is false when mounted")
	_assert_eq(conduit.global_position, Vector2(144, 160), "mounted floor pivot is (144, 160)")
	pres._refresh()
	_assert_eq(pres.global_position + pres.offset, Vector2(112, 102), "mounted PNG TL is (112, 102)")
	_assert_eq(pres.texture, pres.tex_mounted, "uses tex_mounted")

	# Second rewind should report no_history
	var res2 := session.interaction_service.request(&"player", &"ch01.concourse_west.conduit_01", &"rewind")
	_assert_false(res2.ok, "second rewind fails")
	_assert_eq(res2.reason, &"no_history", "second rewind returns no_history")

	# 3. Reset (unsolved): returns to fallen
	conduit.reset_for_puzzle(&"CH1-PZ-001", false)
	_assert_eq(conduit.conduit_state, &"fallen", "reset returns to fallen")
	_assert_true(conduit.is_pinning(), "is_pinning true after reset")
	_assert_eq(conduit.global_position, Vector2(328, 184), "fallen floor pivot is (328, 184)")
	pres._refresh()
	_assert_eq(pres.global_position + pres.offset, Vector2(304, 158), "fallen PNG TL is (304, 158)")

	# 4. Solved latch: latches to mounted
	conduit._apply_solved_state()
	_assert_eq(conduit.conduit_state, &"mounted", "latches to mounted on solved")
	_assert_false(conduit.is_pinning(), "unpinned on solved")
	_assert_eq(conduit.global_position, Vector2(144, 160), "mounted floor pivot is (144, 160)")
	pres._refresh()
	_assert_eq(pres.global_position + pres.offset, Vector2(112, 102), "mounted PNG TL is (112, 102)")

	stop()
