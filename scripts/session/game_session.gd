class_name GameSession
extends Node

## Container node for session-scoped services per ADR-011.
## Belongs to group 'game_session' so gameplay nodes can discover services cleanly.

@export var sim_clock: SimClock
@export var id_registry: IdRegistry
@export var interaction_service: InteractionService
@export var echo_service: EchoService
@export var puzzle_service: PuzzleService
@export var narrative_state: NarrativeState


func _enter_tree() -> void:
	add_to_group(&"game_session")


func _ready() -> void:
	if sim_clock == null:
		sim_clock = get_node_or_null("SimClock") as SimClock
	if id_registry == null:
		id_registry = get_node_or_null("IdRegistry") as IdRegistry
	if interaction_service == null:
		interaction_service = get_node_or_null("InteractionService") as InteractionService
	if echo_service == null:
		echo_service = get_node_or_null("EchoService") as EchoService
	if puzzle_service == null:
		puzzle_service = get_node_or_null("PuzzleService") as PuzzleService
	if narrative_state == null:
		narrative_state = get_node_or_null("NarrativeState") as NarrativeState
