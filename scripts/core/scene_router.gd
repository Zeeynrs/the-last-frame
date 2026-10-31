extends Node

## SceneRouter autoload (ADR-011 amendment TLF-037): top-level flow Boot -> title -> chapter.
## No class_name: it would hide the autoload name (ADR-011 note TLF-027).
##
## - start_chapter() changes to a chapter scene and remembers the save slot to restore; the
##   chapter calls consume_pending_restore() in its _ready().
## - return_to_title() goes back to the title screen.
## - After a chapter emits `chapter_completed`, `confirm` returns to the title (the chapter
##   scene needs no code for that; the hint is shown here).

signal title_requested()

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const CHAPTER_01_SCENE := "res://scenes/chapters/ch01/Chapter01.tscn"
## Ignore input this long after chapter completion, so the press that ended the outro
## doesn't also leave the complete screen.
const COMPLETE_INPUT_GRACE_MSEC := 600

var _pending_restore: int = -1
var _awaiting_title_confirm: bool = false
var _completed_at_msec: int = 0
var _complete_hint: CanvasLayer = null


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed()


## Loads `scene_path` as the current scene. `restore_slot` >= 0 asks the chapter to restore that
## save slot instead of starting fresh.
func start_chapter(scene_path: String, restore_slot: int = -1) -> Error:
	_pending_restore = restore_slot
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		_pending_restore = -1
		push_error("SceneRouter: cannot load chapter '%s' (error %d)." % [scene_path, error])
	return error


## The slot the current chapter should restore, or -1 for a fresh start. Clears it.
func consume_pending_restore() -> int:
	var slot := _pending_restore
	_pending_restore = -1
	return slot


func has_pending_restore() -> bool:
	return _pending_restore >= 0


func return_to_title() -> Error:
	_pending_restore = -1
	_clear_complete_state()
	title_requested.emit()
	return get_tree().change_scene_to_file(TITLE_SCENE)


func _on_scene_changed() -> void:
	_clear_complete_state()
	var scene := get_tree().current_scene
	if scene != null and scene.has_signal(&"chapter_completed") \
			and not scene.is_connected(&"chapter_completed", _on_chapter_completed):
		scene.connect(&"chapter_completed", _on_chapter_completed)


func _on_chapter_completed() -> void:
	_awaiting_title_confirm = true
	_completed_at_msec = Time.get_ticks_msec()
	_show_complete_hint()


func _unhandled_input(event: InputEvent) -> void:
	if not _awaiting_title_confirm or not event.is_action_pressed(&"confirm"):
		return
	if Time.get_ticks_msec() - _completed_at_msec < COMPLETE_INPUT_GRACE_MSEC:
		return
	get_viewport().set_input_as_handled()
	return_to_title()


func _show_complete_hint() -> void:
	if _complete_hint != null:
		return
	_complete_hint = CanvasLayer.new()
	_complete_hint.name = "ChapterCompleteHint"
	_complete_hint.layer = 101   # above the chapter's complete overlay (layer 100)
	var label := Label.new()
	label.name = "HintLabel"
	label.text = InputPrompts.format_prompt(&"confirm", "UI_CHAPTER_RETURN_TO_TITLE")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_left = -200
	label.offset_right = 200
	label.offset_top = -40
	label.offset_bottom = -20
	_complete_hint.add_child(label)
	add_child(_complete_hint)


func _clear_complete_state() -> void:
	_awaiting_title_confirm = false
	if _complete_hint != null:
		_complete_hint.queue_free()
		_complete_hint = null
