# TLF-080 technical review: Concourse West v2 (Flash, `f44af6e`)

Opus, 2026-11-10. Read-only review of `origin/adityadaffa522/tlf-080-concourse-v2` at `f44af6e`, on top of main `f21aef6`.

**Spec:** `origin/lead/tlf-080-spec` `e3f7b76`, namely `design/ch01/rooms_v2/concourse_west.md`, PATTERN.md rules 8–12 and `docs/tasks/TLF-080.md`.

**Method:**
- **Scratch copy:** a renamed `git archive` ("TLF Verify rev080-f44af6e"), imported headless.
- **Runs:** every Godot call had a hard 120 s cap and no `--eval`. I ran the affected test files, five probe files of my own (real capsule, real input after setup), and a mutation run against Flash's new suite.
- **Unchanged:** no Flash file was changed and nothing was merged; the real save was not touched. The Lead runs the full validate.
- **Evidence:** `TLF-080/f44af6e/`.

## Verdict: **CHANGES REQUIRED** (one test P1 for Flash, one layout P1 for the Lead; everything measured on the room itself passes)

**What holds:** the geometry follows the spec exactly, and the puzzle clusters are rigid. Stand-spot reach, the door aperture, the 3 s door sweep, the camera, TEST-AU-08, the PZ-001/PZ-006 negatives and statue rule P all hold.

**What blocks:**
- **Divider guard (test):** nothing guards the turnstile dividers. Disabling the north divider (an open hall around the gate, i.e. skipping PZ-001) passes Flash's suite *and* the Step 1 negatives.
- **Divider visibility (layout):** the dividers are invisible collision across a 16-tile open hall, so a visible partition is needed before the owner plays the room.

| # | Priority | Owner | Finding |
|---|---|---|---|
| 1 | **P1** | Flash | No test fails when a turnstile divider is removed (mutation MV1 stays GREEN in the suite and in `test_ch01_step1_negatives`). Add a divider sweep. |
| 2 | **P1** | Lead (Sol for the art) | Dividers at x = 8 (y 0–7, 9–16) are collision only across an open hall. Add the existing low partition along both segments (item 5). |
| 3 | P2 | Lead/Flash | The 3 tactile floor cells were not moved with the PZ-001 cluster: they still mark the old threshold at x = 3, next to the spawn, 5 tiles from the gate. |
| 4 | P2 | Lead/Sol | `conduit_01` (fallen state) now lies at the W wall, about 5 tiles from the turnstile it "pins" (PZ-001 hint 2). This follows the spec; the causal link no longer reads. |
| 5 | P2 | Flash | Camera test is self-referential: it takes its expected values from `router.current_room_bounds()`. Ignoring `metadata/room_shape` (MC3) stays GREEN. Assert the explicit bounds and centre. |
| 6 | P2 | Flash | `tests/chapters/ch01/test_ch01_art_integration.gd` gained a UTF-8 BOM and mojibake (`§1` → `Â§1`). |
| 7 | P2 | Flash | `diff_concourse_dry_run.txt` (UTF-16 LE with BOM) at the repo root: delete it (the diff is already in the handoff) or move it as UTF-8 under `docs/handoffs/TLF-080/`. |
| 8 | P2 | Flash | Handoff placement table and camera section have wrong numbers (item 4). |
| 9 | P3 | Flash | `test_ch01_graph.gd`: the E-door rule is loosened for **every** room (`x == w − 1 or x == w`) to accept this room's door on the edge. Use a per-room exception. |
| 10 | P3 | — | `run_tests.gd` file arguments: safe for `validate.ps1`/CI (item 1). Builder test move: coverage kept (item 2). |
| 11 | P3 | Flash | TEST-AU-08 test: it uses the arrival spawn, not the spec's entry anchor, and checks only clause 1. The probe shows all clauses hold, except the pre-existing TLF-056 limit on (312,188) with the gate closed. |

## 1. Geometry vs spec, rigid clusters, statue rule P

