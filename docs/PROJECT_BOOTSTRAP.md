# Project Bootstrap — From Empty Folder to First Playable Build

## Phase 0 — Safety and baseline

1. Create repository and initial commit.
2. Add this pack's docs and prompts.
3. Create `project.godot` using the installed Godot 4.x version; do not let agents invent version-specific settings.
4. Add a `.gitignore` for Godot generated files, editor caches, local secrets and temporary exports. Keep required `.import` metadata behavior compatible with the chosen Godot version.
5. Confirm project opens and exports a blank build before feature work.

## Phase 1 — Vertical-slice foundation

- Main menu / continue / settings shell.
- Player movement and camera/isometric presentation.
- Interaction system with stable IDs.
- One station room with clear navigation and collision.
- Save/load skeleton with schema version.
- Audio bus and subtitle foundation.

## Phase 2 — Temporal prototype

Implement a small set of explicit temporal object types. Record deterministic events (for example: `lever_activated`, `door_opened`, `crate_moved`) with timestamps and stable object IDs. Do not record raw input or every rendered frame. Replay events against registered objects and validate ordering/idempotence.

## Phase 3 — First puzzle

One puzzle must demonstrate observation → hypothesis → experimentation → execution → confirmation. Provide environmental clues, feedback, a reset path and optional hints. Ensure the player can recover from an incorrect experiment.

## Phase 4 — Spatial prototype

Use a logical spatial graph as source of truth. A rotation/fold operation must update room transforms, doorway links, collision, navigation, player placement and interaction anchors as one transaction. Roll back cleanly on invalid transforms.

## Phase 5 — Vertical slice polish

Integrate art/audio/UI, add cinematic reveal, save/load, accessibility settings, performance pass and playtest. Target 30–45 minutes for the Chapter 1 vertical slice. Do not start all six chapters until this slice passes review.
