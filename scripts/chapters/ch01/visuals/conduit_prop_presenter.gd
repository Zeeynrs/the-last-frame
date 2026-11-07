class_name ConduitPropPresenter
extends Sprite2D

## Visual presenter for ConduitProp (conduit_01, CH1-PZ-001).

@export var tex_fallen: Texture2D = preload("res://assets/props/ch01/ch01_prop_conduit_fallen.png")
@export var tex_mounted: Texture2D = preload("res://assets/props/ch01/ch01_prop_conduit_mounted.png")

var _target: ConduitProp


func _ready() -> void:
	centered = false
	offset = Vector2(-24, -26)
	_target = get_parent() as ConduitProp
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as ConduitProp
	if _target == null:
		return
	var is_mounted: bool = _target.conduit_state == &"mounted"
	var next_tex: Texture2D = tex_mounted if is_mounted else tex_fallen
	if texture != next_tex:
		texture = next_tex
