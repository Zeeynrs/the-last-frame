class_name ResetAnchor
extends Interactable

## Puzzle reset console (ADR-016). `use` or `reset` resets its puzzle through PuzzleService.

@export var puzzle_id: StringName = &""
## Step 1 consoles (TLF-054): refuse with &"already_open" once the puzzle is SOLVED. Default off:
## a reset after SOLVED is allowed and never re-blocks the passage (ADR-016).
@export var refuse_when_solved: bool = false


func _can_use(_actor_id: StringName, interaction_id: StringName, _payload: Dictionary) -> StringName:
	if interaction_id != &"use" and interaction_id != &"reset":
		return &"unsupported"
	var puzzles := _puzzles()
	if puzzles == null:
		return &"missing_target"
	return &"already_open" if refuse_when_solved and puzzles.is_solved(puzzle_id) else &""


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	_puzzles().reset_puzzle(puzzle_id)


func _puzzles() -> PuzzleService:
	var sess := get_session()
	return sess.puzzle_service if sess != null else null
