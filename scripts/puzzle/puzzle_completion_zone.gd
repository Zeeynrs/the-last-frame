class_name PuzzleCompletionZone
extends TriggerZone

## Completion trigger (ADR-016): marks its puzzle SOLVED when the player enters. Echoes are ignored.

@export var puzzle_id: StringName = &""


func _ready() -> void:
	accepts_echoes = false
	super._ready()
	var puzzles := _puzzles()
	if puzzles != null and not String(puzzle_id).is_empty():
		puzzles.register_puzzle(puzzle_id)


func on_trigger_enter(actor_id: StringName) -> void:
	super.on_trigger_enter(actor_id)
	if actor_id != &"player" or String(puzzle_id).is_empty():
		return
	var puzzles := _puzzles()
	if puzzles != null:
		puzzles.mark_solved(puzzle_id)


func _puzzles() -> PuzzleService:
	var sess := get_session()
	return sess.puzzle_service if sess != null else null
