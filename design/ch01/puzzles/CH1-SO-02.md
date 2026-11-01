# Puzzle Specification: CH1-SO-02 — Held Open (Freeze solo)

**Task:** TLF-047 phase 2 (Step 1) · **Concept:** `design/ch01/CH01_EXPANSION.md` §4a, with one documented delta (§8) · **Author:** design agent (Claude Code, Sonnet 5.5), standing in for Argon

## 1. Standard Puzzle Specification (`PUZZLE_DESIGN.md` §2)

- **Puzzle ID:** `CH1-SO-02`
- **Name:** Held Open
- **Chapter / Room:** Chapter 1 (*The Forgotten Station*) / Maintenance Bay (`ch01.maintenance_bay`, Beat 04, sub-beats 04a-04b)
- **Narrative purpose:** Teach `Freeze` as "keep a mechanism in the state it is in, even after I step away", through the technician who died holding a hatch open (he is frozen, not dead; the lore stays ambiguous). The watch's hand stops dead when Elias Traces him.
- **Player objective:** Get past the service hatch that closes the entry strip of the bay: it only opens while someone stands on its plate.
- **Required abilities:** `Freeze` (unlocked in this puzzle by Tracing the technician), `Trace` for information. Solo puzzle: no other acting ability is required (and none exists yet that could replace it, see §6).
- **Required objects:** `n11_hatch_tech` (`TraceMemory`), `hatch_residue` (`TraceMemory`, scene memory on the plate), `hatch_plate_01`, `bell_plate_01` (`TriggerZone`), `hatch_01` (`FreezableGate` = `PlateLinkedGate` + `TemporalComponent`, FREEZE), `hatch_threshold` (`TriggerZone`), `doc_hatch_chart` (readable), `exit_trigger_hatch` (`PuzzleCompletionZone`), `safe_anchor_entry` (`Marker2D`, new).
- **Initial room state:** Elias enters through `door_entry_west`. A new full-width bulkhead splits the room at tile `x = 3`; its only opening is `hatch_01` (closed). `hatch_plate_01` and `bell_plate_01` are on the entry side. Freeze is **not yet unlocked** (only Trace and Rewind).
- **Rules the player must discover:**
  1. Tracing the technician unlocks `Freeze` and says "hold it open".
  2. The hatch opens while a plate is occupied and closes the moment the plate is vacated (the Security Crossing gate works the same way, later).
  3. `Freeze` on the hatch keeps it in its current state, open **or closed**, until it is toggled again.
  4. Only the brass plate A works the hatch; the green plate B only rings a bell.
