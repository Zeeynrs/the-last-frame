extends RefCounted

## Shared assertion wrappers and session fixtures for tests (TD-002).
## The runner injects assert_helper and scene_tree into every test instance.
## Not discovered as a test file itself (name does not start with "test_").

var assert_helper: RefCounted
var scene_tree: SceneTree
## Frame budget for an awaited test before the runner fails it (TLF-029).
var timeout_frames: int = 3600
## Set by the runner when this test timed out: helpers stop waiting and stop pressing input.
var aborted: bool = false

var _pressed_actions: Array[StringName] = []


func _assert_eq(actual, expected, msg: String = "") -> bool:
	return assert_helper.assert_eq(actual, expected, msg)


func _assert_true(cond: bool, msg: String = "") -> bool:
	return assert_helper.assert_true(cond, msg)


func _assert_false(cond: bool, msg: String = "") -> bool:
	return assert_helper.assert_false(cond, msg)


func _tree() -> SceneTree:
	return scene_tree if scene_tree != null else Engine.get_main_loop() as SceneTree


## Frame stepping (TLF-029). `await physics_frames(n)` lets physics, input and timers run.
func physics_frames(n: int = 1) -> void:
	for i in n:
		if aborted:
			return
		await _tree().physics_frame


## Polls `condition` once per physics frame; true as soon as it holds, false after max_frames.
## Use as `_assert_true(await until(func(): return x, 120), "x happened")`.
func until(condition: Callable, max_frames: int = 600) -> bool:
	for i in max_frames:
		if aborted:
			return false
		if condition.call():
			return true
		await _tree().physics_frame
	return condition.call()


## Presses an input action as a real InputEventAction (Input state + _input dispatch).
## The runner releases everything after the test, even when it fails.
func press(action: StringName, strength: float = 1.0) -> void:
	if aborted:
		return
	_send_action(action, true, strength)
	if not _pressed_actions.has(action):
		_pressed_actions.append(action)


func release(action: StringName) -> void:
	_send_action(action, false, 0.0)
	_pressed_actions.erase(action)


## Press, hold for `frames` physics frames, release (for is_action_just_pressed handlers).
func tap(action: StringName, frames: int = 1) -> void:
	press(action)
	await physics_frames(frames)
	release(action)


func release_all_input() -> void:
	for action in _pressed_actions.duplicate():
		release(action)


func _send_action(action: StringName, pressed: bool, strength: float) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = strength
	Input.parse_input_event(event)


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
	var echo := EchoService.new()
	echo.name = "EchoService"
	session.add_child(echo)
	echo.bind(clock, service)
	session.sim_clock = clock
	session.id_registry = registry
	session.interaction_service = service
	session.echo_service = echo
	var puzzles := PuzzleService.new()
	puzzles.name = "PuzzleService"
	puzzles.sim_clock = clock
	puzzles.echo_service = echo
	session.add_child(puzzles)
	session.puzzle_service = puzzles
	var narrative := NarrativeState.new()
	narrative.name = "NarrativeState"
	session.add_child(narrative)
	session.narrative_state = narrative
	var spatial := SpatialService.new()
	spatial.name = "SpatialService"
	session.add_child(spatial)
	session.spatial_service = spatial
	var hints := HintService.new()
	hints.name = "HintService"
	hints.sim_clock = clock
	hints.puzzle_service = puzzles
	session.add_child(hints)
	session.hint_service = hints
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
