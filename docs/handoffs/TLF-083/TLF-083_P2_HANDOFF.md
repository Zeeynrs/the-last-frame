# TLF-083 handoff, Part 2: Concourse West lit (ADR-026)

Opus, 2026-11-11. Branch `agent/opus-core-tlf083-p2` from `origin/main` `fb04a2e` (Part 1 merged).

**Commits:** the room in **`2a1daa5`** (WIP before it: `3a48065`), this handoff and the proof pack in the commit after it. Not merged.

**Scope:** only `scenes/chapters/ch01/rooms/concourse_west.tscn` changes: `metadata/lighting` on the root and six `RoomLight` nodes under a new `Lighting` Node2D. No script, shader, test or asset is changed. The proof tool is kept as a text file in this folder (`p2/capture_tlf083_p2.gd.txt`); it is not added to `tools/`.

**Sources:**
- task `docs/tasks/TLF-083.md` Part 2;
- ADR-026;
- Sol `docs/reviews/TLF-082_art_direction.md` §§2-6 and `docs/reviews/TLF-083/TLF-083_c49b9c9_SOL_VISUAL.md`;
- `design/ch01/rooms_v2/concourse_west.md` §4.

## Focal proposal: the gate, not the clock

**Proposal: the dominant focal is the turnstile gate / decision area (PZ-001).** The 23:59 clock stays a warm accent without a pool.
- **Sol's concourse row** (TLF-082 §3) asks for "one active control/decision bank 2/1". The gate is that bank: the fallen conduit pins it, the courier is the Trace that unlocks Rewind, and the reset console stands beside it.
- **The clock already wins its own read.** Its core is index 25/26, which never shifts (`exempt_from` 25), so `23:59` stays the brightest warm shape on the N wall without a light. A 2/1 pool on it would add a second dominant point.
- **One screen.** The room fits the 960×540 view with a fixed camera (416,216), so every shot below is the same frame. "One dominant focal per screen" therefore means one for the whole room.
- **No repeat of the arrival.** The arrival's focal is the clock, so a gate focal here avoids repeating that composition room after room.

If Sol prefers the clock, the swap is two nodes: move the focal pair onto the N wall face, and give the gate a 1/0 body receiver.

## What is in the scene

`metadata/lighting` = `RoomLighting`: `ambient_steps` **2**, `exempt_from` **25**, `dither` false, Elias zone at the round-2 default (radius **18×28**, offset (0,−20), inner 0.85, lifts **1/0**). A and exempt are written explicitly; the zone uses the class defaults.

| Node (`Lighting/…`) | Kind | Position | Size | Lift | `only_indices` | Why |
|---|---|---|---|---|---|---|
| `GateFloor` | ellipse | (316,194) | 64×32 (2:1), inner 0.55 | **2/1** | 00-05 (terrazzo) | The focal pool on the floor around the gate. |
| `GateBody` | ellipse | (312,182) | 44×40, inner 0.6 | **2/1** | 11-24 (steel, figure, amber) | The same focal on the standing things: gate, fallen conduit, courier N-05, reset console, Elias when he is there. |
| `EastHelper` | ellipse | (600,330) | 64×32 (2:1), inner 0.55 | **1/0** | 00-05 | The low helper on the floor in front of the east door. |
| `CommuterBodies` | ellipse | (544,326) | 128×64, one band | **1/1** | 11-24 | Keeps the PZ-006 Trace targets N-06..N-09 and the east door one ramp step down. It lifts no floor, so no oval is drawn. |
| `DialsInfo` | quad | around (592,172) | the three dial faces, inset inside the casing rims | **2** | 02 03 14 15 23 24 | The information region: flap rows, icons and jam marks. Casing, panel 12 and wall stay dark. |
| `ValidatorInfo` | quad | around (620,215) | the validator screen | **2** | 02 03 14 15 23 24 | The information region for the validator screen. Its accepted marks are 25/26 and stay bright anyway. |

