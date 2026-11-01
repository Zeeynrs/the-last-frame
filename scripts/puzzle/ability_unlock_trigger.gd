class_name AbilityUnlockTrigger
extends Node

## Unlocks a pocket-watch ability when a story/progress condition is met (TLF-050, ADR-020 am.).
## Data only: place it in a room (or the chapter) and set one or more conditions; the first one
## that holds unlocks `ability` in the session's AbilityUnlocks. Conditions already true when the
## trigger is ready (e.g. after loading a save) unlock immediately; unlocking twice is harmless.
##   - on_flag:            a NarrativeState flag becomes truthy
##   - on_pickup_id:       the ProgressionPickup with this object_id is collected (same room;
##                         for a pickup elsewhere use on_flag with the pickup's flag_id)
##   - on_puzzle_solved:   a PuzzleService puzzle becomes SOLVED

signal fired(ability: StringName)

@export var ability: StringName = &""
@export var on_flag: StringName = &""
@export var on_pickup_id: StringName = &""
@export var on_puzzle_solved: StringName = &""

var _session: GameSession = null
var _done: bool = false


func _ready() -> void:
	if not AbilityUnlocks.is_known(ability):
		push_error("AbilityUnlockTrigger '%s': unknown ability '%s'." % [name, ability])
		return
	_session = _find_session()
	if _session == null or _session.ability_unlocks == null:
		push_error("AbilityUnlockTrigger '%s': no GameSession with AbilityUnlocks." % name)
		return
	if _session.narrative_state != null and not String(on_flag).is_empty():
		_session.narrative_state.flag_changed.connect(_on_flag_changed)
	if _session.puzzle_service != null and not String(on_puzzle_solved).is_empty():
		_session.puzzle_service.puzzle_solved.connect(_on_puzzle_solved)
	# Room objects register in their own _ready; bind the pickup once the room is complete.
	_bind_pickup.call_deferred()
	_check_now()


func _find_session() -> GameSession:
	var node := get_parent()
	while node != null:
		if node is GameSession:
			return node
		node = node.get_parent()
	return get_tree().get_first_node_in_group(&"game_session") as GameSession if is_inside_tree() else null


func _bind_pickup() -> void:
	if _done or _session == null or String(on_pickup_id).is_empty() or _session.id_registry == null:
		return
	var pickup := _session.id_registry.resolve(on_pickup_id) as ProgressionPickup
	if pickup == null:
		push_warning("AbilityUnlockTrigger '%s': pickup '%s' not found in the loaded room." % [name, on_pickup_id])
		return
	if pickup.is_collected():
		_fire()
	elif not pickup.collected_changed.is_connected(_on_pickup_collected):
		pickup.collected_changed.connect(_on_pickup_collected)


func _check_now() -> void:
	if not String(on_flag).is_empty() and _session.narrative_state != null and _session.narrative_state.get_flag(on_flag):
		_fire()
	elif not String(on_puzzle_solved).is_empty() and _session.puzzle_service != null and _session.puzzle_service.is_solved(on_puzzle_solved):
		_fire()


func _on_flag_changed(flag: StringName, value: Variant) -> void:
	if flag == on_flag and value:
		_fire()


func _on_puzzle_solved(puzzle_id: StringName, _tick: int) -> void:
	if puzzle_id == on_puzzle_solved:
		_fire()


func _on_pickup_collected(collected: bool) -> void:
	if collected:
		_fire()


func _fire() -> void:
	if _done:
		return
	_done = true
	_session.ability_unlocks.unlock(ability)
	fired.emit(ability)
