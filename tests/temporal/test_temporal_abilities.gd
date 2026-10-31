extends "res://tests/support/base_test.gd"

## Pocket-watch abilities through the ADR-006 contract, reproducing the CH1-PZ-001/002 spec tests
## (design/ch01/puzzles) against greybox stand-ins. IDs differ; behaviour must be identical.

const GATE := &"ch01.test.gate"
const PILLAR := &"ch01.test.pillar"
const SHUTTER := &"ch01.test.shutter"
const GEAR := &"ch01.test.gear"


func _gate(session: GameSession) -> TemporalTestGate:
	var temporal := make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
		[{"arm_state": &"open", "passage_blocked": false}])
	return spawn(session, TemporalTestGate.new(), GATE, temporal) as TemporalTestGate


func _shutter_rig(session: GameSession) -> Array:
	var gear := spawn(session, TemporalTestGear.new(), GEAR, make_temporal(TemporalComponent.CAP_FREEZE, [])) as TemporalTestGear
	var shutter_node := TemporalTestShutter.new()
	shutter_node.gear_id = GEAR
	var temporal := make_temporal(TemporalComponent.CAP_REWIND, ["shutter_state", "hold_ticks", "passage_blocked"],
		[{"shutter_state": &"raised", "hold_ticks": 180, "passage_blocked": false}])
	var shutter := spawn(session, shutter_node, SHUTTER, temporal) as TemporalTestShutter
	return [shutter, gear]


func _req(session: GameSession, target: StringName, interaction: StringName) -> InteractionResult:
	return session.interaction_service.request(&"player", target, interaction)


# --- CH1-PZ-001 -----------------------------------------------------------------

func test_pz001_01_use_on_collapsed_gate_is_jammed() -> void:
	var s := make_session()
	var gate := _gate(s)
	var r := _req(s, GATE, &"use")
	_assert_false(r.ok, "use fails")
	_assert_eq(r.reason, &"jammed", "reason jammed")
	_assert_true(gate.passage_blocked, "still blocked")
	free_session(s)


func test_pz001_02_static_pillar_rejects_every_ability() -> void:
	var s := make_session()
	spawn(s, Interactable.new(), PILLAR)
	for ability in [&"rewind", &"freeze", &"trace", &"fast_forward"]:
		_assert_eq(_req(s, PILLAR, ability).reason, &"unsupported", "pillar %s -> unsupported" % ability)
	free_session(s)


func test_pz001_03_rewind_restores_pre_arrival_open_state_and_signals_tick() -> void:
	var s := make_session()
	var gate := _gate(s)
	s.sim_clock.step(10)
	var applied := {}
	# Lambdas capture locals by value: mutate the dictionary instead of reassigning it.
	s.interaction_service.interaction_applied.connect(func(tick, _a, _t, iid, _p): applied.merge({"tick": tick, "iid": iid}, true))
	var r := _req(s, GATE, &"rewind")
	_assert_true(r.ok, "rewind ok")
	_assert_eq(gate.capture_state(), {"arm_state": &"open", "passage_blocked": false}, "open restored")
	_assert_eq(applied, {"tick": 10, "iid": &"rewind"}, "interaction_applied at tick 10")
	free_session(s)


func test_pz001_04_second_rewind_reports_no_history() -> void:
	var s := make_session()
	var gate := _gate(s)
	_req(s, GATE, &"rewind")
	var r := _req(s, GATE, &"rewind")
	_assert_eq(r.reason, &"no_history", "oldest entry reached")
	_assert_eq(gate.arm_state, &"open", "stays open")
	free_session(s)


# --- CH1-PZ-002 -----------------------------------------------------------------

func test_pz002_01_rewound_shutter_holds_180_ticks_then_closes() -> void:
	var s := make_session()
	var shutter: TemporalTestShutter = _shutter_rig(s)[0]
	_assert_true(_req(s, SHUTTER, &"rewind").ok, "rewind ok")
	s.sim_clock.step(179)
	_assert_eq(shutter.shutter_state, &"raised", "raised at tick 179")
	_assert_eq(shutter.hold_ticks, 1, "1 tick left")
	s.sim_clock.step(1)
	_assert_eq(shutter.shutter_state, &"closed", "closed at tick 180")
	_assert_true(shutter.passage_blocked, "blocked again")
	free_session(s)


