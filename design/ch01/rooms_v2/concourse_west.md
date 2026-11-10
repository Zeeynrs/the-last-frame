# Concourse West v2 (room 2, TLF-080)

Author: Lead · Status: DRAFT for the owner (2026-11-10) · ADR-023, ADR-025, `PATTERN.md` rules 8-12 · Source of the change: owner feedback on the old room (2026-11-10)

## 0. Why the room is rebuilt (owner feedback, measured)

* **Cramped.** The old room is 16 × 12 tiles (192 cells). The entry strip, where the player starts, is only **2.5 tiles wide** (x 0..2.5, the turnstile line is at x = 2.5), and the strip is also the room that holds the checkpoint, the courier and the gate. The pilot is 360 cells; the target for main rooms is W+H 40..52.
* **The door sits on the spawn.** `door_entry_west` is at tile (0.5, 4.5) and Elias appears at (1.5, 4.5), one tile away. Pressing left walks into the door aperture, so the player cannot go left at all.
* **Frontal props.** The three flap dials, the ticket validator, the ticket-terms notice, the call box and the mounted conduit are drawn frontal (TLF-078 audit rows, `currently_frontal = y`). They read as facing the screen instead of sitting on the wall.
* **Lighting is not started.** ART_BIBLE Appendix D wants dark, cold, selectively lit rooms; the owner asks that lighting starts from now on (TLF-082).

## 1. Shape and size

* Grid **28 × 16** tiles, rectangle, no cut: outline `[[0,0],[28,0],[28,16],[0,16]]`. 448 floor cells (today 192, 2.3×), W+H = 44. Floor extent about 720 × 360 px: about 0.75 screen wide, 0.67 tall plus walls, so the camera scrolls horizontally and only a little vertically.
* Walls: tall N wall (y = 0, x 0..28) and tall W wall (x = 0, y 0..16). Low partitions on the S and E sides only where the old room has them (S edge y = 16, E edge x = 28, door opening at (28, 8)). N/W walls stay straight, no floor hidden (`hidden_floor_cells()` empty).
* Two zones, split by the turnstile line **x = 8** (the old line at x = 2.5):
  * **Entry hall** x 0..8 (8 × 16 = 128 cells, was about 30): spawn, checkpoint, courier, call box, ticket-terms notice, conduit.
  * **Concourse hall** x 8..28 (20 × 16 = 320 cells): dials, validator, bench, pillar, four commuters, the east door.
* Builder: `build_room_from_shape.py --outset 0.25` (dry run first, keep the diff in the handoff).

## 2. Objects (tile, then why there)

All ids unchanged. Tiles are (x, y) with x along the N wall, y along the W wall. Where an old object belongs to a puzzle cluster, the cluster is **translated as a rigid block**, so every puzzle distance (17.9 px stand spots, TEST-AU-08, PZ-001) stays exactly as before.

| Object | Old tile | New tile | Note |
|---|---|---|---|
| `door_entry_west` + archway | (0.5, 4.5) | **(0, 8)** | W wall, middle. Trigger is the thin aperture only; the door `Spawn` marker is at **(2, 8)**, 2 tiles inside |
| Elias arrival (door `Spawn`) | (1.5, 4.5) | **(2, 8)** | 2 tiles from the door, open floor on all sides, the player can walk left, up and down |
| `checkpoint` | (1.5, 4.5) | **(3, 8)** | beside the arrival, as in the pilot |
| `safe_anchor_east` | (1.5, 4.5) | **(7, 8)** | puzzle cluster anchor (gate −1 tile), kept 1 tile west of the gate |
| `turnstile_gate`, `turnstile_footprint` | (2.5, 4.5) | **(8, 8)** | gate stands in the divider opening: **2 tiles** wide (≥ 1.5); dividers run y 0..7 and y 9..16 along x = 8 |
| `turnstile_trace_anchor` | (3.0, 4.5) | **(8.5, 8)** | cluster offset kept |
| `n05_courier` (statue, Trace unlocks Rewind) | (1.5, 5.5) | **(7, 9)** | cluster offset (0, +1) from the anchor, entry side of the gate |
| `reset_anchor_01` | (3.5, 6.5) | **(9, 10)** | cluster offset kept |
| `conduit_01` (mounted on the W wall, falls) | (2.5, 8.5) | **W wall, (0.5, 12)** | mounted on the W wall face with the W variant; its stand spot and puzzle rules come from `CH1-PZ-001.md`; keep the fall state on the floor |
| `call_box_09` (W wall phone) | (1.0, 3.0) | **W wall, (0.5, 3)** | W-face wall fixture, 5 tiles north of the door |
| `doc_ticket_terms` | (9.5, 8.5) interior | **W wall, (0.5, 14)** | plaque on the W wall face (TLF-078 W target), 6 tiles south of the door |
| `safe_anchor_west`, `exit_trigger_concourse` | (4.5, 4.5) | **(10, 8)** | 2 tiles east of the gate, on the line to the east door |
| Digital clock `digital_clock_2359` + `Clock_3` | (5, −3) | **N wall, (11, 0)** | one clock, N-face variant (`..._n_idle`, same art as the pilot) |
| `dial_line` | (9.5, 0.5) | **(15.5, 0.5)** | N wall, N-face wall variant (TLF-081) |
| `dial_platform` | (11.5, 0.5) | **(17.5, 0.5)** | 2 tiles apart, as before |
| `dial_time` | (13.5, 0.5) | **(19.5, 0.5)** | |
| `reset_anchor_02` | (8.5, 0.5) | **(14.5, 0.5)** | cluster offset kept |
| `ticket_validator` (console + footprint) | (14.5, 1.5) | **(20.5, 1.5)** | freestanding console against the N wall: facing variant (PATTERN rule 9) |
| `ConcourseBench` | (12, 3) | **(13, 2)** | along the N wall, facing into the room |
| `support_pillar_01` (collision) | (9.5, 4.5) | **(17, 11)** | south of the walking line y = 8, not on it |
| `doc_evac_notice` | (8.5, 5.5) | **(16, 10)** | beside the pillar, detour from the line |
| `door_exit_east` + `staff_door` + archway | (15.5, 4.5) | **(28, 8)** | E opening at least 1.5 tiles; the staff door keeps its Blocker |
| `n06_red_coat`, `n07_briefcase`, `n08_father`, `n09_teen` | (13.5, 5.5), (13.5, 7.5), (13.5, 9.5), (11.5, 8.5) | **(22.5, 9.5), (22.5, 11.5), (22.5, 13.5), (20.5, 12.5)** | rigid block shifted (+9, +4): stays 1.5+ tiles south of the walking line y = 8; statue rule P (TEST-CM-05) unchanged |

