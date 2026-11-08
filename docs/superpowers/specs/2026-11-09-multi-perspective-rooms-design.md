# Multi-perspective rooms (design)

Date: 2026-11-09 · Author: Lead · Status: APPROVED by the owner (2026-11-09) · Decision record: ADR-025 (ADR-024 stays reserved for elevation levels and stairs).

## 1. Intent and why

The owner wants the game to stop being isometric only. Different stages, or a building, may use a different camera (reference images: an oblique top-down forest and a flat side-view crime-scene room) so that the game can offer more puzzle variety. Chosen approach (owner, 2026-11-09): **A, a view mode per room, added step by step.** Chapter 1 stays isometric. Each new mode arrives as one pilot scene first.

My proposal, in the story's own terms: the first non-isometric view is a **Trace memory scene shown in side view**. When Elias traces something the world already remembers (Beat 06, Mira's departure), the frozen moment can play as a flat side-view scene like the second reference. The change of view then has a reason inside the story.

## 2. Goals, non-goals, anti-goals

Goals
* A room declares its view mode (`iso`, `side`, `topdown`); everything shared keeps working in every mode: puzzles, the four abilities, dialogue, journal, save/load, Echo and Rewind, audio, HUD.
* One working side-view pilot scene in Chapter 1.
* A clean place to add `topdown` later without touching `iso` and `side`.

Non-goals (this phase)
* No change to any existing isometric room, its art or its tests.
* No `topdown` mode yet (only the hook for it).
* No new narrative text: the pilot uses existing text keys (Lead may write new ones before the build starts).
* No elevation, stairs or levels (ADR-024).

Anti-goals
* A mode that works only for the pilot and breaks Echo, Rewind, Freeze or save/load.
* Two incompatible Elias art styles in the same scene.
* Side view that is just the isometric room seen flat, with no puzzle reason.

## 3. Constraints (found in the project)

* `Player` implements 8-direction screen-relative isometric movement with the 2:1 diagonal ratio; facing is one of 8 tags (`s`, `se`, …); animations are `walk_<dir>` and `idle_<dir>` on `elias_sprite_frames.tres` (sheet `ch01_char_elias_base_sheet`, 32 × 48, 5 directions plus mirrors).
* `RoomRouter` loads room scenes, reads `metadata/room_shape` (ADR-023) and hands the camera its bounds; a room without a shape uses the fixed screen.
* `DepthSort` (TLF-067) orders actors and upright bodies by floor contact y; it is isometric/oblique by nature and not needed for a flat side view.
* The logical canvas becomes 960 × 540 (ADR-023 addendum 3, task TLF-072). A side-view scene is composed for 960 × 540 with letterbox bars, as in the second reference.
* Art pipeline: Pixelorama sources, palette TLF-CH01-32, generators and gates, Sol reviews, Argon draws.
* Merge discipline: validate the exact tree, owner "Ya" before every merge.

## 4. Approaches considered

A. A view mode per room, step by step (CHOSEN). Shared systems stay shared; each mode adds its movement mapping, sprite set, camera rule and art kit.
B. Replace the whole game's view with a new one. Rejected: discards the roughly 260 isometric Chapter 1 art files and makes the game uniform again, so no variety.
C. Stay isometric and vary puzzles through mechanics only. Rejected: does not give the camera variety the owner asked for.

## 5. Design (decisions and my calls)

V1 View mode is data: `metadata/view_mode` (`StringName`, default `&"iso"`) on the room root, next to `metadata/room_shape`. `RoomRouter` publishes `view_mode_changed(mode)` when a room is entered; `Player`, `RoomCamera`, `DepthSort` and the HUD read it.

V2 Movement per mode (Player): `iso` unchanged. `side`: only `move_left` and `move_right` move Elias, vertical input is ignored, speed the same as `walk_speed`, facing is `e` or `w`; he stays on the scene's floor line. `topdown` (later): 8 directions with equal diagonal speed.

V3 Sprites per mode: `side` needs profile `idle_e`, `walk_e` (4–6 frames), and `interact_e`, mirrored for `w`, drawn by Argon in the same palette and the same 32 × 48 cell so he reads at the same scale. A separate `SpriteFrames` resource per mode; `Player` swaps it when the mode changes.

V4 Side-view scene structure: 960 × 540 canvas with a floor line and letterbox bars (about 90 px top and bottom), 2–3 parallax-free background layers (no scrolling parallax in the pilot), props on the floor line, interactables as the existing `Interactable` classes with 1-D reach. No `RoomShape`; the camera is fixed unless the scene is wider than the screen, then it scrolls horizontally with whole-pixel steps (reuse `RoomCamera` with a horizontal-only mode).

V5 Abilities in side view: Trace and Rewind work as today on the scene's objects; Freeze and Echo work (the Echo records the 1-D track). Anything that cannot work in a mode is refused with an existing reason key, not hidden.

V6 Pilot scene (my proposal, the Lead owns the content): the **Beat 06 Mira departure memory** in side view, entered by tracing the Mira silhouette in the Waiting Lounge and left at its end back to the same spot. It reuses existing text keys and the existing memory fragment `ch01.fragment.mira_departure`. Interaction in the pilot: walk, look at two objects, one Trace on a frozen person, and one Rewind of a small object, enough to prove the abilities, no new puzzle yet. The side-view puzzle itself is designed after the pilot is approved.

V7 Save/load: the saved room id determines the mode; loading inside the memory scene returns to it; the exit target is stored so the return is exact.

V8 Tests: the pilot scene's real-input walk, ability use in side mode (each ability once), Echo and Rewind positions inside the floor line, save/load in the memory scene, mode switch both ways without leaks, the existing 479+ tests unchanged.

## 6. Phases and owners (proposed)

P0 `view_mode` plumbing and the `side` movement/camera rule (Opus, TLF-074), after TLF-072.
P1 Elias side-view sprites and a small side-view background kit, composed for 960 × 540 (Argon, TLF-075, Sol reviews); can start now.
P2 Pilot scene: layout by the Lead, build and wiring by Flash, technical review by Opus, visual review by Sol, owner plays (TLF-076).
P3 After the owner approves the pilot: design the first side-view puzzles; then decide on the `topdown` mode.
Order relative to running work: TLF-069 (isometric pilot room) and TLF-072 (960 × 540) come first for the code parts; P1 art is independent.

## 7. Left to the builder

The exact `SpriteFrames` structure and animation names beyond V3, how the camera's horizontal-only mode is implemented, the HUD tweaks for letterbox, file names, test structure.

## 8. Open items

* The pilot memory scene's content (V6) is my proposal; the owner can choose another memory.
* Whether the owner wants a small depth band in side view (walk slightly toward and away from the camera, like the first reference's feel) is not part of the pilot.
