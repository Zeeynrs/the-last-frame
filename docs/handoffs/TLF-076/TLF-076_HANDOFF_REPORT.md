# TLF-076 Handoff Report: Pilot Side-View Scene (Beat 06 Mira Departure Memory) — Round 3

**Task:** TLF-076 — Pilot: Beat 06 Mira departure memory in side view (ADR-025, `design/ch01/side_view/mira_memory.md`)  
**Owner:** Flash (build and wiring)  
**Layout:** Lead  
**Technical Review:** Opus  
**Visual Review:** Sol  
**Branch:** `adityadaffa522/tlf-076-mira-memory-side`  
**Status:** READY FOR REVIEW (Round 3 — Letterbox Palette Restoration)  

---

## 1. Executive Summary

This handoff delivers the side-view pilot memory room `scenes/chapters/ch01/rooms/side_mira_memory.tscn` per ADR-025 V6 and `design/ch01/side_view/mira_memory.md`, addressing all review findings from Opus (`docs/reviews/TLF-076/TLF-076_a94aee3_OPUS_REVIEW.md`) and Sol (`docs/reviews/TLF-076_a94aee3_visual_review.md`).

The player accesses this historical flashback during Beat 06 in Chapter 1:
1. **Finding 3 / Main Flow Unchanged:** In `waiting_lounge.tscn`, Trace before Beat 06 dialogue stays completely silent (matching `origin/main`). Interacting (Use) with `trace_bench` displays Elias's monologue (`EL_B06_01`), sets flag `heard.ch01_b06_bench`, and records journal entry `JRN_CH1_TWO_SILHOUETTES`.
2. A subsequent Trace on the bench closes any active dialogue, sets return flag `ch01.flag.mira_memory_return`, and transitions to the side-view memory scene (`ch01.side_mira_memory`) via `call_deferred`.
3. Inside the memory scene, Elias moves horizontally along the platform floor line ($y = 394$), examines the station bench at $x = 520$, observes the frozen silhouette of Mira at $x = 780$, Rewinds a fallen voice recorder cup back onto the bench at $(540, 384)$, and Traces Mira to obtain fragment `ch01.fragment.mira_departure`.
4. Walking past the platform edge to the exit marker ($x = 1380$) seamlessly returns the player to `waiting_lounge` at `safe_anchor_center` in isometric view mode.

---

## 2. Review Resolutions (Round 2)

### 2.1 Sol P1 — Ability Marker Occlusion & Mira Recapture
- **Marker Anchor Position:** Added `TargetAnchor` Marker2D at `Vector2(0, -56)` under `mira_silhouette` and added `target_marker_offset = Vector2(0, -56)` to `mira_memory_silhouette.gd`.
- **HUD Support:** `scripts/ui/hud.gd` updated so `_update_target_highlight_position()` checks `target.get_node("TargetAnchor")` or `target.target_marker_offset` before falling back to generic `(0, -28)`.
- **Clearance:** At screen coordinates, the 10×10 cyan `AbilityMarker` occupies $x \in [499, 508], y \in [333, 342]$, leaving **11 px of clear space** above Mira's head (screen $y = 353$), exceeding the required $\ge 6\text{ px}$ clearance.
- **Recaptured Screenshot:** Recaptured `doc_mira_side_mira.png` with Elias standing separated at $x = 756$ facing east toward Mira at $x = 780$, with Trace selected and cyan target marker clearly hovering above Mira's head.

### 2.2 Opus P1-1 — Autosave Safety & Checkpoint Removal
- **No Autosave in Memory:** Completely removed `CheckpointZone` from `side_mira_memory.tscn`. The memory room does not write autosaves.
- **Autosave Verification:** Automated tests assert that entering, roaming, and exiting the memory room leaves the waiting lounge autosave intact (slot 0 points to `ch01.waiting_lounge`, never `ch01.side_mira_memory`).

