# Orca Worktree Plan

Create these workspaces from the same clean base commit:

1. `tlf-lead` — Claude Code / Opus; owns architecture, task assignment, review and integration.
2. `tlf-design-art` — Gemini CLI / Argon; owns design docs and Pixelorama (.pxo) source assets.
3. `tlf-implementation-qa` — Gemini CLI / Flash; owns GDScript, Godot scenes and tests.

If Orca cannot launch two different Gemini model variants as separate sessions, use two Gemini CLI sessions and select the requested model per session only if supported by the current CLI/account. Otherwise keep the role split but run one Gemini agent at a time. Do not pretend model selection is guaranteed by the workspace name.

Only the integration owner merges. Do not use one shared writable Godot project copy for simultaneous full-control editor sessions. Keep the design and implementation worktrees isolated; transfer approved exports/contracts through commits or reviewed patches.
