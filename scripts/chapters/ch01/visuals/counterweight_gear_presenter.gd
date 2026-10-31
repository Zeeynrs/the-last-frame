class_name CounterweightGearPresenter
extends Sprite2D

## Visual presenter for CounterweightGear (CH1-PZ-002).
## Binds to parent CounterweightGear and selects idle vs slipping vs frozen texture.

@export var tex_idle: Texture2D = preload("res://assets/props/ch01/ch01_prop_counterweight_gear_idle.png")
@export var tex_slipping: Texture2D = preload("res://assets/props/ch01/ch01_prop_counterweight_gear_slipping.png")
@export var tex_frozen: Texture2D = preload("res://assets/props/ch01/ch01_prop_counterweight_gear_frozen.png")

var _target: CounterweightGear


func _ready() -> void:
	centered = false
	offset = Vector2(-32, -56)
	_target = get_parent() as CounterweightGear
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as CounterweightGear
	if _target == null:
		return
	var is_frozen_or_locked: bool = (_target.has_method("is_frozen") and _target.is_frozen()) or _target.gear_state == &"locked"
	var next_tex: Texture2D = tex_idle
	if is_frozen_or_locked:
		next_tex = tex_frozen
	elif _target.gear_state == &"slipping":
		next_tex = tex_slipping
	if texture != next_tex:
		texture = next_tex
