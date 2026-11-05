class_name PuzzleCompletionZone
extends TriggerZone

## Completion trigger (ADR-016): marks its puzzle SOLVED when the player enters. Echoes are ignored.

@export var puzzle_id: StringName = &""
## Journal entry added when this zone solves the puzzle (optional, e.g. JRN_SO002_SOLVED).
@export var solved_journal_key: String = ""
@export_enum("observation", "fact", "theory") var solved_journal_category: String = "fact"


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
	if puzzles != null and puzzles.mark_solved(puzzle_id) and not solved_journal_key.is_empty():
		var sess := get_session()
		if sess != null and sess.narrative_state != null:
			sess.narrative_state.add_journal_entry(solved_journal_key, solved_journal_category)


func _puzzles() -> PuzzleService:
	var sess := get_session()
	return sess.puzzle_service if sess != null else null
