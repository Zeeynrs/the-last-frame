# TLF-056 handoff: Step 1 real-input playthrough, negatives, unlock guards, PZ-004 save/load (Opus)

## Branch and SHAs

* **Branch:** `agent/opus-core-tlf056`, cut from `origin/main` `6ae6455` (TLF-055 merged).
* **Commits:**
  * `550d846`: TLF-049, `a28fe63` replayed unchanged.
  * `65c0ea3`: the TLF-049 setup change, `_start()` only (Lead decision, TLF-055 §F a).
  * `5bca6a6`: the TLF-056 tests.
  * `3e51375`: the unlock-order fix, a separate commit, the two Lead-authorized files only. **This is the validated tree.**
  * The commit with this file adds documentation only.

## Status: validate on `3e51375` is `TESTS: 424 passed, 0 failed`, with 0 `SCRIPT ERROR` lines in the log

**The defect the playthrough found, now fixed** (Lead decision: Opus applies it in a separate commit, two files only):
* `AbilityUnlocks.unlock()` (`scripts/narrative/ability_unlocks.gd`) emitted `ability_unlocked` **before** `unlocks_changed`.
* `chapter01.gd` `_on_ability_unlocked` calls `watch.set_selected_ability(ability)`. The PocketWatch had not resynced yet (it does so on `unlocks_changed`), so the call was refused with `ability_locked`.
* The HUD then replaced "Rewind unlocked." with "The watch can't do that yet." (`UI_FB_ABILITY_LOCKED`), at all three unlocks.
* Before the fix, `5bca6a6` validated at `TESTS: 422 passed, 2 failed`: the playthrough's toast and auto-select assertions, and `test_playtest_log`, which reuses the route.
* **Fix (`3e51375`):**
  * `ability_unlocks.gd`: `unlocks_changed` is emitted first, then `ability_unlocked`.
  * `tests/player/test_ability_unlocks.gd:142`: selects Rewind in at most 4 taps. The single tap only passed while auto-select was broken: one tap from the auto-selected Rewind wraps back to Trace.
* Nothing else changed.

## TLF-049 (Lead condition §F a)

* **Diff proof** (`git diff a28fe63 -- tests/chapters/ch01/test_ch01_pz002_negative.gd`):
  * There is one hunk, inside `_start()`.
  * Everything outside `_start()` is byte-identical: `cmp` of the file with `_start()` cut out reports identical. `_run_without_freeze()`, `ROUTE`, `REWIND_SPOT`, the windows and every assertion are unchanged. The diff is pasted below.
* **On `5bca6a6`:** it passes with the assist off and on. The shutter closes after 180 / 300 ticks, the exit trigger is never reached, and the player never leaves east.
* **RED with the `unanchored` rule disabled** (`inner_shutter requires_gear_frozen = false`): **the unchanged TLF-049 stays GREEN** (output below).
  * TLF-049's route never Rewinds the inner shutter. In the Step 1 layout, the closed inner shutter's Blocker stops it whatever the rule says.
  * So the rule cannot be proven by TLF-049 without changing its body.
  * The rule is covered by the new `test_pz002_inner_shutter_needs_the_gear_frozen` (R03 + R04). That test goes **RED** with the rule disabled (output below).
  * TLF-049 itself goes **RED** with the inner shutter's Blocker removed: SOLVED 43 ticks after the Rewind, and the player leaves east (output below).
* **Lead decision:** byte-identity accepted as is, with this alternative proof. TLF-049 gets no extra step. Both RED outputs are under *Raw evidence*: `test_pz002_inner_shutter_needs_the_gear_frozen` in set A, and TLF-049 in set C.

## What the tests cover

### Playthrough

`test_ch01_real_playthrough.gd` (replaces it and `_late.gd`):
* One test runs from a new game (`[trace]`) to chapter complete: the 8 Step 1 puzzles SOLVED once each, in order, and the three unlocks once each, in order.
* The intended wrong moves, each checked with its reason and HUD text:
  * SO-01: `wrong_code` / `locked_out`, then the right code after the lock-out.
  * PZ-001: `pinned`.
  * PZ-006: `invalid_ticket`.
  * PZ-004: the C brown-out, `PZ004_FB_BROWNOUT`.
  * PZ-005: `unpowered`, `invalid_graph` (B before A), `dead_relay` (C).
* Also played: the watch pickup with the `UNLOCK_TRACE` toast, the 12 commuter and anchor Traces, and the ticket terms.
* `_play()` (R1-R4) stays the clean route that `test_playtest_log` times. Its wrong moves only run when `wrong_moves` is set.

### Negatives

`test_ch01_step1_negatives.gd`, 12 tests. Each was seen RED against the break named in it (table below):

| Puzzle | Tests |
|---|---|
| SO-01 | SO01-05: the gate holds 300 ticks. SO01-04: the lock-out, on real input. |
| PZ-001 | `pinned`, and 300 ticks at the turnstile. |
| PZ-006 | PZ006-09: the staff door holds. |
| SO-02 | SO02-04: the hatch closes without Freeze. SO02-05: the bulkhead is sealed, from 5 spots. SO02-07 / SO02-08: the bell decoy, and the Continue spawn at `safe_anchor_entry`. |
| PZ-002 | R03 `unanchored` plus 600 ticks, then R04 late Freeze solves. |
| PZ-003 | R07: no Echo, 600 ticks. R04: the reader without the pass answers `no_pass`. |
| PZ-004 | R07: no Echo, with C present (moved from `_late.gd`). |
| PZ-005 | R02: empty plate. R03: no lever from 5 spots on the plate. |

### Unlock guards

`test_ch01_unlock_guards.gd`:
* With Trace only, `ability_next` / `ability_prev` and all 6 wheel slots never select anything else. The wheel refusals are counted.
* The courier is the Trace target from the R2 spawn.
* A Continue in R2 before the courier keeps Rewind locked, also after the courier was traced in the meantime.
* A Continue in R3 before N-11 keeps Freeze locked, likewise.
* A Continue re-derives all four abilities from the flags (AU-07).

### PZ-004 save/load

`test_ch01_pz004_saveload.gd`, F1-F4:
* Saves go through `ch01.cp.signal_control` with real input; loads go through Continue.
* After every load the test asserts:
  * `is_solved == grid_online == not vestibule_door.passage_blocked` (no desync);
  * no echo;
  * no engaged breaker;
  * the hint title.
* F1 and F2 also check the frozen capacitor, F3 the discharged and unfrozen capacitor, and F4 that C answers `already_open`, the hint reports solved, and the player walks north into R7.

### Support

`tests/support/ch01_real_input.gd` is a shared fixture (additive). `select_ability()` fails instead of looping forever, which was the TLF-049 failure mode.

## RED proofs (scratch copies of the `5bca6a6` tests; breaks applied by `breaks.py`)

| Set | Break | Test seen RED |
|---|---|---|
| A | `platform_gate/Blocker` collision_layer 0 | `test_so01_closed_gate_holds_300_ticks` |
| A | `turnstile_gate.pinned_by = ""` | `test_pz001_gate_pinned_and_turnstile_holds` |
| A | `staff_door/Blocker` removed | `test_pz006_staff_door_holds_300_ticks` |
| A | `hatch_01/Blocker` removed | `test_so02_hatch_closes_without_freeze` |
| A | `inner_shutter.requires_gear_frozen = false` (the `unanchored` rule) | `test_pz002_inner_shutter_needs_the_gear_frozen` |
| A | bay checkpoint `spawn_anchor_id = safe_anchor_west` | `test_so02_bell_decoy_and_checkpoint_spawn` (spawn half) |
| A | `bridge_platform_01/Blocker` removed | `test_pz003_bridge_cannot_be_crossed_without_echo` |
| A | `breaker_a.engage_ticks_base = 600` (RISK-018) | `test_pz004_cannot_be_solved_without_echo` |
| A | `junction_lever_a.requires_plate_id = ""` | `test_pz005_levers_need_an_echo_on_the_plate` (R02) |
| B | `release_lock.lockout_base_ticks = 0` | `test_so01_lockout_holds_until_it_ends` |
| B | Bulkhead segment (368,88)-(332,106) deleted | `test_so02_bulkhead_sealed` |
| B | `card_reader_01.pass_flag = ch01.flag.echo_pedestal_used` | `test_pz003_reader_without_the_pass` |
| B | `standby_plate_01` moved to (240,152) | `test_pz005_levers_need_an_echo_on_the_plate` (R03) |
| C | `hatch_01.plate_id = bell_plate_01` | `test_so02_bell_decoy_and_checkpoint_spawn` (bell half) |
| C | `inner_shutter/Blocker` removed | TLF-049, both tests |
| C | Chapter01 `starting_abilities` = all four | `test_ch01_unlock_guards.gd`, 3 of 4 (the re-derive test cannot fail on it) |
| C | `TemporalComponent.import_history` drops `is_frozen` | `test_f1_*`, `test_f2_*` |

In each set, every test without its own break stayed GREEN, with these exceptions:
* In set C, the bell rewiring also stops the hatch test.
* In set C, the removed inner Blocker also breaks PZ-002 R03.

**The first bulkhead test was too weak.** It skipped spots it could not reach, and stayed GREEN with the segment deleted. I rewrote it: the spots are reached through the corridor above N-11, and a spot that can't be reached fails the test. It is now RED on that break and GREEN on the clean tree.

## Telemetry: PlaytestLog of the full playthrough (on `3e51375`; the game-time floor for the scripted run)

```
  INFO: playthrough | 1 arrival (SO-01)                     591 frames (9.85 s)
  INFO: playthrough | 2a concourse PZ-001                   160 frames (2.67 s)
  INFO: playthrough | 2b concourse PZ-006                   367 frames (6.12 s)
  INFO: playthrough | 3a bay SO-02                           87 frames (1.45 s)
  INFO: playthrough | 3b bay PZ-002                         138 frames (2.30 s)
  INFO: playthrough | 4 crossing PZ-003                     304 frames (5.07 s)
  INFO: playthrough | 5 lounge (audio log, exit)             93 frames (1.55 s)
  INFO: playthrough | 6a PZ-004 step 1 (Rewind+Freeze)      214 frames (3.57 s)
  INFO: playthrough | 6b PZ-004 step 2 (Echo + Z-route)     440 frames (7.33 s)
  INFO: playthrough | 6c PZ-004 exit                         62 frames (1.03 s)
  INFO: playthrough | 7 vestibule PZ-005 (levers)           358 frames (5.97 s)
  INFO: playthrough | 9 atrium terminal (Beat 09)           136 frames (2.27 s)
  INFO: playthrough | 10 street exit outro (Beat 10)         55 frames (0.92 s)
  INFO: real-input playthrough took 3005 physics frames (50.1 s game time, 50.18 s wall)
  INFO: SOLVED ticks [[&"CH1-SO-01", 571], [&"CH1-PZ-001", 751], [&"CH1-PZ-006", 1086], [&"CH1-SO-02", 1198], [&"CH1-PZ-002", 1322], [&"CH1-PZ-003", 1623], [&"CH1-PZ-004", 2434], [&"CH1-PZ-005", 2801]]
  INFO: unlock ticks [[&"rewind", 594], [&"freeze", 1134], [&"echo", 1342]]
  INFO: PlaytestLog | Playtest: 0:49 played, 0:01 paused
  INFO: PlaytestLog | PZ-001 0:03   PZ-002 0:04   PZ-003 0:05
  INFO: PlaytestLog | PZ-004 0:12   PZ-005 0:06   PZ-006 0:08
  INFO: PlaytestLog | SO-01 0:10   SO-02 0:01
  INFO: playtest log of the TLF-030 route: total 15.37 s active, 0 dialogue ticks; CH1-PZ-001 1.45 s (87 ticks); CH1-PZ-002 3.57 s (214 ticks); CH1-PZ-003 4.82 s (289 ticks); ch01.arrival_platform 2.07 s; ch01.concourse_west 4.43 s; ch01.maintenance_bay 3.77 s; ch01.security_crossing 5.07 s; ch01.waiting_lounge 0.03 s
```

The full playthrough includes every wrong move and the 12 Traces. The `test_playtest_log` line is the clean R1-R4 route.

**The RED proofs** were run on the `5bca6a6` tests, before the fix. The fix changes no test the breaks target.

## Raw evidence

### TLF-049 diff against a28fe63

```
diff --git a/tests/chapters/ch01/test_ch01_pz002_negative.gd b/tests/chapters/ch01/test_ch01_pz002_negative.gd
index 353add2..6c14052 100644
--- a/tests/chapters/ch01/test_ch01_pz002_negative.gd
+++ b/tests/chapters/ch01/test_ch01_pz002_negative.gd
@@ -78,9 +78,27 @@ func _start(assist: bool) -> bool:
 	await physics_frames(2)
 	await dismiss_blocking_ui()
 	_session.puzzle_service.mark_solved(&"CH1-PZ-001")
+	# Step 1 layout (TLF-055, Lead-approved setup change): a new game has only Trace and the bay
+	# has the SO-02 bulkhead. Set the courier and technician flags (the chapter's unlock triggers
+	# give Rewind and Freeze; Freeze stays unused), latch SO-02 so the hatch is open, then walk
+	# through the hatch to the east side of the bulkhead. The checks below are unchanged.
+	_session.narrative_state.set_flag(&"ch01.npc.n05.traced")
+	_session.narrative_state.set_flag(&"ch01.npc.n11.traced")
+	_session.puzzle_service.mark_solved(&"CH1-SO-02")
 	_router.enter_room(BAY, &"door_entry_west")
 	await physics_frames(3)
-	return _assert_eq(_router.current_room_id, BAY, "setup entered the maintenance bay")
+	if not _assert_eq(_router.current_room_id, BAY, "setup entered the maintenance bay"):
+		return false
+	if not (_assert_true(_session.ability_unlocks.is_unlocked(&"rewind"), "setup: Rewind unlocked")
+			and _assert_true(_session.ability_unlocks.is_unlocked(&"freeze"), "setup: Freeze unlocked")):
+		return false
+	# Through the 1.5-tile hatch aperture straight down at x = 320-321, above N-11's footprint
+	# (304,104) (checked against the TLF-055 colliders in TLF-056).
+	var hatch_walk: Array[Vector2] = [Vector2(288, 92), Vector2(320, 92), Vector2(321, 140)]
+	for point in hatch_walk:
+		if not await walk_to(_player, "setup: bay -> through the hatch", point):
+			return false
+	return true
 
 
 func _stop() -> void:
```

### TLF-049 with the `unanchored` rule disabled (inner_shutter requires_gear_frozen = false): stays GREEN

```
  INFO: PZ-002 no-Freeze run (assist off, window 180 ticks): Rewind from (384.7212, 145.9502); gap passed after 14 ticks at (384.7212, 167.9502); exit trigger (SOLVED) after never; shutter closed after 180 ticks; left east after never; player now (448.9129, 171.761) in ch01.maintenance_bay
  PASS: test_pz002_cannot_be_solved_without_freeze_assist_off
  INFO: PZ-002 no-Freeze run (assist on, window 300 ticks): Rewind from (384.7212, 145.9502); gap passed after 14 ticks at (384.7212, 167.9502); exit trigger (SOLVED) after never; shutter closed after 300 ticks; left east after never; player now (448.9129, 171.761) in ch01.maintenance_bay
  PASS: test_pz002_cannot_be_solved_without_freeze_assist_on
TESTS: 2 passed, 0 failed
```

### RED set A (test_ch01_step1_negatives.gd; run before the bulkhead test was strengthened, set A has no bulkhead break)

Includes the Lead-requested proof: `test_pz002_inner_shutter_needs_the_gear_frozen` (R03/R04) RED with the `unanchored` rule disabled.

```
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz001_gate_pinned_and_turnstile_holds] Rewind on the pinned gate refused: pinned ([])
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz001_gate_pinned_and_turnstile_holds] turnstile still blocked
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz001_gate_pinned_and_turnstile_holds] 300 ticks at the turnstile: PZ-001 still UNSOLVED (player at (287.4162, 131.626))
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz002_inner_shutter_needs_the_gear_frozen] R03: inner shutter refused: unanchored ([])
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz002_inner_shutter_needs_the_gear_frozen] R03: inner shutter still closed
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz002_inner_shutter_needs_the_gear_frozen] R03: 600 ticks without Freeze: PZ-002 still UNSOLVED
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz002_inner_shutter_needs_the_gear_frozen] R04 start: the fire shutter has closed again
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz003_bridge_cannot_be_crossed_without_echo] 600 ticks without Echo: the trench is not crossed (player at (367.8885, 197.5777))
  PASS: test_pz003_reader_without_the_pass
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz004_cannot_be_solved_without_echo] RISK-018: grid came online without Echo; B pulled 418 ticks after A from (516.3919, 181.4689) (window 600)
  INFO: no-Echo run: B pulled 418 ticks after A from (516.3919, 181.4689); grid_online=true
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz005_levers_need_an_echo_on_the_plate] R02: lever A on an empty plate: unpowered ([])
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz006_staff_door_holds_300_ticks] the staff door holds from (448.0, 200.0) (Expected ch01.concourse_west, got ch01.maintenance_bay)
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so01_closed_gate_holds_300_ticks] the closed gate holds from (416.0, 200.0) (Expected ch01.arrival_platform, got ch01.concourse_west)
  PASS: test_so01_lockout_holds_until_it_ends
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so02_bell_decoy_and_checkpoint_spawn] Continue respawns at safe_anchor_entry (272,104), west of the bulkhead (at (336.0, 136.0))
  PASS: test_so02_bulkhead_sealed
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so02_hatch_closes_without_freeze] the hatch closed when the plate was left
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so02_hatch_closes_without_freeze] 300 ticks without Freeze: SO-02 still UNSOLVED (player at (320.1993, 113.6892))
TESTS: 3 passed, 9 failed
```

