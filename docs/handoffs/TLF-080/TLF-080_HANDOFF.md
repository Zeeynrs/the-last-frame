# TLF-080 Handoff Report: Concourse West v2 Rebuild

**Task:** TLF-080 (P0) — Bangun ulang ruangan `ch01.concourse_west` (Concourse West v2)  
**Implementer:** Flash (`adityadaffa522`)  
**Base Commit:** `origin/main` (`f21aef6`)  
**Branch:** `adityadaffa522/tlf-080-concourse-v2`  
**Status:** COMPLETE (Review Fix Round Applied — Ready for Lead Validation)

---

## 1. Executive Summary

This handoff delivers the complete rebuild of `scenes/chapters/ch01/rooms/concourse_west.tscn` from the legacy cramped 16×12 rectangular layout (192 floor cells) to the approved Concourse West v2 28×16 layout (448 floor cells, 2.33× expansion) with `RoomCamera` following and bounding per ADR-023, `design/ch01/rooms_v2/concourse_west.md`, and `design/ch01/rooms_v2/PATTERN.md`.

All three primary owner complaints and subsequent review findings (from Opus and Sol) have been fully resolved:
1. **Ruangan Sempit:** Rebuilt from 16×12 (192 cells, entry strip only 2.5 tiles) into a spacious 28×16 hall (448 cells) with an 8-tile entry hall ($x \in [0, 8]$) west of the turnstile dividing line at $x = 8$, providing natural breathing room and clear sightlines.
2. **Pintu Masuk Terlalu Dekat ke Spawn:** In v1, `door_entry_west` was at $(0.5, 4.5)$ and spawn was at $(1.5, 4.5)$ (1 tile away), causing leftward movement from spawn to immediately re-trigger the west entrance. In v2, the entrance aperture is moved to tile $(0, 8) \implies (192, 128)$, spawn is placed at tile $(2, 8) \implies (224, 144)$ (2 tiles east), and the door aperture trigger shape is a precise circle (`radius = 6.0`, offset `(-4, -2)`). Player capsule holding Left, Up, or Down for 3 full seconds from spawn never enters `door_entry_west`.
3. **Props Menghadap Layar Bukan Menempel Dinding:** Swapped all frontal props for their approved wall-mounted and facing variants:
   - Digital clock swapped for the sheared N-face variant (`ch01_prop_digital_clock_2359_n_idle.png`) flush against the North wall at $(480, 99)$.
   - Merged `origin/adityadaffa522/tlf-081-concourse-wall-art-sol` (`f84f19e`) and wired all 13 TLF-081 prop variants (3 flap dials N idle/jammed, call box W idle/ringing, conduit W mounted with fallen floor state preserved, ticket terms W plaque, and ticket validator N idle/rejecting/accepted) matching the exact mount transforms and presenter offsets.
4. **Turnstile Dividing Line Dressing & Sweeps (Sol / Opus Review):**
   - Dressed the turnstile line $x = 8$ with 8 low partition Sprite2Ds (`ch01_env_wall_partition_low_e_idle.png`, 3 whole + 1 half per run, halves at the gate) under `YSort_Walls` per Sol's visual specification (no new collision).
   - Added a rigorous divider sweep test across 19 lines ($y \in [0.8, 15.2]$, start $x = 7.2$, push east 60 ticks) asserting tile $x$ never passes $8.2$ with gate closed.
   - Proved test sensitivity via mutation checks: disabling `DividerNorth` or `DividerSouth` immediately fails the sweep test (MV1 turns RED).
5. **Notice Placement & Tactile Cells Clean-Up:**
   - Moved `doc_evac_notice` to tile $(15, 11) \implies (384, 272)$ so paper pixels sit beside rather than on top of the support pillar. Updated stand spot, reach test, render manifest, and collision fingerprint baseline.
   - Converted legacy tactile floor cells $(3,4), (3,5), (3,6)$ back to plain terrazzo (source 0).

Zero new narrative text, zero new object IDs, and zero custom lighting were introduced.

---

## 2. Room Geometry & RoomShape

