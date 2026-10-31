extends "res://tests/support/base_test.gd"

## Chapter 1 puzzle objects (TLF-023) against every acceptance test in design/ch01/puzzles/CH1-PZ-00N.md,
## using the exact object IDs from the specs, plus ADR-016 (reset/solved latch) and the timing assist.

var relocations: Array = []


func _session() -> GameSession:
	var s := make_session()
	relocations = []
	s.spatial_service.relocate_requested.connect(func(actor, anchor): relocations.append([actor, anchor]))
	return s


func _req(s: GameSession, actor: StringName, target: StringName, iid: StringName) -> InteractionResult:
	return s.interaction_service.request(actor, target, iid)


func _zone(s: GameSession, id: StringName) -> TriggerZone:
	return spawn(s, TriggerZone.new(), id) as TriggerZone


func _anchor(s: GameSession, id: StringName, puzzle: StringName) -> ResetAnchor:
	var a := ResetAnchor.new()
	a.puzzle_id = puzzle
	return spawn(s, a, id) as ResetAnchor


func _exit(s: GameSession, id: StringName, puzzle: StringName) -> PuzzleCompletionZone:
	var z := PuzzleCompletionZone.new()
	z.puzzle_id = puzzle
	return spawn(s, z, id) as PuzzleCompletionZone


# =============================== CH1-PZ-001 =========================================

const P1 := &"CH1-PZ-001"
const GATE := &"ch01.concourse_west.turnstile_gate"


func _pz1(s: GameSession) -> TurnstileGate:
	_zone(s, &"ch01.concourse_west.turnstile_footprint")
	var g := TurnstileGate.new()
	g.puzzle_id = P1
	g.footprint_zone_id = &"ch01.concourse_west.turnstile_footprint"
	g.safe_anchor_id = &"ch01.concourse_west.safe_anchor_east"
	spawn(s, g, GATE, make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
		[{"arm_state": &"open", "passage_blocked": false}]))
	spawn(s, Interactable.new(), &"ch01.concourse_west.support_pillar_01")
	_anchor(s, &"ch01.concourse_west.reset_anchor_01", P1)
	_exit(s, &"ch01.concourse_west.exit_trigger_concourse", P1)
	return g


func test_pz001_01_use_on_collapsed_turnstile_is_jammed() -> void:
	var s := _session()
	var g := _pz1(s)
	_assert_eq(_req(s, &"player", GATE, &"use").reason, &"jammed", "jammed")
	_assert_true(g.passage_blocked, "still blocked")
	free_session(s)


func test_pz001_02_pillar_rewind_unsupported() -> void:
	var s := _session()
	_pz1(s)
	_assert_eq(_req(s, &"player", &"ch01.concourse_west.support_pillar_01", &"rewind").reason, &"unsupported", "unsupported")
	free_session(s)


func test_pz001_03_rewind_restores_open_at_tick_10() -> void:
	var s := _session()
	var g := _pz1(s)
	s.sim_clock.step(10)
	var ticks: Array = []
	s.interaction_service.interaction_applied.connect(func(t, _a, _tg, _i, _p): ticks.append(t))
	_assert_true(_req(s, &"player", GATE, &"rewind").ok, "rewind ok")
	_assert_eq(g.capture_state(), {"arm_state": &"open", "passage_blocked": false}, "open")
	_assert_eq(ticks, [10], "interaction_applied at tick 10")
	free_session(s)


func test_pz001_04_second_rewind_no_history() -> void:
	var s := _session()
	var g := _pz1(s)
	_req(s, &"player", GATE, &"rewind")
	_assert_eq(_req(s, &"player", GATE, &"rewind").reason, &"no_history", "no_history")
	_assert_eq(g.arm_state, &"open", "stays open")
	free_session(s)


func test_pz001_05_exit_trigger_solves() -> void:
	var s := _session()
	_pz1(s)
	_req(s, &"player", GATE, &"rewind")
	s.interaction_service.trigger_enter(&"player", &"ch01.concourse_west.exit_trigger_concourse")
	_assert_true(s.puzzle_service.is_solved(P1), "solved")
	free_session(s)


