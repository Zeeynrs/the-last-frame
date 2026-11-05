class_name SecurityGatePresenter
extends Sprite2D

## Visual presenter for PlateLinkedGate (CH1-PZ-003) and PoweredDoor (CH1-SO-01, CH1-PZ-006).
## Binds to parent gate/door and selects closed vs open texture.

@export var tex_closed: Texture2D = preload("res://assets/props/ch01/ch01_prop_security_gate_closed.png")
@export var tex_open: Texture2D = preload("res://assets/props/ch01/ch01_prop_security_gate_open.png")
@export var sprite_offset: Vector2 = Vector2(-20, -42)

var _target: Node


func _ready() -> void:
	centered = false
	offset = sprite_offset
	_target = get_parent()
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent()
	if _target == null:
		return
	var is_open: bool = false
	if "gate_state" in _target:
		is_open = _target.gate_state == &"open" or not _target.passage_blocked
	elif "door_state" in _target:
		is_open = _target.door_state == &"open" or not _target.passage_blocked
	elif "passage_blocked" in _target:
		is_open = not _target.passage_blocked
	var next_tex: Texture2D = tex_open if is_open else tex_closed
	if texture != next_tex:
		texture = next_tex
