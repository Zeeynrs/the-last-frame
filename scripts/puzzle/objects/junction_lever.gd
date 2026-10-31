class_name JunctionLever
extends PuzzleObject

## CH1-PZ-005 route-junction lever. Toggles between two relay states by applying a doorway
## re-pairing to the SpatialGraph (ADR-009). The transform is dry-run in can_interact, so an
## invalid order (e.g. lever B before lever A) is refused with the graph's reason and changes nothing.
## Spatial index relays are outside local time: no temporal component, so abilities are unsupported.
## Latched (no further changes) once the puzzle is solved: State 2 stays permanent (ADR-016).

signal relay_changed(relay_state: StringName)

@export var state_a: StringName = &""
@export var state_b: StringName = &""
## Pairings applied when switching a -> b, and b -> a ([room, door, room, door, traversable?]).
@export var pairs_to_b: Array = []
@export var pairs_to_a: Array = []

var relay_state: StringName = &""


func _ready() -> void:
	relay_state = state_a
	super._ready()


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	if latched_solved:
		return &"locked"
	var spatial := _spatial()
	if spatial == null:
		return &"missing_target"
	return spatial.validate_transform(_next_pairs()).reason


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	var result := _spatial().apply_transform(_next_pairs())
	if result.ok:
		relay_state = state_b if relay_state == state_a else state_a
		relay_changed.emit(relay_state)


## Reset: the SpatialStateResetter restores the graph atomically; the lever only resets its label.
func _reset_unsolved() -> void:
	relay_state = state_a
	relay_changed.emit(relay_state)


func _next_pairs() -> Array:
	return pairs_to_b if relay_state == state_a else pairs_to_a


func _spatial() -> SpatialService:
	var sess := get_session()
	return sess.spatial_service if sess != null else null
