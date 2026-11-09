# TLF-069 focused re-check of `53b4010` (Opus): APPROVE

Branch `adityadaffa522/tlf-069-arrival-platform-v2`. This is a focused re-check of what changed since my APPROVE of `90da970` (`c50351b`):

- **Merged art:** TLF-073 sheared plaques (`e0648b3`) and TLF-077 sheared wall fixtures (`2701746`).
- **`6ae10f1` / `b675a90`:** these commits integrate that art into `arrival_platform.tscn`.
- **`53b4010`:** docs, screenshots and the capture tool only. The code tree is the same as `b675a90`.

Between `90da970` and `53b4010` there are no `scripts/` changes. The only scene change is `arrival_platform.tscn`, and the only test change is `test_ch01_art_integration.gd`.

## Results

| Check | Result |
|---|---|
| **Probe:** `precheck/run_probe.sh` on a renamed archive of `53b4010`, sections A–H, stands from handoff §2 | exit 0, `PROBE SUMMARY 0 rule failures`, `TESTS: 1 passed, 0 failed`, 0 SCRIPT ERROR (`probe_full.log`) |
| **Godot validate:** `tools/validate.ps1` on a fresh `git archive` of `53b4010`, `config/name="TLF Verify 53b4010"`, no BOM | exit 0, **`TESTS: 479 passed, 0 failed`**, leak check clean for the scripts and the test suite, 0 SCRIPT ERROR. The 22 `ERROR:` lines are the same negative-test set as on `90da970`; only the object ids differ. `PASS: test_room1_arrival_platform_kit_complete`. (`validate_key_lines.txt`) |
| **Python builder tests:** on the same archive | `python -m unittest discover -s tools/content -p "test_*.py" -v`: **`Ran 22 tests in 0.272s` / `OK`** |

## Re-checked items

### Selectors (sheared N art `ch01_prop_selector_{line,platform,car}_n_pos0..2`)

- **Stand reach and target:** from the declared stands (21,2), (23,2) and (25,2), the real capsule reaches **0.11 px**, and `use` picks the right selector each time.
  - The two other free sides of each selector also work.
  - The (x,0) side is inside the wall, as before.
- **Wall silhouette (section H, against the real WallN pixels):** for all three, **0 px above the wall top and 0 px below the wall foot**, over 26 columns each, all of them on a wall module.
  - The 6 px corner overhang on `90da970` is gone.
  - Section H measures the pos0 texture that is shown at load. I also compared the alpha of pos1 and pos2 with pos0 column by column. Neither has an opaque pixel outside pos0's span in any column, so every lever position stays inside the wall face.
- **Layout:** the art boxes are (624,172), (656,188) and (688,204), each 32×48, at z 7 (absolute). All 9 textures are 32×48, so the presenter's fixed `offset (-16,-40)` still fits.
  - The interaction circles are unchanged on the floor at (640,240), (672,256) and (704,272).

### Wall fixtures (section H)

| Fixture | Art rect | Wall | Above top | Below foot | Columns off a wall module |
|---|---|---|---|---|---|
| `ClosedTrackNotice` (`_n_idle`) | (488,116) 80×56 | N | 0 px | 0 px | 0 / 80 |
| `Clock_8` (`digital_clock_2359_n_idle`) | (576,147) 32×40 | N | 0 px | 0 px | 0 / 31 opaque |
| `DepartureBoard` (`nowhere_w_idle`) | (64,68) 160×112 | W | 0 px | 0 px | 0 / 160 |

The notice's 5 px overhang on `90da970` is gone. `Clock_2` at (400,66) is removed. `test_room1_arrival_platform_kit_complete` asserts it is null.

### Clock trigger

`digital_clock_2359` is still at (592,200), tile (17,0). It is reachable: 170 capsule positions overlap it, with the smallest gap −19.2 px. It lies directly below the new `Clock_8` art, which spans x 576..608.

### No regressions

- **Door sweep, gate closed:** 166 starts, 0 entries, closest 14.0 px. Static gap to `door_exit_east`: 4.0 px.
- **Camera:** 0 of 20 838 reachable positions give a view outside (16,0,800,384). Centre x 336..496, y 180..204.
- **Room shape:** `hidden_floor_cells() == []`, and the four low-edge lines give 0.0 px reach past the edge.
- **Lever:** z 10 absolute, it draws in front of Elias at (28,2), and `use` picks it.
- **Statues:** unchanged: 3.79, 3.81, 4.86 and 2.20 tiles from the line, and the line walk is clear.

### `test_ch01_art_integration.gd` selector rows

- **What the three rows assert:** each `selector_*/Presenter` exists, sits at `(0,-28)`, and has 3 textures with `[0]` ending in `selector_<id>_n_pos0.png`.
- **The scene matches:** each `Presenter` has `textures = [<id>_0, <id>_1, <id>_2]`, and those ext_resources point to `_n_pos0`, `_n_pos1` and `_n_pos2`.
- `test_room1_arrival_platform_kit_complete` passes in the validate.
- The rows check only `textures[0]`; I checked `[1]` and `[2]` by reading the scene.

### The selector change touches no other room

- `selector_switch_presenter.gd` is unchanged. The textures are a per-instance `@export` array, set in `arrival_platform.tscn` only.
- At `53b4010`, the only scene that uses `SelectorSwitchPresenter` or any `ch01_prop_selector_*` texture is `arrival_platform.tscn`, the same as on `90da970`.
- The old `ch01_prop_selector_*_pos*.png` files stay in the tree, unchanged. No scene references them any more; only `design/art/TLF-057_VERIFICATION.txt` mentions them.

## Notes (not blocking)

1. **Missing `.import` files.** The 22 new PNGs from TLF-073 and TLF-077 (`assets/props/ch01/*_n_*`, `*_w_*`) are committed without `.png.import` files. The other 128 PNGs in `assets/props/ch01` have them. Godot generates them on import, so the validate and the game are unaffected. But the first editor open will leave 22 untracked files, so commit them with the art, as for the other props.
2. **Stale handoff values.** `TLF-069_HANDOFF_REPORT.md` §3 "Wall and Fixture Expansions" still says `Clock_8` is at `(592, 162)`, where it is now (576,147). It also says the selector `Presenter` is at `position = Vector2(0, -22)`, where it is (0,-28). Elsewhere in the report, these values are correct.
3. **Earlier notes, now fixed:**
   - The handoff now gives the correct n03 clearance (2.1 px) and n03 tile (10.56,2.56).
   - The clock trigger is labelled tile (17,0).
4. **Real save:** `saves/slot_0.json` is still dated 2026-11-07 16:46.

## Probe change in this review

Section H now takes a wall prefix (`WallN_` / `WallW_`) per fixture. It adds `Clock_8` and `DepartureBoard`, and it counts art columns that lie over no wall module. Section A also lists the three wall fixtures.
