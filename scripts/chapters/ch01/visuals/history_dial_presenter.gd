class_name HistoryDialPresenter
extends Sprite2D

## Visual presenter for HistoryDial (CH1-PZ-006).

@export var tex_idle: Texture2D
@export var tex_jammed: Texture2D

var _target: HistoryDial


func _ready() -> void:
	centered = false
	offset = Vector2.ZERO
	_target = get_parent() as HistoryDial
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as HistoryDial
	if _target == null:
		return
	var next_tex: Texture2D = tex_idle
	if texture != next_tex:
		texture = next_tex
