class_name Chapter01
extends Node2D

## Chapter 1 controller (TLF-009). Instances ChapterRoot, applies the Ch1 ChapterGraphDef
## to the SpatialService, loads the Ch1 puzzle definitions, registers the room scenes,
## and spawns into arrival_platform.

@onready var session: GameSession = $GameSession
@onready var room_router: RoomRouter = $RoomRouter
@onready var room_container: Node2D = $RoomContainer
@onready var player: CharacterBody2D = $Player

const GRAPH_DEF_PATH := "res://data/chapters/ch01/ch01_graph.tres"
const PUZZLE_DIR := "res://data/puzzles/ch01"


func _ready() -> void:
	if session == null:
		session = get_node_or_null("GameSession") as GameSession
	if room_router == null:
		room_router = get_node_or_null("RoomRouter") as RoomRouter

	# 1. Apply ChapterGraphDef to spatial service
	var graph_def := load(GRAPH_DEF_PATH) as ChapterGraphDef
	if graph_def != null and session != null and session.spatial_service != null:
		graph_def.apply_to(session.spatial_service)

	# 2. Load puzzle definitions
	if session != null and session.hint_service != null:
		session.hint_service.load_defs_from(PUZZLE_DIR)

	# 3. Register Chapter 1 room scenes
	if room_router != null:
		room_router.register_room(&"ch01.arrival_platform", preload("res://scenes/chapters/ch01/rooms/arrival_platform.tscn"))
		room_router.register_room(&"ch01.concourse_west", preload("res://scenes/chapters/ch01/rooms/concourse_west.tscn"))
		room_router.register_room(&"ch01.maintenance_bay", preload("res://scenes/chapters/ch01/rooms/maintenance_bay.tscn"))
		room_router.register_room(&"ch01.security_crossing", preload("res://scenes/chapters/ch01/rooms/security_crossing.tscn"))

		if room_router.current_room == null:
			room_router.enter_room(&"ch01.arrival_platform", &"", &"ch01.arrival_platform.safe_anchor_spawn")
