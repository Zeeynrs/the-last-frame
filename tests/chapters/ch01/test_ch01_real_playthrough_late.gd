extends "res://tests/support/base_test.gd"

## Real-input Chapter 1 playthrough, rooms 5-10 (TLF-031): waiting lounge (Beat 06),
## signal control PZ-004 with Echo and the Z-route (Beat 07), upper vestibule PZ-005 levers
## (Beat 08), atrium dispatch terminal (Beat 09) and the street-exit outro (Beat 10).
## Input actions and physics frames only (TLF-029 helpers); state is only read for assertions.
##
## Start state (setup, not gameplay): Chapter01.tscn boots normally, then PZ-001..003 are
## marked SOLVED through PuzzleService.mark_solved() and the router enters the room under test
## (the waiting lounge via its west door, as after the TLF-030 segment). Rooms 1-4 are covered
## with real input by test_ch01_real_playthrough.gd.
## The SaveService autoload is pointed at a test folder for the run (ISSUE-016).
##
## The RISK-018 negative check (PZ-004 must not be solvable without an Echo) lands together with
## the signal_control layout fix: today a no-Echo run makes the window (reported in TLF-031).
##
## Movement helpers mirror test_ch01_real_playthrough.gd (the shared support file is outside
## this task's allowed files).

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_ch01_late_saves"
const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"
const ARRIVE_TOLERANCE := 3.0
const STUCK_FRAMES := 30
const STUCK_DISTANCE := 1.0
const EARLIER_PUZZLES: Array[StringName] = [&"CH1-PZ-001", &"CH1-PZ-002", &"CH1-PZ-003"]

## PZ-004 Z-route waypoints (design/ch01/ROOM_GRAPH.md 5.4).
const W0 := Vector2(176, 152)   # breaker A spot, south lane
const W1 := Vector2(400, 232)   # south railing crossover (east end)
const W2 := Vector2(304, 104)   # north railing crossover (west end)
const W3 := Vector2(528, 184)   # breaker B spot, north lane

var _ch01: Node2D = null
var _session: GameSession = null
var _router: RoomRouter = null
var _player: Player = null
var _held_moves: Array[StringName] = []
var _store: SaveStore = null
var _original_save_root: String = ""
var _real_before: Dictionary = {}
var _segments: Array = []   # [label, frames]
var _segment_start: int = 0


func _init() -> void:
	timeout_frames = 3600


# --- input-only movement (as in test_ch01_real_playthrough.gd) ----------------------------

func _directions() -> Array:
	var out: Array = []
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			if x == 0 and y == 0:
				continue
			var actions: Array[StringName] = []
			if x < 0: actions.append(&"move_left")
			if x > 0: actions.append(&"move_right")
			if y < 0: actions.append(&"move_up")
			if y > 0: actions.append(&"move_down")
			out.append({"dir": Player.compute_movement_vector(Vector2(x, y)), "actions": actions})
	return out


func _hold_moves(actions: Array[StringName]) -> void:
	for action in _held_moves.duplicate():
		if not actions.has(action):
			release(action)
			_held_moves.erase(action)
	for action in actions:
		if not _held_moves.has(action):
			press(action)
			_held_moves.append(action)


## Steers toward `target` until within ARRIVE_TOLERANCE or `stop_when` holds. A stall fails the
## test with positions (layout bug), unless `blocked_ok` (then it just returns false).
func _walk_to(label: String, target: Vector2, stop_when: Callable = Callable(), max_frames: int = 900,
		blocked_ok: bool = false) -> bool:
	var directions := _directions()
	var anchor_pos := _player.global_position
	var still_frames := 0
	for i in max_frames:
		if aborted:
			return false
		if stop_when.is_valid() and stop_when.call():
			_hold_moves([])
			return true
		var delta := target - _player.global_position
		if delta.length() <= ARRIVE_TOLERANCE:
			_hold_moves([])
			return not stop_when.is_valid()
		var best: Dictionary = directions[0]
		var best_score := -INF
		for d in directions:
			var score: float = d["dir"].dot(delta.normalized())
			if score > best_score:
				best_score = score
				best = d
		_hold_moves(best["actions"])
		await physics_frames(1)
		if _player.global_position.distance_to(anchor_pos) >= STUCK_DISTANCE:
			anchor_pos = _player.global_position
			still_frames = 0
		else:
			still_frames += 1
			if still_frames >= STUCK_FRAMES:
				_hold_moves([])
				if not blocked_ok:
					assert_helper.fail("%s: player blocked at %s in %s while walking to %s" % [
						label, _player.global_position, _router.current_room_id, target])
				return false
	_hold_moves([])
	if not blocked_ok:
		assert_helper.fail("%s: did not reach %s within %d frames (player at %s in %s)" % [
			label, target, max_frames, _player.global_position, _router.current_room_id])
	return false


