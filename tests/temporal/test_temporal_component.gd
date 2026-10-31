extends "res://tests/support/base_test.gd"

## Unit tests for TemporalComponent history, cursor and freeze semantics (ADR-007 + am.1/am.2).


class Probe extends Node:
	var phase: StringName = &"b"
	var counter: int = 0
	var advanced: int = 0

	func capture_state() -> Dictionary:
		return {"phase": phase, "counter": counter}

	func apply_state(state: Dictionary) -> void:
		phase = state["phase"]
		counter = state["counter"]

	func advance(ticks: int) -> void:
		advanced += ticks


func _probe(caps: int, history: Array = [{"phase": &"a", "counter": 9}], capacity: int = 32) -> Probe:
	var probe := Probe.new()
	var temporal := make_temporal(caps, ["phase", "counter"], history)
	temporal.history_capacity = capacity
	probe.add_child(temporal)
	_tree().root.add_child(probe)  # parent ready -> history seeded
	return probe


func _t(probe: Probe) -> TemporalComponent:
	return probe.get_child(0) as TemporalComponent


func _drop(probe: Probe) -> void:
	probe.get_parent().remove_child(probe)
	probe.free()


func test_initial_history_seeds_before_current_state() -> void:
	var probe := _probe(TemporalComponent.CAP_REWIND)
	_assert_eq(_t(probe).get_history_size(), 2, "initial_history + tick-0 state")
	_assert_eq(_t(probe).get_history_cursor(), 1, "cursor on current state")
	_assert_eq(_t(probe).get_history_entry(0), {"phase": &"a", "counter": 9}, "oldest entry is pre-arrival state")
	_drop(probe)


func test_rewind_steps_back_then_reports_no_history() -> void:
	var probe := _probe(TemporalComponent.CAP_REWIND)
	_assert_eq(_t(probe).rewind(), &"", "first rewind succeeds")
	_assert_eq(probe.phase, &"a", "pre-arrival phase applied")
	_assert_eq(probe.counter, 9, "counter restored from snapshot")
	_assert_eq(_t(probe).rewind(), &"no_history", "nothing older")
	_assert_eq(probe.phase, &"a", "state unchanged after no_history")
	_drop(probe)


func test_commit_after_rewind_truncates_future() -> void:
	var probe := _probe(TemporalComponent.CAP_REWIND)
	_t(probe).rewind()
	probe.phase = &"c"
	_assert_true(_t(probe).commit_history(), "commit ok")
	_assert_eq(_t(probe).get_history_size(), 2, "old future (b) dropped, c appended")
	_assert_eq(_t(probe).get_history_entry(1)["phase"], &"c", "newest entry is c")
	_t(probe).rewind()
	_assert_eq(probe.phase, &"a", "rewind from c returns to a, not b")
	_drop(probe)


func test_counter_changes_do_not_commit() -> void:
	var probe := _probe(TemporalComponent.CAP_REWIND, [])
	for i in range(50):
		probe.counter += 1
	_assert_eq(_t(probe).get_history_size(), 1, "counters alone never commit")
	_drop(probe)


func test_ring_capacity_evicts_oldest() -> void:
	var probe := _probe(TemporalComponent.CAP_REWIND, [], 3)
	for p in [&"c", &"d", &"e"]:
		probe.phase = p
		_t(probe).commit_history()
	_assert_eq(_t(probe).get_history_size(), 3, "capped at capacity")
	_assert_eq(_t(probe).get_history_entry(0)["phase"], &"c", "oldest entries evicted")
	_assert_eq(_t(probe).get_history_cursor(), 2, "cursor still on newest")
	_drop(probe)


func test_freeze_is_a_toggle_and_blocks_rewind() -> void:
	var probe := _probe(TemporalComponent.CAP_REWIND | TemporalComponent.CAP_FREEZE)
	_assert_eq(_t(probe).toggle_freeze(), &"", "freeze ok")
	_assert_true(_t(probe).is_frozen, "frozen")
	_assert_eq(_t(probe).rewind(), &"frozen", "frozen blocks rewind")
	_t(probe).toggle_freeze()
	_assert_false(_t(probe).is_frozen, "second freeze unfreezes")
	_assert_eq(_t(probe).rewind(), &"", "rewind works again")
	_drop(probe)


func test_missing_capabilities_are_unsupported() -> void:
	var probe := _probe(0)
	_assert_eq(_t(probe).rewind(), &"unsupported", "no REWIND")
	_assert_eq(_t(probe).toggle_freeze(), &"unsupported", "no FREEZE")
	_assert_eq(_t(probe).fast_forward(), &"unsupported", "no FAST_FORWARD")
	_assert_eq(probe.phase, &"b", "state untouched")
	_drop(probe)


func test_fast_forward_calls_parent_advance() -> void:
	var probe := _probe(TemporalComponent.CAP_FAST_FORWARD)
	_assert_eq(_t(probe).fast_forward(), &"", "fast forward ok")
	_assert_eq(probe.advanced, _t(probe).fast_forward_ticks, "advance(fast_forward_ticks) called")
	_drop(probe)


func test_invalid_snapshot_is_rejected() -> void:
	var probe := _probe(TemporalComponent.CAP_REWIND, [])
	_t(probe).state_fields = PackedStringArray(["phase"])  # capture now returns an extra key
	_assert_false(_t(probe).commit_history(), "mismatched keys rejected")
	_assert_eq(_t(probe).get_history_size(), 1, "history unchanged")
	_drop(probe)


func test_export_import_round_trip() -> void:
	var probe := _probe(TemporalComponent.CAP_REWIND | TemporalComponent.CAP_FREEZE)
	_t(probe).rewind()
	_t(probe).toggle_freeze()
	var saved := _t(probe).export_history()
	_drop(probe)
	var restored := _probe(TemporalComponent.CAP_REWIND | TemporalComponent.CAP_FREEZE)
	_assert_true(_t(restored).import_history(saved), "import ok")
	_assert_eq(_t(restored).get_history_cursor(), 0, "cursor restored, consumed pre-history stays consumed")
	_assert_eq(restored.phase, &"a", "state at cursor applied")
	_assert_true(_t(restored).is_frozen, "freeze flag restored")
	_drop(restored)


func test_reset_to_initial_restores_tick0_and_history() -> void:
	var probe := _probe(TemporalComponent.CAP_REWIND | TemporalComponent.CAP_FREEZE)
	_t(probe).rewind()
	_t(probe).toggle_freeze()
	_t(probe).reset_to_initial()
	_assert_eq(probe.phase, &"b", "tick-0 state")
	_assert_false(_t(probe).is_frozen, "unfrozen")
	_assert_eq(_t(probe).get_history_cursor(), 1, "pre-history available again")
	_drop(probe)


func test_sim_clock_step_emits_every_tick() -> void:
	var clock := SimClock.new()
	var seen: Array = []
	clock.tick_advanced.connect(func(t): seen.append(t))
	clock.step(4)
	_assert_eq(seen, [1, 2, 3, 4], "one emission per tick, so step(N) == N x step(1)")
	clock.free()
