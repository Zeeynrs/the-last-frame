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


## Press, hold, release (for is_action_just_pressed and _input handlers). Returns once the press
## has been handled, so its effect is observable.
## Input events are flushed once per idle frame, but one idle frame can run several physics
## steps; waiting a fixed number of physics frames could flush press and release together and
## lose the press (TLF-031). So: hold until Input reports the action pressed, let `frames`
## physics steps handle it, release, and let one more step run.
func tap(action: StringName, frames: int = 1) -> void:
	press(action)
	await until(func() -> bool: return Input.is_action_pressed(action), 30)
	await physics_frames(frames)
	release(action)
	await until(func() -> bool: return not Input.is_action_pressed(action), 30)
	await physics_frames(1)


## Called by the runner after every test (even a failed or timed-out one).
func release_all_input() -> void:
	# walk_context is usually a lambda capturing this test instance; clearing it breaks the cycle.
	walk_context = Callable()
	_held_moves.clear()
	for action in _pressed_actions.duplicate():
		release(action)


# --- real-input movement (TLF-030/031) -----------------------------------------------------

const WALK_TOLERANCE := 3.0
## Frames without moving at least WALK_STUCK_DISTANCE before a walk counts as blocked.
const WALK_STUCK_FRAMES := 30
const WALK_STUCK_DISTANCE := 1.0
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

## Optional: returns extra context (e.g. the current room) for walk failure messages.
var walk_context: Callable = Callable()

var _held_moves: Array[StringName] = []


## The 8 directions the player can move in, with the move actions that produce them.
static func move_directions() -> Array:
	var out: Array = []
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			if x == 0 and y == 0:
				continue
			var actions: Array[StringName] = []
			if x < 0: actions.append(&"move_left")
			if x > 0: actions.append(&"move_right")
			if y < 0: actions.append(&"move_up")
			if y > 0: actions.append(&"move_down")
			out.append({"dir": Player.compute_movement_vector(Vector2(x, y)), "actions": actions})
	return out


## Holds exactly `actions` among the move actions (presses new ones, releases the rest).
func hold_moves(actions: Array[StringName]) -> void:
	for action in _held_moves.duplicate():
		if not actions.has(action):
			release(action)
			_held_moves.erase(action)
	for action in actions:
		if not _held_moves.has(action):
			press(action)
			_held_moves.append(action)


## Holds the move direction that heads most directly from `player` toward `target`.
func steer(player: Node2D, target: Vector2) -> void:
	var delta := target - player.global_position
	var best: Array[StringName] = []
	var best_score := -INF
	for d in move_directions():
		var score: float = d["dir"].dot(delta.normalized())
		if score > best_score:
			best_score = score
			best = d["actions"]
	hold_moves(best)


## Walks `player` toward `target` with the move actions only. Returns true when `stop_when`
## holds (if given) or when within WALK_TOLERANCE (if not). If it arrives and `stop_when` is
## still false after a short wait, or the player stops making progress (a layout bug), or
## max_frames runs out, it fails the test with positions and returns false; with `blocked_ok`
## it returns false without failing.
func walk_to(player: Node2D, label: String, target: Vector2, stop_when: Callable = Callable(),
		max_frames: int = 900, blocked_ok: bool = false) -> bool:
	var anchor_pos := player.global_position
	var still_frames := 0
	var problem := ""
	for i in max_frames:
		if aborted:
			return false
		if stop_when.is_valid() and stop_when.call():
			hold_moves([])
			return true
		if player.global_position.distance_to(target) <= WALK_TOLERANCE:
			hold_moves([])
			if not stop_when.is_valid():
				return true
			if await until(stop_when, 10):
				return true
			problem = "reached %s but the stop condition did not hold" % target
			break
		steer(player, target)
		await physics_frames(1)
		if player.global_position.distance_to(anchor_pos) >= WALK_STUCK_DISTANCE:
			anchor_pos = player.global_position
			still_frames = 0
		else:
			still_frames += 1
			if still_frames >= WALK_STUCK_FRAMES:
				problem = "player blocked at %s while walking to %s" % [player.global_position, target]
				break
	hold_moves([])
	if problem.is_empty():
		problem = "did not reach %s within %d frames (player at %s)" % [target, max_frames, player.global_position]
	if not blocked_ok:
		var context := " in %s" % walk_context.call() if walk_context.is_valid() else ""
		assert_helper.fail("%s: %s%s" % [label, problem, context])
	return false


## True while a blocking DialogueBox line or the DocumentViewer is open (TLF-032 UI).
func blocking_ui_open() -> bool:
	var root := _tree().root
	var diag := root.find_child("DialogueBox", true, false) as DialogueBox
	if diag != null and diag.is_active and diag.is_blocking:
		return true
	var viewer := root.find_child("DocumentViewer", true, false) as DocumentViewer
	return viewer != null and viewer.is_open


## Advances blocking UI with real input until none is open: `interact` for dialogue lines and
## document pages, `cancel` on a document's last page (the viewer's close prompt). Closing with
## `interact` instead reopens a document the player stands next to on the next physics frame
## (reported in TLF-031). Returns the number of taps; fails the test after `max_taps`.
func dismiss_blocking_ui(max_taps: int = 40) -> int:
	var taps := 0
	while blocking_ui_open():
		if aborted:
			return taps
		if taps >= max_taps:
			assert_helper.fail("blocking dialogue/document still open after %d taps" % max_taps)
			return taps
		var viewer := _tree().root.find_child("DocumentViewer", true, false) as DocumentViewer
		if viewer != null and viewer.is_open and viewer.current_page_index + 1 >= viewer.pages.size():
			await tap(&"cancel")
		else:
			await tap(&"interact")
		taps += 1
	return taps


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
