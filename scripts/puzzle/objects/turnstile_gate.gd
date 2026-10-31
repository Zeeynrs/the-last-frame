class_name TurnstileGate
extends PuzzleObject

## CH1-PZ-001 turnstile: REWIND only. Starts collapsed; pre-arrival history (initial_history) is open.
## Reset (unsolved) collapses it again; a player standing in its footprint is moved to safety first.

## TriggerZone covering the gate footprint (optional).
@export var footprint_zone_id: StringName = &""

var arm_state: StringName = &"collapsed"
var passage_blocked: bool = true


func _ready() -> void:
	super._ready()
	set_passage_blocked(passage_blocked)


func capture_state() -> Dictionary:
	return {"arm_state": arm_state, "passage_blocked": passage_blocked}


func apply_state(state: Dictionary) -> void:
	arm_state = StringName(state["arm_state"])
	passage_blocked = bool(state["passage_blocked"])
	set_passage_blocked(passage_blocked)


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"jammed" if arm_state == &"collapsed" else &"already_open"


func _apply_solved_state() -> void:
	apply_state({"arm_state": &"open", "passage_blocked": false})


func _reset_unsolved() -> void:
	if player_in_zone(footprint_zone_id):
		relocate_player_to_safety()
	super._reset_unsolved()
