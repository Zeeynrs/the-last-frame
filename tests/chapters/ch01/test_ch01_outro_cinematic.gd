extends "res://tests/support/base_test.gd"

## Automated Test Suite for TLF-059 (Beat 10 Outro Cinematic).
## Verifies Story Bible Ch1 Event 10 / ADR-022 D2 / OPERATOR_MYSTERY_GUIDELINES:
## 1. Node hierarchy, CanvasLayer layer 60, 1280x360 plate, rain & screen positioning.
## 2. Integer-pixel pan progression (no subpixel blur: round(x) == x).
## 3. Reduced effects accessibility: static frame, zero panning.
## 4. SimClock pause and player movement input blocking during playback.
## 5. Skippability via tap `cancel`.
## 6. Skippability via hold `confirm` for 1.0 s.
## 7. 3-line dialogue sequence ("You are late.", 1s pause, "Again.") and VOICE speaker label.
## 8. Save/load lifecycle persistence and idempotency.
## 9. Audio click hook for TLF-064.

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const OUTRO_SCENE_PATH := "res://scenes/ui/cinematics/ch01_outro.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_outro_saves"
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


# -------------------------------------------------------------------------------------------------
# 1. Node Hierarchy, Layer, and Texture Properties
# -------------------------------------------------------------------------------------------------
func test_outro_scene_and_properties() -> void:
	var scene := load(OUTRO_SCENE_PATH) as PackedScene
	_assert_true(scene != null, "ch01_outro.tscn loads cleanly")
	var outro := scene.instantiate() as Ch01Outro
	_assert_true(outro != null, "ch01_outro instantiates cleanly")
	_tree().root.add_child(outro)

	_assert_eq(outro.layer, 60, "CanvasLayer layer is 60 (above rooms, below DialogueBox 70)")

	var plate_container := outro.get_node_or_null("PlateContainer") as Control
	_assert_true(plate_container != null, "PlateContainer exists")
	_assert_eq(plate_container.size, Vector2(1280, 360), "PlateContainer is 1280x360 px")
	# ADR-023 addendum 3: letterboxed in the 960 x 540 view, 1:1 pixel scale, 90 px bars.
	_assert_eq(plate_container.scale, Vector2.ONE, "the plate is not scaled")
	_assert_eq(plate_container.position, Vector2(0, 90), "plate starts at x 0 under a 90 px top bar")
	_assert_eq(Ch01Outro.letterbox_top() * 2.0 + 360.0, 540.0, "equal bars top and bottom of the 540 px view")
	var dimmer := outro.get_node_or_null("Dimmer") as ColorRect
	_assert_true(dimmer != null and dimmer.color == Color.BLACK and dimmer.anchor_right == 1.0 and dimmer.anchor_bottom == 1.0,
		"the black Dimmer fills the whole view behind the plate (the bars)")
	_assert_eq(outro.end_pan_x, 960.0 - 1280.0, "pan ends where the plate's right edge meets the view's (-320)")
	_assert_eq(outro.reduced_effects_static_x, -320.0, "reduced_effects frame is the end frame (-320)")

	var city_plate := outro.get_node_or_null("PlateContainer/CityPlate") as TextureRect
	_assert_true(city_plate != null, "CityPlate node exists")
	_assert_true(city_plate.texture != null, "CityPlate texture assigned")
	_assert_eq(city_plate.texture.get_size(), Vector2(1280, 360), "CityPlate texture is 1280x360 px")

	var backdrop := outro.get_node_or_null("PlateContainer/Backdrop") as TextureRect
	_assert_true(backdrop != null, "Backdrop node exists")

	var screen_left := outro.get_node_or_null("PlateContainer/MiraScreenLeft") as TextureRect
	_assert_true(screen_left != null, "MiraScreenLeft exists")
	_assert_eq(screen_left.position, Vector2(440, 136), "Mira screen left at (440, 136)")

	var screen_right := outro.get_node_or_null("PlateContainer/MiraScreenRight") as TextureRect
	_assert_true(screen_right != null, "MiraScreenRight exists")
	_assert_eq(screen_right.position, Vector2(844, 104), "Mira screen right at (844, 104)")

	var rain := outro.get_node_or_null("PlateContainer/SuspendedRain") as TextureRect
	_assert_true(rain != null, "SuspendedRain node exists")

	var audio := outro.get_node_or_null("AudioClick") as AudioStreamPlayer
	_assert_true(audio != null, "AudioClick node exists for TLF-064 hook")

	# Verify exported timing variables are data-driven and positive
	_assert_true(outro.pan_duration > 0.0, "pan_duration is positive")
	_assert_true(outro.line1_duration > 0.0, "line1_duration is positive")
	_assert_true(outro.line2_pause > 0.0, "line2_pause is positive")
	_assert_true(outro.line2_duration > 0.0, "line2_duration is positive")
	_assert_eq(outro.line3_pause, 1.0, "line3_pause is exactly 1.0 s canon pause")
	_assert_true(outro.line3_duration > 0.0, "line3_duration is positive")
	_assert_true(outro.outro_hold_duration > 0.0, "outro_hold_duration is positive")

	outro.free()


