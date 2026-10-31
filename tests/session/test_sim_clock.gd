extends RefCounted

## Automated tests for SimClock determinism per ADR-004 and TLF-007.

var assert_helper: RefCounted


func _assert_eq(actual, expected, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_eq(actual, expected, msg)
	assert(actual == expected, msg)
	return actual == expected


func _assert_true(cond: bool, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_true(cond, msg)
	assert(cond, msg)
	return cond


func test_sim_clock_step() -> void:
	var clock = SimClock.new()
	_assert_eq(clock.tick, 0, "Initial tick must be 0")

	clock.step(1)
	_assert_eq(clock.tick, 1, "After step(1), tick must be 1")

	clock.step(5)
	_assert_eq(clock.tick, 6, "After step(5), tick must be 6")

	clock.step(0)
	_assert_eq(clock.tick, 6, "Step with 0 must not change tick")

	clock.free()


func test_sim_clock_pause() -> void:
	var clock = SimClock.new()
	_assert_eq(clock.tick, 0, "Initial tick must be 0")

	# Physics process advancement while unpaused
	clock._physics_process(1.0 / 60.0)
	_assert_eq(clock.tick, 1, "Physics process must advance tick by 1 when unpaused")

	# Pause clock
	clock.is_paused = true
	clock._physics_process(1.0 / 60.0)
	_assert_eq(clock.tick, 1, "Physics process must not advance tick when paused")

	# Unpause
	clock.is_paused = false
	clock._physics_process(1.0 / 60.0)
	_assert_eq(clock.tick, 2, "Physics process must resume advancing tick when unpaused")

	clock.free()
