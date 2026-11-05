class_name ReleaseLeverPresenter
extends Sprite2D

## Visual presenter for ReleaseLever (CH1-SO-01).

@export var tex_idle: Texture2D = preload("res://assets/props/ch01/ch01_prop_release_lever_idle.png")
@export var tex_buzzing: Texture2D = preload("res://assets/props/ch01/ch01_prop_release_lever_buzzing.png")
@export var tex_accepted: Texture2D = preload("res://assets/props/ch01/ch01_prop_release_lever_accepted.png")

var _target: ReleaseLever


func _ready() -> void:
	centered = false
	offset = Vector2(-12, -28)
	_target = get_parent() as ReleaseLever
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as ReleaseLever
	if _target == null:
		return
	var lock = _target._lock()
	var next_tex: Texture2D = tex_idle
	if lock != null:
		if lock.unlocked or lock.latched_solved:
			next_tex = tex_accepted
		elif lock.current_tick() < lock.lockout_until_tick:
			next_tex = tex_buzzing
	if texture != next_tex:
		texture = next_tex
