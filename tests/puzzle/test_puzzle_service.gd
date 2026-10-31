extends "res://tests/support/base_test.gd"

## PuzzleService, PuzzleCompletionZone and ResetAnchor per ADR-016.

const PZ := &"CH1-PZ-TEST"


class Member extends Node:
	var calls: Array = []

	func reset_for_puzzle(puzzle_id: StringName, is_solved: bool) -> void:
		calls.append([puzzle_id, is_solved])


func test_unknown_puzzles_are_unsolved_and_solving_is_idempotent() -> void:
	var s := make_session()
	var puzzles := s.puzzle_service
	var solved: Array = []
	puzzles.puzzle_solved.connect(func(id, tick): solved.append([id, tick]))
	_assert_eq(puzzles.get_state(PZ), PuzzleService.UNSOLVED, "default UNSOLVED")
	s.sim_clock.step(12)
	_assert_true(puzzles.mark_solved(PZ), "first solve transitions")
	_assert_false(puzzles.mark_solved(PZ), "second solve is a no-op")
	_assert_eq(solved, [[PZ, 12]], "signal once, with tick")
	free_session(s)


func test_reset_clears_echo_and_tells_members_whether_solved() -> void:
	var s := make_session()
	var member := Member.new()
	s.add_child(member)
	s.puzzle_service.register_member(PZ, member)
	s.echo_service.start_recording()
	s.puzzle_service.reset_puzzle(PZ)
	_assert_eq(s.echo_service.state, EchoService.State.IDLE, "echo reset by puzzle reset")
	s.puzzle_service.mark_solved(PZ)
	s.puzzle_service.reset_puzzle(PZ)
	_assert_eq(member.calls, [[PZ, false], [PZ, true]], "members learn the solved state")
	_assert_true(s.puzzle_service.is_solved(PZ), "reset never un-solves (ADR-016)")
	free_session(s)


func test_export_import_never_downgrades_and_ignores_garbage() -> void:
	var s := make_session()
	s.puzzle_service.mark_solved(&"CH1-PZ-001")
	s.puzzle_service.register_puzzle(&"CH1-PZ-002")
	_assert_eq(s.puzzle_service.export_state(), {"CH1-PZ-001": "SOLVED", "CH1-PZ-002": "UNSOLVED"}, "export")
	s.puzzle_service.import_state({"CH1-PZ-001": "UNSOLVED", "CH1-PZ-003": "SOLVED", "CH1-PZ-004": "BANANA"})
	_assert_true(s.puzzle_service.is_solved(&"CH1-PZ-001"), "SOLVED not downgraded")
	_assert_true(s.puzzle_service.is_solved(&"CH1-PZ-003"), "imported SOLVED")
	_assert_eq(s.puzzle_service.get_state(&"CH1-PZ-004"), PuzzleService.UNSOLVED, "garbage ignored")
	free_session(s)


func test_completion_zone_solves_for_player_only() -> void:
	var s := make_session()
	var zone := PuzzleCompletionZone.new()
	zone.puzzle_id = PZ
	spawn(s, zone, &"ch01.test.exit_trigger")
	s.interaction_service.trigger_enter(&"echo.0", zone.object_id)
	_assert_false(s.puzzle_service.is_solved(PZ), "echo cannot solve")
	s.interaction_service.trigger_enter(&"player", zone.object_id)
	_assert_true(s.puzzle_service.is_solved(PZ), "player solves")
	free_session(s)


func test_reset_anchor_resets_its_puzzle_through_the_contract() -> void:
	var s := make_session()
	var member := Member.new()
	s.add_child(member)
	s.puzzle_service.register_member(PZ, member)
	var anchor := ResetAnchor.new()
	anchor.puzzle_id = PZ
	spawn(s, anchor, &"ch01.test.reset_anchor")
	_assert_true(s.interaction_service.request(&"player", anchor.object_id, &"reset").ok, "reset via 'reset'")
	_assert_true(s.interaction_service.request(&"player", anchor.object_id, &"use").ok, "reset via 'use'")
	_assert_eq(member.calls.size(), 2, "two resets")
	_assert_eq(s.interaction_service.request(&"player", anchor.object_id, &"rewind").reason, &"unsupported", "not temporal")
	free_session(s)


func test_watch_focus_hook_emits_once_per_change() -> void:
	var s := make_session()
	var target := spawn(s, Interactable.new(), &"ch01.test.focus")
	var seen: Array = []
	target.watch_focused_changed.connect(func(f, a): seen.append([f, a]))
	target.set_watch_focused(true, &"rewind")
	target.set_watch_focused(true, &"rewind")
	target.set_watch_focused(true, &"freeze")
	target.set_watch_focused(false)
	_assert_eq(seen, [[true, &"rewind"], [true, &"freeze"], [false, &""]], "deduplicated changes")
	free_session(s)
