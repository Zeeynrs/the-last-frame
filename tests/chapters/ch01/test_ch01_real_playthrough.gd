extends "res://tests/support/base_test.gd"

## Real-input Chapter 1 playthrough (TLF-030, Step 1 by TLF-056): a new game with only Trace to
## chapter complete, through every Step 1 puzzle (SO-01, PZ-001, PZ-006, SO-02, PZ-002, PZ-003,
## PZ-004, PZ-005) and every unlock (Rewind at the courier N-05, Freeze at the technician N-11,
## Echo at the pedestal). Plays Chapter01.tscn with input actions and physics frames only
## (TLF-029 helpers); game state is only read for assertions, nothing on the path is called.
## The SaveService autoload is pointed at a test folder for the run (ISSUE-016).
##
## _play() (rooms 1-4) is also the route test_playtest_log.gd times; it makes no wrong moves
## unless `wrong_moves` is set. The full test sets it and checks the intended wrong moves of
## TLF-055 D1 with their exact reason and HUD feedback text on the way. Unchanged rules for the
## walks: stand spots from the specs (design/ch01/expansion/step1_placement_check.txt) unless a
## comment says why not.

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_ch01_real_saves"
const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"

const LOUNGE := &"ch01.waiting_lounge"

## PZ-004 Z-route waypoints (design/ch01/ROOM_GRAPH.md 5.4).
const W0 := Vector2(176, 152)   # breaker A spot, south lane
const W1 := Vector2(400, 232)   # south railing crossover (east end)
const W2 := Vector2(304, 104)   # north railing crossover (west end)
const W3 := Vector2(528, 184)   # breaker B spot, north lane

## Set by the full playthrough: also make the intended wrong moves (TLF-055 D1).
var wrong_moves: bool = false

var _ch01: Node2D = null
var _session: GameSession = null
var _router: RoomRouter = null
var _player: Player = null
var _checkpoints: Array = []      # [checkpoint_id, error] from router.checkpoint_reached
var _traversals: Array = []       # destinations from the crossing's east door
var _failures: Array = []         # [actor_id, target_id, reason] from interaction_failed
var _unlocks: Array = []          # [ability, tick] from ability_unlocked
var _solves: Array = []           # [puzzle_id, tick] from puzzle_solved
var _segments: Array = []         # [label, frames]
var _segment_start: int = 0


func _init() -> void:
	timeout_frames = 6000


func _in_room(room_id: StringName) -> Callable:
	return func() -> bool: return _router.current_room_id == room_id


func _solved(puzzle_id: StringName) -> Callable:
	return func() -> bool: return _session.puzzle_service.is_solved(puzzle_id)


func _flag(flag: StringName) -> Callable:
	return func() -> bool: return bool(_session.narrative_state.get_flag(flag))


func _resolve(id: StringName) -> Node:
	return _session.id_registry.resolve(id)


func _targets(node: Node) -> Callable:
	return func() -> bool: return _player.current_target == node


func _segment(label: String) -> void:
	var now := Engine.get_physics_frames()
	_segments.append([label, now - _segment_start])
	_segment_start = now


## Selects `ability` with ability_next; fails instead of looping when it is locked.
func _select(ability: StringName) -> bool:
	var watch: PocketWatch = _player.pocket_watch
	for i in 4:
		if watch.selected_ability == ability:
			break
		await tap(&"ability_next")
	return _assert_eq(watch.selected_ability, ability, "%s selected" % ability)


## Taps the watch on `target` with `ability` selected and waits for `done`.
func _use_watch(ability: StringName, target: Node, done: Callable, label: String) -> bool:
	if not await _select(ability):
		return false
	await physics_frames(1)
	if not _assert_eq(_player.pocket_watch.current_target, target, "%s auto-targets %s" % [ability, target.name]):
		return false
	await tap(&"watch")
	return _assert_true(await until(done, 10), label)


## Walks to a stand spot, checks the interact target and taps interact once.
func _use_at(spot: Vector2, target: Node, label: String) -> bool:
	if not await walk_to(_player, label, spot, _targets(target)):
		return false
	await tap(&"interact")
	return true


## Walks to `spot` and Traces `statue` (non-blocking memory lines), waiting for its flag.
func _trace_at(spot: Vector2, statue_id: StringName, flag: StringName) -> bool:
	if not await walk_to(_player, "trace %s" % statue_id, spot):
		return false
	return await _use_watch(&"trace", _resolve(statue_id), _flag(flag), "%s traced" % statue_id)


