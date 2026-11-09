extends "res://tests/support/ch01_real_input.gd"

## TLF-069: Verification tests for Arrival Platform v2 (L-shape room + follow camera).
## Requirements:
## 1. Door sweep with gate closed never enters door_exit_east.
## 2. Every interactable stand spot is reachable within 2.6 px with the real player capsule.
## 3. Camera view rect never extends outside room bounds (bounds_px) at spawn, watch, pit edge, gate.
## 4. Save/load at checkpoint restores Elias and camera together.
## 5. Walking to digital_clock_2359 trigger at (592, 200) and interacting plays EL_CLOCK_2359.

const R1 := &"ch01.arrival_platform"


func _init() -> void:
	timeout_frames = 3600


## 1. Door sweep: closed gate holds and cannot be glided/pushed through from any angle.
func test_door_sweep_gate_closed_never_enters_door() -> void:
	if not await start_at(R1, &""):
		stop()
		return

	var gate := resolve(&"ch01.arrival_platform.platform_gate") as PoweredDoor
	_assert_true(gate.passage_blocked, "arrival platform gate starts closed")

	var door := router.current_room.get_node("door_exit_east") as Area2D
	var entered := false
	door.body_entered.connect(func(b): if b == player: entered = true)

	var door_pos := Vector2(720, 328)
	var sweep_probes := [
		["spawn", Vector2(160, 224)],
		["north", Vector2(720, 280)],
		["west", Vector2(672, 328)],
		["south-west", Vector2(672, 360)]
	]

	for probe in sweep_probes:
		entered = false
		player.global_position = probe[1]
		await physics_frames(2)
		var reached := await walk_to(player, "door_sweep_" + probe[0], door_pos, Callable(), 120, true)
		_assert_false(reached, "probe %s stopped before door center" % probe[0])
		_assert_false(entered, "probe %s never entered door_exit_east trigger" % probe[0])
		_assert_eq(router.current_room_id, R1, "still in arrival platform after probe %s" % probe[0])

	stop()


## 2. Stand spot reach: Every interactable stand spot is reachable within 2.6 px by real player capsule,
## and the game picks the expected target (choose_best_interactable for use, choose_watch_target for trace).
func test_every_stand_spot_reachable_within_2_6_px() -> void:
	if not await start_at(R1, &""):
		stop()
		return

	player.pocket_watch.unlocked_abilities = [&"trace"]
	player.pocket_watch.selected_ability = &"trace"

	# Table of all objects, stand spots, target IDs, and primary interaction kind
	var spots := [
		["pocket_watch_pickup", Vector2(224, 240), &"global.pocket_watch", &"use"],
		["n02_student", Vector2(224, 160), &"ch01.arrival_platform.n02_student", &"trace"],
		["n03_old_man", Vector2(432, 168), &"ch01.arrival_platform.n03_old_man", &"trace"],
		["n01_conductor", Vector2(480, 208), &"ch01.arrival_platform.n01_conductor", &"trace"],
		["n04_cleaner", Vector2(624, 312), &"ch01.arrival_platform.n04_cleaner", &"trace"],
		["doc_last_service", Vector2(384, 128), &"ch01.arrival_platform.doc_last_service", &"use"],
		["selector_line", Vector2(624, 248), &"ch01.arrival_platform.selector_line", &"use"],
		["selector_platform", Vector2(656, 264), &"ch01.arrival_platform.selector_platform", &"use"],
		["selector_car", Vector2(688, 280), &"ch01.arrival_platform.selector_car", &"use"],
		["release_lever", Vector2(736, 304), &"ch01.arrival_platform.release_lever", &"use"]
	]

	for entry in spots:
		var name: String = entry[0]
		var target_spot: Vector2 = entry[1]
		var target_id: StringName = entry[2]
		var kind: StringName = entry[3]

		# First walk toward the spot using standard walk_to
		await walk_to(player, "reach_" + name, target_spot, Callable(), 300, true)
		# If within standard WALK_TOLERANCE (3.0 px) but not yet <= 2.6 px, step precisely
		for step in 10:
			if player.global_position.distance_to(target_spot) <= 2.6:
				break
			steer(player, target_spot)
			await physics_frames(1)
		hold_moves([])
		var dist := player.global_position.distance_to(target_spot)
		_assert_true(dist <= 2.6, "%s stand spot reached within 2.6 px (got %.2f px)" % [name, dist])

		var target_node := resolve(target_id)
		_assert_true(target_node != null, "%s: target node resolved" % name)
		if kind == &"use":
			var best = Player.choose_best_interactable(player.global_position, player._candidates, &"player")
			_assert_eq(best, target_node, "%s: choose_best_interactable picked target" % name)
		elif kind == &"trace":
			var candidates: Array = _tree().get_nodes_in_group(&"interactable")
			var best = PocketWatch.choose_watch_target(player.global_position, candidates, &"trace", player.pocket_watch.watch_radius, &"player")
			_assert_eq(best, target_node, "%s: choose_watch_target picked target" % name)

	stop()


