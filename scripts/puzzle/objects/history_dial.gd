class_name HistoryDial
extends PuzzleObject

## CH1-PZ-006 ticket-machine dial: REWIND only, multi-entry history. Its TemporalComponent carries
## the dial's past as initial_history ([{"index": 0} … {"index": 4}], oldest first) and tick 0 is the
## newest entry (index 5), so each Rewind steps one entry back and index 0 answers &"no_history".
## It cannot be turned by hand (&"jammed"). After SOLVED it keeps its index and refuses Rewind with
## &"already_open". Reset (unsolved) restores index 5 and the full history (TemporalComponent).

signal index_changed(index: int)

## One text key per history entry (e.g. PZ006_LINE_0..5); the glyph is the presenter's job.
@export var label_keys: PackedStringArray = PackedStringArray()

var index: int = 5


func capture_state() -> Dictionary:
	return {"index": index}


func apply_state(state: Dictionary) -> void:
	index = int(state["index"])
	index_changed.emit(index)


func label_key() -> String:
	return label_keys[index] if index >= 0 and index < label_keys.size() else ""


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"jammed"


func _can_use_ability(_actor_id: StringName, _ability_id: StringName, _payload: Dictionary) -> StringName:
	return &"already_open" if latched_solved else &""


func _default_feedback_keys() -> Dictionary:
	return {&"jammed": "PZ006_FB_DIAL_JAMMED"}


func _apply_solved_state() -> void:
	pass  # the dials stay where the player left them