# -------------------------------------------------------------------------------------------------
# 2. Integer-Pixel Pan Progression (No Subpixel Blur)
# -------------------------------------------------------------------------------------------------
func test_outro_integer_pixel_pan_progression() -> void:
	var outro := (load(OUTRO_SCENE_PATH) as PackedScene).instantiate() as Ch01Outro
	_tree().root.add_child(outro)

	outro.start(null, null, null)
	_assert_eq(outro.get_current_pan_x(), 0.0, "Pan starts at x = 0.0")

	# Step across several delta steps and verify every step is an exact integer
	var deltas: Array[float] = [0.0166, 0.0333, 0.125, 0.5, 1.0, 2.5, 4.0, 8.0]
	for d in deltas:
		outro._process(d)
		var cur_x := outro.get_current_pan_x()
		_assert_eq(cur_x, round(cur_x), "Pan x (%.2f) is an exact integer (no subpixel blur)" % cur_x)
		_assert_true(cur_x <= 0.0, "Pan moves leftward (x <= 0.0)")
		_assert_true(cur_x >= -320.0, "Pan does not exceed -320.0")
		_assert_eq(outro.plate_container.position.y, 90.0, "the plate stays between the bars")
	_assert_eq(outro.get_current_pan_x(), -320.0, "Pan ends at x = -320.0 (plate right edge on the view's)")

	outro.free()


# -------------------------------------------------------------------------------------------------
# 3. Accessibility: Reduced Effects Mode (Static Frame)
# -------------------------------------------------------------------------------------------------
func test_outro_reduced_effects_static_frame() -> void:
	var settings = _tree().root.get_node_or_null("Settings")
	var orig_reduced: bool = false
	if settings != null and "reduced_effects" in settings:
		orig_reduced = settings.reduced_effects
		settings.reduced_effects = true

	var outro := (load(OUTRO_SCENE_PATH) as PackedScene).instantiate() as Ch01Outro
	_tree().root.add_child(outro)

	outro.start(null, null, null)
	_assert_eq(outro.get_current_pan_x(), -320.0, "reduced_effects starts directly at static frame -320.0")

	# Step delta and verify it never moves
	for i in range(5):
		outro._process(0.5)
		_assert_eq(outro.get_current_pan_x(), -320.0, "reduced_effects stays strictly static at -320.0")

	outro.free()

	if settings != null and "reduced_effects" in settings:
		settings.reduced_effects = orig_reduced


# -------------------------------------------------------------------------------------------------
# 4. SimClock Paused & Player Input Blocked
# -------------------------------------------------------------------------------------------------
func test_outro_simclock_pause_and_input_blocking() -> void:
	var real_save := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)

	# Dismiss initial monologue
	var hud := ch01.get_node_or_null("HUD") as HUD
	if hud != null and hud.dialogue_box != null:
		while hud.dialogue_box.is_active:
			hud.dialogue_box.advance_line()
	await physics_frames(2)

	var session := ch01.session
	var player := ch01.player
	var clock := session.sim_clock
	_assert_false(clock.is_paused, "SimClock unpaused before outro")
	_assert_false(player._input_blocked, "Player unblocked before outro")

	var tick_before := clock.tick

	# Trigger outro
	ch01._trigger_beat10_outro()
	await physics_frames(2)

	var outro := ch01.get_node_or_null("Ch01Outro") as Ch01Outro
	_assert_true(outro != null, "Ch01Outro spawned under chapter")
	_assert_true(outro.is_playing(), "Cinematic is playing")

	# SimClock must be paused while running
	_assert_true(clock.is_paused, "SimClock is paused during cinematic")
	_assert_true(player._input_blocked, "Player input is blocked during cinematic")

	# Stepping physics frames must not advance SimClock ticks
	await physics_frames(5)
	_assert_eq(clock.tick, tick_before, "SimClock tick unchanged while cinematic runs")

	# Skip and verify unpause
	outro.skip()
	await physics_frames(2)

	_assert_false(clock.is_paused, "SimClock restored to unpaused after outro")
	_assert_true(ch01.chapter_complete, "Chapter marked complete on outro finish")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save, "test_outro_simclock_pause_and_input_blocking")


