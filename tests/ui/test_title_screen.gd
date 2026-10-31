extends "res://tests/support/base_test.gd"

## Title screen -> Chapter 1 (TLF-037): Continue gating, real-input menu navigation, New Game,
## Continue restore, broken save. The SaveService autoload is pointed at a test root for every
## test (ISSUE-016; TLF-036 already keeps headless runs off the real saves).

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const CH01_SCENE := "res://scenes/chapters/ch01/Chapter01.tscn"
const TEST_SAVE_ROOT := "user://tlf_test_title_saves"
const SLOT := 0

var _store: SaveStore = null
var _original_root: String = ""


func _init() -> void:
	timeout_frames = 1200


func _begin() -> void:
	_store = _tree().root.get_node("SaveService") as SaveStore
	_original_root = _store.save_root
	_store.save_root = TEST_SAVE_ROOT
	_remove_test_root()


func _end() -> void:
	release_all_input()
	_tree().unload_current_scene()
	await physics_frames(2)
	var router := _tree().root.get_node_or_null("SceneRouter")
	if router != null:
		router.consume_pending_restore()
	_store.save_root = _original_root
	_remove_test_root()
	_assert_false(DirAccess.dir_exists_absolute(TEST_SAVE_ROOT), "test save root removed")


func _remove_test_root() -> void:
	var dir := DirAccess.open(TEST_SAVE_ROOT)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	if DirAccess.dir_exists_absolute(TEST_SAVE_ROOT):
		DirAccess.remove_absolute(TEST_SAVE_ROOT)


func _open_title():
	_tree().change_scene_to_file(TITLE_SCENE)
	await until(func() -> bool: return _current_path() == TITLE_SCENE, 10)
	await physics_frames(1)
	return _tree().current_scene


func _current_path() -> String:
	var scene := _tree().current_scene
	return scene.scene_file_path if scene != null else ""


func _await_chapter() -> Node:
	var ok := await until(func() -> bool:
		var scene := _tree().current_scene
		return scene != null and scene.scene_file_path == CH01_SCENE and scene.is_node_ready(), 30)
	_assert_true(ok, "Chapter01 became the current scene (current: '%s')" % _current_path())
	await physics_frames(2)
	return _tree().current_scene if ok else null


## A real save at the signal_control checkpoint: PZ-001..003 SOLVED, Beat 01 heard (setup only).
func _write_signal_control_save() -> void:
	var ch01 := (load(CH01_SCENE) as PackedScene).instantiate()
	_tree().root.add_child(ch01)
	var session := ch01.get_node("GameSession") as GameSession
	var router := ch01.get_node("RoomRouter") as RoomRouter
	for puzzle_id in [&"CH1-PZ-001", &"CH1-PZ-002", &"CH1-PZ-003"]:
		session.puzzle_service.mark_solved(puzzle_id)
	session.narrative_state.set_flag(&"heard.ch01_b01_start", true)
	router.enter_room(&"ch01.signal_control", &"door_entry_south")
	_store.write_slot(SLOT, router.capture_save("ch01.cp.signal_control"))
	router._unload_current()
	_tree().root.remove_child(ch01)
	ch01.free()


# --- tests ---------------------------------------------------------------------------------

func test_continue_disabled_without_a_save() -> void:
	_begin()
	var title = await _open_title()
	_assert_false(title.continue_enabled, "Continue disabled without slot 0")
	_assert_eq(title.selected_item(), &"new_game", "New Game selected by default")
	await tap(&"move_down")
	_assert_eq(title.selected_item(), &"quit", "move_down skips the disabled Continue")
	await tap(&"move_up")
	_assert_eq(title.selected_item(), &"new_game", "move_up skips it too")
	await _end()


func test_continue_enabled_with_a_save_and_menu_navigation() -> void:
	_begin()
	_store.write_slot(SLOT, SaveStore.default_save())
	var title = await _open_title()
	_assert_true(title.continue_enabled, "Continue enabled with slot 0")
	_assert_eq(title.selected_item(), &"continue", "Continue selected by default when a save exists")
	await tap(&"move_down")
	_assert_eq(title.selected_item(), &"quit", "move_down -> Quit")
	await tap(&"move_down")
	_assert_eq(title.selected_item(), &"new_game", "wraps to New Game")
	await tap(&"move_up")
	_assert_eq(title.selected_item(), &"quit", "move_up wraps back to Quit")
	await _end()


