class_name SignalControlIntercom
extends Interactable

## Intercom in Signal Control (TLF-025).
## Plays Operator warning (OP_B07_01 / OP_B07_02) and adds JRN_CH1_OPERATOR_WARNING (theory)
## when PZ-004 is solved.

signal warning_played()

var warning_given: bool = false


func _ready() -> void:
	super._ready()
	var sess := get_session()
	if sess != null and sess.puzzle_service != null:
		sess.puzzle_service.puzzle_solved.connect(_on_puzzle_solved)
		if sess.puzzle_service.is_solved(&"CH1-PZ-004"):
			trigger_warning()


func _on_puzzle_solved(puzzle_id: StringName, _tick: int = 0) -> void:
	if puzzle_id == &"CH1-PZ-004":
		trigger_warning()


func trigger_warning() -> void:
	if warning_given:
		return
	warning_given = true
	var sess := get_session()
	if sess != null and sess.narrative_state != null:
		sess.narrative_state.add_journal_entry("JRN_CH1_OPERATOR_WARNING", "theory")
		sess.narrative_state.set_flag(&"ch01.flag.operator_substation_warn", true)
	warning_played.emit()


func _can_use(_actor_id: StringName, interaction_id: StringName, _payload: Dictionary) -> StringName:
	if interaction_id != &"use":
		return &"unsupported"
	return &""


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	trigger_warning()
