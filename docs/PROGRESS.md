# Project Progress

**Last updated:** 2026-10-31  
**Current milestone:** Milestone 1 — Isometric foundation  
**Overall status:** Milestone 0 complete. Ch1 beat sheet approved. No gameplay implemented yet.

## Milestone status

| Milestone | Status | Notes |
|---|---|---|
| 0 — Project setup | COMPLETE | Tag `m0-complete`: repo, ADRs, folder structure, input map, pixel-art display, headless validation (5/5) documented in README |
| 1 — Isometric foundation | IN PROGRESS (exit criteria met except one item) | Movement, collision, interaction, settings and remapping are merged and verified. Remaining: a physical controller spot-check by a human (ISSUE-011) |
| 2 — Temporal prototype | COMPLETE | Exit criteria met: unit tests for state transitions, echo holds a switch while the player acts (tests + playable PZ-003), invalid targets fail gracefully; pocket watch + HUD merged (TLF-018) |
| 3 — Spatial prototype | COMPLETE | Graph validation tests pass; PZ-005 doorway reassignment works in play (real-input probe), presenters derive from the graph, relocation from the sealed niche. Room rotation remains Ch3 scope |
| 4 — Puzzle/narrative framework | IN PROGRESS | Data-driven puzzles (5 Ch1 puzzles from PuzzleDefs + reusable classes), save/load of checkpoint + progression, hints, documents, journal data: done. Pending: dialogue/document/journal **presentation UI** |
| 5 — Chapter 1 vertical slice | IN PROGRESS | Whole path playable in greybox (rooms 1–10, PZ-001…005, revelation, outro). Missing for Gate C: art/audio/VFX pass, dialogue/journal UI, cinematic, accessibility pass, external playtest |
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
  - Gemini 4 Argon — puzzle/narrative/design specialist (unavailable since 2026-10-31; design-art worktree covered by Claude Code on Sonnet 5.5, RISK-019).
  - Gemini 3.8 Flash High — implementation/QA.

## Work log

