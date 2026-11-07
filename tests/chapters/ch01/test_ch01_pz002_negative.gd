extends "res://tests/support/base_test.gd"

## TLF-049: real-input negative check for CH1-PZ-002 (RISK-018 class, CH01_EXPANSION.md 0.11).
## Rewind raises the fire shutter for its hold window (180 ticks, 300 with the timing assist);
## only a frozen counterweight gear keeps it up. Without Freeze the player must not reach
## exit_trigger_east (PZ-002 SOLVED) nor leave the bay east before it closes.
##
## Fastest attempt a player can make: Rewind from just above the shutter gap, then walk the
## TLF-030 playthrough's collision-free line through the gap to the exit trigger and the east door
## without stopping. Input actions and physics frames only (TLF-029 helpers).
##
## Start state (setup, not gameplay): Chapter01.tscn boots, PZ-001 is marked SOLVED and the router
## enters the maintenance bay through its west door. The SaveService autoload uses a test root.

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_ch01_pz002neg_saves"
const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"
const BAY := &"ch01.maintenance_bay"
const CROSSING := &"ch01.security_crossing"
const PZ002 := &"CH1-PZ-002"

## Rewind spot: above the gap, inside watch range of the shutter (384,160).
const REWIND_SPOT := Vector2(384, 146)
## TLF-030 line: through the gap (dividers end at (396,154) and (372,166)), exit trigger, east door.
const ROUTE: Array[Vector2] = [Vector2(384, 176), Vector2(416, 176), Vector2(464, 200)]

var _ch01: Node2D = null
var _session: GameSession = null
var _router: RoomRouter = null
var _player: Player = null
var _store: SaveStore = null
var _settings: Node = null
var _original_save_root: String = ""
var _original_assist: bool = false
var _real_before: Dictionary = {}


func _init() -> void:
	timeout_frames = 2400


func _resolve(id: StringName) -> Node:
	return _session.id_registry.resolve(id)


func _real_save_state() -> Dictionary:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	return {"exists": exists, "mtime": FileAccess.get_modified_time(REAL_SAVE_SLOT_0) if exists else 0}


func _remove_test_save_root() -> void:
	var dir := DirAccess.open(TEST_SAVE_ROOT)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	if DirAccess.dir_exists_absolute(TEST_SAVE_ROOT):
		DirAccess.remove_absolute(TEST_SAVE_ROOT)


func _start(assist: bool) -> bool:
	_store = _tree().root.get_node_or_null("SaveService") as SaveStore
	_settings = _tree().root.get_node_or_null("Settings")
	if not (_assert_true(_store != null, "SaveService autoload") and _assert_true(_settings != null, "Settings autoload")):
		return false
	_real_before = _real_save_state()
	_original_save_root = _store.save_root
	_remove_test_save_root()
	_store.save_root = TEST_SAVE_ROOT
	# In memory only: the assist setter does not write settings.cfg.
	_original_assist = _settings.assist_extended_timing
	_settings.assist_extended_timing = assist
	_ch01 = (load(CH01_SCENE_PATH) as PackedScene).instantiate() as Node2D
	_tree().root.add_child(_ch01)
	_session = _ch01.get_node("GameSession") as GameSession
	_router = _ch01.get_node("RoomRouter") as RoomRouter
	_player = _ch01.get_node("Player") as Player
	walk_context = func() -> String: return String(_router.current_room_id)
	await physics_frames(2)
	await dismiss_blocking_ui()
	_session.puzzle_service.mark_solved(&"CH1-PZ-001")
	# Step 1 layout (TLF-055, Lead-approved setup change): a new game has only Trace and the bay
	# has the SO-02 bulkhead. Set the courier and technician flags (the chapter's unlock triggers
	# give Rewind and Freeze; Freeze stays unused), latch SO-02 so the hatch is open, then walk
	# through the hatch to the east side of the bulkhead. The checks below are unchanged.
	_session.narrative_state.set_flag(&"ch01.npc.n05.traced")
	_session.narrative_state.set_flag(&"ch01.npc.n11.traced")
	_session.puzzle_service.mark_solved(&"CH1-SO-02")
	_router.enter_room(BAY, &"door_entry_west")
	await physics_frames(3)
	if not _assert_eq(_router.current_room_id, BAY, "setup entered the maintenance bay"):
		return false
	if not (_assert_true(_session.ability_unlocks.is_unlocked(&"rewind"), "setup: Rewind unlocked")
			and _assert_true(_session.ability_unlocks.is_unlocked(&"freeze"), "setup: Freeze unlocked")):
		return false
	# Through the 1.5-tile hatch aperture straight down at x = 320-321, above N-11's footprint
	# (304,104) (checked against the TLF-055 colliders in TLF-056).
	var hatch_walk: Array[Vector2] = [Vector2(288, 92), Vector2(320, 92), Vector2(321, 140)]
	for point in hatch_walk:
		if not await walk_to(_player, "setup: bay -> through the hatch", point):
			return false
	return true


