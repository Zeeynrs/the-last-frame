class_name GameSession
extends Node

## Container node for session-scoped services per ADR-011.
## Belongs to group 'game_session' so gameplay nodes can discover services cleanly.

@onready var sim_clock: SimClock = $SimClock
@onready var id_registry: IdRegistry = $IdRegistry
@onready var interaction_service: InteractionService = $InteractionService


func _enter_tree() -> void:
	add_to_group(&"game_session")
