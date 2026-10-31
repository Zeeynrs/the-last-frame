# Orca Task Board — Initial Backlog

## Current status (2026-10-31)

| ID | Status | Note |
|---|---|---|
| TLF-000 | COMPLETE | Repo, relocation, baseline tag `m0-base` |
| TLF-001 | COMPLETE | `docs/TLF-001_AUDIT_REPORT.md` |
| TLF-002 | COMPLETE | `docs/ADR_LOG.md` (ADR-014 accepted 2026-10-31) |
| TLF-003 | COMPLETE | Merged `db09cc2` (re-review of `d5bfba6` passed) |
| TLF-006 | COMPLETE | Merged `c1492d8` (re-review of `846f806` passed; validate on main 5/5) |
| TLF-004 | COMPLETE | Merged `eed7c4e` (re-review of `75dcb95` passed) |
| TLF-007 | COMPLETE | Merged `99f6bb3` (re-review of `1801ed0` passed; validate on main 26/26) |
| TLF-005 | COMPLETE | Merged `e1c0816` (re-review of `41190e7`: PZ-004 forced route 318 ticks recomputed, boundary doors, arithmetic) |
| TLF-008 | COMPLETE | Opus temporal core merged `fe3744a` (validate 51/51; TestRoom regression probe OK) |
| TLF-017 | COMPLETE (with noted deviation) | Merged `c72f272`. Evidence: `docs/handoffs/TLF-017/` (scripted synthetic controller + remap run) + Lead's independent remap probe on `main`. Deviation: no physical controller used, so a human spot-check is outstanding (ISSUE-011) |
| TLF-018 | CHANGES REQUESTED | `6332fb6` reviewed (`docs/reviews/2026-10-31_TLF-018.md`): works in runtime; fix R1 ghost leak/parenting, R2 SaveService autoload + translations, R3/R4 minor. Was: READY | Flash: `docs/tasks/TLF-018.md`. **Start by porting `431d1c5`** per `docs/reviews/2026-10-31_TLF-008-flash-duplicate.md`; also register the SaveService autoload |
| TLF-020 | COMPLETE | Opus SpatialGraph + SpatialService + DoorwayPresenter merged `3740531` (94/94; physics doorway probe) |
| TLF-021 | COMPLETE | Opus RoomRouter + ChapterRoot + world memory merged `5fda100` (118/118, mutation-checked, physics probe). Was: room router (scene loading per room, doorway spawn placement, checkpoints → SaveService), Echo stop on room change |
| TLF-019 | COMPLETE | Opus PuzzleService + SaveService + NarrativeState merged `afa6929` (82/82, no leaks; real-scene save probe OK). Autoload registration → TLF-018 |
| TLF-016 | COMPLETE | Opus EchoService + TriggerZone merged `9f55245` (validate 67/67; physics runtime probe OK) |
| TLF-023 | COMPLETE | Opus Ch1 puzzle objects merged `e6de2b4`: all 27 spec tests + 10 extra, mutation-checked; 166/166 |
| TLF-029 | READY (after TLF-028) | Opus impl agent: frame-stepping (await physics frames) tests in `tests/run_tests.gd`, so playthroughs can use real input + physics |
| TLF-028 | READY | Opus impl agent: `docs/tasks/TLF-028.md` (`validate.ps1` dies on any Godot stderr line under PowerShell 5.1) |
| TLF-027 | COMPLETE | Opus impl agent `aafb2bb`, merged: class `SaveStore`, autoload name `SaveService`; verified 180/180 with and without the autoload; router adopts the autoload. **TLF-018 R2b unblocked** |
| TLF-026 | COMPLETE | Opus: Ch1 graph as `ChapterGraphDef` (`data/chapters/ch01/ch01_graph.tres`) generated from ROOM_GRAPH + PZ-005; 9 tests, mutation-checked; 180/180 |
| TLF-024b | IN PROGRESS | Design worktree agent (now Opus): port improvements from `eecb822` into main's `CH01_TEXT.md` (main's keys, SPK_* labels); `eecb822` itself not merged (add/add conflict). Lead reviews + approves new IDs, then re-runs `gen_ch01_text.py` |
| TLF-024 | COMPLETE (first pass) | Opus (re-assigned; Argon at usage limit): 66 keys in `narrative/ch01/CH01_TEXT.md` → CSV + 5 DocumentDefs via `tools/content/gen_ch01_text.py`; 171/171. Open for Argon's narrative review |
| TLF-009 | APPROVED, merge pending | `b157fd4` reviewed (`docs/reviews/2026-10-31_TLF-009.md`): 203/203, real-input probe rooms 1→3 + PZ-001 OK. Pre-merge: R1 test must not write the real autosave. Merges with TLF-018 after the ch01_text translation commit. Was: BLOCKED (TLF-018) | Flash: `docs/tasks/TLF-009.md` (rooms 1–4 playable greybox); rooms 5–10 → TLF-025 |
| TLF-022 | COMPLETE | Opus HintService + PuzzleDef (5 Ch1 defs + CSV generated from specs) + DocumentDef/ReadableDocument + journal merged `440a5be` (129/129) |
| TLF-010 | COMPLETE | Merged (Argon `68e299f`): all 10 `.pxo` pass the Pixelorama CLI open/export check; PNGs byte-identical to the re-exports; palette-only; 0 semi-alpha. Art polish notes → ISSUE-012 |
| others | NOT STARTED | |

