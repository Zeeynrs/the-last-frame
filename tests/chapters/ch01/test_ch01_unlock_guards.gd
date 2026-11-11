extends "res://tests/support/ch01_real_input.gd"

## TLF-056 unlock guards (ABILITY_UNLOCKS.md 5, TEST-AU-08, SO01-10, PZ006-14): no ability can be
## selected or used before its trigger, also after a save and a Continue, and a Continue re-derives
## the unlocks from the saved flags (AU-07). Real input only; loads go through the in-game
## checkpoint autosave and RoomRouter.restore_from_save (the Continue path).
## RED: Chapter01.tscn GameSession starting_abilities = all four (the pre-Step-1 default).

const R2 := &"ch01.concourse_west"
const R3 := &"ch01.maintenance_bay"
const R4 := &"ch01.security_crossing"

## The wheel's six aim directions (ability_wheel.gd SEGMENT_ANGLES -90, -30, 30, 90, 150, -150).
const WHEEL_AIMS: Array = [[&"move_up"], [&"move_up", &"move_right"], [&"move_down", &"move_right"],
	[&"move_down"], [&"move_down", &"move_left"], [&"move_up", &"move_left"]]


func _init() -> void:
	timeout_frames = 3600


## Cycles with ability_next / ability_prev and aims the wheel at every slot. Returns the abilities
## that ever became selected; `refused` counts the watch's ability_selection_refused signals.
func _try_every_selection(refused: Array) -> Array:
	var watch: PocketWatch = player.pocket_watch
	var seen: Array = [watch.selected_ability]
	var on_refused := func(_ability: StringName, _reason: StringName) -> void: refused[0] += 1
	watch.ability_selection_refused.connect(on_refused)
	for action in [&"ability_next", &"ability_prev"]:
		for i in 5:
			await tap(action)
			if not seen.has(watch.selected_ability):
				seen.append(watch.selected_ability)
	# The wheel stays closed while any dialogue line is up (ability_wheel.gd _is_modal_open), and
	# non-blocking lines (Beat 01: 3 x 4 s, unlock and memory lines) advance on wall-clock time.
	var diag = ch01.get_dialogue_box()
	_assert_true(await until(func() -> bool: return not diag.is_active, 1500), "dialogue lines finished before the wheel")
	var wheel = player.hud.ability_wheel
	var start_pos := player.global_position
	for i in WHEEL_AIMS.size():
		var moves: Array[StringName] = []
		moves.assign(WHEEL_AIMS[i])
		press(&"ability_wheel")
		if not _assert_true(await until(func() -> bool: return wheel.is_open, 30), "the wheel opens"):
			break
		hold_moves(moves)
		_assert_true(await until(func() -> bool: return wheel.current_aimed_segment == i, 30), "aimed at wheel slot %d" % i)
		release(&"ability_wheel")
		await until(func() -> bool: return not wheel.is_open, 30)
		hold_moves([])
		await physics_frames(2)
		if not seen.has(watch.selected_ability):
			seen.append(watch.selected_ability)
	_assert_true(player.global_position.distance_to(start_pos) < 2.0, "aiming the wheel does not walk the player")
	watch.ability_selection_refused.disconnect(on_refused)
	return seen


## A new game has Trace only: ability_next / ability_prev change nothing and the wheel refuses
## every locked slot (SO01-10, TEST-AU-08).
func test_new_game_selects_nothing_but_trace() -> void:
	if not await start_at(&"ch01.arrival_platform", &""):
		stop()
		return
	_assert_eq(session.ability_unlocks.unlocked(), [&"trace"], "new game: Trace only")
	var refused := [0]
	var seen := await _try_every_selection(refused)
	_assert_eq(seen, [&"trace"], "only Trace was ever selected (next, prev, wheel)")
	_assert_true(refused[0] >= 3, "the wheel refused the locked slots (%d refusals)" % refused[0])
	stop()