- **Step-by-step intended solution:**
  1. `Trace` the technician `n11_hatch_tech` from `(288,112)`: Freeze unlocks; "Hold it open!".
  2. Read `doc_hatch_chart` (plate A opens Hatch 4, plate B rings a bell) and/or `Trace` the plate residue `hatch_residue` from the brass plate (the technician's weight on plate A).
  3. Step on `hatch_plate_01`: the hatch opens. Stepping on `bell_plate_01` only rings a bell.
  4. With `Freeze` selected, activate it on `hatch_01` (66 px from the plate): the hatch is frozen open.
  5. Step off the plate and walk through the hatch into `exit_trigger_hatch`: `CH1-SO-02` is `SOLVED` and the hatch latches open (ADR-016).
- **Alternative valid solutions:** Freezing the hatch before stepping on the plate freezes it **closed**; the player unfreezes (second `Freeze`), then follows the main solution. No other solution exists (§6).
- **Failure states:**
  * `use` on a closed hatch: `&"locked"` ("The hatch only opens under weight.").
  * Stepping off the plate before freezing: the hatch closes on the same tick (no harm); try again.
  * `Freeze` on a closed, unoccupied hatch: it is frozen closed (`gate_state = closed`), plate changes are ignored; the player toggles `Freeze` again.
  * Unfreezing while the player is standing in `hatch_threshold` with the plate empty: the hatch closes and the player is moved to `safe_anchor_west` (east side) first (ADR-016 clutch).
- **Reset behavior:** nothing here can be broken. A second `Freeze` always undoes a freeze; `reset_anchor_01` (east of the bulkhead, existing) is not needed. After `SOLVED` the hatch stays open and `Freeze` on it returns `&"already_open"`.
- **Hint 1 (nudge):** *"The technician was holding something open. What was he doing with his hands, and where was he standing?"*
- **Hint 2 (rule reminder):** *"The hatch opens only under weight. Freeze keeps a mechanism the way it is, so it can stay open without you."*
- **Hint 3 (next action):** *"Stand on the brass plate to open the hatch, switch to Freeze and activate it on the hatch, then step off and walk through."*
- **Success feedback:** Visual: the hatch lifts, a brass lock-ring appears on it (shape cue, not only colour) and stays after the plate is vacated. Audio: a hydraulic hiss and a held chime. Journal: `JRN_SO002_SOLVED` (fact).
- **Narrative reward:** access to the shutter area (`CH1-PZ-002`); the Freeze unlock (Elias: "It can hold things still.").
- **Accessibility considerations:** no timers; plate states and the frozen state have shape glyphs (open chevron `[>>]`, lock ring `[o]`, bell icon); both plates carry a letter (`A`, `B`) in addition to their colour.
- **Estimate (model §1.3):** 3 d (75 s: technician, chart, residue) + 3 e (36 s) + 1 w (15 s) = 126 s = **2.1 min design**, 1.3 min floor. ✔ ≥ 1.5.
- **Dependent steps (≥ 3):** Trace the technician (unlock) → identify the right plate → stand on it → Freeze the hatch → step off and walk through.

## 2. Object & Temporal Schema (`ADR-005`, `ADR-007`)

Room `14 × 10`. Tile `(x,y)` → px `(320+(x−y)·16, 64+(x+y)·8)`. Existing and unchanged: `fire_shutter (8,4) (384,160)`, `counterweight_gear (5,1) (384,112)`, `reset_anchor_01 (4,6) (288,144)`, `doc_tech_log (7,9) (288,192)`, `safe_anchor_west (5,4) (336,136)`, `checkpoint (1,5) (256,112)`, `door_entry_west (0,5) (240,104)`.

| `object_id` (`ch01.maintenance_bay.…`) | Class | Caps | State fields (tick-0) | `initial_history` | Tile / px |
|---|---|---|---|---|---|
| `n11_hatch_tech` | `TraceMemory` | trace | — | — | `(2,3)` `(304,104)` |
| `hatch_residue` | `TraceMemory` (scene memory, `MEM_HATCH_RESIDUE_*`) | trace | — | — | `(2,6)` `(256,128)` |
| `hatch_plate_01` | `TriggerZone` (accepts echoes) | none | `occupants` | — | `(2,6)` `(256,128)` |
| `bell_plate_01` | `TriggerZone` | none | `occupants`; on enter: feedback `SO002_FB_BELL` | — | `(1,8)` `(208,136)` |
| `hatch_01` | `FreezableGate` (`plate_id = hatch_plate_01`, `threshold_zone_id = hatch_threshold`, `safe_anchor_id = safe_anchor_west`) + `Blocker` | **FREEZE** | `gate_state: StringName = &"closed"`, `passage_blocked: bool = true` | `[]` | `(3,3)` `(320,112)` |
| `hatch_threshold` | `TriggerZone` (player only) | none | — | — | `(3,3)` `(320,112)` |
| `exit_trigger_hatch` | `PuzzleCompletionZone` (`puzzle_id = CH1-SO-02`) | none | — | — | `(4,3)` `(336,120)` |
| `doc_hatch_chart` | `ReadableDocument` (`doc_hatch_chart.tres`) | use | — | — | `(2,7)` `(240,136)` |
| `safe_anchor_entry` | `Marker2D` (new) | none | — | — | `(1,4)` `(272,104)` |

`hatch_01` temporal schema: `capabilities = FREEZE`, `state_fields = ["gate_state", "passage_blocked"]`, `schema_version = 1`, `initial_history = []`. `is_frozen` is owned by the component (ADR-007 am. 2), never in the snapshot.

**New colliders (own fingerprint entries, existing collision untouched):** `Bulkhead` (`StaticBody2D`, layer 1) with two `SegmentShape2D`: `(368,88) → (328,108)` and `(312,116) → (224,160)` (the tile line `x = 3` from the north wall to the south wall; the 1-tile gap between `(328,108)` and `(312,116)` is the hatch aperture centred on `(320,112)`); `hatch_01/Blocker` fills the gap when closed (24 × 12). Statue footprint for `n11_hatch_tech` (12 × 8).

**Checkpoint delta (spawn-bypass guard, ADR-010):** the room's `checkpoint` (`ch01.cp.maintenance_bay`) uses `spawn_anchor = safe_anchor_entry` instead of `safe_anchor_west`, so Continue / respawn never places the player east of the bulkhead while `CH1-SO-02` is unsolved. `safe_anchor_west` stays as the ADR-016 relocation anchor.

**New behaviours (ledger):** `FreezableGate` (S: `PlateLinkedGate` plus a `TemporalComponent`; while `is_frozen()` it ignores `_on_plate_changed`; it implements `capture_state/apply_state`; `_set_open(false)` with the player in `threshold_zone_id` relocates them to `safe_anchor_id` first; it is a **default-off** option, `PlateLinkedGate` in the Security Crossing is unchanged), `TraceMemory`, `safe_anchor_entry` + the checkpoint's spawn anchor. No contract change.

## 3. Interaction Contract Table (`ADR-006`)

| `target_id` | `interaction_id` | Condition | `reason` | Feedback |
|---|---|---|---|---|
| `hatch_01` | `use` | never while closed; open: `&"already_open"` | `&"locked"` / `&"already_open"`; frozen: `&"frozen"` | `SO002_FB_HATCH_WEIGHT`, `SO002_FB_HATCH_HELD` |
| `hatch_01` | `freeze` | `Freeze` unlocked; not `SOLVED` | `&"already_open"` once `SOLVED` | toggles `is_frozen` |
| `hatch_01` | `rewind` / `fast_forward` | never | `&"unsupported"` | `UI_FB_UNSUPPORTED` |
| `hatch_01` | `trace` | never (the technician and the residue carry the memory) | `&"unsupported"` | `UI_FB_UNSUPPORTED` |
| `n11_hatch_tech`, `hatch_residue` | `trace` | always | — | memory lines |
| `hatch_plate_01` / `bell_plate_01` | `trigger_enter/exit` | player or echo | — | hatch opens/closes; bell feedback |
| `doc_hatch_chart` | `use` | always | — | opens the document |
| `exit_trigger_hatch` | `trigger_enter` | player only | — | marks `CH1-SO-02` `SOLVED` |

## 4. Soft-lock and reachable-bad-state analysis

| State | Issue | Recovery |
|---|---|---|
| Hatch frozen closed | cannot open | `Freeze` again (toggle) |
| Hatch frozen open, player on the entry side | none | walk through |
| Freeze, then toggle while standing in the aperture with the plate empty | would trap the player in the Blocker | clutch: relocated to `safe_anchor_west` |
| Continue / respawn | would spawn east of the bulkhead | checkpoint spawns at `safe_anchor_entry` (west) |
| Player reaches the east side without solving (impossible) | n/a | §6 |
| Reset console | `reset_anchor_01` is east of the bulkhead | not needed; `Freeze` toggles |
| Echo | not unlocked | n/a |

## 5. ADR-015 reach and targeting (placement checker `design/ch01/expansion/step1_placement_check.py`, 12 of 12 checks in the room OK)

* Freeze (96 px) from the brass plate `(256,128)`: `hatch_01` 66.0 px; `counterweight_gear` 129 px (out of range), so the hatch is the only Freeze target.
* Trace (96 px): from the plate `hatch_residue` 0.0 px (nearest, the technician is 53.7 px away); from `(288,112)` the technician is nearest (17.9 px; the residue is 35.8 px).
* `use` (36 px): chart from `(224,128)` 17.9 px; the hatch is 96 px+ away from that spot, so the chart is not shadowed.
* The existing `reset_anchor_01` from `(272,152)` is still the nearest use target (17.9 px).

## 6. Shortcut analysis (RISK-018)

| Shortcut | Excluded by | Negative test (real input) |
|---|---|---|
| Walk around the bulkhead | the two segments run wall to wall (flood-fill) | `TEST-SO02-05`: flood-fill from `safe_anchor_entry` with the hatch closed reaches no tile east of `x = 3` |
| Pass without Freeze | the hatch closes on the tick the plate is vacated; the aperture is 2 tiles from the plate | `TEST-SO02-04`: occupy the plate, open the hatch, move off for 60 ticks, assert closed and the player still west |
| Use `Rewind`/`Echo` instead | `hatch_01` has no REWIND; Echo is not unlocked (availability) and, once unlocked, the room is already solved | `TEST-SO02-06`: `rewind` returns `&"unsupported"` |
| Spawn past the bulkhead | checkpoint spawns at `safe_anchor_entry` | `TEST-SO02-08` |
| Freeze it from the bell plate or from the aperture side | bell plate is 126 px from the hatch (out of range); the aperture side is already past it | `TEST-SO02-07`: from `(208,136)` no Freeze target is in range |
| Timers | there are none, so the accessibility assist cannot weaken the puzzle | n/a |

## 7. Acceptance tests (`GIVEN / WHEN / THEN`)

* **TEST-SO02-01 — Freeze unlocks from the technician.** GIVEN Trace and Rewind unlocked; WHEN `n11_hatch_tech` is Traced; THEN Freeze is unlocked (`AbilityUnlocks`) and `ch01.npc.n11.traced` is true.
* **TEST-SO02-02 — the plate opens the hatch.** GIVEN the hatch closed; WHEN `hatch_plate_01` is entered by the player; THEN `hatch_01.passage_blocked == false`; WHEN exited; THEN `passage_blocked == true` on the same tick.
* **TEST-SO02-03 — Freeze holds the hatch open.** GIVEN the player on the plate, hatch open; WHEN `request(player, hatch_01, freeze)`; THEN `ok == true`, `is_frozen()`; WHEN the player leaves the plate; THEN `passage_blocked == false` after 600 ticks.
* **TEST-SO02-04 — without Freeze the player cannot pass (real input).** GIVEN no Freeze use; WHEN the player stands on the plate then walks towards `exit_trigger_hatch` for 300 ticks; THEN `exit_trigger_hatch` is never entered and `CH1-SO-02` is unsolved.
* **TEST-SO02-05 — bulkhead is sealed.** (flood-fill as §6).
* **TEST-SO02-06 — unsupported abilities.** `rewind`, `fast_forward`, `trace` on `hatch_01` return `&"unsupported"`.
* **TEST-SO02-07 — bell plate is a decoy.** GIVEN the player enters `bell_plate_01`; THEN the hatch stays closed and `SO002_FB_BELL` is shown; AND from `(208,136)` `choose_watch_target(&"freeze")` returns null.
* **TEST-SO02-08 — checkpoint spawn.** GIVEN `CH1-SO-02` unsolved and a checkpoint autosave; WHEN the save is applied; THEN the player appears at `safe_anchor_entry` (west of `x = 3`).
* **TEST-SO02-09 — freeze closed is recoverable.** GIVEN the hatch closed and unoccupied; WHEN `freeze` is used twice; THEN `is_frozen()` is false again and the plate works.
* **TEST-SO02-10 — clutch.** GIVEN the hatch frozen open and the player in `hatch_threshold` with the plate empty; WHEN `freeze` is used again; THEN the player is at `safe_anchor_west` and the hatch is closed.
* **TEST-SO02-11 — latch.** GIVEN `SOLVED`; WHEN saved, loaded, the plate vacated and `freeze` toggled; THEN the hatch is open (`already_open` for `freeze`).
* **TEST-SO02-12 — existing PZ-002 and Security Crossing gate unchanged.** GIVEN the object defaults; THEN `TEST-PZ002-*` and `TEST-PZ003-*` object tests still pass (the freezable option is default-off).

## 8. Delta from the approved concept

`CH01_EXPANSION.md` §4a describes **two** hatches in series. The Maintenance Bay's entry strip (`x = 1…4` west of `safe_anchor_west`, with `reset_anchor_01` at `(4,6)`) has room for **one** bulkhead without moving frozen objects. Depth is kept by the third discovery (residue Trace), the decoy plate and the freeze-closed recovery; the estimate stays 2.1 min (§1). A second hatch can be added in Step 2 east of the shutter if the playtest asks for more.
