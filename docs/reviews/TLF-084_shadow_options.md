# TLF-084 Part 1: shadow and depth options

Opus, 2026-11-11. Branch `agent/opus-core-tlf084` from `origin/main` `1388d6d`. **No game code changes on this branch.** The spike runs in a renamed scratch copy ("TLF Verify tlf084spike"). Its code is kept as text in `docs/reviews/TLF-084/spike/`:
- `capture_tlf084.gd.txt`: the baker and capture;
- `palette_lighting_spike.gdshader.txt`;
- `lighting_pass_spike.diff.txt`.

**Inputs:**
- task TLF-084 and `ROOMS_V2_PROGRAM.md` (`origin/lead/tlf-084-plan`);
- ADR-026;
- the TLF-083 handoffs and the Fable review on main `1388d6d`;
- ART_BIBLE §4: the sprites are drawn with a top-left 315° key light.

## Recommendation

1. **Option C: a shade map in the ADR-026 pass.** It is a world-space L8 map (one texel per world pixel, values 0..2), baked from the room when the room is entered, plus one dynamic contact ellipse under Elias. The pass rule becomes:

   `k = clamp(A − lift + shade, 0, 3)`

   - **Receivers:** shade applies only to floor indices 00-05.
   - **Information regions:** never shaded.
   - **Exempt indices (≥ `exempt_from`):** never move (the shift table already guarantees this).
   - **Setting:** `lighting_enabled` off hides the pass, so the frame is byte-identical to unlit.
2. **Shapes are derived automatically.** The room author normally writes nothing:
   - AO strips from `RoomShape.wall_segments()` and the divider segments;
   - contact ellipses from footprint colliders and actor-layer sprites;
   - cast quads from grounded sprites at least 28 px tall.
3. **Cast direction: the ART_BIBLE key (315°, shadows fall screen down-right, +x in tile space) for every room.** It does not radiate from the focal `RoomLight`, so the floor shadows agree with the shading already painted into every sprite (comparison below). A per-room `key_dir` override exists only for a room Sol asks for.
4. **A floor fill comes with shadows.** Shadows need a floor that still has value. At A 2 the open terrazzo is already at 00-02, so +1 shade is almost invisible outside the pools. The fill is one `RoomLight` with lift 1/1 on floor indices 00-05 only, covering the floor. With it, AO, contact and cast shadows read across the room, and the open floor no longer collapses to 00 (Fable P3).
   - **Price:** the focal pool loses one step of contrast; the gate pool reads weaker (`gate_fill_*`).
   - **Who decides:** Sol or the owner. The alternative is fill only in the parts of a room that need depth.
5. **Bake:** at room entry in Part 2, with a cost budget. If the owner's machine is over budget, bake offline in the room builder instead (option C′, a file per room plus a staleness test).

## Options in detail

### A. Analytic shapes as shader uniforms

Each contact, cast or AO shape is a uniform entry, like the lights today.

| | |
|---|---|
| **Palette** | Safe: it is the same ramp shift. |
| **Authoring** | Automatic, same rules as C. |
| **Readability** | Same receiver mask and info suppression as C. |
| **With lights** | Shade adds after lift (`A − lift + shade`), so a contact shadow stays visible inside a pool: one step darker than the pool. |
| **Side view** | Works. |
| **Cost** | Grows with the shape count. Concourse West needs 29 shapes (17 polygons, 12 ellipses), so 29 tests per pixel on top of the 9 light slots, and a fixed uniform-array cap per room. |
| **Tests** | Like C. |

**Rejected:** C produces the same shapes at O(1) cost per pixel (one texel fetch) and has no shape cap.

### B. Authored shadow sprites (palette 00/01 blobs under objects)

| | |
|---|---|
| **Palette** | Safe, but they **overwrite** the floor instead of darkening it: the terrazzo grid disappears under every blob, and in the dark parts of the room 01 shifts to 00 and vanishes. In spike `sprites_*` (16-point 01 ellipses under the same bodies), 0 pixels get darker than lit, because the blobs are in every frame. |
| **Authoring** | Art and placement per object, per facing, per room, and redone when a layout changes. |
| **Lighting off** | Must be toggled with the pass. Otherwise lighting off ≠ today's unlit look (`sprites_unlit` still shows the blobs). |
| **Side view** | Needs its own set. |
| **Cost** | None. |

