class_name FireShutter
extends PuzzleObject

## CH1-PZ-002 fire shutter: REWIND only. Rewound to its pre-arrival "raised" state it holds for
## the timing window (180 ticks, 300 with the accessibility assist), counting down once per tick
## unless the coupled gear is frozen. Reaching zero is a discrete transition (raised -> closed) and
## commits history, so it can be rewound again without a reset (TEST-PZ002-05).
## Safety clutch: a player in the threshold zone when it closes is moved to safety first.
## `requires_gear_frozen` (CH1-PZ-002 R1 inner shutter, TLF-054): the opposite rule. Rewind is
## refused with &"unanchored" unless the gear is frozen. A state rule, not a timing gate, so the
## timing assist cannot weaken it. Default false = the base shutter.

@export var gear_id: StringName = &""
@export var threshold_zone_id: StringName = &""
@export var hold_ticks_base: int = 180
@export var requires_gear_frozen: bool = false

var shutter_state: StringName = &"closed"
var hold_ticks: int = 0
var passage_blocked: bool = true


func _ready() -> void:
	super._ready()
	set_passage_blocked(passage_blocked)


func capture_state() -> Dictionary:
	return {"shutter_state": shutter_state, "hold_ticks": hold_ticks, "passage_blocked": passage_blocked}


func apply_state(state: Dictionary) -> void:
	shutter_state = StringName(state["shutter_state"])
	hold_ticks = int(state["hold_ticks"])
	passage_blocked = bool(state["passage_blocked"])
	if shutter_state == &"raised" and hold_ticks == hold_ticks_base:
		hold_ticks = timing_window(hold_ticks_base)  # assist applies to every fresh raise
	set_passage_blocked(passage_blocked)


func gear_locked() -> bool:
	var gear = resolve(gear_id)
	return gear != null and gear.has_method("is_frozen") and gear.is_frozen()


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"jammed"  # too heavy to lift by hand


func _can_use_ability(_actor_id: StringName, ability_id: StringName, _payload: Dictionary) -> StringName:
	if ability_id != ABILITY_REWIND:
		return &""
	if requires_gear_frozen:
		return &"" if gear_locked() else &"unanchored"
	if gear_locked():
		return &"frozen"  # the frozen counterweight spindle blocks the shutter (spec rule 4)
	return &""


func _default_feedback_keys() -> Dictionary:
	return {&"unanchored": "PZ002_FB_UNANCHORED"}


func _puzzle_tick(_tick: int) -> void:
	if shutter_state != &"raised" or gear_locked():
		return
	hold_ticks -= 1
	if hold_ticks > 0:
		return
	if player_in_zone(threshold_zone_id):
		relocate_player_to_safety()
	apply_state({"shutter_state": &"closed", "hold_ticks": 0, "passage_blocked": true})
	var temporal := get_temporal()
	if temporal != null:
		temporal.commit_history()


func _apply_solved_state() -> void:
	shutter_state = &"raised"
	passage_blocked = false
	set_passage_blocked(false)
