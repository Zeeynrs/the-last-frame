# TLF-084 round 2: shadows in pools, the fill on the floor only, rebake on blocker toggles

**Branch** `agent/opus-core-tlf084-r2`, from `origin/main` `f7649fd`. **Code** `af2880f` (this handoff and the validate log follow it, docs only). Not merged.
**Input:** Fable stand-in review `docs/reviews/TLF-084/TLF-084_8f7cb2d_FABLE_VISUAL.md` (P2-1, P2-3, P3); Lead brief 2026-11-11.
**Proof pack:** `docs/handoffs/TLF-084/r2/`, made by `tools/capture_tlf084r2.gd` (windowed Forward+, renamed scratch copy, every Godot call capped at 120 s) and `r2/make_pack_r2.py.txt`.

## 1. P2-1: shadows read inside the focal and helper pools

**Rule (shader and `LightingPass.output_index`):** `k = clamp(max(A − lift, 0) + shade, 0, 3)`. `lift` is the light lift with the floor fill.

**Why this rule and not another:**
- **A shadow is always `shade` steps below the light around it.** Under round 1, a pool lifted above A (the gate core is 2 + fill 1 = 3 at A 2) spent its surplus cancelling the shade. Capping the lift at A removes that surplus and nothing else.
- **No pixel without shade changes.** `max(A − lift, 0)` equals the old `clamp(A − lift, 0, 3)` when shade is 0. Every room without shadows, and every non-receiver, is untouched.
- **Alternatives rejected:**
  - Shade multiplied by a pool factor: there is no basis for picking one factor.
  - Clamping the pool lift to A in `RoomLight`: this also changes non-floor indices such as GateBody on the bodies, which take no shade.

**Measured by rebuilding round 1 on the CPU from the same frames.** The rebuild equals the merged P2 pack's `*_lit_shadows.png` pixel for pixel in all five shots (`r2/palette_recount.txt`).
- **Shaded px** = a shade texel or Elias's contact on a receiver.
- **Showing** = the output differs from the same pixel without shade.

| Shot | Pool | Core: shaded / showing r1 / showing r2 | Band: shaded / r1 / r2 |
|---|---|---|---|
| gate (Elias at the gate) | GateFloor 2/1 | 351 / **9** / **240** | 379 / 298 / 298 |
| gate | EastHelper 1/0 | 0 / 0 / 0 | 197 / 148 / 148 |
| east (Elias at the helper) | EastHelper 1/0 | 76 / 76 / 76 | 197 / 148 / 148 |
| side A 1 | MiraFocal 1/0 | 42 / **0** / **36** | 318 / 296 / 279 |

- **Gate core:** the post's contact and cast and Elias's foot contact show again. See `r2/gate_core_x4_r1_vs_r2.png`, `r2/gate_x2_r1_vs_r2.png` and `r2/gate_change_r1_to_r2.png` (magenta marks where round 2 is darker).
- **Shaded px that still don't show:** these sit on palette index 00, the ramp bottom, which cannot move.
- **The helper core already showed its shade in round 1.** Its lift is 1 + fill 1 = 2, exactly A, so nothing was swallowed there. `r2/east_x2_r1_vs_r2.png` is unchanged around Elias. Fable's "about 60 px in the helper core" did not reproduce with the pixel-exact rebuild, so the east crop shows no change. On the side, the Mira pool at A 1 had swallowed every core shadow (0 of 42); it now shows 36.

## 2. P2-3: the fill (and the shade) only on the floor, and never up to the unlit value

**Rule:**
1. **Receivers are geometric.** A receiver is a floor index (00-05) **on the room's floor mask**. `ShadeBaker.bake()` returns the mask alongside the shade map (same texels, L8, 1 = floor):
   - iso rooms: the `RoomShape` floor polygon, split into convex parts;
   - side rooms: the ASSET_METADATA 13.1 platform floor strip, screen y 378..449 (`floor_y − 16 .. floor_y + 56`): deck, tactile strip, curb and rail trench;
   - legacy rooms without a `RoomShape`: the whole map, which means the index rule only, as before.
   
   The shade uses the same mask, so casts that run off the floor edge into the void or onto a wall stop at the edge.
2. **The fill is at most A − 1** (`RoomLighting.effective_fill()`). At A 1 or A 0 a fill of 1 is not applied, so the open floor stays one step under its art and a pool keeps its step. At A 2 and A 3 the fill is unchanged.

**Measured (pixels whose output the fill changes):**

