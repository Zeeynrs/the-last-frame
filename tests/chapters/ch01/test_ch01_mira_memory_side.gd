extends "res://tests/support/base_test.gd"

## TLF-076 (ADR-025 V6): Pilot side-view scene — Beat 06 Mira departure memory.
## Verifies:
## 1. Entry from waiting lounge on second Trace on trace_bench (first Trace is untouched).
## 2. Real-input walk across the 1440 px scene on floor line y=394.
## 3. Look x2 at station bench (x=520, EL_B06_01) and digital clock (x=1180, EL_CLOCK_2359).
## 4. Trace once on Mira silhouette (x=780, JRN_CH1_TWO_SILHOUETTES + ch01.fragment.mira_departure).
## 5. Rewind once on voice recorder cup (x=600 -> returns to bench top at x=540, y=384; second rewind refused).
## 6. Freeze and Echo safely refused/executed without crashing.
## 7. Exit marker at x=1380 returns to waiting lounge at safe_anchor_center in isometric mode.
## 8. Save inside side scene and restore (mode, sprites, camera, anchor, return target).
## 9. Objects reachable from both sides within 24 px.
## 10. Walk bounds clamped to [16, 1424] on floor line y=394.
## 11. Iso <-> side mode transitions leave no leaked orphan nodes.

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const MEMORY_ROOM := &"ch01.side_mira_memory"
const LOUNGE_ROOM := &"ch01.waiting_lounge"
const FLOOR_Y := 394.0
const TEST_SAVE_ROOT := "user://tlf_test_mira_memory_saves"
const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"

const ViewMode = preload("res://scripts/rooms/view_mode.gd")
const SideView = preload("res://scripts/rooms/side_view.gd")


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


func _make_ch01() -> Chapter01:
	_cleanup_test_save_dir()
	var ch01_scene := load(CH01_SCENE_PATH) as PackedScene
	var ch01 := ch01_scene.instantiate() as Chapter01
	var router := ch01.get_node_or_null("RoomRouter") as RoomRouter
	if router != null:
		var store := SaveStore.new()
		store.name = "TestSaveStore"
		store.save_root = TEST_SAVE_ROOT
		router.add_child(store)
		router.save_service = store

	var hud_scene := load("res://scenes/ui/HUD.tscn") as PackedScene
	var hud := hud_scene.instantiate() as HUD
	ch01.add_child(hud)

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


func _advance_dialogue(diag: DialogueBox) -> void:
	var safety := 0
	while diag != null and diag.is_active and safety < 50:
		diag.advance_line()
		safety += 1


func _walk_to_x(player: Player, target_x: float, max_frames: int = 500) -> void:
	var action: StringName = &"move_right" if target_x > player.global_position.x else &"move_left"
	press(action)
	var cond = (func() -> bool: return player.global_position.x >= target_x) if action == &"move_right" else (func() -> bool: return player.global_position.x <= target_x)
	await until(cond, max_frames)
	release(action)
	await physics_frames(2)


func _hold(action: StringName, frames: int) -> void:
	press(action)
	await until(func() -> bool: return Input.is_action_pressed(action), 30)
	await physics_frames(frames)
	release(action)
	await until(func() -> bool: return not Input.is_action_pressed(action), 30)
	await physics_frames(1)


# --- Test 1: Real input full flow (entry, walk, look x2, trace, rewind, exit) -------------

