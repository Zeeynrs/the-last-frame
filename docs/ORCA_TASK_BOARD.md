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
| TLF-018 | COMPLETE | Merged `7fb8aec` (Flash): pocket watch, HUD feedback, Elias SpriteFrames (`7dafc5a`), translations + SaveService autoload; ui_feedback translation committed `4476e0e` |
| TLF-020 | COMPLETE | Opus SpatialGraph + SpatialService + DoorwayPresenter merged `3740531` (94/94; physics doorway probe) |
| TLF-021 | COMPLETE | Opus RoomRouter + ChapterRoot + world memory merged `5fda100` (118/118, mutation-checked, physics probe). Was: room router (scene loading per room, doorway spawn placement, checkpoints → SaveService), Echo stop on room change |
| TLF-019 | COMPLETE | Opus PuzzleService + SaveService + NarrativeState merged `afa6929` (82/82, no leaks; real-scene save probe OK). Autoload registration → TLF-018 |
| TLF-016 | COMPLETE | Opus EchoService + TriggerZone merged `9f55245` (validate 67/67; physics runtime probe OK) |
| TLF-023 | COMPLETE | Opus Ch1 puzzle objects merged `e6de2b4`: all 27 spec tests + 10 extra, mutation-checked; 166/166 |
| TLF-029 | COMPLETE (runner) | Merged `2eb5272` (Opus impl): awaitable frame-stepping tests + 6 self-tests. Follow-up TLF-030: real-input Ch1 playthrough test |
| TLF-030 | COMPLETE | Merged `0ddf131` (Opus impl): real-input playthrough PZ-001…003, ~524 physics frames |
| TLF-033 | READY | Flash: `docs/tasks/TLF-033.md` (PZ-004 layout: no reach through railing, seal the gap, unskippable exit trigger, real geometric route test) |
| TLF-032 | COMPLETE | Merged (Flash `dcdb67e`): dialogue box, document viewer, journal, hint (H + joypad 10), Ch1 Beat wiring. Lead spec review item by item + runtime probes |
| TLF-031 | CHANGES REQUESTED | Opus impl `af95b40`: passes on old main, fails on main+TLF-032 (Beat 01 blocking monologue not dismissed). Rebase on main, add dismiss steps for Beats 01/09/10, and fix `tests/support/base_test.gd::tap()` (can drop a press when 2 physics steps run in one idle frame; allowed). The RISK-018 negative test (`agent/opus-core-risk018`) is merged together with TLF-033 |
| TLF-025 | COMPLETE | Merged `a39be53` (Flash): rooms 5–10, PZ-004/005, Beat 09/10, intercom journal hook. Lead real-input probe: PZ-005 levers → atrium → terminal → outro (`chapter_complete`) |
| TLF-028 | COMPLETE | Merged `2eb5272` (Opus impl): validate.ps1 robust on PowerShell 5.1; fresh clone validates on first run |
| TLF-027 | COMPLETE | Opus impl agent `aafb2bb`, merged: class `SaveStore`, autoload name `SaveService`; verified 180/180 with and without the autoload; router adopts the autoload. **TLF-018 R2b unblocked** |
| TLF-026 | COMPLETE | Opus: Ch1 graph as `ChapterGraphDef` (`data/chapters/ch01/ch01_graph.tres`) generated from ROOM_GRAPH + PZ-005; 9 tests, mutation-checked; 180/180 |
| TLF-024b | IN PROGRESS | Design worktree agent (now Opus): port improvements from `eecb822` into main's `CH01_TEXT.md` (main's keys, SPK_* labels); `eecb822` itself not merged (add/add conflict). Lead reviews + approves new IDs, then re-runs `gen_ch01_text.py` |
| TLF-024 | COMPLETE (first pass) | Opus (re-assigned; Argon at usage limit): 66 keys in `narrative/ch01/CH01_TEXT.md` → CSV + 5 DocumentDefs via `tools/content/gen_ch01_text.py`; 171/171. Open for Argon's narrative review |
| TLF-009 | COMPLETE | Merged `7fb8aec` (Flash): Ch1 rooms 1–4 playable; R1 autosave isolation verified; Lead real-input probe rooms 1→3 + PZ-001 |
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
