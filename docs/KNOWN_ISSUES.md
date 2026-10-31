# Known Issues and Risk Register

This file starts as a tracking template. Do not invent resolved status.

| ID | Issue / risk | Severity | Status | Owner | Next action |
|---|---|---|---|---|---|
| RISK-001 | Temporal snapshots may become difficult to maintain if object state is not explicit | High | Open | Agent 1 | Define temporal state contract before broad implementation |
| RISK-002 | Echo playback may desynchronize across frame rates | High | Open | Agent 1 / Agent 3 | Use timestamped deterministic events and tests |
| RISK-003 | Spatial transforms may desynchronize visuals, collision and navigation | High | Open | Agent 1 | Make spatial graph authoritative |
| RISK-004 | Puzzle complexity may become unfair or opaque | Medium | Open | Agent 2 | Use discovery/hint ladder and playtests |
| RISK-005 | Pixel-art assets may have inconsistent scale and density | Medium | Open | Agent 2 | Establish art bible and asset review checklist |
| RISK-006 | Parallel agents may conflict in shared files | High | Open | Agent 1 | Use worktrees, ownership boundaries and reviewed merges |
| RISK-007 | Scope may exceed solo/small-team production capacity | High | Mitigating | Agent 1 | Enforce Chapter 1 vertical-slice gate; SD-1 scope cut |
| RISK-008 | No version control | Critical | Resolved 2026-10-31 | Human / Agent 1 | Repo created, baseline `4297a5a`, tag `m0-base` |
| RISK-009 | Godot 4.7.2 newer than verified versions of GUT/GdUnit4 | Medium | Mitigated | Agent 1 | ADR-012 zero-dependency runner |
| RISK-010 | Vertical-slice P0 list too large | High | Mitigating | Agent 1 | SD-1 tiering; review after TLF-003/004 |
| RISK-011 | Lead session sees Godot MCP write tools; two Godot writers could clash | High | Open | Agent 1 | ADR-012 tool policy: only assigned Godot owner writes |
| RISK-012 | Docs location drift | Medium | Resolved 2026-10-31 | Agent 1 | Pack relocated to root (ADR-001) |
| RISK-013 | Pixelorama version unpinned; `.pxo` format may change between versions | Low | Open | Human | Record version in TOOLCHAIN_VERSIONS |
| RISK-014 | Gemini model labels (Argon/Flash) unverified | Medium | Open | Human | Verify in Gemini CLI; record result |
| ISSUE-001 | Docs specify Godot AI Workbench; it is not installed and a different `godot` MCP server is connected | Low | Open | Human / Agent 1 | Decide install vs adopt existing server; until then use Godot CLI |

## Issue template

```text
ID:
Title:
Description:
Reproduction steps:
Expected behavior:
Actual behavior:
Severity:
Affected version/commit:
Owner:
Status:
Proposed fix:
Validation:
```
