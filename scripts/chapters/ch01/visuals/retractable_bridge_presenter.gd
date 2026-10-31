class_name RetractableBridgePresenter
extends Sprite2D

## Visual presenter for RetractableBridge (CH1-PZ-003).
## Binds to parent RetractableBridge and selects retracted vs extended texture.
## Pivot is offset by +(0, 8) per placement sheet §0.6 / TLF-041.

@export var tex_retracted: Texture2D = preload("res://assets/props/ch01/ch01_prop_bridge_platform_retracted.png")
@export var tex_extended: Texture2D = preload("res://assets/props/ch01/ch01_prop_bridge_platform_extended.png")

var _target: RetractableBridge


func _ready() -> void:
	centered = false
	offset = Vector2(-24, -10)
	_target = get_parent() as RetractableBridge
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as RetractableBridge
	if _target == null:
		return
	var is_extended: bool = _target.platform_state == &"extended" or _target.walkable
	var next_tex: Texture2D = tex_extended if is_extended else tex_retracted
	if texture != next_tex:
		texture = next_tex
