# TLF-076 technical re-review, round 2 (Flash, `1e8a0ca`)

Opus, 2026-11-10. Read-only re-review of `origin/adityadaffa522/tlf-076-mira-memory-side` at `1e8a0ca`, which builds on `a94aee3` (base main `fe4bfb1`). The round-1 report is `TLF-076_a94aee3_OPUS_REVIEW.md`; it is not changed. No Flash file was changed, nothing was merged, and the Lead runs the official validate.

**Method:**
- **Scratch copies:** renamed `git archive` copies (imported headless) of `1e8a0ca`, and of the **merge tree** of `1e8a0ca` with main `5399674`, tree `9da7e47`.
- **Test runs:** Flash's test file, the regression tests, and my round-1 probes adapted to the new bench flow.
- **Mutation run:** each fix stubbed in turn, then Flash's test file run against it.
- **Evidence:** in `1e8a0ca/`. The real save is not touched.

## Verdict: **APPROVE** (with P2/P3 follow-ups that do not block)

Every P1 is fixed and verified, and the P2 items are resolved. The mutation run (section 3) shows that Flash's tests go RED when any of the requested fixes is stubbed out, with two exceptions: the re-entry state (M12) and orphan leaks (M11). Those two, together with the clamp and camera edges, are the remaining test gaps. They are P2 test debt; the behaviour they would cover is correct by probe.

## 1. Round-1 findings

| Round 1 | Status at `1e8a0ca` | Evidence |
|---|---|---|
| **P1-1** autosave left inside the memory | **Fixed.** The CheckpointZone is removed from `side_mira_memory.tscn`. | **Entry, roaming and exit write no checkpoint.** Probe C/E: `checkpoints []`. **After the exit** the autosave is `ch01.waiting_lounge` / `ch01.cp.waiting_lounge` (probe L). **Mutation M3** (checkpoint put back) is RED in 2 tests. |
| **P1-2** test coverage | **Fixed for entry, abilities, exit, autosave and Continue.** **Partly fixed** for re-entry, leaks and clamp (section 3). | **Real input now:** the bench Trace, Use, the cup Rewind and the Mira Trace are taps; walking is real; the exit is walked into. **Continue:** reads slot 0 from disk. |
| **3** Trace before Beat 06 | **Same as main.** | **Probe A, identical lines on `fe4bfb1` and `1e8a0ca`:** `watch_used trace … ok=true`, no dialogue, `heard` false, journal 0. **Use (probe B):** identical on both trees: EL_B06_01, `heard` true, JRN_CH1_TWO_SILHOUETTES ×1; a second Use does nothing. **Mutation M4** (Trace plays B06 again) is RED. |
| **4** `DialogueTrigger._on_traced` | **Reverted.** | `git diff fe4bfb1 1e8a0ca -- scripts/ui/dialogue_trigger.gd`: empty. |
| **5** synchronous entry | **Deferred:** `room_router.enter_room.call_deferred(...)` in `TraceBench._enter_memory()`. | No ERROR or SCRIPT ERROR in any run. |
| `pocket_watch.gd` patch | **Reverted.** | `git diff fe4bfb1 1e8a0ca -- scripts/player/pocket_watch.gd`: empty. **After the deferred entry** `current_target` is the freed bench, the same as after any door change on main. **That is safe:** a freed object `== null` is true, so a watch press at the spawn gives `missing_target` with no error, and the HUD marker is hidden (probe R). |
| **6** B06 line carries over | **Fixed.** `_enter_memory()` calls `finish_sequence()` before the deferred entry. | Probe C: `dlg active false` in the memory. **Mutation M2** is RED. |
| **7** cup Rewind message | **Fixed:** no message. | Probe C: the feedback line is not shown after the Rewind. **Mutation M6** (round-1 message) is RED. |
| `chapter01._on_flag_changed` `not value` | **Still there** (`chapter01.gd:160`). | **Needed:** the flag is now a String, and main's `bool(value)` gives a SCRIPT ERROR (round 1, probe H). The only other code that walks all flags is the save serialization (`export_flags`). |
| P3 `unsupported` after the Mira Trace | **Fixed:** a second Trace is accepted and does nothing (`_traced_used`), with no refusal line. | Flash test 1; probe C/D: no refusal recorded. |
| P3 cup takes the interact focus | **Fixed.** After the Rewind the cup clears `collision_layer`/`collision_mask`, and `supports_ability()` returns false. | **Probe F:** the bench is the interact target at x 500–550 before and after the Rewind, and E there plays `ch01_b06_bench_look`. **Mutation M5** is RED. |
| P3 flag name | **Fixed:** `ch01.flag.mira_memory_return`, a String. | It survives the round trip (probe C: `(String)`); the exit marker handles String or StringName. |
| P3 dead code / Mira journal | **Fixed:** `_can_watch`/`_on_watch` are removed from `TraceBench` and Mira, and so is Mira's no-op journal call. | Code read. |
| P3 handoff numbers | **Partly fixed:** see 4c. | |

