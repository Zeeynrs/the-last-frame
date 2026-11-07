# Chapter 1 large rooms Implementation Plan

> **For agentic workers:** Executed by the Orca agents named on each task (Opus, Sol, Argon, Flash), one task per branch, reviewed and validated by the Lead before each merge. Steps use checkbox syntax.

**Goal:** Chapter 1 rooms become larger and non-rectangular, with a follow camera, and object facing and sorting stop breaking.

**Architecture:** A per-room `RoomShape` resource (floor outline in tile coordinates, ADR-003 tile math) generates floor tiles, perimeter collision, N/W wall segments and camera bounds. A `RoomCamera` follows the player at whole-pixel positions inside the shape bounds. Rooms migrate one at a time behind the existing `RoomRouter`.

**Tech Stack:** Godot 4.7.2, GDScript, existing headless test runner (`tools/validate.ps1`), Python art generators and gates (`tools/art/**`), Pixelorama `.pxo` sources.

**Spec:** `docs/superpowers/specs/2026-11-07-ch1-large-rooms-design.md` (rules R1–R10 are referenced below).

## Global Constraints

* Internal canvas 640×360, integer scaling; tile 32×16 (2:1 dimetric); character 32×48; palette TLF-CH01-32; top-left light (ADR-003, ART_BIBLE).
* Camera position is always a whole pixel (R1). Camera never shows outside the room bounds.
* No wall taller than about 20 px on a south or east face of walkable floor (R2).
* Room, door, checkpoint and safe-anchor ids are unchanged (R4).
* Apertures between walkable regions at least 1.5 tiles (24×12 px opening, TLF-055 §G).
* No new puzzles, no new narrative text without the Lead (R10). Existing text keys only.
* Every merge: full `tools/validate.ps1` green on the exact tree, 0 failed, no SCRIPT ERROR, art gates green when art changes; the Lead merges after the owner's OK.

## Review Focus

* Elias standing exactly on a camera clamp edge or at a door: no jitter, no off-bounds frame, no black strip.
* Room transition with different room sizes: the camera is already at the new room's correct position on the first frame (no pan from the old room).
* Save/load inside a large room and at a checkpoint: Elias and the camera restore together, Echo and Rewind positions stay inside the new collision shape.
* Concave corner: Elias walking along an inner corner is never hidden by a wall and never clips through a low partition.
* A shape whose outline is clockwise vs counter-clockwise, or has a collinear point: generation gives the same floor and collision.

---

### Task 1 (TLF-065, Opus): RoomShape and RoomCamera

