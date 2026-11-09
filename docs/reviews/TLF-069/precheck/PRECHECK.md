# TLF-069 pre-build check of the Arrival Platform v2 layout (Opus, technical reviewer)

Layout: `design/ch01/rooms_v2/arrival_platform.md` at main `0644424`. Read-only review; no room
scene, test or art changed. Measured on a **reference build**:
- `make_ref_scene.py` runs the builder with the approved outline, `--edge-strip 2,S,E` and `--door E,29,4`.
- It then moves today's nodes to the layout tiles.
- Low partitions, corners and new props are not placed.

Then the probe boots `Chapter01.tscn` on a renamed `git archive` copy. It uses the real Player capsule, the real colliders, the RoomRouter bounds and the RoomCamera.

Every tile below is a vertex: `tile_to_px(x, y) = (320 + (x - y)*16, 64 + (x + y)*8)`.

## Cannot work as written (fix before the build)

| # | Item | Measured | Proposed |
|---|---|---|---|
| 1 | `release_lever` (29,2): its stand spot by the SO-01 pattern (south, (29,3) = (736,320)) is 1 tile from the gate (29,4). Today the lever was 3 tiles from the gate ((13,2) vs (13,5)); in v2 only 2. | The 24 × 24 Blocker keeps the real capsule **6.31 px** from (29,3) (rule <= 2.6). That spot is not capsule-free. | **A (recommended):** keep (29,2) and declare the stand **(28,2) = (736,304)**, on the west side where the player comes from the panel. Reached at 0.11 px, and `use` picks the lever. **B:** move the lever to **(29,1)** and stand at (29,2) = (752,312): 0.58 px, picks the lever. |
| 2 | `n04_cleaner` (23,7) is **1.82 tiles** from the line spawn → (8,8) → gate (rule >= 2). The real line walk passes 7.8 px from its footprint. | At x = 23, the rule needs y <= 3.1, which puts it on the selector stand spots (P1), or y >= 7.2, which is on the pit edge. | **(25,7) = (608,320)** is 2.20 tiles from the line, and its stand **(25,6) = (624,312)** is reached at 0.11 px with Trace picking n04. The line walk passes 15.8 px from the footprint. It is 89 px from the `selector_car` stand. (24,7) would be 2.01, too marginal. |
| 3 | `--edge-strip 2,S,E` under the low partitions. | With the TLF-068 PNGs placed per §10.2, the **pit-edge row y = 7 is 100 % hidden (4096 / 4096 px)**, and so is the arm column x = 11 (2048 / 2048 px). The row behind it (y = 6) is 3 % covered. A 16 px parapet on an iso edge covers exactly the 16 px screen band of the row next to it. x = 30 and y = 18 behave the same way, so the strip shows **only in the E doorway gap**. | Lead / Sol decide. Either drop `--edge-strip` for rooms with low S/E partitions, since the partitions carry their own amber dado band, or I add a builder option that paints the strip one row further in (y = 6, x = 10, …). |
| 4 | `--door` is listed as "not used". | Without `--door E,29,4`, the builder paints the doorway tile (29,4) amber: 46 strip cells instead of 45 (`builder_dry_run_*.txt`). Today's room keeps its door tile unpainted. `--door E` cuts no wall, because only N/W modules are ever left out. | If the strip stays, build with `--door E,29,4`. Item 3 still leaves (29,5) amber in the gap next to the terrazzo (29,4). |
| 5 | `CLOSED TRACK` notice "on the pit-edge partition, about (20,8)". | The art is **80 × 16 px, flat**, pivot (40,14). The parapet is 16 px tall and drops 40 px across 80 px of screen width, so a flat plaque cannot sit on it: its ends overhang the floor or the pit by up to about 24 px. (20,8) is also a module seam, because low_S modules sit at odd x. | Sol picks the wall. One option is the tall N wall above the strip, centred on a module (odd x, e.g. (19,0) or (21,0)). |
| 6 | Departure board at (0,12). | **160 × 32 px flat**, pivot (80,28), so it spans 5 W modules. (0,12) is a module seam, because W modules sit at odd y. Neither TLF-063 PNG has a `.import` in the repo yet (they are not used anywhere). | Sol: check the placement. Flash: commit the two `.import` files that the first import creates. |
| 7 | `checkpoint` (6,14) no longer covers the spawn (5,15). | The capsule at the spawn is 10 px from the 28 × 16 zone, so **a new game no longer checkpoints and autosaves at boot**. The first save happens on the walk to the watch, which crosses the zone. Tests that expect "checkpoint reached at spawn" change. | Lead decides: keep (6,14), or put the zone on the spawn (5,15) as today. |

