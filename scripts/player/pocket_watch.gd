class_name PocketWatch
extends Node2D

## Pocket watch controller per ADR-006, ADR-007, ADR-008, and ADR-015.
## Attached to Player. Handles ability selection, capability-preferring targeting,
## target highlighting, Echo state machine driving, and dispatching watch interaction requests.

signal watch_used(ability: StringName, target_id: StringName, result: InteractionResult)
signal ability_changed(new_ability: StringName)
signal target_changed(new_target: Interactable)

const MASTER_CYCLE_ORDER: Array[StringName] = [
	&"trace",
	&"rewind",
	&"freeze",
	&"echo",
	&"fast_forward",
]

const WATCH_RADIUS: float = 96.0

@export var unlocked_abilities: Array = [&"trace", &"rewind", &"freeze", &"echo"]:
	set(val):
		unlocked_abilities = []
		for ab in val:
			unlocked_abilities.append(StringName(ab))
@export var watch_radius: float = WATCH_RADIUS
@export var session: GameSession = null

var selected_ability: StringName = &"trace"
var current_target: Interactable = null
var last_result: InteractionResult = null

var _ghost_node: Node2D = null


func _ready() -> void:
	if not unlocked_abilities.is_empty():
		for ab in MASTER_CYCLE_ORDER:
			if unlocked_abilities.has(ab):
				selected_ability = ab
				break
	_setup_ghost()


func _exit_tree() -> void:
	_cleanup_ghost()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_cleanup_ghost()


func _physics_process(_delta: float) -> void:
	update_targeting()
	_update_ghost_visibility()


## Locates the active GameSession via direct export, ancestor hierarchy, or tree group.
func get_session() -> GameSession:
	if session != null:
		return session

	var p = get_parent()
	while p != null:
		if p is GameSession:
			return p as GameSession
		if p.is_in_group(&"game_session") and "interaction_service" in p:
			return p as GameSession
		p = p.get_parent()

	if is_inside_tree():
		var tree = get_tree()
		if tree != null:
			var found = tree.get_first_node_in_group(&"game_session")
			if found != null:
				return found as GameSession

	return null


## Cycles through unlocked abilities in the ADR-015 order with wrap.
## Order: Trace -> Rewind -> Freeze -> Echo (-> Fast-Forward).
func cycle_ability(direction: int = 1) -> void:
	if unlocked_abilities.is_empty():
		return

	var ordered: Array[StringName] = []
	for ab in MASTER_CYCLE_ORDER:
		if unlocked_abilities.has(ab):
			ordered.append(ab)

	if ordered.is_empty():
		return

	var idx = ordered.find(selected_ability)
	if idx == -1:
		idx = 0
	else:
		idx = (idx + direction) % ordered.size()
		if idx < 0:
			idx += ordered.size()

	selected_ability = ordered[idx]
	ability_changed.emit(selected_ability)
	update_targeting()


func next_ability() -> void:
	cycle_ability(1)


func prev_ability() -> void:
	cycle_ability(-1)


## Sets the selected ability directly if unlocked.
func set_selected_ability(ability: StringName) -> bool:
	if unlocked_abilities.has(ability):
		selected_ability = ability
		ability_changed.emit(selected_ability)
		update_targeting()
		return true
	return false


## Selects the best watch target per ADR-015:
## 1. Filter candidates within watch_radius (default 96 px).
## 2. If any candidate supports the selected ability, pick the nearest of those.
## 3. Otherwise pick the nearest candidate overall so unsupported feedback stays teachable.
## 4. Break ties lexicographically by object_id.
static func choose_watch_target(from_pos: Vector2, candidates: Array, p_selected_ability: StringName, max_radius: float = WATCH_RADIUS) -> Interactable:
	if p_selected_ability == &"echo":
		return null

	var in_range: Array[Interactable] = []
	for c in candidates:
		if not (c is Interactable):
			continue
		if is_instance_valid(c) and from_pos.distance_to(c.global_position) <= max_radius:
			in_range.append(c)

	if in_range.is_empty():
		return null

	var supporting: Array[Interactable] = []
	for c in in_range:
		if c.supports_ability(p_selected_ability):
			supporting.append(c)

	var pool = supporting if not supporting.is_empty() else in_range
	return _find_nearest(from_pos, pool)


static func _find_nearest(from_pos: Vector2, pool: Array[Interactable]) -> Interactable:
	var best: Interactable = null
	var best_dist: float = INF

	for c in pool:
		var dist = from_pos.distance_to(c.global_position)
		if dist < best_dist - 0.001:
			best_dist = dist
			best = c
		elif abs(dist - best_dist) <= 0.001:
			if best == null or String(c.object_id) < String(best.object_id):
				best_dist = dist
				best = c

	return best


