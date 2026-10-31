extends "res://tests/support/base_test.gd"

## Self-tests of the frame-stepping runner (TLF-029). Each case drives a fixture through
## run_tests.gd's run_test() with a quiet helper, so expected failures stay out of the suite.


class Fixture extends "res://tests/support/base_test.gd":
	var seen_pressed: bool = false
	var left_node: WeakRef = null

	func case_async_pass() -> void:
		await physics_frames(3)
		_assert_true(true, "async pass")

	func case_async_fail() -> void:
		await physics_frames(2)
		_assert_eq(1, 2, "async failure")

	func case_never_finishes() -> void:
		await until(func() -> bool: return false, 1000000)
		# Only reached after the runner gave up: must not count and must not press input.
		_assert_true(false, "zombie assertion after timeout")
		press(&"interact")

	func case_presses_then_fails() -> void:
		press(&"interact")
		press(&"move_right")
		await physics_frames(2)
		seen_pressed = Input.is_action_pressed(&"interact") and Input.is_action_pressed(&"move_right")
		_assert_true(false, "fails while holding input")

	func case_sync_press_then_fail() -> void:
		press(&"interact")
		_assert_true(false, "fails before the press is flushed")

	func case_leaves_node_and_hangs() -> void:
		var node := Node.new()
		node.name = "LeftByTimedOutTest"
		_tree().root.add_child(node)
		left_node = weakref(node)
		await until(func() -> bool: return false, 1000000)


func _fixture() -> Fixture:
	var fixture := Fixture.new()
	fixture.scene_tree = _tree()
	return fixture


func _run(fixture: Fixture, method_name: String) -> Dictionary:
	var runner = _tree()
	var helper = runner.make_assert_helper()
	helper.set_context("fixture", method_name)
	fixture.assert_helper = helper
	var passed: bool = await runner.run_test(fixture, method_name, helper)
	return {"passed": passed, "failures": helper.failures}


func test_async_pass_steps_physics_frames() -> void:
	var start := Engine.get_physics_frames()
	var result := await _run(_fixture(), "case_async_pass")
	_assert_true(result["passed"], "awaited test passes")
	_assert_eq(result["failures"].size(), 0, "no failures recorded")
	_assert_true(Engine.get_physics_frames() - start >= 3, "physics frames really advanced")


func test_async_failure_is_reported() -> void:
	var result := await _run(_fixture(), "case_async_fail")
	_assert_false(result["passed"], "failure after an await is reported")
	_assert_eq(result["failures"].size(), 1, "exactly one failure")
	_assert_eq(result["failures"][0]["method"], "case_async_fail", "failure keeps its test context")


func test_async_timeout_fails_with_clear_message_and_detaches() -> void:
	var fixture := _fixture()
	fixture.timeout_frames = 10
	var start := Engine.get_physics_frames()
	var result := await _run(fixture, "case_never_finishes")
	_assert_false(result["passed"], "never-finishing test fails")
	_assert_eq(result["failures"].size(), 1, "one failure: the timeout")
	_assert_true(String(result["failures"][0]["message"]).begins_with("Timed out after 10 physics frames"),
		"clear timeout message")
	_assert_true(Engine.get_physics_frames() - start < 20, "gave up at the frame budget")
	await physics_frames(3)
	_assert_true(fixture.aborted, "fixture marked aborted")
	_assert_eq(result["failures"].size(), 1, "zombie assertion after timeout is discarded")
	_assert_false(Input.is_action_pressed(&"interact"), "zombie cannot press input")


func test_input_released_after_failing_async_test() -> void:
	var fixture := _fixture()
	var result := await _run(fixture, "case_presses_then_fails")
	_assert_false(result["passed"], "fixture failed")
	_assert_true(fixture.seen_pressed, "actions were really pressed during the test")
	_assert_false(Input.is_action_pressed(&"interact"), "interact released")
	_assert_false(Input.is_action_pressed(&"move_right"), "move_right released")
	await physics_frames(2)
	_assert_false(Input.is_action_pressed(&"interact"), "still released on later frames")


func test_input_released_when_sync_test_fails_before_flush() -> void:
	var result := await _run(_fixture(), "case_sync_press_then_fail")
	_assert_false(result["passed"], "fixture failed")
	await physics_frames(2)
	_assert_false(Input.is_action_pressed(&"interact"), "buffered press does not leak into later frames")


func test_nodes_left_by_timed_out_test_are_freed() -> void:
	var fixture := _fixture()
	fixture.timeout_frames = 5
	var result := await _run(fixture, "case_leaves_node_and_hangs")
	_assert_false(result["passed"], "fixture timed out")
	_assert_true(fixture.left_node != null and fixture.left_node.get_ref() == null,
		"node the test left under the root was freed")
