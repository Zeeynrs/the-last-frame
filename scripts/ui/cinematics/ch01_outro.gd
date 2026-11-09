class_name Ch01Outro
extends CanvasLayer

## Beat 10 Cinematic Controller (Story Bible Ch1 Event 10 / ADR-022 D2 / TLF-059).
## Displays the nocturnal frozen city plate at 1280x360 across the 960x540 viewport, letterboxed
## (ADR-023 addendum 3): the plate keeps its 1:1 pixel scale between black bars of 90 px (the Dimmer).
## - Slow pan by integer-pixel steps (no subpixel blur) from x = 0 to x = -320 (1280 - 960).
## - Frozen suspended rain and silent Mira broadcast screen on the plaza.
## - Narrative dialogue: EL_B10_01, pause, OP_B10_01 ("You are late."), 1s pause, OP_B10_02 ("Again.").
## - Skippable via hold `confirm` (1.0 s) or `cancel`.
## - SimClock paused and player input blocked while running.
## - Accessibility `reduced_effects`: no pan, holds static frame.
## - Data-driven timing with exported shot parameters for Ending 3 parity.

## The city plate's size in pixels; it is never scaled.
const PLATE_SIZE := Vector2(1280, 360)

signal cinematic_started()
signal cinematic_completed()
signal cinematic_skipped()
signal device_click_played()
signal shot_advanced(shot_index: int)

@export_group("Cinematic Timing")
@export var pan_duration: float = 8.0          ## Total duration of integer-pixel pan (320 px / 8.0 s = 40 px/s)
@export var line1_delay: float = 0.5           ## Lead-in before Elias speaks EL_B10_01
@export var line1_duration: float = 2.5        ## On-screen time for EL_B10_01
@export var line2_pause: float = 1.0           ## Dramatic pause + street device activation
@export var line2_duration: float = 1.8        ## On-screen time for OP_B10_01 ("You are late.")
@export var line3_pause: float = 1.0           ## Canon 1.0 s pause before OP_B10_02 ("Again.")
@export var line3_duration: float = 1.8        ## On-screen time for OP_B10_02 ("Again.")
@export var outro_hold_duration: float = 1.2   ## Hold on final vista before chapter complete overlay
@export var skip_hold_duration: float = 1.0    ## Seconds to hold confirm to trigger skip

@export_group("Pan Geometry")
@export var start_pan_x: float = 0.0           ## Start position (Station Exit -> Plaza crop)
@export var end_pan_x: float = -320.0          ## End position (Broadcast Tower -> City crop)
@export var reduced_effects_static_x: float = -320.0 ## Static crop under reduced_effects

@export_group("Compositing")
@export var use_layer_compositing: bool = false ## When true, composites backdrop + screens + rain at runtime

@onready var plate_container: Control = $PlateContainer
@onready var city_plate: TextureRect = $PlateContainer/CityPlate
@onready var backdrop: TextureRect = $PlateContainer/Backdrop
@onready var mira_screen_left: TextureRect = $PlateContainer/MiraScreenLeft
@onready var mira_screen_right: TextureRect = $PlateContainer/MiraScreenRight
@onready var suspended_rain: TextureRect = $PlateContainer/SuspendedRain
@onready var skip_label: Label = get_node_or_null("SkipPrompt/VBox/SkipLabel") as Label
@onready var skip_progress: ProgressBar = get_node_or_null("SkipPrompt/VBox/SkipProgress") as ProgressBar
@onready var audio_click: AudioStreamPlayer = $AudioClick

var _session: GameSession = null
var _player: CharacterBody2D = null
var _diag: DialogueBox = null
var _is_playing: bool = false
var _is_skipping: bool = false
var _pan_time: float = 0.0
var _timeline: float = 0.0
var _confirm_hold_time: float = 0.0
var _current_shot: int = 0
var _device_click_fired: bool = false
var _dialogue_manually_advanced: bool = false
var _timeline_advancing: bool = false   ## true while the timeline itself advances the dialogue
var _dialogue_finished: bool = false


func _ready() -> void:
	layer = 60 # Behind DialogueBox (70) and ChapterCompleteOverlay (100)
	_setup_compositing()
	_update_skip_label()
	if not _is_playing:
		# If instantiated without explicit start call, align initial frame
		_apply_pan_position(0.0)


