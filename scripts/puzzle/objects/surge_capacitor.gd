class_name SurgeCapacitor
extends PuzzleObject

## CH1-PZ-004 surge capacitor: REWIND | FREEZE on the same object.
## Rewound to its pre-arrival "charged" state it powers the bus and decays once per tick unless
## frozen; reaching zero is a discrete transition (charged -> discharged) that commits history,
## so it can be rewound again without a reset.

var charge_state: StringName = &"discharged"
var decay_ticks: int = 0
var bus_powered: bool = false


func capture_state() -> Dictionary:
	return {"charge_state": charge_state, "decay_ticks": decay_ticks, "bus_powered": bus_powered}


func apply_state(state: Dictionary) -> void:
	charge_state = StringName(state["charge_state"])
	decay_ticks = int(state["decay_ticks"])
	bus_powered = bool(state["bus_powered"])


func is_stabilized() -> bool:
	return bus_powered and is_frozen()


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"


func _puzzle_tick(_tick: int) -> void:
	if charge_state != &"charged" or is_frozen():
		return
	decay_ticks -= 1
	if decay_ticks > 0:
		return
	apply_state({"charge_state": &"discharged", "decay_ticks": 0, "bus_powered": false})
	var temporal := get_temporal()
	if temporal != null:
		temporal.commit_history()
