# TLF-085 Handoff Report: Maintenance Bay v2 Rebuild (Round 2)

**Task:** TLF-085 (P0) — Bangun ulang ruangan `ch01.maintenance_bay` (Maintenance Bay v2)  
**Implementer:** Flash (`adityadaffa522`)  
**Base Commit:** `origin/main` (`f7649fd`) + `origin/lead/tlf-085-r2` (`b191fe9`)  
**Branch:** `adityadaffa522/tlf-085-maintenance-v2`  
**Status:** COMPLETE (All Reviews Addressed — Full Suite Validated 0 Failed / 0 SCRIPT ERROR)

---

## 1. Executive Summary & Round 2 Revisions

This handoff delivers the revised Maintenance Bay v2 room (`scenes/chapters/ch01/rooms/maintenance_bay.tscn`) addressing all items from the Opus technical review (`TLF-085_71bb9ea_OPUS_REVIEW.md`), Fable visual review (`TLF-085_71bb9ea_FABLE_VISUAL.md`), and Lead instructions in `origin/lead/tlf-085-r2`:

1. **P1 Checkpoint at $(5, 5) \implies (320, 144)$:**
   - Checkpoint moved from the arrival spawn $(2, 5)$ to the spec cluster H tile $(5, 5) \implies (320, 144)$.
   - `ROOM_GRAPH.md` checkpoint table updated to $(5, 5)$.
   - Checkpoint save/load test asserts save zone at $(320, 144)$ with `outside` anchor $\ge 1$ tile away, restoring Elias to `safe_anchor_entry` $(336, 136)$.
   - Rigid cluster H assertions in `test_ch01_maintenance_bay_v2.gd` now explicitly guard both `checkpoint` and `safe_anchor_entry`.
2. **26-Wide Room Outline & East Door $(26, 4)$:**
   - Expanded grid from $25 \times 16$ to $26 \times 16$ (416 floor cells) via builder spec.
   - Added 13th North wall module (`WallN_12` at $(720, 264)$), perfectly closing the NE corner without builder gaps.
   - Moved `door_exit_east` and `Archway_door_exit_east` to $(26, 4) \implies (672, 304)$ with child `Spawn` at $(24, 4) \implies (640, 288)$ (local `(-32, -16)`).
   - Builder dry run confirms 0 diff lines against the updated JSON spec.
3. **Fable P1-a Bulkhead Low Partitions:**
   - Swapped `Wall_bulkhead_s0..s5` to low partition art (`ch01_env_wall_partition_low_e_idle.png`, `offset = Vector2(-16, -24)`), unhiding the SO-02 floor items (`hatch_plate_01`, `doc_hatch_chart`, `bell_plate_01`).
   - `Wall_bulkhead_n0` remains tall next to the hatch frame. Bulkhead collision shape and sealing remain completely unchanged.
4. **Fable P1-b W-Face Shutters & Fit Report:**
   - Updated both `fire_shutter` and `inner_shutter` presenters to use `ch01_prop_inner_shutter_closed.png` and `ch01_prop_inner_shutter_raised.png` ($32\times64$ W-face, pivot $(16, 56)$, `offset = Vector2(-16, -56)`).
   - **Fit Report:** Standing along their respective divider lines ($x = 16$ and $x = 19$), the 32×64 W-face textures cleanly align with the low partition ends, covering the 1.5-tile apertures without obscuring Elias in the pocket airlock or overlapping the counterweight gear.
5. **Floor Tiles Alignment:**
   - Shifted 30 industrial-grating cells (source 3) to $x \in [15, 17], y \in [0, 9]$ to align with the active fire shutter and gear bay divider.
   - Shifted 5 cable-conduit cells (source 5) to $(6..10, 4)$ and updated `ConduitPresenter` coordinates accordingly.
   - Remaining 381 cells are `concrete_service` (source 4).
6. **Real-Input Stand Spots Walked from Safe Anchors:**
   - Refactored `test_every_stand_spot_reachable_within_2_6_px` to walk the player capsule with real directional input from safe anchors $\ge 1$ tile away, eliminating artificial teleports to `spot + (2,2)`. All canonical spec spots hold within $\le 2.6\text{ px}$ (or within bounds clearance $\le 4.0\text{ px}$).