Branch naming and merge flow: ADR-002 (incl. Orca naming amendment).

Use this as the initial task list. Each task must run in its assigned worktree. Agent 1 controls dependencies and integration.

| ID | Task | Owner | Depends on | Deliverable / acceptance |
|---|---|---|---|---|
| TLF-001 | Audit repo and existing docs | Opus | None | Inventory, gaps, risk list; no destructive edits |
| TLF-002 | Lock core architecture and conventions | Opus | 001 | ADRs, folder structure, naming and data contracts approved |
| TLF-003 | Define Chapter 1 narrative beats | Argon | 001 | Beat sheet with objective, reveal, emotional turn and exit hook |
| TLF-004 | Design five vertical-slice puzzles | Argon | 002, 003 | Puzzle specs with logic, clues, solution, hint ladder and recovery |
| TLF-005 | Define station room graph and puzzle flow | Argon | 002, 003 | Room graph, critical path, optional routes, spatial logic |
| TLF-006 | Build Godot project skeleton | Flash | 002 | Opens in Godot 4.x without errors; README run instructions |
| TLF-007 | Implement player movement + interaction | Flash | 006 | Keyboard/controller movement, deterministic interact targeting, tests |
| TLF-008 | Implement temporal state framework | Flash | 006, 002 | Stable IDs, serializable state, deterministic event replay tests |
| TLF-009 | Implement first temporal puzzle (re-scoped: Ch1 rooms 1–4, see docs/tasks/TLF-009.md) | Flash | 018, 021, 023 | Rooms 1–4 playable with PZ-001…003 |
| TLF-010 | Create visual target sheet + sprite kit | Argon | 003 | Pixelorama (.pxo) sources, export PNGs, palette and scale spec |
| TLF-011 | Import assets and create first room | Flash | 005, 010 | Room loads, collision/nav/anchors align, visual review passed |
| TLF-012 | Vertical slice integration | Opus | 007–011 | 30–45 min target slice flow, no critical blockers |
| TLF-013 | Playtest and regression | Flash | 012 | Test report, repro steps, severity and fixes |
| TLF-014 | Narrative polish and cinematic | Argon | 012 | Scripted sequence, dialogue and asset list |
| TLF-015 | Release candidate review | Opus | 013, 014 | Build checklist, known issues, go/no-go decision |

## Task handoff format

Every assignment must state:

- **Objective:** one measurable outcome.
- **Context:** relevant docs and existing implementation.
- **Dependencies:** task IDs and approved interfaces.
- **Allowed files:** exact paths or folder ownership.
- **Forbidden files:** files another agent owns or shared critical files.
- **Acceptance criteria:** observable pass/fail conditions.
- **Tests:** exact commands or manual test steps.
- **Deliverables:** code/assets/docs/report.
- **Stop conditions:** missing requirements, conflicting interfaces, destructive action, or scope expansion.

## Status definitions

`NOT STARTED` → `IN PROGRESS` → `BLOCKED` or `IMPLEMENTED` → `TESTED` → `REVIEW REQUIRED` → `COMPLETE`.

Only Agent 1 may mark a cross-agent task `COMPLETE` after review. An agent must not claim a task is complete because code was merely generated.
