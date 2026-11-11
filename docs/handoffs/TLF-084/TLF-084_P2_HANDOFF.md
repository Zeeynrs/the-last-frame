# TLF-084 Part 2 handoff: shadows and the floor fill in the ADR-026 pass (ADR-027)

**Branch:** `agent/opus-core-tlf084`, on top of Part 1 (`2bc6983`, from `origin/main` `1388d6d`). Not merged.

**Commits:**
- WIP: `ee78a39`, `95e64be`;
- the final commit is this handoff and the validate log (SHA in the report to the Lead).

**Decision implemented:** ADR-027 (`origin/lead/tlf-084-plan` `ac78c11`):
- option C, a runtime bake at room entry, with C′ (offline bake) as the fallback;
- key light at 315° in every room;
- default strengths;
- Elias's contact shadow placed below his body;
- the owner's floor fill: "fill, keep the focal".

**Visual review:** Sol is offline, so a Fable stand-in reviews the visuals.

**Rules kept:**
- every Godot call is capped at 120 s;
- everything runs in a renamed scratch copy (`TLF Verify tlf084p2`) or a fresh renamed `git archive`;
- no `--eval`;
- the real save is untouched (`slot_0.json` 11306 bytes, 2026-11-07 16:46).

## 1. What changed

| File | Change |
|---|---|
| `scripts/rendering/lighting/shade_baker.gd` (new) | `ShadeBaker`: builds the room's shade map from what the room already has; scanline rasterizer |
| `scripts/rendering/lighting/lighting_pass.gd` | Shade map lifecycle, Elias contact, floor receivers, both fill modes, CPU mirror of the new rule (`output_index`, `fill_at`, `shade_at`, `light_terms`) |
| `scripts/rendering/lighting/palette_lighting.gdshader` | Fill and shade terms (uniforms `room_light_count`, `receivers`, `fill_lift`, `fill_mode`, `fill_clear`, `shade_on`, `shade_map`, `shade_rect`, `shade_size`, `actor_shade`) |
| `scripts/rendering/lighting/room_lighting.gd` | New fields `shadows` (off by default), `fill_lift` 0..1 (0 by default), `fill_mode` ADD/CLEAR (ADD by default), `fill_clear` 1..3 (1.5); their checks in `validate()` |
| `scripts/rendering/lighting/room_light.gd` | `validate()`: an information region (quad with `only_indices`) must lift at least 1, so the fill can never change its pixels |
| `scenes/chapters/ch01/rooms/concourse_west.tscn` | Only the RoomLighting sub-resource: `shadows = true`, `fill_lift = 1` (fill mode ADD by default). The lights are unchanged. |
| `tests/rendering/test_shadows.gd` (new) | 14 tests (§5) |
| `tools/capture_tlf084.gd` (new) | Windowed D.7 capture and checks (scratch copy only) |
| `docs/handoffs/TLF-084/` | This handoff and the `p2/` proof pack |

Rooms without the new fields look exactly as before: shadows and fill are off by default. Lighting rooms and RoomRouter are untouched.

### The rule

On floor receivers (`LightingPass.RECEIVERS`, indices 00–05):

```
k = clamp(A - lift + shade, 0, 3)
lift  = max(light lifts)                                  any pixel (ADR-026)
      ADD:   max(lift, room-light lift + fill)            floor receivers only
      CLEAR: max(lift, fill) outside fill_clear x the outer radius of every room pool lifting it
shade = shade-map texel, at least 1 inside Elias's contact ellipse; 0 inside an information region
```

- **Shade comes after the lift**, so a shadow still reads inside a pool. At A 2, a pool at lift 2 plus shade 1 gives k 1.
- **Unaffected pixels:**
  - wall, body, information and exempt pixels (≥ 25) never take shade or fill;
  - the Elias zone neither adds to nor clears the fill (no bright capsule on the floor, no dark ring around him).
- **Setting off:** with `lighting_enabled` off the pass is hidden and **nothing is baked**. The frame is byte-identical to unlit (measured in every shot).

### The shade map (ShadeBaker)

