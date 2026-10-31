# Project Status

**Updated:** 2026-10-31 · **Main:** see `git log -1 origin/main` · **Engine:** Godot 4.7.2 · **Validation:** `tools/validate.ps1` → import clean, 51/51 tests

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
| Ch1 design: beat sheet (10 beats, 38 min), 5 puzzle specs with 27 given/when/then tests | `design/ch01/` | Lead reviews in `docs/reviews/` |

## B. Partially implemented
- Interaction feedback: `InteractionResult.reason` exists, but the player ignores it, so no UI feedback (ISSUE-006).
- Boot scene: placeholder label only; `run/main_scene` is Boot, not a gameplay scene.

## C. Implemented but not integrated
- Nothing yet.

## D. Broken
- Nothing known (validation green on `main`).

## E. Missing (next by priority)
1. Echo record/playback (TLF-016, Opus, in progress)
2. Pocket-watch controller + HUD (TLF-018, Flash, after TLF-017)
3. PuzzleService (ADR-016) and SaveService (ADR-010) (Opus)
5. Settings autoload and input-remapping foundation (TLF-017, Flash)
6. Camera, scene routing between rooms, SpatialGraph (doorway reassignment)
7. Ch1 room graph (TLF-005, Argon, in progress), then art target sheet (TLF-010)
8. All art, audio, UI, dialogue/narrative presentation and Ch1 content

## F. Should be improved
- Prompt text is hard-coded `[E]` and English-only (ISSUE-007).
- Expected `push_error` output from negative tests shows up in logs; acceptable for now.

## G. Stable, don't rework without an ADR
- ADR-locked contracts: IdRegistry API, `InteractionService.request` signature and order, SimClock tick model, display settings, input action names.
