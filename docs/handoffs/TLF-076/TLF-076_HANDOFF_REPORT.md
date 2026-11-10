# TLF-076 Handoff Report: Pilot Side-View Scene (Beat 06 Mira Departure Memory)

**Task:** TLF-076 — Pilot: Beat 06 Mira departure memory in side view (ADR-025, `design/ch01/side_view/mira_memory.md`)  
**Owner:** Flash (build and wiring)  
**Layout:** Lead  
**Technical Review:** Opus  
**Visual Review:** Sol  
**Branch:** `adityadaffa522/tlf-076-mira-memory-side`  
**Status:** READY FOR REVIEW  

---

## 1. Executive Summary

This handoff delivers the side-view pilot memory room `scenes/chapters/ch01/rooms/side_mira_memory.tscn` per ADR-025 V6 and `design/ch01/side_view/mira_memory.md`. 

The player accesses this historical flashback during Beat 06 in Chapter 1:
1. The primary path in `waiting_lounge.tscn` is 100% preserved: the first Trace interaction on `trace_bench` displays Elias's monologue (`EL_B06_01`) and records the journal entry `JRN_CH1_TWO_SILHOUETTES`.
2. A subsequent Trace on the bench transitions the camera and gameplay mode to the side-view memory scene (`ch01.side_mira_memory`).
3. Inside the memory scene, Elias can move horizontally along the platform floor line ($y = 394$), examine the station bench, observe the frozen silhouette of Mira, Rewind a fallen coffee cup / voice recorder back onto the bench, and Trace Mira to obtain fragment `ch01.fragment.mira_departure`.
4. Walking past the platform edge to the exit marker ($x = 1380$) seamlessly returns the player to `waiting_lounge` at `safe_anchor_center` in isometric view mode.

---

## 2. Key Deliverables & Implementation Details

### 2.1 Side-View Scene Geometry (`scenes/chapters/ch01/rooms/side_mira_memory.tscn`)
- **Canvas & Dimensions:** 960 × 540 canvas viewport, full room width 1440 px, floor contact line at $y = 394$.
- **Camera Configuration:** Attached `RoomCamera` configured with `limit_left = 0`, `limit_right = 1440`, `limit_top = 0`, `limit_bottom = 540`.
- **View Mode Metadata:** Declared with `metadata/view_mode = "side"` and `metadata/side_view` resource (`scripts/rooms/side_view.gd`) setting `floor_y = 394.0`, `walk_min_x = 40.0`, `walk_max_x = 1400.0`.
- **Letterbox Bars:** Top and bottom cinematic black bars (~90 px each, top: $y = 0..90$, bottom: $y = 450..540$) at `z_index = 15` per ADR-025.
- **Layer & Parallax Architecture:**
  - FarWall: 3 repeating slices of `ch01_env_side_bg_far_wall_arches_idle.png` ($480 \times 304$ px each at $x = 0, 480, 960$, $y = 90$, `z_index = 1`).
  - NearWall: 3 repeating slices of `ch01_env_side_bg_near_wall_pillars_idle.png` ($480 \times 304$ px each at $x = 0, 480, 960$, $y = 90$, `z_index = 2`).
  - FloorStrip: 3 repeating slices of `ch01_env_side_platform_floor_strip_idle.png` ($480 \times 146$ px each at $x = 0, 480, 960$, $y = 394$, `z_index = 3`).

### 2.2 Object & Actor Placement (Section 3 Table)
All 8 objects and markers placed precisely per `design/ch01/side_view/mira_memory.md`:
| ID / Node | Type | Position | Facing / Pivot / Notes |
|:---|:---|:---|:---|
| `safe_anchor_start` | `Marker2D` | $(80, 394)$ | Spawn point when entering side view. |
| `pillar_1` | `Sprite2D` | $(360, 394)$ | Midground pillar ($z\_index = 4$, pivot foot). |
| `station_bench` | `Interactable` | $(540, 394)$ | Bench ($z\_index = 5$); look target `doc_side_station_bench`. |
| `voice_recorder_cup`| `Interactable` | $(600, 394)$ | On floor line; Rewind restores to bench top at $(540, 384)$. |
| `mira_memory_silhouette` | `Interactable` | $(720, 394)$ | Silhouette placeholder ($z\_index = 6$); Trace grants fragment `mira_departure`. |
| `pillar_2` | `Sprite2D` | $(980, 394)$ | Midground pillar ($z\_index = 4$, pivot foot). |
| `luggage_trolley` | `Sprite2D` | $(1160, 394)$ | Static background prop ($z\_index = 5$). |
| `clock_2359` | `Interactable` | $(1280, 280)$ | Wall clock showing 23:59; plays dialogue line `EL_CLOCK_2359`. |
| `exit_marker` | `TriggerZone` | $(1380, 394)$ | Walking past $x = 1380$ triggers deferred return to `waiting_lounge`. |

