# TLF-083 handoff, Part 1: the ADR-026 lighting pass

Opus, 2026-11-10. Branch `agent/opus-core-tlf083` from `origin/main` `f21aef6`.

**Commits:** code, tests and proofs in **`f1545bd`**; this handoff in the commit after it. Not merged.

**Sources:** task `docs/tasks/TLF-083.md` and ADR-026 (`origin/lead/tlf-080-spec` `1a571ce` / `e8c8155`); Sol's direction `docs/reviews/TLF-082_art_direction.md` (`0326cbf`).

**Scope:** Part 1 only, the pass. **No room scene is changed**, so every room looks exactly as today until a room gets `metadata/lighting`. Part 2 (lighting Concourse West) waits for TLF-080 to land on main.

## What was built

| File | What |
|---|---|
| `scripts/rendering/lighting/lighting_pass.gd` (`LightingPass`) | **Pass:** a `CanvasLayer` at **layer 1** with one full-screen `ColorRect` running the palette shader, above the world canvas and under every UI layer. **Rules:** pure functions (`shifted_index`, `shift_table`, `lift_at`, `output_index`, `validate_room`). The shader indexes the same table and mirrors `lift_at`. **Room handling:** `apply_room(room, lighting, player)` takes the room's `RoomLight` nodes (the first 8; more give a warning). `screen_lights()` converts positions through the viewport's canvas transform and rounds them to whole pixels; it runs every frame. **Visibility:** visible only with a lit room *and* `Settings.lighting_enabled`. |
| `scripts/rendering/lighting/palette_lighting.gdshader` | **Per pixel:** snap to the nearest of the 32 colours (exact for palette art), then lift = the strongest of ≤ 9 slots (8 room lights + the Elias zone; **no sum**), `k = clamp(A − lift, 0, 3)`, output `palette[shift_table[index*4 + k]]`. **Hard bands:** no dither, glow, tint or flicker. |
| `scripts/rendering/lighting/room_lighting.gd` (`RoomLighting`, `metadata/lighting`) | **Room values:** `ambient_steps` 0–3 (default 2), `exempt_from` 25–32 (default **25**; 24 is rejected because index-24 information is protected locally), `dither` (must stay **false**; validation rejects true until Sol accepts a dither). **Elias zone:** offset (0,−20), radius (30,45), lifts **2/1**, inner 0.8. The inner band (24×36) covers his 32×48 sprite; the outer band is a 6–9 px ring (see open point 1). `validate()` lists every range problem. |
| `scripts/rendering/lighting/room_light.gd` (`RoomLight`, a `Marker2D`) | **`ELLIPSE` pool:** radius x/y, lift inner/outer, inner 0.55 (iso floor pools 2:1). **`QUAD` region:** 4 local points around a convex area, lifting `lift_inner` inside. **`only_indices`:** restricts either kind to some palette indices. A QUAD with `only_indices = [24]` is the **information region** for the departure-board glyphs (item 3). `validate()` checks lifts 0..3, outer ≤ inner, positive radius, a convex 4-point quad, and indices 0..31. |
| `scripts/rendering/lighting/tlf_palette.gd` (`TlfPalette`) | The 32 colours and 6 ramp starts (ART_BIBLE §3.1); a test keeps them equal to the `.gpl`. |
| `scripts/rooms/room_router.gd` | `current_room_lighting()`. **Entry:** `_apply_lighting()` runs on every room entry right after `_apply_view_mode()`, and creates the pass as a child the first time a lit room is entered (an unlit chapter never creates one). **Unload:** the pass is cleared on unload, so it never holds freed lights. |
| `scripts/settings/settings.gd` | **`lighting_enabled`:** on by default, saved and loaded under `[accessibility]`, reset to on; off hides the pass. **`reduced_effects`** does not touch it (static lighting). The game has no options menu yet, so it is a `settings.cfg` key like `reduced_effects`. |
| `scenes/ui/HUD.tscn` | `layer = 2` (was the default 1). |
| `scenes/test/TestRoom.tscn` | UI `layer = 2`, so no CanvasLayer in `scenes/` sits at or below the pass. |
| `tests/rendering/test_lighting_pass.gd` | 15 tests (below). |
| `tools/capture_tlf083.gd` | Windowed proof: lights Arrival Platform **at runtime only** and checks the shader pixel by pixel (below). |
| `tools/measure_lighting.gd` | The owner's A/B cost check (below). |

## Task items 1–7

