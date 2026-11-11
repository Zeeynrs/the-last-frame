# TLF-083 handoff, Part 2: Concourse West lit (ADR-026)

Opus, 2026-11-11. Branch `agent/opus-core-tlf083-p2` from `origin/main` `fb04a2e` (Part 1 merged).

**Commits:**
- **Round 1:** the room in **`2a1daa5`** (WIP before it: `3a48065`), handoff and proof pack `8c78da0` / `7f9d634`.
- **Round 2** (wall dado 25 → 24, below): art in **`8c62cb7`**; this handoff update, the ASSET_METADATA rule and the re-shot proof pack in the commit after it.

Not merged.

**Scope (round 1):** only `scenes/chapters/ch01/rooms/concourse_west.tscn` changes: `metadata/lighting` on the root and six `RoomLight` nodes under a new `Lighting` Node2D. No script, shader, test or asset is changed. The proof tool is kept as a text file in this folder (`p2/capture_tlf083_p2.gd.txt`); it is not added to `tools/`.

**Sources:**
- task `docs/tasks/TLF-083.md` Part 2;
- ADR-026;
- Sol `docs/reviews/TLF-082_art_direction.md` §§2-6 and `docs/reviews/TLF-083/TLF-083_c49b9c9_SOL_VISUAL.md`;
- `design/ch01/rooms_v2/concourse_west.md` §4.

## Round 2: wall dado 25 → 24 (Fable stand-in review, owner decision)

**Review:** Sol was offline, so a Fable 5.2 stand-in reviewed `2a1daa5`.
- **Accepted:** the lights as placed (gate focal, no spill, information readable).
- **P1 (CHANGES REQUIRED):** the W-wall dado stays a full-length glowing amber line. `ch01_env_wall_subterranean_w_idle.png` uses palette index **25**, which ADR-026 exempts, where the N wall uses **24**. The divider partitions had the same problem.

**Owner decision:** swap 25 → 24 in the art. The room scene, the lights and the pass are unchanged.

### 1. Audit: every wall-type env asset in `assets/environments/ch01` (+ `.pxo`)

All index-24/25/26 pixels were mapped per asset (`p2/dado/png_pixel_diff.txt` has the result).
- **The rule found:** in every wall, endcap, corner, partition and pillar asset, the **N/`low_S`-facing dado is 24** and the **W/`low_E`-facing dado is 25**, on the same `z` rows.
- **What changed:** those W-facing dado pixels became 24, and nothing else.
- **Order note:** the edit commit `8c62cb7` came before this written list; the audit itself was done first, and its counts were checked against the edit afterwards.