7. **Technician Stand Spot & Graph Camera Comment:**
   - Updated `test_ch01_unlock_guards.gd` technician walk target to $(352, 144)$ (matching the spec and real playthrough).
   - Updated camera comment in `tests/spatial/test_ch01_graph.gd` to reflect fixed framing (room fits 960×540 viewport).
8. **Placement Table Corrected:**
   - Fully regenerated placement table directly from scene nodes, correcting all 10 discrepancies identified in Opus section 2.6.
9. **Visual Screenshots:**
   - Captured 6 Forward+ windowed 960×540 screenshots using native D3D12 / Forward+ renderer on NVIDIA GeForce RTX 5060, including dedicated shots of Elias at the gear stand spot $(496, 184)$ and in the pocket at `safe_anchor_east` $(544, 240)$.

---

## 2. Room Geometry & RoomShape

- **Outline:** `[[0, 0], [26, 0], [26, 16], [0, 16]]` (Grid: 26×16 tiles).
- **Floor Bounding Diamond:** $(0, 0) \implies (320, 64)$, $(26, 0) \implies (736, 272)$, $(26, 16) \implies (480, 400)$, $(0, 16) \implies (64, 192)$.
- **Floor Dimensions:** $672 \times 336\text{ px}$.
- **Floor Cells:** 416 tiles on `TileMapLayer_Floor`:
  - 381 cells `concrete_service` (source 4).
  - 30 cells `industrial_grating` (source 3) at $x \in [15, 17], y \in [0, 9]$.
  - 5 cells `cable_conduit` (source 5) at $(6..10, 4)$.
- **Hidden Floor Cells:** Empty (`hidden_floor_cells()` returns `[]`).
- **Metadata:** `metadata/room_shape` resource attached to the scene root with outline coordinates `[[0, 0], [26, 0], [26, 16], [0, 16]]`.
- **Collision Boundary:** `PerimeterWalls` CollisionPolygon2D outset by 0.25 tile:
  `[(320, 60), (744, 272), (480, 404), (56, 192)]`.
- **Wall Modules:** 13 North wall modules (`WallN_0..12`) and 8 West wall modules (`WallW_0..7`).
- **Bulkhead Modules:** 1 tall module (`Wall_bulkhead_n0` at $(416, 128)$) and 6 low partition modules (`Wall_bulkhead_s0..s5` at $y = 5, 7, 9, 11, 13, 15$).
- **Low Partitions on $x = 16$ and $x = 19$:**
  - North run ($y \in [0, 3.25]$): 1 whole module (`n0`) + 1 half module (`n1_half`).
  - South run ($y \in [4.75, 16]$): 1 half module (`s0_half`) + 5 whole modules (`s1..s5`).
  - Total per line: 8 Sprite2Ds (6 whole, 2 halves) with zero new collision bodies.
- **Apertures:** Hatch at $(7, 3)$, fire shutter at $(16, 4)$, and inner shutter at $(19, 4)$ all provide $\ge 1.5$ tiles clear walkable opening.

---

## 3. Builder Dry-Run Diff

Executed via:
```powershell
python tools/content/build_room_from_shape.py --outset 0.25 design/ch01/rooms_v2/maintenance_bay.json scenes/chapters/ch01/rooms/maintenance_bay.tscn
```

Output:
```text
shape: [['0', '0'], ['26', '0'], ['26', '16'], ['0', '16']]
  floor: 416 tiles (416 kept with their tile, 0 new with source 4, 0 removed, 0 holes)
  collision: 4 corners, outset 0.25 tile
  walls: 13 N and 8 W modules
  NOT DRAWN: low_E partition (26, 0) -> (26, 16) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 16) -> (26, 16) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (26, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (26, 16) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 16) (faces low_S/W, TLF-068 kit)
  metadata/room_shape: outline [[0, 0], [26, 0], [26, 16], [0, 16]]
diff: 0 changed line(s) (dry run)
```

The rebuilt scene is 100% compliant with the generator output (0 diff lines).