func _stop() -> void:
	hold_moves([])
	if _ch01 != null:
		if _router != null and _router.current_room != null:
			_router._unload_current()
		if _ch01.get_parent() != null:
			_ch01.get_parent().remove_child(_ch01)
		_ch01.free()
		_ch01 = null
	if _settings != null:
		_settings.assist_extended_timing = _original_assist
	if _store != null:
		_store.save_root = _original_save_root
	_remove_test_save_root()
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root removed")
	var real_after := _real_save_state()
	_assert_eq(real_after["exists"], _real_before["exists"], "real user://saves slot untouched (existence)")
	_assert_eq(real_after["mtime"], _real_before["mtime"], "real user://saves slot untouched (mtime)")


func test_pz002_cannot_be_solved_without_freeze_assist_off() -> void:
	await _run_without_freeze(false)


func test_pz002_cannot_be_solved_without_freeze_assist_on() -> void:
	await _run_without_freeze(true)


func _run_without_freeze(assist: bool) -> void:
	var label := "assist %s" % ("on" if assist else "off")
	if not await _start(assist):
		_stop()
		return
	var watch: PocketWatch = _player.pocket_watch
	var shutter := _resolve(&"ch01.maintenance_bay.fire_shutter") as FireShutter
	var gear := _resolve(&"ch01.maintenance_bay.counterweight_gear") as CounterweightGear
	var clock := _session.sim_clock
	if not await walk_to(_player, "bay -> above the shutter gap", REWIND_SPOT):
		_stop()
		return
	while watch.selected_ability != &"rewind":
		await tap(&"ability_next")
	_assert_eq(watch.current_target, shutter, "Rewind auto-targets the shutter from %s" % _player.global_position)
	var rewind_pos := _player.global_position
	var raise := {"tick": -1, "hold": -1}
	shutter.get_temporal().rewound.connect(func(_cursor: int) -> void:
		raise["tick"] = clock.tick
		raise["hold"] = shutter.hold_ticks, CONNECT_ONE_SHOT)
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return shutter.shutter_state == &"raised", 10), "shutter raised by Rewind"):
		_stop()
		return
	var raised_tick: int = raise["tick"]
	var window: int = raise["hold"]
	_assert_eq(window, 300 if assist else 180, "%s: hold window right after the Rewind" % label)
	_assert_false(gear.is_frozen(), "gear never frozen")

	# Walk the line without stopping; log when the gap is passed, the trigger hit, the shutter closes.
	var through_tick := -1
	var through_pos := Vector2.ZERO
	var solved_tick := -1
	var closed_tick := -1
	var left_tick := -1
	var leg := 0
	for frame in 900:
		if aborted:
			break
		if _router.current_room_id != BAY or not is_instance_valid(shutter):
			left_tick = clock.tick   # the bay was unloaded: the player went through the east door
			break
		if through_tick < 0 and _player.global_position.y > 166.0:
			through_tick = clock.tick
			through_pos = _player.global_position
		if solved_tick < 0 and _session.puzzle_service.is_solved(PZ002):
			solved_tick = clock.tick
		if closed_tick < 0 and shutter.shutter_state == &"closed":
			closed_tick = clock.tick
		if leg < ROUTE.size() and _player.global_position.distance_to(ROUTE[leg]) <= WALK_TOLERANCE:
			leg += 1
		if leg >= ROUTE.size() or (closed_tick >= 0 and through_tick < 0 and clock.tick - closed_tick > 30):
			break   # route done, or the shutter closed in front of the player
		steer(_player, ROUTE[mini(leg, ROUTE.size() - 1)])
		await physics_frames(1)
	hold_moves([])
	await physics_frames(3)

	var fmt := func(t: int) -> String: return "never" if t < 0 else "%d ticks" % (t - raised_tick)
	print("  INFO: PZ-002 no-Freeze run (%s, window %d ticks): Rewind from %s; gap passed after %s at %s; exit trigger (SOLVED) after %s; shutter closed after %s; left east after %s; player now %s in %s" % [
		label, window, rewind_pos, fmt.call(through_tick), through_pos, fmt.call(solved_tick),
		fmt.call(closed_tick), fmt.call(left_tick), _player.global_position, _router.current_room_id])
	if solved_tick >= 0:
		print("  INFO: PZ-002 no-Freeze run (%s): SOLVED with %d of %d ticks to spare" % [label, window - (solved_tick - raised_tick), window])
	_assert_false(_session.puzzle_service.is_solved(PZ002),
		"%s: PZ-002 must not be SOLVED without Freeze (exit trigger reached %s after the Rewind, window %d)" % [label, fmt.call(solved_tick), window])
	_assert_ne(_router.current_room_id, CROSSING, "%s: the bay must not be left east without Freeze" % label)
	_stop()


func _assert_ne(actual, expected, msg: String) -> bool:
	return assert_helper.assert_ne(actual, expected, msg)