## The last refusal of `target` by the player is `reason`, and the HUD shows `text_key`
## (an object-specific key is shown deferred, after player.gd's generic one).
func _expect_refusal(target: Node, reason: StringName, text_key: String, label: String) -> bool:
	await physics_frames(2)
	var last: Array = []
	for f in _failures:
		if f[0] == &"player" and f[1] == target.get("object_id"):
			last = f
	if not _assert_true(not last.is_empty(), "%s: %s refused" % [label, target.name]):
		return false
	var ok := _assert_eq(last[2], reason, "%s: reason" % label)
	var hud = _player.hud
	return _assert_eq(hud.feedback_label.text, tr(text_key), "%s: HUD shows %s" % [label, text_key]) and ok


## Waits for an unlock and checks the toast and the auto-select (ABILITY_UNLOCKS 3).
func _expect_unlock(ability: StringName) -> bool:
	if not _assert_true(await until(func() -> bool: return _session.ability_unlocks.is_unlocked(ability), 10), "%s unlocked" % ability):
		return false
	var count := _unlocks.filter(func(u: Array) -> bool: return u[0] == ability).size()
	_assert_eq(count, 1, "ability_unlocked(%s) emitted once" % ability)
	var hud = _player.hud
	_assert_eq(hud.feedback_label.text, tr("UNLOCK_" + String(ability).to_upper()), "%s unlock toast" % ability)
	_assert_eq(_player.pocket_watch.selected_ability, ability, "%s auto-selected" % ability)
	return true


# --- fixture -------------------------------------------------------------------------------

func _save_service() -> SaveStore:
	return _tree().root.get_node_or_null("SaveService") as SaveStore


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


func _start_chapter() -> void:
	_ch01 = (load(CH01_SCENE_PATH) as PackedScene).instantiate() as Node2D
	_tree().root.add_child(_ch01)
	_session = _ch01.get_node("GameSession") as GameSession
	_router = _ch01.get_node("RoomRouter") as RoomRouter
	_player = _ch01.get_node("Player") as Player
	_router.checkpoint_reached.connect(func(id: StringName, error: Error) -> void: _checkpoints.append([id, error]))
	var clock := _session.sim_clock
	_session.interaction_service.interaction_failed.connect(
		func(_tick: int, actor: StringName, target: StringName, _interaction: StringName, reason: StringName) -> void:
			_failures.append([actor, target, reason]))
	_session.ability_unlocks.ability_unlocked.connect(func(ability: StringName) -> void: _unlocks.append([ability, clock.tick]))
	_session.puzzle_service.puzzle_solved.connect(func(id: StringName, tick: int) -> void: _solves.append([id, tick]))
	walk_context = func() -> String: return String(_router.current_room_id)
	_segment_start = Engine.get_physics_frames()


func _stop_chapter() -> void:
	hold_moves([])
	if _ch01 == null:
		return
	if _router != null and _router.current_room != null:
		_router._unload_current()
	if _ch01.get_parent() != null:
		_ch01.get_parent().remove_child(_ch01)
	_ch01.free()
	_ch01 = null


# --- the playthrough -----------------------------------------------------------------------

func test_real_input_new_game_to_chapter_complete() -> void:
	var store := _save_service()
	if not _assert_true(store != null, "SaveService autoload is registered"):
		return
	var real_before := _real_save_state()
	var original_root := store.save_root
	_remove_test_save_root()
	store.save_root = TEST_SAVE_ROOT
	wrong_moves = true

	var start_frame := Engine.get_physics_frames()
	var start_msec := Time.get_ticks_msec()
	_start_chapter()
	_assert_true(_router.save_service == store, "router uses the SaveService autoload")

	if await _play():
		await _play_late()

	var frames := Engine.get_physics_frames() - start_frame
	for s in _segments:
		print("  INFO: playthrough | %-36s %4d frames (%.2f s)" % [s[0], s[1], s[1] / float(Engine.physics_ticks_per_second)])
	print("  INFO: real-input playthrough took %d physics frames (%.1f s game time, %.2f s wall)" % [
		frames, frames / float(Engine.physics_ticks_per_second), (Time.get_ticks_msec() - start_msec) / 1000.0])
	print("  INFO: SOLVED ticks %s" % [_solves])
	print("  INFO: unlock ticks %s" % [_unlocks])
	var log := _session.playtest_log
	if log != null:
		for line in log.summary_lines():
			print("  INFO: PlaytestLog | %s" % line)

	_assert_eq(_unlocks.map(func(u: Array) -> StringName: return u[0]), [&"rewind", &"freeze", &"echo"],
		"unlocks in play order, each once")
	var order: Array = _solves.map(func(s: Array) -> StringName: return s[0])
	_assert_eq(order, [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-PZ-006", &"CH1-SO-02", &"CH1-PZ-002", &"CH1-PZ-003",
		&"CH1-PZ-004", &"CH1-PZ-005"], "every Step 1 puzzle SOLVED once, in the intended order")

	_stop_chapter()
	release_all_input()
	store.save_root = original_root
	_remove_test_save_root()
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root removed")
	var real_after := _real_save_state()
	_assert_eq(real_after["exists"], real_before["exists"], "real user://saves slot untouched (existence)")
	_assert_eq(real_after["mtime"], real_before["mtime"], "real user://saves slot untouched (mtime)")