| Asset | 25 → 24 | Source | Index 25 left |
|---|---:|---|---:|
| `ch01_env_wall_subterranean_w_idle` | 32 | **Argon batch 1, no generator**: `.pxo` cel `layer_3` (32 px) and `final_images/1` (32 px) edited byte-wise; zip order, timestamps and compression kept; PNG re-exported by Pixelorama from that `.pxo` | 0 |
| `ch01_env_wall_subterranean_w_endcap_low_idle` | 32 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_partition_low_e_idle` | 32 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_partition_low_corner_inner_idle` | 16 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_partition_low_corner_outer_idle` | 15 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_subterranean_corner_nw_inner_idle` | 15 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_subterranean_corner_nw_outer_idle` | 16 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_subterranean_corner_n_turn_inner_idle` | 14 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_subterranean_corner_n_turn_outer_idle` | 17 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_subterranean_corner_w_turn_inner_idle` | 16 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_subterranean_corner_w_turn_outer_idle` | 17 | generated: `tlf068_shape_kit.py` | 0 |
| `ch01_env_wall_corner_pillar_idle` | 26 | generated: `props.corner_pillar` (the stripe's second face) | 0 |
| **Total** | **248** | | |

**Correction to the brief:** only `subterranean_w` (and the unchanged `subterranean_n`) has no generator. The other 11 are in `registry.py`. Editing their PNGs alone would have broken `verify_regen`, so the change is in the generators:
- `tlf068_shape_kit.py`: a new `DADO_W = 24` replaces the 13 `25`s on the dado rows (`z_down` 36 tall, `z` 5 low);
- `props.corner_pillar`: the stripe's second face is 24;
- the `.pxo` and PNG files are rewritten with `gen_all.py --only ch01_env_wall_ --export` (Pixelorama).

The corner-join highlights (index **26**) stay as they were.

**Not changed, on purpose:**

| Asset | Index 25 | Why it stays |
|---|---:|---|
| `ch01_env_archway_frame_e_idle` / `_n_idle` | 30 / 30 | Threshold lamps. They are the same on the N and E archway, so it is not a W-face trim. |
| `ch01_env_wall_railing_iron_idle` | 2 | Not a wall face and has no N counterpart. |
| `ch01_env_tile_cable_conduit_on_idle` | 16 | Powered state (emissive). |
| `ch01_env_tile_tactile_amber_idle` | 17 | Tactile safety cue (excluded by the brief). |
| `bulkhead_module`, `subterranean_n`, `n_endcap_low`, `partition_low_s` | 0 | Already 24. |
| Props, clock, side-view kit, Beat 10 city, arrival target sheet | any | Excluded by the brief. |

### 2. Nothing else changes

**Assets:** the PNG diffs against the old files are 248 px, every pair `(235,138,40)` → `(204,78,30)` (`p2/dado/png_pixel_diff.txt`).

**Mockups and proofs:** 20 mockups in `design/art/mockups/` and the 4 TLF-081 proof images (`docs/handoffs/TLF-081/tlf081_modules_*.png`) embed these walls. `verify_regen` checks them, so they were regenerated with `gen_all.py --sheet`.
- **Their diffs** are only that colour pair, or its luminance pair `156 → 110` in the greyscale proofs (`p2/dado/mockup_pixel_diff.txt`).
- **Placement sheet:** `CH01_PLACEMENT_SHEET.md` is byte-identical.
- **Not add-only:** the TLF-081 proof files are generated outputs that must match their generator. Regenerating them is not an edit of a review.

**Art gates (logs in `p2/dado/`):**
- `verify_regen.py`: **ALL REPRODUCIBLE** (the same NOT COVERED list as before, `subterranean_w` among them);
- `verify_pxo.py --only ch01_env_wall_`: **17 `.pxo`, all identical**: Pixelorama's re-export equals the committed PNG, including `subterranean_w`;
- `check_assets.py`: **ALL PASS (314)**, also after the ASSET_METADATA edit.

**Every unlit room, before vs after** (`p2/dado/room_frames.gd.txt`): one frame per ch01 room with lighting off and the HUD hidden, rendered in the `2a1daa5` archive and the `8c62cb7` archive and diffed pixel by pixel (`p2/dado/unlit_room_frames_diff.txt`).

| Room | Changed px | Colour pairs |
|---|---:|---|
| arrival | 379 | only 25→24 |
| concourse | 467 | only 25→24 |
| maintenance | 128 | only 25→24 |
| security | 160 | only 25→24 |
| lounge | 128 | only 25→24 |
| signal | 148 | only 25→24 |
| upper vestibule | 192 | only 25→24 |
| niche | 64 | only 25→24 |
| street exit | 160 | only 25→24 |
| side memory | **0** | — |
| atrium | 230 | 224 are 25→24. The other **6** are Elias's idle arm-swing frame: different animation timing between the two runs, at (311-315, 302-305). This is the left-hand pixel of Elias, not art. |

**Crops:**
- `unlit_concourse_w_wall_and_dividers_before_after_x2.png`: before on the left, after on the right, ×2;
- `unlit_arrival_before_after.png` and `unlit_station_atrium_before_after.png`: full frames.

**Baselines:** the collision and sort baselines are unchanged (no scene or collision file is touched):
- `test_ch01_art_integration` (incl. `test_collision_freeze_all_10_rooms`) 6/0;
- `test_ch01_sort_order` 3/0;
- `test_room_builder_output` 5/0.

All are in the validate below.

### 3. Re-shot proof pack and the index-25 count

**Re-shoot:** the whole D.7 pack (table below, `p2/capture.log`) was re-shot in the `8c62cb7` archive. It still shows 0 mismatches, 0 off-palette pixels and 0 wall/cap pixels lifted, with all information pixels kept and setting off == unlit.
- **Lit before/after:** `p2/dado/lit_gate_before_after.png`, top `2a1daa5`, bottom `8c62cb7`.
- **Result:** the W dado and both divider runs now dim like the N wall.

**Index-25 pixels in the lit no-HUD frames** (`p2/dado/lit_index25_counts.txt`):

| Shot | arrival | gate | dials | east | solved | echo |
|---|---:|---:|---:|---:|---:|---:|
| before (`2a1daa5`) | 539 | 530 | 537 | 539 | 542 | 530 |
| after (`8c62cb7`) | **72** | **72** | **70** | **72** | **80** | **72** |

**The 72 left in the gate frame**, all emissive cores:

| Source | Index-25 px |
|---|---:|
| W archway threshold lamps | 30 |
| E archway / staff-door lamps | 12 |
| 23:59 clock core | 18 |
| dial amber marks | 5 |
| reset-console button | 3 |
| evac clipboard | 2 |
| fallen-conduit tip | 2 |

**Outside the clock and tactile:** 54 px. There is no tactile tile in this room.
- **`solved` = 80:** the accepted validator marks.
- **`dials` = 70:** Elias covers 2 px.
- **Texture-based count:** the room's sprites hold 162 index-25 texels after the change, 668 before (`p2/dado/concourse_index25_after.txt`). This counts the archway sprite twice, because `ArchwayWest`/`ArchwayEast` and `YSort_Walls/Archway_door_*` draw the same archway at the same spot (TLF-080 layout; harmless, noted only).

**Index 24 lifted by the gate focal:** 13 index-24 px stay at 24 in the lit gate frame (x 354..395, y 232..252). They are the gate's own 24, the console button rim and the two divider dado ends inside `GateBody`. This is local light on the dado under the focal source, which Sol §2 allows. Everywhere else the dado darkens to 22.

### 4. ASSET_METADATA

New **§15 "Wall dado / trim index rule"**:
- the dado/trim is **24 on every wall face**;
- **25 is reserved for emissive cores** (ADR-026 exempts 25..31);
- the per-asset table above, the kept-at-25 list, and the gates.

Stale index lists are corrected:
- §2.6 `subterranean_w`;
- §4 `corner_pillar`;
- §10 `nw_outer` "25 amber dado";
- §10 low partitions "24/25".

### Round 2 validate (`8c62cb7`)

Same capped procedure on a fresh renamed archive. Log `p2/validate_capped_8c62cb7.log` (LF), sha256 `220bd5ca47f6244a8d26a5bc258f3b75d40846f4be37928e4901c4496b3659da`:

```
[1/3] import: exit 0, 0 ERROR lines, 15 s
[2/3] script check: exit 0, Script check: 191 scripts, 0 failed., 0 ERROR lines, leak check: clean, 6 s
=== TOTAL: 65 test files, TESTS: 530 passed, 0 failed, SCRIPT ERROR lines 0, files needing a look: ['test_operator_sighting.gd'] ===
```

The flagged file is the same pre-existing operator leak. **Real save:** untouched (`slot_0.json` 11306 bytes, 2026-11-07 16:46).

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
- **Tree:** the fresh validate archive of **`8c62cb7`** ("TLF Verify 8c62cb7"), re-shot in round 2 with the dado at 24. The room scene is the same as `2a1daa5`; the round-1 pack is in git at `8c78da0`.
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
| Pass cost (viewport GPU) | +0.075 ms | +0.076 ms | +0.075 ms | +0.075 ms | +0.075 ms | +0.076 ms |

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

**Full validate of `2a1daa5`:** fresh renamed `git archive` ("TLF Verify 2a1daa5", `project.godot` without BOM), the same capped procedure as Part 1 (`p2/validate_capped.py.txt`; every Godot call ≤ 120 s: import, the embedded script checker, then each test file in its own call). Log `p2/validate_capped_2a1daa5.log`, sha256 `ce1dc1562724b1d65e5fbeb0c152306805c9bdef106119a9d845cf5595fff73d` as committed (LF; the CRLF original in scratch was `59fb8ea3…69ec19`):

```
[1/3] import: exit 0, 0 ERROR lines, 13 s
[2/3] script check: exit 0, Script check: 191 scripts, 0 failed., 0 ERROR lines, leak check: clean, 6 s
=== TOTAL: 65 test files, TESTS: 530 passed, 0 failed, SCRIPT ERROR lines 0, files needing a look: ['test_operator_sighting.gd'] ===
```

530 equals the merged-tree count of main `fb04a2e`. The flagged file is the pre-existing `test_operator_sighting.gd` leak (7/0, 2 leak lines when run alone; same on older main, see the Part 1 handoff). The single-process whole-suite leak check of `validate.ps1` cannot run under the 120 s cap; the Lead's official run stays the gate.

**Real save:** untouched (`slot_0.json` 11306 bytes, 2026-11-07 16:46, before and after). The captures use `user://tlf083p2_capture_saves` in the renamed project.

