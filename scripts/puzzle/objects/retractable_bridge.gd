class_name RetractableBridge
extends PuzzleObject

## CH1-PZ-003 bridge: extended (walkable) exactly while its pressure plate is occupied.
## Safety interlock (spec §5): if the player is on the bridge when it retracts, they are moved to
## safety first. Latched extended once the puzzle is solved.

@export var plate_id: StringName = &""
@export var bridge_zone_id: StringName = &""

var platform_state: StringName = &"retracted"
var walkable: bool = false


func _ready() -> void:
	super._ready()
	if not _link_plate():
		set_passage_blocked(not walkable)


func player_on_bridge() -> bool:
	return player_in_zone(bridge_zone_id)


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"


func _on_plate_changed(occupied: bool) -> void:
	if latched_solved:
		return
	if not occupied and walkable and player_on_bridge():
		relocate_player_to_safety()
	_set_extended(occupied)


func _set_extended(extended: bool) -> void:
	platform_state = &"extended" if extended else &"retracted"
	walkable = extended
	set_passage_blocked(not walkable)  # the Blocker is the trench edge


func _apply_solved_state() -> void:
	_set_extended(true)


func _reset_unsolved() -> void:
	var plate := resolve(plate_id) as TriggerZone
	_on_plate_changed(plate != null and plate.is_occupied())


## Connects to the plate once it is registered (scene order independent). Returns true when linked.
func _link_plate() -> bool:
	var plate := resolve(plate_id) as TriggerZone
	if plate == null:
		return false
	if not plate.occupancy_changed.is_connected(_on_plate_changed):
		plate.occupancy_changed.connect(_on_plate_changed)
		_set_extended(plate.is_occupied())
	return true


func _puzzle_tick(_tick: int) -> void:
	_link_plate()

