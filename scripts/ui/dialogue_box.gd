class_name DialogueBox
extends CanvasLayer

## Dialogue and monologue box per TLF-032.
## Displays speaker-labeled lines (SPK_*) at the bottom of the 640x360 screen.
## Non-blocking for device voices (player can walk); blocking for key story beats (Beats 01, 09, 10).
## One-shot sequences record 'heard.<sequence_id>' in NarrativeState to prevent replay on reload.

signal sequence_started(sequence_id: StringName)
signal line_displayed(speaker_key: String, text_key: String)
signal line_advanced(line_index: int, total_lines: int)
signal sequence_finished(sequence_id: StringName)

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/Margin/VBox/TopRow/SpeakerLabel
@onready var text_label: Label = $Panel/Margin/VBox/TextLabel
@onready var prompt_label: Label = $Panel/Margin/VBox/TopRow/PromptLabel

var is_active: bool = false
var is_blocking: bool = false
var current_sequence_id: StringName = &""
var current_lines: Array = []
var current_line_index: int = -1
var auto_advance_delay: float = 0.0

var _auto_timer: float = 0.0
var _player_ref: CharacterBody2D = null

const SPEAKER_COLORS: Dictionary = {
	"SPK_ELIAS": Color(0.3, 0.75, 1.0),
	"SPK_OPERATOR": Color(1.0, 0.75, 0.2),
	"SPK_MIRA": Color(0.8, 0.4, 1.0),
}


func _ready() -> void:
	UIFeedback.init_translations()
	if panel != null:
		panel.visible = false
	visible = false


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed(&"confirm") or event.is_action_pressed(&"interact"):
		advance_line()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not is_active:
		return

	if auto_advance_delay > 0.0:
		_auto_timer += delta
		if _auto_timer >= auto_advance_delay:
			advance_line()


func play_sequence(sequence_id: StringName, lines: Array, blocking: bool = false, auto_advance: float = 0.0, one_shot: bool = true) -> bool:
	UIFeedback.init_translations()
	if lines.is_empty():
		return false

	var session = _find_session()
	if session != null and session.narrative_state != null and sequence_id != &"" and one_shot:
		if session.narrative_state.get_flag(StringName("heard." + String(sequence_id)), false):
			return false
		session.narrative_state.set_flag(StringName("heard." + String(sequence_id)), true)

	current_sequence_id = sequence_id
	current_lines = lines.duplicate(true)
	current_line_index = 0
	is_blocking = blocking
	auto_advance_delay = auto_advance
	_auto_timer = 0.0
	is_active = true
	visible = true
	if panel != null:
		panel.visible = true

	if is_blocking:
		_set_player_movement_blocked(true)

	_display_current_line()
	sequence_started.emit(sequence_id)
	return true


func advance_line() -> void:
	if not is_active:
		return

	current_line_index += 1
	if current_line_index < current_lines.size():
		_display_current_line()
		line_advanced.emit(current_line_index, current_lines.size())
	else:
		finish_sequence()


func finish_sequence() -> void:
	if not is_active:
		return

	is_active = false
	visible = false
	if panel != null:
		panel.visible = false

	if is_blocking:
		_set_player_movement_blocked(false)

	var finished_seq = current_sequence_id
	current_sequence_id = &""
	current_lines.clear()
	current_line_index = -1
	_auto_timer = 0.0

	sequence_finished.emit(finished_seq)


func _display_current_line() -> void:
	if current_line_index < 0 or current_line_index >= current_lines.size():
		return

	var line = current_lines[current_line_index]
	var speaker_key := ""
	var text_key := ""

	if line is Array and line.size() >= 2:
		speaker_key = String(line[0])
		text_key = String(line[1])
	elif line is Dictionary:
		speaker_key = String(line.get("speaker", ""))
		text_key = String(line.get("text", ""))

	if speaker_label != null:
		speaker_label.text = tr(speaker_key) if speaker_key != "" else ""
		speaker_label.modulate = SPEAKER_COLORS.get(speaker_key, Color(0.93, 0.96, 0.98))

	if text_label != null:
		var localized_text = tr(text_key).replace("<br>", "\n")
		text_label.text = localized_text

	if prompt_label != null:
		prompt_label.text = InputPrompts.format_prompt(&"interact", "UI_DIALOGUE_ADVANCE")

	_auto_timer = 0.0
	line_displayed.emit(speaker_key, text_key)


func _set_player_movement_blocked(blocked: bool) -> void:
	_player_ref = Player.set_player_blocked(self, blocked, _player_ref)


func _find_session() -> GameSession:
	if not is_inside_tree():
		return null
	var sess = get_tree().get_first_node_in_group(&"game_session")
	if sess is GameSession:
		return sess
	return get_tree().root.find_child("GameSession", true, false) as GameSession
