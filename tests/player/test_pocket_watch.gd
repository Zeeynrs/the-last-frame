extends "res://tests/support/base_test.gd"

## Automated unit tests for PocketWatch per ADR-006, ADR-007, ADR-008, and ADR-015.
## Covers cycling order, capability-preferring targeting, fallbacks, radii, Echo state machine,
## and ability dispatching.

const GATE := &"ch01.test.gate"
const PILLAR := &"ch01.test.pillar"
const SHUTTER := &"ch01.test.shutter"
const GEAR := &"ch01.test.gear"
const ANCHOR := &"ch01.test.anchor"


func test_ability_cycling_order_and_wrap() -> void:
	var watch = PocketWatch.new()
	watch.unlocked_abilities = [&"trace", &"rewind", &"freeze", &"echo"]
	watch._ready()

	_assert_eq(watch.selected_ability, &"trace", "Initial ability should be trace")

	watch.next_ability()
	_assert_eq(watch.selected_ability, &"rewind", "Next after trace should be rewind")

	watch.next_ability()
	_assert_eq(watch.selected_ability, &"freeze", "Next after rewind should be freeze")

	watch.next_ability()
	_assert_eq(watch.selected_ability, &"echo", "Next after freeze should be echo")

	# Wrap-around forward
	watch.next_ability()
	_assert_eq(watch.selected_ability, &"trace", "Next after echo should wrap to trace")

	# Wrap-around backward
	watch.prev_ability()
	_assert_eq(watch.selected_ability, &"echo", "Prev from trace should wrap to echo")

	watch.prev_ability()
	_assert_eq(watch.selected_ability, &"freeze", "Prev from echo should be freeze")

	watch.free()


func test_targeting_preference_for_supporting_object() -> void:
	var s = make_session()

	# Nearer object (dist = 30 px) does NOT support Freeze
	var nearer_unsupported = spawn(s, Interactable.new(), &"ch01.near.pillar")
	nearer_unsupported.global_position = Vector2(30, 0)

	# Farther object (dist = 60 px) supports Freeze
	var temporal = make_temporal(TemporalComponent.CAP_FREEZE, [])
	var farther_supporting = spawn(s, TemporalTestGear.new(), &"ch01.far.gear", temporal)
	farther_supporting.global_position = Vector2(60, 0)

	var candidates = [nearer_unsupported, farther_supporting]

	# When FREEZE is selected, must prefer the supporting object over the nearer unsupported one
	var target = PocketWatch.choose_watch_target(Vector2.ZERO, candidates, &"freeze", 96.0)
	_assert_true(target != null, "Should find a target")
	_assert_eq(target.object_id, &"ch01.far.gear", "Should prefer supporting object even though it is farther")

	free_session(s)


func test_targeting_fallback_to_nearest() -> void:
	var s = make_session()

	# Neither object supports Freeze
	var obj_a = spawn(s, Interactable.new(), &"ch01.obj.a")
	obj_a.global_position = Vector2(25, 0)

	var obj_b = spawn(s, Interactable.new(), &"ch01.obj.b")
	obj_b.global_position = Vector2(50, 0)

	var candidates = [obj_a, obj_b]

	# Fallback: nearest overall so unsupported feedback stays teachable
	var target = PocketWatch.choose_watch_target(Vector2.ZERO, candidates, &"freeze", 96.0)
	_assert_true(target != null, "Should fallback to nearest")
	_assert_eq(target.object_id, &"ch01.obj.a", "Fallback should pick closest object")

	free_session(s)


func test_targeting_tie_break_lexicographical() -> void:
	var s = make_session()

	# Two objects at identical distance
	var obj_z = spawn(s, Interactable.new(), &"ch01.obj.z")
	obj_z.global_position = Vector2(40, 0)

	var obj_a = spawn(s, Interactable.new(), &"ch01.obj.a")
	obj_a.global_position = Vector2(40, 0)

	var candidates = [obj_z, obj_a]

	var target = PocketWatch.choose_watch_target(Vector2.ZERO, candidates, &"freeze", 96.0)
	_assert_true(target != null)
	_assert_eq(target.object_id, &"ch01.obj.a", "Tie-break should select lexicographically smaller object_id")

	free_session(s)