**Positions:** every top-level node in the scene sits on its spec tile, using `tile(x,y) = (320+16(x−y), 64+8(x+y))`:
- door W `(0,8)`, spawn `(2,8)`, checkpoint `(3,8)`, gate `(8,8)`;
- trace anchor `(8.5,8)`, courier `(7,9)`, `reset_anchor_01` `(9,10)`;
- conduit `(0.5,11.5)`, call box `(0.5,3)`, ticket terms `(0.5,15)`, clock `(11,0)`;
- dials `(15.5/17.5/19.5, 0.5)`, `reset_anchor_02` `(14.5,0.5)`, validator `(20.5,1.5)`;
- pillar `(17,11)`, evac notice `(16,10)`, door E `(28,8)`;
- commuters `(22.5,9.5)`, `(22.5,11.5)`, `(22.5,13.5)`, `(20.5,12.5)`.

**Rigid clusters (old scene → new scene, pixel deltas):**
- **PZ-001:** +(48,72) for gate, footprint, trace anchor, courier, `reset_anchor_01`, both safe anchors and the exit trigger.
- **PZ-006:** +(112,48) for the three dials, `reset_anchor_02` and the validator.
- **Commuters:** +(96,104) for all four.

Each member moves by the same delta, so every puzzle distance (17.9 px spots, TEST-AU-08) is unchanged.

**Statue rule P / TEST-CM-05:** the commuters are ≥ 1.5 tiles south of the walking line y = 8 and away from the door approach. The courier is 1 tile from the line but has no collider (Area2D only). The real playthrough walks spawn → gate → dials → east door with every statue collider on (passes).

**Shape:** `metadata/room_shape` 28×16, 448 cells, builder dry-run diff 0. 14 N and 8 W modules, with `WallW_*` and `WallN_*` at x/y = 2k+1.

## 2. Reach, apertures, door sweep, east door, camera

**Stand spots:** Flash's `test_every_stand_spot_reachable_within_2_6_px` walks 19 spots with the real capsule and passes. The gate Rewind spot (298,198) and the entry anchor (304,184) are reached within 1.5 px with the gate closed (probe F).

**West door from the inside (probe A):** pushing into the W wall triggers `door_entry_west` for wall positions y 7.0–9.0, an aperture of about **2 tiles** (≥ 1.5). Walking from the spawn at the archway centre leaves to the arrival platform.

**Turnstile opening (probe C):** once the gate is open, the passage is crossed from every start y 7.6–9.2, about 1.6 tiles of usable width for the 12 px capsule (≥ 1.5).

**3 s sweep from the arrival (224,144)** (probe B2, each direction from a fresh `start_at`):

| Held | Result |
|---|---|
| left | stayed |
| up | stayed |
| down | stayed |
| left + down | stayed |
| **left + up** | the door triggers at frame 15 (0.25 s) |

Left + up heads straight at the exit, so this is expected and rule 10 (left/up/down) is met. The owner may still find 2 tiles short; spec §3.2 allowed 3. (My first probe, B, mixed directions within one test after a door traversal; its "left" result came from that earlier traversal and is discarded.)

**East door with the staff door closed (probe D):** 10 approaches from inside the room on a 34/60 px ring push at the door for 100 ticks; none enters the bay. Flash's 3-approach test passes too.

**Camera with the real 960×540 view (probe E):**
- **Bounds:** `current_room_bounds()` = `Rect2(48, 0, 736, 432)`, smaller than the view on both axes.
- **Fixed centre:** RoomCamera therefore centres the room at **(416,216)**, the same for the arrival, gate, dials and east door. The view `(−64,−54,960,540)` encloses the whole room, and Elias is on screen at all four.
- **Edges:** none are reached; there is no scroll.
- **Flash's screenshots:** they agree. The handoff's "view 640×360" and "bounds [160,−52]→[736,428]" are wrong (item 8).

## 3. TEST-AU-08, negatives, playthrough

**TEST-AU-08 (probe F):**

| Clause | Result |
|---|---|
| 1. From the entry anchor (304,184), the Trace target is `n05_courier` at 17.9 px | ✓ (the trace anchor is at 26.8) |
| 2. From (312,188), the target is `turnstile_trace_anchor` at 17.9 px | ✓ |
| 3. Reachability with the gate closed | (304,184) ✓; (312,188) is reached only within 4.1 px, because it overlaps the gate Blocker. This limit is documented since TLF-056, and the playthrough traces it after the gate opens. |

