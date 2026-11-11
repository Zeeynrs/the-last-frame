# TLF-085 round 2: Opus technical re-review of `1d01443`

**Target:** Flash `adityadaffa522/tlf-085-maintenance-v2` at `1d01443`. It merges main `f7649fd` and `origin/lead/tlf-085-r2` `b191fe9`; the Lead's round 2 decisions are layout §7.
**Round 1:** `TLF-085_71bb9ea_OPUS_REVIEW.md` (`895f012`, CHANGES REQUIRED).
**Method:**
- Scratch copy: renamed `git archive` ("TLF Verify rev085-1d01443").
- Godot: one call at a time, each capped at 120 s, no `--eval`. The real save was not touched.
- Evidence: `docs/reviews/TLF-085/1d01443/`.

## Verdict: APPROVE, with one required one-line fix (P2-1) before merge

- **Round 1:** the P1 and every P2/P3 I raised are closed or deferred by the Lead (§1).
- **Lead's checks:** (a) to (e) pass (§2), except (b). In (b), a stale archway sprite draws a second door frame. The fix is one line, and I verified it in scratch: one frame, art tests green. It needs no new review round.

## 1. Round 1 findings

| Round 1 | Status at `1d01443` | Evidence |
|---|---|---|
| **P1** checkpoint on the spawn (2,5) | **Closed.** `checkpoint` (320,144) = (5,5); `spawn_anchor_id` safe_anchor_entry (336,136); ROOM_GRAPH row (5,5) + safe_anchor_entry; the cluster H test asserts `checkpoint` and `safe_anchor_entry` | mutations MK1/MK2 RED (§2e) |
| P2 floor grating / conduit not moved | **Closed.** Decoded TileMap: 416 cells; source 3 at x 15..17, y 0..9 (30); source 5 at (6..10,4) (5); 381 source 4. `ConduitPresenter.conduit_coords` (6..10,4) | layout §7.5 |
| P2 gear behind the shutter, Elias half hidden at the gear spot | **Elias closed, gear deferred.** With the W-face shutter pair, Elias is fully visible at the gear stand spot (496,184) and in the pocket (`gear_spot_x3.png`, `pocket_x3.png`). The closed fire shutter's top still covers the gear's lower right; the Lead leaves this to TLF-085b (§7.6) | crops of Flash's shots |
| P2 NE 1-tile N-wall gap | **Closed.** Width 26, `WallN_12` (720,264), 13 N modules; builder dry run 0 changed lines; Python 22 OK | — |
| P2 stand-spot test teleports to spot + (2,2) | **Closed.** It now walks with real input (`walk_to` + `steer`) from an anchor and asserts ≤ 2.6 px. A blocked spot goes RED (MS1, MS2). See P3-3 for two weak rows | §2c |
| P2 handoff numbers | **Closed.** I spot-checked 14 rows of the placement table against the scene and the tile formula; all match (door E (26,4) = (672,304), Spawn (24,4) = (640,288), checkpoint, anchors, shutters, plaque). Bounds `Rect2(48,0,704,416)`, centre (400,208) | — |
| P3 unlock-guards spot (352,128) | **Closed.** (352,144) | — |
| P3 "follow framing" comment | **Closed.** ROOM_GRAPH "Fixed 960×540"; graph test comment fixed | — |
| P3 `step1_negatives` near the cap | **Open.** 106 s; the bay file now takes 91 s too (P3-4) | `test_files.log` |
| P3 visible vs real aperture | **Unchanged, convention.** West door triggers for start rows y 3.75..6.0 (about 2.5 tiles) against a 2-tile arch; holds left, up, down and left+down stay; left+up exits after 14 ticks, as in round 1 | `probe_085b.log` A, B |

## 2. The Lead's checks

### (a) Shared code: no effect on other rooms

- **`scripts/rooms/depth_sort.gd`:** adds `"ch01_prop_inner_shutter_"` to `UPRIGHT_ASSETS`.
  - **Who uses that art:** only the two `FireShutterPresenter` sprites in `maintenance_bay.tscn`. It was unused before; `step1_props.py` and the mockups only generate it.
  - **Readers of the prefix:** `DepthSort` and `ShadeBaker` (casters).
  - **Lighting consequence:** both shutters become sprite casters, which only matters for the Maintenance Bay lighting (next task).
  - **The sort-order test** keeps its own copy of the list and has the same prefix added.