func test_pz001_reset_collapses_and_relocates_player_in_footprint() -> void:
	var s := _session()
	var g := _pz1(s)
	_req(s, &"player", GATE, &"rewind")
	s.interaction_service.trigger_enter(&"player", &"ch01.concourse_west.turnstile_footprint")
	_assert_true(_req(s, &"player", &"ch01.concourse_west.reset_anchor_01", &"reset").ok, "reset ok")
	_assert_eq(g.arm_state, &"collapsed", "collapsed again")
	_assert_eq(relocations, [[&"player", &"ch01.concourse_west.safe_anchor_east"]], "moved out of the footprint first")
	_assert_true(_req(s, &"player", GATE, &"rewind").ok, "pre-history available again")
	free_session(s)


func test_pz001_adr016_reset_after_solve_keeps_passage_open() -> void:
	var s := _session()
	var g := _pz1(s)
	_req(s, &"player", GATE, &"rewind")
	s.interaction_service.trigger_enter(&"player", &"ch01.concourse_west.exit_trigger_concourse")
	_req(s, &"player", &"ch01.concourse_west.reset_anchor_01", &"reset")
	_assert_false(g.passage_blocked, "solved passage never re-blocks")
	free_session(s)


func test_pz001_solved_before_load_latches_open_on_ready() -> void:
	var s := _session()
	s.puzzle_service.mark_solved(P1)       # e.g. restored from a save before the room loads
	var g := _pz1(s)
	_assert_false(g.passage_blocked, "latched open on _ready")
	free_session(s)


# =============================== CH1-PZ-002 =========================================

const P2 := &"CH1-PZ-002"
const SHUTTER := &"ch01.maintenance_bay.fire_shutter"
const GEAR := &"ch01.maintenance_bay.counterweight_gear"
const THRESHOLD := &"ch01.maintenance_bay.shutter_threshold_trigger"


func _pz2(s: GameSession) -> Array:
	_zone(s, THRESHOLD)
	var gear := CounterweightGear.new()
	gear.puzzle_id = P2
	gear.shutter_id = SHUTTER
	spawn(s, gear, GEAR, make_temporal(TemporalComponent.CAP_FREEZE, []))
	var sh := FireShutter.new()
	sh.puzzle_id = P2
	sh.gear_id = GEAR
	sh.threshold_zone_id = THRESHOLD
	sh.safe_anchor_id = &"ch01.maintenance_bay.safe_anchor_west"
	spawn(s, sh, SHUTTER, make_temporal(TemporalComponent.CAP_REWIND, ["shutter_state", "hold_ticks", "passage_blocked"],
		[{"shutter_state": &"raised", "hold_ticks": 180, "passage_blocked": false}]))
	_anchor(s, &"ch01.maintenance_bay.reset_anchor_01", P2)
	_exit(s, &"ch01.maintenance_bay.exit_trigger_east", P2)
	return [sh, gear]


func test_pz002_01_raised_for_180_ticks_then_closes() -> void:
	var s := _session()
	var sh: FireShutter = _pz2(s)[0]
	_req(s, &"player", SHUTTER, &"rewind")
	s.sim_clock.step(179)
	_assert_eq([sh.shutter_state, sh.hold_ticks], [&"raised", 1], "tick 179: raised, 1 left")
	s.sim_clock.step(1)
	_assert_eq([sh.shutter_state, sh.passage_blocked], [&"closed", true], "tick 180: closed")
	free_session(s)


func test_pz002_02_freezing_gear_halts_countdown() -> void:
	var s := _session()
	var rig := _pz2(s)
	var sh: FireShutter = rig[0]
	_req(s, &"player", SHUTTER, &"rewind")
	s.sim_clock.step(60)
	_req(s, &"player", GEAR, &"freeze")
	s.sim_clock.step(300)
	_assert_eq([sh.shutter_state, sh.hold_ticks, sh.passage_blocked], [&"raised", 120, false], "halted at 120")
	_assert_eq(rig[1].gear_state, &"locked", "gear locked")
	free_session(s)


func test_pz002_03_frozen_gear_blocks_rewind() -> void:
	var s := _session()
	var sh: FireShutter = _pz2(s)[0]
	_req(s, &"player", GEAR, &"freeze")
	_assert_eq(_req(s, &"player", SHUTTER, &"rewind").reason, &"frozen", "frozen")
	_assert_eq(sh.shutter_state, &"closed", "unchanged")
	free_session(s)


