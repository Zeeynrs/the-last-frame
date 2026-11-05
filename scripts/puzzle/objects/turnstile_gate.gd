class_name TurnstileGate
extends PuzzleObject

## CH1-PZ-001 turnstile: REWIND only. Starts collapsed; pre-arrival history (initial_history) is open.
## Reset (unsolved) collapses it again; a player standing in its footprint is moved to safety first.

## TriggerZone covering the gate footprint (optional).
@export var footprint_zone_id: StringName = &""
## CH1-PZ-001 R1 (TLF-054): the object pinning the arm (a ConduitProp). While it pins, Rewind is
## refused with &"pinned" and nothing changes. Empty = the base turnstile.
@export var pinned_by: StringName = &""

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


func _can_use_ability(_actor_id: StringName, ability_id: StringName, _payload: Dictionary) -> StringName:
	return &"pinned" if ability_id == ABILITY_REWIND and is_pinned() else &""


## True while `pinned_by` is set and that object still pins the arm (or cannot be found: fail closed).
func is_pinned() -> bool:
	if String(pinned_by).is_empty():
		return false
	var pin = resolve(pinned_by)
	return pin == null or not pin.has_method("is_pinning") or pin.is_pinning()


func _default_feedback_keys() -> Dictionary:
	return {&"pinned": "PZ001_FB_PINNED"}


func _apply_solved_state() -> void:
	apply_state({"arm_state": &"open", "passage_blocked": false})


func _reset_unsolved() -> void:
	if player_in_zone(footprint_zone_id):
		relocate_player_to_safety()
	super._reset_unsolved()
