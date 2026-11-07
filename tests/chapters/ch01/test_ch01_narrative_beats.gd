extends "res://tests/support/base_test.gd"

## Comprehensive Chapter 1 Narrative Beats Test Suite (TLF-032).
## Verifies all narrative beats from CH01_TEXT.md (Beats 01 to 10),
## one-shot flag persistence, duplicate journal prevention, 23:59 clocks,
## ASCII-only text localization, and real-save isolation.

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

	# Instantiate HUD so DialogueBox, DocumentViewer, JournalScreen are present
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


func _advance_all_dialogue(diag: DialogueBox) -> void:
	while diag != null and diag.is_active:
		diag.advance_line()


func test_beat01_platform_awakening_and_watch_pickup() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)

	var diag := ch01.get_dialogue_box()
	_assert_true(diag != null, "DialogueBox present in scene")
	_assert_true(diag.is_active, "Beat 01 awakening dialogue is active")
	_assert_false(diag.is_blocking, "Beat 01 monologue is non-blocking")
	_assert_eq(diag.auto_advance_delay, 4.0, "Beat 01 monologue auto-advances at 4.0s")
	_assert_eq(diag.current_sequence_id, &"ch01_b01_start", "sequence is ch01_b01_start")
	_assert_eq(diag.current_lines.size(), 3, "Beat 01 start has 3 lines (EL_B01_01..03)")

	_advance_all_dialogue(diag)
	_assert_false(diag.is_active, "dialogue inactive after advancing")
	_assert_true(ch01.session.narrative_state.get_flag(&"heard.ch01_b01_start"), "heard.ch01_b01_start recorded")

	# Re-triggering start does not replay
	ch01._trigger_beat01_start()
	_assert_false(diag.is_active, "Beat 01 does not replay when flag is set")

	# Pick up watch (global.pocket_watch)
	var watch_trigger: DialogueTrigger = null
	for child in ch01.room_router.current_room.get_children():
		if child is DialogueTrigger and child.object_id == &"global.pocket_watch":
			watch_trigger = child
			break
	_assert_true(watch_trigger != null, "pocket_watch_pickup trigger found")

	var fired := watch_trigger.trigger()
	_assert_true(fired, "watch trigger fired")
	_assert_true(diag.is_active, "Beat 01 watch dialogue is active")
	_assert_eq(diag.current_sequence_id, &"ch01_b01_watch", "sequence is ch01_b01_watch")
	_assert_eq(diag.current_lines.size(), 3, "watch line has 3 lines (MEM_WATCH_1, MEM_WATCH_2, EL_B01_04)")
	_assert_eq(diag.auto_advance_delay, 4.0, "watch pickup lines auto-advance at 4.0s")
	_assert_true(ch01.session.narrative_state.get_flag(&"ch01.flag.pocket_watch_acquired"), "pocket_watch_acquired flag set")
	_assert_true(ch01.session.narrative_state.get_flag(&"heard.ch01_b01_watch"), "heard.ch01_b01_watch flag set")

	_advance_all_dialogue(diag)

	# Second trigger fails because one_shot
	var fired_again := watch_trigger.trigger()
	_assert_false(fired_again, "watch trigger does not fire again")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat01_platform_awakening_and_watch_pickup")


func test_beat01_player_moves_immediately_and_dialogue_auto_advances() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(2)

	var player := ch01.player
	_assert_true(player != null, "Player exists in Chapter01")
	var initial_x := player.global_position.x

	var diag := ch01.get_dialogue_box()
	_assert_true(diag != null, "DialogueBox exists")
	_assert_true(diag.is_active, "Beat 01 is active")
	_assert_false(diag.is_blocking, "Beat 01 is non-blocking")

	# Move right for 8 physics frames (<= 10 frames), with NO interact press
	press(&"move_right")
	await physics_frames(8)
	release(&"move_right")
	await physics_frames(1)

	_assert_true(player.global_position.x > initial_x + 5.0, "Player moved right immediately without needing interact")

	# Advance lines via auto_advance or fast simulate
	var steps := 0
	while diag.is_active and steps < 20:
		steps += 1
		diag._process(diag.auto_advance_delay + 0.1)
		await physics_frames(1)

	_assert_false(diag.is_active, "Dialogue finished via auto-advance")
	_assert_true(ch01.session.narrative_state.get_flag(&"heard.ch01_b01_start"), "heard.ch01_b01_start is set")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat01_player_moves_immediately_and_dialogue_auto_advances")


