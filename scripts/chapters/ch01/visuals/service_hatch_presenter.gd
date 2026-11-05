class_name ServiceHatchPresenter
extends Sprite2D

## Visual presenter for service hatch (hatch_01, CH1-SO-02).
## Selects closed, open, frozen_closed, frozen_open textures.

@export var tex_closed: Texture2D = preload("res://assets/props/ch01/ch01_prop_service_hatch_closed.png")
@export var tex_open: Texture2D = preload("res://assets/props/ch01/ch01_prop_service_hatch_open.png")
@export var tex_frozen_closed: Texture2D = preload("res://assets/props/ch01/ch01_prop_service_hatch_frozen_closed.png")
@export var tex_frozen_open: Texture2D = preload("res://assets/props/ch01/ch01_prop_service_hatch_frozen_open.png")

var _target: PlateLinkedGate


func _ready() -> void:
	centered = false
	offset = Vector2(-16, -56)
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
	var frozen: bool = _target.is_frozen()
	var next_tex: Texture2D = tex_closed
	if frozen:
		next_tex = tex_frozen_open if is_open else tex_frozen_closed
	else:
		next_tex = tex_open if is_open else tex_closed
	if texture != next_tex:
		texture = next_tex
