# TLF-001 — Repository Audit Report

**Author:** Agent 1 (Lead, Claude Opus 5.5) · **Date:** 2026-10-31 · **Status:** REVIEW REQUIRED (human)
**Scope:** Non-destructive audit. No existing file was modified, moved or deleted. No packages installed. No MCP write actions run.

---

## 1. Environment evidence

| Check | Result | Evidence |
|---|---|---|
| Project root | `D:\TheLastFrame\the-last-frame` | `pwd` |
| Git repository | **NONE** — no `.git` here or in any parent | `git status` → `fatal: not a git repository` |
| Branch / clean state | N/A (no repo) | — |
| Parent folder | `D:\TheLastFrame` is an Obsidian vault (`.obsidian/`) | `ls -la` |
| Godot project | `project.godot` exists, `config_version=5`, features `4.7, Forward Plus`, created 2026-10-31 07:33 | file read |
| Godot content | 0 scenes, 0 scripts, 1 asset (`icon.svg`) | Godot MCP `get_project_info` |
| Docs location | **Nested**: `THE_LAST_FRAME_Full_Setup_Pixelorama/THE_LAST_FRAME_Project_Pack/` (README, `docs/`, `agent_prompts/`, `orca_templates/`, `assets/`) — 30 Markdown files, 91 KB | `find` |
| Code in pack | None. README mentions `scripts/windows/` — **does not exist** | `find` |

### Toolchain (verified 2026-10-31)

| Component | Version / location | Notes |
|---|---|---|
| Windows | 10 Home 10.0.19045 | |
| Godot | **4.7.2.stable.official.ed1daf0bf** — `D:\Godot\Godot_v4.7.2-stable_win64(_console).exe` | Not on PATH |
| Git | 2.54.0.windows.1 | |
| Node.js | v24.21.0 | |
| Claude Code | 2.1.286 | |
| Gemini CLI | 0.65.0 | Access to "Gemini 4 Argon" / "Gemini 3.8 Flash" **not verified** |
| Orca | Installed (`AppData\Local\Programs\orca`, updater → github `stablyai/orca`) | Version not read |
| Pixelorama | Unzipped in `C:\Users\adity\Downloads\Pixelorama-Windows-64bit\` | Version not verified; not in a stable install location |
| Godot AI Workbench | **Not installed** (`gaw` not found, no `addons/`) | |
| Python | 3.14 at `C:\Python314` | |

### MCP servers visible to the Lead session

| Server | Verified read-only call | Notes |
|---|---|---|
| `godot` (not Godot AI Workbench) | `get_godot_version` ✅, `get_project_info` ✅ | Also exposes **write** tools (`create_scene`, `add_node`, `save_scene`, `update_project_uids`, `run_project`). Lead must not use them (see RISK-011). |
| `pixel-art` | not exercised | Unrelated to Pixelorama; docs say Pixelorama has no MCP. Not part of pipeline. |
| Roblox Studio, Figma, ForgeGUI, Claude Docs | not exercised | Irrelevant to this project. Do not use. |

---

## 2. Missing foundations

1. **No Git repository / base commit.** Orca worktrees, the handoff policy and every review step depend on it. Hard blocker for multi-agent work.
2. **Docs not at repo root.** Every prompt references `README.md` and `docs/` at root; they live two folders deep, inside `res://`.
3. **No ADRs.** Architecture doc is principles-level; no data contracts are locked (IDs, clock, interaction API, state schema, save schema).
4. **No test framework** and no headless validation procedure.
5. **No folder structure, input map, main scene, or display settings** for pixel art.
6. **No art bible numbers**: internal resolution, pixel density, iso tile size, character height, palette.
7. **Godot AI Workbench absent**; the MCP actually present is a different Godot server. Docs and reality diverge.
8. `.gitignore` covers only `.godot/` and `/android/` — no export dirs, local MCP configs, env files.

---

## 3. Contradictions & ambiguities

