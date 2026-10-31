# Project Status

**Updated:** 2026-10-31 · **Main:** see `git log -1 origin/main` · **Engine:** Godot 4.7.2 · **Validation:** `tools/validate.ps1` → import clean, 216/216 tests, 78 scripts

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
| Spatial: `SpatialGraph` (transactional doorway re-pairing, critical paths, reachability), `SpatialService` (relocation), `DoorwayPresenter` | `scripts/spatial/` | `tests/spatial/` incl. TEST-PZ005-01..05; physics doorway probe |
| Settings autoload: volumes→buses, accessibility flags, assist timing window (180→300), input remapping with conflict check + persistence; `echo_reset` action | `scripts/settings/`, `project.godot` | `tests/settings/`; `docs/handoffs/TLF-017/` (scripted synthetic controller run); Lead remap probe |
| Room routing: `ChapterRoot.tscn`, `RoomRouter` (doorway transitions, world memory, checkpoint autosave + restore), `CheckpointZone`, `SafeAnchor` | `scripts/rooms/`, `scenes/chapter/` | `tests/rooms/`; physics room-change probe |
| Hints + content data: `HintService` (FR-010), `PuzzleDef` (5 Ch1 defs + English CSV from specs), `DocumentDef`/`ReadableDocument`, journal (observation/fact/theory) | `scripts/puzzle/`, `scripts/narrative/`, `data/puzzles/ch01/`, `localization/` | `tests/puzzle/test_hint_service.gd`, `tests/narrative/` |
| Ch1 puzzle logic: `PuzzleObject` + TurnstileGate, FireShutter, CounterweightGear, PlateLinkedGate, RetractableBridge, ProgressionPickup, SurgeCapacitor, TimedBreaker, SubstationGrid, PoweredDoor, JunctionLever, SpatialStateResetter | `scripts/puzzle/objects/` | `tests/puzzle/test_ch01_puzzles.gd`: all 27 spec tests (TEST-PZ001…005) |
| Ch1 text: Elias, Operator, journal, fragment, puzzle feedback, 6 readables (66 keys) + 5 DocumentDefs, generated from `narrative/ch01/CH01_TEXT.md` | `narrative/ch01/`, `localization/ch01_text.csv`, `data/documents/ch01/`, `tools/content/` | `tests/narrative/test_ch01_text.gd` |
| Ch1 graph data: `ChapterGraphDef` (rooms, doors, sides/tiles, safe anchors, pairs, critical pairs, relocation) from ROOM_GRAPH + PZ-005 | `data/chapters/ch01/`, `scripts/spatial/chapter_graph_def.gd`, `tools/content/gen_ch01_graph.py` | `tests/spatial/test_ch01_graph.gd` |
| **Playable:** `scenes/chapters/ch01/Chapter01.tscn`: **all 10 rooms, start to `chapter_complete`**, PZ-001…005, Beat 09 revelation, Beat 10 outro, pocket watch (Trace/Rewind/Freeze/Echo), HUD feedback, hints, checkpoints/autosave, Elias sprite animations | `scenes/chapters/ch01/`, `scripts/player/`, `scripts/ui/` | `tests/chapters/ch01/`, `tests/player/`, `tests/ui/`; Lead real-input probe |
| Art v1: art bible, Ch1 palette (32), arrival platform target sheet, Elias 8-dir idle/walk, 3 floor tiles, 2 walls, archway, 23:59 clock, CC0 pixel font | `design/art/`, `assets/` | Lead verification (Pixelorama CLI, palette, alpha, mirrors); not yet placed in a scene |
| Ch1 design: beat sheet (10 beats, 38 min), 5 puzzle specs with 27 given/when/then tests, room graph (10 rooms, boundary doors, placement metrics, kit list) | `design/ch01/` | Lead reviews in `docs/reviews/` |

## B. Partially implemented
- Interaction feedback: `InteractionResult.reason` exists, but the player ignores it, so no UI feedback (ISSUE-006).
- Boot scene: placeholder label only; `run/main_scene` is Boot, not a gameplay scene.

## C. Implemented but not integrated
- `SaveService` is not yet an autoload; `RoomRouter` owns one and uses it for checkpoint autosaves. Autoload registration happens in TLF-018.
- No real Ch1 room scenes yet: router and ChapterRoot are proven with test rooms only (Ch1 rooms come with TLF-009 + TLF-010 art).
- Flash's pocket watch exists only on its branch (`431d1c5`); it is being ported in TLF-018.

## D. Broken
- Nothing known (validation green on `main`).

## E. Missing (next by priority)
1. Real-input proof of PZ-004 as a test (TLF-031, Opus impl)
2. Dialogue/document/journal presentation UI (Milestone 4)
3. Vertical-slice polish: art beyond v1 (Argon unavailable, ISSUE-012), audio, lighting/VFX, Beat 10 cinematic, accessibility pass
4. External playtest (Gate C)

## F. Should be improved
- Prompt text is hard-coded `[E]` and English-only (ISSUE-007).
- Expected `push_error` output from negative tests shows up in logs; acceptable for now.

## G. Stable, don't rework without an ADR
- ADR-locked contracts: IdRegistry API, `InteractionService.request` signature and order, SimClock tick model, display settings, input action names.
