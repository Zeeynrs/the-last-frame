extends "res://tests/support/base_test.gd"

## Shared fixture for the TLF-056 real-input Chapter 1 tests (negatives, unlock guards, save/load).
## Boots Chapter01.tscn with the SaveService autoload on a test root (ISSUE-016), applies a setup
## (puzzles marked SOLVED, flags set, the router entering a room) and then drives the game with
## input actions and physics frames only (TLF-029 helpers). Game state is read for assertions.
## Every test calls stop() at the end, which also checks that user://saves was not touched.

const CH01_SCENE_PATH := "res://scenes/chapters/ch01/Chapter01.tscn"
const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"
const BASE_SAVE_ROOT := "user://tlf_test_ch01_ri"

## Unlock flags in play order (ABILITY_UNLOCKS.md 1): Rewind, Freeze, Echo.
const FLAG_REWIND := &"ch01.npc.n05.traced"
const FLAG_FREEZE := &"ch01.npc.n11.traced"
const FLAG_ECHO := &"ch01.flag.echo_pedestal_used"

var ch01: Node2D = null
var session: GameSession = null
var router: RoomRouter = null
var player: Player = null
var store: SaveStore = null
var save_root: String = ""
var failures: Array = []          # [actor_id, target_id, reason, tick] from interaction_failed
var _original_save_root: String = ""
var _real_before: Dictionary = {}


# --- fixture -------------------------------------------------------------------------------

func _real_save_state() -> Dictionary:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	return {"exists": exists, "mtime": FileAccess.get_modified_time(REAL_SAVE_SLOT_0) if exists else 0}


func _remove_save_root() -> void:
	if save_root.is_empty():
		return
	var dir := DirAccess.open(save_root)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	if DirAccess.dir_exists_absolute(save_root):
		DirAccess.remove_absolute(save_root)


## Boots the chapter (new game, Beat 01 dismissed with interact). Setup only: marks `solved`
## SOLVED, sets `flags`, and enters `room_id` through `door_id` unless it is the arrival platform.
func start_at(room_id: StringName, door_id: StringName, solved: Array = [], flags: Array = []) -> bool:
	store = _tree().root.get_node_or_null("SaveService") as SaveStore
	if not _assert_true(store != null, "SaveService autoload is registered"):
		return false
	save_root = "%s_%s" % [BASE_SAVE_ROOT, String(get_script().resource_path.get_file().get_basename())]
	_real_before = _real_save_state()
	_original_save_root = store.save_root
	_remove_save_root()
	store.save_root = save_root
	failures.clear()
	ch01 = (load(CH01_SCENE_PATH) as PackedScene).instantiate() as Node2D
	_tree().root.add_child(ch01)
	session = ch01.get_node("GameSession") as GameSession
	router = ch01.get_node("RoomRouter") as RoomRouter
	player = ch01.get_node("Player") as Player
	session.interaction_service.interaction_failed.connect(
		func(tick: int, actor: StringName, target: StringName, _interaction: StringName, reason: StringName) -> void:
			failures.append([actor, target, reason, tick]))
	walk_context = func() -> String: return String(router.current_room_id)
	await physics_frames(2)
	await dismiss_blocking_ui()
	if not _assert_false(blocking_ui_open(), "Beat 01 monologue dismissed"):
		return false
	for puzzle_id in solved:
		session.puzzle_service.mark_solved(puzzle_id)
	for flag in flags:
		session.narrative_state.set_flag(flag)
	if room_id != router.current_room_id:
		router.enter_room(room_id, door_id)
		await physics_frames(3)
	return _assert_eq(router.current_room_id, room_id, "setup entered %s" % room_id)


func stop() -> void:
	hold_moves([])
	release_all_input()
	if ch01 != null:
		if router != null and router.current_room != null:
			router._unload_current()
		if ch01.get_parent() != null:
			ch01.get_parent().remove_child(ch01)
		ch01.free()
		ch01 = null
	if store != null:
		store.save_root = _original_save_root
	_remove_save_root()
	_assert_false(DirAccess.dir_exists_absolute(save_root), "test save root removed")
	var real_after := _real_save_state()
	_assert_eq(real_after["exists"], _real_before["exists"], "real user://saves slot untouched (existence)")
	_assert_eq(real_after["mtime"], _real_before["mtime"], "real user://saves slot untouched (mtime)")


