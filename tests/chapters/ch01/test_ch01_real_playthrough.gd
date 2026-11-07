extends "res://tests/support/base_test.gd"

## Real-input Chapter 1 playthrough (TLF-030), replacing the Lead's runtime probe (TLF-009 review).
## Plays Chapter01.tscn with input actions and physics frames only (TLF-029 helpers):
## arrival (SO-01 code) -> concourse (PZ-001 Rewind, PZ-006 dials) -> maintenance bay (SO-02 hatch,
## PZ-002 Rewind + Freeze) -> security crossing (PZ-003 Echo + card reader) -> door to the lounge.
## Step 1 layout (TLF-055): a new game has only Trace; Rewind, Freeze and Echo unlock through their
## triggers on the way (courier N-05, technician N-11, the echo pedestal). Minimal path through the
## new gates only; the wrong moves and negative checks are TLF-056.
## Game state is only read for assertions; nothing on the gameplay path is called directly.
## The SaveService autoload is pointed at a test folder for the run (ISSUE-016).

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_ch01_real_saves"
const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"

const LOUNGE := &"ch01.waiting_lounge"

var _ch01: Node2D = null
var _session: GameSession = null
var _router: RoomRouter = null
var _player: Player = null
var _checkpoints: Array = []      # [checkpoint_id, error] from router.checkpoint_reached
var _traversals: Array = []       # destinations from the crossing's east door


func _init() -> void:
	timeout_frames = 3000


func _in_room(room_id: StringName) -> Callable:
	return func() -> bool: return _router.current_room_id == room_id


func _solved(puzzle_id: StringName) -> Callable:
	return func() -> bool: return _session.puzzle_service.is_solved(puzzle_id)


func _resolve(id: StringName) -> Node:
	return _session.id_registry.resolve(id)


func _targets(node: Node) -> Callable:
	return func() -> bool: return _player.current_target == node


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
	walk_context = func() -> String: return String(_router.current_room_id)


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

func test_real_input_playthrough_pz001_to_pz003() -> void:
	var store := _save_service()
	if not _assert_true(store != null, "SaveService autoload is registered"):
		return
	var real_before := _real_save_state()
	var original_root := store.save_root
	_remove_test_save_root()
	store.save_root = TEST_SAVE_ROOT

	var start_frame := Engine.get_physics_frames()
	var start_msec := Time.get_ticks_msec()
	_start_chapter()
	_assert_true(_router.save_service == store, "router uses the SaveService autoload")

	await _play()

	var frames := Engine.get_physics_frames() - start_frame
	var seconds := (Time.get_ticks_msec() - start_msec) / 1000.0
	print("  INFO: real-input playthrough took %d physics frames (%.1f s game time, %.2f s wall)" % [
		frames, frames / float(Engine.physics_ticks_per_second), seconds])

	_stop_chapter()
	store.save_root = original_root
	_remove_test_save_root()
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root removed")
	var real_after := _real_save_state()
	_assert_eq(real_after["exists"], real_before["exists"], "real user://saves slot untouched (existence)")
	_assert_eq(real_after["mtime"], real_before["mtime"], "real user://saves slot untouched (mtime)")


