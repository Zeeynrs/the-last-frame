class_name SelectorSwitchPresenter
extends Sprite2D

## Visual presenter for SelectorSwitch (CH1-SO-01).
## Selects texture based on target.selector_position.

@export var textures: Array[Texture2D] = []

var _target: SelectorSwitch


func _ready() -> void:
	centered = false
	offset = Vector2(-16, -40)   # canonical pivot (16, 40) (ASSET_METADATA)
	_target = get_parent() as SelectorSwitch
	if _target != null:
		_target.changed.connect(func(_pos): _refresh())
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as SelectorSwitch
	if _target == null:
		return
	var pos := _target.selector_position
	if pos >= 0 and pos < textures.size():
		var next_tex: Texture2D = textures[pos]
		if texture != next_tex:
			texture = next_tex
