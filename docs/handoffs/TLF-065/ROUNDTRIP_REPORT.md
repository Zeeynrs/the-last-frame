# TLF-065 follow-up: round-trip check of `build_room_from_shape.py`

Read-only. Tree: `origin/main` `7e2f5c9`. No scene was modified: every run was a dry run, and the
scene files are unchanged.

## What was run

For each of the 10 rooms, the outline `[[0,0],[W,0],[W,H],[0,H]]` used W × H from
`design/ch01/ROOM_GRAPH.md` §2 and the default `--outset 0`:

```
python tools/content/build_room_from_shape.py shape_<room>.json scenes/chapters/ch01/rooms/<room>.tscn
```

- **Dry-run output:** the raw output of all 10 runs is in `roundtrip/dry_<room>.txt`. Every run exited 0, and none reported an R2 hidden floor tile.
- **Comparison script:** `roundtrip/roundtrip.py` imports the builder's own functions and compares their output with the hand-built scene.
- **What it compares:**
  - floor cells;
  - the perimeter polygon in px and in tile coordinates;
  - the `WallN_*` / `WallW_*` names, positions and properties;
  - the camera bounds and the camera centre for every floor tile;
  - every root `Area2D` and `Marker2D`, measured against both polygons.
- **Reach test:** this is a reach check, not a runtime test. Reach counts the whole-pixel positions where Elias's body overlaps the trigger and still fits inside the collision polygon. The body is the capsule from `Player.tscn`: radius 6, height 16, rotated 90°, at (0, −4).

Run:

```
python roundtrip/roundtrip.py <repo> roundtrip/rooms.txt out.json
```

## Summary per room

| Room | W×H | Floor cells, hand / built | N+W wall modules, hand / built | Polygon corners, hand / built | Collision area in px², hand / built | Camera centre |
|---|---|---|---|---|---|---|
| arrival_platform | 14×10 | 140 / 140, same | 7+5 / 7+5, identical | 6 / 4 | 37976 / 35840 | (320,180), unchanged |
| concourse_west | 16×12 | 192 / 192, same | 8+6 / 8+6, identical | 8 / 4 | 51672 / 49152 | (320,180), unchanged |
| maintenance_bay | 14×10 | 140 / 140, same | 7+5 / 7+5, identical | 8 / 4 | 38008 / 35840 | (320,180), unchanged |
| security_crossing | 16×12 | **180 / 192: +12 new** | 8+6 / 8+6, identical | 8 / 4 | 51640 / 49152 | (320,180), unchanged |
| waiting_lounge | 12×10 | 120 / 120, same | 6+5 / 6+5, identical | 4 / 4 | 32864 / 30720 | (320,180), unchanged |
| signal_control | 16×12 | 192 / 192, same | 8+6 / 8+6, identical | 4 / 4 | 51872 / 49152 | (320,180), unchanged |
| upper_vestibule | 14×14 | 196 / 196, same | 7+7 / 7+7, identical | 4 / 4 | 52896 / 50176 | (320,180), unchanged |
| vestibule_niche | 6×6 | 36 / 36, same | 3+3 / 3+3, identical | 4 / 4 | 10400 / 9216 | (320,180), unchanged |
| station_atrium | 16×14 | 224 / 224, same | 8+7 / 8+7, identical | 4 / 4 | 60256 / 57344 | (320,180), unchanged |
| street_exit | 12×10 | 120 / 120, same | 6+5 / 6+5, identical | 4 / 4 | 32864 / 30720 | (320,180), unchanged |

**What the builder would change in a rebuild:**
- **Every room:** the collision polygon (one diff line).
- **security_crossing:** the floor as well (12 new cells).

The floor in the other 9 rooms and the walls in all 10 come out byte-identical (0 diff lines).

## 1. Floor tiles

