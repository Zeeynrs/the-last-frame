# Lead Review — Flash's TLF-008 commit `431d1c5` (duplicate of the re-assigned task) · **NOT MERGED, PORT INTO TLF-018**

**Reviewer:** Agent 1 (Lead) · **Date:** 2026-10-31

## What happened
TLF-008 had already been sent to Flash before ADR-017 re-assigned its temporal core to Opus. Flash completed it on its own branch (`431d1c5`, based on `655e779`), in parallel with the Opus core that is now on `main` (`fe3744a`, plus Echo `9f55245` and Puzzle/Save `afa6929`, which depend on it). The root cause is a Lead process error: a task that had been dispatched was re-assigned without confirming it hadn't started (ISSUE-008).

## Overlap
These files conflict directly with `main`: `scripts/interaction/interactable.gd`, `scripts/temporal/temporal_component.gd` (+ `.uid`), `tests/temporal/test_temporal_component.gd` (+ `.uid`).

## Decision
- **`main`'s temporal core stays canonical.** It's merged and ADR-documented, and Echo, Puzzle and Save are built on it (82 tests).
- **Not merged:** Flash's `TemporalComponent`, its `Interactable` changes, and its `test_temporal_component.gd`. They duplicate merged behaviour.
- **Worth keeping, port into TLF-018:** `scripts/temporal/pocket_watch.gd`, `scenes/test/TemporalTestRoom.tscn`, the `player.gd` / `Player.tscn` integration, `tests/temporal/test_pocket_watch.gd`. `PocketWatch` already uses the same API names as `main` (`supports_ability`, `object_id`, `interaction_service.request`), and `main` now has `Interactable.set_watch_focused(focused, ability)` with Flash's exact signature, so the port is mostly mechanical.
- **Retire or port as needed:** `scripts/test/test_gate|gear|shutter|pillar.gd` and `tests/temporal/test_puzzle_specs.gd`. `main` already has `TemporalTestGate/Shutter/Gear` and spec tests for PZ-001/002. Keep a spec test only if it covers something `main` doesn't (list those in the handoff).

## How Flash should port (non-destructive)
1. In the `tlf-implementation-qa` worktree, after TLF-017 is pushed: `git revert --no-edit 431d1c5` (keeps history; nothing is deleted).
2. `git pull --ff-only origin main` (or merge if TLF-017 is ahead).
3. Bring back the keepers: `git checkout 431d1c5 -- scripts/temporal/pocket_watch.gd scenes/test/TemporalTestRoom.tscn tests/temporal/test_pocket_watch.gd`, then re-apply the `player.gd`/`Player.tscn` hunks by hand.
4. Move `pocket_watch.gd` to `scripts/player/` (TLF-018 allowed path), adapt it to `main`'s API, and draw the highlight in the watch/HUD rather than in `Interactable` (`main`'s hook is logic-only).
5. Run `tools/validate.ps1` and continue with TLF-018.
