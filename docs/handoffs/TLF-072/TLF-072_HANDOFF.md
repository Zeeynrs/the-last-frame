# TLF-072 handoff: logical canvas 960 x 540 (ADR-023 addendum 3)

Opus, branch `agent/opus-core-tlf072` from `origin/main` `a46a06b`. Not merged.

## What changed

| Area | Change |
|---|---|
| `project.godot` | `viewport_width=960`, `viewport_height=540`. Unchanged: the 1920 x 1080 window override, stretch `viewport`, aspect `keep`, scale `integer` (x2 at 1080p). New: `rendering/environment/defaults/default_clear_color` = `#0A0D14`, palette TLF-CH01-32 index 00 *Abyssal Void* (its darkest colour). It fills only where nothing is drawn (the margin around a room); no art changes. The title screen draws its own background and looks the same. |
| `RoomCamera` | **Fits the view (per axis):** the centre is the middle of the bounds, rounded to a whole pixel, and it never moves. A room smaller than the screen therefore sits centred, with the margin around it. **Larger than the view:** follow and clamp, unchanged. **Constants:** `view_size()` defaults to 960 x 540. The new `LEGACY_SCREEN = Rect2(0, 0, 640, 360)` is the fallback bounds. |
| `RoomRouter` | `current_room_bounds()` without `metadata/room_shape` returns `RoomCamera.LEGACY_SCREEN` (the old screen area), not the view size. **Rooms 2–10:** the camera sits at (320, 180), so they are drawn 160 px right and 90 px down, inside a 160 / 90 px margin. **Pilot room:** bounds (16, 0, 800, 384) fit, so the camera is fixed at (416, 192) and the whole room is on screen. |
| Beat 10 outro | **Letterbox:** the plate stays 1280 x 360 at 1:1 and sits at y = 90 (`Ch01Outro.letterbox_top()`). The full-screen black `Dimmer` makes the 90 px bars. **Pan:** `end_pan_x` and `reduced_effects_static_x` = −320 (1280 − 960), over the same 8.0 s (40 px/s instead of 80). The timing table in `docs/handoffs/TLF-059/TLF-059_HANDOFF_REPORT.md` §2 is updated. **Fix (Lead decision 1):** the outro stopped after "You are late.", because its own `advance_line()` to `OP_B10_01` raised `line_advanced` and `_on_dialogue_line_advanced()` took that for a manual [Enter]. Its three advances now go through `_timeline_advance()`, which the handler ignores. A dialogue the timeline itself finished now waits for the end of the 1.2 s hold (`outro_end`). It used to end the cinematic on the next frame. Manual advance, skip and reduced_effects are unchanged. |
| `DialogueBox.tscn` | The panel was pinned at 640 x 360 offsets (20, 256)–(620, 348), so at 960 x 540 it floated mid-screen. It is now anchored centre-bottom: same 600 x 92 size, 12 px above the bottom edge. On a 640 x 360 view the anchors give exactly the old rectangle. |
| `chapter_complete_overlay.tscn` | The text block was pinned at (20, 16)–(620, 308). It is now anchored to the centre: same 600 x 292, giving the old rectangle at 640 x 360. |
| `ability_wheel.gd` | Mouse aiming measured from a hard-coded (320, 180). It now uses the wheel's real centre, which is (480, 270). |
| Comments | `dialogue_box.gd` and `title_screen.gd` say 960x540. ADR-003 references now name addendum 3 where they meant the canvas. The tile math references (`room_shape.gd`, ROOM_GRAPH §1) still hold and are unchanged. |

### Tests

**Updated:**
- `test_project_settings`: 960 / 540, and the clear colour is `#0A0D14` (setting and renderer).
- `test_room_camera`:
  - The large room is now 64 x 20 (1376 x 752 px) so it still scrolls both ways.
  - The new `test_room_smaller_than_screen_is_centred_and_fixed` covers the legacy fallback at (320, 180) with canvas origin (160, 90), the 14 x 10 room at (352, 136), the pilot bounds at (416, 192), and an odd-sized room on whole pixels.
- `test_room_router`:
  - The big room is 64 x 16.
  - The small room is centred at (352, 136) with canvas origin (128, 134).
  - The west clamp is at view.x / 2.
  - The builder room (704 x 368) is now shown whole, centred at (400, 184).
- `test_room_builder_output`: the builder room is larger than the old 640 x 360 area and smaller than 960 x 540.
- `test_room_shape` and `test_ch01_graph`: "fits the old screen" uses `RoomCamera.LEGACY_SCREEN`.
- `test_ch01_arrival_platform_v2`: camera test 3 now asserts the whole pilot room is on screen, centred at (416, 192), from every key spot.
- `test_ch01_outro_cinematic`: plate at (0, 90), unscaled, equal bars, black full-screen Dimmer, pan bounded by −320 and ending there, reduced-effects frame −320. Two new tests:
  - `test_outro_plays_to_the_end_without_input`: a real DialogueBox and no input. It checks EL_B10_01 at 0.6 s, OP_B10_01 at 4.1 s and OP_B10_02 at 6.9 s, then the dialogue closing after 8.6 s, still playing in the hold, and one `cinematic_completed` after 9.8 s with no skip and the pan at −320. On the `aa05806` outro it fails five asserts, from "Again." on.
  - `test_outro_manual_advance_and_skip_still_work`: [Enter] shows each next line at once and ends the cinematic with the last one; `skip()` after a timeline advance still skips and completes.