| ID | Conflict | Sources | Proposed resolution |
|---|---|---|---|
| C1 | Docs expected at root; actually nested. README cites non-existent `scripts/windows/`; lists Pixelorama twice. | README, prompts | ADR-001: relocate pack to root (needs human approval). Fix README. |
| C2 | **"Echo" names two mechanics**: pocket-watch ability *reveal residual traces* (GDD §8) vs *record & replay own actions* (GDD §9). | GDD §8, §9 | ADR-014: rename the reveal ability (e.g. "Trace"). Argon proposes name, Opus approves. |
| C3 | VS needs "at least one" of rewind/freeze/fast-forward (PRD §8) but FR-004 and FR-005 make all three P0. | PRD §6, §8 | Scope decision SD-1 (below). |
| C4 | PRD §8 and FR-012 require a spatial puzzle in Ch1; GDD §5 says Ch3 *introduces* room rotation/doorways and Ch1's purpose doesn't mention spatial. | PRD, GDD §5 | SD-1: Ch1 gets one spatial *foreshadow* puzzle; Ch3 owns the full introduction. Update GDD §5. |
| C5 | Example puzzle CH1-PZ-003 needs the echo to physically hold a switch, but architecture says avoid raw per-frame transforms. | PUZZLE_DESIGN §3, ARCH §5 | ADR-008: logic = discrete events (incl. `trigger_enter/exit`); presentation = low-rate path samples, visual only. |
| C6 | Docs require integer scaling and consistent pixel density; `project.godot` uses `stretch/mode=canvas_items`, `aspect=expand`, no nearest default filter (blur/shimmer risk). | ARCH §10, GDD §13, project.godot | ADR-003. |
| C7 | PRD says choose renderer after testing; project already set to Forward Plus + D3D12 + **Jolt 3D physics** for a 2D game targeting Linux. | PRD §4, project.godot | ADR-003 spike: Forward+ vs Compatibility on target hardware. Jolt is harmless but irrelevant. |
| C8 | TLF-006 "build Godot project skeleton" — a bare project already exists. | Task board | Re-scope TLF-006 to structure + settings + validation. |
| C9 | Docs specify Godot AI Workbench (`gaw.exe`); installed MCP is a different server. | MCP_SETUP_WINDOWS | ADR-012/tooling note: decide whether to install Workbench or adopt existing server; record in KNOWN_ISSUES. |
| C10 | README puts helper scripts in `scripts/windows/`; ownership policy gives `scripts/` to Flash for GDScript. | README, Git policy | Put shell helpers in `tools/`. |
| C11 | VS P0 list (controller remap, accessibility, audio mix, journal, hints, dialogue, cinematic, save/load, ≥5 puzzles) is large for one vertical slice. | PRD §6 | SD-1: tier P0 into "VS-must" and "VS-foundation-only" (e.g. remap UI can be minimal). |
| C12 | Model labels "Gemini 4 Argon" / "Gemini 3.8 Flash High" are unverified role targets. | README, ORCA setup | Human verifies in Gemini CLI; record in TOOLCHAIN_VERSIONS. |

### SD-1 — Proposed Chapter 1 mechanic scope (reversible assumption, needs human/Opus sign-off)

- **In:** Rewind, Freeze, Echo recording/playback (1 echo at a time), one spatial foreshadow puzzle (single doorway reassignment or one 90° room rotation, backed by the real SpatialGraph), Trace reveal for narrative clues.
- **Stretch:** Fast-Forward (one puzzle) — keeps FR-005 P0 only if it fits.
- **Out (P1):** Time Shift between timelines, gravity, folding, overlap, multiple simultaneous echoes, temporal energy (Ch1 has no energy constraint → no soft-lock risk).

---

## 4. Minimal architecture baseline (proposal)

```
res:// (= repo root)
├─ project.godot
├─ docs/  (Opus)        design/ narrative/ (Argon)
├─ assets/source/ (Argon, .pxo)   assets/{characters,environments,props,vfx,ui,audio}/ (exports)
├─ scenes/  scripts/  tests/  (Flash)
├─ tools/   (shell helpers; Opus approves)
└─ addons/  (only after ADR-012)
```

