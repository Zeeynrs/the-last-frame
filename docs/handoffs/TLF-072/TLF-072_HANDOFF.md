# TLF-072 handoff: logical canvas 960 x 540 (ADR-023 addendum 3)

Opus, branch `agent/opus-core-tlf072` from `origin/main` `a46a06b`. Not merged.

## What changed

| Area | Change |
|---|---|
| `project.godot` | `viewport_width=960`, `viewport_height=540`. Unchanged: the 1920 x 1080 window override, stretch `viewport`, aspect `keep`, scale `integer` (x2 at 1080p). |
| `RoomCamera` | **Fits the view (per axis):** the centre is the middle of the bounds, rounded to a whole pixel, and it never moves. A room smaller than the screen therefore sits centred, with the margin around it. **Larger than the view:** follow and clamp, unchanged. **Constants:** `view_size()` defaults to 960 x 540. The new `LEGACY_SCREEN = Rect2(0, 0, 640, 360)` is the fallback bounds. |
| `RoomRouter` | `current_room_bounds()` without `metadata/room_shape` returns `RoomCamera.LEGACY_SCREEN` (the old screen area), not the view size. **Rooms 2–10:** the camera sits at (320, 180), so they are drawn 160 px right and 90 px down, inside a 160 / 90 px margin. **Pilot room:** bounds (16, 0, 800, 384) fit, so the camera is fixed at (416, 192) and the whole room is on screen. |
| Beat 10 outro | **Letterbox:** the plate stays 1280 x 360 at 1:1 and sits at y = 90 (`Ch01Outro.letterbox_top()`). The full-screen black `Dimmer` makes the 90 px bars. **Pan:** `end_pan_x` and `reduced_effects_static_x` = −320 (1280 − 960), over the same 8.0 s (40 px/s instead of 80). The timing table in `docs/handoffs/TLF-059/TLF-059_HANDOFF_REPORT.md` §2 is updated. |
| `DialogueBox.tscn` | The panel was pinned at 640 x 360 offsets (20, 256)–(620, 348), so at 960 x 540 it floated mid-screen. It is now anchored centre-bottom: same 600 x 92 size, 12 px above the bottom edge. On a 640 x 360 view the anchors give exactly the old rectangle. |
| `chapter_complete_overlay.tscn` | The text block was pinned at (20, 16)–(620, 308). It is now anchored to the centre: same 600 x 292, giving the old rectangle at 640 x 360. |
| `ability_wheel.gd` | Mouse aiming measured from a hard-coded (320, 180). It now uses the wheel's real centre, which is (480, 270). |
| Comments | `dialogue_box.gd` and `title_screen.gd` say 960x540. ADR-003 references now name addendum 3 where they meant the canvas. The tile math references (`room_shape.gd`, ROOM_GRAPH §1) still hold and are unchanged. |

### Tests

**Updated:**
- `test_project_settings`: 960 / 540.
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
- `test_ch01_outro_cinematic`: plate at (0, 90), unscaled, equal bars, black full-screen Dimmer, pan bounded by −320 and ending there, reduced-effects frame −320.
- `test_chapter_complete_overlay`: the safe rect is 960 x 540 minus 12 px, and the SceneRouter hint is at (280, 500, 400, 20).

**New:** `tests/ui/test_ui_layout_960.gd`, 5 tests:
- The root view is 960 x 540.
- The dialogue panel is at (180, 436, 600, 92).
- The chapter-complete block is centred.
- The document viewer, wheel and journal are centred at (480, 270), and so is the wheel's mouse centre.
- The HUD feedback panel is centred, 28 px above the bottom edge; the ability panel is at (12, 12); the title menu is centred.

The art mockup tools that draw 640 x 360 proofs are left alone. `tools/capture_arrival_v2.gd` now expects 960 x 540 shots.

## Evidence

- **Screenshots:** windowed (Forward+, D3D12) 960 x 540, from `tools/capture_tlf072.gd`. It ran in a renamed scratch copy ("TLF Verify tlf072-dev") and wrote saves to `user://tlf072_capture_saves`; the real save folder was not used.

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
| `shot_10_cinematic_end.png`, `shot_10b_cinematic_end_again.png` | Pan at −320 (plate right edge on the view's right edge), "You are late." and "Again." |
| `shot_11_chapter_complete.png` | Chapter-complete overlay with the SceneRouter hint |

- **Validate:** see "Validate" below.

## UI text size

The canvas is shown at x2 on a 1080p screen instead of x3, so every UI glyph is a third smaller on screen. The 8 px theme font is drawn 16 physical px tall instead of 24. Panels keep their pixel sizes, so they also cover a smaller share of the screen:
- the dialogue box is 600 of 960 px wide (was 600 of 640);
- the HUD ability panel is 148 px in the corner.

In the screenshots the body text of the dialogue box, document viewer and feedback line is readable but small. No UI scale was added, as the task says; that stays a separate decision.

Also, at window sizes below 1920 x 1080, integer scaling gives x1, for example a 1280 x 720 or 1366 x 768 window. The game then shows 960 x 540 with black borders, where 640 x 360 used to scale x2.

## Findings for the Lead / Sol (not changed here)

1. **The Beat 10 outro waits for [Enter] after "You are late."** This is existing logic, independent of the resolution.
   - `Ch01Outro._on_dialogue_line_advanced()` sets `_dialogue_manually_advanced = true` on every `line_advanced`. That includes the timeline's own advance to `OP_B10_01` at shot 4.
   - From then on, `_update_timeline_shots()` returns early, so "Again." and the hold never come on their own. The player has to press [Enter] twice, or skip.
   - Seen in the capture run: at 8.4 s the box still showed "You are late."
   - A fix would ignore advances made by the outro itself. I left it alone because it changes the cinematic's behaviour.
2. **Margin colour.** Outside the room there is no art, so the margin shows the clear colour, which is Godot's default grey (0.3, 0.3, 0.3). That is the same grey that already surrounds every room today. A darker margin is one project setting, `rendering/environment/defaults/default_clear_color`. Sol's call; I did not change the look.
3. **The chapter-complete panel** grows to fill its 292 px block. With a short summary that leaves empty space in the panel (`shot_11`). This was the same at 640 x 360.
4. **Docs:** ART_BIBLE §8 and ADR-003 still describe a 640 x 360 UI canvas. ADR-023 addendum 3 already supersedes the canvas, so I left the ADR log to the Lead.

## Validate

Raw key lines, pasted after the run on the pushed SHA, are in the Lead message. `tools/content` is unchanged, so the Python builder tests are not affected; they were run anyway.
