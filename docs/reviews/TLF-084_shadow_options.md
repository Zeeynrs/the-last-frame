# TLF-084 Part 1: shadow and depth options (draft)

Opus, 2026-11-11. Branch `agent/opus-core-tlf084` from `origin/main` `1388d6d`. No game code changes on this branch. The spike runs in a renamed scratch copy, and its code is kept as text in `docs/reviews/TLF-084/spike/` (`capture_tlf084.gd.txt`, `palette_lighting_spike.gdshader.txt`, `lighting_pass_spike.diff.txt`).

**Status:** this is a DRAFT, because the session hit its usage limit. The spike evidence and the measured numbers are complete. What is missing is the visual review of the floor-fill shots and a longer comparison text (see "Left to do").

## Recommendation: pass-side shade map, plus a floor fill per room

Recommended: option **C, a world-space shade map baked at room entry**, plus one dynamic contact ellipse under Elias.
- **Pass rule:** `k = clamp(A − lift + shade, 0, 3)`.
- **Receivers:** floor indices 00-05 only.
- **Never shaded:** pixels inside an information region, and indices at or above `exempt_from` (the shift table already keeps them fixed).

The map is derived automatically from what every room already has:
- **AO strips** along the tall N/W wall bases (0.5 tile), along the low S/E edges, and on both sides of the turnstile dividers (0.3 tile). The source is `RoomShape.wall_segments()` plus divider segments.
- **Contact shadows:** 2:1 ellipses with core shade 2 and rim shade 1. They go under every `StaticBody2D` footprint (statues, validator, gate, pillar) and under actor-layer sprites that have no body (courier, reset console, bench).
- **Cast shadows:** shade 1, a tapered floor quad pointing away from the focal `RoomLight`. It is used for grounded sprites at least 28 px tall, with length = height / 32 tiles.
- **Elias:** contact only, as a dynamic ellipse (8×4).

**Key finding: shadows need a floor that still has value.** At A 2 the open terrazzo is already at 00-02. One more shade step there is nearly invisible: only about 2 000 px change per frame, and almost all of them are inside the gate and east pools.
- **What the fill does:** a broad floor fill (one `RoomLight`, lift 1/1, only indices 00-05, covering the floor) keeps one ramp step on the floor. With it, the AO, contact and cast shadows read across the room: about 10 500 px change per frame. The fill also answers the Fable P3 "floor collapses to 00".
- **Proposal:** fill + shade as the per-room default. Sol or the owner decides, since it lifts the room's darkness by one step on the floor only.

## Options compared (short)

| Option | Palette | Authoring | Readability / info | Lights | Side view | Cost | Lighting off |
|---|---|---|---|---|---|---|---|
| **A** Analytic shapes as shader uniforms | Safe (ramp shift) | Automatic | Index mask + info suppression | Shade adds after lift | Works | Grows with the shape count: about 30 shapes per room, a loop per pixel | Identical |
| **B** Authored shadow sprites (palette 00/01) | Safe, but they overwrite the floor (the grid disappears) | Art for every object, placed by hand | Must be hidden when lighting is off (otherwise lighting off ≠ unlit) | Not darkening: a flat blob. Spike `sprites_*`: 0 px darker, the blob replaces the floor | Needs side variants | Free | Extra node toggling |
| **C** Shade map baked at room entry (**recommended**) + Elias ellipse | Safe | Automatic from colliders and walls; overrides possible | Same masks as A | Same as A | Same map in world px (spike `side_*`) | +0.003..0.006 ms GPU; bake 32 ms GDScript per room entry (736×432 map) | Identical |
| **C′** Same map baked offline by the room builder (file) | Safe | Automatic, with a staleness test | Same | Same | Same | 0 at entry | Identical |

## Spike evidence (`docs/reviews/TLF-084/spike/`, log `spike.log`)

**Setup:** windowed Forward+ at 960×540, in a scratch archive of `1388d6d` ("TLF Verify tlf084spike"). The lighting comes from the room scene.

**Images per shot:** `<shot>_lit`, `<shot>_lit_shadows`, `<shot>_unlit`, greyscale copies of each, and `<shot>_x2_lit_vs_shadows`. The shots are:
- arrival, gate, dials, east;
- `sprites` (option B, gate);
- `side` (side memory, runtime A 1 plus a Mira 1/0 light, a far-wall AO band, contact and cast shadows);
- `*_fill` (A 2 + floor fill + shade).

| Check | All 10 shots |
|---|---|
| Shader vs GDScript reference (518 400 px) | **0 mismatches** |
| Off-palette | **0** |
| Lighting off == unlit (bytes) | **true** |
| Information pixels changed by shade | **0** (488 / 487 checked) |
| Exempt (≥ 25) pixels changed | **0** |
| GPU cost of the shade term | **+0.003 … +0.006 ms** (pass about 0.11 ms) |
| Bake (GDScript rasterizer) | about 32 ms per room entry |

**Real save:** untouched (`slot_0.json` 11306 bytes, 2026-11-07 16:46).

## Left to do (next session)

1. Look at the `*_fill` and `side_*` images and write the visual comparison. These images were captured but **not yet reviewed by me**.
2. Expand the per-option sections: test impact, how a room adds overrides (e.g. `metadata/shadow` exclusions, key-light override), and side-view rules (wall/deck AO, horizontal cast).
3. Bake cost on low-end hardware. A 32 ms GDScript bake at room entry may need C′ (offline) or a GPU rasterizer.
4. The open question about the Elias ellipse vs his trousers on terrazzo 02/03 (they also receive shade).