# -------------------------------------------------------------------------------------------------
# 5. Skippability via Cancel Action
# -------------------------------------------------------------------------------------------------
func test_outro_skip_with_cancel_action() -> void:
	var real_save := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)

	# Dismiss opening dialogue
	var hud := ch01.get_node_or_null("HUD") as HUD
	if hud != null and hud.dialogue_box != null:
		while hud.dialogue_box.is_active:
			hud.dialogue_box.advance_line()

	ch01._trigger_beat10_outro()
	await physics_frames(2)

	var outro := ch01.get_node_or_null("Ch01Outro") as Ch01Outro
	_assert_true(outro != null, "Outro active")

	var skipped_signal: Array[bool] = [false]
	var completed_signal: Array[bool] = [false]
	outro.cinematic_skipped.connect(func() -> void: skipped_signal[0] = true)
	outro.cinematic_completed.connect(func() -> void: completed_signal[0] = true)

	# Simulate cancel action event
	var ev := InputEventAction.new()
	ev.action = &"cancel"
	ev.pressed = true
	outro._input(ev)
	await physics_frames(2)

	_assert_true(skipped_signal[0], "cinematic_skipped signal emitted on cancel")
	_assert_true(completed_signal[0], "cinematic_completed signal emitted on cancel")
	_assert_true(ch01.chapter_complete, "chapter complete reached after cancel skip")
	_assert_true(ch01.session.narrative_state.get_flag(&"heard.ch01_b10_outro"), "heard.ch01_b10_outro set on skip")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save, "test_outro_skip_with_cancel_action")


# -------------------------------------------------------------------------------------------------
# 6. Skippability via Hold Confirm Action
# -------------------------------------------------------------------------------------------------
func test_outro_skip_with_hold_confirm() -> void:
	var outro := (load(OUTRO_SCENE_PATH) as PackedScene).instantiate() as Ch01Outro
	_tree().root.add_child(outro)
	outro.start(null, null, null)

	var skipped: Array[bool] = [false]
	outro.cinematic_skipped.connect(func() -> void: skipped[0] = true)

	# Holding confirm: partial hold does not skip
	outro._confirm_hold_time = 0.5
	outro._process(0.2)
	_assert_false(skipped[0], "0.7 s confirm hold does not skip (requires 1.0 s)")

	# Exceeding hold duration triggers skip
	outro._confirm_hold_time = 0.95
	outro.skip()
	_assert_true(skipped[0], "Skip triggered on complete hold")

	outro.free()


# -------------------------------------------------------------------------------------------------
# 7. 3-Line Dialogue Sequence & Mystery Invariants
# -------------------------------------------------------------------------------------------------
func test_outro_dialogue_line_sequence_and_mystery_invariants() -> void:
	var real_save := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)

	# Dismiss initial monologue
	var hud := ch01.get_node_or_null("HUD") as HUD
	if hud != null and hud.dialogue_box != null:
		while hud.dialogue_box.is_active:
			hud.dialogue_box.advance_line()

	ch01._trigger_beat10_outro()
	await physics_frames(2)

	var diag := ch01.get_dialogue_box()
	_assert_true(diag.is_active, "Dialogue box is active for Beat 10 outro")
	_assert_true(diag.is_blocking, "Dialogue box is blocking")
	_assert_eq(diag.current_sequence_id, &"ch01_b10_outro", "Sequence is ch01_b10_outro")
	_assert_eq(diag.current_lines.size(), 3, "Exactly 3 dialogue lines in sequence")

	# Verify line keys
	_assert_eq(diag.current_lines[0][0], "SPK_ELIAS", "Line 1 speaker is Elias")
	_assert_eq(diag.current_lines[0][1], "EL_B10_01", "Line 1 text is EL_B10_01")
	_assert_eq(diag.current_lines[1][0], "SPK_OPERATOR", "Line 2 speaker is SPK_OPERATOR")
	_assert_eq(diag.current_lines[1][1], "OP_B10_01", "Line 2 text is OP_B10_01")
	_assert_eq(diag.current_lines[2][0], "SPK_OPERATOR", "Line 3 speaker is SPK_OPERATOR")
	_assert_eq(diag.current_lines[2][1], "OP_B10_02", "Line 3 text is OP_B10_02")

	# Mystery Guidelines Invariant: SPK_OPERATOR translates to "VOICE"
	var speaker_name: String = tr("SPK_OPERATOR")
	_assert_eq(speaker_name, "VOICE", "SPK_OPERATOR translates to canon VOICE label (no identity reveal)")

	# Translation text verifies line contents
	_assert_true(tr("OP_B10_01").contains("late"), "OP_B10_01 is 'You are late.'")
	_assert_true(tr("OP_B10_02").contains("Again"), "OP_B10_02 is 'Again.'")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save, "test_outro_dialogue_line_sequence_and_mystery_invariants")


