# Chapter 1 Expansion — Phase 1 Concepts (TLF-047)

| | |
|---|---|
| **Task** | TLF-047, phase 1 (concepts only; no specs, no implementation) |
| **Author** | Design agent (Claude Code, Sonnet 5.5), standing in for Argon as puzzle/narrative designer |
| **Date / base** | 2026-11-01 · branch `adityadaffa522/tlf-art-batch2` merged with `origin/main` at `e8bb405` |
| **Decision** | ADR-020 including both 2026-11-01 amendments (progressive abilities / NPCs / story; measured length) |
| **Read for this doc** | `CH01_BEAT_SHEET.md`, `ROOM_GRAPH.md`, `puzzles/CH1-PZ-001..005.md`, `scripts/puzzle/**`, `scripts/temporal/temporal_component.gd`, `scripts/echo/echo_service.gd`, `scripts/spatial/*`, `scripts/interaction/*`, `scripts/narrative/*`, `scripts/player/pocket_watch.gd`, `scripts/rooms/room_router.gd`, `scripts/chapters/ch01/*`, `localization/ch01_text.csv`, ADR-015/016/019/020, RISK-018/ISSUE-021 |
| **Status** | Draft for Lead and user approval. Nothing here is a spec; all text lines are drafts for `CH01_TEXT.md` in phase 2 |

All minute figures use one stated model (§1.3) that reproduces the measured result. "Design" is the average first-time estimate, "floor" is the fast-player estimate (0.6 × design), which is the number the ≥ 15 min target is checked against.

---

## TL;DR for the Lead

* **Why 5 minutes:** every existing puzzle is *one object, one verb*. Nothing has to be found, read or compared; all four abilities are in the player's hands from second zero (try-everything solves any room in ~10 s); and **Trace appears to do nothing visible today** (§0.1, from code reading). A perfect scripted run of all five puzzles is ~25 s of game time.
* **The fix is depth, not count:** each puzzle gets ≥ 3 dependent steps, information that only Trace or a frozen commuter's memory provides, plausible wrong options with a cost, and small hubs. Abilities arrive one at a time: **Trace → Rewind → Freeze → Echo**, each with a solo puzzle before the first combo.
* **Proposal (recommended):** 2 new solo puzzles (Trace, Freeze) + all 5 existing puzzles deepened (PZ-001 and PZ-003 become the Rewind and Echo solos) + 3 new combos (`Trace+Rewind`, `Echo+Freeze`, `Trace+Echo`) + an `Echo+doorway` stage in PZ-005 + 3 optional side puzzles with fragments + 23 frozen commuters (13 are needed by puzzles) + 2 interactive NPCs + 2 new rooms. No new mechanic, no contract change, Fast-Forward only as one optional stretch puzzle.
* **Numbers:** main path **36.8 min design / 22.1 min floor**; optional **+8.5 / +5.1**. A first step with **no new rooms and one new combo** already gives **28.7 design / 17.2 floor** (≥ 15 ✔). Everything is built from step counts, not feelings (§1.3, §8).
* **Two code findings to confirm (§0.1, §0.11):** Trace appears to show nothing in the current build, and PZ-002 appears solvable with Rewind alone (the walk after Rewind is ~0.9 s of a 3 s hold). Neither needs a contract change.
* **Needs a decision/confirmation:** §7 (11 questions).

---

## 0. What the code says (facts this design relies on)

Read from the code, **not** run in the game. Items marked ⚠ are findings that change the design.

| # | Fact (source) | Consequence for the design |
|---|---|---|
| 0.1 ⚠ | **Trace carries no information today.** `Interactable.interact(&"trace")` emits `traced(object_id)` and calls `_on_traced()` (`interactable.gd:125-126`), which is an empty override (`:153`). Nothing connects to `traced` except one unit test. The turnstile's `turnstile_trace_anchor` is a bare `Interactable` (`concourse_west.tscn`); `JRN_CH1_TURNSTILE_TRACE` exists only as text, never wired. `DialogueTrigger` has `_can_watch`/`_on_watch` (`dialogue_trigger.gd:30-38`) but the base class never calls them; the lounge bench test calls `trigger()` directly (`test_ch01_narrative_beats.gd:304`). Pending an in-game check, **tracing the bench or the anchor probably shows nothing**. | Trace has to become the *information ability*. One small new class, `TraceMemory` (a traceable `Interactable` whose `_on_traced` shows 1-2 lines, sets a flag, adds a journal observation). No contract change: the hook already exists. Everything in §4b depends on it. |
| 0.2 | `TurnstileGate` is **REWIND only**; the spec's Trace step is explicitly non-gating (`CH1-PZ-001.md`, "Direct Rewind"). | PZ-001 today is a **Rewind solo**, not Trace+Rewind. In the new curve it stays solvable with the same solution (§4a). |
| 0.3 | `PocketWatch.unlocked_abilities` already exists and `cycle_ability` honours it; the default is all four (`pocket_watch.gd:22`). Unlocks are **not saved** yet. | Progressive unlock is cheap in the watch; needs a save field + HUD slots + unlock events (Opus/Flash). |
| 0.4 | **An echo belongs to its room**: `RoomRouter` calls `notify_room_changed()` + `reset_echo()` on every room change (`room_router.gd:12, 165-167`). | Every Echo puzzle must be solvable inside one room. No cross-room echo tricks. |
| 0.5 | Echo replays *logical* events: `InteractionService.request(&"echo.0", id, …)` has no distance check; it never records watch abilities (`echo_service.gd:176`), is refused by `progression = true` objects (`&"echo_forbidden"`), and **keeps trigger occupancy after playback ends** (`HOLDING`). | Echo = "a second body that can use levers and hold plates". It can never Rewind/Freeze/Trace. |
| 0.6 | `Interactable.can_interact` returns `&"frozen"` for any **non-ability** `use` on an object whose `TemporalComponent` is frozen (`interactable.gd`), and `TemporalComponent.rewind()` returns `&"frozen"` while frozen. | **"Freeze locks a switch in position" is free** for any object with a `TemporalComponent` (FREEZE). "Freeze, then you cannot rewind it" is also free (a plausible wrong option PZ-002 already uses). |
| 0.7 | `TemporalComponent` supports **multi-entry `initial_history`** (exact `state_fields` per entry, capacity 32). History only moves *back*; a `commit_history()` after a rewind cuts the future. There is no redo. | Multi-position dials/boards are data-only; **overshooting is a real, recoverable wrong option** (reset anchor calls `reset_to_initial`). |
| 0.8 | `TimedBreaker`, `PlateLinkedGate`, `RetractableBridge`, `FireShutter`, `SurgeCapacitor`, `PoweredDoor`, `JunctionLever`, `ProgressionPickup`, `ReadableDocument`, `PuzzleCompletionZone`, `ResetAnchor`, `HintService` (3 hint keys per `PuzzleDef`) exist. | §2-§4 reuse these and list the *small* new behaviours explicitly (ledger in §8.4). |
| 0.9 | `SpatialGraph.apply` is transactional and rejects dangling doorways and critical-path breaks; stranded actors are relocated. | A decoy lever can only produce **valid-but-useless** graphs; no soft lock is possible. |
| 0.10 | `FireShutter` hold timer is paused by a frozen gear; `SurgeCapacitor` decays unless frozen; both commit history on decay (re-rewindable). `timing_window()` **scales every timer with the accessibility assist** (180 → 300 ticks). | Any proof of the form "the player cannot walk faster than the timer" must hold against the **assisted** window, or it silently fails when the assist is on. New concepts therefore exclude shortcuts by occupancy, state or **dwell** (a condition that must hold longer than the decay interval), not by speed (design rule R3, §1.5). |
| 0.11 ⚠ | **PZ-002 appears solvable without Freeze.** The real-input playthrough rewinds the shutter at (340,128), freezes the gear, then walks (384,146) → (384,176) → (416,176) to `exit_trigger_east` (`test_ch01_real_playthrough.gd:165-182`): ≈ 110 px ≈ 0.9 s at 120 px/s, against a 180-tick (3.0 s; 5.0 s assisted) hold. The spec claims 3 s is "too fast for Elias to walk all the way through" (`CH1-PZ-002.md`), which does not hold for this layout, and no test asserts that Freeze is needed (the test freezes but never proves it matters). From reading only, not run. | Same class as RISK-018/ISSUE-021 in an existing puzzle. It is one more reason PZ-002 is a deepening candidate: §4 adds a long railing route east of the shutter (new colliders, own fingerprint; existing geometry untouched). Recommend the Lead asks for a real-input negative test ("Rewind, walk, no Freeze") now. |

---

## 1. Time budget (task item 1)

### 1.1 Measured vs. estimated

