class_name CheckpointZone
extends TriggerZone

## Auto-save checkpoint (design/ch01/ROOM_GRAPH.md §6). When the player enters, the room router
## writes the autosave. On load, the player respawns at `spawn_anchor_id` (or this zone).

@export var checkpoint_id: StringName = &""
@export var spawn_anchor_id: StringName = &""


func _ready() -> void:
	accepts_echoes = false
	super._ready()


func on_trigger_enter(actor_id: StringName) -> void:
	super.on_trigger_enter(actor_id)
	if actor_id != &"player" or String(checkpoint_id).is_empty():
		return
	var sess := get_session()
	if sess != null and sess.room_router != null:
		sess.room_router.reach_checkpoint(checkpoint_id)