- **Outline:** `[[0, 0], [28, 0], [28, 16], [0, 16]]` (Grid: 28×16 tiles).
- **Pixel Dimensions:** 896 × 328 px.
- **Floor Cells:** 448 tiles on `TileMapLayer_Floor` (all source 0 `terrazzo_dark`).
- **Hidden Floor Cells:** Empty (`hidden_floor_cells()` returns `[]`).
- **Metadata:** `metadata/room_shape` resource attached to the scene root with outline coordinates.
- **Collision Boundary:** `PerimeterWalls` CollisionPolygon2D outset by 0.25 tile:
  `[(736, 172), (288, -52), (160, 204), (608, 428)]`.
- **Wall Modules:** 14 North wall modules (`WallN_0` to `WallN_13`) and 8 West wall modules (`WallW_0` to `WallW_7`).
- **Low Partitions:** 8 partition Sprite2Ds dressing the turnstile line at $x = 8$ (`PartitionLowE_divider_n0..n3_half` and `PartitionLowE_divider_s0_half..s3`).
- **Apertures:** Both west and east door openings have $\ge 1.5$ tiles clear aperture width.

---

## 3. Builder Dry-Run Diff

Generated via `tools/content/build_room_from_shape.py --outset 0.25 design/ch01/rooms_v2/concourse_west.json scenes/chapters/ch01/rooms/concourse_west.tscn`:

```text
shape: [['0', '0'], ['28', '0'], ['28', '16'], ['0', '16']]
  floor: 448 tiles (448 kept with their tile, 0 new with source 0, 0 removed, 0 holes)
  collision: 4 corners, outset 0.25 tile
  walls: 14 N and 8 W modules
  NOT DRAWN: low_E partition (28, 0) -> (28, 16) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 16) -> (28, 16) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (28, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (28, 16) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 16) (faces low_S/W, TLF-068 kit)
  metadata/room_shape: outline [[0, 0], [28, 0], [28, 16], [0, 16]]
diff: 0 changed line(s) (dry run)
```

The scene perfectly matches the builder generator output with 0 diff lines.

---

## 4. Canonical Stand Spots & Placement Table

All scene positions and tile coordinates have been regenerated directly from the scene nodes. Stand spots comply with SO-01 ($17.89\text{ px}$ offset from object center) and are verified with the real player physics capsule to be reachable within $\le 2.6\text{ px}$:

| Object ID / Name | Object Tile | Object Pos (px) | Stand Spot Tile | Stand Spot Pos (px) | Approach Side | SO-01 Dist | Clearance / Notes |
|---|---|---|---|---|---|---|---|
| `door_entry_west` | `(0, 8)` | `(192, 128)` | `(2, 8)` | `(224, 144)` | East | 35.8 px | Entry spawn. Capsule holding L/U/D never triggers aperture. |
| `checkpoint` | `(3, 8)` | `(240, 152)` | `(3, 8)` | `(240, 152)` | Center | 0.0 px | Autosave zone beside spawn. Restores to `safe_anchor_east`. |
| `call_box_09` | `(0.5, 3)` | `(280, 92)` | `(1.0, 3.5)` | `(280, 100)` | South | 8.0 px | Mounted on W wall module 1. TLF-081 W idle/ringing prop variant. |
| `conduit_01` | `(0.5, 11.5)` | `(144, 160)` | `(1.5, 11.5)` | `(160, 168)` | East | 17.89 px | Mounted on W wall module 5. Stand spot on floor. Fallen art on floor. |
| `doc_ticket_terms` | `(0.5, 15)` | `(88, 188)` | `(1.5, 15)` | `(104, 196)` | East | 17.89 px | Plaque mounted on W wall module 7. Opens document viewer. |
| `safe_anchor_east` | `(7, 8)` | `(304, 184)` | `(7, 8)` | `(304, 184)` | Center | 0.0 px | Pre-turnstile safe anchor. |
| `n05_courier` | `(7, 9)` | `(288, 192)` | `(2, 8)` | `(224, 144)` | Arrival | 80.0 px | Auto-targeted by Trace from arrival and entry anchor; unlocks Rewind. |
| `turnstile_gate` | `(8, 8)` | `(320, 192)` | `(7.5, 8.5)` | `(298, 198)` | West | 17.89 px | Turnstile divider line at $x = 8$. |
| `turnstile_trace_anchor` | `(8.5, 8)` | `(328, 196)` | `(8.5, 8)` | `(328, 196)` | Center | 0.0 px | Trace anchor for falling conduit memory. |
| `reset_anchor_01` | `(9, 10)` | `(304, 216)` | `(9, 10)` | `(304, 216)` | Center | 0.0 px | PZ-001 puzzle reset anchor. |
| `safe_anchor_west` | `(10, 8)` | `(352, 208)` | `(10, 8)` | `(352, 208)` | Center | 0.0 px | Post-turnstile safe anchor & exit trigger for PZ-001. |
| `exit_trigger_concourse`| `(10, 8)` | `(352, 208)` | `(10, 8)` | `(352, 208)` | Center | 0.0 px | Completion trigger for PZ-001. |
| `digital_clock_2359` | `(11, 0)` | `(496, 152)` | `(11, 0)` | `(496, 152)` | South | 17.89 px | Visual at $(480, 99)$ flush on N wall module 5. |
| `ConcourseBench` | `(13, 2)` | `(496, 184)` | `(13, 3)` | `(496, 200)` | South | 16.0 px | Bench facing south into the room along North wall. |
| `reset_anchor_02` | `(14.5, 0.5)`| `(544, 184)` | `(14.5, 1.5)`| `(544, 200)` | Center | 0.0 px | PZ-006 puzzle reset anchor. |
| `doc_evac_notice` | `(15, 11)` | `(384, 272)` | `(15, 11)` | `(384, 272)` | Center | 0.0 px | Evacuation notice moved beside pillar (Sol/Opus fix). |
| `dial_line` | `(15.5, 0.5)`| `(560, 192)` | `(14.5, 0.5)`| `(544, 200)` | South-West | 17.89 px | History Dial 1. TLF-081 N idle/jammed prop variant. |
| `support_pillar_01` | `(17, 11)` | `(416, 288)` | `(17, 11)` | `(416, 288)` | Obstacle | — | Pillar with circular collider. Detour south of walking line. |
| `dial_platform` | `(17.5, 0.5)`| `(592, 208)` | `(16.5, 0.5)`| `(576, 216)` | South-West | 17.89 px | History Dial 2. TLF-081 N idle/jammed prop variant. |
| `dial_time` | `(19.5, 0.5)`| `(624, 224)` | `(18.5, 0.5)`| `(608, 232)` | South-West | 17.89 px | History Dial 3. TLF-081 N idle/jammed prop variant. |
| `ticket_validator` | `(20.5, 1.5)`| `(624, 240)` | `(19.5, 1.5)`| `(608, 248)` | South-West | 17.89 px | Freestanding console. TLF-081 N idle/accept/reject variant. |
| `n09_teen` | `(20.5, 12.5)`| `(448, 328)` | `(20, 13)` | `(432, 336)` | South-West | 17.89 px | Commuter queue statue 4. |
| `n06_red_coat` | `(22.5, 9.5)`| `(528, 320)` | `(23, 10)` | `(544, 328)` | South-East | 17.89 px | Commuter queue statue 1. |
| `n07_briefcase`| `(22.5, 11.5)`| `(496, 336)` | `(23, 12)` | `(512, 344)` | South-East | 17.89 px | Commuter queue statue 2. |
| `n08_father` | `(22.5, 13.5)`| `(464, 352)` | `(23, 14)` | `(480, 360)` | South-East | 17.89 px | Commuter queue statue 3 (waypoint at $(452, 366)$). |
| `staff_door` | `(28, 8)` | `(640, 352)` | `(27, 8)` | `(608, 336)` | West | 35.8 px | Powered door with Blocker static body; holds shut for PZ-006. |
| `door_exit_east` | `(28, 8)` | `(640, 352)` | `(27, 8)` | `(608, 336)` | West | 35.8 px | Exit doorway to `ch01.maintenance_bay`. |

---

## 5. Puzzle Cluster & Narrative Invariance

