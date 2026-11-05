# Orca Task Board — Initial Backlog

## Current status (2026-10-31)

| ID | Status | Note |
|---|---|---|
| TLF-000 | COMPLETE | Repo, relocation, baseline tag `m0-base` |
| TLF-001 | COMPLETE | `docs/TLF-001_AUDIT_REPORT.md` |
| TLF-002 | COMPLETE | `docs/ADR_LOG.md` (ADR-014 accepted 2026-10-31) |
| TLF-003 | COMPLETE | Merged `db09cc2` (re-review of `d5bfba6` passed) |
| TLF-006 | COMPLETE | Merged `c1492d8` (re-review of `846f806` passed; validate on main 5/5) |
| TLF-004 | COMPLETE | Merged `eed7c4e` (re-review of `75dcb95` passed) |
| TLF-007 | COMPLETE | Merged `99f6bb3` (re-review of `1801ed0` passed; validate on main 26/26) |
| TLF-005 | COMPLETE | Merged `e1c0816` (re-review of `41190e7`: PZ-004 forced route 318 ticks recomputed, boundary doors, arithmetic) |
| TLF-008 | COMPLETE | Opus temporal core merged `fe3744a` (validate 51/51; TestRoom regression probe OK) |
| TLF-017 | COMPLETE (with noted deviation) | Merged `c72f272`. Evidence: `docs/handoffs/TLF-017/` (scripted synthetic controller + remap run) + Lead's independent remap probe on `main`. Deviation: no physical controller used, so a human spot-check is outstanding (ISSUE-011) |
| TLF-018 | COMPLETE | Merged `7fb8aec` (Flash): pocket watch, HUD feedback, Elias SpriteFrames (`7dafc5a`), translations + SaveService autoload; ui_feedback translation committed `4476e0e` |
| TLF-020 | COMPLETE | Opus SpatialGraph + SpatialService + DoorwayPresenter merged `3740531` (94/94; physics doorway probe) |
| TLF-021 | COMPLETE | Opus RoomRouter + ChapterRoot + world memory merged `5fda100` (118/118, mutation-checked, physics probe). Was: room router (scene loading per room, doorway spawn placement, checkpoints → SaveService), Echo stop on room change |
| TLF-019 | COMPLETE | Opus PuzzleService + SaveService + NarrativeState merged `afa6929` (82/82, no leaks; real-scene save probe OK). Autoload registration → TLF-018 |
| TLF-016 | COMPLETE | Opus EchoService + TriggerZone merged `9f55245` (validate 67/67; physics runtime probe OK) |
| TLF-023 | COMPLETE | Opus Ch1 puzzle objects merged `e6de2b4`: all 27 spec tests + 10 extra, mutation-checked; 166/166 |
| TLF-029 | COMPLETE (runner) | Merged `2eb5272` (Opus impl): awaitable frame-stepping tests + 6 self-tests. Follow-up TLF-030: real-input Ch1 playthrough test |
| TLF-030 | COMPLETE | Merged `0ddf131` (Opus impl): real-input playthrough PZ-001…003, ~524 physics frames |
| TLF-040 | COMPLETE | Merged `98f3304` (Flash `830a3e7`): project theme `tlf_ui_theme.tres` (UITheme), TLF Pixel Mono, sizes 8/16/24, text_scale ×2 live, bible panel styles, confirm glyph "[Enter]". Lead fresh archive 97 scripts, 278/278, leak clean; handoff output genuine. Follow-up: silent font fallback → TLF-043 B |
| TLF-041 | COMPLETE | Merged `e6e9ee9` (Flash `2067abe`): all 10 rooms on art batches 2+3, read-only puzzle-prop presenters, 41 `.png.import` (no mipmaps). tlf-lead independent collision dump: 325 lines per side, only diff = ADR-019 intercom (352,160)->(528,154). Lead fresh archive 112 scripts, 291/291, RISK-018 negative test PASS. Follow-up TLF-046 (barrier visual) |
| TLF-045 | COMPLETE | Merged `283e9dc` (design-art `b66dd43`): generators read `tools/art/gen/placement_snapshot_ch01.json` (from `0be1959`), no scene reads; Lead: `verify_regen.py` ALL REPRODUCIBLE, `check_assets.py` 57 PASS on the merged archive. Optional scene-drift diagnostic offered as a separate tool (not taken yet) |
| TLF-047 | COMPLETE | Phase 1 merged `e038e45`. Phase 2 merged `15ecf28` (design `d009748`): specs SO-01, SO-02, PZ-006, R1 revisions of PZ-001..005 (PZ-002 inner shutter), `TRACE_MEMORY.md`, `ABILITY_UNLOCKS.md`, 13 commuters, beat sheet §7 (Step 1 = 28.7 min design / 17.2 floor), ROOM_GRAPH deltas, art wish list, text. tlf-lead: `ch01_text.csv` byte-identical to generator output, 209 keys ASCII. Puzzle data not generated (generator hard-codes 5; patch -> TLF-054). Lead decisions in ADR-020 am. "phase 2" |
| TLF-048 | COMPLETE | Merged `6a5607d` (Opus impl `dbede51`): PlaytestLog (room/puzzle ticks, resets, hints, failures by reason, pauses separate), save v2 + migration, summary on chapter complete, JSON under `user://playtest/` (headless: `user://headless/playtest/`), flag `tlf/playtest_log` (debug on). InteractionService gained an additive `interaction_failed` signal (ADR-006 signature/order unchanged). Lead fresh archive 114 scripts, 300/300, JSON only under headless. Follow-up TLF-051 (overlay) |
| TLF-049 | DONE, RED by design (not merged) | Opus `a28fe63` on `agent/opus-core-pz002neg` (keep the branch): main + branch -> 300 passed, 2 failed: PZ-002 solved 26 ticks after the Rewind without Freeze (window 180; assisted 300). RISK-020 confirmed. Merged together with the fix in TLF-056, where it must pass unchanged |
| TLF-050 | COMPLETE | Merged `cf12b23` (Opus `4a550aa`): `TraceMemory` (on `_on_traced`, non-blocking lines, flag + journal on first trace, `traced.<id>` flag), `AbilityUnlocks` session service, `AbilityUnlockTrigger` (flag / pickup / SOLVED), PocketWatch refuses locked abilities (`ability_locked`, `UI_FB_ABILITY_LOCKED`), save v3 + v2->v3 migration (all four). `GameSession.starting_abilities` empty = old four (game unchanged until TLF-055) |
| TLF-051 | COMPLETE | Merged `87ea19d` (Flash `70faec8`): `chapter_complete_overlay.tscn` (HeaderLarge/HeaderMedium, summary 8 px in a themed scrolling panel, 12 px margins). tlf-lead windowed screenshot: centred, inside the screen. Leftover: HUD "Move: [WASD]" shows through the overlay (ISSUE-041 -> TLF-052). Handoff log was condensed, not raw (ISSUE-028 again) |
| TLF-052 | READY | Flash: `docs/tasks/TLF-052.md` (ability wheel per ADR-021: hold Z / LT, aim with keys/mouse/stick, release selects, toggle-mode setting, locked slots, SimClock paused). TLF-050 + TLF-053 art merged. Extra: ISSUE-041 (hide the HUD movement hint under the chapter-complete overlay) |
| TLF-053 | COMPLETE | Merged `f432bca` (design-art `169024c`): `assets/ui/ability_wheel/` (face, bead pointers 0-5 + rest, 6 segments x normal/selected/locked, 12 icons 16x16 incl. locked, lock glyph), generator `ui_wheel.py`, mockups + greyscale proof. tlf-lead: Pixelorama re-export 39/39 pixel-identical, `verify_regen` ALL REPRODUCIBLE, `check_assets` 99 PASS. Bead pointer instead of a rotated needle (accepted) |
| TLF-054 | READY | Opus impl: `docs/tasks/TLF-054.md` (Step 1 puzzle logic per §8.4 ledger + R1 deltas, spec tests, puzzle data generator patch) |
| TLF-055 | BLOCKED (TLF-052, TLF-054) | Flash: `docs/tasks/TLF-055.md` (Step 1 rooms: new objects/colliders, TraceMemory nodes, 13 commuters, unlock triggers, Chapter 1 starts with Trace, unlock feedback) |
| TLF-056 | BLOCKED (TLF-055) | Opus impl: `docs/tasks/TLF-056.md` (real-input playthrough with progressive unlocks + negative test per Step 1 puzzle; TLF-049 merged and green) |
| TLF-057 | COMPLETE | Merged `efed5ab` (Argon `efa0701` + fixes `e4e111b`; Sol visual review `cdb80d6`/`d3098d3`/`cbd9780`: APPROVE for `e4e111b`): 13 assembled commuters (idle + read), Trace shimmer, Step 1 puzzle props, generator `step1_statues.py`. Lead re-check on the `efed5ab` archive: validate 314/314, leak clean; `check_assets` ALL PASS (234); `verify_regen` ALL REPRODUCIBLE. Art only (no scenes/scripts). Open for TLF-055: `dead_relay_c` sorting layer (prose says Wall_Fixtures z7, rows 225-226 say YSort_Actors z10) |
| TLF-058 | BLOCKED (TLF-055) | Flash: `docs/tasks/TLF-058.md` (Operator sighting at the far end of the Arrival Platform, once, saved; ADR-022 D3) |
| TLF-059 | BLOCKED (TLF-055) | Flash: `docs/tasks/TLF-059.md` (Beat 10 cinematic: frozen city, silent Mira image, "You are late." / "Again."; skippable) |
| TLF-060 | READY | Flash: `docs/tasks/TLF-060.md` (export preset + Windows smoke test from a renamed scratch copy; Linux if templates exist) |
| TLF-061 | READY | **Sol**: `docs/tasks/TLF-061.md` (direction note from the owner's references: Elias v3 proposal, Operator per ADR-022 A4, Mira, hourglass, Ch1 palette, props list) |
| TLF-062 | BLOCKED (TLF-061, after TLF-057) | Argon (fallback Sol): `docs/tasks/TLF-062.md` (Operator sighting sprite + Beat 10 city plate) |
| TLF-063 | BLOCKED (TLF-061, after TLF-057) | Argon → Flash: `docs/tasks/TLF-063.md` (environmental props: NOWHERE 23:59 board, A1 → Research, R&D Access, Sector A, closed track) |
| TLF-064 | READY (after TLF-052) | Flash: `docs/tasks/TLF-064.md` (basic audio pass from a reproducible SFX generator + Operator motif) |
| TLF-046 | COMPLETE | Merged `21d892b` (Flash `6f7a63d`): barrier visual = collision ∩ floor (palette-styled wedge, z 6), collision unchanged (tlf-lead fingerprint identical; test asserts exact polygon); capacitor `frozen_charged/discharged`; `pocket_watch.is_targetable` delegates to `Player.is_targetable` |
| TLF-044 | COMPLETE | Merged `2717059` (design-art `756d294`): capacitor `_frozen_charged`/`_frozen_discharged`. `check_assets.py` 57 PASS. `verify_regen.py` breaks on the integrated scenes (KeyError Clock) -> TLF-045 |
| TLF-043 | COMPLETE | Merged `c38520d` (Flash `6575818`): `is_targetable` (use not unsupported or any watch ability) in player + watch selection, checkpoint no longer targeted at spawn; UITheme always sets styles, warns once without the font. tlf-lead behavioural red: 5 failures on old main incl. spawn target |
| TLF-042 | COMPLETE | Merged `0be1959` (design-art Sonnet 5.5, `40491c4`): route board, security gate, bridge, transit car, dispatch terminal, pocket watch, lever badges, PA speaker, 15 generators in `tools/art/gen/`. tlf-lead 51/51 `.pxo` pixel-identical; Lead ran `verify_regen.py` (ALL REPRODUCIBLE vs committed files; 9 batch-1 Argon files not covered) and `check_assets.py` (55 PASS). Findings decided in ADR-019 am. 2026-11-01 |
| TLF-039 | COMPLETE | Merged `34d95be` (design-art Sonnet 5.5, `6c07b4c`): Elias v2 (layout-compatible), 14 kit pieces, 5 tier-2 puzzle props, placement sheet (10 rooms), 3 mockups, `tools/art/check_assets.py`. tlf-lead: 37/37 `.pxo` re-exports pixel-identical. Lead: own palette/alpha check 40/40, Pixelorama spot check 3/3 pixel-identical, fresh archive 95/273, leak clean. Open questions decided in ADR-019 |
| TLF-038 | COMPLETE | Merged `756368a` (Flash `2281538`): Beat 01 non-blocking + auto-advance, centred pulsing continue cue (static with reduced_effects), movement hint once per save, non-blocking dialogue leaves `interact` to the world, HUD marker via canvas transform, `UI_FB_USE_UNSUPPORTED`, watch-only prompt. Handoff validate output genuine (ISSUE-028 improving). Lead red check: marker test fails with the old `hud.gd` line |
| TLF-037 | COMPLETE | Merged `2ba788b` (Opus impl `6395b56`): SceneRouter autoload, Boot → title (New Game / Continue / Quit, overwrite confirm), Chapter01 restore hook, chapter complete → confirm → title. CSV conflict with TLF-038 resolved as union; `.translation` regenerated, 53/53 keys checked. Lead fresh archive 95 scripts, 273/273, leak check clean |
| TLF-036 | COMPLETE | Merged `e6fa5f1` (Opus impl `19e06d9`): SaveStore + Settings resolve to `user://headless/` when headless (env override `TLF_ALLOW_REAL_USER_DATA=1`); old tests no longer reset `settings_path` to the real file. Lead fresh archive 91 scripts, 255/255, leak check clean, startup lines show the headless roots |
| TLF-035 | COMPLETE | Merged `6559aba` (Opus impl `ae73b5d`): leak gate in validate.ps1 (script check + test suite, `--verbose` rerun on failure) + `tools/validate_selftest/` 6/6. Lead fresh archive 89/242 "Leak check: clean"; independent Lead red check (orphan Area2D + shape: RID + ObjectDB leak → exit 1) |
| TLF-034 | COMPLETE | Merged `7bc0ea9` (Flash `8ce4bc7`): `Player.set_input_blocked` + `Player.set_player_blocked` (one lookup), interact swallowed on the unblock frame +1; barrier visual = collision. tlf-lead red check: 3 new tests fail on main code. **Handoff validate output was not genuine (ISSUE-028)** |
| TLF-033 | COMPLETE | Merged `66677d9` (Flash `73df531`): PZ-004 layout, railing reach sealed, exit trigger spans the north approach, geometric route + reach tests on real scene colliders. Opus negative real-input test green (no-Echo attempt 411 ticks > 180 window) |
| TLF-032 | COMPLETE | Merged (Flash `dcdb67e`): dialogue box, document viewer, journal, hint (H + joypad 10), Ch1 Beat wiring. Lead spec review item by item + runtime probes |
| TLF-031 | COMPLETE | Merged `0c0006f` (Opus impl `e60cf3f`): real-input playthrough rooms 5–10 incl. PZ-004 with Echo, dismisses TLF-032 dialogue, robust `tap()`/walk helpers. RISK-018 negative test merged `3df2583` (`1bebf50`) |
| TLF-025 | COMPLETE | Merged `a39be53` (Flash): rooms 5–10, PZ-004/005, Beat 09/10, intercom journal hook. Lead real-input probe: PZ-005 levers → atrium → terminal → outro (`chapter_complete`) |
| TLF-028 | COMPLETE | Merged `2eb5272` (Opus impl): validate.ps1 robust on PowerShell 5.1; fresh clone validates on first run |
| TLF-027 | COMPLETE | Opus impl agent `aafb2bb`, merged: class `SaveStore`, autoload name `SaveService`; verified 180/180 with and without the autoload; router adopts the autoload. **TLF-018 R2b unblocked** |
| TLF-026 | COMPLETE | Opus: Ch1 graph as `ChapterGraphDef` (`data/chapters/ch01/ch01_graph.tres`) generated from ROOM_GRAPH + PZ-005; 9 tests, mutation-checked; 180/180 |
| TLF-024b | IN PROGRESS | Design worktree agent (now Opus): port improvements from `eecb822` into main's `CH01_TEXT.md` (main's keys, SPK_* labels); `eecb822` itself not merged (add/add conflict). Lead reviews + approves new IDs, then re-runs `gen_ch01_text.py` |
| TLF-024 | COMPLETE (first pass) | Opus (re-assigned; Argon at usage limit): 66 keys in `narrative/ch01/CH01_TEXT.md` → CSV + 5 DocumentDefs via `tools/content/gen_ch01_text.py`; 171/171. Open for Argon's narrative review |
| TLF-009 | COMPLETE | Merged `7fb8aec` (Flash): Ch1 rooms 1–4 playable; R1 autosave isolation verified; Lead real-input probe rooms 1→3 + PZ-001 |
| TLF-022 | COMPLETE | Opus HintService + PuzzleDef (5 Ch1 defs + CSV generated from specs) + DocumentDef/ReadableDocument + journal merged `440a5be` (129/129) |
| TLF-010 | COMPLETE | Merged (Argon `68e299f`): all 10 `.pxo` pass the Pixelorama CLI open/export check; PNGs byte-identical to the re-exports; palette-only; 0 semi-alpha. Art polish notes → ISSUE-012 |
| others | NOT STARTED | |

