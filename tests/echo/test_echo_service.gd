extends "res://tests/support/base_test.gd"

## EchoService (ADR-008 + am., ADR-015 controls) incl. CH1-PZ-003/004 spec behaviours.

const SWITCH := &"ch01.test.pressure_switch"
const EXIT := &"ch01.test.exit_trigger"
const BREAKER := &"ch01.test.breaker"
const PICKUP := &"ch01.test.pickup"


## Breaker stand-in: rejects use while unpowered (PZ-004 "unpowered" rule), records who pulled it when.
class TestBreaker extends Interactable:
	var powered: bool = true
	var pulls: Array = []

	func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
		return &"" if powered else &"unpowered"

	func _on_use(actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
		var sess := get_session()
		pulls.append([actor_id, sess.sim_clock.tick])


class Mover extends Node2D:
	pass


func _switch(s: GameSession, id: StringName = SWITCH) -> TriggerZone:
	return spawn(s, TriggerZone.new(), id) as TriggerZone


func _echo(s: GameSession) -> EchoService:
	return s.echo_service


func _svc(s: GameSession) -> InteractionService:
	return s.interaction_service


## Records: player steps on the switch at rel 40, recording stops at rel 80, player steps off at rel 90.
func _record_switch_hold(s: GameSession) -> void:
	_echo(s).start_recording()
	s.sim_clock.step(40)
	_svc(s).trigger_enter(&"player", SWITCH)
	s.sim_clock.step(40)
	_echo(s).stop_recording()
	s.sim_clock.step(10)
	_svc(s).trigger_exit(&"player", SWITCH)


func test_recording_captures_player_events_with_relative_ticks() -> void:
	var s := make_session()
	_switch(s)
	spawn(s, TestBreaker.new(), BREAKER)
	s.sim_clock.step(7)
	_echo(s).start_recording()
	s.sim_clock.step(40)
	_svc(s).trigger_enter(&"player", SWITCH)
	s.sim_clock.step(10)
	_svc(s).request(&"player", BREAKER, &"use")
	_echo(s).stop_recording()
	var events := _echo(s).get_events()
	_assert_eq(events.size(), 2, "two events")
	_assert_eq([events[0][0], events[0][1], events[0][2]], [40, &"trigger_enter", SWITCH], "enter at rel 40")
	_assert_eq([events[1][0], events[1][1], events[1][2], events[1][3]], [50, &"interact", BREAKER, &"use"], "use at rel 50")
	_assert_eq(_echo(s).get_record_length(), 50, "length 50")
	_assert_eq(_echo(s).state, EchoService.State.READY, "READY after stop")
	free_session(s)


func test_watch_abilities_and_non_player_actors_are_not_recorded() -> void:
	var s := make_session()
	var gate := TemporalTestGate.new()
	spawn(s, gate, &"ch01.test.gate", make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
		[{"arm_state": &"open", "passage_blocked": false}]))
	spawn(s, TestBreaker.new(), BREAKER)
	_echo(s).start_recording()
	s.sim_clock.step(5)
	_svc(s).request(&"player", &"ch01.test.gate", &"rewind")
	_svc(s).request(&"echo.1", BREAKER, &"use")
	_echo(s).stop_recording()
	_assert_eq(_echo(s).get_events(), [], "rewind (ability) and foreign actor ignored")
	free_session(s)


func test_triggers_occupied_at_record_start_are_seeded_at_rel_zero() -> void:
	var s := make_session()
	_switch(s)
	_svc(s).trigger_enter(&"player", SWITCH)
	s.sim_clock.step(3)
	_echo(s).start_recording()
	s.sim_clock.step(20)
	_echo(s).stop_recording()
	var events := _echo(s).get_events()
	_assert_eq(events.size(), 1, "one seeded event")
	_assert_eq([events[0][0], events[0][1], events[0][2]], [0, &"trigger_enter", SWITCH], "seeded at rel 0")
	free_session(s)


func test_pz003_02_echo_keeps_holding_switch_after_playback() -> void:
	var s := make_session()
	var sw := _switch(s)
	_record_switch_hold(s)                      # now tick 90, player off the switch
	_assert_false(sw.is_occupied(), "switch released by player")
	s.sim_clock.step(10)                        # tick 100
	_assert_eq(_echo(s).start_playback(), &"", "playback starts")
	s.sim_clock.step(39)
	_assert_false(sw.is_occupied(), "not yet at tick 139")
	s.sim_clock.step(1)
	_assert_true(&"echo.0" in sw.occupants, "echo enters at tick 140 (100 + 40)")
	s.sim_clock.step(160)                       # tick 300, far past rel_end 80
	_assert_eq(_echo(s).state, EchoService.State.HOLDING, "HOLDING after playback")
	_assert_true(&"echo.0" in sw.occupants, "occupancy kept while holding")
	free_session(s)


