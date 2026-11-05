class_name SelectorSwitch
extends PuzzleObject

## CH1-SO-01 release-panel selector (LINE / PLATFORM / CAR): `use` steps `selector_position` forward
## modulo `count` (the spec calls it `position`, which Node2D already owns). A selector never fails
## until its puzzle is solved, then answers &"already_open".
## No temporal component: every watch ability is unsupported. The position is panel state only
## (not saved; a reload starts at 0, which costs the player nothing).

signal changed(selector_position: int)

@export var count: int = 3
## One text key per position (e.g. SO001_LINE_0..2); the shape glyph is the presenter's job.
@export var label_keys: PackedStringArray = PackedStringArray()

var selector_position: int = 0


func label_key() -> String:
	return label_keys[selector_position] if selector_position < label_keys.size() else ""


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"already_open" if latched_solved else &""


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	selector_position = (selector_position + 1) % maxi(count, 1)
	changed.emit(selector_position)


func _reset_unsolved() -> void:
	pass  # nothing to undo: the player just turns the selector again