func test_pz002_04_safety_clutch_relocates_player() -> void:
	var s := _session()
	var sh: FireShutter = _pz2(s)[0]
	_req(s, &"player", SHUTTER, &"rewind")
	s.sim_clock.step(175)                                  # hold_ticks == 5
	s.interaction_service.trigger_enter(&"player", THRESHOLD)
	s.sim_clock.step(5)
	_assert_eq(relocations, [[&"player", &"ch01.maintenance_bay.safe_anchor_west"]], "moved to safe_anchor_west")
	_assert_true(sh.passage_blocked, "closed after the player was moved")
	free_session(s)


func test_pz002_05_rewind_again_after_slipping() -> void:
	var s := _session()
	var sh: FireShutter = _pz2(s)[0]
	_req(s, &"player", SHUTTER, &"rewind")
	s.sim_clock.step(190)
	_assert_true(_req(s, &"player", SHUTTER, &"rewind").ok, "rewind ok at 190")
	_assert_eq([sh.shutter_state, sh.hold_ticks], [&"raised", 180], "full hold again")
	free_session(s)


func test_pz002_accessibility_assist_extends_window_to_300() -> void:
	var settings := _tree().root.get_node_or_null("Settings")
	if settings == null:
		_assert_true(false, "Settings autoload required")
		return
	var s := _session()
	var sh: FireShutter = _pz2(s)[0]
	var before: bool = settings.assist_extended_timing
	settings.assist_extended_timing = true
	_req(s, &"player", SHUTTER, &"rewind")
	_assert_eq(sh.hold_ticks, 300, "assist window")
	s.sim_clock.step(299)
	_assert_eq(sh.shutter_state, &"raised", "still raised at 299")
	settings.assist_extended_timing = before
	free_session(s)


func test_pz002_reset_and_solved_latch() -> void:
	var s := _session()
	var rig := _pz2(s)
	var sh: FireShutter = rig[0]
	_req(s, &"player", GEAR, &"freeze")
	_req(s, &"player", &"ch01.maintenance_bay.reset_anchor_01", &"use")
	_assert_false(rig[1].is_frozen(), "reset unfreezes the gear")
	_req(s, &"player", SHUTTER, &"rewind")
	_req(s, &"player", GEAR, &"freeze")
	s.interaction_service.trigger_enter(&"player", &"ch01.maintenance_bay.exit_trigger_east")
	_req(s, &"player", GEAR, &"freeze")                    # unfreeze after solving
	s.sim_clock.step(400)
	_assert_false(sh.passage_blocked, "solved shutter never closes again")
	free_session(s)


# =============================== CH1-PZ-003 =========================================

const P3 := &"CH1-PZ-003"
const PLATE := &"ch01.security_crossing.pressure_switch_01"
const SGATE := &"ch01.security_crossing.security_gate_01"
const BRIDGE := &"ch01.security_crossing.bridge_platform_01"
const ON_BRIDGE := &"ch01.security_crossing.bridge_walk_zone"


func _pz3(s: GameSession) -> Array:
	var plate := _zone(s, PLATE)
	_zone(s, ON_BRIDGE)
	var gate := PlateLinkedGate.new()
	gate.puzzle_id = P3
	gate.plate_id = PLATE
	spawn(s, gate, SGATE)
	var bridge := RetractableBridge.new()
	bridge.puzzle_id = P3
	bridge.plate_id = PLATE
	bridge.bridge_zone_id = ON_BRIDGE
	bridge.safe_anchor_id = &"ch01.security_crossing.safe_anchor_west"
	spawn(s, bridge, BRIDGE)
	var pickup := ProgressionPickup.new()
	pickup.flag_id = &"ch01.flag.transit_pass"
	spawn(s, pickup, &"ch01.security_crossing.transit_pass_pickup")
	_anchor(s, &"ch01.security_crossing.reset_anchor_01", P3)
	_exit(s, &"ch01.security_crossing.exit_trigger_lounge", P3)
	return [plate, gate, bridge, pickup]


func _record_hold(s: GameSession) -> void:
	s.echo_service.start_recording()
	s.sim_clock.step(40)
	s.interaction_service.trigger_enter(&"player", PLATE)
	s.sim_clock.step(40)
	s.echo_service.stop_recording()
	s.sim_clock.step(10)
	s.interaction_service.trigger_exit(&"player", PLATE)


