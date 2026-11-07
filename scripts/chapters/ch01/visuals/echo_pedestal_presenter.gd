class_name EchoPedestalPresenter
extends Sprite2D

## Visual presenter for echo_recorder_pedestal (ProgressionPickup, CH1-PZ-003).
## Keeps sprite visible; switches to used texture on collection.

@export var tex_idle: Texture2D = preload("res://assets/props/ch01/ch01_prop_echo_pedestal_idle.png")
@export var tex_used: Texture2D = preload("res://assets/props/ch01/ch01_prop_echo_pedestal_used.png")

var _target: ProgressionPickup


func _ready() -> void:
	centered = false
	offset = Vector2(-12, -30)
	_target = get_parent() as ProgressionPickup
	if _target != null:
		_target.collected_changed.connect(func(_col): _refresh())
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as ProgressionPickup
	if _target == null:
		return
	# Keep visible at all times
	visible = true
	var used: bool = _target.is_collected()
	var next_tex: Texture2D = tex_used if used else tex_idle
	if texture != next_tex:
		texture = next_tex