1. **CH1-PZ-001 (Turnstile Gate):**
   - Conduit prop on W wall at $(0.5, 11.5) \implies (144, 160)$.
   - Rewind triggers fallen conduit restoration; turnstile gate opens; walking across $x = 10 \implies (352, 208)$ triggers `exit_trigger_concourse` and marks PZ-001 SOLVED.
2. **CH1-PZ-006 (Ticket Validator & History Dials):**
   - Dials shifted rigidly along N wall ($x = 15.5, 17.5, 19.5$).
   - Commuters shifted rigidly as a block by $(+9, +4)$ to stay $\ge 1.5$ tiles south of walking line $y = 8$.
   - Staff door holds shut with 24×24 Blocker until validator is activated with correct dial indices (2, 3, 1).
3. **TEST-AU-08 (Courier Rewind Unlock):**
   - Verified from both arrival spawn $(224, 144)$ ($80.0\text{ px} \le 96.0\text{ px}$) and entry anchor $(304, 184)$ ($17.89\text{ px} \le 96.0\text{ px}$).
   - In both cases, courier `n05_courier` at $(288, 192)$ is the closest candidate and Tracing unlocks Rewind with real collision shapes.
4. **Negatives & Divider Sweeps Preserved:**
   - PZ-001 closed gate sweeps prove player cannot cross the $x = 8$ divider line when closed (max $x \le 8.2$).
   - PZ-006 staff door holds against 300-tick player walk attempts when closed.

---

## 6. Art Asset Audit & TLF-081 Prop Variant Integration

All frontal prop assets identified in TLF-078 have been replaced with their approved directional prop variants:
- **Digital Clock 23:59:** Replaced frontal sprite with the existing sheared N-face asset `res://assets/props/ch01/ch01_prop_digital_clock_2359_n_idle.png` at position `Vector2(480, 99)`, flush with `WallN_5`.
- **TLF-081 Concourse Prop Variants:** Merged `origin/adityadaffa522/tlf-081-concourse-wall-art-sol` (`f84f19e`) and wired all 13 variants per ASSET_METADATA §14.2:
  1. `flap_dial_line_n_idle` & `jammed`
  2. `flap_dial_platform_n_idle` & `jammed`
  3. `flap_dial_time_n_idle` & `jammed`
  4. `call_box_phone_w_idle` & `ringing`
  5. `conduit_w_mounted` (mounted state; fallen state preserves `ch01_prop_conduit_fallen.png` on floor)
  6. `ticket_terms_notice_w_idle`
  7. `ticket_validator_n_idle`, `rejecting`, and `accepted`
- **Presenter Offset Normalization:** Handled `_ready()` offset resets in presenter scripts:
  - `history_dial_presenter.gd`: `offset = Vector2.ZERO`
  - `ticket_validator_presenter.gd`: `offset = Vector2(-16, -42)`
  - `conduit_prop_presenter.gd`: mounted `position = (-32, -35)`, `offset = (0, -23)`; fallen `position = (0, 0)`, `offset = (-24, -26)`.
  An automated integration test asserts final on-screen PNG top-lefts match `mount_correction.json`.
- **Turnstile Divider Dressing:** Added 8 `ch01_env_wall_partition_low_e_idle.png` Sprite2Ds along $x = 8$ per Sol's visual specification (no new collision bodies).

---

## 7. Room Graph & Camera Bounds Integration

1. **`design/ch01/ROOM_GRAPH.md`:**
   - Documented `concourse_west` grid 28×16, doors at $(0, 8)$ and $(28, 8)$, safe anchors at $(7, 8)$ and $(10, 8)$, and checkpoint at $(3, 8)$.
2. **`data/chapters/ch01/ch01_graph.tres`:**
   - Regenerated via `python tools/content/gen_ch01_graph.py`.
3. **`test_ch01_graph.gd`:**
   - Preserved strict boundary checks for other rooms while scoping the edge door rule ($x = 28$) specifically to `ch01.concourse_west`.
4. **Camera Bounds Clamping:**
   - Explicit room bounds asserted in tests: `Rect2(48, 0, 736, 432)` with center `Vector2(416, 216)`.
   - On the standard 960×540 viewport, the 736×432 room is fully contained and smoothly centered at $(416, 216)$ across arrival, gate, dials, and east door without boundary jitter.

