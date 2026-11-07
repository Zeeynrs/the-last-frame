extends "res://tests/support/base_test.gd"

## Unit tests for AudioFeedback per ADR-022 A5 and TLF-064.
## Validates sound stream loading, signal wiring for abilities, refusals,
## Echo lifecycle, Operator motif, sighting sting, device click, clock ticking,
## and AudioServer bus volume settings.

const AudioFeedbackScript = preload("res://scripts/audio/audio_feedback.gd")

var _feedback: Node = null


func _setup_feedback() -> Node:
	_feedback = AudioFeedbackScript.new()
	scene_tree.root.add_child(_feedback)
	return _feedback


func _cleanup_feedback() -> void:
	if _feedback != null and is_instance_valid(_feedback):
		_feedback.free()
		_feedback = null
	await physics_frames(2)


func test_audio_feedback_streams_loaded() -> void:
	var fb = _setup_feedback()
	_assert_eq(fb.streams.size(), AudioFeedbackScript.SOUND_PATHS.size(), "All 11 sound streams loaded")

	for id in AudioFeedbackScript.SOUND_PATHS:
		var stream = fb.streams.get(id)
		_assert_true(stream != null, "Stream '%s' exists" % String(id))
		_assert_true(stream is AudioStream, "Stream '%s' is an AudioStream" % String(id))

	await _cleanup_feedback()


func test_audio_feedback_watch_used_abilities() -> void:
	var fb = _setup_feedback()

	# Trace
	fb.clear_history()
	fb._on_watch_used(&"trace", &"target1", InteractionResult.success())
	_assert_eq(fb.last_played_sound, &"trace", "Trace success plays sfx_ability_trace")

	# Rewind
	fb.clear_history()
	fb._on_watch_used(&"rewind", &"target2", InteractionResult.success())
	_assert_eq(fb.last_played_sound, &"rewind", "Rewind success plays sfx_ability_rewind")

	# Freeze
	fb.clear_history()
	fb._on_watch_used(&"freeze", &"target3", InteractionResult.success())
	_assert_eq(fb.last_played_sound, &"freeze", "Freeze success plays sfx_ability_freeze")

	await _cleanup_feedback()


func test_audio_feedback_ability_locked_and_refused() -> void:
	var fb = _setup_feedback()

	# Selection refused signal
	fb.clear_history()
	fb._on_ability_selection_refused(&"rewind", &"ability_locked")
	_assert_eq(fb.last_played_sound, &"ability_locked", "Selection refused plays sfx_ability_locked")

	# Watch used failure with ability_locked reason
	fb.clear_history()
	fb._on_watch_used(&"freeze", &"", InteractionResult.failure(&"ability_locked"))
	_assert_eq(fb.last_played_sound, &"ability_locked", "Watch used failure plays sfx_ability_locked")

	# Watch used failure with missing_target / unsupported reason
	fb.clear_history()
	fb._on_watch_used(&"trace", &"", InteractionResult.failure(&"missing_target"))
	_assert_eq(fb.last_played_sound, &"ability_locked", "Refused watch activation plays sfx_ability_locked")

	await _cleanup_feedback()


func test_audio_feedback_echo_service_lifecycle() -> void:
	var fb = _setup_feedback()

	# 1. State -> RECORDING
	fb.clear_history()
	fb._on_echo_state_changed(EchoService.State.RECORDING)
	_assert_eq(fb.last_played_sound, &"echo_record_start", "Transition to RECORDING plays sfx_echo_record_start")

	# 2. State -> READY (manual stop)
	fb.clear_history()
	fb._on_echo_state_changed(EchoService.State.READY)
	_assert_eq(fb.last_played_sound, &"echo_record_stop", "Transition from RECORDING to READY plays sfx_echo_record_stop")

	# 3. State -> PLAYING
	fb.clear_history()
	fb._on_echo_state_changed(EchoService.State.PLAYING)
	_assert_eq(fb.last_played_sound, &"echo_play", "Transition to PLAYING plays sfx_echo_play")

	# 4. Auto-stop while recording
	fb.clear_history()
	fb._prev_echo_state = EchoService.State.RECORDING
	fb._on_echo_recording_auto_stopped(&"max_duration")
	_assert_eq(fb.last_played_sound, &"echo_record_stop", "Auto-stop plays sfx_echo_record_stop")

	await _cleanup_feedback()