| Shot | Round 1 | of which off the floor | Round 2 | off the floor |
|---|---:|---:|---:|---:|
| Concourse (any of the 4 shots) | about 92,300 | **280** | about 91,800 | **0** |
| side A 1 (Part 2's shot) | 75,574 | **45,832** (61%) | **0** (A 1: no fill) | 0 |
| side A 2 (extra shot to show the strip) | 20,981 | **2,798** | 18,183 | **0** |

- **Concourse:** the 280 px are the dark opening of the west door in the W wall (`r2/gate_change_r1_to_r2.png`, top left). It goes back to its ADR-026 value. That is the only visible fill change in the room.
- **Side A 1:** the frame is the ADR-026 look plus shade (`r2/side_r1_over_r2.png`): arches and wall darks are no longer lifted, and the Mira pool reads one step above the deck again.
- **Side A 2:** the fill stops at the strip top (`r2/side_a2_r1_over_r2.png`).
- **Off-floor pixels changed against ADR-026 lit: 0 in every shot.**

**Test relaxed:** `test_every_lit_ch01_room_has_shadows_and_the_fill` still asks every lit room for shadows. It asks for fill 1 only at A ≥ 2. At A ≤ 1 the fill is not applied (asserted through `effective_fill`), so its value is free.

**What the mask cannot do:** the pass cannot tell floor art from a prop drawn over the floor. Props standing on the floor still take the fill on their 00-05 pixels, as in round 1. At the N/W edge this does not show as a seam: the floor's AO strip (shade 1) sits on the mask edge and cancels the fill there.

## 3. P3: rebake when a gate or blocker toggles

- **Wiring:** `LightingPass.apply_room` connects to `passage_changed` on every room node that has a `Blocker` (the PuzzleObject API) and disconnects on the next room.
  - **Deferred check:** `set_passage_blocked()` toggles the colliders with `set_deferred` and then emits. The pass defers its check behind those writes.
  - **Rebake condition:** the map is rebaked only when a Blocker collider's `disabled` flag differs from the one it was baked with. A rewind re-emits the same state every tick and costs only that compare.
  - **Setting off:** a toggle drops the stale map and bakes nothing until the pass is shown again.
- **Test:** `test_opening_the_concourse_gate_rebakes_the_map`:
  - **Open:** opening CH1-PZ-001 in the room removes the Blocker's contact rim. The map equals a fresh bake of the open gate, and nothing is baked before the collider changes.
  - **Same state again:** applying the open state again bakes nothing.
  - **Closed again:** gives back the first map texel for texel.
  - **Setting off / on:** turning the setting off drops the map; turning it back on bakes the open gate.
  - **Leaving the room** disconnects the gate.
  - **Capture:** `capture_gate_open.log` shows "bakes 1 -> 2; map == fresh bake of the open gate true" (`r2/gate_closed_vs_open_x3.png`).
- **Correction to the Part 2 handoff (open point 4):** "Entering a solved room bakes no gate-post contact" was wrong.
  - **Why:** once the Blocker is off, the gate's Presenter sprite (actor layer, 32×40) is a caster in its own right. A solved room therefore bakes a smaller contact (rx 11 instead of the bar's 15) and a cast under the post (centre texel shade 2).
  - **What round 2 changes:** opening the gate in the room now gives exactly that same map, so the 24×12 bar's wide contact is what disappears. The post, which still stands in the open art, keeps its own contact.
  - **If the owner wants no shadow under the open post:** add `metadata/shade_skip = true` on `turnstile_gate/Presenter`. It is a one-line scene change and not made here.

## 4. Tests and mutations

`tests/rendering/test_shadows.gd`: 19 tests. For round 2, 5 are new and 3 changed: the two below marked updated/extended, and `test_every_lit_ch01_room_has_shadows_and_the_fill`, relaxed as in §2.
- `test_shade_is_added_after_the_lift` (updated: A 1, lift 2, shade 1 → k 1, was k 0);
- `test_shadows_read_inside_the_focal_and_helper_pools`;
- `test_fill_and_shade_only_on_the_floor_mask`;
- `test_the_fill_never_returns_the_floor_to_its_unlit_value`;
- `test_baked_floor_mask_iso_polygon_and_side_strip` (the Concourse mask is exactly 448 cells × 256 px; side rows 377/378/449/450 pinned to ASSET_METADATA, not to the constants);
- `test_opening_the_concourse_gate_rebakes_the_map`;
- `test_setting_off_skips_the_bake_and_hides_the_pass`, extended: a fill-only room bakes the mask.

**Mutations** (`r2/mutate_r2.py.txt`, log `r2/logs/mutation_r2.log`): 12 of 12 RED.

| Mutation | RED test |
|---|---|
| Old rule `clamp(A − lift + shade)` | after_the_lift, focal_and_helper_pools |
| Fill ignores the mask | only_on_the_floor_mask |
| Shade ignores the mask | only_on_the_floor_mask |
| No A − 1 cap | never_returns_the_floor |
| Side strip top −60 | floor_mask (row 377), after pinning the rows; the first version used the constant and stayed green, fixed |
| Iso mask = whole map | floor_mask |
| No mask for fill-only rooms | setting_off |
| Blockers not watched | gate rebake |
| Rebake on every emission | gate rebake (same state) |
| Rebake before `set_deferred` lands | gate rebake |
| Not disconnected on room change | gate rebake |
| Concourse fill 0 | every_lit_room |

