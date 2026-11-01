# Puzzle Specification: CH1-SO-01 — Last Departure (Trace solo)

**Task:** TLF-047 phase 2 (Step 1) · **Concept:** `design/ch01/CH01_EXPANSION.md` §4a (approved `e038e45`) · **Author:** design agent (Claude Code, Sonnet 5.5), standing in for Argon

## 1. Standard Puzzle Specification (`PUZZLE_DESIGN.md` §2)

- **Puzzle ID:** `CH1-SO-01`
- **Name:** Last Departure
- **Chapter / Room:** Chapter 1 (*The Forgotten Station*) / Arrival Platform (`ch01.arrival_platform`, Beat 01, sub-beat 01b)
- **Narrative purpose:** Teach the first and only starting ability, `Trace`, as the way to learn what people believed at 23:59. The platform gate answers to the *last* thing announced, which the player pieces together from four frozen people.
- **Player objective:** Find out which service, platform and car the last departure used (the latest statement per field wins), set the three selector dials on the release panel and pull the release lever to open the platform gate to the Concourse.
- **Required abilities:** `Trace` only (the only unlocked ability). Solo puzzle: no acting ability is required.
- **Required objects:** `ch01.arrival_platform.n01_conductor`, `n02_student`, `n03_old_man`, `n04_cleaner` (`TraceMemory`), `doc_last_service` (readable, insurance), `selector_line`, `selector_platform`, `selector_car` (`SelectorSwitch`), `release_lever` + `release_lock` (`CodeLock`), `platform_gate` (`PoweredDoor`-style blocker in the east doorway), `pocket_watch_pickup` (existing).
- **Initial room state:** Elias wakes, takes the watch (`ch01.flag.pocket_watch_acquired`, Trace unlocks). All three selectors are at position 0. `platform_gate` is closed (`passage_blocked = true`). The four statues are untraced.
- **Rules the player must discover:**
  1. `Trace` on a frozen person shows a time-stamped memory; the time stamp matters.
  2. The panel has three selectors (LINE, PLATFORM, CAR); `use` cycles each through 3 positions with a label **and a shape glyph**.
  3. Announcements overrode each other: for each field, **the latest statement wins** (N-01 says so explicitly: "Go by the last announcement").
  4. A wrong code makes the panel buzz and reset for 6 seconds; it never says which part was wrong.
- **Step-by-step intended solution:**
  1. Walk the platform and `Trace` the four statues: N-01 (23:57: Hollow Quay, rear car), N-02 (23:41: Central, platform 1, front car), N-03 (23:30: Harbour, platform 2, middle car), N-04 (23:58: platform 3). Each adds a journal observation.
  2. Optionally read `doc_last_service` (times only: it confirms that service changes came at 23:30, 23:41, 23:57 and the platform change at 23:58).
  3. Work out per field: LINE = HOLLOW QUAY (N-01, 23:57 beats 23:41 and 23:30), PLATFORM = 3 (N-04, 23:58 beats 23:41 and 23:30), CAR = REAR (N-01, 23:57 beats 23:41 and 23:30).
  4. At the panel set `selector_line` to HOLLOW QUAY (1 `use`), `selector_platform` to PLAT 3 (2 `use`), `selector_car` to REAR CAR (1 `use`).
  5. Pull `release_lever`: the lock accepts, `platform_gate` opens and stays open, `CH1-SO-01` is `SOLVED`. Walk through the east doorway.
- **Alternative valid solutions:** none that skip the information. Guessing is possible but costs more than reading (§6).
- **Failure states:**
  * Wrong code: `request(release_lever, use)` returns `ok == false`, `reason == &"wrong_code"` (identical feedback for every wrong code), then `&"locked_out"` for 360 ticks (600 with the assist).
  * `use` on `platform_gate` returns `&"locked"` with the hint where the panel is.
  * A selector never fails.
