class_name PlateLinkedGate
extends PuzzleObject

## CH1-PZ-003 security gate: open exactly while its pressure plate (TriggerZone) is occupied, by the
## player or an echo. Chrono-shielded: no temporal component, so every watch ability is unsupported.
## Latched open once the puzzle is solved.

@export var plate_id: StringName = &""

var gate_state: StringName = &"closed"
var passage_blocked: bool = true


func _ready() -> void:
	super._ready()
	if not _link_plate():
		set_passage_blocked(passage_blocked)


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"locked" if passage_blocked else &"already_open"


func _on_plate_changed(occupied: bool) -> void:
	if latched_solved:
		return
	_set_open(occupied)


func _set_open(open: bool) -> void:
	gate_state = &"open" if open else &"closed"
	passage_blocked = not open
	set_passage_blocked(passage_blocked)


func _apply_solved_state() -> void:
	_set_open(true)


func _reset_unsolved() -> void:
	var plate := resolve(plate_id) as TriggerZone
	_set_open(plate != null and plate.is_occupied())


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