### RED set B (test_ch01_step1_negatives.gd, with the strengthened bulkhead test)

```
  PASS: test_pz001_gate_pinned_and_turnstile_holds
  PASS: test_pz002_inner_shutter_needs_the_gear_frozen
  PASS: test_pz003_bridge_cannot_be_crossed_without_echo
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz003_reader_without_the_pass] reader without the pass: no_pass ([])
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz003_reader_without_the_pass] the barrier stays closed
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz003_reader_without_the_pass] 300 ticks at the barrier: PZ-003 still UNSOLVED
  INFO: no-Echo run: B pulled 418 ticks after A from (516.3919, 181.4689); grid_online=false
  PASS: test_pz004_cannot_be_solved_without_echo
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz005_levers_need_an_echo_on_the_plate] R03: standing on the plate at (240.0, 152.6335), no lever is the interact target (got junction_lever_a:<Area2D#370625481338>)
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz005_levers_need_an_echo_on_the_plate] R03: standing on the plate at (230.0, 152.6335), no lever is the interact target (got junction_lever_a:<Area2D#370625481338>)
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz005_levers_need_an_echo_on_the_plate] R03: standing on the plate at (250.0, 152.6335), no lever is the interact target (got junction_lever_a:<Area2D#370625481338>)
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz005_levers_need_an_echo_on_the_plate] R03: standing on the plate at (239.2669, 147.2669), no lever is the interact target (got junction_lever_a:<Area2D#370625481338>)
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz005_levers_need_an_echo_on_the_plate] R03: standing on the plate at (239.2669, 157.2669), no lever is the interact target (got junction_lever_a:<Area2D#370625481338>)
  PASS: test_pz006_staff_door_holds_300_ticks
  PASS: test_so01_closed_gate_holds_300_ticks
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so01_lockout_holds_until_it_ends] lock-out of 360 ticks from the wrong pull (Expected 360, got 0)
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so01_lockout_holds_until_it_ends] back at the lever before the lock-out ends (tick 159, ends 73)
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so01_lockout_holds_until_it_ends] right code just before the end is refused locked_out ([&"player", &"ch01.arrival_platform.release_lever", &"wrong_code", 73], ends 73)
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so01_lockout_holds_until_it_ends] not solved during the lock-out
  PASS: test_so02_bell_decoy_and_checkpoint_spawn
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so02_bulkhead_sealed] the bulkhead holds from (330.0107, 91.1329) towards (348.0, 112.0) (player at (344.3215, 108.4994))
  PASS: test_so02_hatch_closes_without_freeze
TESTS: 8 passed, 4 failed
```

### RED set C (test_ch01_step1_negatives.gd)

```
  PASS: test_pz001_gate_pinned_and_turnstile_holds
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz002_inner_shutter_needs_the_gear_frozen] R03: 600 ticks without Freeze: PZ-002 still UNSOLVED
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_pz002_inner_shutter_needs_the_gear_frozen] R04 start: the fire shutter has closed again
  PASS: test_pz003_bridge_cannot_be_crossed_without_echo
  PASS: test_pz003_reader_without_the_pass
  INFO: no-Echo run: B pulled 418 ticks after A from (516.3919, 181.4689); grid_online=false
  PASS: test_pz004_cannot_be_solved_without_echo
  PASS: test_pz005_levers_need_an_echo_on_the_plate
  PASS: test_pz006_staff_door_holds_300_ticks
  PASS: test_so01_closed_gate_holds_300_ticks
  PASS: test_so01_lockout_holds_until_it_ends
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so02_bell_decoy_and_checkpoint_spawn] the bell plate does not open the hatch
  PASS: test_so02_bulkhead_sealed
  FAIL: [res://tests/chapters/ch01/test_ch01_step1_negatives.gd::test_so02_hatch_closes_without_freeze] bay -> hatch plate: reached (256.0, 128.0) but the stop condition did not hold in ch01.maintenance_bay
TESTS: 9 passed, 3 failed
```

### RED set C (test_ch01_pz002_negative.gd)

Lead-requested proof: TLF-049 RED with the inner shutter's Blocker removed.

```
  INFO: PZ-002 no-Freeze run (assist off, window 180 ticks): Rewind from (384.7212, 145.9502); gap passed after 14 ticks at (384.7212, 167.9502); exit trigger (SOLVED) after 43 ticks; shutter closed after never; left east after 58 ticks; player now (241.7888, 120.8944) in ch01.security_crossing
  INFO: PZ-002 no-Freeze run (assist off): SOLVED with 137 of 180 ticks to spare
  FAIL: [res://tests/chapters/ch01/test_ch01_pz002_negative.gd::test_pz002_cannot_be_solved_without_freeze_assist_off] assist off: PZ-002 must not be SOLVED without Freeze (exit trigger reached 43 ticks after the Rewind, window 180)
  FAIL: [res://tests/chapters/ch01/test_ch01_pz002_negative.gd::test_pz002_cannot_be_solved_without_freeze_assist_off] assist off: the bay must not be left east without Freeze (Expected not ch01.security_crossing, got ch01.security_crossing)
  INFO: PZ-002 no-Freeze run (assist on, window 300 ticks): Rewind from (384.7212, 145.9502); gap passed after 14 ticks at (384.7212, 167.9502); exit trigger (SOLVED) after 43 ticks; shutter closed after never; left east after 58 ticks; player now (241.7888, 120.8944) in ch01.security_crossing
  INFO: PZ-002 no-Freeze run (assist on): SOLVED with 257 of 300 ticks to spare
  FAIL: [res://tests/chapters/ch01/test_ch01_pz002_negative.gd::test_pz002_cannot_be_solved_without_freeze_assist_on] assist on: PZ-002 must not be SOLVED without Freeze (exit trigger reached 43 ticks after the Rewind, window 300)
  FAIL: [res://tests/chapters/ch01/test_ch01_pz002_negative.gd::test_pz002_cannot_be_solved_without_freeze_assist_on] assist on: the bay must not be left east without Freeze (Expected not ch01.security_crossing, got ch01.security_crossing)
TESTS: 0 passed, 2 failed
```

### RED set C (test_ch01_unlock_guards.gd)

```
  FAIL: [res://tests/chapters/ch01/test_ch01_unlock_guards.gd::test_load_in_bay_before_the_technician_keeps_freeze_locked] Continue in R3 before N-11: Trace and Rewind (Expected [&"trace", &"rewind"], got [&"trace", &"rewind", &"freeze", &"echo"])
  FAIL: [res://tests/chapters/ch01/test_ch01_unlock_guards.gd::test_load_in_bay_before_the_technician_keeps_freeze_locked] R3 after the load: Freeze and Echo never selectable ([&"trace", &"rewind", &"freeze", &"echo"])
  FAIL: [res://tests/chapters/ch01/test_ch01_unlock_guards.gd::test_load_in_bay_before_the_technician_keeps_freeze_locked] Continue from the earlier autosave: Freeze locked again (Expected [&"trace", &"rewind"], got [&"trace", &"rewind", &"freeze", &"echo"])
  FAIL: [res://tests/chapters/ch01/test_ch01_unlock_guards.gd::test_load_in_concourse_before_the_courier_keeps_rewind_locked] Continue in R2 before the courier: Trace only (Expected [&"trace"], got [&"trace", &"rewind", &"freeze", &"echo"])
  FAIL: [res://tests/chapters/ch01/test_ch01_unlock_guards.gd::test_load_in_concourse_before_the_courier_keeps_rewind_locked] R2 after the load: nothing but Trace selectable (Expected [&"trace"], got [&"trace", &"rewind", &"freeze", &"echo"])
  FAIL: [res://tests/chapters/ch01/test_ch01_unlock_guards.gd::test_load_in_concourse_before_the_courier_keeps_rewind_locked] Continue from the earlier autosave: Rewind locked again (Expected [&"trace"], got [&"trace", &"rewind", &"freeze", &"echo"])
  PASS: test_load_rederives_unlocks_from_the_flags
  FAIL: [res://tests/chapters/ch01/test_ch01_unlock_guards.gd::test_new_game_selects_nothing_but_trace] new game: Trace only (Expected [&"trace"], got [&"trace", &"rewind", &"freeze", &"echo"])
  FAIL: [res://tests/chapters/ch01/test_ch01_unlock_guards.gd::test_new_game_selects_nothing_but_trace] only Trace was ever selected (next, prev, wheel) (Expected [&"trace"], got [&"trace", &"rewind", &"freeze", &"echo"])
  FAIL: [res://tests/chapters/ch01/test_ch01_unlock_guards.gd::test_new_game_selects_nothing_but_trace] the wheel refused the locked slots (2 refusals)
TESTS: 1 passed, 3 failed
```

### RED set C (test_ch01_pz004_saveload.gd)

```
  FAIL: [res://tests/chapters/ch01/test_ch01_pz004_saveload.gd::test_f1_save_with_a_recorded_echo] F1: capacitor still frozen
  FAIL: [res://tests/chapters/ch01/test_ch01_pz004_saveload.gd::test_f1_save_with_a_recorded_echo] F1: the echo pulls A
  FAIL: [res://tests/chapters/ch01/test_ch01_pz004_saveload.gd::test_f2_save_while_the_echo_replays] F2: capacitor still stabilized
  FAIL: [res://tests/chapters/ch01/test_ch01_pz004_saveload.gd::test_f2_save_while_the_echo_replays] F2: the echo pulls A
  PASS: test_f3_save_after_a_brownout
  PASS: test_f4_save_after_solved
TESTS: 2 passed, 2 failed
```

## Complete raw validate output (`3e51375`, `git archive` copy, `config/name="TLF Verify 3e51375"`, no BOM; exit 0)

ANSI colour codes, the UTF-8 BOM and CR line endings are stripped; nothing else is changed. The log has no `SCRIPT ERROR` lines.