- **Reset behavior:** no reset console is needed (nothing can be broken); the lock-out clears itself. After `SOLVED` the gate stays open (ADR-016); selectors and the lever return `&"already_open"`.
- **Hint 1 (nudge):** *"Four people on this platform said where the last train goes. Ask each one when they said it."*
- **Hint 2 (rule reminder):** *"For the line, the platform and the car, the latest announcement counts. Compare the time stamps."*
- **Hint 3 (next action):** *"Set the panel to Hollow Quay, platform 3, rear car, then pull the release lever."*
- **Success feedback:** Visual: three green chevrons `[>>>]` on the panel, the gate lifts. Audio: a soft chime and a servo. Journal: `JRN_SO001_SOLVED` (fact).
- **Narrative reward:** the way to the Concourse; four journal observations that begin the "five minutes" timeline.
- **Accessibility considerations:** every selector position has a text label **and** a distinct shape glyph (line: circle / diamond / triangle; platform: 1-3 pips; car: three car silhouettes); the lock-out is announced as text; no colour is needed to read the panel; the 6 s lock-out is scaled by the assist (`timing_window`).
- **Estimate (model §1.3):** 4 d (100 s) + 4 e (48 s) + 1 w (15 s) = 163 s = **2.7 min design**, 1.6 min floor. ✔ ≥ 1.5.
- **Dependent steps (≥ 3):** Trace statues → compare time stamps per field → set three selectors → pull lever → walk through.

## 2. Object & Schema (`ADR-005`, `ADR-016`)

Positions: tile `(x,y)` → px `(320+(x−y)·16, 64+(x+y)·8)`; room `14 × 10`. Existing: `pocket_watch_pickup (8,5) (368,168)`, `safe_anchor_spawn (7,5) (352,160)`, `door_exit_east (13,5) (448,208)`.

| `object_id` | Role / class | Caps | State fields (tick-0) | Tile / px | Stand spot → distance |
|---|---|---|---|---|---|
| `ch01.arrival_platform.n01_conductor` | `TraceMemory` | trace | — | `(10,8)` `(352,208)` | `(368,200)` → 17.9 |
| `ch01.arrival_platform.n02_student` | `TraceMemory` | trace | — | `(5,8)` `(272,168)` | `(288,160)` → 17.9 |
| `ch01.arrival_platform.n03_old_man` | `TraceMemory` | trace | — | `(4,2)` `(352,112)` | `(336,120)` → 17.9 |
| `ch01.arrival_platform.n04_cleaner` | `TraceMemory` | trace | — | `(12,7)` `(400,216)` | `(416,208)` → 17.9 |
| `ch01.arrival_platform.doc_last_service` | `ReadableDocument` (`doc_last_service.tres`) | use | — | `(1,3)` `(288,96)` | `(272,104)` → 17.9 |
| `ch01.arrival_platform.selector_line` | `SelectorSwitch` (wall panel) | use | `position: int = 0` of 3; labels `SO001_LINE_0..2` | `(7,1)` `(416,128)` | `(400,136)` → 17.9 |
| `ch01.arrival_platform.selector_platform` | `SelectorSwitch` | use | `position = 0` of 3; `SO001_PLAT_0..2` | `(9,1)` `(448,144)` | `(432,152)` → 17.9 |
| `ch01.arrival_platform.selector_car` | `SelectorSwitch` | use | `position = 0` of 3; `SO001_CAR_0..2` | `(11,1)` `(480,160)` | `(464,168)` → 17.9 |
| `ch01.arrival_platform.release_lever` | `Interactable` (`use`) feeding the lock | use | — | `(13,2)` `(496,184)` | `(480,192)` → 17.9 |
| `ch01.arrival_platform.release_lock` | `CodeLock` (logic node, no sprite) | none | `answer = [1, 2, 1]`; `lockout_until_tick: int = 0`; `unlocked: bool = false`; `grid_online` / `grid_online_changed(online)` API (same as `SubstationGrid`) | — | — |
| `ch01.arrival_platform.platform_gate` | `PoweredDoor` (`grid_id = release_lock`), Blocker | none (chrono-shielded) | `door_state = &"locked"`, `passage_blocked = true` | doorway aperture `(13,5)` `(448,208)` | — |

