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
| TLF-005 | READY | Argon: `docs/tasks/TLF-005.md` (room graph, critical path, placement, kit list) |
| TLF-008 | IN PROGRESS | **Opus** (ADR-017): temporal core in `agent/opus-core` |
| TLF-017 | READY | Flash: `docs/tasks/TLF-017.md` (Settings autoload, remapping foundation, `echo_reset`, controller evidence) |
| TLF-018 | NOT STARTED | Flash, after TLF-008 + TLF-016 merge: pocket-watch controller (ADR-015), HUD feedback (ISSUE-006/007) |
| TLF-019 | NOT STARTED | Opus: PuzzleService (ADR-016) + SaveService (ADR-010) |
| TLF-016 | NOT STARTED | **Opus**, after TLF-008: EchoService record/playback, occupancy, trigger dispatch (ADR-008 + am.) |
| TLF-010 | NOT STARTED | Argon, after TLF-005 |
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