```
=== Validating The Last Frame Project ===
Using Godot executable: D:\Godot\Godot_v4.7.2-stable_win64_console.exe
Project root: C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\verify_3e51375

[1/3] Running headless import check...
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started Project initialization (5 steps)
[   0% ] first_scan_filesystem | Scanning file structure...
[  16% ] first_scan_filesystem | Loading global class names...
[  33% ] first_scan_filesystem | Verifying GDExtensions...
[  50% ] first_scan_filesystem | Creating autoload scripts...
[  66% ] first_scan_filesystem | Initializing plugins...
[  83% ] first_scan_filesystem | Starting file scan...
[ DONE ] first_scan_filesystem

[   0% ] update_scripts_classes | Started Registering global classes... (150 steps)
[   0% ] update_scripts_classes | BreakerCPresenter
[   0% ] update_scripts_classes | CableConduitPresenter
[   1% ] update_scripts_classes | CardReaderPresenter
[   1% ] update_scripts_classes | CommuterStatuePresenter
[   2% ] update_scripts_classes | ConduitPropPresenter
[   3% ] update_scripts_classes | CounterweightGearPresenter
[   3% ] update_scripts_classes | DeadRelayPresenter
[   4% ] update_scripts_classes | DispatchTerminalPresenter
[   5% ] update_scripts_classes | EchoPedestalPresenter
[   5% ] update_scripts_classes | FireShutterPresenter
[   6% ] update_scripts_classes | HistoryDialPresenter
[   7% ] update_scripts_classes | LeverPresenter
[   7% ] update_scripts_classes | PressureSwitchPresenter
[   8% ] update_scripts_classes | ReleaseLeverPresenter
[   9% ] update_scripts_classes | RetractableBridgePresenter
[   9% ] update_scripts_classes | RoomVisuals
[  10% ] update_scripts_classes | RouteBoardPresenter
[  11% ] update_scripts_classes | SecurityGatePresenter
[  11% ] update_scripts_classes | SelectorSwitchPresenter
[  12% ] update_scripts_classes | ServiceHatchPresenter
[  13% ] update_scripts_classes | SurgeCapacitorPresenter
[  13% ] update_scripts_classes | TicketValidatorPresenter
[  14% ] update_scripts_classes | TurnstilePresenter
[  15% ] update_scripts_classes | Chapter01
[  15% ] update_scripts_classes | SignalControlIntercom
[  16% ] update_scripts_classes | 
[  17% ] update_scripts_classes | 
[  17% ] update_scripts_classes | EchoService
[  18% ] update_scripts_classes | Interactable
[  19% ] update_scripts_classes | Lever
[  19% ] update_scripts_classes | TriggerZone
[  20% ] update_scripts_classes | AbilityUnlocks
[  21% ] update_scripts_classes | DocumentDef
[  21% ] update_scripts_classes | NarrativeState
[  22% ] update_scripts_classes | ReadableDocument
[  23% ] update_scripts_classes | TraceMemory
[  23% ] update_scripts_classes | Player
[  24% ] update_scripts_classes | PocketWatch
[  25% ] update_scripts_classes | CardReader
[  25% ] update_scripts_classes | CodeLock
[  26% ] update_scripts_classes | ConduitProp
[  27% ] update_scripts_classes | CounterweightGear
[  27% ] update_scripts_classes | DeadRelay
[  28% ] update_scripts_classes | DecoyPlate
[  29% ] update_scripts_classes | FireShutter
[  29% ] update_scripts_classes | HistoryDial
[  30% ] update_scripts_classes | JunctionLever
[  31% ] update_scripts_classes | LampRingBreaker
[  31% ] update_scripts_classes | PlateLinkedGate
[  32% ] update_scripts_classes | PoweredDoor
[  33% ] update_scripts_classes | ProgressionPickup
[  33% ] update_scripts_classes | PuzzleObject
[  34% ] update_scripts_classes | ReleaseLever
[  35% ] update_scripts_classes | RetractableBridge
[  35% ] update_scripts_classes | SelectorSwitch
[  36% ] update_scripts_classes | SpatialStateResetter
[  37% ] update_scripts_classes | SubstationGrid
[  37% ] update_scripts_classes | SurgeCapacitor
[  38% ] update_scripts_classes | TicketValidator
[  39% ] update_scripts_classes | TimedBreaker
[  39% ] update_scripts_classes | TurnstileGate
[  40% ] update_scripts_classes | AbilityUnlockTrigger
[  41% ] update_scripts_classes | HintService
[  41% ] update_scripts_classes | PuzzleCompletionZone
[  42% ] update_scripts_classes | PuzzleDef
[  43% ] update_scripts_classes | PuzzleService
[  43% ] update_scripts_classes | ResetAnchor
[  44% ] update_scripts_classes | CheckpointZone
[  45% ] update_scripts_classes | RoomRouter
[  45% ] update_scripts_classes | SafeAnchor
[  46% ] update_scripts_classes | SaveStore
[  47% ] update_scripts_classes | GameSession
[  47% ] update_scripts_classes | IdRegistry
[  48% ] update_scripts_classes | InteractionResult
[  49% ] update_scripts_classes | InteractionService
[  49% ] update_scripts_classes | SimClock
[  50% ] update_scripts_classes | 
[  50% ] update_scripts_classes | ChapterGraphDef
[  51% ] update_scripts_classes | DoorwayPresenter
[  52% ] update_scripts_classes | SpatialGraph
[  52% ] update_scripts_classes | SpatialService
[  53% ] update_scripts_classes | PlaytestLog
[  54% ] update_scripts_classes | TemporalComponent
[  54% ] update_scripts_classes | TemporalTestGate
[  55% ] update_scripts_classes | TemporalTestGear
[  56% ] update_scripts_classes | TemporalTestShutter
[  56% ] update_scripts_classes | AbilityWheel
[  57% ] update_scripts_classes | ChapterCompleteOverlay
[  58% ] update_scripts_classes | DialogueBox
[  58% ] update_scripts_classes | DialogueTrigger
[  59% ] update_scripts_classes | DocumentViewer
[  60% ] update_scripts_classes | HUD
[  60% ] update_scripts_classes | InputPrompts
[  61% ] update_scripts_classes | JournalScreen
[  62% ] update_scripts_classes | 
[  62% ] update_scripts_classes | UIFeedback
[  63% ] update_scripts_classes | UITheme
[  64% ] update_scripts_classes | 
[  64% ] update_scripts_classes | 
[  65% ] update_scripts_classes | 
[  66% ] update_scripts_classes | 
[  66% ] update_scripts_classes | 
[  67% ] update_scripts_classes | 
[  68% ] update_scripts_classes | 
[  68% ] update_scripts_classes | 
[  69% ] update_scripts_classes | 
[  70% ] update_scripts_classes | 
[  70% ] update_scripts_classes | 
[  71% ] update_scripts_classes | 
[  72% ] update_scripts_classes | 
[  72% ] update_scripts_classes | 
[  73% ] update_scripts_classes | 
[  74% ] update_scripts_classes | 
[  74% ] update_scripts_classes | 
[  75% ] update_scripts_classes | 
[  76% ] update_scripts_classes | 
[  76% ] update_scripts_classes | 
[  77% ] update_scripts_classes | 
[  78% ] update_scripts_classes | 
[  78% ] update_scripts_classes | 
[  79% ] update_scripts_classes | 
[  80% ] update_scripts_classes | 
[  80% ] update_scripts_classes | 
[  81% ] update_scripts_classes | 
[  82% ] update_scripts_classes | 
[  82% ] update_scripts_classes | 
[  83% ] update_scripts_classes | 
[  84% ] update_scripts_classes | 
[  84% ] update_scripts_classes | 
[  85% ] update_scripts_classes | 
[  86% ] update_scripts_classes | 
[  86% ] update_scripts_classes | 
[  87% ] update_scripts_classes | 
[  88% ] update_scripts_classes | 
[  88% ] update_scripts_classes | 
[  89% ] update_scripts_classes | 
[  90% ] update_scripts_classes | 
[  90% ] update_scripts_classes | 
[  91% ] update_scripts_classes | 
[  92% ] update_scripts_classes | 
[  92% ] update_scripts_classes | 
[  93% ] update_scripts_classes | 
[  94% ] update_scripts_classes | 
[  94% ] update_scripts_classes | 
[  95% ] update_scripts_classes | 
[  96% ] update_scripts_classes | 
[  96% ] update_scripts_classes | 
[  97% ] update_scripts_classes | 
[  98% ] update_scripts_classes | 
[  98% ] update_scripts_classes | 
[ DONE ] update_scripts_classes

[   0% ] _update_scan_actions | Started Scanning actions... (262 steps)
[   0% ] _update_scan_actions | ch01_char_elias_base_sheet.png
[   0% ] _update_scan_actions | ch01_char_operator_sighting_ne_sheet.png
[   0% ] _update_scan_actions | ch01_char_statue_body_a_pose1_idle.png
[   1% ] _update_scan_actions | ch01_char_statue_body_a_pose1_read.png
[   1% ] _update_scan_actions | ch01_char_statue_body_a_pose2_idle.png
[   1% ] _update_scan_actions | ch01_char_statue_body_a_pose2_read.png
[   2% ] _update_scan_actions | ch01_char_statue_body_b_pose1_idle.png
[   2% ] _update_scan_actions | ch01_char_statue_body_b_pose1_read.png
[   3% ] _update_scan_actions | ch01_char_statue_body_b_pose2_idle.png
[   3% ] _update_scan_actions | ch01_char_statue_body_b_pose2_read.png
[   3% ] _update_scan_actions | ch01_char_statue_body_c_pose1_idle.png
[   4% ] _update_scan_actions | ch01_char_statue_body_c_pose1_read.png
[   4% ] _update_scan_actions | ch01_char_statue_body_c_pose2_idle.png
[   4% ] _update_scan_actions | ch01_char_statue_body_c_pose2_read.png
[   5% ] _update_scan_actions | ch01_char_statue_commuter_n01_conductor_idle.png
[   5% ] _update_scan_actions | ch01_char_statue_commuter_n01_conductor_read.png
[   6% ] _update_scan_actions | ch01_char_statue_commuter_n02_student_idle.png
[   6% ] _update_scan_actions | ch01_char_statue_commuter_n02_student_read.png
[   6% ] _update_scan_actions | ch01_char_statue_commuter_n03_old_man_idle.png
[   7% ] _update_scan_actions | ch01_char_statue_commuter_n03_old_man_read.png
[   7% ] _update_scan_actions | ch01_char_statue_commuter_n04_cleaner_idle.png
[   7% ] _update_scan_actions | ch01_char_statue_commuter_n04_cleaner_read.png
[   8% ] _update_scan_actions | ch01_char_statue_commuter_n05_courier_idle.png
[   8% ] _update_scan_actions | ch01_char_statue_commuter_n05_courier_read.png
[   9% ] _update_scan_actions | ch01_char_statue_commuter_n06_red_coat_idle.png
[   9% ] _update_scan_actions | ch01_char_statue_commuter_n06_red_coat_read.png
[   9% ] _update_scan_actions | ch01_char_statue_commuter_n07_briefcase_idle.png
[  10% ] _update_scan_actions | ch01_char_statue_commuter_n07_briefcase_read.png
[  10% ] _update_scan_actions | ch01_char_statue_commuter_n08_father_idle.png
[  11% ] _update_scan_actions | ch01_char_statue_commuter_n08_father_read.png
[  11% ] _update_scan_actions | ch01_char_statue_commuter_n09_teen_idle.png
[  11% ] _update_scan_actions | ch01_char_statue_commuter_n09_teen_read.png
[  12% ] _update_scan_actions | ch01_char_statue_commuter_n11_hatch_tech_idle.png
[  12% ] _update_scan_actions | ch01_char_statue_commuter_n11_hatch_tech_read.png
[  12% ] _update_scan_actions | ch01_char_statue_commuter_n13_guard_idle.png
[  13% ] _update_scan_actions | ch01_char_statue_commuter_n13_guard_read.png
[  13% ] _update_scan_actions | ch01_char_statue_commuter_n20_engineer_idle.png
[  14% ] _update_scan_actions | ch01_char_statue_commuter_n20_engineer_read.png
[  14% ] _update_scan_actions | ch01_char_statue_commuter_n21_tourist_idle.png
[  14% ] _update_scan_actions | ch01_char_statue_commuter_n21_tourist_read.png
[  15% ] _update_scan_actions | ch01_char_statue_n03_old_man_seated_idle.png
[  15% ] _update_scan_actions | ch01_char_statue_n03_old_man_seated_read.png
[  15% ] _update_scan_actions | ch01_char_statue_n04_cleaner_idle.png
[  16% ] _update_scan_actions | ch01_char_statue_n04_cleaner_read.png
[  16% ] _update_scan_actions | ch01_char_statue_n05_courier_vault_idle.png
[  17% ] _update_scan_actions | ch01_char_statue_n05_courier_vault_read.png
[  17% ] _update_scan_actions | ch01_char_statue_n11_tech_crank_idle.png
[  17% ] _update_scan_actions | ch01_char_statue_n11_tech_crank_read.png
[  18% ] _update_scan_actions | ch01_env_archway_frame_e_idle.png
[  18% ] _update_scan_actions | ch01_env_archway_frame_n_idle.png
[  19% ] _update_scan_actions | ch01_env_arrival_platform_target_sheet.png
[  19% ] _update_scan_actions | ch01_env_beat10_city_backdrop_idle.png
[  19% ] _update_scan_actions | ch01_env_beat10_city_plate_idle.png
[  20% ] _update_scan_actions | ch01_env_beat10_suspended_rain_idle.png
[  20% ] _update_scan_actions | ch01_env_tile_cable_conduit_off_idle.png
[  20% ] _update_scan_actions | ch01_env_tile_cable_conduit_on_idle.png
[  21% ] _update_scan_actions | ch01_env_tile_concrete_service_idle.png
[  21% ] _update_scan_actions | ch01_env_tile_industrial_grating_idle.png
[  22% ] _update_scan_actions | ch01_env_tile_stone_step_wet_idle.png
[  22% ] _update_scan_actions | ch01_env_tile_tactile_amber_idle.png
[  22% ] _update_scan_actions | ch01_env_tile_terrazzo_cracked_idle.png
[  23% ] _update_scan_actions | ch01_env_tile_terrazzo_dark_idle.png
[  23% ] _update_scan_actions | ch01_env_wall_bulkhead_module_idle.png
[  23% ] _update_scan_actions | ch01_env_wall_corner_pillar_idle.png
[  24% ] _update_scan_actions | ch01_env_wall_railing_iron_idle.png
[  24% ] _update_scan_actions | ch01_env_wall_subterranean_n_idle.png
[  25% ] _update_scan_actions | ch01_env_wall_subterranean_w_idle.png
[  25% ] _update_scan_actions | ch01_fx_operator_sighting_trace_ring_idle.png
[  25% ] _update_scan_actions | ch01_prop_alarm_plate_idle.png
[  26% ] _update_scan_actions | ch01_prop_alarm_plate_ringing.png
[  26% ] _update_scan_actions | ch01_prop_bell_icon_idle.png
[  26% ] _update_scan_actions | ch01_prop_bell_icon_ringing.png
[  27% ] _update_scan_actions | ch01_prop_breaker_c_browned_out.png
[  27% ] _update_scan_actions | ch01_prop_breaker_c_engaged.png
[  28% ] _update_scan_actions | ch01_prop_breaker_c_idle.png
[  28% ] _update_scan_actions | ch01_prop_bridge_platform_extended.png
[  28% ] _update_scan_actions | ch01_prop_bridge_platform_retracted.png
[  29% ] _update_scan_actions | ch01_prop_call_box_phone_idle.png
[  29% ] _update_scan_actions | ch01_prop_call_box_phone_ringing.png
[  30% ] _update_scan_actions | ch01_prop_card_reader_accepted.png
[  30% ] _update_scan_actions | ch01_prop_card_reader_denied.png
[  30% ] _update_scan_actions | ch01_prop_card_reader_idle.png
[  31% ] _update_scan_actions | ch01_prop_conduit_fallen.png
[  31% ] _update_scan_actions | ch01_prop_conduit_mounted.png
[  31% ] _update_scan_actions | ch01_prop_counterweight_gear_frozen.png
[  32% ] _update_scan_actions | ch01_prop_counterweight_gear_idle.png
[  32% ] _update_scan_actions | ch01_prop_counterweight_gear_slipping.png
[  33% ] _update_scan_actions | ch01_prop_dead_relay_c_idle.png
[  33% ] _update_scan_actions | ch01_prop_dead_relay_c_shake.png
[  33% ] _update_scan_actions | ch01_prop_departure_board_nowhere_idle.png
[  34% ] _update_scan_actions | ch01_prop_digital_clock_2359_idle.png
[  34% ] _update_scan_actions | ch01_prop_dispatch_terminal_active.png
[  34% ] _update_scan_actions | ch01_prop_dispatch_terminal_idle.png
[  35% ] _update_scan_actions | ch01_prop_document_clipboard_idle.png
[  35% ] _update_scan_actions | ch01_prop_door_rd_access_sealed_idle.png
[  36% ] _update_scan_actions | ch01_prop_echo_pedestal_idle.png
[  36% ] _update_scan_actions | ch01_prop_echo_pedestal_used.png
[  36% ] _update_scan_actions | ch01_prop_fire_shutter_closed.png
[  37% ] _update_scan_actions | ch01_prop_fire_shutter_raised.png
[  37% ] _update_scan_actions | ch01_prop_flap_dial_line_idle.png
[  38% ] _update_scan_actions | ch01_prop_flap_dial_line_jammed.png
[  38% ] _update_scan_actions | ch01_prop_flap_dial_platform_idle.png
[  38% ] _update_scan_actions | ch01_prop_flap_dial_platform_jammed.png
[  39% ] _update_scan_actions | ch01_prop_flap_dial_time_idle.png
[  39% ] _update_scan_actions | ch01_prop_flap_dial_time_jammed.png
[  39% ] _update_scan_actions | ch01_prop_floor_plate_a_empty.png
[  40% ] _update_scan_actions | ch01_prop_floor_plate_a_pressed.png
[  40% ] _update_scan_actions | ch01_prop_floor_plate_b_empty.png
[  41% ] _update_scan_actions | ch01_prop_floor_plate_b_pressed.png
[  41% ] _update_scan_actions | ch01_prop_inner_shutter_closed.png
[  41% ] _update_scan_actions | ch01_prop_inner_shutter_raised.png
[  42% ] _update_scan_actions | ch01_prop_lever_badge_a_idle.png
[  42% ] _update_scan_actions | ch01_prop_lever_badge_b_idle.png
[  42% ] _update_scan_actions | ch01_prop_lever_switch_off.png
[  43% ] _update_scan_actions | ch01_prop_lever_switch_on.png
[  43% ] _update_scan_actions | ch01_prop_notice_closed_track_idle.png
[  44% ] _update_scan_actions | ch01_prop_pa_speaker_idle.png
[  44% ] _update_scan_actions | ch01_prop_pillar_mark_sector_a_idle.png
[  44% ] _update_scan_actions | ch01_prop_platform_gate_closed.png
[  45% ] _update_scan_actions | ch01_prop_platform_gate_open.png
[  45% ] _update_scan_actions | ch01_prop_pocket_watch_idle.png
[  46% ] _update_scan_actions | ch01_prop_pressure_switch_pressed.png
[  46% ] _update_scan_actions | ch01_prop_pressure_switch_released.png
[  46% ] _update_scan_actions | ch01_prop_release_lever_accepted.png
[  47% ] _update_scan_actions | ch01_prop_release_lever_buzzing.png
[  47% ] _update_scan_actions | ch01_prop_release_lever_idle.png
[  47% ] _update_scan_actions | ch01_prop_reset_console_idle.png
[  48% ] _update_scan_actions | ch01_prop_route_board_state0.png
[  48% ] _update_scan_actions | ch01_prop_route_board_state1.png
[  49% ] _update_scan_actions | ch01_prop_route_board_state2.png
[  49% ] _update_scan_actions | ch01_prop_security_gate_closed.png
[  49% ] _update_scan_actions | ch01_prop_security_gate_open.png
[  50% ] _update_scan_actions | ch01_prop_selector_car_pos0.png
[  50% ] _update_scan_actions | ch01_prop_selector_car_pos1.png
[  50% ] _update_scan_actions | ch01_prop_selector_car_pos2.png
[  51% ] _update_scan_actions | ch01_prop_selector_line_pos0.png
[  51% ] _update_scan_actions | ch01_prop_selector_line_pos1.png
[  52% ] _update_scan_actions | ch01_prop_selector_line_pos2.png
[  52% ] _update_scan_actions | ch01_prop_selector_platform_pos0.png
[  52% ] _update_scan_actions | ch01_prop_selector_platform_pos1.png
[  53% ] _update_scan_actions | ch01_prop_selector_platform_pos2.png
[  53% ] _update_scan_actions | ch01_prop_service_hatch_closed.png
[  53% ] _update_scan_actions | ch01_prop_service_hatch_frozen_closed.png
[  54% ] _update_scan_actions | ch01_prop_service_hatch_frozen_open.png
[  54% ] _update_scan_actions | ch01_prop_service_hatch_open.png
[  55% ] _update_scan_actions | ch01_prop_sign_a1_research_idle.png
[  55% ] _update_scan_actions | ch01_prop_staff_barrier_closed.png
[  55% ] _update_scan_actions | ch01_prop_staff_barrier_open.png
[  56% ] _update_scan_actions | ch01_prop_staff_door_closed.png
[  56% ] _update_scan_actions | ch01_prop_staff_door_open.png
[  57% ] _update_scan_actions | ch01_prop_standby_plate_empty.png
[  57% ] _update_scan_actions | ch01_prop_standby_plate_held.png
[  57% ] _update_scan_actions | ch01_prop_station_bench_idle.png
[  58% ] _update_scan_actions | ch01_prop_statue_ov_breaker_handle_idle.png
[  58% ] _update_scan_actions | ch01_prop_statue_ov_breaker_handle_read.png
[  58% ] _update_scan_actions | ch01_prop_statue_ov_briefcase_idle.png
[  59% ] _update_scan_actions | ch01_prop_statue_ov_briefcase_read.png
[  59% ] _update_scan_actions | ch01_prop_statue_ov_courier_bag_idle.png
[  60% ] _update_scan_actions | ch01_prop_statue_ov_courier_bag_read.png
[  60% ] _update_scan_actions | ch01_prop_statue_ov_gate_lever_idle.png
[  60% ] _update_scan_actions | ch01_prop_statue_ov_gate_lever_read.png
[  61% ] _update_scan_actions | ch01_prop_statue_ov_hatch_crank_idle.png
[  61% ] _update_scan_actions | ch01_prop_statue_ov_hatch_crank_read.png
[  61% ] _update_scan_actions | ch01_prop_statue_ov_headphones_idle.png
[  62% ] _update_scan_actions | ch01_prop_statue_ov_headphones_read.png
[  62% ] _update_scan_actions | ch01_prop_statue_ov_map_idle.png
[  63% ] _update_scan_actions | ch01_prop_statue_ov_map_read.png
[  63% ] _update_scan_actions | ch01_prop_statue_ov_paper_bag_idle.png
[  63% ] _update_scan_actions | ch01_prop_statue_ov_paper_bag_read.png
[  64% ] _update_scan_actions | ch01_prop_statue_ov_phone_idle.png
[  64% ] _update_scan_actions | ch01_prop_statue_ov_phone_read.png
[  65% ] _update_scan_actions | ch01_prop_statue_ov_red_coat_idle.png
[  65% ] _update_scan_actions | ch01_prop_statue_ov_red_coat_read.png
[  65% ] _update_scan_actions | ch01_prop_statue_ov_sleeping_child_idle.png
[  66% ] _update_scan_actions | ch01_prop_statue_ov_sleeping_child_read.png
[  66% ] _update_scan_actions | ch01_prop_statue_ov_suitcase_idle.png
[  66% ] _update_scan_actions | ch01_prop_statue_ov_suitcase_read.png
[  67% ] _update_scan_actions | ch01_prop_statue_ov_trolley_idle.png
[  67% ] _update_scan_actions | ch01_prop_statue_ov_trolley_read.png
[  68% ] _update_scan_actions | ch01_prop_statue_ov_whistle_idle.png
[  68% ] _update_scan_actions | ch01_prop_statue_ov_whistle_read.png
[  68% ] _update_scan_actions | ch01_prop_surge_capacitor_charged.png
[  69% ] _update_scan_actions | ch01_prop_surge_capacitor_discharged.png
[  69% ] _update_scan_actions | ch01_prop_surge_capacitor_frozen.png
[  69% ] _update_scan_actions | ch01_prop_surge_capacitor_frozen_charged.png
[  70% ] _update_scan_actions | ch01_prop_surge_capacitor_frozen_discharged.png
[  70% ] _update_scan_actions | ch01_prop_ticket_terms_notice_idle.png
[  71% ] _update_scan_actions | ch01_prop_ticket_validator_accepted.png
[  71% ] _update_scan_actions | ch01_prop_ticket_validator_idle.png
[  71% ] _update_scan_actions | ch01_prop_ticket_validator_rejecting.png
[  72% ] _update_scan_actions | ch01_prop_trace_shimmer_ring_loop.png
[  72% ] _update_scan_actions | ch01_prop_trace_timestamp_glyph_idle.png
[  73% ] _update_scan_actions | ch01_prop_transit_car_stalled_idle.png
[  73% ] _update_scan_actions | ch01_prop_turnstile_gate_collapsed.png
[  73% ] _update_scan_actions | ch01_prop_turnstile_gate_open.png
[  74% ] _update_scan_actions | ch01_ui_icon_echo.png
[  74% ] _update_scan_actions | ch01_ui_icon_echo_locked.png
[  74% ] _update_scan_actions | ch01_ui_icon_fast_forward.png
[  75% ] _update_scan_actions | ch01_ui_icon_fast_forward_locked.png
[  75% ] _update_scan_actions | ch01_ui_icon_freeze.png
[  76% ] _update_scan_actions | ch01_ui_icon_freeze_locked.png
[  76% ] _update_scan_actions | ch01_ui_icon_rewind.png
[  76% ] _update_scan_actions | ch01_ui_icon_rewind_locked.png
[  77% ] _update_scan_actions | ch01_ui_icon_trace.png
[  77% ] _update_scan_actions | ch01_ui_icon_trace_locked.png
[  77% ] _update_scan_actions | ch01_ui_icon_unknown.png
[  78% ] _update_scan_actions | ch01_ui_icon_unknown_locked.png
[  78% ] _update_scan_actions | ch01_ui_lock_glyph.png
[  79% ] _update_scan_actions | ch01_ui_wheel_face.png
[  79% ] _update_scan_actions | ch01_ui_wheel_pointer_0.png
[  79% ] _update_scan_actions | ch01_ui_wheel_pointer_1.png
[  80% ] _update_scan_actions | ch01_ui_wheel_pointer_2.png
[  80% ] _update_scan_actions | ch01_ui_wheel_pointer_3.png
[  80% ] _update_scan_actions | ch01_ui_wheel_pointer_4.png
[  81% ] _update_scan_actions | ch01_ui_wheel_pointer_5.png
[  81% ] _update_scan_actions | ch01_ui_wheel_pointer_rest.png
[  82% ] _update_scan_actions | ch01_ui_wheel_seg0_locked.png
[  82% ] _update_scan_actions | ch01_ui_wheel_seg0_normal.png
[  82% ] _update_scan_actions | ch01_ui_wheel_seg0_selected.png
[  83% ] _update_scan_actions | ch01_ui_wheel_seg1_locked.png
[  83% ] _update_scan_actions | ch01_ui_wheel_seg1_normal.png
[  84% ] _update_scan_actions | ch01_ui_wheel_seg1_selected.png
[  84% ] _update_scan_actions | ch01_ui_wheel_seg2_locked.png
[  84% ] _update_scan_actions | ch01_ui_wheel_seg2_normal.png
[  85% ] _update_scan_actions | ch01_ui_wheel_seg2_selected.png
[  85% ] _update_scan_actions | ch01_ui_wheel_seg3_locked.png
[  85% ] _update_scan_actions | ch01_ui_wheel_seg3_normal.png
[  86% ] _update_scan_actions | ch01_ui_wheel_seg3_selected.png
[  86% ] _update_scan_actions | ch01_ui_wheel_seg4_locked.png
[  87% ] _update_scan_actions | ch01_ui_wheel_seg4_normal.png
[  87% ] _update_scan_actions | ch01_ui_wheel_seg4_selected.png
[  87% ] _update_scan_actions | ch01_ui_wheel_seg5_locked.png
[  88% ] _update_scan_actions | ch01_ui_wheel_seg5_normal.png
[  88% ] _update_scan_actions | ch01_ui_wheel_seg5_selected.png
[  88% ] _update_scan_actions | ch01_ui_mira_broadcast_portrait_idle.png
[  89% ] _update_scan_actions | tlf_pixel_mono.ttf
[  89% ] _update_scan_actions | ch01_ability_wheel_a_trace_only_mockup.png
[  90% ] _update_scan_actions | ch01_ability_wheel_b_all_four_mockup.png
[  90% ] _update_scan_actions | ch01_ability_wheel_c_rewind_selected_mockup.png
[  90% ] _update_scan_actions | ch01_ability_wheel_greyscale_proof.png
[  91% ] _update_scan_actions | ch01_arrival_platform_mockup.png
[  91% ] _update_scan_actions | ch01_beat10_city_pan_end_640x360_mockup.png
[  92% ] _update_scan_actions | ch01_beat10_city_pan_start_640x360_mockup.png
[  92% ] _update_scan_actions | ch01_beat10_city_plate_greyscale_proof.png
[  92% ] _update_scan_actions | ch01_concourse_west_mockup.png
[  93% ] _update_scan_actions | ch01_operator_cast_silhouette_greyscale_proof.png
[  93% ] _update_scan_actions | ch01_operator_sighting_platform_mockup.png
[  93% ] _update_scan_actions | ch01_security_crossing_mockup.png
[  94% ] _update_scan_actions | ch01_signal_control_mockup.png
[  94% ] _update_scan_actions | ch01_step1_props_greyscale_proof.png
[  95% ] _update_scan_actions | ch01_step1_room_statues_greyscale_proof.png
[  95% ] _update_scan_actions | ch01_step1_room_statues_mockup.png
[  95% ] _update_scan_actions | ch01_step1_room_statues_x3_proof.png
[  96% ] _update_scan_actions | ch01_step1_statues_all13_greyscale_proof.png
[  96% ] _update_scan_actions | ch01_tlf063_story_props_greyscale_proof.png
[  96% ] _update_scan_actions | ch01_tlf063_story_props_room_mockup.png
[  97% ] _update_scan_actions | TLF-044_capacitor_states.png
[  97% ] _update_scan_actions | TLF-044_capacitor_states_grey.png
[  98% ] _update_scan_actions | ch01_puzzles.csv
[  98% ] _update_scan_actions | ch01_text.csv
[  98% ] _update_scan_actions | ui_feedback.csv
[  99% ] _update_scan_actions | icon.svg
[ DONE ] _update_scan_actions

[   0% ] reimport | Started (Re)Importing Assets (262 steps)
[   0% ] reimport | Preparing files to reimport...
[   0% ] reimport | Preparing files to reimport...
[   0% ] reimport | Preparing files to reimport...
[   1% ] reimport | Preparing files to reimport...
[   1% ] reimport | Preparing files to reimport...
[   1% ] reimport | Preparing files to reimport...
[   2% ] reimport | Preparing files to reimport...
[   2% ] reimport | Preparing files to reimport...
[   3% ] reimport | Preparing files to reimport...
[   3% ] reimport | Preparing files to reimport...
[   3% ] reimport | Preparing files to reimport...
[   4% ] reimport | Preparing files to reimport...
[   4% ] reimport | Preparing files to reimport...
[   4% ] reimport | Preparing files to reimport...
[   5% ] reimport | Preparing files to reimport...
[   5% ] reimport | Preparing files to reimport...
[   6% ] reimport | Preparing files to reimport...
[   6% ] reimport | Preparing files to reimport...
[   6% ] reimport | Preparing files to reimport...
[   7% ] reimport | Preparing files to reimport...
[   7% ] reimport | Preparing files to reimport...
[   7% ] reimport | Preparing files to reimport...
[   8% ] reimport | Preparing files to reimport...
[   8% ] reimport | Preparing files to reimport...
[   9% ] reimport | Preparing files to reimport...
[   9% ] reimport | Preparing files to reimport...
[   9% ] reimport | Preparing files to reimport...
[  10% ] reimport | Preparing files to reimport...
[  10% ] reimport | Preparing files to reimport...
[  11% ] reimport | Preparing files to reimport...
[  11% ] reimport | Preparing files to reimport...
[  11% ] reimport | Preparing files to reimport...
[  12% ] reimport | Preparing files to reimport...
[  12% ] reimport | Preparing files to reimport...
[  12% ] reimport | Preparing files to reimport...
[  13% ] reimport | Preparing files to reimport...
[  13% ] reimport | Preparing files to reimport...
[  14% ] reimport | Preparing files to reimport...
[  14% ] reimport | Preparing files to reimport...
[  14% ] reimport | Preparing files to reimport...
[  15% ] reimport | Preparing files to reimport...
[  15% ] reimport | Preparing files to reimport...
[  15% ] reimport | Preparing files to reimport...
[  16% ] reimport | Preparing files to reimport...
[  16% ] reimport | Preparing files to reimport...
[  17% ] reimport | Preparing files to reimport...
[  17% ] reimport | Preparing files to reimport...
[  17% ] reimport | Preparing files to reimport...
[  18% ] reimport | Preparing files to reimport...
[  18% ] reimport | Preparing files to reimport...
[  19% ] reimport | Preparing files to reimport...
[  19% ] reimport | Preparing files to reimport...
[  19% ] reimport | Preparing files to reimport...
[  20% ] reimport | Preparing files to reimport...
[  20% ] reimport | Preparing files to reimport...
[  20% ] reimport | Preparing files to reimport...
[  21% ] reimport | Preparing files to reimport...
[  21% ] reimport | Preparing files to reimport...
[  22% ] reimport | Preparing files to reimport...
[  22% ] reimport | Preparing files to reimport...
[  22% ] reimport | Preparing files to reimport...
[  23% ] reimport | Preparing files to reimport...
[  23% ] reimport | Preparing files to reimport...
[  23% ] reimport | Preparing files to reimport...
[  24% ] reimport | Preparing files to reimport...
[  24% ] reimport | Preparing files to reimport...
[  25% ] reimport | Preparing files to reimport...
[  25% ] reimport | Preparing files to reimport...
[  25% ] reimport | Preparing files to reimport...
[  26% ] reimport | Preparing files to reimport...
[  26% ] reimport | Preparing files to reimport...
[  26% ] reimport | Preparing files to reimport...
[  27% ] reimport | Preparing files to reimport...
[  27% ] reimport | Preparing files to reimport...
[  28% ] reimport | Preparing files to reimport...
[  28% ] reimport | Preparing files to reimport...
[  28% ] reimport | Preparing files to reimport...
[  29% ] reimport | Preparing files to reimport...
[  29% ] reimport | Preparing files to reimport...
[  30% ] reimport | Preparing files to reimport...
[  30% ] reimport | Preparing files to reimport...
[  30% ] reimport | Preparing files to reimport...
[  31% ] reimport | Preparing files to reimport...
[  31% ] reimport | Preparing files to reimport...
[  31% ] reimport | Preparing files to reimport...
[  32% ] reimport | Preparing files to reimport...
[  32% ] reimport | Preparing files to reimport...
[  33% ] reimport | Preparing files to reimport...
[  33% ] reimport | Preparing files to reimport...
[  33% ] reimport | Preparing files to reimport...
[  34% ] reimport | Preparing files to reimport...
[  34% ] reimport | Preparing files to reimport...
[  34% ] reimport | Preparing files to reimport...
[  35% ] reimport | Preparing files to reimport...
[  35% ] reimport | Preparing files to reimport...
[  36% ] reimport | Preparing files to reimport...
[  36% ] reimport | Preparing files to reimport...
[  36% ] reimport | Preparing files to reimport...
[  37% ] reimport | Preparing files to reimport...
[  37% ] reimport | Preparing files to reimport...
[  38% ] reimport | Preparing files to reimport...
[  38% ] reimport | Preparing files to reimport...
[  38% ] reimport | Preparing files to reimport...
[  39% ] reimport | Preparing files to reimport...
[  39% ] reimport | Preparing files to reimport...
[  39% ] reimport | Preparing files to reimport...
[  40% ] reimport | Preparing files to reimport...
[  40% ] reimport | Preparing files to reimport...
[  41% ] reimport | Preparing files to reimport...
[  41% ] reimport | Preparing files to reimport...
[  41% ] reimport | Preparing files to reimport...
[  42% ] reimport | Preparing files to reimport...
[  42% ] reimport | Preparing files to reimport...
[  42% ] reimport | Preparing files to reimport...
[  43% ] reimport | Preparing files to reimport...
[  43% ] reimport | Preparing files to reimport...
[  44% ] reimport | Preparing files to reimport...
[  44% ] reimport | Preparing files to reimport...
[  44% ] reimport | Preparing files to reimport...
[  45% ] reimport | Preparing files to reimport...
[  45% ] reimport | Preparing files to reimport...
[  46% ] reimport | Preparing files to reimport...
[  46% ] reimport | Preparing files to reimport...
[  46% ] reimport | Preparing files to reimport...
[  47% ] reimport | Preparing files to reimport...
[  47% ] reimport | Preparing files to reimport...
[  47% ] reimport | Preparing files to reimport...
[  48% ] reimport | Preparing files to reimport...
[  48% ] reimport | Preparing files to reimport...
[  49% ] reimport | Preparing files to reimport...
[  49% ] reimport | Preparing files to reimport...
[  49% ] reimport | Preparing files to reimport...
[  50% ] reimport | Preparing files to reimport...
[  50% ] reimport | Preparing files to reimport...
[  50% ] reimport | Preparing files to reimport...
[  51% ] reimport | Preparing files to reimport...
[  51% ] reimport | Preparing files to reimport...
[  52% ] reimport | Preparing files to reimport...
[  52% ] reimport | Preparing files to reimport...
[  52% ] reimport | Preparing files to reimport...
[  53% ] reimport | Preparing files to reimport...
[  53% ] reimport | Preparing files to reimport...
[  53% ] reimport | Preparing files to reimport...
[  54% ] reimport | Preparing files to reimport...
[  54% ] reimport | Preparing files to reimport...
[  55% ] reimport | Preparing files to reimport...
[  55% ] reimport | Preparing files to reimport...
[  55% ] reimport | Preparing files to reimport...
[  56% ] reimport | Preparing files to reimport...
[  56% ] reimport | Preparing files to reimport...
[  57% ] reimport | Preparing files to reimport...
[  57% ] reimport | Preparing files to reimport...
[  57% ] reimport | Preparing files to reimport...
[  58% ] reimport | Preparing files to reimport...
[  58% ] reimport | Preparing files to reimport...
[  58% ] reimport | Preparing files to reimport...
[  59% ] reimport | Preparing files to reimport...
[  59% ] reimport | Preparing files to reimport...
[  60% ] reimport | Preparing files to reimport...
[  60% ] reimport | Preparing files to reimport...
[  60% ] reimport | Preparing files to reimport...
[  61% ] reimport | Preparing files to reimport...
[  61% ] reimport | Preparing files to reimport...
[  61% ] reimport | Preparing files to reimport...
[  62% ] reimport | Preparing files to reimport...
[  62% ] reimport | Preparing files to reimport...
[  63% ] reimport | Preparing files to reimport...
[  63% ] reimport | Preparing files to reimport...
[  63% ] reimport | Preparing files to reimport...
[  64% ] reimport | Preparing files to reimport...
[  64% ] reimport | Preparing files to reimport...
[  65% ] reimport | Preparing files to reimport...
[  65% ] reimport | Preparing files to reimport...
[  65% ] reimport | Preparing files to reimport...
[  66% ] reimport | Preparing files to reimport...
[  66% ] reimport | Preparing files to reimport...
[  66% ] reimport | Preparing files to reimport...
[  67% ] reimport | Preparing files to reimport...
[  67% ] reimport | Preparing files to reimport...
[  68% ] reimport | Preparing files to reimport...
[  68% ] reimport | Preparing files to reimport...
[  68% ] reimport | Preparing files to reimport...
[  69% ] reimport | Preparing files to reimport...
[  69% ] reimport | Preparing files to reimport...
[  69% ] reimport | Preparing files to reimport...
[  70% ] reimport | Preparing files to reimport...
[  70% ] reimport | Preparing files to reimport...
[  71% ] reimport | Preparing files to reimport...
[  71% ] reimport | Preparing files to reimport...
[  71% ] reimport | Preparing files to reimport...
[  72% ] reimport | Preparing files to reimport...
[  72% ] reimport | Preparing files to reimport...
[  73% ] reimport | Preparing files to reimport...
[  73% ] reimport | Preparing files to reimport...
[  73% ] reimport | Preparing files to reimport...
[  74% ] reimport | Preparing files to reimport...
[  74% ] reimport | Preparing files to reimport...
[  74% ] reimport | Preparing files to reimport...
[  75% ] reimport | Preparing files to reimport...
[  75% ] reimport | Preparing files to reimport...
[  76% ] reimport | Preparing files to reimport...
[  76% ] reimport | Preparing files to reimport...
[  76% ] reimport | Preparing files to reimport...
[  77% ] reimport | Preparing files to reimport...
[  77% ] reimport | Preparing files to reimport...
[  77% ] reimport | Preparing files to reimport...
[  78% ] reimport | Preparing files to reimport...
[  78% ] reimport | Preparing files to reimport...
[  79% ] reimport | Preparing files to reimport...
[  79% ] reimport | Preparing files to reimport...
[  79% ] reimport | Preparing files to reimport...
[  80% ] reimport | Preparing files to reimport...
[  80% ] reimport | Preparing files to reimport...
[  80% ] reimport | Preparing files to reimport...
[  81% ] reimport | Preparing files to reimport...
[  81% ] reimport | Preparing files to reimport...
[  82% ] reimport | Preparing files to reimport...
[  82% ] reimport | Preparing files to reimport...
[  82% ] reimport | Preparing files to reimport...
[  83% ] reimport | Preparing files to reimport...
[  83% ] reimport | Preparing files to reimport...
[  84% ] reimport | Preparing files to reimport...
[  84% ] reimport | Preparing files to reimport...
[  84% ] reimport | Preparing files to reimport...
[  85% ] reimport | Preparing files to reimport...
[  85% ] reimport | Preparing files to reimport...
[  85% ] reimport | Preparing files to reimport...
[  86% ] reimport | Preparing files to reimport...
[  86% ] reimport | Preparing files to reimport...
[  87% ] reimport | Preparing files to reimport...
[  87% ] reimport | Preparing files to reimport...
[  87% ] reimport | Preparing files to reimport...
[  88% ] reimport | Preparing files to reimport...
[  88% ] reimport | Preparing files to reimport...
[  88% ] reimport | Preparing files to reimport...
[  89% ] reimport | Preparing files to reimport...
[  89% ] reimport | Preparing files to reimport...
[  90% ] reimport | Preparing files to reimport...
[  90% ] reimport | Preparing files to reimport...
[  90% ] reimport | Preparing files to reimport...
[  91% ] reimport | Preparing files to reimport...
[  91% ] reimport | Preparing files to reimport...
[  92% ] reimport | Preparing files to reimport...
[  92% ] reimport | Preparing files to reimport...
[  92% ] reimport | Preparing files to reimport...
[  93% ] reimport | Preparing files to reimport...
[  93% ] reimport | Preparing files to reimport...
[  93% ] reimport | Preparing files to reimport...
[  94% ] reimport | Preparing files to reimport...
[  94% ] reimport | Preparing files to reimport...
[  95% ] reimport | Preparing files to reimport...
[  95% ] reimport | Preparing files to reimport...
[  95% ] reimport | Preparing files to reimport...
[  96% ] reimport | Preparing files to reimport...
[  96% ] reimport | Preparing files to reimport...
[  96% ] reimport | Preparing files to reimport...
[  97% ] reimport | Preparing files to reimport...
[  97% ] reimport | Preparing files to reimport...
[  98% ] reimport | Preparing files to reimport...
[  98% ] reimport | Preparing files to reimport...
[  98% ] reimport | Preparing files to reimport...
[  99% ] reimport | Preparing files to reimport...
[   0% ] reimport | Executing pre-reimport operations...
[   0% ] reimport | ui_feedback.csv
[   0% ] reimport | ch01_text.csv
[   0% ] reimport | ch01_puzzles.csv
[   1% ] reimport | tlf_pixel_mono.ttf
[   1% ] reimport | ui_feedback.csv
[   1% ] reimport | ch01_text.csv
[   2% ] reimport | ch01_puzzles.csv
[   2% ] reimport | tlf_pixel_mono.ttf
[   3% ] reimport | ch01_prop_statue_ov_trolley_idle.png
[   3% ] reimport | ch01_prop_statue_ov_suitcase_read.png
[   3% ] reimport | ch01_prop_statue_ov_suitcase_idle.png
[   4% ] reimport | ch01_prop_statue_ov_sleeping_child_read.png
[   4% ] reimport | ch01_prop_statue_ov_sleeping_child_idle.png
[   4% ] reimport | ch01_prop_statue_ov_red_coat_read.png
[   5% ] reimport | ch01_prop_statue_ov_red_coat_idle.png
[   5% ] reimport | ch01_prop_statue_ov_phone_read.png
[   6% ] reimport | ch01_prop_statue_ov_phone_idle.png
[   6% ] reimport | ch01_prop_statue_ov_paper_bag_read.png
[   6% ] reimport | ch01_prop_statue_ov_paper_bag_idle.png
[   7% ] reimport | ch01_prop_statue_ov_map_read.png
[   7% ] reimport | ch01_prop_statue_ov_map_idle.png
[   7% ] reimport | ch01_prop_statue_ov_headphones_read.png
[   8% ] reimport | ch01_prop_statue_ov_headphones_idle.png
[   8% ] reimport | ch01_prop_statue_ov_trolley_read.png
[   9% ] reimport | ch01_prop_statue_ov_whistle_idle.png
[   9% ] reimport | ch01_prop_statue_ov_whistle_read.png
[   9% ] reimport | ch01_prop_surge_capacitor_charged.png
[  10% ] reimport | ch01_prop_surge_capacitor_discharged.png
[  10% ] reimport | ch01_prop_surge_capacitor_frozen.png
[  11% ] reimport | ch01_prop_surge_capacitor_frozen_charged.png
[  11% ] reimport | ch01_prop_surge_capacitor_frozen_discharged.png
[  11% ] reimport | ch01_prop_ticket_terms_notice_idle.png
[  12% ] reimport | ch01_prop_ticket_validator_accepted.png
[  12% ] reimport | ch01_prop_ticket_validator_idle.png
[  12% ] reimport | ch01_prop_ticket_validator_rejecting.png
[  13% ] reimport | ch01_prop_trace_shimmer_ring_loop.png
[  13% ] reimport | ch01_prop_trace_timestamp_glyph_idle.png
[  14% ] reimport | ch01_prop_transit_car_stalled_idle.png
[  14% ] reimport | ch01_prop_turnstile_gate_collapsed.png
[  14% ] reimport | ch01_prop_security_gate_open.png
[  15% ] reimport | ch01_prop_selector_car_pos0.png
[  15% ] reimport | ch01_prop_selector_car_pos1.png
[  15% ] reimport | ch01_prop_selector_car_pos2.png
[  16% ] reimport | ch01_prop_selector_line_pos0.png
[  16% ] reimport | ch01_prop_selector_line_pos1.png
[  17% ] reimport | ch01_prop_selector_line_pos2.png
[  17% ] reimport | ch01_prop_selector_platform_pos0.png
[  17% ] reimport | ch01_prop_selector_platform_pos1.png
[  18% ] reimport | ch01_prop_selector_platform_pos2.png
[  18% ] reimport | ch01_prop_service_hatch_closed.png
[  19% ] reimport | ch01_prop_service_hatch_frozen_closed.png
[  19% ] reimport | ch01_prop_service_hatch_frozen_open.png
[  19% ] reimport | ch01_prop_service_hatch_open.png
[  20% ] reimport | ch01_prop_sign_a1_research_idle.png
[  20% ] reimport | ch01_prop_staff_barrier_closed.png
[  20% ] reimport | ch01_prop_staff_barrier_open.png
[  21% ] reimport | ch01_prop_staff_door_closed.png
[  21% ] reimport | ch01_prop_staff_door_open.png
[  22% ] reimport | ch01_prop_standby_plate_empty.png
[  22% ] reimport | ch01_prop_standby_plate_held.png
[  22% ] reimport | ch01_prop_station_bench_idle.png
[  23% ] reimport | ch01_prop_statue_ov_breaker_handle_idle.png
[  23% ] reimport | ch01_prop_statue_ov_breaker_handle_read.png
[  23% ] reimport | ch01_prop_statue_ov_briefcase_idle.png
[  24% ] reimport | ch01_prop_statue_ov_briefcase_read.png
[  24% ] reimport | ch01_prop_statue_ov_courier_bag_idle.png
[  25% ] reimport | ch01_prop_statue_ov_courier_bag_read.png
[  25% ] reimport | ch01_prop_statue_ov_gate_lever_idle.png
[  25% ] reimport | ch01_prop_statue_ov_gate_lever_read.png
[  26% ] reimport | ch01_prop_statue_ov_hatch_crank_idle.png
[  26% ] reimport | ch01_prop_statue_ov_hatch_crank_read.png
[  26% ] reimport | ch01_ui_wheel_seg3_normal.png
[  27% ] reimport | ch01_ui_wheel_seg3_selected.png
[  27% ] reimport | ch01_ui_wheel_seg4_locked.png
[  28% ] reimport | ch01_ui_wheel_seg4_normal.png
[  28% ] reimport | ch01_ui_wheel_seg4_selected.png
[  28% ] reimport | ch01_ui_wheel_seg5_locked.png
[  29% ] reimport | ch01_ui_wheel_seg5_normal.png
[  29% ] reimport | ch01_ui_wheel_seg5_selected.png
[  30% ] reimport | ch01_ui_mira_broadcast_portrait_idle.png
[  30% ] reimport | ch01_ability_wheel_a_trace_only_mockup.png
[  30% ] reimport | ch01_ability_wheel_b_all_four_mockup.png
[  31% ] reimport | ch01_ability_wheel_c_rewind_selected_mockup.png
[  31% ] reimport | ch01_ability_wheel_greyscale_proof.png
[  31% ] reimport | ch01_arrival_platform_mockup.png
[  32% ] reimport | ch01_beat10_city_pan_end_640x360_mockup.png
[  32% ] reimport | ch01_beat10_city_pan_start_640x360_mockup.png
[  33% ] reimport | ch01_beat10_city_plate_greyscale_proof.png
[  33% ] reimport | ch01_concourse_west_mockup.png
[  33% ] reimport | ch01_operator_cast_silhouette_greyscale_proof.png
[  34% ] reimport | ch01_operator_sighting_platform_mockup.png
[  34% ] reimport | ch01_security_crossing_mockup.png
[  34% ] reimport | ch01_signal_control_mockup.png
[  35% ] reimport | ch01_step1_props_greyscale_proof.png
[  35% ] reimport | ch01_step1_room_statues_greyscale_proof.png
[  36% ] reimport | ch01_step1_room_statues_mockup.png
[  36% ] reimport | ch01_step1_room_statues_x3_proof.png
[  36% ] reimport | ch01_step1_statues_all13_greyscale_proof.png
[  37% ] reimport | ch01_tlf063_story_props_greyscale_proof.png
[  37% ] reimport | ch01_tlf063_story_props_room_mockup.png
[  38% ] reimport | TLF-044_capacitor_states.png
[  38% ] reimport | TLF-044_capacitor_states_grey.png
[  38% ] reimport | icon.svg
[  39% ] reimport | ch01_prop_turnstile_gate_open.png
[  39% ] reimport | ch01_ui_icon_echo.png
[  39% ] reimport | ch01_ui_icon_echo_locked.png
[  40% ] reimport | ch01_ui_icon_fast_forward.png
[  40% ] reimport | ch01_ui_icon_fast_forward_locked.png
[  41% ] reimport | ch01_ui_icon_freeze.png
[  41% ] reimport | ch01_ui_icon_freeze_locked.png
[  41% ] reimport | ch01_ui_icon_rewind.png
[  42% ] reimport | ch01_ui_icon_rewind_locked.png
[  42% ] reimport | ch01_ui_icon_trace.png
[  42% ] reimport | ch01_ui_icon_trace_locked.png
[  43% ] reimport | ch01_ui_icon_unknown.png
[  43% ] reimport | ch01_ui_icon_unknown_locked.png
[  44% ] reimport | ch01_ui_lock_glyph.png
[  44% ] reimport | ch01_ui_wheel_face.png
[  44% ] reimport | ch01_ui_wheel_pointer_0.png
[  45% ] reimport | ch01_ui_wheel_pointer_1.png
[  45% ] reimport | ch01_ui_wheel_pointer_2.png
[  46% ] reimport | ch01_ui_wheel_pointer_3.png
[  46% ] reimport | ch01_ui_wheel_pointer_4.png
[  46% ] reimport | ch01_ui_wheel_pointer_5.png
[  47% ] reimport | ch01_ui_wheel_pointer_rest.png
[  47% ] reimport | ch01_ui_wheel_seg0_locked.png
[  47% ] reimport | ch01_ui_wheel_seg0_normal.png
[  48% ] reimport | ch01_ui_wheel_seg0_selected.png
[  48% ] reimport | ch01_ui_wheel_seg1_locked.png
[  49% ] reimport | ch01_ui_wheel_seg1_normal.png
[  49% ] reimport | ch01_ui_wheel_seg1_selected.png
[  49% ] reimport | ch01_ui_wheel_seg2_locked.png
[  50% ] reimport | ch01_ui_wheel_seg2_normal.png
[  50% ] reimport | ch01_ui_wheel_seg2_selected.png
[  50% ] reimport | ch01_ui_wheel_seg3_locked.png
[  51% ] reimport | ch01_char_statue_commuter_n11_hatch_tech_read.png
[  51% ] reimport | ch01_char_statue_commuter_n13_guard_idle.png
[  52% ] reimport | ch01_char_statue_commuter_n13_guard_read.png
[  52% ] reimport | ch01_char_statue_commuter_n20_engineer_idle.png
[  52% ] reimport | ch01_char_statue_commuter_n20_engineer_read.png
[  53% ] reimport | ch01_char_statue_commuter_n21_tourist_idle.png
[  53% ] reimport | ch01_char_statue_commuter_n21_tourist_read.png
[  53% ] reimport | ch01_char_statue_n03_old_man_seated_idle.png
[  54% ] reimport | ch01_char_statue_n03_old_man_seated_read.png
[  54% ] reimport | ch01_char_statue_n04_cleaner_idle.png
[  55% ] reimport | ch01_char_statue_n04_cleaner_read.png
[  55% ] reimport | ch01_char_statue_n05_courier_vault_idle.png
[  55% ] reimport | ch01_char_statue_n05_courier_vault_read.png
[  56% ] reimport | ch01_char_statue_n11_tech_crank_idle.png
[  56% ] reimport | ch01_char_statue_n11_tech_crank_read.png
[  57% ] reimport | ch01_env_archway_frame_e_idle.png
[  57% ] reimport | ch01_env_archway_frame_n_idle.png
[  57% ] reimport | ch01_env_arrival_platform_target_sheet.png
[  58% ] reimport | ch01_env_beat10_city_backdrop_idle.png
[  58% ] reimport | ch01_env_beat10_city_plate_idle.png
[  58% ] reimport | ch01_env_beat10_suspended_rain_idle.png
[  59% ] reimport | ch01_env_tile_cable_conduit_off_idle.png
[  59% ] reimport | ch01_env_tile_cable_conduit_on_idle.png
[  60% ] reimport | ch01_env_tile_concrete_service_idle.png
[  60% ] reimport | ch01_env_tile_industrial_grating_idle.png
[  60% ] reimport | ch01_env_tile_stone_step_wet_idle.png
[  61% ] reimport | ch01_env_tile_tactile_amber_idle.png
[  61% ] reimport | ch01_env_tile_terrazzo_cracked_idle.png
[  61% ] reimport | ch01_env_tile_terrazzo_dark_idle.png
[  62% ] reimport | ch01_env_wall_bulkhead_module_idle.png
[  62% ] reimport | ch01_env_wall_corner_pillar_idle.png
[  63% ] reimport | ch01_env_wall_railing_iron_idle.png
[  63% ] reimport | ch01_char_elias_base_sheet.png
[  63% ] reimport | ch01_char_operator_sighting_ne_sheet.png
[  64% ] reimport | ch01_char_statue_body_a_pose1_idle.png
[  64% ] reimport | ch01_char_statue_body_a_pose1_read.png
[  65% ] reimport | ch01_char_statue_body_a_pose2_idle.png
[  65% ] reimport | ch01_char_statue_body_a_pose2_read.png
[  65% ] reimport | ch01_char_statue_body_b_pose1_idle.png
[  66% ] reimport | ch01_char_statue_body_b_pose1_read.png
[  66% ] reimport | ch01_char_statue_body_b_pose2_idle.png
[  66% ] reimport | ch01_char_statue_body_b_pose2_read.png
[  67% ] reimport | ch01_char_statue_body_c_pose1_idle.png
[  67% ] reimport | ch01_char_statue_body_c_pose1_read.png
[  68% ] reimport | ch01_char_statue_body_c_pose2_idle.png
[  68% ] reimport | ch01_char_statue_body_c_pose2_read.png
[  68% ] reimport | ch01_char_statue_commuter_n01_conductor_idle.png
[  69% ] reimport | ch01_char_statue_commuter_n01_conductor_read.png
[  69% ] reimport | ch01_char_statue_commuter_n11_hatch_tech_idle.png
[  69% ] reimport | ch01_char_statue_commuter_n09_teen_read.png
[  70% ] reimport | ch01_char_statue_commuter_n09_teen_idle.png
[  70% ] reimport | ch01_char_statue_commuter_n08_father_read.png
[  71% ] reimport | ch01_char_statue_commuter_n08_father_idle.png
[  71% ] reimport | ch01_char_statue_commuter_n07_briefcase_read.png
[  71% ] reimport | ch01_char_statue_commuter_n07_briefcase_idle.png
[  72% ] reimport | ch01_char_statue_commuter_n06_red_coat_read.png
[  72% ] reimport | ch01_char_statue_commuter_n06_red_coat_idle.png
[  73% ] reimport | ch01_char_statue_commuter_n05_courier_read.png
[  73% ] reimport | ch01_char_statue_commuter_n05_courier_idle.png
[  73% ] reimport | ch01_char_statue_commuter_n04_cleaner_read.png
[  74% ] reimport | ch01_char_statue_commuter_n04_cleaner_idle.png
[  74% ] reimport | ch01_char_statue_commuter_n03_old_man_read.png
[  74% ] reimport | ch01_char_statue_commuter_n03_old_man_idle.png
[  75% ] reimport | ch01_char_statue_commuter_n02_student_read.png
[  75% ] reimport | ch01_char_statue_commuter_n02_student_idle.png
[  76% ] reimport | ch01_prop_fire_shutter_raised.png
[  76% ] reimport | ch01_prop_flap_dial_line_idle.png
[  76% ] reimport | ch01_prop_flap_dial_line_jammed.png
[  77% ] reimport | ch01_prop_flap_dial_platform_idle.png
[  77% ] reimport | ch01_prop_flap_dial_platform_jammed.png
[  77% ] reimport | ch01_prop_flap_dial_time_idle.png
[  78% ] reimport | ch01_prop_flap_dial_time_jammed.png
[  78% ] reimport | ch01_prop_floor_plate_a_empty.png
[  79% ] reimport | ch01_prop_floor_plate_a_pressed.png
[  79% ] reimport | ch01_prop_floor_plate_b_empty.png
[  79% ] reimport | ch01_prop_floor_plate_b_pressed.png
[  80% ] reimport | ch01_prop_inner_shutter_closed.png
[  80% ] reimport | ch01_prop_inner_shutter_raised.png
[  80% ] reimport | ch01_prop_lever_badge_a_idle.png
[  81% ] reimport | ch01_prop_lever_badge_b_idle.png
[  81% ] reimport | ch01_prop_lever_switch_off.png
[  82% ] reimport | ch01_prop_security_gate_closed.png
[  82% ] reimport | ch01_prop_route_board_state2.png
[  82% ] reimport | ch01_prop_route_board_state1.png
[  83% ] reimport | ch01_prop_route_board_state0.png
[  83% ] reimport | ch01_prop_reset_console_idle.png
[  84% ] reimport | ch01_prop_release_lever_idle.png
[  84% ] reimport | ch01_prop_release_lever_buzzing.png
[  84% ] reimport | ch01_prop_release_lever_accepted.png
[  85% ] reimport | ch01_prop_pressure_switch_released.png
[  85% ] reimport | ch01_prop_pressure_switch_pressed.png
[  85% ] reimport | ch01_prop_pocket_watch_idle.png
[  86% ] reimport | ch01_prop_platform_gate_open.png
[  86% ] reimport | ch01_prop_platform_gate_closed.png
[  87% ] reimport | ch01_prop_pillar_mark_sector_a_idle.png
[  87% ] reimport | ch01_prop_pa_speaker_idle.png
[  87% ] reimport | ch01_prop_notice_closed_track_idle.png
[  88% ] reimport | ch01_prop_lever_switch_on.png
[  88% ] reimport | ch01_env_wall_subterranean_n_idle.png
[  88% ] reimport | ch01_env_wall_subterranean_w_idle.png
[  89% ] reimport | ch01_fx_operator_sighting_trace_ring_idle.png
[  89% ] reimport | ch01_prop_alarm_plate_idle.png
[  90% ] reimport | ch01_prop_alarm_plate_ringing.png
[  90% ] reimport | ch01_prop_bell_icon_idle.png
[  90% ] reimport | ch01_prop_bell_icon_ringing.png
[  91% ] reimport | ch01_prop_breaker_c_browned_out.png
[  91% ] reimport | ch01_prop_breaker_c_engaged.png
[  92% ] reimport | ch01_prop_breaker_c_idle.png
[  92% ] reimport | ch01_prop_bridge_platform_extended.png
[  92% ] reimport | ch01_prop_bridge_platform_retracted.png
[  93% ] reimport | ch01_prop_call_box_phone_idle.png
[  93% ] reimport | ch01_prop_call_box_phone_ringing.png
[  93% ] reimport | ch01_prop_card_reader_accepted.png
[  94% ] reimport | ch01_prop_card_reader_denied.png
[  94% ] reimport | ch01_prop_fire_shutter_closed.png
[  95% ] reimport | ch01_prop_echo_pedestal_used.png
[  95% ] reimport | ch01_prop_echo_pedestal_idle.png
[  95% ] reimport | ch01_prop_door_rd_access_sealed_idle.png
[  96% ] reimport | ch01_prop_document_clipboard_idle.png
[  96% ] reimport | ch01_prop_dispatch_terminal_idle.png
[  96% ] reimport | ch01_prop_dispatch_terminal_active.png
[  97% ] reimport | ch01_prop_digital_clock_2359_idle.png
[  97% ] reimport | ch01_prop_departure_board_nowhere_idle.png
[  98% ] reimport | ch01_prop_dead_relay_c_shake.png
[  98% ] reimport | ch01_prop_dead_relay_c_idle.png
[  98% ] reimport | ch01_prop_counterweight_gear_slipping.png
[  99% ] reimport | ch01_prop_counterweight_gear_idle.png
[  99% ] reimport | Finalizing Asset Import...
[ DONE ] reimport

[   0% ] reimport | Started (Re)Importing Assets (262 steps)
[   0% ] reimport | Executing post-reimport operations...
[ DONE ] reimport

[   0% ] loading_editor_layout | Started Loading editor (5 steps)
[   0% ] loading_editor_layout | Loading editor layout...
[  16% ] loading_editor_layout | Loading docks...
[ DONE ] loading_editor_layout

Import check passed with zero errors.

[2/3] Checking that every GDScript parses...
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Script check: 150 scripts, 0 failed.
Settings: headless, path = user://headless/settings.cfg (C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Verify 3e51375/headless/settings.cfg)
SaveStore: headless, root = user://headless/saves (C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Verify 3e51375/headless/saves)
Leak check: clean (script check)

[3/3] Running headless automated test suite...
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Settings: headless, path = user://headless/settings.cfg (C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Verify 3e51375/headless/settings.cfg)
SaveStore: headless, root = user://headless/saves (C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Verify 3e51375/headless/saves)
--- Running Test Suite ---
Test file: res://tests/chapters/ch01/test_ch01_art_integration.gd
  PASS: test_collision_freeze_all_10_rooms
  PASS: test_intercom_reach_walkable
  PASS: test_no_greybox_nodes_remain_across_all_rooms
  PASS: test_puzzle_prop_presenter_state_mappings
  PASS: test_real_save_unmodified
  PASS: test_room1_arrival_platform_kit_complete
Test file: res://tests/chapters/ch01/test_ch01_narrative_beats.gd
  PASS: test_all_narrative_text_keys_localized_and_ascii
  PASS: test_beat01_platform_awakening_and_watch_pickup
  PASS: test_beat01_player_moves_immediately_and_dialogue_auto_advances
  PASS: test_beat03_call_box_09
  PASS: test_beat05_security_crossing_pa_speaker_echo
  PASS: test_beat06_waiting_lounge_trace_bench_and_mira_audio
  PASS: test_beat07_signal_control_intercom_warning_once
  PASS: test_beat08_upper_vestibule_loop_detection
  PASS: test_beat09_dispatch_terminal_revelation
  PASS: test_beat10_outro_and_chapter_complete
  PASS: test_clocks_2359_are_reusable
  PASS: test_movement_hint_lifecycle
Test file: res://tests/chapters/ch01/test_ch01_playthrough.gd
  PASS: test_chapter01_scene_initialization_and_graph_validation
  PASS: test_doorways_match_chapter_graph_def
  PASS: test_every_door_has_spawn_outside_presenter_shape
  PASS: test_gate_blockers_cover_door_triggers_from_all_approach_vectors
  PASS: test_intercom_adds_operator_warning_after_pz004
  PASS: test_interior_apertures_walkable_with_real_player_capsule
  PASS: test_object_specific_feedback_deferred_flow
  PASS: test_passage_blockers_toggle_with_puzzle_state
  PASS: test_puzzle_objects_configured_with_correct_exports
  PASS: test_pz004_route_is_at_least_600_px
  PASS: test_pz005_levers_and_resetter_configuration
  PASS: test_readables_apply_flags_fragments_and_journal
  PASS: test_room_object_ids_are_valid_and_unique
  PASS: test_room_scenes_exist_and_instantiate
  PASS: test_safe_anchors_and_checkpoints_match_specs
  PASS: test_scripted_playthrough_full_chapter_rooms_1_to_10
  PASS: test_scripted_playthrough_rooms_1_to_4
  PASS: test_street_exit_trigger_outro_completes_chapter
  PASS: test_watch_pickup_shows_unlock_trace_toast_without_regrant
Test file: res://tests/chapters/ch01/test_ch01_pz002_negative.gd
  INFO: PZ-002 no-Freeze run (assist off, window 180 ticks): Rewind from (384.7212, 145.9502); gap passed after 14 ticks at (384.7212, 167.9502); exit trigger (SOLVED) after never; shutter closed after 180 ticks; left east after never; player now (448.9129, 171.761) in ch01.maintenance_bay
  PASS: test_pz002_cannot_be_solved_without_freeze_assist_off
  INFO: PZ-002 no-Freeze run (assist on, window 300 ticks): Rewind from (384.7212, 145.9502); gap passed after 14 ticks at (384.7212, 167.9502); exit trigger (SOLVED) after never; shutter closed after 300 ticks; left east after never; player now (448.9129, 171.761) in ch01.maintenance_bay
  PASS: test_pz002_cannot_be_solved_without_freeze_assist_on
Test file: res://tests/chapters/ch01/test_ch01_pz004_layout.gd
  PASS: test_breaker_b_unreachable_from_south_of_north_railing
  PASS: test_exit_trigger_unskippable_on_path_to_door_exit_north
  PASS: test_north_barrier_visual_and_collision_match
  PASS: test_railings_physically_seal_lanes_at_walls
  PASS: test_shortest_walkable_path_between_breakers_exceeds_600_px
Test file: res://tests/chapters/ch01/test_ch01_pz004_saveload.gd
  PASS: test_f1_save_with_a_recorded_echo
  PASS: test_f2_save_while_the_echo_replays
  PASS: test_f3_save_after_a_brownout
  PASS: test_f4_save_after_solved
Test file: res://tests/chapters/ch01/test_ch01_real_playthrough.gd
  INFO: playthrough | 1 arrival (SO-01)                     591 frames (9.85 s)
  INFO: playthrough | 2a concourse PZ-001                   160 frames (2.67 s)
  INFO: playthrough | 2b concourse PZ-006                   367 frames (6.12 s)
  INFO: playthrough | 3a bay SO-02                           87 frames (1.45 s)
  INFO: playthrough | 3b bay PZ-002                         138 frames (2.30 s)
  INFO: playthrough | 4 crossing PZ-003                     304 frames (5.07 s)
  INFO: playthrough | 5 lounge (audio log, exit)             93 frames (1.55 s)
  INFO: playthrough | 6a PZ-004 step 1 (Rewind+Freeze)      214 frames (3.57 s)
  INFO: playthrough | 6b PZ-004 step 2 (Echo + Z-route)     440 frames (7.33 s)
  INFO: playthrough | 6c PZ-004 exit                         62 frames (1.03 s)
  INFO: playthrough | 7 vestibule PZ-005 (levers)           358 frames (5.97 s)
  INFO: playthrough | 9 atrium terminal (Beat 09)           136 frames (2.27 s)
  INFO: playthrough | 10 street exit outro (Beat 10)         55 frames (0.92 s)
  INFO: real-input playthrough took 3005 physics frames (50.1 s game time, 50.18 s wall)
  INFO: SOLVED ticks [[&"CH1-SO-01", 571], [&"CH1-PZ-001", 751], [&"CH1-PZ-006", 1086], [&"CH1-SO-02", 1198], [&"CH1-PZ-002", 1322], [&"CH1-PZ-003", 1623], [&"CH1-PZ-004", 2434], [&"CH1-PZ-005", 2801]]
  INFO: unlock ticks [[&"rewind", 594], [&"freeze", 1134], [&"echo", 1342]]
  INFO: PlaytestLog | Playtest: 0:49 played, 0:01 paused
  INFO: PlaytestLog | PZ-001 0:03   PZ-002 0:04   PZ-003 0:05
  INFO: PlaytestLog | PZ-004 0:12   PZ-005 0:06   PZ-006 0:08
  INFO: PlaytestLog | SO-01 0:10   SO-02 0:01
  INFO: PlaytestLog | Log: user://headless/playtest/ch01_20261107_094519.json
  PASS: test_real_input_new_game_to_chapter_complete
Test file: res://tests/chapters/ch01/test_ch01_step1_negatives.gd
  PASS: test_pz001_gate_pinned_and_turnstile_holds
  PASS: test_pz002_inner_shutter_needs_the_gear_frozen
  PASS: test_pz003_bridge_cannot_be_crossed_without_echo
  PASS: test_pz003_reader_without_the_pass
  INFO: no-Echo run: B pulled 418 ticks after A from (516.3919, 181.4689); grid_online=false
  PASS: test_pz004_cannot_be_solved_without_echo
  PASS: test_pz005_levers_need_an_echo_on_the_plate
  PASS: test_pz006_staff_door_holds_300_ticks
  PASS: test_so01_closed_gate_holds_300_ticks
  PASS: test_so01_lockout_holds_until_it_ends
  PASS: test_so02_bell_decoy_and_checkpoint_spawn
  PASS: test_so02_bulkhead_sealed
  PASS: test_so02_hatch_closes_without_freeze
Test file: res://tests/chapters/ch01/test_ch01_unlock_guards.gd
  PASS: test_load_in_bay_before_the_technician_keeps_freeze_locked
  PASS: test_load_in_concourse_before_the_courier_keeps_rewind_locked
  PASS: test_load_rederives_unlocks_from_the_flags
  PASS: test_new_game_selects_nothing_but_trace
Test file: res://tests/core/test_scene_router.gd
  PASS: test_boot_routes_to_the_title_screen
  PASS: test_confirm_after_chapter_complete_returns_to_title
  PASS: test_router_is_an_autoload_without_class_name
  PASS: test_start_chapter_remembers_the_restore_slot_once
Test file: res://tests/echo/test_echo_service.gd
  PASS: test_completion_trigger_ignores_echo
  PASS: test_determinism_chunked_and_per_tick_playback_match
  PASS: test_ghost_follows_samples_and_holds_final_position
  PASS: test_missing_target_is_skipped_and_playback_continues
  PASS: test_pz003_02_echo_keeps_holding_switch_after_playback
  PASS: test_pz003_03_reset_releases_occupancy
  PASS: test_pz003_04_echo_cannot_take_progression_items
  PASS: test_pz004_04_echo_pull_lands_on_its_recorded_offset
  PASS: test_pz004_05_unpowered_replay_fails_gracefully
  PASS: test_recording_auto_stops_at_max_length
  PASS: test_recording_captures_player_events_with_relative_ticks
  PASS: test_restarting_playback_releases_then_reacquires_occupancy
  PASS: test_room_change_stops_recording
  PASS: test_state_machine_guards
  PASS: test_triggers_occupied_at_record_start_are_seeded_at_rel_zero
  PASS: test_watch_abilities_and_non_player_actors_are_not_recorded
Test file: res://tests/interaction/test_interactable_lifecycle.gd
ERROR: IdRegistry: Duplicate ID 'ch01.test_lever' already registered to OriginalLever:<Area2D#2134464531291>.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:40)
       [1] _register_with_session (res://scripts/interaction/interactable.gd:75)
       [2] _ready (res://scripts/interaction/interactable.gd:39)
       [3] test_duplicate_interactable_removal_preserves_original (res://tests/interaction/test_interactable_lifecycle.gd:61)
       [4] run_test (res://tests/run_tests.gd:158)
       [5] _run_all (res://tests/run_tests.gd:131)
       [6] run_test (res://tests/run_tests.gd:183)
  PASS: test_duplicate_interactable_removal_preserves_original
ERROR: Interactable 'EmptyIdLever' has an empty object_id.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/interaction/interactable.gd:37)
       [1] test_empty_id_interactable_does_not_register (res://tests/interaction/test_interactable_lifecycle.gd:102)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_empty_id_interactable_does_not_register
ERROR: Interactable 'OrphanLever' (ch01.orphan_lever) could not find GameSession with IdRegistry.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _register_with_session (res://scripts/interaction/interactable.gd:73)
       [1] _ready (res://scripts/interaction/interactable.gd:39)
       [2] test_interactable_handles_missing_game_session (res://tests/interaction/test_interactable_lifecycle.gd:125)
       [3] run_test (res://tests/run_tests.gd:158)
       [4] _run_all (res://tests/run_tests.gd:131)
       [5] run_test (res://tests/run_tests.gd:183)
  PASS: test_interactable_handles_missing_game_session
Test file: res://tests/interaction/test_targeting.gd
  PASS: test_targeting_nearest_interactable
  PASS: test_targeting_tie_break_lexicographical
Test file: res://tests/narrative/test_ch01_text.gd
  PASS: test_documents_reference_existing_keys_and_load
  PASS: test_every_feedback_key_in_the_specs_has_text
  PASS: test_multiline_pages_survive_godot_import
  PASS: test_revelation_document_applies_its_effects
  PASS: test_text_is_ascii_and_within_limits
Test file: res://tests/narrative/test_documents_journal.gd
  PASS: test_echo_cannot_read_documents
  PASS: test_invalid_document_is_refused
  PASS: test_journal_categories_and_promotion
  PASS: test_journal_survives_save_and_load
  PASS: test_reading_applies_flag_fragment_and_journal_once
Test file: res://tests/narrative/test_trace_memory.gd
  PASS: test_one_shot_dialogue_and_use_rules
  PASS: test_revealed_state_survives_a_save
  PASS: test_trace_with_real_input_reveals_the_memory_once
Test file: res://tests/player/test_ability_unlocks.gd
  PASS: test_continue_restores_unlocks
  PASS: test_default_start_keeps_all_four_abilities
  PASS: test_locked_selected_ability_falls_back_when_the_set_shrinks
  PASS: test_trace_only_start_and_locked_feedback
WARNING: AbilityUnlocks: unknown ability 'teleport'.
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] unlock (res://scripts/narrative/ability_unlocks.gd:43)
       [1] test_unlock_triggers_flag_pickup_and_puzzle_solved (res://tests/player/test_ability_unlocks.gd:163)
       [2] physics_frames (res://tests/support/base_test.gd:38)
  PASS: test_unlock_triggers_flag_pickup_and_puzzle_solved
Test file: res://tests/player/test_player_movement.gd
  PASS: test_cardinal_movement_vectors
  PASS: test_diagonal_movement_vectors_2_to_1
  PASS: test_zero_movement_on_no_input
Test file: res://tests/player/test_pocket_watch.gd
  PASS: test_ability_cycling_order_and_wrap
  PASS: test_echo_watch_state_machine_and_reset
  PASS: test_ghost_node_freed_on_watch_cleanup_no_leaks
  PASS: test_player_interact_failure_shows_hud_feedback
  PASS: test_targeting_echo_clears_target
  PASS: test_targeting_fallback_to_nearest
  PASS: test_targeting_out_of_radius_rejected
  PASS: test_targeting_preference_for_supporting_object
  PASS: test_targeting_tie_break_lexicographical
  PASS: test_watch_dispatches_correct_interaction_id
Test file: res://tests/player/test_spawn_targeting.gd
  PASS: test_spawn_targeting_ignores_checkpoint_and_picks_up_watch
Test file: res://tests/player/test_targeting_selection.gd
  PASS: test_adr006_tie_break_unchanged
  PASS: test_blocked_but_supported_use_stays_targetable
  PASS: test_fallback_pool_contains_no_trigger
  PASS: test_trigger_and_checkpoint_only_returns_null
  PASS: test_trigger_closer_than_usable_picks_usable
Test file: res://tests/puzzle/test_ch01_puzzles.gd
  PASS: test_pz001_01_use_on_collapsed_turnstile_is_jammed
  PASS: test_pz001_02_pillar_rewind_unsupported
  PASS: test_pz001_03_rewind_restores_open_at_tick_10
  PASS: test_pz001_04_second_rewind_no_history
  PASS: test_pz001_05_exit_trigger_solves
  PASS: test_pz001_adr016_reset_after_solve_keeps_passage_open
  PASS: test_pz001_reset_collapses_and_relocates_player_in_footprint
  PASS: test_pz001_solved_before_load_latches_open_on_ready
  PASS: test_pz002_01_raised_for_180_ticks_then_closes
  PASS: test_pz002_02_freezing_gear_halts_countdown
  PASS: test_pz002_03_frozen_gear_blocks_rewind
  PASS: test_pz002_04_safety_clutch_relocates_player
  PASS: test_pz002_05_rewind_again_after_slipping
  PASS: test_pz002_accessibility_assist_extends_window_to_300
  PASS: test_pz002_reset_and_solved_latch
  PASS: test_pz003_01_plate_toggles_gate_and_bridge_on_the_same_tick
  PASS: test_pz003_02_echo_holds_the_plate_after_playback
  PASS: test_pz003_03_reset_releases_echo_and_relocates_player_on_bridge
  PASS: test_pz003_04_echo_cannot_take_the_transit_pass
  PASS: test_pz003_05_gate_is_chrono_shielded
  PASS: test_pz003_solved_bridge_survives_echo_reset
  PASS: test_pz004_01_breakers_unpowered_before_step_1
  PASS: test_pz004_02_rewind_then_freeze_locks_the_bus
  PASS: test_pz004_03_single_breaker_expires_after_180
  PASS: test_pz004_04_echo_a_plus_player_b_brings_the_grid_online
  PASS: test_pz004_04b_echo_window_equals_player_window
  PASS: test_pz004_05_unpowered_replay_fails_with_reason
  PASS: test_pz004_06_exit_trigger_solves
  PASS: test_pz004_rewinding_frozen_capacitor_is_refused_and_reset_restores
  PASS: test_pz005_01_state0_north_loops_to_west
  PASS: test_pz005_02_lever_b_first_is_invalid_graph
  PASS: test_pz005_03_lever_a_then_b_routes_north_to_atrium
  PASS: test_pz005_04_severing_the_entry_is_critical_path_unreachable
  PASS: test_pz005_05_player_in_niche_is_relocated_when_sealed
  PASS: test_pz005_06_atrium_entry_solves_and_latches_levers
  PASS: test_pz005_levers_and_route_board_abilities
  PASS: test_pz005_reset_restores_state0_atomically
Test file: res://tests/puzzle/test_hint_service.gd
  PASS: test_ch01_puzzle_data_is_complete_and_translated
  PASS: test_hint_levels_survive_save_and_load
  PASS: test_hints_escalate_after_cooldown_and_stop_at_level_three
  PASS: test_hints_refused_for_unknown_or_solved_puzzles
ERROR: HintService: invalid PuzzleDef 'CH1-PZ-T01'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register_def (res://scripts/puzzle/hint_service.gd:31)
       [1] test_invalid_defs_are_rejected (res://tests/puzzle/test_hint_service.gd:74)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: HintService: invalid PuzzleDef '<null>'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register_def (res://scripts/puzzle/hint_service.gd:31)
       [1] test_invalid_defs_are_rejected (res://tests/puzzle/test_hint_service.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_invalid_defs_are_rejected
  PASS: test_room_hint_follows_play_order_in_shared_rooms
  PASS: test_room_hint_targets_first_unsolved_puzzle
Test file: res://tests/puzzle/test_puzzle_service.gd
  PASS: test_completion_zone_solves_for_player_only
WARNING: PuzzleService: ignoring invalid state 'BANANA' for 'CH1-PZ-004'.
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] import_state (res://scripts/puzzle/puzzle_service.gd:90)
       [1] test_export_import_never_downgrades_and_ignores_garbage (res://tests/puzzle/test_puzzle_service.gd:48)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_export_import_never_downgrades_and_ignores_garbage
  PASS: test_reset_anchor_resets_its_puzzle_through_the_contract
  PASS: test_reset_clears_echo_and_tells_members_whether_solved
  PASS: test_unknown_puzzles_are_unsolved_and_solving_is_idempotent
  PASS: test_watch_focus_hook_emits_once_per_change
Test file: res://tests/puzzle/test_step1_r1_deltas.gd
  PASS: test_pz001_r01_the_courier_unlocks_rewind
  PASS: test_pz001_r02_anchor_memory_journals_once
  PASS: test_pz001_r03_fallen_conduit_pins_the_turnstile
  PASS: test_pz001_r04_conduit_rewinds_once
  PASS: test_pz001_r05_full_solution_and_latch
  PASS: test_pz001_r06_order_independence
  PASS: test_pz001_r08_empty_pinned_by_is_the_base_turnstile
  PASS: test_pz001_r09_reset_while_unsolved
  PASS: test_pz002_r01_inner_shutter_is_unanchored_while_the_gear_is_free
  PASS: test_pz002_r02_anchored_inner_shutter_holds
  PASS: test_pz002_r03_freeze_is_required_assist_off
  PASS: test_pz002_r03_freeze_is_required_assist_on
  PASS: test_pz002_r04_late_freeze_from_the_pocket_solves
  PASS: test_pz002_r05_full_solution_survives_save_and_load
  PASS: test_pz002_r07_clutch_when_the_gear_is_unfrozen_later
  PASS: test_pz002_r08_base_shutter_rule_unchanged
  PASS: test_pz002_r09_old_trigger_is_inert
  PASS: test_pz002_r10_reset_closes_both_and_unfreezes
  PASS: test_pz003_r01_pedestal_unlocks_echo
  PASS: test_pz003_r02_guard_memory_journals_once
  PASS: test_pz003_r03_echo_cannot_take_the_pass
  PASS: test_pz003_r04_reader_without_the_pass
  PASS: test_pz003_r05_reader_with_the_pass_latches
  PASS: test_pz003_r06_alarm_plate_does_not_open_the_gate
  PASS: test_pz003_r09_full_solution_survives_save_and_load
  PASS: test_pz004_r01_breaker_c_browns_the_capacitor_out
  PASS: test_pz004_r02_dead_bus
  PASS: test_pz004_r03_c_is_not_an_input
  PASS: test_pz004_r04_brownout_is_recoverable
  PASS: test_pz004_r05_c_does_nothing_once_the_grid_is_online
  PASS: test_pz004_r06_engineer_and_chart_name_c_as_the_lamp_ring
  PASS: test_pz005_r01_dead_relay_without_the_standby_plate
  PASS: test_pz005_r02_echo_on_the_plate_powers_the_relays
  PASS: test_pz005_r02_relay_is_checked_at_pull_time
  PASS: test_pz005_r04_order_rule_unchanged
  PASS: test_pz005_r05_lever_c_is_a_dead_relay
  PASS: test_pz005_r06_echo_reset_keeps_state_2
  PASS: test_pz005_r07_empty_requires_plate_is_the_base_lever
  PASS: test_pz005_r08_memo_and_tourist_do_not_state_the_lever_order
Test file: res://tests/puzzle/test_step1_solo_and_ticket.gd
  PASS: test_pz006_01_correct_ticket_solves
  PASS: test_pz006_02_rewind_steps_the_dial_back
  PASS: test_pz006_03_use_on_a_dial_is_jammed
  PASS: test_pz006_04_initial_state_is_wrong
  PASS: test_pz006_05_every_wrong_triple_gives_the_same_answer
  PASS: test_pz006_06_no_constant_triple_and_tickets_match_the_memories
  PASS: test_pz006_07_the_fathers_ticket_is_rejected
  PASS: test_pz006_08_ticket_values_live_only_in_trace_memories
  PASS: test_pz006_10_reset_restores_index_5_and_the_history
  PASS: test_pz006_11_latch_after_solved_survives_save_and_load
  PASS: test_pz006_12_save_keeps_the_dial_history
  PASS: test_pz006_13_no_hidden_prerequisite
  PASS: test_pz006_14_rewind_needs_the_unlock
  PASS: test_so01_01_correct_code_opens_the_gate_and_solves
  PASS: test_so01_02_initial_position_is_wrong
  PASS: test_so01_03_every_wrong_code_gives_the_same_answer
  PASS: test_so01_04_lockout_360_ticks_assist_off
  PASS: test_so01_04_lockout_600_ticks_assist_on
  PASS: test_so01_06_answer_lives_only_in_trace_memories_and_labels
  PASS: test_so01_07_latest_statement_per_field_is_the_answer
  PASS: test_so01_08_statues_are_trace_only
  PASS: test_so01_09_latch_after_solved_survives_save_and_load
  PASS: test_so01_lockout_is_not_saved
  PASS: test_so01_lockout_is_not_started_by_prompt_queries
  PASS: test_so02_01_tracing_the_technician_unlocks_freeze
  PASS: test_so02_02_plate_opens_and_closes_the_hatch_on_the_same_tick
  PASS: test_so02_03_freeze_holds_the_hatch_open
  PASS: test_so02_06_other_abilities_are_unsupported
  PASS: test_so02_07_bell_plate_is_a_decoy
  PASS: test_so02_09_freeze_closed_is_recoverable
  PASS: test_so02_10_clutch_moves_the_player_before_closing
  PASS: test_so02_11_latch_after_solved_survives_save_and_load
  PASS: test_so02_12_security_crossing_gate_defaults_unchanged
  PASS: test_so02_frozen_open_state_survives_save_and_load_unsolved
  PASS: test_so02_unfreeze_on_an_occupied_plate_stays_open
Test file: res://tests/rooms/test_room_router.gd
  PASS: test_arrival_grace_ignores_immediate_traversal
  PASS: test_checkpoint_autosave_and_restore_into_fresh_session
  PASS: test_doorway_moves_player_to_other_room_and_unloads_old_one
ERROR: RoomRouter: unknown room 'ch01.nowhere'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] enter_room (res://scripts/rooms/room_router.gd:91)
       [1] test_enter_room_loads_scene_registers_objects_and_places_player (res://tests/rooms/test_room_router.gd:130)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_enter_room_loads_scene_registers_objects_and_places_player
  PASS: test_relocation_to_anchor_in_another_room_loads_that_room
  PASS: test_restore_places_player_at_checkpoint_spawn_anchor
  PASS: test_restore_with_unknown_room_is_refused
  PASS: test_room_change_resets_echo
  PASS: test_same_room_loop_repositions_without_reload
  PASS: test_world_memory_keeps_consumed_rewind_across_rooms
Test file: res://tests/save/test_headless_save_root.gd
  PASS: test_env_override_resolves_to_real_root
  PASS: test_headless_resolves_to_headless_root
  PASS: test_new_store_uses_the_resolved_root_and_assignment_wins
  PASS: test_this_headless_run_never_targets_the_real_saves
  PASS: test_windowed_resolves_to_real_root
Test file: res://tests/save/test_save_service.gd
  PASS: test_capture_and_apply_round_trip_ability_unlocks
  PASS: test_capture_contains_every_section_and_temporal_history
  PASS: test_disk_round_trip_preserves_types_and_leaves_no_temp_file
  PASS: test_full_loop_consumed_pre_history_stays_consumed_after_load
ERROR: SaveService: refusing to write invalid save (invalid).
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] write_slot (res://scripts/save/save_service.gd:145)
       [1] test_invalid_structure_is_refused_for_read_and_write (res://tests/save/test_save_service.gd:235)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_invalid_structure_is_refused_for_read_and_write
  PASS: test_migrations_run_in_order_up_to_current_version
ERROR: Parse JSON failed. Error at line 0: Expected key
   at: parse_string (core/io/json.cpp:629)
   GDScript backtrace (most recent call first):
       [0] read_slot (res://scripts/save/save_service.gd:172)
       [1] test_missing_and_corrupt_files_fail_gracefully (res://tests/save/test_save_service.gd:121)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_missing_and_corrupt_files_fail_gracefully
  PASS: test_missing_optional_fields_get_defaults
  PASS: test_newer_version_is_rejected
  PASS: test_unknown_temporal_ids_are_skipped_not_fatal
  PASS: test_v1_save_migrates_to_v2_with_an_empty_playtest_log
  PASS: test_v2_save_migrates_to_v3_with_all_four_abilities
Test file: res://tests/session/test_id_registry.gd
ERROR: IdRegistry: Duplicate ID 'ch01.test_node' already registered to <Node#2543123958360>.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:40)
       [1] test_duplicate_id_rejected (res://tests/session/test_id_registry.gd:90)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_duplicate_id_rejected
ERROR: IdRegistry: Cannot register node with empty ID.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:32)
       [1] test_empty_id_rejected (res://tests/session/test_id_registry.gd:51)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_empty_id_rejected
ERROR: IdRegistry: ID 'ch1.gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'platform.gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'ch01.' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'ch01..gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'CH01.gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'global.Gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'global.pocket-watch' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'global' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_malformed_ids_rejected
  PASS: test_unregister_and_resolve
  PASS: test_unregister_requires_matching_node
  PASS: test_valid_id_registration
Test file: res://tests/session/test_interaction_service.gd
  PASS: test_interaction_can_interact_rejection
  PASS: test_interaction_echo_forbidden_on_progression
  PASS: test_interaction_missing_target
  PASS: test_interaction_success_and_signal
  PASS: test_trigger_signals
Test file: res://tests/session/test_sim_clock.gd
  PASS: test_sim_clock_pause
  PASS: test_sim_clock_step
Test file: res://tests/settings/test_headless_settings_path.gd
  PASS: test_env_override_resolves_to_real_settings
  PASS: test_headless_resolves_to_headless_settings
  PASS: test_new_settings_use_the_resolved_path_and_assignment_wins
  PASS: test_this_headless_run_never_targets_the_real_settings
  PASS: test_windowed_resolves_to_real_settings
Test file: res://tests/settings/test_settings.gd
  PASS: test_ability_wheel_remap_and_conflict
  PASS: test_bus_volumes_applied
ERROR: ConfigFile parse error at user://test_settings_corrupt.cfg:0: Unexpected EOF while parsing simple tag.
   at: _parse (core/io/config_file.cpp:293)
   GDScript backtrace (most recent call first):
       [0] load_settings (res://scripts/settings/settings.gd:177)
       [1] test_corrupt_file_handling (res://tests/settings/test_settings.gd:167)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
WARNING: Settings file 'user://test_settings_corrupt.cfg' exists but failed to parse (error 43). Resetting to defaults.
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] load_settings (res://scripts/settings/settings.gd:180)
       [1] test_corrupt_file_handling (res://tests/settings/test_settings.gd:167)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_corrupt_file_handling
  PASS: test_default_settings
  PASS: test_echo_reset_present_and_no_conflicts
  PASS: test_joypad_device_minus_one_preserved
  PASS: test_remap_allow_list_interact_confirm
  PASS: test_remap_conflict_rejected
  PASS: test_remap_persisted_and_reapplied
  PASS: test_remap_success
  PASS: test_reset_action
  PASS: test_save_load_round_trip
  PASS: test_timing_window_assist
  PASS: test_unknown_action_and_invalid_event
  PASS: test_value_clamping
Test file: res://tests/spatial/test_ch01_graph.gd
  PASS: test_apply_to_configures_the_session_and_relocates_from_the_sealed_niche
  PASS: test_cutting_the_start_off_the_vestibule_is_refused
  PASS: test_definition_builds_a_valid_graph
  PASS: test_every_door_sits_on_its_boundary_wall
  PASS: test_every_room_fits_the_fixed_camera
  PASS: test_relocation_anchors_are_declared_safe_anchors
  PASS: test_solving_pz005_opens_the_rest_of_the_chapter_and_backtracking_works
  PASS: test_state0_reachability_and_the_grille
  PASS: test_static_edges_connect_opposite_sides
Test file: res://tests/spatial/test_spatial_graph.gd
  PASS: test_doorway_presenter_reports_destination_and_blocks_grille
  PASS: test_i2_relooping_while_routed_to_atrium_is_rejected
  PASS: test_i3_unknown_duplicate_and_dangling_are_invalid
  PASS: test_levers_reverse_back_to_state0
  PASS: test_player_in_vestibule_is_not_relocated
  PASS: test_pz005_01_state0_north_loops_to_west
  PASS: test_pz005_02_lever_b_first_is_rejected_without_side_effects
  PASS: test_pz005_03_lever_a_then_b_reaches_atrium
  PASS: test_pz005_04_severing_the_entry_is_critical_path_unreachable
  PASS: test_pz005_05_player_stranded_in_niche_is_relocated
  PASS: test_reachability_respects_non_traversable_edges
  PASS: test_spatial_state_survives_save_and_load
Test file: res://tests/support/test_test_runner_async.gd
  PASS: test_async_failure_is_reported
  PASS: test_async_pass_steps_physics_frames
  PASS: test_async_timeout_fails_with_clear_message_and_detaches
  PASS: test_input_released_after_failing_async_test
  PASS: test_input_released_when_sync_test_fails_before_flush
  NOTE: case_leaves_node_and_hangs left 1 node(s) under the root; freed them.
  PASS: test_nodes_left_by_timed_out_test_are_freed
Test file: res://tests/telemetry/test_playtest_log.gd
  PASS: test_chapter_complete_writes_json_to_the_headless_folder_and_shows_a_summary
  PASS: test_continue_from_a_v1_save_marks_solved_puzzles_untracked
  PASS: test_flag_defaults_on_in_debug_off_in_export_and_output_paths
  PASS: test_flag_off_means_no_log_no_file_no_summary
  PASS: test_hints_resets_and_failures_are_counted_per_puzzle
  PASS: test_pauses_are_counted_separately_not_as_puzzle_time
  INFO: playtest log of the TLF-030 route: total 15.37 s active, 0 dialogue ticks; CH1-PZ-001 1.45 s (87 ticks); CH1-PZ-002 3.57 s (214 ticks); CH1-PZ-003 4.82 s (289 ticks); ch01.arrival_platform 2.07 s; ch01.concourse_west 4.43 s; ch01.maintenance_bay 3.77 s; ch01.security_crossing 5.07 s; ch01.waiting_lounge 0.03 s
  PASS: test_real_input_rooms_1_to_4_times_match_the_sim_clock
  PASS: test_save_and_continue_keep_the_log
Test file: res://tests/temporal/test_temporal_abilities.gd
  PASS: test_determinism_step_chunking_is_irrelevant
  PASS: test_echo_actor_may_use_abilities_on_non_progression_objects
  PASS: test_frozen_object_rejects_use_until_unfrozen
  PASS: test_pz001_01_use_on_collapsed_gate_is_jammed
  PASS: test_pz001_02_static_pillar_rejects_every_ability
  PASS: test_pz001_03_rewind_restores_pre_arrival_open_state_and_signals_tick
  PASS: test_pz001_04_second_rewind_reports_no_history
  PASS: test_pz002_01_rewound_shutter_holds_180_ticks_then_closes
  PASS: test_pz002_02_freezing_gear_halts_countdown
  PASS: test_pz002_03_frozen_gear_blocks_shutter_rewind
  PASS: test_pz002_05_shutter_can_be_rewound_again_after_slipping
  PASS: test_trace_on_traceable_object_emits_traced
  PASS: test_wrong_ability_on_coupled_objects_is_unsupported
Test file: res://tests/temporal/test_temporal_component.gd
  PASS: test_commit_after_rewind_truncates_future
  PASS: test_counter_changes_do_not_commit
  PASS: test_export_import_round_trip
  PASS: test_fast_forward_calls_parent_advance
  PASS: test_freeze_is_a_toggle_and_blocks_rewind
  PASS: test_initial_history_seeds_before_current_state
ERROR: TemporalComponent on '@Node@743': capture_state() keys ["phase", "counter"] do not match state_fields ["phase"].
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _is_valid_snapshot (res://scripts/temporal/temporal_component.gd:234)
       [1] commit_history (res://scripts/temporal/temporal_component.gd:89)
       [2] test_invalid_snapshot_is_rejected (res://tests/temporal/test_temporal_component.gd:119)
       [3] run_test (res://tests/run_tests.gd:158)
       [4] _run_all (res://tests/run_tests.gd:131)
       [5] run_test (res://tests/run_tests.gd:183)
  PASS: test_invalid_snapshot_is_rejected
  PASS: test_missing_capabilities_are_unsupported
  PASS: test_reset_to_initial_restores_tick0_and_history
  PASS: test_rewind_steps_back_then_reports_no_history
  PASS: test_ring_capacity_evicts_oldest
  PASS: test_sim_clock_step_emits_every_tick
Test file: res://tests/test_project_settings.gd
  PASS: test_autoloads
  PASS: test_controller_device_configuration
  PASS: test_custom_theme_registered
  PASS: test_input_actions
  PASS: test_main_scene
  PASS: test_no_input_binding_conflicts
  PASS: test_viewport_and_display_settings
Test file: res://tests/ui/test_ability_wheel.gd
  PASS: test_aiming_locked_segment_refused_no_change
  PASS: test_controller_lt_axis_and_stick_selection
  PASS: test_hold_z_aim_right_down_selects_freeze
  PASS: test_issue_041_hud_elements_hidden_during_chapter_complete
  PASS: test_modal_priority_blocks_wheel_opening
  PASS: test_reduced_effects_prevents_pulse
  PASS: test_release_does_not_trigger_watch_action
  PASS: test_release_in_dead_zone_no_change
  PASS: test_segment_positions_stay_identical_after_unlock
  PASS: test_toggle_mode_open_confirm_cancel
Test file: res://tests/ui/test_chapter_complete_overlay.gd
  PASS: test_overlay_compat_title_label
  PASS: test_overlay_layout_and_safe_margins
  PASS: test_overlay_text_scale_2
  PASS: test_overlay_without_summary
Test file: res://tests/ui/test_dialogue_box.gd
  PASS: test_blocking_dialogue_continue_cue_and_reduced_effects
  NOTE: test_dialogue_box_advance_does_not_trigger_interactable left 1 node(s) under the root; freed them.
  PASS: test_dialogue_box_advance_does_not_trigger_interactable
  PASS: test_dialogue_box_auto_advance
  PASS: test_dialogue_box_blocking_stops_player_movement
  PASS: test_dialogue_box_sequencing_and_advancement
  PASS: test_dialogue_one_shot_flag_and_save_load
  NOTE: test_non_blocking_dialogue_does_not_consume_interact left 1 node(s) under the root; freed them.
  PASS: test_non_blocking_dialogue_does_not_consume_interact
Test file: res://tests/ui/test_document_viewer.gd
  NOTE: test_document_viewer_interact_does_not_reopen_on_close left 1 node(s) under the root; freed them.
  PASS: test_document_viewer_interact_does_not_reopen_on_close
  PASS: test_document_viewer_multipage_paging_and_beat09_journal
  PASS: test_document_viewer_single_page_and_simclock_pause
Test file: res://tests/ui/test_hint_ui.gd
  PASS: test_hint_action_binding
  PASS: test_hint_hud_request_and_escalation
Test file: res://tests/ui/test_hud_feedback.gd
  PASS: test_feedback_text_resolves_all_standard_reasons
  PASS: test_hud_feedback_toast_display_and_dismissal
  PASS: test_prompt_glyphs_keyboard_vs_joypad
ERROR: Interactable '@Area2D@877' (ch01.test_target) could not find GameSession with IdRegistry.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _register_with_session (res://scripts/interaction/interactable.gd:73)
       [1] _ready (res://scripts/interaction/interactable.gd:39)
       [2] test_target_marker_camera_offset_conversion (res://tests/ui/test_hud_feedback.gd:114)
       [3] run_test (res://tests/run_tests.gd:158)
       [4] _run_all (res://tests/run_tests.gd:131)
       [5] run_test (res://tests/run_tests.gd:183)
  PASS: test_target_marker_camera_offset_conversion
  PASS: test_translations_registered_in_project_settings
  PASS: test_use_vs_watch_unsupported_feedback
Test file: res://tests/ui/test_journal_screen.gd
  PASS: test_journal_screen_empty_state
  PASS: test_journal_screen_grouping_by_category
Test file: res://tests/ui/test_title_screen.gd
ERROR: Parse JSON failed. Error at line 0: Expected key
   at: parse_string (core/io/json.cpp:629)
   GDScript backtrace (most recent call first):
       [0] read_slot (res://scripts/save/save_service.gd:172)
       [1] _ready (res://scripts/chapters/ch01/chapter01.gd:66)
  PASS: test_broken_save_starts_fresh_with_feedback
  PASS: test_continue_disabled_without_a_save
  PASS: test_continue_enabled_with_a_save_and_menu_navigation
  PASS: test_continue_restores_the_signal_control_checkpoint
  PASS: test_new_game_starts_chapter_1_in_the_arrival_platform
  PASS: test_new_game_with_a_save_asks_once
  PASS: test_title_text_is_translated_ascii
Test file: res://tests/ui/test_ui_theme.gd
  PASS: test_action_glyph_first_key_and_confirm
  PASS: test_font_scan_ui_and_chapter01
  PASS: test_panel_clipping_dialogue_and_documents
  PASS: test_static_scene_font_size_overrides
WARNING: UITheme: TLF Pixel Mono not available, using default font
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _setup_font (res://scripts/ui/ui_theme.gd:74)
       [1] _setup_theme (res://scripts/ui/ui_theme.gd:50)
       [2] _init (res://scripts/ui/ui_theme.gd:25)
       [3] test_theme_fallback_when_font_unavailable (res://tests/ui/test_ui_theme.gd:273)
       [4] run_test (res://tests/run_tests.gd:158)
       [5] _run_all (res://tests/run_tests.gd:131)
       [6] run_test (res://tests/run_tests.gd:183)
  PASS: test_theme_fallback_when_font_unavailable
---------------------------
TESTS: 424 passed, 0 failed
Leak check: clean (test suite)

=== All validation checks passed successfully! ===
```

