class_name TemporalTestGear
extends Interactable

## Greybox stand-in for CH1-PZ-002 counterweight gear: FREEZE only, no rewindable state.


func capture_state() -> Dictionary:
	return {}


func apply_state(_state: Dictionary) -> void:
	pass


func is_locked() -> bool:
	var temporal := get_temporal()
	return temporal != null and temporal.is_frozen


func _ready() -> void:
	super._ready()
	var temporal := get_temporal()
	if temporal != null:
		temporal.freeze_changed.connect(func(_frozen): queue_redraw())


func _draw() -> void:
	draw_circle(Vector2(0, -8), 8.0, Color(0.6, 0.8, 1.0) if is_locked() else Color(0.7, 0.6, 0.4))
