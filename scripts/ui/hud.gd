class_name HUD
extends CanvasLayer

## Ability feedback HUD per ADR-015, closing ISSUE-006 (feedback toast) and ISSUE-007 (dynamic prompts).
## Shows current ability, watch target indicator, echo state & recording progress, and toast feedback.

@onready var ability_panel: PanelContainer = $AbilityPanel
@onready var ability_icon: ColorRect = $AbilityPanel/Margin/HBox/AbilityIcon
@onready var ability_label: Label = $AbilityPanel/Margin/HBox/AbilityLabel
@onready var watch_prompt: Label = $AbilityPanel/Margin/HBox/WatchPrompt
@onready var wheel_prompt: Label = get_node_or_null("AbilityPanel/Margin/HBox/WheelPrompt")
@onready var hint_prompt: Label = get_node_or_null("AbilityPanel/Margin/HBox/HintPrompt")

@onready var echo_panel: PanelContainer = $EchoPanel
@onready var echo_state_label: Label = $EchoPanel/Margin/VBox/StateLabel
@onready var echo_progress_label: Label = $EchoPanel/Margin/VBox/ProgressLabel
@onready var echo_reset_label: Label = $EchoPanel/Margin/VBox/ResetLabel

@onready var feedback_panel: PanelContainer = $FeedbackPanel
@onready var feedback_label: Label = $FeedbackPanel/Margin/FeedbackLabel

@onready var target_highlight: Node2D = $TargetHighlight
@onready var target_icon: ColorRect = $TargetHighlight/AbilityMarker

var pocket_watch: Node = null
var echo_service: Node = null

var dialogue_box: DialogueBox = null
var document_viewer: DocumentViewer = null
var journal_screen: JournalScreen = null
var ability_wheel: AbilityWheel = null

var _toast_timer: float = 0.0

const ABILITY_COLORS: Dictionary = {
	&"trace": Color(0.3, 0.8, 1.0),
	&"rewind": Color(1.0, 0.75, 0.2),
	&"freeze": Color(0.4, 0.7, 1.0),
	&"echo": Color(0.8, 0.4, 1.0),
	&"fast_forward": Color(0.3, 1.0, 0.4),
}


func _ready() -> void:
	UIFeedback.init_translations()
	if feedback_panel != null:
		feedback_panel.visible = false
	if target_highlight != null:
		target_highlight.visible = false
	_setup_sub_ui()
	update_ability_ui()


func _setup_sub_ui() -> void:
	if dialogue_box == null:
		var existing_diag = get_tree().root.find_child("DialogueBox", true, false)
		if existing_diag is DialogueBox:
			dialogue_box = existing_diag
		else:
			var diag_res = load("res://scenes/ui/DialogueBox.tscn")
			if diag_res != null:
				dialogue_box = diag_res.instantiate() as DialogueBox
				add_child(dialogue_box)

	if document_viewer == null:
		var existing_doc = get_tree().root.find_child("DocumentViewer", true, false)
		if existing_doc is DocumentViewer:
			document_viewer = existing_doc
		else:
			var doc_res = load("res://scenes/ui/DocumentViewer.tscn")
			if doc_res != null:
				document_viewer = doc_res.instantiate() as DocumentViewer
				add_child(document_viewer)

	if journal_screen == null:
		var existing_jrn = get_tree().root.find_child("JournalScreen", true, false)
		if existing_jrn is JournalScreen:
			journal_screen = existing_jrn
		else:
			var jrn_res = load("res://scenes/ui/JournalScreen.tscn")
			if jrn_res != null:
				journal_screen = jrn_res.instantiate() as JournalScreen
				add_child(journal_screen)

	if ability_wheel == null:
		var child_wheel = get_node_or_null("AbilityWheel")
		if child_wheel is AbilityWheel:
			ability_wheel = child_wheel
		else:
			var existing_wheel = get_tree().root.find_child("AbilityWheel", true, false)
			if existing_wheel is AbilityWheel:
				ability_wheel = existing_wheel
			else:
				var wheel_res = load("res://scenes/ui/ability_wheel.tscn")
				if wheel_res != null:
					ability_wheel = wheel_res.instantiate() as AbilityWheel
					add_child(ability_wheel)
	if ability_wheel != null and pocket_watch != null:
		ability_wheel.bind_pocket_watch(pocket_watch)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not InputPrompts.is_joypad_mode:
			InputPrompts.set_joypad_mode(true)
			update_ability_ui()
	elif event is InputEventKey or event is InputEventMouseButton:
		if InputPrompts.is_joypad_mode:
			InputPrompts.set_joypad_mode(false)
			update_ability_ui()

	if event.is_action_pressed(&"hint"):
		request_hint()
	elif event.is_action_pressed(&"journal"):
		toggle_journal()


