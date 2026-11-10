class_name SideMemoryExitMarker
extends TriggerZone

## SideMemoryExitMarker (TLF-076 / ADR-025 V6)
## Invisible 24 px wide trigger zone at x=1380 on the floor line.
## Walking into the marker returns the player to the waiting lounge at the bench stand spot.

@export var return_room_id: StringName = &"ch01.waiting_lounge"
@export var return_anchor_id: StringName = &"ch01.waiting_lounge.safe_anchor_center"


func _ready() -> void:
	accepts_echoes = false
	super._ready()


func on_trigger_enter(actor_id: StringName) -> void:
	super.on_trigger_enter(actor_id)
	if actor_id != &"player":
		return
	var sess := get_session()
	if sess == null:
		sess = get_tree().get_first_node_in_group(&"game_session") as GameSession if is_inside_tree() else null
	if sess != null and sess.room_router != null:
		var target := return_anchor_id
		if sess.narrative_state != null:
			var flagged = sess.narrative_state.get_flag(&"ch01.flag.mira_memory_return", "")
			if flagged != null and String(flagged) != "":
				target = StringName(String(flagged))
		sess.room_router.enter_room.call_deferred(return_room_id, &"", target)
