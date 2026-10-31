class_name JournalScreen
extends CanvasLayer

## Journal and memory fragment viewer per TLF-032.
## Opens via the 'journal' action.
## Groups entries by category (observation / fact / theory), lists memory fragments,
## and pauses SimClock and player input while open.

signal opened()
signal closed()

@onready var panel: PanelContainer = $Panel
@onready var tab_container: TabContainer = $Panel/Margin/VBox/TabContainer
@onready var journal_content: VBoxContainer = $Panel/Margin/VBox/TabContainer/Journal/Scroll/Content
@onready var fragments_content: VBoxContainer = $Panel/Margin/VBox/TabContainer/Fragments/Scroll/Content
@onready var prompt_label: Label = $Panel/Margin/VBox/Footer/PromptLabel

var is_open: bool = false
var _player_ref: CharacterBody2D = null

const CATEGORY_KEYS: Dictionary = {
	"observation": "UI_JOURNAL_CAT_OBSERVATION",
	"fact": "UI_JOURNAL_CAT_FACT",
	"theory": "UI_JOURNAL_CAT_THEORY",
}

const CATEGORY_COLORS: Dictionary = {
	"observation": Color(0.3, 0.75, 1.0),
	"fact": Color(0.3, 1.0, 0.6),
	"theory": Color(0.8, 0.45, 1.0),
}


func _ready() -> void:
	UIFeedback.init_translations()
	if panel != null:
		panel.visible = false
	visible = false


func _input(event: InputEvent) -> void:
	if not is_open:
		return

	if event.is_action_pressed(&"journal") or event.is_action_pressed(&"cancel"):
		close_journal()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ability_prev") or event.is_action_pressed(&"move_left"):
		if tab_container != null and tab_container.current_tab > 0:
			tab_container.current_tab -= 1
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ability_next") or event.is_action_pressed(&"move_right"):
		if tab_container != null and tab_container.current_tab < tab_container.get_tab_count() - 1:
			tab_container.current_tab += 1
			if get_viewport() != null:
				get_viewport().set_input_as_handled()


func toggle_journal() -> void:
	if is_open:
		close_journal()
	else:
		open_journal()


func open_journal() -> void:
	UIFeedback.init_translations()
	is_open = true
	visible = true
	if panel != null:
		panel.visible = true

	var session = _find_session()
	if session != null and session.sim_clock != null:
		session.sim_clock.is_paused = true
	_set_player_blocked(true)

	_populate_journal(session)
	_populate_fragments(session)

	if prompt_label != null:
		var close_prompt = InputPrompts.format_prompt(&"journal", "UI_JOURNAL_CLOSE")
		var tab_switch = "%s / %s Tabs" % [InputPrompts.get_action_glyph(&"ability_prev"), InputPrompts.get_action_glyph(&"ability_next")]
		prompt_label.text = "%s  |  %s" % [tab_switch, close_prompt]

	opened.emit()


func close_journal() -> void:
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

	closed.emit()


func _populate_journal(session: GameSession) -> void:
	if journal_content == null:
		return

	for child in journal_content.get_children():
		child.queue_free()

	var entries: Array[Dictionary] = []
	if session != null and session.narrative_state != null:
		entries = session.narrative_state.get_journal()

	if entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = tr("UI_JOURNAL_EMPTY")
		empty_lbl.modulate = Color(0.65, 0.7, 0.8, 0.8)
		journal_content.add_child(empty_lbl)
		return

	var categories: Array[String] = ["observation", "fact", "theory"]
	for cat in categories:
		var cat_entries := entries.filter(func(e): return e.get("category", "") == cat)
		if cat_entries.is_empty():
			continue

		var cat_header := Label.new()
		var cat_key = CATEGORY_KEYS.get(cat, cat.capitalize())
		cat_header.text = "%s (%d)" % [tr(cat_key), cat_entries.size()]
		cat_header.modulate = CATEGORY_COLORS.get(cat, Color.WHITE)
		journal_content.add_child(cat_header)

		for entry in cat_entries:
			var entry_lbl := Label.new()
			var key = String(entry.get("key", ""))
			entry_lbl.text = " - %s" % tr(key)
			entry_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			entry_lbl.modulate = Color(0.88, 0.92, 0.96)
			journal_content.add_child(entry_lbl)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 6)
		journal_content.add_child(spacer)


func _populate_fragments(session: GameSession) -> void:
	if fragments_content == null:
		return

	for child in fragments_content.get_children():
		child.queue_free()

	var fragments: Array = []
	if session != null and session.narrative_state != null:
		fragments = session.narrative_state.export_fragments()

	if fragments.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = tr("UI_FRAGMENTS_EMPTY")
		empty_lbl.modulate = Color(0.65, 0.7, 0.8, 0.8)
		fragments_content.add_child(empty_lbl)
		return

	for frag_id in fragments:
		var id_str = String(frag_id)
		var last_part = id_str.split(".")[-1].to_upper()
		var title_key = "FRAG_%s_TITLE" % last_part
		var body_key = "FRAG_%s_BODY" % last_part

		var title_lbl := Label.new()
		title_lbl.text = tr(title_key)
		title_lbl.modulate = Color(0.8, 0.45, 1.0)
		fragments_content.add_child(title_lbl)

		var body_lbl := Label.new()
		body_lbl.text = tr(body_key).replace("<br>", "\n")
		body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_lbl.modulate = Color(0.88, 0.92, 0.96)
		fragments_content.add_child(body_lbl)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 8)
		fragments_content.add_child(spacer)


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