---

## 4. Canonical Stand Spots & Placement Table

Directly extracted from `scenes/chapters/ch01/rooms/maintenance_bay.tscn`:

| Object ID / Name | Object Tile | Object Pos (px) | Stand Spot Tile | Stand Spot Pos (px) | Approach Side | SO-01 Dist | Clearance / Reach Notes |
|---|---|---|---|---|---|---|---|
| `door_entry_west` | `(0, 5)` | `(240, 104)` | `(2, 5)` | `(272, 120)` | East | 35.8 px | Entry spawn. Player capsule holding L/U/D for 3s never enters doorway aperture. |
| `safe_anchor_entry` | `(5, 4)` | `(336, 136)` | `(5, 4)` | `(336, 136)` | Center | 0.0 px | Pre-bulkhead safe anchor. Restores from checkpoint Continue. |
| `checkpoint` | `(5, 5)` | `(320, 144)` | `(5, 5)` | `(320, 144)` | Center | 0.0 px | Autosave zone at (5, 5). Restores player to `safe_anchor_entry` at (336, 136). |
| `bell_plate_01` | `(5, 8)` | `(272, 168)` | `(5, 8)` | `(272, 168)` | Center | 0.0 px | Decoy alarm plate (SO-02). Stepping on it yields no ability target. |
| `doc_hatch_chart` | `(6, 7)` | `(304, 168)` | `(5, 7)` | `(288, 160)` | West | 17.89 px | Hatch schematic on floor. |
| `hatch_plate_01` | `(6, 6)` | `(320, 160)` | `(6, 6)` | `(320, 160)` | Center | 0.0 px | Weight plate opening `hatch_01`. Stepping on it targets `hatch_01` for Freeze. |
| `hatch_residue` | `(6, 6)` | `(320, 160)` | `(6, 6)` | `(320, 160)` | Center | 0.0 px | Trace residue for hatch memory. |
| `n11_hatch_tech` | `(6, 3)` | `(368, 136)` | `(6, 4)` | `(352, 144)` | South-West | 17.89 px | Technician statue. Tracing unlocks Freeze ability. |
| `hatch_01` | `(7, 3)` | `(384, 144)` | `(7, 4)` | `(368, 152)` | South-West | 17.89 px | SO-02 service hatch in bulkhead $x = 7$. |
| `hatch_threshold` | `(7, 3)` | `(384, 144)` | `(7, 3)` | `(384, 144)` | Center | 0.0 px | Hatch threshold detection zone. |
| `exit_trigger_hatch` | `(8, 3)` | `(400, 152)` | `(8, 3)` | `(400, 152)` | Center | 0.0 px | SO-02 puzzle completion trigger past bulkhead. |
| `safe_anchor_west` | `(13, 4)` | `(464, 200)` | `(13, 4)` | `(464, 200)` | Center | 0.0 px | Gear bay safe anchor. |
| `counterweight_gear` | `(13, 1)` | `(512, 176)` | `(13, 2)` | `(496, 184)` | South | 17.89 px | Counterweight gear on North wall. Also targetable from casting spot $(480, 208)$. |
| `gear_residue` | `(13, 2)` | `(496, 184)` | `(13, 2)` | `(496, 184)` | Center | 0.0 px | Trace residue for gear slippage. Targetable from $(480, 208)$. |
| `reset_anchor_01` | `(12, 6)` | `(416, 208)` | `(11, 6)` | `(400, 216)` | West | 17.89 px | PZ-002 puzzle reset anchor. |
| `doc_tech_log` | `(15, 9)` | `(416, 256)` | `(15, 9)` | `(416, 256)` | Center | 0.0 px | Technician log document on floor. |
| `fire_shutter` | `(16, 4)` | `(512, 224)` | `(15.5, 4.5)` | `(496, 224)` | West | 17.89 px | Fire shutter across $x = 16$. Rewind target from $(480, 208)$ and $(468, 192)$. |
| `shutter_threshold_trigger` | `(16, 4)` | `(512, 224)` | `(16, 4)` | `(512, 224)` | Center | 0.0 px | Shutter 1 threshold trigger. |
| `safe_anchor_east` | `(18, 4)` | `(544, 240)` | `(18, 4)` | `(544, 240)` | Center | 0.0 px | Pocket safe anchor. Targets `inner_shutter` and `counterweight_gear`. |
| `exit_trigger_east` | `(18, 4)` | `(544, 240)` | `(18, 4)` | `(544, 240)` | Center | 0.0 px | Legacy pocket trigger (does not solve PZ-002). |
| `inner_shutter` | `(19, 4)` | `(560, 248)` | `(18, 4)` | `(544, 240)` | West | 17.89 px | Inner shutter across $x = 19$. Rewind target from pocket. |
| `inner_shutter_threshold` | `(19, 4)` | `(560, 248)` | `(19, 4)` | `(560, 248)` | Center | 0.0 px | Inner shutter threshold trigger. |
| `doc_inner_shutter_plate` | `(19, 1)` | `(608, 224)` | `(18, 1)` | `(592, 232)` | West | 17.89 px | Notice plate at inner divider line. Reachable from pocket at $(592, 232)$. |
| `exit_trigger_east_02` | `(20, 4)` | `(576, 256)` | `(20, 4)` | `(576, 256)` | Center | 0.0 px | PZ-002 stage 2 completion trigger. |
| `door_exit_east` | `(26, 4)` | `(672, 304)` | `(24, 4)` | `(640, 288)` | West | 35.8 px | Exit doorway to `ch01.security_crossing`. Spawn at $(24, 4) \implies (640, 288)$. |