func test_beat01_watch_pickup_real_input_interact_advance_and_unblock_wheel() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(5)

	var player := ch01.player
	var diag := ch01.get_dialogue_box()
	var wheel := ch01.find_child("AbilityWheel", true, false) as AbilityWheel
	_assert_true(player != null, "Player exists")
	_assert_true(diag != null, "DialogueBox exists")

	# Dismiss opening Beat 01 monologue if active
	if diag.is_active and diag.current_sequence_id == &"ch01_b01_start":
		_advance_all_dialogue(diag)
		await physics_frames(2)

	# Walk player to pocket watch pickup at (368, 168)
	var pickup_pos := Vector2(368, 168)
	var arrived := await walk_to(player, "pocket_watch_pickup", pickup_pos, func() -> bool:
		return player.current_target != null and player.current_target.object_id == &"global.pocket_watch"
	, 180)
	_assert_true(arrived, "Player walked to pocket watch pickup")

	# 1. Tap interact with real input to take watch
	await tap(&"interact", 2)
	await physics_frames(5)

	var acquired: bool = ch01.session.narrative_state.get_flag(&"ch01.flag.pocket_watch_acquired", false)
	_assert_true(acquired, "ch01.flag.pocket_watch_acquired set after interact tap")
	_assert_true(diag.is_active, "Watch pickup dialogue is active")
	_assert_eq(diag.current_sequence_id, &"ch01_b01_watch", "Sequence is ch01_b01_watch")
	_assert_eq(diag.auto_advance_delay, 4.0, "Watch pickup lines configured with auto_advance_delay = 4.0")
	_assert_eq(diag.current_line_index, 0, "Line 0 (MEM_WATCH_1) displayed")

	# 2. While watch dialogue is active, ability wheel cannot open
	if wheel != null:
		_assert_true(wheel._is_modal_open(), "Ability wheel detects active dialogue modal")
		press(&"ability_wheel")
		await physics_frames(2)
		_assert_false(wheel.is_open, "Ability wheel cannot open via real input while watch dialogue is displayed")
		release(&"ability_wheel")

	# 3. Real input: Tap interact advances line 0 -> line 1 (MEM_WATCH_2)
	await tap(&"interact", 2)
	await physics_frames(3)
	_assert_true(diag.is_active, "Dialogue remains active on line 1")
	_assert_eq(diag.current_line_index, 1, "Interact tap advanced to line 1 (MEM_WATCH_2)")

	# 4. Real input: Tap interact advances line 1 -> line 2 (EL_B01_04)
	await tap(&"interact", 2)
	await physics_frames(3)
	_assert_true(diag.is_active, "Dialogue remains active on line 2")
	_assert_eq(diag.current_line_index, 2, "Interact tap advanced to line 2 (EL_B01_04)")

	# 5. Real input: Tap interact on last line finishes dialogue sequence
	await tap(&"interact", 2)
	await physics_frames(3)
	_assert_false(diag.is_active, "Interact tap dismissed final watch line")

	# 6. Once dialogue cleared, ability wheel opens freely
	if wheel != null:
		_assert_false(wheel._is_modal_open(), "Modal priority cleared once dialogue closed")
		press(&"ability_wheel")
		_assert_true(await until(func(): return wheel.is_open, 30), "Ability wheel opens via real input after watch dialogue cleared")
		release(&"ability_wheel")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat01_watch_pickup_real_input_interact_advance_and_unblock_wheel")


