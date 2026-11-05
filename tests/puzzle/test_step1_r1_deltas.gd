extends "res://tests/support/base_test.gd"

## Step 1 puzzle logic (TLF-054), commit B: the R1 deltas of CH1-PZ-001..005 (section "R1 Revision 1"
## of each spec), as standalone rooms with the spec IDs. Every new export defaults to the base
## behaviour, so tests/puzzle/test_ch01_puzzles.gd (TEST-PZ00x-*) runs unchanged next to these.
## Real-input / real-collider tests (TEST-PZ001-R07, PZ002-R03 walk, R06, PZ003-R07/R08,
## PZ005-R03, ...) are TLF-056.

const TEXT_CSV := "res://localization/ch01_text.csv"

var relocations: Array = []
var feedback: Array = []


func _session() -> GameSession:
	var s := make_session()
	relocations = []
	feedback = []
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


func _memory(s: GameSession, id: StringName, flag: StringName = &"", journal: String = "") -> TraceMemory:
	var m := TraceMemory.new()
	m.flag_id = flag
	m.journal_key = journal
	return spawn(s, m, id) as TraceMemory


func _unlock_on_flag(s: GameSession, ability: StringName, flag: StringName) -> void:
	var t := AbilityUnlockTrigger.new()
	t.ability = ability
	t.on_flag = flag
	s.add_child(t)


func _journal_count(s: GameSession, key: String) -> int:
	return s.narrative_state.get_journal().filter(func(e): return e["key"] == key).size()


func _text() -> Dictionary:
	var out := {}
	var file := FileAccess.open(TEXT_CSV, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2 and not row[0].is_empty():
			out[row[0]] = row[1]
	return out


func _reload(s: GameSession, build: Callable) -> GameSession:
	var store := _tree().root.get_node("SaveService")
	var data: Dictionary = store.capture(s, "ch01", "test")
	free_session(s)
	var s2 := _session()
	_assert_true(store.apply(s2, data)["ok"], "progress applied")
	build.call(s2)
	_assert_true(store.apply(s2, data)["ok"], "room histories applied")
	return s2


# =============================== CH1-PZ-001 R1 ======================================

const P1 := &"CH1-PZ-001"
const GATE := &"ch01.concourse_west.turnstile_gate"
const CONDUIT := &"ch01.concourse_west.conduit_01"
const COURIER := &"ch01.concourse_west.n05_courier"
const COURIER_FLAG := &"ch01.npc.n05.traced"
const ANCHOR_MEM := &"ch01.concourse_west.turnstile_trace_anchor"
const EXIT_1 := &"ch01.concourse_west.exit_trigger_concourse"


func _pz1(s: GameSession) -> Array:
	_zone(s, &"ch01.concourse_west.turnstile_footprint")
	var conduit := ConduitProp.new()
	conduit.puzzle_id = P1
	spawn(s, conduit, CONDUIT, make_temporal(TemporalComponent.CAP_REWIND, ["conduit_state"], [{"conduit_state": &"mounted"}]))
	var g := TurnstileGate.new()
	g.puzzle_id = P1
	g.footprint_zone_id = &"ch01.concourse_west.turnstile_footprint"
	g.safe_anchor_id = &"ch01.concourse_west.safe_anchor_east"
	g.pinned_by = CONDUIT
	spawn(s, g, GATE, make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
		[{"arm_state": &"open", "passage_blocked": false}]))
	_memory(s, COURIER, COURIER_FLAG, "JRN_MEM_N05")
	_memory(s, ANCHOR_MEM, &"", "JRN_CH1_TURNSTILE_TRACE")
	_unlock_on_flag(s, &"rewind", COURIER_FLAG)
	_anchor(s, &"ch01.concourse_west.reset_anchor_01", P1)
	_exit(s, EXIT_1, P1)
	return [g, conduit]


func test_pz001_r01_the_courier_unlocks_rewind() -> void:
	var s := _session()
	s.ability_unlocks.set_unlocked([&"trace"])
	_pz1(s)
	_assert_false(s.ability_unlocks.is_unlocked(&"rewind"), "rewind locked at the start")
	_assert_true(_req(s, &"player", COURIER, &"trace").ok, "trace the courier")
	_assert_true(s.ability_unlocks.is_unlocked(&"rewind"), "rewind unlocked")
	_assert_true(bool(s.narrative_state.get_flag(COURIER_FLAG)), "n05 traced flag")
	free_session(s)


