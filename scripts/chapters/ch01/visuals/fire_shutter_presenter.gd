class_name FireShutterPresenter
extends Sprite2D

## Visual presenter for FireShutter (CH1-PZ-002).
## Binds to parent FireShutter and selects closed vs raised texture.

@export var tex_closed: Texture2D = preload("res://assets/props/ch01/ch01_prop_fire_shutter_closed.png")
@export var tex_raised: Texture2D = preload("res://assets/props/ch01/ch01_prop_fire_shutter_raised.png")

var _target: FireShutter


func _ready() -> void:
	centered = false
	offset = Vector2(-32, -56)
	_target = get_parent() as FireShutter
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as FireShutter
	if _target == null:
		return
	var is_raised: bool = _target.shutter_state == &"raised"
	var next_tex: Texture2D = tex_raised if is_raised else tex_closed
	if texture != next_tex:
		texture = next_tex