**Files:**
- Create: `scripts/rooms/room_shape.gd`, `scripts/rooms/room_camera.gd`, `tests/rooms/test_room_shape.gd`, `tests/rooms/test_room_camera.gd`, `tools/content/build_room_from_shape.py`
- Modify: `scripts/rooms/room_router.gd` (hand the camera the new room's bounds and the player), `tests/rooms/test_room_router.gd`

**Interfaces:**
- Produces: `class_name RoomShape extends Resource` with `@export var outline: PackedVector2Array` (tile coordinates, closed implicitly), `func contains_tile(t: Vector2i) -> bool`, `func floor_cells() -> Array[Vector2i]`, `func tile_to_px(t: Vector2) -> Vector2` (px_x = 320 + (x - y)·16, px_y = 64 + (x + y)·8), `func perimeter_polygon_px() -> PackedVector2Array`, `func wall_segments() -> Array[Dictionary]` (each `{face: &"N"|&"W"|&"low_S"|&"low_E", from: Vector2i, to: Vector2i, kind: &"straight"|&"inner_corner"|&"outer_corner"}`), `func bounds_px() -> Rect2`.
- Produces: `class_name RoomCamera extends Camera2D` with `var target: Node2D`, `func set_bounds(r: Rect2) -> void`, `func snap_now() -> void` (position exactly on the target on the same frame, used on room entry); the position is always whole-pixel.

- [ ] **Step 1: Write failing tests.** `test_room_shape.gd`: `test_rectangle_matches_adr003_math` (a 14×10 outline gives `floor_cells().size() == 140` and `bounds_px()` width 384 + margins per ADR-003), `test_l_shape_floor_and_collision_agree` (every `floor_cells()` tile centre is inside `perimeter_polygon_px()`; a point in the cut-out is outside), `test_winding_and_collinear_points_are_equivalent`, `test_inner_corner_emits_low_south_east_faces_only` (R2: no `N`/`W` wall on a south/east face). `test_room_camera.gd`: `test_position_is_whole_pixel_every_frame`, `test_clamps_to_bounds`, `test_room_smaller_than_screen_is_fixed`, `test_snap_now_on_room_entry_same_frame`.
- [ ] **Step 2: Run them (`TLF_ONLY` filter per the fast test loop memory) and confirm FAIL** (classes missing).
- [ ] **Step 3: Implement `RoomShape` and `RoomCamera`** per the Interfaces; approach: polygon fill for `floor_cells`, edge walk with turn direction for `wall_segments`, `Camera2D` limits plus script rounding for the camera.
- [ ] **Step 4: `tools/content/build_room_from_shape.py`:** takes a JSON outline and writes the floor `tile_map_data`, `CollisionPolygon2D` points and the wall sprite node list into a room scene. A dry-run flag prints a diff and the tool never edits a room scene unless `--write` is passed.
- [ ] **Step 5: Hook `RoomRouter`:** on `room_entered` call `set_bounds` and `snap_now`; add `test_transition_camera_correct_on_first_frame` and `test_save_load_restores_camera_with_player` to `tests/rooms/test_room_router.gd` (Review Focus 2 and 3).
- [ ] **Step 6: Full validate green; commit; handoff `docs/handoffs/TLF-065/` with raw validate output.**

### Task 2 (TLF-066, Sol): Facing and overlap audit (read-only)

**Files:**
- Create: `docs/reviews/TLF-066_facing_overlap_audit.md`, `docs/reviews/TLF-066/audit.csv`, screenshots under `docs/reviews/TLF-066/`

**Interfaces:**
- Produces: `audit.csv`, one row per object in all ten Chapter 1 rooms, with columns `room,object_id,sprite,expected_facing,actual_facing,overlaps_elias_from,fix_owner,severity`. `expected_facing` comes from the room position and the ART_BIBLE direction rule. `overlaps_elias_from` lists which of N/S/E/W approaches draw wrongly. `fix_owner` is `art` (Argon), `data` (Opus) or `placement` (Flash).

- [ ] **Step 1:** Render each room windowed at 640×360 with Elias at the four sides of every object (tooling already used for the TLF-055 screenshots).
- [ ] **Step 2:** Fill the CSV and the markdown table; mark each defect with its `fix_owner`.
- [ ] **Step 3:** Push on the review branch and report the SHA. Do not edit game files.

### Task 3 (TLF-067, Opus; Argon for `art` rows): Sorting, pivot and facing fixes

**Files:**
- Modify: per the audit CSV (room scene pivots/z, presenters under `scripts/chapters/ch01/visuals/`); Argon edits art through the generators.
- Test: `tests/chapters/ch01/test_ch01_sort_order.gd`

**Interfaces:**
- Consumes: `docs/reviews/TLF-066/audit.csv`.
- Produces: `test_probe_actor_sorts_correctly_at_all_four_sides` run over every audited object (data-driven from the CSV).

- [ ] **Step 1:** Write the sort test from the audit CSV and confirm it FAILS on the rows marked `data`.
- [ ] **Step 2:** Fix pivot, z and placement rows; Argon fixes `art` rows (regeneration gates green, Sol reviews).
- [ ] **Step 3:** Re-baseline the collision fingerprint test only where shapes changed; full validate green; handoff with raw output.

### Task 4 (TLF-068, Argon, Sol reviews): Shape art kit

**Files:**
- Create: `tools/art/gen/tlf068_shape_kit.py`, the `.pxo` sources and PNGs for inner-corner and outer-corner N/W wall pieces, low partition (S/E) pieces at most 20 px tall, floor-edge tiles for concave cuts; entries in `design/art/ASSET_METADATA.md`.

**Interfaces:**
- Produces: asset filenames that `RoomShape.wall_segments()` kinds map to (`straight`, `inner_corner`, `outer_corner`, `low_S`, `low_E`), listed in a mapping table in `design/art/ASSET_METADATA.md`.

- [ ] **Step 1:** Generate; run `check_assets.py` and `verify_regen.py` (green); Pixelorama re-export identical.
- [ ] **Step 2:** Sol visual review (2:1 projection, palette, lighting) with APPROVE VISUAL on the exact SHA.

### Task 5 (TLF-069, Lead layout, Flash wiring, Opus review): Pilot room, Arrival Platform

**Files:**
- Create: `design/ch01/rooms_v2/arrival_platform.md` (the Lead's L-shape outline, objects, door and spawn positions)
- Modify: `scenes/chapters/ch01/rooms/arrival_platform.tscn`, tests coupled to its coordinates (`tests/chapters/ch01/*` for room 1)

**Interfaces:**
- Consumes: Tasks 1, 3 and 4.
- Produces: `design/ch01/rooms_v2/PATTERN.md`, the pattern the nine following room tasks copy (shape resource path, door pairing table, test checklist).

- [ ] **Step 1:** Lead writes the layout (shape, 1.6–2× size, low partitions at concave corners, objects including the TLF-063 props with Lead-written text).
- [ ] **Step 2:** Flash builds the scene from the shape with the Task 1 tool and wires the objects; the real-input segment and negatives for room 1 are green with updated coordinates; windowed screenshots.
- [ ] **Step 3:** Opus technical review (reach, apertures, door sweep, camera clamp edges); the Lead validates the exact tree; **the owner plays the room and approves or adjusts size and shape before Task 6.**

### Task 6 (after the pilot): rooms 2–10, one TLF task each

Per room: Lead layout, Flash wiring, Opus review, same landing criteria as Task 5. The Lead writes the nine task files after the owner's pilot feedback.

---

Self-review: spec rules R1 (Task 1), R2 (Tasks 1, 4), R3 (Task 1), R4 (Tasks 1, 5), R5 (Task 5, tuned), R6 (Task 6), R7 (Tasks 2, 3), R8 (Tasks 5, 6), R9 (stated in ADR-023), R10 (Tasks 5, 6). Interface names are consistent across tasks (`RoomShape`, `RoomCamera`, `wall_segments` kinds).
