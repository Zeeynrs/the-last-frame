class_name DocumentViewer
extends CanvasLayer

## Document viewer modal dialog per TLF-032.
## Opens on ReadableDocument.opened.
## Displays document title, paged body text (detects _BODY_2, etc.), and pauses SimClock and player input.

signal document_opened(doc: DocumentDef)
signal page_changed(current_page: int, total_pages: int)
signal document_closed(doc: DocumentDef, max_page_seen: int)

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var body_label: Label = $Panel/Margin/VBox/BodyLabel
@onready var page_label: Label = $Panel/Margin/VBox/BottomRow/PageLabel
@onready var prompt_label: Label = $Panel/Margin/VBox/BottomRow/PromptLabel

var current_doc: DocumentDef = null
var pages: Array[String] = []
var current_page_index: int = 0
var max_page_seen: int = 1
var is_open: bool = false

var _player_ref: CharacterBody2D = null


func _ready() -> void:
	UIFeedback.init_translations()
	if panel != null:
		panel.visible = false
	visible = false


func _input(event: InputEvent) -> void:
	if not is_open:
		return

	if event.is_action_pressed(&"cancel"):
		close_document()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"interact"):
		if current_page_index + 1 < pages.size():
			next_page()
		else:
			close_document()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"watch") or event.is_action_pressed(&"move_left") or event.is_action_pressed(&"ability_prev"):
		if current_page_index > 0:
			prev_page()
			if get_viewport() != null:
				get_viewport().set_input_as_handled()


func open_document(doc: DocumentDef) -> void:
	UIFeedback.init_translations()
	if doc == null or not doc.is_valid():
		return

	current_doc = doc
	pages = _gather_pages(doc)
	current_page_index = 0
	max_page_seen = 1
	is_open = true
	visible = true
	if panel != null:
		panel.visible = true

	var session = _find_session()
	if session != null and session.sim_clock != null:
		session.sim_clock.is_paused = true
	_set_player_blocked(true)

	_update_page_display()
	document_opened.emit(doc)


func close_document() -> void:
	if not is_open:
		return

	is_open = false
	visible = false
	if panel != null:
		panel.visible = false

	var session = _find_session()
	if session != null and session.sim_clock != null:
		session.sim_clock.is_paused = false
	_set_player_blocked(false)

	var doc = current_doc
	var seen = max_page_seen
	current_doc = null
	pages.clear()
	current_page_index = 0

	document_closed.emit(doc, seen)


func next_page() -> void:
	if not is_open or current_page_index + 1 >= pages.size():
		return

	current_page_index += 1
	max_page_seen = maxi(max_page_seen, current_page_index + 1)
	_update_page_display()

	if current_doc != null and current_doc.document_id == &"ch01.station_atrium.dispatch_terminal" and current_page_index == 1:
		var session = _find_session()
		if session != null and session.narrative_state != null:
			session.narrative_state.add_journal_entry("JRN_CH1_REPEATS", "theory")

	page_changed.emit(current_page_index + 1, pages.size())


func prev_page() -> void:
	if not is_open or current_page_index <= 0:
		return

	current_page_index -= 1
	_update_page_display()
	page_changed.emit(current_page_index + 1, pages.size())


func _gather_pages(doc: DocumentDef) -> Array[String]:
	var list: Array[String] = []
	if doc == null:
		return list

	var base := doc.body_key
	if base.ends_with("_1"):
		base = base.trim_suffix("_1")

	list.append(doc.body_key)

	var p_num := 2
	while true:
		var next_key := "%s_%d" % [base, p_num]
		var translated = tr(next_key)
		if translated != next_key and not translated.is_empty():
			list.append(next_key)
			p_num += 1
		else:
			break

	return list


func _update_page_display() -> void:
	if current_doc == null:
		return

	if title_label != null:
		title_label.text = tr(current_doc.title_key)

	if body_label != null and current_page_index < pages.size():
		var key = pages[current_page_index]
		body_label.text = tr(key).replace("<br>", "\n")

	if page_label != null:
		if pages.size() > 1:
			page_label.text = tr("UI_DOC_PAGE") % [current_page_index + 1, pages.size()]
			page_label.visible = true
		else:
			page_label.visible = false

	if prompt_label != null:
		var close_prompt = InputPrompts.format_prompt(&"cancel", "UI_DOC_CLOSE")
		if pages.size() > 1:
			var next_prompt = InputPrompts.format_prompt(&"interact", "UI_DOC_NEXT")
			prompt_label.text = "%s  |  %s" % [next_prompt, close_prompt]
		else:
			prompt_label.text = close_prompt


func _set_player_blocked(blocked: bool) -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		var session = _find_session()
		if session != null and session.room_router != null and session.room_router.player != null:
			_player_ref = session.room_router.player
		elif is_inside_tree():
			var p = get_tree().get_first_node_in_group(&"player")
			if p is CharacterBody2D:
				_player_ref = p
			else:
				var candidate = get_tree().root.find_child("Player", true, false)
				if candidate is CharacterBody2D:
					_player_ref = candidate

	if _player_ref != null and is_instance_valid(_player_ref):
		_player_ref.set_physics_process(not blocked)
		if blocked:
			_player_ref.velocity = Vector2.ZERO


func _find_session() -> GameSession:
	if not is_inside_tree():
		return null
	var sess = get_tree().get_first_node_in_group(&"game_session")
	if sess is GameSession:
		return sess
	return get_tree().root.find_child("GameSession", true, false) as GameSession