---

## 5. Puzzle Cluster & Narrative Invariance

1. **Rigid Cluster Invariance:**
   - **Cluster H (CH1-SO-02):** Shifted $x + 4$ ($+64\text{ px}, +32\text{ px}$). All relative distances between `n11_hatch_tech`, `hatch_plate_01`, `hatch_01`, `bell_plate_01`, `safe_anchor_entry`, `checkpoint`, and `exit_trigger_hatch` remain exact to the sub-pixel.
   - **Cluster BC (CH1-PZ-002):** Shifted $x + 8$ ($+128\text{ px}, +64\text{ px}$). Relative distances between `counterweight_gear`, `fire_shutter`, `inner_shutter`, `reset_anchor_01`, and `exit_trigger_east_02` remain identical to v1.
2. **CH1-SO-02 Lifecycle:**
   - Tracing `n11_hatch_tech` at $(368, 136)$ from stand spot $(352, 144)$ unlocks Freeze.
   - Stepping on `hatch_plate_01` opens `hatch_01`. Stepping off closes it unless Freezed.
   - Decoy `bell_plate_01` does not open the hatch and offers no Freeze target.
   - Walking through frozen open hatch triggers `exit_trigger_hatch` (SO-02 SOLVED).
3. **CH1-PZ-002 Lifecycle & R1 Multi-Stage Geometry:**
   - Rewind raises `fire_shutter` for 180 ticks (300 with assist); only Freezing `counterweight_gear` holds it permanently.
   - Without Freeze, player cannot cross into pocket before shutter closes (`test_ch01_pz002_negative.gd`).
   - `inner_shutter` requires gear frozen (`requires_gear_frozen = true`); otherwise Rewind fails.
   - Entering old pocket trigger `exit_trigger_east` does NOT mark PZ-002 solved. Crossing `exit_trigger_east_02` marks PZ-002 SOLVED.
4. **Checkpoint Save/Restore:**
   - Checkpoint at $(5, 5) \implies (320, 144)$ triggers autosave when reached.
   - Continue restores player to `safe_anchor_entry` at $(336, 136)$ with correct inventory, abilities, and camera centering.

---

## 6. Visual Dressing & Divider Integration

- **Bulkhead ($x = 7$):**
  - North of hatch opening: `Wall_bulkhead_n0` at $(416, 128)$ remains full wall height.
  - South of hatch opening: `Wall_bulkhead_s0..s5` swapped to low partition art (`ch01_env_wall_partition_low_e_idle.png`, `offset = Vector2(-16, -24)`). This completely resolves Fable P1-a, unhiding the floor objects while retaining full physical collision sealing.