func test_audio_feedback_operator_motif_and_clock_dialogue() -> void:
	var fb = _setup_feedback()

	# Operator motif: VOICE speaks
	fb.clear_history()
	fb._on_dialogue_line_displayed("SPK_OPERATOR", "OP_B03_01")
	_assert_eq(fb.last_played_sound, &"operator_motif", "SPK_OPERATOR dialogue plays sfx_operator_motif")

	# Other speaker does not trigger Operator motif
	fb.clear_history()
	fb._on_dialogue_line_displayed("SPK_ELIAS", "EL_B01_01")
	_assert_true(fb.last_played_sound != &"operator_motif", "SPK_ELIAS does not trigger Operator motif")

	# Examine 23:59 clock
	fb.clear_history()
	fb._on_dialogue_line_displayed("SPK_ELIAS", "EL_CLOCK_2359")
	_assert_eq(fb.last_played_sound, &"clock_tick", "EL_CLOCK_2359 dialogue plays sfx_clock_tick")

	await _cleanup_feedback()


func test_audio_feedback_operator_sighting_and_device_click() -> void:
	var fb = _setup_feedback()

	# Operator sighting vanish sting
	fb.clear_history()
	fb._on_operator_sting_requested()
	_assert_eq(fb.last_played_sound, &"operator_sighting", "Operator vanish sting plays sfx_operator_sighting")

	# Beat 10 street device click
	fb.clear_history()
	fb._on_device_click_played()
	_assert_eq(fb.last_played_sound, &"device_click", "Beat 10 device click plays sfx_device_click")

	await _cleanup_feedback()


func test_audio_feedback_clock_proximity_ticking() -> void:
	var fb = _setup_feedback()

	var dummy_clock := Node2D.new()
	dummy_clock.name = "digital_clock_2359"
	dummy_clock.position = Vector2(200, 200)
	scene_tree.root.add_child(dummy_clock)

	var dummy_player := Node2D.new()
	dummy_player.name = "Player"
	dummy_player.position = Vector2(250, 200) # distance = 50px (< CLOCK_PROXIMITY_RADIUS)
	scene_tree.root.add_child(dummy_player)

	fb._player_node_ref = dummy_player
	fb._active_clock_nodes = [dummy_clock]

	# Advance less than interval -> no tick
	fb.clear_history()
	fb._update_clock_tick(0.5)
	_assert_false(fb.was_sound_played(&"clock_tick"), "No tick before full interval")

	# Advance past interval -> tick played
	fb._update_clock_tick(0.6)
	_assert_true(fb.was_sound_played(&"clock_tick"), "Tick played when player within proximity radius")

	# Move player far away (> 180px)
	dummy_player.position = Vector2(500, 500)
	fb.clear_history()
	fb._update_clock_tick(1.1)
	_assert_false(fb.was_sound_played(&"clock_tick"), "No tick when player outside proximity radius")

	dummy_player.free()
	dummy_clock.free()
	await _cleanup_feedback()


func test_audio_volume_settings_integration() -> void:
	var settings: Node = null
	if scene_tree.root.has_node("Settings"):
		settings = scene_tree.root.get_node("Settings")

	if settings == null:
		return

	# Save current volumes
	var orig_sfx: float = settings.sfx_volume
	var orig_voice: float = settings.voice_volume

	# Test SFX bus volume mapping
	settings.sfx_volume = 0.5
	var sfx_idx = AudioServer.get_bus_index("SFX")
	_assert_true(sfx_idx >= 0, "SFX audio bus exists")
	var vol_db = AudioServer.get_bus_volume_db(sfx_idx)
	var expected_db = linear_to_db(0.5)
	_assert_true(absf(vol_db - expected_db) < 0.1, "SFX volume maps correctly to AudioServer bus")

	# Test SFX mute when linear_vol is 0
	settings.sfx_volume = 0.0
	_assert_true(AudioServer.is_bus_mute(sfx_idx), "SFX bus muted when volume set to 0.0")

	# Restore original volumes
	settings.sfx_volume = orig_sfx
	settings.voice_volume = orig_voice
	settings.apply_audio_volumes()
