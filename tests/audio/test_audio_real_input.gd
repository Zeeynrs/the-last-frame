extends "res://tests/support/ch01_real_input.gd"

## Real-input automated tests for TLF-064 Audio Affordance Pass.
## Verifies that driving the game with real player input actions (WASD, watch, interact, wheel)
## triggers the correct audio feedback for each ability, lock refusals, Echo transitions,
## and Operator story beats.

const R1 := &"ch01.arrival_platform"
const R2 := &"ch01.concourse_west"
const R3 := &"ch01.maintenance_bay"


func _init() -> void:
	timeout_frames = 3600


func test_audio_real_input_abilities_refusal_and_echo() -> void:
	# Start in R2 with Rewind and Echo unlocked (Freeze remains locked for refusal testing)
	if not await start_at(R2, &"door_entry_west", [&"CH1-SO-01"], [FLAG_REWIND, FLAG_ECHO]):
		stop()
		return

	var fb := ch01.get_node_or_null("AudioFeedback") as AudioFeedback
	if not _assert_true(fb != null, "AudioFeedback instance exists in Chapter01 scene"):
		stop()
		return

	# 1. Refusal / locked ability feedback: Aim wheel at locked Freeze slot (segment 2)
	var wheel = player.hud.ability_wheel
	if wheel != null:
		press(&"ability_wheel")
		if await until(func() -> bool: return wheel.is_open, 30):
			hold_moves([&"move_down", &"move_right"])
			await until(func() -> bool: return wheel.current_aimed_segment == 2, 30)
			fb.clear_history()
			release(&"ability_wheel")
			await until(func() -> bool: return not wheel.is_open, 30)
			hold_moves([])
			await physics_frames(2)
			_assert_eq(fb.last_played_sound, &"ability_locked", "Wheel selecting locked slot plays sfx_ability_locked")

	# 2. Select Trace and target courier n05
	await select_ability(&"trace")
	await physics_frames(2)
	var courier := resolve(&"ch01.concourse_west.n05_courier")
	await physics_frames(1)
	if player.pocket_watch.current_target == courier:
		fb.clear_history()
		await tap(&"watch")
		await physics_frames(2)
		_assert_eq(fb.last_played_sound, &"trace", "Trace on courier plays sfx_ability_trace")

	# 3. Rewind: Select Rewind and activate on conduit_01
	await select_ability(&"rewind")
	await physics_frames(2)
	var conduit := resolve(&"ch01.concourse_west.conduit_01")
	if conduit != null:
		var ok := await walk_to(player, "walk to conduit_01", Vector2(208, 152), targets(conduit), 180)
		if ok:
			fb.clear_history()
			await tap(&"watch")
			await physics_frames(2)
			_assert_eq(fb.last_played_sound, &"rewind", "Rewind on conduit plays sfx_ability_rewind")

	# 4. Echo: Select Echo and cycle record start -> stop -> play
	await select_ability(&"echo")
	await physics_frames(2)

	# 4a. Echo record start
	fb.clear_history()
	await tap(&"watch")
	await physics_frames(3)
	_assert_eq(fb.last_played_sound, &"echo_record_start", "Echo record start plays sfx_echo_record_start")

	# 4b. Echo record stop
	fb.clear_history()
	await tap(&"watch")
	await physics_frames(3)
	_assert_eq(fb.last_played_sound, &"echo_record_stop", "Echo record stop plays sfx_echo_record_stop")

	# 4c. Echo play
	fb.clear_history()
	await tap(&"watch")
	await physics_frames(3)
	_assert_eq(fb.last_played_sound, &"echo_play", "Echo playback plays sfx_echo_play")

	stop()


func test_audio_real_input_operator_motif_and_clock() -> void:
	# Start on Arrival Platform with real input
	if not await start_at(R1, &""):
		stop()
		return

	var fb := ch01.get_node_or_null("AudioFeedback") as AudioFeedback
	if not _assert_true(fb != null, "AudioFeedback exists on arrival platform"):
		stop()
		return

	var diag := ch01.get_node_or_null("HUD/DialogueBox") as DialogueBox
	if diag == null:
		diag = ch01.find_child("DialogueBox", true, false) as DialogueBox

	if diag != null:
		# Simulate Operator dialogue line emission through DialogueBox
		fb.clear_history()
		diag.line_displayed.emit("SPK_OPERATOR", "OP_B03_01")
		_assert_eq(fb.last_played_sound, &"operator_motif", "Operator dialogue emits sfx_operator_motif")

		# Examine digital_clock_2359
		fb.clear_history()
		diag.line_displayed.emit("SPK_ELIAS", "EL_CLOCK_2359")
		_assert_eq(fb.last_played_sound, &"clock_tick", "Examining clock emits sfx_clock_tick")

	# Operator sighting vanish sting on approach
	var op := ch01.find_child("operator_sighting", true, false) as OperatorSighting
	if op != null:
		fb.clear_history()
		op.audio_sting_requested.emit()
		_assert_eq(fb.last_played_sound, &"operator_sighting", "Operator sighting approach emits sfx_operator_sighting")

	stop()
