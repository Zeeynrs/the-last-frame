extends "res://tests/support/ch01_real_input.gd"

## TLF-056 / ADR-022 directive P0: save and load around The Forgotten Sequence (CH1-PZ-004), cases
## F1-F4 of TLF-055 D3. Saves go through the in-game checkpoint ch01.cp.signal_control (288,208)
## with real input (walk out of the zone and back in); loads go through the Continue path
## (RoomRouter.restore_from_save on the autosave just written). After every load:
## is_solved(CH1-PZ-004) == grid_online == not vestibule_door.passage_blocked (no desync), no echo
## and no breaker engaged without an actor, and the puzzle is still solvable (or still solved).
## RED: import_history drops is_frozen (scratch break in TemporalComponent): F1 fails on the
## frozen capacitor.

const R6 := &"ch01.signal_control"
const R7 := &"ch01.upper_vestibule"
const BEFORE_R6: Array = [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-PZ-006", &"CH1-SO-02", &"CH1-PZ-002", &"CH1-PZ-003"]
const CHECKPOINT := &"ch01.cp.signal_control"
const ZONE := Vector2(288, 208)        # checkpoint (28 x 16) and the south door spawn
const OUTSIDE := Vector2(322, 218)     # south lane, clear of the zone
## PZ-004 Z-route waypoints (design/ch01/ROOM_GRAPH.md 5.4).
const W0 := Vector2(176, 152)   # breaker A spot, south lane
const W1 := Vector2(400, 232)   # south railing crossover (east end)
const W2 := Vector2(304, 104)   # north railing crossover (west end)
const W3 := Vector2(528, 184)   # breaker B spot, north lane

var capacitor: SurgeCapacitor
var breaker_a: TimedBreaker
var breaker_b: TimedBreaker
var grid: SubstationGrid
var door: Node


func _init() -> void:
	timeout_frames = 3600


func _start() -> bool:
	if not await start_at(R6, &"door_entry_south", BEFORE_R6, [FLAG_REWIND, FLAG_FREEZE, FLAG_ECHO]):
		return false
	_bind()
	return true


func _bind() -> void:
	capacitor = resolve(&"ch01.signal_control.surge_capacitor") as SurgeCapacitor
	breaker_a = resolve(&"ch01.signal_control.breaker_a") as TimedBreaker
	breaker_b = resolve(&"ch01.signal_control.breaker_b") as TimedBreaker
	grid = resolve(&"ch01.signal_control.substation_grid") as SubstationGrid
	door = resolve(&"ch01.signal_control.vestibule_door")


func _stabilize() -> bool:
	if not await use_watch(&"rewind", capacitor, func() -> bool: return capacitor.bus_powered, "capacitor charged after Rewind"):
		return false
	return await use_watch(&"freeze", capacitor, func() -> bool: return capacitor.is_stabilized(), "capacitor stabilized")


## At W0: start recording, pull breaker A, stop recording.
func _record_pull_a() -> bool:
	if not await walk_to(player, "signal control -> W0 (breaker A)", W0):
		return false
	if not await select_ability(&"echo"):
		return false
	await tap(&"watch")
	if not _assert_eq(session.echo_service.state, EchoService.State.RECORDING, "recording at W0"):
		return false
	_assert_eq(player.current_target, breaker_a, "breaker A is the interact target at W0")
	await tap(&"interact")
	_assert_true(breaker_a.is_engaged(), "breaker A pulled while recording")
	await tap(&"watch")
	return _assert_eq(session.echo_service.state, EchoService.State.READY, "recording stopped")


## Step 2 with a recorded echo: the Z-route to W3, replay, pull B, walk to the exit trigger.
func _finish_with_echo(label: String) -> bool:
	for leg in [W1, W2, W3]:
		if not await walk_to(player, "%s: Z-route -> %s" % [label, leg], leg):
			return false
	_assert_eq(player.current_target, breaker_b, "%s: breaker B is the interact target at W3" % label)
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return breaker_a.is_engaged(), 120), "%s: the echo pulls A" % label):
		return false
	await tap(&"interact")
	if not _assert_true(await until(func() -> bool: return grid.grid_online, 10), "%s: grid online" % label):
		return false
	# Down the middle of the north lane first: the straight line W3 -> trigger touches door_exit_north.
	if not await walk_to(player, "%s: -> north lane middle" % label, Vector2(472, 168)):
		return false
	if not await walk_to(player, "%s: -> exit_trigger_vestibule" % label, Vector2(428, 146), func() -> bool: return is_solved(&"CH1-PZ-004")):
		return false
	return _assert_true(is_solved(&"CH1-PZ-004"), "%s: PZ-004 SOLVED" % label)