func test_pz001_r02_anchor_memory_journals_once() -> void:
	var s := _session()
	_pz1(s)
	var revealed := [0]
	(s.id_registry.resolve(ANCHOR_MEM) as TraceMemory).memory_revealed.connect(func(_id): revealed[0] += 1)
	_req(s, &"player", ANCHOR_MEM, &"trace")
	_req(s, &"player", ANCHOR_MEM, &"trace")
	_assert_eq(revealed[0], 2, "memory plays on every trace")
	_assert_eq(_journal_count(s, "JRN_CH1_TURNSTILE_TRACE"), 1, "journaled once")
	free_session(s)


func test_pz001_r03_fallen_conduit_pins_the_turnstile() -> void:
	var s := _session()
	var rig := _pz1(s)
	var r := _req(s, &"player", GATE, &"rewind")
	_assert_eq([r.ok, r.reason], [false, &"pinned"], "pinned")
	_assert_eq(rig[0].arm_state, &"collapsed", "arm unchanged")
	_assert_eq(rig[0].feedback_key(&"pinned"), "PZ001_FB_PINNED", "feedback key")
	_assert_eq(rig[0].get_temporal().get_history_cursor(), 1, "no history step")
	free_session(s)


func test_pz001_r04_conduit_rewinds_once() -> void:
	var s := _session()
	var rig := _pz1(s)
	_assert_true(_req(s, &"player", CONDUIT, &"rewind").ok, "rewind conduit")
	_assert_eq(rig[1].conduit_state, &"mounted", "mounted")
	_assert_eq(_req(s, &"player", CONDUIT, &"rewind").reason, &"no_history", "second rewind")
	_assert_eq(_req(s, &"player", CONDUIT, &"use").reason, &"unsupported", "not by hand")
	free_session(s)


func test_pz001_r05_full_solution_and_latch() -> void:
	var s := _session()
	s.ability_unlocks.set_unlocked([&"trace"])
	var rig := _pz1(s)
	_req(s, &"player", COURIER, &"trace")
	_req(s, &"player", ANCHOR_MEM, &"trace")
	_assert_eq(_req(s, &"player", GATE, &"rewind").reason, &"pinned", "plausible wrong order")
	_assert_true(_req(s, &"player", CONDUIT, &"rewind").ok, "conduit back on its bracket")
	_assert_true(_req(s, &"player", GATE, &"rewind").ok, "gate rewinds now")
	_assert_false(rig[0].passage_blocked, "open")
	s.interaction_service.trigger_enter(&"player", EXIT_1)
	_assert_true(s.puzzle_service.is_solved(P1), "SOLVED")
	_req(s, &"player", &"ch01.concourse_west.reset_anchor_01", &"reset")
	_assert_eq([rig[1].conduit_state, rig[0].passage_blocked], [&"mounted", false], "latched after reset")
	free_session(s)


func test_pz001_r06_order_independence() -> void:
	var s := _session()
	var rig := _pz1(s)
	_req(s, &"player", CONDUIT, &"rewind")
	_assert_true(_req(s, &"player", GATE, &"rewind").ok, "solvable before the anchor is traced")
	_req(s, &"player", ANCHOR_MEM, &"trace")
	_assert_eq(_journal_count(s, "JRN_CH1_TURNSTILE_TRACE"), 1, "journal entry when traced later")
	_assert_false(rig[0].passage_blocked, "still open")
	free_session(s)


func test_pz001_r08_empty_pinned_by_is_the_base_turnstile() -> void:
	var s := _session()
	var g := TurnstileGate.new()
	g.puzzle_id = P1
	spawn(s, g, GATE, make_temporal(TemporalComponent.CAP_REWIND, ["arm_state", "passage_blocked"],
		[{"arm_state": &"open", "passage_blocked": false}]))
	_assert_false(g.is_pinned(), "not pinned")
	_assert_true(_req(s, &"player", GATE, &"rewind").ok, "base rewind")
	free_session(s)


