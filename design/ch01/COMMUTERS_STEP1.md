# Frozen commuters — Step 1 (13) (TLF-047 phase 2)

**Source:** `CH01_EXPANSION.md` §4b (approved, `e038e45`); user decision: desaturated grey "statues" with a shimmer, 13 in Step 1. **Class:** `TraceMemory` (`TRACE_MEMORY.md`). **Text:** `narrative/ch01/CH01_TEXT.md` (keys below; do not re-type the lines here, the table only names the keys).
**Placement rules:** P1 a `use`-object's stand spot is nearer to it than to any statue; P2 a statue is the nearest Trace candidate from its listed stand spot; statues keep ≥ 2 tiles (35.8 px) from each other. Distances below are produced by the placement checker (`design/ch01/expansion/step1_placement_check.py`, output in `step1_placement_check.txt`).
**Collision:** every statue has a **12 × 8 px** footprint (`StaticBody2D`, layer 1) and is listed in the new-collider fingerprint (ADR-019). No statue stands in a doorway, on a plate, on a safe anchor, or on the straight line between a door and its puzzle.
**Coordinates:** tile `(x, y)` → px `(320 + (x − y)·16, 64 + (x + y)·8)`.

| ID | Object ID (`ch01.<room>.…`) | Room | Tile / px | Stand spot (px) → distance | Pose (art) | Memory keys (`MEM_*_1/_2`, `SPK_MEM_*`, `JRN_MEM_*`) | Time | Role | Unlocks / feeds |
|---|---|---|---|---|---|---|---|---|---|
| N-01 | `arrival_platform.n01_conductor` | R1 | `(10,8)` `(352,208)` | `(368,200)` → 17.9 | woman in uniform, thumb on the close button, whistle in her teeth | `N01` | 23:57 | LINE + CAR (latest) | CH1-SO-01 |
| N-02 | `arrival_platform.n02_student` | R1 | `(5,8)` `(272,168)` | `(288,160)` → 17.9 | student, one foot over the yellow line, phone in hand | `N02` | 23:41 | decoy (older) | CH1-SO-01 |
| N-03 | `arrival_platform.n03_old_man` | R1 | `(4,2)` `(352,112)` | `(336,120)` → 17.9 | old man seated on the bench, paper bag on his knee | `N03` | 23:30 | decoy (oldest) | CH1-SO-01 |
| N-04 | `arrival_platform.n04_cleaner` | R1 | `(12,7)` `(400,216)` | `(416,208)` → 17.9 | night cleaner, trolley half-turned | `N04` | 23:58 | PLATFORM (latest) | CH1-SO-01 |
| N-05 | `concourse_west.n05_courier` | R2 | `(1,6)` `(240,120)` | entry anchor `(256,112)` → 17.9; `(248,116)` → 8.9 | bike courier in the run-up, one foot leaving the floor, bag swinging | `N05` | 23:59 | **Rewind unlock**, conduit clue | CH1-PZ-001 |
| N-06 | `concourse_west.n06_red_coat` | R2 | `(13,6)` `(432,216)` | `(448,224)` → 17.9 | woman in a red coat, card in hand | `N06` | 23:41 | Harbour, P1 (decoy) | CH1-PZ-006 |
| N-07 | `concourse_west.n07_briefcase` | R2 | `(13,8)` `(400,232)` | `(416,240)` → 17.9 | man with a briefcase, checking his wrist | `N07` | 23:49 | Central, P2 (decoy) | CH1-PZ-006 |
| N-08 | `concourse_west.n08_father` | R2 | `(13,10)` `(368,248)` | `(384,256)` → 17.9 | father, sleeping child on his shoulder | `N08` | 23:53 | Orchard Gate, P3 (right line, too early) | CH1-PZ-006 |
| N-09 | `concourse_west.n09_teen` | R2 | `(11,9)` `(352,224)` | `(336,232)` → 17.9 | teenager with headphones, thumb on the stamp | `N09` | 23:55 | **target ticket** Orchard Gate, P1, 23:55 | CH1-PZ-006 |
| N-11 | `maintenance_bay.n11_hatch_tech` | R3 | `(2,3)` `(304,104)` | `(288,112)` → 17.9 (the residue on the brass plate is a separate scene memory) | technician, both hands on a hatch crank, leaning back | `N11` | 23:58 | **Freeze unlock**, hatch clue | CH1-SO-02 |
| N-13 | `security_crossing.n13_guard` | R4 | `(4,3)` `(336,120)` | `(320,128)` → 17.9 | guard at the desk, one hand on the gate lever | `N13` | 23:57 | south plate = gate | CH1-PZ-003 |
| N-20 | `signal_control.n20_engineer` | R6 | `(6,7)` `(304,168)` | `(288,176)` → 17.9 | engineer, hand on a breaker handle | `N20` | 23:56 | "don't touch C" | CH1-PZ-004 |
| N-21 | `upper_vestibule.n21_tourist` | R7 | `(5,4)` `(336,136)` | `(320,144)` → 17.9 | tourist, map open, turning towards the arches | `N21` | 23:55 | loop clue | CH1-PZ-005 |

Journal: each Trace adds `JRN_MEM_<ID>` as an **observation** (rule R2). The scene memory `MEM_ANCHOR_TURNSTILE_1/_2` (speaker `SPK_MEMORY`) belongs to `ch01.concourse_west.turnstile_trace_anchor`, uses the existing journal key `JRN_CH1_TURNSTILE_TRACE`, and is not a commuter.

## Deliberate wording rules (so no memory pre-empts Beat 09)

* No memory says who locked the station, who the Operator is, or what ELYSIUM did. They say what the person was doing and what they believed.
* The medic's "the man from the lab" (N-19) and the porter / splicer lines are **not** in Step 1 (decided by the user: soften or cut the medic line; the rest is Step 2).
* Time stamps are real puzzle data for N-01…N-04 and N-06…N-09 (the latest statement wins; the ticket must be bought after 23:54). Changing a time stamp in the text file changes the puzzle: the tests below pin them.

## Tests (given / when / then)

* **TEST-CM-01 — every Step 1 commuter exists once, with a memory.** GIVEN the 6 room scenes (R1, R2, R3, R4, R6, R7); WHEN `get_nodes_in_group(&"interactable")` is filtered by `TraceMemory`; THEN exactly the 13 object IDs above (plus the turnstile anchor) are found, each with 1-2 `lines` whose text keys exist in `ch01_text.csv`, a `flag_id` and a `journal_key`.
* **TEST-CM-02 — Trace picks the intended statue.** GIVEN each stand spot above, Trace selected; THEN `choose_watch_target` returns the listed statue at the listed distance (± 0.1 px).
* **TEST-CM-03 — SO-01 data.** GIVEN `MEM_N01_1` … `MEM_N04_2`; THEN, per field, the latest time stamp names the answer: LINE `HOLLOW QUAY` (23:57, N-01), PLATFORM `3` (23:58, N-04), CAR `REAR` (23:57, N-01); N-02 (23:41) and N-03 (23:30) name different values for all three fields.
* **TEST-CM-04 — PZ-006 data.** GIVEN `MEM_N06_1` … `MEM_N09_2`; THEN exactly one ticket has line `ORCHARD GATE` **and** a time after 23:54: N-09 (platform 1, 23:55); N-08 has the right line but 23:53; N-06/N-07 have other lines.
* **TEST-CM-05 — no statue blocks a route.** GIVEN each room's navigation from the entry to every Step 1 object and the exit; THEN a path exists with all statue colliders enabled (flood-fill on real colliders).
* **TEST-CM-06 — text rules.** As `TEST-TM-09`.
