# Agent Handoff & Git Policy

## Ownership boundaries

- Opus: `docs/`, architecture decisions, integration branch, release notes. It may review all files but should avoid concurrent implementation edits.
- Argon (Sol while Argon is unavailable): `design/`, `narrative/`, puzzle specifications, and `assets/source/` including `.pxo` (Pixelorama) files.
- Sol: visual direction (`design/art/ART_BIBLE.md`) and the visual review of art deliveries.
- Flash: `scripts/`, `scenes/`, `tests/`, Godot project wiring, and import configuration.
- Shared contracts are proposed by the owner and approved by Opus before implementation.

Adjust paths if the repository has an established structure; never relocate a mature project just to match this template.

## Git rules

1. Start from a clean base commit.
2. One task = one worktree/branch where possible.
3. Before editing: `git status --short` and confirm correct branch/worktree.
4. Do not run `git reset --hard`, `git clean -fd`, force-push, branch deletion or bulk deletion without explicit human approval.
5. Commit only the files owned by the task; inspect `git diff --stat` and `git diff` first.
6. Agent 1 integrates by reviewing diffs and cherry-picking/merging deliberately.
7. Never merge two worktrees while either agent is still editing the same logical feature.
8. After integration, run the project validation checklist and update docs.

## Definition of done

A task is complete only when:

- acceptance criteria are met;
- relevant tests pass;
- no critical regression is introduced;
- the change is reviewed in the diff;
- docs/asset inventory/progress are updated where relevant;
- reproducible evidence is attached (test log, screenshot, or steps).

## Conflict protocol

If two agents propose incompatible APIs, node paths, data schemas or puzzle rules:
1. Stop implementation on the conflicting interface.
2. Each agent submits a short proposal with trade-offs.
3. Opus chooses and records an Architecture Decision Record.
4. Update contracts before either agent resumes.