func test_pz003_01_plate_toggles_gate_and_bridge_on_the_same_tick() -> void:
	var s := _session()
	var rig := _pz3(s)
	s.sim_clock.step(10)
	s.interaction_service.trigger_enter(&"player", PLATE)
	_assert_eq([rig[1].passage_blocked, rig[2].walkable], [false, true], "open + extended at tick 10")
	s.sim_clock.step(10)
	s.interaction_service.trigger_exit(&"player", PLATE)
	_assert_eq([rig[1].passage_blocked, rig[2].walkable], [true, false], "closed + retracted at tick 20")
	free_session(s)


func test_pz003_02_echo_holds_the_plate_after_playback() -> void:
	var s := _session()
	var rig := _pz3(s)
	_record_hold(s)
	s.sim_clock.step(10)                                   # tick 100
	s.echo_service.start_playback()
	s.sim_clock.step(40)
	_assert_true(&"echo.0" in rig[0].occupants, "echo on the plate at 140")
	s.sim_clock.step(160)
	_assert_eq([rig[1].passage_blocked, rig[2].walkable], [false, true], "still held at 300")
	free_session(s)


func test_pz003_03_reset_releases_echo_and_relocates_player_on_bridge() -> void:
	var s := _session()
	var rig := _pz3(s)
	_record_hold(s)
	s.echo_service.start_playback()
	s.sim_clock.step(60)
	s.interaction_service.trigger_enter(&"player", ON_BRIDGE)
	_req(s, &"player", &"ch01.security_crossing.reset_anchor_01", &"reset")
	_assert_false(rig[0].is_occupied(), "echo's trigger_exit dispatched")
	_assert_eq(relocations, [[&"player", &"ch01.security_crossing.safe_anchor_west"]], "player moved off the bridge")
	_assert_false(rig[2].walkable, "bridge retracted")
	free_session(s)


func test_pz003_04_echo_cannot_take_the_transit_pass() -> void:
	var s := _session()
	var rig := _pz3(s)
	var failures: Array = []
	s.echo_service.echo_event_failed.connect(func(_t, target, reason): failures.append([target, reason]))
	_assert_eq(_req(s, &"echo.0", &"ch01.security_crossing.transit_pass_pickup", &"use").reason, &"echo_forbidden", "forbidden")
	_assert_false(rig[3].is_collected(), "not collected")
	_assert_true(_req(s, &"player", &"ch01.security_crossing.transit_pass_pickup", &"use").ok, "player can take it")
	_assert_eq(_req(s, &"player", &"ch01.security_crossing.transit_pass_pickup", &"use").reason, &"already_open", "only once")
	free_session(s)


func test_pz003_05_gate_is_chrono_shielded() -> void:
	var s := _session()
	_pz3(s)
	_assert_eq(_req(s, &"player", SGATE, &"freeze").reason, &"unsupported", "freeze")
	_assert_eq(_req(s, &"player", SGATE, &"rewind").reason, &"unsupported", "rewind")
	free_session(s)


func test_pz003_solved_bridge_survives_echo_reset() -> void:
	var s := _session()
	var rig := _pz3(s)
	_record_hold(s)
	s.echo_service.start_playback()
	s.sim_clock.step(60)
	s.interaction_service.trigger_enter(&"player", &"ch01.security_crossing.exit_trigger_lounge")
	s.echo_service.reset_echo()
	_assert_eq([rig[1].passage_blocked, rig[2].walkable], [false, true], "latched open after SOLVED")
	free_session(s)


# =============================== CH1-PZ-004 =========================================

const P4 := &"CH1-PZ-004"
const CAP := &"ch01.signal_control.surge_capacitor"
const BA := &"ch01.signal_control.breaker_a"
const BB := &"ch01.signal_control.breaker_b"
const GRID := &"ch01.signal_control.substation_grid"
const DOOR := &"ch01.signal_control.vestibule_door"


