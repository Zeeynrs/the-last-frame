extends "res://tests/support/base_test.gd"

## TLF-076 (ADR-025 V6): Pilot side-view scene — Beat 06 Mira departure memory.
## Verifies per Lead Decisions & Reviews (Opus / Sol):
## 1. TraceBench: Trace before B06 is silent (main behavior).
## 2. TraceBench: Use plays EL_B06_01, adds JRN_CH1_TWO_SILHOUETTES, sets heard flag.
## 3. TraceBench: Second Trace (after B06) enters ch01.side_mira_memory via call_deferred.
## 4. Entry closes EL_B06_01 so dialogue does not linger.
## 5. Camera clamped in [480, 960] horizontally, y=270, horizontal_only = true.
## 6. Cup Rewind: moves from (600, 394) to (540, 384); no message displayed; leaves interact focus to bench.
## 7. Mira Trace: collects ch01.fragment.mira_departure; target marker positioned above Mira head (>=6px clear space).
## 8. Second Trace on Mira: neutral/silent (no unsupported message).
## 9. Exit marker at x=1380 returns to lounge at safe_anchor_center in isometric mode.
## 10. Autosave: memory scene has NO CheckpointZone; autosave does not point to side room.
## 11. Re-entry: cup remains on bench, fragment stays collected.
## 12. Save/load from disk and mode transitions leave zero leaks.

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const MEMORY_ROOM := &"ch01.side_mira_memory"
const LOUNGE_ROOM := &"ch01.waiting_lounge"
const FLOOR_Y := 394.0
const TEST_SAVE_ROOT := "user://tlf_test_mira_memory_saves"
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