### 2.3 Opus P1-2 — Real Input Test Coverage
- `tests/chapters/ch01/test_ch01_mira_memory_side.gd` rewritten to drive actions through real input (`tap`, `press`, `release`, physics stepping):
  - Entry via second Trace on bench after monologue.
  - Trace on Mira granting fragment.
  - Rewind on cup restoring it to bench.
  - Exit marker walk back to lounge.
  - Re-entry flow after visiting once.
  - Continue from disk inside memory room (restoring to waiting lounge save).
  - Walk bounds ($x \in [16, 1424]$) and camera horizontal center-follow clamp ($x \in [480, 960]$).

### 2.4 Lead Finding 3 & Revert of Engine-Level Hooks
- **Reverted Files:** Reverted `scripts/ui/dialogue_trigger.gd` and `scripts/player/pocket_watch.gd` back to `origin/main` byte-for-byte.
- **Clean Deferred Entry:** Transition to memory room uses `call_deferred` in `trace_bench.gd`. Active monologue `EL_B06_01` is closed upon entry.

### 2.5 Opus P3 Polish
- **Cup Rewind:** Neutral response without ability name; upon rewind, cup collision is disabled and `supports_ability` returns false so bench at $x = 520$ retains interact focus.
- **Mira Second Trace:** Returns empty StringName `&""`, providing neutral silent behavior without failure toasts.
- **Dead Code Cleanup:** Removed dead `_on_watch`/`_can_watch` methods.
- **Namespace:** Stored return flag as `ch01.flag.mira_memory_return` (String).

### 2.6 Sol Round 3 — Letterbox Palette Restoration & Pixel Measurement
- **Palette Restoration:** In `scenes/chapters/ch01/rooms/side_mira_memory.tscn`, restored letterbox bars and hairlines to strict 32-color project palette per `design/art/ASSET_METADATA.md` §13.1 / `ART_BIBLE`:
  - `LetterboxTop` and `LetterboxBottom`: `Color(0.0392157, 0.0509804, 0.0784314, 1)` (`#0A0D14`, palette 00).
  - `LetterboxTopHairline` and `LetterboxBottomHairline`: `Color(0.180392, 0.2, 0.239216, 1)` (`#2E333D`, palette 12).
- **Pixel Measurements:** Verified across recaptured 960×540 Forward+ screenshots (`doc_mira_side_start.png`, `doc_mira_side_bench.png`, `doc_mira_side_mira.png`, `doc_mira_side_clock.png`):
  - Bar sample at `(900, 60)` = `RGB(10, 13, 20)` (`#0A0D14`).
  - Hairline sample at `(900, 89)` = `RGB(46, 51, 61)` (`#2E333D`).

---

## 3. Scene Geometry & Placements (Sol P2 Corrected)

### 3.1 Dimensions & Viewport
- **Canvas:** 960 × 540 viewport, full room width 1440 px, floor contact line at $y = 394$.
- **Camera Configuration:** Attached `RoomCamera` configured with `limit_left = 0`, `limit_right = 1440`, `limit_top = 0`, `limit_bottom = 540`, center-follow framing ($x \in [480, 960]$, $y = 270$).
- **View Mode Metadata:** Declared with `metadata/view_mode = "side"` and `SideView` resource setting `floor_y = 394.0`, `walk_min_x = 16.0`, `walk_max_x = 1424.0` (16 px margin).
- **Cinematic Letterbox:** 90 px top/bottom bars ($y = 0..90$, $y = 450..540$) at `z_index = 15` in `#0A0D14` with 1 px boundary hairlines in `#2E333D`.

### 3.2 Layers
- **FarWall:** `ch01_env_side_bg_far_wall_arches_idle.png` ($960 \times 360$ at $y = 90$, repeated at $x = 0, 960$, `z_index = 1`).
- **NearWall:** `ch01_env_side_bg_near_wall_pillars_idle.png` ($960 \times 360$ at $y = 90$, repeated at $x = 0, 960$, `z_index = 2`).
- **Pillars:** Standalone `PlatformPillar` at $x = 300, y = 394$ (`z_index = 4`).
- **FloorStrip:** `ch01_env_side_platform_floor_strip_idle.png` ($960 \times 72$ at $y = 378$, repeated at $x = 0, 960$, `z_index = 3`).