## Rooms 1-4, new game -> door to the waiting lounge. True when it arrived.
func _play() -> bool:
	var unlocks := _session.ability_unlocks
	var watch: PocketWatch = _player.pocket_watch

	# 1. Arrival platform (CH1-SO-01)
	await physics_frames(2)
	_assert_eq(_router.current_room_id, &"ch01.arrival_platform", "starts on the arrival platform")
	_assert_eq(unlocks.unlocked(), [&"trace"], "new game starts with Trace only")
	# Beat 01 monologue blocks the player at boot (TLF-032): advance it with interact.
	await dismiss_blocking_ui()
	_assert_false(blocking_ui_open(), "Beat 01 monologue dismissed")
	if wrong_moves:
		await tap(&"ability_next")
		_assert_eq(watch.selected_ability, &"trace", "with only Trace, ability_next changes nothing")
	# The watch: MEM_WATCH lines, then the UNLOCK_TRACE toast (no new unlock).
	if not await _use_at(Vector2(224, 240), _resolve(&"global.pocket_watch"), "arrival -> pocket watch"):
		return false
	if not _assert_true(await until(_flag(&"ch01.flag.pocket_watch_acquired"), 10), "pocket watch taken"):
		return false
	await physics_frames(2)
	_assert_eq(_player.hud.feedback_label.text, tr("UNLOCK_TRACE"), "UNLOCK_TRACE toast at the watch")
	_assert_eq(unlocks.unlocked(), [&"trace"], "the watch does not grant anything new")

	var gate := _resolve(&"ch01.arrival_platform.platform_gate") as PoweredDoor
	var lever := _resolve(&"ch01.arrival_platform.release_lever")
	var lock := _resolve(&"ch01.arrival_platform.release_lock") as CodeLock
	_assert_true(gate.passage_blocked, "platform gate starts closed")
	if wrong_moves:
		# The four commuters hold the code (CH1-SO-01 R1).
		for row in [[&"n03_old_man", Vector2(432, 168)], [&"n02_student", Vector2(224, 160)],
				[&"n01_conductor", Vector2(480, 208)], [&"n04_cleaner", Vector2(624, 312)]]:
			var id := StringName("ch01.arrival_platform." + String(row[0]))
			if not await _trace_at(row[1], id, StringName("ch01.npc.%s.traced" % String(row[0]).left(3))):
				return false
		# One wrong code (selectors untouched), then the silent lock-out. From N-04 around the north
		# side of the closed gate's blocker (24x24 at (720,328)).
		if not await walk_to(_player, "arrival -> north of the gate", Vector2(712, 300)):
			return false
		if not await _use_at(Vector2(736, 304), lever, "arrival -> release_lever (wrong code)"):
			return false
		await _expect_refusal(lever, &"wrong_code", "SO001_FB_WRONG_CODE", "SO-01 wrong code")
		await tap(&"interact")
		await _expect_refusal(lever, &"locked_out", "SO001_FB_LOCKED_OUT", "SO-01 during the lock-out")
	# Stand spots one tile south of each wall panel (CH1-SO-01 object table, 17.9 px).
	for row in [[&"selector_line", Vector2(624, 248), 1], [&"selector_platform", Vector2(656, 264), 2],
			[&"selector_car", Vector2(688, 280), 1]]:
		var selector := _resolve(StringName("ch01.arrival_platform." + String(row[0]))) as SelectorSwitch
		for i in row[2]:
			if not await _use_at(row[1], selector, "arrival -> %s" % row[0]):
				return false
		_assert_eq(selector.selector_position, row[2], "%s set to %d" % [row[0], row[2]])
	if not await walk_to(_player, "arrival -> release_lever", Vector2(736, 304), _targets(lever)):
		return false
	if wrong_moves:
		var clock := _session.sim_clock
		_assert_true(await until(func() -> bool: return clock.tick >= lock.lockout_until_tick, 600), "lock-out over")
	await tap(&"interact")
	if not _assert_true(await until(_solved(&"CH1-SO-01"), 10), "SO-01 SOLVED by the release lever"):
		return false
	_assert_false(gate.passage_blocked, "platform gate open")
	if not await walk_to(_player, "arrival -> door_exit_east", Vector2(720, 328), _in_room(&"ch01.concourse_west")):
		return false
	await physics_frames(2)
	_segment("1 arrival (SO-01)")

	# 2. Concourse: the courier (Rewind unlocks), PZ-001 conduit + turnstile, PZ-006 dials + validator
	var turnstile := _resolve(&"ch01.concourse_west.turnstile_gate") as TurnstileGate
	var conduit := _resolve(&"ch01.concourse_west.conduit_01")
	_assert_true(turnstile.passage_blocked, "turnstile starts blocked")
	if not await _use_watch(&"trace", _resolve(&"ch01.concourse_west.n05_courier"), _flag(&"ch01.npc.n05.traced"), "courier traced"):
		return false
	await dismiss_blocking_ui()
	if not await _expect_unlock(&"rewind"):
		return false
	if wrong_moves:
		# Rewind on the gate while the conduit still pins it (via the west hall waypoint: the straight line
		# from the conduit spot catches the Blocker's corner).
		if not await walk_to(_player, "concourse -> conduit spot", Vector2(320, 168)):
			return false
		if not await walk_to(_player, "concourse -> west hall waypoint", Vector2(280, 168)):
			return false
		if not await walk_to(_player, "concourse -> gate Rewind spot", Vector2(298, 198)):
			return false
		if not await _select(&"rewind"):
			return false
		await physics_frames(1)
		_assert_eq(watch.current_target, turnstile, "Rewind targets the turnstile from the gate spot")
		await tap(&"watch")
		await _expect_refusal(turnstile, &"pinned", "PZ001_FB_PINNED", "PZ-001 gate pinned by the conduit")
		if not await walk_to(_player, "concourse -> west hall waypoint", Vector2(280, 168)):
			return false
	if not await walk_to(_player, "concourse -> conduit spot", Vector2(320, 168)):
		return false
	if not await _use_watch(&"rewind", conduit, func() -> bool: return conduit.get("conduit_state") == &"mounted", "conduit mounted after Rewind"):
		return false
	# Gate Rewind spot in the entry strip (TLF-055 review): the gate is nearer than the conduit (by 26.6 px)
	# and the capsule stays 3.7 px clear of door_entry_west and 1.2 px clear of the walls.
	if not await walk_to(_player, "concourse -> west hall waypoint", Vector2(280, 168)):
		return false
	if not await walk_to(_player, "concourse -> gate Rewind spot", Vector2(298, 198)):
		return false
	if not await _use_watch(&"rewind", turnstile, func() -> bool: return not turnstile.passage_blocked, "turnstile opens after Rewind"):
		return false
	if wrong_moves:
		# The anchor's memory (the conduit falling onto the arm), from the spec spot (312,188) now that
		# the gate's Blocker is gone: while it is closed that spot overlaps the Blocker, and the pocket
		# north of it connects to the entry strip only past door_entry_west (reported, TLF-056).
		if not await _trace_at(Vector2(312, 188), &"ch01.concourse_west.turnstile_trace_anchor",
				&"traced.ch01.concourse_west.turnstile_trace_anchor"):
			return false
	if not await walk_to(_player, "concourse -> exit_trigger", Vector2(352, 208), _solved(&"CH1-PZ-001")):
		return false
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-001"), "PZ-001 SOLVED by walking through")
	_segment("2a concourse PZ-001")

	var validator := _resolve(&"ch01.concourse_west.ticket_validator")
	if wrong_moves:
		# The terms and the four commuters by the staff door (CH1-PZ-006 clues), then the validator
		# with the dials untouched.
		var terms := _resolve(&"ch01.concourse_west.doc_ticket_terms")
		if not await walk_to(_player, "concourse -> gate aperture west", Vector2(320, 192)):
			return false
		if not await _use_at(Vector2(104, 196), terms, "concourse -> doc_ticket_terms"):
			return false
		_assert_true(blocking_ui_open(), "the ticket terms open the document viewer")
		await dismiss_blocking_ui()
		if not await walk_to(_player, "concourse -> gate aperture east", Vector2(320, 192)):
			return false
		if not await walk_to(_player, "concourse -> east corridor", Vector2(352, 208)):
			return false
		for row in [[&"n09_teen", Vector2(432, 336)], [&"n08_father", Vector2(480, 360)],
				[&"n07_briefcase", Vector2(512, 344)], [&"n06_red_coat", Vector2(544, 328)]]:
			var id := StringName("ch01.concourse_west." + String(row[0]))
			if row[0] == &"n08_father":
				# South of N-08's footprint, which sits on the straight line.
				if not await walk_to(_player, "concourse -> south of N-08", Vector2(452, 366)):
					return false
			if not await _trace_at(row[1], id, StringName("ch01.npc.%s.traced" % String(row[0]).left(3))):
				return false
		if not await _use_at(Vector2(608, 248), validator, "concourse -> ticket_validator (dials untouched)"):
			return false
		await _expect_refusal(validator, &"invalid_ticket", "PZ006_FB_NO_SUCH_TICKET", "PZ-006 validator before the dials")
	# PZ-006: Rewind the dials 3 / 2 / 4 steps (index 5 -> 2 / 3 / 1), then use the validator.
	for row in [[&"dial_line", Vector2(544, 200), 2], [&"dial_platform", Vector2(576, 216), 3],
			[&"dial_time", Vector2(608, 232), 1]]:
		var dial := _resolve(StringName("ch01.concourse_west." + String(row[0]))) as HistoryDial
		if not await walk_to(_player, "concourse -> %s" % row[0], row[1]):
			return false
		while dial.index > row[2]:
			var before := dial.index
			if not await _use_watch(&"rewind", dial, func() -> bool: return dial.index == before - 1, "%s steps back" % row[0]):
				return false
	var staff_door := _resolve(&"ch01.concourse_west.staff_door") as PoweredDoor
	if not await _use_at(Vector2(608, 248), validator, "concourse -> ticket_validator"):
		return false
	if not _assert_true(await until(_solved(&"CH1-PZ-006"), 10), "PZ-006 SOLVED by the validator"):
		return false
	_assert_false(staff_door.passage_blocked, "staff door open")
	if not await walk_to(_player, "concourse -> door_exit_east", Vector2(640, 352), _in_room(&"ch01.maintenance_bay")):
		return false
	await physics_frames(2)
	_segment("2b concourse PZ-006")

	# Checkpoint autosave written to the test root (Lead probe: frame 197)
	var store := _save_service()
	_assert_true(FileAccess.file_exists(TEST_SAVE_ROOT.path_join("slot_%d.json" % _router.autosave_slot)),
		"checkpoint autosave written to the test save root")
	var saved: Dictionary = store.read_slot(_router.autosave_slot)
	_assert_true(saved.get("ok", false), "autosave reads back")
	if saved.get("ok", false):
		_assert_eq(saved["data"].get("checkpoint_id", ""), "ch01.cp.maintenance_bay", "autosave is the bay checkpoint")
		_assert_eq(saved["data"]["puzzles"].get("CH1-PZ-001", ""), "SOLVED", "autosave records PZ-001 SOLVED")

	# 3. Maintenance bay: the technician (Freeze unlocks), SO-02 plate + Freeze the hatch, PZ-002
	var hatch := _resolve(&"ch01.maintenance_bay.hatch_01") as PlateLinkedGate
	if not await walk_to(_player, "bay -> technician spot", Vector2(352, 144)):
		return false
	if not await _use_watch(&"trace", _resolve(&"ch01.maintenance_bay.n11_hatch_tech"), _flag(&"ch01.npc.n11.traced"), "technician traced"):
		return false
	await dismiss_blocking_ui()
	if not await _expect_unlock(&"freeze"):
		return false
	if not await walk_to(_player, "bay -> hatch plate", Vector2(320, 160), func() -> bool: return not hatch.passage_blocked):
		return false
	if not await _use_watch(&"freeze", hatch, func() -> bool: return hatch.is_frozen(), "hatch frozen open"):
		return false
	# Through the hatch straight down at x = 384, clear of the technician's footprint (368,136).
	for point in [Vector2(352, 124), Vector2(384, 124)]:
		if not await walk_to(_player, "bay -> above the hatch", point):
			return false
	if not await walk_to(_player, "bay -> through the hatch", Vector2(384, 172), _solved(&"CH1-SO-02")):
		return false
	_assert_true(_session.puzzle_service.is_solved(&"CH1-SO-02"), "SO-02 SOLVED by walking through the hatch")
	_segment("3a bay SO-02")

	var shutter := _resolve(&"ch01.maintenance_bay.fire_shutter") as FireShutter
	var gear := _resolve(&"ch01.maintenance_bay.counterweight_gear") as CounterweightGear
	var inner := _resolve(&"ch01.maintenance_bay.inner_shutter") as FireShutter
	_assert_true(shutter.passage_blocked, "shutter starts blocked")
	# (488,188): the gear (26.8 px) is nearer than the latched hatch (112 px) for Freeze.
	if not await walk_to(_player, "bay -> within watch range", Vector2(488, 188)):
		return false
	if not await _use_watch(&"rewind", shutter, func() -> bool: return not shutter.passage_blocked, "shutter raised after Rewind"):
		return false
	if not await _use_watch(&"freeze", gear, func() -> bool: return gear.is_frozen(), "gear frozen"):
		return false
	# Straight down through the middle of the shutter gap (dividers end at (524,218) and (500,230)).
	if not await walk_to(_player, "bay -> above the shutter gap", Vector2(512, 210)):
		return false
	if not await walk_to(_player, "bay -> through the shutter gap", Vector2(512, 240)):
		return false
	if not await walk_to(_player, "bay -> pocket", Vector2(560, 234)):
		return false
	if not await _use_watch(&"rewind", inner, func() -> bool: return not inner.passage_blocked, "inner shutter raised after Rewind"):
		return false
	if not await walk_to(_player, "bay -> exit_trigger_east_02", Vector2(560, 264), _solved(&"CH1-PZ-002")):
		return false
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-002"), "PZ-002 SOLVED behind the inner shutter")
	if not await walk_to(_player, "bay -> door_exit_east", Vector2(656, 296), _in_room(&"ch01.security_crossing")):
		return false
	await physics_frames(2)
	_segment("3b bay PZ-002")

	# 4. Security crossing: the pedestal (Echo unlocks), the pass, an Echo onto the plate, the reader
	if not await _use_at(Vector2(256, 144), _resolve(&"ch01.security_crossing.echo_recorder_pedestal"), "crossing -> echo pedestal"):
		return false
	await dismiss_blocking_ui()
	if not await _expect_unlock(&"echo"):
		return false
	# (348,100): the pass (12.6 px) is nearer than the guard statue (23.3 px; a tie at (320,112)).
	if not await _use_at(Vector2(348, 100), _resolve(&"ch01.security_crossing.transit_pass_pickup"), "crossing -> transit pass"):
		return false
	_assert_true(await until(_flag(&"ch01.flag.transit_pass"), 10), "transit pass taken")
	var bridge := _resolve(&"ch01.security_crossing.bridge_platform_01") as RetractableBridge
	_assert_false(bridge.walkable, "bridge starts retracted")
	if not await _select(&"echo"):
		return false
	var echo := _session.echo_service
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.RECORDING, "watch starts recording")
	if not await walk_to(_player, "crossing -> pressure plate", Vector2(256, 176)):
		return false
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.READY, "watch stops recording on the plate")
	if not await walk_to(_player, "crossing -> off the plate", Vector2(300, 168)):
		return false
	await physics_frames(2)
	_assert_false(bridge.walkable, "bridge retracts when the player leaves the plate")
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return bridge.walkable, 600), "bridge extends while the Echo holds the plate"):
		return false
	# Straight down across the bridge gap (trench barriers end at (380,178) and (356,190)).
	if not await walk_to(_player, "crossing -> above the bridge", Vector2(368, 170)):
		return false
	if not await walk_to(_player, "crossing -> across the bridge", Vector2(368, 198)):
		return false
	var barrier := _resolve(&"ch01.security_crossing.staff_barrier_01") as PoweredDoor
	if not await _use_at(Vector2(400, 200), _resolve(&"ch01.security_crossing.card_reader_01"), "crossing -> card reader"):
		return false
	if not _assert_true(await until(func() -> bool: return not barrier.passage_blocked, 10), "staff barrier lifts after the reader"):
		return false
	if not await walk_to(_player, "crossing -> above the barrier", Vector2(432, 186)):
		return false
	if not await walk_to(_player, "crossing -> exit_trigger_lounge", Vector2(432, 216), _solved(&"CH1-PZ-003")):
		return false
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-003"), "PZ-003 SOLVED behind the staff barrier")

	# 5. Door to the waiting lounge
	var door := _resolve(&"ch01.security_crossing.door_exit_east") as DoorwayPresenter
	door.traversed.connect(func(_actor: StringName, destination: Dictionary) -> void: _traversals.append(destination))
	var arrived := func() -> bool: return _router.current_room_id == LOUNGE or not _traversals.is_empty()
	if not await walk_to(_player, "crossing -> door_exit_east", Vector2(464, 232), arrived):
		return false
	_assert_false(_traversals.is_empty(), "walking into the east door traverses it")
	if not _traversals.is_empty():
		_assert_eq(StringName(_traversals[0]["room_id"]), LOUNGE, "east door leads to the waiting lounge")
	if not _assert_true(await until(_in_room(LOUNGE), 10), "arrived in the waiting lounge"):
		return false
	await physics_frames(2)
	_segment("4 crossing PZ-003")
	return true


