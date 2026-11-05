class_name CommuterStatuePresenter
extends Sprite2D

## Visual presenter for frozen commuter statues (TraceMemory).
## Switches between idle and read (revealed outline) textures.

@export var tex_idle: Texture2D
@export var tex_read: Texture2D

var _target: TraceMemory


func _ready() -> void:
	centered = false
	offset = Vector2(-8, -36)
	_target = get_parent() as TraceMemory
	if _target != null:
		_target.memory_revealed.connect(func(_id): _refresh())
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as TraceMemory
	if _target == null:
		return
	var revealed: bool = _target.is_revealed()
	var next_tex: Texture2D = tex_read if revealed else tex_idle
	if texture != next_tex:
		texture = next_tex