### 3.3 Object & Marker Table
| ID / Node | Type | Position | Facing / Pivot / Notes |
|:---|:---|:---|:---|
| `safe_anchor_start` | `Marker2D` | $(120, 394)$ | Spawn point when entering side view. |
| `PlatformPillar` | `Sprite2D` | $(300, 394)$ | Midground pillar ($z\_index = 4$). |
| `station_bench` | `Interactable` | $(520, 394)$ | Bench ($z\_index = 5$, pivot $(32, 28)$); look target `doc_side_station_bench`. |
| `voice_recorder_cup`| `Interactable` | $(600, 394)$ | Floor cup ($z\_index = 5$, pivot $(12, 14)$); Rewind restores to bench top at $(540, 384)$. |
| `mira_silhouette` | `Interactable` | $(780, 394)$ | Silhouette placeholder ($z\_index = 6$, pivot $(16, 44)$); Trace grants fragment `mira_departure`. TargetAnchor at $(0, -56)$. |
| `luggage_trolley` | `Sprite2D` | $(1000, 394)$ | Static background prop ($z\_index = 5$, pivot $(24, 36)$). |
| `clock_2359` | `Interactable` | $(1180, 156)$ | Suspended wall clock mount; interaction floor position $x = 1180, y = 394$. Plays `EL_CLOCK_2359`. |
| `exit_marker` | `TriggerZone` | $(1380, 394)$ | Walking past $x = 1380$ triggers deferred return to `waiting_lounge`. |

---

## 4. Automated Test Suite (`tests/chapters/ch01/test_ch01_mira_memory_side.gd`)

Six comprehensive automated real-input and regression tests:
1. `test_real_input_full_memory_flow`: Full real input sequence: first trace silent -> use monologue -> second trace entry -> look bench -> rewind cup -> trace Mira -> walk to exit -> returns to lounge at `(336, 152)`. Asserts autosave slot 0 still points to `ch01.waiting_lounge`.
2. `test_reentry_memory_flow`: Verifies visiting the memory room again after obtaining the fragment and exiting cleanly.
3. `test_save_and_continue_from_disk`: Loads save file created in lounge, verifies seamless resume and ViewMode.ISO restoration.
4. `test_walk_bounds_and_clamping`: Confirms horizontal movement clamping at $x = 16$ and $x = 1424$, vertical clamping at $y = 394$, and camera center-follow clamping between $480$ and $960$.
5. `test_freeze_and_echo_safety`: Verifies Freeze and Echo abilities are cleanly refused without exceptions.
6. `test_mode_switch_leaves_no_leaks`: Confirms zero orphaned nodes or memory leaks across repeated mode switches.

---

## 5. Visual Review Artifacts (Forward+ 960×540 Screenshots)

Captured using `tools/capture_mira_memory_side.gd` (Forward+, zero player save interference):
- `docs/handoffs/TLF-076/doc_mira_side_start.png`: Elias spawning at $(120, 394)$.
- `docs/handoffs/TLF-076/doc_mira_side_bench.png`: Elias standing at station bench $(520, 394)$.
- `docs/handoffs/TLF-076/doc_mira_side_mira.png`: Elias standing at $(756, 394)$ separated from Mira at $(780, 394)$ with cyan `AbilityMarker` hovering at $y = 333..342$ (11 px clearance above Mira's head).
- `docs/handoffs/TLF-076/doc_mira_side_clock.png`: Elias standing at $(1180, 394)$ beneath suspended 23:59 clock.
- `docs/handoffs/TLF-076/doc_mira_side_exit.png`: Elias at platform exit $(1380, 394)$.

---

## 6. Verification & Validation Results

- Standalone test suite: `tests/chapters/ch01/test_ch01_mira_memory_side.gd`: **6 passed, 0 failed (35s runtime)**.
- Scratch validate: Full `tools/validate.ps1` from a fresh scratch copy: **0 failed, 0 SCRIPT ERROR, 0 leaks**.
- Zero modification to existing real player saves (`user://saves/`).
