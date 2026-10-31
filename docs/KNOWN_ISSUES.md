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
| RISK-007 | Scope may exceed solo/small-team production capacity | High | Open | Agent 1 | Enforce Chapter 1 vertical-slice gate |

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
