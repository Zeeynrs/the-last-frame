# Project Status

**Updated:** 2026-10-31 · **Main:** see `git log -1 origin/main` · **Engine:** Godot 4.7.2 · **Validation:** `tools/validate.ps1` → import clean, 82/82 tests

This file states what the repository **actually** contains. Task-level detail lives in `ORCA_TASK_BOARD.md`; history lives in `PROGRESS.md`.

## A. Works (merged, tested)
| Area | Where | Evidence |
|---|---|---|
| Project config: 640×360 integer-scaled pixel display, Forward+, 60 Hz physics | `project.godot` | `tests/test_project_settings.gd` |
| Input map: 12 actions, keyboard/mouse + controller (all devices), no conflicting binds | `project.godot` | binding-conflict + device tests |
| Headless validation (import + zero-dependency test runner) | `tools/validate.ps1`, `tests/run_tests.gd` | runner fails correctly on a broken assert |
| Session core: `GameSession`, `SimClock` (integer ticks), `IdRegistry` (ADR-005 regex, duplicate-safe), `InteractionService` (ADR-006 order, `interaction_applied` signal) | `scripts/session/`, `scenes/session/` | 4 test files |
| Player: 8-dir isometric movement (2:1 diagonals, 120 px/s), deterministic nearest-target interaction | `scripts/player/`, `scenes/player/` | unit tests + Lead runtime probe |
| Interactable base + test Lever | `scripts/interaction/` | lifecycle tests |
| Greybox `TestRoom` (12×12 iso floor, walls, obstacle, 2 levers) | `scenes/test/TestRoom.tscn` | runtime probe: bounds hold |
| Temporal core: `TemporalComponent` (history/cursor, commit-on-transition, freeze toggle, save export/import); abilities trace/rewind/freeze/fast_forward through `InteractionService` | `scripts/temporal/`, `scripts/interaction/interactable.gd` | `tests/temporal/` incl. TEST-PZ001-01..04, TEST-PZ002-01/02/03/05 |
| Echo: `EchoService` record/playback (player-only logic track, watch abilities excluded, 1200-tick cap, persistent occupancy, reset) + `TriggerZone` occupancy | `scripts/echo/`, `scripts/interaction/trigger_zone.gd` | `tests/echo/` incl. TEST-PZ003-02/03/04, TEST-PZ004-04/05; physics runtime probe |
| Puzzle progression: `PuzzleService` (permanent SOLVED, member resets), `PuzzleCompletionZone`, `ResetAnchor`; `NarrativeState` (flags, fragments) | `scripts/puzzle/`, `scripts/narrative/` | `tests/puzzle/` |
| Save/load: `SaveService` (type-tagged JSON, atomic write, migrations, validation, temporal history) | `scripts/save/` | `tests/save/` incl. save → fresh scene → load loop |
| Ch1 design: beat sheet (10 beats, 38 min), 5 puzzle specs with 27 given/when/then tests | `design/ch01/` | Lead reviews in `docs/reviews/` |

## B. Partially implemented
- Interaction feedback: `InteractionResult.reason` exists, but the player ignores it, so no UI feedback (ISSUE-006).
- Boot scene: placeholder label only; `run/main_scene` is Boot, not a gameplay scene.

## C. Implemented but not integrated
- `SaveService` is not yet an autoload, and nothing calls it from gameplay (checkpoints arrive with SceneRouter). Registration happens in TLF-018.
- Flash's pocket watch exists only on its branch (`431d1c5`); it is being ported in TLF-018.

## D. Broken
- Nothing known (validation green on `main`).

## E. Missing (next by priority)
1. SpatialGraph + doorway presenters (TLF-020, Opus, next)
2. Pocket-watch controller + Echo controls + HUD (TLF-018, Flash, after TLF-017)
3. Ghost visuals and echo HUD (part of TLF-018)
4. Settings autoload and input-remapping foundation (TLF-017, Flash)
5. Camera, scene routing between rooms, SpatialGraph (doorway reassignment)
6. Ch1 room graph (TLF-005, Argon, changes requested), then art target sheet (TLF-010)
7. All art, audio, UI, dialogue/narrative presentation and Ch1 content

## F. Should be improved
- Prompt text is hard-coded `[E]` and English-only (ISSUE-007).
- Expected `push_error` output from negative tests shows up in logs; acceptable for now.

## G. Stable, don't rework without an ADR
- ADR-locked contracts: IdRegistry API, `InteractionService.request` signature and order, SimClock tick model, display settings, input action names.
