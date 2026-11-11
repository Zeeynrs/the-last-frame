# Maintenance Bay v2 (room 3, TLF-085)

Author: Lead · Status: READY (2026-11-11) · ADR-023, ADR-025, ADR-026, `PATTERN.md` rules 1-12 · Program: `docs/tasks/ROOMS_V2_PROGRAM.md`

## 0. Why the room is rebuilt (measured on main `1388d6d`)

* **Cramped.** 14 × 10 tiles (140 cells, W+H 24). Three gate lines cut it into four bands that are 3, 5, 3 and 2-3 tiles wide: bulkhead with the service hatch at x = 3 (CH1-SO-02), fire shutter at x = 8 (CH1-PZ-002 stage 1), inner shutter at x = 11 (PZ-002 R1 stage 2).
* **The door sits on the spawn.** `door_entry_west` (0,5); the checkpoint is (1,5) and `safe_anchor_entry` (1,4), one tile from the aperture (same fault as the old concourse).
* **Invisible dividers.** The shutter line (x = 8) and the inner divider (x = 11) are collision segments with no art except the shutter itself.
* **Frontal / unsheared art** (TLF-078 rows): the N-wall counterweight gear (3 states) and both fire shutters (W-face, 2 states) need sheared variants.
* **No lighting yet** (ADR-026: maintenance A 3, "nearly unlit").

## 1. Shape and size

* Grid **25 × 16**, rectangle: outline `[[0,0],[25,0],[25,16],[0,16]]`. 400 cells (2.9× today), W+H = 41.
* N wall y = 0 and W wall x = 0 stay straight and tall; S and E edges are low/open (rule R2). The room grows **east** (slack between the clusters) and **south** (y 10..16); nothing that is mounted on the N wall moves in y.
* Bands after the rebuild (the three gate lines keep their order):
  * **A, entry hall** x 0..7 (7 wide): arrival, checkpoint, SO-02 hatch side.
  * **B, gear bay** x 7..16 (9 wide): counterweight gear (N wall), reset valve, tech log, fire shutter.
  * **C, pocket** x 16..19 (3 wide, unchanged on purpose: the airlock between the shutters, PZ-002 R1 geometry).
  * **D, exit hall** x 19..25 (6 wide): inner-shutter exit, east door.
* Builder: `build_room_from_shape.py --outset 0.25 design/ch01/rooms_v2/maintenance_bay.json` (dry run first, diff in the handoff).

## 2. Rigid clusters (every distance inside a cluster is unchanged)

Coordinates are tile corners, `tile(x,y) = (320+16(x−y), 64+8(x+y))` (same origin as today, TileMap at (304,64)). y never changes.

**Cluster H (CH1-SO-02 hatch), shift x + 4:**

| Object | Old tile | New tile |
|---|---|---|
| `safe_anchor_entry` | (1,4) | (5,4) |
| `checkpoint` | (1,5) | (5,5) |
| `n11_hatch_tech` | (2,3) | (6,3) |
| `hatch_01`, `hatch_threshold` | (3,3) | (7,3) |
| `exit_trigger_hatch` | (4,3) | (8,3) |
| `hatch_plate_01`, `hatch_residue` | (2,6) | (6,6) |
| `doc_hatch_chart` | (2,7) | (6,7) |
| `bell_plate_01` | (1,8) | (5,8) |
| Bulkhead (segments + `Bulkhead` modules) | x = 3, y 0..2.25 and 3.75..10 | x = 7, y 0..2.25 and 3.75..**16** (extend the south run to the new S edge, same module art) |

**Cluster BC (CH1-PZ-002 both stages), shift x + 8:**

| Object | Old tile | New tile |
|---|---|---|
| `reset_anchor_01` | (4,6) | (12,6) |
| `safe_anchor_west` | (5,4) | (13,4) |
| `counterweight_gear` (N wall) | (5,1) | (13,1) |
| `gear_residue` | (5,2) | (13,2) |
| `fire_shutter`, `shutter_threshold_trigger` | (8,4) | (16,4) |
| `doc_tech_log` | (7,9) | (15,9) |
| `safe_anchor_east`, `exit_trigger_east` | (10,4) | (18,4) |
| `inner_shutter`, `inner_shutter_threshold` | (11,4) | (19,4) |
| `doc_inner_shutter_plate` | (11,1) | (19,1) |
| `exit_trigger_east_02` | (12,4) | (20,4) |
| ShutterDividers | x = 8, y 0..3.25 and 4.75..10 | x = 16, y 0..3.25 and 4.75..**16** |
| InnerDivider | x = 11, y 0..3.25 and 4.75..10 | x = 19, y 0..3.25 and 4.75..**16** |