func _pz4(s: GameSession) -> Array:
	var cap := SurgeCapacitor.new()
	cap.puzzle_id = P4
	spawn(s, cap, CAP, make_temporal(TemporalComponent.CAP_REWIND | TemporalComponent.CAP_FREEZE,
		["charge_state", "decay_ticks", "bus_powered"],
		[{"charge_state": &"charged", "decay_ticks": 240, "bus_powered": true}]))
	var out := [cap]
	for id in [BA, BB]:
		var b := TimedBreaker.new()
		b.puzzle_id = P4
		b.capacitor_id = CAP
		out.append(spawn(s, b, id))
	var grid := SubstationGrid.new()
	grid.puzzle_id = P4
	grid.capacitor_id = CAP
	grid.breaker_a_id = BA
	grid.breaker_b_id = BB
	out.append(spawn(s, grid, GRID))
	var door := PoweredDoor.new()
	door.puzzle_id = P4
	door.grid_id = GRID
	out.append(spawn(s, door, DOOR))
	_anchor(s, &"ch01.signal_control.reset_anchor_01", P4)
	_exit(s, &"ch01.signal_control.exit_trigger_vestibule", P4)
	return out   # [cap, breaker_a, breaker_b, grid, door]


func _stabilize(s: GameSession) -> void:
	_req(s, &"player", CAP, &"rewind")
	_req(s, &"player", CAP, &"freeze")


func test_pz004_01_breakers_unpowered_before_step_1() -> void:
	var s := _session()
	var rig := _pz4(s)
	_assert_eq(_req(s, &"player", BA, &"use").reason, &"unpowered", "unpowered")
	_assert_eq(rig[1].lever_state, &"open", "still open")
	free_session(s)


func test_pz004_02_rewind_then_freeze_locks_the_bus() -> void:
	var s := _session()
	var rig := _pz4(s)
	s.sim_clock.step(10)
	_req(s, &"player", CAP, &"rewind")
	s.sim_clock.step(40)
	_assert_eq(rig[0].decay_ticks, 200, "decayed to 200 at tick 50")
	_req(s, &"player", CAP, &"freeze")
	s.sim_clock.step(500)
	_assert_eq([rig[0].bus_powered, rig[0].decay_ticks, rig[3].step_1_stabilized], [true, 200, true], "locked at 550")
	free_session(s)


func test_pz004_03_single_breaker_expires_after_180() -> void:
	var s := _session()
	var rig := _pz4(s)
	_stabilize(s)
	s.sim_clock.step(100)
	_req(s, &"player", BA, &"use")
	s.sim_clock.step(179)
	_assert_true(rig[1].is_engaged(), "engaged at 279")
	s.sim_clock.step(1)
	_assert_false(rig[1].is_engaged(), "open at 280")
	_assert_false(rig[3].grid_online, "grid offline")
	free_session(s)


func test_pz004_04_echo_a_plus_player_b_brings_the_grid_online() -> void:
	var s := _session()
	var rig := _pz4(s)
	_stabilize(s)
	s.echo_service.start_recording()
	s.sim_clock.step(30)
	_req(s, &"player", BA, &"use")
	s.sim_clock.step(30)
	s.echo_service.stop_recording()
	s.sim_clock.step(240)                                  # A times out; tick 300
	_assert_false(rig[1].is_engaged(), "A back to open before playback")
	s.echo_service.start_playback()
	s.sim_clock.step(30)
	_assert_true(rig[1].is_engaged(), "echo engaged A at 330")
	s.sim_clock.step(50)
	_assert_true(_req(s, &"player", BB, &"use").ok, "player pulls B at 380")
	_assert_true(rig[3].grid_online, "grid online")
	_assert_false(rig[4].passage_blocked, "vestibule door open")
	free_session(s)


func test_pz004_04b_echo_window_equals_player_window() -> void:
	var s := _session()
	var rig := _pz4(s)
	_stabilize(s)
	s.echo_service.start_recording()
	s.sim_clock.step(5)
	_req(s, &"player", BA, &"use")
	s.echo_service.stop_recording()
	s.sim_clock.step(200)
	s.echo_service.start_playback()
	s.sim_clock.step(5)                                    # echo engages A inside a tick signal
	s.sim_clock.step(179)
	_assert_true(rig[1].is_engaged(), "still engaged 179 ticks after the echo's pull")
	s.sim_clock.step(1)
	_assert_false(rig[1].is_engaged(), "released at exactly +180, like a player pull")
	free_session(s)