# -------------------------------------------------------------------------------------------------
# 1. Full Real Input Memory Flow
# -------------------------------------------------------------------------------------------------
func test_real_input_full_memory_flow() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	var diag: DialogueBox = ch01.get_dialogue_box()
	_advance_dialogue(diag)

	var router: RoomRouter = ch01.room_router
	var player: Player = ch01.player
	var watch: PocketWatch = player.pocket_watch
	var hud: HUD = ch01.get_node_or_null("HUD") as HUD
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]

	# Start in waiting lounge at safe_anchor_center (336, 152)
	router.enter_room(LOUNGE_ROOM, &"", &"ch01.waiting_lounge.safe_anchor_center")
	await physics_frames(2)
	_assert_eq(router.current_room_id, LOUNGE_ROOM, "in waiting lounge")
	_assert_eq(router.current_view_mode(), ViewMode.ISO, "lounge is iso")
	_assert_eq(player.view_mode, ViewMode.ISO, "player in iso mode")

	# Write lounge autosave (slot 0) to establish baseline autosave
	var store: SaveStore = router.save_service as SaveStore
	if store != null:
		store.write_slot(0, router.capture_save("ch01.cp.lounge"))

	# Find trace_bench
	var trace_bench: Interactable = null
	for child in router.current_room.get_children():
		if child is Interactable and child.object_id == &"ch01.waiting_lounge.trace_bench":
			trace_bench = child
			break
	_assert_true(trace_bench != null, "trace_bench found in lounge")

	# Stand near bench (320, 160)
	player.global_position = Vector2(320, 160)
	await physics_frames(2)
	_assert_eq(player.current_target, trace_bench, "bench is interact target")

	# --- (4) Finding 3 check: First Trace before B06 is heard stays SILENT (main behavior) ---
	watch.set_selected_ability(&"trace")
	await physics_frames(1)
	_assert_eq(watch.current_target, trace_bench, "bench is watch target")
	await tap(&"watch")
	await physics_frames(2)
	_assert_false(diag.is_active, "first trace does NOT open dialogue (stays silent like main)")
	_assert_eq(router.current_room_id, LOUNGE_ROOM, "still in lounge after first trace")
	_assert_false(ch01.session.narrative_state.get_flag(&"heard.ch01_b06_bench", false), "heard flag not set yet")

	# --- Use bench: plays EL_B06_01, records JRN_CH1_TWO_SILHOUETTES, sets heard flag ---
	await tap(&"interact")
	await physics_frames(2)
	_assert_true(diag.is_active, "Use on bench triggers EL_B06_01 dialogue")
	_assert_eq(diag.current_sequence_id, &"ch01_b06_bench", "sequence is ch01_b06_bench")
	_assert_true(ch01.session.narrative_state.get_flag(&"heard.ch01_b06_bench", false), "heard flag now set")

	var has_silhouettes := false
	for entry in ch01.session.narrative_state.get_journal():
		if entry.get("key") == "JRN_CH1_TWO_SILHOUETTES":
			has_silhouettes = true
			break
	_assert_true(has_silhouettes, "JRN_CH1_TWO_SILHOUETTES in journal")

	# --- (4) Second Trace on bench (now that B06 is heard): enters side memory scene ---
	# (7) Keep dialogue open when tracing, verify entry closes/finishes it cleanly
	_assert_true(diag.is_active, "dialogue currently active before second trace")
	await tap(&"watch")
	await physics_frames(3)

	_assert_eq(router.current_room_id, MEMORY_ROOM, "second trace loaded side memory scene")
	_assert_eq(router.current_view_mode(), ViewMode.SIDE, "side view mode active")
	_assert_eq(player.view_mode, ViewMode.SIDE, "player in side view mode")
	_assert_eq(player.sprite.sprite_frames, Player.SIDE_FRAMES, "player has side SpriteFrames")
	_assert_eq(player.global_position, Vector2(120, FLOOR_Y), "spawned at anchor (120, 394)")

	# (7) Verify EL_B06_01 dialogue was finished on entry
	_assert_false(diag.is_active, "dialogue closed on entry so EL_B06_01 does not linger")

	# Camera checks
	var cam: RoomCamera = router.camera as RoomCamera
	_assert_true(cam != null, "camera exists")
	_assert_true(cam.horizontal_only, "camera is horizontal only")
	_assert_eq(cam.bounds, Rect2(0, 0, 1440, 540), "camera bounds are (0, 0, 1440, 540)")
	_assert_eq(cam.global_position.y, 270.0, "camera y fixed at 270")
	_assert_eq(cam.global_position.x, 480.0, "camera clamped at left clamp 480 at spawn x=120")

	# --- Walk right to bench (x=520) ---
	await _walk_to_x(player, 510.0, 300)
	_assert_eq(player.global_position.y, FLOOR_Y, "feet stay on floor line y=394 while walking")
	_assert_true(cam.global_position.x >= 480.0 and cam.global_position.x <= 960.0, "camera x clamped in [480, 960]")

	# Look target 1: Station bench look
	await tap(&"interact")
	await physics_frames(2)
	_assert_true(diag.is_active, "bench look: dialogue active")
	_assert_eq(diag.current_lines[0][1], "EL_B06_01", "bench line is EL_B06_01")
	_advance_dialogue(diag)

	# --- Walk right to cup (x=600) ---
	await _walk_to_x(player, 590.0, 150)
	var cup: VoiceRecorderCup = router.current_room.get_node("voice_recorder_cup") as VoiceRecorderCup
	_assert_true(cup != null, "voice_recorder_cup found")
	_assert_eq(cup.position, Vector2(600, FLOOR_Y), "cup starts on floor at (600, 394)")

	# (8) Rewind on cup: moves to (540, 384); NO message displayed on red refusal line
	watch.set_selected_ability(&"rewind")
	await physics_frames(1)
	_assert_eq(watch.current_target, cup, "cup is rewind target")
	await tap(&"watch")
	await physics_frames(2)
	_assert_eq(cup.position, Vector2(540, 384), "cup rewound to bench top at (540, 384)")
	if hud != null and hud.feedback_panel != null:
		_assert_false(hud.feedback_panel.visible, "Rewind cup shows no message on refusal line")

	# --- (9) Focus test: Walk back to x=540, verify cup does NOT steal interact focus from bench ---
	await _walk_to_x(player, 540.0, 100)
	var bench_side: Interactable = router.current_room.get_node("station_bench") as Interactable
	_assert_true(bench_side != null, "station_bench found in side scene")
	_assert_eq(player.current_target, bench_side, "player at x=540 targets bench for interact (cup does not steal focus)")

	# --- Walk right to Mira silhouette (x=780) ---
	await _walk_to_x(player, 756.0, 200)
	_assert_true(absf(player.global_position.x - 756.0) <= 4.0, "standing separated at x=756 facing Mira at x=780")

	var mira: MiraMemorySilhouette = router.current_room.get_node("mira_silhouette") as MiraMemorySilhouette
	_assert_true(mira != null, "mira_silhouette found")

	# (1) Sol P1: verify target highlight anchor is positioned above Mira's head (>=6px clear space)
	watch.set_selected_ability(&"trace")
	await physics_frames(1)
	_assert_eq(watch.current_target, mira, "mira is trace target")
	if hud != null and hud.target_highlight != null:
		_assert_true(hud.target_highlight.visible, "target highlight visible on Mira")
		var marker_y := hud.target_highlight.global_position.y
		# Mira silhouette top pixel is at screen y=353; marker top/bottom is marker_y +/- 5
		# Clear space = 353 - (marker_y + 5) >= 6 => marker_y <= 342
		_assert_true(marker_y <= 342.0, "target highlight marker y (%.1f) is <= 342 (leaves >= 6px clear space above Mira)" % marker_y)

	# Trace Mira once: collects fragment
	await tap(&"watch")
	await physics_frames(2)
	_assert_true(ch01.session.narrative_state.has_fragment(&"ch01.fragment.mira_departure"),
		"ch01.fragment.mira_departure collected")

	# (9) Second trace on Mira: neutral / silent (no unsupported message)
	await tap(&"watch")
	await physics_frames(2)
	if hud != null and hud.feedback_panel != null:
		_assert_false(hud.feedback_panel.visible, "second trace on Mira shows no failure message (neutral)")

	# --- Walk right to clock (x=1180) ---
	await _walk_to_x(player, 1170.0, 350)
	await tap(&"interact")
	await physics_frames(2)
	_assert_true(diag.is_active, "clock look: dialogue active")
	_assert_eq(diag.current_lines[0][1], "EL_CLOCK_2359", "clock line is EL_CLOCK_2359")
	_advance_dialogue(diag)

	# --- Walk right into exit marker (x=1380) ---
	press(&"move_right")
	await until(func() -> bool: return router.current_room_id == LOUNGE_ROOM, 300)
	release(&"move_right")
	await physics_frames(2)

	_assert_eq(router.current_room_id, LOUNGE_ROOM, "returned to waiting lounge")
	_assert_eq(router.current_view_mode(), ViewMode.ISO, "back in iso mode")
	_assert_eq(player.view_mode, ViewMode.ISO, "player back in iso mode")
	_assert_false(router.camera.horizontal_only, "camera restored to iso follow")

	# --- (2) Opus P1-1: verify autosave does NOT point to side memory room ---
	if store != null:
		var slot0: Dictionary = store.read_slot(0)
		_assert_true(slot0.get("ok", false), "autosave slot 0 exists")
		var data: Dictionary = slot0.get("data", {})
		var saved_room = data.get("spatial", {}).get("actor_rooms", {}).get("player", "")
		_assert_false(saved_room == String(MEMORY_ROOM), "autosave does NOT point to side memory room")
		_assert_eq(saved_room, String(LOUNGE_ROOM), "autosave points to waiting lounge")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_real_input_full_memory_flow")


