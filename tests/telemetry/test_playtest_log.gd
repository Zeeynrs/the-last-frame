extends "res://tests/support/base_test.gd"

## Playtest telemetry (TLF-048): PlaytestLog times per room and puzzle on SimClock ticks, pauses
## counted separately, the log survives save/load (save v2), the JSON goes to the headless folder in
## tests (never user://saves), and `tlf/playtest_log` off means no log, no file, no summary.
## Every test points the SaveService autoload at its own test root (ISSUE-016, TLF-036).

const CH01_SCENE := "res://scenes/chapters/ch01/Chapter01.tscn"
## The TLF-030 real-input route through rooms 1-4 (arrival -> security crossing -> lounge door).
const ROUTE_SCRIPT := "res://tests/chapters/ch01/test_ch01_real_playthrough.gd"
const TEST_SAVE_ROOT := "user://tlf_test_playtest_saves"
const SLOT := 0
const CONCOURSE := &"ch01.concourse_west"
const PZ1 := "CH1-PZ-001"

var _store: SaveStore = null
var _original_root: String = ""


func _init() -> void:
	timeout_frames = 3600


func _begin(root: String = TEST_SAVE_ROOT) -> void:
	_store = _tree().root.get_node("SaveService") as SaveStore
	_original_root = _store.save_root
	_store.save_root = root
	_remove_dir_files(root)


func _end(root: String = TEST_SAVE_ROOT) -> void:
	release_all_input()
	_tree().paused = false
	_store.save_root = _original_root
	_remove_dir_files(root)
	_assert_false(DirAccess.dir_exists_absolute(root), "test save root removed")


func _remove_dir_files(root: String) -> void:
	var dir := DirAccess.open(root)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	if DirAccess.dir_exists_absolute(root):
		DirAccess.remove_absolute(root)


func _add_chapter() -> Node2D:
	var ch01 := (load(CH01_SCENE) as PackedScene).instantiate() as Node2D
	_tree().root.add_child(ch01)
	return ch01


func _free_chapter(ch01: Node) -> void:
	if ch01 == null or not is_instance_valid(ch01):
		return
	var router := ch01.get_node("RoomRouter") as RoomRouter
	if router.current_room != null:
		router._unload_current()
	if ch01.get_parent() != null:
		ch01.get_parent().remove_child(ch01)
	ch01.free()


func _log_of(ch01: Node) -> PlaytestLog:
	return (ch01.get_node("GameSession") as GameSession).playtest_log


func _diag() -> DialogueBox:
	return _tree().root.find_child("DialogueBox", true, false) as DialogueBox


func _blocking_dialogue() -> bool:
	var diag := _diag()
	return diag != null and diag.is_active and diag.is_blocking


func _json_files(dir_path: String) -> PackedStringArray:
	var dir := DirAccess.open(dir_path)
	return dir.get_files() if dir != null else PackedStringArray()


func _headless_default() -> bool:
	return OS.get_environment(SaveStore.ALLOW_REAL_USER_DATA_ENV) != "1"


# --- flag and paths ------------------------------------------------------------------------

func test_flag_defaults_on_in_debug_off_in_export_and_output_paths() -> void:
	_assert_eq(ProjectSettings.get_setting(PlaytestLog.SETTING), false, "base value (exports) is false")
	_assert_true(ProjectSettings.has_setting(PlaytestLog.SETTING + ".debug"), "debug override exists")
	_assert_eq(ProjectSettings.get_setting(PlaytestLog.SETTING + ".debug"), true, "debug builds: true")
	_assert_eq(PlaytestLog.is_enabled(), OS.is_debug_build(), "enabled == debug build (this run: %s)" % OS.is_debug_build())
	_assert_eq(PlaytestLog.resolve_output_dir("headless", ""), "user://headless/playtest", "headless -> user://headless/playtest")
	_assert_eq(PlaytestLog.resolve_output_dir("headless", "1"), "user://playtest", "override -> user://playtest")
	_assert_eq(PlaytestLog.resolve_output_dir("Windows", ""), "user://playtest", "windowed -> user://playtest")
	for dir_path in [PlaytestLog.DEFAULT_DIR, PlaytestLog.HEADLESS_DIR]:
		_assert_false(dir_path.begins_with(SaveStore.DEFAULT_ROOT) or dir_path.begins_with(SaveStore.HEADLESS_ROOT),
			"%s is not a save folder" % dir_path)
		_assert_false(dir_path.contains("settings"), "%s is not the settings file" % dir_path)
	var log := PlaytestLog.new()
	if _headless_default():
		_assert_eq(log.output_dir, PlaytestLog.HEADLESS_DIR, "this headless run writes to user://headless/playtest")
	log.free()


