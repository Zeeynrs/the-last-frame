# TLF-082 lighting options and ADR-026 proposal (Part 1, Opus)

Opus, 2026-11-10, on `origin/main` `f21aef6`.

**Task:** `docs/tasks/TLF-082.md` (branch `lead/tlf-080-spec`).

**Inputs:** PATTERN.md rule 11, ART_BIBLE §3 (TLF-CH01-32), §4 (planar values), §5 (binary alpha, dithering) and Appendix D (D.2 mood table, D.6, D.7). The owner now authorizes a lighting system (2026-11-10); that supersedes D.2's last bullet.

**Scope:** proposal and spike only. No game branch, scene or project file is changed. The spike ran in a renamed scratch `git archive` of `f21aef6` ("TLF Verify tlf082-spike"), with a hard timeout on every Godot call and the real save untouched. The evidence is in `TLF-082/spike/`. Sol's art-direction review (Part 2) comes next and sets the final values.

## Recommendation (for ADR-026)

Use **runtime lighting computed in palette space: a palette-indexed ramp-shift pass** (option C below).
- **Where:** one full-screen pass over the world canvas, under every UI layer.
- **What it does:** for each pixel it finds the TLF-CH01-32 index and moves it **k whole steps down that index's own material ramp**.
  - **k** = room ambient minus the lift of the strongest motivated light at that pixel.
  - **Lights:** stepped elliptical bands, placed as nodes by the room author.
  - **Exemptions:** emissive and information indices (ramp 5 hot entries, all of ramp 6) never shift.
- **Strictly palette-safe:** 0 off-palette pixels, by construction and as measured. It keeps each material's hue family and is identical in iso and side view. It follows the camera, is deterministic, costs about 0.07 ms on the dev GPU, and is switched off with one setting.
- **Later, if Sol wants light that stops at walls:** an optional **authored lift mask** per room (painted data, not pixels) can be added to the same pass.

**Rejected:**
- **A, Godot `CanvasModulate` + `PointLight2D` as they are:** the colours leave the palette.
- **A + post-quantize:** the palette is fixed, but material hues drift.
- **B, authored overlay sprites:** they cannot darken actors or upright bodies, stipple destroys text, and they cannot follow Elias.

The details follow.

## 1. The options in the spike

All variants were shot on Arrival Platform v2 in a windowed Forward+ run at 960 × 540, from two positions:
- **spawn:** Elias at (160, 224);
- **gate:** Elias at (656, 264), next to the selectors, with the platform gate at (720, 328).

The HUD is visible: the ability panel, the target marker on a commuter, and a feedback line. The camera is the room's fixed view (−64, −78, 960, 540).

**Motivated lights in the spike**, chosen to match D.2 "small readable silhouette zone around Elias; optional subdued status indicator":
- the 23:59 clock at (592, 160);
- the gate at (720, 314);
- a small zone that follows Elias.

| Variant | What | Files |
|---|---|---|
| v0 | Baseline (main today) | `spawn_v0_baseline.png`, `gate_v0_baseline.png` |
| v1 (A) | `CanvasModulate` (0.42, 0.47, 0.60) + three `PointLight2D`, ADD blend, with pixel-stepped light textures (3 flat bands, nearest) | `*_v1_runtime.png` |
| v2 (A + quantize) | v1, then every pixel snapped to the nearest palette colour | `*_v2_runtime_quantized.png` |
| v3 (B) | Authored-overlay mock: a static 2×2-Bayer stipple of `#0A0D14` (binary alpha, palette 00) at z 9, with clear pools at the clock and gate | `*_v3_overlay.png` |
| v4 (C) | Ramp shift: ambient 2 steps, lift 2 in the inner band and 1 in the outer, exemptions from index 24 | `*_v4_ramp_shift.png` |
| v4b (C) | As v4, exemptions only from 25: the dado stripe (24) shifts too | `*_v4b_ramp_shift_exempt25.png` |
| v4c (C) | As v4, with a 2×2 Bayer dither across each band edge (adjacent steps only) | `*_v4c_ramp_shift_dither.png` |
| side (C) | The Mira memory (ADR-025 side view, horizontal camera) with v4; lights at the clock, Mira and Elias | `side_v0_baseline.png`, `side_v4_ramp_shift.png`, `side_v4_ramp_shift_scrolled.png` (camera x 960) |

**Measurements** (HUD hidden; `spike/palette_stats_nohud.json`):

| Variant | Off-palette pixels | Distinct colours | Mean luma (0–255) | GPU frame time (RTX 5060) |
|---|---|---|---|---|
| v0 | 0 | 30 | 22.7 | 0.033 ms |
| v1 | **134,912 (26 %)**, which is almost every room pixel; the rest is the clear-colour margin | 149–170 | 16.3 | 0.044 ms |
| v2 | 0 | 27 | 17.2 | 0.101 ms |
| v3 | 0 | 29 | 18.5 | 0.040 ms |
| v4 | 0 | 29 | 16.0 | 0.101 ms |
| v4b | 0 | 29 | 15.8 | 0.101 ms |
| v4c | 0 | 29 | 16.0 | 0.106 ms |