- **Floor layer position:** all 10 `TileMapLayer_Floor` nodes are at (304, 64), the builder's expected position.
- **9 rooms:** the cell set equals the W × H grid. Every tile keeps its source, and the encode/decode round-trip is byte-identical.
- **security_crossing:** the hand-built floor leaves out the 12 cells of column **x = 9** (y 0–11). That column is the trench.
  - `TrenchVisual` is a `Polygon2D` at **z −1**, so it draws *under* the floor layer. Its polygon (464,136)–(480,144)–(304,232)–(288,224) is exactly tile column x = 9.
  - The builder fills every cell inside the outline, so it would add those 12 cells with `--tile-source` (default 0, terrazzo) and **hide the trench**.
  - So security_crossing needs a "holes" input (cells to leave empty) before Task 6 uses the builder on it. Alternatively, put the trench cells back by hand after a rebuild.
- **New tiles default to source 0** (`terrazzo_dark`). Maintenance bay, security crossing and signal control use **source 4** (`concrete_service`) as their base. Their rebuilds need `--tile-source 4`.
- **Arrival platform's floor sources:**
  - 0 `terrazzo_dark`: 107 cells;
  - 1 `terrazzo_cracked`: 11 cells, scattered;
  - 2 `tactile_amber`: 22 cells. This is the platform-edge strip: column x = 13 at y 0–4 and 6–8 (the door row y = 5 is left plain) and row y = 9 at x 0–13.

  Kept cells keep their source. **After enlarging or cutting the room, the old strip stays at x = 13 / y = 9, and new edges get plain terrazzo.** The strip must be repainted along the new S/E edges by hand, or with a later builder option.

## 2. Perimeter polygon (the main change)

Every hand-built polygon uses `build_mode = 1` (segments, closed loop) on a `StaticBody2D` at (0,0). Here they are in tile coordinates, from `px_to_tile`. Vertices marked `*` are collinear with their neighbours, so they add no geometry.

| Room | Hand-built vertices (tile coordinates) |
|---|---|
| arrival_platform | (−¼,−¼) (14,−¼) (14,5)* **(14,6)** (14¼,10¼) (−¼,10) |
| concourse_west | (−¼,−¼) (16,−¼) (16,5)* **(16,6)** (16¼,12¼) (−¼,12) (−¼,5¾)* (−¼,4¾)* |
| maintenance_bay | (−¼,−¼) (14,−¼) (14,4)* **(14,5)** (14¼,10¼) (−¼,10) (−¼,5¾)* (−¼,4¾)* |
| security_crossing | (−¼,−¼) (16,−¼) (16,6)* **(16,7)** (16¼,12¼) (−¼,12) (−¼,6¾)* (−¼,5¾)* |
| the other 6 | (−¼,−¼) (W,−¼) (W+¼,H+¼) (−¼,H) |

The builder produces the plain rectangle (0,0) (W,0) (W,H) (0,H). For arrival that is `(320,64) (544,176) (384,256) (160,144)`, against hand-built `(320,60) (548,174) (464,216) (448,224) (384,260) (156,142)`.

**The difference per face:**

| Face | Hand-built | Built with `--outset 0` | Built with `--outset 0.25` |
|---|---|---|---|
| N (tall wall) | ¼ tile out (4 px up, 3.6 px perpendicular) | on the floor edge: **3.6 px tighter** | same as hand-built |
| W (tall wall) | ¼ tile out | on the floor edge: **3.6 px tighter** | same as hand-built |
| E (open) | 0 at the N end, to ¼ at the S corner; straight on x = W down to the east-door row in 4 rooms | on the edge: same at the N end, up to 3.6 px tighter at the S corner | ¼ everywhere: up to 3.6 px *looser* at the N end |
| S (open) | 0 at the W corner, to ¼ at the S corner | on the edge: up to 3.6 px tighter | ¼ everywhere |
| Corners | N (0,−4) px, E (+4,−2), S (0,+4), W (−4,−2) from the floor corner | at the floor corners | N and S corners match; E and W corners sit (+4,+2) / (−4,+2) px from the hand-built ones |

