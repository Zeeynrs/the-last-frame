# Agent Handoff

Read this first when resuming. Keep it short and current.

## Team and ownership (ADR-017)
| Agent | Role | Owns |
|---|---|---|
| Opus (Claude) | Lead architect, **core-systems programmer**, integration authority | `docs/`, ADRs, integration on `main`; core systems in `scripts/temporal/`, `scripts/echo/`, `scripts/puzzle/`, `scripts/save/`, `scripts/spatial/`, `scripts/session/` and their tests |
| Flash (Gemini) | Feature implementer + QA | player, interaction feel, UI/HUD/menus, settings, input, camera, audio/VFX integration, scene setup, `project.godot` (single owner), regression tests |
| Argon (Gemini) | On-demand creative/design | `design/`, `narrative/`, `assets/source/` (`.pxo`), high-value batches only |

Shared contract files (`interactable.gd`, `game_session.gd`, `GameSession.tscn`, `project.godot`) have **one owner per task**, named in the task file.

## Where work happens
- Primary checkout `D:\TheLastFrame\the-last-frame` = `main`, Lead integration only.
- Opus implementation worktree: `D:\TheLastFrame\wt-opus-core`, branch `agent/opus-core`.
- Agents: Orca worktrees `C:\Users\adity\orca\workspaces\the-last-frame\tlf-*` on branches `adityadaffa522/tlf-*`.

## Current state
- See `PROJECT_STATUS.md` (what works), `ORCA_TASK_BOARD.md` (task status), `DEVELOPMENT_ROADMAP.md` (order).
- In flight: TLF-018 fixes (Flash, R1–R5). Argon unavailable (usage limit). TLF-024 done by Opus, open for Argon's review later.
- Content generators: `python tools/content/gen_ch01_text.py`, `gen_ch01_puzzle_data.py` and `gen_ch01_graph.py` (sources: `narrative/ch01/CH01_TEXT.md`, `design/ch01/puzzles/*.md`, `design/ch01/ROOM_GRAPH.md`). Opus core systems + Ch1 puzzle logic are merged; TLF-009 (rooms 1–4) waits for TLF-018. Open: TLF-017 manual evidence (ISSUE-011).
- Building Ch1 rooms: instance them under `ChapterRoot`, follow ADR-018 (Spawn markers off the presenter, IDs `ch01.<room>.<object>`).

## How to verify anything
`$env:GODOT=<console exe>; ./tools/validate.ps1` (must exit 0). Review method: `git archive <sha>` into a scratch folder, then run validate plus runtime probes there. Never inside an agent's worktree.

## Rules that bit us (see ISSUE-003)
- Never run git in another agent's checkout. Re-`fetch` and compare SHAs right before any branch deletion or merge.
- Merge with `--no-ff` only after re-checking that the branch tip equals the reviewed SHA.