1. **Layers:** the pass is on layer 1; the HUD moves to 2. **Checked:**
   - the wheel 15, outro 60, dialogue 70, documents and journal 80, chapter complete 100;
   - SceneRouter's hint 101 (asserted in its source);
   - `TestRoom.tscn` UI (now 2).

   The test scans **every `.tscn` under `scenes/`** and requires each CanvasLayer above 1.
2. **`RoomLighting` / `RoomLight`:** at most 8 lights; positions go through the canvas transform in whole pixels.
3. **Index-24 information:** a `QUAD` `RoomLight` over the board face with `only_indices = [24]` and lift 2. Proof on the real arrival frame (runtime only):

   | Check | Spawn | Gate |
   |---|---|---|
   | Board glyph pixels kept at 24 | **234 of 234** | **234 of 234** |
   | 24-pixels darkened outside the board (dado, trims) | 1148 | 1112 |
   | Other indices darkened inside the board face (floor, wall, casing) | 1957 | 1957 |

   It restores only the glyphs; the floor, dado and wall around them are not lifted. The pure test does the same on a synthetic face.
4. **Router:**
   - **Lighting on entry:** applied beside `_apply_view_mode()`.
   - **No metadata:** no pass is created, or the existing one hides (`setting off == unlit` is byte-identical, below).
5. **Setting:** `lighting_enabled` (on by default, saved); off hides the pass; `reduced_effects` keeps the static lighting.
6. **Tests (15, all fail when stubbed, see below):**
   - metadata ranges;
   - ≤ 8 lights inside the room bounds;
   - every lit ch01 room validates (0 lit rooms today; it applies automatically to Part 2);
   - UI layers above the pass;
   - the setting hides the pass and is saved (scratch settings file `user://tlf_test_lighting_settings.cfg`, removed after);
   - the ramp table maps every index inside its ramp or to 00/01;
   - the information region;
   - bands, ambient, no adding up;
   - camera and whole pixels;
   - router iso → side → iso, 3 round trips: no orphan nodes, no stale lights, the same pass instance; an unlit room hides it.
7. **Performance:** measured below. No LUT is needed on the dev GPU; the owner's script is ready.

## Proof (windowed, Forward+ D3D12, RTX 5060, 960 × 540)

`tools/capture_tlf083.gd` in a renamed scratch copy lights Arrival Platform at runtime with the ADR-026 arrival values:
- A 2;
- clock 2/1 at (592,160), radius 40×28;
- gate helper 1/0 at (720,326), 64×32;
- the board information quad;
- the Elias zone 2/1.

At the spawn and the gate it saved lit / unlit / setting-off frames (HUD hidden for the checks). `capture.log`:

| | Spawn | Gate |
|---|---|---|
| Shader output vs `LightingPass.output_index()` on the unlit frame | **0 mismatches / 518 400 px** | **0 / 518 400** |
| Off-palette pixels in the lit frame | **0** | **0** |
| Setting off frame == unlit frame (byte-identical) | **true** | **true** |
| Viewport GPU, pass on / off | 0.066 / 0.028 ms | 0.105 / 0.035 ms |

**Images:** `spawn_lit.png` and `gate_lit.png` (HUD visible: HUD, marker and panel stay unlit), `*_lit_nohud.png`, `*_unlit_nohud.png`, `*_setting_off_nohud.png`, and greyscale copies of the lit and unlit frames. The arrival lighting is a demonstration of the pass, **not** a room proposal: Arrival gets its lighting in its own task, under Sol's D.7 review.

**Owner A/B** (`tools/measure_lighting.gd`, `measure_lighting.log`): the worst case is 8 room lights + the Elias zone over a full 960×540 backdrop, 300 frames each.

| GPU | Without the pass | With the pass | Cost |
|---|---|---|---|
| RTX 5060 | 0.012 ms | 0.108 ms (p95 0.114) | **+0.096 ms** |

The ADR-026 budget is 1 ms, so the 32-colour search stays and **no LUT** is needed on this GPU.

**For the owner's machine:** `godot --path . -s tools/measure_lighting.gd` (windowed). It starts no chapter and writes no save or settings; Godot itself still writes its usual engine log under `user://logs`. The last line prints `PASS COST: … -> OK` or `OVER BUDGET`.

## Mutation check (`mutations.log`)

Each stub was applied to the dev scratch copy, the file run, and the stubbed file restored (baseline 15/0, restored 15/0). **12 of 12 go RED.**

