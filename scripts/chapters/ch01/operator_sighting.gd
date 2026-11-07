class_name OperatorSighting
extends Node2D

## Operator sighting on the Arrival Platform (Story Bible Ch1 Event 7 / TLF-058).
## Follows docs/OPERATOR_MYSTERY_GUIDELINES.md strictly:
## - No visible face, no dialogue, no name reveal.
## - Appears after the pocket watch pickup (ch01.flag.pocket_watch_acquired).
## - Loops the 4-frame watch-check animation at cadence 0.25 / 0.25 / 1.00 / 0.25 s.
## - Static pose on frame 2 (F3) and suppressed trace ring under reduced_effects.
## - Fades out over 0.5 s (or instant cut with reduced_effects) when Elias approaches.
## - Emits audio_sting_requested / plays audio sting hook for TLF-064.
## - Sets ch01.flag.operator_sighting_seen and adds JRN_CH1_FIGURE journal entry.
## - Persists once per save; never re-appears after being seen.

signal audio_sting_requested()

const FLAG_WATCH_ACQUIRED: StringName = &"ch01.flag.pocket_watch_acquired"
const FLAG_SIGHTING_SEEN: StringName = &"ch01.flag.operator_sighting_seen"
const JOURNAL_KEY: String = "JRN_CH1_FIGURE"
const JOURNAL_CATEGORY: String = "observation"

## Cadence: F1 (0.25 s) -> F2 (0.25 s) -> F3 (1.00 s) -> F4 (0.25 s) = 1.75 s
const FRAME_DURATIONS: Array[float] = [0.25, 0.25, 1.00, 0.25]
const CYCLE_DURATION: float = 1.75
const FADE_DURATION: float = 0.5

@export var approach_trigger: TriggerZone
@export var figure_sprite: Sprite2D
@export var ground_ring: Sprite2D
@export var audio_player: AudioStreamPlayer2D

var _cycle_time: float = 0.0
var _is_active: bool = false
var _is_vanishing: bool = false
var _seen: bool = false
var _tween: Tween


func _ready() -> void:
	if figure_sprite == null:
		figure_sprite = get_node_or_null("FigureSprite") as Sprite2D
	if ground_ring == null:
		ground_ring = get_node_or_null("GroundRing") as Sprite2D
	if audio_player == null:
		audio_player = get_node_or_null("AudioSting") as AudioStreamPlayer2D
	if approach_trigger == null:
		approach_trigger = get_node_or_null("ApproachTrigger") as TriggerZone

	if approach_trigger != null:
		if not approach_trigger.actor_entered.is_connected(_on_actor_entered):
			approach_trigger.actor_entered.connect(_on_actor_entered)
		if not approach_trigger.body_entered.is_connected(_on_body_entered):
			approach_trigger.body_entered.connect(_on_body_entered)

	var sess := _get_session()
	if sess != null and sess.narrative_state != null:
		if not sess.narrative_state.flag_changed.is_connected(_on_flag_changed):
			sess.narrative_state.flag_changed.connect(_on_flag_changed)

	var s := _get_settings()
	if s != null and s.has_signal("setting_changed"):
		if not s.setting_changed.is_connected(_on_setting_changed):
			s.setting_changed.connect(_on_setting_changed)

	refresh_state()


func _process(delta: float) -> void:
	if not _is_active or _is_vanishing or not visible:
		return

	if _is_reduced_effects():
		if figure_sprite != null and figure_sprite.frame != 2:
			figure_sprite.frame = 2
		if ground_ring != null and ground_ring.visible:
			ground_ring.visible = false
		return

	if ground_ring != null and not ground_ring.visible:
		ground_ring.visible = true

	_cycle_time += delta
	while _cycle_time >= CYCLE_DURATION:
		_cycle_time -= CYCLE_DURATION

	var target_frame: int = 0
	if _cycle_time < 0.25:
		target_frame = 0
	elif _cycle_time < 0.50:
		target_frame = 1
	elif _cycle_time < 1.50:
		target_frame = 2
	else:
		target_frame = 3

	if figure_sprite != null and figure_sprite.frame != target_frame:
		figure_sprite.frame = target_frame