func test_targeting_out_of_radius_rejected() -> void:
	var s = make_session()

	# Object just outside 96 px radius (97 px)
	var obj_out = spawn(s, Interactable.new(), &"ch01.obj.out")
	obj_out.global_position = Vector2(97, 0)

	var target = PocketWatch.choose_watch_target(Vector2.ZERO, [obj_out], &"rewind", 96.0)
	_assert_true(target == null, "Object outside 96 px radius should be ignored")

	free_session(s)


func test_watch_dispatches_correct_interaction_id() -> void:
	var s = make_session()
	var temporal = make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
		[{"arm_state": &"open", "passage_blocked": false}])
	var gate = spawn(s, TemporalTestGate.new(), GATE, temporal)
	gate.global_position = Vector2(30, 0)

	var player = Player.new()
	player.global_position = Vector2.ZERO
	s.add_child(player)

	var watch = player.pocket_watch
	watch.set_selected_ability(&"rewind")
	watch.update_targeting()

	_assert_true(watch.current_target != null, "Watch should target gate")
	_assert_eq(watch.current_target.object_id, GATE)

	var res = watch.activate_watch()
	_assert_true(res.ok, "Watch rewind should succeed on gate")
	_assert_true(watch.last_result != null)
	_assert_true(watch.last_result.ok)

	free_session(s)


func test_echo_watch_state_machine_and_reset() -> void:
	var s = make_session()
	var player = Player.new()
	s.add_child(player)

	var watch = player.pocket_watch
	watch.set_selected_ability(&"echo")

	var echo_svc = s.echo_service
	_assert_true(echo_svc != null, "GameSession must have echo_service")
	_assert_eq(echo_svc.state, 0, "Echo starts IDLE")

	# Watch on Echo in IDLE -> start_recording
	var r1 = watch.activate_watch()
	_assert_true(r1.ok)
	_assert_eq(echo_svc.state, 1, "Echo state should be RECORDING")

	# Advance 20 ticks
	s.sim_clock.step(20)

	# Watch on Echo in RECORDING -> stop_recording
	var r2 = watch.activate_watch()
	_assert_true(r2.ok)
	_assert_eq(echo_svc.state, 2, "Echo state should be READY")

	# Watch on Echo in READY -> start_playback
	var r3 = watch.activate_watch()
	_assert_true(r3.ok)
	_assert_true(echo_svc.state in [3, 4], "Echo state should be PLAYING or HOLDING")

	# echo_reset -> resets echo back to IDLE
	watch.reset_echo()
	_assert_eq(echo_svc.state, 0, "Echo should be reset to IDLE")

	free_session(s)


func test_targeting_echo_clears_target() -> void:
	var s = make_session()
	var pillar = spawn(s, Interactable.new(), PILLAR)
	pillar.global_position = Vector2(30, 0)

	var player = Player.new()
	s.add_child(player)

	var watch = player.pocket_watch
	watch.set_selected_ability(&"rewind")
	watch.update_targeting()
	_assert_true(watch.current_target != null, "Target should exist for rewind")

	# Switching to Echo should clear target
	watch.set_selected_ability(&"echo")
	_assert_true(watch.current_target == null, "Echo must clear watch target")

	free_session(s)


func test_player_interact_failure_shows_hud_feedback() -> void:
	var s = make_session()
	# Collapsed gate: interacting with 'use' fails with 'jammed'
	var temporal = make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
		[{"arm_state": &"open", "passage_blocked": false}])
	var gate = spawn(s, TemporalTestGate.new(), GATE, temporal)
	gate.global_position = Vector2(20, 0)

	var player = Player.new()
	player.global_position = Vector2.ZERO
	s.add_child(player)
	player.current_target = gate

	# Simulate interact call
	var res = s.interaction_service.request(player.actor_id, gate.object_id, &"use")
	_assert_false(res.ok, "use on collapsed gate fails")
	_assert_eq(res.reason, &"jammed")

	# Pass to player HUD
	if player.hud != null:
		player.hud.show_feedback(res.reason)
		_assert_true(player.hud.feedback_panel.visible, "HUD should show toast on interact failure")
		_assert_eq(player.hud.feedback_label.text, "Mechanism is jammed.")

	free_session(s)
