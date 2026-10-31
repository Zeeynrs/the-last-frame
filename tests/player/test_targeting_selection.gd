extends "res://tests/support/base_test.gd"

## Unit tests for Player and PocketWatch target selection functions per TLF-043.
## Verifies non-targetable triggers/checkpoints are ignored, blocked-but-supported
## objects stay targetable, fallback pools exclude triggers, and ADR-006 tie-breaking holds.


class DummyTrigger extends TriggerZone:
	func _init(id: StringName, pos: Vector2 = Vector2.ZERO) -> void:
		object_id = id
		position = pos


class DummyCheckpoint extends CheckpointZone:
	func _init(id: StringName, pos: Vector2 = Vector2.ZERO) -> void:
		object_id = id
		position = pos


class DummyUsable extends Interactable:
	func _init(id: StringName, pos: Vector2 = Vector2.ZERO) -> void:
		object_id = id
		position = pos


class DummyBlockedUsable extends Interactable:
	var block_reason: StringName = &"unpowered"

	func _init(id: StringName, pos: Vector2 = Vector2.ZERO, reason: StringName = &"unpowered") -> void:
		object_id = id
		position = pos
		block_reason = reason

	func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
		return block_reason


class DummyWatchObject extends Interactable:
	var ability: StringName

	func _init(id: StringName, pos: Vector2, supp_ability: StringName) -> void:
		object_id = id
		position = pos
		ability = supp_ability

	func supports_ability(ability_id: StringName) -> bool:
		return ability_id == ability

	func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
		return &"unsupported"


func test_trigger_and_checkpoint_only_returns_null() -> void:
	var trigger = DummyTrigger.new(&"ch01.zone.trigger", Vector2(10, 0))
	var cp = DummyCheckpoint.new(&"ch01.zone.cp", Vector2(15, 0))
	var candidates: Array = [trigger, cp]

	var player_target = Player.choose_best_interactable(Vector2.ZERO, candidates)
	_assert_true(player_target == null, "Player target must be null when only triggers/checkpoints in candidates")

	var watch_target_trace = PocketWatch.choose_watch_target(Vector2.ZERO, candidates, &"trace")
	_assert_true(watch_target_trace == null, "PocketWatch trace target must be null when only triggers/checkpoints")

	var watch_target_freeze = PocketWatch.choose_watch_target(Vector2.ZERO, candidates, &"freeze")
	_assert_true(watch_target_freeze == null, "PocketWatch freeze target must be null when only triggers/checkpoints")

	trigger.free()
	cp.free()


func test_trigger_closer_than_usable_picks_usable() -> void:
	var trigger = DummyTrigger.new(&"ch01.near.trigger", Vector2(10, 0)) # dist = 10
	var usable = DummyUsable.new(&"ch01.far.usable", Vector2(25, 0))     # dist = 25
	var candidates: Array = [trigger, usable]

	var player_target = Player.choose_best_interactable(Vector2.ZERO, candidates)
	_assert_eq(player_target, usable, "Player must pick usable object over closer trigger")

	var watch_target = PocketWatch.choose_watch_target(Vector2.ZERO, candidates, &"trace")
	_assert_eq(watch_target, usable, "PocketWatch fallback pool must pick usable object over closer trigger")

	trigger.free()
	usable.free()


func test_blocked_but_supported_use_stays_targetable() -> void:
	var trigger = DummyTrigger.new(&"ch01.near.trigger", Vector2(10, 0))
	var unpowered_console = DummyBlockedUsable.new(&"ch01.console", Vector2(20, 0), &"unpowered")
	var candidates: Array = [trigger, unpowered_console]

	var player_target = Player.choose_best_interactable(Vector2.ZERO, candidates)
	_assert_eq(player_target, unpowered_console, "Blocked use (unpowered) must remain targetable for Player")

	var watch_target = PocketWatch.choose_watch_target(Vector2.ZERO, candidates, &"rewind")
	_assert_eq(watch_target, unpowered_console, "Blocked use (unpowered) must remain in fallback pool for PocketWatch")

	trigger.free()
	unpowered_console.free()


func test_fallback_pool_contains_no_trigger() -> void:
	# Neither object supports freeze; one is a trigger, one is a usable object
	var trigger = DummyTrigger.new(&"ch01.zone.trigger", Vector2(15, 0))
	var usable = DummyUsable.new(&"ch01.prop.item", Vector2(30, 0))
	var candidates: Array = [trigger, usable]

	var watch_target = PocketWatch.choose_watch_target(Vector2.ZERO, candidates, &"freeze", 96.0)
	_assert_eq(watch_target, usable, "PocketWatch fallback pool must contain usable item, NOT trigger")

	trigger.free()
	usable.free()


func test_adr006_tie_break_unchanged() -> void:
	var item_a = DummyUsable.new(&"ch01.apple", Vector2(20, 0))
	var item_b = DummyUsable.new(&"ch01.banana", Vector2(-20, 0))

	# Order 1: [banana, apple]
	var p_target_1 = Player.choose_best_interactable(Vector2.ZERO, [item_b, item_a])
	_assert_eq(p_target_1, item_a, "Player tie-break picks lexicographically smaller ID")
	var w_target_1 = PocketWatch.choose_watch_target(Vector2.ZERO, [item_b, item_a], &"trace")
	_assert_eq(w_target_1, item_a, "PocketWatch tie-break picks lexicographically smaller ID")

	# Order 2: [apple, banana]
	var p_target_2 = Player.choose_best_interactable(Vector2.ZERO, [item_a, item_b])
	_assert_eq(p_target_2, item_a, "Player tie-break order invariant")
	var w_target_2 = PocketWatch.choose_watch_target(Vector2.ZERO, [item_a, item_b], &"trace")
	_assert_eq(w_target_2, item_a, "PocketWatch tie-break order invariant")

	item_a.free()
	item_b.free()