The shader is checked only by the capture tool: shader vs `output_index` mismatches are **0 / 518,400 px in all 7 shots**.

## 5. Proof pack (`docs/handoffs/TLF-084/r2/`)

- **Shots:**
  - Part 2 positions: arrival, gate, dials, east;
  - side at A 1, the Part 2 runtime lighting;
  - side_a2, for this proof only;
  - gate_open, the gate opened in the room.
- **Per shot:** `*_unlit`, `*_lit_shadows`, `*_lit_shadows_hud`, greyscale of unlit and lit, `*_x2_r1_vs_r2` (x2 around Elias; left round 1 as merged, right round 2) and `*_change_r1_to_r2`.
  - **Round 1 CPU frames:** `side_a2_lit_r1_cpu` and `gate_open_lit_r1_cpu`. The other shots' round 1 frames are the P2 pack's `*_lit_shadows`, which the CPU rebuild equals.
- **Extra sheets:** `gate_core_x4_r1_vs_r2.png`, `gate_closed_vs_open_x3.png`, `side_r1_over_r2.png`, `side_a2_r1_over_r2.png`.
- **Checks, every shot (`r2/logs/capture_*.log`):**
  - shader vs reference: 0;
  - off-palette: 0, both in-engine and recounted in Python (`r2/palette_recount.txt`);
  - setting off == unlit: true;
  - against ADR-026 lit, 0 changed px in each of: information, exempt (≥ 25), non-receiver, off the floor mask;
  - unlit frames equal Part 2's byte for byte.
- **Cost:**
  - **Bake time** at entry, with the mask: Concourse 3.3 ms median (map 736×432 plus mask; Part 2: about 3 ms). Every ch01 room is ≤ 3.4 ms median and ≤ 5.4 ms max (`capture_bake.log`), all on this PC. The owner-machine measurement is still open, as in Part 2.
  - **GPU:** round 2 costs the same as ADR-026 lit, within ±0.002 ms per frame.

## 6. Validate

549 passed, 0 failed, 0 SCRIPT ERROR on the exact tree `af2880f`: see §8.

## 7. Proposed ADR-027 wording (the Lead's file, not edited here)

Replace the "Open:" sentence of the "Fill rule as built" bullet with:

> **Round 2 (TLF-084 r2, Fable P2-1/P2-3/P3):** the rule is `k = clamp(max(A − lift, 0) + shade, 0, 3)` (the lift is capped at A before the shade is added, so shadows read inside pools). Receivers are floor indices 00-05 on the room's floor mask, baked with the shade map (iso floor polygon; side platform strip y 378..449); the fill is at most A − 1, so A ≤ 1 rooms get no fill. A blocker that opens or closes in the room rebakes the map.

## 8. Validate result

Capped validate of the exact tree `af2880f`, run with `docs/handoffs/TLF-083/p2/validate_capped.py.txt`. The tree is a fresh renamed `git archive` ("TLF Verify af2880f"). Godot ran one call at a time, each capped at 120 s, with no other Godot process on the machine.

- **Log:** `r2/logs/validate_capped_af2880f.log` (LF), sha256 `293a9f555a811003731545e2100434d8d58254a1837be57812c88a010db6ff7b`.
- **History:** a first run was stopped by Claude Code under low memory (other agents' Godot runs were open). This re-run is complete.

```
[1/3] import: exit 0, 0 ERROR lines, 15 s
[2/3] script check: exit 0, Script check: 195 scripts, 0 failed., 0 ERROR lines, leak check: clean, 7 s
[3/3] tests/chapters/ch01/test_ch01_step1_negatives.gd exit 0  TESTS: 12 passed, 0 failed | SCRIPT ERROR 0 | leaks clean | 104 s
[3/3] tests/rendering/test_lighting_pass.gd            exit 0  TESTS: 15 passed, 0 failed | SCRIPT ERROR 0 | leaks clean | 2 s
[3/3] tests/rendering/test_shadows.gd                  exit 0  TESTS: 19 passed, 0 failed | SCRIPT ERROR 0 | leaks clean | 3 s
=== TOTAL: 66 test files, TESTS: 549 passed, 0 failed, SCRIPT ERROR lines 0, files needing a look: ['test_operator_sighting.gd'] ===
```

- **Totals:** 549 = Part 2's 544 + the 5 new tests.
- **`test_operator_sighting.gd`** passes 7/0 but prints 2 leak lines at exit. Part 2's validate of `1129515` flagged it the same way; the file was not touched here.
- **`test_ch01_step1_negatives.gd`** took 104 s, still close to the 120 s cap (TLF-085 review P3).