**The "east-door notch" is not a notch.**
- In the 4 rooms with an east door, the extra vertices sit at (W, door_y) and (W, door_y + 1). The first is collinear. The second is the only kink, where the straight x = W edge turns and flares out ¼ tile towards the S corner.
- So there is no opening and no inward step: the polygon is a closed loop in either version. The door trigger sits 1 tile inside the E face, at tile corner (W−1, door_y).
- The W-side extra vertices (concourse, bay, security) are all collinear: they have no effect.
- A rebuilt polygon doesn't need a notch. Only the outset choice changes anything.

**Why it matters (walkable area):** with outset 0, every room loses 4.8–11.4 % of its collision area (niche −11.4 %, arrival −5.6 %). All of that is in a 3.6 px band along N/W and a wedge towards the S corner.

## 3. N/W wall sprites

- **Identical in all 10 rooms:** same names (`WallN_k`, `WallW_k`), same positions, same properties (`offset (−16,−56)`, `centered = false`, the `wall_subterranean_n/w_idle` texture), same node order. The builder's diff has 0 wall lines.
- **No 1-tile ends:** every W and H is even, so the builder reports none.
- **Left alone by the builder** (it only rewrites `Wall[NW]_<n>`):
  - `Archway_*` (one per door);
  - concourse `PillarSprite` (tile (9.5, 5.5));
  - maintenance `bulkhead`;
  - the railing sprites.
- **No door awareness, in either version:** on N/W doors a wall module and the archway share a pivot. For example, concourse `WallW_2` and `Archway_door_entry_west` are both at (240,104).
  - TLF-069 is unaffected, because arrival's only door is on the E face (low, no module).
  - For Task 6 rooms with N/W doors, the builder must not be expected to cut the wall.
- **Not drawn by either version:** the low_S / low_E partitions and the 4 corner pieces. Today's rooms have none, and the builder lists them as `NOT DRAWN`, for TLF-068.

## 4. Camera bounds

- **Today:** no room has `metadata/room_shape`. `RoomRouter.current_room_bounds()` therefore returns the 640 × 360 screen, and the camera sits at (320,180), which is no transform.
- **With a W × H RoomShape**, `bounds_px()` is:

  | Room | bounds_px() as (x, y, w, h) |
  |---|---|
  | arrival, bay | (144, 0, 416, 272) |
  | concourse, security, signal | (112, 0, 480, 304) |
  | waiting lounge, street exit | (144, 0, 384, 256) |
  | upper vestibule | (80, 0, 480, 304) |
  | niche | (208, 0, 224, 176) |
  | atrium | (80, 0, 512, 320) |

  Every one fits inside 640 × 360. For **every floor tile in every room**, the RoomCamera centre is (320,180): computed per tile with `RoomCamera._axis`. Adding the shape to today's rooms changes nothing on screen.
- **Gap for TLF-069:** the builder writes floor, collision and walls, but **not** `metadata/room_shape`. Without that metadata the router keeps the fixed screen bounds, so a larger room will not scroll. The pilot scene needs a `RoomShape` sub-resource with the same outline on the room root, added by hand or by adding a `--write-meta` option to the builder (small; I can do it). `bounds_px()` uses the outline, not the outset, so it doesn't depend on the outset choice.

## 5. Door triggers, spawns and other objects near edges

**Doors** (circle r 10) and **checkpoints** (rect 28 × 16):
- *d* is the trigger centre's distance inside the polygon, in px.
- *reach* is the number of valid body positions.

