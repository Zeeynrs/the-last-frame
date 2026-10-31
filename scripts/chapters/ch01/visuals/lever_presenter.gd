class_name LeverPresenter
extends Sprite2D

## Visual presenter for JunctionLever (CH1-PZ-005) and TimedBreaker (CH1-PZ-004).
## Selects lever_switch_off vs on texture and manages optional A/B badge overlay.

@export var tex_off: Texture2D = preload("res://assets/props/ch01/ch01_prop_lever_switch_off.png")
@export var tex_on: Texture2D = preload("res://assets/props/ch01/ch01_prop_lever_switch_on.png")
@export var badge_type: StringName = &"" # &"a" or &"b"

var _target: Node
var _badge_sprite: Sprite2D


func _ready() -> void:
	centered = false
	offset = Vector2(-12, -28)
	_target = get_parent()
	_setup_badge()
	_refresh()


func _setup_badge() -> void:
	if badge_type == &"":
		return
	if _badge_sprite == null:
		_badge_sprite = Sprite2D.new()
		_badge_sprite.name = "Badge"
		_badge_sprite.centered = false
		_badge_sprite.offset = Vector2(-2, -3)
		_badge_sprite.position = Vector2(3, -8)
		if badge_type == &"a":
			_badge_sprite.texture = preload("res://assets/props/ch01/ch01_prop_lever_badge_a_idle.png")
		elif badge_type == &"b":
			_badge_sprite.texture = preload("res://assets/props/ch01/ch01_prop_lever_badge_b_idle.png")
		add_child(_badge_sprite)


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent()
	if _target == null:
		return
	var is_on: bool = false
	if _target.has_method("is_engaged"):
		is_on = _target.is_engaged()
	elif "relay_state" in _target and "state_a" in _target:
		is_on = _target.relay_state != _target.state_a
	var next_tex: Texture2D = tex_on if is_on else tex_off
	if texture != next_tex:
		texture = next_tex
