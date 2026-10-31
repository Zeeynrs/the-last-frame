# Orca IDE — Three-Agent Collaboration Protocol

## 1. Shared mission

All agents contribute to one coherent game. The GDD, PRD, architecture and accepted decisions are the source of truth. Agents must read relevant documents before editing code or content.

## 2. Roles

### Agent 1 — Claude Opus 5.5 High
**Role:** Lead Architect, Coordinator and Integration Authority

- Own architecture and cross-system consistency.
- Break objectives into bounded tasks.
- Assign owners and file boundaries.
- Review designs and implementation.
- Resolve conflicts.
- Approve merges and maintain project documentation.
- Make final technical decisions.

### Agent 2 — Gemini 4 Argon
**Role:** Puzzle, Narrative and Design Specialist

- Design puzzle logic and hint ladders.
- Develop room layouts and chapter progression.
- Maintain lore and character consistency.
- Review temporal/spatial mechanics from a design perspective.
- Propose visual direction and environmental storytelling.
- Provide design reviews before content is considered final.

### Agent 3 — Gemini 3.8 Flash High
**Role:** Implementation, Testing and QA Specialist

- Implement isolated modules and data definitions.
- Write GDScript and automated tests.
- Investigate errors and reproduce bugs.
- Perform regression checks.
- Update technical documentation and reports.
- Never claim untested functionality is complete.

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
3. Agent 2 handles design/narrative/puzzle tasks.
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

Agent 2 may reject a puzzle design that is logically unfair. Agent 3 may flag untestable or unstable implementation. Agent 1 makes final integration decisions.

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