**Format:** L8, one texel per world pixel over the room bounds, values 0..2.
- **When it is baked:** when the pass applies a lit room with `shadows` on, once per room and only while the pass is shown.
- **When it is dropped:** on every room change, including a change to an unlit room.
- **Shapes:** AO, contacts and casts.
- **Sizes at the defaults:** AO 0.5 / 0.3 tile, contact core 2 / rim 1, cast 1. Casts come from casters ≥ 28 px tall, length height/32 tiles, direction +x in tile space (the 315° key, toward the screen's bottom-right) in every room.

**Casters come from the room automatically:**
- **Footprints:** every Rectangle/Circle/Capsule collider under a `StaticBody2D`.
- **Sprites without a footprint:** every actor-layer sprite (DepthSort upright art, or z `ACTOR_Z`).
- **Not counted:**
  - a sprite within 16 px of a footprint already listed is that body's art; this keeps the pillar from being counted twice;
  - a footprint closer than 0.25 tile to the floor outline, or outside it, casts nothing (the staff door set into the E wall);
  - anything under a node with `metadata/shade_skip = true` (the only manual override; Concourse West needs none).
- **Partitions:** `SegmentShape2D` colliders under a `StaticBody2D` get AO on both sides.
- **Concourse West's 10 casters:** the gate post, pillar, validator, 4 statues, reset console, bench and courier (`test_concourse_west_casters_ao_and_the_315_key`).

**Side view (ADR-025):** an AO band where the far wall meets the deck (`floor_y - 12 .. -9`), contact ellipses on the floor line, and short casts to the right.

**Elias's contact shadow** (shade 1, dynamic):
- an ellipse of r (8, 3), centred (0, 6) below his feet in iso and (0, 5) in side view; the side sheet's lowest body row is one pixel higher;
- this is the highest placement where no pixel of any iso or side frame that a shade step could change lies inside it;
- `test_elias_contact_sits_below_his_body` checks every frame of both sheets, and that the ellipse touches his lowest body row rather than floating.

## 2. The floor fill: both rules, ADD shipped

**`p2/fill_modes_gate_east.png`** (native crops; rows gate and east door): ADR-026 lit | **ADD (shipped)** | CLEAR 1.5 | CLEAR 1.0.

| Rule | Gate focal (2/1) | East helper (1/0) | Open floor | Seen in the shots |
|---|---|---|---|---|
| ADR-026 (before) | core k0, band k1 | core k1, band k2 | k2 (shadows invisible) | dark hall, floor visible only in pools |
| **ADD**: pools add the fill | core and band k0 | core k0, band k1 | k1 | every pool one step above the filled floor, nothing darker than the fill. Focal and helper cores reach the same value (art value). The focal still leads through its size and the GateBody lift. |
| CLEAR 1.5 | core k0, band k1, ring k2 to 1.5 radii | core k1, band and ring k2 | k1 | full ADR-026 contrast kept, but every pool sits in a **dark doughnut** |
| CLEAR 1.0 | core k0, band k1 (= floor) | core k1 (= floor), band k2 | k1 | the helper becomes a **dark ring** |

**Recommendation: ADD**, the Lead's "pools stay 1+ step brighter than the filled floor".
- It is the simplest rule: one term, no radius parameter.
- No dark rings, and it is closest to light adding up.
- **Cost:** at A 2 only one step is left above the fill, so the focal and the helper core look equally bright.

**CLEAR** is the ADR wording ("except around the focal and helper pools ... against the darker floor"). It is there for the reviewers to compare.
- **To switch a room:** `fill_mode = 1` (and `fill_clear` if not 1.5) in the room's RoomLighting.
- **ADR text:** if ADD is accepted, the ADR-027 fill bullet needs a one-line update by the Lead.

## 3. Bake speed (the ADR gate)

The spike's GDScript point-in-polygon bake took **30–40 ms** for Concourse West. The production bake fills spans row by row with `Image.fill_rect`, in ascending value order, so the map holds the maximum.
- **Measured in game at room entry** (`ENTRY`, windowed, this PC): **2.8–3.2 ms** for Concourse West.
- **Every ch01 room** (`p2/logs/capture_bake.log`: one cold bake, then 20 more):

| Room | Shapes (polygons / ellipses) | Map | First | Median | Max |
|---|---|---|---:|---:|---:|
| arrival_platform | 14 / 8 | 800×384 | 2.66 ms | 2.38 ms | 2.93 ms |
| concourse_west | 16 / 10 | 736×432 | 2.80 ms | 2.62 ms | 2.96 ms |
| maintenance_bay | 12 / 6 | 640×360 | 1.27 ms | 1.11 ms | 1.47 ms |
| security_crossing | 19 / 15 | 640×360 | 1.52 ms | 1.45 ms | 1.77 ms |
| waiting_lounge | 1 / 1 | 640×360 | 0.28 ms | 0.20 ms | 0.34 ms |
| signal_control | 19 / 17 | 640×360 | 1.52 ms | 1.43 ms | 1.71 ms |
| upper_vestibule | 6 / 6 | 640×360 | 0.59 ms | 0.53 ms | 0.56 ms |
| vestibule_niche | 1 / 1 | 640×360 | 0.24 ms | 0.18 ms | 0.20 ms |
| station_atrium | 3 / 3 | 640×360 | 0.41 ms | 0.32 ms | 0.35 ms |
| street_exit | 0 / 0 | 640×360 | 0.16 ms | 0.12 ms | 0.13 ms |
| side_mira_memory | 6 / 6 | 1440×540 | 0.41 ms | 0.14 ms | 0.38 ms |

All are under 3 ms, about 10–14 times faster than the spike and far below a 16 ms frame. **C′ (offline bake) is not needed on this PC.**

The ADR gate still asks for a measurement on the owner's machine. `LightingPass.bake_ms` holds the last bake, and `tools/capture_tlf084.gd` with `TLF_SHOT=bake` prints the whole table (scratch copy only).

**GPU cost of the new terms** (viewport GPU, 90 frames): ADR-026 lit **0.122 ms**, ADR-027 **0.127 ms**, about **+0.005 ms**. Unlit is 0.035 ms.

## 4. D.7 proof pack (`p2/`)

**Shots:** windowed 960×540 native, HUD hidden unless named.
- **Positions:** arrival, gate, dials and east door are the TLF-083 P2 spots; side is the Mira memory at A 1, lit at runtime for this proof only.
- **Per shot:**
  - `_unlit`, `_lit_adr026` (the TLF-083 look) and `_lit_shadows` (ADR-027), each with a `_greyscale` copy;
  - `_lit_shadows_hud`;
  - `_x2_adr026_vs_shadows` (×2 crop around Elias, ADR-026 on the left, ADR-027 on the right).
- **Fill-mode shots:** `gate_` / `east_clear15_` and `_clear10_` frames.
- **Logs:** in `p2/logs/`.

**Checks per shot (all 9 shots, including the 4 fill-mode variants):**

| Check | arrival | gate | dials | east | side |
|---|---:|---:|---:|---:|---:|
| Shader vs GDScript reference (`output_index`), mismatched px of 518 400 | 0 | 0 | 0 | 0 | 0 |
| Off-palette px, no HUD / outside the HUD | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| Setting off == unlit (bytes) | yes | yes | yes | yes | yes |
| Information px changed (dials, validator) | 0 of 488 | 0 of 488 | 0 of 487 | 0 of 488 | none |
| Exempt (≥ 25) px changed | 0 | 0 | 0 | 0 | 0 |
| Non-receiver px (index ≥ 6) changed | 0 | 0 | 0 | 0 | 0 |
| Floor px lifted by the fill / darkened | 90 370 / 141 | 90 828 / 31 | 90 603 / 138 | 90 251 / 31 | 72 758 / 83 |
| Px with shade > 0 | 11 789 | 11 800 | 11 766 | 11 864 | 3 432 |
| Elias body px darkened / lifted | 0 / 0 | 0 / 1 | 0 / 0 | 0 / 32 | 0 / 0 |
| Bake at entry | 3.18 ms | 2.86 ms | 2.91 ms | 3.01 ms | 0.41 ms |

**The two tables measure different things:**
- **Shade > 0** counts pixels that are actually shaded.
- **Darkened vs ADR-026** is small in ADD because a shadow on the filled floor (k 2 − 1 + 1) lands on the old unfilled value. The shadow reads one step below the filled floor around it.

**Independent recount:** `p2/palette_recount.txt` recounts every saved frame against the `.gpl` in Python, with 0 off-palette pixels in all 25 frames.

**Elias:** no body pixel is darkened in any ADD shot. At the east door he is 32 px brighter, because his trousers (floor colours) stand in the helper pool: pool + fill.

## 5. Tests (`tests/rendering/test_shadows.gd`, 14) and proof that they fail when stubbed

| Test | What it pins |
|---|---|
| `test_rasterizer_matches_a_brute_force_reference` | Scanline map == per-texel reference on Concourse West's shapes plus a sliver, an off-map polygon and an edge ellipse; L8; one texel per pixel |
| `test_concourse_west_casters_ao_and_the_315_key` | The 10 casters; AO on N/W/low S; contact core and rim; the pillar cast falls down-right, not up-left or down-left; baking adds no node |
| `test_skip_meta_and_footprints_on_the_floor_edge` | `shade_skip`; a footprint 0.1 tile from the W edge casts nothing, but casts inside the floor |
| `test_side_view_band_contacts_and_casts` | Side band, contact on the floor line, cast to the right |
| `test_only_floor_receivers_take_shade_and_fill` | Indices 00–05 take shade and fill; 06–31 take neither |
| `test_information_regions_and_exempt_indices_take_nothing` | Dial 02/24 unchanged under shade 2 + fill; floor 00/04 inside the region but not in its indices are shaded; 25–31 never move; an information region with lift 0 is invalid |
| `test_shade_is_added_after_the_lift` | A 1, lift 2, shade 1 → k 0 (not 1); a shadow reads inside a pool; clamp at 3 |
| `test_fill_adds_to_room_pools_but_not_to_the_elias_zone` | ADD: helper core k0, band = the fill, no ring; body-only lights add nothing to the floor; the Elias zone does not add |
| `test_fill_is_cleared_around_room_pools_only` | CLEAR: cleared inside 1.5 radii, not by body-only lights or the Elias zone |
| `test_room_lighting_fill_ranges` | Defaults (shadows off, fill 0, ADD) and ranges |
| `test_every_lit_ch01_room_has_shadows_and_the_fill` | ADR-027: every lit ch01 room has shadows on and fill 1 |
| `test_elias_contact_sits_below_his_body` | Every frame of the iso and side sheets: no changeable body pixel inside, and the ellipse touches his lowest row |
| `test_setting_off_skips_the_bake_and_hides_the_pass` | Setting off: hidden, no bake; on: one bake over the room bounds; toggling again does not rebake; the room's nodes are untouched; an unlit room drops the map |
| `test_map_rebuilt_on_every_room_change_without_leaks` | Router iso ↔ side, 3 round trips: a new map per entry with the right bounds and no stale contact; orphan nodes and **object count** unchanged |

The 15 existing `test_lighting_pass` tests are unchanged and pass.

**Mutation check** (`p2/mutate.py.txt`, `p2/logs/mutation.log`): each change is made in the scratch copy, both test files are run (120 s cap), and the file is restored. **All 17 are caught:**

| Mutation | Failing tests |
|---|---|
| Shade stubbed to 0 | 3 |
| Receiver mask = every index | 3 |
| Information regions ignored by the shade | 1 |
| ADD: pools do not add the fill | 1 |
| ADD: the Elias zone adds the fill | 1 |
| Exempt ignored | 1 (+2 in `test_lighting_pass`) |
| Shade added after the clamp | 1 |
| CLEAR: fill never cleared | 1 |
| CLEAR: the Elias zone clears the fill | 1 |
| Map not rebuilt on room change | 1 |
| Bake while the setting is off | 1 |
| Maps leak | 1 |
| Elias contact at his feet | 1 |
| Rasterizer stubbed (empty map) | 4 |
| Cast toward the key (up-left) | 1 |
| No AO strips | 2 |
| No edge rule (the door in the wall casts) | 2 |

**Dead branch removed:** a first version also kept the fill out of information regions. The mutation run showed this could never change a pixel: a region lifts its indices by at least the fill. The branch was removed, and `RoomLight.validate()` now enforces "an information region lifts at least 1".

## 6. Validate

VALIDATE_PLACEHOLDER

## 7. Open points

1. **Fill rule:** ADD (shipped) or CLEAR 1.5, for Fable/Sol and the owner (§2). If ADD stays, the ADR-027 fill bullet needs rewording.
2. **Owner's machine:** bake time and A/B (the ADR gate). Numbers here are from this PC only.
3. **Static shade on Elias's trousers:** the baked map darkens floor-coloured body pixels by one step when he stands inside a cast or AO strip. His contact ellipse avoids his body; the baked map cannot.
   - **In the four shots:** 0 such pixels.
   - **Proper fix:** the actor/silhouette receiver already named in TLF-083 (open point 1, Fable P3).
4. **Shadows follow the room at entry, not live state changes.**
   - **The gate case:** the gate's Blocker collider is disabled when the gate opens. Entering a solved room bakes no gate-post contact. Opening it while inside keeps the contact until the next entry.
   - **The fix:** `LightingPass` can rebake on a signal (`_drop_shade()` then `_ensure_shade()`, about 3 ms). Not wired yet; tell me if a room needs it.
5. **Carried over from TLF-083, unchanged:**
   - the echo ghost loses its violet in lit rooms;
   - the Elias zone still lifts wall pixels behind him into a faint capsule. With the fill, the floor part of that capsule no longer shows (`p2/arrival_x2_adr026_vs_shadows.png`).
6. **Rooms TLF-085..092:** shadows and fill are two lines in the room's RoomLighting (`shadows = true`, `fill_lift = 1`). `test_every_lit_ch01_room_has_shadows_and_the_fill` enforces it for every lit ch01 room.
