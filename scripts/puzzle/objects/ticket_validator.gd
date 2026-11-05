class_name TicketValidator
extends PuzzleObject

## CH1-PZ-006 validator console. `use` compares its dials' indexes with `target`: a match accepts the
## ticket for good (grid_online for the staff door's PoweredDoor, puzzle SOLVED, journal entry,
## "Ticket accepted." via feedback_requested); anything else is &"invalid_ticket", the same reason for
## every wrong triple, with no lock-out and no hint which dial is wrong.

signal grid_online_changed(online: bool)

@export var dial_ids: Array[StringName] = []
@export var target: PackedInt32Array = PackedInt32Array()
@export var solved_journal_key: String = ""
@export_enum("observation", "fact", "theory") var solved_journal_category: String = "theory"
@export var accepted_text_key: String = "PZ006_OK"

var accepted: bool = false
var grid_online: bool = false


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	if accepted or latched_solved:
		return &"already_open"
	return &"" if ticket_matches() else &"invalid_ticket"


func ticket_matches() -> bool:
	if dial_ids.size() != target.size() or target.is_empty():
		return false
	for i in dial_ids.size():
		var dial := resolve(dial_ids[i]) as HistoryDial
		if dial == null or dial.index != target[i]:
			return false
	return true


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	_accept()
	var puzzles := _puzzles()
	if puzzles != null and not String(puzzle_id).is_empty():
		puzzles.mark_solved(puzzle_id)
	var sess := get_session()
	if sess != null and sess.narrative_state != null and not solved_journal_key.is_empty():
		sess.narrative_state.add_journal_entry(solved_journal_key, solved_journal_category)
	if not accepted_text_key.is_empty():
		feedback_requested.emit(accepted_text_key)


func _default_feedback_keys() -> Dictionary:
	return {&"invalid_ticket": "PZ006_FB_NO_SUCH_TICKET"}


func _accept() -> void:
	if accepted:
		return
	accepted = true
	grid_online = true
	grid_online_changed.emit(true)


func _apply_solved_state() -> void:
	_accept()


func _reset_unsolved() -> void:
	pass  # an accepted ticket stays accepted; before that there is nothing to reset
