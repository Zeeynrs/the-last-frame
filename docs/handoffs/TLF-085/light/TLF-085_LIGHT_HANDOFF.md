# TLF-085: Maintenance Bay v2 lighting and shadows (ADR-026 + ADR-027 round 2)

**Branch** `agent/opus-core-tlf085-light`, built from:
- Flash's tip `bc4a87e` (root archways removed; my own archway commit was dropped, as the Lead asked);
- my ADR-027 round 2 `40ac555`;
- the concrete recolour `d040470` (`docs/handoffs/TLF-085/concrete/`).

Not merged. Visual review: Fable/Sol.

## Result: A 2, one cue, shadows, fill 1, Elias zone 1/0

**The A 3 dark stress test fails**, so the room uses the ADR-026 fallback, as Sol's TLF-082 §3 and the Lead prescribe.

| Setting | Value |
|---|---|
| `metadata/lighting` | A 2, `exempt_from` 25, `shadows` on, `fill_lift` 1 (applied: A − 1 = 1), fill ADD, Elias zone 1/0 (radius (18,28), inner 0.85) |
| `Lighting/ShutterFloor` | the cue's floor pool: ellipse at (496,216), radius (64,32), 2/1, floor indices 00–05. The casting spot (480,208) is in the core, the shutter aperture is in the pool, and the inner shutter is outside it |
| `Lighting/ShutterGearBody` | the cue's body region: a quad over the fire-shutter and counterweight-gear sprites, (478,118)–(546,234), lift 2, indices 11–24 only. The ceramic wall ramp 06–10 behind the gear is never lifted |

That is one purposeful cue and two entries. There is no helper and no other light (Sol: "1 purposeful cue").

## Dark stress test (A 3 with Elias zone 2/0, against A 2)

- **Method:** each shot is taken twice on the same frame, with only the ambient and the Elias zone overridden (`TLF_A=3 TLF_ELIAS=2/0`). Per decision object and doorway, the tool measures:
  - the share of its opaque sprite pixels at index 00 (merged into the margin colour);
  - the distinct indices left;
  - the greyscale contrast against a 4 px ring.

  Logs: `logs/capture_<shot>.log` (A 2) and `logs/capture_<shot>_a3.log` (A 3).

**Pixels at 00, gear shot** (other shots match within ±2 points, except the inner shutter in the pocket shot: 26% / 43%):

| Object | Unlit | A 2 | A 3 |
|---|---:|---:|---:|
| bulkhead (tall module by the hatch) | 2% | **17%** | **68%** |
| east archway | 14% | 45% | 67% |
| west archway | 14% | 60% | 67% |
| inner shutter (PZ-002 stage 2) | 12% | 34% | 56% |
| reset console | 13% | 25% | 55% |
| hatch technician | 20% | 33% | 50% |
| hatch plate | 31% | 49% | 63% |
| counterweight gear / fire shutter (the cue) | 27% / 12% | 29% / 16% | 29% / 16% |

- **Distinct indices left at A 3:** 4 on the bulkhead, the hatch and the technician (5–7 at A 2).
- **The floor capsule at A 3:** the lift-2 Elias zone lifts the floor receivers beyond the fill, by 243 px at the gear, 353 at the technician, 377 at the arrival and 514 at the east door. That is the "moving spotlight" Sol rules out (`stress_east_x2_a3_a2.png`, greyscale panels).
- **At A 2:** 0 capsule px in all six shots.
- **Verdict:** A 3 loses the bulkhead, both doorways, the inner shutter and the SO-02 side into the margin, and needs a capsule to keep Elias at lift 2. **A 2 passes.**
  - Every decision object keeps 5–9 indices; the worst is the west archway at 60% 00, and its frame and amber strip still read in native and greyscale.
  - Elias's body is at k 1 everywhere.

**See:** `stress_<shot>_a3_over_a2.png` (full frames, colour then greyscale) and `stress_<shot>_x2_a3_a2.png`.

## D.7 pack (`docs/handoffs/TLF-085/light/`)

- **Shots,** all with Elias at Flash's spec spots:

| Shot | Spot |
|---|---|
| arrival | spawn (272,120) |
| tech | (352,144) |
| gear | casting spot (480,208) |
| solved | gear locked, fire shutter raised |
| pocket | (544,240) |
| east | (640,288) |

- **Per shot:**
  - `<shot>_unlit`, `_lit` (shipped), `_lit_hud`, `_lit_noshadows` (the ADR-026 look: no shadows, no fill), plus greyscale copies;
  - `<shot>_x2_unlit_adr026_lit.png`: x2 around Elias, unlit | ADR-026 | shipped, then a greyscale row.
