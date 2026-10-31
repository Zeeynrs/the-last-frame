extends "res://tests/support/base_test.gd"

## Real-input Chapter 1 playthrough (TLF-030), replacing the Lead's runtime probe (TLF-009 review).
## Plays Chapter01.tscn with input actions and physics frames only (TLF-029 helpers):
## arrival -> concourse (PZ-001 Rewind) -> maintenance bay (PZ-002 Rewind + Freeze) ->
## security crossing (PZ-003 Echo) -> door to the waiting lounge.
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
	var watch: PocketWatch = _player.pocket_watch

	# 1. Arrival platform -> concourse (Lead probe: frame 50)
	await physics_frames(2)
	_assert_eq(_router.current_room_id, &"ch01.arrival_platform", "starts on the arrival platform")

	# Beat 01 monologue blocks the player at boot (TLF-032): advance it with interact.
	await dismiss_blocking_ui()
	_assert_false(blocking_ui_open(), "Beat 01 monologue dismissed")

	if not await walk_to(_player, "arrival -> door_exit_east", Vector2(448, 208), _in_room(&"ch01.concourse_west")):
		return
	await physics_frames(2)

	# 2. Concourse: Rewind via the watch auto-targets the turnstile (Lead probe: frame 66)
	var gate := _resolve(&"ch01.concourse_west.turnstile_gate") as TurnstileGate
	_assert_true(gate.passage_blocked, "turnstile starts blocked")
	await tap(&"ability_next")
	_assert_eq(watch.selected_ability, &"rewind", "ability_next selects Rewind")
	await physics_frames(1)
	_assert_eq(watch.current_target, gate, "Rewind auto-targets the turnstile")
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return not gate.passage_blocked, 10), "turnstile opens after Rewind"):
		return
	if not await walk_to(_player, "concourse -> exit_trigger", Vector2(304, 136), _solved(&"CH1-PZ-001")):
		return
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-001"), "PZ-001 SOLVED by walking through")
	# Around support_pillar_01 (384,176), which stands on the straight line to the east door.
	if not await walk_to(_player, "concourse -> north of pillar", Vector2(360, 140)):
		return
	if not await walk_to(_player, "concourse -> past pillar", Vector2(440, 180)):
		return
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

	# 3. Maintenance bay: Rewind the shutter, switch to Freeze, the gear is auto-targeted
	var shutter := _resolve(&"ch01.maintenance_bay.fire_shutter") as FireShutter
	var gear := _resolve(&"ch01.maintenance_bay.counterweight_gear") as CounterweightGear
	_assert_true(shutter.passage_blocked, "shutter starts blocked")
	if not await walk_to(_player, "bay -> within watch range", Vector2(340, 128)):
		return
	_assert_eq(watch.current_target, shutter, "Rewind auto-targets the shutter")
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return not shutter.passage_blocked, 10), "shutter raised after Rewind"):
		return
	await tap(&"ability_next")
	_assert_eq(watch.selected_ability, &"freeze", "ability_next selects Freeze")
	await physics_frames(1)
	_assert_eq(watch.current_target, gear, "Freeze auto-targets the gear")
	await tap(&"watch")
	_assert_true(await until(func() -> bool: return gear.is_frozen(), 10), "gear frozen")
	# Straight down through the middle of the shutter gap (dividers end at (396,154) and (372,166)).
	if not await walk_to(_player, "bay -> above the shutter gap", Vector2(384, 146)):
		return
	if not await walk_to(_player, "bay -> through the shutter gap", Vector2(384, 176)):
		return
	if not await walk_to(_player, "bay -> exit_trigger_east", Vector2(416, 176), _solved(&"CH1-PZ-002")):
		return
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-002"), "PZ-002 SOLVED by walking under the shutter")
	if not await walk_to(_player, "bay -> door_exit_east", Vector2(464, 200), _in_room(&"ch01.security_crossing")):
		return
	await physics_frames(2)

	# 4. Security crossing: record an Echo onto the plate, stop on it, walk off, play, cross
	var bridge := _resolve(&"ch01.security_crossing.bridge_platform_01") as RetractableBridge
	_assert_false(bridge.walkable, "bridge starts retracted")
	await tap(&"ability_next")
	_assert_eq(watch.selected_ability, &"echo", "ability_next selects Echo")
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
	if not await walk_to(_player, "crossing -> exit_trigger_lounge", Vector2(432, 216), _solved(&"CH1-PZ-003")):
		return
	_assert_true(_session.puzzle_service.is_solved(&"CH1-PZ-003"), "PZ-003 SOLVED by crossing the bridge")

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