**Behaviour re-checked by probe on `1e8a0ca`, all real input after setup:**

| Area | Result |
|---|---|
| Entry | The second Trace (after Use) leads to the memory: side mode, Elias at (120, 394), `view_mode_changed [side]`. |
| Camera | Over the whole walk, x 480 → 960, y fixed at 270, 0 fractional frames. |
| Cup | (600, 394) → (540, 384). |
| Mira | Fragment collected once. |
| Exit | Lounge at (338, 152), iso, legacy bounds, ability kept, `[side, iso]`. |
| Second visit | The cup is still on the bench and can no longer be targeted; the fragment and journal are still single. |
| Continue | From the lounge autosave: lounge, iso. |

## 2. New change outside the scope: `scripts/ui/hud.gd` (7 lines) and TLF-079

**What it does:** `_update_target_highlight_position()` now places the watch marker with an offset. It uses a target's `TargetAnchor` child (its local position) when there is one, otherwise a `target_marker_offset` property, otherwise the old `(0, -28)`. This answers Sol's finding that the marker covered Mira (`TargetAnchor` at `(0, -56)`).

**Merge with TLF-079 (main `5399674`):**
- **No conflict:** `git merge-tree --write-tree origin/main 1e8a0ca` gives tree `9da7e47`, exit 0. Flash's lines sit inside `_update_target_highlight_position()`; TLF-079's readout block begins after that function and does not use the target marker. The merged function is correct; the readout code is untouched.
- **Merged tree `9da7e47`, scratch copy:**

  | Test | Result |
  |---|---|
  | `test_dial_readout` | 3/0, 0 ERROR |
  | `test_hud_feedback` | 6/0. Its 1 `ERROR:` line is the same negative-test line as on main. |
  | `test_ch01_mira_memory_side` | 6/0 |
  | `test_ui_layout_960` | 5/0 |

  All have 0 SCRIPT ERROR.

**Effect on other objects:** none. No other object has a `TargetAnchor` node or a `target_marker_offset` property, so every other target keeps `(0, -28)`, and `test_target_marker_camera_offset_conversion` (default offset) passes. **Mutation M10** (anchor ignored) is RED in Flash's Mira-marker assertion.

**P3:** Mira has **both** the `TargetAnchor` node and an exported `target_marker_offset` with the same value, and the HUD reads the node first, so the export is dead. Keep only one of them, preferably the node. The HUD also adds a world-space offset in canvas space; that is correct while the camera has no zoom, which is true for all rooms today.

## 3. Test quality: does each test fail when the code is stubbed?

Each mutation was applied to the `1e8a0ca` scratch copy, Flash's file run, and the file restored byte for byte. Baseline and after-restore runs: 6/0. Full log: `1e8a0ca/mutations_r2.log`.

| # | Stub | Result | Caught by |
|---|---|---|---|
| M1 | The bench Trace never enters the memory | **RED** 4/2 | test 1, test 2 (entry) |
| M2 | Entry does not close EL_B06_01 | **RED** 5/1 | test 1 "dialogue closed on entry" |
| M3 | CheckpointZone put back at the memory spawn | **RED** 4/2 | test 1 autosave room; test 3 restore |
| M4 | A Trace before Beat 06 plays it (round-1 behaviour) | **RED** 5/1 | test 1 "first trace does NOT open dialogue" |
| M5 | The cup keeps its focus after the Rewind | **RED** 5/1 | test 1 focus at x 540 |
| M6 | The cup Rewind shows the round-1 message | **RED** 5/1 | test 1 "no message on refusal line" |
| M7 | The Mira Trace collects nothing | **RED** 5/1 | test 1 fragment |
| M8 | Side walk not clamped | **RED** 5/1 | test 4 left clamp (x 6.0) |
| M9 | The exit marker does nothing | **RED** 4/2 | test 1, test 2 return |
| M10 | HUD skips `TargetAnchor` only | GREEN | Not a stub: the `target_marker_offset` fallback gives the same (0, −56); see section 2, P3. |
| M10b | HUD offset always (0, −28): anchor and export ignored | **RED** 5/1 | test 1 marker y 366 > 342 |
| M11 | The room swap leaks the old room (not freed, an orphan) | **GREEN, not caught** | (P2-b) |
| M12 | The cup is back on the floor on re-entry | **GREEN, not caught** | (P2-a) |
| M13 | Mira collects the fragment and journal on every Trace | GREEN | Equivalent mutation: `NarrativeState.collect_fragment` / `add_journal_entry` already ignore duplicates. Not a gap. |
| M14 | Camera not clamped (x follows Elias) | **RED** 5/1 | test 1 camera x 480 at the spawn |