## R2 entry: the courier is the Trace target from the door spawn with the real colliders; a
## Continue from the entry autosave (before the courier) has Rewind locked, also after the courier
## was traced in the meantime.
func test_load_in_concourse_before_the_courier_keeps_rewind_locked() -> void:
	if not await start_at(R2, &"door_entry_west", [&"CH1-SO-01"]):
		stop()
		return
	var courier := resolve(&"ch01.concourse_west.n05_courier")
	await physics_frames(1)
	_assert_eq(player.pocket_watch.current_target, courier, "Trace targets the courier from the entry spawn")
	if not await continue_from_autosave():
		stop()
		return
	_assert_eq(session.ability_unlocks.unlocked(), [&"trace"], "Continue in R2 before the courier: Trace only")
	# Away from door_entry_west first: the respawn anchor (256,112) is under 2 px from its trigger.
	if not await walk_to(player, "concourse -> away from the west door", Vector2(232, 128)):
		stop()
		return
	var refused := [0]
	_assert_eq(await _try_every_selection(refused), [&"trace"], "R2 after the load: nothing but Trace selectable")
	courier = resolve(&"ch01.concourse_west.n05_courier")
	if not await use_watch(&"trace", courier, func() -> bool: return bool(session.narrative_state.get_flag(FLAG_REWIND)), "courier traced"):
		stop()
		return
	await dismiss_blocking_ui()
	_assert_true(session.ability_unlocks.is_unlocked(&"rewind"), "the courier unlocks Rewind")
	if not await continue_from_autosave():
		stop()
		return
	_assert_eq(session.ability_unlocks.unlocked(), [&"trace"], "Continue from the earlier autosave: Rewind locked again")
	_assert_false(bool(session.narrative_state.get_flag(FLAG_REWIND)), "the courier flag is not in that save")
	stop()


## R3 entry: a Continue from the bay autosave (courier traced, technician not) has Rewind but not
## Freeze, also after N-11 was traced in the meantime.
func test_load_in_bay_before_the_technician_keeps_freeze_locked() -> void:
	if not await start_at(R3, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-PZ-006"], [FLAG_REWIND]):
		stop()
		return
	if not await continue_from_autosave():
		stop()
		return
	_assert_eq(session.ability_unlocks.unlocked(), [&"trace", &"rewind"], "Continue in R3 before N-11: Trace and Rewind")
	var refused := [0]
	var seen := await _try_every_selection(refused)
	_assert_false(seen.has(&"freeze") or seen.has(&"echo"), "R3 after the load: Freeze and Echo never selectable (%s)" % [seen])
	if not await walk_to(player, "bay -> technician spot", Vector2(352, 128)):
		stop()
		return
	var tech := resolve(&"ch01.maintenance_bay.n11_hatch_tech")
	if not await use_watch(&"trace", tech, func() -> bool: return bool(session.narrative_state.get_flag(FLAG_FREEZE)), "technician traced"):
		stop()
		return
	await dismiss_blocking_ui()
	_assert_true(session.ability_unlocks.is_unlocked(&"freeze"), "N-11 unlocks Freeze")
	if not await continue_from_autosave():
		stop()
		return
	_assert_eq(session.ability_unlocks.unlocked(), [&"trace", &"rewind"], "Continue from the earlier autosave: Freeze locked again")
	stop()


## AU-07 on the Continue path: with the three unlock flags in the save, a load re-derives all four
## abilities, and each one is selectable with ability_next.
func test_load_rederives_unlocks_from_the_flags() -> void:
	if not await start_at(R4, &"door_entry_west", [&"CH1-SO-01", &"CH1-PZ-001", &"CH1-PZ-006", &"CH1-SO-02", &"CH1-PZ-002"],
			[FLAG_REWIND, FLAG_FREEZE, FLAG_ECHO]):
		stop()
		return
	if not await continue_from_autosave():
		stop()
		return
	_assert_eq(session.ability_unlocks.unlocked(), [&"trace", &"rewind", &"freeze", &"echo"], "Continue in R4: all four")
	var seen: Array = [player.pocket_watch.selected_ability]
	for i in 4:
		await tap(&"ability_next")
		if not seen.has(player.pocket_watch.selected_ability):
			seen.append(player.pocket_watch.selected_ability)
	# As Strings: Array.sort() does not order StringNames by text (the order varies between runs).
	var names: Array = seen.map(func(a: StringName) -> String: return String(a))
	names.sort()
	_assert_eq(names, ["echo", "freeze", "rewind", "trace"], "ability_next reaches all four after the load")
	stop()