# --- times against a real-input run --------------------------------------------------------

func test_real_input_rooms_1_to_4_times_match_the_sim_clock() -> void:
	var route = load(ROUTE_SCRIPT).new()
	route.assert_helper = assert_helper
	route.scene_tree = scene_tree
	_begin(route.TEST_SAVE_ROOT)
	route._start_chapter()
	var session: GameSession = route._session
	var router: RoomRouter = route._router
	var clock := session.sim_clock
	var log := session.playtest_log
	if not _assert_true(log != null, "PlaytestLog created for the chapter (flag on in debug)"):
		route._stop_chapter()
		_end(route.TEST_SAVE_ROOT)
		return
	_assert_eq(clock.tick, 0, "chapter starts at tick 0 (arrival entered on tick 0)")

	# Independent bookkeeping on the same SimClock: room entries, solves, blocking-dialogue ticks.
	var entries: Array = [[String(router.current_room_id), clock.tick]]
	var solved: Dictionary = {}
	var room_ticks: Dictionary = {}
	var room_dialogue: Dictionary = {}
	var on_enter := func(room_id: StringName) -> void: entries.append([String(room_id), clock.tick])
	var on_solved := func(puzzle_id: StringName, tick: int) -> void: solved[String(puzzle_id)] = tick
	var on_tick := func(_tick: int) -> void:
		var room := String(router.current_room_id)
		room_ticks[room] = int(room_ticks.get(room, 0)) + 1
		if _blocking_dialogue():
			room_dialogue[room] = int(room_dialogue.get(room, 0)) + 1
	router.room_entered.connect(on_enter)
	session.puzzle_service.puzzle_solved.connect(on_solved)
	clock.tick_advanced.connect(on_tick)

	await route._play()

	clock.tick_advanced.disconnect(on_tick)
	var now := clock.tick
	_assert_eq(log.active_ticks + int(log.paused["dialogue"]) + int(log.paused["unfocused"]), now,
		"every SimClock tick is either active or a running pause (%d ticks)" % now)
	_assert_eq(int(log.paused["unfocused"]), 0, "headless: never unfocused")

	# Visits, in order, with tick spans from the router's own room_entered.
	var all_visits: Array = log.visits.duplicate()
	all_visits.append(log.current_visit)
	_assert_eq(all_visits.size(), entries.size(), "one visit per room entry")
	var active_sum := 0
	for i in mini(all_visits.size(), entries.size()):
		var visit: Dictionary = all_visits[i]
		var end_tick: int = entries[i + 1][1] if i + 1 < entries.size() else now
		_assert_eq(visit["room"], entries[i][0], "visit %d is %s" % [i, entries[i][0]])
		_assert_eq(visit["ticks"], end_tick - entries[i][1], "visit %d (%s) ticks == SimClock span" % [i, visit["room"]])
		active_sum += int(visit["active_ticks"])
	_assert_eq(active_sum, log.active_ticks, "visit active ticks add up to the total")
	for room in room_ticks.keys():
		_assert_eq(log.rooms[room]["ticks"], room_ticks[room], "%s: ticks" % room)
		_assert_eq(log.rooms[room]["active_ticks"], room_ticks[room] - int(room_dialogue.get(room, 0)),
			"%s: active = ticks - blocking dialogue" % room)

	# Puzzles: first entry into the puzzle's room -> SOLVED.
	var rooms_of := {"CH1-PZ-001": "ch01.concourse_west", "CH1-PZ-002": "ch01.maintenance_bay", "CH1-PZ-003": "ch01.security_crossing"}
	var tps := float(Engine.physics_ticks_per_second)
	var info := PackedStringArray()
	for id in rooms_of.keys():
		var puzzle: Dictionary = log.puzzles.get(id, {})
		if not _assert_true(not puzzle.is_empty() and solved.has(id), "%s measured and solved" % id):
			continue
		var entry_tick := -1
		for e in entries:
			if e[0] == rooms_of[id]:
				entry_tick = e[1]
				break
		_assert_eq(puzzle["state"], PlaytestLog.SOLVED, "%s SOLVED in the log" % id)
		_assert_eq(puzzle["room"], rooms_of[id], "%s room from its PuzzleDef" % id)
		_assert_eq(puzzle["ticks"], solved[id] - entry_tick, "%s ticks == solve tick - room entry tick" % id)
		_assert_eq(puzzle["active_ticks"] + puzzle["paused_ticks"], puzzle["ticks"], "%s: active + paused == span" % id)
		_assert_eq(puzzle["hints"], {"1": 0, "2": 0, "3": 0}, "%s: no hints on the scripted route" % id)
		_assert_eq(puzzle["echo_resets"], 0, "%s: no echo resets" % id)
		info.append("%s %.2f s (%d ticks)" % [id, puzzle["active_ticks"] / tps, puzzle["active_ticks"]])
	for room in log.rooms.keys():
		info.append("%s %.2f s" % [room, log.rooms[room]["active_ticks"] / tps])
	print("  INFO: playtest log of the TLF-030 route: total %.2f s active, %d dialogue ticks; %s" % [
		log.active_ticks / tps, log.paused["dialogue"], "; ".join(info)])
	_assert_eq(log.failures, {}, "no failed interactions on the scripted route")

	route._stop_chapter()
	route.release_all_input()
	_end(route.TEST_SAVE_ROOT)