**Receiver masks without new code:** no light lists ramp **06-10**: the ceramic wall brick, the partition brick and its caps (10/9), and the cornices. So no room light can brighten a wall, a cap or the wall behind a floor pool; the measured count is in the table below. This is the "receiver mask" of ADR-026 done with `only_indices`, the only mechanism the room scene can use. No painted mask is needed.

**Budget:**
- **Visible sources:** two (the gate focal and the east helper).
- **Receivers:** the body receivers (`GateBody`, `CommuterBodies`) belong to those two sources; they are not new sources.
- **Information regions:** two.
- **Elias zone:** one.
- **Total:** 6 of the 8 `RoomLight` slots.

## Proof pack (D.7): `docs/handoffs/TLF-083/p2/`

**Setup:**
- **Render:** windowed Forward+ (D3D12, RTX 5060), 960×540 native, via `capture_tlf083_p2.gd.txt`.
- **Tree:** the fresh validate archive of `2a1daa5` ("TLF Verify 2a1daa5").
- **Lighting:** read from the scene, not set at runtime.
- **One Godot call per shot**, each capped at 120 s.

**Per shot:**
- `<shot>_lit.png` (HUD on);
- `<shot>_lit_nohud.png`, `<shot>_setting_off_nohud.png` and `<shot>_unlit_nohud.png`;
- greyscale `<shot>_lit_nohud_greyscale.png` and `<shot>_unlit_nohud_greyscale.png`;
- `<shot>_lit_x2.png`: a nearest ×2 crop around Elias.

| Shot | Elias at | State |
|---|---|---|
| `arrival` | door spawn (224,144) | start |
| `gate` | gate stand (298,198) | conduit **fallen** across the arm (328,184), gate collapsed |
| `dials` | dial stand (576,216) | dials, validator idle |
| `east` | east door spawn (608,336) | start |
| `solved` | gate stand | conduit **mounted** (144,160), gate open, validator accepted |
| `echo` | gate stand | two Echo ghost placeholders, one inside the gate pool and one outside |

**Measured** (log `p2/capture.log`):

| Check | arrival | gate | dials | east | solved | echo |
|---|---|---|---|---|---|---|
| Shader vs `LightingPass.output_index()` (518 400 px) | **0** | **0** | **0** | **0** | **0** | **0** |
| Off-palette, no HUD | **0** | **0** | **0** | **0** | **0** | **0** |
| Off-palette outside the HUD (HUD frame) | **0** | **0** | **0** | **0** | **0** | **0** |
| Setting off == unlit (bytes) | true | true | true | true | true | true |
| Wall/partition/cap pixels (06-10) lifted by a room light | **0** / 27 893 | **0** / 27 920 | **0** / 27 846 | **0** / 27 956 | **0** / 27 462 | **0** / 27 982 |
| Dial + validator info pixels kept | 488/488 | 488/488 | 487/487 | 488/488 | 480/480 | 488/488 |
| Other indices lifted inside the info regions | 0 | 0 | 0 | 0 | 0 | 0 |
| Pass cost (viewport GPU) | +0.076 ms | +0.076 ms | +0.076 ms | +0.076 ms | +0.076 ms | +0.075 ms |

**Notes on the counts:**
- **Info pixels:** 487 at the dials because Elias stands in front of one pixel; 480 when solved because the accepted validator texture has fewer such pixels.

**Target sheet (`targets_in_range.png`):** every selectable target with Elias on its stand spot (the positions from `test_ch01_concourse_west_v2`) and the **HUD and marker hidden**.
- **Rows:** call box, ticket terms, courier/gate/conduit, reset console, 3 dials, validator, evac notice, N-09, N-08, N-07, N-06 and the east door.
- **Columns:** lit, unlit, lit greyscale; 128×96 native crops.
- **Check:** 0 mismatches and 0 off-palette pixels over the 14 crops.

