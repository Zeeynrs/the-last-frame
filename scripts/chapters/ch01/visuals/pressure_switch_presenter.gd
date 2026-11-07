class_name PressureSwitchPresenter
extends Sprite2D

## Visual presenter for PressureSwitch (TriggerZone, CH1-PZ-003).
## Binds to parent TriggerZone and selects released vs pressed texture.

@export var tex_released: Texture2D = preload("res://assets/props/ch01/ch01_prop_pressure_switch_released.png")
@export var tex_pressed: Texture2D = preload("res://assets/props/ch01/ch01_prop_pressure_switch_pressed.png")
@export var sprite_offset: Vector2 = Vector2(-16, -12)

var _target: TriggerZone


func _ready() -> void:
	centered = false
	offset = sprite_offset
	_target = get_parent() as TriggerZone
	if _target != null:
		_target.occupancy_changed.connect(func(_occ: bool): _refresh())
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as TriggerZone
	if _target == null:
		return
	var occupied: bool = _target.is_occupied()
	var next_tex: Texture2D = tex_pressed if occupied else tex_released
	if texture != next_tex:
		texture = next_tex
