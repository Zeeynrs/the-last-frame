class_name ProgressionPickup
extends Interactable

## Permanent pickup (keycard, transit pass). Progression object: echoes are refused (ADR-006).
## Collecting sets `flag_id` in NarrativeState; that flag is also how the pickup knows it was taken.

signal collected_changed(collected: bool)

@export var flag_id: StringName = &""


func _ready() -> void:
	progression = true
	super._ready()


func is_collected() -> bool:
	var sess := get_session()
	return sess != null and sess.narrative_state != null and bool(sess.narrative_state.get_flag(flag_id))


func _can_use(_actor_id: StringName, interaction_id: StringName, _payload: Dictionary) -> StringName:
	if interaction_id != &"use":
		return &"unsupported"
	return &"already_open" if is_collected() else &""


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	get_session().narrative_state.set_flag(flag_id)
	collected_changed.emit(true)