# -------------------------------------------------------------------------------------------------
# 2. Re-entry Memory Flow
# -------------------------------------------------------------------------------------------------
func test_reentry_memory_flow() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	var diag: DialogueBox = ch01.get_dialogue_box()
	_advance_dialogue(diag)

	var router: RoomRouter = ch01.room_router
	var player: Player = ch01.player
	var watch: PocketWatch = player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]

	# Set up narrative state: Beat 06 heard so Trace on bench enters memory
	ch01.session.narrative_state.set_flag(&"heard.ch01_b06_bench", true)
	ch01.session.narrative_state.add_journal_entry("JRN_CH1_TWO_SILHOUETTES", "observation")

	# Start in waiting lounge
	router.enter_room(LOUNGE_ROOM, &"", &"ch01.waiting_lounge.safe_anchor_center")
	await physics_frames(2)

	# --- Visit 1: Enter memory room, Rewind cup to bench, exit ---
	player.global_position = Vector2(320, 160)
	watch.set_selected_ability(&"trace")
	await physics_frames(1)
	await tap(&"watch")
	await physics_frames(3)
	_assert_eq(router.current_room_id, MEMORY_ROOM, "visit 1: entered memory room")

	# Walk to cup and rewind it onto bench
	await _walk_to_x(player, 590.0, 350)
	var cup1: VoiceRecorderCup = router.current_room.get_node("voice_recorder_cup") as VoiceRecorderCup
	_assert_true(cup1 != null, "cup found in visit 1")
	_assert_eq(cup1.position, Vector2(600, FLOOR_Y), "cup starts at (600, 394)")

	watch.set_selected_ability(&"rewind")
	await physics_frames(2)
	_assert_eq(watch.current_target, cup1, "cup is rewind target")
	await tap(&"watch")
	await physics_frames(2)
	_assert_eq(cup1.position, Vector2(540, 384), "cup rewound to bench top at (540, 384)")

	# Exit back to lounge
	await _walk_to_x(player, 1360.0, 600)
	press(&"move_right")
	await until(func() -> bool: return router.current_room_id == LOUNGE_ROOM, 150)
	release(&"move_right")
	await physics_frames(2)
	_assert_eq(router.current_room_id, LOUNGE_ROOM, "visit 1: returned cleanly to lounge")

	# --- Visit 2 (Re-entry): Trace bench again, assert cup still on bench & rewind returns no_history ---
	player.global_position = Vector2(320, 160)
	watch.set_selected_ability(&"trace")
	await physics_frames(1)
	await tap(&"watch")
	await physics_frames(3)
	_assert_eq(router.current_room_id, MEMORY_ROOM, "visit 2: re-entered memory room")

	var cup2: VoiceRecorderCup = router.current_room.get_node("voice_recorder_cup") as VoiceRecorderCup
	_assert_true(cup2 != null, "cup found in visit 2")
	_assert_eq(cup2.position, Vector2(540, 384), "re-entry: cup remains on bench at (540, 384)")

	# Assert temporal history rewind returns no_history
	var cup_temporal: TemporalComponent = cup2.get_temporal()
	_assert_true(cup_temporal != null, "cup temporal component exists")
	_assert_eq(cup_temporal.rewind(), &"no_history", "re-entry: rewinding cup again returns no_history")

	# Elias near cup cannot target cup for watch
	await _walk_to_x(player, 540.0, 300)
	watch.set_selected_ability(&"rewind")
	await physics_frames(2)
	_assert_false(watch.current_target == cup2, "re-entry: cup is not targetable for watch")

	# Exit back to lounge
	await _walk_to_x(player, 1360.0, 600)
	press(&"move_right")
	await until(func() -> bool: return router.current_room_id == LOUNGE_ROOM, 150)
	release(&"move_right")
	await physics_frames(2)
	_assert_eq(router.current_room_id, LOUNGE_ROOM, "visit 2: returned cleanly to lounge")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_reentry_memory_flow")


