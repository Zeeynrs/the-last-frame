# Agent Handoff

Read this first when resuming. Keep it short and current.

## Team and ownership (ADR-017, amended 2026-11-05)
| Agent | Role | Owns |
|---|---|---|
| Opus (Claude Opus 5.5) | Lead Architect and Senior Programmer, integration authority | `docs/`, ADRs, integration on `main`; core systems in `scripts/temporal/`, `scripts/echo/`, `scripts/puzzle/`, `scripts/save/`, `scripts/spatial/`, `scripts/session/` and their tests |
| Flash (Gemini 3.8 Flash High) | Feature implementation + QA, follows Opus contracts | player, interaction feel, UI/HUD/menus, settings, input, camera, audio/VFX integration, scene setup, `project.godot` (single owner), regression tests |
| Argon (Gemini 4) | **Primary creative asset specialist** (available again 2026-11-05), follows Sol's direction. Worktree `tlf-design-art`, new branch per task from `main` | `design/ch01/**` (puzzle/level specs), `assets/source/**` (`.pxo`), art exports, `tools/art/gen/**`, `design/art/` except `ART_BIBLE.md` and `reference/` |
| Sol (GPT-6.1) | **Art Director**, visual direction authority, and **full Argon fallback** (ADR-017 am.). Orca worktree `tlf-art-direction`, branch `adityadaffa522/tlf-art-direction` (create in Orca) | `design/art/ART_BIBLE.md`; visual review of every art delivery. Argon's paths **only** while it is the active specialist (fallback) |
| ~~Sonnet 5.5~~ | **Excluded 2026-11-05**: no tasks, no fallback role. Its merged art/design work stays; `adityadaffa522/tlf-art-batch2` is history | — |

**Argon fallback (ADR-017 am.):** if Argon is unavailable (limit, quota, access), stop assigning to it. Sol takes every unfinished Argon task from Argon's last pushed commit, and the owner line in the task file and the board change to Sol. Finished work is never redone, and no one waits for Argon. When Argon is back, it takes new and not-yet-started tasks. Sol finishes what it started and stays Art Director. One active asset specialist writes art sources at a time.

Shared contract files (`interactable.gd`, `game_session.gd`, `GameSession.tscn`, `project.godot`) have **one owner per task**, named in the task file.

**Story canon and dialogue (ADR-022 D5):** the Lead owns `docs/STORY_BIBLE.md` + its five companions and `narrative/**`. Every narrative merge passes the Operator checklist (`docs/OPERATOR_MYSTERY_GUIDELINES.md` §6). Owner references: `design/art/reference/ch01/`.

## Where work happens
- Primary checkout `D:\TheLastFrame\the-last-frame` = `main`, Lead integration only.
- Opus implementation worktree: `D:\TheLastFrame\wt-opus-core`, branch `agent/opus-core`. **Since 2026-10-31 it belongs to a dedicated Opus implementation agent** (Orca terminal `term_21972ee7-5fe2-4037-a554-c6cb4a4b09c6`). The Lead session works only in the primary checkout (review, integration, docs) and never edits `wt-opus-core`. Route Opus implementation tasks to that terminal.
- Agents: Orca worktrees `C:\Users\adity\orca\workspaces\the-last-frame\tlf-*` on branches `adityadaffa522/tlf-*`.

## Current state
- See `PROJECT_STATUS.md` (what works), `ORCA_TASK_BOARD.md` (task status), `DEVELOPMENT_ROADMAP.md` (order).
- **State 2026-10-31:** F5 plays: title → Chapter 1 end to end, Continue restores checkpoints; first-playtest fixes merged; leak gate + headless save guard in place. Art batch 2 merged (TLF-039). UI pixel-font theme, spawn targeting fix and art batches 2+3 merged and **integrated in all 10 rooms** (TLF-041). Barrier visual, capacitor frozen split and art reproducibility snapshot merged (TLF-045/046). Playtest #2: no bugs, combos loved, chapter too short (ISSUE-038). ADR-020 expansion: concept approved (`CH01_EXPANSION.md`), telemetry merged (TLF-048). **2026-11-01 (`f432bca`):** Step 1 specs (TLF-047 phase 2), TraceMemory + ability unlocks + save v3 (TLF-050), chapter-complete overlay (TLF-051) and wheel art (TLF-053) merged; TLF-049 confirmed PZ-002 needs no Freeze (RED, kept on `agent/opus-core-pz002neg`). Open: TLF-052 wheel (Flash), TLF-054 Step 1 logic (Opus impl), TLF-057 Step 1 art (Argon, Sol reviews); then TLF-055 rooms (Flash), TLF-056 real-input proofs (Opus impl).
- **Merge rule:** the Lead re-runs `validate.ps1` on a fresh `git archive` with a renamed `config/name` for every merge; agent-pasted validate output is never accepted as evidence alone (ISSUE-028).
- **Handoff rule:** paste raw `tools/validate.ps1` output (not a paraphrase) in every handoff.
- Content generators: `python tools/content/gen_ch01_text.py`, `gen_ch01_puzzle_data.py` and `gen_ch01_graph.py` (sources: `narrative/ch01/CH01_TEXT.md`, `design/ch01/puzzles/*.md`, `design/ch01/ROOM_GRAPH.md`). Opus core systems + Ch1 puzzle logic are merged; TLF-009 (rooms 1–4) waits for TLF-018. Open: TLF-017 manual evidence (ISSUE-011).
- Building Ch1 rooms: instance them under `ChapterRoot`, follow ADR-018 (Spawn markers off the presenter, IDs `ch01.<room>.<object>`).

## How to verify anything
`$env:GODOT=<console exe>; ./tools/validate.ps1` (must exit 0). Review method: `git archive <sha>` into a scratch folder, then run validate plus runtime probes there. Never inside an agent's worktree.

## Rules that bit us (see ISSUE-003)
- Never run git in another agent's checkout. Re-`fetch` and compare SHAs right before any branch deletion or merge.
- Merge with `--no-ff` only after re-checking that the branch tip equals the reviewed SHA.