## Updates visibility, animation, and active state based on session flags and settings.
func refresh_state() -> void:
	var sess := _get_session()
	var seen: bool = false
	var watch_acquired: bool = false

	if sess != null and sess.narrative_state != null:
		seen = bool(sess.narrative_state.get_flag(FLAG_SIGHTING_SEEN, false))
		watch_acquired = bool(sess.narrative_state.get_flag(FLAG_WATCH_ACQUIRED, false))
	else:
		seen = _seen

	if seen:
		_seen = true
		_is_active = false
		_is_vanishing = false
		visible = false
		set_process(false)
		return

	if watch_acquired:
		_is_active = true
		_is_vanishing = false
		visible = true
		modulate.a = 1.0
		_cycle_time = 0.0
		set_process(true)
		_apply_reduced_effects_state()
	else:
		_is_active = false
		_is_vanishing = false
		visible = false
		set_process(false)


func is_figure_active() -> bool:
	return _is_active and visible and not _is_vanishing


func is_seen() -> bool:
	return _seen


## Triggers the vanish sequence programmatically or upon player approach.
func trigger_approach() -> void:
	_trigger_vanish()


func play_audio_sting() -> void:
	audio_sting_requested.emit()
	if audio_player != null and audio_player.stream != null:
		audio_player.play()


func _trigger_vanish() -> void:
	if not _is_active or _is_vanishing or _seen:
		return
	_is_vanishing = true
	_seen = true

	play_audio_sting()

	var sess := _get_session()
	if sess != null and sess.narrative_state != null:
		sess.narrative_state.set_flag(FLAG_SIGHTING_SEEN, true)
		sess.narrative_state.add_journal_entry(JOURNAL_KEY, JOURNAL_CATEGORY)

	if _is_reduced_effects():
		visible = false
		_is_vanishing = false
		_is_active = false
		set_process(false)
	else:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
		_tween.tween_callback(func() -> void:
			visible = false
			_is_vanishing = false
			_is_active = false
			set_process(false)
		)


func _apply_reduced_effects_state() -> void:
	if not _is_active or _is_vanishing or not visible:
		return
	if _is_reduced_effects():
		if figure_sprite != null:
			figure_sprite.frame = 2
		if ground_ring != null:
			ground_ring.visible = false
	else:
		if ground_ring != null:
			ground_ring.visible = true


func _on_actor_entered(actor_id: StringName) -> void:
	if not _is_active or _is_vanishing:
		return
	if actor_id == &"player" or String(actor_id) == "player":
		_trigger_vanish()


func _on_body_entered(body: Node) -> void:
	if not _is_active or _is_vanishing:
		return
	if "actor_id" in body and (body.actor_id == &"player" or String(body.actor_id) == "player"):
		_trigger_vanish()
	elif body.name == "player" or body.name == "Player":
		_trigger_vanish()


func _on_flag_changed(flag_id: StringName, value: Variant) -> void:
	if flag_id == FLAG_WATCH_ACQUIRED and bool(value) and not _seen:
		refresh_state()
	elif flag_id == FLAG_SIGHTING_SEEN and bool(value):
		refresh_state()


func _on_setting_changed(setting_name: StringName, _value: Variant) -> void:
	if setting_name == &"reduced_effects":
		_apply_reduced_effects_state()


func _get_session() -> GameSession:
	var p := get_parent()
	while p != null:
		if p is GameSession:
			return p as GameSession
		if p.is_in_group(&"game_session") and "narrative_state" in p:
			return p as GameSession
		p = p.get_parent()
	if is_inside_tree() and get_tree() != null:
		var found = get_tree().get_first_node_in_group(&"game_session")
		if found != null:
			return found as GameSession
	return null


func _get_settings() -> Node:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		return get_tree().root.get_node_or_null("Settings")
	return null


func _is_reduced_effects() -> bool:
	var s := _get_settings()
	if s != null and "reduced_effects" in s:
		return s.reduced_effects
	return false
