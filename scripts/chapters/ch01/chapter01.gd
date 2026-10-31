class_name Chapter01
extends Node2D

## Chapter 1 controller (TLF-009 / TLF-025 / TLF-032). Instances ChapterRoot, applies the Ch1 ChapterGraphDef
## to the SpatialService, loads the Ch1 puzzle definitions, registers all 10 room scenes,
## wires all narrative beats (Beats 01 to 10), and handles Beat 10 outro completion.

signal chapter_completed()

@onready var session: GameSession = $GameSession
@onready var room_router: RoomRouter = $RoomRouter
@onready var room_container: Node2D = $RoomContainer
@onready var player: CharacterBody2D = $Player

const GRAPH_DEF_PATH := "res://data/chapters/ch01/ch01_graph.tres"
const PUZZLE_DIR := "res://data/puzzles/ch01"

var chapter_complete: bool = false
var _complete_overlay: CanvasLayer = null
var _movement_hint_timer: float = 0.0
var _movement_hint_active: bool = false


func _physics_process(delta: float) -> void:
	_update_movement_hint(delta)


func _ready() -> void:
	UIFeedback.init_translations()
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

		room_router.room_entered.connect(_on_room_entered)

		if room_router.current_room == null:
			room_router.enter_room(&"ch01.arrival_platform", &"", &"ch01.arrival_platform.safe_anchor_spawn")

	# 4. Connect narrative hooks
	if session != null:
		if session.puzzle_service != null:
			session.puzzle_service.puzzle_solved.connect(_on_puzzle_solved)
		if session.interaction_service != null:
			session.interaction_service.trigger_entered.connect(_on_trigger_entered)
		if session.narrative_state != null:
			session.narrative_state.document_read.connect(_on_document_read)
		if session.echo_service != null:
			session.echo_service.state_changed.connect(_on_echo_state_changed)

	_setup_document_viewer_listener()


func _setup_document_viewer_listener() -> void:
	var doc_viewer = get_document_viewer()
	if doc_viewer != null and not doc_viewer.document_closed.is_connected(_on_document_closed):
		doc_viewer.document_closed.connect(_on_document_closed)


func _on_room_entered(room_id: StringName) -> void:
	_setup_document_viewer_listener()

	# Connect any ReadableDocuments in the room
	if room_router != null and room_router.current_room != null:
		for child in room_router.current_room.find_children("*", "ReadableDocument", true, false):
			if child is ReadableDocument and not child.opened.is_connected(_on_readable_opened):
				child.opened.connect(_on_readable_opened)

	# Beat 01: Awakening monologue
	if room_id == &"ch01.arrival_platform":
		call_deferred("_trigger_beat01_start")

	# Beat 08: Loop detection on door_north in upper_vestibule
	if room_id == &"ch01.upper_vestibule" and room_router.current_room != null:
		var door_north = room_router.current_room.find_child("door_exit_north", true, false)
		if door_north == null:
			door_north = room_router.current_room.find_child("door_north", true, false)
		if door_north is DoorwayPresenter and not door_north.traversed.is_connected(_on_upper_vestibule_door_traversed):
			door_north.traversed.connect(_on_upper_vestibule_door_traversed)


func _trigger_beat01_start() -> void:
	if session != null and session.narrative_state != null:
		if session.narrative_state.get_flag(&"heard.ch01_b01_start", false):
			return

	var diag = get_dialogue_box()
	if diag != null:
		diag.play_sequence(
			&"ch01_b01_start",
			[["SPK_ELIAS", "EL_B01_01"], ["SPK_ELIAS", "EL_B01_02"], ["SPK_ELIAS", "EL_B01_03"]],
			false,
			4.0
		)


func _update_movement_hint(delta: float) -> void:
	if session == null or session.narrative_state == null:
		return

	if session.narrative_state.get_flag(&"ch01.flag.movement_hint_shown", false):
		if _movement_hint_active:
			var move_input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
			var is_moving = move_input.length_squared() > 0.01 or (player != null and player.velocity.length_squared() > 0.01)
			if is_moving:
				_movement_hint_active = false
				var hud = _find_hud()
				if hud != null:
					hud.hide_feedback()
		return

	var move_input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var is_moving = move_input.length_squared() > 0.01 or (player != null and player.velocity.length_squared() > 0.01)
	if is_moving:
		session.narrative_state.set_flag(&"ch01.flag.movement_hint_shown", true)
		return

	_movement_hint_timer += delta
	if _movement_hint_timer >= 3.0:
		session.narrative_state.set_flag(&"ch01.flag.movement_hint_shown", true)
		_movement_hint_active = true
		var hud = _find_hud()
		if hud != null:
			hud.show_message(InputPrompts.format_movement_hint(), 10.0)


func _find_hud() -> HUD:
	for child in get_children():
		if child is HUD:
			return child
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		var h = get_tree().root.find_child("HUD", true, false)
		if h is HUD:
			return h
	return null


