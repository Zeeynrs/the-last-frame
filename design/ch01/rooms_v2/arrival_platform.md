# Arrival Platform v2 (pilot room, TLF-069)

Author: Lead · Status: APPROVED by the owner (2026-11-07) · ADR-023, plan Task 5 · Diagram: `arrival_platform_v2_layout.png`

## 1. Shape and size

* Grid 30 × 18 tiles with the south-east block x 12..30, y 8..18 removed (R2b: the cut is on the S/E side, so N and W walls stay straight and no floor is hidden; `hidden_floor_cells()` must be empty).
* Outline (tile coordinates): `[[0,0],[30,0],[30,8],[12,8],[12,18],[0,18]]`.
* 360 floor cells (today 140). Floor extent 768 × 368 px (today 384 × 192): about 1.2 screens wide, 1.02 tall. The camera scrolls horizontally and barely vertically.
* The two legs: the **strip** (y 0..8, all x, 8 deep, runs to the east door) and the **arm** (x 0..12, y 8..18, 10 deep, the awakening dead end). The cut is the **track pit** with the stalled transit car.
* Walls: tall N wall (y = 0, x 0..30, 15 modules) and tall W wall (x = 0, y 0..18, 9 modules). Low partitions (TLF-068 kit, at most about 20 px): pit edge y = 8 (x 12..30), arm east edge x = 12 (y 8..18), arm south edge y = 18 (x 0..12), strip east edge x = 30 (y 0..8) with the door opening. Inner corner at (12,8), outer corners at (30,8), (12,18), (0,18) per the §10.2 recipe.
* Builder: `build_room_from_shape.py` with `--outset 0.25 --edge-strip 2,S,E --door` not used (E door only).

## 2. Objects (tile, then why there)

| Object | Tile | Note |
|---|---|---|
| `safe_anchor_spawn` / Elias spawn | (5,15) | arm dead end, camera at the left |
| `checkpoint` (`ch01.cp.arrival`) | (6,14) | beside the spawn |
| `pocket_watch_pickup` | (8,13) | 3 tiles from the spawn |
| Operator sighting figure (TLF-058) | (9,10) | keeps the approved framing: same offset (+1,-3) tiles from the pickup as the old (9,2) from (8,5), so Ending 3 can reuse it; trigger centre = old offset from the pickup, radius 32 |
| `n02_student` | (3,10) | in the arm, off the walking line |
| `n03_old_man` (seated, bench beside) | (10,2) | N wall, west half of the strip |
| `n01_conductor` | (14,3) | strip, north of the line to the gate |
| `n04_cleaner` | (23,7) | strip, near the east end, clear of the pit edge |
| `doc_last_service` | (6,1) | N wall, a detour from the route |
| `selector_line` / `selector_platform` / `selector_car` | (21,1) / (23,1) / (25,1) | wall panel, 2 tiles apart, east half of the N wall |
| `release_lever` | (29,2) | one tile inside the E face |
| `door_exit_east`, archway, `platform_gate` | (29,4) | the gate stands in the doorway (24 × 24 Blocker at (0,0), TLF-055) |
| Stalled transit car | (22,12) | inside the pit, runs +x about 5 tiles (x 19.5..24.5) |
| Digital clocks 23:59 (2) | (5,0), (17,0) | N wall fixtures |
| Departure board `DESTINATION: NOWHERE - 23:59` (TLF-063) | (0,12) | W wall of the arm, visible at the awakening |
| `CLOSED TRACK` notice (TLF-063) | (20,8) | on the pit edge partition, readable from the strip |

All stand spots follow the SO-01 rule (17.9 px from the contact, on the approach side); Flash verifies each with the real capsule probe. Statues stay at least 2 tiles from the line spawn → (8,8) → gate (placement rule P, TEST-CM-05). No object may sit on a cell removed by the cut.

## 3. Puzzle (CH1-SO-01 unchanged)

Same solution (Hollow Quay, platform 3, rear car), same states and feedback keys. The route is longer: spawn to gate is about 28 tiles along the path (today about 11), so the player passes all four statues and the panel on the way. The lock-out, hints and Echo/Rewind rules are untouched. Apertures: the only passage is the E doorway (opening at least 1.5 tiles, TLF-055 §G).

## 4. Camera

* `metadata/room_shape` on the room root (the builder writes it). Bounds from `RoomShape.bounds_px()`; no frame outside them.
* Spawn view shows the arm and the first third of the strip; the gate view shows the east end. The Operator (9,10) and the watch (8,13) are visible together from the pickup spot (about 66 px apart).
* On entry from another room the camera snaps (`snap_now`), no pan.

## 5. Landing criteria (TLF-069)

1. `RoomShape` outline above; builder dry run diff reviewed; `hidden_floor_cells()` empty.
2. Real-input segment of the playthrough and the SO-01 negatives pass with the new coordinates (updated by this task); door sweep with the gate closed never enters the door; every object's stand spot reachable within 2.6 px.
3. Sort order: `test_ch01_sort_order.gd` rows for arrival move with the objects; the Operator and statues sort correctly with Elias.
4. Camera: clamp edges, snap on entry, save/load at the checkpoint (Review Focus 1-3, 5 of the plan).
5. Collision baseline `test_collision_freeze_all_10_rooms` and `test_room1_arrival_platform_kit_complete` re-baselined for this room only, with the diff explained.
6. Windowed screenshots at the spawn, the watch, the pit edge and the gate; Sol reviews facing and overlap at the four sides of the new objects.
7. Full validate 0 failed, no SCRIPT ERROR; the owner plays the room.

## 6. Open points for the owner

* Size: is 30 × 18 (about 2× per side, 768 px wide) right, or larger?
* The track pit is dark void with the car and low partitions; a dedicated track-bed art piece (Argon) is a possible follow-up, not part of the pilot.
