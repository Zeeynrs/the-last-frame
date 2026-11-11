# TLF-085 technical review: Maintenance Bay v2 (Flash, `71bb9ea`)

Opus, 2026-11-11. Read-only review of `origin/adityadaffa522/tlf-085-maintenance-v2` at `71bb9ea`, on top of main `1388d6d`.

**Spec:** `design/ch01/rooms_v2/maintenance_bay.md` and `.json`, `PATTERN.md` rules 1–12 and `docs/tasks/TLF-085.md`. All four are byte-identical to `origin/lead/tlf-084-plan`.

**Bar:** the same as my TLF-080 reviews (`docs/reviews/TLF-080/`).

**Method:**
- **Scratch copy:** a renamed `git archive` ("TLF Verify rev085-71bb9ea"), imported headless.
- **Runs:** every Godot call had a hard 120 s cap and no `--eval`. I ran the affected test files, one probe file of my own (real capsule, real input after setup), and my own mutation run (not Flash's in-suite mutation tests).
- **Unchanged:** no Flash file was changed and nothing was merged; the real save and `D:\TheLastFrame\the-last-frame` were not touched.
- **Evidence:** `TLF-085/71bb9ea/`.

## Verdict: **CHANGES REQUIRED**

**What holds:**
- **Geometry and clusters:** the geometry follows the spec, and both puzzle clusters are rigid to the pixel (every member, sub-node and collider), with **one exception: the checkpoint** (item 1).
- **Doors and spawns:** the doors work, and both spawns are right; the 3 s holds from the arrival never trigger the door.
- **Reach and tests:** every spec stand spot is reachable with the right target. PZ-002 and SO-02 pass with real input, including R03/R04 and the negatives.
- **Manifest and baseline:** edited in place for this room only.
- **Full real playthrough:** passes.

**What blocks:** the checkpoint was not moved with cluster H, and the tests and ROOM_GRAPH were rewritten to match the scene instead of the layout. Everything else is P2/P3.

**Tests vs my own mutations:** all 11 go RED in Flash's suite (section 4).
- **Door, camera, checkpoint and cluster:** the door sweep (radius 6 → 40, spawn 1 tile from the door), the camera (bounds ignoring `room_shape`), the checkpoint anchor and a cluster drift are all guarded.
- **Divider sweeps:** each of the 6 divider segments goes RED when its collider is removed (x = 7, 16, 19, north and south).

| # | Priority | Owner | Finding |
|---|---|---|---|
| 1 | **P1** | Flash (or the Lead amends the layout) | `checkpoint` is at **(2,5)** (272,120), on the arrival spawn, instead of the layout's **(5,5)** (320,144) (cluster H, +4). The checkpoint test, `ROOM_GRAPH.md` §checkpoints and the handoff were all set to (2,5). The task asks for "checkpoint save/load at (5,5) → `safe_anchor_entry`". |
| 2 | P2 | Lead / Sol | Floor decor did not move with the clusters: the 30 industrial-grating cells (source 3) still mark the **old** shutter line x 7..9, y 0..9, now right behind the bulkhead. The 5 cable-conduit cells (source 5) at (2..6, 4) are also unchanged. TLF-080 had the same issue with the tactile cells. |
| 3 | P2 | Lead / Sol | In the gear bay, `counterweight_gear` (13,1) and `fire_shutter` (16,4) share screen x 512 (x − y = 12 for both, inherited from the rigid cluster: 4 and 4 in the old room). The closed shutter covers the gear's lower third, and at the gear's own stand spot it covers Elias's legs (`gear_x3.png`). Puzzle readability: art call for Fable/Sol (item 6.3). |
| 4 | P2 | Lead / Sol | The odd width (25) leaves the last N-wall tile (24..25, 0) without a module. The builder says "NOT DRAWN: 1-tile N wall end … needs a TLF-068 piece", and the floor runs one tile past the wall end at the NE corner (`ne_corner_x3.png`). |
| 5 | P2 | Flash | The stand-spot test proves nothing about reach: it teleports Elias to `spot + (2,2)` and then walks 2.8 px. Several of its spots are not the spec's (gear/shutter (488,188) vs the casting spot (480,208); plaque (608,240) in band D vs (592,232) from the pocket). My probe walks the **spec** spots from a safe anchor ≥ 1 tile away and they hold (item 3), so only the test is weak. |
| 6 | P2 | Flash | Handoff numbers that are wrong (item 2.6). Regenerate the table from the scene. |
| 7 | P3 | Flash | `test_ch01_unlock_guards.gd` walks to (352,128) for the technician, not the translated spec spot (352,144) that the real playthrough uses. Both trace `n11` (probe C), but use the cluster spot. |
| 8 | P3 | Flash | `test_ch01_graph.gd` comment and `ROOM_GRAPH.md` say the bay uses follow framing / "Follow 640×360". The room fits 960×540, so the camera is fixed at (392,204) (Flash's own test asserts this). |
| 9 | P3 | Lead | `test_ch01_step1_negatives.gd` takes 107.6 s in one call (103 s on main), close to the 120 s per-call cap of the capped validate. Consider splitting it. |
| 10 | P3 | — | Visible vs real apertures: the bulkhead modules leave a 2-tile visual gap at the hatch (y 2..4) for a 1.5-tile collision gap (2.25..3.75). The partition halves at x = 16/19 show y ≤ 3 and ≥ 5 around the 3.25..4.75 opening. This is the Concourse v2 convention, already accepted by Sol. |

## 1. Rigid clusters, every node vs `1388d6d`

**Method:** I parsed both scene files and compared every node's global position (`nodes.py.txt`, `node_deltas.txt`).

**Cluster H, +(64,32) = +4 tiles:**
- `safe_anchor_entry`, `n11_hatch_tech` and its CollisionShape, Footprint and Presenter;
- `hatch_01` and its CollisionShape, Blocker, TemporalComponent and Presenter;
- `hatch_threshold`, `exit_trigger_hatch`;
- `hatch_plate_01`, `hatch_residue`, `doc_hatch_chart`, `bell_plate_01` and their children.

Every one moves by exactly (64,32).

**Cluster BC, +(128,64) = +8 tiles:**
- `reset_anchor_01`, both safe anchors, `counterweight_gear`, `gear_residue`;
- `fire_shutter` and `shutter_threshold_trigger`, `doc_tech_log`;
- `exit_trigger_east`, `inner_shutter` and `inner_shutter_threshold`, `doc_inner_shutter_plate`, `exit_trigger_east_02`.

Every one moves by exactly (128,64), children included. y is unchanged in tiles everywhere.

**Not in a cluster:**

| Node | Old | New | Spec |
|---|---|---|---|
| `door_entry_west`, archway | (0,5) | (0,5) | (0,5) ✓ |
| door `Spawn` | (1,5) | **(2,5)** (272,120) | (2,5) ✓ |
| `door_exit_east`, archway, Spawn | (13,4) | **(25,4)** (656,296); Spawn (24,4) | (25,4) ✓ |
| **`checkpoint`** | (1,5) (256,112) | **(2,5)** (272,120), +(16,8) | **(5,5)** (320,144) ✗ (item 1) |

**Colliders (segments in tile space):**
- **Bulkhead:** x = 7, y 0..2.25 and 3.75..**16**.
- **ShutterDividers:** x = 16, y 0..3.25 and 4.75..**16**.
- **InnerDivider:** x = 19, y 0..3.25 and 4.75..**16**.
- All three equal the old segments + the cluster delta, with the south runs extended to the new S edge as the spec asks.
- **Perimeter:** `(320,60),(728,264),(464,396),(56,192)`, the 25 × 16 outline with a 0.25-tile outset.

**Dressing:**
- **Bulkhead modules:** 7 (`Wall_bulkhead_n0` at (7,1); `s0..s5` at (7,5)…(7,15)), the last reaching y 16 ✓.
- **Low partitions:** 8 per line at x = 16 and x = 19 (1 whole + 1 half north of the opening, 1 half + 5 whole south of it), with halves at the openings ✓.
- **Walls:** 12 N and 8 W modules ✓.

**Shape:** builder dry run (mine) shows 0 diff, `metadata/room_shape` 25 × 16 (400 cells), and `hidden_floor_cells()` empty (`test_room_shape` 7/0). Python builder tests: 22 OK.

**Flash's cluster test:** `test_rigid_cluster_shifts_and_relative_distances` asserts H and BC with hard-coded old/new pairs, but its H list leaves out `checkpoint` and `safe_anchor_entry`, so item 1 slips past it.

## 2. The handoff items the Lead asked about

### 2.1 Checkpoint (item 1)

**The mismatch:**

| Source | Checkpoint | Note |
|---|---|---|
| Layout §2 (cluster H) and landing criteria | (5,5) | |
| Scene | (2,5) (272,120) | the same point as the arrival `Spawn` |
| `ROOM_GRAPH.md` §checkpoint table | (2,5) | the branch rewrote it from (1,5); the rooms table does not list the checkpoint tile |
| `test_checkpoint_saveload_restores_player_and_camera` | (2,5) | `cp_zone` |

**Effect:** entering the bay autosaves at once. Arriving inside the zone is the same as the old room's behaviour, but it is not the rebuilt layout. Continue restores to `safe_anchor_entry` (5,4) (336,136) either way: the test passes, and so does `test_so02_bell_decoy_and_checkpoint_spawn`.

**Fix:**
1. Move `checkpoint` to (320,144).
2. Point the test's `cp_zone` there (with `outside` at least 1 tile away).
3. Add `checkpoint` and `safe_anchor_entry` to the cluster-H assertions.
4. Set ROOM_GRAPH to (5,5).

**Alternatively,** the Lead accepts (2,5) and amends the layout. Note that with (5,5) the arrival is no longer inside a save zone.

### 2.2 `door_entry_west`: a radius-6 circle at (−4,−2)

The trigger centre is (236,102), tile (−0.25, 5): on the 0.25-tile perimeter outset, inside the wall cut.

**Probe A** (from inside, push straight west from x 1.2 for 90 ticks, start y every 0.25 tile):

| Start y (tiles) | Result |
|---|---|
| 3.0–3.5 | stays (stops at tile x 0.49) |
| **3.75–6.0** | **the door triggers** (6–26 ticks) |
| 6.25–7.0 | stays |

**Result: still a working door.** It leads back to `ch01.concourse_west`, the pair in the graph (E2), not security; the trigger is about 2.25 tiles of wall. It is thin enough: nothing else touches it.
- **Archway:** the archway sprite covers y 4..6, and the trigger reaches about 0.25 tile beyond it on each side; Concourse v2 had about 2 tiles.
- **Spawn:** the arrival `Spawn` (2,5) is 2 tiles from the door (rule 10 minimum; the layout allowed no more on this side).

### 2.3 Camera bounds

`Rect2(48, 0, 688, 408)` is right. The floor diamond is (64..720, 64..392) px. With `MARGIN_SIDE` 16 / `MARGIN_TOP` 64 / `MARGIN_BOTTOM` 16 that gives x 48..736 and y 0..408, centre (392,204). The room fits the 960×540 view, so RoomCamera centres it at (392,204) at every spot (Flash's test). The handoff's "Pixel Dimensions: 800 × 328" is wrong; the floor is 656 × 328.

### 2.4 Bulkhead to y 16

Yes. The south segment runs (372,150) → (176,248) = tile (7,3.75) → (7,16); module `s5` at (7,15) covers 14..16.

### 2.5 Low partitions at x = 16 / 19

Yes. There are 8 sprites each, the halves sit at (16,3)/(16,5) and (19,3)/(19,5), next to the 1.5-tile openings, and there is no new collision. The regions and offsets are the same as Concourse v2's `PartitionLowE_divider_*_half`.

### 2.6 Wrong numbers in the handoff (item 6)

| Handoff says | Scene says |
|---|---|
| `checkpoint` (2,5) | (2,5) (the layout says (5,5), item 1) |
| `safe_anchor_entry` (336,120) | (336,136) |
| Bulkhead modules `WallW_bulkhead_0..6` | `Wall_bulkhead_n0`, `s0..s5` |
| "3 whole + 1 half per run" | north: 1 whole + 1 half; south: 1 half + 5 whole |
| Perimeter "(688,148),(288,−52),(160,204),(560,404)" | `(320,60),(728,264),(464,396),(56,192)` |
| "800 × 328 px" | 656 × 328 |
| "all source 4 `terrazzo_worn`" | source 4 is `concrete_service`; there are also 30 grating (3) and 5 conduit (5) cells |
| Arrival screenshot caption "checkpoint at (320,144)" | contradicts its own table (272,120) |
| `n11_hatch_tech` stand (5,3) (352,128) | the translated spec spot is (6,4) (352,144) |

## 3. Tests: real input, sweeps, stand spots, camera

**Affected files in the scratch copy** (one capped call each; `runs/*.log`):

| File | Result | Time |
|---|---|---:|
| `test_ch01_maintenance_bay_v2` | 15/0 | 85 s |
| `test_ch01_step1_negatives` | 12/0 | 107.6 s |
| `test_ch01_pz002_negative` | 2/0 | 38.6 s |
| `test_ch01_unlock_guards` | 4/0 | 33.7 s |
| `test_ch01_sort_order` | 3/0 | 6.1 s |
| `test_ch01_art_integration` | 6/0 | 2.9 s |
| `test_ch01_playthrough` | 19/0 | 15.4 s |
| `test_room_shape` | 7/0 | 9.4 s |
| `test_ch01_graph` | 9/0 | 1.3 s |
| `test_audio_real_input` | 2/0 | 5.2 s |
| `test_ch01_real_playthrough` | 1/0 | 67.1 s |

All have 0 SCRIPT ERROR. The first `--import` of the archive crashed on `ui_feedback.csv` (the known flaky import crash); the second was clean.

**SO-02 and PZ-002 with real input after translation:**
- **The real playthrough** traces the technician to unlock Freeze, steps on the plate, Freezes the hatch and walks through: SO-02 solved, 116 frames. It then Rewinds the shutter, Freezes the gear, crosses, Rewinds the inner shutter and walks to `exit_trigger_east_02`: PZ-002 solved, 210 frames. It ends in the east door.
- **The negatives** walk the translated routes:
  - `test_so02_hatch_closes_without_freeze`, `test_so02_bulkhead_sealed` (bulkhead line `x + 2y` 544 → 672, +128 ✓), `test_so02_bell_decoy_and_checkpoint_spawn`;
  - `test_pz002_inner_shutter_needs_the_gear_frozen` (**R03**: Rewind on the inner shutter refused `unanchored`, 600 ticks unsolved; **R04**: a late Freeze from the pocket solves);
  - `test_ch01_pz002_negative` with assist off and on.
- **Deltas:** every translated waypoint is the old one + (64,32) or + (128,64). The only exceptions are a 1 px x shift on two hatch points and item 7.
- **Flash's own lifecycle test** unlocks Rewind/Freeze directly instead of tracing. That is acceptable, because the real playthrough covers the Trace unlock.

**3 s holds from the arrival (probe B,** each from a fresh placement at the spawn):

| Held | Result |
|---|---|
| left | stayed |
| up | stayed |
| down | stayed |
| left + down | stayed |
| left + up | the door triggers after 14 ticks |

Left + up walks straight at the door, as in Concourse v2 (15 ticks), so rule 10 (left/up/down) holds.

**Spec stand spots (probe C):** each spot is walked to with real input from a safe anchor ≥ 1 tile away, then the ability's target is chosen with `PocketWatch.choose_watch_target` (watch) or `Player.current_target` (use).

| Spot (spec + cluster delta) | Reached | Target (distance) |
|---|---:|---|
| SO-02 technician Trace (352,144) | 2.00 px | `n11_hatch_tech` (16.2) ✓ |
| unlock-guards spot (352,128) | 2.10 px | `n11_hatch_tech` (16.0) ✓ |
| SO-02 chart use (288,160) | 2.05 px | `doc_hatch_chart` (17.0) ✓ |
| SO-02 plate Freeze (320,160) | 2.44 px | `hatch_01` (64.3) ✓ |
| SO-02 bell decoy (272,168), Freeze | 2.00 px | none ✓ (TEST-SO02-07) |
| PZ-002 casting spot (480,208): Rewind / Freeze / Trace | 2.10 px | `fire_shutter` 33.9 / `counterweight_gear` 43.8 / `gear_residue` 27.7 ✓ |
| R03 Rewind spot (468,192) | 1.75 px | `fire_shutter` (53.6) ✓ |
| `reset_anchor_01` use (400,216) | 2.20 px | `reset_anchor_01` (19.9) ✓ |
| pocket (544,240): Rewind / Freeze | 1.51 px | `inner_shutter` 18.6 / `counterweight_gear` 71.9 ✓ |
| pocket (528,232), Rewind (spec (400,168)) | 4.03 px | `fire_shutter` (21.4) ✓ |
| plaque from the pocket (592,232) | 3.81 px | `doc_inner_shutter_plate` (16.5) ✓ |
| Flash's plaque spot (608,240), from the pocket | 17.7 px | `doc_inner_shutter_plate` (7.9); band D, behind the closed inner shutter |

The two spots above 2.6 px:
- **(528,232)** sits against the closed shutter's Blocker.
- **(592,232)** lies on the inner divider line itself.

Both have the same geometry as in the old room (rigid cluster), and both still choose the right target. The **reach** therefore holds; only Flash's test (item 5) does not show it.

**Camera test:** not self-referential any more. It asserts `bounds == Rect2(48,0,688,408)` and centre (392,204) explicitly (mutation MC3 below).

**East door (probe D):**
- **Out:** pushing from (608,272) into the east door enters `ch01.security_crossing` after 23 ticks, 1.9 px from its `door_entry_west/Spawn` (240,120).
- **Back:** pushing into security's west door returns to the bay at (638.2,287.1), 2.0 px from `door_exit_east/Spawn` (640,288).
- **Away again:** walking west from there stays in the bay.

## 4. My mutations (not Flash's in-suite ones)

**Method:** each stub edits the scratch copy and runs the listed files (one capped call each), then the file is restored byte for byte (sha256 checked afterwards, `mutation_085.log`).

| Stub | `test_ch01_maintenance_bay_v2` | Negatives | Note |
|---|---|---|---|
| MV1 bulkhead north segment disabled | **RED** 14/1 (bulkhead sweep reaches x 8.21) | **RED** `step1_negatives` 11/1 (`test_so02_bulkhead_sealed`) | |
| MV2 bulkhead south segment disabled | **RED** 14/1 (x 8.11) | **RED** `step1_negatives` 11/1 | |
| MV3 shutter divider north (x = 16) disabled | **RED** 14/1 (x 17.21) | GREEN `pz002_negative` 2/0 | only Flash's sweep guards x = 16 |
| MV4 shutter divider south disabled | **RED** 14/1 (x 17.11) | GREEN `pz002_negative` 2/0 | idem |
| MV5 inner divider north (x = 19) disabled | **RED** 14/1 (x 20.21) | GREEN `step1_negatives` 12/0 (a re-run: the first call printed no TESTS line) | only Flash's sweep guards x = 19 |
| MV6 inner divider south disabled | **RED** 14/1 (x 20.11) | GREEN `step1_negatives` 12/0 | idem |
| MD1 west door trigger radius 6 → 40 | **RED** 13/2 (sweep up and down; checkpoint/Continue) | — | |
| MD2 arrival Spawn 1 tile from the door | **RED** 14/1 (spawn assertion and all three holds) | — | unlike TLF-080, the left/up/down holds alone catch it here |
| MC3 room bounds ignore `metadata/room_shape` | **RED** 14/1 (explicit `Rect2` and centre) | — | my TLF-080 P2 fixed |
| MK1 checkpoint spawn anchor removed | **RED** 14/1 | — | |
| MR1 `counterweight_gear` +16 px | **RED** 14/1 (cluster test) | — | |

**Result:** the door sweep and the three divider sweeps are real guards, not only Flash's in-suite mutation tests. They pass on the real scene and go RED on the real scene with the collider removed. The shutter and inner-divider lines are guarded **only** by the new sweeps, not by the real-input negatives; that is fine, because the sweeps are in the suite.

**Not mutated:** stand-spot reach (item 5: Flash's test teleports to 2.8 px, so a blocked spot would still need an obstacle within 2.8 px to fail it). My probe C covers the spec spots instead.

## 5. Manifest, baseline, graph, churn

- **`render_manifest.json`:** the 416-line diff (208 +/208 −) changes `rooms[2]` (`maintenance_bay`) only.
  - **Unchanged:** `sha`/`display`/`sides`/`user_dir` and the other 9 rooms.
  - **Within the room:** the same 27 objects and 14 non-visual ids, and **every changed number is a pure translation** by that object's delta: H (64,32), BC (128,64), east door/archway (192,96), walls and the west door (0,0). No `pixels`, `audit` or `notes` field changed.
  - **New nodes:** the new modules and partitions are not added as rows, which is the same in-place policy as Concourse v2.
- **Collision baseline** (`test_ch01_art_integration.gd`): the decoded GZIP JSON differs only in `maintenance_bay`.
- **`test_ch01_sort_order.gd`:** unchanged (it reads the manifest), 3/0.
- **Graph:** `ch01_graph.tres` changes 25 × 16, the E door (25,4), and safe anchors (13,4), (18,4) and the new `safe_anchor_entry` (5,4). `ROOM_GRAPH.md` changes the size, doors, anchors and E3, plus the checkpoint row (item 1).
  - **`test_ch01_graph`:** the E-door exception is per room (my TLF-080 P3 adopted), and the fit-the-camera skip comment is wrong (item 8).
- **Churn:**
  - **Files:** the 25 changed files are all in scope. The task, layout and program docs are byte-identical to the Lead's branch, and `tools/capture_maintenance_bay.gd` is the screenshot tool.
  - **Encoding:** no BOM or UTF-16 in any changed file, the manifest stays LF, and there are no stray root files.

## 6. Visual sanity (Fable/Sol make the art call)

1. **Grating band in the wrong place (item 2):** in `gear_bay_960x540.png` the dark grate floor (source 3) fills x 7..9 right behind the bulkhead. In the old room it was the shutter line x = 8 (the fire-shutter gap). It reads as a floor feature with no purpose here. Moved with BC it would be x 15..17 (all y), or wherever Sol puts the shutter threshold.
2. **Conduit strip:** the 5 conduit cells (2..6, 4) used to run from the old hatch line (x = 3) east toward the gear. They now end at x 6, beside the new bulkhead.
3. **Gear behind the shutter (item 3)**, `gear_x3.png` and `pocket_x3.png`:
   - **What overlaps:** the gear placeholder (N-wall, 1 tile off the wall) stands directly above the closed fire shutter on screen. The shutter's top covers the gear's lower third, and when Elias stands on the gear's Trace/Freeze side he is drawn behind the shutter from the waist down.
   - **The puzzle still reads:** the gear's teeth stay visible, and the Freeze target is chosen by distance, not by sight.
   - **Why it matters:** the causal pair "gear holds the shutter" stacks into one silhouette, and Elias is half hidden at the decision point.
   - **Not new:** both sit in the rigid cluster, so this was the same in the old room (x − y = 4 for both).
   - **Options (Lead/Fable/Sol):**
     - shift the gear along the N wall (x only, e.g. (11..12, 1)) and re-check the 17.9 px Freeze/Trace spots;
     - or let the TLF-085b sheared N-wall gear sit higher on the wall so it clears the shutter top.
4. **NE corner (item 4):** the N wall stops at x = 24 and the floor at x = 25, so a 1-tile strip of floor runs past the wall end. It needs the TLF-068 1-tile end piece, or an even width.
5. **`doc_inner_shutter_plate`** is described as a "wall plaque on N wall module 9", but it is drawn as a floor document at (19,1) next to the x = 19 partition. That is the same as before (old (11,1)), so this is a facing note for Sol, not a TLF-085 regression.

## Evidence (`TLF-085/71bb9ea/`)

- `evidence.txt`: test results, probe output and mutation output.
- `node_deltas.txt` (every node, old → new global position, delta, tile) and `nodes.py.txt`.
- `probe_085.gd.txt`, `mutate_085.py.txt`, `mutation_085.log`.
- `gear_x3.png`, `pocket_x3.png`, `ne_corner_x3.png`: crops ×3 of Flash's screenshots.
- **Not done:**
  - the full validate (the Lead runs it on the exact tree);
  - the art and facing call (Fable/Sol).