- `test_chapter_complete_overlay`: the safe rect is 960 x 540 minus 12 px, and the SceneRouter hint is at (280, 500, 400, 20).

**New:** `tests/ui/test_ui_layout_960.gd`, 5 tests:
- The root view is 960 x 540.
- The dialogue panel is at (180, 436, 600, 92).
- The chapter-complete block is centred.
- The document viewer, wheel and journal are centred at (480, 270), and so is the wheel's mouse centre.
- The HUD feedback panel is centred, 28 px above the bottom edge; the ability panel is at (12, 12); the title menu is centred.

The art mockup tools that draw 640 x 360 proofs are left alone. `tools/capture_arrival_v2.gd` now expects 960 x 540 shots.

## Evidence

- **Screenshots:** windowed (Forward+, D3D12) 960 x 540, from `tools/capture_tlf072.gd`, re-taken for this SHA with the dark clear colour and the fixed outro. It ran in a renamed scratch copy ("TLF Verify tlf072-dev") and wrote saves to `user://tlf072_capture_saves`; the real save folder was not used.

| File | Shows |
|---|---|
| `shot_01_title.png` | Title screen |
| `shot_02_dialogue_line_arrival.png` | Pilot room at boot with Beat 01's first line (dialogue box at the bottom centre) |
| `shot_03_arrival_spawn.png`, `shot_04_arrival_gate.png` | Pilot room: whole room on screen from the spawn and from the gate, camera fixed at (416, 192) |
| `shot_05_ability_wheel.png` | Ability wheel, centred |
| `shot_06_feedback_line.png` | HUD feedback line (`no_history`) |
| `shot_07_document_viewer.png` | Document viewer (`doc_last_service`) |
| `shot_08_old_room_maintenance_bay.png`, `shot_08_old_room_signal_control.png` | Old rooms centred with the margin around them |
| `shot_09_cinematic_start.png` | Beat 10 start: pan x −32 at 0.8 s, plate at y 90, bars top and bottom |
| `shot_10_cinematic_end.png` | 8.4 s with no input: pan at −320 (plate right edge on the view's right edge), "Again." shown by the timeline itself |
| `shot_11_chapter_complete.png` | Chapter-complete overlay with the SceneRouter hint. The cinematic ended by itself after the hold. |
| `shot_12_window_1280x720.png` | The whole 1280 x 720 window (from `tools/capture_tlf072_window.gd`), black borders included |

- **Validate:** see "Validate" below.

## UI text size

The canvas is shown at x2 on a 1080p screen instead of x3, so every UI glyph is a third smaller on screen. The 8 px theme font is drawn 16 physical px tall instead of 24. Panels keep their pixel sizes, so they also cover a smaller share of the screen:
- the dialogue box is 600 of 960 px wide (was 600 of 640);
- the HUD ability panel is 148 px in the corner.

In the screenshots the body text of the dialogue box, document viewer and feedback line is readable but small. No UI scale was added, as the task says; that stays a separate decision.

**Windows smaller than 1920 x 1080 render at x1 with borders.** The stretch is still integer. In a 1280 x 720 window the whole 960 x 540 canvas shows at x1, with 160 px black borders left and right and 90 px top and bottom. Measured: window (1280, 720), `content_scale_mode` 2 (viewport), `content_scale_stretch` 1 (integer), visible rect (0, 0, 960, 540), final transform scale 1 with origin (160, 90); see `shot_12`. At 640 x 360 the same window scaled x2.

## Lead decisions on the first round (`aa05806`)

1. **Outro stall:** fixed, see the Beat 10 row and the two new tests.
2. **Margin:** dark, `#0A0D14`. Re-taken: `shot_03` (pilot), both `shot_08` (rooms 2–10), `shot_09` (cinematic, unchanged: the Dimmer is already black). The title (`shot_01`) is unchanged because it draws its own background.
3. **Docs:** ART_BIBLE and ADR_LOG are not touched. These lines still say 640 x 360:
   - `design/art/ART_BIBLE.md`:
     - line 14: Internal Authoring Canvas `640 × 360 px`, `viewport_width = 640`;
     - §8 heading and §8.1 (lines 191, 193, 194: authoring canvas 640 × 360, "scales ×3 to 1920 × 1080");
     - line 208: font sizes "at 640 × 360";
     - lines 314 and 330: "native 640×360", "Keep 640×360".
   - `docs/ADR_LOG.md`:
     - ADR-003, lines 56 and 60: internal canvas 640×360; the UI is authored at 640×360;
     - ADR-023, lines 395 and 397: "fixed 640×360 screen"; "the internal canvas stays 640×360".

   Addendum 3, line 410, already supersedes them.

## Note

The chapter-complete panel grows to fill its 292 px block, which leaves empty space with a short summary (`shot_11`). It was the same at 640 x 360.

## Validate

Raw key lines, pasted after the run on the pushed SHA, are in the Lead message. `tools/content` is unchanged, so the Python builder tests are not affected; they were run anyway.
