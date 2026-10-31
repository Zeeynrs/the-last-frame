extends RefCounted

## Automated reproduction of spec tests TEST-PZ001-01..04 and TEST-PZ002-01..03, 05 per TLF-008.

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


func _assert_false(cond: bool, msg: String = "") -> bool:
	if assert_helper != null:
		return assert_helper.assert_false(cond, msg)
	assert(not cond, msg)
	return not cond


func _create_test_session() -> Dictionary:
	var tree = Engine.get_main_loop() as SceneTree
	var session = GameSession.new()
	var registry = IdRegistry.new()
	registry.name = "IdRegistry"
	session.add_child(registry)
	session.id_registry = registry

	var clock = SimClock.new()
	clock.name = "SimClock"
	session.add_child(clock)
	session.sim_clock = clock

	var interaction = InteractionService.new()
	interaction.name = "InteractionService"
	interaction.id_registry = registry
	interaction.sim_clock = clock
	session.add_child(interaction)
	session.interaction_service = interaction

	if tree != null and tree.root != null:
		tree.root.add_child(session)

	return {
		"session": session,
		"registry": registry,
		"clock": clock,
		"interaction": interaction,
		"tree": tree,
	}


func _free_test_session(env: Dictionary) -> void:
	var tree = env.get("tree") as SceneTree
	var session = env["session"] as GameSession
	if tree != null and tree.root != null and session.get_parent() == tree.root:
		tree.root.remove_child(session)
	session.free()


func test_spec_pz001_01_physical_interaction_on_collapsed_gate_jammed() -> void:
	var env = _create_test_session()
	var gate = TestGate.new()
	gate.name = "TestGate"
	gate.object_id = &"ch01.test.gate"
	gate.session = env["session"]
	env["session"].add_child(gate)
	gate._ready()

	# GIVEN gate is in arm_state == &"collapsed" and passage_blocked == true
	_assert_eq(gate.arm_state, &"collapsed")
	_assert_true(gate.passage_blocked)

	# WHEN physical use is requested
	var result = env["interaction"].request(&"player", &"ch01.test.gate", &"use")

	# THEN result is rejected with reason == &"jammed" and passage remains blocked
	_assert_false(result.ok, "Physical use on collapsed gate must fail")
	_assert_eq(result.reason, &"jammed", "Failure reason must be &\"jammed\"")
	_assert_true(gate.passage_blocked, "Passage must remain blocked")

	env["session"].remove_child(gate)
	gate.free()
	_free_test_session(env)


func test_spec_pz001_02_unsupported_ability_on_static_pillar() -> void:
	var env = _create_test_session()
	var pillar = TestPillar.new()
	pillar.name = "TestPillar"
	pillar.object_id = &"ch01.test.pillar"
	pillar.session = env["session"]
	env["session"].add_child(pillar)
	pillar._ready()

	# GIVEN static pillar with no temporal component
	# WHEN rewind ability is requested
	var result = env["interaction"].request(&"player", &"ch01.test.pillar", &"rewind")

	# THEN result has ok == false and reason == &"unsupported"
	_assert_false(result.ok, "Rewind on static pillar must fail")
	_assert_eq(result.reason, &"unsupported", "Reason must be &\"unsupported\"")

	env["session"].remove_child(pillar)
	pillar.free()
	_free_test_session(env)


func test_spec_pz001_03_rewind_turnstile_restores_initial_history() -> void:
	var env = _create_test_session()
	var gate = TestGate.new()
	gate.name = "TestGate"
	gate.object_id = &"ch01.test.gate"
	gate.session = env["session"]
	env["session"].add_child(gate)
	gate._ready()

	# GIVEN gate at tick = 10 with initial_history [{"arm_state": &"open", "passage_blocked": false}]
	env["clock"].step(10)
	var signal_ticks: Array[int] = []
	env["interaction"].interaction_applied.connect(func(tick, _actor, _target, _id, _payload):
		signal_ticks.append(tick)
	)

	# WHEN rewind is requested
	var result = env["interaction"].request(&"player", &"ch01.test.gate", &"rewind")

	# THEN result has ok == true, state restored to open, and interaction_applied emitted at tick 10
	_assert_true(result.ok, "Rewind request must succeed")
	_assert_eq(gate.arm_state, &"open", "Gate arm_state should be restored to open")
	_assert_false(gate.passage_blocked, "Passage must no longer be blocked")
	_assert_eq(gate.capture_state(), {"arm_state": &"open", "passage_blocked": false})
	_assert_eq(signal_ticks.size(), 1, "interaction_applied must be emitted once")
	_assert_eq(signal_ticks[0], 10, "interaction_applied must be emitted with current tick 10")

	env["session"].remove_child(gate)
	gate.free()
	_free_test_session(env)


