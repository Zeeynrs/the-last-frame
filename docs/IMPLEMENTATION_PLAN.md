# Implementation Plan

## Working rules

- Deliver vertical-slice quality before expanding content.
- Each task has an owner, scope, dependencies and acceptance criteria.
- Work in isolated branches/worktrees when parallelizing.
- Integrate only reviewed, tested changes.
- Update `PROGRESS.md`, `KNOWN_ISSUES.md` and relevant documentation.

## Milestone 0 — Project setup

Deliverables:
- Godot 4.x project created and imports cleanly.
- Git repository and ignore rules.
- Folder structure established.
- Input actions configured.
- Test framework selected and a sample test runs.
- README and project settings documented.

Exit criteria:
- Clean project opens on target development machines.
- A headless import/check procedure is documented.

## Milestone 1 — Isometric foundation

Deliverables:
- Player controller.
- Camera and isometric room prototype.
- Collision and navigation.
- Interaction prompt and stable interactable IDs.
- Basic UI and input remapping foundation.

Exit criteria:
- Player can traverse a test room without collision/navigation defects.
- Interactions work with keyboard/mouse and controller.

## Milestone 2 — Temporal prototype

Deliverables:
- Temporal object registration.
- Explicit object state schema.
- Rewind prototype.
- Freeze and fast-forward prototype.
- Echo event recording and deterministic playback.

Exit criteria:
- Unit tests cover supported state transitions.
- Echo can reliably activate a switch while player performs a second action.
- Invalid/missing targets fail gracefully.

## Milestone 3 — Spatial prototype

Deliverables:
- Room graph.
- 90-degree room orientation changes.
- Doorway connection prototype.
- Safe player relocation.
- Visual/collision/navigation synchronization.

Exit criteria:
- Graph validation tests pass.
- A room transformation cannot silently desynchronize collision and visuals.

## Milestone 4 — Puzzle and narrative framework

Deliverables:
- Data-driven puzzle definitions.
- Puzzle states, completion conditions, reset and hint ladder.
- Dialogue/document/memory fragment presentation.
- Journal and narrative flags.
- Save/load foundation.

Exit criteria:
- At least three test puzzles can be authored without bespoke monolithic scripts.
- Save/load preserves checkpoint and puzzle progression.

## Milestone 5 — Chapter 1 vertical slice

Deliverables:
- Complete Forgotten Station area.
- 30–45 minute target play path.
- Minimum five polished puzzles; 8–12 stretch target.
- Tutorial and first major revelation.
- Character presence and cinematic beat.
- Lighting, VFX, sound and UI polish.
- Save/load and accessibility pass.

Exit criteria:
- Fresh player can complete Chapter 1 without developer intervention.
- No known critical blocker.
- At least one external playtest and documented feedback pass.

## Milestone 6 — Full content production

Produce Chapters 2–6 in sequence using validated content pipelines. Each chapter requires:
- Chapter brief and narrative beats.
- Room graph and map.
- Puzzle specifications and hint ladders.
- Asset list.
- Implementation tasks.
- Playtest and acceptance report.

## Milestone 7 — Beta and release

- Full-game regression.
- Ending path verification.
- Save migration and corrupted-save handling.
- Performance profiling.
- Accessibility and controller testing.
- Audio/visual polish.
- Windows/Linux packaging.
- Credits, settings, legal asset review and release notes.

## Task state definitions

- `NOT STARTED`: no work begun.
- `IN PROGRESS`: active implementation.
- `BLOCKED`: dependency or unresolved issue prevents progress.
- `IMPLEMENTED`: code/content exists but validation is incomplete.
- `TESTED`: acceptance checks passed locally.
- `REVIEW REQUIRED`: awaiting lead review/integration.
- `COMPLETE`: accepted, tested, reviewed and documented.
