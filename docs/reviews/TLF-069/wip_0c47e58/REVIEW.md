# TLF-069 technical review of Flash's WIP `0c47e58` (Opus)

Branch `adityadaffa522/wip-tlf-069`. This is a review of the WIP; the final SHA gets a re-run and a validate.

The probe is `precheck/run_probe.sh` on a renamed `git archive` of `0c47e58` (`config/name="TLF Verify 0c47e58"`). `TLF_PROBE_STANDS` is set from WIP_STATUS §1.3:

```
release_lever=28,2;n04_cleaner=25,6;n01_conductor=14,4;n02_student=4,10;n03_old_man=10,3;doc_last_service=5,1;selector_line=21,2;selector_platform=23,2;selector_car=25,2;pocket_watch_pickup=7,13
```

Result: exit 0, `PROBE SUMMARY 1 rule failures`, `TESTS: 1 passed, 0 failed`, 0 SCRIPT ERROR. The log is `probe_full.log`.

## Findings

| # | File / object | Problem | Fix |
|---|---|---|---|
| 1 | `arrival_platform.tscn` / `digital_clock_2359` | **Rule failure.** The trigger moved from (320,50) on main to (400,66), the Clock_2 sprite position. That is up on the N wall face, and the capsule cannot get closer than **14.7 px** to it, so **Elias's 23:59 clock line can never play**. No test catches this: `test_ch01_narrative_beats` fires the trigger through the service, not by walking. | Put the trigger on the floor at the wall vertex under **Clock_8, (17,0) = (592,200)**. `probe_clock_points.log` measures this: 170 capsule positions overlap it, overlap box (570..610, 198..224), well clear of the route and of every stand spot. Under Clock_2, (400,104) is also reachable, but it overlaps the `doc_last_service` west stand (5,1), so reading the document would fire the clock line too. Main's (320,50) still works, but only from 6 positions in the N corner. |
| 2 | `data/chapters/ch01/ch01_graph.tres` + `tests/chapters/ch01/test_ch01_playthrough.gd` | The graph data still describes the old room: `width 14, height 10`, door `door_exit_east` (13,5), anchor (7,5). The two tests skip it instead: `test_doorways_match_chapter_graph_def` and `test_safe_anchors_and_checkpoints_match_specs` gained `if arrival …: continue` cases. | Update the arrival entry to `width 30, height 18`, door E `x 29, y 4`, anchor `x 5, y 15`, then delete both special cases. `test_every_door_sits_on_its_boundary_wall` still holds, because E needs x == w − 1 = 29 and 1 <= y <= 16. Runtime code reads only the door ids from this file, so the change is data and tests only. |
| 3 | `docs/handoffs/TLF-069/WIP_STATUS.md` §1.3 | Three rows give a tile that does not match their px. The px values are what the tests use. **`n02_student`:** "(4,10) → (224,160)", but (224,160) is **(3,9)** and (4,10) is (224,176). **`doc_last_service`:** "(5,1) → (384,128)", but (384,128) is **(6,2)** and (5,1) is (384,112). **`pocket_watch_pickup`:** "(7,13) → (224,240)", but (224,240) is **(8,14)** and (7,13) is (224,224). | Fix the labels in the handoff, or the px. The probe walked all four sides of every object, and the tiles and px both work: 0.11 px and the right target each time. Nothing changes in the game. |
| 4 | `arrival_platform.tscn` / `Wall_Fixtures/DepartureBoard`, `ClosedTrackNotice` | Both flat sprites are pinned with their pivot on the wall's foot vertex, where the clocks are raised 38 px. The notice spans x 488..568, y 154..170; the N wall foot at x = 488 is y 148, so its left part lies **6–22 px on the floor**. The board spans x 64..224, y 124..156; the W wall foot at x = 224 is y 112, so its right end lies **12–44 px on the floor**. A flat plate on a 2:1 wall always drops 40 px over 80 px (the notice) or 80 px over 160 px (the board). | This is a visual call for Sol, not a technical blocker. Today's screenshots predate decision 6: they still show the notice at the pit edge. Sol needs the recaptured shots. |
| 5 | `design/art/mockups/*.png.import` (25), `design/ch01/rooms_v2/arrival_platform_v2_layout.png.import` | Editor noise from opening the project. Main commits no `.import` under `design/art/mockups`. | Drop the 26 files from the commit, or the Lead decides on a `.gdignore`. The 17 `assets/**/*.png.import` files (the TLF-068 kit and TLF-063 props) and the `.gd.uid` files are correct to commit. |
| 6 | `tests/chapters/ch01/test_ch01_arrival_platform_v2.gd` | Not wrong, but thin. The stand-spot test walks the spots in a chain, each from the previous one, and does not check which target the game picks. The door sweep uses 4 starts. | Optional: assert `choose_best_interactable` / `choose_watch_target` at each stand. The probe below covers both meanwhile. |

## Checked and fine (probe, `probe_full.log`)

- **Shape:**
  - 360 floor cells, `hidden_floor_cells() == []`.
  - `bounds_px()` == router bounds == (16,0,800,384).
  - Every object is on the floor except the clock trigger (finding 1).
- **Kit placement, checked by hand against TLF-068:**
  - 15 WallN modules at (odd x, 0) and 9 WallW at (0, odd y).
  - 6 LowS_arm at (odd x, 18), 5 LowE_arm at (12, odd y), 9 LowS_pit at (odd x, 8).
  - LowE_strip at (30,1), (30,3) and (30,7). (30,5) is left out for the archway.
  - The 6 corners are on the outline vertices.
- **Stand spots:**
  - From one tile further out, the real capsule reaches every declared stand at **0.11 px**, and the game picks the intended object. The selectors, lever and document use `use`; n01–n04 use `trace`.
  - The lever stand (28,2) is clear of the gate Blocker. (29,3) stays blocked at 6.31 px, as the precheck found.
- **Door sweep, gate closed:** 166 reachable starts within 96 px, 3 goals × 40 frames each, **0 entries**, closest end 14.0 px. Statically, the smallest capsule gap to `door_exit_east` is 4.0 px.
- **Walk-in triggers:**
  - The checkpoint is on the spawn: the capsule overlaps it there, so a new game autosaves at boot again.
  - The pickup and the Operator ApproachTrigger are reachable.
- **Statues vs the line spawn → (8,8) → gate:**
  - n01 is 3.79 tiles away, n02 3.81, n03 5.52, n04 2.20.
  - The real walk of the line is clear. Its closest footprint gap is n04 at 15.8 px.
- **RoomCamera:**

  | Position | Camera centre | View |
  |---|---|---|
  | Spawn | (336,204) | (16,24)–(656,384) |
  | Watch | (336,204) | (16,24)–(656,384) |
  | Gate | (496,204) | (176,24)–(816,384) |
  | Lever | (496,204) | (176,24)–(816,384) |

  - Every view is inside the bounds.
  - `centre_for()` over all 20 828 reachable positions: 0 views outside. Centre range x 336..496, y 180..204.
  - The Operator figure is fully in view from the watch.

## Probe options added in this review (`precheck/test_zprobe_arrival_v2.gd.txt`)

- `TLF_PROBE_SECTIONS="D"` runs only the listed sections. A and B always run.
- `TLF_PROBE_POINTS="label=x,y,r;..."` reports whether a circle trigger at (x,y) with radius r is reachable, and the box of capsule positions that overlap it. `probe_clock_points.log` comes from this.
