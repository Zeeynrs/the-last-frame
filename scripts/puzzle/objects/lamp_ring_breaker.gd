class_name LampRingBreaker
extends PuzzleObject

## CH1-PZ-004 R1 breaker C, the lamp ring (TLF-054): a trap, never an input to the grid. Pulled
## while the bus is powered it browns the capacitor out (discharged, unfrozen, re-rewindable). With
## a dead bus it answers &"unpowered"; once the grid is online (or the puzzle SOLVED) &"already_open".

@export var capacitor_id: StringName = &""
@export var grid_id: StringName = &""
@export var brownout_text_key: String = "PZ004_FB_BROWNOUT"


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	var grid = resolve(grid_id)
	if latched_solved or (grid != null and grid.grid_online):
		return &"already_open"
	var capacitor := resolve(capacitor_id) as SurgeCapacitor
	return &"" if capacitor != null and capacitor.bus_powered else &"unpowered"


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	(resolve(capacitor_id) as SurgeCapacitor).brownout()
	if not brownout_text_key.is_empty():
		feedback_requested.emit(brownout_text_key)


func _default_feedback_keys() -> Dictionary:
	return {&"unpowered": "PZ004_FB_C_DEAD"}


func _reset_unsolved() -> void:
	pass  # no state of its own
