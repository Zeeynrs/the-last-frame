class_name CableConduitPresenter
extends Node

## Swaps cable conduit floor tiles between off (source 5) and on (source 6)
## when the powering condition for the room is active.

@export var floor_layer_path: NodePath = ^"../TileMapLayer_Floor"
@export var conduit_coords: Array[Vector2i] = []
@export var trigger_node_path: NodePath

const SOURCE_OFF: int = 5
const SOURCE_ON: int = 6

var _layer: TileMapLayer
var _trigger_node: Node
var _is_on: bool = false


func _ready() -> void:
	_layer = get_node_or_null(floor_layer_path) as TileMapLayer
	if not trigger_node_path.is_empty():
		_trigger_node = get_node_or_null(trigger_node_path)
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _layer == null:
		_layer = get_node_or_null(floor_layer_path) as TileMapLayer
		if _layer == null:
			return

	var powered: bool = false
	if _trigger_node == null and not trigger_node_path.is_empty():
		_trigger_node = get_node_or_null(trigger_node_path)

	if _trigger_node != null:
		if _trigger_node.has_method("is_occupied"):
			powered = _trigger_node.is_occupied()
		elif "bus_powered" in _trigger_node:
			powered = bool(_trigger_node.bus_powered)
		elif "relay_state" in _trigger_node and "state_b" in _trigger_node:
			powered = _trigger_node.relay_state == _trigger_node.state_b
		elif "shutter_state" in _trigger_node:
			powered = _trigger_node.shutter_state == &"raised"

	if powered != _is_on:
		_is_on = powered
		var source_id := SOURCE_ON if _is_on else SOURCE_OFF
		for cell in conduit_coords:
			_layer.set_cell(cell, source_id, Vector2i(0, 0), 0)