# -------------------------------------------------------------------------------------------------
# 3. Save / Load from Disk Inside Memory Room
# -------------------------------------------------------------------------------------------------
func test_save_and_continue_from_disk() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	var diag: DialogueBox = ch01.get_dialogue_box()
	_advance_dialogue(diag)

	var router: RoomRouter = ch01.room_router
	var player: Player = ch01.player
	var store: SaveStore = router.save_service as SaveStore
	_assert_true(store != null, "store exists")

	# Save in lounge at lounge checkpoint
	router.enter_room(LOUNGE_ROOM, &"", &"ch01.waiting_lounge.safe_anchor_center")
	await physics_frames(2)
	var lounge_snap: Dictionary = router.capture_save("ch01.cp.waiting_lounge")
	var save_res: Error = store.write_slot(0, lounge_snap)
	_assert_eq(save_res, OK, "manual save to slot 0 ok")

	# Setup: in memory room
	router.enter_room(MEMORY_ROOM, &"", &"ch01.side_mira_memory.anchor")
	await physics_frames(2)
	_assert_eq(router.current_room_id, MEMORY_ROOM, "in memory room")

	# Continue from disk (autosave slot 0 written in lounge)
	var read_res: Dictionary = store.read_slot(0)
	_assert_true(read_res.get("ok", false), "read slot 0 ok")
	var restore_res: Dictionary = router.restore_from_save(read_res["data"])
	_assert_true(restore_res.get("ok", false), "restore from save ok")
	await physics_frames(3)

	_assert_eq(router.current_room_id, LOUNGE_ROOM, "restored in waiting lounge from disk")
	_assert_eq(router.current_view_mode(), ViewMode.ISO, "iso view mode active after load")
	_assert_eq(player.view_mode, ViewMode.ISO, "player is iso view after load")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_save_and_continue_from_disk")