func _on_upper_vestibule_door_traversed(actor_id: StringName, destination: Dictionary) -> void:
	if actor_id != &"player":
		return
	if destination.get("room_id", &"") == &"ch01.upper_vestibule" and destination.get("door_id", &"") == &"door_west":
		if session != null and session.narrative_state != null:
			if session.narrative_state.get_flag(&"heard.ch01_b08_loop", false):
				return
		var diag = get_dialogue_box()
		if diag != null:
			diag.play_sequence(&"ch01_b08_loop", [["SPK_ELIAS", "EL_B08_01"]], false, 4.0)


func _on_echo_state_changed(state: int) -> void:
	# State 3 is PLAYING
	if state == 3:
		var current_room = room_router.current_room_id if room_router != null else &""
		if current_room == &"ch01.security_crossing":
			if session != null and session.narrative_state != null:
				if session.narrative_state.get_flag(&"heard.ch01_b05_echo", false):
					return
			var diag = get_dialogue_box()
			if diag != null:
				diag.play_sequence(
					&"ch01_b05_echo",
					[["SPK_OPERATOR", "OP_B05_01"], ["SPK_ELIAS", "EL_B05_01"]],
					false,
					4.0
				)


func _on_readable_opened(doc: DocumentDef) -> void:
	var doc_viewer = get_document_viewer()
	if doc_viewer != null:
		doc_viewer.open_document(doc)


func _on_document_read(doc: DocumentDef) -> void:
	var doc_viewer = get_document_viewer()
	if doc_viewer != null and not doc_viewer.is_open:
		doc_viewer.open_document(doc)


func _on_document_closed(doc: DocumentDef, max_page_seen: int) -> void:
	if doc == null:
		return

	# Beat 06: Elias reaction to Mira's audio log
	if doc.document_id == &"ch01.waiting_lounge.audio_mira_01":
		if session != null and session.narrative_state != null:
			if not session.narrative_state.get_flag(&"heard.ch01_b06_mira_reaction", false):
				var diag = get_dialogue_box()
				if diag != null:
					diag.play_sequence(&"ch01_b06_mira_reaction", [["SPK_ELIAS", "EL_B06_02"]], false, 4.0)

	# Beat 09: Revelation monologue after reading page 2 of dispatch terminal
	if doc.document_id == &"ch01.station_atrium.dispatch_terminal" and max_page_seen >= 2:
		if session != null and session.narrative_state != null:
			if not session.narrative_state.get_flag(&"heard.ch01_b09_revelation", false):
				var diag = get_dialogue_box()
				if diag != null:
					diag.play_sequence(
						&"ch01_b09_revelation",
						[
							["SPK_ELIAS", "EL_B09_01"],
							["SPK_ELIAS", "EL_B09_02"],
							["SPK_ELIAS", "EL_B09_03"],
							["SPK_ELIAS", "EL_B09_04"],
						],
						true
					)


func _on_puzzle_solved(_puzzle_id: StringName, _tick: int = 0) -> void:
	# Duplicate journal logic removed per TLF-032; SignalControlIntercom handles CH1-PZ-004
	pass


func _on_trigger_entered(_tick: int, actor_id: StringName, zone_id: StringName) -> void:
	if actor_id == &"player" and zone_id == &"ch01.street_exit.trigger_outro":
		_trigger_beat10_outro()


func _trigger_beat10_outro() -> void:
	if chapter_complete:
		return

	if session != null and session.narrative_state != null:
		if session.narrative_state.get_flag(&"heard.ch01_b10_outro", false):
			complete_chapter()
			return

	var diag = get_dialogue_box()
	if diag != null:
		diag.sequence_finished.connect(func(seq_id):
			if seq_id == &"ch01_b10_outro":
				complete_chapter()
		, CONNECT_ONE_SHOT)
		var played = diag.play_sequence(
			&"ch01_b10_outro",
			[
				["SPK_ELIAS", "EL_B10_01"],
				["SPK_OPERATOR", "OP_B10_01"],
				["SPK_OPERATOR", "OP_B10_02"],
			],
			true
		)
		if not played:
			complete_chapter()
	else:
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
	label.text = "%s\n%s" % [tr("UI_CHAPTER_COMPLETE"), tr("UI_CHAPTER_01_TITLE")]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	_complete_overlay.add_child(label)

	add_child(_complete_overlay)


func get_dialogue_box() -> DialogueBox:
	if not is_inside_tree():
		return null
	var diag = get_tree().root.find_child("DialogueBox", true, false)
	if diag is DialogueBox:
		return diag
	return null


func get_document_viewer() -> DocumentViewer:
	if not is_inside_tree():
		return null
	var doc = get_tree().root.find_child("DocumentViewer", true, false)
	if doc is DocumentViewer:
		return doc
	return null


func get_journal_screen() -> JournalScreen:
	if not is_inside_tree():
		return null
	var jrn = get_tree().root.find_child("JournalScreen", true, false)
	if jrn is JournalScreen:
		return jrn
	return null