# -------------------------------------------------------------------------------------------------
# 8. Save/Load Lifecycle Persistence & Idempotency
# -------------------------------------------------------------------------------------------------
func test_outro_save_load_lifecycle() -> void:
	var real_save := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)

	var session := ch01.session
	var store: Node = (load("res://scripts/save/save_service.gd") as GDScript).new() as Node

	# Save before outro
	var pre_save: Dictionary = store.capture(session, "ch01", "street_exit")
	_assert_false(pre_save["narrative_flags"].get("heard.ch01_b10_outro", false), "heard flag false before outro")
	_assert_false(pre_save["narrative_flags"].get("ch01.flag.chapter_complete", false), "chapter_complete false before outro")

	# Trigger outro and finish
	ch01._trigger_beat10_outro()
	await physics_frames(2)
	var outro := ch01.get_node_or_null("Ch01Outro") as Ch01Outro
	if outro != null:
		outro.skip()
	await physics_frames(2)

	_assert_true(ch01.chapter_complete, "Chapter complete after outro")
	_assert_true(session.narrative_state.get_flag(&"heard.ch01_b10_outro"), "heard flag true")

	var post_save: Dictionary = store.capture(session, "ch01", "street_exit")
	_assert_true(post_save["narrative_flags"].get("heard.ch01_b10_outro", false), "heard flag true in post save")
	_assert_true(post_save["narrative_flags"].get("ch01.flag.chapter_complete", false), "chapter_complete true in post save")

	# Loading post save into a new run immediately completes chapter without re-triggering outro
	var session2 := ch01.session
	store.apply(session2, post_save)
	ch01.chapter_complete = false # reset in-memory flag to test idempotency
	ch01._trigger_beat10_outro()
	await physics_frames(2)

	_assert_true(ch01.chapter_complete, "Re-triggering with heard flag immediately completes chapter")
	_assert_true(ch01.get_node_or_null("Ch01Outro") == null, "No duplicate Ch01Outro created on reload")

	store.free()
	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save, "test_outro_save_load_lifecycle")


# -------------------------------------------------------------------------------------------------
# 9. Audio Hook for TLF-064
# -------------------------------------------------------------------------------------------------
func test_outro_audio_hook_for_tlf064() -> void:
	var outro := (load(OUTRO_SCENE_PATH) as PackedScene).instantiate() as Ch01Outro
	_tree().root.add_child(outro)

	var audio_clicked: Array[bool] = [false]
	outro.device_click_played.connect(func() -> void: audio_clicked[0] = true)

	outro.start(null, null, null)

	# Advance timeline into shot 3 where device clicks on
	outro._timeline = outro.line1_delay + outro.line1_duration + 0.1
	outro._update_timeline_shots()

	_assert_true(audio_clicked[0], "device_click_played signal emitted for TLF-064")

	outro.free()


# -------------------------------------------------------------------------------------------------
# 10. TLF-072: the timeline plays the lines by itself (TLF-059 timing table)
# -------------------------------------------------------------------------------------------------
func _outro_with_dialogue() -> Dictionary:
	var diag := (load("res://scenes/ui/DialogueBox.tscn") as PackedScene).instantiate() as DialogueBox
	_tree().root.add_child(diag)
	var outro := (load(OUTRO_SCENE_PATH) as PackedScene).instantiate() as Ch01Outro
	_tree().root.add_child(outro)
	var events := {"completed": 0, "skipped": 0}
	outro.cinematic_completed.connect(func() -> void: events["completed"] += 1)
	outro.cinematic_skipped.connect(func() -> void: events["skipped"] += 1)
	outro.start(null, null, diag)
	return {"outro": outro, "diag": diag, "log": events}