**Summary:** 11 of the 13 real stubs go RED (M1–M9, M10b, M14). Two gaps remain: leaks (M11) and the re-entry cup (M12). M13 changes nothing, because duplicates are already ignored, and M10 was not a stub; M10b is the real one and goes RED. **Lead's question, whether some test always passes:** no test passes no matter what the code does. Two assertions in test 4 can never fail on their own (P2-c), and the left clamp assertion still catches M8. No SCRIPT ERROR in any mutated run, except M1. Its 1 SCRIPT ERROR most likely comes from test 1 carrying on in the lounge after the failed entry and reading side-room nodes that do not exist there.

**Findings:**
- **P2-a, re-entry test:** `test_reentry_memory_flow` builds a "second visit" only from narrative flags. It never makes a first visit, so the cup's state across visits (RoomRouter temporal cache, the `position.x < 590` rule in `VoiceRecorderCup._ready`/`apply_state`) is not checked; M12 stays GREEN. The behaviour is correct by probe D. **Fix:** in test 1, after the exit, Trace the bench again and assert the cup at (540, 384) and not targetable.
- **P2-b, leak test:** `test_mode_switch_leaves_no_leaks` now compares `Chapter01.get_child_count()` instead of round 1's `OBJECT_ORPHAN_NODE_COUNT`, so it does not see orphans; M11 (every unloaded room left as an orphan) stays GREEN. **Fix:** go back to `Performance.OBJECT_ORPHAN_NODE_COUNT`, as round 1 and `test_view_mode_side` do.
- **P2-c, clamp test:**
  - **Left:** `test_walk_bounds_and_clamping` asserts `x >= 16`, which also passes if Elias never moves.
  - **Right:** "right walk clamped at x <= 1424" is checked after the walk stops at 1350, so it can never fail.
  - **Camera:** no camera clamp at 960 is asserted; test 1 only checks x 480 at the spawn and a range at x 510.
- **P3:** `test_save_and_continue_from_disk` writes its lounge save with the checkpoint id `ch01.cp.lounge`, which does not exist (the real one is `ch01.cp.waiting_lounge`). The restore therefore uses no checkpoint, and the player is not placed by it. The room and mode assertions still hold.

## 4. Other remarks (P3)

- **(a) Magic number in the cup:** the "rewound" state is inferred from `position.x < 590.0`, which works for this scene. A saved flag (part of `capture_state`) or `temporal` cursor > 0 would not depend on a magic number.
- **(b) Silent bench overrides:** `TraceBench._can_use_ability` returns `""` for Trace, the same as the base default, so it can go. The second Trace now succeeds silently as well, which is consistent.
- **(c) Handoff round 2 still does not match the scene in places:**
  - **z values:** it gives bench 5, cup 5, Mira 6, trolley 5 and pillar 4; the instantiated values are 8, 9, 9, 8 and 6.
  - **Names:** `safe_anchor_start` is the node `Anchor` in the scene. `walk_min_x`/`walk_max_x` are not SideView fields; it uses `walk_margin` 16. "Look target `doc_side_station_bench`" is wrong: the bench is a DialogueTrigger with EL_B06_01.
  - **Test descriptions:** test 4 is said to cover the camera clamp, and test 6 is said to check for "zero orphaned nodes". Neither is true (see 3).
  - **Numbers that are right:** positions, bounds and the camera range.
- **(d) Spec section 2 (Lead):** "Save inside the memory scene stores the memory room id plus the return target" no longer applies, because nothing is saved inside the memory. The return flag is still set and works. The spec text should say so (option b of round-1 finding 1).

## Evidence (`1e8a0ca/`)

- **`1e8a0ca`:**

  | Test | Result |
  |---|---|
  | `test_ch01_mira_memory_side` | 6/0 |
  | `test_ch01_narrative_beats` | 13/0 |
  | `test_ch01_real_playthrough` | 1/0 |
  | `test_hud_feedback` | 6/0 (1 negative-test ERROR, as on main) |

  The others have 0 SCRIPT ERROR / 0 ERROR.
- **Merge tree `9da7e47`:** see section 2.
- **Probes:**
  - **Files:** `probe_r2_visit.gd.txt` (A–E), `probe_r2_focus.gd.txt` (F, H, L) and `probe_r2_freed.gd.txt` (R).
  - **Results:** 6/0 and 1/0, with output in `probe_output_r2.txt`.
- **Mutation run:** `mutate_r2.py.txt` and `mutations_r2.log`.
- **Not done:** the full validate (the Lead), and the visual review (Sol).