No new objects, no new text. Beat sheet dressing (kiosks, luggage) is **not** added here; if the owner wants more dressing it is a later task, one prop at a time, with its art.

## 3. Space rules (owner rule, measured on this room)

These are PATTERN rules 8-10, checked here:

1. **Free width.** Every route between two interactive things is at least **3 tiles wide**; the arrival has at least 2 free tiles on every side (here: x 0..8 around (2, 8)).
2. **No door within 3 tiles of a spawn or checkpoint.** (Here: 2 tiles from the arrival to the door aperture because the arrival is the door's own `Spawn`; the door trigger is the thin aperture only and a sweep test proves a left press from the arrival never triggers it.)
3. **Density.** At least **18 floor cells per object** (pilot: 360 cells / ~20 objects). Here 448 cells / 25 objects = 17.9; if a probe shows a clump, move the decor, not the puzzle.
4. **Props against walls** are on the wall plane with the matching variant (TLF-078, PATTERN rule 9); no prop within 1 tile of a doorway.

## 4. Camera and lighting

* `metadata/room_shape` on the room root; spawn view shows the entry hall and the gate, the east view shows the dials and the east door. On entry the camera snaps.
* Lighting (TLF-082): this is the first room that gets the lighting model. Mood from ART_BIBLE Appendix D table: *dark open space, selective silhouettes of architecture, broad low-value ambient to reveal exits*. Focal lights: the gate and the 23:59 clock; the dials stay readable; no golden floodlighting.

## 5. Landing criteria (TLF-080)

1. Outline above; builder dry-run diff reviewed; `hidden_floor_cells()` empty.
2. Puzzle clusters keep their relative geometry; PZ-001 and PZ-002 real-input segments pass with the new coordinates; TEST-AU-08 passes with the real colliders (courier is the nearest Trace candidate from the entry anchor).
3. Door sweep: from the arrival, a continuous left, up and down press for 3 s never triggers `door_entry_west`; with the gate closed the player never enters the east door.
4. Every stand spot reachable within 2.6 px; apertures at least 1.5 tiles; statue rule P holds.
5. Sort order rows for `ch01.concourse_west` in `test_ch01_sort_order.gd` / `render_manifest.json` updated for the moved objects (**do not overwrite other rooms' rows; add-only for review docs**).
6. Collision baseline `test_collision_freeze_all_10_rooms` re-baselined for this room only, with the diff explained.
7. Windowed screenshots at the arrival, the gate, the dials and the east door; Sol checks facing and overlap.
8. Full validate 0 failed, no SCRIPT ERROR; python builder tests if `tools/content/` changed; the owner plays the room.

## 6. Open points for the owner

* Size: 28 × 16 (about 2.3× the cells). If it still feels tight in play, widen to 32 × 18 before more dressing.
* Whether the entry door stays on the W wall (as now) or moves to the N wall later (needs a Sol-reviewed N door).