From the arrival spawn, the courier is the only traceable object within 96 px (80.0 px), so Flash's spawn-based test holds. Its comment and spot differ from the spec text (item 11).

**Negatives:** `test_ch01_step1_negatives.gd` passes 12/0. The PZ-001 pinned-gate and PZ-006 staff-door pushes are moved by exactly the cluster and door deltas.

**Real playthrough:** 1/0, with the concourse segments 2a (309 frames) and 2b (728 frames).

**Other affected files:**

| File | Result |
|---|---|
| `test_ch01_playthrough` | 19/0 |
| `test_ch01_sort_order` | 3/0 |
| `test_ch01_art_integration` | 6/0 |
| `test_ch01_graph` | 9/0 |
| `test_dial_readout` | 3/0 |
| `test_audio_real_input` | 2/0 |
| `test_ch01_unlock_guards` | 4/0 |
| Python builder | 22 OK |

All have 0 SCRIPT ERROR and 0 ERROR.

**Manifest and baseline edited in place, this room only:** `render_manifest.json` changes `rooms[concourse_west]` only, and `sha`/`display`/`sides`/`user_dir` and the other 9 rooms are identical. The decoded collision fingerprint baseline changes `concourse_west` only.

## 4. Mutation check of `test_ch01_concourse_west_v2.gd`

Each stub was applied to the scratch copy, and the files were restored byte for byte (identical to `f44af6e` afterwards). Baseline 7/0; restored 7/0.

| Stub | Result | Note |
|---|---|---|
| MD1 door trigger radius 6 → 40 | **RED** 3/4 | the sweep fails on up and down; checkpoint and Continue also fail |
| MD2 arrival Spawn moved to 1 tile from the door | **RED** 5/2 | caught by the hard-coded spawn assertion and by AU-08 (the conduit becomes the target); the left/up/down sweeps alone stay green |
| MC1 camera follows instead of centring a room that fits | **RED** 6/1 | |
| MC2 camera clamp branch removed | GREEN | expected: this room fits the view, so the clamp branch never runs |
| MC3 room bounds ignore `metadata/room_shape` | **GREEN** | the test compares against the router's own bounds (item 5) |
| MK1 checkpoint spawn anchor removed | **RED** 6/1 | |
| MK2 `restore_from_save` skips placement | **RED** 6/1 | |
| MV1 north turnstile divider disabled | **GREEN** in the suite **and** in `test_ch01_step1_negatives.gd` | item 1 |

So the door sweep, the checkpoint restore and the centring are guarded. The room-bounds source and the dividers are not.

**Fix for MV1:** a divider sweep like probe C, with the gate closed: start at x 7.2 every 0.8 tile of y, push east 60 ticks, and assert the tile x never passes 8.2. With the dividers present the furthest point reached is x 7.77, with no crossing.

**Fix for MC3:** assert `current_room_bounds() == Rect2(48,0,736,432)` and centre `(416,216)`.

## 5. Items the Lead asked about

1. **`tests/run_tests.gd` file arguments: safe.** It reads `.gd` paths only from `OS.get_cmdline_user_args()`, i.e. after `--`.
   - `validate.ps1` and CI call `-s res://tests/run_tests.gd` without user arguments, so discovery is unchanged; a non-`.gd` user argument also falls back to discovery.
   - A missing file is counted as a failure (`TESTS: 0 passed, 1 failed`, exit 1), so a typo cannot pass.
   - It is outside the task's scope but useful (I ran every file this way). Document it in the runner header or in `tools/validate.ps1` usage.
2. **Builder `Doors` test moved to `maintenance_bay`: coverage kept.**
   - **Same behaviour checked:** the W door at (0,5) leaves `WallW_2` to the archway, keeps the other modules' names, and one module fewer is drawn. The E door argument was dropped, but low E sides have no modules to remove, so nothing about E was asserted before either.
   - **Concourse still covered:** v2 is now in `TenRoomsRoundTrip`, built from `rooms_v2/concourse_west.json`.
   - **Result:** `python -m unittest discover -s tools/content` 22 OK.
