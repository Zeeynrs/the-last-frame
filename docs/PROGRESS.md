# Project Progress

**Last updated:** 2026-10-31  
**Current milestone:** Milestone 1 — Isometric foundation  
**Overall status:** Milestone 0 complete. Ch1 beat sheet approved. No gameplay implemented yet.

## Milestone status

| Milestone | Status | Notes |
|---|---|---|
| 0 — Project setup | COMPLETE | Tag `m0-complete`: repo, ADRs, folder structure, input map, pixel-art display, headless validation (5/5) documented in README |
| 1 — Isometric foundation | IN PROGRESS (exit criteria met except one item) | Movement, collision, interaction, settings and remapping are merged and verified. Remaining: a physical controller spot-check by a human (ISSUE-011) |
| 2 — Temporal prototype | IN PROGRESS | Core done (TLF-008 temporal, TLF-016 Echo); player-facing pocket watch/HUD pending (TLF-018) |
| 3 — Spatial prototype | IN PROGRESS | SpatialGraph (TLF-020) + room routing (TLF-021) merged; exit needs a playable PZ-005 room (TLF-009 content) |
| 4 — Puzzle/narrative framework | IN PROGRESS | PuzzleService, NarrativeState, SaveService merged (TLF-019); dialogue/journal UI pending |
| 5 — Chapter 1 vertical slice | NOT STARTED | |
| 6 — Full content production | NOT STARTED | |
| 7 — Beta and release | NOT STARTED | |

## Current decisions

- Isometric / 2.5D presentation.
- Psychological mystery / science-fiction story.
- Premium HD cinematic pixel art.
- Godot 4.x and GDScript.
- Windows/Linux, single-player.
- Orca IDE with three agents:
  - Claude Opus 5.5 High — lead architect.
  - Gemini 4 Argon — puzzle/narrative/design specialist.
  - Gemini 3.8 Flash High — implementation/QA.

## Work log

| Date | Change | Owner |
|---|---|---|
| Initial | Project documentation baseline created | Project team |
| 2026-10-31 | TLF-001 audit (`docs/TLF-001_AUDIT_REPORT.md`) | Agent 1 |
| 2026-10-31 | Git repo initialised, pack relocated to root, baseline `4297a5a` tagged `m0-base`, pushed to GitHub | Human + Agent 1 |
| 2026-10-31 | TLF-002: `docs/ADR_LOG.md` (SD-1, ADR-001…013 accepted, ADR-014 proposed); ARCHITECTURE/PRD/GDD annotated | Agent 1 |
| 2026-10-31 | Flash's TLF-017 handoff received and stored (`docs/handoffs/TLF-017/`, local paths removed). Its manual checks were scripted synthetic input; the Lead re-verified remap on `main` independently. TLF-017 COMPLETE with deviation; only a physical controller spot-check remains for Milestone 1 | Agent 1 |
| 2026-10-31 | TLF-021 implemented by Opus, merged `5fda100`: RoomRouter (queued transitions, arrival grace, world memory, checkpoint autosave, restore, cross-room relocation), ChapterRoot.tscn, CheckpointZone, SafeAnchor; ADR-018; 118/118 | Agent 1 |
| 2026-10-31 | Lead review of Flash TLF-017 (`19436f9`, after reverting duplicate `431d1c5`): net diff in scope, simulated merge 108/108, merged `c72f272`; manual controller evidence still missing (ISSUE-011); remap single-slot note (ISSUE-010) | Agent 1 |
| 2026-10-31 | TLF-020 implemented by Opus, merged `3740531`: SpatialGraph (transactional re-pairing, critical paths), SpatialService (relocation), DoorwayPresenter, spatial save section, GameSession refs via node paths; 94/94 | Agent 1 |
| 2026-10-31 | TLF-005 re-review passed, merged `e1c0816`; TLF-010 written (Pixelorama CLI verified: export-only, so `.pxo` must pass a CLI open/export check). Flash's revert of `431d1c5` moved to before the TLF-017 push | Agent 1 |
| 2026-10-31 | TLF-019 implemented by Opus, merged `afa6929`: PuzzleService, PuzzleCompletionZone, ResetAnchor, NarrativeState, SaveService (type-tagged JSON, atomic, migrations, validation), IdRegistry.get_ids, watch-focus hook; 82/82, no leaks. Flash's duplicate TLF-008 `431d1c5` reviewed: not merged, keepers ported in TLF-018 | Agent 1 |
| 2026-10-31 | TLF-016 Echo implemented by Opus (`3893b1c` on agent/opus-core), merged `9f55245`: EchoService, TriggerZone, trigger dispatch, null-safe service fallbacks; 67/67; runtime probe with physical trigger replays offsets exactly. TLF-018 extended with Echo controls | Agent 1 |
| 2026-10-31 | Lead review TLF-005 (`636d305`): CHANGES REQUESTED (R1 PZ-004 breaker route too short, R2 door tiles/labels, R3 arithmetic) | Agent 1 |
| 2026-10-31 | TLF-008 temporal core implemented by Opus (`682fb87`), merged `fe3744a`: TemporalComponent, ability delegation, PZ-001/002 spec tests, runner fix (first-frame execution); 51/51. TLF-018 spec written | Agent 1 |
| 2026-10-31 | User master prompt v2 adopted (ADR-017): Opus implements core systems; TLF-008 re-assigned to Opus, Flash gets TLF-017; added PROJECT_STATUS / DEVELOPMENT_ROADMAP / TECHNICAL_DEBT / AGENT_HANDOFF | Agent 1 |
| 2026-10-31 | Re-review passed; merged TLF-007 (`99f6bb3`) and TLF-004 (`eed7c4e`); validate on main 26/26; TLF-005 + TLF-008 dispatched; Echo split out as TLF-016 | Agent 1 |
| 2026-10-31 | Lead review TLF-004 (`52a563a`) + TLF-007 (`864339c`): both CHANGES REQUESTED (small); ADR-006/009 clarifications, ADR-007 am.2 (history commits, freeze toggle), ADR-008 am. (echo scope), new ADR-015 (watch UX/targeting, `echo_reset`) and ADR-016 (completion/reset policy) | Agent 1 |
| 2026-10-31 | Re-review passed; merged TLF-006 (`c1492d8`) and TLF-003 (`db09cc2`); validate on main: import clean, 5/5 tests; README validation section; tag `m0-complete`; TLF-004/TLF-007 dispatched | Agent 1 |
| 2026-10-31 | Lead review of TLF-003 (`33e25d5`) and TLF-006 (`a792438`): both CHANGES REQUESTED; ADR-007 pre-history amendment; ADR-014 accepted (Trace) | Agent 1 |
| 2026-10-31 | Orca role worktrees created; TLF-003 and TLF-006 dispatched; Gemini models confirmed; Pixelorama 1.2.3 pinned; Godot MCP chosen and pinned (ADR-012 amendment) | Human + Agent 1 |

## Update instructions

After every accepted task, record:
- Task ID and summary.
- Agent/owner.
- Files changed.
- Tests run and results.
- Review status.
- Remaining risks or follow-up tasks.

Do not mark work complete based only on generated code or an agent's assertion.


## Pack baseline update (2026-10-30)
- [x] Correct Orca product identified as Onorca Orca IDE.
- [x] Added Windows MCP templates, worktree ownership, task board, bootstrap and QA gates.
- [x] Verify actual installed versions and MCP connections on the user machine (2026-10-31).
- [x] Create Godot project skeleton (TLF-006, 2026-10-31).
- [ ] Complete first vertical-slice milestone.