| Room | Trigger | Tile | d: hand / out 0 / out ¼ | Reach: hand / out 0 / out ¼ |
|---|---|---|---|---|
| arrival | door_exit_east | (13,5) | 14.3 / 14.3 / 17.9 | 712 / 711 / 815 |
| arrival | checkpoint | (7,5) | 74.1 / 71.6 / 75.1 | 1149 / 1149 / 1149 |
| concourse, bay, security, lounge | door_entry_west | (0,5) or (0,6) | **3.6 / 0.0** / 3.6 | **340 / 220** / 340 |
| concourse, bay, security, lounge | checkpoint by the W door | (1,5) or (1,6) | 17.9 / 14.3 / 17.9 | 1008 / 896 / 1008 |
| concourse, bay, security | door_exit_east | (W−1, door_y) | 14.3 / 14.3 / 17.9 | 711–712 / 711 / 815 |
| lounge, signal, vestibule, niche, atrium | north doors | (x,0) | **3.6 / 0.0** / 3.6 | **340 / 220** / 340 |
| vestibule, niche | door_west / door_in | (0,y) | **3.6 / 0.0** / 3.6 | **340 / 220** / 340 |
| signal, vestibule, atrium, street | south and east doors | 1 tile inside | 16.2–16.3 / 14.3 / 17.9 | 769–771 / 711 / 815 |
| signal, vestibule, atrium, street | checkpoint | 1 tile inside | 30.7–30.8 / 28.6 / 32.2 | 1149 / 1149 / 1149 |

- **Doors on the N or W face** have their trigger centre at a tile corner on the floor edge. With `--outset 0`, it lies **exactly on the collision line**.
  - The doors stay reachable: the body can come within 6 px of the line, and the trigger reaches 16 px. But the reach area drops by 35 %.
  - With `--outset 0.25` it is identical to hand-built.
- **E/S doors** are 1 tile inside and unaffected in practice.
- **Spawns and safe anchors:** every one of them fits the body in both polygons, in all 10 rooms. Those next to an N/W door move from 14.3 px inside to 10.7 px with outset 0. Nothing becomes unreachable.
- **On or outside the edge in both versions** (wall-mounted, reached by interaction radius, not by walking):
  - `digital_clock_2359` at (320,50) in 6 rooms;
  - security `pa_speaker`;
  - signal `intercom`;
  - with outset 0, also signal `breaker_a`, `breaker_c` and `doc_bus_chart`, which move from 3.6 px inside the W line to exactly on it.

  The interaction detector is r 36, so this doesn't change.

**Recommendation for TLF-069:** use `--outset 0.25`. It keeps the N/W faces, the N/W door reach and the N and S corners exactly as they are now. The only change is ¼ tile more room on the open E/S faces near the E and W corners, which the hand polygon already gives at the S corner.

## 6. Tests coupled to what a rebuild changes

- **`tests/chapters/ch01/test_ch01_art_integration.gd::test_collision_freeze_all_10_rooms`.**
  - It pins every collision polygon, zone, spawn and interactable position in all 10 rooms to a gzip baseline (TLF-041).
  - **Any rebuild fails it** until the baseline is regenerated for that room.
  - TLF-069 has to update the arrival entry on purpose.
- **`test_room1_arrival_platform_kit_complete`.** It pins:
  - 140 floor tiles;
  - `WallN_0..6` at (336+32k, 72+16k);
  - `WallW_0..4` at (304−32j, 72+16j);
  - the archway at (448,208), z 6.
