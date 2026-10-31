class_name PocketWatch
extends Node2D

## Pocket watch controller per ADR-006, ADR-007, and ADR-015.
## Attached to Player. Handles ability selection, capability-preferring targeting,
## target highlighting, and dispatching watch interaction requests.

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

@export var unlocked_abilities: Array[StringName] = [&"trace", &"rewind", &"freeze"]:
	set(val):
		unlocked_abilities = []
		for ab in val:
			unlocked_abilities.append(StringName(ab))
@export var watch_radius: float = WATCH_RADIUS
@export var session: GameSession = null

var selected_ability: StringName = &"trace"
var current_target: Interactable = null
var last_result: InteractionResult = null

var _hud_label: Label = null


func _ready() -> void:
	if not unlocked_abilities.is_empty():
		# Start with the first unlocked ability matching the master order
		for ab in MASTER_CYCLE_ORDER:
			if ab == &"echo":
				continue
			if unlocked_abilities.has(ab):
				selected_ability = ab
				break
	_setup_hud()
	_update_hud()


func _physics_process(_delta: float) -> void:
	update_targeting()


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


## Cycles through unlocked abilities in the ADR-015 order.
## Direction: +1 for next, -1 for prev. Skips Echo until TLF-016.
func cycle_ability(direction: int = 1) -> void:
	if unlocked_abilities.is_empty():
		return

	var ordered: Array[StringName] = []
	for ab in MASTER_CYCLE_ORDER:
		if ab == &"echo":
			continue  # Echo record/playback is handled in TLF-016
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
	_update_hud()
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
		_update_hud()
		update_targeting()
		return true
	return false


## Selects the best watch target per ADR-015:
## 1. Filter candidates within watch_radius (default 96 px).
## 2. If any candidate supports the selected ability, pick the nearest of those.
## 3. Otherwise pick the nearest candidate overall so unsupported feedback stays teachable.
## 4. Break ties lexicographically by object_id.
static func choose_watch_target(from_pos: Vector2, candidates: Array, p_selected_ability: StringName, max_radius: float = WATCH_RADIUS) -> Interactable:
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


## Activates the selected watch ability on the current watch target.
func activate_watch() -> InteractionResult:
	if current_target == null:
		last_result = InteractionResult.failure(&"missing_target")
		watch_used.emit(selected_ability, &"", last_result)
		return last_result

	var sess = get_session()
	if sess == null or sess.interaction_service == null:
		last_result = InteractionResult.failure(&"missing_target")
		watch_used.emit(selected_ability, current_target.object_id, last_result)
		return last_result

	var result = sess.interaction_service.request(&"player", current_target.object_id, selected_ability)
	last_result = result
	watch_used.emit(selected_ability, current_target.object_id, result)
	return result


func _setup_hud() -> void:
	if _hud_label == null:
		_hud_label = Label.new()
		_hud_label.name = "WatchHUDLabel"
		_hud_label.position = Vector2(-60, -68)
		_hud_label.size = Vector2(120, 16)
		_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_hud_label.add_theme_font_size_override("font_size", 9)
		_hud_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		add_child(_hud_label)


func _update_hud() -> void:
	if _hud_label != null:
		_hud_label.text = "Watch: %s [Q]" % String(selected_ability).to_upper()
