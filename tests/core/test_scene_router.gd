extends "res://tests/support/base_test.gd"

## SceneRouter autoload + Boot (TLF-037). Scene changes run on the real SceneTree; every test
## unloads the current scene again.

const BOOT_SCENE := "res://scenes/boot/Boot.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
## Frame budget for Boot to reach the title screen.
const BOOT_FRAMES := 10


func _router() -> Node:
	return _tree().root.get_node_or_null("SceneRouter")


func _current_path() -> String:
	var scene := _tree().current_scene
	return scene.scene_file_path if scene != null else ""


func _unload() -> void:
	_tree().unload_current_scene()
	await physics_frames(2)
	if _router() != null:
		_router().consume_pending_restore()


func test_router_is_an_autoload_without_class_name() -> void:
	var router := _router()
	if not _assert_true(router != null, "SceneRouter autoload exists"):
		return
	_assert_eq((router.get_script() as GDScript).get_global_name(), &"", "SceneRouter script has no class_name")
	_assert_eq(router.consume_pending_restore(), -1, "no pending restore by default")


func test_boot_routes_to_the_title_screen() -> void:
	_tree().change_scene_to_file(BOOT_SCENE)
	var reached := await until(func() -> bool: return _current_path() == TITLE_SCENE, BOOT_FRAMES)
	_assert_true(reached, "Boot -> title screen within %d frames (current: '%s')" % [BOOT_FRAMES, _current_path()])
	await _unload()


func test_start_chapter_remembers_the_restore_slot_once() -> void:
	var router := _router()
	_assert_eq(router.start_chapter(TITLE_SCENE, 2), OK, "start_chapter loads the scene")
	_assert_true(router.has_pending_restore(), "restore slot pending")
	_assert_eq(router.consume_pending_restore(), 2, "consume returns the slot")
	_assert_eq(router.consume_pending_restore(), -1, "and clears it")
	await physics_frames(2)
	_assert_eq(_current_path(), TITLE_SCENE, "scene changed")
	await _unload()


func test_confirm_after_chapter_complete_returns_to_title() -> void:
	# Stand-in chapter: any current scene with a chapter_completed signal.
	var script := GDScript.new()
	script.source_code = "extends Node\nsignal chapter_completed()\n"
	script.reload()
	var chapter := Node.new()
	chapter.set_script(script)
	chapter.name = "StandInChapter"
	_tree().change_scene_to_node(chapter)
	await physics_frames(2)
	_assert_eq(_tree().current_scene, chapter, "stand-in chapter is the current scene")
	chapter.emit_signal(&"chapter_completed")
	var hint := _router().get_node_or_null("ChapterCompleteHint/HintLabel") as Label
	if _assert_true(hint != null, "return-to-title hint shown"):
		_assert_true(hint.text.ends_with(tr("UI_CHAPTER_RETURN_TO_TITLE")), "hint text: '%s'" % hint.text)
	await tap(&"confirm")   # inside the grace period: ignored
	_assert_eq(_tree().current_scene, chapter, "a confirm right after completion is ignored")
	await until(func() -> bool: return false, 45)   # let the grace period pass
	await tap(&"confirm")
	var back := await until(func() -> bool: return _current_path() == TITLE_SCENE, 10)
	_assert_true(back, "confirm on the complete screen returns to the title")
	await _unload()