func _process(delta: float) -> void:
	if _is_chapter_complete_active():
		if feedback_panel != null:
			feedback_panel.visible = false
		if ability_panel != null:
			ability_panel.visible = false
		if echo_panel != null:
			echo_panel.visible = false
		if target_highlight != null:
			target_highlight.visible = false
		return
	elif ability_panel != null and not ability_panel.visible:
		ability_panel.visible = true

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and feedback_panel != null:
			feedback_panel.visible = false

	_update_echo_progress()
	_update_target_highlight_position()


func bind_pocket_watch(watch: Node) -> void:
	pocket_watch = watch
	if pocket_watch != null:
		if pocket_watch.has_signal("ability_changed"):
			pocket_watch.ability_changed.connect(_on_ability_changed)
		if pocket_watch.has_signal("target_changed"):
			pocket_watch.target_changed.connect(_on_target_changed)
		if pocket_watch.has_signal("watch_used"):
			pocket_watch.watch_used.connect(_on_watch_used)
		if pocket_watch.has_signal("ability_selection_refused"):
			pocket_watch.ability_selection_refused.connect(_on_ability_selection_refused)
	if ability_wheel != null and pocket_watch is PocketWatch:
		ability_wheel.bind_pocket_watch(pocket_watch as PocketWatch)
	update_ability_ui()


func _on_ability_selection_refused(_ability: StringName, reason: StringName) -> void:
	show_feedback(reason, &"watch")


func bind_echo_service(service: Node) -> void:
	echo_service = service
	if echo_service != null:
		if echo_service.has_signal("state_changed"):
			echo_service.state_changed.connect(func(_s): update_ability_ui())
	update_ability_ui()


func _on_ability_changed(_new_ability: StringName) -> void:
	update_ability_ui()


func _on_target_changed(new_target: Interactable) -> void:
	if target_highlight != null:
		target_highlight.visible = (new_target != null and is_instance_valid(new_target) and pocket_watch != null and pocket_watch.selected_ability != &"echo")
		_update_target_highlight_position()


func _on_watch_used(_ability: StringName, _target_id: StringName, result: InteractionResult) -> void:
	if result != null and not result.ok:
		show_feedback(result.reason, &"watch")


## Displays a temporary feedback toast for an interaction reason (closes ISSUE-006).
func show_feedback(reason: StringName, context: StringName = &"watch") -> void:
	if _is_chapter_complete_active():
		return
	var msg = UIFeedback.get_feedback_text(reason, context)
	if msg == "" or feedback_label == null or feedback_panel == null:
		return
	feedback_label.text = msg
	feedback_panel.visible = true
	_toast_timer = 2.0


func hide_feedback() -> void:
	_toast_timer = 0.0
	if feedback_panel != null:
		feedback_panel.visible = false


func update_ability_ui() -> void:
	if pocket_watch == null:
		return

	var current_ability: StringName = pocket_watch.selected_ability
	var ab_str = String(current_ability).to_upper()
	var localized_name = tr("ABILITY_" + ab_str)

	if ability_label != null:
		ability_label.text = localized_name

	if ability_icon != null:
		ability_icon.color = ABILITY_COLORS.get(current_ability, Color.WHITE)

	if watch_prompt != null:
		var watch_glyph = InputPrompts.get_action_glyph(&"watch")
		watch_prompt.text = "%s %s" % [watch_glyph, tr("PROMPT_WATCH")]

	if hint_prompt != null:
		var hint_glyph = InputPrompts.get_action_glyph(&"hint")
		hint_prompt.text = "%s %s" % [hint_glyph, tr("UI_PROMPT_HINT")]

	if wheel_prompt != null:
		var wheel_glyph = InputPrompts.get_action_glyph(&"ability_wheel")
		if InputPrompts.is_joypad_mode and (wheel_glyph == "" or wheel_glyph == "[Z]"):
			wheel_glyph = "[LT]"
		wheel_prompt.text = "%s %s" % [wheel_glyph, tr("UI_PROMPT_ABILITIES")]

	if current_ability == &"echo":
		if echo_panel != null:
			echo_panel.visible = true
		_update_echo_state()
		if target_highlight != null:
			target_highlight.visible = false
	else:
		if echo_panel != null:
			echo_panel.visible = false
		if target_highlight != null:
			target_highlight.visible = (pocket_watch.current_target != null and is_instance_valid(pocket_watch.current_target))


