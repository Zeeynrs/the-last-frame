class_name Player
extends CharacterBody2D

## Playable protagonist controller per TLF-007.
## Implements 8-direction screen-relative isometric movement and deterministic targeting.

@export var walk_speed: float = 120.0
@export var actor_id: StringName = &"player"

@onready var interaction_detector: Area2D = $InteractionDetector
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pocket_watch: PocketWatch = get_node_or_null("PocketWatch")

var _candidates: Array[Interactable] = []
var current_target: Interactable = null


func _ready() -> void:
	if interaction_detector != null:
		interaction_detector.area_entered.connect(_on_interaction_area_entered)
		interaction_detector.area_exited.connect(_on_interaction_area_exited)

	if pocket_watch == null:
		pocket_watch = PocketWatch.new()
		pocket_watch.name = "PocketWatch"
		add_child(pocket_watch)


func _physics_process(_delta: float) -> void:
	_handle_movement()
	_update_targeting()
	_handle_interaction()


func _handle_movement() -> void:
	var raw_input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var move_dir = compute_movement_vector(raw_input)
	velocity = move_dir * walk_speed
	move_and_slide()


## Maps screen-relative input into 8 directions with 2:1 isometric diagonal ratio.
static func compute_movement_vector(raw_input: Vector2) -> Vector2:
	if raw_input.length_squared() < 0.04:
		return Vector2.ZERO

	var sign_x = sign(raw_input.x) if abs(raw_input.x) > 0.3 else 0.0
	var sign_y = sign(raw_input.y) if abs(raw_input.y) > 0.3 else 0.0

	if sign_x != 0.0 and sign_y != 0.0:
		# Diagonal: 2:1 isometric axis ratio
		return Vector2(sign_x * 2.0, sign_y * 1.0).normalized()
	elif sign_x != 0.0:
		return Vector2(sign_x, 0.0)
	elif sign_y != 0.0:
		return Vector2(0.0, sign_y)

	return raw_input.normalized()


func _on_interaction_area_entered(area: Area2D) -> void:
	if area is Interactable and not _candidates.has(area):
		_candidates.append(area)


func _on_interaction_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_candidates.erase(area)


func _update_targeting() -> void:
	# Filter out any candidates that became invalid or queued for deletion
	_candidates = _candidates.filter(func(c): return is_instance_valid(c) and c.is_inside_tree())

	var best = choose_best_interactable(global_position, _candidates)
	if best != current_target:
		if current_target != null and is_instance_valid(current_target):
			current_target.set_focused(false)
		current_target = best
		if current_target != null:
			current_target.set_focused(true)


## Chooses the closest Interactable; breaks ties lexicographically by object_id.
static func choose_best_interactable(from_pos: Vector2, candidates: Array) -> Interactable:
	if candidates.is_empty():
		return null

	var best: Interactable = null
	var best_dist: float = INF

	for c in candidates:
		if not (c is Interactable):
			continue
		var dist = from_pos.distance_to(c.global_position)
		if dist < best_dist - 0.001:
			best_dist = dist
			best = c
		elif abs(dist - best_dist) <= 0.001:
			# Tie-break: lexicographically smallest object_id
			if best == null or String(c.object_id) < String(best.object_id):
				best_dist = dist
				best = c

	return best


func _handle_interaction() -> void:
	if Input.is_action_just_pressed(&"interact"):
		if current_target != null:
			var session = get_tree().get_first_node_in_group(&"game_session")
			if session != null and "interaction_service" in session and session.interaction_service != null:
				session.interaction_service.request(actor_id, current_target.object_id, &"use")

	if Input.is_action_just_pressed(&"watch"):
		if pocket_watch != null:
			pocket_watch.activate_watch()

	if Input.is_action_just_pressed(&"ability_next"):
		if pocket_watch != null:
			pocket_watch.next_ability()

	if Input.is_action_just_pressed(&"ability_prev"):
		if pocket_watch != null:
			pocket_watch.prev_ability()
