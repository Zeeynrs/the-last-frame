extends "res://tests/support/base_test.gd"

## Progressive ability unlocks (TLF-050, ADR-020 am., ADR-021 reads them): AbilityUnlocks in the
## session, the pocket watch following it, AbilityUnlockTrigger (flag / pickup / puzzle SOLVED),
## the chapter start config, the ability_locked feedback and save/Continue.
## The SaveService autoload is pointed at a test root for every test (ISSUE-016).

const CH01_SCENE := "res://scenes/chapters/ch01/Chapter01.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_ability_unlock_saves"
const SLOT := 0
const ALL_FOUR: Array[StringName] = [&"trace", &"rewind", &"freeze", &"echo"]

var _store: SaveStore = null
var _original_root: String = ""
var _ch01: Node2D = null
var _session: GameSession = null
var _router: RoomRouter = null
var _player: Player = null


func _init() -> void:
	timeout_frames = 1200


func _remove_root() -> void:
	var dir := DirAccess.open(TEST_SAVE_ROOT)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	if DirAccess.dir_exists_absolute(TEST_SAVE_ROOT):
		DirAccess.remove_absolute(TEST_SAVE_ROOT)


func _begin(starting: Array[StringName] = []) -> void:
	_store = _tree().root.get_node("SaveService") as SaveStore
	_original_root = _store.save_root
	_remove_root()
	_store.save_root = TEST_SAVE_ROOT
	_ch01 = (load(CH01_SCENE) as PackedScene).instantiate() as Node2D
	(_ch01.get_node("GameSession") as GameSession).starting_abilities = starting   # chapter start config
	_tree().root.add_child(_ch01)
	_session = _ch01.get_node("GameSession") as GameSession
	_router = _ch01.get_node("RoomRouter") as RoomRouter
	_player = _ch01.get_node("Player") as Player
	_session.narrative_state.set_flag(&"heard.ch01_b01_start", true)   # setup: no Beat 01 dialogue
	await physics_frames(3)


func _free_chapter() -> void:
	if _ch01 != null:
		if _router.current_room != null:
			_router._unload_current()
		_tree().root.remove_child(_ch01)
		_ch01.free()
		_ch01 = null


func _end() -> void:
	release_all_input()
	_free_chapter()
	_store.save_root = _original_root
	_remove_root()
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root removed")


func _add_to_room(node: Node) -> Node:
	_router.current_room.add_child(node)
	return node


# --- start config ----------------------------------------------------------------------------

func test_default_start_keeps_all_four_abilities() -> void:
	await _begin()
	_assert_eq(_session.ability_unlocks.unlocked(), ALL_FOUR, "AbilityUnlocks: the old flow's four")
	_assert_eq(_player.pocket_watch.unlocked_abilities, ALL_FOUR, "the watch follows it")
	await tap(&"ability_next")
	_assert_eq(_player.pocket_watch.selected_ability, &"rewind", "ability_next reaches Rewind")
	await _end()


func test_trace_only_start_and_locked_feedback() -> void:
	await _begin([&"trace"])
	var watch: PocketWatch = _player.pocket_watch
	_assert_eq(_session.ability_unlocks.unlocked(), [&"trace"], "start config [trace]")
	_assert_eq(watch.unlocked_abilities, [&"trace"], "the watch has Trace only")
	_assert_eq(watch.selected_ability, &"trace", "Trace selected")
	await tap(&"ability_next")
	_assert_eq(watch.selected_ability, &"trace", "ability_next can't reach a locked ability")
	await tap(&"ability_prev")
	_assert_eq(watch.selected_ability, &"trace", "ability_prev neither")

	var refused: Array = []
	watch.ability_selection_refused.connect(func(ability: StringName, reason: StringName) -> void: refused.append([ability, reason]))
	_assert_false(watch.set_selected_ability(&"rewind"), "direct selection of a locked ability refused")
	_assert_eq(refused, [[&"rewind", &"ability_locked"]], "ability_selection_refused(rewind, ability_locked)")
	_assert_eq(watch.selected_ability, &"trace", "selection unchanged")

	# A locked ability that is selected anyway (setup) never reaches the services.
	watch.selected_ability = &"rewind"
	await tap(&"watch")
	_assert_eq(watch.last_result.reason, &"ability_locked", "watch refuses the locked ability")
	var hud = _player.hud
	if _assert_true(hud != null, "HUD present"):
		_assert_true(hud.feedback_panel.visible, "feedback shown")
		_assert_eq(hud.feedback_label.text, tr("UI_FB_ABILITY_LOCKED"), "ability_locked feedback text")
		_assert_false(tr("UI_FB_ABILITY_LOCKED") == "UI_FB_ABILITY_LOCKED", "UI_FB_ABILITY_LOCKED translated")
	await _end()


# --- unlock events -----------------------------------------------------------------------------