## Updates current watch targeting based on position and interactables in scene.
func update_targeting() -> void:
	if selected_ability == &"echo":
		if current_target != null:
			if is_instance_valid(current_target):
				current_target.set_watch_focused(false)
			current_target = null
			target_changed.emit(null)
		return

	var candidates: Array = []
	if is_inside_tree():
		candidates = get_tree().get_nodes_in_group(&"interactable")

	var best = choose_watch_target(global_position, candidates, selected_ability, watch_radius)
	if best != current_target:
		if current_target != null and is_instance_valid(current_target):
			current_target.set_watch_focused(false)
		current_target = best
		if current_target != null:
			current_target.set_watch_focused(true, selected_ability)
		target_changed.emit(current_target)
	elif current_target != null and is_instance_valid(current_target):
		current_target.set_watch_focused(true, selected_ability)


## Activates the selected watch ability.
## For Echo: drives the ADR-015 state machine (IDLE -> record, RECORDING -> stop, READY/PLAYING/HOLDING -> play).
## For other abilities: dispatches request on current watch target.
func activate_watch() -> InteractionResult:
	var sess = get_session()

	if selected_ability == &"echo":
		if sess == null or sess.echo_service == null:
			last_result = InteractionResult.failure(&"missing_target")
			watch_used.emit(&"echo", &"", last_result)
			return last_result

		var echo_svc = sess.echo_service
		match echo_svc.state:
			EchoService.State.IDLE:
				var parent_node = get_parent() as Node2D
				var res = echo_svc.start_recording(parent_node)
				if res == &"":
					last_result = InteractionResult.success()
				else:
					last_result = InteractionResult.failure(res)
			EchoService.State.RECORDING:
				var res = echo_svc.stop_recording()
				if res == &"":
					last_result = InteractionResult.success()
				else:
					last_result = InteractionResult.failure(res)
			EchoService.State.READY, EchoService.State.PLAYING, EchoService.State.HOLDING:
				var res = echo_svc.start_playback()
				if res == &"":
					last_result = InteractionResult.success()
				else:
					last_result = InteractionResult.failure(res)
			_:
				last_result = InteractionResult.failure(&"echo_busy")

		watch_used.emit(&"echo", &"echo.0", last_result)
		return last_result

	# Standard abilities (Trace, Rewind, Freeze, Fast-Forward)
	if current_target == null:
		last_result = InteractionResult.failure(&"missing_target")
		watch_used.emit(selected_ability, &"", last_result)
		return last_result

	if sess == null or sess.interaction_service == null:
		last_result = InteractionResult.failure(&"missing_target")
		watch_used.emit(selected_ability, current_target.object_id, last_result)
		return last_result

	var result = sess.interaction_service.request(&"player", current_target.object_id, selected_ability)
	last_result = result
	watch_used.emit(selected_ability, current_target.object_id, result)
	return result


## Resets echo from any state (echo_reset action).
func reset_echo() -> void:
	var sess = get_session()
	if sess != null and sess.echo_service != null:
		sess.echo_service.reset_echo()
		if _ghost_node != null:
			_ghost_node.visible = false


func _setup_ghost() -> void:
	if _ghost_node == null:
		_ghost_node = Node2D.new()
		_ghost_node.name = "GhostPlaceholder"
		_ghost_node.visible = false

		# Ghost visual placeholder: translucent purple body
		var rect = ColorRect.new()
		rect.name = "GhostVisual"
		rect.size = Vector2(16, 24)
		rect.position = Vector2(-8, -24)
		rect.color = Color(0.7, 0.4, 0.9, 0.55)
		_ghost_node.add_child(rect)

		var p = get_parent()
		var ghost_parent: Node = null
		if p != null and p.get_parent() != null:
			ghost_parent = p.get_parent()
		elif p != null:
			ghost_parent = p
		elif is_inside_tree():
			ghost_parent = get_tree().current_scene

		if ghost_parent != null:
			ghost_parent.add_child.call_deferred(_ghost_node)

		var sess = get_session()
		if sess != null and sess.echo_service != null:
			if not sess.echo_service.ghost_moved.is_connected(_on_ghost_moved):
				sess.echo_service.ghost_moved.connect(_on_ghost_moved)


func _cleanup_ghost() -> void:
	if _ghost_node != null and is_instance_valid(_ghost_node):
		if _ghost_node.get_parent() != null:
			_ghost_node.queue_free()
		else:
			_ghost_node.free()
		_ghost_node = null


func _on_ghost_moved(pos: Vector2) -> void:
	if _ghost_node != null:
		if _ghost_node.get_parent() == null:
			var p = get_parent()
			var ghost_parent: Node = p.get_parent() if (p != null and p.get_parent() != null) else p
			if ghost_parent != null:
				ghost_parent.add_child(_ghost_node)
		_ghost_node.global_position = pos
		_ghost_node.visible = true


func _update_ghost_visibility() -> void:
	var sess = get_session()
	if sess == null or sess.echo_service == null:
		if _ghost_node != null:
			_ghost_node.visible = false
		return

	if sess.echo_service.state in [EchoService.State.IDLE, EchoService.State.RECORDING]:
		if _ghost_node != null:
			_ghost_node.visible = false
	elif sess.echo_service.state in [EchoService.State.PLAYING, EchoService.State.HOLDING]:
		if _ghost_node != null:
			_ghost_node.visible = true