func test_pz001_r09_reset_while_unsolved() -> void:
	var s := _session()
	var rig := _pz1(s)
	_req(s, &"player", CONDUIT, &"rewind")
	_req(s, &"player", GATE, &"rewind")
	s.puzzle_service.reset_puzzle(P1)
	_assert_eq([rig[1].conduit_state, rig[0].arm_state], [&"fallen", &"collapsed"], "both back to tick 0")
	_assert_eq(_req(s, &"player", GATE, &"rewind").reason, &"pinned", "pinned again")
	free_session(s)


# =============================== CH1-PZ-002 R1 ======================================

const P2 := &"CH1-PZ-002"
const SHUTTER := &"ch01.maintenance_bay.fire_shutter"
const INNER := &"ch01.maintenance_bay.inner_shutter"
const GEAR := &"ch01.maintenance_bay.counterweight_gear"
const THRESHOLD := &"ch01.maintenance_bay.shutter_threshold_trigger"
const INNER_THRESHOLD := &"ch01.maintenance_bay.inner_shutter_threshold"
const OLD_EXIT := &"ch01.maintenance_bay.exit_trigger_east"
const EXIT_2 := &"ch01.maintenance_bay.exit_trigger_east_02"
const SHUTTER_FIELDS := ["shutter_state", "hold_ticks", "passage_blocked"]
const SHUTTER_HISTORY := [{"shutter_state": &"raised", "hold_ticks": 180, "passage_blocked": false}]


func _shutter(s: GameSession, id: StringName, threshold: StringName, anchor: StringName, inner: bool) -> FireShutter:
	var sh := FireShutter.new()
	sh.puzzle_id = P2
	sh.gear_id = GEAR
	sh.threshold_zone_id = threshold
	sh.safe_anchor_id = anchor
	sh.requires_gear_frozen = inner
	return spawn(s, sh, id, make_temporal(TemporalComponent.CAP_REWIND, SHUTTER_FIELDS, SHUTTER_HISTORY)) as FireShutter


func _pz2(s: GameSession) -> Array:
	_zone(s, THRESHOLD)
	_zone(s, INNER_THRESHOLD)
	var gear := CounterweightGear.new()
	gear.puzzle_id = P2
	gear.shutter_id = SHUTTER
	spawn(s, gear, GEAR, make_temporal(TemporalComponent.CAP_FREEZE, []))
	var outer := _shutter(s, SHUTTER, THRESHOLD, &"ch01.maintenance_bay.safe_anchor_west", false)
	var inner := _shutter(s, INNER, INNER_THRESHOLD, &"ch01.maintenance_bay.safe_anchor_east", true)
	_anchor(s, &"ch01.maintenance_bay.reset_anchor_01", P2)
	_exit(s, OLD_EXIT, &"")       # D3: kept in place, puzzle_id cleared (inert)
	_exit(s, EXIT_2, P2)
	return [outer, inner, gear]


func test_pz002_r01_inner_shutter_is_unanchored_while_the_gear_is_free() -> void:
	var s := _session()
	var rig := _pz2(s)
	var r := _req(s, &"player", INNER, &"rewind")
	_assert_eq([r.ok, r.reason], [false, &"unanchored"], "unanchored")
	_assert_eq(rig[1].feedback_key(&"unanchored"), "PZ002_FB_UNANCHORED", "feedback key")
	_assert_eq(rig[1].shutter_state, &"closed", "still closed")
	free_session(s)


func test_pz002_r02_anchored_inner_shutter_holds() -> void:
	var s := _session()
	var rig := _pz2(s)
	_req(s, &"player", GEAR, &"freeze")
	_assert_true(_req(s, &"player", INNER, &"rewind").ok, "rewind with the gear frozen")
	_assert_eq(rig[1].shutter_state, &"raised", "raised")
	s.sim_clock.step(2000)
	_assert_eq(rig[1].shutter_state, &"raised", "still raised after 2000 ticks")
	free_session(s)


func _rule_holds_without_freeze() -> void:
	var s := _session()
	var rig := _pz2(s)
	_assert_true(_req(s, &"player", SHUTTER, &"rewind").ok, "first shutter up")
	s.sim_clock.step(26)                                   # the TLF-049 run reached the pocket in 26 ticks
	_assert_eq(_req(s, &"player", INNER, &"rewind").reason, &"unanchored", "inner refused without Freeze")
	s.interaction_service.trigger_enter(&"player", OLD_EXIT)
	s.sim_clock.step(600)
	_assert_false(s.puzzle_service.is_solved(P2), "not solved after 600 ticks")
	_assert_true(rig[1].passage_blocked, "inner shutter closed")
	free_session(s)


