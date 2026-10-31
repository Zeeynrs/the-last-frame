class_name ResetAnchor
extends Interactable

## Puzzle reset console (ADR-016). `use` or `reset` resets its puzzle through PuzzleService.

@export var puzzle_id: StringName = &""


func _can_use(_actor_id: StringName, interaction_id: StringName, _payload: Dictionary) -> StringName:
	if interaction_id != &"use" and interaction_id != &"reset":
		return &"unsupported"
	return &"" if _puzzles() != null else &"missing_target"


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	_puzzles().reset_puzzle(puzzle_id)


func _puzzles() -> PuzzleService:
	var sess := get_session()
	return sess.puzzle_service if sess != null else null