- **`test_ch01_sort_order.gd` (TLF-067).**
  - It asserts that each audited object sorts at its contact from `docs/reviews/TLF-066/render_manifest.json`.
  - For arrival, that covers `platform_gate`, the 3 selectors and `release_lever`.
  - If those objects move, the manifest rows (or the test's anchor source) must move with them.
- **Signal control:** `test_ch01_playthrough.gd::test_pz004_route_is_at_least_600_px` and `test_ch01_pz004_layout.gd` read its perimeter polygon. This concerns Task 6, not the pilot.
- **Other tests that reference `arrival_platform`:** 16 test files, including real-input walks with fixed coordinates (`test_ch01_real_playthrough`, `test_ch01_step1_negatives`, `test_ch01_unlock_guards`, `test_spawn_targeting`). Each needs a coordinate check in TLF-069.

## 7. Arrival platform: what is in the way of an L cut on the south/east side

**Tile frame.**
- x runs 0–14, NW → SE (screen down-right); y runs 0–10, NE → SW (screen down-left).
- The S face is y = 10, the platform edge, with the tactile strip on row 9 and the stalled car beyond it.
- The E face is x = 14, with the east door.
- Object positions are the node positions in tile coordinates. Most sit on tile corners, as in ROOM_GRAPH.

| Object | Tile | Distance to E face (14−x) | Distance to S face (10−y) | Notes |
|---|---|---|---|---|
| `door_exit_east` + `Archway_door_exit_east` + `platform_gate` (Blocker 12×12) | (13,5) | 1 | 5 | E-face door; the gate stands in the doorway |
| `door_exit_east/Spawn` | (12,5) | 2 | 5 | |
| `release_lever` (wall fixture) | (13,2) | 1 | 8 | |
| `n04_cleaner` (+ footprint) | (12,7) | 2 | 3 | |
| `n01_conductor` (+ footprint) | (10,8) | 4 | 2 | |
| `pocket_watch_pickup` | (8,5) | 6 | 5 | |
| `checkpoint`, `safe_anchor_spawn` | (7,5) | 7 | 5 | |
| `StalledTransitCar` (128×80, pivot (64,52)) | (6.97, 11.28), beyond the S face | 7 | −1.3 | Its 5-tile body runs along +x from about x 4.5 to 9.5, outside the floor; the sprite's top overlaps rows 8–9 visually |
| `n02_student` | (5,8) | 9 | 2 | |
| `operator_sighting` (approach r 32) | (9,2) | 5 | 8 | |
| `selector_line` / `_platform` / `_car` | (7,1) (9,1) (11,1) | 7 / 5 / 3 | 9 | N-wall fixtures |
| `PlatformBench`, `n03_old_man`, `doc_last_service` | (4.5,2.5), (4,2), (1,3) | ≥ 9.5 | ≥ 7 | |
| `WallN_0..6`, `Clock_2`, `Clock_5` | y = 0 (clocks above the N wall) | | 10 | N wall |
| `WallW_0..4` | x = 0 | 14 | | W wall |

**Cut at the SE corner** (remove x ≥ 14−a, y ≥ 10−b). The new faces are a low_S face, a low_E face and one inner corner. **No tall wall is touched, and the R2 check finds no hidden floor** (6 × 4 example: hidden = []).

| Cut depth b (rows removed) | Objects removed or displaced |
|---|---|
| b ≤ 2 (rows 8–9) | nothing if a ≤ 3; `n01_conductor` if a ≥ 4 |
| b = 3–4 (rows 6/7–9) | `n04_cleaner` for any a ≥ 2; plus `n01_conductor` if a ≥ 4 |
| b ≥ 5 (reaches the door row y = 5) | **the east door, archway, platform_gate and door spawn**, so the door has to move; plus the pickup if a ≥ 6, and the checkpoint/spawn anchor if a ≥ 7 |
| any b with a ≥ 5 | the cut's west edge reaches the car's east end (x ≈ 9.5): the car would overhang the new low_E face or void |

**Cuts at the other two corners** also touch the S or E side, but they create a new *tall* face:
- **At the E corner** (x ≥ 14−a, y < b):
  - it removes `WallN_5`/`WallN_6` and possibly `Clock_5`, `selector_car` and `release_lever`;
  - its new N face hides floor under R2 (4 × 3 example: tiles (7,0) (8,0) (9,0) (8,1) (9,1) (9,2)).
- **At the W corner** (x < a, y ≥ 10−b):
  - it removes `WallW_3`/`WallW_4` and the car's west end, and `n02_student` if a ≥ 6;
  - its new W face hides 6 tiles (4 × 3 example) and leaves two 1-tile W ends.

So the SE corner is the only cut that needs no new tall wall and no R2 fix. Up to a ≤ 4, b ≤ 4, the only things to move are the two NPCs `n04_cleaner` and `n01_conductor`, plus the tactile strip, which has to be repainted along the new edges (section 1).

## Raw output

The raw dry-run output is in `roundtrip/dry_<room>.txt`; the summary and diff lines of each are quoted below. Diff lines longer than 220 characters are truncated by the tool itself.

<details><summary>dry_arrival_platform.txt</summary>

```
shape: [['0', '0'], ['14', '0'], ['14', '10'], ['0', '10']]
  floor: 140 tiles (140 kept with their tile, 0 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 7 N and 5 W modules
  NOT DRAWN: low_E partition (14, 0) -> (14, 10) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 10) -> (14, 10) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (14, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (14, 10) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 10) (faces low_S/W, TLF-068 kit)
diff: 2 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/arrival_platform.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/arrival_platform.tscn (built)
@@ -91,3 +91,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 548, 174, 464, 216, 448, 224, 384, 260, 156, 142)
+polygon = PackedVector2Array(320, 64, 544, 176, 384, 256, 160, 144)
 
```
</details>

<details><summary>dry_concourse_west.txt</summary>

```
shape: [['0', '0'], ['16', '0'], ['16', '12'], ['0', '12']]
  floor: 192 tiles (192 kept with their tile, 0 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 8 N and 6 W modules
  NOT DRAWN: low_E partition (16, 0) -> (16, 12) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 12) -> (16, 12) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (16, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (16, 12) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 12) (faces low_S/W, TLF-068 kit)
diff: 2 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/concourse_west.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/concourse_west.tscn (built)
@@ -127,3 +127,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 580, 190, 496, 232, 480, 240, 384, 292, 124, 158, 224, 108, 240, 100)
+polygon = PackedVector2Array(320, 64, 576, 192, 384, 288, 128, 160)
 
```
</details>

<details><summary>dry_maintenance_bay.txt</summary>

```
shape: [['0', '0'], ['14', '0'], ['14', '10'], ['0', '10']]
  floor: 140 tiles (140 kept with their tile, 0 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 7 N and 5 W modules
  NOT DRAWN: low_E partition (14, 0) -> (14, 10) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 10) -> (14, 10) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (14, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (14, 10) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 10) (faces low_S/W, TLF-068 kit)
diff: 2 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/maintenance_bay.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/maintenance_bay.tscn (built)
@@ -117,3 +117,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 548, 174, 480, 208, 464, 216, 384, 260, 156, 142, 224, 108, 240, 100)
+polygon = PackedVector2Array(320, 64, 544, 176, 384, 256, 160, 144)
 
```
</details>

<details><summary>dry_security_crossing.txt</summary>

```
shape: [['0', '0'], ['16', '0'], ['16', '12'], ['0', '12']]
  floor: 192 tiles (180 kept with their tile, 12 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 8 N and 6 W modules
  NOT DRAWN: low_E partition (16, 0) -> (16, 12) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 12) -> (16, 12) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (16, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (16, 12) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 12) (faces low_S/W, TLF-068 kit)
diff: 4 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/security_crossing.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/security_crossing.tscn (built)
@@ -117,3 +117,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 580, 190, 480, 240, 464, 248, 384, 292, 124, 158, 208, 116, 224, 108)
+polygon = PackedVector2Array(320, 64, 576, 192, 384, 288, 128, 160)
 
@@ -299,3 +299,3 @@
 position = Vector2(304, 64)
-tile_map_data = PackedByteArray(0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 5 ...
+tile_map_data = PackedByteArray(0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 5 ...
 tile_set = ExtResource("art_tileset")
```
</details>

<details><summary>dry_waiting_lounge.txt</summary>

```
shape: [['0', '0'], ['12', '0'], ['12', '10'], ['0', '10']]
  floor: 120 tiles (120 kept with their tile, 0 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 6 N and 5 W modules
  NOT DRAWN: low_E partition (12, 0) -> (12, 10) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 10) -> (12, 10) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (12, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (12, 10) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 10) (faces low_S/W, TLF-068 kit)
diff: 2 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/waiting_lounge.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/waiting_lounge.tscn (built)
@@ -39,3 +39,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 516, 158, 352, 244, 156, 142)
+polygon = PackedVector2Array(320, 64, 512, 160, 352, 240, 160, 144)
 
```
</details>

<details><summary>dry_signal_control.txt</summary>

```
shape: [['0', '0'], ['16', '0'], ['16', '12'], ['0', '12']]
  floor: 192 tiles (192 kept with their tile, 0 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 8 N and 6 W modules
  NOT DRAWN: low_E partition (16, 0) -> (16, 12) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 12) -> (16, 12) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (16, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (16, 12) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 12) (faces low_S/W, TLF-068 kit)
diff: 2 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/signal_control.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/signal_control.tscn (built)
@@ -87,3 +87,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 580, 190, 384, 292, 124, 158)
+polygon = PackedVector2Array(320, 64, 576, 192, 384, 288, 128, 160)
 
```
</details>

<details><summary>dry_upper_vestibule.txt</summary>

```
shape: [['0', '0'], ['14', '0'], ['14', '14'], ['0', '14']]
  floor: 196 tiles (196 kept with their tile, 0 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 7 N and 7 W modules
  NOT DRAWN: low_E partition (14, 0) -> (14, 14) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 14) -> (14, 14) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (14, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (14, 14) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 14) (faces low_S/W, TLF-068 kit)
diff: 2 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/upper_vestibule.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/upper_vestibule.tscn (built)
@@ -72,3 +72,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 548, 174, 320, 292, 92, 174)
+polygon = PackedVector2Array(320, 64, 544, 176, 320, 288, 96, 176)
 
```
</details>

<details><summary>dry_vestibule_niche.txt</summary>

```
shape: [['0', '0'], ['6', '0'], ['6', '6'], ['0', '6']]
  floor: 36 tiles (36 kept with their tile, 0 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 3 N and 3 W modules
  NOT DRAWN: low_E partition (6, 0) -> (6, 6) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 6) -> (6, 6) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (6, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (6, 6) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 6) (faces low_S/W, TLF-068 kit)
diff: 2 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/vestibule_niche.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/vestibule_niche.tscn (built)
@@ -33,3 +33,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 420, 110, 320, 164, 220, 110)
+polygon = PackedVector2Array(320, 64, 416, 112, 320, 160, 224, 112)
 
```
</details>

<details><summary>dry_station_atrium.txt</summary>

```
shape: [['0', '0'], ['16', '0'], ['16', '14'], ['0', '14']]
  floor: 224 tiles (224 kept with their tile, 0 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 8 N and 7 W modules
  NOT DRAWN: low_E partition (16, 0) -> (16, 14) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 14) -> (16, 14) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (16, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (16, 14) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 14) (faces low_S/W, TLF-068 kit)
diff: 2 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/station_atrium.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/station_atrium.tscn (built)
@@ -39,3 +39,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 580, 190, 352, 308, 92, 174)
+polygon = PackedVector2Array(320, 64, 576, 192, 352, 304, 96, 176)
 
```
</details>

<details><summary>dry_street_exit.txt</summary>

```
shape: [['0', '0'], ['12', '0'], ['12', '10'], ['0', '10']]
  floor: 120 tiles (120 kept with their tile, 0 new, 0 removed)
  collision: 4 corners, outset 0 tile
  walls: 6 N and 5 W modules
  NOT DRAWN: low_E partition (12, 0) -> (12, 10) (open today; TLF-068 low piece if needed)
  NOT DRAWN: low_S partition (0, 10) -> (12, 10) (open today; TLF-068 low piece if needed)
  NOT DRAWN: outer_corner N at (0, 0) (faces W/N, TLF-068 kit)
  NOT DRAWN: outer_corner N at (12, 0) (faces N/low_E, TLF-068 kit)
  NOT DRAWN: outer_corner low_S at (12, 10) (faces low_E/low_S, TLF-068 kit)
  NOT DRAWN: outer_corner W at (0, 10) (faces low_S/W, TLF-068 kit)
diff: 2 changed line(s) (dry run)
--- ../wt-rt/scenes/chapters/ch01/rooms/street_exit.tscn
+++ ../wt-rt/scenes/chapters/ch01/rooms/street_exit.tscn (built)
@@ -35,3 +35,3 @@
 build_mode = 1
-polygon = PackedVector2Array(320, 60, 516, 158, 352, 244, 156, 142)
+polygon = PackedVector2Array(320, 64, 512, 160, 352, 240, 160, 144)
 
```
</details>