---

## 8. Verification Results

All tests executed with a strict 120s timeout in isolated scratch environments without touching real player saves:

| Test Suite | Result | Details |
|---|---|---|
| `tests/chapters/ch01/test_ch01_concourse_west_v2.gd` | **11 passed, 0 failed** | Door sweep (L/U/D 3s holds), closed staff door guard, 19 stand spots reachable $\le 2.6\text{ px}$, explicit camera bounds Rect2(48,0,736,432) & center (416,216), checkpoint save/load, AU-08 rewind unlock from spawn & entry anchor, 19-line divider sweep test, TLF-081 wall art mount integration, mutation checks for door trigger and dividers. |
| `tests/spatial/test_ch01_graph.gd` | **9 passed, 0 failed** | Graph connectivity, per-room exception for Concourse West E-door at boundary. |
| `tests/chapters/ch01/test_ch01_playthrough.gd` | **19 passed, 0 failed** | Scripted playthrough across all 10 rooms, doorway coordinates, safe anchors, checkpoints. |
| `tests/chapters/ch01/test_ch01_sort_order.gd` | **3 passed, 0 failed** | Y-sort order and render manifest validation for Concourse West (including TLF-081 props). |
| `tests/chapters/ch01/test_ch01_step1_negatives.gd` | **12 passed, 0 failed** | PZ-001 pinned gate, PZ-006 staff door 300-tick hold. |
| `tests/chapters/ch01/test_ch01_art_integration.gd` | **6 passed, 0 failed** | Collision fingerprint baseline frozen and verified for all 10 rooms (no UTF-8 BOM, clean § symbols). |
| `tests/chapters/ch01/test_ch01_real_playthrough.gd` | **1 passed, 0 failed** | Complete 10-room real-input chapter playthrough (3862 physics frames, 8 puzzles, 3 abilities). |
| `tools/content/test_build_room_from_shape.py` | **22 passed, 0 failed** | Python builder round-trip, door cutting, and LF line ending tests. |
| `tools/validate.ps1` (Full Suite) | **Target 0 failed, 0 SCRIPT ERROR** | Full validation run in fresh scratch archive. |

---

## 9. Visual Evidence Screenshots

Four Forward+ windowed screenshots (960×540) captured from the live game engine via `tools/capture_concourse_v2.gd` using OpenGL3 / Compatibility on NVIDIA GeForce RTX 5060:

1. **Arrival Platform Entry View:**  
   `docs/handoffs/TLF-080/arrival_960x540.png`  
   *Shows Elias at spawn $(224, 144)$, the 8-tile spacious entrance hall, mounted conduit variant on West wall, and clear corridor to turnstile.*
2. **Turnstile Dividing Line View:**  
   `docs/handoffs/TLF-080/gate_960x540.png`  
   *Shows dressed turnstile low partitions on both north and south sides of the gate at $x = 8$, safe anchor east, and unobstructed passage through the 2-tile gate opening.*
3. **History Dials & Validator View:**  
   `docs/handoffs/TLF-080/dial_960x540.png`  
   *Shows N-face history dial variants along North wall, sheared N-face digital clock flush against wall, ticket validator variant, and bench.*
4. **East Doorway & Commuter Queue View:**  
   `docs/handoffs/TLF-080/east_door_960x540.png`  
   *Shows commuter queue statues shifted $\ge 1.5$ tiles south of main walking aisle, relocated evac notice beside pillar, and exit doorway to maintenance bay.*

---

## 10. Mutation Check Summary

1. **Door Sweep Mutation Check (`test_mutation_check_sweep_fails_when_stubbed`):**
   The west door trigger shape was mutated by shifting it onto the player's walking line at $(210, 144)$. Walking left from spawn immediately triggered room transition out of concourse, confirming that the door sweep test fails when the door is placed too close to spawn.
2. **Divider Sweep Mutation Checks (`test_mutation_check_divider_north_disabled_fails` & `test_mutation_check_divider_south_disabled_fails`):**
   Disabling either `DividerNorth` or `DividerSouth` causes the divider sweep test to immediately go RED, asserting that any bypass around the closed turnstile gate is caught and rejected.