## The logic half of TEST-PZ002-R03 (the real-input walk is TLF-056): a rule, not a timing gate,
## so the assist window changes nothing.
func test_pz002_r03_freeze_is_required_assist_off() -> void:
	var settings := _tree().root.get_node("Settings")
	var before: bool = settings.assist_extended_timing
	settings.assist_extended_timing = false
	_rule_holds_without_freeze()
	settings.assist_extended_timing = before


func test_pz002_r03_freeze_is_required_assist_on() -> void:
	var settings := _tree().root.get_node("Settings")
	var before: bool = settings.assist_extended_timing
	settings.assist_extended_timing = true
	_rule_holds_without_freeze()
	settings.assist_extended_timing = before


func test_pz002_r04_late_freeze_from_the_pocket_solves() -> void:
	var s := _session()
	var rig := _pz2(s)
	_req(s, &"player", SHUTTER, &"rewind")
	s.sim_clock.step(180)
	_assert_eq(rig[0].shutter_state, &"closed", "first shutter closed again")
	_assert_true(_req(s, &"player", GEAR, &"freeze").ok, "freeze the gear from the pocket")
	_assert_true(_req(s, &"player", INNER, &"rewind").ok, "inner shutter lifts")
	s.interaction_service.trigger_enter(&"player", EXIT_2)
	_assert_true(s.puzzle_service.is_solved(P2), "SOLVED")
	free_session(s)


func test_pz002_r05_full_solution_survives_save_and_load() -> void:
	var s := _session()
	_pz2(s)
	_req(s, &"player", SHUTTER, &"rewind")
	_req(s, &"player", GEAR, &"freeze")
	_req(s, &"player", INNER, &"rewind")
	s.interaction_service.trigger_enter(&"player", EXIT_2)
	_assert_true(s.puzzle_service.is_solved(P2), "SOLVED")
	s = _reload(s, func(s2): _pz2(s2))
	for id in [SHUTTER, INNER]:
		_assert_false((s.id_registry.resolve(id) as FireShutter).passage_blocked, "%s open after load" % id)
	free_session(s)


func test_pz002_r07_clutch_when_the_gear_is_unfrozen_later() -> void:
	var s := _session()
	var rig := _pz2(s)
	_req(s, &"player", GEAR, &"freeze")
	_req(s, &"player", INNER, &"rewind")
	s.interaction_service.trigger_enter(&"player", INNER_THRESHOLD)
	_req(s, &"player", GEAR, &"freeze")                    # unfreeze: the hold counts down again
	s.sim_clock.step(180)
	_assert_eq(relocations, [[&"player", &"ch01.maintenance_bay.safe_anchor_east"]], "moved to safe_anchor_east")
	_assert_true(rig[1].passage_blocked, "closed after the move")
	free_session(s)


func test_pz002_r08_base_shutter_rule_unchanged() -> void:
	var s := _session()
	_pz2(s)
	_req(s, &"player", GEAR, &"freeze")
	_assert_eq(_req(s, &"player", SHUTTER, &"rewind").reason, &"frozen", "base shutter: frozen gear blocks it")
	free_session(s)


func test_pz002_r09_old_trigger_is_inert() -> void:
	var s := _session()
	_pz2(s)
	_req(s, &"player", SHUTTER, &"rewind")
	_req(s, &"player", GEAR, &"freeze")
	s.interaction_service.trigger_enter(&"player", OLD_EXIT)
	_assert_false(s.puzzle_service.is_solved(P2), "old exit does not solve")
	free_session(s)


func test_pz002_r10_reset_closes_both_and_unfreezes() -> void:
	var s := _session()
	var rig := _pz2(s)
	_req(s, &"player", SHUTTER, &"rewind")
	_req(s, &"player", GEAR, &"freeze")
	_req(s, &"player", INNER, &"rewind")
	s.puzzle_service.reset_puzzle(P2)
	_assert_eq([rig[0].shutter_state, rig[1].shutter_state], [&"closed", &"closed"], "both closed")
	_assert_false(rig[2].is_frozen(), "gear unfrozen")
	free_session(s)


# =============================== CH1-PZ-003 R1 ======================================

