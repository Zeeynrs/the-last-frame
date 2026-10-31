class_name CounterweightGear
extends PuzzleObject

## CH1-PZ-002 counterweight gear: FREEZE only (toggle). No rewindable state of its own.
## gear_state is presentation: idle / slipping (shutter raised and counting) / locked (frozen).

@export var shutter_id: StringName = &""

var gear_state: StringName = &"idle"


func capture_state() -> Dictionary:
	return {}


func apply_state(_state: Dictionary) -> void:
	pass


func _ready() -> void:
	super._ready()
	var temporal := get_temporal()
	if temporal != null:
		temporal.freeze_changed.connect(func(_f): _refresh())


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"


func _puzzle_tick(_tick: int) -> void:
	_refresh()


func _refresh() -> void:
	var shutter = resolve(shutter_id)
	if is_frozen():
		gear_state = &"locked"
	elif shutter != null and shutter.shutter_state == &"raised":
		gear_state = &"slipping"
	else:
		gear_state = &"idle"


func _reset_unsolved() -> void:
	var temporal := get_temporal()
	if temporal != null:
		temporal.set_frozen(false)
	_refresh()
