# Agent Handoff

Read this first when resuming. Keep it short and current.

## Team and ownership (ADR-017)
| Agent | Role | Owns |
|---|---|---|
| Opus (Claude) | Lead architect, **core-systems programmer**, integration authority | `docs/`, ADRs, integration on `main`; core systems in `scripts/temporal/`, `scripts/echo/`, `scripts/puzzle/`, `scripts/save/`, `scripts/spatial/`, `scripts/session/` and their tests |
| Flash (Gemini) | Feature implementer + QA | player, interaction feel, UI/HUD/menus, settings, input, camera, audio/VFX integration, scene setup, `project.godot` (single owner), regression tests |
| Argon (Gemini) | On-demand creative/design | `design/`, `narrative/`, `assets/source/` (`.pxo`), high-value batches only. **Unavailable since 2026-10-31 (RISK-019)** |
| Design-art (Claude Code, Sonnet 5.5) | Stand-in for Argon on art, worktree `tlf-design-art`, branch `adityadaffa522/tlf-art-batch2` | `design/art/`, `assets/source/ch01/`, PNG exports in `assets/{characters,environments,props}/ch01/`; no scenes/scripts/merges. First task TLF-039 |

Shared contract files (`interactable.gd`, `game_session.gd`, `GameSession.tscn`, `project.godot`) have **one owner per task**, named in the task file.

## Where work happens
- Primary checkout `D:\TheLastFrame\the-last-frame` = `main`, Lead integration only.
- Opus implementation worktree: `D:\TheLastFrame\wt-opus-core`, branch `agent/opus-core`. **Since 2026-10-31 it belongs to a dedicated Opus implementation agent** (Orca terminal `term_21972ee7-5fe2-4037-a554-c6cb4a4b09c6`). The Lead session works only in the primary checkout (review, integration, docs) and never edits `wt-opus-core`. Route Opus implementation tasks to that terminal.
- Agents: Orca worktrees `C:\Users\adity\orca\workspaces\the-last-frame\tlf-*` on branches `adityadaffa522/tlf-*`.

## Current state
- See `PROJECT_STATUS.md` (what works), `ORCA_TASK_BOARD.md` (task status), `DEVELOPMENT_ROADMAP.md` (order).
- **State 2026-10-31:** F5 plays: title → Chapter 1 end to end, Continue restores checkpoints; first-playtest fixes merged; leak gate + headless save guard in place. Art batch 2 merged (TLF-039). UI pixel-font theme, spawn targeting fix and art batches 2+3 merged. Open: TLF-041 (Flash: art integration, ADR-019 + am.), TLF-044 (design-art: capacitor frozen states).
- **Merge rule:** the Lead re-runs `validate.ps1` on a fresh `git archive` with a renamed `config/name` for every merge; agent-pasted validate output is never accepted as evidence alone (ISSUE-028).
- **Handoff rule:** paste raw `tools/validate.ps1` output (not a paraphrase) in every handoff.
- Content generators: `python tools/content/gen_ch01_text.py`, `gen_ch01_puzzle_data.py` and `gen_ch01_graph.py` (sources: `narrative/ch01/CH01_TEXT.md`, `design/ch01/puzzles/*.md`, `design/ch01/ROOM_GRAPH.md`). Opus core systems + Ch1 puzzle logic are merged; TLF-009 (rooms 1–4) waits for TLF-018. Open: TLF-017 manual evidence (ISSUE-011).
- Building Ch1 rooms: instance them under `ChapterRoot`, follow ADR-018 (Spawn markers off the presenter, IDs `ch01.<room>.<object>`).

## How to verify anything
`$env:GODOT=<console exe>; ./tools/validate.ps1` (must exit 0). Review method: `git archive <sha>` into a scratch folder, then run validate plus runtime probes there. Never inside an agent's worktree.

## Rules that bit us (see ISSUE-003)
- Never run git in another agent's checkout. Re-`fetch` and compare SHAs right before any branch deletion or merge.
- Merge with `--no-ff` only after re-checking that the branch tip equals the reviewed SHA.