func test_real_input_full_memory_flow() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	var diag: DialogueBox = ch01.get_dialogue_box()
	_advance_dialogue(diag)

	var router: RoomRouter = ch01.room_router
	var player: Player = ch01.player
	var watch: PocketWatch = player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]

	# Step 1: Start in waiting lounge at the bench
	router.enter_room(LOUNGE_ROOM, &"", &"ch01.waiting_lounge.safe_anchor_center")
	await physics_frames(2)
	_assert_eq(router.current_room_id, LOUNGE_ROOM, "in waiting lounge")
	_assert_eq(router.current_view_mode(), ViewMode.ISO, "lounge is iso")
	_assert_eq(player.view_mode, ViewMode.ISO, "player in iso mode")
	_assert_eq(player.sprite.sprite_frames, Player.ISO_FRAMES, "player has iso sprites")

	# Find trace_bench
	var trace_bench: Interactable = null
	for child in router.current_room.get_children():
		if child is Interactable and child.object_id == &"ch01.waiting_lounge.trace_bench":
			trace_bench = child
			break
	_assert_true(trace_bench != null, "trace_bench found in lounge")

	# First Trace on bench: Main flow untouched (EL_B06_01 + JRN_CH1_TWO_SILHOUETTES)
	watch.set_selected_ability(&"trace")
	player.global_position = trace_bench.global_position
	await physics_frames(2)
	var trace_res1 := watch.activate_watch()
	_assert_true(trace_res1.ok, "first trace succeeds")
	_assert_true(diag.is_active, "dialogue active after first trace")
	_assert_eq(diag.current_sequence_id, &"ch01_b06_bench", "sequence is ch01_b06_bench")
	_advance_dialogue(diag)
	_assert_eq(router.current_room_id, LOUNGE_ROOM, "still in lounge after first trace")

	# Second Trace on bench: enters side memory scene!
	player.global_position = trace_bench.global_position
	await physics_frames(2)
	var trace_res2 := watch.activate_watch()
	_assert_true(trace_res2.ok, "second trace succeeds")
	await physics_frames(3)
	_assert_eq(router.current_room_id, MEMORY_ROOM, "second trace loaded side memory scene")
	_assert_eq(router.current_view_mode(), ViewMode.SIDE, "side view mode active")
	_assert_eq(player.view_mode, ViewMode.SIDE, "player in side view mode")
	_assert_eq(player.sprite.sprite_frames, Player.SIDE_FRAMES, "player has side SpriteFrames")
	_assert_eq(player.global_position, Vector2(120, FLOOR_Y), "spawned at anchor (120, 394)")
	_assert_true(router.camera.horizontal_only, "camera is horizontal only")
	_assert_eq(router.camera.bounds, Rect2(0, 0, 1440, 540), "camera bounds are (0, 0, 1440, 540)")

	# Step 2: Walk right towards bench (x=520) using real input
	await _walk_to_x(player, 510.0, 300)
	_assert_eq(player.global_position.y, FLOOR_Y, "feet stay on floor line y=394 while walking")
	_assert_true(absf(player.global_position.x - 520.0) <= 24.0, "near station bench (x %.1f)" % player.global_position.x)

	# Look target 1: Station bench look x2
	await tap(&"interact")
	await physics_frames(2)
	_assert_true(diag.is_active, "bench look 1: dialogue active")
	_assert_eq(diag.current_lines[0][1], "EL_B06_01", "bench line is EL_B06_01")
	_advance_dialogue(diag)

	await tap(&"interact")
	await physics_frames(2)
	_assert_true(diag.is_active, "bench look 2: dialogue active again")
	_assert_eq(diag.current_lines[0][1], "EL_B06_01", "bench line 2 is EL_B06_01")
	_advance_dialogue(diag)

	# Step 3: Walk right to voice recorder cup (x=600)
	await _walk_to_x(player, 590.0, 150)
	_assert_true(absf(player.global_position.x - 600.0) <= 24.0, "near voice recorder cup (x %.1f)" % player.global_position.x)

	var cup: VoiceRecorderCup = router.current_room.get_node("voice_recorder_cup") as VoiceRecorderCup
	_assert_true(cup != null, "voice_recorder_cup found")
	_assert_eq(cup.position, Vector2(600, FLOOR_Y), "cup starts on floor at (600, 394)")

	# Rewind target: Rewind once returns cup to bench top at (540, 384)
	watch.set_selected_ability(&"rewind")
	await physics_frames(2)
	var rew_res1 := watch.activate_watch()
	_assert_true(rew_res1.ok, "rewind on cup succeeds")
	await physics_frames(2)
	_assert_eq(cup.position, Vector2(540, 384), "cup rewound to bench top at (540, 384)")

	# Second Rewind refused: no earlier temporal history
	var rew_res2 := watch.activate_watch()
	_assert_false(rew_res2.ok, "second rewind refused")
	_assert_eq(rew_res2.reason, &"no_history", "reason is no_history")

	# Step 4: Walk right to Mira silhouette (x=780)
	await _walk_to_x(player, 770.0, 200)
	_assert_true(absf(player.global_position.x - 780.0) <= 24.0, "near Mira silhouette (x %.1f)" % player.global_position.x)

	var mira: MiraMemorySilhouette = router.current_room.get_node("mira_silhouette") as MiraMemorySilhouette
	_assert_true(mira != null, "mira_silhouette found")

	# Trace on Mira once: records journal + fragment
	watch.set_selected_ability(&"trace")
	await physics_frames(2)
	var mira_trace1 := watch.activate_watch()
	_assert_true(mira_trace1.ok, "trace on Mira succeeds")
	_assert_true(ch01.session.narrative_state.has_fragment(&"ch01.fragment.mira_departure"),
		"ch01.fragment.mira_departure collected into narrative state")

	# Second Trace on Mira refused / stays used for visit
	var mira_trace2 := watch.activate_watch()
	_assert_false(mira_trace2.ok, "second trace on Mira is refused (stays used)")

	# Step 5: Walk right to suspended clock (x=1180)
	await _walk_to_x(player, 1170.0, 350)
	_assert_true(absf(player.global_position.x - 1180.0) <= 24.0, "near digital clock (x %.1f)" % player.global_position.x)

	# Look target 2: Clock 23:59 look x2
	await tap(&"interact")
	await physics_frames(2)
	_assert_true(diag.is_active, "clock look 1: dialogue active")
	_assert_eq(diag.current_lines[0][1], "EL_CLOCK_2359", "clock line is EL_CLOCK_2359")
	_advance_dialogue(diag)

	await tap(&"interact")
	await physics_frames(2)
	_assert_true(diag.is_active, "clock look 2: dialogue active again")
	_assert_eq(diag.current_lines[0][1], "EL_CLOCK_2359", "clock line 2 is EL_CLOCK_2359")
	_advance_dialogue(diag)

	# Step 6: Walk right into exit marker (x=1380)
	press(&"move_right")
	await until(func() -> bool: return router.current_room_id == LOUNGE_ROOM, 300)
	release(&"move_right")
	await physics_frames(2)

	_assert_eq(router.current_room_id, LOUNGE_ROOM, "returned to waiting lounge")
	_assert_eq(router.current_view_mode(), ViewMode.ISO, "back in iso mode")
	_assert_eq(player.view_mode, ViewMode.ISO, "player is back in iso mode")
	_assert_eq(player.sprite.sprite_frames, Player.ISO_FRAMES, "player has iso sprites again")
	_assert_false(router.camera.horizontal_only, "camera is back to normal iso follow")
	_assert_true(player.global_position.distance_to(Vector2(336, 152)) <= 4.0,
		"player returned to safe_anchor_center (336, 152), actual: %s" % str(player.global_position))

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_real_input_full_memory_flow")