# --- pauses ----------------------------------------------------------------------------------

func test_pauses_are_counted_separately_not_as_puzzle_time() -> void:
	_begin()
	var ch01 := _add_chapter()
	var session := ch01.get_node("GameSession") as GameSession
	var router := ch01.get_node("RoomRouter") as RoomRouter
	var log := session.playtest_log
	if not _assert_true(log != null, "log present"):
		_free_chapter(ch01)
		_end()
		return
	await physics_frames(2)
	await dismiss_blocking_ui()
	router.enter_room(CONCOURSE)
	await physics_frames(3)
	var puzzle: Dictionary = log.puzzles[PZ1]
	_assert_eq(puzzle["state"], PlaytestLog.ACTIVE, "PZ-001 starts on entering the concourse")

	# Journal (real input): the SimClock stops, the log counts journal frames instead.
	var active_before := log.active_ticks
	var puzzle_before: int = puzzle["active_ticks"]
	var tick_before := session.sim_clock.tick
	await tap(&"journal")
	_assert_true(session.sim_clock.is_paused, "journal pauses the SimClock")
	var journal_before := int(log.paused["journal"])
	await physics_frames(40)
	_assert_true(int(log.paused["journal"]) - journal_before >= 39, "journal frames counted (%d)" % (int(log.paused["journal"]) - journal_before))
	await tap(&"cancel")
	_assert_false(session.sim_clock.is_paused, "journal closed")
	var run_ticks := session.sim_clock.tick - tick_before
	_assert_eq(log.active_ticks - active_before, run_ticks, "only ticks outside the journal are active")
	_assert_eq(puzzle["active_ticks"] - puzzle_before, run_ticks, "puzzle time excludes the journal")

	# Blocking dialogue: ticks run, but they are dialogue pause.
	active_before = log.active_ticks
	var dialogue_before := int(log.paused["dialogue"])
	_diag().play_sequence(&"tlf048_test_pause", [["SPK_ELIAS", "EL_B01_01"]], true, 0.0, false)
	tick_before = session.sim_clock.tick
	await physics_frames(30)
	var dialogue_ticks := session.sim_clock.tick - tick_before
	_assert_true(dialogue_ticks >= 30, "ticks keep running under dialogue")
	_assert_eq(int(log.paused["dialogue"]) - dialogue_before, dialogue_ticks, "dialogue ticks counted as pause")
	_assert_eq(log.active_ticks, active_before, "no active time while the dialogue blocks")
	await dismiss_blocking_ui()

	# Game pause (SceneTree.paused): neither the SimClock nor the puzzle time moves.
	active_before = log.active_ticks
	tick_before = session.sim_clock.tick
	var game_before := int(log.paused["game"])
	_tree().paused = true
	await physics_frames(20)
	_tree().paused = false
	_assert_eq(session.sim_clock.tick, tick_before, "paused tree: no ticks")
	_assert_true(int(log.paused["game"]) - game_before >= 19, "game pause frames counted (%d)" % (int(log.paused["game"]) - game_before))
	_assert_eq(log.active_ticks, active_before, "no active time while the game is paused")
	# Puzzle ticks are SimClock ticks (active + dialogue); its pause also holds the frames the clock
	# stood still (journal, game). All of those happened after PZ-001 started.
	var stopped := int(log.paused["journal"]) + int(log.paused["game"]) + int(log.paused["document"]) + int(log.paused["other"])
	_assert_eq(puzzle["active_ticks"] + puzzle["paused_ticks"], puzzle["ticks"] + stopped,
		"puzzle: active + paused == ticks + frames the SimClock stood still")

	_free_chapter(ch01)
	_end()


