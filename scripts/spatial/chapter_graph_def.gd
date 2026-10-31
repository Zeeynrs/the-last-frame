class_name ChapterGraphDef
extends Resource

## Data definition of a chapter's room/doorway graph (ADR-009, ADR-013), generated from the chapter's
## ROOM_GRAPH.md by tools/content/gen_ch01_graph.py. Also carries the layout metadata scenes are
## built from (footprints, door tiles and sides, safe anchors) so tests can check scenes against it.

## Tile -> pixel mapping (ROOM_GRAPH §1): floor apex of tile (0,0) at (320, 64), 32x16 iso tiles.
const ORIGIN := Vector2(320, 64)

@export var chapter_id: String = ""
## Reachability reference for relocation (ADR-009 relocation rule).
@export var anchor_room: StringName = &""
## [{room_id, width, height, doors: [{door_id, side, x, y}], safe_anchors: [{id, x, y}]}]
@export var rooms: Array = []
## Initial doorway pairing: [room_a, door_a, room_b, door_b, traversable].
@export var initial_pairs: Array = []
## Room pairs that must stay mutually reachable through any transform.
@export var critical_pairs: Array = []
## room_id -> SafeAnchor object_id used when an actor is stranded in that room.
@export var relocation_anchors: Dictionary = {}


static func tile_to_px(x: float, y: float) -> Vector2:
	return ORIGIN + Vector2((x - y) * 16.0, (x + y) * 8.0)


func get_room(room_id: StringName) -> Dictionary:
	for room in rooms:
		if StringName(room["room_id"]) == room_id:
			return room
	return {}


func get_door(room_id: StringName, door_id: StringName) -> Dictionary:
	for door in get_room(room_id).get("doors", []):
		if StringName(door["door_id"]) == door_id:
			return door
	return {}


## Builds and validates the SpatialGraph. Returns null (with an error) if the data is invalid.
func build_graph() -> SpatialGraph:
	var graph := SpatialGraph.new()
	for room in rooms:
		var doors: Array = []
		for door in room["doors"]:
			doors.append(StringName(door["door_id"]))
		graph.add_room(StringName(room["room_id"]), doors)
	for pair in critical_pairs:
		graph.add_critical_pair(StringName(pair[0]), StringName(pair[1]))
	var result := graph.set_initial_pairs(initial_pairs)
	if not result["ok"]:
		push_error("ChapterGraphDef '%s': initial pairing invalid (%s)." % [chapter_id, result["reason"]])
		return null
	return graph


## Configures a SpatialService for this chapter (graph, anchor room, relocation anchors).
func apply_to(spatial: SpatialService) -> bool:
	var graph := build_graph()
	if graph == null:
		return false
	spatial.set_graph(graph, anchor_room)
	for room_id in relocation_anchors.keys():
		spatial.set_relocation_anchor(StringName(room_id), StringName(relocation_anchors[room_id]))
	return true