- **Puzzle state:** `cue_x2_before_after_solve.png`, the cue before and after the solve (idle gear and closed shutter, then locked gear and raised shutter).
- **Checks, every A 2 and A 3 shot** (`logs/`):
  - shader vs `LightingPass.output_index()`: **0 / 518,400**;
  - off-palette: **0** in-engine and **0** in the Python recount (`palette_recount.txt`, 23 frames);
  - setting off == unlit: true;
  - against the ADR-026 look, **0** changed px for each of: exempt (≥ 25), non-receiver, and off the floor mask;
  - Elias: 0 movable body px below lift A − 1.
- **Cost:** bake at entry 3.0–3.1 ms (map 704×416 plus floor mask). Viewport GPU is 0.113 ms lit against 0.035 ms unlit, on this PC.

**What the shots show:**
- **The cue leads:** the floor pool is in front of the shutter, and the gear and shutter are at their art value.
- **Shadows:** the concrete (recoloured) now takes the fill and the shadows: AO along the N/W walls and the three divider lines, and contact and cast shadows from the grounded props and shutters, falling down-right (visible in `gear_x2_unlit_adr026_lit.png`).
- **The pocket and the SO-02 side** sit at ambient but read.

## Tests

`tests/rendering/test_maintenance_lighting.gd` (3 tests; it passes; `logs/test_files.log`):
- A 2 fallback values, the Elias zone 1/0, and the room validates;
- one cue: the pool's core covers the casting spot and it excludes the inner shutter; the body region excludes indices 06–10 and contains every corner of the gear and fire-shutter sprites;
- the concrete tile is in 01/03/04, all receivers, and the floor mask covers the 416 cells.

**Mutations** (`mutate_light.py.txt`, `logs/mutation_light.log`): 6 of 6 RED: A 3; Elias 2/0; a wall index in the body mask; the floor pool moved to the inner shutter; fill 0; the old steel-ramp tile.

**Also passing:** `test_shadows.gd` 19/0, `test_lighting_pass.gd` 15/0, `test_ch01_sort_order.gd` 3/0, `test_ch01_art_integration.gd` 6/0. The full capped validate is in §Validate.

## Open for the art review

1. **Band edges:** the ShutterFloor ellipse is visible on the concrete as two hard steps. ADR-026 has dither off, so this is by design.
2. **Side band at ambient:** the hatch technician and the inner shutter are readable at A 2 but low-contrast against their surroundings (greyscale contrast about −1 to +1; the stress tables list it). If Sol wants more, the room's only ADR-allowed addition is a 1/0 helper. I have not added one.
3. **Elias zone at the cue:** inside the pool core (lift 2 + fill 1), the Elias zone adds nothing on the floor, which is correct. His contact shadow shows there (ADR-027 round 2 rule).

## Validate

Capped validate of the exact tree `b7b7ebb`:
- **Method:** a fresh renamed `git archive`, run with `validate_capped_guarded.py.txt`. That is the TLF-083 capped script plus the Lead's rule: before every Godot call it waits while any other Godot or Pixelorama process runs. Every call is capped at 120 s.
- **Log:** `logs/validate_capped_b7b7ebb.log` (LF), sha256 `304cf195c753ba229c3f64dc1ccfaf268423eb6b7c4523e64e98b3fc9973c8f6`.

```
[1/3] import: exit 0, 0 ERROR lines, 13 s
[2/3] script check: exit 0, Script check: 200 scripts, 0 failed., 0 ERROR lines, leak check: clean, 7 s
[3/3] tests/chapters/ch01/test_ch01_maintenance_bay_v2.gd exit 0  TESTS: 15 passed, 0 failed | SCRIPT ERROR 0 | leaks clean | 91 s
[3/3] tests/rendering/test_maintenance_lighting.gd     exit 0  TESTS: 3 passed, 0 failed | SCRIPT ERROR 0 | leaks clean | 1 s
[3/3] tests/rendering/test_shadows.gd                  exit 0  TESTS: 19 passed, 0 failed | SCRIPT ERROR 0 | leaks clean | 3 s
=== TOTAL: 68 test files, TESTS: 567 passed, 0 failed, SCRIPT ERROR lines 0, files needing a look: ['test_operator_sighting.gd'] ===
```

- **`test_operator_sighting.gd`:** passes 7/0 with 2 leak lines at exit, flagged the same way in every validate since TLF-084 Part 2; not touched here.
- **`test_ch01_unlock_guards.gd`:** 4/0 in this run; it is intermittent (TLF-085 re-review P3-2).
- **Python:** builder tests 22 OK.