func test_unlock_triggers_flag_pickup_and_puzzle_solved() -> void:
	await _begin([&"trace"])
	var watch: PocketWatch = _player.pocket_watch
	var unlocks := _session.ability_unlocks
	var events: Array = []
	unlocks.ability_unlocked.connect(func(ability: StringName) -> void: events.append(ability))

	var pickup := ProgressionPickup.new()
	pickup.name = "test_pass"
	pickup.object_id = &"ch01.arrival_platform.test_pass"
	pickup.flag_id = &"ch01.flag.test_pass_taken"
	_add_to_room(pickup)
	var on_flag := AbilityUnlockTrigger.new()
	on_flag.ability = &"rewind"
	on_flag.on_flag = &"ch01.flag.test_unlock_rewind"
	_add_to_room(on_flag)
	var on_solved := AbilityUnlockTrigger.new()
	on_solved.ability = &"freeze"
	on_solved.on_puzzle_solved = &"CH1-PZ-001"
	_add_to_room(on_solved)
	var on_pickup := AbilityUnlockTrigger.new()
	on_pickup.ability = &"echo"
	on_pickup.on_pickup_id = pickup.object_id
	_add_to_room(on_pickup)
	await physics_frames(2)   # the pickup binding is deferred until the room is complete
	_assert_eq(unlocks.unlocked(), [&"trace"], "nothing unlocked yet")

	_session.narrative_state.set_flag(&"ch01.flag.test_unlock_rewind")
	_assert_true(unlocks.is_unlocked(&"rewind"), "flag -> Rewind unlocked")
	for i in 4:   # auto-selected on unlock (ABILITY_UNLOCKS 3); otherwise reached with ability_next
		if watch.selected_ability == &"rewind":
			break
		await tap(&"ability_next")
	_assert_eq(watch.selected_ability, &"rewind", "the new ability is selectable with real input")

	_session.puzzle_service.mark_solved(&"CH1-PZ-001")
	_assert_true(unlocks.is_unlocked(&"freeze"), "puzzle SOLVED -> Freeze unlocked")

	_assert_true(_session.interaction_service.request(&"player", pickup.object_id, &"use").ok, "pickup collected")
	_assert_true(unlocks.is_unlocked(&"echo"), "pickup -> Echo unlocked")
	_assert_eq(events, [&"rewind", &"freeze", &"echo"], "ability_unlocked once per unlock, in order")
	_assert_eq(watch.unlocked_abilities, ALL_FOUR, "the watch follows every unlock")

	# A condition that already holds when the trigger is ready unlocks at once (e.g. after a load).
	var late := AbilityUnlockTrigger.new()
	late.ability = &"fast_forward"
	late.on_flag = &"ch01.flag.test_unlock_rewind"
	_add_to_room(late)
	_assert_true(unlocks.is_unlocked(&"fast_forward"), "already-true condition fires on ready")
	_assert_false(unlocks.unlock(&"rewind"), "unlocking twice is a no-op")
	_assert_false(unlocks.unlock(&"teleport"), "unknown abilities are refused")
	await _end()


func test_locked_selected_ability_falls_back_when_the_set_shrinks() -> void:
	await _begin()
	var watch: PocketWatch = _player.pocket_watch
	await tap(&"ability_next")
	await tap(&"ability_next")
	_assert_eq(watch.selected_ability, &"freeze", "Freeze selected")
	_session.ability_unlocks.set_unlocked([&"trace", &"rewind"])
	_assert_eq(watch.selected_ability, &"trace", "a no-longer-unlocked selection falls back to the first unlocked")
	await _end()


# --- save / Continue ---------------------------------------------------------------------------

func test_continue_restores_unlocks() -> void:
	await _begin([&"trace"])
	_session.ability_unlocks.unlock(&"freeze")
	_assert_eq(_store.write_slot(SLOT, _router.capture_save("ch01.cp.arrival")), OK, "save written")
	_free_chapter()
	var read := _store.read_slot(SLOT)
	if _assert_true(read.get("ok", false), "save reads back"):
		_assert_eq(read["data"]["unlocked_abilities"], ["trace", "freeze"], "unlocks in the save")

	# Continue through SceneRouter; the scene's own start config (all four) must not win.
	var scene_router := _tree().root.get_node("SceneRouter")
	scene_router.start_chapter(CH01_SCENE, SLOT)
	var ok := await until(func() -> bool:
		var scene := _tree().current_scene
		return scene != null and scene.scene_file_path == CH01_SCENE and scene.is_node_ready(), 30)
	if _assert_true(ok, "Continue loaded Chapter01"):
		var scene := _tree().current_scene
		var watch := (scene.get_node("Player") as Player).pocket_watch
		_assert_eq((scene.get_node("GameSession") as GameSession).ability_unlocks.unlocked(), [&"trace", &"freeze"], "unlocks restored")
		_assert_eq(watch.unlocked_abilities, [&"trace", &"freeze"], "the watch follows the restore")
		await physics_frames(2)
		await tap(&"ability_next")
		_assert_eq(watch.selected_ability, &"freeze", "ability_next goes Trace -> Freeze (Rewind locked)")
	_tree().unload_current_scene()
	await physics_frames(2)
	scene_router.consume_pending_restore()
	await _end()