- **`scripts/chapters/ch01/visuals/fire_shutter_presenter.gd`:** the default textures change to the W-face pair, and the offset goes from (−32,−56) to (−16,−56) for a 32-px sprite. `git grep` finds the script only in `maintenance_bay.tscn`.
- **Run evidence**, one call each, all with 0 SCRIPT ERROR (`test_files.log`):

| File | Result |
|---|---|
| `test_ch01_sort_order.gd` (every room's manifest) | 3/0 |
| `test_ch01_art_integration.gd` | 6/0 |
| `test_ch01_concourse_west_v2.gd` | 12/0 |
| `test_ch01_playthrough.gd` | 19/0 |
| `test_ch01_real_playthrough.gd` | 1/0 |
| `test_shadows.gd` (main's) | 14/0 |
| `test_lighting_pass.gd` | 15/0 |

- **Manifest and collision baseline:** the decoded collision baseline differs from main and from `71bb9ea` only in `maintenance_bay`. The render manifest differs only in its `maintenance_bay` room, two positions since `71bb9ea` (door_exit_east, checkpoint).
- **Files:** no BOM, CRLF or NUL in the 38 changed files.

### (b) Two east door frames: a stale archway (**P2-1**)

`maintenance_bay.tscn` has two archway sprites per door:
- the builder's `YSort_Walls/Archway_door_*`;
- the legacy root-level `ArchwayWest` / `ArchwayEast` (centred, offset (0,−24)).

Both draw the same pixels when they share a position. Round 1 moved both east archways to (656,296). Round 2 moved the door and `Archway_door_exit_east` to (672,304) but **left `ArchwayEast` at (656,296)**, one tile short. It draws the second frame at screen (720..752, 302..366) in every shot that shows the east end.

- **Fix (one line):** `ArchwayEast` position → `Vector2(672, 304)`, which matches how Concourse West and Security Crossing pair theirs.
- **Verified in scratch:**
  - Flash's `tools/capture_maintenance_bay.gd`, re-shot, shows one frame (`east_frames_x3_before_after.png`: left `1d01443`, right fixed).
  - The pixels that change are only the stale frame's: bbox (720,302)-(752,366), 748 px.
  - `test_ch01_sort_order` 3/0 and `test_ch01_art_integration` 6/0 still pass; the maintenance manifest does not list `ArchwayEast`.
  - The scene was then restored byte-identical.
- **Alternative:** deleting both legacy nodes works too. It is cleaner, but the Concourse and Security copies should go in the same cleanup (P3-1).

### (c) Stand-spot test walks and goes RED when a spot is blocked

`test_every_stand_spot_reachable_within_2_6_px`:
- **Walking:** it places Elias at each row's anchor and then walks with move actions only (`walk_to(..., 240, true)` followed by up to 8 `steer` frames). The 2.6 px assertion catches a blocked walk because `blocked_ok` suppresses only `walk_to`'s own failure.
- **MS1:** a 10 px post on the casting spot (480,208) turns the three casting rows RED (stopped at 18.13 px).
- **MS2:** a post on the pocket spot (544,240) turns the two pocket rows RED (16.75 px), and the real-input lifecycle test too.
- **My probe:** it walks every spec spot from an anchor at least one tile away, with real input and the real capsule (`probe_085b.log` C).
  - **Reached within 2.6 px with the right target:** 11 of 13 rows, including the pocket from an anchor 42 px away.
  - **The other two, as in round 1:**
    - PZ-002 (400,168)+BC from the pocket side is reached at 9.1 px against the closed shutter, but still targets `fire_shutter`.
    - The plaque is reached at 3.89 px on the x = 19 line.

### (d) Checkpoint (5,5) and cluster H

- **`test_checkpoint_saveload_restores_player_and_camera`:** saves at the zone (320,144) after walking in from (272,120), 54 px away. It then moves Elias to (512,176) and checks that Continue restores him at safe_anchor_entry (336,136), within 2 px.
- **`test_rigid_cluster_shifts_and_relative_distances`:** asserts `checkpoint` and `safe_anchor_entry` among the 10 cluster H nodes, at their exact positions with a delta of (64,32).
- **Mutations:**
  - **MK2** (checkpoint back on (272,120)) is RED in both tests.
  - **MK1** (no spawn anchor) is RED: restored at (320,144).

### (e) My own mutations (`mutate_085b.py.txt`, `mutation_085b.log`): 14 of 14 RED in Flash's bay file

Baseline: 15/0, 0 SCRIPT ERROR, 91 s (`bay_baseline.log`).

| Mutation | RED test |
|---|---|
| MV1 / MV2: bulkhead north / south segment disabled | bulkhead sweep (crosses to x 8.21 / 8.11) |
| MV3 / MV4: shutter divider north / south disabled | shutter sweep (17.21 / 17.11) |
| MV5 / MV6: inner divider north / south disabled | inner sweep (20.21 / 20.11) |
| MD1: west door trigger radius 6 → 40 | door sweep (up / down holds leave), checkpoint test, stand spots |
| MD2: arrival Spawn 1 tile from the door | door sweep (spawn position, left / up / down holds leave) |
| MC3: room bounds ignore `metadata/room_shape` | camera bounds and centre |
| MK1: checkpoint spawn anchor removed | checkpoint test |
| MK2: checkpoint back on (2,5) | checkpoint test, cluster H |
| MR1: counterweight gear +16 px | cluster BC (position, delta, internal distance) |
| MS1 / MS2: casting / pocket spot blocked | stand spots (and the lifecycle for MS2) |

### Doors, real playthrough, other files

- **Probe D:** the east door (26,4) leads to Security Crossing's `door_entry_west/Spawn` (240,120) in 32 ticks; the way back arrives at the bay's east Spawn (640,288). Walking west from it stays in the bay.
- **Real playthrough:** 1/0.
- **Other files:**

| File | Result |
|---|---|
| `test_ch01_step1_negatives.gd` | 12/0, 106 s |
| `test_ch01_pz002_negative.gd` | 2/0 |
| `test_room_shape.gd` | 7/0 |
| `test_ch01_graph.gd` | 9/0 |
| `test_audio_real_input.gd` | 2/0 |
| `test_ch01_unlock_guards.gd` | 3/1 once, 4/0 on the re-run (P3-2) |

- **Python:** 22 OK; builder dry run 0 changed lines.

## 3. New findings

**P2-1: stale `ArchwayEast` draws a second east door frame** (§2b). One line; required before merge.

**P3**
1. **Legacy duplicate archways.** Root-level `ArchwayWest` / `ArchwayEast` duplicate the builder archways here and in `concourse_west.tscn` and `security_crossing.tscn`. Where they share a position they are invisible, but any door move has to remember both nodes (that is how P2-1 happened). Remove them in one cleanup across the rebuilt rooms; the manifest and `placement_snapshot_ch01.json` list them.
2. **`test_ch01_unlock_guards.gd` is intermittent:** "aiming the wheel does not walk the player" failed once in 2 runs.
   - **Not the room:** `probe_restore_085b.log` shows Elias still to 0.00 px for 180 frames after each of 3 Continues at (336,136).
   - **Likely cause, in the test helper (unchanged from main):** `_try_every_selection` releases `ability_wheel` and waits for the wheel to close before releasing the held move keys. On some frames Elias then walks a step.
   - **Fix:** call `hold_moves([])` before `release(&"ability_wheel")`.
   - **Why it shows now:** round 2 added the checkpoint save and Continue in front of the helper, which changes the timing. A Lead validate can flake on it.
3. **Two weak stand-spot rows in the new test:**
   - **Pocket rows** start from (560,236), 16.5 px from (544,240), less than one tile (17.9 px). Use (504,252) as my probe does.
   - **The plaque row** allows 4.0 px; the spot sits on the x = 19 line (3.89 px reached). Either keep the tolerance with a comment, or move the spec spot off the line in TLF-085b along with the N-wall plaque.
4. **Run time:** the bay file takes 91 s and `step1_negatives` 106 s against the 120 s cap.
5. **Handoff nit:** the placement table's "SO-01 Dist" column is the stand-spot-to-object distance; rename it.

## 4. Next

On this APPROVE (pending P2-1), I start the Maintenance Bay lighting and shadows on `agent/opus-core-tlf085-light`, built from Flash's tip merged with `40ac555`. The proof shots need a single east frame, so that branch carries the same one-line `ArchwayEast` move as its own commit. If Flash lands the identical line, the merge is clean.
