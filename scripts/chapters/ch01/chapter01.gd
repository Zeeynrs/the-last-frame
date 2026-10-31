class_name Chapter01
extends Node2D

## Chapter 1 controller (TLF-009 / TLF-025). Instances ChapterRoot, applies the Ch1 ChapterGraphDef
## to the SpatialService, loads the Ch1 puzzle definitions, registers all 10 room scenes,
## handles intercom warnings and Beat 10 outro completion.

signal chapter_completed()

@onready var session: GameSession = $GameSession
@onready var room_router: RoomRouter = $RoomRouter
@onready var room_container: Node2D = $RoomContainer
@onready var player: CharacterBody2D = $Player

const GRAPH_DEF_PATH := "res://data/chapters/ch01/ch01_graph.tres"
const PUZZLE_DIR := "res://data/puzzles/ch01"

var chapter_complete: bool = false
var _complete_overlay: CanvasLayer = null


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

	# 3. Register Chapter 1 room scenes (all 10 rooms)
	if room_router != null:
		room_router.register_room(&"ch01.arrival_platform", preload("res://scenes/chapters/ch01/rooms/arrival_platform.tscn"))
		room_router.register_room(&"ch01.concourse_west", preload("res://scenes/chapters/ch01/rooms/concourse_west.tscn"))
		room_router.register_room(&"ch01.maintenance_bay", preload("res://scenes/chapters/ch01/rooms/maintenance_bay.tscn"))
		room_router.register_room(&"ch01.security_crossing", preload("res://scenes/chapters/ch01/rooms/security_crossing.tscn"))
		room_router.register_room(&"ch01.waiting_lounge", preload("res://scenes/chapters/ch01/rooms/waiting_lounge.tscn"))
		room_router.register_room(&"ch01.signal_control", preload("res://scenes/chapters/ch01/rooms/signal_control.tscn"))
		room_router.register_room(&"ch01.upper_vestibule", preload("res://scenes/chapters/ch01/rooms/upper_vestibule.tscn"))
		room_router.register_room(&"ch01.vestibule_niche", preload("res://scenes/chapters/ch01/rooms/vestibule_niche.tscn"))
		room_router.register_room(&"ch01.station_atrium", preload("res://scenes/chapters/ch01/rooms/station_atrium.tscn"))
		room_router.register_room(&"ch01.street_exit", preload("res://scenes/chapters/ch01/rooms/street_exit.tscn"))

		if room_router.current_room == null:
			room_router.enter_room(&"ch01.arrival_platform", &"", &"ch01.arrival_platform.safe_anchor_spawn")

	# 4. Connect narrative hooks
	if session != null:
		if session.puzzle_service != null:
			session.puzzle_service.puzzle_solved.connect(_on_puzzle_solved)
		if session.interaction_service != null:
			session.interaction_service.trigger_entered.connect(_on_trigger_entered)


func _on_puzzle_solved(puzzle_id: StringName, _tick: int = 0) -> void:
	if puzzle_id == &"CH1-PZ-004":
		if session != null and session.narrative_state != null:
			session.narrative_state.add_journal_entry("JRN_CH1_OPERATOR_WARNING", "theory")
			session.narrative_state.set_flag(&"ch01.flag.operator_substation_warn", true)


func _on_trigger_entered(_tick: int, actor_id: StringName, zone_id: StringName) -> void:
	if actor_id == &"player" and zone_id == &"ch01.street_exit.trigger_outro":
		complete_chapter()


func complete_chapter() -> void:
	if chapter_complete:
		return
	chapter_complete = true
	if session != null and session.narrative_state != null:
		session.narrative_state.set_flag(&"ch01.flag.chapter_complete", true)
	_show_chapter_complete_ui()
	chapter_completed.emit()


func _show_chapter_complete_ui() -> void:
	if _complete_overlay != null:
		return
	_complete_overlay = CanvasLayer.new()
	_complete_overlay.name = "ChapterCompleteOverlay"
	_complete_overlay.layer = 100

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.04, 0.06, 0.1, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_complete_overlay.add_child(bg)

	var label := Label.new()
	label.name = "TitleLabel"
	label.text = "CHAPTER 1 COMPLETE\nTHE FORGOTTEN STATION"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	_complete_overlay.add_child(label)

	add_child(_complete_overlay)