func _update_echo_state() -> void:
	if echo_service == null or echo_state_label == null:
		return

	var state_name := "IDLE"
	match echo_service.state:
		0: state_name = "IDLE (Ready to Record)"
		1: state_name = "RECORDING..."
		2: state_name = "READY"
		3: state_name = "PLAYING..."
		4: state_name = "HOLDING"

	echo_state_label.text = "Echo: %s" % state_name

	if echo_reset_label != null:
		var reset_glyph = InputPrompts.get_action_glyph(&"echo_reset")
		echo_reset_label.text = "%s Reset Echo" % reset_glyph


func _update_echo_progress() -> void:
	if echo_panel == null or not echo_panel.visible or echo_service == null or echo_progress_label == null:
		return

	var elapsed = echo_service.get_elapsed_ticks()
	var max_ticks = echo_service.max_record_ticks
	echo_progress_label.text = "Ticks: %d / %d (%.1fs / %.1fs)" % [elapsed, max_ticks, float(elapsed)/60.0, float(max_ticks)/60.0]


func _update_target_highlight_position() -> void:
	if target_highlight == null or not target_highlight.visible or pocket_watch == null:
		return

	var target = pocket_watch.current_target
	if target != null and is_instance_valid(target):
		target_highlight.global_position = target.get_global_transform_with_canvas().origin + Vector2(0, -28)
		if target_icon != null:
			target_icon.color = ABILITY_COLORS.get(pocket_watch.selected_ability, Color.WHITE)
	else:
		target_highlight.visible = false


func show_message(msg: String, duration: float = 3.5) -> void:
	if _is_chapter_complete_active():
		return
	if msg == "" or feedback_label == null or feedback_panel == null:
		return
	feedback_label.text = msg
	feedback_panel.visible = true
	_toast_timer = duration


func request_hint() -> void:
	var session = _find_session()
	if session == null or session.hint_service == null:
		return
	var room_id: StringName = &""
	if session.spatial_service != null:
		room_id = session.spatial_service.get_actor_room(&"player")
	var res = session.hint_service.request_hint_for_room(room_id)
	if not res.get("ok", false) and res.get("reason", &"") == &"no_active_puzzle":
		if session.puzzle_service != null and "_defs" in session.hint_service:
			for p_def in session.hint_service._defs.values():
				if p_def.room_id == room_id and session.puzzle_service.is_solved(p_def.puzzle_id):
					res["reason"] = &"already_solved"
					break
	if res.get("ok", false):
		var text_key = String(res.get("text_key", ""))
		show_message(tr(text_key), 4.5)
	else:
		var reason = res.get("reason", &"")
		show_feedback(reason)


func toggle_journal() -> void:
	if journal_screen != null:
		journal_screen.toggle_journal()


func _find_session() -> GameSession:
	if not is_inside_tree():
		return null
	var sess = get_tree().get_first_node_in_group(&"game_session")
	if sess is GameSession:
		return sess
	return get_tree().root.find_child("GameSession", true, false) as GameSession


func _is_chapter_complete_active() -> bool:
	if not is_inside_tree():
		return false
	var overlay = get_tree().root.find_child("ChapterCompleteOverlay", true, false)
	if overlay != null and overlay is CanvasLayer and overlay.visible:
		return true
	var sess = _find_session()
	if sess != null and sess.narrative_state != null and sess.narrative_state.get_flag(&"ch01.flag.chapter_complete"):
		return true
	return false
