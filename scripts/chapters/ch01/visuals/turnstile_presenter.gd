class_name TurnstilePresenter
extends Sprite2D

## Visual presenter for TurnstileGate (CH1-PZ-001).
## Binds to parent TurnstileGate and selects collapsed vs open texture.

@export var tex_collapsed: Texture2D = preload("res://assets/props/ch01/ch01_prop_turnstile_gate_collapsed.png")
@export var tex_open: Texture2D = preload("res://assets/props/ch01/ch01_prop_turnstile_gate_open.png")

var _target: TurnstileGate


func _ready() -> void:
	centered = false
	offset = Vector2(-16, -34)
	_target = get_parent() as TurnstileGate
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as TurnstileGate
	if _target == null:
		return
	var is_open: bool = _target.arm_state == &"open" or not _target.passage_blocked
	var next_tex: Texture2D = tex_open if is_open else tex_collapsed
	if texture != next_tex:
		texture = next_tex