func _input(event: InputEvent) -> void:
	if not _is_playing or _is_skipping:
		return

	if event.is_action_pressed(&"cancel"):
		skip()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _is_playing or _is_skipping:
		return

	# 1. Skip hold progression
	if Input.is_action_pressed(&"confirm"):
		_confirm_hold_time += delta
		if skip_progress != null:
			skip_progress.visible = true
			skip_progress.value = clampf(_confirm_hold_time / skip_hold_duration, 0.0, 1.0)
		if _confirm_hold_time >= skip_hold_duration:
			skip()
			return
	else:
		_confirm_hold_time = 0.0
		if skip_progress != null:
			skip_progress.visible = false
			skip_progress.value = 0.0

	# 2. Integer-pixel pan
	if _is_reduced_effects():
		_apply_pan_position(reduced_effects_static_x)
	else:
		_pan_time += delta
		var pan_progress: float = clampf(_pan_time / pan_duration, 0.0, 1.0)
		var raw_x: float = lerp(start_pan_x, end_pan_x, pan_progress)
		_apply_pan_position(raw_x)

	# 3. Timeline progression & auto-advance
	_timeline += delta
	_update_timeline_shots()


## Starts the cinematic sequence.
func start(session: GameSession, player: CharacterBody2D, diag: DialogueBox) -> void:
	_session = session
	_player = player
	_diag = diag
	_is_playing = true
	_is_skipping = false
	_pan_time = 0.0
	_timeline = 0.0
	_confirm_hold_time = 0.0
	_current_shot = 1
	_device_click_fired = false
	_dialogue_manually_advanced = false
	_dialogue_finished = false

	# Pause simulation clock per ADR-004
	if _session != null and _session.sim_clock != null:
		_session.sim_clock.is_paused = true

	# Block player input and movement
	if _player != null:
		Player.set_player_blocked(self, true, _player)

	_setup_compositing()
	if _is_reduced_effects():
		_apply_pan_position(reduced_effects_static_x)
	else:
		_apply_pan_position(start_pan_x)

	# Connect and play dialogue sequence
	if _diag != null:
		if not _diag.sequence_finished.is_connected(_on_dialogue_finished):
			_diag.sequence_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
		if not _diag.line_advanced.is_connected(_on_dialogue_line_advanced):
			_diag.line_advanced.connect(_on_dialogue_line_advanced)

		_diag.play_sequence(
			&"ch01_b10_outro",
			[
				["SPK_ELIAS", "EL_B10_01"],
				["SPK_OPERATOR", "OP_B10_01"],
				["SPK_OPERATOR", "OP_B10_02"],
			],
			true
		)

	cinematic_started.emit()
	shot_advanced.emit(1)


## Skips the cinematic immediately and proceeds to completion.
func skip() -> void:
	if _is_skipping or not _is_playing:
		return
	_is_skipping = true

	if _diag != null and _diag.is_active and _diag.current_sequence_id == &"ch01_b10_outro":
		_diag.finish_sequence()

	cinematic_skipped.emit()
	_finish_cinematic()


func is_playing() -> bool:
	return _is_playing and not _is_skipping


func get_current_pan_x() -> float:
	if plate_container != null:
		return plate_container.position.x
	return start_pan_x


## Top of the plate: the black bar above it, (540 - 360) / 2 = 90 px at 960 x 540.
static func letterbox_top() -> float:
	var view_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 540)
	return floorf((view_h - PLATE_SIZE.y) * 0.5)


func _apply_pan_position(target_x: float) -> void:
	if plate_container != null:
		# Enforce exact integer pixel step to avoid subpixel blur
		plate_container.position = Vector2(round(target_x), letterbox_top())