- **Determinism:** v4 at the gate captured twice gives md5 `1049fb6914e8` both times.
- **Side view:** the side captures contain the HUD; their only 844 off-palette pixels are HUD text and label colours, the same in v0 and v4.
- **GPU times:** viewport GPU render time, averaged over 90 frames. Absolute numbers on the dev GPU say nothing about the low-end target (section 3).

## 2. Comparison

| Criterion | **A. Godot `CanvasModulate` + `PointLight2D`** | **B. Authored overlay sprites** | **C. Palette-indexed ramp shift (recommended)** |
|---|---|---|---|
| **Palette fit (32 colours)** | **Fails.** A multiply and an additive light make new RGB values everywhere: v1 has 149–170 colours, with 26 % of the frame (practically the whole room) off-palette. **With a post-quantize (v2)** the palette holds, but the nearest colour crosses ramps: blue terrazzo (ramp 1) and ceramic (ramp 2) turn into neutral steel greys (ramp 3), so material hue drifts (compare `gate_v2` with `gate_v0`). | **Holds** (palette 00 with binary alpha). Brightening is impossible without replacing the art's pixels, so "light pools" can only be the absence of stipple. | **Holds by construction:** every output pixel is a palette entry (0 off-palette), and each pixel stays in **its own ramp** (terrazzo stays blue, steel stays grey, the coat stays brown), as §4 wants for planar value. |
| **Clues and ability targets** | CanvasModulate also dims the emissive pixels (the 23:59 digits, the tactile studs, temporal VFX) unless a light covers them, and it needs a light mask per item to exempt them. **The HUD and the wheel** are CanvasLayers, so they are not affected. | The stipple covers the floor, walls and **readable text**: the departure board and the `CLOSED TRACK` plaque fall apart in `gate_v3`. Anything drawn above the overlay's z (Elias, commuters, the gate, the train car: actor layer 10) is **never darkened**, so the scene splits into lit actors on a screen-door room. | Indices from `exempt_from` up never shift. With 24 they are the clock digits, tactile studs, watch pickup, departure-board LEDs and ramp-6 temporal VFX and UI cyan, so clues and ability feedback keep full value in the dark (`spawn_v4`: the pickup at the spawn stays bright amber). **The HUD, marker and wheel** are on layers above the pass and stay unlit (all v4 shots). |
| **Iso and side view (ADR-025)** | Works in both. | Works in both, but it is per-room art and must be redrawn whenever the layout changes. | **Same pass and nodes in both** (`side_v4*`). A light radius is set per light: 2:1 ellipses for iso floor pools, upright ellipses for side figures. |
| **Follow camera** | Lights are world nodes; fine. | Static overlay in world space; fine while the camera moves in whole pixels. **It cannot follow Elias.** | The pass reads light positions through the canvas transform every frame, rounded to whole pixels; it was checked with the scrolling side camera (`side_v4_ramp_shift_scrolled`, camera x 960). |
| **Performance (low end)** | Cheapest (+0.01 ms here); 2D lights are evaluated per lit item. | Cheapest at runtime. Memory: one room-sized texture per room. | One 960 × 540 pass with a 32-entry nearest-colour loop and ≤ 8 light tests per pixel: +0.07 ms on the dev GPU. **Not yet measured on low-end hardware.** If needed, a 32³ index LUT texture replaces the loop. |
| **Determinism and tests** | Deterministic, but a pixel test must allow off-palette colours. | Deterministic. | Deterministic (identical md5). Purely presentational: no gameplay state, no physics, no RoomRouter state. The headless suite never renders it, so no existing test changes. |
| **Authoring** | Place `PointLight2D` nodes, tune energy/colour/texture/masks; easy to over-light (D.2's main risk). | Argon/Sol paint a full-room overlay per room plus a regen pipeline, and repaint it after any layout change. | `metadata/lighting` on the room root (ambient steps, exemption threshold, dither on/off) plus a few `RoomLight` marker nodes (radius x/y, lift); the Elias light is one per room. Hard to over-light: a light can only undo the ambient darkening, never brighten above the authored art. |
| **Fallback / Settings** | Hide the modulate and the lights. | Hide the overlays. | **One flag:** with lighting off the pass is hidden and the game looks exactly like today. |
| **Main risk** | Breaks the palette rule; the quantized version drifts material hue. | Unreadable text, lit actors on a dark room, art cost per room. | **Shared indices:** a pixel's index says nothing about which object it belongs to. Exempting 24 keeps the departure-board LEDs lit, but also the orange dado stripe along every wall base (v4). Not exempting it (v4b) darkens the stripe and the board text (it turns dark red). See section 4. |

## 3. Proposed ADR-026 shape (for the Lead's decision)

1. **One pass.** A `LightingPass` scene owns:
   - a `CanvasLayer` at **layer 1** with one full-screen `ColorRect` and the palette shader (the spike's `palette_light.gdshader`, plus a LUT if needed);
   - **the HUD moves from layer 1 (default) to layer 2.** It is the only game UI layer below 15; the wheel (15), outro (60), dialogue (70), documents and journal (80), chapter complete (100) and its SceneRouter hint (101) are already above. Only the test scene `TestRoom.tscn` also uses the default layer.

   The pass sits under every UI layer and above the world canvas.
2. **Per room:**
   - **`metadata/lighting`:** a small `RoomLighting` resource with `ambient_steps` (0–3), `exempt_from` (24 or 25), `dither` (bool), and `player_light` (radius x/y, lift).
   - **`RoomLight` nodes** (Marker2D with radius x/y, lift 1–2, optional `follow` path) under the room root.
   - **Without the metadata,** lighting is off and the room looks as it does today, so rooms not yet rebuilt are untouched (PATTERN rule 11 adds lighting room by room from room 2).
3. **Router hook.** RoomRouter applies the room's lighting on entry, in the same place as `_apply_view_mode()`. The pass reads the `RoomLight` positions through the canvas transform each frame, rounded to whole pixels, with at most 8 lights. Appendix D asks for one dominant focal light per screen; Sol sets the per-screen budget.
4. **Settings.**
   - A new **`lighting_enabled`** (on by default). Off hides the pass, for low-end machines and for players who find the dark rooms hard to read.
   - **`reduced_effects`** keeps lighting (it is static: no flicker, nothing animated); any future animated light is frozen under it.
5. **Tests** (headless, cheap):
   - every room with `metadata/lighting` validates (ranges, ≤ 8 lights, lights inside the room bounds);
   - the HUD layer is above the pass layer;
   - the setting hides the pass;
   - the ramp table maps every index to an index of the same ramp, or to 00/01 below its start (a pure function, testable without rendering);
   - the router hook switches lighting with the room (iso → side → iso, no leaks).
6. **Proof pack per lit room** (D.7): windowed native shots at spawn and focal points, lighting on and off, with a palette check of 0 off-palette pixels outside the HUD.
7. **Low-end gate before merge:** measure the pass with the owner's lowest machine (the Settings toggle gives the A/B comparison). If it costs more than 1 ms, replace the loop with the LUT.

## 4. Open points for Sol (Part 2) and the Lead

- **Exemption threshold and shared indices:**
  - **`exempt_from` = 24 (v4)** keeps the departure board readable but leaves the orange dado stripe lit along every wall.
  - **25 (v4b)** dims the stripe and the board's LED text.
  - **Fix without new colours:** a small `RoomLight` (lift 2) on the board keeps it readable under 25. Alternatively, Argon moves the board's LED segments from 24 to 25 (same ramp).
- **Ambient and lift values:** the spike uses ambient 2 and lift 2/1, which leaves the unlit floor at 00–01 and walls at 06–07. Sol sets these per area against the D.2 table:
  - **Maintenance:** likely ambient 3 ("nearly unlit");
  - **Concourse:** ambient 1–2 with broad low lifts at the exits.
- **Band edges:** hard steps (v4) read as discs on the iso floor. v4c's 2×2 Bayer edge is allowed for environment by §5.3 but also falls on characters inside the edge band (§5.3 forbids character dithering); keep it off, or make the Elias light large enough that he is never in an edge band.
- **Light shape:** circles and ellipses ignore walls; a pool can spill over a wall top (`gate_v4`). If Sol wants pools that stop at walls, the follow-up is an **authored lift mask** per room: a coarse painted texture (e.g. 1 texel per 8 px) read by the same pass. That keeps option B's art control without its drawbacks.
- **Non-palette pixels in the world:** some world pixels are not palette colours (semi-transparent echo ghost, Trace shimmer, any modulated sprite). The pass snaps them to the nearest index first and then shifts them. That needs a check with active temporal VFX in a proof pack; the spike shows only idle frames.

## Evidence

All files are in `docs/reviews/TLF-082/spike/`.

- **Screenshots** (960 × 540 viewport images, HUD visible): spawn and gate × v0, v1, v2, v3, v4, v4b and v4c; side v0, v4 and v4 scrolled.
- **Spike code** (scratch only, kept as text): `spike_tlf082.gd.txt` and `palette_light.gdshader.txt`.
- **Run log:** `spike_run.log`. The windowed run exited 0 with no ERROR or SCRIPT ERROR; the import also exited 0 with no SCRIPT ERROR.
- **Palette check:** `palette_stats_nohud.json`. Pixels were checked against `assets/source/ch01/ch01_palette_elysium09.gpl`; the HUD-hidden captures are not committed.
- **Not done:** no game code, no validate (nothing in the game changed), no low-end measurement, no active-VFX check.
