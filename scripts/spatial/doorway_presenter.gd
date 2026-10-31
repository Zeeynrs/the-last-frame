class_name DoorwayPresenter
extends TriggerZone

## Scene-side doorway (ADR-009): when the player steps in, asks SpatialService where this doorway
## leads and emits `traversed`. Loading/positioning the destination room belongs to the room router;
## this node only reports the logical result, so rendering never decides connectivity.
## Its object_id should be "<room_id>.<door_id>" (ADR-005), e.g. ch01.upper_vestibule.door_north.

signal traversed(actor_id: StringName, destination: Dictionary)
signal blocked(actor_id: StringName)

@export var room_id: StringName = &""
@export var door_id: StringName = &""


func _ready() -> void:
	accepts_echoes = false  # echoes don't change rooms (ADR-008 am.: recording stops on room change)
	super._ready()


func on_trigger_enter(actor_id: StringName) -> void:
	super.on_trigger_enter(actor_id)
	if actor_id != &"player":
		return
	var spatial := _spatial()
	if spatial == null:
		return
	var destination := spatial.traverse(actor_id, room_id, door_id)
	if destination.is_empty():
		blocked.emit(actor_id)
	else:
		traversed.emit(actor_id, destination)


## The doorway this presenter currently leads to (for transom glyphs / previews), or {}.
func get_destination() -> Dictionary:
	var spatial := _spatial()
	return spatial.graph.get_destination(room_id, door_id) if spatial != null else {}


func _spatial() -> SpatialService:
	var sess := get_session()
	return sess.spatial_service if sess != null else null