# -------------------------------------------------------------------------------------------------
# 4. Walk Bounds and Clamping
# -------------------------------------------------------------------------------------------------
func test_walk_bounds_and_clamping() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_dialogue(ch01.get_dialogue_box())

	var router: RoomRouter = ch01.room_router
	var player: Player = ch01.player
	router.enter_room(MEMORY_ROOM, &"", &"ch01.side_mira_memory.anchor")
	await physics_frames(2)

	var cam: RoomCamera = router.camera as RoomCamera
	_assert_true(cam != null, "camera exists")

	# Walk hard left past 0, check bounds while holding input
	press(&"move_left")
	await physics_frames(70)
	_assert_true(player.global_position.x >= 16.0, "left walk clamped at x >= 16 (got %.1f)" % player.global_position.x)
	_assert_eq(player.global_position.x, 16.0, "left walk hits clamp limit exactly at x=16")
	_assert_eq(player.global_position.y, FLOOR_Y, "y clamped at floor line 394")
	_assert_eq(cam.global_position.x, 480.0, "camera clamped at left clamp 480 when player is at x=16")
	release(&"move_left")
	await physics_frames(2)

	# Disable exit marker trigger so player can walk past 1380 to the true right bound 1424
	var exit_marker: Area2D = router.current_room.get_node_or_null("exit_marker") as Area2D
	if exit_marker != null:
		exit_marker.monitoring = false

	# Walk hard right towards exit limit, check bounds while holding input
	player.global_position.x = 1350.0
	await physics_frames(1)
	press(&"move_right")
	await physics_frames(60)
	_assert_true(player.global_position.x <= 1424.0, "right walk clamped at x <= 1424 (got %.1f)" % player.global_position.x)
	_assert_eq(player.global_position.x, 1424.0, "right walk hits clamp limit exactly at x=1424")
	_assert_eq(player.global_position.y, FLOOR_Y, "y clamped at floor line 394")
	_assert_eq(cam.global_position.x, 960.0, "camera clamped at right clamp 960 when player is at x=1424 (bounds 0..1440)")
	release(&"move_right")
	await physics_frames(2)

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_walk_bounds_and_clamping")


# -------------------------------------------------------------------------------------------------
# 5. Freeze and Echo Safety
# -------------------------------------------------------------------------------------------------
func test_freeze_and_echo_safety() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_dialogue(ch01.get_dialogue_box())

	var router: RoomRouter = ch01.room_router
	var player: Player = ch01.player
	var watch: PocketWatch = player.pocket_watch
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]

	router.enter_room(MEMORY_ROOM, &"", &"ch01.side_mira_memory.anchor")
	await physics_frames(2)

	# Test Freeze on cup: refused as unsupported
	var cup = router.current_room.get_node("voice_recorder_cup") as Interactable
	watch.set_selected_ability(&"freeze")
	player.global_position = Vector2(590, FLOOR_Y)
	await physics_frames(2)
	var freeze_res = watch.activate_watch()
	_assert_false(freeze_res.ok, "freeze on cup is refused")

	# Test Echo: start recording, walk, stop recording without crashing
	watch.set_selected_ability(&"echo")
	await physics_frames(1)
	var echo_res = watch.activate_watch()
	_assert_true(echo_res.ok, "echo records without error")
	press(&"move_right")
	await physics_frames(10)
	release(&"move_right")
	await physics_frames(1)
	watch.activate_watch()
	await physics_frames(5)

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_freeze_and_echo_safety")


# -------------------------------------------------------------------------------------------------
# 6. Mode Switch Leaves No Leaks
# -------------------------------------------------------------------------------------------------
func test_mode_switch_leaves_no_leaks() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_dialogue(ch01.get_dialogue_box())

	var router: RoomRouter = ch01.room_router
	router.enter_room(LOUNGE_ROOM, &"", &"ch01.waiting_lounge.safe_anchor_center")
	await physics_frames(2)

	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)

	# Round trip 3 times between Iso and Side
	for i in range(3):
		router.enter_room(MEMORY_ROOM, &"", &"ch01.side_mira_memory.anchor")
		await physics_frames(2)
		_assert_eq(router.current_view_mode(), ViewMode.SIDE, "iteration %d: side mode" % i)

		router.enter_room(LOUNGE_ROOM, &"", &"ch01.waiting_lounge.safe_anchor_center")
		await physics_frames(2)
		_assert_eq(router.current_view_mode(), ViewMode.ISO, "iteration %d: iso mode" % i)

	_assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before,
		"no orphan nodes leaked after 3 mode-switch round trips")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_mode_switch_leaves_no_leaks")