- **Fire Shutter ($x = 16$) & Inner Divider ($x = 19$):**
  - Each divider dressed with 8 `ch01_env_wall_partition_low_e_idle.png` sprites:
    - North run: 1 whole + 1 half module at aperture.
    - South run: 1 half module at aperture + 5 whole modules.
- **W-Face Shutter Fit:**
  - `fire_shutter` and `inner_shutter` use `ch01_prop_inner_shutter_closed.png` and `ch01_prop_inner_shutter_raised.png` ($32\times64$ W-face, pivot $(16, 56)$).
  - Standing along the divider line, they neatly fit the 1.5-tile apertures, eliminating the visual obstruction of Elias in the pocket airlock (Fable P1-b).

---

## 7. Room Graph & Camera Bounds Integration

1. **`design/ch01/ROOM_GRAPH.md`:**
   - Updated room 3 entry: Grid $26\times16$ ($672 \times 336\text{ px}$), camera "Fixed `960×540`", doors `(0, 5)` and `(26, 4)`, checkpoint `(5, 5)`.
2. **`data/chapters/ch01/ch01_graph.tres`:**
   - Regenerated via `python tools/content/gen_ch01_graph.py` with width 26 and door `(26, 4)`.
3. **Camera Bounds Clamping:**
   - Explicit room bounds asserted in tests: `Rect2(48, 0, 704, 416)` with whole-pixel center `Vector2(400, 208)`.
   - On the standard 960×540 viewport, the 704×416 room bounds are fully contained within the viewport and smoothly centered without boundary drift.

---

## 8. Verification Results

All tests executed with a strict 120s timeout in isolated scratch environments without touching real player saves:

| Test Suite | Result | Details |
|---|---|---|
| `tests/chapters/ch01/test_ch01_maintenance_bay_v2.gd` | **15 passed, 0 failed** | West door 3s holds, bulkhead sweep ($x=7$), fire shutter sweep ($x=16$), inner divider sweep ($x=19$), 6 mutation checks, stand spots walked from safe anchors $\le 2.6\text{ px}$, explicit camera bounds Rect2(48,0,704,416) & center (400,208), checkpoint save/load at (320,144) restoring to (336,136), rigid cluster H and BC shifts math, and complete real-input lifecycle. |
| `tests/chapters/ch01/test_ch01_concourse_west_v2.gd` | **12 passed, 0 failed** | Concourse West v2 regression suite clean. |
| `tests/chapters/ch01/test_ch01_playthrough.gd` | **19 passed, 0 failed** | Full scripted playthrough, aperture navigation with real capsule, door trigger blockers, spawn offsets, graph alignment. |
| `tests/chapters/ch01/test_ch01_pz002_negative.gd` | **2 passed, 0 failed** | Real-input PZ-002 negative checks (assist on/off: shutter closes and blocks player before east exit without Freeze). |
| `tests/chapters/ch01/test_ch01_sort_order.gd` | **3 passed, 0 failed** | Y-sort order and render manifest validation for Maintenance Bay. |
| `tests/chapters/ch01/test_ch01_step1_negatives.gd` | **12 passed, 0 failed** | SO-02 hatch plate release, bulkhead sealing, decoy plate, and PZ-002 hold window tests. |
| `tests/chapters/ch01/test_ch01_unlock_guards.gd` | **4 passed, 0 failed** | Technician trace at $(352, 144)$, checkpoint autosave at $(320, 144)$, Continue restoration to $(336, 136)$. |
| `tests/chapters/ch01/test_ch01_art_integration.gd` | **6 passed, 0 failed** | Collision fingerprint baseline frozen and verified for all 10 rooms. |
| `tests/rooms/test_room_shape.gd` | **7 passed, 0 failed** | 26x16 grid shape math (416 cells, 13 N-wall modules, corners (25,0) and (25,15)). |
| `tests/spatial/test_ch01_graph.gd` | **9 passed, 0 failed** | Room graph topology and camera framing assertions. |
| `tests/audio/test_audio_real_input.gd` | **2 passed, 0 failed** | Real input audio feedback verification for abilities. |
| `tests/chapters/ch01/test_ch01_real_playthrough.gd` | **1 passed, 0 failed** | Complete 10-room real-input chapter playthrough (walking through $(320, 144)$ checkpoint on entry). |
| `tools/content/test_build_room_from_shape.py` | **22 passed, 0 failed** | Python builder round-trip, 26x16 geometry, door cutting, and LF line ending tests. |
| `tools/validate.ps1` (Full Suite) | **559 passed, 0 failed** | Headless import (0 errors), script parse check (clean), full test suite across all subsystems, clean leak check (0 SCRIPT ERROR). |

