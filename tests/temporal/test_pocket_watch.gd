extends RefCounted

## Automated tests for PocketWatch ability cycling, ADR-015 targeting, and activation.

var assert_helper: RefCounted

class DummyWatchTarget extends Interactable:
	var caps: int = 0

	func _init(id: StringName, pos: Vector2, p_caps: int = 0, p_traceable: bool = false) -> void:
		object_id = id
		position = pos
		caps = p_caps
		traceable = p_traceable

	func supports_ability(ability_id: StringName) -> bool:
		if ability_id == &"trace":
			return traceable
		if ability_id == &"rewind":
			return (caps & TemporalComponent.Capability.REWIND) != 0
		if ability_id == &"freeze":
			return (caps & TemporalComponent.Capability.FREEZE) != 0
		if ability_id == &"fast_forward":
			return (caps & TemporalComponent.Capability.FAST_FORWARD) != 0
		return false


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


func test_ability_cycling_order_and_wraparound() -> void:
	var watch = PocketWatch.new()
	var abilities: Array[StringName] = [&"trace", &"rewind", &"freeze"]
	watch.unlocked_abilities = abilities
	watch._ready()

	_assert_eq(watch.selected_ability, &"trace", "Initial ability should be trace")

	# Forward cycle (ability_next)
	watch.next_ability()
	_assert_eq(watch.selected_ability, &"rewind", "Next after trace should be rewind")

	watch.next_ability()
	_assert_eq(watch.selected_ability, &"freeze", "Next after rewind should be freeze")

	watch.next_ability()
	_assert_eq(watch.selected_ability, &"trace", "Next after freeze should wrap around to trace")

	# Backward cycle (ability_prev)
	watch.prev_ability()
	_assert_eq(watch.selected_ability, &"freeze", "Prev from trace should wrap backward to freeze")

	watch.prev_ability()
	_assert_eq(watch.selected_ability, &"rewind", "Prev from freeze should be rewind")

	watch.prev_ability()
	_assert_eq(watch.selected_ability, &"trace", "Prev from rewind should be trace")

	watch.free()


func test_ability_cycling_skips_echo() -> void:
	var watch = PocketWatch.new()
	# Even if echo is present in unlocked_abilities, cycle skips it until TLF-016
	var abilities: Array[StringName] = [&"trace", &"rewind", &"freeze", &"echo"]
	watch.unlocked_abilities = abilities
	watch._ready()

	_assert_eq(watch.selected_ability, &"trace")
	watch.next_ability()
	_assert_eq(watch.selected_ability, &"rewind")
	watch.next_ability()
	_assert_eq(watch.selected_ability, &"freeze")
	watch.next_ability()
	_assert_eq(watch.selected_ability, &"trace", "Cycle must wrap around, skipping echo")

	watch.free()


func test_targeting_preference_for_supporting_object() -> void:
	var player_pos = Vector2(100, 100)

	# Shutter at (140, 100) -> distance = 40 px, supports REWIND
	var shutter = DummyWatchTarget.new(&"ch01.test.shutter", Vector2(140, 100), TemporalComponent.Capability.REWIND)
	# Gear at (170, 100) -> distance = 70 px, supports FREEZE
	var gear = DummyWatchTarget.new(&"ch01.test.gear", Vector2(170, 100), TemporalComponent.Capability.FREEZE)

	var candidates: Array = [shutter, gear]

	# When Freeze is selected, gear MUST be chosen despite shutter being closer (40 px vs 70 px)
	var freeze_target = PocketWatch.choose_watch_target(player_pos, candidates, &"freeze", 96.0)
	_assert_eq(freeze_target, gear, "Targeting with Freeze selected must prefer gear (supports FREEZE) over nearer shutter")

	# When Rewind is selected, shutter is chosen (supports REWIND)
	var rewind_target = PocketWatch.choose_watch_target(player_pos, candidates, &"rewind", 96.0)
	_assert_eq(rewind_target, shutter, "Targeting with Rewind selected must pick shutter")

	shutter.free()
	gear.free()


func test_targeting_fallback_to_nearest() -> void:
	var player_pos = Vector2(0, 0)
	# Neither object supports trace
	var close_obj = DummyWatchTarget.new(&"ch01.close", Vector2(30, 0), TemporalComponent.Capability.REWIND)
	var far_obj = DummyWatchTarget.new(&"ch01.far", Vector2(60, 0), TemporalComponent.Capability.FREEZE)

	var candidates: Array = [far_obj, close_obj]

	# When trace is selected and no candidates support trace, fallback to nearest overall
	var target = PocketWatch.choose_watch_target(player_pos, candidates, &"trace", 96.0)
	_assert_eq(target, close_obj, "Targeting fallback must pick nearest candidate overall for teachable feedback")

	close_obj.free()
	far_obj.free()


