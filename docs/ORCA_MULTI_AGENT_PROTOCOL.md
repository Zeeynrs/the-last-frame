# Orca IDE — Multi-Agent Collaboration Protocol

## 1. Shared mission

All agents contribute to one coherent game. The GDD, PRD, architecture and accepted decisions are the source of truth. Agents must read relevant documents before editing code or content.

## 2. Roles

Team as of 2026-11-05 (ADR-017 amendment). **Claude Sonnet 5.5 is excluded:** it gets no tasks, no fallback role and no workflows.

### Agent 1 — Claude Opus 5.5
**Role:** Lead Architect and Senior Programmer, Coordinator and Integration Authority (core gameplay, Temporal Echo, puzzle system and dual-Elias architecture; core systems are built by the Opus implementation agent in `wt-opus-core`)

- Own architecture and cross-system consistency.
- Break objectives into bounded tasks.
- Assign owners and file boundaries.
- Review designs and implementation.
- Resolve conflicts.
- Approve merges and maintain project documentation.
- Make final technical decisions.

### Agent 2 — Gemini 4 Argon
**Role:** Primary Creative Asset Specialist: puzzle, narrative and level specs, character/environment/prop/VFX asset concepts and specifications, sprite and animation planning, tilesets, `.pxo` sources and exports, asset quality review. Follows Sol's visual direction.

- Design puzzle logic and hint ladders.
- Develop room layouts and chapter progression.
- Maintain lore and character consistency.
- Review temporal/spatial mechanics from a design perspective.
- Propose environmental storytelling; visual direction comes from Sol.
- Provide design reviews before content is considered final.

### Agent 3 — Gemini 3.8 Flash High
**Role:** Feature Implementation and QA (gameplay features, puzzles in scenes, UI, bug fixing, regression tests, performance, technical docs). Follows the architecture and contracts set by Opus.

- Implement isolated modules and data definitions.
- Write GDScript and automated tests.
- Investigate errors and reproduce bugs.
- Perform regression checks.
- Update technical documentation and reports.
- Never claim untested functionality is complete.

### Agent 4 — GPT-6.1 Sol
**Role:** Art Director and full Argon fallback

- Own the visual direction: style, palette, lighting, composition, character and environment direction, cinematic identity (`design/art/ART_BIBLE.md`).
- Review every art delivery for visual consistency before the Lead merges it.
- While Argon is unavailable, take over all of Argon's unfinished responsibilities (section 2a).

## 2a. Argon fallback protocol (mandatory)

When Argon is unavailable (usage limit, quota, access or other problems):
1. Stop assigning new tasks to Argon immediately.
2. Move every unfinished Argon task to Sol. Sol starts from Argon's last pushed commit, and the task file and the board name Sol as owner.
3. Sol is Art Director and creative asset specialist until Argon returns.
4. Keep all completed Argon work, and don't redo finished tasks.
5. Never use Claude Sonnet 5.5 as a replacement, and don't wait for Argon.

When Argon is available again:
1. Argon is the primary creative asset specialist again for new tasks and for unfinished tasks Sol hasn't started.
2. Sol finishes what it has started and stays Art Director.
3. Keep Sol's work; don't produce the same asset twice.

Only one **active asset specialist** (Argon, or Sol in fallback) writes `.pxo` sources, art exports, art generators, design specs and narrative at a time. Authority: Sol decides visual direction; Opus decides technical integration and has the final integration call.

## 3. Task assignment format

Every delegated task must include:

```text
TASK ID:
TITLE:
OWNER:
OBJECTIVE:
CONTEXT:
DEPENDENCIES:
FILES ALLOWED:
FILES FORBIDDEN:
TECHNICAL REQUIREMENTS:
ACCEPTANCE CRITERIA:
TESTS REQUIRED:
EXPECTED DELIVERABLES:
REPORT FORMAT:
```

Tasks should be small enough to review and independent enough to run in parallel.

## 4. Safe parallelism

- Use a separate Git worktree or branch for each parallel task when available.
- Assign clear file ownership.
- Do not allow two agents to modify the same critical file concurrently.
- If shared files must change, serialize the work or have Agent 1 own the integration.
- Agents must not overwrite uncommitted work from another agent.
- Before merge, inspect diffs and run relevant tests.
- Keep the main branch stable and buildable.

## 5. Standard workflow

1. Agent 1 inspects the request and current repository state.
2. Agent 1 creates bounded tasks with explicit file ownership.
3. Agent 2 (or Agent 4 in fallback) handles design, narrative, puzzle and asset tasks, under Agent 4's visual direction.
4. Agent 3 handles isolated implementation and tests.
5. Agent 1 reviews architecture and diffs.
6. Resolve conflicts and revise work as necessary.
7. Run unit and integration tests.
8. Merge accepted changes.
9. Update documentation and progress.
10. Report completed, incomplete and blocked work honestly.

## 6. Review rules

A review must check:
- Requirements alignment.
- Architecture compatibility.
- Edge cases and error handling.
- Performance implications.
- Tests and test results.
- Documentation.
- Unintended scope changes.
- Whether the implementation is actually present in the repository.

Agent 2 may reject a puzzle design that is logically unfair. Agent 4 may reject art that breaks the visual direction. Agent 3 may flag untestable or unstable implementation. Agent 1 makes final integration decisions.

## 7. Conflict resolution

Priority order:
1. PRD requirements and acceptance criteria.
2. Accepted architecture decisions.
3. GDD player experience and design pillars.
4. Maintainability and testability.
5. Agent preference.

If documents conflict, Agent 1 identifies the conflict, proposes a resolution and updates the authoritative documents. Do not silently choose whichever instruction is newest in a chat.

## 8. Definition of done

A task is `COMPLETE` only when:
- Acceptance criteria pass.
- Required tests pass.
- Changes are reviewed.
- No known critical regression remains.
- Relevant documentation is updated.
- The accepted changes are integrated.

Allowed statuses: NOT STARTED, IN PROGRESS, BLOCKED, IMPLEMENTED, TESTED, REVIEW REQUIRED, COMPLETE.

## 9. Agent communication

Every agent completion report must include:
- Summary.
- Files changed.
- Important implementation decisions.
- Tests run and exact results.
- Known limitations.
- Follow-up tasks.
- Commit/branch/worktree reference if applicable.

Do not assume agents share conversation history. Pass relevant context explicitly in each task.