func _update_timeline_shots() -> void:
	if _dialogue_manually_advanced:
		# The player advanced the lines ([Enter]): they drive the dialogue now, and the cinematic
		# ends with the last line.
		if _dialogue_finished:
			_finish_cinematic()
		return

	var t1_start := line1_delay
	var t1_end := t1_start + line1_duration
	var t2_start := t1_end + line2_pause
	var t2_end := t2_start + line2_duration
	var t3_start := t2_end + line3_pause
	var t3_end := t3_start + line3_duration
	var outro_end := t3_end + outro_hold_duration

	# Shot 2: Line 1 (EL_B10_01)
	if _timeline >= t1_start and _timeline < t1_end:
		if _current_shot < 2:
			_current_shot = 2
			shot_advanced.emit(2)
			if _diag != null and _diag.panel != null:
				_diag.panel.visible = true

	# Shot 3: Pause + device click
	elif _timeline >= t1_end and _timeline < t2_start:
		if _current_shot < 3:
			_current_shot = 3
			shot_advanced.emit(3)
			if _diag != null and _diag.panel != null:
				_diag.panel.visible = false
			if not _device_click_fired:
				_device_click_fired = true
				device_click_played.emit()
				if audio_click != null and audio_click.stream != null:
					audio_click.play()

	# Shot 4: Line 2 (OP_B10_01 "You are late.")
	elif _timeline >= t2_start and _timeline < t2_end:
		if _current_shot < 4:
			_current_shot = 4
			shot_advanced.emit(4)
			if _diag != null and _diag.is_active:
				if _diag.current_line_index == 0:
					_timeline_advance()
				if _diag.panel != null:
					_diag.panel.visible = true

	# Shot 5: 1.0 s canon pause before OP_B10_02
	elif _timeline >= t2_end and _timeline < t3_start:
		if _current_shot < 5:
			_current_shot = 5
			shot_advanced.emit(5)
			if _diag != null and _diag.panel != null:
				_diag.panel.visible = false

	# Shot 6: Line 3 (OP_B10_02 "Again.")
	elif _timeline >= t3_start and _timeline < t3_end:
		if _current_shot < 6:
			_current_shot = 6
			shot_advanced.emit(6)
			if _diag != null and _diag.is_active:
				if _diag.current_line_index == 1:
					_timeline_advance()
				if _diag.panel != null:
					_diag.panel.visible = true

	# Shot 7: Hold on vista then finish
	elif _timeline >= t3_end and _timeline < outro_end:
		if _current_shot < 7:
			_current_shot = 7
			shot_advanced.emit(7)
			if _diag != null and _diag.is_active:
				_timeline_advance()

	elif _timeline >= outro_end:
		_finish_cinematic()


## Advances the dialogue on the timeline's schedule; not a manual advance.
func _timeline_advance() -> void:
	_timeline_advancing = true
	_diag.advance_line()
	_timeline_advancing = false


func _on_dialogue_line_advanced(_line_idx: int, _total: int) -> void:
	if _timeline_advancing:
		return
	_dialogue_manually_advanced = true
	if _diag != null and _diag.panel != null:
		_diag.panel.visible = true


func _on_dialogue_finished(_seq_id: StringName) -> void:
	_dialogue_finished = true
	if _dialogue_manually_advanced or _is_skipping:
		_finish_cinematic()


func _finish_cinematic() -> void:
	if not _is_playing and not _is_skipping:
		return
	_is_playing = false
	_is_skipping = false

	# Restore simulation clock
	if _session != null and _session.sim_clock != null:
		_session.sim_clock.is_paused = false

	# Restore narrative heard flag
	if _session != null and _session.narrative_state != null:
		_session.narrative_state.set_flag(&"heard.ch01_b10_outro", true)

	# Restore player movement block
	if _player != null:
		Player.set_player_blocked(self, false, _player)

	cinematic_completed.emit()
	queue_free()


func _setup_compositing() -> void:
	if city_plate == null:
		return
	if use_layer_compositing:
		city_plate.visible = false
		if backdrop != null: backdrop.visible = true
		if mira_screen_left != null: mira_screen_left.visible = true
		if mira_screen_right != null: mira_screen_right.visible = true
		if suspended_rain != null: suspended_rain.visible = true
	else:
		city_plate.visible = true
		if backdrop != null: backdrop.visible = false
		if mira_screen_left != null: mira_screen_left.visible = false
		if mira_screen_right != null: mira_screen_right.visible = false
		if suspended_rain != null: suspended_rain.visible = false


func _update_skip_label() -> void:
	if skip_label != null:
		skip_label.text = "[Esc] Skip  |  Hold [Enter]"


func _is_reduced_effects() -> bool:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		var settings = get_tree().root.get_node_or_null("Settings")
		if settings != null and "reduced_effects" in settings:
			return settings.reduced_effects
	return false
