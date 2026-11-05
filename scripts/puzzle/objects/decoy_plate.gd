class_name DecoyPlate
extends TriggerZone

## A plate wired to nothing but a message (CH1-SO-02 bell plate B, CH1-PZ-003 alarm plate): when the
## player steps on it, feedback_requested carries `enter_text_key`. No mechanical effect; it is
## still a normal TriggerZone (occupancy, echoes) so a scene can listen to it like any other plate.

signal feedback_requested(text_key: String)

@export var enter_text_key: String = ""


func on_trigger_enter(actor_id: StringName) -> void:
	var was_occupied := actor_id in occupants
	super.on_trigger_enter(actor_id)
	if actor_id == &"player" and not was_occupied and actor_id in occupants and not enter_text_key.is_empty():
		feedback_requested.emit(enter_text_key)