**Selector answers:** LINE `[CENTRAL, HOLLOW QUAY, HARBOUR]` → `1`; PLATFORM `[PLAT 1, PLAT 2, PLAT 3]` → `2`; CAR `[MIDDLE CAR, REAR CAR, FRONT CAR]` → `1`. Initial `(0,0,0)` is wrong in all three fields.

**New behaviours (ledger):** `TraceMemory` (see `TRACE_MEMORY.md`), `SelectorSwitch` (S: `use` increments `position` modulo `count`, emits `changed`; no temporal component), `CodeLock` (S: `evaluate(selectors)` on `release_lever` use; on a match sets `unlocked`, emits `grid_online_changed(true)` and calls `PuzzleService.mark_solved(&"CH1-SO-01")`; on a mismatch sets `lockout_until_tick = tick + timing_window(360)`). `PoweredDoor` is reused unchanged. **Completion:** the lock calls `mark_solved` directly because the next trigger is the doorway itself (ADR-016 latch still applies: `platform_gate` latches open, selectors and lever refuse with `&"already_open"`).

## 3. Interaction Contract Table (`ADR-006`)

| `target_id` | `interaction_id` | Allowed condition | Failure `reason` | Feedback key |
|---|---|---|---|---|
| `n01…n04` | `trace` | always | — | memory lines (`MEM_N0x_1/2`) |
| `n01…n04` | `use` | never | `&"unsupported"` | `UI_FB_UNSUPPORTED` (default) |
| `doc_last_service` | `use` | always | — | opens the document; sets `ch01.flag.last_service_read`, journal `JRN_DOC_LAST_SERVICE` |
| `selector_*` | `use` | not solved | `&"already_open"` once solved | label changes |
| `selector_*` | `trace` / `rewind` / `freeze` | never | `&"unsupported"` | `UI_FB_UNSUPPORTED` |
| `release_lever` | `use` | `tick >= lockout_until_tick` and not solved | `&"locked_out"` (during lock-out), `&"already_open"` (solved); a wrong code returns `&"wrong_code"` | `SO001_FB_LOCKED_OUT`, `SO001_FB_WRONG_CODE` |
| `platform_gate` | `use` | never while closed | `&"locked"` | `SO001_FB_GATE_SEALED` |
| `platform_gate` | any watch ability | never | `&"unsupported"` | `UI_FB_UNSUPPORTED` |

New reasons: `&"wrong_code"`, `&"locked_out"` (feedback keys above).

## 4. Soft-lock and reachable-bad-state analysis

| State | Issue | Recovery |
|---|---|---|
| Player never Traces N-01/N-04 | cannot know the answer | hint ladder (3 levels), journal re-read, `doc_last_service` gives the rule; brute force is possible (§6) |
| Selectors left in any position | none | `use` cycles; no state is lost |
| Lock-out running while the player walks off | none | lock-out is tick-based and expires |
| Statues block the path | route to the gate | placement rule P: statues are off the spawn→gate line; TEST-CM-05 |
| Save/load mid-lock-out | the lock-out must not persist across a load | `lockout_until_tick` is not saved; a load clears it |
| Load after SOLVED | gate must stay open | `PuzzleObject` latch (ADR-016) |
| Echo / other abilities | none exist yet at this point | availability guard (`ABILITY_UNLOCKS.md`) |

## 5. ADR-015 reach and targeting

* Trace (96 px): each statue is the nearest Trace candidate from its stand spot (table above, 17.9 px each); other statues are ≥ 35.8 px away from every stand spot.
* `use` (36 px): from each selector stand spot the intended selector is nearest (17.9 px; neighbours 48.8 px); `release_lever` from `(480,192)` is 17.9 px, nearest; `doc_last_service` from `(272,104)` is 17.9 px. No statue is within 36 px of any of those stand spots (P1).
* Placement checker result: 10 of 10 stand-spot checks in the room OK (`design/ch01/expansion/step1_placement_check.py`, output `step1_placement_check.txt`).