# --- hints, resets, failures -----------------------------------------------------------------

func test_hints_resets_and_failures_are_counted_per_puzzle() -> void:
	_begin()
	var ch01 := _add_chapter()
	var session := ch01.get_node("GameSession") as GameSession
	var router := ch01.get_node("RoomRouter") as RoomRouter
	var log := session.playtest_log
	if not _assert_true(log != null, "log present"):
		_free_chapter(ch01)
		_end()
		return
	await physics_frames(2)
	await dismiss_blocking_ui()
	router.enter_room(CONCOURSE)
	await physics_frames(3)
	var puzzle: Dictionary = log.puzzles[PZ1]

	await tap(&"hint")
	_assert_eq(puzzle["hints"]["1"], 1, "hint button (real input) -> level 1 counted for PZ-001")
	await tap(&"hint")
	_assert_eq(puzzle["hints"]["1"], 2, "a re-shown level counts as another request at that level")
	session.sim_clock.step(session.hint_service.escalation_cooldown_ticks)
	await tap(&"hint")
	_assert_eq(puzzle["hints"]["2"], 1, "escalated -> level 2")
	_assert_eq(log.hints, {"1": 2, "2": 1, "3": 0}, "chapter hint totals")

	await tap(&"echo_reset")
	_assert_eq(log.echo_resets, 1, "echo_reset press (real input) counted")
	_assert_eq(puzzle["echo_resets"], 1, "and attributed to the room's puzzle")

	session.puzzle_service.reset_puzzle(StringName(PZ1))
	_assert_eq(puzzle["resets"], 1, "reset anchor counted")

	session.interaction_service.request(&"player", &"ch01.concourse_west.no_such_object", &"use")
	session.interaction_service.request(&"echo.0", &"ch01.concourse_west.no_such_object", &"use")
	_assert_eq(log.failures.get("missing_target", 0), 1, "player failure counted by reason; echo actor ignored")
	_assert_eq(puzzle["failures"].get("missing_target", 0), 1, "failure attributed to PZ-001")
	var watch := (ch01.get_node("Player") as Player).pocket_watch
	watch.watch_used.emit(&"echo", &"echo.0", InteractionResult.failure(&"echo_busy"))
	_assert_eq(log.failures.get("echo_busy", 0), 1, "Echo watch failure (no InteractionService) counted")

	_free_chapter(ch01)
	_end()


# --- save / load -------------------------------------------------------------------------------

func test_save_and_continue_keep_the_log() -> void:
	_begin()
	var ch01 := _add_chapter()
	var session := ch01.get_node("GameSession") as GameSession
	var router := ch01.get_node("RoomRouter") as RoomRouter
	var log := session.playtest_log
	if not _assert_true(log != null, "log present"):
		_free_chapter(ch01)
		_end()
		return
	await physics_frames(2)
	await dismiss_blocking_ui()
	router.enter_room(CONCOURSE)
	await physics_frames(30)
	await tap(&"hint")
	var saved_state := log.export_state()
	_assert_eq(_store.write_slot(SLOT, router.capture_save("ch01.cp.concourse_west")), OK, "save written")
	_free_chapter(ch01)

	var read := _store.read_slot(SLOT)
	_assert_true(read.get("ok", false), "save reads back")
	_assert_eq(read["data"]["save_version"], SaveStore.SAVE_VERSION, "current save version")
	_assert_eq(read["data"]["playtest"], saved_state, "playtest state round-trips through the save file")

	# Continue through the real path: SceneRouter -> Chapter01 restore hook.
	var scene_router := _tree().root.get_node("SceneRouter")
	scene_router.start_chapter(CH01_SCENE, SLOT)
	var ok := await until(func() -> bool:
		var scene := _tree().current_scene
		return scene != null and scene.scene_file_path == CH01_SCENE and scene.is_node_ready(), 30)
	if _assert_true(ok, "Continue loaded Chapter01"):
		var restored := _log_of(_tree().current_scene)
		_assert_eq(restored.sessions, 2, "second session of the same log")
		_assert_eq(restored.run_id, saved_state["run_id"], "same run")
		_assert_eq(restored.rooms["ch01.arrival_platform"], saved_state["rooms"]["ch01.arrival_platform"], "arrival room time kept")
		_assert_eq(restored.puzzles[PZ1]["hints"]["1"], 1, "hint count kept")
		_assert_eq(restored.puzzles[PZ1]["state"], PlaytestLog.ACTIVE, "PZ-001 still being measured")
		_assert_true(restored.visits.back().get("interrupted", false), "the visit in progress at save time is closed as interrupted")
		_assert_eq(restored.current_visit.get("room", ""), String(CONCOURSE), "a new concourse visit after loading")
		await physics_frames(10)
		var since := restored.active_ticks - int(saved_state["active_ticks"])
		_assert_true(since > 0, "measuring continues after Continue")
		_assert_eq(restored.puzzles[PZ1]["active_ticks"] - int(saved_state["puzzles"][PZ1]["active_ticks"]), since,
			"PZ-001 time continues from the saved value")
	_tree().unload_current_scene()
	await physics_frames(2)
	scene_router.consume_pending_restore()
	_end()


