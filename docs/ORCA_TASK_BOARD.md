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
| TLF-017 | TESTED (merged `c72f272`) | Code merged: 14 settings tests, 108/108 on merge result. **Manual controller + remap evidence not provided yet**, so not COMPLETE (Milestone 1 exit criterion) |
| TLF-018 | READY | Flash: `docs/tasks/TLF-018.md`. **Start by porting `431d1c5`** per `docs/reviews/2026-10-31_TLF-008-flash-duplicate.md`; also register the SaveService autoload |
| TLF-020 | COMPLETE | Opus SpatialGraph + SpatialService + DoorwayPresenter merged `3740531` (94/94; physics doorway probe) |
| TLF-021 | IN PROGRESS | Opus: room router (scene loading per room, doorway spawn placement, checkpoints → SaveService), Echo stop on room change |
| TLF-019 | COMPLETE | Opus PuzzleService + SaveService + NarrativeState merged `afa6929` (82/82, no leaks; real-scene save probe OK). Autoload registration → TLF-018 |
| TLF-016 | COMPLETE | Opus EchoService + TriggerZone merged `9f55245` (validate 67/67; physics runtime probe OK) |
| TLF-010 | READY | Argon: `docs/tasks/TLF-010.md` (art bible, palette, target sheet, first sprite batch; `.pxo` must pass Pixelorama CLI verification) |
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
| TLF-009 | Implement first temporal puzzle | Flash | 004, 008 | Complete playable puzzle with reset/recovery and tests |
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
