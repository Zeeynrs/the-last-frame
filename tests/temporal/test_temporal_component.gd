extends RefCounted

## Automated tests for TemporalComponent per ADR-007 (Amendments 1 & 2).

var assert_helper: RefCounted

class DummyTemporalNode extends Node:
	var state: Dictionary = {}

	func _init(initial_state: Dictionary = {}) -> void:
		state = initial_state.duplicate(true)

	func capture_state() -> Dictionary:
		return state.duplicate(true)

	func apply_state(d: Dictionary) -> void:
		state = d.duplicate(true)


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


func test_initial_history_seeding_and_cursor() -> void:
	var node = DummyTemporalNode.new({"val": 20})
	var tc = TemporalComponent.new()
	tc.capabilities = TemporalComponent.Capability.REWIND
	tc.state_fields = ["val"]
	var h: Array[Dictionary] = [
		{"val": 5},
		{"val": 10}
	]
	tc.initial_history = h
	node.add_child(tc)
	tc._ready()

	_assert_eq(tc.get_history_cursor(), 2, "Cursor should point to tick-0 state at end of buffer")
	var history = tc.get_history()
	_assert_eq(history.size(), 3, "History should contain 2 pre-history entries plus 1 tick-0 entry")
	_assert_eq(history[0]["val"], 5, "Oldest entry should be val=5")
	_assert_eq(history[1]["val"], 10, "Middle entry should be val=10")
	_assert_eq(history[2]["val"], 20, "Latest entry should be val=20")

	node.remove_child(tc)
	tc.free()
	node.free()


func test_rewind_to_no_history_at_oldest_entry() -> void:
	var node = DummyTemporalNode.new({"val": 30})
	var tc = TemporalComponent.new()
	tc.capabilities = TemporalComponent.Capability.REWIND
	tc.state_fields = ["val"]
	var h: Array[Dictionary] = [{"val": 10}]
	tc.initial_history = h
	node.add_child(tc)
	tc._ready()

	# First rewind: moves from 30 -> 10
	var res1 = tc.rewind()
	_assert_eq(res1, &"", "First rewind should succeed")
	_assert_eq(node.state["val"], 10, "Node state should be restored to 10")
	_assert_eq(tc.get_history_cursor(), 0, "Cursor should now be at oldest entry 0")

	# Second rewind: already at oldest entry (cursor == 0) -> no_history
	var res2 = tc.rewind()
	_assert_eq(res2, &"no_history", "Rewinding past oldest entry must return &\"no_history\"")
	_assert_eq(node.state["val"], 10, "State must remain unchanged at 10")
	_assert_eq(tc.get_history_cursor(), 0, "Cursor must remain at 0")

	node.remove_child(tc)
	tc.free()
	node.free()


func test_commit_truncates_entries_after_cursor() -> void:
	var node = DummyTemporalNode.new({"val": 30})
	var tc = TemporalComponent.new()
	tc.capabilities = TemporalComponent.Capability.REWIND
	tc.state_fields = ["val"]
	var h: Array[Dictionary] = [{"val": 10}, {"val": 20}]
	tc.initial_history = h
	node.add_child(tc)
	tc._ready()
	# History: [10, 20, 30], cursor = 2

	# Rewind to 20 (cursor = 1)
	tc.rewind()
	_assert_eq(tc.get_history_cursor(), 1, "Cursor should be at 1 (val=20)")

	# Node undergoes a new discrete transition to 99 and commits
	node.state["val"] = 99
	var committed = tc.commit_history()
	_assert_true(committed, "Commit should succeed")

	# Entry 30 after cursor must be dropped; new history: [10, 20, 99], cursor = 2
	var history = tc.get_history()
	_assert_eq(history.size(), 3, "Future branch should be truncated and new snapshot appended")
	_assert_eq(tc.get_history_cursor(), 2, "Cursor should be on the new snapshot")
	_assert_eq(history[2]["val"], 99, "Latest entry should be 99")

	# Rewind steps to 20, not 30
	tc.rewind()
	_assert_eq(node.state["val"], 20, "Rewinding should restore 20")

	node.remove_child(tc)
	tc.free()
	node.free()


func test_counters_dont_commit() -> void:
	var node = DummyTemporalNode.new({"state": "raised", "hold_ticks": 180})
	var tc = TemporalComponent.new()
	tc.capabilities = TemporalComponent.Capability.REWIND
	tc.state_fields = ["state", "hold_ticks"]
	var h: Array[Dictionary] = []
	tc.initial_history = h
	node.add_child(tc)
	tc._ready()
	# History: [{"state": "raised", "hold_ticks": 180}], cursor = 0

	# Simulating per-tick countdown without calling commit_history
	node.state["hold_ticks"] = 179
	node.state["hold_ticks"] = 178
	node.state["hold_ticks"] = 100

	# History count remains 1
	_assert_eq(tc.get_history().size(), 1, "Per-tick counter updates must not commit history entries")

	# Now a discrete transition occurs (raised -> closed) and commits
	node.state["state"] = "closed"
	node.state["hold_ticks"] = 0
	tc.commit_history()

	# History has 2 entries: [raised180, closed0]
	_assert_eq(tc.get_history().size(), 2, "Discrete transition committed")
	_assert_eq(tc.get_history_cursor(), 1, "Cursor at closed")

	# Rewind restores the original snapshot including full hold_ticks=180
	tc.rewind()
	_assert_eq(node.state["state"], "raised", "State restored to raised")
	_assert_eq(node.state["hold_ticks"], 180, "hold_ticks restored to 180")

	node.remove_child(tc)
	tc.free()
	node.free()


