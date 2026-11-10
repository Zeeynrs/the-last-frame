# TLF-080 technical re-review, fix round (Flash, `db7efcf`)

Opus, 2026-11-10. Read-only re-review of `origin/adityadaffa522/tlf-080-concourse-v2` at `db7efcf`. It builds on `f44af6e` and includes merge `02f6042` of TLF-081 `f84f19e`.

**Checked against:** my review `TLF-080_f44af6e_OPUS_REVIEW.md` (`145c3c1`) and Sol's `TLF-080_f44af6e_SOL_VISUAL.md` (`8d35510`).

**Method:**
- **Scratch copy:** a renamed `git archive` ("TLF Verify rev080-db7efcf"), imported headless with 0 ERROR.
- **Runs:** every Godot call had a hard 120 s cap and no `--eval`. I ran the affected test files, my round-1 divider probe, and a 12-stub mutation run against Flash's suite.
- **Unchanged:** no Flash file was changed and nothing was merged; the real save was not touched.
- **Evidence:** `TLF-080/db7efcf/`.

## Verdict: **APPROVE** (no P1 left; one P2 test gap and P3 notes, none blocking)

## 1. Round-1 items

| Item (source) | Status at `db7efcf` | Evidence |
|---|---|---|
| **P1 divider guard** (Opus 1) | **Closed.** `test_divider_sweep_with_gate_closed_never_passes_x_8_2` sweeps 19 lines (start x 7.2, y 0.8–15.2) with the gate closed, asserting x ≤ 8.2 and a maximum < 8.0. | **Mutations:** DividerNorth disabled **in the scene** is **RED** (x 8.88–9.21); DividerSouth disabled is **RED** (x 8.99–9.11). Flash's two in-suite tests that disable a divider at runtime and expect a crossing are an extra sensitivity check, not a replacement; the scene-level stubs are what count. **My probe C** (straight and diagonal pushes): furthest x **7.77** with no crossing; once open, the gate is passable for y 7.6–9.2. |
| **P1 visible divider** (Opus 2, Sol 1) | **Closed.** Eight `PartitionLowE_divider_*` sprites in `YSort_Walls` exactly per Sol's table: whole modules at `(432,136)`, `(400,152)`, `(368,168)`, `(272,216)`, `(240,232)` and `(208,248)` with offset `(-16,-24)`; north half `(336,184)` with region `(16,0,16,32)` and offset `(0,-24)`; south half `(304,200)` with region `(0,0,16,32)` and offset `(-16,-24)`. | **Aperture not narrowed:** the half pieces end at x 336 and x 304, the divider end points, so the 32 px (2-tile) gap stays visually open. The sprites have no collision, and probe C confirms the passable band is unchanged. **No actor hidden:** the gate presenter, courier presenter and reset console are `z_index 10` (absolute) over the partitions' z 5 (the existing wall convention). Flash's new gate and dial shots agree. |
| **P2 tactile cells** (Opus 3, Sol 3) | **Closed** (removed, as Sol asked; not moved). | Decoded floor: 448 cells = 431 dark + 17 cracked, **0 tactile**. |
| **Evac notice** (Sol 2) | **Closed.** `doc_evac_notice` at **(384,272) = tile (15,11)**. | The reach test spot was updated; the stand-spot test passes. |
| **P2 camera test** (Opus 5) | **Closed.** It asserts `current_room_bounds() == Rect2(48,0,736,432)` and centre `(416,216)`. | **MC3** (bounds ignore `room_shape`) is now **RED** (it was GREEN). |
| **P2 BOM/mojibake** (Opus 6) | **Closed.** | `test_ch01_art_integration.gd` has no BOM; `§1` is restored. |
| **P2 dry-run file** (Opus 7) | **Closed.** | `diff_concourse_dry_run.txt` is no longer in the tree. |
| **P3 graph rule** (Opus 9) | **Closed.** The E-door edge exception is per room (`ch01.concourse_west` only); every other room keeps `x == w − 1`. | `test_ch01_graph` 9/0. |
| **P3 AU-08** (Opus 11) | **Closed for clause 1.** The test places Elias on the entry anchor (304,184), asserts `n05_courier` is the Trace target at 17.9 px, then also checks the spawn and does the real-input Trace. | Clause 2/flood-fill ((312,188) overlaps the closed gate Blocker) is the documented pre-existing TLF-056 limit. |
| **P2 conduit far from the gate** (Opus 4) | Not changed; Lead/Sol decision (spec placement). Sol's review accepts the fallen conduit as floor art. | — |
| **Collision baseline and manifest** | Re-baselined for this room only. | Decoded fingerprint: only `concourse_west` differs from `f44af6e`. `render_manifest.json`: only `rooms[concourse_west]` changes; the top-level fields are identical. |

## 2. Art swap (TLF-081 `f84f19e` merged)

Final PNG top-lefts (scene/presenter transform + offset, `centered=false`) against `mount_correction.json` / ASSET_METADATA §14.2:

| Fixture | Transform | PNG top-left | Recipe | Result |
|---|---|---|---|---|
| dial_line / platform / time | Presenter position `(-16,-58)`; `history_dial_presenter.gd` offset `Vector2.ZERO` | (544,134) / (576,150) / (608,166) | same | ✓ |
| Call box (W idle) | `CallBoxSprite` position `(260,47)`, offset `(0,-11)` | (260,36) | (260,36) | ✓ |
| Mounted conduit (W) | `conduit_prop_presenter.gd` when mounted: position `(-32,-35)`, offset `(0,-23)` | 144−32, 160−35−23 = **(112,102)** | (112,102) | ✓ |
| Fallen conduit | when fallen: position `ZERO`, offset `(-24,-26)` (as before) | (120,134), unchanged from `f44af6e` | — | ✓ still correct |
| Ticket terms (W) | `DocSprite` position `(-16,-35)`, offset `(0,-7)` | (72,146) | (72,146) | ✓ |
| Validator (N, freestanding) | presenter offset `(-16,-42)` (script and scene), `z_index 10` | (608,198) | (608,198), actor sorting §14.3 | ✓ |

**The presenter now switches the transform with the state:** a Rewind to mounted and a reset to fallen each select the matching texture, position and offset on the next `_refresh()`.

**The new integration test (`test_tlf081_wall_art_integration_and_transforms`) fails when a recipe is off.** Each stub moved by 1 px is **RED**:
- the dial_line presenter;
- the mounted conduit position;
- the ticket-terms DocSprite;
- the validator offset (presenter script);
- the call-box sprite;
- the dial offset back to the frontal `(-16,-28)`;
- `WallW_6`.

**P2 (Flash, small):** moving **`WallN_7`** (the dial_line wall) or **`WallW_1`** (the call-box wall) by 1 px stays **GREEN**. The test asserts the W5–W7 module transforms only, while the dial and call-box recipes depend on `WallN_7..9` and `WallW_1` too (`mount_correction.json` asks for "actual module transforms"). Adding four `global_position + offset` assertions closes it: N7 `(544,128)`, N8 `(576,144)`, N9 `(608,160)`, W1 `(256,32)`.

**Unused states, P3 (none were wired on main either):**
- **Validator:** `tex_rejecting` is exported but `_refresh()` only selects idle or accepted; main's presenter had no rejecting state.
- **Dials:** `tex_jammed` is exported but never selected, the same on main.
- **Call box:** the static `CallBoxSprite` has no ringing state, the same on main.

## 3. Mutation run (`mutations_db7efcf.log`)

Baseline 11/0; restored 11/0. The stubbed files are identical to `db7efcf` afterwards.

| Stub | Result |
|---|---|
| D1 DividerNorth disabled in the scene | **RED** 10/1 |
| D2 DividerSouth disabled in the scene | **RED** 10/1 |
| MC3 bounds ignore `room_shape` | **RED** 10/1 |
| R1 dial_line presenter +1 px | **RED** |
| R2 mounted conduit +1 px | **RED** |
| R3 ticket-terms DocSprite +1 px | **RED** |
| R4 validator offset +1 px | **RED** |
| R5 call box +1 px | **RED** |
| R6 dial offset frontal | **RED** |
| R7 WallW_6 +1 px | **RED** |
| R8 WallN_7 +1 px | GREEN (P2 above) |
| R9 WallW_1 +1 px | GREEN (P2 above) |

## 4. Tests on `db7efcf` (each its own Godot call, ≤ 120 s)

| File | Result |
|---|---|
| `test_ch01_concourse_west_v2` | 11/0 (56 s) |
| `test_ch01_step1_negatives` | 12/0 |
| `test_ch01_real_playthrough` | 1/0 |
| `test_ch01_art_integration` | 6/0 |
| `test_ch01_sort_order` | 3/0 |
| `test_ch01_graph` | 9/0 |
| `test_dial_readout` | 3/0 |
| `test_ch01_playthrough` | 19/0 |
| `test_ch01_unlock_guards` | 4/0 |
| `test_audio_real_input` | 2/0 |

All have **0 SCRIPT ERROR and 0 ERROR**. The full validate is the Lead's.

## 5. P3 notes

- **Draw order:** the partitions sit at the wall layer (z 5), so an actor standing *behind* a low partition still draws over it. That is the existing wall convention Sol asked to keep; Sol may want to look at it once Elias walks along the dividers.
- **Screenshot renderer:** the handoff says the screenshots were taken with **OpenGL3 / Compatibility**; the game renders with D3D12 Forward+. Sol's D.7 proofs should be on Forward+.
- **One handoff label still wrong:** the `dial_line` stand spot (544,200) is labelled `(14.5, 0.5)`; it is tile (15.5,1.5). The positions are right.
- **Fallen-conduit transform not asserted:** the integration test sets the mounted state only, so a later regression in the fallen branch would be caught only visually.
