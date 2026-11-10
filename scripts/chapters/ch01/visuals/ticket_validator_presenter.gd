class_name TicketValidatorPresenter
extends Sprite2D

## Visual presenter for TicketValidator (ticket_validator, CH1-PZ-006).

@export var tex_idle: Texture2D = preload("res://assets/props/ch01/ch01_prop_ticket_validator_n_idle.png")
@export var tex_accepted: Texture2D = preload("res://assets/props/ch01/ch01_prop_ticket_validator_n_accepted.png")
@export var tex_rejecting: Texture2D = preload("res://assets/props/ch01/ch01_prop_ticket_validator_n_rejecting.png")

var _target: TicketValidator


func _ready() -> void:
	centered = false
	offset = Vector2(-16, -42)
	_target = get_parent() as TicketValidator
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _target == null:
		_target = get_parent() as TicketValidator
	if _target == null:
		return
	var is_accepted: bool = _target.accepted or _target.latched_solved
	var next_tex: Texture2D = tex_accepted if is_accepted else tex_idle
	if texture != next_tex:
		texture = next_tex