3. **`diff_concourse_dry_run.txt`:** UTF-16 LE with BOM (`FF FE`) at the repo root; git treats it as binary. Delete it, or move it as UTF-8 under `docs/handoffs/TLF-080/` (item 7).
4. **Handoff placement table:** the scene positions match the spec, but the table's tile labels do not.
   - **Wrong tile labels:** `dial_line` (23,5) (actual (15.5,0.5)), `reset_anchor_01` (11,8) (actual (9,10)), `call_box` "(5,5) N wall" (actual (0.5,3) on the W wall). Likewise `reset_anchor_02` (22,6) at (544,200) (actual (14.5,0.5) at (544,184)), `ticket_validator` (27,7) at (608,248) (actual (20.5,1.5) at (624,240)), and `n05_courier` (6,10) (actual (7,9)).
   - **Camera section:** "view 640×360" should be 960×540, and the bounds are wrong.
   - **Recommendation:** regenerate the table from the scene.
5. **Turnstile dividers: the player cannot bypass the gate, but a visible partition is needed.**
   - **Probe C:**
     - **Closed gate:** 40 pushes from the west along x = 8 (straight and diagonal, every 0.8 tile, including both wall ends). The furthest point reached is tile x **7.77**, with **no crossing**.
     - **Small gaps:** the gaps between the divider ends and the perimeter, and between the divider and the gate Blocker, are ~4.5 px, smaller than the 12 px capsule.
     - **Open gate:** the opening is passable.
   - **Visibility:** the segments are collision only, across a hall that otherwise reads as open floor (`annotated_arrival_x2.png`: red line). The old room had the same invisible segments, but only 2.5 tiles from the W wall; here they cut a 16-tile hall, so the player will walk into invisible walls on either side of the gate (Appendix D.6 #4, spatial clarity).
   - **Recommendation:** place the existing `ch01_env_wall_partition_low_e_idle.png` (32×32, pivot (16,24), a 2-tile low_E run ≤ 20 px tall, ASSET_METADATA §10.2) along both segments, with an end piece at the gate. It is the same orientation as a low E edge and does not hide actors or the gate. It is new dressing, so rule 6 ("no new objects") needs the Lead's OK; Sol should check the end pieces against the turnstile.

## 6. Other observations

- **Tactile band (item 3):**
  - **Where it is:** floor cells (3,4), (3,5) and (3,6) (source 2 tactile) are unchanged, because the builder keeps existing cells. In the old room they marked the turnstile threshold; Sol's Appendix D audit lists "the concourse tactile band leads to the turnstile" as a strength to keep. Now they sit beside the spawn and checkpoint.
  - **Where it should be:** moved with the PZ-001 cluster (+5.5, +3.5 tiles) they would be cells (8,7), (8,8) and (8,9), or wherever Sol puts the threshold.
  - **Also:** the 17 cracked cells also kept their old cells; that is harmless decor.
- **Fallen conduit (item 4):** the spec put the conduit on the W wall at (0.5,11.5), so its fallen state is ~180 px from the gate. PZ-001 hint 2 says "Something fell on the gate … It pins the turnstile". Either the fallen sprite/offset should lie at the gate, or the hint/puzzle reading needs a Lead/Sol decision. Mechanically it works (pinned, then Rewind).
- **Checkpoint:** `checkpoint` (3,8) restores to `safe_anchor_east` (7,8), 4 tiles from the zone, beside the gate. This matches the old design (same anchor), and the test asserts it.
- **AU-08 margin:** from the spawn, the courier (80.0 px) is the only traceable object in range. If the spawn moves 1 tile toward the door (MD2), the courier leaves the 96 px radius and the conduit becomes the fallback target, so keep the spawn where it is.

## Evidence (`TLF-080/f44af6e/`)

- `evidence.txt`: every test-file result, the probe output, the Python run and the runner-argument check.
- `mutations_080.log`, produced by `mutate_080.py.txt`.
- Probe scripts `probe_ab/b2/c/d/ef.gd.txt`. Probe ab's test_b result is superseded by b2, as noted in the file.
- `annotated_arrival_x2.png`: Flash's arrival screenshot ×2, with the invisible dividers, the gate, the tactile cells and the conduit marked.
- **Not done:** the full validate (a single Godot call exceeds the 120 s cap; the Lead runs it); visual review of facing (Sol).