func test_spec_pz001_04_rewind_open_turnstile_at_oldest_returns_no_history() -> void:
	var env = _create_test_session()
	var gate = TestGate.new()
	gate.name = "TestGate"
	gate.object_id = &"ch01.test.gate"
	gate.session = env["session"]
	env["session"].add_child(gate)
	gate._ready()

	# GIVEN gate has already been rewound to open (cursor at oldest entry 0)
	var res1 = env["interaction"].request(&"player", &"ch01.test.gate", &"rewind")
	_assert_true(res1.ok)
	_assert_eq(gate.arm_state, &"open")

	# WHEN rewind is requested a second time
	var res2 = env["interaction"].request(&"player", &"ch01.test.gate", &"rewind")

	# THEN result has ok == false and reason == &"no_history", arm_state remains open
	_assert_false(res2.ok, "Second rewind must fail")
	_assert_eq(res2.reason, &"no_history", "Reason must be &\"no_history\"")
	_assert_eq(gate.arm_state, &"open", "State must remain open")

	env["session"].remove_child(gate)
	gate.free()
	_free_test_session(env)


func test_spec_pz002_01_rewind_shutter_countdown_and_slip_closed() -> void:
	var env = _create_test_session()

	var gear = TestGear.new()
	gear.name = "TestGear"
	gear.object_id = &"ch01.test.gear"
	gear.session = env["session"]
	env["session"].add_child(gear)
	gear._ready()

	var shutter = TestShutter.new()
	shutter.name = "TestShutter"
	shutter.object_id = &"ch01.test.shutter"
	shutter.session = env["session"]
	shutter.gear = gear
	env["session"].add_child(shutter)
	shutter._ready()

	# GIVEN shutter closed and gear not frozen at tick 0
	_assert_eq(shutter.shutter_state, &"closed")
	_assert_false(gear.is_gear_frozen())

	# WHEN shutter is rewound to raised
	var rew_res = env["interaction"].request(&"player", &"ch01.test.shutter", &"rewind")
	_assert_true(rew_res.ok, "Rewinding shutter must succeed")
	_assert_eq(shutter.shutter_state, &"raised")
	_assert_eq(shutter.hold_ticks, 180)

	# AND clock steps 179 ticks
	env["clock"].step(179)
	# THEN at tick 179: shutter remains raised with hold_ticks == 1
	_assert_eq(shutter.shutter_state, &"raised")
	_assert_eq(shutter.hold_ticks, 1)

	# AND clock steps 1 tick (tick = 180)
	env["clock"].step(1)
	# THEN shutter slips shut: shutter_state == &"closed" and passage_blocked == true
	_assert_eq(shutter.shutter_state, &"closed")
	_assert_eq(shutter.hold_ticks, 0)
	_assert_true(shutter.passage_blocked)

	env["session"].remove_child(shutter)
	shutter.free()
	env["session"].remove_child(gear)
	gear.free()
	_free_test_session(env)


func test_spec_pz002_02_freezing_gear_halts_shutter_countdown() -> void:
	var env = _create_test_session()

	var gear = TestGear.new()
	gear.name = "TestGear"
	gear.object_id = &"ch01.test.gear"
	gear.session = env["session"]
	env["session"].add_child(gear)
	gear._ready()

	var shutter = TestShutter.new()
	shutter.name = "TestShutter"
	shutter.object_id = &"ch01.test.shutter"
	shutter.session = env["session"]
	shutter.gear = gear
	env["session"].add_child(shutter)
	shutter._ready()

	# GIVEN shutter was rewound at tick 0 and clock advanced 60 ticks (hold_ticks == 120)
	env["interaction"].request(&"player", &"ch01.test.shutter", &"rewind")
	env["clock"].step(60)
	_assert_eq(shutter.shutter_state, &"raised")
	_assert_eq(shutter.hold_ticks, 120)

	# WHEN gear is frozen
	var freeze_res = env["interaction"].request(&"player", &"ch01.test.gear", &"freeze")
	_assert_true(freeze_res.ok, "Freezing gear must succeed")
	_assert_true(gear.is_gear_frozen())

	# AND clock advances 300 ticks (tick = 360)
	env["clock"].step(300)

	# THEN countdown is halted: hold_ticks remains 120, shutter remains raised and unblocked
	_assert_true(gear.is_gear_frozen())
	_assert_eq(shutter.shutter_state, &"raised")
	_assert_eq(shutter.hold_ticks, 120, "Countdown must remain halted at 120 ticks")
	_assert_false(shutter.passage_blocked, "Passage must remain open")

	env["session"].remove_child(shutter)
	shutter.free()
	env["session"].remove_child(gear)
	gear.free()
	_free_test_session(env)


