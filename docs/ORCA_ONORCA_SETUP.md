# Orca IDE (Onorca) — Setup & Operating Guide

**Target:** Orca from [onorca.dev](https://www.onorca.dev/), not the unrelated Orca Desktop container manager at orca-desktop.com.

## 1. Understand the execution model

Orca is an agent development environment. It launches coding-agent CLIs (Claude Code, Gemini CLI, Codex, etc.) in separate Git worktrees. A worktree is its own checkout, branch, files and agent terminal. This isolation is the primary protection against simultaneous edits.

**Important:** Orca worktrees do not automatically make every MCP server available to every agent. MCP servers are configured for the agent runtime/CLI. Configure and verify them for each agent type you actually launch. Do not paste secrets into repository files or prompts.

Official references:
- Orca: https://www.onorca.dev/
- First 3-agent session: https://www.onorca.dev/docs/first-session
- Worktrees: https://www.onorca.dev/docs/model/worktrees
- Settings: https://www.onorca.dev/docs/settings

## 2. Recommended project setup

1. Install Git for Windows, Godot 4.x Standard, Pixelorama, Node.js 20+, Claude Code and Gemini CLI as applicable.
2. Create a local Git repository for `THE_LAST_FRAME` and make an initial commit before agents start.
3. Add the repository to Orca.
4. Create three task workspaces from the same base commit. Name them `tlf-lead`, `tlf-design-art`, and `tlf-implementation-qa`.
5. Launch the chosen CLI in each workspace and select the requested model in that CLI's supported model selector. The display names in this pack are role targets; actual model availability is controlled by the provider/account and CLI version.
6. Open each workspace in Orca panes so you can monitor the terminals and diffs.
7. Do not let agents edit the same files concurrently. Agent 1 owns integration and final merge.

If your Orca build has a dedicated orchestration/task feature, use it to assign the tasks in `ORCA_TASK_BOARD.md`. Otherwise use the three worktrees and paste the matching prompt into each agent.

## 3. Worktree ownership map

| Worktree | Agent | Primary ownership |
|---|---|---|
| `tlf-lead` | Claude Opus 5.5 High | Architecture, project governance, review, integration, release decisions |
| `tlf-design-art` | Gemini 4 Argon | Narrative, puzzle specifications, room/level design, Pixelorama source assets |
| `tlf-implementation-qa` | Gemini 3.8 Flash High | GDScript implementation, Godot scenes, tests, asset import and QA |

These are logical assignments, not a claim that Orca can force model-specific permissions. Enforce them through prompts, separate worktrees and human review.

## 4. MCP setup principle

Add MCP servers to the relevant agent CLI configuration, then verify them in a fresh session. Do not assume a single Orca-wide JSON configuration exists or that adding an MCP to one CLI automatically exposes it to another.

- Claude Code: use `claude mcp add` or its supported project/user MCP configuration.
- Gemini CLI: use Gemini CLI's supported `mcpServers` settings configuration.
- Godot AI Workbench is configured as a local MCP server; Pixelorama is used by Argon for `.pxo` source art creation and PNG export.

See `MCP_SETUP_WINDOWS.md` for safe templates. The exact config location and syntax can change with CLI versions; verify against current vendor docs before applying.

## 5. Operational safety

- Start with Godot Workbench `lite` tool mode where available; use `full` only for tasks requiring full editor/runtime control.
- Only one agent should have write access to a Godot scene/project at a time. Prefer Flash for implementation; Opus reviews read-only or reviews diffs.
- Argon is the sole writer of `.pxo` (Pixelorama) source files. Other agents consume exported PNG/spritesheets.
- Never have two agents run destructive Git operations or merge simultaneously.
- Keep credentials, API keys, local paths containing usernames, and tokens out of Git.
- Ask for confirmation before deleting assets, overwriting scenes, resetting branches, or bulk-renaming files.
- Before each milestone, make a Git commit or tag. Use a clean checkpoint before risky changes.

## 6. First-day acceptance checklist

- [ ] Orca sees the repository and base branch.
- [ ] Three distinct worktrees exist and have separate branches.
- [ ] Each agent can read project docs and report its role.
- [ ] Claude Code and Gemini CLI sessions start successfully (as applicable).
- [ ] Pixelorama installed and verified for `.pxo` editing and PNG spritesheet export.
- [ ] Godot Workbench connects to the open Godot project.
- [ ] One read-only test succeeds per MCP server before granting write actions.
- [ ] A test commit in one worktree does not alter the other two.
- [ ] The team knows which agent owns each file category.

If a CLI or MCP server is not available in the current Orca build, do not invent a workaround or mark it complete. Use the manual workflow and record the limitation in `docs/KNOWN_ISSUES.md`.