func _play() -> void:
	var unlocks := _session.ability_unlocks

	# 1. Arrival platform: SO-01, selectors 1 / 2 / 1 and the release lever (Lead probe: frame 50)
	await physics_frames(2)
	_assert_eq(_router.current_room_id, &"ch01.arrival_platform", "starts on the arrival platform")
	_assert_eq(unlocks.unlocked(), [&"trace"], "new game starts with Trace only")

	# Beat 01 monologue blocks the player at boot (TLF-032): advance it with interact.
	await dismiss_blocking_ui()
	_assert_false(blocking_ui_open(), "Beat 01 monologue dismissed")

	# Stand spots one tile south of each wall panel (CH1-SO-01 object table, 17.9 px).
	var gate := _resolve(&"ch01.arrival_platform.platform_gate") as PoweredDoor
	_assert_true(gate.passage_blocked, "platform gate starts closed")
	for row in [[&"selector_line", Vector2(400, 136), 1], [&"selector_platform", Vector2(432, 152), 2],
			[&"selector_car", Vector2(464, 168), 1]]:
		var selector := _resolve(StringName("ch01.arrival_platform." + String(row[0]))) as SelectorSwitch
		for i in row[2]:
			if not await _use_at(row[1], selector, "arrival -> %s" % row[0]):
				return
		_assert_eq(selector.selector_position, row[2], "%s set to %d" % [row[0], row[2]])
	if not await _use_at(Vector2(480, 192), _resolve(&"ch01.arrival_platform.release_lever"), "arrival -> release_lever"):
		return
	if not _assert_true(await until(_solved(&"CH1-SO-01"), 10), "SO-01 SOLVED by the release lever"):
		return
	_assert_false(gate.passage_blocked, "platform gate open")
	if not await walk_to(_player, "arrival -> door_exit_east", Vector2(448, 208), _in_room(&"ch01.concourse_west")):
		return
	await physics_frames(2)

	# 2. Concourse: Trace the courier (Rewind unlocks), Rewind the conduit, then the turnstile
	var turnstile := _resolve(&"ch01.concourse_west.turnstile_gate") as TurnstileGate
	var conduit := _resolve(&"ch01.concourse_west.conduit_01")
	_assert_true(turnstile.passage_blocked, "turnstile starts blocked")
	var flag_set := func(flag: StringName) -> Callable:
		return func() -> bool: return _session.narrative_state.get_flag(flag)
	if not await _use_watch(&"trace", _resolve(&"ch01.concourse_west.n05_courier"), flag_set.call(&"ch01.npc.n05.traced"), "courier traced"):
		return
	await dismiss_blocking_ui()
	_assert_true(unlocks.is_unlocked(&"rewind"), "Rewind unlocked by the courier")
	if not await walk_to(_player, "concourse -> conduit spot", Vector2(208, 136)):
		return
	if not await _use_watch(&"rewind", conduit, func() -> bool: return conduit.get("conduit_state") == &"mounted", "conduit mounted after Rewind"):
		return
	# Gate Rewind spot in the entry strip (TLF-055 review): the gate is nearer than the conduit (by 26.6 px)
	# and the capsule stays 3.7 px clear of door_entry_west and 1.2 px clear of the walls.
	if not await walk_to(_player, "concourse -> gate Rewind spot", Vector2(250, 126)):
		return
	if not await _use_watch(&"rewind", turnstile, func() -> bool: return not turnstile.passage_blocked, "turnstile opens after Rewind"):
		return
	if not await walk_to(_player, "concourse -> exit_trigger", Vector2(304, 136), _solved(&"CH1-PZ-001")):
		return
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-001"), "PZ-001 SOLVED by walking through")

	# PZ-006: Rewind the dials 3 / 2 / 4 steps (index 5 -> 2 / 3 / 1), then use the validator.
	for row in [[&"dial_line", Vector2(432, 152), 2], [&"dial_platform", Vector2(464, 168), 3],
			[&"dial_time", Vector2(496, 184), 1]]:
		var dial := _resolve(StringName("ch01.concourse_west." + String(row[0]))) as HistoryDial
		if not await walk_to(_player, "concourse -> %s" % row[0], row[1]):
			return
		while dial.index > row[2]:
			var before := dial.index
			if not await _use_watch(&"rewind", dial, func() -> bool: return dial.index == before - 1, "%s steps back" % row[0]):
				return
	var staff_door := _resolve(&"ch01.concourse_west.staff_door") as PoweredDoor
	if not await _use_at(Vector2(496, 200), _resolve(&"ch01.concourse_west.ticket_validator"), "concourse -> ticket_validator"):
		return
	if not _assert_true(await until(_solved(&"CH1-PZ-006"), 10), "PZ-006 SOLVED by the validator"):
		return
	_assert_false(staff_door.passage_blocked, "staff door open")
	if not await walk_to(_player, "concourse -> door_exit_east", Vector2(480, 224), _in_room(&"ch01.maintenance_bay")):
		return
	await physics_frames(2)

	# Checkpoint autosave written to the test root (Lead probe: frame 197)
	var store := _save_service()
	_assert_true(FileAccess.file_exists(TEST_SAVE_ROOT.path_join("slot_%d.json" % _router.autosave_slot)),
		"checkpoint autosave written to the test save root")
	var saved: Dictionary = store.read_slot(_router.autosave_slot)
	_assert_true(saved.get("ok", false), "autosave reads back")
	if saved.get("ok", false):
		_assert_eq(saved["data"].get("checkpoint_id", ""), "ch01.cp.maintenance_bay", "autosave is the bay checkpoint")
		_assert_eq(saved["data"]["puzzles"].get("CH1-PZ-001", ""), "SOLVED", "autosave records PZ-001 SOLVED")

	# 3. Maintenance bay: Trace the technician (Freeze unlocks), stand on the plate, Freeze the hatch
	var hatch := _resolve(&"ch01.maintenance_bay.hatch_01") as PlateLinkedGate
	if not await walk_to(_player, "bay -> technician spot", Vector2(288, 112)):
		return
	if not await _use_watch(&"trace", _resolve(&"ch01.maintenance_bay.n11_hatch_tech"), flag_set.call(&"ch01.npc.n11.traced"), "technician traced"):
		return
	await dismiss_blocking_ui()
	_assert_true(unlocks.is_unlocked(&"freeze"), "Freeze unlocked by the technician")
	if not await walk_to(_player, "bay -> hatch plate", Vector2(256, 128), func() -> bool: return not hatch.passage_blocked):
		return
	if not await _use_watch(&"freeze", hatch, func() -> bool: return hatch.is_frozen(), "hatch frozen open"):
		return
	# Through the hatch straight down at x = 320, clear of the technician's footprint (304,104).
	for point in [Vector2(288, 92), Vector2(320, 92)]:
		if not await walk_to(_player, "bay -> above the hatch", point):
			return
	if not await walk_to(_player, "bay -> through the hatch", Vector2(320, 140), _solved(&"CH1-SO-02")):
		return
	_assert_true(_session.puzzle_service.is_solved(&"CH1-SO-02"), "SO-02 SOLVED by walking through the hatch")

	# PZ-002: Rewind the shutter, Freeze the gear, into the pocket, Rewind the inner shutter
	var shutter := _resolve(&"ch01.maintenance_bay.fire_shutter") as FireShutter
	var gear := _resolve(&"ch01.maintenance_bay.counterweight_gear") as CounterweightGear
	var inner := _resolve(&"ch01.maintenance_bay.inner_shutter") as FireShutter
	_assert_true(shutter.passage_blocked, "shutter starts blocked")
	# (360,124): the gear (26.8 px) is nearer than the latched hatch (41.8 px) for Freeze.
	if not await walk_to(_player, "bay -> within watch range", Vector2(360, 124)):
		return
	if not await _use_watch(&"rewind", shutter, func() -> bool: return not shutter.passage_blocked, "shutter raised after Rewind"):
		return
	if not await _use_watch(&"freeze", gear, func() -> bool: return gear.is_frozen(), "gear frozen"):
		return
	# Straight down through the middle of the shutter gap (dividers end at (396,154) and (372,166)).
	if not await walk_to(_player, "bay -> above the shutter gap", Vector2(384, 146)):
		return
	if not await walk_to(_player, "bay -> through the shutter gap", Vector2(384, 176)):
		return
	if not await walk_to(_player, "bay -> pocket", Vector2(432, 170)):
		return
	if not await _use_watch(&"rewind", inner, func() -> bool: return not inner.passage_blocked, "inner shutter raised after Rewind"):
		return
	if not await walk_to(_player, "bay -> exit_trigger_east_02", Vector2(432, 200), _solved(&"CH1-PZ-002")):
		return
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-002"), "PZ-002 SOLVED behind the inner shutter")
	if not await walk_to(_player, "bay -> door_exit_east", Vector2(464, 200), _in_room(&"ch01.security_crossing")):
		return
	await physics_frames(2)

	# 4. Security crossing: the pedestal (Echo unlocks), the pass, an Echo onto the plate, the reader
	if not await _use_at(Vector2(256, 144), _resolve(&"ch01.security_crossing.echo_recorder_pedestal"), "crossing -> echo pedestal"):
		return
	await dismiss_blocking_ui()
	_assert_true(await until(func() -> bool: return unlocks.is_unlocked(&"echo"), 10), "Echo unlocked by the pedestal")
	# (348,100): the pass (12.6 px) is nearer than the guard statue (23.3 px; a tie at (320,112)).
	if not await _use_at(Vector2(348, 100), _resolve(&"ch01.security_crossing.transit_pass_pickup"), "crossing -> transit pass"):
		return
	_assert_true(await until(flag_set.call(&"ch01.flag.transit_pass"), 10), "transit pass taken")
	var bridge := _resolve(&"ch01.security_crossing.bridge_platform_01") as RetractableBridge
	_assert_false(bridge.walkable, "bridge starts retracted")
	if not await _select(&"echo"):
		return
	var echo := _session.echo_service
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.RECORDING, "watch starts recording")
	if not await walk_to(_player, "crossing -> pressure plate", Vector2(256, 176)):
		return
	await tap(&"watch")
	_assert_eq(echo.state, EchoService.State.READY, "watch stops recording on the plate")
	if not await walk_to(_player, "crossing -> off the plate", Vector2(300, 168)):
		return
	await physics_frames(2)
	_assert_false(bridge.walkable, "bridge retracts when the player leaves the plate")
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return bridge.walkable, 600), "bridge extends while the Echo holds the plate"):
		return
	# Straight down across the bridge gap (trench barriers end at (380,178) and (356,190)).
	if not await walk_to(_player, "crossing -> above the bridge", Vector2(368, 170)):
		return
	if not await walk_to(_player, "crossing -> across the bridge", Vector2(368, 198)):
		return
	var barrier := _resolve(&"ch01.security_crossing.staff_barrier_01") as PoweredDoor
	if not await _use_at(Vector2(400, 200), _resolve(&"ch01.security_crossing.card_reader_01"), "crossing -> card reader"):
		return
	if not _assert_true(await until(func() -> bool: return not barrier.passage_blocked, 10), "staff barrier lifts after the reader"):
		return
	if not await walk_to(_player, "crossing -> above the barrier", Vector2(432, 186)):
		return
	if not await walk_to(_player, "crossing -> exit_trigger_lounge", Vector2(432, 216), _solved(&"CH1-PZ-003")):
		return
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-003"), "PZ-003 SOLVED behind the staff barrier")

	# 5. Door to the waiting lounge
	var door := _resolve(&"ch01.security_crossing.door_exit_east") as DoorwayPresenter
	door.traversed.connect(func(_actor: StringName, destination: Dictionary) -> void: _traversals.append(destination))
	var arrived := func() -> bool: return _router.current_room_id == LOUNGE or not _traversals.is_empty()
	if not await walk_to(_player, "crossing -> door_exit_east", Vector2(464, 232), arrived):
		return
	_assert_false(_traversals.is_empty(), "walking into the east door traverses it")
	if not _traversals.is_empty():
		_assert_eq(StringName(_traversals[0]["room_id"]), LOUNGE, "east door leads to the waiting lounge")
	if _router.has_room(LOUNGE):
		_assert_true(await until(_in_room(LOUNGE), 10), "arrived in the waiting lounge")
	else:
		print("  NOTE: %s has no room scene yet (TLF-025); arrival checked as the door traversal only." % LOUNGE)