## Robust tap. Input events are flushed once per idle frame, but an idle frame can run several
## physics steps; base_test.tap() (press, 1 physics frame, release) can then flush press and
## release together and the press is lost. Hold until Input reports the action pressed, give the
## player one physics step to handle it, then release and let one more step run.
func _tap(action: StringName) -> void:
	press(action)
	await until(func() -> bool: return Input.is_action_pressed(action), 30)
	await physics_frames(1)
	release(action)
	await until(func() -> bool: return not Input.is_action_pressed(action), 30)
	await physics_frames(1)


func _in_room(room_id: StringName) -> Callable:
	return func() -> bool: return _router.current_room_id == room_id


func _solved(puzzle_id: StringName) -> Callable:
	return func() -> bool: return _session.puzzle_service.is_solved(puzzle_id)


func _targets(node: Node) -> Callable:
	return func() -> bool: return _player.current_target == node


func _resolve(id: StringName) -> Node:
	return _session.id_registry.resolve(id)


func _segment(label: String) -> void:
	var now := Engine.get_physics_frames()
	_segments.append([label, now - _segment_start])
	_segment_start = now


func _print_segments(title: String) -> void:
	var total := 0
	for s in _segments:
		total += s[1]
		print("  INFO: %s | %-34s %4d frames (%.2f s)" % [title, s[0], s[1], s[1] / float(Engine.physics_ticks_per_second)])
	print("  INFO: %s | %-34s %4d frames (%.2f s)" % [title, "total", total, total / float(Engine.physics_ticks_per_second)])


# --- fixture -------------------------------------------------------------------------------

func _remove_test_save_root() -> void:
	var dir := DirAccess.open(TEST_SAVE_ROOT)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	if DirAccess.dir_exists_absolute(TEST_SAVE_ROOT):
		DirAccess.remove_absolute(TEST_SAVE_ROOT)


func _real_save_state() -> Dictionary:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	return {"exists": exists, "mtime": FileAccess.get_modified_time(REAL_SAVE_SLOT_0) if exists else 0}


## Boots Chapter01 with the SaveService autoload on the test root, marks PZ-001..003 SOLVED
## and enters `room_id` through `door_id` (setup only).
func _start_chapter(room_id: StringName, door_id: StringName) -> bool:
	_store = _tree().root.get_node_or_null("SaveService") as SaveStore
	if not _assert_true(_store != null, "SaveService autoload is registered"):
		return false
	_real_before = _real_save_state()
	_original_save_root = _store.save_root
	_remove_test_save_root()
	_store.save_root = TEST_SAVE_ROOT
	_ch01 = (load(CH01_SCENE_PATH) as PackedScene).instantiate() as Node2D
	_tree().root.add_child(_ch01)
	_session = _ch01.get_node("GameSession") as GameSession
	_router = _ch01.get_node("RoomRouter") as RoomRouter
	_player = _ch01.get_node("Player") as Player
	_assert_true(_router.save_service == _store, "router uses the SaveService autoload")
	for puzzle_id in EARLIER_PUZZLES:
		_session.puzzle_service.mark_solved(puzzle_id)
	_router.enter_room(room_id, door_id)
	await physics_frames(3)
	_segment_start = Engine.get_physics_frames()
	return _assert_eq(_router.current_room_id, room_id, "setup entered %s" % room_id)