func test_pz003_03_reset_releases_occupancy() -> void:
	var s := make_session()
	var sw := _switch(s)
	_record_switch_hold(s)
	_echo(s).start_playback()
	s.sim_clock.step(60)
	_assert_true(sw.is_occupied(), "held by echo")
	_echo(s).reset_echo()
	_assert_false(sw.is_occupied(), "trigger_exit dispatched on reset")
	_assert_eq(_echo(s).state, EchoService.State.IDLE, "IDLE")
	_assert_eq(_echo(s).get_events(), [], "recording cleared")
	free_session(s)


func test_pz003_04_echo_cannot_take_progression_items() -> void:
	var s := make_session()
	var pickup := TestBreaker.new()
	pickup.progression = true
	spawn(s, pickup, PICKUP)
	var failures: Array = []
	_echo(s).echo_event_failed.connect(func(tick, target, reason): failures.append([tick, target, reason]))
	_echo(s).start_recording()
	s.sim_clock.step(10)
	_svc(s).request(&"player", PICKUP, &"use")
	_echo(s).stop_recording()
	pickup.pulls.clear()
	_echo(s).start_playback()                   # tick 10
	s.sim_clock.step(10)                        # tick 20 -> rel 10
	_assert_eq(failures, [[20, PICKUP, &"echo_forbidden"]], "echo_event_failed with echo_forbidden")
	_assert_eq(pickup.pulls, [], "pickup untouched by echo")
	free_session(s)


func test_pz004_04_echo_pull_lands_on_its_recorded_offset() -> void:
	var s := make_session()
	var breaker := spawn(s, TestBreaker.new(), BREAKER) as TestBreaker
	_echo(s).start_recording()
	s.sim_clock.step(30)
	_svc(s).request(&"player", BREAKER, &"use")
	s.sim_clock.step(30)
	_echo(s).stop_recording()                   # length 60
	s.sim_clock.step(240)                       # tick 300
	breaker.pulls.clear()
	_echo(s).start_playback()
	s.sim_clock.step(30)
	_assert_eq(breaker.pulls, [[&"echo.0", 330]], "echo pulls at 300 + 30")
	free_session(s)


func test_pz004_05_unpowered_replay_fails_gracefully() -> void:
	var s := make_session()
	var breaker := spawn(s, TestBreaker.new(), BREAKER) as TestBreaker
	var failures: Array = []
	_echo(s).echo_event_failed.connect(func(_tick, target, reason): failures.append([target, reason]))
	_echo(s).start_recording()
	s.sim_clock.step(20)
	_svc(s).request(&"player", BREAKER, &"use")
	_echo(s).stop_recording()
	breaker.powered = false
	breaker.pulls.clear()
	_echo(s).start_playback()
	s.sim_clock.step(20)
	_assert_eq(failures, [[BREAKER, &"unpowered"]], "echo_event_failed(unpowered)")
	_assert_eq(breaker.pulls, [], "breaker stays open")
	free_session(s)


func test_missing_target_is_skipped_and_playback_continues() -> void:
	var s := make_session()
	var doomed := spawn(s, TestBreaker.new(), &"ch01.test.doomed") as TestBreaker
	var breaker := spawn(s, TestBreaker.new(), BREAKER) as TestBreaker
	var failures: Array = []
	_echo(s).echo_event_failed.connect(func(_tick, target, reason): failures.append([target, reason]))
	_echo(s).start_recording()
	s.sim_clock.step(5)
	_svc(s).request(&"player", &"ch01.test.doomed", &"use")
	s.sim_clock.step(5)
	_svc(s).request(&"player", BREAKER, &"use")
	_echo(s).stop_recording()
	s.remove_child(doomed)
	doomed.free()
	breaker.pulls.clear()
	_echo(s).start_playback()
	s.sim_clock.step(20)
	_assert_eq(failures, [[&"ch01.test.doomed", &"missing_target"]], "missing target reported")
	_assert_eq(breaker.pulls.size(), 1, "later event still dispatched")
	_assert_eq(_echo(s).state, EchoService.State.HOLDING, "playback completed")
	free_session(s)


func test_recording_auto_stops_at_max_length() -> void:
	var s := make_session()
	var reasons: Array = []
	_echo(s).recording_auto_stopped.connect(func(r): reasons.append(r))
	_echo(s).start_recording()
	s.sim_clock.step(1199)
	_assert_eq(_echo(s).state, EchoService.State.RECORDING, "still recording at 1199")
	s.sim_clock.step(1)
	_assert_eq(_echo(s).state, EchoService.State.READY, "stopped at 1200")
	_assert_eq(_echo(s).get_record_length(), 1200, "length capped")
	_assert_eq(reasons, [&"max_length"], "auto-stop reason")
	free_session(s)