func test_continue_from_a_v1_save_marks_solved_puzzles_untracked() -> void:
	_begin()
	# A save as written before TLF-048 (v1, no "playtest"), at the bay checkpoint with PZ-001 solved.
	var ch01 := _add_chapter()
	var router := ch01.get_node("RoomRouter") as RoomRouter
	var session := ch01.get_node("GameSession") as GameSession
	session.puzzle_service.mark_solved(StringName(PZ1))
	router.enter_room(&"ch01.maintenance_bay")
	var v1 := router.capture_save("ch01.cp.maintenance_bay")
	_free_chapter(ch01)
	v1.erase("playtest")
	v1["save_version"] = 1
	DirAccess.make_dir_recursive_absolute(TEST_SAVE_ROOT)
	var file := FileAccess.open(_store.slot_path(SLOT), FileAccess.WRITE)
	file.store_string(JSON.stringify(JSON.from_native(v1), "\t"))
	file.close()

	var scene_router := _tree().root.get_node("SceneRouter")
	scene_router.start_chapter(CH01_SCENE, SLOT)
	var ok := await until(func() -> bool:
		var scene := _tree().current_scene
		return scene != null and scene.scene_file_path == CH01_SCENE and scene.is_node_ready(), 30)
	if _assert_true(ok, "Continue from the v1 save"):
		var scene := _tree().current_scene
		_assert_eq((scene.get_node("RoomRouter") as RoomRouter).current_room_id, &"ch01.maintenance_bay", "v1 save restored (migrated)")
		var log := _log_of(scene)
		_assert_eq(log.puzzles[PZ1]["state"], PlaytestLog.UNTRACKED, "PZ-001 was solved before the log: untracked")
		_assert_eq(log.puzzles["CH1-PZ-002"]["state"], PlaytestLog.ACTIVE, "PZ-002 is measured from here")
		_assert_false(log.complete_run, "the run is marked as not fully measured")
		var text := "\n".join(log.summary_lines())
		_assert_true(text.contains(tr("UI_PLAYTEST_UNTRACKED")), "summary says 'not measured' (%s)" % text)
	_tree().unload_current_scene()
	await physics_frames(2)
	scene_router.consume_pending_restore()
	_end()


# --- chapter complete --------------------------------------------------------------------------

