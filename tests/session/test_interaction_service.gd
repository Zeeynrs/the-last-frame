extends RefCounted

## Automated tests for InteractionService per ADR-006 and TLF-007.

var assert_helper: RefCounted

class MockInteractable extends Node:
	var object_id: StringName = &"ch01.mock_target"
	var progression: bool = false
	var interact_called: bool = false
	var interact_count: int = 0
	var can_interact_reason: StringName = &""

	func can_interact(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary = {}) -> StringName:
		return can_interact_reason

	func interact(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary = {}) -> void:
		interact_called = true
		interact_count += 1


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


func _assert_false(cond: bool, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_false(cond, msg)
	assert(not cond, msg)
	return not cond


func test_interaction_success_and_signal() -> void:
	var registry = IdRegistry.new()
	var clock = SimClock.new()
	var service = InteractionService.new()
	service.id_registry = registry
	service.sim_clock = clock

	clock.tick = 42

	var target = MockInteractable.new()
	registry.register(&"ch01.mock_target", target)

	var signal_captured = {}
	service.interaction_applied.connect(func(tick, actor_id, target_id, interaction_id, payload):
		signal_captured["tick"] = tick
		signal_captured["actor_id"] = actor_id
		signal_captured["target_id"] = target_id
		signal_captured["interaction_id"] = interaction_id
		signal_captured["payload"] = payload
	)

	var payload = {"key": "val"}
	var result = service.request(&"player", &"ch01.mock_target", &"use", payload)

	_assert_true(result.ok, "Request should succeed")
	_assert_eq(result.reason, &"", "Success reason should be empty")
	_assert_true(target.interact_called, "Target interact() must be called")
	_assert_eq(signal_captured.get("tick"), 42, "Signal must capture current tick")
	_assert_eq(signal_captured.get("actor_id"), &"player", "Signal must capture actor_id")
	_assert_eq(signal_captured.get("target_id"), &"ch01.mock_target", "Signal must capture target_id")
	_assert_eq(signal_captured.get("interaction_id"), &"use", "Signal must capture interaction_id")
	_assert_eq(signal_captured.get("payload"), payload, "Signal must capture payload")

	target.free()
	registry.free()
	clock.free()
	service.free()


func test_interaction_missing_target() -> void:
	var registry = IdRegistry.new()
	var clock = SimClock.new()
	var service = InteractionService.new()
	service.id_registry = registry
	service.sim_clock = clock

	var result = service.request(&"player", &"ch01.non_existent_target", &"use")
	_assert_false(result.ok, "Request on non-existent target should fail")
	_assert_eq(result.reason, &"missing_target", "Reason should be 'missing_target'")

	registry.free()
	clock.free()
	service.free()


func test_interaction_can_interact_rejection() -> void:
	var registry = IdRegistry.new()
	var clock = SimClock.new()
	var service = InteractionService.new()
	service.id_registry = registry
	service.sim_clock = clock

	var target = MockInteractable.new()
	target.can_interact_reason = &"frozen"
	registry.register(&"ch01.mock_target", target)

	var signal_emitted = false
	service.interaction_applied.connect(func(_t, _a, _tg, _i, _p): signal_emitted = true)

	var result = service.request(&"player", &"ch01.mock_target", &"use")
	_assert_false(result.ok, "Request on frozen target must fail")
	_assert_eq(result.reason, &"frozen", "Reason must pass through 'frozen'")
	_assert_false(target.interact_called, "interact() must not be called when can_interact returns reason")
	_assert_false(signal_emitted, "interaction_applied must not be emitted on rejection")

	target.free()
	registry.free()
	clock.free()
	service.free()


func test_interaction_echo_forbidden_on_progression() -> void:
	var registry = IdRegistry.new()
	var clock = SimClock.new()
	var service = InteractionService.new()
	service.id_registry = registry
	service.sim_clock = clock

	var target = MockInteractable.new()
	target.progression = true
	registry.register(&"ch01.mock_target", target)

	# 1. Echo actor attempting progression interaction -> &"echo_forbidden"
	var echo_result = service.request(&"echo.0", &"ch01.mock_target", &"use")
	_assert_false(echo_result.ok, "Echo interaction with progression=true must fail")
	_assert_eq(echo_result.reason, &"echo_forbidden", "Reason must be 'echo_forbidden'")
	_assert_false(target.interact_called, "interact() must not be called for forbidden echo")

	# 2. Player actor attempting same progression interaction -> succeeds
	var player_result = service.request(&"player", &"ch01.mock_target", &"use")
	_assert_true(player_result.ok, "Player interaction with progression=true must succeed")
	_assert_true(target.interact_called, "interact() must be called for player")

	target.free()
	registry.free()
	clock.free()
	service.free()


func test_trigger_signals() -> void:
	var clock = SimClock.new()
	var service = InteractionService.new()
	service.sim_clock = clock
	clock.tick = 100

	var enter_captured = {}
	var exit_captured = {}

	service.trigger_entered.connect(func(t, a, tr):
		enter_captured["tick"] = t
		enter_captured["actor"] = a
		enter_captured["trigger"] = tr
	)
	service.trigger_exited.connect(func(t, a, tr):
		exit_captured["tick"] = t
		exit_captured["actor"] = a
		exit_captured["trigger"] = tr
	)

	service.trigger_enter(&"player", &"ch01.door_sensor")
	_assert_eq(enter_captured.get("tick"), 100, "trigger_enter tick must match clock")
	_assert_eq(enter_captured.get("actor"), &"player", "trigger_enter actor must match")
	_assert_eq(enter_captured.get("trigger"), &"ch01.door_sensor", "trigger_enter trigger_id must match")

	clock.tick = 110
	service.trigger_exit(&"player", &"ch01.door_sensor")
	_assert_eq(exit_captured.get("tick"), 110, "trigger_exit tick must match clock")
	_assert_eq(exit_captured.get("actor"), &"player", "trigger_exit actor must match")
	_assert_eq(exit_captured.get("trigger"), &"ch01.door_sensor", "trigger_exit trigger_id must match")

	clock.free()
	service.free()