func test_movement_hint_lifecycle() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(2)

	var hud: HUD = null
	for child in ch01.get_children():
		if child is HUD:
			hud = child
			break
	_assert_true(hud != null, "HUD found in Chapter01")

	# Advance 3 seconds without movement (180 frames at 60fps)
	for i in range(190):
		await physics_frames(1)

	# Movement hint should now be displayed
	_assert_true(ch01.session.narrative_state.get_flag(&"ch01.flag.movement_hint_shown"), "movement_hint_shown flag is set")
	_assert_true(hud.feedback_panel.visible, "Feedback panel is visible showing movement hint")
	_assert_true(hud.feedback_label.text.contains("Move:"), "Feedback label contains 'Move:'")

	# Move player: hint must disappear immediately
	press(&"move_right")
	await physics_frames(2)
	release(&"move_right")
	await physics_frames(1)
	_assert_false(hud.feedback_panel.visible, "Movement hint disappears immediately on player movement")

	# Test save and reload: hint must not show again
	var saved_flags = ch01.session.narrative_state.export_flags()
	_cleanup_ch01(ch01)

	var ch01_second := _make_ch01()
	ch01_second.session.narrative_state.import_state(saved_flags, [])
	await physics_frames(2)

	var hud2: HUD = null
	for child in ch01_second.get_children():
		if child is HUD:
			hud2 = child
			break

	# Advance another 3 seconds
	for i in range(190):
		await physics_frames(1)

	_assert_false(hud2.feedback_panel.visible, "Movement hint does not appear again after reload")

	_cleanup_ch01(ch01_second)
	_assert_real_save_unchanged(real_save_before, "test_movement_hint_lifecycle")


func test_beat03_call_box_09() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_all_dialogue(ch01.get_dialogue_box())

	ch01.room_router.enter_room(&"ch01.concourse_west", &"", &"ch01.concourse_west.safe_anchor_east")
	await physics_frames(2)

	var call_box: DialogueTrigger = null
	for child in ch01.room_router.current_room.get_children():
		if child is DialogueTrigger and child.object_id == &"ch01.concourse_west.call_box_09":
			call_box = child
			break
	_assert_true(call_box != null, "call_box_09 trigger found")

	var ok := call_box.trigger()
	_assert_true(ok, "call_box trigger fired")

	var diag := ch01.get_dialogue_box()
	_assert_true(diag.is_active, "call box dialogue active")
	_assert_eq(diag.current_sequence_id, &"ch01_b03_call_box", "sequence is ch01_b03_call_box")
	_assert_eq(diag.current_lines.size(), 6, "Beat 03 has 6 lines (OP_B03_01..03, EL_B03_01, OP_B03_04..05)")

	# Check journal added once
	var journal_entries := ch01.session.narrative_state.get_journal()
	var op_found := false
	var op_count := 0
	for entry in journal_entries:
		if entry.get("key") == "JRN_CH1_OPERATOR":
			op_found = true
			op_count += 1
			_assert_eq(entry.get("category"), "observation", "JRN_CH1_OPERATOR is observation")
	_assert_true(op_found, "JRN_CH1_OPERATOR journal entry present")
	_assert_eq(op_count, 1, "JRN_CH1_OPERATOR added exactly once")

	_advance_all_dialogue(diag)

	# Second trigger rejected
	var ok2 := call_box.trigger()
	_assert_false(ok2, "call_box trigger does not fire twice")
	_assert_eq(ch01.session.narrative_state.get_journal().size(), journal_entries.size(), "journal entry not duplicated")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat03_call_box_09")


func test_beat05_security_crossing_pa_speaker_echo() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_all_dialogue(ch01.get_dialogue_box())

	ch01.room_router.enter_room(&"ch01.security_crossing", &"", &"ch01.security_crossing.safe_anchor_west")
	await physics_frames(2)

	# Simulate echo entering PLAYING state (3)
	ch01._on_echo_state_changed(3)

	var diag := ch01.get_dialogue_box()
	_assert_true(diag.is_active, "Beat 05 PA speaker dialogue active")
	_assert_eq(diag.current_sequence_id, &"ch01_b05_echo", "sequence is ch01_b05_echo")
	_assert_eq(diag.current_lines.size(), 2, "Beat 05 has 2 lines (OP_B05_01, EL_B05_01)")
	_assert_true(ch01.session.narrative_state.get_flag(&"heard.ch01_b05_echo"), "heard.ch01_b05_echo flag set")

	_advance_all_dialogue(diag)

	# Subsequent echo state change does not replay
	ch01._on_echo_state_changed(3)
	_assert_false(diag.is_active, "Beat 05 does not replay on second echo playback")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat05_security_crossing_pa_speaker_echo")