func test_chapter_complete_writes_json_to_the_headless_folder_and_shows_a_summary() -> void:
	if not _headless_default():
		print("  NOTE: %s=1 set; the JSON would go to user://playtest, skipping the write." % SaveStore.ALLOW_REAL_USER_DATA_ENV)
		return
	_begin()
	var ch01 := _add_chapter()
	var session := ch01.get_node("GameSession") as GameSession
	var router := ch01.get_node("RoomRouter") as RoomRouter
	var log := session.playtest_log
	if not _assert_true(log != null, "log present"):
		_free_chapter(ch01)
		_end()
		return
	_assert_eq(log.output_dir, PlaytestLog.HEADLESS_DIR, "JSON target is the headless folder")
	await physics_frames(2)
	await dismiss_blocking_ui()
	router.enter_room(CONCOURSE)
	await physics_frames(20)
	session.puzzle_service.mark_solved(StringName(PZ1))
	ch01.complete_chapter()

	var path := log.written_path
	_assert_true(path.begins_with(PlaytestLog.HEADLESS_DIR + "/ch01_") and path.ends_with(".json"), "written under user://headless/playtest (%s)" % path)
	_assert_false(path.begins_with(SaveStore.DEFAULT_ROOT) or path.begins_with(SaveStore.HEADLESS_ROOT) or path.begins_with(TEST_SAVE_ROOT),
		"never under a saves folder")
	_assert_false(Array(_json_files(TEST_SAVE_ROOT)).any(func(f: String) -> bool: return f.begins_with("ch01_")),
		"no playtest JSON in the save root (only slot files: %s)" % ", ".join(_json_files(TEST_SAVE_ROOT)))
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if _assert_true(parsed is Dictionary, "JSON file parses"):
		_assert_eq(parsed["chapter"], "ch01", "chapter")
		_assert_true(parsed["completed"], "completed")
		_assert_eq(int(parsed["complete_active_ticks"]), log.active_ticks, "time to chapter_complete")
		_assert_eq(int(parsed["puzzles"][PZ1]["active_ticks"]), int(log.puzzles[PZ1]["active_ticks"]), "per-puzzle ticks")
		_assert_true(parsed["summary"]["puzzles_seconds"].has(PZ1), "per-puzzle seconds")
		_assert_true(parsed["summary"]["rooms_seconds"].has(String(CONCOURSE)), "per-room seconds")
		for kind in PlaytestLog.PAUSE_KINDS:
			_assert_true(parsed["paused"].has(kind), "pause kind '%s' reported" % kind)
	var frozen := log.active_ticks
	await physics_frames(5)
	_assert_eq(log.active_ticks, frozen, "the log stops at chapter_complete")

	var summary := ch01.find_child("PlaytestSummary", true, false) as Label
	if _assert_true(summary != null, "summary on the complete screen"):
		_assert_false(summary.text.contains("UI_"), "summary translated (%s)" % summary.text)
		_assert_true(summary.text.to_ascii_buffer().get_string_from_ascii() == summary.text, "summary ASCII")
		_assert_true(summary.text.contains("PZ-001 "), "per-puzzle line")
		_assert_true(summary.text.contains(path), "names the JSON file")
	for key in ["UI_PLAYTEST_TOTAL", "UI_PLAYTEST_PUZZLE", "UI_PLAYTEST_UNSOLVED", "UI_PLAYTEST_UNTRACKED", "UI_PLAYTEST_SAVED"]:
		_assert_false(tr(key) == key, "%s translated" % key)

	# Only the file this test wrote, in the headless test folder.
	if path.begins_with(PlaytestLog.HEADLESS_DIR + "/"):
		DirAccess.remove_absolute(path)
	_free_chapter(ch01)
	_end()


func test_flag_off_means_no_log_no_file_no_summary() -> void:
	_begin()
	var base_value = ProjectSettings.get_setting(PlaytestLog.SETTING)
	var debug_value = ProjectSettings.get_setting(PlaytestLog.SETTING + ".debug")
	ProjectSettings.set_setting(PlaytestLog.SETTING, false)
	ProjectSettings.set_setting(PlaytestLog.SETTING + ".debug", false)
	_assert_false(PlaytestLog.is_enabled(), "flag off")
	var before := _json_files(PlaytestLog.HEADLESS_DIR)
	var ch01 := _add_chapter()
	var session := ch01.get_node("GameSession") as GameSession
	_assert_true(session.playtest_log == null, "no PlaytestLog")
	_assert_true(ch01.find_child("PlaytestLog", true, false) == null, "no PlaytestLog node")
	await physics_frames(5)
	_assert_eq((ch01.get_node("RoomRouter") as RoomRouter).capture_save("x")["playtest"], {}, "save carries an empty log")
	ch01.complete_chapter()
	_assert_true(ch01.find_child("PlaytestSummary", true, false) == null, "no summary on the complete screen")
	_assert_eq(_json_files(PlaytestLog.HEADLESS_DIR), before, "no JSON written")
	_free_chapter(ch01)
	ProjectSettings.set_setting(PlaytestLog.SETTING, base_value)
	ProjectSettings.set_setting(PlaytestLog.SETTING + ".debug", debug_value)
	_assert_eq(PlaytestLog.is_enabled(), OS.is_debug_build(), "flag restored")
	_end()
