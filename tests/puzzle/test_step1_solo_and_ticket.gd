extends "res://tests/support/base_test.gd"

## Step 1 puzzle logic (TLF-054), commit A: CH1-SO-01 Last Departure, CH1-SO-02 Held Open and
## CH1-PZ-006 Last Ticket, against the given/when/then tests of design/ch01/puzzles/CH1-SO-01.md,
## CH1-SO-02.md and CH1-PZ-006.md that need no real input (standalone rooms with the spec IDs).
## Real-collider and real-input tests (TEST-SO01-05, TEST-SO02-04/05/08, TEST-PZ006-09, ...) are TLF-056.

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


func _journal_keys(s: GameSession) -> Array:
	return s.narrative_state.get_journal().map(func(e): return e["key"])


func _text() -> Dictionary:
	var out := {}
	var file := FileAccess.open(TEXT_CSV, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2 and not row[0].is_empty():
			out[row[0]] = row[1]
	return out


## Saves the session, frees it, and rebuilds the room in a fresh one (ADR-010 order: progress first,
## then the room, then the room's temporal histories).
func _reload(s: GameSession, build: Callable) -> GameSession:
	var store := _tree().root.get_node("SaveService")
	var data: Dictionary = store.capture(s, "ch01", "test")
	free_session(s)
	var s2 := _session()
	_assert_true(store.apply(s2, data)["ok"], "progress applied")
	build.call(s2)
	_assert_true(store.apply(s2, data)["ok"], "room histories applied")
	return s2


func _with_assist(on: bool) -> bool:
	var settings := _tree().root.get_node_or_null("Settings")
	var before: bool = settings.assist_extended_timing
	settings.assist_extended_timing = on
	return before


func _restore_assist(before: bool) -> void:
	_tree().root.get_node("Settings").assist_extended_timing = before


# =============================== CH1-SO-01 ==========================================

const SO1 := &"CH1-SO-01"
const SEL_LINE := &"ch01.arrival_platform.selector_line"
const SEL_PLAT := &"ch01.arrival_platform.selector_platform"
const SEL_CAR := &"ch01.arrival_platform.selector_car"
const LEVER := &"ch01.arrival_platform.release_lever"
const LOCK := &"ch01.arrival_platform.release_lock"
const PGATE := &"ch01.arrival_platform.platform_gate"
const STATUES_SO1 := [&"ch01.arrival_platform.n01_conductor", &"ch01.arrival_platform.n02_student",
	&"ch01.arrival_platform.n03_old_man", &"ch01.arrival_platform.n04_cleaner"]


func _so1(s: GameSession) -> Dictionary:
	var sels: Array = []
	for pair in [[SEL_LINE, "SO001_LINE"], [SEL_PLAT, "SO001_PLAT"], [SEL_CAR, "SO001_CAR"]]:
		var sel := SelectorSwitch.new()
		sel.puzzle_id = SO1
		sel.label_keys = PackedStringArray([pair[1] + "_0", pair[1] + "_1", pair[1] + "_2"])
		sels.append(spawn(s, sel, pair[0]))
	var lock := CodeLock.new()
	lock.puzzle_id = SO1
	var ids: Array[StringName] = [SEL_LINE, SEL_PLAT, SEL_CAR]
	lock.selector_ids = ids
	lock.answer = PackedInt32Array([1, 2, 1])
	lock.solved_journal_key = "JRN_SO001_SOLVED"
	spawn(s, lock, LOCK)
	var lever := ReleaseLever.new()
	lever.puzzle_id = SO1
	lever.lock_id = LOCK
	spawn(s, lever, LEVER)
	var gate := PoweredDoor.new()
	gate.puzzle_id = SO1
	gate.grid_id = LOCK
	gate.closed_reason = &"locked"
	gate.feedback_keys = {&"locked": "SO001_FB_GATE_SEALED"}
	spawn(s, gate, PGATE)
	for id in STATUES_SO1:
		_memory(s, id)
	return {"sels": sels, "lock": lock, "lever": lever, "gate": gate}


## Sets the selectors with `use`, the way the player does.
func _set_code(s: GameSession, code: Array) -> void:
	var ids := [SEL_LINE, SEL_PLAT, SEL_CAR]
	for i in 3:
		var sel := s.id_registry.resolve(ids[i]) as SelectorSwitch
		while sel.selector_position != code[i]:
			_req(s, &"player", ids[i], &"use")


func test_so01_01_correct_code_opens_the_gate_and_solves() -> void:
	var s := _session()
	var rig := _so1(s)
	_assert_eq(_req(s, &"player", PGATE, &"use").reason, &"locked", "gate sealed before")
	_assert_eq(rig["gate"].feedback_key(&"locked"), "SO001_FB_GATE_SEALED", "gate feedback key")
	_set_code(s, [1, 2, 1])
	_assert_true(_req(s, &"player", LEVER, &"use").ok, "lever accepts")
	_assert_false(rig["gate"].passage_blocked, "gate open")
	_assert_true(s.puzzle_service.is_solved(SO1), "SOLVED")
	_assert_true("JRN_SO001_SOLVED" in _journal_keys(s), "journal")
	_assert_eq(_req(s, &"player", LEVER, &"use").reason, &"already_open", "lever after solve")
	_assert_eq(_req(s, &"player", SEL_LINE, &"use").reason, &"already_open", "selector after solve")
	free_session(s)


func test_so01_02_initial_position_is_wrong() -> void:
	var s := _session()
	var rig := _so1(s)
	_assert_eq(_req(s, &"player", LEVER, &"use").reason, &"wrong_code", "wrong code")
	_assert_true(rig["gate"].passage_blocked, "gate closed")
	_assert_false(s.puzzle_service.is_solved(SO1), "unsolved")
	free_session(s)


func test_so01_03_every_wrong_code_gives_the_same_answer() -> void:
	var s := _session()
	var rig := _so1(s)
	var reasons := {}
	var keys := {}
	var tried := 0
	for a in 3:
		for b in 3:
			for c in 3:
				if [a, b, c] == [1, 2, 1]:
					continue
				_set_code(s, [a, b, c])
				var reason := _req(s, &"player", LEVER, &"use").reason
				reasons[reason] = true
				keys[rig["lever"].feedback_key(reason)] = true
				tried += 1
				s.sim_clock.step(360)   # wait out the lock-out
	_assert_eq(tried, 26, "26 wrong codes")
	_assert_eq(reasons.keys(), [&"wrong_code"], "one reason for all")
	_assert_eq(keys.keys(), ["SO001_FB_WRONG_CODE"], "one feedback key for all")
	_assert_true(rig["gate"].passage_blocked, "gate still closed")
	free_session(s)


func _check_lockout(window: int) -> void:
	var s := _session()
	var rig := _so1(s)
	s.sim_clock.step(25)                                     # t = 25
	_assert_eq(_req(s, &"player", LEVER, &"use").reason, &"wrong_code", "wrong code at t")
	_set_code(s, [1, 2, 1])                                   # selectors still turn during the lock-out
	s.sim_clock.step(window - 1)
	_assert_eq(_req(s, &"player", LEVER, &"use").reason, &"locked_out", "t + %d: locked out" % (window - 1))
	_assert_eq(rig["lever"].feedback_key(&"locked_out"), "SO001_FB_LOCKED_OUT", "lock-out key")
	s.sim_clock.step(1)
	_assert_true(_req(s, &"player", LEVER, &"use").ok, "t + %d: accepts again" % window)
	free_session(s)


func test_so01_04_lockout_360_ticks_assist_off() -> void:
	var before := _with_assist(false)
	_check_lockout(360)
	_restore_assist(before)


func test_so01_04_lockout_600_ticks_assist_on() -> void:
	var before := _with_assist(true)
	_check_lockout(600)
	_restore_assist(before)


func test_so01_lockout_is_not_started_by_prompt_queries() -> void:
	var s := _session()
	var rig := _so1(s)
	# The player asks can_interact() for prompts every frame: that must never lock the panel.
	for i in 5:
		_assert_eq(rig["lever"].can_interact(&"player", &"use"), &"wrong_code", "query %d" % i)
	_set_code(s, [1, 2, 1])
	_assert_true(_req(s, &"player", LEVER, &"use").ok, "no lock-out from queries")
	free_session(s)


func test_so01_06_answer_lives_only_in_trace_memories_and_labels() -> void:
	var text := _text()
	var mem: String = (text["MEM_N01_1"] + " " + text["MEM_N04_1"]).to_lower()
	for answer in ["hollow quay", "platform 3", "rear car"]:
		_assert_true(mem.contains(answer), "'%s' in MEM_N01/N04" % answer)
	_assert_eq([text["SO001_LINE_1"], text["SO001_PLAT_2"], text["SO001_CAR_1"]], ["HOLLOW QUAY", "PLAT 3", "REAR CAR"], "labels")
	for key in text.keys():
		if key.begins_with("DOC_") or key.begins_with("OP_"):
			var low: String = text[key].to_lower()
			for answer in ["hollow quay", "platform 3", "plat 3", "rear car"]:
				_assert_false(low.contains(answer), "%s does not contain '%s'" % [key, answer])


func test_so01_07_latest_statement_per_field_is_the_answer() -> void:
	var text := _text()
	var labels := {
		"line": [text["SO001_LINE_0"], text["SO001_LINE_1"], text["SO001_LINE_2"]],
		"plat": ["platform 1", "platform 2", "platform 3"],
		"car": [text["SO001_CAR_0"], text["SO001_CAR_1"], text["SO001_CAR_2"]],
	}
	var latest := {"line": [-1, -1], "plat": [-1, -1], "car": [-1, -1]}   # [minute, index]
	var stamp := RegEx.create_from_string("^\\[(\\d\\d):(\\d\\d)\\]")
	for n in range(1, 5):
		var line: String = text["MEM_N0%d_1" % n]
		var m := stamp.search(line)
		_assert_true(m != null, "MEM_N0%d_1 has a time stamp" % n)
		var minute := int(m.get_string(1)) * 60 + int(m.get_string(2))
		for field in labels.keys():
			for i in 3:
				if line.to_lower().contains(String(labels[field][i]).to_lower()) and minute > latest[field][0]:
					latest[field] = [minute, i]
	_assert_eq([latest["line"][1], latest["plat"][1], latest["car"][1]], [1, 2, 1], "latest statements = answer [1,2,1]")


func test_so01_08_statues_are_trace_only() -> void:
	var s := _session()
	_so1(s)
	for id in STATUES_SO1:
		_assert_eq(_req(s, &"player", id, &"use").reason, &"unsupported", "%s use" % id)
		_assert_eq(_req(s, &"player", id, &"rewind").reason, &"unsupported", "%s rewind" % id)
		_assert_eq(_req(s, &"player", id, &"freeze").reason, &"unsupported", "%s freeze" % id)
		_assert_true(_req(s, &"player", id, &"trace").ok, "%s trace" % id)
	for id in [SEL_LINE, LEVER, PGATE]:
		_assert_eq(_req(s, &"player", id, &"trace").reason, &"unsupported", "%s trace unsupported" % id)
		_assert_eq(_req(s, &"player", id, &"rewind").reason, &"unsupported", "%s rewind unsupported" % id)
	free_session(s)


func test_so01_09_latch_after_solved_survives_save_and_load() -> void:
	var s := _session()
	_so1(s)
	_set_code(s, [1, 2, 1])
	_req(s, &"player", LEVER, &"use")
	s = _reload(s, func(s2): _so1(s2))
	var gate := s.id_registry.resolve(PGATE) as PoweredDoor
	_assert_false(gate.passage_blocked, "gate open after load")
	_assert_eq(_req(s, &"player", LEVER, &"use").reason, &"already_open", "lever already_open")
	free_session(s)


func test_so01_lockout_is_not_saved() -> void:
	var s := _session()
	_so1(s)
	_req(s, &"player", LEVER, &"use")   # wrong code, lock-out starts
	s = _reload(s, func(s2): _so1(s2))
	_set_code(s, [1, 2, 1])
	_assert_true(_req(s, &"player", LEVER, &"use").ok, "a load clears the lock-out")
	free_session(s)


# =============================== CH1-SO-02 ==========================================

const SO2 := &"CH1-SO-02"
const HATCH := &"ch01.maintenance_bay.hatch_01"
const HPLATE := &"ch01.maintenance_bay.hatch_plate_01"
const BELL := &"ch01.maintenance_bay.bell_plate_01"
const HTHRESH := &"ch01.maintenance_bay.hatch_threshold"
const HEXIT := &"ch01.maintenance_bay.exit_trigger_hatch"
const TECH := &"ch01.maintenance_bay.n11_hatch_tech"
const TECH_FLAG := &"ch01.npc.n11.traced"


func _so2(s: GameSession) -> PlateLinkedGate:
	_zone(s, HPLATE)
	_zone(s, HTHRESH)
	var bell := DecoyPlate.new()
	bell.enter_text_key = "SO002_FB_BELL"
	spawn(s, bell, BELL)
	bell.feedback_requested.connect(func(key): feedback.append(key))
	var hatch := PlateLinkedGate.new()
	hatch.puzzle_id = SO2
	hatch.plate_id = HPLATE
	hatch.threshold_zone_id = HTHRESH
	hatch.safe_anchor_id = &"ch01.maintenance_bay.safe_anchor_west"
	hatch.feedback_keys = {&"locked": "SO002_FB_HATCH_WEIGHT", &"already_open": "SO002_FB_HATCH_HELD"}
	spawn(s, hatch, HATCH, make_temporal(TemporalComponent.CAP_FREEZE, ["gate_state", "passage_blocked"]))
	var exit := PuzzleCompletionZone.new()
	exit.puzzle_id = SO2
	exit.solved_journal_key = "JRN_SO002_SOLVED"
	spawn(s, exit, HEXIT)
	_memory(s, TECH, TECH_FLAG, "JRN_MEM_N11")
	_memory(s, &"ch01.maintenance_bay.hatch_residue")
	_unlock_on_flag(s, &"freeze", TECH_FLAG)
	return hatch


func test_so02_01_tracing_the_technician_unlocks_freeze() -> void:
	var s := _session()
	s.ability_unlocks.set_unlocked([&"trace", &"rewind"])
	_so2(s)
	_assert_false(s.ability_unlocks.is_unlocked(&"freeze"), "freeze locked before")
	_assert_true(_req(s, &"player", TECH, &"trace").ok, "trace the technician")
	_assert_true(s.ability_unlocks.is_unlocked(&"freeze"), "freeze unlocked")
	_assert_true(bool(s.narrative_state.get_flag(TECH_FLAG)), "n11 traced flag")
	free_session(s)


func test_so02_02_plate_opens_and_closes_the_hatch_on_the_same_tick() -> void:
	var s := _session()
	var hatch := _so2(s)
	_assert_eq(_req(s, &"player", HATCH, &"use").reason, &"locked", "closed hatch is locked")
	_assert_eq(hatch.feedback_key(&"locked"), "SO002_FB_HATCH_WEIGHT", "weight feedback")
	s.interaction_service.trigger_enter(&"player", HPLATE)
	_assert_false(hatch.passage_blocked, "open on the plate")
	s.interaction_service.trigger_exit(&"player", HPLATE)
	_assert_true(hatch.passage_blocked, "closed the moment the plate is vacated")
	free_session(s)


func test_so02_03_freeze_holds_the_hatch_open() -> void:
	var s := _session()
	var hatch := _so2(s)
	s.interaction_service.trigger_enter(&"player", HPLATE)
	_assert_true(_req(s, &"player", HATCH, &"freeze").ok, "freeze ok")
	_assert_true(hatch.is_frozen(), "frozen")
	s.interaction_service.trigger_exit(&"player", HPLATE)
	s.sim_clock.step(600)
	_assert_false(hatch.passage_blocked, "still open after 600 ticks")
	_assert_eq(_req(s, &"player", HATCH, &"use").reason, &"frozen", "use while frozen")
	s.interaction_service.trigger_enter(&"player", HEXIT)
	_assert_true(s.puzzle_service.is_solved(SO2), "walk through solves")
	_assert_true("JRN_SO002_SOLVED" in _journal_keys(s), "journal")
	free_session(s)


func test_so02_06_other_abilities_are_unsupported() -> void:
	var s := _session()
	_so2(s)
	for ability in [&"rewind", &"fast_forward", &"trace"]:
		_assert_eq(_req(s, &"player", HATCH, ability).reason, &"unsupported", String(ability))
	free_session(s)


func test_so02_07_bell_plate_is_a_decoy() -> void:
	var s := _session()
	var hatch := _so2(s)
	s.interaction_service.trigger_enter(&"player", BELL)
	_assert_true(hatch.passage_blocked, "hatch stays closed")
	_assert_eq(feedback, ["SO002_FB_BELL"], "bell feedback once")
	s.interaction_service.trigger_enter(&"echo.0", BELL)
	_assert_eq(feedback, ["SO002_FB_BELL"], "no message for an echo")
	free_session(s)


func test_so02_09_freeze_closed_is_recoverable() -> void:
	var s := _session()
	var hatch := _so2(s)
	_assert_true(_req(s, &"player", HATCH, &"freeze").ok, "freeze while closed")
	s.interaction_service.trigger_enter(&"player", HPLATE)
	_assert_true(hatch.passage_blocked, "frozen closed ignores the plate")
	s.interaction_service.trigger_exit(&"player", HPLATE)
	_assert_true(_req(s, &"player", HATCH, &"freeze").ok, "second freeze")
	_assert_false(hatch.is_frozen(), "unfrozen")
	s.interaction_service.trigger_enter(&"player", HPLATE)
	_assert_false(hatch.passage_blocked, "plate works again")
	free_session(s)


func test_so02_unfreeze_on_an_occupied_plate_stays_open() -> void:
	var s := _session()
	var hatch := _so2(s)
	_req(s, &"player", HATCH, &"freeze")                  # frozen closed
	s.interaction_service.trigger_enter(&"player", HPLATE)
	_req(s, &"player", HATCH, &"freeze")                  # unfreeze: follows the plate
	_assert_false(hatch.passage_blocked, "opens to the occupied plate")
	free_session(s)


func test_so02_10_clutch_moves_the_player_before_closing() -> void:
	var s := _session()
	var hatch := _so2(s)
	s.interaction_service.trigger_enter(&"player", HPLATE)
	_req(s, &"player", HATCH, &"freeze")
	s.interaction_service.trigger_exit(&"player", HPLATE)
	s.interaction_service.trigger_enter(&"player", HTHRESH)
	_assert_true(_req(s, &"player", HATCH, &"freeze").ok, "unfreeze")
	_assert_eq(relocations, [[&"player", &"ch01.maintenance_bay.safe_anchor_west"]], "moved to safe_anchor_west")
	_assert_true(hatch.passage_blocked, "closed")
	free_session(s)


func test_so02_11_latch_after_solved_survives_save_and_load() -> void:
	var s := _session()
	_so2(s)
	s.interaction_service.trigger_enter(&"player", HPLATE)
	_req(s, &"player", HATCH, &"freeze")
	s.interaction_service.trigger_exit(&"player", HPLATE)
	s.interaction_service.trigger_enter(&"player", HEXIT)
	s = _reload(s, func(s2): _so2(s2))
	var hatch := s.id_registry.resolve(HATCH) as PlateLinkedGate
	_assert_false(hatch.passage_blocked, "open after load")
	_assert_eq(_req(s, &"player", HATCH, &"freeze").reason, &"already_open", "freeze refused after SOLVED")
	_assert_false(hatch.passage_blocked, "still open")
	free_session(s)


func test_so02_frozen_open_state_survives_save_and_load_unsolved() -> void:
	var s := _session()
	_so2(s)
	s.interaction_service.trigger_enter(&"player", HPLATE)
	_req(s, &"player", HATCH, &"freeze")
	s.interaction_service.trigger_exit(&"player", HPLATE)
	s = _reload(s, func(s2): _so2(s2))
	var hatch := s.id_registry.resolve(HATCH) as PlateLinkedGate
	_assert_true(hatch.is_frozen(), "still frozen")
	_assert_false(hatch.passage_blocked, "still held open")
	free_session(s)


func test_so02_12_security_crossing_gate_defaults_unchanged() -> void:
	var s := _session()
	_zone(s, &"ch01.security_crossing.pressure_switch_01")
	var gate := PlateLinkedGate.new()
	gate.plate_id = &"ch01.security_crossing.pressure_switch_01"
	spawn(s, gate, &"ch01.security_crossing.security_gate_01")
	_assert_eq(_req(s, &"player", gate.object_id, &"freeze").reason, &"unsupported", "no FREEZE without the option")
	s.interaction_service.trigger_enter(&"player", gate.plate_id)
	_assert_false(gate.passage_blocked, "plate opens it")
	s.interaction_service.trigger_exit(&"player", gate.plate_id)
	_assert_true(gate.passage_blocked, "plate closes it")
	_assert_eq(relocations, [], "no clutch without a threshold zone")
	free_session(s)


# =============================== CH1-PZ-006 =========================================

const P6 := &"CH1-PZ-006"
const DIAL_LINE := &"ch01.concourse_west.dial_line"
const DIAL_PLAT := &"ch01.concourse_west.dial_platform"
const DIAL_TIME := &"ch01.concourse_west.dial_time"
const VALIDATOR := &"ch01.concourse_west.ticket_validator"
const STAFF_DOOR := &"ch01.concourse_west.staff_door"
const RESET_02 := &"ch01.concourse_west.reset_anchor_02"
const TARGET := [2, 3, 1]
## Passenger tickets as dial indexes [LINE, PLATFORM, TIME] (spec §1).
const TICKETS := {"MEM_N06_1": [1, 3, 3], "MEM_N07_1": [3, 2, 2], "MEM_N08_1": [2, 4, 4], "MEM_N09_1": [2, 3, 1]}


func _pz6(s: GameSession) -> Dictionary:
	var dials: Array = []
	for pair in [[DIAL_LINE, "PZ006_LINE"], [DIAL_PLAT, "PZ006_PLAT"], [DIAL_TIME, "PZ006_TIME"]]:
		var d := HistoryDial.new()
		d.puzzle_id = P6
		var labels := PackedStringArray()
		for i in 6:
			labels.append("%s_%d" % [pair[1], i])
		d.label_keys = labels
		dials.append(spawn(s, d, pair[0], make_temporal(TemporalComponent.CAP_REWIND, ["index"],
			[{"index": 0}, {"index": 1}, {"index": 2}, {"index": 3}, {"index": 4}])))
	var v := TicketValidator.new()
	v.puzzle_id = P6
	var ids: Array[StringName] = [DIAL_LINE, DIAL_PLAT, DIAL_TIME]
	v.dial_ids = ids
	v.target = PackedInt32Array(TARGET)
	v.solved_journal_key = "JRN_PZ006_SOLVED"
	spawn(s, v, VALIDATOR)
	v.feedback_requested.connect(func(key): feedback.append(key))
	var door := PoweredDoor.new()
	door.puzzle_id = P6
	door.grid_id = VALIDATOR
	door.closed_reason = &"locked"
	door.feedback_keys = {&"locked": "PZ006_FB_DOOR_WAITING"}
	spawn(s, door, STAFF_DOOR)
	var anchor := ResetAnchor.new()
	anchor.puzzle_id = P6
	anchor.refuse_when_solved = true
	spawn(s, anchor, RESET_02)
	for id in [&"n06_red_coat", &"n07_briefcase", &"n08_father", &"n09_teen"]:
		_memory(s, StringName("ch01.concourse_west." + id))
	return {"dials": dials, "validator": v, "door": door}


## From the newest entry (index 5): reset, then rewind each dial down to `indexes`.
func _set_dials(s: GameSession, indexes: Array) -> void:
	_req(s, &"player", RESET_02, &"use")
	var ids := [DIAL_LINE, DIAL_PLAT, DIAL_TIME]
	for i in 3:
		for k in 5 - int(indexes[i]):
			_req(s, &"player", ids[i], &"rewind")


func _indexes(rig: Dictionary) -> Array:
	return rig["dials"].map(func(d): return d.index)


func test_pz006_01_correct_ticket_solves() -> void:
	var s := _session()
	var rig := _pz6(s)
	_assert_eq(_req(s, &"player", STAFF_DOOR, &"use").reason, &"locked", "door waits")
	_assert_eq(rig["door"].feedback_key(&"locked"), "PZ006_FB_DOOR_WAITING", "door key")
	_set_dials(s, TARGET)
	_assert_eq(_indexes(rig), TARGET, "dials set by rewinds [3, 2, 4]")
	_assert_true(_req(s, &"player", VALIDATOR, &"use").ok, "ticket accepted")
	_assert_false(rig["door"].passage_blocked, "door open")
	_assert_true(s.puzzle_service.is_solved(P6), "SOLVED")
	_assert_true("JRN_PZ006_SOLVED" in _journal_keys(s), "journal")
	_assert_eq(feedback, ["PZ006_OK"], "accepted message")
	_assert_eq(_req(s, &"player", VALIDATOR, &"use").reason, &"already_open", "validator after")
	_assert_eq(_req(s, &"player", DIAL_LINE, &"rewind").reason, &"already_open", "dial after")
	free_session(s)


func test_pz006_02_rewind_steps_the_dial_back() -> void:
	var s := _session()
	var line: HistoryDial = _pz6(s)["dials"][0]
	_assert_eq(line.label_key(), "PZ006_LINE_5", "starts at the newest entry")
	for i in 3:
		_assert_true(_req(s, &"player", DIAL_LINE, &"rewind").ok, "rewind %d" % i)
	_assert_eq(line.capture_state(), {"index": 2}, "index 2")
	_assert_eq(_text()[line.label_key()], "ORCHARD GATE", "label ORCHARD GATE")
	_req(s, &"player", DIAL_LINE, &"rewind")
	_assert_eq(line.index, 1, "fourth rewind: index 1")
	_req(s, &"player", DIAL_LINE, &"rewind")
	_assert_eq(_req(s, &"player", DIAL_LINE, &"rewind").reason, &"no_history", "index 0: no_history")
	free_session(s)


func test_pz006_03_use_on_a_dial_is_jammed() -> void:
	var s := _session()
	var line: HistoryDial = _pz6(s)["dials"][0]
	_assert_eq(_req(s, &"player", DIAL_LINE, &"use").reason, &"jammed", "jammed")
	_assert_eq(line.feedback_key(&"jammed"), "PZ006_FB_DIAL_JAMMED", "dial key")
	_assert_eq(line.index, 5, "unchanged")
	for ability in [&"freeze", &"fast_forward", &"trace"]:
		_assert_eq(_req(s, &"player", DIAL_LINE, ability).reason, &"unsupported", String(ability))
	free_session(s)


func test_pz006_04_initial_state_is_wrong() -> void:
	var s := _session()
	var rig := _pz6(s)
	_assert_eq(_req(s, &"player", VALIDATOR, &"use").reason, &"invalid_ticket", "[5,5,5] rejected")
	_assert_eq(rig["validator"].feedback_key(&"invalid_ticket"), "PZ006_FB_NO_SUCH_TICKET", "key")
	_assert_true(rig["door"].passage_blocked, "door closed")
	free_session(s)


func test_pz006_05_every_wrong_triple_gives_the_same_answer() -> void:
	var s := _session()
	var rig := _pz6(s)
	var reasons := {}
	var tried := 0
	for a in 6:
		for b in 6:
			for c in 6:
				if [a, b, c] == TARGET:
					continue
				_set_dials(s, [a, b, c])
				reasons[_req(s, &"player", VALIDATOR, &"use").reason] = true
				tried += 1
	_assert_eq(tried, 215, "215 wrong triples")
	_assert_eq(reasons.keys(), [&"invalid_ticket"], "one reason for all, no lock-out")
	_assert_true(rig["door"].passage_blocked, "door still closed")
	_assert_false(s.puzzle_service.is_solved(P6), "unsolved")
	free_session(s)


func test_pz006_06_no_constant_triple_and_tickets_match_the_memories() -> void:
	for k in 6:
		_assert_true(TARGET != [k, k, k], "target is not [%d,%d,%d]" % [k, k, k])
	var text := _text()
	for key in TICKETS.keys():
		var ticket: Array = TICKETS[key]
		_assert_false(ticket[0] == ticket[1] and ticket[1] == ticket[2], "%s is not a constant triple" % key)
		# The memory names exactly this line, platform and time (labels from the generated text).
		var mem: String = text[key].to_lower()
		_assert_true(mem.contains(text["PZ006_LINE_%d" % ticket[0]].to_lower()), "%s line" % key)
		_assert_true(mem.contains(text["PZ006_PLAT_%d" % ticket[1]].to_lower().replace("plat ", "platform ")), "%s platform" % key)
		_assert_true(mem.contains(text["PZ006_TIME_%d" % ticket[2]]), "%s time" % key)
	_assert_eq(TICKETS["MEM_N09_1"], TARGET, "the teenager's ticket is the target")


func test_pz006_07_the_fathers_ticket_is_rejected() -> void:
	var s := _session()
	var rig := _pz6(s)
	_set_dials(s, [2, 4, 4])
	_assert_eq(_req(s, &"player", VALIDATOR, &"use").reason, &"invalid_ticket", "father rejected")
	_assert_true(rig["door"].passage_blocked, "door closed")
	free_session(s)


func test_pz006_08_ticket_values_live_only_in_trace_memories() -> void:
	var text := _text()
	for key in ["DOC_TICKET_TERMS_BODY_1", "DOC_EVAC_NOTICE_BODY_1"]:
		var low: String = text[key].to_lower()
		for value in ["plat 1", "platform 1", "23:55"]:
			_assert_false(low.contains(value), "%s does not contain '%s'" % [key, value])
	_assert_true(text["MEM_N09_1"].contains("23:55") and text["MEM_N09_1"].to_lower().contains("platform 1"), "teen memory has the values")


func test_pz006_10_reset_restores_index_5_and_the_history() -> void:
	var s := _session()
	var rig := _pz6(s)
	_set_dials(s, [0, 3, 1])
	_assert_true(_req(s, &"player", RESET_02, &"use").ok, "reset")
	_assert_eq(_indexes(rig), [5, 5, 5], "all at index 5")
	for d in rig["dials"]:
		var t: TemporalComponent = d.get_temporal()
		_assert_eq([t.get_history_size(), t.get_history_cursor()], [6, 5], "5 earlier entries + tick 0")
	free_session(s)


func test_pz006_11_latch_after_solved_survives_save_and_load() -> void:
	var s := _session()
	_pz6(s)
	_set_dials(s, TARGET)
	_req(s, &"player", VALIDATOR, &"use")
	s = _reload(s, func(s2): _pz6(s2))
	var door := s.id_registry.resolve(STAFF_DOOR) as PoweredDoor
	_assert_false(door.passage_blocked, "door open after load")
	_assert_eq(_req(s, &"player", RESET_02, &"use").reason, &"already_open", "reset console refuses")
	_assert_eq((s.id_registry.resolve(DIAL_TIME) as HistoryDial).index, 1, "dials kept")
	free_session(s)


func test_pz006_12_save_keeps_the_dial_history() -> void:
	var s := _session()
	_pz6(s)
	for i in 3:
		_req(s, &"player", DIAL_TIME, &"rewind")
	s = _reload(s, func(s2): _pz6(s2))
	var dial := s.id_registry.resolve(DIAL_TIME) as HistoryDial
	_assert_eq([dial.index, dial.get_temporal().get_history_cursor()], [2, 2], "index 2 restored")
	_assert_true(_req(s, &"player", DIAL_TIME, &"rewind").ok, "one more rewind")
	_assert_eq(dial.index, 1, "index 1")
	free_session(s)


func test_pz006_13_no_hidden_prerequisite() -> void:
	var s := _session()
	var rig := _pz6(s)
	# No passenger traced and no sign read: the dials and the validator behave the same.
	_set_dials(s, TARGET)
	_assert_true(_req(s, &"player", VALIDATOR, &"use").ok, "accepted without any flag")
	_assert_false(rig["door"].passage_blocked, "door open")
	free_session(s)


func test_pz006_14_rewind_needs_the_unlock() -> void:
	var s := _session()
	s.ability_unlocks.set_unlocked([&"trace"])
	_pz6(s)
	_assert_false(s.ability_unlocks.is_unlocked(&"rewind"), "rewind locked until the courier is traced")
	free_session(s)