## 6. Shortcut analysis (RISK-018 / ISSUE-021 lesson)

| Shortcut | Excluded by | Negative test (real input) |
|---|---|---|
| Open the gate without the code | `platform_gate` is a `Blocker` in the only exit aperture (E1); chrono-shielded; no other ability exists | `TEST-SO01-04`: walk the player at the aperture with the gate closed → position stays west of the aperture for 300 ticks |
| Read the answer from a document | the values appear only in the four `MEM_*` texts; `DOC_LAST_SERVICE_BODY_1` contains no line, platform or car value | `TEST-SO01-05`: grep the text table: the three answer strings occur in no `DOC_*` key |
| Brute force the code | 27 combinations; every wrong code costs ~12 s (3 `use` + lever) + 6 s lock-out; no partial feedback → expected ≈ 14 tries ≈ 4.2 min vs. 2.7 min by reading | `TEST-SO01-03`: all 26 wrong codes return the **same** reason and feedback key |
| Skip the lock-out by quitting | `lockout_until_tick` is cleared on load; but the tries still cost the same real time | accepted: no benefit |
| Use `Trace` on selectors/lever | `unsupported` | `TEST-SO01-06` |

The RISK-018 analogue for an information puzzle is guessing; the defence is *cost parity plus story reward*: reading takes about as long as guessing and shows the story (Q-8 policy: 6 s lock-out, silent reset, never per-step feedback).

## 7. Acceptance tests (`GIVEN / WHEN / THEN`)

* **TEST-SO01-01 — correct code opens the gate and solves.** GIVEN selectors at `(1,2,1)`; WHEN `request(player, release_lever, use)`; THEN `ok == true`, `platform_gate.passage_blocked == false`, `PuzzleService.is_solved(&"CH1-SO-01")`, `JRN_SO001_SOLVED` is in the journal.
* **TEST-SO01-02 — the initial position is wrong.** GIVEN selectors at `(0,0,0)`; WHEN the lever is used; THEN `ok == false`, `reason == &"wrong_code"`, the gate stays closed.
* **TEST-SO01-03 — no partial feedback.** GIVEN each of the 26 wrong codes in turn (waiting out the lock-out); WHEN the lever is used; THEN every result has the same `reason` and the HUD shows the same key `SO001_FB_WRONG_CODE`.
* **TEST-SO01-04 — lock-out.** GIVEN a wrong code was entered at tick `t`; WHEN the lever is used at `t + 359` (assist off) or at `t + 599` (assist on); THEN `reason == &"locked_out"`; AND at `t + 360` (assist off) or `t + 600` (assist on) the lever accepts a code again.
* **TEST-SO01-05 — gate is the only exit (real colliders).** GIVEN the gate closed; WHEN the player walks towards `door_exit_east` for 300 ticks; THEN the player never enters the `door_exit_east` area.
* **TEST-SO01-06 — the answer is only in Trace memories.** GIVEN the generated `ch01_text.csv`; THEN `HOLLOW QUAY`, `platform 3` and `rear car` (case-insensitive) occur in `MEM_N01_*`/`MEM_N04_*` and in the selector labels, and in **no** `DOC_*` or `OP_*` key.
* **TEST-SO01-07 — latest statement per field.** GIVEN the memory data; THEN for each field the statement with the latest time stamp equals the answer (as `TEST-CM-03`).
* **TEST-SO01-08 — statues are Trace-only.** GIVEN a statue; WHEN `use` is requested; THEN `&"unsupported"`; WHEN `rewind`/`freeze` are requested; THEN `&"unsupported"`.
* **TEST-SO01-09 — latch after SOLVED.** GIVEN `CH1-SO-01` is `SOLVED`; WHEN saved, loaded and the room re-entered; THEN the gate is open and the lever returns `&"already_open"`.
* **TEST-SO01-10 — only Trace exists.** GIVEN a fresh session after the pickup; THEN `AbilityUnlocks.unlocked == [&"trace"]` and `ability_next` changes nothing.
