# Security Crossing v2 (room 4, TLF-086)

Author: Lead · Status: READY (2026-11-11) · ADR-023, ADR-025, ADR-026, ADR-027, `PATTERN.md` rules 1-12 · Program: `docs/tasks/ROOMS_V2_PROGRAM.md` · Puzzle: `design/ch01/puzzles/CH1-PZ-003.md` (base + R1)

## 0. Why the room is rebuilt (measured on main `1388d6d`)

* **Cramped.** 16 × 12 tiles (192 cells, W+H 28), 19 objects: 10 cells per object (rule 8 asks ≥ 18). The west deck (x 0..9) holds the pass desk, guard, alarm plate, guard log, pedestal, south plate and reset console; the trench (x 9..10), the landing strip (x 10..12, 2 tiles) and the exit strip (x 12..16) follow.
* **The door sits on the spawn.** `door_entry_west` (0,6) with its `Spawn` at (1,6) (`(240,120)`), and the `checkpoint` is on the same tile; `doc_guard_log` (2,4) is 2 tiles from the aperture.
* **The two dividers may not reach the S wall.** `TrenchBarriers` runs x = 9 from y 0 to **11** and `StaffBarrier` x = 12 from y 0 to **11**, while the perimeter goes to y 12 (+0.25 outset). Either the bottom row is not floor or there is a 1-tile path round both lines; the v2 sweeps settle it, and v2 runs both lines wall to wall.
* **Invisible divider.** `StaffBarrier` (x = 12) is two collision segments; only the barrier sprite in the aperture is drawn.
* **Frontal art** (TLF-078 rows): `pa_speaker` (N wall, frontal horn) and `card_reader_01` (W face of the staff barrier, anchor off the plane, 3 states).
* **No lighting yet** (ADR-026 security area: A 2, one focal 2/1, at most one helper 1/0).

## 1. Shape and size

* Grid **24 × 16**, rectangle: outline `[[0,0],[24,0],[24,16],[0,16]]`. 384 cells (2.0× today), W+H = 40.
* N wall y = 0 and W wall x = 0 straight and tall; S and E open/low (R2). The room grows **west** (a new entry hall in front of the deck), **east** (an exit hall behind the barrier) and **south** (y 12..16). Nothing moves in y.
* Bands after the rebuild:
  * **A, entry hall** x 0..4 (4 wide): arrival, checkpoint.
  * **B, west deck** x 4..13 (9 wide, unchanged contents): pass desk, guard, alarm plate, log, pedestal, south plate, reset console.
  * **Trench** x 13..14, bridge at y ≈ 6.
  * **C, landing** x 14..16 (2 wide, unchanged on purpose: card reader in front of the barrier, PZ-003 R1 geometry).
  * **D, exit hall** x 16..24 (8 wide): `exit_trigger_lounge`, east door.
* Builder: `build_room_from_shape.py --outset 0.25 --tile-source 4 design/ch01/rooms_v2/security_crossing.json` (dry run first, diff in the handoff). The trench stays as today (`TrenchVisual` polygon + collision line + railings), not `--holes`.

## 2. One rigid cluster (every distance inside it is unchanged)

`tile(x,y) = (320+16(x−y), 64+8(x+y))`, TileMap at (304,64) as today. **Cluster P (the whole puzzle) shifts x + 4: Δpx = (64, 32).** y never changes.

| Object | Old tile (px) | New tile (px) |
|---|---|---|
| `transit_pass_pickup` | (3,2) (336,104) | (7,2) (400,136) |
| `n13_guard` (+ Footprint) | (4,3) (336,120) | (8,3) (400,152) |
| `alarm_plate_01` | (5,3) (352,128) | (9,3) (416,160) |
| `doc_guard_log` | (2,4) (288,112) | (6,4) (352,144) |
| `echo_recorder_pedestal` | (4,8) (256,160) | (8,8) (320,192) |
| `pressure_switch_01` | (5,9) (256,176) | (9,9) (320,208) |
| `reset_anchor_01` | (7,6) (336,168) | (11,6) (400,200) |
| `safe_anchor_west` | (6,6) (320,160) | (10,6) (384,192) |
| `bridge_platform_01`, `bridge_walk_zone` | (9,6) (368,184) | (13,6) (432,216) |
| `security_gate_01` (+ Blocker) | (10,4) (416,176) | (14,4) (480,208) |
| `card_reader_01` | (11,7) (384,208) | (15,7) (448,240) |
| `staff_barrier_01` (+ Blocker) | aperture (12,5) (432,200) | (16,5) (496,232) |
| `exit_trigger_lounge` | (13,6) (432,216) | (17,6) (496,248) |
| `safe_anchor_east` | (13,6) (432,216) | (17,6) (496,248) |
| `pa_speaker` + `PASpeakerSprite` (N wall) | logical (320,60) | (384,92), still on the N wall |
| `TrenchVisual`, `TrenchBarriers`, `Railing_0..9` | x = 9..10, y 0..11 | x = 13..14, y 0..**16** (extend: new railing modules at y 13 and 15 on both lines, the polygon and `TrenchSouth` to the S edge + outset) |
| `StaffBarrier` segments | x = 12, y 0..4.25 and 5.75..11 | x = 16, y 0..4.25 and 5.75..**16** |