## Checked and fine

- **Shape:** 360 floor cells, `hidden_floor_cells() == []`, `bounds_px() = (16, 0, 800, 384)`. Every object is on the floor. The clock trigger (320,50) sits above the N corner as it does today.
- **Collision:** with the outset of 0.25, the capsule never passes a low S/E edge line (0.0 px, corners excluded).
- **Operator (9,10):**
  - It has no collider. It is 1.71 tiles (20.4 px) from the spawn → (8,8) line.
  - Its trigger (radius 32, offset (−12,8)) keeps today's offset from the pickup (52.6 px). Walking north from the watch fires it just as today's walk east did: the line passes 16.1 px from the trigger centre, against 30.4 px today.
  - From the watch, the figure's 32 × 48 rect is entirely in the view.
  - Not a blocker, and nothing changes.
- **Other statues:** n01 is 3.79 tiles from the line, n02 3.81 and n03 5.52. The real line walk is clear.
- **Stand spots** on the approach side: from the next tile out, the real capsule reaches each one within **0.11 px**, and the game picks the intended target.
  - **Use:** `selector_line` (21,2), `selector_platform` (23,2), `selector_car` (25,2), `doc_last_service` (6,2).
  - **Trace:** n01 (14,4), n02 (4,10), n03 (10,3), n04 (23,6). After fix 2, n04 is at (25,6).
- **Door sweep, gate closed:**
  - From 166 reachable start points within 96 px, each pushed at the door centre and at two points beyond it for 40 frames: **0 entries**, closest end 14.0 px.
  - Statically, no reachable capsule position overlaps `door_exit_east` (smallest gap 4.0 px).
- **Walk-in triggers:** the capsule can reach the pickup, the checkpoint, the clock (from 6 positions, at the same N corner as today) and the Operator trigger.
- **Camera:** the centre stays in x 336..496 and y 180..204.

  | Position | Camera centre | View |
  |---|---|---|
  | Spawn | (336,204) | (16,24)–(656,384) |
  | Watch | (336,204) | (16,24)–(656,384) |
  | Gate | (496,204) | (176,24)–(816,384) |

  Of the 20 829 reachable positions, 0 give a view outside the bounds. The Operator and the watch are on screen together.
- **E doorway art:**
  - The archway at (29,4) spans x 704..736 on screen. It lines up exactly with the low_E module **(30,5)** at (720,344), so leave that one module out for the opening.
  - (30,3) and (30,7) flank it, and no 1-tile end is needed.
- **For Sol:** Elias, statues and upright bodies draw at z 10, above the walls and low partitions at z 5. Elias on the edge row therefore draws over the parapet that stands in front of him.

## Tools (this folder)

- `make_ref_scene.py <repo> <out.tscn> [--set node=x,y] [--no-door]` builds the reference scene.
- `test_zprobe_arrival_v2.gd.txt` is the probe. Sections:
  - A: room facts.
  - B: capsule flood fill.
  - C: four stand spots per object at 17.9 px, with a real-input walk and the target the game picks.
  - D: walk-in triggers.
  - E: door sweep.
  - F: statue-to-line distance and a real walk of the line.
  - G: RoomCamera.

  It reads every position from the scene, so the same file checks Flash's build.
- `run_probe.sh <repo> <sha> <scratch dir> [scene]` makes a renamed `git archive` copy and runs the probe. `TLF_PROBE_STANDS="release_lever=28,2"` declares the stand spots to judge.
- `strip_cover.py <repo>` is the pixel count behind item 3. The `builder_dry_run_*.txt` files are behind item 4.
- Logs:
  - `probe_layout_v1.log`: the layout as written, 2 rule failures (items 1 and 2).
  - `probe_layout_v2.log`: n04 at (25,7) and lever stand (28,2), 0 failures.
  - `probe_layout_v3.log`: n04 at (25,7) and lever at (29,1), 0 failures.
  - All three: `TESTS: 1 passed, 0 failed`, 0 SCRIPT ERROR.
