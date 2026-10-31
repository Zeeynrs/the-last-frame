extends RefCounted

## Automated tests for Player 8-direction isometric movement mapping per TLF-007.

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


func test_cardinal_movement_vectors() -> void:
	var v_up = Player.compute_movement_vector(Vector2(0, -1))
	var v_down = Player.compute_movement_vector(Vector2(0, 1))
	var v_left = Player.compute_movement_vector(Vector2(-1, 0))
	var v_right = Player.compute_movement_vector(Vector2(1, 0))

	_assert_eq(v_up, Vector2(0, -1), "Up movement vector must be (0, -1)")
	_assert_eq(v_down, Vector2(0, 1), "Down movement vector must be (0, 1)")
	_assert_eq(v_left, Vector2(-1, 0), "Left movement vector must be (-1, 0)")
	_assert_eq(v_right, Vector2(1, 0), "Right movement vector must be (1, 0)")


func test_diagonal_movement_vectors_2_to_1() -> void:
	# Down-Right (1, 1)
	var v_dr = Player.compute_movement_vector(Vector2(1, 1).normalized())
	var expected_dr = Vector2(2, 1).normalized()
	_assert_true((v_dr - expected_dr).length() < 0.001, "Down-Right diagonal must follow Vector2(2, 1).normalized()")
	_assert_true(abs(v_dr.x / v_dr.y - 2.0) < 0.001, "Down-Right diagonal must maintain 2:1 aspect ratio")
	_assert_true(abs(v_dr.length() - 1.0) < 0.001, "Down-Right diagonal vector must be normalized")

	# Down-Left (-1, 1)
	var v_dl = Player.compute_movement_vector(Vector2(-1, 1).normalized())
	var expected_dl = Vector2(-2, 1).normalized()
	_assert_true((v_dl - expected_dl).length() < 0.001, "Down-Left diagonal must follow Vector2(-2, 1).normalized()")
	_assert_true(abs(v_dl.x / v_dl.y - (-2.0)) < 0.001, "Down-Left diagonal must maintain 2:1 aspect ratio")

	# Up-Right (1, -1)
	var v_ur = Player.compute_movement_vector(Vector2(1, -1).normalized())
	var expected_ur = Vector2(2, -1).normalized()
	_assert_true((v_ur - expected_ur).length() < 0.001, "Up-Right diagonal must follow Vector2(2, -1).normalized()")
	_assert_true(abs(v_ur.x / v_ur.y - (-2.0)) < 0.001, "Up-Right diagonal must maintain 2:1 aspect ratio")

	# Up-Left (-1, -1)
	var v_ul = Player.compute_movement_vector(Vector2(-1, -1).normalized())
	var expected_ul = Vector2(-2, -1).normalized()
	_assert_true((v_ul - expected_ul).length() < 0.001, "Up-Left diagonal must follow Vector2(-2, -1).normalized()")
	_assert_true(abs(v_ul.x / v_ul.y - 2.0) < 0.001, "Up-Left diagonal must maintain 2:1 aspect ratio")


func test_zero_movement_on_no_input() -> void:
	var v_zero = Player.compute_movement_vector(Vector2.ZERO)
	_assert_eq(v_zero, Vector2.ZERO, "Zero input must produce zero movement vector")

	var v_deadzone = Player.compute_movement_vector(Vector2(0.1, 0.1))
	_assert_eq(v_deadzone, Vector2.ZERO, "Sub-deadzone input must produce zero movement vector")
