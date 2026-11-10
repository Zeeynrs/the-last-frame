# TLF-076b test hardening review (Flash, `aaf31fe`)

Opus, 2026-11-10. Read-only review of `origin/adityadaffa522/tlf-076b-test-hardening` at `aaf31fe`, whose parent is main `f21aef6` (TLF-076 merged). It follows up the P2/P3 items of `TLF-076_1e8a0ca_OPUS_REVIEW.md`.

**How it was checked:** in a renamed scratch `git archive` copy ("TLF Verify rev076b-aaf31fe"), imported headless. Flash's file was run, then a mutation run, then a save/load probe of the cup and the regression tests. No Flash file was changed and nothing was merged; the real save was not touched. The Lead runs the official validate. Evidence is in `aaf31fe/`.

## Verdict: **APPROVE**

All three test gaps of round 2 are closed. Re-entry, leak and clamp now go RED when their behaviour is stubbed (6 of 6 mutations). The `voice_recorder_cup.gd` change is safe for save/load. Game behaviour is unchanged apart from one new saved flag (see 2).

## 1. Mutation check (Flash's `test_ch01_mira_memory_side.gd`)

Each stub was applied to the scratch copy, the file was run, and the stubbed file was restored byte for byte. The restored files are identical to `aaf31fe`.

| Run | Stub | Result | Caught by |
|---|---|---|---|
| baseline | — | 6/0 | — |
| L1 | RoomRouter does not free the old room (orphan leak) | **RED** 5/1 | `test_mode_switch_leaves_no_leaks`: orphans 280 → 484 |
| R1 | Cup back on the floor on re-entry | **RED** 5/1 | `test_reentry_memory_flow`: cup (600,394) ≠ (540,384); cup targetable |
| R2 | `_is_cup_rewound()` always false (rewound state not restored) | **RED** 5/1 | `test_reentry_memory_flow`: "cup is not targetable for watch" |
| C1 | Left walk not clamped | **RED** 5/1 | `test_walk_bounds_and_clamping`: x −12 |
| C2 | Right walk not clamped | **RED** 5/1 | `test_walk_bounds_and_clamping`: x 1468 |
| C3 | Camera not clamped | **RED** 4/2 | test 1 (x 120 at the spawn) and test 4 (480 at x 16, 960 at x 1424) |
| restored | — | 6/0 | — |

Round 2's gaps M11 (leak) and M12 (re-entry cup) are now caught, and the clamp assertions can fail (x exactly 16 and 1424, camera 480 and 960). In the right-clamp case the test turns off `exit_marker.monitoring` so that Elias can reach 1424. That is a test-only change to the instance and does not alter the scene.

## 2. `voice_recorder_cup.gd`: `_is_cup_rewound()`

**The rule:** the "rewound" state used to be inferred from `position.x < 590`. It is now true when any one of these holds:
- `_is_rewound` is already set;
- the narrative flag `ch01.flag.mira_memory_cup_rewound` (bool, set in `_on_rewound`) is true;
- the position is exactly `BENCH_POSITION` (540, 384).

It is checked in `_ready()` and in `apply_state()`, which runs when RoomRouter imports the temporal history on re-entry or after a load.

**Probe (`aaf31fe/probe_076b_cup.gd.txt`), real input after setup:**
1. In the lounge, Use plays B06; Trace enters the memory.
2. Elias walks to the cup and Rewinds it: the cup moves to (540,384) and the flag becomes true.
3. Elias walks out, then into the lounge checkpoint: **an autosave on disk**.
4. The JSON holds the flag (`true`) and the cup's temporal history (`cursor 0`, entries `[(540,384),(600,394)]`).
5. A fresh Chapter01 continues from it, Elias walks back to the bench and enters the memory with a Trace.

| Continue from | Cup on re-entry | Rewind-targetable | Result |
|---|---|---|---|
| The real autosave | (540,384), `collision_layer` 0 | no; the bench is both watch and interact target | **correct** |
| An older save without the flag | (540,384), restored from temporal data, then the position fallback | no | **correct**, older saves stay safe |
| A synthetic save with the flag but the cup's temporal entry removed | (600,394) on the floor | no | inconsistent (cup on the floor, but not rewindable) |

The last row is not reachable in normal play: the router always saves the cup's temporal entry once the room has been visited. **P3:** the flag duplicates state the temporal history already holds, so two sources can disagree. The temporal data alone (cursor/entries, or the position fallback) would be a single source of truth. This does not block.

**About "no change to game behaviour":**
- **What runs the same:** the playthrough, Beat 06 and the side-view tests all still pass, and the cup acts exactly as in round 2 (probe).
- **The one new state:** a flag `ch01.flag.mira_memory_cup_rewound` in `narrative_flags` of new saves. It is a bool, so `Chapter01._on_flag_changed` ignores it as it does any other non-handled flag.
- **`mira_memory_silhouette.gd`:** drops the dead `target_marker_offset` export (my round-2 P3); the `TargetAnchor` node still sets the marker, and Flash's marker assertion passes.
- **HUD (P3):** `hud.gd`'s `elif "target_marker_offset" in target` branch is now unused; it can be removed later.
- **Spec:** `mira_memory.md` §2/§6 are updated to the no-save-inside rule (my round-2 4d).

## 3. Other test changes

- **Continue test:** now saves with the real checkpoint id `ch01.cp.waiting_lounge` (my round-2 P3).
- **Re-entry test:** makes a real first visit (Trace entry, Rewind tap, walk out) before the second.
- **Its direct call:** `cup_temporal.rewind()` is called directly for the `no_history` check. The call is read-only here, since it refuses, and the watch-target check that follows uses real input.

## Evidence (`aaf31fe/`)

- **`aaf31fe` runs:**

  | Test | Result |
  |---|---|
  | `test_ch01_mira_memory_side` | 6/0 |
  | `test_ch01_narrative_beats` | 13/0 |
  | `test_ch01_real_playthrough` | 1/0 |
  | `test_view_mode_side` | 8/0 |
  | cup probe | 1/0 |

  All have 0 SCRIPT ERROR and 0 ERROR (`probe_output.txt`).
- **Mutation run:** `mutations_076b.log`, with the runner in `mutate_076b.py.txt`.
- **Not done:** the full validate (the Lead).
