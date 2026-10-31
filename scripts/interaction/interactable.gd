class_name Interactable
extends Area2D

## Base interactable component per ADR-005 and ADR-006.
## Registers with session IdRegistry and implements interaction contract.

signal focused_changed(is_focused: bool)

@export var object_id: StringName = &""
@export var progression: bool = false
@export var prompt_text: String = "[E] Interact"

var is_focused: bool = false


func _enter_tree() -> void:
	add_to_group(&"interactable")


func _ready() -> void:
	if not String(object_id).is_empty():
		_register_with_session()


func _exit_tree() -> void:
	if not String(object_id).is_empty():
		_unregister_from_session()


func _register_with_session() -> void:
	var session = get_tree().get_first_node_in_group(&"game_session")
	if session != null and "id_registry" in session and session.id_registry != null:
		session.id_registry.register(object_id, self)


func _unregister_from_session() -> void:
	var session = get_tree().get_first_node_in_group(&"game_session")
	if session != null and "id_registry" in session and session.id_registry != null:
		session.id_registry.unregister(object_id)


## Check if the actor can interact. Returns &"" if allowed, or failure reason (e.g. &"frozen").
func can_interact(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary = {}) -> StringName:
	return &""


## Execute the interaction.
func interact(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary = {}) -> void:
	pass


## Called by player when this interactable becomes the closest target.
func set_focused(p_focused: bool) -> void:
	if is_focused != p_focused:
		is_focused = p_focused
		focused_changed.emit(is_focused)
		_on_focus_changed(is_focused)


func _on_focus_changed(_focused: bool) -> void:
	pass
