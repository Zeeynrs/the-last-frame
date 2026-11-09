# TLF-074 handoff: view_mode plumbing and the side-view movement/camera rule (ADR-025)

Opus, branch `agent/opus-core-tlf074`, stacked on `agent/opus-core-tlf072` at `8384d0f` (Lead instruction 2026-11-10; rebase onto `main` after TLF-072 is merged). Not merged.

## What changed

| Area | Change |
|---|---|
| `scripts/rooms/view_mode.gd` (new, `ViewMode`) | **Constants:** `ISO`, `SIDE`, `TOPDOWN` (reserved). **`ViewMode.of(room)`:** reads `metadata/view_mode` from the room root. With no value it returns `iso`. With `topdown` or an unknown value it returns `iso` and pushes a warning. **`side_view_of(room)`:** returns the room's `metadata/side_view`, or the default layout. |
| `scripts/rooms/side_view.gd` (new, `SideView` resource) | Layout of a side scene, stored as `metadata/side_view`: `floor_y` (default 394, ASSET_METADATA 13.1), `width` (default 960) and `walk_margin` (16). **Bounds:** `bounds_px()` is (0, 0, width, 540). **`snap(p)`:** puts a point on the floor line inside [margin, width − margin]. |
| `RoomRouter` | **New API:** signal `view_mode_changed(mode)`, `current_view_mode()` and `current_side_view()`. **On every room load,** `_apply_view_mode()` calls `player.set_view_mode(mode, side_view)` when the player has that method; the signal fires when the mode differs from the previous room's. **Side rooms:** `current_room_bounds()` returns the scene, and every placement (door spawn, anchor, checkpoint, load) goes through `SideView.snap()`. **Camera:** `_sync_camera()` sets `camera.horizontal_only` in side rooms. |
| `RoomCamera` | `horizontal_only`: y is fixed on the middle of the bounds (270 for a side scene), and x follows and clamps as before, on whole pixels. A 960 px side scene therefore has a fixed camera at (480, 270). A wider one scrolls horizontally only. |
| `DepthSort.apply()` | Returns 0 for a side room. `RoomVisuals` and anything else that calls it get the skip for free. |
| `Player` | **`set_view_mode(mode, side)`:** swaps the SpriteFrames (`ISO_FRAMES` / `SIDE_FRAMES`, both preloaded, so a switch creates nothing new), moves facing to `e`/`w` (any facing containing `w` becomes `w`), snaps Elias onto the floor line and plays idle. **Movement in side:** `compute_side_movement_vector()` uses only the horizontal input (\|x\| > 0.3), at full `walk_speed`, so up/down are ignored and diagonals move horizontally at full speed. After `move_and_slide()` Elias is snapped onto the floor line. **Gesture:** a successful use or watch request plays `interact_<e\|w>`, which the idle update lets finish. **Iso:** unchanged. |
| `scenes/player/elias_side_sprite_frames.tres` (new) | Built from Argon's `ch01_char_elias_side_sheet.png` (TLF-075, ASSET_METADATA 13.1): `idle_e` cells 0–1, `walk_e` 2–7, `interact_e` 8–10, `idle_w` 11–12, `walk_w` 13–18, `interact_w` 19–21. **Speeds:** walk and interact play at 10 fps; interact does not loop. Idle plays at **2 fps**, my choice: the metadata gives 10 fps for the whole sheet, but a 2-frame breathing cycle at 10 fps flickers at 5 Hz. Sol to confirm. **Import:** the sheet's `.png.import` was missing on main and is added, with the same settings as the base sheet. |
| `tests/rooms/fixtures/side_room_fixture.tscn` (new) | **Layout:** `view_mode = &"side"`, a SideView 1440 px wide with the floor at 394. **Contents:** door W with a spawn off the line (to test the snap), anchor and checkpoint at x 200, a Rewind gate at 560, a Freeze gear at 700, a traceable silhouette at 840 and an echo plate at 1000. |

**HUD:** no change was needed. The HUD panels and the dialogue box already sit in the 90 px bars of a side composition, and the target marker converts through the canvas transform. TLF-076 can revisit this with the real scene.

**Refused abilities:** all four work in side view, so nothing is refused for being in side. A refusal from the target itself still uses the existing reason keys; the test checks one, a second Rewind of the gate, against `UIFeedback.REASON_TO_KEY`.

## Tests: `tests/rooms/test_view_mode_side.gd`, 8 tests

The tests use the real `Player.tscn`, a session, the router and the fixture, plus a small iso room linked to it by a door.

1. **`test_mode_switch_both_ways_without_leaks`:** three iso ↔ side round trips through the doors.
   - Each time it checks the mode, SpriteFrames, facing and idle, and the spawn snapped to (72, 394).
   - It also checks the camera's horizontal-only mode and bounds (0, 0, 1440, 540), and that DepthSort returns 0.
   - `view_mode_changed` fires six times (side/iso ×3), and the orphan-node count is unchanged.
2. **`test_unknown_or_reserved_mode_is_iso`:** no metadata gives iso, `topdown` gives iso, and the default floor line is 394.
3. **`test_side_movement_and_facing`:** uses real input.
   - Up or down alone does not move Elias.
   - Right faces `e` and plays `walk_e`, then `idle_e`.
   - Right+up moves at `walk_speed` along the line.
   - Left faces `w` and plays `walk_w`, then `idle_w`.
   - Elias stops at walk_max_x 1424.
4. **`test_side_camera_horizontal_clamp_and_fixed`:**
   - **1440 px scene:** y is always 270, x is clamped to [480, 960] on whole pixels, and the view stays inside the scene. With Elias at x 700 the camera is at (700, 270).
   - **960 px scene:** the camera is fixed at (480, 270).
5. **`test_each_ability_in_the_side_room`:** each ability through the pocket watch.
   - Trace, Rewind and Freeze each target their object from a spot on the floor line and succeed.
   - A refusal comes back with an existing key.
   - Echo records, stops and plays back, and the echo holds the plate.
6. **`test_echo_and_rewind_positions_on_the_floor_line`:**
   - A recorded walk, done while also pressing down, has every echo position on y 394, and the ghost walks on y 394.
   - Rewinding the gate leaves Elias and the gate on the line.
7. **`test_save_load_in_the_side_room`:** saves at the side checkpoint, then restores into a fresh session that is standing in the iso room.
   - On the same frame as the restore, the mode, sprites, horizontal camera and bounds come back, the player is at the anchor (200, 394) and the camera is at (480, 270).
   - `view_mode_changed` fires, the player is still on the line after physics, and the test saves are removed.
8. **`test_side_sprite_frames_and_reach_gesture`:**
   - The six animations have the right frame counts, loop flags and sheet cells.
   - A real-input Trace plays `interact_e`, then `idle_e`.

The rest of the suite is unchanged and passes. The pilot scene, its art placement and its real-input walk belong to TLF-076.

## Validate

The raw lines are in the Lead message. `tools/content` is unchanged.