### 2.3 Entry & Exit Mechanics
- **Waiting Lounge Entry (`scripts/chapters/ch01/objects/trace_bench.gd`):**
  - First Trace: Elias monologues `EL_B06_01` and unlocks journal entry `JRN_CH1_TWO_SILHOUETTES`. Main playthrough flow remains 100% unaltered.
  - Second Trace: After `JRN_CH1_TWO_SILHOUETTES` is recorded in narrative state, interacting with the bench sets `mira_memory.return_target = safe_anchor_center` and calls `room_router.enter_room(&"ch01.side_mira_memory", &"safe_anchor_start")`.
- **Exit Marker (`scripts/chapters/ch01/objects/side_memory_exit_marker.gd`):**
  - Uses `sess.room_router.enter_room.call_deferred(&"ch01.waiting_lounge", target_anchor)` to prevent Godot 4 2D physics flush errors (`Removing a CollisionObject node during a physics callback is not allowed`).
  - Target anchor in waiting lounge is `safe_anchor_center` at $(336, 152)$, preserving exact baseline collision zones and matching `test_ch01_art_integration.gd` requirements.

### 2.4 Ability Gating & Safety
- **Trace:** Active on bench (entry) and Mira silhouette (fragment unlock). Second trace on Mira safely displays standard refusal/consumed feedback.
- **Rewind:** Active on `voice_recorder_cup`, smoothly interpolating from floor $(600, 394)$ back to bench top $(540, 384)$.
- **Freeze & Echo:** Refused safely inside the memory room with standard refusal HUD toast.
- **Targeting & Clamping:** Player movement restricted cleanly to $x \in [40, 1400]$ at fixed $y = 394$.

### 2.5 Text Keys & Content
- Zero new text keys introduced (adheres strictly to prompt and ADR-025 constraints):
  - `EL_B06_01`: "Two cups. Still warm. She was here minutes ago..."
  - `EL_CLOCK_2359`: "Stopped at 23:59. Just like the others."
  - `JRN_CH1_TWO_SILHOUETTES`: Journal entry for the bench encounter.
  - `FRAG_MIRA_DEPARTURE_TITLE` / `FRAG_MIRA_DEPARTURE_BODY`: Memory fragment text.

---

## 3. Automated Test Suite (`tests/chapters/ch01/test_ch01_mira_memory_side.gd`)

Six comprehensive automated real-input and unit tests were created and verified:
1. `test_real_input_full_memory_flow`: Full end-to-end integration test from `waiting_lounge` -> first trace -> journal entry -> second trace -> side memory scene -> look bench -> rewind cup -> trace Mira -> examine clock -> walk to exit -> returns to lounge at `safe_anchor_center`.
2. `test_walk_bounds_and_clamping`: Confirms horizontal movement clamping at $x = 40$ and $x = 1400$, and vertical clamping at $y = 394$.
3. `test_each_object_reachable_from_both_sides`: Verifies that all interactables (`station_bench`, `voice_recorder_cup`, `mira_memory_silhouette`, `clock_2359`) are reachable and targetable from both left and right approaches.
4. `test_freeze_and_echo_safety`: Verifies that Freeze and Echo abilities are cleanly refused without exceptions or state corruption.
5. `test_save_and_restore_inside_memory_scene`: Verifies save file persistence, restoration of side-view mode, player position, and temporal state inside `side_mira_memory`.
6. `test_mode_switch_leaves_no_leaks`: Confirms zero orphaned nodes or memory leaks across repeated mode transitions between isometric and side-view.

---

## 4. Visual Review Artifacts (Forward+ 960×540 Screenshots)

Five windowed screenshots were captured using `tools/capture_mira_memory_side.gd` (renamed scratch configuration, zero player save interference):
- `docs/handoffs/TLF-076/doc_mira_side_start.png`: Elias spawning at $x = 80$, showing FarWall arches, NearWall pillars, and bottom letterbox bar.
- `docs/handoffs/TLF-076/doc_mira_side_bench.png`: Elias standing at station bench ($x = 540$) and looking at the bench.
- `docs/handoffs/TLF-076/doc_mira_side_mira.png`: Elias standing before Mira's frozen departure silhouette ($x = 720$).
- `docs/handoffs/TLF-076/doc_mira_side_clock.png`: Elias standing beneath the 23:59 platform clock ($x = 1280$).
- `docs/handoffs/TLF-076/doc_mira_side_exit.png`: Elias reaching the exit marker at the right end of the platform ($x = 1380$).

---

## 5. Verification & Validation Results

- Standalone test suite: `tests/chapters/ch01/test_ch01_mira_memory_side.gd`: **6 passed, 0 failed**.
- Full `tools/validate.ps1` in fresh scratch copy:
  - Step 1: Headless import check: **Zero errors**.
  - Step 2: Script check (180 scripts): **0 failed, leak check clean**.
  - Step 3: Full automated test suite (62 test files): **500 passed, 0 failed, leak check clean**.
  - Chapter 1 real playthrough (`test_ch01_real_playthrough.gd`): **All 8 puzzles solved, 3 unlocks, complete in 3351 physics frames**.
- Zero modification to existing real player saves (`user://saves/slot_0.json`).
