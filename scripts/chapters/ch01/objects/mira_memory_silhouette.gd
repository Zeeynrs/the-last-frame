class_name MiraMemorySilhouette
extends Interactable

## MiraMemorySilhouette (TLF-076 / ADR-025 V6)
## Frozen silhouette placeholder marker at x=780 on the floor line.
## Trace target once: collects fragment `ch01.fragment.mira_departure` if not already owned.
## Stays used for the visit; no movement, dialogue, or present-day encounter.

const FRAGMENT_ID := &"ch01.fragment.mira_departure"

var _traced_used: bool = false


func _can_use_ability(_actor_id: StringName, ability_id: StringName, _payload: Dictionary) -> StringName:
	if traceable and ability_id == ABILITY_TRACE:
		return &""
	return &"unsupported"


func _on_traced(_actor_id: StringName) -> void:
	if not traceable or _traced_used:
		return
	_traced_used = true
	var sess := get_session()
	if sess == null:
		sess = _find_session_in_tree()
	if sess != null and sess.narrative_state != null:
		if not sess.narrative_state.has_fragment(FRAGMENT_ID):
			sess.narrative_state.collect_fragment(FRAGMENT_ID)


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"


func _find_session_in_tree() -> GameSession:
	if not is_inside_tree():
		return null
	var s := get_tree().get_first_node_in_group(&"game_session")
	if s is GameSession:
		return s
	return get_tree().root.find_child("GameSession", true, false) as GameSession