func test_spec_pz002_03_frozen_gear_prevents_shutter_rewind() -> void:
	var env = _create_test_session()

	var gear = TestGear.new()
	gear.name = "TestGear"
	gear.object_id = &"ch01.test.gear"
	gear.session = env["session"]
	env["session"].add_child(gear)
	gear._ready()

	var shutter = TestShutter.new()
	shutter.name = "TestShutter"
	shutter.object_id = &"ch01.test.shutter"
	shutter.session = env["session"]
	shutter.gear = gear
	env["session"].add_child(shutter)
	shutter._ready()

	# GIVEN shutter is closed
	_assert_eq(shutter.shutter_state, &"closed")

	# WHEN gear is frozen before shutter rewind
	var freeze_res = env["interaction"].request(&"player", &"ch01.test.gear", &"freeze")
	_assert_true(freeze_res.ok)
	_assert_true(gear.is_gear_frozen())

	# AND rewind is requested on shutter
	var rew_res = env["interaction"].request(&"player", &"ch01.test.shutter", &"rewind")

	# THEN rewind request returns ok == false and reason == &"frozen", shutter remains closed
	_assert_false(rew_res.ok, "Rewind on shutter with frozen spindle must fail")
	_assert_eq(rew_res.reason, &"frozen", "Reason must be &\"frozen\"")
	_assert_eq(shutter.shutter_state, &"closed", "Shutter must remain closed")

	env["session"].remove_child(shutter)
	shutter.free()
	env["session"].remove_child(gear)
	gear.free()
	_free_test_session(env)


func test_spec_pz002_05_shutter_rewind_again_after_slipping_without_reset() -> void:
	var env = _create_test_session()

	var gear = TestGear.new()
	gear.name = "TestGear"
	gear.object_id = &"ch01.test.gear"
	gear.session = env["session"]
	env["session"].add_child(gear)
	gear._ready()

	var shutter = TestShutter.new()
	shutter.name = "TestShutter"
	shutter.object_id = &"ch01.test.shutter"
	shutter.session = env["session"]
	shutter.gear = gear
	env["session"].add_child(shutter)
	shutter._ready()

	# GIVEN shutter was rewound at tick 0 and allowed to slip back to closed at tick 180
	env["interaction"].request(&"player", &"ch01.test.shutter", &"rewind")
	env["clock"].step(180)
	_assert_eq(shutter.shutter_state, &"closed")

	# AND clock advances to tick 190
	env["clock"].step(10)

	# WHEN rewind is called again on shutter
	var rew2 = env["interaction"].request(&"player", &"ch01.test.shutter", &"rewind")

	# THEN rewind succeeds, restoring raised state with hold_ticks = 180
	_assert_true(rew2.ok, "Second rewind after natural slip must succeed")
	_assert_eq(shutter.shutter_state, &"raised", "State must be raised again")
	_assert_eq(shutter.hold_ticks, 180, "hold_ticks must be restored to 180")
	_assert_false(shutter.passage_blocked, "Passage must be unblocked")

	env["session"].remove_child(shutter)
	shutter.free()
	env["session"].remove_child(gear)
	gear.free()
	_free_test_session(env)


func test_determinism_step_1_vs_step_n() -> void:
	# CASE A: advancing 60 ticks one by one via step(1)
	var env_a = _create_test_session()
	var shutter_a = TestShutter.new()
	shutter_a.object_id = &"ch01.test.shutter_a"
	shutter_a.session = env_a["session"]
	env_a["session"].add_child(shutter_a)
	shutter_a._ready()
	shutter_a.get_temporal_component().rewind()  # Raised with 180 ticks

	for i in range(60):
		env_a["clock"].step(1)

	var ticks_a = shutter_a.hold_ticks
	var state_a = shutter_a.shutter_state
	var blocked_a = shutter_a.passage_blocked

	# CASE B: advancing 60 ticks in a single step(60)
	var env_b = _create_test_session()
	var shutter_b = TestShutter.new()
	shutter_b.object_id = &"ch01.test.shutter_b"
	shutter_b.session = env_b["session"]
	env_b["session"].add_child(shutter_b)
	shutter_b._ready()
	shutter_b.get_temporal_component().rewind()

	env_b["clock"].step(60)

	var ticks_b = shutter_b.hold_ticks
	var state_b = shutter_b.shutter_state
	var blocked_b = shutter_b.passage_blocked

	# THEN outcomes at tick 60 are identical
	_assert_eq(ticks_a, ticks_b, "hold_ticks must be identical: step(1)x60 vs step(60)")
	_assert_eq(state_a, state_b, "shutter_state must be identical")
	_assert_eq(blocked_a, blocked_b, "passage_blocked must be identical")
	_assert_eq(ticks_a, 120, "hold_ticks should be 120")

	# Full countdown to expiration: Case A step(1)x120 vs Case B step(120)
	for i in range(120):
		env_a["clock"].step(1)
	env_b["clock"].step(120)

	_assert_eq(shutter_a.shutter_state, &"closed", "Case A must be closed")
	_assert_eq(shutter_b.shutter_state, &"closed", "Case B must be closed")
	_assert_eq(shutter_a.hold_ticks, shutter_b.hold_ticks, "Hold ticks must be identical (0)")
	_assert_eq(shutter_a.passage_blocked, shutter_b.passage_blocked, "Passage blocked must be identical (true)")

	env_a["session"].remove_child(shutter_a)
	shutter_a.free()
	_free_test_session(env_a)

	env_b["session"].remove_child(shutter_b)
	shutter_b.free()
	_free_test_session(env_b)