func test_beat06_waiting_lounge_trace_bench_and_mira_audio() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_all_dialogue(ch01.get_dialogue_box())

	ch01.room_router.enter_room(&"ch01.waiting_lounge", &"", &"ch01.waiting_lounge.safe_anchor_west")
	await physics_frames(2)

	var trace_bench: DialogueTrigger = null
	for child in ch01.room_router.current_room.get_children():
		if child is DialogueTrigger and child.object_id == &"ch01.waiting_lounge.trace_bench":
			trace_bench = child
			break
	_assert_true(trace_bench != null, "trace_bench found in waiting lounge")
	_assert_true(trace_bench.traceable, "trace_bench is traceable")

	# Trace bench
	var ok := trace_bench.trigger()
	_assert_true(ok, "trace_bench triggered")

	var diag := ch01.get_dialogue_box()
	_assert_true(diag.is_active, "Beat 06 trace dialogue active")
	_assert_eq(diag.current_sequence_id, &"ch01_b06_bench", "sequence is ch01_b06_bench")
	_assert_eq(diag.current_lines.size(), 1, "Beat 06 trace has 1 line (EL_B06_01)")

	# Journal entry
	var sil_found := false
	for entry in ch01.session.narrative_state.get_journal():
		if entry.get("key") == "JRN_CH1_TWO_SILHOUETTES":
			sil_found = true
			_assert_eq(entry.get("category"), "observation", "JRN_CH1_TWO_SILHOUETTES is observation")
	_assert_true(sil_found, "JRN_CH1_TWO_SILHOUETTES present in journal")

	_advance_all_dialogue(diag)

	# Audio log reading reaction (EL_B06_02)
	var audio_doc := load("res://data/documents/ch01/audio_mira_01.tres") as DocumentDef
	_assert_true(audio_doc != null, "audio_mira_01 doc loaded")

	var viewer := ch01.get_document_viewer()
	_assert_true(viewer != null, "DocumentViewer present")
	viewer.open_document(audio_doc)
	viewer.close_document()

	_assert_true(diag.is_active, "Beat 06 Mira reaction active after closing audio doc")
	_assert_eq(diag.current_sequence_id, &"ch01_b06_mira_reaction", "sequence is ch01_b06_mira_reaction")
	_assert_eq(diag.current_lines.size(), 1, "Beat 06 reaction has 1 line (EL_B06_02)")
	_assert_true(ch01.session.narrative_state.get_flag(&"heard.ch01_b06_mira_reaction"), "heard.ch01_b06_mira_reaction flag set")

	_advance_all_dialogue(diag)

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat06_waiting_lounge_trace_bench_and_mira_audio")


func test_beat07_signal_control_intercom_warning_once() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_all_dialogue(ch01.get_dialogue_box())

	ch01.room_router.enter_room(&"ch01.signal_control", &"", &"ch01.signal_control.safe_anchor_west")
	await physics_frames(2)

	var intercom: SignalControlIntercom = null
	for child in ch01.room_router.current_room.get_children():
		if child is SignalControlIntercom:
			intercom = child
			break
	_assert_true(intercom != null, "SignalControlIntercom found in signal_control")

	# Solve CH1-PZ-004
	ch01.session.puzzle_service.mark_solved(&"CH1-PZ-004")

	var diag := ch01.get_dialogue_box()
	_assert_true(diag.is_active, "Beat 07 intercom dialogue active")
	_assert_eq(diag.current_sequence_id, &"ch01_b07_intercom", "sequence is ch01_b07_intercom")
	_assert_eq(diag.current_lines.size(), 2, "Beat 07 has 2 lines (OP_B07_01, OP_B07_02)")

	# Journal entry added exactly once (theory)
	var warn_count := 0
	for entry in ch01.session.narrative_state.get_journal():
		if entry.get("key") == "JRN_CH1_OPERATOR_WARNING":
			warn_count += 1
			_assert_eq(entry.get("category"), "theory", "JRN_CH1_OPERATOR_WARNING is theory")
	_assert_eq(warn_count, 1, "JRN_CH1_OPERATOR_WARNING added exactly once (no duplicates)")

	_advance_all_dialogue(diag)

	# Triggering warning again does nothing
	intercom.trigger_warning()
	_assert_false(diag.is_active, "intercom does not replay warning")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat07_signal_control_intercom_warning_once")