## PZ-004 step 1 from the current spot: Rewind + Freeze the capacitor. Leaves Freeze selected.
func _stabilize_capacitor() -> bool:
	var capacitor := _resolve(&"ch01.signal_control.surge_capacitor") as SurgeCapacitor
	_assert_false(capacitor.bus_powered, "capacitor discharged before the Rewind")
	if not await _use_watch(&"rewind", capacitor, func() -> bool: return capacitor.bus_powered, "capacitor charged after Rewind"):
		return false
	return await _use_watch(&"freeze", capacitor, func() -> bool: return capacitor.is_stabilized(), "capacitor stabilized (powered + frozen)")


## Rooms 5-10, waiting lounge -> chapter complete.
func _play_late() -> void:
	var narrative := _session.narrative_state
	var watch: PocketWatch = _player.pocket_watch

	# 5. Waiting lounge (Beat 06): read audio_mira_01
	var mira := _resolve(&"ch01.waiting_lounge.audio_mira_01") as ReadableDocument
	if not await walk_to(_player, "lounge -> audio_mira_01", Vector2(340, 140), _targets(mira)):
		return
	await tap(&"interact")
	_assert_true(blocking_ui_open(), "audio_mira_01 opens the document viewer")
	await dismiss_blocking_ui()
	_assert_false(blocking_ui_open(), "document viewer closed with interact")
	_assert_true(narrative.has_fragment(&"ch01.fragment.mira_departure"), "audio_mira_01 gives fragment mira_departure")
	if not await walk_to(_player, "lounge -> door_exit_north", Vector2(416, 112), _in_room(&"ch01.signal_control")):
		return
	await physics_frames(2)
	_segment("5 lounge (audio log, exit)")

	# 6. Signal control (Beat 07, CH1-PZ-004 The Forgotten Sequence)
	var capacitor := _resolve(&"ch01.signal_control.surge_capacitor") as SurgeCapacitor
	# The door spawn (288,208) is in the south lane, 89 px from the capacitor (watch range 96).
	if wrong_moves:
		# (304,200), south lane: the spec spot (288,176) lies on the south railing (208,136)-(368,216).
		if not await _trace_at(Vector2(304, 200), &"ch01.signal_control.n20_engineer", &"ch01.npc.n20.traced"):
			return
		if not await walk_to(_player, "signal control -> back at the door spawn", Vector2(288, 208)):
			return
	if not await _stabilize_capacitor():
		return
	if wrong_moves:
		# Breaker C on the charged bus: brown-out, the capacitor is discharged and thawed. C (224,112)
		# stands north of the south railing (192,128)-(384,224); walking from W0 towards its spec spot
		# (240,120) slides along the railing's south side until C is the interact target.
		var breaker_c := _resolve(&"ch01.signal_control.breaker_c")
		if not await walk_to(_player, "signal control -> W0", W0):
			return
		if not await _use_at(Vector2(240, 120), breaker_c, "signal control -> breaker C"):
			return
		_assert_true(await until(func() -> bool: return not capacitor.bus_powered, 10), "C browns the bus out")
		_assert_false(capacitor.is_frozen(), "the brown-out thaws the capacitor")
		await physics_frames(2)
		_assert_eq(_player.hud.feedback_label.text, tr("PZ004_FB_BROWNOUT"), "HUD shows PZ004_FB_BROWNOUT")
		if not await walk_to(_player, "signal control -> back at the door spawn", Vector2(288, 208)):
			return
		if not await _stabilize_capacitor():
			return
	_segment("6a PZ-004 step 1 (Rewind+Freeze)")
	var a := _resolve(&"ch01.signal_control.breaker_a") as TimedBreaker
	var b := _resolve(&"ch01.signal_control.breaker_b") as TimedBreaker
	var grid := _resolve(&"ch01.signal_control.substation_grid") as SubstationGrid
	var echo := _session.echo_service
	if not await walk_to(_player, "signal control -> W0 (breaker A)", W0):
		return
	if not await _select(&"echo"):
		return
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.RECORDING, "watch starts recording at W0")
	_assert_eq(_player.current_target, a, "breaker A is the interact target at W0")
	await tap(&"interact")
	_assert_true(a.is_engaged(), "breaker A pulled while recording")
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.READY, "watch stops recording")
	for leg in [["W0 -> W1 (south crossover)", W1], ["W1 -> W2 (north crossover)", W2], ["W2 -> W3 (breaker B)", W3]]:
		if not await walk_to(_player, "Z-route " + leg[0], leg[1]):
			return
	_assert_false(a.is_engaged(), "live pull of A expired during the Z-route (window shorter than the walk)")
	_assert_eq(_player.current_target, b, "breaker B is the interact target at W3")
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return a.is_engaged(), 120), "Echo pulls breaker A on playback"):
		return
	await tap(&"interact")
	_assert_true(b.is_engaged(), "breaker B pulled inside A's window")
	if not _assert_true(await until(func() -> bool: return grid.grid_online, 10), "grid online"):
		return
	var door := _resolve(&"ch01.signal_control.vestibule_door")
	_assert_false(door.passage_blocked, "vestibule door open")
	_segment("6b PZ-004 step 2 (Echo + Z-route)")
	# Down the middle of the north lane: the straight line W3 -> trigger touches door_exit_north
	# (448,128) at about (450,145) before the trigger and leaves PZ-004 UNSOLVED (reported).
	if not await walk_to(_player, "signal control -> north lane middle", Vector2(472, 168)):
		return
	if not await walk_to(_player, "signal control -> exit_trigger_vestibule", Vector2(428, 146), _solved(&"CH1-PZ-004")):
		return
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-004"), "PZ-004 SOLVED")
	var journal_keys: Array = narrative.get_journal().map(func(e: Dictionary) -> String: return e["key"])
	_assert_true(journal_keys.has("JRN_CH1_OPERATOR_WARNING"), "journal gets JRN_CH1_OPERATOR_WARNING")
	if not await walk_to(_player, "signal control -> door_exit_north", Vector2(448, 128), _in_room(&"ch01.upper_vestibule")):
		return
	await physics_frames(2)
	_segment("6c PZ-004 exit")

	# 7. Upper vestibule (Beat 08, CH1-PZ-005): an Echo holds the standby plate, then lever A, then B
	var lever_a := _resolve(&"ch01.upper_vestibule.junction_lever_a")
	var lever_b := _resolve(&"ch01.upper_vestibule.junction_lever_b")
	var graph := _session.spatial_service.graph
	_assert_eq(StringName(graph.get_destination(&"ch01.upper_vestibule", &"door_north").get("room_id", "")),
		&"ch01.upper_vestibule", "door_north starts on the West Loop")
	if wrong_moves:
		if not await _use_at(Vector2(256, 158), lever_a, "vestibule -> lever A (empty plate)"):
			return
		await _expect_refusal(lever_a, &"unpowered", "PZ005_FB_UNPOWERED_RELAY", "PZ-005 lever A on an empty plate")
	if not await _select(&"echo"):
		return
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.RECORDING, "watch starts recording in the vestibule")
	if not await walk_to(_player, "vestibule -> standby plate", Vector2(176, 168)):
		return
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.READY, "watch stops recording on the standby plate")
	if not await walk_to(_player, "vestibule -> lever A", Vector2(256, 158), _targets(lever_a)):
		return
	await tap(&"watch")
	var plate_held := func() -> bool: return echo.get_echo_occupied_triggers().has(&"ch01.upper_vestibule.standby_plate_01")
	if not _assert_true(await until(plate_held, 600), "the Echo holds the standby plate"):
		return
	if wrong_moves:
		if not await _use_at(Vector2(380, 196), lever_b, "vestibule -> lever B first"):
			return
		await _expect_refusal(lever_b, &"invalid_graph", "UI_FB_INVALID_GRAPH", "PZ-005 lever B before A")
	if not await _use_at(Vector2(256, 158), lever_a, "vestibule -> lever A"):
		return
	if not await _use_at(Vector2(380, 196), lever_b, "vestibule -> lever B"):
		return
	_assert_eq(StringName(graph.get_destination(&"ch01.upper_vestibule", &"door_north").get("room_id", "")),
		&"ch01.station_atrium", "lever A then B routes door_north to the atrium")
	if wrong_moves:
		var lever_c := _resolve(&"ch01.upper_vestibule.junction_lever_c")
		if not await _use_at(Vector2(368, 136), lever_c, "vestibule -> lever C"):
			return
		await _expect_refusal(lever_c, &"dead_relay", "PZ005_FB_DEAD_RELAY", "PZ-005 lever C")
	if not await walk_to(_player, "vestibule -> door_north", Vector2(432, 120), _in_room(&"ch01.station_atrium")):
		return
	_assert_true(await until(_solved(&"CH1-PZ-005"), 10), "PZ-005 SOLVED on entering the atrium")
	_segment("7 vestibule PZ-005 (levers)")

	# 9. Station atrium (Beat 09): the dispatch terminal
	var terminal := _resolve(&"ch01.station_atrium.dispatch_terminal") as ReadableDocument
	if not await walk_to(_player, "atrium -> dispatch_terminal", Vector2(336, 184), _targets(terminal)):
		return
	await tap(&"interact")
	_assert_true(blocking_ui_open(), "dispatch terminal opens the document viewer")
	# Page through the terminal; closing it after page 2 starts the blocking Beat 09 monologue.
	await dismiss_blocking_ui()
	_assert_false(blocking_ui_open(), "terminal and Beat 09 monologue dismissed")
	_assert_true(narrative.get_flag(StringName("read.%s" % terminal.document.document_id)), "dispatch terminal read")
	_assert_true(narrative.get_flag(&"heard.ch01_b09_revelation"), "Beat 09 revelation monologue played")
	if not await walk_to(_player, "atrium -> door_exit_north", Vector2(448, 128), _in_room(&"ch01.street_exit")):
		return
	await physics_frames(2)
	_segment("9 atrium terminal (Beat 09)")

	# 10. Street exit (Beat 10): the outro trigger completes the chapter
	var outro_started := func() -> bool: return _ch01.chapter_complete or blocking_ui_open()
	if not await walk_to(_player, "street exit -> trigger_outro", Vector2(384, 128), outro_started):
		return
	# Beat 10 outro monologue is blocking; the chapter completes when it finishes.
	await dismiss_blocking_ui()
	_assert_true(narrative.get_flag(&"heard.ch01_b10_outro"), "Beat 10 outro monologue played")
	_assert_true(_ch01.chapter_complete, "chapter_complete == true")
	_assert_true(narrative.get_flag(&"ch01.flag.chapter_complete"), "chapter_complete flag set")
	_segment("10 street exit outro (Beat 10)")