| Stub | Result |
|---|---|
| no darkening | 11/4 |
| exemption ignored | 13/2 |
| router hook removed | 14/1 |
| stale lights kept | 14/1 |
| HUD back on layer 1 | 14/1 |
| setting ignored | 14/1 |
| index mask ignored | 14/1 |
| light limit not enforced | 14/1 |
| camera transform ignored | 14/1 |
| overlapping lights add up | 14/1 |
| setting not saved | 14/1 |
| validation off | 14/1 |

## Validate

**Why not one `validate.ps1` call:** the task requires a hard **120 s cap on every Godot call**. `tools/validate.ps1` runs the whole suite in one Godot call, which takes longer than 120 s on this machine, so it cannot finish under the cap. I ran **its three steps on a fresh renamed `git archive f1545bd`** ("TLF Verify f1545bd", `project.godot` without BOM), every Godot call capped at 120 s (`validate_capped.py.txt`):
- **[1/3]** `--headless --import`;
- **[2/3]** the exact script checker embedded in `validate.ps1`;
- **[3/3]** every `tests/**/test_*.gd` in its own Godot call, through a copy of `tests/run_tests.gd` that differs only by a file-name filter (added to the scratch copy after step 2, so the checker saw the archive as committed).

Raw key lines (`validate_capped_f1545bd.log`, sha256 `2367ac71227d2a067b57b2dae2779827bf7b4d3e452706c1b3e654d65cd1e225`):

```
[1/3] import: exit 0, 0 ERROR lines, 17 s
[2/3] script check: exit 0, Script check: 189 scripts, 0 failed., 0 ERROR lines, leak check: clean, 7 s
=== TOTAL: 64 test files, TESTS: 518 passed, 0 failed, SCRIPT ERROR lines 0, files needing a look: ['test_operator_sighting.gd'] ===
```

**The flagged file:** `test_operator_sighting.gd` passes 7/0, but **run on its own** it prints `2 ObjectDB instances were leaked at exit` / `1 resources still in use at exit`. This is pre-existing: the same file run alone on a scratch copy of the older main `fe4bfb1` (before TLF-076 and this branch) prints the same two lines, and my changes touch no operator code.

**Still needed:** the whole-suite leak check (one process) is not reproducible under the 120 s cap; the Lead's official `validate.ps1` run remains the gate.

**Python:** `tools/content` is unchanged, so no Python tests are required.

**Real save:** untouched (`slot_0.json` 11306 bytes, 2026-11-07 16:46). The settings test uses a scratch file and removes it.

## Open points for Sol and the Lead

1. **Elias zone shape.** The first default (radius 44×66, inner 0.55) read as a spotlight moving with Elias. The default is now a tight zone: inner 24×36 just covers the sprite, plus a 6–9 px outer ring (`spawn_lit.png`). It still shows as a narrow capsule of un-darkened floor around him.
   - **Index masking cannot replace it:** his trousers use 02/03, the floor's terrazzo indices (ART_BIBLE A.2).
   - **For Sol:** keep 2/1 tight, use 2/2 tight (no ring), or lower the zone in A-1 rooms. These are data on `RoomLighting`.
2. **Receiver masks.** Not built. A `QUAD` with `only_indices` already confines a lift to a face and a set of indices. A painted per-room mask (Sol §5) is added only if a room's proof shows spill (ADR-026); Part 2 decides that for the concourse.
3. **Side-view shared indices 25/26** (Sol §2: lamp strips and rails). With `exempt_from` 25 these indices never shift, and a `RoomLight` can only *lift*, so no light can calm a decorative 25/26 strip.
   - **Option 1:** a small extension, a "receiver override" region that lets the indices inside it shift although they are ≥ `exempt_from`.
   - **Option 2:** a limited pigment fix in the source art.

   The Lead decides before the side memory is lit.
4. **VFX.** Non-palette world pixels (echo ghost transparency, Trace shimmer) are snapped to the nearest index before the shift. Sol asks for active-VFX proofs; they belong in each lit room's D.7 pack (Part 2), not in this pass-only part.
5. **Settings menu.** None exists; `lighting_enabled` is a config key until a menu task adds a toggle.

## Part 2 (after TLF-080 lands on main)

Concourse West values from ADR-026:
- A 2;
- one focal 2/1 on the turnstile/decision area or the 23:59 clock (choose with Sol);
- one helper 1/0 toward the east door;
- the Elias zone 2/1.

The D.7 proof pack covers the arrival, gate, dials and east door, lit and unlit, measured for 0 off-palette pixels and with greyscale copies. `capture_tlf083.gd` already does the pixel and palette checks.