func test_targeting_tie_break_lexicographical() -> void:
	var player_pos = Vector2(0, 0)
	# Both at equal distance 50 px, both support REWIND
	var item_b = DummyWatchTarget.new(&"ch01.target_b", Vector2(50, 0), TemporalComponent.Capability.REWIND)
	var item_a = DummyWatchTarget.new(&"ch01.target_a", Vector2(-50, 0), TemporalComponent.Capability.REWIND)

	var candidates: Array = [item_b, item_a]
	var chosen = PocketWatch.choose_watch_target(player_pos, candidates, &"rewind", 96.0)
	_assert_eq(chosen, item_a, "Tie-break must pick lexicographically smaller ID 'ch01.target_a' over 'ch01.target_b'")

	item_b.free()
	item_a.free()


func test_targeting_out_of_range_rejected() -> void:
	var player_pos = Vector2(0, 0)
	var out_of_range = DummyWatchTarget.new(&"ch01.far_away", Vector2(120, 0), TemporalComponent.Capability.REWIND)

	var candidates: Array = [out_of_range]
	var chosen = PocketWatch.choose_watch_target(player_pos, candidates, &"rewind", 96.0)
	_assert_eq(chosen, null, "Candidate outside 96 px radius must not be chosen")

	out_of_range.free()


func test_watch_activation_request_and_signal() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	var session = GameSession.new()
	var registry = IdRegistry.new()
	registry.name = "IdRegistry"
	session.add_child(registry)
	session.id_registry = registry

	var sim_clock = SimClock.new()
	sim_clock.name = "SimClock"
	session.add_child(sim_clock)
	session.sim_clock = sim_clock

	var interaction_service = InteractionService.new()
	interaction_service.name = "InteractionService"
	interaction_service.id_registry = registry
	interaction_service.sim_clock = sim_clock
	session.add_child(interaction_service)
	session.interaction_service = interaction_service

	if tree != null and tree.root != null:
		tree.root.add_child(session)

	var target = DummyWatchTarget.new(&"ch01.target_node", Vector2(20, 0), TemporalComponent.Capability.FREEZE)
	session.add_child(target)
	registry.register(&"ch01.target_node", target)

	var watch = PocketWatch.new()
	watch.session = session
	var abilities: Array[StringName] = [&"freeze"]
	watch.unlocked_abilities = abilities
	watch.selected_ability = &"freeze"
	watch.current_target = target

	var events: Array[Dictionary] = []
	watch.watch_used.connect(func(ab, tid, res):
		events.append({"ability": ab, "target": tid, "result": res})
	)

	var res = watch.activate_watch()
	_assert_eq(events.size(), 1, "watch_used signal must be emitted")
	_assert_eq(events[0]["ability"], &"freeze", "Emitted ability must match selected ability")
	_assert_eq(events[0]["target"], &"ch01.target_node", "Emitted target ID must match")
	_assert_eq(watch.last_result, res, "watch.last_result must match activation result")

	watch.free()
	session.remove_child(target)
	target.free()
	if tree != null and tree.root != null and session.get_parent() == tree.root:
		tree.root.remove_child(session)
	session.free()


func test_trace_ability_on_traceable_object() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	var session = Node2D.new()
	if tree != null and tree.root != null:
		tree.root.add_child(session)

	var traceable_obj = Interactable.new()
	traceable_obj.name = "TraceableObj"
	traceable_obj.object_id = &"ch01.trace_locus"
	traceable_obj.traceable = true
	session.add_child(traceable_obj)

	var non_traceable_obj = Interactable.new()
	non_traceable_obj.name = "NonTraceableObj"
	non_traceable_obj.object_id = &"ch01.solid_wall"
	non_traceable_obj.traceable = false
	session.add_child(non_traceable_obj)

	# can_interact checks
	_assert_eq(traceable_obj.can_interact(&"player", &"trace"), &"", "Traceable object must allow &\"trace\"")
	_assert_eq(non_traceable_obj.can_interact(&"player", &"trace"), &"unsupported", "Non-traceable object must return &\"unsupported\"")

	# Interact emits traced signal
	var traced_events: Array[StringName] = []
	traceable_obj.traced.connect(func(id): traced_events.append(id))
	traceable_obj.interact(&"player", &"trace")
	_assert_eq(traced_events.size(), 1, "Traced event must be received")
	_assert_eq(traced_events[0], &"ch01.trace_locus", "interact(&\"trace\") must emit traced signal with object_id")

	session.remove_child(traceable_obj)
	traceable_obj.free()
	session.remove_child(non_traceable_obj)
	non_traceable_obj.free()
	if tree != null and tree.root != null and session.get_parent() == tree.root:
		tree.root.remove_child(session)
	session.free()