const P3 := &"CH1-PZ-003"
const PLATE := &"ch01.security_crossing.pressure_switch_01"
const SGATE := &"ch01.security_crossing.security_gate_01"
const PASS := &"ch01.security_crossing.transit_pass_pickup"
const PASS_FLAG := &"ch01.flag.transit_pass"
const PEDESTAL := &"ch01.security_crossing.echo_recorder_pedestal"
const PEDESTAL_FLAG := &"ch01.flag.echo_pedestal_used"
const GUARD := &"ch01.security_crossing.n13_guard"
const ALARM := &"ch01.security_crossing.alarm_plate_01"
const READER := &"ch01.security_crossing.card_reader_01"
const BARRIER := &"ch01.security_crossing.staff_barrier_01"
const EXIT_3 := &"ch01.security_crossing.exit_trigger_lounge"


func _pz3(s: GameSession) -> Array:
	_zone(s, PLATE)
	var gate := PlateLinkedGate.new()
	gate.puzzle_id = P3
	gate.plate_id = PLATE
	spawn(s, gate, SGATE)
	var pickup := ProgressionPickup.new()
	pickup.flag_id = PASS_FLAG
	spawn(s, pickup, PASS)
	var pedestal := ProgressionPickup.new()        # a one-line `use` object that sets the unlock flag
	pedestal.flag_id = PEDESTAL_FLAG
	spawn(s, pedestal, PEDESTAL)
	_unlock_on_flag(s, &"echo", PEDESTAL_FLAG)
	_memory(s, GUARD, &"", "JRN_MEM_N13")
	var alarm := DecoyPlate.new()
	alarm.enter_text_key = "PZ003_FB_ALARM"
	spawn(s, alarm, ALARM)
	alarm.feedback_requested.connect(func(key): feedback.append(key))
	var reader := CardReader.new()
	reader.puzzle_id = P3
	spawn(s, reader, READER)
	var barrier := PoweredDoor.new()
	barrier.puzzle_id = P3
	barrier.grid_id = READER
	barrier.closed_reason = &"locked"
	barrier.feedback_keys = {&"locked": "PZ003_FB_BARRIER"}
	spawn(s, barrier, BARRIER)
	_anchor(s, &"ch01.security_crossing.reset_anchor_01", P3)
	_exit(s, EXIT_3, P3)
	return [gate, reader, barrier]


func test_pz003_r01_pedestal_unlocks_echo() -> void:
	var s := _session()
	s.ability_unlocks.set_unlocked([&"trace", &"rewind", &"freeze"])
	_pz3(s)
	_assert_true(_req(s, &"player", PEDESTAL, &"use").ok, "use the pedestal")
	_assert_true(s.ability_unlocks.is_unlocked(&"echo"), "echo unlocked")
	_assert_eq(_req(s, &"player", PEDESTAL, &"use").reason, &"already_open", "second use")
	free_session(s)


func test_pz003_r02_guard_memory_journals_once() -> void:
	var s := _session()
	_pz3(s)
	_req(s, &"player", GUARD, &"trace")
	_req(s, &"player", GUARD, &"trace")
	_assert_eq(_journal_count(s, "JRN_MEM_N13"), 1, "journaled once")
	free_session(s)


## An echo only replays interactions that were applied, so the only way an echo can reach the pass
## is a direct request with an echo actor; it is refused before anything changes (ADR-006).
func test_pz003_r03_echo_cannot_take_the_pass() -> void:
	var s := _session()
	_pz3(s)
	_assert_eq(_req(s, &"echo.0", PASS, &"use").reason, &"echo_forbidden", "echo_forbidden")
	_assert_false(bool(s.narrative_state.get_flag(PASS_FLAG)), "pass not taken")
	free_session(s)


func test_pz003_r04_reader_without_the_pass() -> void:
	var s := _session()
	var rig := _pz3(s)
	_assert_eq(_req(s, &"player", READER, &"use").reason, &"no_pass", "no_pass")
	_assert_eq(rig[1].feedback_key(&"no_pass"), "PZ003_FB_NO_PASS", "feedback key")
	_assert_eq(_req(s, &"player", BARRIER, &"use").reason, &"locked", "barrier locked")
	_assert_eq(rig[2].feedback_key(&"locked"), "PZ003_FB_BARRIER", "barrier key")
	_assert_true(rig[2].passage_blocked, "barrier closed")
	free_session(s)