func test_title_text_is_translated_ascii() -> void:
	_begin()
	var title = await _open_title()
	var labels: Array[Label] = [title.title_label, title.hint_label,
		title.get_node("Menu/NewGame"), title.get_node("Menu/Continue"), title.get_node("Menu/Quit")]
	for label in labels:
		_assert_false(label.text.contains("UI_"), "%s is translated ('%s')" % [label.name, label.text])
		_assert_true(label.text.to_ascii_buffer().get_string_from_ascii() == label.text and
			not label.text.is_empty(), "%s is non-empty ASCII" % label.name)
	_assert_eq(title.title_label.text, "THE LAST FRAME", "UI_TITLE_GAME")
	for key in ["UI_TITLE_OVERWRITE_CONFIRM", "UI_FB_RESTORE_FAILED", "UI_CHAPTER_RETURN_TO_TITLE"]:
		var text := tr(key)
		_assert_ne_key(text, key)
		_assert_true(text.to_ascii_buffer().get_string_from_ascii() == text, "%s is ASCII" % key)
	await _end()


func _assert_ne_key(text: String, key: String) -> void:
	_assert_false(text == key, "%s has a translation" % key)


func test_new_game_starts_chapter_1_in_the_arrival_platform() -> void:
	_begin()
	var title = await _open_title()
	await tap(&"confirm")
	var ch01 := await _await_chapter()
	if ch01 != null:
		var router := ch01.get_node("RoomRouter") as RoomRouter
		_assert_eq(router.current_room_id, &"ch01.arrival_platform", "New Game starts in the arrival platform")
		_assert_false((ch01.get_node("GameSession") as GameSession).puzzle_service.is_solved(&"CH1-PZ-001"), "fresh puzzles")
	await _end()


func test_new_game_with_a_save_asks_once() -> void:
	_begin()
	_store.write_slot(SLOT, SaveStore.default_save())
	var before := FileAccess.get_file_as_string(_store.slot_path(SLOT))
	var title = await _open_title()
	await tap(&"move_up")
	_assert_eq(title.selected_item(), &"new_game", "New Game selected")
	await tap(&"interact")
	_assert_eq(_current_path(), TITLE_SCENE, "first confirm stays on the title")
	_assert_eq(title.message_label.text, tr("UI_TITLE_OVERWRITE_CONFIRM"), "overwrite confirmation shown")
	_assert_eq(FileAccess.get_file_as_string(_store.slot_path(SLOT)), before, "the save is not touched by the question")
	await tap(&"interact")
	var ch01 := await _await_chapter()
	if ch01 != null:
		_assert_eq((ch01.get_node("RoomRouter") as RoomRouter).current_room_id, &"ch01.arrival_platform", "second confirm starts a new game")
	await _end()


func test_continue_restores_the_signal_control_checkpoint() -> void:
	_begin()
	_write_signal_control_save()
	var title = await _open_title()
	_assert_eq(title.selected_item(), &"continue", "Continue selected")
	await tap(&"confirm")
	var ch01 := await _await_chapter()
	if ch01 != null:
		var session := ch01.get_node("GameSession") as GameSession
		var router := ch01.get_node("RoomRouter") as RoomRouter
		_assert_eq(router.current_room_id, &"ch01.signal_control", "Continue -> signal_control")
		_assert_eq(router.last_checkpoint_id, &"ch01.cp.signal_control", "at the saved checkpoint")
		for puzzle_id in [&"CH1-PZ-001", &"CH1-PZ-002", &"CH1-PZ-003"]:
			_assert_true(session.puzzle_service.is_solved(puzzle_id), "%s SOLVED after restore" % puzzle_id)
		_assert_true(session.narrative_state.get_flag(&"heard.ch01_b01_start"), "heard.* flags restored")
		# Beat 01 may be blocking or not (TLF-038); either way its sequence must not start again.
		await physics_frames(5)
		var diag := _tree().root.find_child("DialogueBox", true, false) as DialogueBox
		_assert_false(diag != null and diag.current_sequence_id == &"ch01_b01_start", "no Beat 01 replay after Continue")
		var player := ch01.get_node("Player") as Node2D
		var anchor := session.id_registry.resolve(&"ch01.signal_control.safe_anchor_center") as Node2D
		_assert_true(player.global_position.distance_to(anchor.global_position) < 2.0,
			"player at the checkpoint's spawn anchor (%s)" % player.global_position)
	await _end()


func test_broken_save_starts_fresh_with_feedback() -> void:
	_begin()
	DirAccess.make_dir_recursive_absolute(TEST_SAVE_ROOT)
	var file := FileAccess.open(_store.slot_path(SLOT), FileAccess.WRITE)
	file.store_string("{ this is not a save")
	file.close()
	var title = await _open_title()
	_assert_true(title.continue_enabled, "a broken slot file still offers Continue")
	await tap(&"confirm")
	var ch01 := await _await_chapter()
	if ch01 != null:
		_assert_eq((ch01.get_node("RoomRouter") as RoomRouter).current_room_id, &"ch01.arrival_platform", "fresh start")
		var hud = ch01.get_node("Player").get("hud")
		if _assert_true(hud != null, "HUD present"):
			_assert_true(hud.feedback_panel.visible, "feedback shown")
			_assert_eq(hud.feedback_label.text, tr("UI_FB_RESTORE_FAILED"), "restore-failed message")
	await _end()