**Rejected.**

### C. Shade map baked at room entry (recommended)

**Bake inputs** (spike `_bake_iso` / `_bake_side`):

| Shape | Source | Size / value |
|---|---|---|
| AO, tall N/W wall base | `wall_segments()` straight N/W | 0.5 tile strip, shade 1 |
| AO, low S/E edge | `wall_segments()` low_S/low_E | 0.3 tile strip, shade 1 |
| AO, dividers | `TurnstileDividers` `SegmentShape2D` | ±0.3 tile, shade 1 |
| Contact | every `StaticBody2D` footprint except walls, dividers and door blockers; actor-layer sprites without a body | 2:1 ellipse, rx = 1.25 × half width (≥ 6 px); core (< 0.55) shade 2, rim shade 1 |
| Cast | grounded bodies whose sprite is ≥ 28 px tall | tapered quad on the floor, length = height / 32 tiles, along the key direction, shade 1 |
| Elias | `player.global_position` | dynamic 8×4 ellipse in the shader, shade 1 |

**Combine rule:** overlapping shapes take the **max**, not the sum, the same rule as lights.

**Pass and shader** (spike diff):
- **Uniforms:** `shade_map` (nearest), `shade_rect` (the map's screen origin and size), `actor_shade` and `shade_receivers`.
- **Information regions:** a pixel inside a matching info quad gets no shade.
- **Reference:** `shade_at()` and `output_index_shaded()` mirror the shader in GDScript.

**Room author's work:** none by default. Overrides for Part 2:
- `RoomLighting.shadows` (on/off);
- `key_dir`;
- a `no_shadow` group or metadata on a node, for things like a hanging sign whose collider is not on the floor.

**Side view (ADR-025):** the same map in world pixels.
- **AO:** a 3 px band where the far wall meets the deck (`floor_y − 12 … −9`).
- **Contact:** flat ellipses (w × 0.45, 3 px) at `floor_y` under every grounded sprite of at least 12 px.
- **Cast:** a horizontal 2 px strip away from the key.

The spike `side_*` (side memory at A 1) shows the deck AO band and contact under the bench, Mira, the pillar and Elias. It is subtle at A 1 and readable. The disc behind Mira comes from the spike's runtime Mira light, not from shadows; the side room's real lighting is its own task.

**Interaction with lights:** shade adds after lift.
- **Inside a 2/1 pool:** a contact core goes from k 0 to k 2, so pool shadows are the strongest. That is physically right: shadows read where there is light.
- **In the dark at A 2:** k is already 2, and +1 gives 3. Terrazzo then goes 02→00 and 03→00 (unchanged) and 04→01, which is nearly invisible. Hence recommendation 4.

**Readability:** the receivers are floor indices only.
- **Unaffected:** wall, cap and prop materials (06-24), signage and information.
- **Exempt:** ≥ 25 by construction.
- **Elias:** his trousers share terrazzo 02/03, so they take shade when he stands in a shadow or on his own contact ellipse, about 1 step. That is physically plausible, and his coat (16-21) never takes shade. In the spike crops his legs stay separated from the floor. If Sol wants it, the actor ellipse can sit 2 px lower so only the boots overlap it.

### C′. Shade map baked offline by the room builder

It is the same map, written as a PNG next to the room by `build_room_from_shape.py` (or a Godot tool) and loaded by the pass.
- **Cost:** zero at room entry.
- **Downsides:** one more asset per room, plus a test that fails when the room changed but the map did not.
- **When:** this is the fallback if the runtime bake is too slow on the owner's machine.

### D. Not worth it here

| Option | Why not |
|---|---|
| Godot `LightOccluder2D` / `PointLight2D` shadows | Leave the palette, as with ADR-026 option A. |
| Normal maps | No art for them, and they are not palette-safe. |
| Per-pixel dither soft edges | Sol §4: no dither. |

## Spike evidence (`docs/reviews/TLF-084/spike/`, raw log `spike.log`)

**Render setup:** windowed Forward+ (D3D12, RTX 5060), 960×540. The tree is a fresh archive of `1388d6d`; the lighting comes from the room scene, plus the runtime fill or Mira light where named.

**Images per shot:**
- `<shot>_lit`, `<shot>_lit_shadows`, `<shot>_unlit`;
- greyscale copies of all three;
- `<shot>_x2_lit_vs_shadows` (×2, top lit, bottom lit+shadows, around Elias).

| Set | Shots | What |
|---|---|---|
| A 2, scene lights | `arrival`, `gate`, `dials`, `east` | Shadows only, radial key |
| A 2 + floor fill | `*_fill` | Fill + shadows, radial key |
| A 2 + fill, 315° key | `*_fill_key315` | **The recommendation** |
| Option B | `sprites` | 01 blobs under the same bodies |
| Side view | `side` | Side memory at A 1, a Mira 1/0 light, deck AO, contact, cast |

**Checks**, the same on all 14 shots:

| Check | Result |
|---|---|
| Shader vs GDScript reference (`output_index_shaded`, 518 400 px) | **0 mismatches** |
| Off-palette pixels | **0** |
| `lighting_enabled` off == unlit (bytes) | **true** |
| Information pixels changed by shade | **0** (488/487 checked per shot) |
| Exempt (≥ 25) pixels changed | **0** |

**Pixels darker than lit:**

| Set | Pixels |
|---|---|
| shadows only | 2 022-2 119 |
| fill + shadows | 10 476-10 591 |
| fill + 315° key | 10 317-10 432 |
| side | 2 861 |

**Cost** (dev GPU RTX 5060, viewport GPU time):
- **Shade term:** +0.003 to +0.006 ms over the lit pass (about 0.11 to 0.12 ms).
- **Bake** (GDScript point-in-polygon rasterizer, 736×432 map, 17 polygons + 12 ellipses): 30-40 ms on the dev CPU at room entry.
- **Low end:** a CPU 3-5× slower would give about 100-200 ms during the room transition. Part 2 should switch the rasterizer to scanline fills (no per-pixel point-in-polygon test; not measured yet), add a budget check to `tools/measure_lighting.gd`, and fall back to C′ above 16 ms on the owner's machine.

**Visual notes** (my reading, for Sol):
- **Shadows only (no fill):** visible only inside the gate and east pools. Contact under the console and Elias, and divider AO, show at the gate. The rest of the floor is already 00-02, so the depth gain is small.
- **Fill + shadows:** the room gains depth.
  - AO bands under the N and W walls and along both dividers;
  - statue contact plus cast shadows;
  - a shadow under the bench and the pillar;
  - Elias grounded by his contact ellipse.

  The cost is that the gate focal pool loses one step of contrast.
- **Radial vs 315°:** radial throws the courier's and console's shadows left of the gate and the bench's toward the N wall. That contradicts the top-left lighting painted into the sprites. 315° keeps every shadow down-right, consistent with the art. **315° is recommended.**
- **Side:** a quiet AO line at the deck/wall seam plus contact shadows. The fill is not needed at A 1.

**Real save:** untouched (`slot_0.json` 11306 bytes, 2026-11-07 16:46).

## Tests for Part 2 (each must fail when stubbed)

- **Bake on a fixture room:**
  - AO texels lie only along the wall segments;
  - contact ellipses lie at the footprints;
  - cast quads point along `key_dir`;
  - the bake is deterministic (same bytes twice).
- **Shader-rule mirror (pure):**
  - shade adds after lift and is clamped at 3;
  - max, not sum;
  - receivers only;
  - none inside an info quad;
  - exempt indices unchanged.
- **Router:** iso → side → iso rebakes, with no stale map, no orphan textures and no leak.
- **Setting:** off hides the pass, so the frame is identical to unlit (existing test, extended).
- **Per lit room:** the bake runs and stays within the size and value range (0..2), and every footprint gets a contact shadow.
- **Windowed proof tool:** shader == reference, 0 off-palette pixels, info and exempt unchanged (the spike checks, kept as a tool).

## Decisions for the Lead, Sol and the owner

1. **Option:** C (runtime bake) with C′ as the fallback.
2. **Floor fill as part of every lit room:** mood change, Sol/owner. If yes, at what lift (1/1 on floor only, spike) and whether it should spare the focal pool's surroundings.
3. **Key direction:** ART_BIBLE 315° globally (recommended), or radial from the focal.
4. **Strength:** contact core 2 / rim 1, AO and cast 1, AO widths 0.5 / 0.3 tile.
5. **Elias:** trousers taking shade is accepted, or the ellipse offset is lowered by 2 px.