func test_pz003_r05_reader_with_the_pass_latches() -> void:
	var s := _session()
	var rig := _pz3(s)
	_assert_true(_req(s, &"player", PASS, &"use").ok, "player takes the pass")
	_assert_true(_req(s, &"player", READER, &"use").ok, "reader accepts")
	_assert_false(rig[2].passage_blocked, "barrier open")
	s.puzzle_service.reset_puzzle(P3)
	_assert_false(rig[2].passage_blocked, "still open after a reset")
	_assert_eq(_req(s, &"player", READER, &"use").reason, &"already_open", "one-time")
	free_session(s)


func test_pz003_r06_alarm_plate_does_not_open_the_gate() -> void:
	var s := _session()
	var rig := _pz3(s)
	s.interaction_service.trigger_enter(&"player", ALARM)
	_assert_true(rig[0].passage_blocked, "gate stays closed")
	_assert_eq(feedback, ["PZ003_FB_ALARM"], "alarm feedback")
	free_session(s)


func test_pz003_r09_full_solution_survives_save_and_load() -> void:
	var s := _session()
	_pz3(s)
	_req(s, &"player", PASS, &"use")
	s.interaction_service.trigger_enter(&"echo.0", PLATE)     # the echo holds the south plate
	_req(s, &"player", READER, &"use")
	s.interaction_service.trigger_enter(&"player", EXIT_3)
	_assert_true(s.puzzle_service.is_solved(P3), "SOLVED")
	s = _reload(s, func(s2): _pz3(s2))
	_assert_false((s.id_registry.resolve(SGATE) as PlateLinkedGate).passage_blocked, "gate open after load")
	_assert_false((s.id_registry.resolve(BARRIER) as PoweredDoor).passage_blocked, "barrier open after load")
	free_session(s)


# =============================== CH1-PZ-004 R1 ======================================

const P4 := &"CH1-PZ-004"
const CAP := &"ch01.signal_control.surge_capacitor"
const BA := &"ch01.signal_control.breaker_a"
const BB := &"ch01.signal_control.breaker_b"
const BC := &"ch01.signal_control.breaker_c"
const GRID := &"ch01.signal_control.substation_grid"


func _pz4(s: GameSession) -> Array:
	var cap := SurgeCapacitor.new()
	cap.puzzle_id = P4
	spawn(s, cap, CAP, make_temporal(TemporalComponent.CAP_REWIND | TemporalComponent.CAP_FREEZE,
		["charge_state", "decay_ticks", "bus_powered"],
		[{"charge_state": &"charged", "decay_ticks": 240, "bus_powered": true}]))
	for id in [BA, BB]:
		var b := TimedBreaker.new()
		b.puzzle_id = P4
		b.capacitor_id = CAP
		spawn(s, b, id)
	var grid := SubstationGrid.new()
	grid.puzzle_id = P4
	grid.capacitor_id = CAP
	grid.breaker_a_id = BA
	grid.breaker_b_id = BB
	spawn(s, grid, GRID)
	var c := LampRingBreaker.new()
	c.puzzle_id = P4
	c.capacitor_id = CAP
	c.grid_id = GRID
	spawn(s, c, BC)
	c.feedback_requested.connect(func(key): feedback.append(key))
	_memory(s, &"ch01.signal_control.n20_engineer")
	return [cap, grid, c]


func _stabilize(s: GameSession) -> void:
	_req(s, &"player", CAP, &"rewind")
	_req(s, &"player", CAP, &"freeze")


func test_pz004_r01_breaker_c_browns_the_capacitor_out() -> void:
	var s := _session()
	var rig := _pz4(s)
	_stabilize(s)
	_assert_true(rig[0].is_stabilized(), "stabilized")
	_assert_true(_req(s, &"player", BC, &"use").ok, "pull C")
	_assert_eq([rig[0].charge_state, rig[0].bus_powered, rig[0].is_frozen()], [&"discharged", false, false], "browned out")
	_assert_eq(feedback, ["PZ004_FB_BROWNOUT"], "brown-out message")
	free_session(s)