## Open points for Sol and the Lead

1. **Focal choice** (above): gate proposed; clock possible.
2. ~~**Index-25 stripes stay lit.**~~ **Closed in round 2:** the dado is 24 on every face (above). The side-view kit still shares 25/26 in strips and rails (Part 1 open point 3); it was excluded from this change by the brief.
3. **W-wall fixtures** (call box phone, ticket-terms plaque) get no light: they are at k = 2, dark but with their outline and shape (target sheet rows 0-1).
   - **If Sol wants them one step up:** a body receiver quad for each fits the remaining 2 slots.
   - **Why I left them out:** they are not puzzle-critical, and both open a document or dialogue UI.
4. **Mounted conduit** after Rewind sits dark on the W wall (`solved`). It no longer pins anything.
5. **VFX:** ch01 has no world VFX for Trace, Rewind or Freeze (no shimmer node; the only runtime tint in `scripts/` outside the UI is the operator fade). The Echo ghost placeholder (`PocketWatch`, a `ColorRect` violet at alpha 0.55) is the only non-palette world visual. **Finding (`echo` shot):** it stays visible and on-palette, but **loses its violet**. Unlit it blends to about (112,74,151); the pass snaps that to the nearest index, terrazzo 03-05 (and 08 at its edge), so it reads as a blue-grey box: indices 04/05 inside the gate pool, 03 outside. Its shape and placement are unchanged. The fix belongs to the ghost, not to the room: draw it with palette violet **30** (exempt, never shifts) or another opaque palette treatment. That is a Lead decision for the Echo task. When real ability VFX land they need their own proof in a lit room.
6. **Owner A/B on the owner's machine** is still `tools/measure_lighting.gd` from Part 1.

**From the Fable stand-in review (P2/P3, for later; not fixed now):**

7. **Echo ghost loses its violet in lit rooms** (P2). Same finding as point 5.
8. **The Elias zone lifts wall pixels** (P3). It lifts about 550 wall pixels behind him into a faint capsule. This is Sol's accepted round-2 default (18×28, 1/0, unmasked); Sol approved it on `c49b9c9`.
   - **Possible fix:** mask the zone to his own indices. But the trousers share terrazzo 02/03 (Part 1 open point 1), so the clean fix is the actor/silhouette receiver Sol named as a fallback.
9. **The floor fill collapses to 00** (P3). At A 2 the terrazzo body (02-04) goes to 00-02, so the open floor reads only through its grid lines; the floor shows only inside the gate and east pools.
   - **Possible fixes:** a broad floor lift 1 (Sol's table allows a wide low helper), or A 1 for the hall.

   Both change the room's mood, so Sol or the owner decides.