**Mutation check of the room validation** (`test_every_lit_ch01_room_validates`, which now finds 1 lit room):
- moving `EastHelper` out of the room bounds → **RED** (14/1);
- `exempt_from = 24` → **RED** (14/1);
- restored file → 15/0, byte-identical to the commit.

## Tests and validate

**Targeted runs** (dev copy, each ≤ 120 s): `test_lighting_pass` 15/0 (`lit rooms … 1`), `test_ch01_concourse_west_v2` 12/0, `test_ch01_sort_order` 3/0, `test_ch01_art_integration` 6/0.

**Full validate of `2a1daa5`:** fresh renamed `git archive` ("TLF Verify 2a1daa5", `project.godot` without BOM), the same capped procedure as Part 1 (`p2/validate_capped.py.txt`; every Godot call ≤ 120 s: import, the embedded script checker, then each test file in its own call). Log `p2/validate_capped_2a1daa5.log`, sha256 `59fb8ea34836a4f1b22fa92d9db84f0f2fd0a84a2f27cc876cfda6cb5969ec19`:

```
[1/3] import: exit 0, 0 ERROR lines, 13 s
[2/3] script check: exit 0, Script check: 191 scripts, 0 failed., 0 ERROR lines, leak check: clean, 6 s
=== TOTAL: 65 test files, TESTS: 530 passed, 0 failed, SCRIPT ERROR lines 0, files needing a look: ['test_operator_sighting.gd'] ===
```

530 equals the merged-tree count of main `fb04a2e`. The flagged file is the pre-existing `test_operator_sighting.gd` leak (7/0, 2 leak lines when run alone; same on older main, see the Part 1 handoff). The single-process whole-suite leak check of `validate.ps1` cannot run under the 120 s cap; the Lead's official run stays the gate.

**Real save:** untouched (`slot_0.json` 11306 bytes, 2026-11-07 16:46, before and after). The captures use `user://tlf083p2_capture_saves` in the renamed project.

## Open points for Sol and the Lead

1. **Focal choice** (above): gate proposed; clock possible.
2. **Index-25 stripes stay lit.** Both turnstile divider runs and the W-wall dado carry amber index **25** (`pp` in `ch01_env_wall_partition_low_e_idle.png`), which `exempt_from` 25 never shifts. They read as two orange lines across the dark hall.
   - **Possible upside:** it marks the barrier, which is useful game information.
   - **Limit:** Sol's "no glowing perimeter" rule cannot be met by the pass here. This is the same shared-index limit as Part 1 open point 3. If Sol wants it calmer, the fix is either a receiver-override region (pass extension) or a pigment change in the partition art (asset author).
3. **W-wall fixtures** (call box phone, ticket-terms plaque) get no light: they are at k = 2, dark but with their outline and shape (target sheet rows 0-1).
   - **If Sol wants them one step up:** a body receiver quad for each fits the remaining 2 slots.
   - **Why I left them out:** they are not puzzle-critical, and both open a document or dialogue UI.
4. **Mounted conduit** after Rewind sits dark on the W wall (`solved`). It no longer pins anything.
5. **VFX:** ch01 has no world VFX for Trace, Rewind or Freeze (no shimmer node; the only runtime tint in `scripts/` outside the UI is the operator fade). The Echo ghost placeholder (`PocketWatch`, a `ColorRect` violet at alpha 0.55) is the only non-palette world visual. **Finding (`echo` shot):** it stays visible and on-palette, but **loses its violet**. Unlit it blends to about (112,74,151); the pass snaps that to the nearest index, terrazzo 03-05 (and 08 at its edge), so it reads as a blue-grey box: indices 04/05 inside the gate pool, 03 outside. Its shape and placement are unchanged. The fix belongs to the ghost, not to the room: draw it with palette violet **30** (exempt, never shifts) or another opaque palette treatment. That is a Lead decision for the Echo task. When real ability VFX land they need their own proof in a lit room.
6. **Owner A/B on the owner's machine** is still `tools/measure_lighting.gd` from Part 1.