Branch naming and merge flow: ADR-002 (incl. Orca naming amendment).

Use this as the initial task list. Each task must run in its assigned worktree. Agent 1 controls dependencies and integration.

| ID | Task | Owner | Depends on | Deliverable / acceptance |
|---|---|---|---|---|
| TLF-001 | Audit repo and existing docs | Opus | None | Inventory, gaps, risk list; no destructive edits |
| TLF-002 | Lock core architecture and conventions | Opus | 001 | ADRs, folder structure, naming and data contracts approved |
| TLF-003 | Define Chapter 1 narrative beats | Argon | 001 | Beat sheet with objective, reveal, emotional turn and exit hook |
| TLF-004 | Design five vertical-slice puzzles | Argon | 002, 003 | Puzzle specs with logic, clues, solution, hint ladder and recovery |
| TLF-005 | Define station room graph and puzzle flow | Argon | 002, 003 | Room graph, critical path, optional routes, spatial logic |
| TLF-006 | Build Godot project skeleton | Flash | 002 | Opens in Godot 4.x without errors; README run instructions |
| TLF-007 | Implement player movement + interaction | Flash | 006 | Keyboard/controller movement, deterministic interact targeting, tests |
| TLF-008 | Implement temporal state framework | Flash | 006, 002 | Stable IDs, serializable state, deterministic event replay tests |
| TLF-009 | Implement first temporal puzzle (re-scoped: Ch1 rooms 1–4, see docs/tasks/TLF-009.md) | Flash | 018, 021, 023 | Rooms 1–4 playable with PZ-001…003 |
| TLF-010 | Create visual target sheet + sprite kit | Argon | 003 | Pixelorama (.pxo) sources, export PNGs, palette and scale spec |
| TLF-011 | Import assets and create first room | Flash | 005, 010 | Room loads, collision/nav/anchors align, visual review passed |
| TLF-012 | Vertical slice integration | Opus | 007–011 | 30–45 min target slice flow, no critical blockers |
| TLF-013 | Playtest and regression | Flash | 012 | Test report, repro steps, severity and fixes |
| TLF-014 | Narrative polish and cinematic | Argon | 012 | Scripted sequence, dialogue and asset list |
| TLF-015 | Release candidate review | Opus | 013, 014 | Build checklist, known issues, go/no-go decision |

## Task handoff format

Every assignment must state:

- **Objective:** one measurable outcome.
- **Context:** relevant docs and existing implementation.
- **Dependencies:** task IDs and approved interfaces.
- **Allowed files:** exact paths or folder ownership.
- **Forbidden files:** files another agent owns or shared critical files.
- **Acceptance criteria:** observable pass/fail conditions.
- **Tests:** exact commands or manual test steps.
- **Deliverables:** code/assets/docs/report.
- **Stop conditions:** missing requirements, conflicting interfaces, destructive action, or scope expansion.

## Status definitions

`NOT STARTED` → `IN PROGRESS` → `BLOCKED` or `IMPLEMENTED` → `TESTED` → `REVIEW REQUIRED` → `COMPLETE`.

Only Agent 1 may mark a cross-agent task `COMPLETE` after review. An agent must not claim a task is complete because code was merely generated.