# --- Test 2: Save and restore inside memory scene -----------------------------------------

func test_save_and_restore_inside_memory_scene() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	var router: RoomRouter = ch01.room_router

	# Enter memory room and save
	router.enter_room(MEMORY_ROOM, &"", &"ch01.side_mira_memory.anchor")
	await physics_frames(2)
	_assert_eq(router.current_room_id, MEMORY_ROOM, "in memory room")
	_assert_eq(router.current_view_mode(), ViewMode.SIDE, "side view mode")

	# Save inside scene
	var save_data := router.capture_save("ch01.cp.side_mira_memory")
	_assert_eq(save_data["checkpoint_id"], "ch01.cp.side_mira_memory", "checkpoint saved")
	_assert_eq(save_data["spatial"]["actor_rooms"]["player"], "ch01.side_mira_memory", "player room saved")

	_cleanup_ch01(ch01)

	# Fresh session restore
	var ch01_fresh := _make_ch01()
	await physics_frames(3)
	var r2: RoomRouter = ch01_fresh.room_router
	var p2: Player = ch01_fresh.player

	# Start in iso arrival
	_assert_eq(p2.view_mode, ViewMode.ISO, "fresh session starts in iso mode")

	var restore_res := r2.restore_from_save(save_data)
	_assert_true(restore_res["ok"], "restore succeeds")
	_assert_eq(r2.current_room_id, MEMORY_ROOM, "restored into side memory room")
	_assert_eq(r2.current_view_mode(), ViewMode.SIDE, "restored view mode is side")
	_assert_eq(p2.view_mode, ViewMode.SIDE, "restored player view mode is side")
	_assert_eq(p2.sprite.sprite_frames, Player.SIDE_FRAMES, "restored player has side frames")
	_assert_eq(p2.global_position, Vector2(120, FLOOR_Y), "restored player at anchor (120, 394)")
	_assert_true(r2.camera.horizontal_only, "restored camera is horizontal only")
	_assert_eq(r2.camera.bounds, Rect2(0, 0, 1440, 540), "restored camera bounds are (0, 0, 1440, 540)")

	_cleanup_ch01(ch01_fresh)
	_assert_real_save_unchanged(real_save_before, "test_save_and_restore_inside_memory_scene")


# --- Test 3: Reachable from both sides within 24 px ---------------------------------------

