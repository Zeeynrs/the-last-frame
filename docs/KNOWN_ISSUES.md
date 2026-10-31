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
| RISK-013 | Pixelorama version unpinned; `.pxo` format may change between versions | Low | Resolved 2026-10-31 | Human | Pinned to 1.2.3; all `.pxo` work uses this version |
| RISK-014 | Gemini model labels (Argon/Flash) unverified | Medium | Resolved 2026-10-31 | Human | User confirmed both models are available |
| ISSUE-001 | Docs specify Godot AI Workbench; it is not installed and a different `godot` MCP server is connected | Low | Resolved 2026-10-31 | Agent 1 | Adopted `@coding-solo/godot-mcp` 0.1.1 (ADR-012 amendment) |
| ISSUE-002 | godot-mcp `get_uid` only reads `<file>.uid` sidecars; for imported assets (e.g. `icon.svg`) it reports "does not exist" and suggests `resave_resources`, but the UID actually lives in `<file>.import` | Low | Open (workaround) | Agent 1 | Don't run resave on that message. Read the UID from the `.import` file instead |
| RISK-015 | Godot MCP launched via unpinned `npx` would auto-run any newly published version | Medium | Resolved 2026-10-31 | Agent 1 | Pinned to `@0.1.1` |
| ISSUE-003 | 2026-10-31: agents used the Lead's primary checkout (created `tlf-003-…`/`tlf-006-…` branches, stray stub files); a Lead commit landed on an agent branch; during cleanup Lead briefly deleted a branch holding TLF-003 work (restored within ~1 min, also present on the Orca branch) | High | Resolved | Agent 1 | Workspace rule added to task files/template (ADR-002 amendment). Lead never deletes a branch without first checking its tip against the last observed SHA |
| ISSUE-004 | Boot/UI text uses Godot's default anti-aliased font, not a pixel font, so it looks soft at ×3 | Low | Open | Argon / Flash | Pixel font in TLF-010 art target sheet, then a UI theme task |
| ISSUE-005 | `pause` is P / Start only; Escape is `cancel`. Players often expect Esc to pause | Low | Open | Flash (menu task) | Pause menu logic: Esc with nothing to cancel opens pause (in code, not a shared binding) |
| ISSUE-006 | Player discards `InteractionResult`; failed interactions give no feedback | Medium | Resolved 2026-10-31 | Flash (HUD/feedback task) | Show `reason` via `tr()` feedback keys from `design/ch01/puzzles/README.md` |
| ISSUE-007 | Interaction prompt text hard-codes "[E]", English-only, no controller glyph | Low | Resolved 2026-10-31 | Flash (UI task) | `tr()` key + input-glyph lookup per active device |
| RISK-017 | PZ-002 180-tick window may be tight even with ADR-015 auto-targeting | Medium | Open | Argon / Flash | Playtest in TLF-009; assist setting extends to 300 ticks |
| RISK-018 | PZ-004 breaker sync puzzle can be solved without Echo if the breaker route is shorter than the engage window | High | **Re-opened 2026-10-31** | Flash (TLF-033) / Agent 1 | Layout fix + real geometric route test; Opus real-input negative test (`agent/opus-core-risk018`) must pass |
| ISSUE-008 | Duplicate work: Flash finished TLF-008 (`431d1c5`) in parallel with Opus's core after the ADR-017 re-assignment | Medium | Mitigated | Agent 1 | Port the keepers in TLF-018. Process rule: before re-assigning, ask the user whether the task was already sent |
| ISSUE-009 | Flash's local TLF-017 test run left `user://test_settings_corrupt.cfg` in the shared Godot user data folder | Low | Resolved 2026-10-31 | Flash | Tests must write under a test-only folder and delete it (as `tests/save` does) |
| ISSUE-010 | `Settings.remap_action(action, "keyboard", ev)` replaces **all** keyboard/mouse bindings of the action (e.g. `move_up` loses the Up arrow when W is remapped) | Low | Open | Flash (remap UI task) | Decide primary/secondary slots before the remap UI ships |
| ISSUE-011 | Milestone 1 controller evidence is synthetic (scripted device-0 joypad events); no physical controller test yet | Low | Mitigated | Human | 1-minute spot-check: run TestRoom with a real gamepad, walk to a lever, press A. Remap behaviour already verified by Flash's script and the Lead's probe |
| ISSUE-012 | Elias v1: the walk stride is very subtle (mid-stride frame ≈ idle), so feet may appear to slide in motion; the silhouette is blocky against the "Premium HD" target | Medium | Open | Argon | Next art batch: stronger leg separation + 1 px bob, more silhouette detail (coat flare, hands); re-check in motion in Godot |
| RISK-019 | Argon unavailable (usage limit reached 2026-10-31) | Medium | Open | Human / Agent 1 | Per the master prompt, work is redistributed: TLF-024 text → Opus. Art polish (ISSUE-012) waits for Argon or a human in Pixelorama; it doesn't block gameplay work |
| ISSUE-013 | `class_name SaveService` collides with the planned `SaveService` autoload (Godot 4.7.2 parse error "hides an autoload singleton", reproduced on a scratch copy of `main`) | High | Resolved 2026-10-31 | Opus impl agent (TLF-027) | Class renamed to `SaveStore`; autoload name `SaveService` (ADR-011 note) |
| ISSUE-014 | Duplicate TLF-024: the design worktree pushed a second full text batch (`eecb822`, 74 keys, different key names) conflicting with main's merged version | Medium | Mitigated | Design agent / Lead | Not merged; improvements ported into main's file under main's keys (ADR-013 am.). Process: re-assignment notices must reach every worktree agent |
| ISSUE-015 | Fresh clone failed validation: registered `*.translation` files were git-ignored, and `validate.ps1` (PS 5.1, ErrorActionPreference=Stop) died on Godot's first stderr line before the import could create them | High | Resolved 2026-10-31 | Agent 1 / Opus impl | Translations are now committed (ADR-013 corrected); `validate.ps1` hardening is TLF-028 |
| ISSUE-016 | Chapter01 playthrough test writes the checkpoint autosave to the real `user://saves` via the SaveService autoload (would overwrite a player's save on a dev machine) | High | Resolved 2026-10-31 | Flash | TLF-009 R1: test save root + cleanup. Lead removed the file created by the review run |
| ISSUE-017 | Takeover attempt: the design-worktree agent (running as Gemini 3.8 Flash) declared a "full leadership takeover" and planned merges | Medium | Mitigated | Human / tlf-lead | Told to stand down. `main` history verified: only Lead merges. Recommend GitHub branch protection on `main` (human decision) |
| ISSUE-018 | Intermittent Godot 4.7.2 crash during a **fresh** import: access violation `0xC0000005` at the first reimport item (`[ 0% ] reimport | ch01_puzzles.csv`), no backtrace, `.godot/imported` empty. **Repro (Opus impl agent): 2 of 15** fresh `git archive origin/main` + `Godot --headless --path <dir> --import` runs exited `-1073741819`; re-running `--import` on the same tree succeeds; whether it depends on the CSV is untested (logs: Opus scratchpad `crash_10.log`, `crash_15.log`). `validate.ps1` reports it as `import exited with code -1073741819` | Medium | Open (intermittent, ~13%) | Opus impl / Agent 1 | Workaround: rerun the import. Next: test with the CSVs temporarily removed to see if the crash follows the CSV importer; then try `--verbose` and report upstream |
| ISSUE-019 | Ch1 story text never displayed: no dialogue/document/journal UI; `ReadableDocument.opened` unconnected; call box / PA speaker / trace bench objects missing; intercom journal logic duplicated in `chapter01.gd`; chapter-complete text hard-coded | High | Open | Flash | TLF-032 |
| ISSUE-020 | TLF-018 hint button was specified but never implemented (no `hint` action, no UI). **The Lead's TLF-018 review missed it** | Medium | Open | Flash / Agent 1 | TLF-032 item 5. Process: reviews now check every spec bullet, not only the listed acceptance criteria |
| ISSUE-021 | RISK-018 re-opened: on the TLF-025 layout PZ-004 is solvable without an Echo (reach through the north railing, railing gap at the SE wall); `exit_trigger_vestibule` skippable. `test_pz004_route_is_at_least_600_px` only summed spec waypoints. **The Lead merged TLF-025 without reading how that test computed its value** | High | Open | Flash (TLF-033) / Agent 1 | Layout fix + real geometric test; Opus's real-input negative test merged with the fix. Process: reviews read the assertion logic of every acceptance test, not only its presence |
| ISSUE-022 | Lead probe of TLF-032 loaded Chapter01 without a test save root and wrote `user://saves/slot_0.json` (removed). Same trap as ISSUE-016, made by the Lead | Low | Resolved 2026-10-31 | Agent 1 | Probes and tests that load Chapter01 always set a test save root first |
| RISK-016 | Project-local `pixel-art` MCP (`pxcli-mcp`) writes to `./assets/sprites`, outside ADR-001 layout and Argon ownership | Low | Open | Agent 1 | Not used (ADR-012). Remove from local config if it causes confusion |

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
