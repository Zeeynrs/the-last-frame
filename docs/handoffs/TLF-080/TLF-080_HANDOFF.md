# TLF-080 Handoff Report: Concourse West v2 Rebuild

**Task:** TLF-080 (P0) — Bangun ulang ruangan `ch01.concourse_west` (Concourse West v2)  
**Implementer:** Flash (`adityadaffa522`)  
**Base Commit:** `origin/main` (`f21aef6`)  
**Branch:** `adityadaffa522/tlf-080-concourse-v2`  
**Status:** COMPLETE (Ready for Lead Validation)

---

## 1. Executive Summary

This handoff delivers the complete rebuild of `scenes/chapters/ch01/rooms/concourse_west.tscn` from the legacy cramped 16×12 rectangular layout (192 floor cells) to the approved Concourse West v2 28×16 layout (448 floor cells, 2.33× expansion) with `RoomCamera` following and bounding per ADR-023, `design/ch01/rooms_v2/concourse_west.md`, and `design/ch01/rooms_v2/PATTERN.md`.

All three primary owner complaints have been resolved:
1. **Ruangan Sempit:** Rebuilt from 16×12 (192 cells, entry strip only 2.5 tiles) into a spacious 28×16 hall (448 cells) with an 8-tile entry hall ($x \in [0, 8]$) west of the turnstile dividing line at $x = 8$, providing natural breathing room and clear sightlines.
2. **Pintu Masuk Terlalu Dekat ke Spawn:** In v1, `door_entry_west` was at $(0.5, 4.5)$ and spawn was at $(1.5, 4.5)$ (1 tile away), causing leftward movement from spawn to immediately re-trigger the west entrance. In v2, the entrance aperture is moved to tile $(0, 8) \implies (192, 128)$, spawn is placed at tile $(2, 8) \implies (224, 144)$ (2 tiles east), and the door aperture trigger shape is a precise circle (`radius = 6.0`, offset `(-4, -2)`). Player capsule holding Left, Up, or Down for 3 full seconds from spawn never enters `door_entry_west`.
3. **Props Menghadap Layar Bukan Menempel Dinding:** Replaced the frontal digital clock with the sheared N-face variant (`assets/props/ch01/ch01_prop_digital_clock_2359_n_idle.png`) flush against the North wall at $(480, 99)$. Unmerged 13 wall art PNGs from `origin/adityadaffa522/tlf-081-concourse-wall-art-sol` remain old art placeholders as instructed (documented in Section 6 below).

Zero new narrative text, zero new object IDs, and zero custom lighting were introduced.

---

## 2. Room Geometry & RoomShape

- **Outline:** `[[0, 0], [28, 0], [28, 16], [0, 16]]` (Grid: 28×16 tiles).
- **Pixel Dimensions:** 896 × 328 px.
- **Floor Cells:** 448 tiles on `TileMapLayer_Floor` (source 0 `terrazzo_dark`).
- **Hidden Floor Cells:** Empty (`hidden_floor_cells()` returns `[]`).
- **Metadata:** `metadata/room_shape` resource attached to the scene root with outline coordinates.
- **Collision Boundary:** `PerimeterWalls` CollisionPolygon2D outset by 0.25 tile:
  `[(736, 172), (288, -52), (160, 204), (608, 428)]`.
- **Wall Modules:** 14 North wall modules (`WallN_0` to `WallN_13`) and 8 West wall modules (`WallW_0` to `WallW_7`).
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

All stand spots were placed according to the SO-01 interaction rule ($17.89\text{ px}$ offset from object center) and verified with the real player capsule to be reachable within $\le 2.6\text{ px}$:

| Object ID / Name | Object Tile | Object Pos (px) | Stand Spot Tile | Stand Spot Pos (px) | Approach Side | SO-01 Dist | Clearance / Notes |
|---|---|---|---|---|---|---|---|
| `door_entry_west` | `(0, 8)` | `(192, 128)` | `(2, 8)` | `(224, 144)` | East | 35.8 px | Entry spawn. Capsule holding L/U/D never triggers aperture. |
| `checkpoint` | `(3, 8)` | `(240, 152)` | `(3, 8)` | `(240, 152)` | Center | 0.0 px | Autosave zone $x \in [226, 254], y \in [144, 160]$. Restores to `safe_anchor_east`. |
| `call_box_09` | `(5, 5)` | `(288, 104)` | `(5.5, 6)` | `(280, 100)` | South | 17.89 px | Mounted on N wall module 3. |
| `conduit_01` | `(0.5, 11.5)` | `(144, 160)` | `(1.5, 11.5)` | `(160, 168)` | East | 17.89 px | Mounted on W wall. Stand spot is reachable floor cell $(1.5, 11.5)$. |
| `doc_ticket_terms` | `(0.5, 15)` | `(88, 188)` | `(1.5, 15)` | `(104, 196)` | East | 17.89 px | Plaque mounted on W wall. Opens document viewer. |
| `safe_anchor_east` | `(7, 8)` | `(304, 184)` | `(7, 8)` | `(304, 184)` | Center | 0.0 px | Pre-turnstile safe anchor. |
| `turnstile_gate` | `(8, 8)` | `(320, 192)` | `(7.5, 8.5)` | `(298, 198)` | West | 17.89 px | Turnstile divider line at $x = 8$. |
| `turnstile_trace_anchor` | `(7.5, 8.5)` | `(312, 188)` | `(7.5, 8.5)` | `(312, 188)` | Center | 0.0 px | Trace anchor for falling conduit memory. |
| `safe_anchor_west` | `(10, 8)` | `(352, 208)` | `(10, 8)` | `(352, 208)` | Center | 0.0 px | Post-turnstile safe anchor & exit trigger for PZ-001. |
| `exit_trigger_concourse`| `(10, 8)` | `(352, 208)` | `(10, 8)` | `(352, 208)` | Center | 0.0 px | Completion trigger for PZ-001. |
| `ConcourseBench` | `(13, 2)` | `(496, 184)` | `(14, 3)` | `(496, 200)` | South | 17.89 px | Bench against North wall. |
| `digital_clock_2359` | `(12.5, 0.5)` | `(496, 152)` | `(12.5, 0.5)` | `(496, 152)` | South | 17.89 px | Visual at $(480, 99)$ flush on N wall. |
| `support_pillar_01` | `(17, 11)` | `(416, 288)` | `(16, 10)` | `(416, 272)` | North | 17.89 px | Pillar with circular collision. Detour south of walking line. |
| `doc_evac_notice` | `(16, 10)` | `(416, 272)` | `(16, 10)` | `(416, 272)` | North | 0.0 px | Notice mounted on north side of support pillar. |
| `reset_anchor_01` | `(11, 8)` | `(368, 216)` | `(11, 8)` | `(368, 216)` | Center | 0.0 px | PZ-001 puzzle reset anchor. |
| `reset_anchor_02` | `(22, 6)` | `(544, 200)` | `(22, 6)` | `(544, 200)` | Center | 0.0 px | PZ-006 puzzle reset anchor. |
| `dial_line` | `(23, 5)` | `(560, 192)` | `(23, 6)` | `(544, 200)` | South-West | 17.89 px | History Dial 1. |
| `dial_platform` | `(25, 5)` | `(592, 208)` | `(25, 6)` | `(576, 216)` | South-West | 17.89 px | History Dial 2. |
| `dial_time` | `(27, 5)` | `(624, 224)` | `(27, 6)` | `(608, 232)` | South-West | 17.89 px | History Dial 3. |
| `ticket_validator` | `(27, 7)` | `(608, 248)` | `(27, 7)` | `(608, 248)` | Center | 0.0 px | PZ-006 completion object. |
| `n05_courier` | `(6, 10)` | `(288, 192)` | `(2, 8)` | `(224, 144)` | Arrival | 80.0 px | Auto-targeted by Trace from arrival spawn; unlocks Rewind. |
| `n06_red_coat` | `(22.5, 9.5)`| `(528, 320)` | `(23, 10)` | `(544, 328)` | South-East | 17.89 px | Commuter queue statue 1. |
| `n07_briefcase`| `(22.5, 11.5)`| `(496, 336)` | `(23, 12)` | `(512, 344)` | South-East | 17.89 px | Commuter queue statue 2. |
| `n08_father` | `(22.5, 13.5)`| `(464, 352)` | `(23, 14)` | `(480, 360)` | South-East | 17.89 px | Commuter queue statue 3 (waypoint at $(452, 366)$). |
| `n09_teen` | `(20.5, 12.5)`| `(448, 328)` | `(20, 13)` | `(432, 336)` | South-West | 17.89 px | Commuter queue statue 4. |
| `staff_door` | `(28, 8)` | `(640, 352)` | `(27, 8)` | `(608, 336)` | West | 35.8 px | Powered door with Blocker static body; holds shut for PZ-006. |
| `door_exit_east` | `(28, 8)` | `(640, 352)` | `(27, 8)` | `(608, 336)` | West | 35.8 px | Exit doorway to `ch01.maintenance_bay`. |

---

## 5. Puzzle Cluster & Narrative Invariance

1. **CH1-PZ-001 (Turnstile Gate):**
   - Conduit prop on W wall at $(0.5, 11.5) \implies (144, 160)$.
   - Rewind triggers fallen conduit restoration; turnstile gate opens; walking across $x = 10 \implies (352, 208)$ triggers `exit_trigger_concourse` and marks PZ-001 SOLVED.
2. **CH1-PZ-006 (Ticket Validator & History Dials):**
   - Dials shifted rigidly along N wall ($x = 23, 25, 27$).
   - Commuters shifted rigidly as a block by $(+9, +4)$ to stay $\ge 1.5$ tiles south of walking line $y = 8$.
   - Staff door holds shut with 24×24 Blocker until validator is activated with correct dial indices (2, 3, 1).
3. **TEST-AU-08 (Courier Rewind Unlock):**
   - Courier `n05_courier` at $(288, 192)$ is within Trace radius ($80.0\text{ px} \le 96.0\text{ px}$) from arrival spawn $(224, 144)$.
   - Tracing courier successfully sets `ch01.npc.n05.traced` and unlocks the Rewind ability with real collision shapes.
