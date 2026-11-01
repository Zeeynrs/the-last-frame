# Project Status

**Updated:** 2026-11-01 · **Main:** see `git log -1 origin/main` · **Engine:** Godot 4.7.2 · **Validation:** `tools/validate.ps1` → import clean, 314/314 tests, 121 scripts, leak check clean (enforced by validate.ps1 since TLF-035)

This file states what the repository **actually** contains. Task-level detail lives in `ORCA_TASK_BOARD.md`; history lives in `PROGRESS.md`.

## A. Works (merged, tested)
| Area | Where | Evidence |
|---|---|---|
| Project config: 640×360 integer-scaled pixel display, Forward+, 60 Hz physics | `project.godot` | `tests/test_project_settings.gd` |
| Input map: 12 actions, keyboard/mouse + controller (all devices), no conflicting binds | `project.godot` | binding-conflict + device tests |
| Headless validation (import + script parse + zero-dependency test runner + leak-at-exit gate) | `tools/validate.ps1`, `tests/run_tests.gd`, `tools/validate_selftest/` | runner fails correctly on a broken assert; self-test 6/6 (node/resource/RID/static leaks red, expected ERROR lines green) |
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
| Story UI: `DialogueBox` (blocking/non-blocking, one-shot `heard.*` flags), `DocumentViewer` (paging, SimClock pause), `JournalScreen` (categories + fragments), `hint` action (H + joypad 10); all Ch1 Beats 01–10 wired | `scripts/ui/`, `scenes/ui/`, `scripts/chapters/ch01/` | `tests/ui/`, `tests/chapters/ch01/test_ch01_narrative_beats.gd` |
| Real-input proofs: full Ch1 playthrough with input actions + physics only (PZ-001…005 incl. PZ-004 with Echo, Beats 09/10); negative test that PZ-004 fails without Echo (RISK-018 closed); PZ-004 geometric route/reach tests on real colliders | `tests/chapters/ch01/`, `tests/support/base_test.gd` | TLF-030/031/033 + `3df2583` |
| Game flow: F5 → Boot → title screen (New Game / Continue / Quit, overwrite confirmation) → Chapter 1; Continue restores the last checkpoint; chapter complete → title. `SceneRouter` autoload | `scripts/core/`, `scenes/boot/`, `scenes/ui/title_screen.tscn` | `tests/core/`, `tests/ui/test_title_screen.gd`; Opus windowed screenshots |
| Art (batches 1+2): art bible, Ch1 palette (32), Elias v2 8-dir idle/walk, 8 floor tiles, walls/pillar/archways/railing, shared props (bench, call box, reset console, lever, clipboard, 23:59 clock), 5 puzzle props (turnstile, fire shutter, gear, capacitor, pressure switch), placement sheet for all 10 rooms, 4 room mockups, batch 3 (route board, security gate, bridge, transit car, dispatch terminal, pocket watch, lever badges, PA speaker), generators in `tools/art/gen/` (byte-reproducible), CC0 pixel font | `design/art/`, `assets/`, `tools/art/check_assets.py` | Pixelorama re-export pixel-identical (tlf-lead 37/37, Lead 3/3), palette/alpha checks; placed in all 10 rooms (TLF-041), collision unchanged |
| Ch1 design: beat sheet (10 beats, 38 min), 5 puzzle specs with 27 given/when/then tests, room graph (10 rooms, boundary doors, placement metrics, kit list) | `design/ch01/` | Lead reviews in `docs/reviews/` |
| Ch1 expansion Step 1 design (ADR-020): concept, specs SO-01/SO-02/PZ-006 + R1 revisions of PZ-001..005, TraceMemory/unlock/commuter specs, beat sheet §7 (28.7 min design / 17.2 floor), text (209 keys) | `design/ch01/`, `narrative/ch01/`, `localization/ch01_text.csv` | TLF-047; tlf-lead generator check |
| Chapter-complete overlay as a themed scene with the playtest summary | `scenes/ui/chapter_complete_overlay.tscn`, `scripts/ui/` | `tests/ui/test_chapter_complete_overlay.gd`; tlf-lead screenshot |
| Ability wheel art (face, pointers, segments x 3 states, icons, lock glyph) | `assets/ui/ability_wheel/`, `tools/art/gen/ui_wheel.py` | TLF-053; Pixelorama 39/39, verify_regen |

## B. Partially implemented

## C. Implemented but not integrated
- `TraceMemory`, `AbilityUnlocks` + `AbilityUnlockTrigger`, locked-ability refusal in PocketWatch, save v3 (TLF-050). The game still starts with all four abilities and no room has a memory until TLF-055.

## D. Broken
- Trace shows nothing in the game yet (ISSUE-039: mechanism merged, content -> TLF-055).
- PZ-002 is solvable without Freeze (RISK-020 confirmed by TLF-049; fix -> TLF-054/055/056).

## E. Missing (next by priority)
1. Chapter 1 expansion Step 1 (ADR-020): TLF-052 ability wheel (Flash), TLF-054 puzzle logic (Opus impl), TLF-057 art (design-art), then TLF-055 rooms (Flash), TLF-056 real-input proofs (Opus impl), then a telemetry playtest (target >= 15 min)
2. Export smoke test (Windows build: theme font, translations, saves) once an export preset exists
3. Human: physical controller spot-check (ISSUE-011, last item for M1)
4. Vertical-slice polish: audio, lighting/VFX, Beat 10 cinematic, accessibility pass
5. External playtest (Gate C)

## F. Should be improved
- Expected `push_error` output from negative tests shows up in logs; acceptable for now.

## G. Stable, don't rework without an ADR
- ADR-locked contracts: IdRegistry API, `InteractionService.request` signature and order, SimClock tick model, display settings, input action names.
