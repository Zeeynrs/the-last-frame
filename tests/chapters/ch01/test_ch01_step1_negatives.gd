extends "res://tests/support/ch01_real_input.gd"

## TLF-056: one or more real-input negative tests per Step 1 puzzle (each spec's shortcut table,
## TLF-055 D4). Input actions and physics frames only; the start state is setup (earlier puzzles
## marked SOLVED, unlock flags set, the router entering the room), never part of the check.
## Each test was seen RED against the scratch break named in its comment (TLF-056 handoff).

const R1 := &"ch01.arrival_platform"
const R2 := &"ch01.concourse_west"
const R3 := &"ch01.maintenance_bay"
const R4 := &"ch01.security_crossing"
const R6 := &"ch01.signal_control"
const R7 := &"ch01.upper_vestibule"
const BEFORE_R2: Array = [&"CH1-SO-01"]
const BEFORE_R3: Array = [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-PZ-006"]
const BEFORE_R4: Array = [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-PZ-006", &"CH1-SO-02", &"CH1-PZ-002"]
const BEFORE_R6: Array = [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-PZ-006", &"CH1-SO-02", &"CH1-PZ-002", &"CH1-PZ-003"]
const BEFORE_R7: Array = [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-PZ-006", &"CH1-SO-02", &"CH1-PZ-002", &"CH1-PZ-003", &"CH1-PZ-004"]
const ALL_FLAGS: Array = [FLAG_REWIND, FLAG_FREEZE, FLAG_ECHO]


func _init() -> void:
	timeout_frames = 3600


# --- CH1-SO-01 -----------------------------------------------------------------------------

## SO01-05: the closed platform gate holds. 300 ticks walking at the east aperture from three
## sides never reach door_exit_east. RED: platform_gate/Blocker removed.
func test_so01_closed_gate_holds_300_ticks() -> void:
	if not await start_at(R1, &""):
		stop()
		return
	var gate := resolve(&"ch01.arrival_platform.platform_gate") as PoweredDoor
	_assert_true(gate.passage_blocked, "gate closed")
	for start in [Vector2(688, 320), Vector2(712, 300), Vector2(684, 342)]:
		# Approach spots near the blocker: a slide along it is fine, the push below is the check.
		await walk_to(player, "arrival -> approach %s" % start, start, Callable(), 300, true)
		await push_for([Vector2(720, 328), Vector2(732, 334)], 100, in_room(R2))
		if not _assert_eq(router.current_room_id, R1, "the closed gate holds from %s" % start):
			break
	_assert_false(is_solved(&"CH1-SO-01"), "SO-01 still UNSOLVED")
	stop()


## SO01-04 on real input: a wrong code locks the lever for 360 ticks; a pull just before the end
## is refused (locked_out), the first pull after it with the right code solves.
## RED: release_lock lockout_base_ticks = 0.
func test_so01_lockout_holds_until_it_ends() -> void:
	if not await start_at(R1, &""):
		stop()
		return
	var lever := resolve(&"ch01.arrival_platform.release_lever")
	var lock := resolve(&"ch01.arrival_platform.release_lock") as CodeLock
	var clock := session.sim_clock
	if not await walk_to(player, "arrival -> north of the gate", Vector2(712, 300)):
		stop()
		return
	if not await use_at(Vector2(736, 304), lever, "arrival -> release_lever (wrong code)"):
		stop()
		return
	await physics_frames(1)
	var wrong := last_refusal(lever)
	if not _assert_true(not wrong.is_empty() and wrong[2] == &"wrong_code", "selectors untouched: wrong_code (%s)" % [wrong]):
		stop()
		return
	var ends: int = lock.lockout_until_tick
	_assert_eq(ends - int(wrong[3]), 360, "lock-out of 360 ticks from the wrong pull")
	for row in [[&"selector_line", Vector2(624, 248), 1], [&"selector_platform", Vector2(656, 264), 2],
			[&"selector_car", Vector2(688, 280), 1]]:
		var selector := resolve(StringName("ch01.arrival_platform." + String(row[0]))) as SelectorSwitch
		for i in row[2]:
			if not await use_at(row[1], selector, "arrival -> %s" % row[0]):
				stop()
				return
	if not await walk_to(player, "arrival -> release_lever", Vector2(736, 304), targets(lever)):
		stop()
		return
	_assert_true(clock.tick < ends - 4, "back at the lever before the lock-out ends (tick %d, ends %d)" % [clock.tick, ends])
	await until(func() -> bool: return clock.tick >= ends - 3, 600)
	await tap(&"interact")
	var late := last_refusal(lever)
	_assert_true(late.size() == 4 and late[2] == &"locked_out" and int(late[3]) < ends,
		"right code just before the end is refused locked_out (%s, ends %d)" % [late, ends])
	_assert_false(is_solved(&"CH1-SO-01"), "not solved during the lock-out")
	await until(func() -> bool: return clock.tick >= ends, 10)
	await tap(&"interact")
	_assert_true(await until(func() -> bool: return is_solved(&"CH1-SO-01"), 10), "first pull after the lock-out solves SO-01")
	stop()


# --- CH1-PZ-001 ----------------------------------------------------------------------------

## PZ-001: with the conduit still fallen, Rewind on the gate is refused (pinned) and 300 ticks
## walking at the turnstile never reach exit_trigger_concourse (R07). RED: turnstile pinned_by = "".
func test_pz001_gate_pinned_and_turnstile_holds() -> void:
	if not await start_at(R2, &"door_entry_west", BEFORE_R2, [FLAG_REWIND]):
		stop()
		return
	var turnstile := resolve(&"ch01.concourse_west.turnstile_gate") as TurnstileGate
	for point in [Vector2(160, 168), Vector2(298, 198)]:
		if not await walk_to(player, "concourse -> gate Rewind spot", point):
			stop()
			return
	if not await select_ability(&"rewind"):
		stop()
		return
	await physics_frames(1)
	_assert_eq(player.pocket_watch.current_target, turnstile, "Rewind targets the turnstile")
	await tap(&"watch")
	await physics_frames(2)
	var refusal := last_refusal(turnstile)
	_assert_true(not refusal.is_empty() and refusal[2] == &"pinned", "Rewind on the pinned gate refused: pinned (%s)" % [refusal])
	_assert_true(turnstile.passage_blocked, "turnstile still blocked")
	await push_for([Vector2(320, 200), Vector2(352, 208)], 300, func() -> bool: return is_solved(&"CH1-PZ-001"))
	_assert_false(is_solved(&"CH1-PZ-001"), "300 ticks at the turnstile: PZ-001 still UNSOLVED (player at %s)" % player.global_position)
	stop()


# --- CH1-PZ-006 ----------------------------------------------------------------------------

## PZ006-09: the staff door holds while the dials are wrong. 300 ticks at the east aperture never
## reach door_exit_east. RED: staff_door/Blocker removed.
func test_pz006_staff_door_holds_300_ticks() -> void:
	if not await start_at(R2, &"door_entry_west", BEFORE_R2 + [&"CH1-PZ-001"], [FLAG_REWIND]):
		stop()
		return
	var door := resolve(&"ch01.concourse_west.staff_door") as PoweredDoor
	_assert_true(door.passage_blocked, "staff door closed")
	if not await walk_to(player, "concourse -> through the turnstile", Vector2(352, 208)):
		stop()
		return
	for start in [Vector2(608, 328), Vector2(630, 324), Vector2(612, 360)]:
		# Approach spots near the blocker: a slide along it is fine, the push below is the check.
		await walk_to(player, "concourse -> approach %s" % start, start, Callable(), 300, true)
		await push_for([Vector2(640, 352), Vector2(652, 358)], 100, in_room(R3))
		if not _assert_eq(router.current_room_id, R2, "the staff door holds from %s" % start):
			break
	_assert_false(is_solved(&"CH1-PZ-006"), "PZ-006 still UNSOLVED")
	stop()


# --- CH1-SO-02 -----------------------------------------------------------------------------

## SO02-04: the plate opens the hatch only while it is held. Stepping off and running for the hatch
## without Freeze never reaches exit_trigger_hatch in 300 ticks. RED: hatch_01/Blocker removed.
func test_so02_hatch_closes_without_freeze() -> void:
	if not await start_at(R3, &"door_entry_west", BEFORE_R3, [FLAG_REWIND, FLAG_FREEZE]):
		stop()
		return
	var hatch := resolve(&"ch01.maintenance_bay.hatch_01") as PlateLinkedGate
	if not await walk_to(player, "bay -> hatch plate", Vector2(320, 160), func() -> bool: return not hatch.passage_blocked):
		stop()
		return
	_assert_false(hatch.passage_blocked, "the plate opens the hatch")
	await push_for([Vector2(352, 124), Vector2(384, 124), Vector2(385, 172), Vector2(400, 160)], 300,
		func() -> bool: return is_solved(&"CH1-SO-02"))
	_assert_true(hatch.passage_blocked, "the hatch closed when the plate was left")
	_assert_false(is_solved(&"CH1-SO-02"), "300 ticks without Freeze: SO-02 still UNSOLVED (player at %s)" % player.global_position)
	stop()


## SO02-05: the bulkhead is sealed apart from the hatch. Walking at it for 150 ticks from five
## spots along its west side (both segments, the closed hatch, the north end) never gets east of it.
## RED: one Bulkhead segment deleted.
func test_so02_bulkhead_sealed() -> void:
	if not await start_at(R3, &"door_entry_west", BEFORE_R3, [FLAG_REWIND, FLAG_FREEZE]):
		stop()
		return
	# Bulkhead (432,120)-(396,138) and (372,150)-(176,248) lie on x + 2y = 672; "east" = the capsule
	# centre (y - 4) past it.
	var east := func() -> bool: return player.global_position.x + 2.0 * (player.global_position.y - 4.0) > 680.0
	# [approach waypoints, push target]; the north spots are reached through the corridor above N-11.
	for row in [[[Vector2(314, 172)], Vector2(326, 194)], [[Vector2(338, 156)], Vector2(354, 178)],
			[[Vector2(352, 124), Vector2(384, 124)], Vector2(390, 152)],
			[[Vector2(352, 124), Vector2(396, 122)], Vector2(412, 144)],
			[[Vector2(352, 124), Vector2(408, 118)], Vector2(426, 138)]]:
		for point in row[0]:
			if not await walk_to(player, "bay -> west of the bulkhead %s" % point, point):
				stop()
				return
		var from := player.global_position
		await push_for([row[1]], 150, east)
		if not _assert_false(east.call(), "the bulkhead holds from %s towards %s (player at %s)" % [from, row[1], player.global_position]):
			break
	stop()


## SO02-07 / SO02-08: the bell plate is a decoy (the hatch stays shut and Freeze has no hatch
## target from it), and the bay checkpoint respawns west of the bulkhead at safe_anchor_entry.
## RED: hatch_01 plate_id = bell_plate_01 / checkpoint spawn_anchor_id = safe_anchor_west.
func test_so02_bell_decoy_and_checkpoint_spawn() -> void:
	if not await start_at(R3, &"door_entry_west", BEFORE_R3, [FLAG_REWIND, FLAG_FREEZE]):
		stop()
		return
	var hatch := resolve(&"ch01.maintenance_bay.hatch_01") as PlateLinkedGate
	if not await walk_to(player, "bay -> bell plate", Vector2(272, 168)):
		stop()
		return
	await physics_frames(2)
	_assert_true(hatch.passage_blocked, "the bell plate does not open the hatch")
	if await select_ability(&"freeze"):
		await physics_frames(1)
		_assert_ne(player.pocket_watch.current_target, hatch, "no Freeze on the hatch from the bell plate")
	# The checkpoint is at (5,5) (320, 144): walk through it to record the autosave.
	if not await walk_to(player, "bell plate -> checkpoint", Vector2(320, 144)):
		stop()
		return
	await physics_frames(2)
	if not await continue_from_autosave():
		stop()
		return
	_assert_eq(router.current_room_id, R3, "Continue loads the bay")
	_assert_true(player.global_position.distance_to(Vector2(336, 136)) < 1.0,
		"Continue respawns at safe_anchor_entry (336,136), west of the bulkhead (at %s)" % player.global_position)
	stop()


# --- CH1-PZ-002 ----------------------------------------------------------------------------

## R03 + R04: without Freeze the inner shutter refuses Rewind (unanchored) and PZ-002 stays
## UNSOLVED for 600 ticks; a late Freeze from the pocket then solves it.
## RED: inner_shutter requires_gear_frozen = false.
func test_pz002_inner_shutter_needs_the_gear_frozen() -> void:
	if not await start_at(R3, &"door_entry_west", BEFORE_R3 + [&"CH1-SO-02"], [FLAG_REWIND, FLAG_FREEZE]):
		stop()
		return
	var shutter := resolve(&"ch01.maintenance_bay.fire_shutter") as FireShutter
	var gear := resolve(&"ch01.maintenance_bay.counterweight_gear") as CounterweightGear
	var inner := resolve(&"ch01.maintenance_bay.inner_shutter") as FireShutter
	for point in [Vector2(352, 124), Vector2(384, 124), Vector2(384, 172), Vector2(488, 188)]:
		if not await walk_to(player, "bay -> fire shutter Rewind spot", point):
			stop()
			return
	if not await use_watch(&"rewind", shutter, func() -> bool: return not shutter.passage_blocked, "fire shutter raised"):
		stop()
		return
	for point in [Vector2(512, 210), Vector2(512, 240), Vector2(544, 240)]:
		if not await walk_to(player, "bay -> pocket (no Freeze)", point):
			stop()
			return
	if not await select_ability(&"rewind"):
		stop()
		return
	await physics_frames(1)
	_assert_eq(player.pocket_watch.current_target, inner, "Rewind targets the inner shutter from the pocket")
	await tap(&"watch")
	await physics_frames(2)
	var refusal := last_refusal(inner)
	_assert_true(not refusal.is_empty() and refusal[2] == &"unanchored", "R03: inner shutter refused: unanchored (%s)" % [refusal])
	_assert_true(inner.passage_blocked, "R03: inner shutter still closed")
	await push_for([Vector2(560, 250), Vector2(576, 256)], 600, func() -> bool: return is_solved(&"CH1-PZ-002"))
	_assert_false(is_solved(&"CH1-PZ-002"), "R03: 600 ticks without Freeze: PZ-002 still UNSOLVED")
	_assert_true(shutter.passage_blocked, "R04 start: the fire shutter has closed again")
	# R04: late Freeze from (544,240), Rewind the inner shutter, walk to (576,256).
	if not await walk_to(player, "pocket -> (544,240)", Vector2(544, 240)):
		stop()
		return
	if not await use_watch(&"freeze", gear, func() -> bool: return gear.is_frozen(), "R04: gear frozen from the pocket"):
		stop()
		return
	if not await use_watch(&"rewind", inner, func() -> bool: return not inner.passage_blocked, "R04: inner shutter raised"):
		stop()
		return
	if not await walk_to(player, "pocket -> exit_trigger_east_02", Vector2(576, 256), func() -> bool: return is_solved(&"CH1-PZ-002")):
		stop()
		return
	_assert_true(is_solved(&"CH1-PZ-002"), "R04: late Freeze solves PZ-002")
	stop()


# --- CH1-PZ-003 ----------------------------------------------------------------------------

## R07: without an Echo the bridge is extended only while the player stands on the plate; running
## for it from the plate never crosses the trench in 600 ticks. RED: bridge_platform_01/Blocker removed.
func test_pz003_bridge_cannot_be_crossed_without_echo() -> void:
	if not await start_at(R4, &"door_entry_west", BEFORE_R4, ALL_FLAGS):
		stop()
		return
	var bridge := resolve(&"ch01.security_crossing.bridge_platform_01") as RetractableBridge
	if not await walk_to(player, "crossing -> pressure plate", Vector2(320, 208), func() -> bool: return bridge.walkable):
		stop()
		return
	var crossed := func() -> bool: return player.global_position.y > 228.0 and player.global_position.x > 416.0
	await push_for([Vector2(364, 200), Vector2(432, 202), Vector2(432, 236)], 600, crossed)
	_assert_false(crossed.call(), "600 ticks without Echo: the trench is not crossed (player at %s)" % player.global_position)
	_assert_false(bridge.walkable, "the bridge is retracted")
	stop()


## R04: across the bridge (with the Echo) but without the pass, the reader answers no_pass, the
## barrier stays closed and 300 ticks at it never reach exit_trigger_lounge.
## RED: card_reader_01 pass_flag = ch01.flag.echo_pedestal_used (already set).
func test_pz003_reader_without_the_pass() -> void:
	if not await start_at(R4, &"door_entry_west", BEFORE_R4, ALL_FLAGS):
		stop()
		return
	var bridge := resolve(&"ch01.security_crossing.bridge_platform_01") as RetractableBridge
	var reader := resolve(&"ch01.security_crossing.card_reader_01")
	var barrier := resolve(&"ch01.security_crossing.staff_barrier_01") as PoweredDoor
	var echo := session.echo_service
	if not await select_ability(&"echo"):
		stop()
		return
	await tap(&"watch")
	if not await walk_to(player, "crossing -> pressure plate", Vector2(320, 208)):
		stop()
		return
	await tap(&"watch")
	if not await walk_to(player, "crossing -> off the plate", Vector2(364, 200)):
		stop()
		return
	await tap(&"watch")
	if not _assert_true(await until(func() -> bool: return bridge.walkable, 600), "the Echo holds the plate"):
		stop()
		return
	for point in [Vector2(432, 202), Vector2(432, 230)]:
		if not await walk_to(player, "crossing -> across the bridge", point):
			stop()
			return
	_assert_false(bool(session.narrative_state.get_flag(&"ch01.flag.transit_pass")), "no pass taken")
	if not await use_at(Vector2(464, 232), reader, "crossing -> card reader (no pass)"):
		stop()
		return
	await physics_frames(2)
	var refusal := last_refusal(reader)
	_assert_true(not refusal.is_empty() and refusal[2] == &"no_pass", "reader without the pass: no_pass (%s)" % [refusal])
	_assert_true(barrier.passage_blocked, "the barrier stays closed")
	await push_for([Vector2(496, 218), Vector2(496, 248)], 300, func() -> bool: return is_solved(&"CH1-PZ-003"))
	_assert_false(is_solved(&"CH1-PZ-003"), "300 ticks at the barrier: PZ-003 still UNSOLVED")
	_assert_ne(echo.state, EchoService.State.IDLE, "the Echo was used (sanity)")
	stop()


# --- CH1-PZ-004 ----------------------------------------------------------------------------

## PZ-004 step 1 from the current spot: Rewind + Freeze the capacitor.
func _stabilize_capacitor() -> bool:
	var capacitor := resolve(&"ch01.signal_control.surge_capacitor") as SurgeCapacitor
	if not await use_watch(&"rewind", capacitor, func() -> bool: return capacitor.bus_powered, "capacitor charged after Rewind"):
		return false
	return await use_watch(&"freeze", capacitor, func() -> bool: return capacitor.is_stabilized(), "capacitor stabilized")


const W0 := Vector2(176, 152)
const W2 := Vector2(304, 104)
const W3 := Vector2(528, 184)
## Fastest no-Echo attempt: around the south railing's east end, then straight at breaker B;
## if B never becomes the interact target on that line, the full Z-route.
const NO_ECHO_ROUTE: Array[Vector2] = [Vector2(392, 232), Vector2(510, 220), W2, W3]


## R07 (ISSUE-021 / RISK-018), moved from test_ch01_real_playthrough_late.gd and run with breaker C
## present: pulling A and running to B as fast as a player can misses the 180-tick window.
## RED: breaker A engage_ticks_base = 600 (the original RISK-018 break).
func test_pz004_cannot_be_solved_without_echo() -> void:
	if not await start_at(R6, &"door_entry_south", BEFORE_R6, ALL_FLAGS):
		stop()
		return
	var a := resolve(&"ch01.signal_control.breaker_a") as TimedBreaker
	var b := resolve(&"ch01.signal_control.breaker_b") as TimedBreaker
	var grid := resolve(&"ch01.signal_control.substation_grid") as SubstationGrid
	_assert_true(resolve(&"ch01.signal_control.breaker_c") != null, "breaker C present")
	if not (await _stabilize_capacitor() and await walk_to(player, "no-Echo run -> W0 (breaker A)", W0)):
		stop()
		return
	_assert_eq(player.current_target, a, "breaker A is the interact target at W0")
	var clock := session.sim_clock
	var a_tick := -1
	var b_tick := -1
	var b_pos := Vector2.ZERO
	var interact_frames := 0     # >0 while interact is held for a pull
	press(&"interact")           # pull A on the move
	interact_frames = 1
	var leg := 0
	var anchor_pos := player.global_position
	var still := 0
	for frame in 1200:
		if aborted or b.is_engaged() or leg >= NO_ECHO_ROUTE.size():
			break
		if interact_frames > 0:
			if Input.is_action_pressed(&"interact"):
				interact_frames += 1
			if interact_frames > 2:
				release(&"interact")
				interact_frames = 0
		if a_tick < 0 and a.is_engaged():
			a_tick = clock.tick
		if a_tick >= 0 and b_tick < 0 and interact_frames == 0 and player.current_target == b:
			press(&"interact")
			interact_frames = 1
			b_tick = clock.tick
			b_pos = player.global_position
		if player.global_position.distance_to(NO_ECHO_ROUTE[leg]) <= WALK_TOLERANCE:
			leg += 1
			continue
		steer(player, NO_ECHO_ROUTE[leg])
		await physics_frames(1)
		if player.global_position.distance_to(anchor_pos) >= WALK_STUCK_DISTANCE:
			anchor_pos = player.global_position
			still = 0
		else:
			still += 1
			if still >= WALK_STUCK_FRAMES:   # blocked on this leg: try the next waypoint
				leg += 1
				still = 0
	hold_moves([])
	if interact_frames > 0:
		release(&"interact")
	await physics_frames(3)
	_assert_true(a_tick >= 0, "breaker A pulled on the move")
	_assert_true(b_tick >= 0, "breaker B pulled at the end of the run")
	_assert_false(grid.grid_online,
		"RISK-018: grid came online without Echo; B pulled %d ticks after A from %s (window %d)" % [
			b_tick - a_tick, b_pos, a.engage_ticks_base])
	print("  INFO: no-Echo run: B pulled %d ticks after A from %s; grid_online=%s" % [b_tick - a_tick, b_pos, grid.grid_online])
	stop()


# --- CH1-PZ-005 ----------------------------------------------------------------------------

## R02 / R03: lever A on an empty standby plate is unpowered; and from the plate no lever is
## within reach, so the player alone cannot hold the plate and pull. Checked at the plate centre
## and its four edges (24 x 16). RED: requires_plate_id = "" on lever A / standby_plate_01 moved
## next to lever A (240,152).
func test_pz005_levers_need_an_echo_on_the_plate() -> void:
	if not await start_at(R7, &"door_south", BEFORE_R7, ALL_FLAGS):
		stop()
		return
	var lever_a := resolve(&"ch01.upper_vestibule.junction_lever_a")
	var lever_b := resolve(&"ch01.upper_vestibule.junction_lever_b")
	var plate := resolve(&"ch01.upper_vestibule.standby_plate_01") as TriggerZone
	if not await use_at(Vector2(256, 158), lever_a, "vestibule -> lever A (empty plate)"):
		stop()
		return
	await physics_frames(2)
	var refusal := last_refusal(lever_a)
	_assert_true(not refusal.is_empty() and refusal[2] == &"unpowered", "R02: lever A on an empty plate: unpowered (%s)" % [refusal])
	var centre: Vector2 = plate.global_position
	for offset in [Vector2.ZERO, Vector2(-10, 0), Vector2(10, 0), Vector2(0, -6), Vector2(0, 6)]:
		var spot: Vector2 = centre + offset
		if not await walk_to(player, "vestibule -> plate %s" % spot, spot, Callable(), 300, true):
			continue
		await physics_frames(2)
		if plate.is_occupied():
			var target := player.current_target
			_assert_true(target != lever_a and target != lever_b,
				"R03: standing on the plate at %s, no lever is the interact target (got %s)" % [player.global_position, target])
	stop()


func _assert_ne(actual, expected, msg: String) -> bool:
	return assert_helper.assert_ne(actual, expected, msg)