Every stand spot in `CH1-PZ-003.md` R1.4 and `ROOM_GRAPH.md` §5.3 moves by (64,32). The base walk (south plate → gate 160 px, 80 ticks) and every R-test keep their logic; only coordinates change. `TEST-PZ003-R07` (no crossing without Echo) and `R08` (barrier sealed) must pass on the new colliders.

**Not in the cluster:**

| Object | Old | New | Why |
|---|---|---|---|
| `door_entry_west` + archway | (0,6) (224,112) | **(0,6)** | W wall, unchanged; trigger = the thin aperture only |
| door `Spawn` (arrival) | (1,6) | **(2,6)** (256,128) | 2 tiles inside, free floor on every side (rule 10) |
| `checkpoint` | (1,6) on the spawn | **(4,6)** (288,144) | 2 tiles past the spawn, 4 from the door; restores to `safe_anchor_west` as today |
| `door_exit_east` + archway | (15,6) in an E-wall notch | **(24,6)** (608,304) | on the E edge (x = w, as concourse/maintenance v2); its `Spawn` (arrival from the lounge) at (22,6) |

## 3. Dividers must be visible and sealed

* **Trench** (x 13..14): keep the railing art on both lines, add the south modules; the bridge stays the only crossing (1.5-tile aperture at y ≈ 5.25..6.75, filled by the bridge `Blocker` while retracted).
* **Staff barrier** (x = 16): dress both runs with `ch01_env_wall_partition_low_e_idle.png` as concourse v2 (whole 2-tile modules, halves at the barrier aperture, `centered=false`, offset = −pivot, no new collision). The barrier sprite stays in its aperture. The card reader is mounted on this partition's W face (TLF-078 row: today's anchor is off the plane; fix the anchor in part b).
* **Sweeps** (gates closed, real capsule): trench x = 13 and barrier x = 16 from y 0.8 to 15.2, push east 60 ticks, never cross. Each sweep must go RED when its collider is removed (Lead/Opus mutate outside the suite as well).

## 4. Space rules check (PATTERN 8-10)

* W+H 40 (✓). 384 cells / 19 objects = 20.2 (✓ ≥ 18).
* Arrival (2,6): free floor x 0..4, y 4..8 (✓). Checkpoint (4,6) has 2 free tiles round it except the deck props at x ≥ 6 (doc log (6,4) is 2 tiles away: ✓).
* Door sweep from (2,6): left/up/down 3 s never triggers `door_entry_west`.
* Routes: entry hall → deck ≥ 3 tiles everywhere; the bridge and the barrier aperture are the puzzle's 1.5-tile gates (allowed).
* No prop within 1 tile of a doorway; nothing on the line between the two doors except the puzzle gates (unchanged).

## 5. Art, lighting, shadows

* Wall fixtures (TLF-086b, Sol or Argon): `pa_speaker` N-wall sheared variant; `card_reader_01` W-face variants (idle, accepted, denied) on the barrier partition plane. Flash builds with today's art as marked placeholders.
* Lighting (Opus after the build, ADR-026 security area): A 2; focal 2/1 on the gate + bridge (the decision); one helper 1/0, either the south plate (the Echo spot) or the east door, Opus proposes and Fable/Sol decide. Card reader screen and the plate glyphs are information regions. Shadows per ADR-027: `shadows = true`, `fill_lift = 1`.

## 6. Landing criteria (TLF-086)

1. Outline above; builder dry run reviewed; `hidden_floor_cells()` empty; `metadata/room_shape`.
2. Cluster P moved rigidly (assert Δ (64,32) on every node in the table); `TEST-PZ003-01..05` and `R01..R10` pass, real input where the spec says so; R07 and R08 on the new colliders.
3. Door sweep from (2,6); trench and barrier sweeps (y 0.8..15.2) with the gates closed; both go RED when their collider is removed.
4. Stand spots within 2.6 px; apertures ≥ 1.5 tiles; camera: the room is 640 × 320 px, fixed camera, explicit bounds asserted at arrival, deck, bridge, landing, east door (real 960×540 view).
5. `test_ch01_sort_order.gd` and `render_manifest.json` rows for this room only (edit in place); collision baseline for this room only; graph data + `ROOM_GRAPH.md` rows (doors (0,6)/(24,6), anchors, checkpoint (4,6), §5.3 table); the maintenance_bay → security_crossing and lounge → security_crossing arrivals land on the new spawns.
6. Windowed Forward+ 960×540 screenshots at arrival, deck (plate + pedestal), bridge (gate open), landing (card reader), east door; full validate 0 failed / 0 SCRIPT ERROR; python builder tests.
