class_name SubstationGrid
extends PuzzleObject

## CH1-PZ-004 controller. Step 1 is stabilized while the capacitor powers the bus and is frozen.
## The grid goes online (permanently) the moment the bus is powered and both breakers are engaged
## at the same tick. Evaluated whenever a breaker engages and on every tick.

signal grid_online_changed(online: bool)

@export var capacitor_id: StringName = &""
@export var breaker_a_id: StringName = &""
@export var breaker_b_id: StringName = &""

var step_1_stabilized: bool = false
var grid_online: bool = false


func _ready() -> void:
	super._ready()
	_link_breakers()


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"


func evaluate() -> void:
	var capacitor = resolve(capacitor_id)
	var a = resolve(breaker_a_id)
	var b = resolve(breaker_b_id)
	step_1_stabilized = capacitor != null and capacitor.is_stabilized()
	if grid_online:
		return
	if capacitor != null and capacitor.bus_powered and a != null and b != null and a.is_engaged() and b.is_engaged():
		grid_online = true
		grid_online_changed.emit(true)


func _puzzle_tick(_tick: int) -> void:
	_link_breakers()
	evaluate()


func _link_breakers() -> void:
	for id in [breaker_a_id, breaker_b_id]:
		var breaker = resolve(id)
		if breaker != null and not breaker.engaged_changed.is_connected(_on_breaker_changed):
			breaker.engaged_changed.connect(_on_breaker_changed)


func _on_breaker_changed(_engaged: bool) -> void:
	evaluate()


## Once online, the substation latch is permanent (spec §5), even before the exit trigger is crossed.
func _reset_unsolved() -> void:
	evaluate()


func _apply_solved_state() -> void:
	if not grid_online:
		grid_online = true
		grid_online_changed.emit(true)