- **Display:** internal canvas 640×360, `stretch/mode=viewport`, `scale_mode=integer` (×3 → 1920×1080), default texture filter Nearest, 2:1 isometric tiles (proposed 32×16). Final numbers fixed by ADR-003 after the TLF-010 target sheet.
- **Sim clock:** a single `SimClock` advancing integer ticks in `_physics_process` at 60 Hz. All temporal/echo timestamps are ticks, never float seconds or frame counts.
- **Stable IDs:** `StringName` `chNN.<room>.<object>` (e.g. `ch01.platform.gate_01`), unique per chapter, validated at load by a registry.
- **Interaction contract:** one entry point, `request(actor_id, target_id, interaction_id, payload) -> Result{ok, reason}`. Player and echo both use it, so echoes cannot bypass validation.
- **TemporalObject (component node):** `object_id`, capability flags `{REWIND, FREEZE, FAST_FORWARD}`, `capture_state() -> Dictionary` (declared fields only), `apply_state(d)`, `validate(d)`. History = per-object ring buffer of discrete state changes keyed by tick, not per-frame snapshots. Permanent progression lives in `PuzzleState`/narrative flags, never in the rewindable state.
- **Echo:** logic track = `[tick, kind, target_id, interaction_id, payload]`; presentation track = position samples at 10 Hz, interpolated for the ghost only. Missing or invalid target → event skipped, reason logged, puzzle notified.
- **SpatialGraph:** pure-data `RefCounted` (rooms, doorway edges). `apply(transform)` validates → commits → emits `changed`, or rolls back. Presenters (visuals, collision, nav, anchors, camera) derive from the graph.
- **Save:** JSON in `user://saves/`, `save_version`, plain dicts of IDs → values, migration table, defaults for missing fields.
- **Autoloads (only 4):** `Settings`, `SaveService`, `SceneRouter`, `AudioService`. Temporal/Puzzle/Spatial/Timeline services hang off a per-session `GameSession` node, so tests can create them in isolation.
- **Content data:** typed custom `Resource` (`.tres`) for puzzles, rooms and capabilities. Dialogue/text uses `tr()` keys.

## 5. ADR list (to be written under TLF-002)

| ADR | Topic | Blocks |
|---|---|---|
| ADR-001 | Repo layout, pack relocation, folder ownership | everything |
| ADR-002 | Git/worktree workflow, branch names, integration flow | multi-agent work |
| ADR-003 | Renderer, internal resolution, stretch/integer scale, pixel density, iso tile metrics, 2D physics | TLF-006, TLF-010 |
| ADR-004 | Fixed-tick SimClock & determinism rules | TLF-008 |
| ADR-005 | Stable ID scheme & registry | TLF-007, 008 |
| ADR-006 | Interaction contract (player + echo) | TLF-007, 008 |
| ADR-007 | TemporalObject capabilities, state schema, rewind history | TLF-008 |
| ADR-008 | Echo recording model (logic events + presentation path) | TLF-008, 009 |
| ADR-009 | SpatialGraph model, transactional apply, Ch1 scope | spatial puzzle |
| ADR-010 | Save format, versioning, migration | save/load |
| ADR-011 | Autoload vs session-scoped services | TLF-006 |
| ADR-012 | Test framework (GdUnit4 vs GUT vs zero-dependency runner, all need Godot 4.7 compatibility check) & headless validation; Godot MCP tool policy | TLF-006 |
| ADR-013 | Data-driven content format (`.tres` vs JSON) | TLF-004 handoff |
| ADR-014 | Ability naming (Echo vs Trace) | TLF-003/004 text |
| SD-1 | Chapter 1 mechanic scope (§3) | TLF-003/004/005 |

---

## 6. Bounded backlog (converted from ORCA_TASK_BOARD)

Common rules for every task: one worktree/branch per task; `git status --short` before/after; no destructive git/fs actions; no MCP write tools unless named as Godot owner; stop on conflicting interface, missing dependency, scope change or destructive need.

