# TLF-069 WIP Status — Pilot Room Arrival Platform v2

**Date:** 2026-11-07  
**Branch:** `adityadaffa522/wip-tlf-069`  
**Task:** `docs/tasks/TLF-069.md` (Pilot room: Arrival Platform v2)

---

## 1. What Is Built

### 1.1 Geometry & RoomShape (ADR-023)
- Rebuilt `scenes/chapters/ch01/rooms/arrival_platform.tscn` to the approved L-shaped outline:
  `[[0,0],[30,0],[30,8],[12,8],[12,18],[0,18]]`.
- Total 360 floor cells (extent 768 × 368 px). Built via `tools/content/build_room_from_shape.py` with `--outset 0.25 --edge-strip 0,S,E`.
- `hidden_floor_cells()` is verified empty (zero hidden floor cells).
- `metadata/room_shape` is attached to the room root node to drive `RoomCamera` following and bounding.
- Tall walls: 15 WallN modules, 9 WallW modules.
- TLF-068 kit pieces:
  - 6 corner sprites: `Corner_NW_0_0`, `Corner_N_Turn_30_0`, `Corner_Low_30_8`, `Corner_Low_12_8`, `Corner_Low_12_18`, `Corner_W_Turn_0_18`.
  - 6 LowS arm modules, 5 LowE arm modules, 9 LowS pit modules.
  - LowE strip modules: `LowE_strip_0` at `(784, 312)` (tile 30,1), `LowE_strip_1` at `(752, 328)` (tile 30,3), `LowE_strip_2` at `(688, 360)` (tile 30,7). Tile `(30,5)` at `(720, 344)` is omitted to align with the doorway archway opening per Lead Decision 3.
  - Boundary edge strip: painted with source 0 (plain terrazzo) per Lead Decision 4; old amber tactile cells at x=13 / y=9 cleared.

### 1.2 Object Placements & Lead Decisions Applied
- `safe_anchor_spawn`: `Vector2(160, 224)` (tile 5, 15).
- `checkpoint`: `Vector2(160, 224)` (tile 5, 15) restored to spawn tile per Lead Decision 7 so new games autosave on boot.
- `pocket_watch_pickup`: `Vector2(240, 232)` (tile 8, 13).
- `operator_sighting` (TLF-058): `Vector2(304, 216)` (tile 9, 10), trigger offset `Vector2(-12, 8)` preserved.
- `n02_student`: `Vector2(208, 168)` (tile 3, 10).
- `n03_old_man`: `Vector2(448, 160)` (tile 10, 2); `PlatformBench` at `Vector2(448, 168)`.
- `n01_conductor`: `Vector2(496, 200)` (tile 14, 3).
- `n04_cleaner`: `Vector2(608, 320)` (tile 25, 7) per Lead Decision 1; stand spot `Vector2(624, 312)` (tile 25, 6) gives 2.20 tiles clearance from walking line.
- `doc_last_service`: `Vector2(400, 120)` (tile 6, 1).
- Clocks: `Clock_2` at `Vector2(400, 66)` (tile 5, 0), `Clock_8` at `Vector2(592, 162)` (tile 17, 0).
- `DepartureBoard`: mounted flush on W wall module 5 at `Vector2(144, 152)` (tile 0, 11) per Lead Decision 5.
- `ClosedTrackNotice`: mounted flush on N wall module 6 at `Vector2(528, 168)` (tile 13, 0) per Lead Decision 6.
- `selector_line`: `Vector2(640, 240)` (tile 21, 1).
- `selector_platform`: `Vector2(672, 256)` (tile 23, 1).
- `selector_car`: `Vector2(704, 272)` (tile 25, 1).
- `release_lever`: `Vector2(752, 312)` (tile 29, 2); stand spot `Vector2(736, 304)` (tile 28, 2) on West side per Lead Decision 2.
- `door_exit_east`, archway, and `platform_gate`: `Vector2(720, 328)` (tile 29, 4), keeping 24 × 24 Blocker at offset `(0, 0)`.
- `StalledTransitCar`: `Vector2(480, 336)` (tile 22, 12).

### 1.3 Canonical Stand Spots Table (for Opus `run_probe.sh`)
```
release_lever:       tile (28, 2) -> Vector2(736, 304)  [West side, SO-01 17.9 px, clear of blocker]
n04_cleaner:         tile (25, 6) -> Vector2(624, 312)  [North side, SO-01 17.9 px, 2.2 tiles from line]
n01_conductor:       tile (14, 4) -> Vector2(480, 208)  [Approach side, SO-01 17.9 px]
n02_student:         tile (4, 10) -> Vector2(224, 160)  [Approach side, SO-01 17.9 px]
n03_old_man:         tile (10, 3) -> Vector2(432, 168)  [Approach side, SO-01 17.9 px]
doc_last_service:    tile (5, 1)  -> Vector2(384, 128)  [Approach side, SO-01 17.9 px]
selector_line:       tile (21, 2) -> Vector2(624, 248)  [South side, SO-01 17.9 px]
selector_platform:   tile (23, 2) -> Vector2(656, 264)  [South side, SO-01 17.9 px]
selector_car:        tile (25, 2) -> Vector2(688, 280)  [South side, SO-01 17.9 px]
pocket_watch_pickup: tile (7, 13) -> Vector2(224, 240)  [Approach side, SO-01 17.9 px]
```