## From the Continue respawn (safe_anchor_center, middle lane) to W0 in the south lane.
func _middle_to_w0() -> bool:
	# W1 lies on the south railing's extension: step south of it before heading west.
	for point in [W1, Vector2(404, 244), Vector2(340, 232), W0]:
		if not await walk_to(player, "middle lane -> %s" % point, point):
			return false
	return true


func _save() -> bool:
	return await save_at_checkpoint(CHECKPOINT, ZONE, OUTSIDE)


## The checks after every load (TLF-055 D3).
func _after_load(label: String, solved: bool) -> void:
	_bind()
	_assert_eq(router.current_room_id, R6, "%s: Continue loads signal control" % label)
	var puzzle_solved := is_solved(&"CH1-PZ-004")
	_assert_eq(puzzle_solved, solved, "%s: PZ-004 %s" % [label, "SOLVED" if solved else "UNSOLVED"])
	_assert_eq(grid.grid_online, puzzle_solved, "%s: grid_online == solved (no desync)" % label)
	_assert_eq(not door.passage_blocked, puzzle_solved, "%s: vestibule door open == solved (no desync)" % label)
	_assert_eq(session.echo_service.state, EchoService.State.IDLE, "%s: no echo after the load" % label)
	if not solved:
		_assert_false(breaker_a.is_engaged() or breaker_b.is_engaged(), "%s: no breaker engaged without an actor" % label)
	var def := load("res://data/puzzles/ch01/CH1-PZ-004.tres") as PuzzleDef
	_assert_eq(tr(def.title_key), "The Forgotten Sequence", "%s: hint title" % label)


## F1: capacitor stabilised, echo recorded but not replayed -> load: capacitor charged and frozen,
## no echo, breakers open, grid offline; re-record and replay -> SOLVED.
func test_f1_save_with_a_recorded_echo() -> void:
	if not await _start():
		stop()
		return
	if not (await _stabilize() and await _record_pull_a()):
		stop()
		return
	if not await _save():
		stop()
		return
	if not await continue_from_autosave():
		stop()
		return
	_after_load("F1", false)
	_assert_true(capacitor.bus_powered, "F1: capacitor still charged")
	_assert_true(capacitor.is_frozen(), "F1: capacitor still frozen")
	if not (await _middle_to_w0() and await _record_pull_a()):
		stop()
		return
	await _finish_with_echo("F1")
	stop()


