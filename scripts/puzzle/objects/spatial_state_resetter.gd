class_name SpatialStateResetter
extends PuzzleObject

## CH1-PZ-005 T_RESET: on an unsolved reset, restores the puzzle's doorways to their initial
## pairing in ONE transactional apply (resetting levers one by one could pass through an invalid
## intermediate graph). Players stranded by the change are relocated by SpatialService (ADR-009).

## Pairings of State 0 for every doorway the puzzle can change.
@export var initial_pairs: Array = []


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"


func _reset_unsolved() -> void:
	var sess := get_session()
	if sess == null or sess.spatial_service == null or initial_pairs.is_empty():
		return
	var result := sess.spatial_service.apply_transform(initial_pairs)
	if not result.ok:
		push_error("SpatialStateResetter '%s': reset transform rejected (%s)." % [object_id, result.reason])
