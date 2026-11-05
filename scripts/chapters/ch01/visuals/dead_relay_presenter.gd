class_name DeadRelayPresenter
extends Sprite2D

## Visual presenter for DeadRelay (junction_lever_c, CH1-PZ-005).
## Draws freestanding at z_index = 10 (YSort_Actors).
## Switches to shake texture briefly when interaction_failed reports dead_relay.

@export var tex_idle: Texture2D = preload("res://assets/props/ch01/ch01_prop_dead_relay_c_idle.png")
@export var tex_shake: Texture2D = preload("res://assets/props/ch01/ch01_prop_dead_relay_c_shake.png")

var _target: DeadRelay
var _shake_timer: float = 0.0


func _ready() -> void:
	centered = false
	offset = Vector2(-12, -32)
	_target = get_parent() as DeadRelay
	_bind_interaction()
	_refresh()


func _bind_interaction() -> void:
	var tree = get_tree()
	if tree != null:
		var sess = tree.get_first_node_in_group(&"game_session")
		if sess != null and sess.interaction_service != null:
			sess.interaction_service.interaction_failed.connect(_on_interaction_failed)


func _on_interaction_failed(_tick: int, _actor_id: StringName, target_id: StringName, _iid: StringName, _reason: StringName) -> void:
	if _target != null and target_id == _target.object_id:
		_shake_timer = 0.4
		_refresh()


func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if _shake_timer <= 0.0:
			_refresh()


func _refresh() -> void:
	var is_shaking: bool = _shake_timer > 0.0
	var next_tex: Texture2D = tex_shake if is_shaking else tex_idle
	if texture != next_tex:
		texture = next_tex
