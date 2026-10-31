class_name InteractionService
extends Node

## Centralized interaction dispatcher per ADR-006.
## Validates actor permissions, delegates to interactables, and emits state signals.

signal interaction_applied(tick: int, actor_id: StringName, target_id: StringName, interaction_id: StringName, payload: Dictionary)
signal trigger_entered(tick: int, actor_id: StringName, trigger_id: StringName)
signal trigger_exited(tick: int, actor_id: StringName, trigger_id: StringName)

@export var id_registry: IdRegistry
@export var sim_clock: SimClock


func _ready() -> void:
	if id_registry == null:
		id_registry = get_node_or_null("../IdRegistry") as IdRegistry
	if sim_clock == null:
		sim_clock = get_node_or_null("../SimClock") as SimClock


func _get_current_tick() -> int:
	if sim_clock != null:
		return sim_clock.tick
	var session = get_tree().get_first_node_in_group(&"game_session")
	if session != null and "sim_clock" in session and session.sim_clock != null:
		return session.sim_clock.tick
	return 0


func _get_id_registry() -> IdRegistry:
	if id_registry != null:
		return id_registry
	var session = get_tree().get_first_node_in_group(&"game_session")
	if session != null and "id_registry" in session and session.id_registry != null:
		return session.id_registry
	return null


## Dispatches an interaction request following the ADR-006 contract order of operations.
func request(actor_id: StringName, target_id: StringName, interaction_id: StringName, payload: Dictionary = {}) -> InteractionResult:
	var registry = _get_id_registry()
	if registry == null:
		return InteractionResult.failure(&"missing_registry")

	# 1. Resolve target; if missing -> &"missing_target"
	var target = registry.resolve(target_id)
	if target == null:
		return InteractionResult.failure(&"missing_target")

	# 2. Call can_interact; non-empty reason -> return it with no state change
	if target.has_method("can_interact"):
		var reason: StringName = target.call("can_interact", actor_id, interaction_id, payload)
		if not String(reason).is_empty():
			return InteractionResult.failure(reason)

	# 3. If progression is true and actor ID starts with "echo." -> &"echo_forbidden"
	var is_progression: bool = false
	if "progression" in target:
		is_progression = bool(target.get("progression"))
	if is_progression and String(actor_id).begins_with("echo."):
		return InteractionResult.failure(&"echo_forbidden")

	# 4. Call interact
	if target.has_method("interact"):
		target.call("interact", actor_id, interaction_id, payload)

	# 5. Emit interaction_applied with current tick
	var current_tick: int = _get_current_tick()
	interaction_applied.emit(current_tick, actor_id, target_id, interaction_id, payload)

	return InteractionResult.success()


## Dispatch trigger enter event for an actor.
func trigger_enter(actor_id: StringName, trigger_id: StringName) -> void:
	var current_tick: int = _get_current_tick()
	trigger_entered.emit(current_tick, actor_id, trigger_id)


## Dispatch trigger exit event for an actor.
func trigger_exit(actor_id: StringName, trigger_id: StringName) -> void:
	var current_tick: int = _get_current_tick()
	trigger_exited.emit(current_tick, actor_id, trigger_id)