## Follow-up issues (not fixed in TLF-056; Lead decides later)

1. **The turnstile anchor's stand spot (264,116) is inside the closed turnstile's Blocker** (260..284 × 114..126; `CH1-PZ-001.md` §1.4, TLF-055 D1).
   * The pocket north of the Blocker joins the entry strip only past the edge of `door_entry_west` (a squeeze of about 0.4 px).
   * So the anchor's hint is practically traceable only after the gate is open. The playthrough traces it then.
2. **N-20's stand spot (288,176) lies on the south trench railing** (192,128)-(384,224) (`step1_placement_check.txt`). The playthrough traces N-20 from (304,200) in the south lane instead.
3. **The R2 west-door arrival spot is under 2 px from the door.**
   * The door spawn and the Continue anchor (256,112) put the player's body under 2 px from `door_entry_west`'s trigger.
   * Holding up or left for 3 frames right after arriving goes back to R1 (engine probe). After a Continue, a 1 px drift toward the door did the same.
4. **The wheel is blocked during the Beat 01 narration.**
   * The ability wheel does not open while any dialogue line is up, non-blocking lines included (`ability_wheel.gd` `_is_modal_open`).
   * Beat 01 is non-blocking and auto-advances on wall-clock time, 3 × 4 s. So the wheel is unavailable for the first 12 s of a new game, and during every unlock or memory line.
5. **Tick jitter of 1.**
   * Two runs give the same route, outcomes and order. SOLVED and unlock ticks differ by up to 1 tick between runs.
   * The likely cause is the TLF-029 `tap()`, which waits for the idle-frame input flush.
   * Runs: SO-01 569/569, PZ-001 755/754, PZ-006 1090/1089, SO-02 1212/1211, PZ-002 1336/1335, PZ-003 1646/1645, PZ-004 2457/2456, PZ-005 2824/2823.

Also noted, for information only:
* `echo_forbidden` on the transit pass cannot be reached with real input. `can_interact` answers `already_open` before the progression check (ADR-006 order). It is covered at unit level.
* The test runner can report PASS for a test that hit a `SCRIPT ERROR` mid-run. Every run log here was checked for script errors.