| ID | Owner | Depends | Allowed files | Acceptance (summary) | Tests / evidence | Status |
|---|---|---|---|---|---|---|
| **TLF-000** *(new)* | **Human** | — | repo root | `git init`, pack relocated per ADR-001, `.gitignore` extended, initial commit + tag `m0-base` | `git log -1`, `git status` clean | BLOCKED (approval) |
| TLF-001 | Opus | — | this file | Inventory, gaps, risks, ADR list | this report | REVIEW REQUIRED |
| TLF-002 | Opus | 000 | `docs/adr/*`, `docs/ARCHITECTURE.md`, `PRD.md`/`GDD.md` (SD-1 edits only) | ADR-001…014 + SD-1 accepted; docs consistent with C1–C12 | Opus checklist; human sign-off on SD-1 | NOT STARTED |
| TLF-003 | Argon | 001 (+SD-1 assumption) | `design/ch01/CH01_BEAT_SHEET.md` | see §7 | Opus canon/scope review | **READY — assigned** |
| TLF-004 | Argon | 002, 003 | `design/ch01/puzzles/CH1-PZ-00N.md` | 5 specs in PUZZLE_DESIGN §2 format; only SD-1 mechanics; hint ladder + reset each | Opus + design review; solvability walkthrough | NOT STARTED |
| TLF-005 | Argon | 002, 003 | `design/ch01/ROOM_GRAPH.md` (+ diagram) | Rooms/edges using ADR-005 IDs; critical path; optional routes; spatial puzzle graph valid | Opus review vs ADR-009 | NOT STARTED |
| TLF-006 | Flash | 000, ADR-001/003/011/012 | see §8 | see §8 | see §8 | **DRAFTED — HELD** |
| TLF-007 | Flash | 006, ADR-005/006 | `scripts/player/`, `scripts/interaction/`, `scenes/test/`, `tests/` | Iso movement, collision, interact targeting deterministic; KB+pad | unit tests (targeting), manual pad test log | NOT STARTED |
| TLF-008 | Flash | 006, ADR-004/005/006/007/008 | `scripts/temporal/`, `tests/temporal/` | Registry, rewind, freeze, echo record/replay; missing-target handling | Tests: start/stop/replay/reset/invalid; determinism at 30/60/144 render FPS | NOT STARTED |
| TLF-009 | Flash | 004, 008 | `scenes/ch01/puzzles/`, `data/puzzles/`, `tests/` | One puzzle playable with reset & hints | integration test + manual repro | NOT STARTED |
| TLF-010 | Argon | 003, ADR-003 draft | `assets/source/ch01/*.pxo`, exports in `assets/*/ch01/`, `design/art/ART_BIBLE.md` | Target sheet, palette, scale spec, Elias idle/walk, 1 tile kit | Flash import check at real resolution | NOT STARTED |
| TLF-011 | Flash | 005, 010 | `scenes/ch01/rooms/`, import settings | First room: collision/nav/anchors align with art | screenshot + walk-test log | NOT STARTED |
| TLF-012 | Opus | 007–011 | integration branch, `docs/` | Ch1 path playable start→finish | full playthrough log | NOT STARTED |
| TLF-013 | Flash | 012 | `docs/qa/` reports only | Severity-ranked report with repro steps | QA checklist run | NOT STARTED |
| TLF-014 | Argon | 012 | `design/`, `narrative/`, assets | Cinematic script, dialogue, asset list | Opus review | NOT STARTED |
| TLF-015 | Opus | 013, 014 | `docs/` | Go/no-go for Gate C | external playtest notes | NOT STARTED |

---

## 7. Assignment — Argon (dispatch now)

```text
TASK ID:      TLF-003
TITLE:        Chapter 1 narrative beat sheet
OWNER:        Agent 2 — Argon (worktree tlf-design-art)
OBJECTIVE:    One beat sheet for "The Forgotten Station" that a puzzle designer and an
              implementer can both build from.
CONTEXT:      GDD §1, §4, §5, §8–9, §12, §15; PRD §8; PUZZLE_DESIGN.md;
              TLF-001 report §3 (C2, C3, C4, SD-1).
ASSUMPTION:   Ch1 mechanics = SD-1 "In" list. Fast-Forward is optional; Time Shift,
              gravity, folding, temporal energy are OUT. If a beat needs anything else, flag it.
DEPENDENCIES: TLF-001 only. No code contracts required.
FILES ALLOWED:   design/ch01/CH01_BEAT_SHEET.md (new)
FILES FORBIDDEN: docs/**, scripts/**, scenes/**, tests/**, project.godot, assets/**
                 (no art in this task), any existing file.
ACCEPTANCE CRITERIA:
  1. 8–14 ordered beats. Each has: location, player objective, mechanic taught or tested,
     narrative information revealed, emotional tone, est. minutes.
  2. Total estimate 30–45 min. ≥5 beats marked as puzzle slots (slot ID + intent only,
     no full specs; full specs belong to TLF-004).
  3. Contains: pocket-watch tutorial, first recorded-echo puzzle, one spatial foreshadow
     beat, ≥1 NPC or recorded character presence, exactly one major revelation,
     one cinematic beat, an exit hook into Chapter 2.
  4. Canon is unchanged (Elias, Mira, Operator = future Elias, Archivist, Elias-0, 23:59,
     loop, 4 endings). Anything canon-adjacent goes in an "Open canon questions" section,
     not into the beats.
  5. Section "Naming proposal (ADR-014)": 2–3 names for the reveal-traces ability with rationale.
  6. Section "Mechanics outside SD-1 that I wanted": list, or "none".
TESTS:        Self-check against criteria 1–6. Opus reviews against GDD canon and SD-1.
DELIVERABLES: The file, committed on its own branch, plus a handoff report
              (summary, files changed, open questions).
STOP CONDITIONS: canon contradiction needed; a beat needs an OUT mechanic to work;
              asked to touch any forbidden path.
```

