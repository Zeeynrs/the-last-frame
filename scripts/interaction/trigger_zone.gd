class_name TriggerZone
extends Interactable

## Occupancy trigger (pressure plates, completion zones) per ADR-006 clarification / ADR-008.
## Physical bodies with an `actor_id` (the Player) are reported through
## InteractionService.trigger_enter/exit; echoes are reported logically by EchoService.
## Either way the service calls on_trigger_enter/exit() here, so occupancy has one code path.

signal occupancy_changed(is_occupied: bool)
signal actor_entered(actor_id: StringName)
signal actor_exited(actor_id: StringName)

const PLAYER_LAYER: int = 2

## When false, echo actors are ignored (ADR-016: completion triggers accept only the player).
@export var accepts_echoes: bool = true

var occupants: Array[StringName] = []


func _ready() -> void:
	super._ready()
	collision_mask |= PLAYER_LAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func is_occupied() -> bool:
	return not occupants.is_empty()


func on_trigger_enter(actor_id: StringName) -> void:
	if not _accepts(actor_id) or actor_id in occupants:
		return
	occupants.append(actor_id)
	actor_entered.emit(actor_id)
	if occupants.size() == 1:
		occupancy_changed.emit(true)


func on_trigger_exit(actor_id: StringName) -> void:
	if not actor_id in occupants:
		return
	occupants.erase(actor_id)
	actor_exited.emit(actor_id)
	if occupants.is_empty():
		occupancy_changed.emit(false)


## Trigger zones are stepped on, not used.
func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	return &"unsupported"


func _accepts(actor_id: StringName) -> bool:
	return accepts_echoes or not String(actor_id).begins_with("echo.")


func _on_body_entered(body: Node) -> void:
	var service := _service()
	if service != null and "actor_id" in body:
		service.trigger_enter(body.actor_id, object_id)


func _on_body_exited(body: Node) -> void:
	var service := _service()
	if service != null and "actor_id" in body:
		service.trigger_exit(body.actor_id, object_id)


func _service() -> InteractionService:
	var sess := get_session()
	return sess.interaction_service if sess != null else null