func _stop_chapter() -> void:
	_hold_moves([])
	if _ch01 != null:
		if _router != null and _router.current_room != null:
			_router._unload_current()
		if _ch01.get_parent() != null:
			_ch01.get_parent().remove_child(_ch01)
		_ch01.free()
		_ch01 = null
	if _store != null:
		_store.save_root = _original_save_root
	_remove_test_save_root()
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root removed")
	var real_after := _real_save_state()
	_assert_eq(real_after["exists"], _real_before["exists"], "real user://saves slot untouched (existence)")
	_assert_eq(real_after["mtime"], _real_before["mtime"], "real user://saves slot untouched (mtime)")


## PZ-004 Step 1 from the signal-control entrance: Rewind + Freeze the capacitor via the watch.
## Leaves Freeze selected.
func _stabilize_capacitor() -> bool:
	var watch: PocketWatch = _player.pocket_watch
	var capacitor := _resolve(&"ch01.signal_control.surge_capacitor") as SurgeCapacitor
	_assert_false(capacitor.bus_powered, "capacitor starts discharged")
	while watch.selected_ability != &"rewind":
		await _tap(&"ability_next")
	_assert_eq(watch.current_target, capacitor, "Rewind auto-targets the capacitor")
	await _tap(&"watch")
	if not _assert_true(await until(func() -> bool: return capacitor.bus_powered, 10), "capacitor charged after Rewind (watch result: %s)" % (watch.last_result.reason if watch.last_result != null else "none")):
		return false
	await _tap(&"ability_next")
	_assert_eq(watch.selected_ability, &"freeze", "ability_next selects Freeze")
	_assert_eq(watch.current_target, capacitor, "Freeze auto-targets the capacitor")
	await _tap(&"watch")
	return _assert_true(await until(func() -> bool: return capacitor.is_stabilized(), 10),
		"capacitor stabilized (powered + frozen)")


# --- the late playthrough ------------------------------------------------------------------

func test_real_input_playthrough_rooms_5_to_10() -> void:
	if not await _start_chapter(&"ch01.waiting_lounge", &"door_entry_west"):
		_stop_chapter()
		return
	var start_msec := Time.get_ticks_msec()
	await _play_late()
	_print_segments("late playthrough")
	print("  INFO: late playthrough wall time %.2f s" % ((Time.get_ticks_msec() - start_msec) / 1000.0))
	_stop_chapter()


