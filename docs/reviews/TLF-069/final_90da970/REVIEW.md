# TLF-069 technical review of `90da970` (Opus): APPROVE

Branch `adityadaffa522/tlf-069-arrival-platform-v2`. These two commits came after the approved `2b5c0b1`:
- `0728777`: builder round-trip tests for the v2 arrival room.
- `90da970`: Sol's visual findings. The selectors and the lever changed, n03 moved onto the bench, the notice moved down 16 px, and the DepartureBoard was removed.

The branch is one docs-only main commit behind (`5d7c133`), with no overlap.

## Results

| Check | Result |
|---|---|
| **Probe:** `precheck/run_probe.sh` on a renamed archive of `90da970`, sections A–H, stands from handoff §2 | `PROBE SUMMARY 0 rule failures`, `TESTS: 1 passed, 0 failed`, 0 SCRIPT ERROR (`probe_full.log`) |
| **Godot validate:** `tools/validate.ps1` on a fresh `git archive` of `90da970`, `config/name="TLF Verify 90da970"`, no BOM | exit 0, **`TESTS: 479 passed, 0 failed`**, leak check clean for the scripts and the test suite, 0 SCRIPT ERROR. The 22 `ERROR:` lines are the same negative-test set as on `2b5c0b1`. |
| **Python builder tests:** `python -m unittest discover -s tools/content -p "test_*.py" -v` on the same archive | **`Ran 22 tests in 0.398s` / `OK`** |

## Selectors and lever: contact and targeting with the new visuals (probe sections C and H)

### Selectors

- Only the `Presenter` moved, by `(0,-28)`. The interaction circles stay on the floor vertices: (21,1), (23,1) and (25,1).
- From the declared stands (21,2), (23,2) and (25,2), the real capsule reaches **0.11 px**, and `use` picks the right selector each time.
- Each art's bottom-centre is 20 px north of its circle, e.g. (640,220) against (640,240). Measured against the real WallN pixels, it is **0 px below the wall foot**, so nothing lies on the floor.

### Lever

- `Presenter` z 10, absolute, which is `DepthSort.ACTOR_Z`. The texture is now an upright asset, and its sort key is the lever's y, 312.
- From the stand (28,2), the reach is **0.11 px**, and `use` picks the lever.
- With Elias at the stand, his sort key is y 304, so **the lever draws in front of him**. Their sprites overlap by 12 × 28 px on his east side. That is the depth rule Sol asked for: he stands north-west of the lever's contact.
- `test_ch01_sort_order` passes: all 4 sides, and every upright body shares the actor layer.

### Unchanged since `2b5c0b1`

- Door sweep with the gate closed: 166 starts, 0 entries, closest 14.0 px.
- The clock trigger is reachable from 170 positions.
- Camera: 0 of 20 838 reachable positions give a view outside the bounds. Centre x 336..496, y 180..204.
- `hidden_floor_cells() == []`.
- Statues vs the line: n01 3.79 tiles, n02 3.81, n03 4.86, n04 2.20. The real walk of the line is clear.

## Notes (not blocking)

1. **n03 left its tile vertex.**
   - The whole node moved from (448,160) to **(448,169)**: the Area2D, the trace circle and the 12 × 8 Footprint. Its tile is now (10.56,2.56).
   - The stand (10,3) is now **16.0 px** from the object instead of the 17.9 px tile step. It still works: reached at 0.93 px, and Trace picks n03.
   - The handoff's numbers for this are wrong. They use a capsule "radius 3.9 px", but the capsule is r 6, h 16, horizontal, so it reaches 8 px each side.
   - The real clearance from the capsule at the stand to the Footprint is **sqrt(8² + 1²) − 6 = 2.1 px**, not 6.1 px. The reach claim "14 + 3.9 = 17.9" also does not describe the code.
   - Please correct the handoff text. Accepting n03 off-grid is the Lead's call. It works, and it is the only way to sort him in front of the bench backrest without moving the bench.
2. **Wall-face edges, for Sol.** These are measured against the WallN art's opaque rows.
   - Each selector's top-right corner rises up to **6 px** above the wall's top edge, over 12 columns: x 640–651, 672–683 and 704–715.
   - The CLOSED TRACK notice's right end rises up to **5 px** above it, over x 556–566.
   - Nothing hangs below the wall foot. In the screenshots this reads as the corner overlapping the wall cap line. Whether that is acceptable is Sol's call.
3. **Handoff labels.** The clock trigger (592,200) is labelled "tile (17, 2)"; it is (17,0). n03 at (448,169) is labelled "tile (10, 2)".
4. **Builder test `read()`.** `tools/content/test_build_room_from_shape.py` `read()` dropped `newline=""`. The repo blobs are LF, so the result is the same. The change only stops the test noticing a CRLF working copy.

## Probe change in this review (`precheck/test_zprobe_arrival_v2.gd.txt`)

- **Section C:** a declared stand that is not exactly one tile step from an off-grid object is now judged as well. Each stand also prints its distance to the object.
- **Section H:**
  - Wall-mounted art (selectors, notice) against the opaque rows of the real WallN sprites, reported as notes.
  - The lever's layer and sort against Elias at its stand, plus the target picked there.
