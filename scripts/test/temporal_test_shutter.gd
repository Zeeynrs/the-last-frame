class_name TemporalTestShutter
extends Interactable

## Greybox stand-in for CH1-PZ-002 fire shutter: REWIND only.
## While raised it counts hold_ticks down once per SimClock tick unless the coupled gear
## is frozen; reaching zero is a discrete transition (raised -> closed) and commits history.

@export var gear_id: StringName = &""
@export var hold_ticks_on_raise: int = 180

var shutter_state: StringName = &"closed"
var hold_ticks: int = 0
var passage_blocked: bool = true


func _ready() -> void:
	super._ready()
	var sess := get_session()
	if sess != null and sess.sim_clock != null:
		sess.sim_clock.tick_advanced.connect(_on_tick)


func capture_state() -> Dictionary:
	return {"shutter_state": shutter_state, "hold_ticks": hold_ticks, "passage_blocked": passage_blocked}


func apply_state(state: Dictionary) -> void:
	shutter_state = state["shutter_state"]
	hold_ticks = state["hold_ticks"]
	passage_blocked = state["passage_blocked"]
	queue_redraw()


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"jammed"


func _can_use_ability(_actor_id: StringName, ability_id: StringName, _payload: Dictionary) -> StringName:
	if ability_id == ABILITY_REWIND and _gear_locked():
		return &"frozen"
	return &""


func _on_tick(_tick: int) -> void:
	var temporal := get_temporal()
	if shutter_state != &"raised" or (temporal != null and temporal.is_frozen) or _gear_locked():
		return
	hold_ticks -= 1
	if hold_ticks <= 0:
		hold_ticks = 0
		shutter_state = &"closed"
		passage_blocked = true
		if temporal != null:
			temporal.commit_history()
		queue_redraw()


func _gear_locked() -> bool:
	var sess := get_session()
	if sess == null or sess.id_registry == null or String(gear_id).is_empty():
		return false
	var gear = sess.id_registry.resolve(gear_id)
	return gear != null and gear.has_method("is_locked") and gear.is_locked()


func _draw() -> void:
	draw_rect(Rect2(-16, -28, 32, 28 if passage_blocked else 6), Color(0.75, 0.3, 0.3))
