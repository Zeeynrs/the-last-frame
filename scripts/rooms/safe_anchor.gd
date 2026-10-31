class_name SafeAnchor
extends Marker2D

## Registered spawn/relocation point (ADR-009/016). Its object_id follows ADR-005,
## e.g. ch01.upper_vestibule.safe_anchor_center, so relocation can target it by ID.

@export var object_id: StringName = &""

var _registered: bool = false


func _ready() -> void:
	var sess := _session()
	if sess != null and sess.id_registry != null and not String(object_id).is_empty():
		_registered = sess.id_registry.register(object_id, self)


func _exit_tree() -> void:
	var sess := _session()
	if _registered and sess != null and sess.id_registry != null:
		sess.id_registry.unregister(object_id, self)
	_registered = false


func _session() -> GameSession:
	return get_tree().get_first_node_in_group(&"game_session") as GameSession if is_inside_tree() else null
