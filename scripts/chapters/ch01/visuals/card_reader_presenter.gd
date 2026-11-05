class_name CardReaderPresenter
extends Sprite2D

## Visual presenter for CardReader (card_reader_01, CH1-PZ-003).

@export var tex_idle: Texture2D = preload("res://assets/props/ch01/ch01_prop_card_reader_idle.png")
@export var tex_accepted: Texture2D = preload("res://assets/props/ch01/ch01_prop_card_reader_accepted.png")

var _target: CardReader


func _ready() -> void:
	centered = false
	offset = Vector2(-8, -20)
	_target = get_parent() as CardReader
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as CardReader
	if _target == null:
		return
	var is_accepted: bool = _target.grid_online or _target.latched_solved
	var next_tex: Texture2D = tex_accepted if is_accepted else tex_idle
	if texture != next_tex:
		texture = next_tex