func test_pz002_02_freezing_gear_halts_countdown() -> void:
	var s := make_session()
	var shutter: TemporalTestShutter = _shutter_rig(s)[0]
	_req(s, SHUTTER, &"rewind")
	s.sim_clock.step(60)
	_assert_true(_req(s, GEAR, &"freeze").ok, "freeze gear ok")
	s.sim_clock.step(300)
	_assert_eq(shutter.shutter_state, &"raised", "still raised")
	_assert_eq(shutter.hold_ticks, 120, "countdown halted at 120")
	_assert_false(shutter.passage_blocked, "passable")
	free_session(s)


func test_pz002_03_frozen_gear_blocks_shutter_rewind() -> void:
	var s := make_session()
	var shutter: TemporalTestShutter = _shutter_rig(s)[0]
	_req(s, GEAR, &"freeze")
	var r := _req(s, SHUTTER, &"rewind")
	_assert_eq(r.reason, &"frozen", "cross-object frozen rule")
	_assert_eq(shutter.shutter_state, &"closed", "unchanged")
	free_session(s)


func test_pz002_05_shutter_can_be_rewound_again_after_slipping() -> void:
	var s := make_session()
	var shutter: TemporalTestShutter = _shutter_rig(s)[0]
	_req(s, SHUTTER, &"rewind")
	s.sim_clock.step(190)
	_assert_eq(shutter.shutter_state, &"closed", "slipped shut")
	var r := _req(s, SHUTTER, &"rewind")
	_assert_true(r.ok, "rewind again without reset")
	_assert_eq(shutter.shutter_state, &"raised", "raised")
	_assert_eq(shutter.hold_ticks, 180, "full hold restored")
	free_session(s)


func test_wrong_ability_on_coupled_objects_is_unsupported() -> void:
	var s := make_session()
	_shutter_rig(s)
	_assert_eq(_req(s, SHUTTER, &"freeze").reason, &"unsupported", "shutter cannot be frozen")
	_assert_eq(_req(s, GEAR, &"rewind").reason, &"unsupported", "gear cannot be rewound")
	free_session(s)


# --- Shared behaviour ------------------------------------------------------------

func test_frozen_object_rejects_use_until_unfrozen() -> void:
	var s := make_session()
	var lever := spawn(s, Interactable.new(), &"ch01.test.frozen_lever", make_temporal(TemporalComponent.CAP_FREEZE, []))
	_req(s, lever.object_id, &"freeze")
	_assert_eq(_req(s, lever.object_id, &"use").reason, &"frozen", "frozen rejects use")
	_req(s, lever.object_id, &"freeze")
	_assert_true(_req(s, lever.object_id, &"use").ok, "unfrozen accepts use")
	free_session(s)


func test_trace_on_traceable_object_emits_traced() -> void:
	var s := make_session()
	var anchor := Interactable.new()
	anchor.traceable = true
	spawn(s, anchor, &"ch01.test.trace_anchor")
	var traced_ids: Array = []
	anchor.traced.connect(func(id): traced_ids.append(id))
	_assert_true(anchor.supports_ability(&"trace"), "supports trace")
	_assert_false(anchor.supports_ability(&"rewind"), "no temporal component")
	_assert_true(_req(s, anchor.object_id, &"trace").ok, "trace ok")
	_assert_eq(traced_ids, [&"ch01.test.trace_anchor"], "traced emitted once")
	free_session(s)


func test_echo_actor_may_use_abilities_on_non_progression_objects() -> void:
	# ADR-008 am.: echoes never *record* abilities; the contract itself stays actor-agnostic.
	var s := make_session()
	_gate(s)
	_assert_true(s.interaction_service.request(&"echo.0", GATE, &"rewind").ok, "contract unchanged for echo actors")
	free_session(s)


func test_determinism_step_chunking_is_irrelevant() -> void:
	var timeline_a := _run_shutter_script(false)
	var timeline_b := _run_shutter_script(true)
	_assert_eq(timeline_a, timeline_b, "step(1) x N and step(N) produce identical timelines")


func _run_shutter_script(chunked: bool) -> Array:
	var s := make_session()
	var shutter: TemporalTestShutter = _shutter_rig(s)[0]
	var timeline: Array = []
	_req(s, SHUTTER, &"rewind")
	for segment in [50, 100, 40, 200]:
		if chunked:
			s.sim_clock.step(segment)
		else:
			for i in range(segment):
				s.sim_clock.step(1)
		timeline.append([s.sim_clock.tick, shutter.shutter_state, shutter.hold_ticks])
		if s.sim_clock.tick == 190:
			_req(s, SHUTTER, &"rewind")
	free_session(s)
	return timeline