## F2: saved while the echo replays (breaker A engaged by the echo) -> load as F1; solvable.
func test_f2_save_while_the_echo_replays() -> void:
	if not await _start():
		stop()
		return
	if not (await _stabilize() and await _record_pull_a()):
		stop()
		return
	if not await walk_to(player, "W0 -> outside the checkpoint", OUTSIDE):
		stop()
		return
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return breaker_a.is_engaged(), 30), "F2: the echo pulls A"):
		stop()
		return
	var written := [false, false, -1]
	var on_cp := func(id: StringName, error: Error) -> void:
		if id == CHECKPOINT and error == OK and not written[0]:
			written[0] = true
			written[1] = breaker_a.is_engaged()
			written[2] = session.echo_service.state
	router.checkpoint_reached.connect(on_cp)
	await walk_to(player, "F2: into the checkpoint", ZONE, func() -> bool: return written[0])
	router.checkpoint_reached.disconnect(on_cp)
	if not _assert_true(written[0], "F2: autosave written"):
		stop()
		return
	_assert_true(written[1], "F2: breaker A was engaged by the echo when the save was written")
	_assert_true(written[2] == EchoService.State.PLAYING or written[2] == EchoService.State.HOLDING, "F2: the echo was out (state %s)" % written[2])
	if not await continue_from_autosave():
		stop()
		return
	_after_load("F2", false)
	_assert_true(capacitor.is_stabilized(), "F2: capacitor still stabilized")
	if not (await _middle_to_w0() and await _record_pull_a()):
		stop()
		return
	await _finish_with_echo("F2")
	stop()


## F3: saved after a brown-out from breaker C -> load: capacitor discharged and not frozen,
## Rewind works again; re-stabilise and solve.
func test_f3_save_after_a_brownout() -> void:
	if not await _start():
		stop()
		return
	if not await _stabilize():
		stop()
		return
	var breaker_c := resolve(&"ch01.signal_control.breaker_c")
	if not await walk_to(player, "signal control -> W0", W0):
		stop()
		return
	# C stands north of the south railing; the walk towards its spec spot (240,120) slides along the
	# railing until C is the interact target.
	if not await use_at(Vector2(240, 120), breaker_c, "signal control -> breaker C"):
		stop()
		return
	if not _assert_true(await until(func() -> bool: return not capacitor.bus_powered, 10), "F3: brown-out"):
		stop()
		return
	if not await _save():
		stop()
		return
	if not await continue_from_autosave():
		stop()
		return
	_after_load("F3", false)
	_assert_false(capacitor.bus_powered, "F3: capacitor discharged after the load")
	_assert_false(capacitor.is_frozen(), "F3: capacitor not frozen after the load")
	if not await _stabilize():
		stop()
		return
	if not (await _middle_to_w0() and await _record_pull_a()):
		stop()
		return
	await _finish_with_echo("F3")
	stop()


## F4: saved after SOLVED -> load: SOLVED, door open, C answers already_open, the hint reports
## solved; walk north into the upper vestibule.
func test_f4_save_after_solved() -> void:
	if not await _start():
		stop()
		return
	if not (await _stabilize() and await _record_pull_a()):
		stop()
		return
	if not await _finish_with_echo("F4 first solve"):
		stop()
		return
	# Back to the south lane: around the north railing's west end, then the south railing's east end.
	for point in [W2, Vector2(352, 176), W1, Vector2(404, 244), Vector2(340, 232)]:
		if not await walk_to(player, "north lane -> south lane %s" % point, point):
			stop()
			return
	if not await _save():
		stop()
		return
	if not await continue_from_autosave():
		stop()
		return
	_after_load("F4", true)
	_assert_eq(session.hint_service.request_hint(&"CH1-PZ-004").get("reason"), &"already_solved", "F4: the hint reports solved")
	var breaker_c := resolve(&"ch01.signal_control.breaker_c")
	if not await _middle_to_w0():
		stop()
		return
	if not await use_at(Vector2(240, 120), breaker_c, "F4: breaker C"):
		stop()
		return
	await physics_frames(2)
	var refusal := last_refusal(breaker_c)
	_assert_true(not refusal.is_empty() and refusal[2] == &"already_open", "F4: C answers already_open (%s)" % [refusal])
	for point in [W1, W2, Vector2(472, 168)]:
		if not await walk_to(player, "F4: -> north lane %s" % point, point):
			stop()
			return
	if not await walk_to(player, "F4: -> door_exit_north", Vector2(448, 128), in_room(R7)):
		stop()
		return
	_assert_eq(router.current_room_id, R7, "F4: walked north into the upper vestibule")
	stop()
