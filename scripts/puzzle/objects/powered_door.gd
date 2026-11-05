class_name PoweredDoor
extends PuzzleObject

## CH1-PZ-004 vestibule door: opens (permanently) when its substation grid goes online.
## Also the Step 1 gates (TLF-054): any node with `grid_online` + `grid_online_changed(online)` can be
## the grid (CodeLock, TicketValidator, CardReader).

@export var grid_id: StringName = &""
## Reason for `use` while closed: &"unpowered" (PZ-004) or &"locked" (SO-01 gate, PZ-006 staff door).
@export var closed_reason: StringName = &"unpowered"

var door_state: StringName = &"locked"
var passage_blocked: bool = true


func _ready() -> void:
	super._ready()
	set_passage_blocked(passage_blocked)
	_link_grid()


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return closed_reason if passage_blocked else &"already_open"


func _puzzle_tick(_tick: int) -> void:
	_link_grid()


func _link_grid() -> void:
	var grid = resolve(grid_id)
	if grid == null or grid.grid_online_changed.is_connected(_on_grid_online):
		return
	grid.grid_online_changed.connect(_on_grid_online)
	if grid.grid_online:
		_open()


func _on_grid_online(online: bool) -> void:
	if online:
		_open()


func _open() -> void:
	door_state = &"open"
	passage_blocked = false
	set_passage_blocked(false)


func _apply_solved_state() -> void:
	_open()


func _reset_unsolved() -> void:
	pass  # the grid latch is permanent; a locked door stays locked until the grid comes online