func test_each_object_reachable_from_both_sides() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	var router: RoomRouter = ch01.room_router
	var player: Player = ch01.player
	var watch: PocketWatch = player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]

	router.enter_room(MEMORY_ROOM, &"", &"ch01.side_mira_memory.anchor")
	await physics_frames(2)

	var targets := [
		{"name": "bench", "x": 520.0, "id": &"ch01.side_mira_memory.bench", "action": "use"},
		{"name": "cup", "x": 600.0, "id": &"ch01.side_mira_memory.cup", "action": "rewind"},
		{"name": "mira", "x": 780.0, "id": &"ch01.side_mira_memory.mira", "action": "trace"},
		{"name": "clock", "x": 1180.0, "id": &"ch01.side_mira_memory.clock", "action": "use"},
	]

	for t in targets:
		# Left side: x - 24
		player.global_position = Vector2(t["x"] - 24.0, FLOOR_Y)
		await physics_frames(2)
		if t["action"] == "use":
			_assert_true(player.current_target != null and player.current_target.object_id == t["id"],
				"%s reachable from left side (x %.1f)" % [t["name"], t["x"] - 24.0])
		else:
			watch.set_selected_ability(t["action"])
			await physics_frames(2)
			_assert_true(watch.current_target != null and watch.current_target.object_id == t["id"],
				"%s watch-targetable from left side (x %.1f)" % [t["name"], t["x"] - 24.0])

		# Right side: x + 24
		player.global_position = Vector2(t["x"] + 24.0, FLOOR_Y)
		await physics_frames(2)
		if t["action"] == "use":
			_assert_true(player.current_target != null and player.current_target.object_id == t["id"],
				"%s reachable from right side (x %.1f)" % [t["name"], t["x"] + 24.0])
		else:
			watch.set_selected_ability(t["action"])
			await physics_frames(2)
			_assert_true(watch.current_target != null and watch.current_target.object_id == t["id"],
				"%s watch-targetable from right side (x %.1f)" % [t["name"], t["x"] + 24.0])

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_each_object_reachable_from_both_sides")


# --- Test 4: Walk bounds and clamping -----------------------------------------------------

func test_walk_bounds_and_clamping() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	var router: RoomRouter = ch01.room_router
	var player: Player = ch01.player

	router.enter_room(MEMORY_ROOM, &"", &"ch01.side_mira_memory.anchor")
	await physics_frames(2)

	# Clamped to west walk margin (16 px)
	player.global_position = Vector2(30, FLOOR_Y)
	await _hold(&"move_left", 30)
	_assert_eq(player.global_position, Vector2(16, FLOOR_Y), "stops at walk_min_x (16)")

	# Clamped to floor line y=394 on up/down
	await _hold(&"move_up", 15)
	_assert_eq(player.global_position.y, FLOOR_Y, "move_up does not leave floor line")
	await _hold(&"move_down", 15)
	_assert_eq(player.global_position.y, FLOOR_Y, "move_down does not leave floor line")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_walk_bounds_and_clamping")


# --- Test 5: Freeze and Echo refused / safe without crashes -------------------------------

func test_freeze_and_echo_safety() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	var router: RoomRouter = ch01.room_router
	var player: Player = ch01.player
	var watch: PocketWatch = player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]

	router.enter_room(MEMORY_ROOM, &"", &"ch01.side_mira_memory.anchor")
	await physics_frames(2)

	# Freeze has no valid target in scene; using it returns failure without crash
	player.global_position = Vector2(600, FLOOR_Y)
	watch.set_selected_ability(&"freeze")
	await physics_frames(2)
	var freeze_res := watch.activate_watch()
	_assert_false(freeze_res.ok, "freeze is refused (no freeze target)")
	_assert_true(UIFeedback.REASON_TO_KEY.has(freeze_res.reason), "refusal uses existing reason key (%s)" % freeze_res.reason)

	# Echo: recording and playback works along floor line
	player.global_position = Vector2(200, FLOOR_Y)
	watch.set_selected_ability(&"echo")
	await physics_frames(2)
	var echo_rec := watch.activate_watch()
	_assert_true(echo_rec.ok, "echo starts recording")

	press(&"move_right")
	await physics_frames(30)
	release(&"move_right")
	await physics_frames(2)

	var echo_stop := watch.activate_watch()
	_assert_true(echo_stop.ok, "echo stops recording")

	var echo_play := watch.activate_watch()
	_assert_true(echo_play.ok, "echo plays back without crash")
	await physics_frames(5)

	watch.reset_echo()
	await physics_frames(2)

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_freeze_and_echo_safety")


# --- Test 6: Mode switch leaves no leaked nodes -------------------------------------------

func test_mode_switch_leaves_no_leaks() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	var router: RoomRouter = ch01.room_router
	router.enter_room(LOUNGE_ROOM, &"", &"ch01.waiting_lounge.safe_anchor_center")
	await physics_frames(2)

	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)

	for round in 3:
		router.enter_room(MEMORY_ROOM, &"", &"ch01.side_mira_memory.anchor")
		await physics_frames(2)
		_assert_eq(router.current_room_id, MEMORY_ROOM, "round %d: in memory room" % round)
		_assert_eq(router.current_view_mode(), ViewMode.SIDE, "round %d: side mode" % round)

		router.enter_room(LOUNGE_ROOM, &"", &"ch01.waiting_lounge.safe_anchor_center")
		await physics_frames(2)
		_assert_eq(router.current_room_id, LOUNGE_ROOM, "round %d: back in lounge" % round)
		_assert_eq(router.current_view_mode(), ViewMode.ISO, "round %d: iso mode" % round)

	_assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before,
		"no orphan nodes leaked after 3 mode-switch round trips")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_mode_switch_leaves_no_leaks")