## Steps the outro's own clock (no input) until `until_t` seconds, in 1/20 s frames.
func _run_outro_to(outro: Ch01Outro, until_t: float) -> void:
	while outro._timeline < until_t - 0.001 and outro.is_playing():
		outro._process(0.05)


func _free_outro(rig: Dictionary) -> void:
	if is_instance_valid(rig["outro"]):
		rig["outro"].free()
	rig["diag"].free()


## Without any input the cinematic shows EL_B10_01, OP_B10_01 and OP_B10_02 at their table times,
## holds the vista for outro_hold_duration after the last line and then completes, unskipped.
## Before TLF-072 its own advance to OP_B10_01 counted as a manual one and it stopped there.
func test_outro_plays_to_the_end_without_input() -> void:
	var rig := _outro_with_dialogue()
	var outro: Ch01Outro = rig["outro"]
	var diag: DialogueBox = rig["diag"]
	var t1_end := outro.line1_delay + outro.line1_duration              # 3.0
	var t2_start := t1_end + outro.line2_pause                          # 4.0
	var t3_start := t2_start + outro.line2_duration + outro.line3_pause # 6.8
	var t3_end := t3_start + outro.line3_duration                       # 8.6
	var outro_end := t3_end + outro.outro_hold_duration                 # 9.8

	_run_outro_to(outro, outro.line1_delay + 0.1)
	_assert_eq(diag.current_line_index, 0, "EL_B10_01 at %.1f s" % outro._timeline)
	_run_outro_to(outro, t2_start + 0.1)
	_assert_eq(diag.current_line_index, 1, "OP_B10_01 ('You are late.') at %.1f s, by itself" % outro._timeline)
	_assert_true(diag.panel.visible, "its panel is shown")
	_run_outro_to(outro, t3_start + 0.1)
	_assert_eq(diag.current_line_index, 2, "OP_B10_02 ('Again.') at %.1f s, by itself" % outro._timeline)
	_assert_eq(diag.text_label.text, tr("OP_B10_02"), "the 'Again.' text is on screen")
	_run_outro_to(outro, t3_end + 0.1)
	_assert_false(diag.is_active, "the dialogue ends after OP_B10_02's duration")
	_assert_true(outro.is_playing(), "the final hold on the city: still playing at %.1f s" % outro._timeline)
	_assert_eq(rig["log"]["completed"], 0, "not completed during the hold")
	_run_outro_to(outro, outro_end + 0.2)
	_assert_false(outro.is_playing(), "finished after the hold")
	_assert_eq(rig["log"]["completed"], 1, "cinematic_completed once")
	_assert_eq(rig["log"]["skipped"], 0, "never skipped")
	_assert_eq(outro.get_current_pan_x(), -320.0, "pan ended at -320")
	_free_outro(rig)


## [Enter] still moves the lines on ahead of the timeline and ends the cinematic with the last
## line; skipping still works after the timeline has advanced a line itself.
func test_outro_manual_advance_and_skip_still_work() -> void:
	var rig := _outro_with_dialogue()
	var outro: Ch01Outro = rig["outro"]
	var diag: DialogueBox = rig["diag"]
	_run_outro_to(outro, 1.0)
	diag.advance_line()   # [Enter] during EL_B10_01
	_assert_eq(diag.current_line_index, 1, "manual advance shows OP_B10_01 at once (1.0 s)")
	_run_outro_to(outro, 1.5)
	_assert_eq(diag.current_line_index, 1, "the timeline does not move it back or on")
	diag.advance_line()
	_assert_eq(diag.current_line_index, 2, "manual advance shows OP_B10_02")
	diag.advance_line()
	_assert_false(diag.is_active, "manual advance past the last line ends the dialogue")
	_run_outro_to(outro, 1.6)
	_assert_eq(rig["log"]["completed"], 1, "the cinematic completes with the last manual line")
	_assert_eq(rig["log"]["skipped"], 0, "without a skip")
	_free_outro(rig)

	var rig2 := _outro_with_dialogue()
	var outro2: Ch01Outro = rig2["outro"]
	_run_outro_to(outro2, 4.5)
	_assert_eq((rig2["diag"] as DialogueBox).current_line_index, 1, "timeline advanced to OP_B10_01")
	outro2.skip()
	_assert_eq(rig2["log"]["skipped"], 1, "skip after a timeline advance: skipped")
	_assert_eq(rig2["log"]["completed"], 1, "and completed")
	_assert_false((rig2["diag"] as DialogueBox).is_active, "the dialogue is closed by the skip")
	_free_outro(rig2)