func _play_late() -> void:
	var narrative := _session.narrative_state
	var watch: PocketWatch = _player.pocket_watch

	# 5. Waiting lounge (Beat 06): read audio_mira_01
	var mira := _resolve(&"ch01.waiting_lounge.audio_mira_01") as ReadableDocument
	if not await _walk_to("lounge -> audio_mira_01", Vector2(340, 140), _targets(mira)):
		return
	await _tap(&"interact")
	_assert_true(narrative.has_fragment(&"ch01.fragment.mira_departure"), "audio_mira_01 gives fragment mira_departure")
	if not await _walk_to("lounge -> door_exit_north", Vector2(416, 112), _in_room(&"ch01.signal_control")):
		return
	await physics_frames(2)
	_segment("5 lounge (audio log, exit)")

	# 6. Signal control (Beat 07, PZ-004)
	if not await _stabilize_capacitor():
		return
	_segment("6a PZ-004 step 1 (Rewind+Freeze)")
	var a := _resolve(&"ch01.signal_control.breaker_a") as TimedBreaker
	var b := _resolve(&"ch01.signal_control.breaker_b") as TimedBreaker
	var grid := _resolve(&"ch01.signal_control.substation_grid") as SubstationGrid
	var echo := _session.echo_service
	if not await _walk_to("signal control -> W0 (breaker A)", W0):
		return
	await _tap(&"ability_next")
	_assert_eq(watch.selected_ability, &"echo", "ability_next selects Echo")
	await _tap(&"watch")
	_assert_eq(echo.state, EchoService.State.RECORDING, "watch starts recording at W0")
	_assert_eq(_player.current_target, a, "breaker A is the interact target at W0")
	await _tap(&"interact")
	_assert_true(a.is_engaged(), "breaker A pulled while recording")
	await _tap(&"watch")
	_assert_eq(echo.state, EchoService.State.READY, "watch stops recording")
	for leg in [["W0 -> W1 (south crossover)", W1], ["W1 -> W2 (north crossover)", W2], ["W2 -> W3 (breaker B)", W3]]:
		if not await _walk_to("Z-route " + leg[0], leg[1]):
			return
	_assert_false(a.is_engaged(), "live pull of A expired during the Z-route (window shorter than the walk)")
	_assert_eq(_player.current_target, b, "breaker B is the interact target at W3")
	await _tap(&"watch")
	if not _assert_true(await until(func() -> bool: return a.is_engaged(), 120), "Echo pulls breaker A on playback"):
		return
	await _tap(&"interact")
	_assert_true(b.is_engaged(), "breaker B pulled inside A's window")
	if not _assert_true(await until(func() -> bool: return grid.grid_online, 10), "grid online"):
		return
	var door := _resolve(&"ch01.signal_control.vestibule_door")
	_assert_false(door.passage_blocked, "vestibule door open")
	_segment("6b PZ-004 step 2 (Echo + Z-route)")
	# Down the middle of the north lane: the straight line W3 -> trigger touches door_exit_north
	# (448,128) at about (450,145) before the trigger and leaves PZ-004 UNSOLVED (reported).
	if not await _walk_to("signal control -> north lane middle", Vector2(472, 168)):
		return
	if not await _walk_to("signal control -> exit_trigger_vestibule", Vector2(428, 146), _solved(&"CH1-PZ-004")):
		return
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-004"), "PZ-004 SOLVED")
	var journal_keys: Array = narrative.get_journal().map(func(e: Dictionary) -> String: return e["key"])
	_assert_true(journal_keys.has("JRN_CH1_OPERATOR_WARNING"), "journal gets JRN_CH1_OPERATOR_WARNING")
	if not await _walk_to("signal control -> door_exit_north", Vector2(448, 128), _in_room(&"ch01.upper_vestibule")):
		return
	await physics_frames(2)
	_segment("6c PZ-004 exit")

	# 7. Upper vestibule (Beat 08, PZ-005): lever A, then lever B, then the north archway
	var lever_a := _resolve(&"ch01.upper_vestibule.junction_lever_a")
	var lever_b := _resolve(&"ch01.upper_vestibule.junction_lever_b")
	var graph := _session.spatial_service.graph
	_assert_eq(StringName(graph.get_destination(&"ch01.upper_vestibule", &"door_north").get("room_id", "")),
		&"ch01.upper_vestibule", "door_north starts on the West Loop")
	if not await _walk_to("vestibule -> lever A", Vector2(256, 158), _targets(lever_a)):
		return
	await _tap(&"interact")
	if not await _walk_to("vestibule -> lever B", Vector2(380, 196), _targets(lever_b)):
		return
	await _tap(&"interact")
	_assert_eq(StringName(graph.get_destination(&"ch01.upper_vestibule", &"door_north").get("room_id", "")),
		&"ch01.station_atrium", "lever A then B routes door_north to the atrium")
	if not await _walk_to("vestibule -> door_north", Vector2(432, 120), _in_room(&"ch01.station_atrium")):
		return
	_assert_true(await until(_solved(&"CH1-PZ-005"), 10), "PZ-005 SOLVED on entering the atrium")
	_segment("7 vestibule PZ-005 (levers)")

	# 9. Station atrium (Beat 09): the dispatch terminal
	var terminal := _resolve(&"ch01.station_atrium.dispatch_terminal") as ReadableDocument
	if not await _walk_to("atrium -> dispatch_terminal", Vector2(336, 184), _targets(terminal)):
		return
	await _tap(&"interact")
	_assert_true(narrative.get_flag(StringName("read.%s" % terminal.document.document_id)), "dispatch terminal read (Beat 09)")
	if not await _walk_to("atrium -> door_exit_north", Vector2(448, 128), _in_room(&"ch01.street_exit")):
		return
	await physics_frames(2)
	_segment("9 atrium terminal (Beat 09)")

	# 10. Street exit (Beat 10): the outro trigger completes the chapter
	if not await _walk_to("street exit -> trigger_outro", Vector2(384, 128), func() -> bool: return _ch01.chapter_complete):
		return
	_assert_true(_ch01.chapter_complete, "chapter_complete == true")
	_assert_true(narrative.get_flag(&"ch01.flag.chapter_complete"), "chapter_complete flag set")
	_segment("10 street exit outro (Beat 10)")
