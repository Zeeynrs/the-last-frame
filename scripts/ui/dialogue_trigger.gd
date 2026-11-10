class_name DialogueTrigger
extends Interactable

## Scene-side dialogue trigger per TLF-032.
## Can act as an Interactable (responding to 'use' or 'trace') or be fired directly via trigger().
## Supports exported sequence_id, lines ([speaker, text]), journal recording, and flags.

signal triggered(sequence_id: StringName)

@export var sequence_id: StringName = &""
@export var lines: Array = []
@export var is_blocking: bool = false
@export var auto_advance_delay: float = 0.0
@export var journal_key: String = ""
@export_enum("observation", "fact", "theory") var journal_category: String = "observation"
@export var flag_id: StringName = &""
@export var one_shot: bool = true


func _can_use(_actor_id: StringName, interaction_id: StringName, _payload: Dictionary) -> StringName:
	if interaction_id != &"use":
		return &"unsupported"
	if one_shot and _is_already_triggered():
		return &"unsupported"
	return &""


func _is_already_triggered() -> bool:
	var sess := get_session()
	if sess == null:
		sess = _find_session_in_tree()
	if sess != null and sess.narrative_state != null:
		if sequence_id != &"" and sess.narrative_state.get_flag(StringName("heard." + String(sequence_id)), false):
			return true
		if flag_id != &"" and sess.narrative_state.get_flag(flag_id, false):
			return true
	return false


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	trigger()


func _can_watch(_actor_id: StringName, ability: StringName, _payload: Dictionary) -> StringName:
	if traceable and ability == &"trace":
		return &""
	return &"unsupported"


func _on_watch(_actor_id: StringName, ability: StringName, _payload: Dictionary) -> void:
	if traceable and ability == &"trace":
		traced.emit(0)
		trigger()


func _on_traced(_actor_id: StringName) -> void:
	if traceable:
		trigger()


func trigger() -> bool:
	var sess := get_session()
	if sess == null:
		sess = _find_session_in_tree()

	if one_shot and sequence_id != &"" and sess != null and sess.narrative_state != null:
		if sess.narrative_state.get_flag(StringName("heard." + String(sequence_id)), false):
			return false

	var diag_box := _find_dialogue_box()
	if diag_box != null:
		diag_box.play_sequence(sequence_id, lines, is_blocking, auto_advance_delay, one_shot)

	if sess != null and sess.narrative_state != null:
		if journal_key != "":
			sess.narrative_state.add_journal_entry(journal_key, journal_category)
		if flag_id != &"":
			sess.narrative_state.set_flag(flag_id, true)

	triggered.emit(sequence_id)
	return true


func _find_dialogue_box() -> DialogueBox:
	if not is_inside_tree():
		return null
	var candidate = get_tree().root.find_child("DialogueBox", true, false)
	if candidate is DialogueBox:
		return candidate
	return null


func _find_session_in_tree() -> GameSession:
	if not is_inside_tree():
		return null
	var s = get_tree().get_first_node_in_group(&"game_session")
	if s is GameSession:
		return s
	return get_tree().root.find_child("GameSession", true, false) as GameSession
