class_name PlateLinkedGate
extends PuzzleObject

## CH1-PZ-003 security gate: open exactly while its pressure plate (TriggerZone) is occupied, by the
## player or an echo. Chrono-shielded: no temporal component, so every watch ability is unsupported.
## Latched open once the puzzle is solved.
##
## Optional FREEZE (CH1-SO-02 hatch, "FreezableGate", TLF-054): give it a TemporalComponent with the
## FREEZE capability and state_fields ["gate_state", "passage_blocked"]. While frozen it ignores
## plate changes (frozen open or frozen closed); unfreezing follows the plate again. Every open/close
## commits history, so a save restores the frozen state it was in. With `threshold_zone_id` set, a
## player in the aperture is moved to `safe_anchor_id` before the gate closes (ADR-016 clutch).
## Without a TemporalComponent nothing changes (the Security Crossing gate).

@export var plate_id: StringName = &""
## TriggerZone in the aperture (optional; enables the closing clutch).
@export var threshold_zone_id: StringName = &""

var gate_state: StringName = &"closed"
var passage_blocked: bool = true


func _ready() -> void:
	super._ready()
	var temporal := get_temporal()
	if temporal != null:
		temporal.freeze_changed.connect(_on_freeze_changed)
	if not _link_plate():
		set_passage_blocked(passage_blocked)


func capture_state() -> Dictionary:
	return {"gate_state": gate_state, "passage_blocked": passage_blocked}


func apply_state(state: Dictionary) -> void:
	gate_state = StringName(state["gate_state"])
	passage_blocked = bool(state["passage_blocked"])
	set_passage_blocked(passage_blocked)


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"locked" if passage_blocked else &"already_open"


func _can_use_ability(_actor_id: StringName, _ability_id: StringName, _payload: Dictionary) -> StringName:
	return &"already_open" if latched_solved else &""


func _on_plate_changed(occupied: bool) -> void:
	if latched_solved or is_frozen():
		return
	_set_open(occupied)


func _on_freeze_changed(frozen: bool) -> void:
	if not frozen and not latched_solved:
		_set_open(_plate_occupied())


func _set_open(open: bool) -> void:
	var changes := open == passage_blocked
	if changes and not open and player_in_zone(threshold_zone_id):
		relocate_player_to_safety()
	gate_state = &"open" if open else &"closed"
	passage_blocked = not open
	set_passage_blocked(passage_blocked)
	var temporal := get_temporal()
	if changes and temporal != null:
		temporal.commit_history()


func _plate_occupied() -> bool:
	var plate := resolve(plate_id) as TriggerZone
	return plate != null and plate.is_occupied()


func _apply_solved_state() -> void:
	_set_open(true)


func _reset_unsolved() -> void:
	var temporal := get_temporal()
	if temporal != null:
		temporal.set_frozen(false)  # resyncs to the plate through _on_freeze_changed
	_set_open(_plate_occupied())


## Connects to the plate once it is registered (scene order independent). Returns true when linked.
func _link_plate() -> bool:
	var plate := resolve(plate_id) as TriggerZone
	if plate == null:
		return false
	if not plate.occupancy_changed.is_connected(_on_plate_changed):
		plate.occupancy_changed.connect(_on_plate_changed)
		_on_plate_changed(plate.is_occupied())
	return true


func _puzzle_tick(_tick: int) -> void:
	_link_plate()