---

## 9. Visual Evidence Screenshots

Six Forward+ windowed screenshots (960×540) captured from the live game engine via `tools/capture_maintenance_bay.gd` using native D3D12 / Forward+ renderer on NVIDIA GeForce RTX 5060:

1. **Arrival Platform Entry View:**  
   `docs/handoffs/TLF-085/arrival_960x540.png`  
   *Shows Elias at arrival spawn $(272, 120)$, the spacious entry hall, low partition bulkhead modules along $x = 7$, unhidden SO-02 floor items, and checkpoint at $(320, 144)$.*
2. **Service Hatch View (SO-02):**  
   `docs/handoffs/TLF-085/hatch_960x540.png`  
   *Shows Elias at the open hatch aperture $(384, 144)$, technician statue `n11_hatch_tech` at $(368, 136)$, and tall module `Wall_bulkhead_n0`.*
3. **Gear Bay & Fire Shutter View (PZ-002):**  
   `docs/handoffs/TLF-085/gear_bay_960x540.png`  
   *Shows counterweight gear on North wall at $(512, 176)$, fire shutter along $x = 16$, and dressed low partition dividers.*
4. **Gear Stand Spot View:**  
   `docs/handoffs/TLF-085/gear_stand_spot_960x540.png`  
   *Shows Elias standing at the canonical gear interaction spot $(496, 184)$, clearly visible without being obscured by the shutter.*
5. **Pocket Safe Anchor East View:**  
   `docs/handoffs/TLF-085/pocket_safe_anchor_east_960x540.png`  
   *Shows Elias at `safe_anchor_east` $(544, 240)$, fully visible and unobstructed inside the pocket airlock (resolving Fable P1-b).*
6. **East Doorway & Exit Hall View:**  
   `docs/handoffs/TLF-085/east_door_960x540.png`  
   *Shows the eastern exit hall past the inner shutter, `doc_inner_shutter_plate` on North wall, and doorway `door_exit_east` at $(672, 304)$ with spawn at $(640, 288)$.*

---

## 10. Mutation Check Summary

1. **Door Sweep Mutation Check (`test_mutation_check_sweep_fails_when_stubbed`):**
   West door trigger shape mutated onto walking line at $(258, 120)$. Walking left from spawn immediately triggers premature room transition, proving door sweep catches door encroaching on spawn.
2. **Bulkhead Sweep Mutation Checks (`test_bulkhead_sweep_mutation_fails_when_shape1_disabled` & `test_bulkhead_sweep_mutation_fails_when_shape2_disabled`):**
   Disabling either Bulkhead Shape 1 (north run $y \in [0, 2.5]$) or Shape 2 (south run $y \in [3.5, 16]$) causes bulkhead sweep test to immediately fail (player crosses $x = 7.2$), proving full physical sealing.
3. **Fire Shutter Sweep Mutation Checks (`test_shutter_sweep_mutation_fails_when_divider_north_disabled` & `test_shutter_sweep_mutation_fails_when_divider_south_disabled`):**
   Disabling either `DividerNorth` or `DividerSouth` on $x = 16$ causes fire shutter sweep test to immediately go RED (player crosses $x = 16.2$).
4. **Inner Divider Sweep Mutation Checks (`test_inner_sweep_mutation_fails_when_shape1_disabled` & `test_inner_sweep_mutation_fails_when_shape2_disabled`):**
   Disabling either Shape North or Shape South on $x = 19$ causes inner divider sweep test to immediately go RED (player crosses $x = 19.2$).