func test_pz004_05_unpowered_replay_fails_with_reason() -> void:
	var s := _session()
	var rig := _pz4(s)
	_stabilize(s)
	var failures: Array = []
	s.echo_service.echo_event_failed.connect(func(_t, target, reason): failures.append([target, reason]))
	s.echo_service.start_recording()
	s.sim_clock.step(20)
	_req(s, &"player", BA, &"use")
	s.echo_service.stop_recording()
	_req(s, &"player", CAP, &"freeze")                     # unfreeze -> decays to discharged
	s.sim_clock.step(300)
	_assert_false(rig[0].bus_powered, "bus unpowered")
	s.echo_service.start_playback()
	s.sim_clock.step(20)
	_assert_eq(failures, [[BA, &"unpowered"]], "echo_event_failed(unpowered)")
	_assert_false(rig[1].is_engaged(), "A stays open")
	free_session(s)


func test_pz004_06_exit_trigger_solves() -> void:
	var s := _session()
	_pz4(s)
	s.interaction_service.trigger_enter(&"player", &"ch01.signal_control.exit_trigger_vestibule")
	_assert_true(s.puzzle_service.is_solved(P4), "solved")
	free_session(s)


func test_pz004_rewinding_frozen_capacitor_is_refused_and_reset_restores() -> void:
	var s := _session()
	var rig := _pz4(s)
	_req(s, &"player", CAP, &"freeze")
	_assert_eq(_req(s, &"player", CAP, &"rewind").reason, &"frozen", "frozen")
	_req(s, &"player", &"ch01.signal_control.reset_anchor_01", &"reset")
	_assert_false(rig[0].is_frozen(), "unfrozen by reset")
	_assert_true(_req(s, &"player", CAP, &"rewind").ok, "rewind available again")
	free_session(s)


# =============================== CH1-PZ-005 =========================================

const P5 := &"CH1-PZ-005"
const SIG := &"ch01.signal_control"
const VEST := &"ch01.upper_vestibule"
const NICHE := &"ch01.vestibule_niche"
const ATRIUM := &"ch01.station_atrium"
const STATE_0 := [
	[SIG, &"door_exit_north", VEST, &"door_south"],
	[VEST, &"door_north", VEST, &"door_west"],
	[VEST, &"door_east", NICHE, &"door_in"],
	[NICHE, &"door_out", ATRIUM, &"door_entry_south", false],
]
const LEVER_A := &"ch01.upper_vestibule.junction_lever_a"
const LEVER_B := &"ch01.upper_vestibule.junction_lever_b"


func _pz5(s: GameSession) -> Array:
	var g := SpatialGraph.new()
	g.add_room(SIG, [&"door_exit_north"])
	g.add_room(VEST, [&"door_south", &"door_west", &"door_east", &"door_north"])
	g.add_room(NICHE, [&"door_in", &"door_out"])
	g.add_room(ATRIUM, [&"door_entry_south"])
	g.add_critical_pair(SIG, VEST)
	g.set_initial_pairs(STATE_0)
	s.spatial_service.set_graph(g, SIG)
	s.spatial_service.set_relocation_anchor(NICHE, &"ch01.upper_vestibule.safe_anchor_center")
	var a := JunctionLever.new()
	a.puzzle_id = P5
	a.state_a = &"loop"
	a.state_b = &"uncoupled"
	a.pairs_to_b = [[VEST, &"door_west", VEST, &"door_east"], [VEST, &"door_north", NICHE, &"door_in"]]
	a.pairs_to_a = [[VEST, &"door_north", VEST, &"door_west"], [VEST, &"door_east", NICHE, &"door_in"]]
	spawn(s, a, LEVER_A)
	var b := JunctionLever.new()
	b.puzzle_id = P5
	b.state_a = &"niche"
	b.state_b = &"atrium"
	b.pairs_to_b = [[VEST, &"door_north", ATRIUM, &"door_entry_south"], [NICHE, &"door_in", NICHE, &"door_out", false]]
	b.pairs_to_a = [[VEST, &"door_north", NICHE, &"door_in"], [NICHE, &"door_out", ATRIUM, &"door_entry_south", false]]
	spawn(s, b, LEVER_B)
	var resetter := SpatialStateResetter.new()
	resetter.puzzle_id = P5
	resetter.initial_pairs = STATE_0.slice(1)
	spawn(s, resetter, &"ch01.upper_vestibule.spatial_resetter")
	var board := Interactable.new()
	board.traceable = true
	spawn(s, board, &"ch01.upper_vestibule.route_board")
	_anchor(s, &"ch01.upper_vestibule.reset_anchor_01", P5)
	_exit(s, &"ch01.station_atrium.entry_trigger_atrium", P5)
	return [a, b, g]