func test_pz004_r02_dead_bus() -> void:
	var s := _session()
	var rig := _pz4(s)
	_assert_eq(_req(s, &"player", BC, &"use").reason, &"unpowered", "unpowered")
	_assert_eq(rig[2].feedback_key(&"unpowered"), "PZ004_FB_C_DEAD", "feedback key")
	free_session(s)


func test_pz004_r03_c_is_not_an_input() -> void:
	var s := _session()
	var rig := _pz4(s)
	_stabilize(s)
	_assert_true(_req(s, &"player", BA, &"use").ok, "A pulled")
	_req(s, &"player", BC, &"use")
	_assert_eq(_req(s, &"player", BB, &"use").reason, &"unpowered", "B has no power after the brown-out")
	s.sim_clock.step(1)
	_assert_false(rig[1].grid_online, "grid offline")
	free_session(s)


func test_pz004_r04_brownout_is_recoverable() -> void:
	var s := _session()
	var rig := _pz4(s)
	_stabilize(s)
	_req(s, &"player", BC, &"use")
	_assert_true(_req(s, &"player", CAP, &"rewind").ok, "rewind again")
	_assert_true(_req(s, &"player", CAP, &"freeze").ok, "freeze again")
	_assert_true(rig[0].is_stabilized(), "stabilized again")
	free_session(s)


func test_pz004_r05_c_does_nothing_once_the_grid_is_online() -> void:
	var s := _session()
	var rig := _pz4(s)
	_stabilize(s)
	_req(s, &"player", BA, &"use")
	_req(s, &"player", BB, &"use")
	_assert_true(rig[1].grid_online, "grid online")
	_assert_eq(_req(s, &"player", BC, &"use").reason, &"already_open", "already_open")
	_assert_true(rig[0].is_stabilized(), "capacitor untouched")
	free_session(s)


func test_pz004_r06_engineer_and_chart_name_c_as_the_lamp_ring() -> void:
	var text := _text()
	var mem: String = (text["MEM_N20_1"] + " " + text["MEM_N20_2"]).to_lower()
	var chart: String = text["DOC_BUS_CHART_BODY_1"].to_lower()
	for source in [mem, chart]:
		_assert_true(source.contains("lamp ring"), "names the lamp ring")
		_assert_true(source.contains("c:") or source.contains("breaker c") or source.contains("c is"), "names C")


# =============================== CH1-PZ-005 R1 ======================================

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
const LEVER_C := &"ch01.upper_vestibule.junction_lever_c"
const STANDBY := &"ch01.upper_vestibule.standby_plate_01"
const EXIT_5 := &"ch01.station_atrium.entry_trigger_atrium"


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
	_zone(s, STANDBY)
	var a := JunctionLever.new()
	a.puzzle_id = P5
	a.state_a = &"loop"
	a.state_b = &"uncoupled"
	a.pairs_to_b = [[VEST, &"door_west", VEST, &"door_east"], [VEST, &"door_north", NICHE, &"door_in"]]
	a.pairs_to_a = [[VEST, &"door_north", VEST, &"door_west"], [VEST, &"door_east", NICHE, &"door_in"]]
	a.requires_plate_id = STANDBY
	spawn(s, a, LEVER_A)
	var b := JunctionLever.new()
	b.puzzle_id = P5
	b.state_a = &"niche"
	b.state_b = &"atrium"
	b.pairs_to_b = [[VEST, &"door_north", ATRIUM, &"door_entry_south"], [NICHE, &"door_in", NICHE, &"door_out", false]]
	b.pairs_to_a = [[VEST, &"door_north", NICHE, &"door_in"], [NICHE, &"door_out", ATRIUM, &"door_entry_south", false]]
	b.requires_plate_id = STANDBY
	spawn(s, b, LEVER_B)
	var c := DeadRelay.new()
	c.puzzle_id = P5
	spawn(s, c, LEVER_C)
	var resetter := SpatialStateResetter.new()
	resetter.puzzle_id = P5
	resetter.initial_pairs = STATE_0.slice(1)
	spawn(s, resetter, &"ch01.upper_vestibule.spatial_resetter")
	_memory(s, &"ch01.upper_vestibule.n21_tourist")
	_anchor(s, &"ch01.upper_vestibule.reset_anchor_01", P5)
	_exit(s, EXIT_5, P5)
	return [a, b, g, c]


func _dest(g: SpatialGraph) -> Array:
	var d := g.get_destination(VEST, &"door_north")
	return [d["room_id"], d["door_id"]]