# --- reading state -------------------------------------------------------------------------

func resolve(id: StringName) -> Node:
	return session.id_registry.resolve(id)


func in_room(room_id: StringName) -> Callable:
	return func() -> bool: return router.current_room_id == room_id


func is_solved(puzzle_id: StringName) -> bool:
	return session.puzzle_service.is_solved(puzzle_id)


func targets(node: Node) -> Callable:
	return func() -> bool: return player.current_target == node


## The last refusal of `target` for `actor` (the player by default), or [].
func last_refusal(target: Node, actor: StringName = &"player") -> Array:
	var last: Array = []
	for f in failures:
		if f[0] == actor and f[1] == target.get("object_id"):
			last = f
	return last


# --- real input ----------------------------------------------------------------------------

## Selects `ability` with ability_next (at most `max_taps`); fails instead of looping when the
## ability is locked (the TLF-049 failure mode).
func select_ability(ability: StringName, max_taps: int = 4) -> bool:
	var watch: PocketWatch = player.pocket_watch
	for i in max_taps:
		if watch.selected_ability == ability:
			break
		await tap(&"ability_next")
	return _assert_eq(watch.selected_ability, ability, "%s selected" % ability)


## Taps the watch on `target` with `ability` selected and waits for `done`.
func use_watch(ability: StringName, target: Node, done: Callable, label: String) -> bool:
	if not await select_ability(ability):
		return false
	await physics_frames(1)
	if not _assert_eq(player.pocket_watch.current_target, target, "%s auto-targets %s" % [ability, target.name]):
		return false
	await tap(&"watch")
	return _assert_true(await until(done, 10), label)


## Walks to a stand spot until `target` is the interact target, then taps interact once.
func use_at(spot: Vector2, target: Node, label: String) -> bool:
	if not await walk_to(player, label, spot, targets(target)):
		return false
	await tap(&"interact")
	return true


## Walks through `points` in order and keeps pushing at the last one until `ticks` physics
## frames have passed, without failing when blocked. Calls `each_frame` every frame; stops early
## when it returns true. Returns the number of frames walked.
func push_for(points: Array, ticks: int, each_frame: Callable = Callable()) -> int:
	var leg := 0
	for frame in ticks:
		if aborted:
			return frame
		if each_frame.is_valid() and each_frame.call():
			hold_moves([])
			return frame
		if leg < points.size() - 1 and player.global_position.distance_to(points[leg]) <= WALK_TOLERANCE:
			leg += 1
		steer(player, points[leg])
		await physics_frames(1)
	hold_moves([])
	return ticks


# --- saves ---------------------------------------------------------------------------------

## Walks out of and back into the room's CheckpointZone (`zone` position) with real input until
## the router reports `checkpoint_id` written OK. `outside` is a free spot outside the zone.
func save_at_checkpoint(checkpoint_id: StringName, zone: Vector2, outside: Vector2) -> bool:
	var written := [false]
	var on_cp := func(id: StringName, error: Error) -> void:
		if id == checkpoint_id and error == OK:
			written[0] = true
	router.checkpoint_reached.connect(on_cp)
	var ok := await walk_to(player, "save: out of the checkpoint", outside)
	if ok:
		ok = await walk_to(player, "save: into the checkpoint", zone, func() -> bool: return written[0])
	router.checkpoint_reached.disconnect(on_cp)
	return _assert_true(ok and written[0], "autosave written at %s" % checkpoint_id)


## The Continue path: reads the autosave slot and restores it through the router.
func continue_from_autosave() -> bool:
	var read: Dictionary = store.read_slot(router.autosave_slot)
	if not _assert_true(read.get("ok", false), "autosave reads back"):
		return false
	var result := router.restore_from_save(read["data"])
	if not _assert_true(result.get("ok", false), "restore_from_save ok (%s)" % result.get("reason", "")):
		return false
	await physics_frames(3)
	return true