func test_room_change_stops_recording() -> void:
	var s := make_session()
	_echo(s).start_recording()
	s.sim_clock.step(15)
	_echo(s).notify_room_changed()
	_assert_eq(_echo(s).state, EchoService.State.READY, "stopped")
	_assert_eq(_echo(s).get_record_length(), 15, "length at transition")
	free_session(s)


func test_state_machine_guards() -> void:
	var s := make_session()
	_assert_eq(_echo(s).start_playback(), &"no_recording", "cannot play from IDLE")
	_assert_eq(_echo(s).stop_recording(), &"not_recording", "cannot stop from IDLE")
	_echo(s).start_recording()
	_assert_eq(_echo(s).start_recording(), &"echo_busy", "cannot record twice")
	_assert_eq(_echo(s).start_playback(), &"no_recording", "cannot play while recording")
	_echo(s).stop_recording()
	_assert_eq(_echo(s).start_recording(), &"echo_busy", "reset required before re-recording (ADR-015)")
	free_session(s)


func test_restarting_playback_releases_then_reacquires_occupancy() -> void:
	var s := make_session()
	var sw := _switch(s)
	var log: Array = []
	sw.actor_entered.connect(func(a): log.append(["enter", a]))
	sw.actor_exited.connect(func(a): log.append(["exit", a]))
	_record_switch_hold(s)
	log.clear()
	_echo(s).start_playback()
	s.sim_clock.step(100)
	_echo(s).start_playback()                   # restart while HOLDING
	_assert_false(sw.is_occupied(), "released on restart")
	s.sim_clock.step(40)
	_assert_eq(log, [["enter", &"echo.0"], ["exit", &"echo.0"], ["enter", &"echo.0"]], "clean exit/enter sequence")
	free_session(s)


func test_completion_trigger_ignores_echo() -> void:
	var s := make_session()
	var exit_zone := TriggerZone.new()
	exit_zone.accepts_echoes = false
	spawn(s, exit_zone, EXIT)
	_svc(s).trigger_enter(&"echo.0", EXIT)
	_assert_false(exit_zone.is_occupied(), "echo ignored (ADR-016)")
	_svc(s).trigger_enter(&"player", EXIT)
	_assert_true(exit_zone.is_occupied(), "player accepted")
	free_session(s)


func test_ghost_follows_samples_and_holds_final_position() -> void:
	var s := make_session()
	var mover := Mover.new()
	s.add_child(mover)
	_echo(s).start_recording(mover)
	for i in range(10):
		mover.global_position = Vector2(i * 6, 0)
		s.sim_clock.step(6)
	mover.global_position = Vector2(99, 0)
	s.sim_clock.step(2)
	_echo(s).stop_recording()                   # length 62, final sample (99, 0)
	_assert_eq(_echo(s).get_ghost_position(0), Vector2(0, 0), "start sample")
	_assert_eq(_echo(s).get_ghost_position(9), Vector2(3, 0), "interpolated halfway between rel 6 (0,0) and rel 12 (6,0)")
	_assert_eq(_echo(s).get_ghost_position(62), Vector2(99, 0), "exact final position at end")
	_assert_eq(_echo(s).get_ghost_position(500), Vector2(99, 0), "holds final position")
	free_session(s)


func test_determinism_chunked_and_per_tick_playback_match() -> void:
	_assert_eq(_playback_ticks(true), _playback_ticks(false), "identical dispatch ticks")


func _playback_ticks(chunked: bool) -> Array:
	var s := make_session()
	var sw := _switch(s)
	var breaker := spawn(s, TestBreaker.new(), BREAKER) as TestBreaker
	var seen: Array = []
	sw.actor_entered.connect(func(a): seen.append(["enter", a, s.sim_clock.tick]))
	_echo(s).start_recording()
	s.sim_clock.step(13)
	_svc(s).trigger_enter(&"player", SWITCH)
	s.sim_clock.step(29)
	_svc(s).request(&"player", BREAKER, &"use")
	s.sim_clock.step(8)
	_echo(s).stop_recording()
	_svc(s).trigger_exit(&"player", SWITCH)
	seen.clear()
	breaker.pulls.clear()
	_echo(s).start_playback()
	if chunked:
		s.sim_clock.step(120)
	else:
		for i in range(120):
			s.sim_clock.step(1)
	var result := [seen.duplicate(), breaker.pulls.duplicate(), _echo(s).state]
	free_session(s)
	return result