---

## 2. Test Status

| Test Suite | Result | Notes |
|---|---|---|
| `test_ch01_arrival_platform_v2.gd` | **4 passed, 0 failed** | Door sweep, stand spot reach (<= 2.6 px), camera bounds clamp, save/load at checkpoint. |
| `test_ch01_art_integration.gd` | **6 passed, 0 failed** | Kit complete + collision freeze baseline verified. Spurious 11th key removed; exact 10 rooms match. |
| `test_ch01_playthrough.gd` | **19 passed, 0 failed** | Graph def & safe anchor checks match v2 coordinates; full chapter scripted playthrough passes. |
| `test_ch01_real_playthrough.gd` | **1 passed, 0 failed** | Full real-input playthrough passes from new game through chapter complete (Beat 10 outro). |
| `test_ch01_step1_negatives.gd` | **12 passed, 0 failed** | SO-01 closed gate holds 300 ticks; SO-01 lockout holds until end. |
| `test_operator_sighting.gd` | **7 passed, 0 failed** | Mystery invariants, vanish on approach, save/load all pass. |
| `test_spawn_targeting.gd` | **1 passed, 0 failed** | Passes with spawn at (160, 224) and watch at (240, 232). |
| `test_room_shape.gd` | **7 passed, 0 failed** | v2 shape matches scene polygon and dimensions. |
| `test_ch01_sort_order.gd` | **3 passed, 0 failed** | Updated `render_manifest.json` rows pass all 4-side sort order checks. |

---

## 3. What Remains from `docs/tasks/TLF-069.md`

1. **Re-capture 4 Windowed Screenshots:**
   - Update `doc_arrival_v2_spawn.png`, `doc_arrival_v2_watch.png`, `doc_arrival_v2_pit_edge.png`, `doc_arrival_v2_gate.png` in `docs/handoffs/TLF-069/` using Forward+ windowed renderer reflecting the latest Decision 1/5/6/7 coordinates.
2. **Clean Full Validation (`tools/validate.ps1`):**
   - Run from clean scratch directory `C:\temp\tlf_val_069` with `config/name="The Last Frame Val069"` (no BOM).
   - Verify 0 errors, 0 failed, 0 leaks, no SCRIPT ERROR. Record raw counts in final report.
3. **Final Handoff Report:**
   - Create `docs/handoffs/TLF-069/TLF-069_HANDOFF_REPORT.md` including the builder dry run diff, collision re-baseline explanation, stand spots table, and validation counts.
4. **Final Push:**
   - Commit to `adityadaffa522/tlf-069-arrival-platform-v2` and push to `origin`.

---

## 4. Exact Next Commands to Resume

```powershell
# 1. Update windowed screenshots reflecting latest positions
& "D:\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . -s "res://tools/capture_arrival_v2.gd"

# 2. Re-create clean scratch directory for validation
Remove-Item -Recurse -Force "C:\temp\tlf_val_069" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force "C:\temp\tlf_val_069"
robocopy . "C:\temp\tlf_val_069" /E /XD .git .godot
$godotConfig = [System.IO.File]::ReadAllText("C:\temp\tlf_val_069\project.godot")
$godotConfig = $godotConfig.Replace('config/name="The Last Frame"', 'config/name="The Last Frame Val069"')
[System.IO.File]::WriteAllText("C:\temp\tlf_val_069\project.godot", $godotConfig, (New-Object System.Text.UTF8Encoding($false)))

# 3. Run validation on scratch copy
Set-Location "C:\temp\tlf_val_069"
& powershell -ExecutionPolicy Bypass -File .\tools\validate.ps1 -Godot "D:\Godot\Godot_v4.7.2-stable_win64_console.exe"

# 4. Generate final handoff report and push
git add scenes/chapters/ch01/rooms/arrival_platform.tscn
git add tests/chapters/ch01/test_ch01_arrival_platform_v2.gd
git add tests/chapters/ch01/test_ch01_art_integration.gd
git add tests/chapters/ch01/test_ch01_playthrough.gd
git add tests/chapters/ch01/test_ch01_real_playthrough.gd
git add tests/chapters/ch01/test_ch01_step1_negatives.gd
git add tests/chapters/ch01/test_operator_sighting.gd
git add tests/player/test_spawn_targeting.gd
git add tests/rooms/test_room_shape.gd
git add docs/reviews/TLF-066/render_manifest.json
git add docs/handoffs/TLF-069/
git commit -m "feat(TLF-069): pilot room Arrival Platform v2 rebuild"
git push origin adityadaffa522/tlf-069-arrival-platform-v2
```