**Measured (playtest #2, user report):** the whole chapter in **under 5 minutes**; every puzzle "well under a minute". **Estimated (beat sheet):** 38 min. That is ~8× off.

Only the total and "each puzzle well under a minute" were reported. The per-beat "realistic actual" below is my allocation of ~4.7 min, cross-checked with the step model (§1.3), and is **not** a measurement. TLF-048 telemetry replaces it.

| Beat | Title | Beat-sheet est. | Realistic actual (alloc.) | Target — design | Target — floor |
|---|---|---:|---:|---:|---:|
| 01 | Awakening on the Sub-Line | 3 | 0.6 | 3.5 | 2.1 |
| 02 | The Fractured Turnstile | 4 | 0.4 | 1.9 | 1.2 |
| 03 | Call Box 09 | 4 | 0.5 | 5.0 | 3.0 |
| 04 | The Runaway Shutter | 5 | 0.4 | 5.2 | 3.1 |
| 05 | The Delayed Platform | 6 | 0.5 | 6.8 | 4.1 |
| 06 | Ghosts in the Waiting Lounge | 3 | 0.3 | 4.9 | 2.9 |
| 07 | The Synchronized Substation | 5 | 0.8 | 3.2 | 1.9 |
| 08 | The Displaced Corridor | 5 | 0.5 | 3.3 | 2.0 |
| 09 | Ledger 23:59 | 2 | 0.4 | 1.0 | 0.6 |
| 10 | Ascent to the Frozen City | 1 | 0.3 | 0.4 | 0.2 |
| — | Room-to-room walking (12 transitions) | — | (inside the beats) | 1.6 | 1.0 |
| | **Total** | **38** | **≈ 4.7** | **36.8** | **22.1** |

Target columns = recommended proposal, main path only (§8 shows the derivation). The design total lands near the old 38 on purpose: the old estimate was plausible for a careful player *if* the puzzles had this depth. At the current depth it was 8× wrong.

### 1.2 Where the minutes come from (and why they were missing)

Diagnosis, from the code and the specs:

1. **One object, one verb.** Each room has one puzzle object; the solution is "do the only thing". A perfect scripted run of rooms 1-4 takes ~9 s and rooms 5-10 ~16 s of game time (ADR-020). The other ~4 minutes were reading, walking and dialogue.
2. **All four abilities from second zero.** With one candidate object a player cycles four abilities in ~10 s ("try everything"). Nothing has to be understood.
3. **Trace is decorative** (§0.1) and Rewind/Freeze are the only "answers". There is no information to discover, so nothing has to be read.
4. **Everything is local.** The whole solution is within 96 px of one standing spot; no clue lives in another room or on a person.
5. **Wrong tries are free and rare.** Few plausible wrong options, no cost, reset is one tap.

Levers that add minutes honestly (in order of weight in this proposal):

| Lever | What it adds | Share of the full proposal |
|---|---|---:|
| **Discovery** (Trace memories, readables, signs; 29 clues at 25 s) | reading and *comparing* information before acting | 12.1 min (39 % of puzzle time) |
| **Dependent steps** (63 actions at 12 s) | longer chains, order matters, state must be held | 12.6 min (40 %) |
| **Plausible wrong options** (18 at 15 s) | decoys, overshoot, wrong order, with a small cost | 4.5 min (14 %) |
| **Resets** (6 at 20 s) | recoverable mistakes that cost a redo | 2.0 min (6 %) |
| Non-puzzle (walking, dialogue, readables) | 12 transitions + story | 5.7 min (added to 31.2 min of puzzle time) |

More puzzles alone would not do it: at the current depth, 8 puzzles would be ~8 min.

### 1.3 Estimation model and calibration

Four step types, each with a fixed cost, applied the same way to every puzzle in this document:

| Symbol | Meaning | Cost |
|---|---|---:|
| **d** | discovery: walk to a clue, Trace/read it, understand it (2-3 lines) | 25 s |
| **e** | one deliberate action: walk to an object + ability select + act (incl. feedback) | 12 s |
| **w** | plausible wrong attempt: try, read the feedback, back off | 15 s |
| **r** | reset/redo after an overshoot or timeout | 20 s |

**Calibration check against the measurement.** The five existing puzzles are 25 e (PZ-001 3, PZ-002 3, PZ-003 6, PZ-004 9, PZ-005 4) and 0 d = 300 s = **5.0 min**. The non-puzzle part (9 transitions × 8 s, ~22 dialogue lines × 3 s, 5 readables × 12 s) is **3.3 min**. Model total 8.3 min; measured ≈ 4.8; ratio **0.58**. So the playtest user was ~0.6× the model on everything. I use **floor = 0.6 × design** as the fast-player number. At the floor the five puzzles take 3.0 min together: 22 s, 22 s, 43 s, 65 s and 29 s. Four of five are well under a minute as reported; the model puts PZ-004 slightly over, so the factor may even be a little high for that puzzle.

**Sensitivity.** The ≥ 15 min check survives a faster player than the model assumes: Step 1 (28.7 design) stays ≥ 15 down to a factor of **0.52**, the full main path (36.8) down to **0.41**. Below that, the reserve in §8.3 applies.

Rules that keep the estimate honest:
* An estimate is the **sum of its listed steps**, never a feeling. The bar (main combo ≥ 3 min, solo ≥ 1.5 min) is checked on the **design** value.
* The ≥ 15 min target is checked on the **floor**, because the one measured player was fast.
* The model can be wrong in either direction; TLF-048 telemetry per puzzle (time to first interaction, to solve, number of wrong tries, resets) recalibrates d/e/w/r before the second step (§8.3).

### 1.4 Targets

| | Design | Floor | Target |
|---|---:|---:|---|
| Next playtest, main path, first-time | 28.7 (Step 1) – 36.8 (full) | 17.2 – 22.1 | **≥ 15 min** (checked on the floor) |
| Vertical-slice goal (second step) | 45.3 incl. optional | 27.2 | 30-45 min, recalibrated from telemetry (§8.3) |

### 1.5 Design rules used by every concept

| # | Rule | Why |
|---|---|---|
| R1 | **One place per answer** for every puzzle whose combo includes Trace (SO-01, PZ-006, PZ-008, SP-B, SP-C): the value lives in exactly one source. "Insurance" clues give the *rule* or a pointer, never the value. Puzzles whose combo is physical (e.g. PZ-007) may repeat a clue in several places. | otherwise the readable replaces the Trace and the combo is skippable |
| R2 | **The journal is the notebook.** Every Trace memory adds a timestamped observation, so nothing depends on the player's memory. | information-heavy puzzles stay fair |
| R3 | **No speed-based exclusion.** Shortcuts are excluded by occupancy, state, or *dwell* (a condition that must hold longer than the decay interval), or by a route longer than the **assisted** window proven on real colliders (the PZ-004 recipe). | the accessibility assist scales timers (§0.10); "you can't walk fast enough" silently breaks |
| R4 | **No partial feedback** on code, sequence or ticket locks; a wrong try costs a small price (lock-out, reset, redo), never a fail state. | stops mastermind-style search (the RISK-018 pattern for information puzzles) |
| R5 | **Echo puzzles live in one room** (§0.4). | echoes are reset on room change |
| R6 | **No forced backtracking.** A needed clue is in the same room or on the mandatory path of an earlier room; each cross-room clue has an in-room insurance clue (R1). | ADR-020 "no padding" |
| R7 | **Reuse before new.** New behaviours are listed in the ledger (§8.4); none touches the `InteractionService`, `TemporalComponent` or `EchoService` contracts. | implementation cost |
| R8 | **Colour-independent cues.** Dial values, selector positions, plate states and the "Trace ring" on a person carry a glyph or shape as well as colour. | accessibility, as in the existing specs |

---

## 2. Main-path concepts (task item 2)

Terminology used everywhere:
* **Acting ability** = Rewind, Freeze, Echo, Fast-Forward, or doorway reassignment (a lever). **Trace is the information ability**: it never changes state, so it is always available and may supply the clue in any puzzle.
* **Solo puzzle** = exactly one acting ability is required (Trace may supply information). **Combo** = two or more acting abilities (or an acting ability + doorway reassignment) are required. "Trace+Rewind" is a combo in the sense of ADR-020 (the answer lives only in Trace; the change only in Rewind), and I mark it so.
* **Progressive unlocks are themselves a RISK-018 guard:** in the first rooms the player does not *have* the other abilities, so cross-ability shortcuts are impossible by availability. Later rooms must still be excluded by geometry/timing/state rules; each concept lists them.

Five concepts; the recommended three are **A, B, C** (distinct combos, distinct feel: deduction, logistics, sequence). D and E are strong alternatives; each needs a 14×10-16×12 room of its own, so they replace B or C rather than avoid a new room.

---

### MP-A · "Last Ticket" — Trace + Rewind (recommended; becomes `CH1-PZ-006`)

* **Room:** Concourse West, east half (existing 16×12; no new room). Placed after the turnstile (PZ-001), before the Maintenance Bay.
* **Combo / new because:** the first time Trace *and* Rewind are both **required**: Trace is the only source of the values, Rewind the only way to set them.
* **Idea.** The east exit is a staff door checked by a **ticket validator** with three one-way **split-flap dials** (LINE · PLATFORM · TIME), each a rewindable machine whose history is its own list of issued tickets (the three machines were issued in different orders). The door honours only one particular ticket. The evacuation bulletin (read in Beat 03) fixes the time: the 23:54 order. A new ticket-terms sign adds the second condition: after the order **only Orchard Gate tickets** are honoured at the staff door. Four frozen passengers stand in the queue; Tracing each reveals the exact ticket they hold (line, platform, time). Two of them hold Orchard Gate tickets, but only one was bought *after* 23:54, so the player has to compare both conditions, then Rewind each dial back to that passenger's values. The Operator on Call Box 09 adds a nudge.
* **Aha:** "the dials only go backwards, and the right answer is a specific moment in the past of each machine".
* **Steps (dependent):** read the ticket terms (d; the bulletin is already known from Beat 03) → Trace the four passengers and compare line and time (4 d) → decide which ticket qualifies → walk to the dial bank → rewind LINE, PLATFORM, TIME to the matching entries (each check-and-click; ~6 e) → press stamp/validate (e) → door opens.
* **Hub:** ticket terms, Call Box 09 and the queue can be done in any order; the dials are the common sink (no backtracking: everything is in the same room).
* **Failure path / feedback:** validating a mixed ticket (values from different passengers) → "No such ticket." with **no partial feedback**; overshooting a dial (one-way) → the dial blinks, reset pedestal (`reset_to_initial`) puts it back. Rewinding below the first entry returns `&"no_history"` (existing feedback).
* **Reuses:** `TemporalComponent` (multi-entry `initial_history`), `ReadableDocument` (`doc_evac_notice` already has the 23:54 line; one new sign), `ResetAnchor`, `PoweredDoor`-style door.
* **New behaviour:** `TraceMemory` (S), `HistoryDial` (multi-state rewindable, M), `TicketValidator` (reads three dials, opens the door via the same signal `PoweredDoor` already listens to, S).
* **Why it cannot be solved without the combo (shortcuts → exclusion):**

  | Shortcut | Excluded by |
  |---|---|
  | Skip Rewind (set dials by hand) | dials have no `use`; `use` returns `&"jammed"`; no other state source exists; the staff door is the only exit east (E2) |
  | Skip Trace (read the answer elsewhere) | the ticket values exist **only** in the four Trace memories; no readable repeats them (rule: "the answer lives in exactly one place") |
  | Guess/brute-force | 3 dials × 6 entries = 216 combinations, each move is one-way and each reset costs ~20 s; mixed tickets give no partial feedback → infeasible. The "all dials at the same index" trick fails because the three machines' histories are **not index-aligned** |
  | Use another ability | at this point the player only has Trace and Rewind (availability guard); the door is not an Echo/Freeze target |
* **Estimate:** 5 d (125 s) + 7 e (84 s) + 2 w (30 s) + 1 r (20 s) = 259 s = **4.3 min design** (2.6 floor). ✔ ≥ 3.
* **Cost:** M (one new object class + door wiring). NPCs: 4 queue passengers (art: 2 base bodies × palette).

---

### MP-B · "Crossed Wires" — Echo + Freeze (recommended; becomes `CH1-PZ-007`)

* **Room:** **new room R11 "Cable Gallery"** between Security Crossing and the Waiting Lounge (14×10, E↔W doors), §5.
* **Combo / new because:** Echo and Freeze both appear in PZ-004 but never *together on the same problem*. New insight: **Freeze turns a state an echo is holding into a permanent one, so the single echo can do two jobs.**
* **Idea.** Two security gates in series block the way east. Each gate opens only while *its* pressure plate is held, and the wiring is **crossed on purpose**: the plate the signs label for gate 1 actually feeds gate 2, and vice versa (the signs lie, the conduits do not). One plate can be held by an echo, but the player must pass **both** gates, and cannot stand on a plate while walking away from it. Gate G1's circuit passes through a **hold relay**, a junction box far from the plates, that can be Frozen: a frozen relay keeps its gate in whatever state it was in. So: an echo holds the plate that feeds G1 → G1 opens → walk over and **Freeze the relay** (G1 stays open without the echo) → reset the echo → record a new echo on the other plate → G2 opens → walk through both.
* **Aha:** "Freeze is how I keep a thing open after my echo is gone."
* **Steps:** Trace the conduits to learn which plate feeds which gate (d) + read the splice work order (d) + the splicer's memory (d, he is also a diegetic hint-giver, §4b) → record echo on the correct first plate (2 e) → play it (e) → Freeze the relay (e) → reset echo (e) → record on the second plate (2 e) → play (e) → cross (e).
* **Failure path / feedback:** standing on the **decoy** plate (alarm) → "The alarm buzzes; nothing opens." (no harm); freezing the relay while G1 is *closed* freezes it closed ("held shut", unfreeze with a second Freeze); forgetting to freeze before resetting the echo closes G1 ("The gate follows its plate.").
* **Reuses:** `TriggerZone` plates, `PlateLinkedGate`, `EchoService`, `ResetAnchor`, `PuzzleCompletionZone`.
* **New behaviour:** `PlateLinkedGate` gets an optional `TemporalComponent` (FREEZE): while frozen it ignores plate changes (S); a hold-relay prop that is the freezable target (S).
* **Why it cannot be solved without the combo:**

  | Shortcut | Excluded by |
  |---|---|
  | Freeze the relay while standing on the plate (no echo) | relay placed **≥ 130 iso-px from both plates** (watch radius is 96 px) with a railing between; geometry test on real colliders, ISSUE-021 lesson |
  | Hold one plate, walk to the other gate | player cannot stand on a plate and be at the gate; gates are chrono-shielded (`unsupported` for Rewind/Freeze) so there is no other lever on them |
  | Two echoes | exactly one echo (`echo.0`); a second recording replaces the first |
  | Echo only, no Freeze | the echo holds one plate; the other gate closes when the player leaves its plate |
  | Rewind | relay is FREEZE-only; gates have no `TemporalComponent`; Rewind returns `&"unsupported"` |
  | Skip the room | R11 is on the only route (E4a/E4b) |
* **Estimate:** 3 d (75 s) + 9 e (108 s) + 3 w (45 s) + 1 r (20 s) = 248 s = **4.1 min design** (2.5 floor). ✔
* **Cost:** S-M (+ a new room using existing kit: plates, railings, gates, conduit tiles).

---

### MP-C · "The Night Round" — Trace + Echo (recommended; becomes `CH1-PZ-008`)

* **Room:** **new room R12 "Night Staff Corridor"** between Waiting Lounge and Signal Control (N↔S doors), §5.
* **Combo / new because:** Trace gives a *sequence*, Echo supplies the second body that makes the last step possible.
* **Idea.** The night watchman's last round touched four checkpoint panels in a fixed order, then the sequence lock expects the **last two to be held at the same time** (the "double key" the watchman used with the controller). The order is not written anywhere: each checkpoint carries a residual trace with a time stamp (23:51, 23:52, 23:54, 23:56); Tracing all four gives the order. Press them in order; the lock gives **no feedback until the sequence is complete** (a silent reset). The last two checkpoints are on opposite sides of a railing: an echo recorded walking 1→2→3 and standing on 3 holds plate 3 while the player steps on 4.
* **Aha:** "the order was in the traces; the double key needs a second me".
* **Steps:** Trace four checkpoints and order them (4 d) → record an echo walking the first three in order, stop on the third (4 e) → replay (e) → step on the fourth (e) → the corridor door opens.
* **Failure path / feedback:** wrong order → the lock resets silently and the panels dim for a moment ("The round was not completed."); no information about which step was wrong.
* **Reuses:** `TriggerZone` plates, `EchoService`, `PoweredDoor`-style exit, `ResetAnchor`.
* **New behaviour:** `SequencePlateLock` (listens to plate enter events in order; the last two simultaneously; M).
* **Why it cannot be solved without the combo:**

  | Shortcut | Excluded by |
  |---|---|
  | Skip Echo | plates 3 and 4 are ≥ 3 tiles apart behind a railing; the player cannot occupy both |
  | Skip Trace | 4! = 24 orders; the lock reports nothing until all four are pressed, so each guess costs a full echo recording (≥ 45 s) → expected > 9 min vs. ~3.7 min by reading. **Mastermind feedback ("step 2 was right") is forbidden** — it would reduce the search to ~9 quick walks |
  | Walk 1→2→3 without echo and test | the lock needs the double hold to complete; partial walks produce no feedback at all |
  | Rewind/Freeze | plates and lock are chrono-shielded |
* **Estimate:** 4 d (100 s) + 6 e (72 s) + 2 w (30 s) + 1 r (20 s) = 222 s = **3.7 min design** (2.2 floor). ✔
* **Cost:** M (one lock class + new room).

---

### MP-D · "Cold Chain" — Rewind + Freeze, three machines (alternative)

* **Room:** needs an S-route layout of PZ-004's size (16×12): R11 in place of MP-B, or R12. Not feasible in the 14×10 Maintenance Bay east half.
* **Combo / new because:** Rewind+Freeze appear in PZ-002/004; new here is a **dependency chain with an ordering rule**.
* **Idea.** Three machines (generator → pump → lift). Each runs only after being Rewound to its pre-arrival "running" state, decays to stopped after its window unless Frozen, and **can only be rewound while the machine upstream is running and *unfrozen*** (a frozen upstream "locks the coupling"). The lift's interlock needs **all three running for 5 s in a row** (a dwell longer than any single decay window), so every machine must end up frozen. The naive "rewind it, freeze it, next" fails at the third machine: the player must leave M2 running-but-unfrozen, rewind M3, freeze M3, and only then freeze M2. Trace on the power cables shows who feeds whom.
* **Aha:** "freeze last what I rewound last".
* **Steps:** Trace cables (2 d) → M1: rewind, freeze → M2: rewind (do not freeze) → M3: rewind, freeze → back to M2: freeze → cross: 9 e.
* **Failure feedback:** `&"unpowered"` (rewinding a machine whose upstream is stopped), `&"coupled_frozen"` (rewinding M3 while M2 is frozen), and a lift that stays dark until the 5 s dwell is met.
* **Why not without (R3):** the exclusion is the **dwell**, not speed: no machine can stay running for 5 s unfrozen, so Rewind alone can never satisfy the interlock however fast the player is; Freeze alone cannot start anything; Echo does nothing here (no plates).
* **Estimate:** 2 d (50 s) + 9 e (108 s) + 2 w (30 s) + 1 r (20 s) = 208 s = **3.5 min design**.
* **New behaviour:** `PoweredRewindable` (FireShutter pattern with `upstream_id`, a coupling rule and a dwell check, S-M). **Cost:** S-M + a room.
* **Verdict:** best fallback if the user wants a pure Rewind+Freeze puzzle. Similar flavour to PZ-002, so it adds less *variety* than A-C.

---

### MP-E · "The Parked Cart" — Rewind + Echo (alternative)

* **Room:** new R11 (instead of MP-B) or R12; any 14×10 room after Echo.
* **Combo / new because:** Rewind and Echo are the two *holders*: an echo holds one plate, a **Rewound cart** holds the other.
* **Idea.** A door needs two plates held while the player walks through. A freight cart sat on plate P2 before the accident; now it is stalled at the dock (history = four notches along a track). Trace on the cart shows its route (a ghost trail, so the player learns how many notches back). Rewind it **exactly 2 steps** (3 overshoots to the depot; recoverable via reset) so it rests on P2; record an echo on P1; walk through.
* **Aha:** "the cart is a second weight that time put back".
* **Why not without:** one body cannot hold two plates and walk through; the echo is the first holder, only a rewound cart can be the second (cart `use` is `&"jammed"`, no pushing exists); Freeze is optional (locks the cart on the plate).
* **Estimate:** 2 d (50 s) + 7 e (84 s) + 2 w (30 s) + 1 r (20 s) = 184 s = **3.1 min design**.
* **New behaviour:** `RewindableCart` (history positions + reports occupancy of the plate under it via `trigger_enter(&"cart.0", plate)`, M). **Cost:** M.
* **Verdict:** nicest "aha" after A-C, but needs a cart that holds a trigger (new object-to-trigger path).

---

### Recommendation

**A + B + C** gives three different *combos* (Trace+Rewind, Echo+Freeze, Trace+Echo), a deduction puzzle, a logistics puzzle and a sequence puzzle, and the doorway stage in PZ-005 adds a fourth (Echo+doorway). It needs two new rooms. **No-new-room variant:** A + the PZ-005 stage + the deepenings (Step 1 in §8.2, floor 17.2 min). D and E each need a room of their own, so they replace B or C rather than avoid a room.

---

## 3. Optional side puzzles (task item 3)

All optional, never required, each rewarding one Memory Fragment plus a readable; each ≤ 4 min; each sits in a room the main path crosses and is **visible from the main route** (an odd prop plus a frozen commuter's memory that names it), so finding it needs no backtracking. They are the content the vertical-slice goal (30-45 min) leans on.

### SP-A · "Mira's Second Tape" — Rewind + Freeze (`CH1-SP-01`)

* **Room:** Waiting Lounge. **Reward:** fragment `ch01.fragment.mira_second_tape` + readable "Cassette, side B".
* **Idea.** The porter and a tag on the kiosk locker ("tape, side B, hold for M.") say that Mira left the other tape in the kiosk deck. The deck is a rewindable machine with four segments; it **plays forward by itself** (decays one segment every 2 s) and the message Mira recorded sits two segments back. Trace on the deck shows segment markers; Rewind twice; Freeze so it cannot run on; `use` plays the segment.
* **Aha:** "I have to stop the tape, not just go back".
* **Why not without (R3, dwell):** playback runs 8 s and **aborts if the segment advances**; the deck advances every 2 s, so only a Frozen deck can finish playing, however fast the player is. Freeze alone leaves the deck on the wrong (current) segment; overshoot (3 rewinds) lands on blank tape.
* **Estimate:** 2 d (50) + 5 e (60) + 2 w (30) + 30 s listening/reading = 170 s = **2.8 min**.
* **New:** `HistoryDial` with optional forward decay (shared with SP-B). **Discoverability:** deck is in the lounge kiosk, 6 tiles from the bench; the porter points at it.

### SP-B · "The Foreman's Punch Clock" — Trace + Rewind + Freeze (`CH1-SP-02`)

* **Room:** Maintenance Bay (west half, after Freeze is known). **Reward:** `ch01.fragment.foreman_card` + readable "Shift note, day 5" (ELYSIUM damper budget cut: "the directors said the field *wants* to hold").
* **Idea.** The foreman's frozen memory states when he clocked out (23:53). A shift clock on the wall (analogue hands, history 23:53…23:59) controls his locker: the locker opens only after the clock has read his punch-out time for **5 s in a row** (a dwell). Rewind six steps back; the clock **ticks forward on its own every 2 s**, so Freeze it at 23:53; the locker releases.
* **Why not without:** time of day only from his Trace memory (no readable has it); the clock cannot be set except by Rewind; without Freeze it advances every 2 s, so the 5 s dwell can never be met.
* **Estimate:** 2 d (50) + 5 e (60) + 2 w (30) + 1 r (20) = 160 s = **2.7 min**.

### SP-C · "The Switchboard" — Echo + Trace (`CH1-SP-03`)

* **Room:** R12 Night Staff Corridor (if R12 is not built, this one is cut). **Reward:** `ch01.fragment.switchboard_log` + readable "Call log 23:41-23:59".
* **Idea.** A manual switchboard needs the "listen" seat and the "speak" seat held at the same time ("a call needs two ends"). Three consoles exist; Trace on the cords shows which was used last. An echo holds the speak seat while Elias sits on the listen seat; the log plays: a series of calls from an unlisted line to the **call boxes**, starting before the 23:54 order, none ever closed. Elias is literally on both ends of the call (thematic nod, no explanation).
* **Why not without:** two seats ≥ 4 tiles apart; one body; wrong console (decoys) shows a dead line.
* **Estimate:** 3 d (75) + 5 e (60) + 2 w (30) + 15 s log = 180 s = **3.0 min**.

### SP-D · "Trickle Charge" — Fast-Forward + Freeze (**STRETCH**, `CH1-SP-04`, not in the totals)

* **Room:** Signal Control, dark UPS nook that opens after PZ-004. **Unlock:** after PZ-004 the monitors boot and the watch grows a third hand — the **only** place Fast-Forward appears, late and optional. **Reward:** `ch01.fragment.last_battery`.
* **Idea.** An emergency battery charges 1 notch per 10 s while a leak drains it. Freeze the leak, Fast-Forward the charger (120 ticks per use), fill five notches.
* **Estimate:** 2 d (50) + 6 e (72) + 1 w (15) = 137 s = **2.3 min**.
* **Why a stretch:** `fast_forward` needs an `advance(ticks)` on one object class and an unlock; the main path never depends on it, and it can be cut entirely.

**Chosen:** SP-A, SP-B, SP-C (design 8.5 min, floor 5.1). SP-D only if the stretch is wanted.

---

## 4. Deepening PZ-001..005 (task item 4)

ADR-020 (second amendment) replaces the "at most 2 second stages" limit; the task text still says "at most 2 stages". I satisfy both: **one "stage" that adds a new combo (PZ-005: Echo+doorway)**; the others are **depth-only** (more steps/clues/wrong options inside the same puzzle). Object classes keep their current behaviour behind new, default-off exports, so the existing unit tests of PZ-001..005 stay valid; only the room-level playthrough tests change.

| Puzzle | Today | Deepening | Design (today → new) |
|---|---|---|---:|
| **PZ-001** Fractured Turnstile | 3 e, 0 d | **Rewind solo.** A fallen conduit pins the turnstile. Trace the anchor: the courier's silhouette vaults the gate, *then* the conduit falls (d) → Trace the courier (d, **unlocks Rewind**) → rewinding the turnstile first is refused `&"pinned"` (w) → find and Rewind the conduit back onto its bracket (e) → Rewind the turnstile (e) → a second lane that was never repairable gives `&"no_history"` (w) → walk through (e). New: a `_can_use_ability` dependency (the FireShutter pattern) | 0.6 → **1.9** |
| **PZ-002** Runaway Shutter | 3 e | Prerequisite: **CH1-SO-02 Held Open** (separate Freeze solo, §4a). Then a **second, inner shutter on the same counterweight gear**: the gear is already frozen (S1 held); S2 refuses Rewind while the gear is locked, so the player must **unfreeze → rewind S2 → refreeze**, in that order, inside a generous window (the sequence needs ~6 s of a 300-tick assisted hold). A **railing S-route in the east half** (new colliders) makes the walk from the casting spot to the east door ≥ 650 px (5.4 s) so that, unlike today (§0.11), Freeze is needed even with the assist on. Clues: tech log (d) + Trace of the slipping gear (d). Wrong: freezing first, a decoy gear (non-freezable). Fire-shutter timer expiring once costs a redo (r) | 0.6 → **3.1** (solo +2.1 separate) |
| **PZ-003** Delayed Platform (Echo solo) | 6 e | Guard's memory: "gate follows the **south** plate; the north one is the alarm" (d) and the guard's log (d, insurance). A **second** barrier east of the bridge needs the staff **transit pass** from the desk (the pass is `progression = true`: recording an echo that fetches it fails `&"echo_forbidden"`, a teachable wrong option, w). Pass at a card reader, then the exit. Decoy north plate (w) | 1.2 → **2.7** |
| **PZ-004** Synchronized Substation | 9 e | Hub of three order-free sub-goals: (1) stabilise the capacitor (existing), (2) learn from the engineer's memory (d) and the bus chart (d) that the **third breaker C is the lamp ring and browns out the capacitor** ("do not engage C on the bus"), (3) the two-breaker sync. Pulling C is a plausible wrong option with a real cost: the capacitor discharges and Step 1 must be redone (w + r). The Z-route layout, railings and the 180-tick window are unchanged | 1.8 → **3.2** |
| **PZ-005** Displaced Corridor — **stage (Echo+doorway)** | 4 e | The relay levers are **dead until the standby plate** in the SW corner is held (they draw standby power). The player cannot stand on the plate and reach either lever, so an **echo holds the plate** while Elias pulls A then B. Clues: route board Trace (d), relay memo (d), the tourist's memory (d). A third, **decoy lever C** applies a valid-but-useless pairing (swaps west/east); pulling B before A is still `invalid_graph`. The niche plaque stays optional | 0.8 → **3.3** |

**Shortcut check (same format as §2):**
* PZ-001: the conduit gate is a state rule (`_can_use_ability`), not geometry; the second lane cannot be rewound; nothing else moves the turnstile. Rewind is the only acting ability available at that point.
* PZ-002: the dependency (gear locked ⇒ no Rewind) is the existing rule 4, now applied twice. The shortcut "Rewind and just run" is excluded by the new route (≥ 650 px ≥ the **assisted** 300-tick window, R3), proven by a real-collider route test plus a "Rewind, walk, no Freeze" negative test; the unfreeze → rewind → refreeze step needs ~6 s, well inside the window, so no precision.
* PZ-003: the pass reader and the plate both need the player; the echo cannot take the pass (`echo_forbidden`, ADR-006); gate and bridge stay chrono-shielded.
* PZ-004: Step 1/2 geometry unchanged (635.8 px route vs. a 180-tick window; ISSUE-021 negative tests still apply). C is a *trap*, not a requirement.
* PZ-005: plate and levers are ≥ 4 tiles apart (reach 36 px); the plate accepts echoes; the lever's `_can_use` returns `&"unpowered"` without it; the graph rules (`invalid_graph`, `critical_path_unreachable`) still forbid soft locks.

---

## 4a. Ability curve (task item 4a)

### Start with Trace — why

| Candidate | Verdict |
|---|---|
| **Trace** | **Chosen.** It is the only ability that cannot break anything (no state change, no failure state, no reset), so the first minutes are safe. It matches the premise (an amnesiac sees what *was* here). It is the vehicle for the frozen commuters and the "story of the room", which is exactly what the user asked for. It makes every later unlock feel earned: Trace tells *what*, the next ability supplies *how*. Risk: ~3.5 min with no state-changing power. Mitigation: SO-01 is a real deduction with physical input and a visible reward (the platform gate), and the commuters give the first world-building. |
| Rewind | Iconic, but needs a target immediately and gives the player no reason to look at people. |
| Freeze | Needs a moving thing; the platform has none. |

### Unlock order, tied to story moments

Each unlock is **diegetic and in the world**: the watch's single working hand changes behaviour when Elias traces the thing that teaches it. HUD shows locked slots greyed; unlocks persist in the save (requirement from the amendment).

| # | Ability | Story moment (what / where / who triggers) | Watch motif (art/audio) |
|---|---|---|---|
| 1 | **Trace** | Beat 01, Arrival Platform: Elias picks up the cracked watch (`global.pocket_watch`). One hand still moves. | hand sweeps once, a faint ring on the nearest thing with a memory |
| 2 | **Rewind** | Beat 02, Concourse West: tracing the **courier** frozen mid-vault over the turnstile (flag `ch01.npc.courier.traced`). His last thought is "go go go"; the hand **clicks backwards** one notch. Elias: "It went back. One step." | hand ticks backwards |
| 3 | **Freeze** | Beat 04, Maintenance Bay: tracing the **hatch tech** whose hands are still locked on a hatch crank ("hold it open!"). The hand **stops dead** for a heartbeat. Elias: "It can hold things still." | hand stops |
| 4 | **Echo** | Beat 05, Security Crossing: using the **echo pedestal** (already in PZ-003). A second, fainter hand splits off the first. The Operator's PA line (existing) fires on first playback. | a second hand follows |
| 5 | Fast-Forward (**stretch, optional**) | After PZ-004, Signal Control monitors boot; the hand races. Only used by SP-D. | hand races |

### Solo puzzles (alone, before combinations)

| Ability | Solo puzzle | Where | Notes | Design min |
|---|---|---|---|---:|
| **Trace** | **CH1-SO-01 "Last Departure"** (new) | Arrival Platform | Platform gate to the concourse needs LINE · PLATFORM · CAR set on three 3-position **selector dials** (each an on-use cycle). The values come from what four frozen people said at different times; **the latest statement per field wins** (the conductor, 23:57: "Hollow Quay, rear car only"; the cleaner, 23:58: "they moved the last service to platform 3"; older, wrong statements from a student at 23:41 and an old man at 23:30). Wrong code → 6 s lock-out, no partial feedback. 27 combinations: brute force ≈ 4 min vs. 2.7 min by reading. Steps: 4 d, 4 e, 1 w. Reward: the gate, plus four journal observations that form the first timeline | **2.7** |
| **Rewind** | **PZ-001 deepened** (§4) | Concourse West | solo, Trace supplies information | **1.9** |
| **Freeze** | **CH1-SO-02 "Held Open"** (new) | Maintenance Bay, west half | The way to the shutter is two **service hatches in series**, each held open only while its **floor plate** is occupied (a `PlateLinkedGate`). The plates are within reach of the hatch (≤ 96 px) but the walk-through is further, so stepping off closes the hatch. **Freeze the hatch while standing on its plate** (it keeps its open state), step off, walk through; the second hatch is the same. A green decoy plate only rings a bell. Clues: the hatch tech's memory ("hold it open!") and the maintenance chart. No timers, so the assist cannot weaken it. Steps: 2 d, 5 e, 1 w | **2.1** |
| **Echo** | **PZ-003 deepened** (§4) | Security Crossing | solo, Trace supplies the guard's clue | **2.7** |

Solo bar (≥ 1.5 min) ✔ for all four. SO-02 also lays the ground for MP-B: first "Freeze keeps a gate how I left it" while standing on the plate, then the same idea with the relay out of reach, which is where the echo comes in.

### Re-sequenced order of all puzzles (the main path)

"Available" = abilities in the watch when the player arrives; "required" = acting abilities the solution needs (Trace = information, always available). Minutes are design / floor.

| # | Room | Puzzle | Available | Required (acting) | Design | Floor |
|--:|---|---|---|---|---:|---:|
| 1 | R1 Arrival Platform | Beat 01 + CH1-SO-01 Last Departure | Trace | — (Trace only) | 3.5 | 2.1 |
| 2 | R2 Concourse West | PZ-001 Fractured Turnstile (Rewind unlocks) | Trace, Rewind | Rewind | 1.9 | 1.2 |
| 3 | R2 Concourse West | Beat 03 + **PZ-006 Last Ticket** (MP-A) | Trace, Rewind | **Trace+Rewind** | 5.0 | 3.0 |
| 4 | R3 Maintenance Bay | CH1-SO-02 Held Open (Freeze unlocks) | + Freeze | Freeze | 2.1 | 1.3 |
| 5 | R3 Maintenance Bay | PZ-002 Runaway Shutter | T, R, F | **Rewind+Freeze** | 3.1 | 1.8 |
| 6 | R4 Security Crossing | PZ-003 Delayed Platform (Echo unlocks) | + Echo | Echo | 2.7 | 1.6 |
| 7 | **R11 Cable Gallery** (new) | **PZ-007 Crossed Wires** (MP-B) | T, R, F, E | **Echo+Freeze** | 4.1 | 2.5 |
| 8 | R5 Waiting Lounge | Beat 06: Mira bench, recorder, porter | all four | — (Trace) | 1.2 | 0.7 |
| 9 | **R12 Night Staff Corridor** (new) | **PZ-008 Night Round** (MP-C) | all four | **Trace+Echo** | 3.7 | 2.2 |
| 10 | R6 Signal Control | PZ-004 Synchronized Substation | all four | **Rewind+Freeze+Echo** | 3.2 | 1.9 |
| 11 | R7 (+R8) Upper Vestibule | PZ-005 Displaced Corridor (stage) | all four | **Trace+Echo+doorway** | 3.3 | 2.0 |
| 12 | R9 Station Atrium | Beat 09 Ledger 23:59 | all four | — (Trace) | 1.0 | 0.6 |
| 13 | R10 Street Exit | Beat 10 | all four | — | 0.4 | 0.2 |
| | Room-to-room walking | | | | 1.6 | 1.0 |
| | | | | **Main path total** | **36.8** | **22.1** |

Non-puzzle time is inside rows 1, 3, 8, 12, 13 and the walking row: Beat 01 (0.8), Beat 03 (0.7), Beat 06 (1.2), Beat 09 (1.0), Beat 10 (0.4) and 1.6 min of room-to-room walking = the 5.7 min of §8.1. Optional content (not in the table): SP-A (Lounge) 2.8, SP-B (Maintenance Bay) 2.7, SP-C (R12) 3.0 = 8.5 design / 5.1 floor.

### Do PZ-001..005 stay solvable at the new positions?

| Puzzle | Needs (original) | Available on arrival | Result |
|---|---|---|---|
| PZ-001 | Trace + Rewind (spec); **Rewind only in code** (§0.2) | Trace; Rewind unlocks on the first Trace of the courier, *before* the turnstile is reachable | ✔ Original solution still works; only an extra conduit step is added |
| PZ-002 | Rewind + Freeze | Trace, Rewind; Freeze unlocks in the same room (hatch tech) before the shutter is reachable | ✔ |
| PZ-003 | Echo | Echo unlocks at the pedestal (the spec already says the pedestal "initiates Echo mode") | ✔ |
| PZ-004 | Rewind + Freeze + Echo | all unlocked | ✔ |
| PZ-005 | Trace + levers | all unlocked | ✔ original two-lever solution plus the Echo-powered relays and the decoy |

**What changes for PZ-001 ("needs Trace+Rewind today")**: nothing about the solution; in the new curve Trace is the *start* ability, so the puzzle begins with both available, and the Trace step now carries real information (the order of events) instead of being decorative. **Test impact:** scripted playthroughs that assume all four abilities from the start must set the unlock flags; unit tests of the object classes are unaffected.

---

## 4b. NPCs (task item 4b)

### Frozen commuters (≥ 8 required; 23 proposed, 13 needed by puzzles)

People who **did not make the 23:54 evacuation**, caught mid-gesture at 23:59. Frozen people are traceable `TraceMemory` objects; a Trace shows a 1-2 line memory with a **time stamp** ("[23:57]") and adds a journal *observation* (the journal is the notebook, so no puzzle depends on the player memorising). "S1" = needed for Step 1 of §8.2 (puzzle/unlock linked); "S2" = world colour. All lines are DRAFT.

| ID | Who | Room · place | Doing at 23:59 | Trace memory (DRAFT) | Link | Step |
|---|---|---|---|---|---|---|
| N-01 | Ines, conductor | R1 · at the car door, east end | thumb on the close button, whistle in her teeth | [23:57] "Doors closing — Hollow Quay, rear car only! They keep changing it; go by the last announcement." | SO-01: LINE + CAR (latest), teaches the rule | S1 |
| N-02 | Tomas, student | R1 · platform edge | one foot over the yellow line, phone in hand | [23:41] "Mum says Central, platform 1, front car. She can't know about the cancellations, can she?" | SO-01 decoy (older) | S1 |
| N-03 | Mr. Adeyemi, old man | R1 · bench | paper bag on his knee | [23:30] "Harbour line, platform 2, middle car. Forty years, same bench, same train." | SO-01 decoy (older) | S1 |
| N-04 | Night cleaner | R1 · near the exit | trolley half-turned | [23:58] "They moved the last service to platform 3 — hauled my trolley over. One minute and I'm clocked out." | SO-01: PLATFORM (latest) | S1 |
| N-05 | Dev, bike courier | R2 · turnstile, **mid-vault** | airborne over the gate, bag in hand | [23:59] "Not stopping for a gate — the conduit's coming down — go go GO." | **Rewind unlock**, PZ-001 clue | S1 |
| N-06 | Woman in a red coat | R2 · ticket queue 1 | card in hand | [23:41] "Harbour, platform 1… I'll make the 23:50 if this thing prints." | PZ-006 ticket (decoy) | S1 |
| N-07 | Man with a briefcase | R2 · queue 2 | checking his watch | [23:49] "Central, platform 2. Third notice today that says 'not a drill'." | PZ-006 ticket (decoy) | S1 |
| N-08 | Father with a sleeping child | R2 · queue 3 | child on his shoulder | [23:53] "Orchard Gate, platform 3. Just let her sleep, just let her sleep." | PZ-006 ticket (right line, too early: decoy) | S1 |
| N-09 | Teenager with headphones | R2 · queue 4 | pressing the stamp | [23:55] "Orchard Gate, platform 1 — bought it right when they said 'evacuate'. Whatever." | PZ-006 **target ticket** (Orchard Gate, P1, 23:55) | S1 |
| N-10 | Kiosk vendor | R2 · kiosk shutter | pulling the roll shutter | [23:54] "'Staff secure the lower concourse.' Who's securing me, I'd like to know." | evacuation-order colour, JRN | S2 |
| N-11 | Hollis, hatch tech | R3 · service hatch | both hands on a hatch crank | [23:58] "Hold it — hold it open! I'll fetch the wrench — hold it —" | **Freeze unlock**, SO-02 clue | S1 |
| N-12 | The foreman | R3 · punch clock | card in the clock | [23:53] "Punched out. Gear's slipping, lads — nobody stands under that shutter, understood?" | SP-B (time 23:53) | S2 |
| N-13 | Corva, security guard | R4 · booth | one hand on the gate lever | [23:57] "Gate follows the south plate. The north one's the alarm. Trust me on that." | PZ-003 clue | S1 |
| N-14 | **Wren**, cable splicer (**interactive**, §4b-2) | R11 · half under a cabinet | tool in hand | [23:55] "Crossed them on purpose. The first plate feeds the second gate. Directors' orders, so don't ask me." | PZ-007 clue | S2 |
| N-15 | Abel, night watchman | R5 · vending machine | thermos to his lips | [23:53] "Four checkpoints on my round: tickets, lamp, crates, stairs. Never the same way twice — the controller likes it that way." | PZ-008 context (the four names, **not** the order, R1) | S2 |
| N-16 | Woman asleep on a bench | R5 · bench corner | head on her coat | [23:56] "Wake me when the 00:05 comes in." | colour: slept through the order | S2 |
| N-17 | **Odalys**, porter (**interactive**, §4b-2) | R5 · by the window | moving *very* slowly | (spoken, not Traced) | lore, SP-A pointer | S2 |
| N-18 | Pell, station controller | R12 · desk | phone to her ear | [23:57] "Level-0 sign-off, yes, yes. Which terminal — the Atrium? Of course the Atrium." | seed (question planted for Beat 09) | S2 |
| N-19 | Dr. Sade, medic | R12 · corridor | pointing at the stairs | [23:58] "Everyone up the stairs. Everyone. Has anyone seen the man from the lab?" | seed, **user decision** (Q-6) | S2 |
| N-20 | Lis, signal engineer | R6 · console | hand on a breaker | [23:56] "Bus 2 is hot. Don't touch C — C's the lamp ring, it'll brown out the whole bank." | PZ-004 trap clue | S1 |
| N-21 | Ayo, tourist | R7 · in front of the arches | map open, turning round | [23:55] "North, then west, then north again. I keep coming out of the same door." | PZ-005 clue | S1 |
| N-22 | Crowd of five | R9 · at the blast doors | hands on the doors | [23:58] "Open it! Why won't it open?!" | emotional beat before the terminal | S2 |
| N-23 | Usher | R10 · stairs | hand out for a ticket | [23:59] "Mind the step, mind the — it's still raining, isn't it?" | colour | S2 |

Counts: 23 commuters (22 Traceable + the porter, who is spoken to), **13 needed for Step 1** (N-01…N-09, N-11, N-13, N-20, N-21 = 13). Art budget idea: 3 base bodies × 2 poses + ~14 props, palette swaps from the existing 32-colour palette, desaturated so "frozen" reads against the living Elias. Collision: commuters that stand on a route get small collision footprints (added to the fingerprint tests, ADR-019); the rest are non-blocking. Traceable commuters keep ≥ 48 px spacing so ADR-015 targeting always picks the intended one.

### Interactive NPCs (2 proposed, both optional lore/hint delivery)

**I-1 Odalys, the porter (Waiting Lounge).** *Concept:* the freeze did not take her cleanly; she moves at roughly one frame every three seconds and her sentences arrive one word at a time. `use` opens a short line set that changes with flags (after the Mira recorder, after PZ-008, after the terminal she is silent). *Lore fit:* evacuation 23:54, lock 23:59, the Operator is only a voice; she only ever mentions "the voice on the old call boxes".
* **She reveals:** the lower concourse was emptied first, the platform last (known); the call boxes rang *all evening, before the order* ("I told the Stationmaster; he said nobody was calling"); a woman and a man who sat like Elias argued on the bench and the woman left a tape in the kiosk deck (points to SP-A).
* **She deliberately does not reveal:** who locked the station, who the Operator is, that the calls come from a different time, what ELYSIUM does, where Mira is. Beat 09 stays the only revelation.

**I-2 Wren, the cable splicer (R11).** *Concept:* half under a cabinet, the freeze caught his hand in mid-twitch. He is a **diegetic hint ladder** for PZ-007: first use "Crossed them on purpose. The first plate feeds the second gate." (nudge), second use "A frozen junction stays how you left it." (rule reminder), third use names the relay (next action). Replaces nothing in `HintService`; it only makes the hint feel like part of the world.
* **He reveals:** the crossed feed was ordered by "the directors" under work order 0959 and he was told not to label it.
* **He does not reveal:** why they wanted the loop, who ordered it.

Both need one small `ConditionalDialogue` (lines chosen by narrative flags; no branching UI).

---

## 4c. World building per room (task item 4c)

Each "story of the room" covers 23:54-23:59 and is expressed through dressing, a sign, a readable and the commuters above. The wish-list for design-art includes only what serves the story. All text is draft.

| Room | Story of the room (23:54-23:59) | Dressing / signage / light mood (design-art wish-list) | New readables |
|---|---|---|---|
| **R1 Arrival Platform** | The last service to Hollow Quay was held "for one more passenger". At 23:54 the platform was told to take the stairs; the conductor held the doors, the cleaner kept working, the student stayed on his phone. At 23:59 the lock fell with the doors half-closed. | amber emergency strips, a departure board with the line field flickering, a conductor with her whistle, a tilted paper bag, chalk platform numbers | `doc_last_service` (PA log: the *times* of three announcements, no values; insurance for the rule "latest wins") |
| **R2 Concourse West** | People kept queueing to buy tickets for five minutes after the evacuation order because the machines never stopped issuing. A courier vaulted the turnstile as the ceiling conduit fell. The vendor shuttered the kiosk. | three split-flap boards (LINE / PLATFORM / TIME) on a ticket-machine wall, a queue of four, a kiosk with the roll-shutter half down, fallen conduit over the turnstile, a cool blue ceiling with a warm queue-lamp | `doc_ticket_terms` ("After the order, only Orchard Gate tickets are honoured at the staff door.") |
| **R3 Maintenance Bay** | The crew had logged "chronometric backflow" for days. At 23:54 the foreman clocked everyone out; one tech stayed holding a service hatch open for the others. | steam haze, two weight-plate hatches with brass cranks, a green decoy plate with a bell, a wall shift clock with the foreman's card, hazard stripes, a technician's hands still on the crank | `doc_hatch_chart` (which plate works which hatch; the green one only rings a bell) |
| **R4 Security Crossing** | The guard sealed the trench for staff-only transit and rerouted the passengers; the "alarm" plate was left live because nobody was told to disarm it. | red alarm light on the decoy plate, guard booth with a log, a card reader at the east barrier, the torn-photo transit pass on the desk | `doc_guard_log` ("S = gate, N = alarm. Do not stand on N.") |
| **R11 Cable Gallery (new)** | ELYSIUM engineers re-routed the station's feeds through this gallery so the field could "feed back"; the crossing was deliberate and unlabeled. The splicer was caught under the cabinet finishing the last splice. | racks of cable with mislabelled tags, a hand-lettered "N → S" chalk mark under the grime, a hold-relay junction box with a brass handle, blue/amber conduit chevrons | `doc_splice_ticket` ("Work order 0959: cross feed per FIELD-SPEC. Do not label.") |
| **R5 Waiting Lounge** | The 23:50 was DELAYED, so people sat and waited under a board that told them to. Mira and a man who sat like Elias argued on the bench; she left her recorder. A woman slept through the announcement. | dim warm lamps, the delayed board, a kiosk with a cassette deck, a thermos, a coat over a sleeper, the window onto the dark tunnel | `doc_lost_property` (tag on a kiosk locker: "tape, side B, hold for M.") |
| **R12 Night Staff Corridor (new)** | Staff mustered here to "secure the lower concourse" per the order. The watchman finished his round on autopilot; the controller took a Level-0 sign-off call; the medic herded people to the stairs. | institutional green walls, four checkpoint panels with key slots, a controller desk and old switchboard, a notice board, a bleak fluorescent flicker | `doc_round_sheet` (the four station *names* without the order), `doc_signoff_slip` ("Level-0 sign-off required — see Atrium terminal") |
| **R6 Signal Control** | Engineers tried to cut the field by dropping the signal bus and failed; the engineer warned the others about the lamp ring and kept her hand on the breaker. The intercom started to ring. | blue-white console glow, a labelled breaker bank A/B/C with a red C, a wiring chart on the wall | `doc_bus_chart` ("Bus 2: A, B feed the vestibule door. C = lamp ring — NEVER on-bus.") |
| **R7 Upper Vestibule** | When the field ramped, the arches stopped agreeing about where they led. A tourist kept walking north and coming out west. Facilities had pinned a standby-power memo to the relay box. | transom glyphs ◁ ◇ ▲ ■, a map-holding tourist, a relay box with a standby plate in the corner, a flickering ceiling light | `doc_relay_memo` ("Relays draw standby power from the floor plate. Keep it held.") |
| **R8 Vestibule Niche** | A facilities alcove whose grille was sealed at 23:58; it shows the Atrium through bars. | iron grille, dust, a pale light from the Atrium side | existing `doc_index_plaque` (no change) |
| **R9 Station Atrium** | At 23:58 everyone who remained ran to the blast doors; they stand with their hands on them, asking why they will not open. The master clock hangs over the Dispatch Recorder. | a crowd silhouette against the doors, a very big clock, long shadows, cold light shafts | none (Beat 09 reads exactly as written; the crowd is atmosphere) |
| **R10 Street Exit** | Rain hangs in the air; an usher waits with his hand out for a ticket that will never come. | suspended rain, wet steps, neon glow, the payphone | none |

New readables total **8** (plus the 4 fragments' texts), within the 4-6 + fragments ADR guidance (the extra ones are one-line signs).

---

## 4d. Story sub-beats (task item 4d)

The ten core beats stay; **Beat 09 stays the only revelation.** New sub-beats sit between them. Minutes are design (floor = 0.6×).

| Core beat | New sub-beats | Min (design) |
|---|---|---:|
| **01** Awakening | 01a "Still people": the first frozen commuter, a first Trace (tutorial in a safe moment) · 01b **Last Departure** (SO-01) | 0.8 + 2.7 |
| **02** Fractured Turnstile | 02a "The courier": Rewind unlocks · 02b PZ-001 deepened | 1.9 |
| **03** Call Box 09 | 03a the queue, the bulletin and the Operator's new hint · 03b **Last Ticket** (PZ-006) · 03c the vendor | 0.7 + 4.3 |
| **04** Runaway Shutter | 04a "Hold it open": the hatch tech, Freeze unlocks · 04b **Held Open** (SO-02) · 04c PZ-002 deepened · 04d (optional) **Foreman's clock** (SP-B) | 2.1 + 3.1 (+2.7) |
| **05** Delayed Platform | 05a the guard, Echo unlocks (pedestal) · 05b PZ-003 deepened · 05c **Crossed Wires** (R11, PZ-007) with Wren | 2.7 + 4.1 |
| **06** Ghosts in the Lounge | 06a Mira's bench + recorder (existing) and the porter · 06b (optional) **Mira's Second Tape** (SP-A) · 06c **The Night Round** (R12, PZ-008), the controller's call, (optional) **Switchboard** (SP-C) | 1.2 + 3.7 (+2.8, +3.0) |
| **07** Synchronized Substation | 07a the engineer's warning · PZ-004 deepened (trap breaker C) · the intercom as today · (optional stretch) FF unlock | 3.2 |
| **08** Displaced Corridor | 08a the tourist · PZ-005 stage (Echo-powered relays, decoy lever) | 3.3 |
| **09** Ledger 23:59 | 09a **the crowd at the blast doors** (new, before the terminal) · the revelation exactly as written | 1.0 |
| **10** Ascent | none | 0.4 |

**Structure the new content creates:** a question planted early and answered at Beat 09. The slip ("Level-0 sign-off required — see Atrium terminal"), the controller's call and the existing Level-0 transit pass all say *someone with Level-0 had to do this*. The player carries "who?" for 20 minutes; Beat 09 answers it (Elias) without any new reveal.

---

## 5. Placement sketch (task item 5)

Rules: every existing puzzle's collision geometry stays exactly as is (ADR-019); new objects get their **own fingerprint entries** and real-collider reach tests (ISSUE-021). Doorways stay on boundary tiles with opposite-side pairing (ROOM_GRAPH §1). All new rooms fit the fixed 640×360 camera.

### New rooms (max 2)

**R11 Cable Gallery** — 14×10 (384×192 px floor). *Doors:* `door_entry_west` (W, (0,5)) ↔ `ch01.security_crossing:door_exit_east`; `door_exit_east` (E, (13,5)) ↔ `ch01.waiting_lounge:door_entry_west`. *Replaces edge E4* with E4a + E4b (both E↔W). *Layout:* west deck x 1-4 holds the two plates (north (2,2), south (2,8)) and the alarm decoy plate (4,5); the central corridor x 5-12 holds gate G1 (6,5) and gate G2 (9,5); the hold-relay box sits at (10,2) on a raised cable rack behind a railing, **≥ 130 iso-px from both plates** (143 px from the north plate, 225 px from the south one); reset console at (3,5). *Checkpoint:* `ch01.cp.cable_gallery` at (1,5).

**R12 Night Staff Corridor** — 12×12 (384×192 px floor). *Doors:* `door_entry_south` (S, (6,11)) ↔ `ch01.waiting_lounge:door_exit_north`; `door_exit_north` (N, (6,0)) ↔ `ch01.signal_control:door_entry_south`. *Replaces edge E5* with E5a + E5b (both N↔S). *Layout:* four checkpoint plates in a loop around a central desk (plates 3 and 4 on opposite sides of a railing), the controller desk NW, the switchboard NE (SP-C), reset console SW. *Checkpoint:* `ch01.cp.staff_corridor` at (6,10).

```
R11 Cable Gallery (schematic, not to scale)      R12 Night Staff Corridor (schematic)
 W door                          E door                              N door
   | P1  .   .   .   .   R1 .  .   |                      +--------------------+
   | .   .  [G1]  . [G2]  .   .    |                      | P2   desk    P4    |
   | .   X(alarm) . . . . . . . .  |                      |  \   ===    / (rail)|
   | P2  .   .   .   .   .   .  .  |                      | P1   board   P3    |
   |   reset                        |                      +----------S door----+
```

### Existing rooms (where the new things live)

| Content | Room · tile area (existing footprint) | Notes |
|---|---|---|
| SO-01 selectors + gate | R1 (14×10) · selector panel on the north wall, x 10-12 y 0-1; gate in the existing E doorway (13,5); commuters along the south platform edge and the bench | PoweredDoor-style gate; commuters off the spawn anchor (7,5) |
| Courier, conduit, second lane | R2 (16×12) · around the existing turnstile (2,5)/(2.5,5); conduit on the ceiling above lane 1 | existing gate/anchor positions unchanged |
| Ticket-machine wall + queue + staff door | R2 · east half x 9-14, y 2-9; dials on the north wall, queue along y 5-8; staff door is the existing E exit (15,5) | the east exit becomes the validator door |
| Two hatches + plates + decoy plate | R3 (14×10) · west half x 1-5, plates ≤ 96 px from their hatch, walk-through further | existing shutter (8,4) / gear (5,1) and casting spot (6,4) unchanged; a layout pass may move the hatches to the east half if the west is too tight |
| Inner shutter S2 + railing S-route | R3 · east half x 9-13; the S-route makes shutter-to-door ≥ 650 px | shares the existing counterweight gear; new colliders get their own fingerprint, existing ones are untouched |
| Second barrier + reader | R4 (16×12) · east of the bridge, before `exit_trigger_lounge` | reader is a `use` object |
| Breaker C + chart | R6 (16×12) · north-west mezzanine, 6+ tiles from Breakers A/B | does not touch the 635.8 px Z-route |
| Standby plate + decoy lever C | R7 (14×14) · plate SW (2,11); lever C at (7,2) (north) | existing levers (3,7)/(11,7) and reset pedestal unchanged |
| Shift clock + locker (SP-B) | R3 · south wall | optional |
| Kiosk tape deck (SP-A) | R5 (12×10) · east wall | optional |

### Main-path order

`R1 → R2 (turnstile, then Last Ticket) → R3 (Held Open, then shutter) → R4 → R11 → R5 → R12 → R6 → R7(+R8) → R9 → R10`. Backtracking check (ROOM_GRAPH §4.3): all new edges are static, bidirectional, and the solved puzzles are latched (ADR-016), so a full walk back needs **zero** ability re-execution.

### Fast-Forward

At most once, late, optional: **SP-D in Signal Control after PZ-004** (stretch). The main path never needs it.

---

## 6. Narrative tie-in (task item 6)

No new main revelation. Hard limits for all new text: **never** state who sealed the station, **never** state who the Operator is, no loop count, no word on where Mira is beyond the Beat 10 hook. Allowed: questions, seeds and ambiguity.

| Thread | New material (all draft) | What it deepens |
|---|---|---|
| **Operator** | New Call Box 09 line after PZ-006: "The staff door answers to the last ticket, I'm told. I'm told a lot of things." · a PA line in R11 after PZ-007: "Crossed on purpose. Somebody wanted the field to feed back." · porter: "the boxes rang all evening, before the order" · switchboard log (SP-C): calls from an unlisted line **start before 23:54** and none ever closes | the voice knows things it should not; its calls precede the event. Ambiguous, not explained |
| **Mira** | Second tape (SP-A): "If it works, the clock stops once. I don't know who starts it again." · lost-property tag "tape, side B, hold for M." · the sleeping woman and porter confirm two people argued on the bench | Mira's fear is specific (a stop and a restart); the bench scene gains a witness |
| **ELYSIUM** | Work order 0959 "cross feed per FIELD-SPEC, do not label" · foreman's note "the directors said the field wants to hold" · the evacuation bulletin ties tickets to the 23:54 order · relay memo | ELYSIUM engineered the station on purpose; staff noticed and were overruled |
| **23:59 / the five minutes** | every Trace memory carries a time stamp; the journal collects them into a **"The Five Minutes" timeline** (observations sorted by stamp, optional UI) · the "everyone kept doing what they were doing" motif (the vendor, the cleaner, the sleeper) | the chapter's question becomes "why did nobody run?", which Beat 09 reframes |
| **Question for Beat 09** | `JRN_CH1_LEVEL0_SIGNOFF` (theory): "Someone with Level-0 clearance had to sign this off. Who?" seeded by the controller (N-18), the slip (R12) and the existing transit pass | Beat 09's single revelation resolves a question the player has been carrying |

Proposed new journal entries (draft keys): `JRN_CH1_FIVE_MINUTES`, `JRN_CH1_CROSSED_FEED`, `JRN_CH1_LEVEL0_SIGNOFF`, `JRN_CH1_CALLS_BEFORE_ORDER`, `JRN_CH1_MIRA_ONCE`, `JRN_CH1_FOREMAN_DAMPER`, plus one observation per Traced commuter (generated from the memory). Fragments: `mira_second_tape`, `foreman_card`, `switchboard_log` (3 optional) on top of `mira_departure`.

---

## 7. Open questions (task item 7)

| # | Question | Who | My recommendation |
|---|---|---|---|
| Q-1 | **Does Trace really show nothing today?** (§0.1, from code reading only) Please confirm in the running game: Trace the turnstile anchor and the lounge bench. | Flash / Lead | If confirmed, `TraceMemory` is the first thing to build; it also fixes the lounge bench |
| Q-2 | Start with **Trace** (recommended) or a different first ability? | User | Trace, for the reasons in §4a |
| Q-3 | **New rooms:** 0, 1 or 2? 2 gives variety (MP-B, MP-C, SP-C). 0 still reaches the target (Step 1: 17.2 floor) but has only one new combo (MP-A); D and E each need a room. | User / Lead | 2 rooms, built in two steps (§8.2) |
| Q-4 | "At most 2 stages" (task) vs. no limit (ADR amendment): I used 1 stage + 4 depth-only deepenings. OK? | Lead | OK; consistent with both readings |
| Q-5 | **Number and look of frozen people:** 13 for Step 1, 23 total. Desaturated "statues" vs. normal colours with a shimmer? Art cost ~3 bodies × 2 poses + props. | User | 13 first, desaturated + shimmer |
| Q-6 | **Seeds for Beat 09:** the medic's "the man from the lab" (N-19) and the controller's "which terminal? the Atrium" are deliberately ambiguous. Too strong, or fine? | User | Keep the controller; make the medic's line vaguer or cut it |
| Q-7 | **Interactive NPC tone:** the porter hearing "boxes that rang before the order". Does this pre-empt the Operator's identity? | User | Keep (it is a question, not an answer) |
| Q-8 | **Brute-force policy** for code/sequence locks: 6 s lock-out (SO-01) vs. silent reset + full redo (PZ-008). Acceptable? | Lead | Yes; never give per-step feedback |
| Q-9 | **Hints:** 8 new/changed puzzles need 3 hint keys each (`PuzzleDef`); Wren is a diegetic hint-giver. Also an in-game notebook rule: every Trace memory adds a journal observation. OK? | Lead | Yes, mandatory for information-heavy puzzles |
| Q-10 | **Save/unlocks:** `unlocked_abilities` must be saved and restored (ADR-020 amendment). The HUD shows locked slots greyed. | Opus / Flash | in phase 2 |
| Q-11 | **PZ-002 does not seem to need Freeze** (§0.11). Add a real-input negative test now (it will probably fail today), and accept the new east-half route in §4 as the fix? ADR-019 keeps the existing collision, so the fix is additive. | Lead | Yes; ask Opus for the negative test first |

*Stop conditions (task):* none triggered. No concept needs a new mechanic beyond SD-1 (+ one optional FF stretch) or any change to the `InteractionService`, `TemporalComponent` or `EchoService` contracts. The Trace finding (§0.1) is a missing *presentation*, not a contract change.

---

## 8. Roll-up: does the chosen proposal reach 15 minutes?

### 8.1 Where the 36.8 min come from (design), with the model of §1.3

| Content | d | e | w | r | Design min | Floor |
|---|--:|--:|--:|--:|---:|---:|
| SO-01 Last Departure (Trace solo) | 4 | 4 | 1 | – | 2.7 | 1.6 |
| PZ-001 Fractured Turnstile (Rewind solo) | 2 | 3 | 2 | – | 1.9 | 1.2 |
| PZ-006 Last Ticket (Trace+Rewind) | 5 | 7 | 2 | 1 | 4.3 | 2.6 |
| SO-02 Held Open (Freeze solo) | 2 | 5 | 1 | – | 2.1 | 1.3 |
| PZ-002 Runaway Shutter (Rewind+Freeze) | 2 | 7 | 2 | 1 | 3.1 | 1.8 |
| PZ-003 Delayed Platform (Echo solo) | 2 | 7 | 2 | – | 2.7 | 1.6 |
| PZ-007 Crossed Wires (Echo+Freeze) | 3 | 9 | 3 | 1 | 4.1 | 2.5 |
| PZ-008 Night Round (Trace+Echo) | 4 | 6 | 2 | 1 | 3.7 | 2.2 |
| PZ-004 Substation (R+F+E) | 2 | 9 | 1 | 1 | 3.2 | 1.9 |
| PZ-005 Displaced Corridor (Trace+Echo+doorway) | 3 | 6 | 2 | 1 | 3.3 | 2.0 |
| **Puzzles** | **29** | **63** | **18** | **6** | **31.2** | **18.7** |
| Non-puzzle: Beats 01, 03, 06, 09, 10 (0.8 + 0.7 + 1.2 + 1.0 + 0.4) and 12 transitions (1.6) | | | | | 5.7 | 3.4 |
| **Main path** | | | | | **36.8** | **22.1** |

Arithmetic: 29 × 25 s + 63 × 12 s + 18 × 15 s + 6 × 20 s = 725 + 756 + 270 + 120 = 1871 s = 31.2 min. Rounding: the rows above are rounded to one decimal and sum to 36.8; the exact seconds give 36.9. 0.6× gives 22.1 either way.

**Bars (design values):** solo ≥ 1.5 ✔ (2.7, 1.9, 2.1, 2.7); main combo ≥ 3 ✔ (4.3, 3.1, 4.1, 3.7, 3.2, 3.3).
**Target ≥ 15 min on the floor: 22.1 ✔ (full) and 17.2 ✔ (Step 1 below).**

### 8.2 Plan in two steps (new rooms deferred)

| | Contents | Design | Floor | Rooms |
|---|---|---:|---:|---|
| **Step 1** (next playtest, target ≥ 15) | `TraceMemory`, progressive unlocks, 13 S1 commuters, SO-01, SO-02, PZ-006, deepened PZ-001/002/003/004, PZ-005 stage | **28.7** | **17.2** | **0 new** |
| Step 1b (optional) | + R11 and PZ-007 Crossed Wires | 32.8 | 19.7 | +1 |
| **Step 2** (second step, vertical-slice) | + R12 and PZ-008, SP-A, SP-B, SP-C with 3 fragments, remaining commuters, interactive NPCs, journal timeline | **45.3** (36.8 main + 8.5 optional) | **27.2** | +2 |

Step 1 = 36.8 − PZ-007 4.1 − PZ-008 3.7 − 2 transitions 0.3 = 28.7 design; floor 0.6× = 17.2.

### 8.3 Path to 30-45 min (the second step)

1. **Measure first.** TLF-048 telemetry on Step 1: per puzzle time-to-first-interaction, time-to-solve, wrong tries, resets, plus total time. Replace the d/e/w/r constants and the 0.6 factor with the measured ratios.
2. **If the ratio holds** (measured ≈ floor): Step 2 gives 27.2 min floor / ~45 design = the 30-45 band from the top.
3. **If the measured time is below the floor** (< 0.8× floor): add from a reserve, each ≥ 3 min and each with its own shortcut table: MP-D Cold Chain (3.5), MP-E Parked Cart (3.1), SP-D Trickle Charge (2.3, FF), 2-3 extra Trace-deduction micro-puzzles around NPC memories (1.5-2 each), a second tape or clock side puzzle.
4. **If it is above the design estimate** (players get stuck), cut optional SP-C first and tighten hints (Wren, Operator lines) before touching the main path.

### 8.4 New-behaviour ledger (for the implementation estimate)

| Behaviour | Used by | Size |
|---|---|---|
| `TraceMemory` (traceable, `_on_traced` shows lines/flag/journal) | all NPCs, clues | S |
| Ability unlock service + save field + HUD locked slots | the whole curve | M |
| `SelectorSwitch` + `CodeLock` (opens a `PoweredDoor`-style gate; lock-out) | SO-01 | S + S |
| `DependentRewindable` (`_can_use_ability` dependency) | PZ-001 conduit | S |
| Second `FireShutter` on the shared gear | PZ-002 | S (config) |
| Card reader + second barrier | PZ-003 | S |
| Breaker C trap (brown-out) | PZ-004 | S |
| `JunctionLever.requires_plate_id` + decoy lever | PZ-005 | S |
| `HistoryDial` (multi-entry rewindable; optional forward decay) + `TicketValidator` | PZ-006, SP-A, SP-B | M |
| `PlateLinkedGate` + optional FREEZE (ignores plate changes while frozen) | SO-02, PZ-007 | S |
| `SequencePlateLock` | PZ-008 | M |
| `ConditionalDialogue` (interactive NPCs) | I-1, I-2 | S-M |
| `advance()` on one object | SP-D (stretch) | S-M |
| New rooms R11/R12 (scene, graph, fingerprints, art kit reuse) | Step 1b / 2 | M each |
| Playthrough tests with progressive unlocks + real-input negative tests per puzzle | all | M |

None changes the `InteractionService`, `TemporalComponent` or `EchoService` contracts.

---

## 9. Summary for the user (plain language)

**What we found.** You finished Chapter 1 in under five minutes. The cause is simple: every puzzle in it is one machine with one trick, you could try all four powers at once, and the "reveal the past" power doesn't actually reveal anything yet. So there was nothing to find out, nothing to get wrong, and no reason to read.

**What we propose.** Keep the ten story beats and the way you liked the powers to combine, and make the chapter *deeper*, not just longer:

* **One power at a time.** You start with only the pocket watch's *reveal* power (Trace). The others come as story moments: a frozen courier makes the watch tick backwards (Rewind); a frozen technician holding a hatch open makes it stop (Freeze); a pedestal in the security crossing splits a second hand off (Echo). Each new power gets a short puzzle of its own first, then is combined with the others.
* **People frozen at 23:59.** The station is full of commuters who never left: a conductor with her whistle, a courier in mid-jump, a cleaner, a tourist stuck in a loop of doors. Tracing each one shows a short memory, and those memories are *clues*: which ticket, which line, in which order. Two of them (a half-frozen porter and a cable splicer) can be spoken to, but they never tell you who locked the station or who the voice on the phone is. That stays for the end of the chapter.
* **Every room has a story** of what happened there between 23:54 and 23:59, told through signs, props and the people. You carry one question the whole way ("who signed this off?") and the ending answers it.
* **Deeper puzzles.** Each puzzle now needs you to find information first, has believable wrong choices (with a small price, never a game-over), and some rooms let you do the sub-goals in any order. We add new puzzles (three new combinations in all, one of them in the first version) and give the old ones a harder second half.
* **Optional extras.** Three side puzzles, each with a memory fragment and something to read (Mira's second tape, the foreman's clock, an old switchboard).

**How long.** Built step by step from what each puzzle asks you to do (not from a feeling), a first-time player should need about **29 minutes** for the first version of this (about **17** even if they play as fast as you did), and about **45** (27 at your speed) once everything is in. The game will measure real play time so we can correct the numbers.

**What we need from you.**
1. Is starting with just the reveal power OK?
2. How many frozen people, and should they look like grey statues or normal people with a shimmer?
3. Are the hints about "the man from the lab" and "calls before the order" too strong a tease, or exactly right?
4. One extra small room or two? (Two give the most variety; the first version needs none.)
5. A second playtest of the first version before we build the rest?