## 3. Camera bounds: Camera view rect never extends outside room bounds (bounds_px) at key spots.
func test_camera_never_outside_room_bounds() -> void:
	if not await start_at(R1, &""):
		stop()
		return

	var room := router.current_room
	var shape: RoomShape = room.get_meta("room_shape", null)
	_assert_true(shape != null, "room has metadata/room_shape")
	var bounds: Rect2 = shape.bounds_px()

	var cam: RoomCamera = router.camera
	_assert_true(cam != null, "router has RoomCamera")

	var key_spots := [
		["spawn", Vector2(160, 224)],
		["watch", Vector2(240, 232)],
		["pit_edge", Vector2(512, 288)],
		["gate", Vector2(720, 328)]
	]

	for entry in key_spots:
		var label: String = entry[0]
		var spot: Vector2 = entry[1]
		player.global_position = spot
		cam.snap_now()
		await physics_frames(2)

		var view := cam.view_rect()
		var x_in := view.position.x >= bounds.position.x - 0.5 and view.end.x <= bounds.end.x + 0.5
		var y_in := view.position.y >= bounds.position.y - 0.5 and view.end.y <= bounds.end.y + 0.5
		_assert_true(x_in, "camera view X at %s stays within bounds (view x [%.1f, %.1f], bounds x [%.1f, %.1f])" % [
			label, view.position.x, view.end.x, bounds.position.x, bounds.end.x])
		_assert_true(y_in, "camera view Y at %s stays within bounds (view y [%.1f, %.1f], bounds y [%.1f, %.1f])" % [
			label, view.position.y, view.end.y, bounds.position.y, bounds.end.y])

	stop()


## 4. Save/load at checkpoint: Checkpoint save/load restores Elias and camera together.
func test_save_load_at_checkpoint_restores_elias_and_camera_together() -> void:
	if not await start_at(R1, &""):
		stop()
		return

	# Player starts at spawn (160, 224) where checkpoint sits
	var cp_spot := Vector2(160, 224)
	await walk_to(player, "walk_to_checkpoint", cp_spot, Callable(), 120, true)

	var cp := resolve(&"ch01.arrival_platform.checkpoint") as CheckpointZone
	_assert_true(cp != null, "checkpoint zone exists")

	# Trigger checkpoint
	session.interaction_service.trigger_enter(&"player", cp.object_id)
	await physics_frames(5)

	# Move player far away
	player.global_position = Vector2(500, 250)
	router.camera.snap_now()
	await physics_frames(5)
	_assert_true(player.global_position.distance_to(Vector2(160, 224)) > 100.0, "player moved away from spawn")

	# Continue from autosave / checkpoint
	var continued := await continue_from_autosave()
	_assert_true(continued, "continue_from_autosave succeeded")
	await physics_frames(5)

	# Player should be restored at safe_anchor_spawn (160, 224)
	var spawn_pos := Vector2(160, 224)
	var spawn_dist := player.global_position.distance_to(spawn_pos)
	_assert_true(spawn_dist <= 2.0, "player restored at safe_anchor_spawn (dist %.2f <= 2.0 px)" % spawn_dist)

	# Camera should be centred on player and clamped to bounds
	var expected_cam_pos := router.camera.centre_for(player.global_position)
	var cam_dist := router.camera.position.distance_to(expected_cam_pos)
	_assert_true(cam_dist <= 1.0, "camera restored with player (dist %.2f <= 1.0 px)" % cam_dist)

	stop()


## 5. Clock dialogue: Walking to digital_clock_2359 trigger at (592, 200) and interacting plays EL_CLOCK_2359.
func test_digital_clock_2359_dialogue_line_plays() -> void:
	if not await start_at(R1, &""):
		stop()
		return

	var clock_spot := Vector2(592, 204)
	var clock_node := resolve(&"ch01.arrival_platform.digital_clock_2359")
	_assert_true(clock_node != null, "digital_clock_2359 trigger exists")

	# Walk toward the clock until targeted
	var reached := await walk_to(player, "walk_to_clock", clock_spot, targets(clock_node), 300, true)
	_assert_true(reached, "player walked within interaction range of digital_clock_2359")
	_assert_true(targets(clock_node).call(), "digital_clock_2359 is player's current_target")

	# Tap interact to read clock
	await tap(&"interact")
	await physics_frames(3)

	var diag: DialogueBox = ch01.find_child("DialogueBox", true, false) as DialogueBox
	_assert_true(diag != null and diag.is_active, "clock dialogue box active")
	_assert_false(diag.current_lines.is_empty(), "dialogue lines populated")
	if not diag.current_lines.is_empty():
		_assert_eq(diag.current_lines[0][0], "SPK_ELIAS", "speaker is SPK_ELIAS")
		_assert_eq(diag.current_lines[0][1], "EL_CLOCK_2359", "line is EL_CLOCK_2359")

	await dismiss_blocking_ui()
	stop()
