class_name SecurityGatePresenter
extends Sprite2D

## Visual presenter for PlateLinkedGate (CH1-PZ-003).
## Binds to parent PlateLinkedGate and selects closed vs open texture.

@export var tex_closed: Texture2D = preload("res://assets/props/ch01/ch01_prop_security_gate_closed.png")
@export var tex_open: Texture2D = preload("res://assets/props/ch01/ch01_prop_security_gate_open.png")

var _target: PlateLinkedGate


func _ready() -> void:
	centered = false
	offset = Vector2(-20, -42)
	_target = get_parent() as PlateLinkedGate
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as PlateLinkedGate
	if _target == null:
		return
	var is_open: bool = _target.gate_state == &"open" or not _target.passage_blocked
	var next_tex: Texture2D = tex_open if is_open else tex_closed
	if texture != next_tex:
		texture = next_tex
