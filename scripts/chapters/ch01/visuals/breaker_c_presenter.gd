class_name BreakerCPresenter
extends Sprite2D

## Visual presenter for LampRingBreaker (breaker_c, CH1-PZ-004).

@export var tex_idle: Texture2D = preload("res://assets/props/ch01/ch01_prop_breaker_c_idle.png")
@export var tex_browned_out: Texture2D = preload("res://assets/props/ch01/ch01_prop_breaker_c_browned_out.png")
@export var tex_engaged: Texture2D = preload("res://assets/props/ch01/ch01_prop_breaker_c_engaged.png")

var _target: LampRingBreaker


func _ready() -> void:
	centered = false
	offset = Vector2(-12, -32)
	_target = get_parent() as LampRingBreaker
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as LampRingBreaker
	if _target == null:
		return
	var capacitor = _target.resolve(_target.capacitor_id) as SurgeCapacitor
	var next_tex: Texture2D = tex_idle
	if capacitor != null and not capacitor.bus_powered and capacitor.charge_state != &"charged":
		next_tex = tex_browned_out
	if texture != next_tex:
		texture = next_tex
