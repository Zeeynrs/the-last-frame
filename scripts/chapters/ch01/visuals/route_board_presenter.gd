class_name RouteBoardPresenter
extends Sprite2D

## Visual presenter for route_board in Upper Vestibule (CH1-PZ-005).
## Derived from the two levers' relay_state per placement sheet §11.

@export var tex_state0: Texture2D = preload("res://assets/props/ch01/ch01_prop_route_board_state0.png")
@export var tex_state1: Texture2D = preload("res://assets/props/ch01/ch01_prop_route_board_state1.png")
@export var tex_state2: Texture2D = preload("res://assets/props/ch01/ch01_prop_route_board_state2.png")

var _lever_a: Node
var _lever_b: Node


func _ready() -> void:
	centered = false
	offset = Vector2(-24, -50)
	_resolve_levers()
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _resolve_levers() -> void:
	var room := get_parent()
	if room != null and not (room is JunctionLever):
		# If attached directly to route_board, room is parent's parent
		var room_node := room.get_parent() if room.name == "route_board" else room
		_lever_a = room_node.get_node_or_null("junction_lever_a")
		_lever_b = room_node.get_node_or_null("junction_lever_b")


func _refresh() -> void:
	if _lever_a == null or _lever_b == null:
		_resolve_levers()
	var state_a: StringName = _lever_a.relay_state if _lever_a != null and "relay_state" in _lever_a else &"loop"
	var state_b: StringName = _lever_b.relay_state if _lever_b != null and "relay_state" in _lever_b else &"niche"

	var next_tex: Texture2D = tex_state0
	if state_a == &"uncoupled":
		if state_b == &"atrium":
			next_tex = tex_state2
		else:
			next_tex = tex_state1
	else:
		next_tex = tex_state0

	if texture != next_tex:
		texture = next_tex