func _dest(g: SpatialGraph) -> Array:
	var d := g.get_destination(VEST, &"door_north")
	return [d["room_id"], d["door_id"]]


func test_pz005_01_state0_north_loops_to_west() -> void:
	var s := _session()
	_assert_eq(_dest(_pz5(s)[2]), [VEST, &"door_west"], "loop")
	free_session(s)


func test_pz005_02_lever_b_first_is_invalid_graph() -> void:
	var s := _session()
	var rig := _pz5(s)
	var changed: Array = []
	rig[2].changed.connect(func(r): changed.append(r))
	_assert_eq(_req(s, &"player", LEVER_B, &"use").reason, &"invalid_graph", "refused")
	_assert_eq([changed, rig[1].relay_state, _dest(rig[2])], [[], &"niche", [VEST, &"door_west"]], "nothing changed")
	free_session(s)


func test_pz005_03_lever_a_then_b_routes_north_to_atrium() -> void:
	var s := _session()
	var rig := _pz5(s)
	var changed: Array = []
	rig[2].changed.connect(func(r): changed.append(r))
	_assert_true(_req(s, &"player", LEVER_A, &"use").ok, "A ok")
	_assert_true(_req(s, &"player", LEVER_B, &"use").ok, "B ok")
	_assert_eq([changed.size(), rig[0].relay_state, rig[1].relay_state], [2, &"uncoupled", &"atrium"], "two changes, relays updated")
	_assert_eq(_dest(rig[2]), [ATRIUM, &"door_entry_south"], "north -> atrium")
	free_session(s)


func test_pz005_04_severing_the_entry_is_critical_path_unreachable() -> void:
	var s := _session()
	var g: SpatialGraph = _pz5(s)[2]
	var sever := [[SIG, &"door_exit_north", SIG, &"door_exit_north"], [VEST, &"door_south", VEST, &"door_north"], [VEST, &"door_west", VEST, &"door_west"]]
	_assert_eq(s.spatial_service.validate_transform(sever).reason, &"critical_path_unreachable", "dry run refuses")
	_assert_eq(g.apply(sever)["reason"], &"critical_path_unreachable", "apply refuses")
	free_session(s)


func test_pz005_05_player_in_niche_is_relocated_when_sealed() -> void:
	var s := _session()
	_pz5(s)
	_req(s, &"player", LEVER_A, &"use")
	s.spatial_service.set_actor_room(&"player", NICHE)
	_req(s, &"player", LEVER_B, &"use")
	_assert_eq(relocations, [[&"player", &"ch01.upper_vestibule.safe_anchor_center"]], "moved to safe_anchor_center")
	free_session(s)


func test_pz005_06_atrium_entry_solves_and_latches_levers() -> void:
	var s := _session()
	_pz5(s)
	_req(s, &"player", LEVER_A, &"use")
	_req(s, &"player", LEVER_B, &"use")
	s.interaction_service.trigger_enter(&"player", &"ch01.station_atrium.entry_trigger_atrium")
	_assert_true(s.puzzle_service.is_solved(P5), "solved")
	_assert_eq(_req(s, &"player", LEVER_B, &"use").reason, &"locked", "State 2 stays permanent")
	free_session(s)


func test_pz005_reset_restores_state0_atomically() -> void:
	var s := _session()
	var rig := _pz5(s)
	var initial: Array = rig[2].export_pairs()
	_req(s, &"player", LEVER_A, &"use")
	_req(s, &"player", LEVER_B, &"use")
	_assert_true(_req(s, &"player", &"ch01.upper_vestibule.reset_anchor_01", &"reset").ok, "reset ok")
	_assert_eq(rig[2].export_pairs(), initial, "State 0 restored in one apply")
	_assert_eq([rig[0].relay_state, rig[1].relay_state], [&"loop", &"niche"], "lever labels reset")
	_assert_true(_req(s, &"player", LEVER_A, &"use").ok, "puzzle playable again")
	free_session(s)


func test_pz005_levers_and_route_board_abilities() -> void:
	var s := _session()
	_pz5(s)
	_assert_eq(_req(s, &"player", LEVER_A, &"rewind").reason, &"unsupported", "relay outside local time")
	_assert_true(_req(s, &"player", &"ch01.upper_vestibule.route_board", &"trace").ok, "board traceable")
	free_session(s)
