class_name TemporalTestGate
extends Interactable

## Greybox stand-in for CH1-PZ-001 turnstile: REWIND only, pre-arrival state "open".

var arm_state: StringName = &"collapsed"
var passage_blocked: bool = true


func capture_state() -> Dictionary:
	return {"arm_state": arm_state, "passage_blocked": passage_blocked}


func apply_state(state: Dictionary) -> void:
	arm_state = state["arm_state"]
	passage_blocked = state["passage_blocked"]
	queue_redraw()


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"jammed" if arm_state == &"collapsed" else &"already_open"


func _draw() -> void:
	draw_rect(Rect2(-12, -20, 24, 20), Color(0.8, 0.5, 0.2) if passage_blocked else Color(0.3, 0.8, 0.9))
