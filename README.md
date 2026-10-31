# THE LAST FRAME — Complete Development Pack

A production-ready **planning, documentation, multi-agent workflow and toolchain starter pack** for building THE LAST FRAME with Godot 4.x, Pixelorama and Orca IDE from Onorca.

> This ZIP is not a finished game. It contains the project specification, technical direction, agent roles, task workflow, MCP setup templates, QA gates and bootstrap instructions needed to start development safely.

## Game identity

- **Genre:** Isometric 2.5D psychological mystery / sci-fi puzzle adventure
- **Engine:** Godot 4.x / GDScript
- **Platform:** Windows and Linux PC
- **Mode:** Single-player
- **Visuals:** Premium HD Cinematic Pixel Art (not low-poly 3D)
- **Target:** 5–8 hours, 6 chapters, 4 endings
- **Core pillars:** time manipulation, spatial manipulation, deterministic temporal echoes, environmental storytelling and fair mind-bending puzzles

## Start here — recommended order

1. `docs/GDD.md` — vision, world, story, gameplay and content scope.
2. `docs/PRD.md` — product requirements and acceptance criteria.
3. `docs/ARCHITECTURE.md` — system boundaries and technical contracts.
4. `docs/ORCA_ONORCA_SETUP.md` — correct setup for Orca from Onorca.
5. `docs/MCP_SETUP_WINDOWS.md` — Pixelorama and Godot Workbench setup templates.
6. `docs/AGENT_HANDOFF_AND_GIT_POLICY.md` — worktree/file ownership rules.
7. `docs/ORCA_TASK_BOARD.md` — initial backlog and task assignments.
8. `docs/PROJECT_BOOTSTRAP.md` — build the project foundation in safe milestones.
9. `docs/ART_PIPELINE.md` — art source/export pipeline.
10. `docs/QA_AND_RELEASE_CHECKLIST.md` — quality gates.
11. `docs/MASTER_PROMPT.md` and `agent_prompts/` — copy the relevant prompt into each agent.

## Three-agent roles

| Agent | Requested model | Role |
|---|---|---|
| 1 | Claude Opus 5.5 High | Lead architect, core-systems programmer, reviewer, integration authority (ADR-017) |
| 2 | Gemini 3.8 Flash High | Feature implementation (player, UI, settings, camera, audio/VFX, scenes), testing and QA |
| 3 | Gemini 4 Argon | On-demand creative: narrative, puzzle/level design, Pixelorama source art |

Model availability and exact model labels depend on the provider account and CLI version. Orca provides isolated worktrees and agent terminals; it does not guarantee a particular model alias or automatically share one MCP configuration across every CLI.

## Toolchain

- Orca from https://www.onorca.dev/ — agent IDE and worktree management.
- Godot 4.x — game engine.
- Godot AI Workbench — optional Godot MCP automation.
- Pixelorama — open-source pixel-art source editor (.pxo master files, spritesheet export).
- Git — version control and safe parallel development.

**Correct Orca product:** Onorca (`onorca.dev`). Do not follow setup instructions for the unrelated Orca Desktop at `orca-desktop.com`.

## Safety rules

- Separate worktree per agent/task.
- Argon alone edits `.pxo` (Pixelorama) source files.
- Flash owns Godot implementation in its assigned worktree.
- Only one agent uses Godot Workbench full write control at a time.
- Opus reviews and integrates; no automatic merge of unreviewed work.
- Never commit secrets, API keys, tokens or machine-specific private paths.
- Do not run destructive Git/filesystem actions without human approval.
- Build a polished Chapter 1 vertical slice before expanding the other five chapters.

## Pack structure

- `docs/` — GDD, PRD, architecture, implementation, MCP, Orca, art, QA and production documentation.
- `agent_prompts/` — role prompts and task prompts for the three agents.
- `orca_templates/` — worktree plan, task template and MCP examples.
- `assets/` — asset folder conventions.
- `tools/` — safe local helper scripts (no credentials or auto-installers); created when first needed. `scripts/` is reserved for GDScript.

## Validate the project

Requires Godot **4.7.2** (console build). Point `GODOT` at it, then from the repo root (PowerShell):

```powershell
$env:GODOT = "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
./tools/validate.ps1          # headless import check + test suite; exit 0 = pass
```

Individual steps:

```powershell
& $env:GODOT --headless --path . --import                       # import, must print no ERROR lines
& $env:GODOT --headless --path . -s res://tests/run_tests.gd    # tests; exit code = failures
```

Tests live in `tests/**/test_*.gd` (zero-dependency runner, ADR-012). Run validation before every push to `main`.

The repository root is the Godot project (`project.godot`). See `docs/ADR_LOG.md` for accepted architecture decisions and `docs/TLF-001_AUDIT_REPORT.md` for the initial audit.

## Official tool references

- Orca: https://www.onorca.dev/
- Orca first session: https://www.onorca.dev/docs/first-session
- Orca worktrees: https://www.onorca.dev/docs/model/worktrees
- Pixelorama: https://github.com/Orama-Interactive/Pixelorama
- Godot AI Workbench: https://github.com/ZemDen/godot-ai-workbench
- Godot: https://godotengine.org/

See `docs/TOOLCHAIN_VERSIONS.md` to record actual installed versions after verification.
