extends RefCounted

## Shared assertion wrappers and session fixtures for tests (TD-002).
## The runner injects assert_helper and scene_tree into every test instance.
## Not discovered as a test file itself (name does not start with "test_").

var assert_helper: RefCounted
var scene_tree: SceneTree


func _assert_eq(actual, expected, msg: String = "") -> bool:
	return assert_helper.assert_eq(actual, expected, msg)


func _assert_true(cond: bool, msg: String = "") -> bool:
	return assert_helper.assert_true(cond, msg)


func _assert_false(cond: bool, msg: String = "") -> bool:
	return assert_helper.assert_false(cond, msg)


func _tree() -> SceneTree:
	return scene_tree if scene_tree != null else Engine.get_main_loop() as SceneTree


## Builds a GameSession with SimClock, IdRegistry and InteractionService under the tree root.
func make_session() -> GameSession:
	var session := GameSession.new()
	var clock := SimClock.new()
	clock.name = "SimClock"
	var registry := IdRegistry.new()
	registry.name = "IdRegistry"
	var service := InteractionService.new()
	service.name = "InteractionService"
	service.id_registry = registry
	service.sim_clock = clock
	session.add_child(clock)
	session.add_child(registry)
	session.add_child(service)
	session.sim_clock = clock
	session.id_registry = registry
	session.interaction_service = service
	_tree().root.add_child(session)
	return session


func free_session(session: GameSession) -> void:
	if session.get_parent() != null:
		session.get_parent().remove_child(session)
	session.free()


func make_temporal(capabilities: int, fields: Array, history: Array = []) -> TemporalComponent:
	var temporal := TemporalComponent.new()
	temporal.name = "Temporal"
	temporal.capabilities = capabilities
	temporal.state_fields = PackedStringArray(fields)
	var typed: Array[Dictionary] = []
	for entry in history:
		typed.append(entry)
	temporal.initial_history = typed
	return temporal


## Adds an Interactable (with optional TemporalComponent) to the session so it registers.
func spawn(session: GameSession, node: Interactable, id: StringName, temporal: TemporalComponent = null) -> Interactable:
	node.object_id = id
	node.name = String(id).replace(".", "_")
	if temporal != null:
		node.add_child(temporal)
	session.add_child(node)
	return node