## 8. Assignment — Flash (drafted, HELD until gates pass)

Gates: TLF-000 done (repo + base commit) **and** ADR-001, 003, 011, 012 accepted. Dispatching earlier would bake in display and test-framework choices that aren't decided yet.

```text
TASK ID:      TLF-006
TITLE:        Project structure, display/input settings, headless validation
OWNER:        Agent 3 — Flash (worktree tlf-implementation-qa); sole Godot writer for this task
OBJECTIVE:    A clean Godot 4.7.2 project that imports headlessly with zero errors, has the
              agreed folders, input map and pixel-art display settings, and runs one
              automated smoke test from the command line.
CONTEXT:      ADR-001/003/011/012; GDD §7 controls; TLF-001 §4 baseline.
FILES ALLOWED:   project.godot; scenes/boot/Boot.tscn; scripts/core/boot.gd;
                 tests/** ; tools/validate.ps1 ; addons/<framework>/ only if ADR-012 picks one
                 AND the human approved the install.
FILES FORBIDDEN: docs/** (send doc changes to Opus), design/**, narrative/**, assets/source/**,
                 icon.svg, .gitattributes, .editorconfig.
REQUIREMENTS:
  - Display settings exactly as ADR-003 (expected: viewport stretch, integer scale,
    Nearest default filter, renderer per ADR-003).
  - Input actions: move_up/down/left/right, interact, watch, ability_next, ability_prev,
    confirm, cancel, journal, pause. Each has a keyboard binding and a joypad binding.
  - Main scene = Boot.tscn (shows a label, no gameplay).
  - Folder skeleton per ADR-001.
  - Use the Godot CLI for validation, not MCP write tools.
ACCEPTANCE CRITERIA:
  1. `D:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --import`
     exits 0 with no ERROR lines.
  2. Smoke test (via ADR-012 runner) exits 0: asserts every listed input action exists
     and has ≥1 key and ≥1 joypad event, and the main scene loads.
  3. `tools/validate.ps1` runs 1 and 2 in sequence and returns their exit code.
  4. Launching the project shows Boot at 1920×1080 with crisp pixels (screenshot).
  5. `git diff --stat` touches only allowed files.
TESTS:        Commands in 1–3; screenshot for 4; diff for 5. Attach the full console logs.
DELIVERABLES: Branch + commit; handoff report (files, decisions, exact test output,
              limitations, any contract change requested).
STOP CONDITIONS: ADR not accepted; framework incompatible with 4.7.2; anything needs an
              addon/package install not yet approved; any forbidden path needed.
```

---

## 9. Risks to add to KNOWN_ISSUES (after TLF-000)

| ID | Risk | Sev | Next action |
|---|---|---|---|
| RISK-008 | No version control: any agent edit is irreversible | **Critical** | TLF-000 |
| RISK-009 | Godot 4.7.2 is newer than tested versions of GUT/GdUnit4 | Medium | ADR-012 compatibility spike |
| RISK-010 | VS P0 list too large for the slice | High | SD-1 tiering |
| RISK-011 | Lead session can see Godot MCP **write** tools; two writers could clash | High | Policy: only the assigned Godot owner uses write tools; Lead stays read-only |
| RISK-012 | Docs location drift (nested pack, duplicate zip in Downloads) | Medium | ADR-001 relocation |
| RISK-013 | Pixelorama runs from Downloads, version unknown; `.pxo` format may change between versions | Low | Pin a version in TOOLCHAIN_VERSIONS |
| RISK-014 | Gemini model labels unverified; the role split may run on one model | Medium | Human verifies in Gemini CLI |