func test_beat08_upper_vestibule_loop_detection() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_all_dialogue(ch01.get_dialogue_box())

	ch01.room_router.enter_room(&"ch01.upper_vestibule", &"", &"ch01.upper_vestibule.safe_anchor_west")
	await physics_frames(2)

	# Simulate door_north looping to door_west
	ch01._on_upper_vestibule_door_traversed(&"player", {
		"room_id": &"ch01.upper_vestibule",
		"door_id": &"door_west"
	})

	var diag := ch01.get_dialogue_box()
	_assert_true(diag.is_active, "Beat 08 loop dialogue active")
	_assert_eq(diag.current_sequence_id, &"ch01_b08_loop", "sequence is ch01_b08_loop")
	_assert_eq(diag.current_lines.size(), 1, "Beat 08 has 1 line (EL_B08_01)")
	_assert_true(ch01.session.narrative_state.get_flag(&"heard.ch01_b08_loop"), "heard.ch01_b08_loop flag set")

	_advance_all_dialogue(diag)

	# Second loop traverse does not replay
	ch01._on_upper_vestibule_door_traversed(&"player", {
		"room_id": &"ch01.upper_vestibule",
		"door_id": &"door_west"
	})
	_assert_false(diag.is_active, "Beat 08 does not replay on second loop traverse")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat08_upper_vestibule_loop_detection")


func test_beat09_dispatch_terminal_revelation() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_all_dialogue(ch01.get_dialogue_box())

	ch01.room_router.enter_room(&"ch01.station_atrium", &"", &"ch01.station_atrium.safe_anchor_south")
	await physics_frames(2)

	var doc := load("res://data/documents/ch01/dispatch_terminal.tres") as DocumentDef
	_assert_true(doc != null, "dispatch_terminal doc loaded")

	var viewer := ch01.get_document_viewer()
	viewer.open_document(doc)
	viewer.next_page() # Advance to page 2 (revelation trigger)
	viewer.close_document()

	var diag := ch01.get_dialogue_box()
	_assert_true(diag.is_active, "Beat 09 revelation dialogue active")
	_assert_true(diag.is_blocking, "Beat 09 revelation is blocking")
	_assert_eq(diag.current_sequence_id, &"ch01_b09_revelation", "sequence is ch01_b09_revelation")
	_assert_eq(diag.current_lines.size(), 4, "Beat 09 has 4 lines (EL_B09_01..04)")
	_assert_true(ch01.session.narrative_state.get_flag(&"heard.ch01_b09_revelation"), "heard.ch01_b09_revelation flag set")

	# Journal entry
	var rep_found := false
	for entry in ch01.session.narrative_state.get_journal():
		if entry.get("key") == "JRN_CH1_REPEATS":
			rep_found = true
			_assert_eq(entry.get("category"), "theory", "JRN_CH1_REPEATS is theory")
	_assert_true(rep_found, "JRN_CH1_REPEATS added to journal")

	_advance_all_dialogue(diag)

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat09_dispatch_terminal_revelation")


