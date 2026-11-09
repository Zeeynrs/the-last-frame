# TLF-069 technical review of the final SHA `2b5c0b1` (Opus): APPROVE

Branch `adityadaffa522/tlf-069-arrival-platform-v2`, commits 0c47e58 → 0e8c7ec → 2b5c0b1. It is one docs-only main commit behind (`5d7c133`: ADR_LOG and TLF-072.md), with no overlap.

## Results

| Check | Result |
|---|---|
| **Probe:** `precheck/run_probe.sh` on a renamed archive of `2b5c0b1`, stands from the handoff table §2 | `PROBE SUMMARY 0 rule failures`, `TESTS: 1 passed, 0 failed`, 0 SCRIPT ERROR (`probe_full.log`) |
| **Validate:** `tools/validate.ps1` on a fresh `git archive` of `2b5c0b1`, `config/name="TLF Verify 2b5c0b1"`, no BOM | exit 0, **`TESTS: 479 passed, 0 failed`**, leak check clean for the scripts and the test suite, 0 SCRIPT ERROR. The 22 `ERROR:` lines are all from the usual negative tests (`validate_key_lines.txt`). |

## The six WIP findings

| # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | `digital_clock_2359` could not be reached | **Closed** | At (592,200), 170 capsule positions overlap the trigger, smallest gap −19.2 px. The new real-input test `test_digital_clock_2359_dialogue_line_plays` passes in the validate. |
| 2 | `ch01_graph.tres` was stale and two tests skipped it | **Closed** | The data is now 30×18, door E (29,4), anchor (5,15), and both special cases are gone. `test_doorways_match_chapter_graph_def`, `test_safe_anchors_and_checkpoints_match_specs` and `test_every_door_sits_on_its_boundary_wall` pass. `ROOM_GRAPH.md` is updated to match. |
| 3 | Stand-table labels | **Closed** | n02 (3,9), doc (6,2) and pickup (8,14) now match their px. The probe walked the declared stands: each is reached at 0.11 px and picks the right target. |
| 4 | Wall plates crossing the wall foot | **Closed on geometry** | The board and the notice are raised 38 px, like the clocks. The notice now spans y 116..132, 16 px above the N wall foot at its left end. In the new screenshots both sit on the wall face. How they look is Sol's call. |
| 5 | `.import` noise under `design/` | **Closed** | `design/**/*.import` files in the tree: 0, the same as main. |
| 6 | The stand-spot test was thin | **Closed** | It now asserts `choose_best_interactable` / `choose_watch_target` at every stand. |

The other probe results are unchanged from the WIP:
- Door sweep with the gate closed: 166 starts, 0 entries.
- Statues: 3.79, 3.81, 5.52 and 2.20 tiles from the line, and the real walk of the line is clear.
- Camera: centre x 336..496, y 180..204. Of 20 828 reachable positions, 0 views fall outside the bounds.
- `hidden_floor_cells()` is `[]`, and the checkpoint is on the spawn.

## Notes (not blocking)

- `TLF-069_HANDOFF_REPORT.md` §1 labels the clock trigger "(592, 200) (tile 17, 2)". (592,200) is tile **(17,0)**, the wall vertex.
- `tests/spatial/test_every_room_fits_the_fixed_camera` skips the arrival room by its id, which ADR-023 justifies (follow camera). When more v2 rooms land, key the skip on `metadata/room_shape` instead of on room ids.
- `tools/capture_arrival_v2.gd` runs in a windowed project with the real project name. It sends saves to `user://tlf069_capture_saves`. The real `saves/slot_0.json` was last modified on 2026-11-07 at 16:46, before that folder was created on 2026-11-08 at 23:31, so the real save was not touched. Future captures should still run from a renamed copy, per the standing rule.
