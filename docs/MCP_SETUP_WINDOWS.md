# Windows MCP Setup — Pixelorama + Godot AI Workbench

This is a cautious setup guide for **Orca from Onorca**. Orca launches agent CLIs; MCP configuration belongs to the relevant CLI runtime. These snippets are templates, not a verified universal Orca configuration file.

> **Project decision (ADR-012 amendment, 2026-10-31):** THE LAST FRAME uses `@coding-solo/godot-mcp` pinned to 0.1.1, not Godot AI Workbench. Section B is kept as reference only.

## Prerequisites

- Windows 10/11 x64
- Git for Windows
- Pixelorama installed (standalone or via Steam/itch.io)
- Godot 4.x Standard build
- Orca installed from https://www.onorca.dev/
- At least one compatible agent CLI installed and authenticated

## A. Pixelorama Workflow & Setup

Project: https://github.com/Orama-Interactive/Pixelorama
Documentation: https://orama-interactive.github.io/Pixelorama-Docs/

Pixelorama is an open-source pixel art editor built on the Godot engine. Pixelorama uses `.pxo` as its native project format and exports runtime PNG spritesheets or frame sequences directly for Godot 4.x.

Workflow guidelines:
- Work with native project files saved as `.pxo` inside `assets/source/`.
- Export runtime spritesheets / PNG sequences via **File > Export > Spritesheet** (or Frame sequence) directly into `assets/characters/`, `assets/props/`, etc.
- Pixelorama is managed directly by Agent 2 (Argon) as the dedicated pixel-art editor. Automated CLI batching can be performed via Pixelorama command-line flags if supported by your installed version.

## B. Godot AI Workbench

Project: https://github.com/ZemDen/godot-ai-workbench
Godot Asset Library: https://godotengine.org/asset-library/asset/5353

General installation sequence (verify current README/release instructions first):

1. Download the Workbench release appropriate for Windows and locate `gaw.exe`.
2. Install/copy the addon into `<Godot project>/addons/godot_ai_workbench` as described by its current README.
3. Open the project in Godot and enable the addon in Project Settings → Plugins.
4. Open the Workbench dock and confirm its local bridge is connected.
5. Configure the MCP client using the actual `gaw.exe` path.

Example entry for a client accepting standard MCP JSON:

```json
{
  "mcpServers": {
    "godot-ai-workbench": {
      "command": "C:/Tools/godot-ai-workbench/bin/gaw.exe",
      "args": ["--tool-mode", "lite"]
    }
  }
}
```

Replace the executable path with the real path. If the current release requires a working directory or bridge-port argument, follow that release's README and ensure the port matches the Godot dock. Do not copy a guessed path or port into a live configuration.

Recommended modes:
- `lite`: default for routine scene/script work.
- `full`: only when a task needs the full editor/runtime tool set.
- Read-only/Analysis profile: use for review when available.
- Full Control: only for the single agent currently implementing a Godot task.

## C. Connect to each agent runtime

**Do not assume Orca has one global MCP config.** Check each CLI's own current documentation and verify tools in a fresh agent session.

- Claude Code: add the servers through the supported `claude mcp add` command or supported configuration file. Consult https://docs.anthropic.com/en/docs/claude-code/mcp.
- Gemini CLI: configure `mcpServers` using the current Gemini CLI documentation. Consult https://github.com/google-gemini/gemini-cli.

A configuration added to Claude Code may not be visible to Gemini CLI, and vice versa. Repeat setup for every runtime that needs a server.

## D. Safe validation sequence

1. Close/reopen the relevant CLI session after changing MCP configuration.
2. Ask the agent to list available MCP tools and identify the server name.
3. Run a harmless status/read-only action.
4. For Godot, ask for project metadata or a scene tree read before allowing edits.
5. For Pixelorama, verify export paths and palette configs before creating sprites.
6. Test one small reversible operation and inspect the result manually.
7. Record working versions, paths and known issues in `docs/TOOLCHAIN_VERSIONS.md` (do not record secrets).

## E. Troubleshooting

- **Server not listed:** check the CLI's config file path, JSON validity, executable path, restart session, and whether that CLI supports stdio MCP.
- **`npx` not found:** confirm Node.js is installed and `node`/`npx` are on PATH in the Orca-launched terminal.
- **Pixelorama:** confirm Pixelorama launches independently and can export PNG spritesheets.
- **Godot bridge disconnected:** open the project, enable the addon, open its dock, check its status and port settings.
- **One agent sees tools but another does not:** configure MCP separately for the second CLI runtime.
- **Agent edits wrong worktree:** stop it, inspect `git status`, and relaunch from the intended Orca workspace.

Never paste access tokens, API keys or private account data into the repository, prompts or screenshots.
