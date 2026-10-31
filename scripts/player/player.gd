class_name Player
extends CharacterBody2D

## Playable protagonist controller per TLF-007 and TLF-018.
## Implements 8-direction screen-relative isometric movement, deterministic targeting,
## PocketWatch abilities integration, and feedback toast / dynamic prompt presentation.

@export var walk_speed: float = 120.0
@export var actor_id: StringName = &"player"

@onready var interaction_detector: Area2D = get_node_or_null("InteractionDetector")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var pocket_watch: PocketWatch = get_node_or_null("PocketWatch")
@onready var sprite: AnimatedSprite2D = get_node_or_null("Sprite")

var hud: HUD = null
var facing_direction: String = "s"

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

	_setup_hud()


func _setup_hud() -> void:
	if hud == null and is_inside_tree():
		var existing = get_tree().root.find_child("HUD", true, false)
		if existing is HUD:
			hud = existing as HUD
		else:
			var hud_res = load("res://scenes/ui/HUD.tscn")
			if hud_res != null:
				hud = hud_res.instantiate() as HUD
				add_child(hud)

	if hud != null:
		hud.bind_pocket_watch(pocket_watch)
		var session = get_tree().get_first_node_in_group(&"game_session")
		if session != null and "echo_service" in session:
			hud.bind_echo_service(session.echo_service)


func _physics_process(_delta: float) -> void:
	_handle_movement()
	_update_targeting()
	_handle_interaction()


func _handle_movement() -> void:
	var raw_input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var move_dir = compute_movement_vector(raw_input)
	velocity = move_dir * walk_speed
	move_and_slide()
	_update_animation(move_dir)


func _update_animation(move_dir: Vector2) -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return

	var is_moving = move_dir.length_squared() > 0.01
	if is_moving:
		facing_direction = direction_tag_from_vector(move_dir)
		var anim = &"walk_" + facing_direction
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)
	else:
		var anim = &"idle_" + facing_direction
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)


static func direction_tag_from_vector(v: Vector2) -> String:
	if v.length_squared() < 0.01:
		return "s"
	var sign_x = sign(v.x) if abs(v.x) > 0.3 else 0.0
	var sign_y = sign(v.y) if abs(v.y) > 0.3 else 0.0
	if sign_x > 0.0 and sign_y > 0.0:
		return "se"
	elif sign_x > 0.0 and sign_y < 0.0:
		return "ne"
	elif sign_x < 0.0 and sign_y > 0.0:
		return "sw"
	elif sign_x < 0.0 and sign_y < 0.0:
		return "nw"
	elif sign_x > 0.0:
		return "e"
	elif sign_x < 0.0:
		return "w"
	elif sign_y < 0.0:
		return "n"
	else:
		return "s"


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
			_update_prompt_on_target(current_target)
	elif current_target != null and is_instance_valid(current_target):
		_update_prompt_on_target(current_target)


func _update_prompt_on_target(target: Interactable) -> void:
	if target == null:
		return
	var label_node = target.get_node_or_null("PromptLabel")
	if label_node is Label:
		var glyph = InputPrompts.get_action_glyph(&"interact")
		var raw_text = target.prompt_text
		if raw_text.begins_with("[E] "):
			label_node.text = "%s %s" % [glyph, raw_text.substr(4)]
		elif raw_text != "":
			label_node.text = "%s %s" % [glyph, raw_text]


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
				var res = session.interaction_service.request(actor_id, current_target.object_id, &"use")
				if res != null and not res.ok and hud != null:
					hud.show_feedback(res.reason)

	if Input.is_action_just_pressed(&"watch"):
		if pocket_watch != null:
			var res = pocket_watch.activate_watch()
			if res != null and not res.ok and hud != null:
				hud.show_feedback(res.reason)

	if Input.is_action_just_pressed(&"ability_next"):
		if pocket_watch != null:
			pocket_watch.next_ability()

	if Input.is_action_just_pressed(&"ability_prev"):
		if pocket_watch != null:
			pocket_watch.prev_ability()

	if Input.is_action_just_pressed(&"echo_reset"):
		if pocket_watch != null:
			pocket_watch.reset_echo()
