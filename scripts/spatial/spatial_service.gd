class_name SpatialService
extends Node

## Session owner of the SpatialGraph (ADR-009, ADR-011) plus actor room tracking and safe relocation.
##
## Relocation rule (ADR-009 clarification, ADR-016): after a committed change, any tracked actor whose
## room is no longer reachable from the session's anchor room is asked to move to that room's
## relocation anchor (`relocate_requested`). Movement itself is done by whoever owns the actor.

signal graph_changed(affected_rooms: Array[StringName])
signal relocate_requested(actor_id: StringName, anchor_id: StringName)
signal actor_room_changed(actor_id: StringName, room_id: StringName)

var graph: SpatialGraph = SpatialGraph.new()
## Reachability reference for relocation (usually the room the chapter path starts from).
var anchor_room: StringName = &""

var _actor_rooms: Dictionary = {}         # actor_id -> room_id
var _relocation_anchors: Dictionary = {}  # room_id -> anchor object_id


func _init() -> void:
	graph.changed.connect(_on_graph_changed)


## Replaces the graph (e.g. a room loader building the chapter graph).
func set_graph(new_graph: SpatialGraph, p_anchor_room: StringName) -> void:
	if graph != null and graph.changed.is_connected(_on_graph_changed):
		graph.changed.disconnect(_on_graph_changed)
	graph = new_graph
	anchor_room = p_anchor_room
	graph.changed.connect(_on_graph_changed)


## Where an actor stranded in `room_id` is sent (may point into another room).
func set_relocation_anchor(room_id: StringName, anchor_id: StringName) -> void:
	_relocation_anchors[room_id] = anchor_id


func set_actor_room(actor_id: StringName, room_id: StringName) -> void:
	if _actor_rooms.get(actor_id) == room_id:
		return
	_actor_rooms[actor_id] = room_id
	actor_room_changed.emit(actor_id, room_id)


func get_actor_room(actor_id: StringName) -> StringName:
	return _actor_rooms.get(actor_id, &"")


## Transactional transform through the graph. Returns an InteractionResult so levers can pass it on.
func apply_transform(pairs: Array) -> InteractionResult:
	var result := graph.apply(pairs)
	return InteractionResult.success() if result["ok"] else InteractionResult.failure(result["reason"])


## Walking through a doorway: returns the destination, or {} if blocked (missing or non-traversable).
## On success the actor's room is updated.
func traverse(actor_id: StringName, room_id: StringName, door_id: StringName) -> Dictionary:
	var dest := graph.get_destination(room_id, door_id)
	if dest.is_empty() or not dest["traversable"]:
		return {}
	set_actor_room(actor_id, dest["room_id"])
	return dest


func export_state() -> Dictionary:
	var actors := {}
	for actor in _actor_rooms.keys():
		actors[String(actor)] = String(_actor_rooms[actor])
	return {"pairs": graph.export_pairs(), "actor_rooms": actors}


func import_state(data: Dictionary) -> Dictionary:
	var result := {"ok": true, "reason": &""}
	if data.get("pairs") is Array and not data["pairs"].is_empty():
		result = graph.import_pairs(data["pairs"])
	if result["ok"] and data.get("actor_rooms") is Dictionary:
		for actor in data["actor_rooms"].keys():
			_actor_rooms[StringName(str(actor))] = StringName(str(data["actor_rooms"][actor]))
	return result


func _on_graph_changed(affected_rooms: Array[StringName]) -> void:
	graph_changed.emit(affected_rooms)
	if String(anchor_room).is_empty():
		return
	var stranded := graph.get_unreachable_rooms(anchor_room)
	for actor in _actor_rooms.keys():
		var room: StringName = _actor_rooms[actor]
		if room in stranded and _relocation_anchors.has(room):
			relocate_requested.emit(actor, _relocation_anchors[room])