| Date | Change | Owner |
|---|---|---|
| Initial | Project documentation baseline created | Project team |
| 2026-10-31 | TLF-001 audit (`docs/TLF-001_AUDIT_REPORT.md`) | Agent 1 |
| 2026-10-31 | Git repo initialised, pack relocated to root, baseline `4297a5a` tagged `m0-base`, pushed to GitHub | Human + Agent 1 |
| 2026-10-31 | TLF-002: `docs/ADR_LOG.md` (SD-1, ADR-001…013 accepted, ADR-014 proposed); ARCHITECTURE/PRD/GDD annotated | Agent 1 |
| 2026-11-01 | User direction: develop the story, start with one ability, richer world/environment, NPCs around, more puzzles. ADR-020 amendment: progressive unlock on `PocketWatch.unlocked_abilities`, frozen commuters (23:59) as NPCs + optional 1-2 interactive, story of each room, sub-beats around the 10 core beats; TLF-047 widened accordingly | Agent 1 |
| 2026-11-01 | User playtest #2 (F5, art build `36f54de`): no bugs; two-ability combos called "a perfect mechanic"; chapter feels very short (ISSUE-038). ADR-020: deepen the combo core (+3 main combo puzzles, 3 optional fragment side puzzles, max 2 second stages, FF at most once), measure with telemetry. TLF-047 (design concepts, Sonnet) and TLF-048 (telemetry, Opus impl) written | Agent 1 |
| 2026-11-01 | Merged TLF-046 (`21d892b`, Flash) and TLF-045 (`283e9dc`, design-art). Lead review: barrier visual equals collision ∩ scene floor polygon (corner points on the floor edge checked), collision asserted exact; dedupe is a pure delegation. Fresh archive 112 scripts, 291/291, leak clean, RISK-018 negative PASS; `verify_regen` ALL REPRODUCIBLE, `check_assets` 57 PASS, no scene reads in `tools/art/gen`. Two editor-generated untracked `.import` files blocked the merge again; moved to `editor_import_backup_0742`. Flash's Orca session has exited (restart needed for its next task) | Agent 1 |
| 2026-11-01 | Merged TLF-041 (`e6e9ee9`, Flash) and TLF-044 (`2717059`, design-art). **All 10 Ch1 rooms now use the art kit.** Lead: scope check both, presenters read-only (no state writes), 41 `.import` without mipmaps; tlf-lead's independent collision dump (only the ADR-019 intercom differs). Fresh archive 112 scripts, 291/291, leak clean, RISK-018 negative PASS; `check_assets` 57 PASS; `verify_regen` KeyError Clock reproduced (ISSUE-036 -> TLF-045). Barrier visual below floor (ISSUE-037 -> TLF-046). The user's editor had generated 41 untracked `.png.import` files (27 differing only in UID) that blocked the merge; moved (not deleted) to the Lead scratchpad `editor_import_backup_0112` | Agent 1 |
| 2026-11-01 | Merged TLF-043 (`c38520d`, Flash) and TLF-042 (`0be1959`, design-art). Lead review: targeting filter correct and narrow (blocked-but-supported stays targetable); notes: `is_targetable` duplicated in player/pocket_watch, editor previews skip the font (`is_editor_hint`). Lead ran `verify_regen.py` on the archive (compares regenerated output to committed files: ALL REPRODUCIBLE) and `check_assets.py` (55 PASS). Fresh archive 99 scripts, 285/285, leak clean. ADR-019 am.: capacitor frozen split (TLF-044), terminal `_active` on `ledger_2359_revealed`, gear `_frozen`=`locked`, transit-car pivot. TLF-041 widened to batches 2+3. Editor re-save of `project.godot` in the primary checkout again (left untouched; merges did not touch it) | Agent 1 |
| 2026-10-31 | Merged TLF-040 (`98f3304`, Flash): pixel-font UI theme, confirm glyph; ISSUE-004/033 resolved. Lead review: theme early-return is wider than reported (styles and sizes also skipped) → ISSUE-035. Fresh archive 97 scripts, 278/278, leak clean. Primary checkout had editor re-saves of `README.md`/`project.godot` (23:37, semantically equal: default values dropped, sections reordered) plus untracked art `.import` files; the two files were `git stash`ed (`stash@{0}`, recoverable), the `.import` files left untouched. tlf-lead found the checkpoint targeted at spawn (ISSUE-034); root cause `pocket_watch.gd:150` → TLF-043 before TLF-041 | Agent 1 |
| 2026-10-31 | Merged TLF-039 art batch 2 (`34d95be`, design-art Sonnet 5.5). Lead verification: own palette/alpha check 40/40 clean (palette file unchanged), Pixelorama re-export spot check 3/3 pixel-identical (note: Pixelorama 1.2.3 writes `<name>.png` next to the `.pxo` and ignores the `--output` filename), mockups and Elias sheet viewed, fresh archive 95 scripts / 273 tests / leak clean. ADR-019 decides the 10 open questions (sorting, frozen collision, intercom + clocks move, no rails rooms 1/5, no pedestal, palette idx 03, committed generators). TLF-041 (Flash integration) and TLF-042 (art batch 3) written | Agent 1 |
| 2026-10-31 | TLF-040 written for Flash (user OK): project-wide pixel-font theme, sizes 8/16/24 per ART_BIBLE §8, integer text_scale mapping (×2 at ≥ 1.5), confirm glyph from the first key binding. TLF-039 tier-2 reference no longer names a task number | Agent 1 |
| 2026-10-31 | Merged TLF-038 (`756368a`, Flash) and TLF-037 (`2ba788b`, Opus impl). **F5 now plays: Boot → title → Chapter 1, Continue restores the checkpoint.** CSV conflict resolved as union (54 lines), `.translation` regenerated and checked key by key (53/53). Lead fresh archive: 95 scripts, 273/273, leak check clean ×2; red check: Flash's marker test fails with the old `hud.gd` line. Real save changed 22:32:59 during a **windowed** run of the real project (log 22:32:28, D3D12; the user's play), not by Lead runs (headless, renamed copies). Follow-ups: ISSUE-033 confirm glyph, ISSUE-004 pixel font in HUD/dialogue | Agent 1 |
| 2026-10-31 | User decision via tlf-lead: design-art worktree reactivated with Claude Code (Sonnet 5.5) until Argon returns; RISK-019 mitigated. TLF-039 written (art batch 2: Elias walk fix with layout-compatible sheet, remaining §7 kit pieces, placement sheet for Flash; hero set-pieces as tier 2). New branch `adityadaffa522/tlf-art-batch2` from origin/main because the old design branch carries obsolete ISSUE-014 commits | Agent 1 |
| 2026-10-31 | Merged TLF-034 (`7bc0ea9`, Flash) and TLF-036 (`e6fa5f1`, Opus impl). Lead review read all new test logic (real `tap()` input, `opened` signal count, use_count, "next press still works" step; headless guard unit + autoload tests). Lead fresh archive (renamed config/name): 91 scripts, 255/255, leak check clean ×2; startup lines show `user://headless/` roots. Real save folder hashed only (user is playing: slot_0 changed 17:56 by the user). ISSUE-028: Flash TLF-034 validate output not genuine. First user playtest (via tlf-lead): stuck at Beat 01, floating cyan marker, wrong `use` feedback, F6 overwrites save → TLF-038 (Flash), ISSUE-032 → TLF-037 | Agent 1 |
| 2026-10-31 | Merged TLF-035 (`6559aba`, Opus impl `ae73b5d`): validate.ps1 fails on leaks at exit. Review read the self-test assertion logic (exit code **and** expected lines). Lead fresh archive (renamed config/name): 89 scripts, 242/242, "Leak check: clean" ×2; independent red check with a different leak (orphan Area2D + CircleShape2D → RID + ObjectDB leak, exit 1). Real save folder (user's own F6 save, 17:39) listed read-only, unchanged | Agent 1 |
| 2026-10-31 | tlf-lead: the real-folder `slot_0.json` came from Flash's hung headless probes (not a sentinel, not the user's); removed by tlf-lead with the user's OK (ISSUE-026). The user can't start the game with F5 (ISSUE-027). ADR-011 amendments: headless runs redirect to `user://headless/`; `SceneRouter` autoload for menu ↔ chapter. TLF-036 + TLF-037 written for Opus impl; TLF-034 (Flash) and TLF-035 (Opus) relayed and started | Agent 1 |
| 2026-10-31 | Merged TLF-031 (`0c0006f`, Opus impl), TLF-033 (`66677d9`, Flash) and the RISK-018 negative test (`3df2583`); main tree == verified fresh tree (89 scripts, 242/242, no leaks). **RISK-018 closed**: no-Echo attempt red on old layout (173 ticks), green on new (411 > 180). Review read Flash's geometric test logic: it uses the real scene colliders (ISSUE-021 rule). New: TLF-034 (Flash: interact reopen bug ISSUE-023, barrier visual ISSUE-024), TLF-035 (Opus: leak gate ISSUE-025) | Agent 1 |
| 2026-10-31 | TLF-032 merged after item-by-item spec review + runtime probes (Beat 09 close order OK, journal blocked during monologue, tlf-lead's LB conflict claim refuted: journal = BACK/4, ability_prev = D-pad/13). 87 scripts, 236/236. TLF-031 changes requested (dialogue dismiss, tap() fix). RISK-018 re-opened (ISSUE-021: Lead review gap) → TLF-033 for Flash. ISSUE-022: Lead probe wrote a real autosave (removed) | Agent 1 |
| 2026-10-31 | Audit for Milestone 4: story text is never shown (ISSUE-019); TLF-018 hint button missing, missed in Lead review (ISSUE-020). TLF-032 written for Flash (dialogue/document/journal UI, hint, Beat wiring) | Agent 1 |
| 2026-10-31 | Merged Flash TLF-025 (`a39be53`) and Opus TLF-030 (`0ddf131`); main tree == verified combined tree (fresh archive 78 scripts, 216/216). **Chapter 1 playable start to finish (greybox).** Lead real-input probe rooms 7–10: PZ-005 levers, atrium terminal (Beat 09), outro → chapter_complete; test save root, real saves untouched. PZ-004 real-input → TLF-031. ISSUE-018 repro recorded (2/15). Process note: Flash handoffs must paste raw validate output, not a paraphrase | Agent 1 |
| 2026-10-31 | tlf-lead confirmed origin/main == verified tree (fresh archive 209/209); TLF-025 → Flash, TLF-030 → Opus impl relayed. ISSUE-018 recorded (intermittent 0xC0000005 during fresh CSV import, not reproduced) | Agent 1 |
| 2026-10-31 | Integrated Flash TLF-018 + TLF-009 (`7fb8aec`) and Opus TLF-028 + TLF-029 (`2eb5272`); committed ui_feedback translation (`4476e0e`). Independent check: fresh clone without the file fails as reported, with it passes on first run (76 scripts, 209/209, no leaks); real user://saves untouched. Ch1 rooms 1–4 playable on main. (Docs commit `100aab2` was partial; completed in the next commit.) | Agent 1 |
| 2026-10-31 | Lead review TLF-009 (`b157fd4`): approved with pre-merge fix R1 (tests wrote the real autosave; artifact removed). Real-input probe: Chapter01 rooms 1→3, PZ-001 via pocket watch, checkpoint autosave. TLF-029 (frame-stepping tests) added. ISSUE-017 recorded (agent takeover attempt; main history clean) | Agent 1 |
| 2026-10-31 | Squash-merged design-art `689e169` (TLF-024b: SPK_* labels, pa_speaker/intercom IDs approved, JRN_CH1_OPERATOR_WARNING) keeping `eecb822` out of history. Reviewed Flash TLF-018 fixes (R1/R2b/R4/R5 OK, 194/194 on merge result, SpriteFrames verified); found fresh-clone failure (ISSUE-015): translations now committed (ADR-013 corrected), `validate.ps1` hardening → TLF-028. TLF-018 merge waits for Flash's ch01_text translation registration | Agent 1 |
| 2026-10-31 | Merged `64f7be8` alone (ART_BIBLE light convention + flip_h trade-offs, docs-only); `eecb822` still excluded | Agent 1 |
| 2026-10-31 | TLF-027 (Opus impl agent `aafb2bb`) reviewed and merged: SaveStore class + SaveService autoload verified with/without autoload; ADR-011 note; TLF-018 R2b unblocked for Flash | Agent 1 |
| 2026-10-31 | TLF-024 duplicate (`eecb822`) not merged; port-into-main decisions recorded (ADR-013 am.: SPK_* labels, SPK_OPERATOR="VOICE", BODY_1..N pages, UI_FB_* only for reasons) | Agent 1 |
| 2026-10-31 | Roles split: a dedicated Opus implementation agent now owns `wt-opus-core`; this session = Lead (review/integration). ISSUE-013 (class/autoload name clash) reproduced and routed as TLF-027 | Agent 1 |
| 2026-10-31 | TLF-026 by Opus, merged: Ch1 ChapterGraphDef generated from the reviewed design docs (10 rooms, 20 doorways), layout checks as tests; TLF-009 now loads it instead of hand-building; 180/180 | Agent 1 |
| 2026-10-31 | TLF-024 written by Opus (Argon unavailable), merged: Ch1 text (66 keys), 5 DocumentDefs, generators moved to `tools/content/`; ASCII-only text rule; 171/171 | Agent 1 |
| 2026-10-31 | Lead review TLF-018 (Flash `6332fb6`): simulated merge 178/178, runtime probe through real input OK (rewind gate/shutter, Freeze auto-targets gear); CHANGES REQUESTED: ghost node leak + root parenting, missing SaveService autoload/translations. Argon hit usage limit → TLF-024 re-assigned to Opus | Agent 1 |
| 2026-10-31 | TLF-023 implemented by Opus, merged `e6de2b4`: PuzzleObject base + 12 Ch1 puzzle classes; all 27 spec acceptance tests pass against production code; breaker window fixed to absolute ticks (echo == player); mutation-checked; 166/166. TLF-024 (Argon) and TLF-009 (Flash) specs written | Agent 1 |
| 2026-10-31 | TLF-022 implemented by Opus, merged `440a5be`: HintService (cooldown-gated 3-level ladder), PuzzleDef + Ch1 defs/CSV generated from specs, DocumentDef/ReadableDocument, journal categories; save sections journal/hints; 129/129 | Agent 1 |
| 2026-10-31 | Lead review TLF-010 (Argon `68e299f`): every `.pxo` verified via Pixelorama CLI, PNGs byte-identical to the re-exports, palette/alpha clean, 8 directions + exact mirrors verified; merged. Integration: asset `.import` files committed, pixel-font import fixed (no AA), `docs/` and `assets/source/` given `.gdignore` | Agent 1 |
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