4. **Negatives Preserved:**
   - PZ-001 gate pinned test holds.
   - PZ-006 staff door holds against 300-tick player walk attempts when closed.

---

## 6. Art Asset Audit & TLF-081 Placeholder Tracking

Per task instructions, no new artwork was hand-drawn:
- **Digital Clock 23:59:** Replaced the frontal sprite with the existing sheared N-face asset `res://assets/props/ch01/ch01_prop_digital_clock_2359_n_idle.png` at position `Vector2(480, 99)`, flush with `WallN_4`.
- **TLF-081 Concourse Wall Art:** The 13 new wall art variant PNGs developed under `origin/adityadaffa522/tlf-081-concourse-wall-art-sol` are not yet merged to `main`. Concourse West v2 continues using the existing standard subterranean wall textures (`ch01_env_wall_subterranean_n_idle.png` and `ch01_env_wall_subterranean_w_idle.png`) as placeholders. When TLF-081 lands on `main`, the wall module textures can be updated directly without moving any collision or object anchors.

---

## 7. Room Graph & Camera Bounds Integration

1. **`design/ch01/ROOM_GRAPH.md`:**
   - Updated lines 34, 53, 83–84, and 208 to document `concourse_west` grid 28×16, doors at $(0, 8)$ and $(28, 8)$, safe anchors at $(7, 8)$ and $(10, 8)$, and checkpoint at $(3, 8)$.
2. **`data/chapters/ch01/ch01_graph.tres`:**
   - Regenerated via `python tools/content/gen_ch01_graph.py`.
3. **Camera Bounds Clamping:**
   - Verified that `RoomCamera` properly calculates bounds from `metadata/room_shape` ($[160, -52] \to [736, 428]$).
   - Camera center is whole-pixel aligned and view rectangle ($640\times 360$) is strictly clamped within room boundaries at arrival, gate, dials, and east door.

---

## 8. Verification Results

All tests executed with a strict 120s timeout in isolated scratch environments without touching real player saves:

| Test Suite | Result | Details |
|---|---|---|
| `tests/chapters/ch01/test_ch01_concourse_west_v2.gd` | **7 passed, 0 failed** | Door sweep (L/U/D 3s holds), closed staff door guard, 19 stand spots reachable $\le 2.6\text{ px}$, camera clamping, checkpoint save/load, AU-08 rewind unlock, mutation check. |
| `tests/spatial/test_ch01_graph.gd` | **9 passed, 0 failed** | Graph connectivity, boundary door positions ($x = 28$ allowed for east boundary). |
| `tests/chapters/ch01/test_ch01_playthrough.gd` | **19 passed, 0 failed** | Scripted playthrough across all 10 rooms, doorway coordinates, safe anchors, checkpoints. |
| `tests/chapters/ch01/test_ch01_sort_order.gd` | **3 passed, 0 failed** | Y-sort order and render manifest validation for Concourse West. |
| `tests/chapters/ch01/test_ch01_step1_negatives.gd` | **12 passed, 0 failed** | PZ-001 pinned gate, PZ-006 staff door 300-tick hold. |
| `tests/chapters/ch01/test_ch01_art_integration.gd` | **6 passed, 0 failed** | Collision fingerprint baseline frozen and verified for all 10 rooms. |
| `tests/chapters/ch01/test_ch01_real_playthrough.gd` | **1 passed, 0 failed** | Complete 10-room real-input chapter playthrough (3862 physics frames, 8 puzzles, 3 abilities). |
| `tools/content/test_build_room_from_shape.py` | **22 passed, 0 failed** | Python builder round-trip and door cutting tests. |

---

## 9. Visual Evidence Screenshots

Four Forward+ windowed screenshots (960×540) captured from the live game engine via `tools/capture_concourse_v2.gd` using D3D12 Forward+ on NVIDIA GeForce RTX 5060:

1. **Arrival Platform Entry View:**  
   `docs/handoffs/TLF-080/arrival_960x540.png`  
   *Shows Elias at spawn $(224, 144)$, the 8-tile spacious entrance hall, conduit on West wall, and clear corridor to turnstile.*
2. **Turnstile Dividing Line View:**  
   `docs/handoffs/TLF-080/gate_960x540.png`  
   *Shows turnstile gate at $x = 8$, safe anchor east, and unobstructed passage.*
3. **History Dials & Validator View:**  
   `docs/handoffs/TLF-080/dial_960x540.png`  
   *Shows history dials along North wall, sheared N-face digital clock flush against wall, and ticket validator.*
4. **East Doorway & Commuter Queue View:**  
   `docs/handoffs/TLF-080/east_door_960x540.png`  
   *Shows commuter queue statues shifted $\ge 1.5$ tiles south of main walking aisle and exit doorway to maintenance bay.*

---

## 10. Mutation Check Summary

In `test_mutation_check_sweep_fails_when_stubbed`, the door trigger was mutated by moving it onto the player's walking line at $(210, 144)$. Walking left from spawn immediately triggered room transition out of concourse, confirming that the door sweep test is sensitive and fails when behavior is stubbed or regressed.