func test_beat10_outro_and_chapter_complete() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_all_dialogue(ch01.get_dialogue_box())

	ch01.room_router.enter_room(&"ch01.street_exit", &"", &"ch01.street_exit.safe_anchor_south")
	await physics_frames(2)

	# Trigger outro
	ch01.session.interaction_service.trigger_enter(&"player", &"ch01.street_exit.trigger_outro")

	var diag := ch01.get_dialogue_box()
	_assert_true(diag.is_active, "Beat 10 outro dialogue active")
	_assert_true(diag.is_blocking, "Beat 10 outro is blocking")
	_assert_eq(diag.current_sequence_id, &"ch01_b10_outro", "sequence is ch01_b10_outro")
	_assert_eq(diag.current_lines.size(), 3, "Beat 10 has 3 lines (EL_B10_01, OP_B10_01, OP_B10_02)")
	_assert_false(ch01.chapter_complete, "chapter complete not yet set before monologue completes")

	_advance_all_dialogue(diag)

	_assert_true(ch01.chapter_complete, "chapter_complete marked true after dialogue completes")
	_assert_true(ch01.session.narrative_state.get_flag(&"ch01.flag.chapter_complete"), "chapter_complete flag set")

	var overlay := ch01.get_node_or_null("ChapterCompleteOverlay") as CanvasLayer
	_assert_true(overlay != null, "ChapterCompleteOverlay created")
	var title_lbl := overlay.find_child("TitleLabel", true, false) as Label
	_assert_true(title_lbl != null, "TitleLabel found on overlay")
	_assert_true(title_lbl.text.contains(tr("UI_CHAPTER_COMPLETE")), "TitleLabel contains localized UI_CHAPTER_COMPLETE")
	_assert_true(title_lbl.text.contains(tr("UI_CHAPTER_01_TITLE")), "TitleLabel contains localized UI_CHAPTER_01_TITLE")

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_beat10_outro_and_chapter_complete")


func test_clocks_2359_are_reusable() -> void:
	var real_save_before := _record_real_save_state()
	var ch01 := _make_ch01()
	await physics_frames(3)
	_advance_all_dialogue(ch01.get_dialogue_box())

	var clock: DialogueTrigger = null
	for child in ch01.room_router.current_room.get_children():
		if child is DialogueTrigger and child.object_id == &"ch01.arrival_platform.digital_clock_2359":
			clock = child
			break
	_assert_true(clock != null, "digital_clock_2359 trigger found in arrival_platform")
	_assert_false(clock.one_shot, "clock is reusable (one_shot = false)")

	# First trigger
	var ok1 := clock.trigger()
	_assert_true(ok1, "clock first trigger succeeds")
	var diag := ch01.get_dialogue_box()
	_assert_true(diag.is_active, "clock dialogue active")
	_assert_eq(diag.current_lines.size(), 1, "clock has 1 line")
	_assert_eq(diag.current_lines[0][1], "EL_CLOCK_2359", "line is EL_CLOCK_2359")
	_advance_all_dialogue(diag)

	# Second trigger (reusable!)
	var ok2 := clock.trigger()
	_assert_true(ok2, "clock second trigger succeeds")
	_assert_true(diag.is_active, "clock dialogue active again")
	_advance_all_dialogue(diag)

	_cleanup_ch01(ch01)
	_assert_real_save_unchanged(real_save_before, "test_clocks_2359_are_reusable")


func test_all_narrative_text_keys_localized_and_ascii() -> void:
	var all_keys := [
		"EL_B01_01", "EL_B01_02", "EL_B01_03", "EL_B01_04",
		"OP_B03_01", "OP_B03_02", "OP_B03_03", "EL_B03_01", "OP_B03_04", "OP_B03_05",
		"OP_B05_01", "EL_B05_01",
		"EL_B06_01", "EL_B06_02",
		"OP_B07_01", "OP_B07_02",
		"EL_B08_01",
		"EL_B09_01", "EL_B09_02", "EL_B09_03", "EL_B09_04",
		"EL_B10_01", "OP_B10_01", "OP_B10_02",
		"EL_CLOCK_2359",
		"SPK_ELIAS", "SPK_OPERATOR", "SPK_MIRA",
		"JRN_CH1_OPERATOR", "JRN_CH1_TWO_SILHOUETTES", "JRN_CH1_OPERATOR_WARNING", "JRN_CH1_REPEATS",
		"UI_CHAPTER_COMPLETE", "UI_CHAPTER_01_TITLE",
	]

	for key in all_keys:
		var localized := tr(key)
		_assert_true(localized != key, "Key '%s' resolves to localized text (not raw key)" % key)
		for c in localized:
			var code := c.unicode_at(0)
			_assert_true(code >= 0 and code <= 127, "Text for key '%s' is pure ASCII (code %d for '%s')" % [key, code, c])