func test_ring_capacity_eviction() -> void:
	var node = DummyTemporalNode.new({"val": 0})
	var tc = TemporalComponent.new()
	tc.capabilities = TemporalComponent.Capability.REWIND
	tc.state_fields = ["val"]
	var h: Array[Dictionary] = []
	tc.initial_history = h
	node.add_child(tc)
	tc._ready()

	# Commit 40 discrete transitions (exceeding CAPACITY = 32)
	for i in range(1, 41):
		node.state["val"] = i
		tc.commit_history()

	var history = tc.get_history()
	_assert_eq(history.size(), TemporalComponent.CAPACITY, "History size must not exceed capacity 32")
	_assert_eq(tc.get_history_cursor(), TemporalComponent.CAPACITY - 1, "Cursor must be at last index (31)")
	_assert_eq(history[history.size() - 1]["val"], 40, "Latest entry should be 40")
	# Oldest remaining entry should be 40 - 32 + 1 = 9
	_assert_eq(history[0]["val"], 9, "Oldest entry should be 9 after eviction")

	node.remove_child(tc)
	tc.free()
	node.free()


func test_freeze_toggle() -> void:
	var node = DummyTemporalNode.new({"val": 1})
	var tc = TemporalComponent.new()
	tc.capabilities = TemporalComponent.Capability.FREEZE
	tc.state_fields = ["val"]
	node.add_child(tc)
	tc._ready()

	_assert_false(tc.is_frozen, "Initial freeze state must be false")

	var res1 = tc.toggle_freeze()
	_assert_eq(res1, &"", "First toggle must succeed")
	_assert_true(tc.is_frozen, "Component should now be frozen")

	var res2 = tc.toggle_freeze()
	_assert_eq(res2, &"", "Second toggle must succeed")
	_assert_false(tc.is_frozen, "Component should now be unfrozen")

	node.remove_child(tc)
	tc.free()
	node.free()


func test_frozen_rejects_use_and_rewind() -> void:
	var node = DummyTemporalNode.new({"val": 1})
	var tc = TemporalComponent.new()
	tc.capabilities = TemporalComponent.Capability.REWIND | TemporalComponent.Capability.FREEZE
	tc.state_fields = ["val"]
	var h: Array[Dictionary] = [{"val": 0}]
	tc.initial_history = h
	node.add_child(tc)
	tc._ready()

	# Freeze component
	tc.is_frozen = true
	_assert_eq(tc.rewind(), &"frozen", "Rewind on frozen component must return &\"frozen\"")

	# Create interactable with temporal component
	var interactable = Interactable.new()
	interactable.name = "FrozenInteractable"
	interactable.object_id = &"ch01.test.frozen_target"
	var tc2 = TemporalComponent.new()
	tc2.capabilities = TemporalComponent.Capability.REWIND | TemporalComponent.Capability.FREEZE
	tc2.is_frozen = true
	interactable.add_child(tc2)

	_assert_eq(interactable.can_interact(&"player", &"use"), &"frozen", "Physical use on frozen interactable must return &\"frozen\"")
	_assert_eq(interactable.can_interact(&"player", &"rewind"), &"frozen", "Rewind on frozen interactable must return &\"frozen\"")

	# Unfreeze
	tc2.is_frozen = false
	_assert_eq(interactable.can_interact(&"player", &"use"), &"", "Physical use on unfrozen interactable must be allowed")

	interactable.remove_child(tc2)
	tc2.free()
	interactable.free()
	node.remove_child(tc)
	tc.free()
	node.free()


func test_unsupported_ability_returns_unsupported() -> void:
	var node = DummyTemporalNode.new({"val": 1})
	var tc = TemporalComponent.new()
	# Only REWIND declared, FREEZE is not
	tc.capabilities = TemporalComponent.Capability.REWIND
	tc.state_fields = ["val"]
	node.add_child(tc)
	tc._ready()

	var freeze_res = tc.toggle_freeze()
	_assert_eq(freeze_res, &"unsupported", "Calling freeze without capability must return &\"unsupported\"")
	_assert_false(tc.is_frozen, "is_frozen must remain false")

	node.remove_child(tc)
	tc.free()
	node.free()


func test_snapshot_field_validation() -> void:
	var tc = TemporalComponent.new()
	tc.state_fields = ["arm_state", "passage_blocked"]

	# Missing a field
	var invalid_snap1 = {"arm_state": &"open"}
	_assert_false(tc.validate_snapshot(invalid_snap1), "Snapshot missing field must fail validation")

	# Extra field
	var invalid_snap2 = {"arm_state": &"open", "passage_blocked": false, "extra": 123}
	_assert_false(tc.validate_snapshot(invalid_snap2), "Snapshot with extra field must fail validation")

	# Exact match
	var valid_snap = {"arm_state": &"open", "passage_blocked": false}
	_assert_true(tc.validate_snapshot(valid_snap), "Snapshot with exact fields must pass validation")

	tc.free()


func test_history_cursor_save_and_load() -> void:
	var node = DummyTemporalNode.new({"val": 30})
	var tc = TemporalComponent.new()
	tc.capabilities = TemporalComponent.Capability.REWIND
	tc.state_fields = ["val"]
	var h: Array[Dictionary] = [{"val": 10}, {"val": 20}]
	tc.initial_history = h
	node.add_child(tc)
	tc._ready()

	# Current cursor is 2 (val=30)
	_assert_eq(tc.get_history_cursor(), 2)

	# Simulate save/load restoring cursor to 1 (consumed pre-history)
	tc.set_history_cursor(1)
	_assert_eq(tc.get_history_cursor(), 1, "Cursor should be updated to 1")
	_assert_eq(node.state["val"], 20, "Node state should be restored to index 1 (val=20)")

	node.remove_child(tc)
	tc.free()
	node.free()