Every stand spot and casting spot in `CH1-PZ-002.md` R1.5 and `CH1-SO-02.md` moves with its cluster (+4 or +8 in x, in px +64/+32 per +4 tiles: Δpx = (16·Δx, 8·Δx)). TEST-PZ002-R03 (Freeze is required) and the SO-02 bell-decoy/hatch timing tests must pass unchanged in logic, only with translated coordinates.

**Not in a cluster:**

| Object | Old tile | New tile | Why |
|---|---|---|---|
| `door_entry_west` + archway | (0,5) | **(0,5)** | W wall, unchanged; trigger = the thin aperture only |
| door `Spawn` (arrival) | (1,5) area | **(2,5)** | 2 tiles inside, free floor on every side (rule 10) |
| `door_exit_east` + archway | (13,4) | **(25,4)** | on the E edge (x = w, as concourse v2); 5 tiles past `exit_trigger_east_02` |

## 3. Dividers must be visible (lesson from TLF-080)

* Bulkhead (x = 7): keep its module art, extended to y 16. Sol/Fable must confirm it does not hide floor or Elias west of it (R2: a tall run parallel to the W wall hides the floor behind it; if it does, the south run from y 10 to 16 uses the low partition instead).
* Shutter line (x = 16) and inner divider (x = 19): dress both runs with the existing `ch01_env_wall_partition_low_e_idle.png` exactly like concourse v2 (whole 2-tile modules, halves at the shutter openings, `centered=false`, offset = −pivot, no new collision). The shutter sprites stay in their openings (1.5 tiles).
* Add a divider sweep test for all three lines (gate closed: no crossing), as TLF-080 did.

## 4. Space rules check (PATTERN 8-10)

* W+H 41 (40..52 ✓). 400 cells / 22 objects = 18.2 (✓ ≥ 18).
* Arrival (2,5): free floor x 0..4, y 3..7 (✓ 2 tiles each side); the door is the spawn's own door (thin aperture + 3 s sweep left/up/down).
* Routes: the walking line y ≈ 4..5 crosses three 1.5-tile openings (hatch, fire shutter, inner shutter). Band C stays 3 wide by design.
* No prop within 1 tile of a doorway.

## 5. Art, lighting, shadows

* Wall fixtures (TLF-085b art, Sol, or Argon after his quota returns): `counterweight_gear` N-wall sheared variant (idle, slipping, frozen); fire shutter W-face variant (closed, raised) used by both shutters. Flash builds with today's art as marked placeholders, as in TLF-080.
* Lighting (ADR-026, Opus after the build): maintenance A 3 "nearly unlit"; one cue 2/1 at the current decision (fire shutter + gear), Elias's whole body inside lift 2; if the dark stress test fails, A 2. Shadows per TLF-084/ADR-027 once accepted.

## 6. Landing criteria (TLF-085)

1. Outline above; builder dry run reviewed; `hidden_floor_cells()` empty; `metadata/room_shape`.
2. Clusters H and BC moved rigidly (pixel deltas (64,32) and (128,64)); CH1-PZ-002 (both stages, R03) and CH1-SO-02 real-input segments and negatives pass; Freeze unlock guards pass.
3. Door sweep from (2,5): left/up/down 3 s never triggers `door_entry_west`; divider sweeps for x = 7, 16, 19 with the gates closed.
4. Stand spots within 2.6 px; apertures ≥ 1.5 tiles; camera bounds at arrival, hatch, gear, pocket, east door (real 960×540 view; explicit bounds asserted).
5. `test_ch01_sort_order.gd` and `render_manifest.json` rows for this room only (edit in place); collision baseline for this room only; graph data + `ROOM_GRAPH.md` rows.
6. Windowed Forward+ 960×540 screenshots at arrival, hatch, gear bay, pocket, east door; full validate 0 failed / 0 SCRIPT ERROR; python builder tests.
