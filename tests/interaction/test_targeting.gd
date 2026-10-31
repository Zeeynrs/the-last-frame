extends RefCounted

## Automated tests for Player interaction targeting and deterministic tie-breaking per TLF-007.

var assert_helper: RefCounted

class DummyInteractable extends Interactable:
	func _init(id: StringName, pos: Vector2) -> void:
		object_id = id
		position = pos


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


func test_targeting_nearest_interactable() -> void:
	var player_pos = Vector2(100, 100)
	var close_target = DummyInteractable.new(&"ch01.close", Vector2(110, 100)) # dist = 10
	var far_target = DummyInteractable.new(&"ch01.far", Vector2(140, 100))    # dist = 40

	var candidates: Array = [far_target, close_target]
	var best = Player.choose_best_interactable(player_pos, candidates)

	_assert_eq(best, close_target, "Closest interactable should be chosen")

	close_target.free()
	far_target.free()


func test_targeting_tie_break_lexicographical() -> void:
	var player_pos = Vector2(0, 0)
	# Both at equal distance of 20 px from player
	var lever_a = DummyInteractable.new(&"ch01.lever_a", Vector2(20, 0))
	var lever_b = DummyInteractable.new(&"ch01.lever_b", Vector2(-20, 0))

	# Test order 1: [lever_b, lever_a]
	var candidates_1: Array = [lever_b, lever_a]
	var chosen_1 = Player.choose_best_interactable(player_pos, candidates_1)
	_assert_eq(chosen_1, lever_a, "Tie-break must pick lexicographically smaller ID 'ch01.lever_a' over 'ch01.lever_b'")

	# Test order 2: [lever_a, lever_b]
	var candidates_2: Array = [lever_a, lever_b]
	var chosen_2 = Player.choose_best_interactable(player_pos, candidates_2)
	_assert_eq(chosen_2, lever_a, "Tie-break must be invariant to candidate array ordering")

	lever_a.free()
	lever_b.free()