func test_pz005_r01_dead_relay_without_the_standby_plate() -> void:
	var s := _session()
	var rig := _pz5(s)
	_assert_eq(_req(s, &"player", LEVER_A, &"use").reason, &"unpowered", "unpowered")
	_assert_eq(rig[0].feedback_key(&"unpowered"), "PZ005_FB_UNPOWERED_RELAY", "feedback key")
	_assert_eq([rig[0].relay_state, _dest(rig[2])], [&"loop", [VEST, &"door_west"]], "State 0")
	free_session(s)


func test_pz005_r02_echo_on_the_plate_powers_the_relays() -> void:
	var s := _session()
	var rig := _pz5(s)
	s.interaction_service.trigger_enter(&"echo.0", STANDBY)
	_assert_true(_req(s, &"player", LEVER_A, &"use").ok, "A")
	_assert_true(_req(s, &"player", LEVER_B, &"use").ok, "B")
	_assert_eq(_dest(rig[2]), [ATRIUM, &"door_entry_south"], "State 2")
	_assert_true(&"echo.0" in (s.id_registry.resolve(STANDBY) as TriggerZone).occupants, "echo still on the plate")
	free_session(s)


func test_pz005_r02_relay_is_checked_at_pull_time() -> void:
	var s := _session()
	_pz5(s)
	s.interaction_service.trigger_enter(&"player", STANDBY)
	s.interaction_service.trigger_exit(&"player", STANDBY)   # pull a lever, then run to the plate: no
	_assert_eq(_req(s, &"player", LEVER_A, &"use").reason, &"unpowered", "plate empty at pull time")
	free_session(s)


func test_pz005_r04_order_rule_unchanged() -> void:
	var s := _session()
	_pz5(s)
	s.interaction_service.trigger_enter(&"echo.0", STANDBY)
	_assert_eq(_req(s, &"player", LEVER_B, &"use").reason, &"invalid_graph", "B first")
	free_session(s)


func test_pz005_r05_lever_c_is_a_dead_relay() -> void:
	var s := _session()
	var rig := _pz5(s)
	s.interaction_service.trigger_enter(&"echo.0", STANDBY)
	_assert_eq(_req(s, &"player", LEVER_C, &"use").reason, &"dead_relay", "dead_relay")
	_assert_eq(rig[3].feedback_key(&"dead_relay"), "PZ005_FB_DEAD_RELAY", "feedback key")
	_assert_eq(_dest(rig[2]), [VEST, &"door_west"], "graph unchanged")
	_assert_eq(_req(s, &"player", LEVER_C, &"rewind").reason, &"unsupported", "watch unsupported")
	free_session(s)


func test_pz005_r06_echo_reset_keeps_state_2() -> void:
	var s := _session()
	var rig := _pz5(s)
	s.interaction_service.trigger_enter(&"echo.0", STANDBY)
	_req(s, &"player", LEVER_A, &"use")
	_req(s, &"player", LEVER_B, &"use")
	s.interaction_service.trigger_enter(&"player", EXIT_5)
	_assert_true(s.puzzle_service.is_solved(P5), "SOLVED")
	s.interaction_service.trigger_exit(&"echo.0", STANDBY)   # the room change clears the echo
	s.echo_service.reset_echo()
	_req(s, &"player", &"ch01.upper_vestibule.reset_anchor_01", &"reset")
	_assert_eq(_dest(rig[2]), [ATRIUM, &"door_entry_south"], "State 2 stays")
	free_session(s)


func test_pz005_r07_empty_requires_plate_is_the_base_lever() -> void:
	var s := _session()
	var rig := _pz5(s)
	rig[0].requires_plate_id = &""
	_assert_true(_req(s, &"player", LEVER_A, &"use").ok, "base lever works without the plate")
	free_session(s)


func test_pz005_r08_memo_and_tourist_do_not_state_the_lever_order() -> void:
	var text := _text()
	for key in ["DOC_RELAY_MEMO_BODY_1", "MEM_N21_1", "MEM_N21_2"]:
		var low: String = text[key].to_lower()
		for word in ["first", "second", "lever a", "lever b", "west lever", "east lever"]:
			_assert_false(low.contains(word), "%s does not say '%s'" % [key, word])
