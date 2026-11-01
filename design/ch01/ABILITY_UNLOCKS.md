# Spec: Ability unlocks (TLF-047 phase 2; data and tests for TLF-050 `AbilityUnlocks`)

**Task:** TLF-047 phase 2 · **Decision:** ADR-020 amendments (progressive abilities; Q-10), ADR-021 (wheel reads this state) · **Status:** spec for implementation
**Contracts:** none changed (`InteractionService`, `TemporalComponent`, `EchoService`). `PocketWatch.unlocked_abilities` already exists and `cycle_ability` already honours it (`pocket_watch.gd:22, 85-107`).

---

## 1. Unlock table (Step 1)

An ability becomes unlocked when its **trigger flag** is set in `NarrativeState` (the flags are written by existing mechanisms: a pickup, a `TraceMemory`, or a one-line `use` object). In the rooms this is one `AbilityUnlockTrigger` node per row (TLF-050: fires on a flag / a `ProgressionPickup` / a puzzle `SOLVED`, configured by exports; placing them is the scene owner's job). This table is the source for those nodes.

| Ability (`StringName`) | Trigger flag | Written by (object ID) | Story moment | Elias line key | HUD toast key |
|---|---|---|---|---|---|
| `&"trace"` | `ch01.flag.pocket_watch_acquired` | `ch01.arrival_platform.pocket_watch_pickup` (`ProgressionPickup`, flag already used in the scene) | Beat 01: the cracked watch; one hand still moves | `EL_B01_04` (existing) | `UNLOCK_TRACE` |
| `&"rewind"` | `ch01.npc.n05.traced` | `ch01.concourse_west.n05_courier` (`TraceMemory`, first Trace) | Beat 02: tracing the courier frozen mid-vault; the hand ticks backwards | `EL_UNLOCK_REWIND` | `UNLOCK_REWIND` |
| `&"freeze"` | `ch01.npc.n11.traced` | `ch01.maintenance_bay.n11_hatch_tech` (`TraceMemory`) | Beat 04: the tech holding a hatch crank; the hand stops dead | `EL_UNLOCK_FREEZE` | `UNLOCK_FREEZE` |
| `&"echo"` | `ch01.flag.echo_pedestal_used` | `ch01.security_crossing.echo_recorder_pedestal` (new `Interactable`, `use` sets the flag) | Beat 05: the calibration pedestal; a second hand splits off | `EL_UNLOCK_ECHO` | `UNLOCK_ECHO` |
| `&"fast_forward"` | `ch01.flag.ff_unlocked` | (reserved, SP-D stretch; **not used in Step 1**) | after CH1-PZ-004, optional | — | — |

Chapter start: TLF-050's chapter config gives `unlocked = [trace]` (the HUD is hidden until the watch is held, so the pickup row is an idempotent safety net and also covers loads). Tests and the old flow keep the default of all four. The wheel's unknown slot (ADR-021) is not an ability and has no entry.

## 2. Service behaviour (`AbilityUnlocks`, TLF-050)

* `is_unlocked(ability) -> bool`, `unlock(ability) -> bool` (true on the first unlock only), `unlocked() -> Array`, signal `ability_unlocked(ability)` (TLF-050 API).
* Each `AbilityUnlockTrigger` listens to `NarrativeState.flag_changed(flag, true)` (or the pickup / `SOLVED` signal) and calls `unlock`.
* **Re-derivation:** after a save is applied (and after a room is restored) the service unions the saved list with the abilities whose trigger flag is already true. This heals a save written between the flag and the list, and makes the flags the source of truth for Step 1.
* **Order independence:** abilities can only unlock through their triggers; nothing can unlock Echo before Rewind except by reaching its trigger first, which the room order prevents (§5).
* `PocketWatch.unlocked_abilities` mirrors the service (the service sets it; the setter already normalises to `StringName`). If the selected ability is no longer unlocked (never possible in Step 1) selection falls back to the first unlocked one in `MASTER_CYCLE_ORDER`.
* `ability_next` / `ability_prev` skip locked abilities (ADR-021). With only Trace unlocked they do nothing and give no error.

## 3. HUD and feedback

* The ability slots (HUD) and the wheel show locked abilities greyed **with a lock glyph** (shape, not only colour); the slot for the next unlock is not named before it unlocks (the wheel shows "?" only for the unknown slot).
* **On unlock:** a toast (`UNLOCK_*` key, 2 s), one Elias line (`EL_UNLOCK_*`, non-blocking, 4 s auto-advance), the unlocked slot pulses once (static outline under `reduced_effects`), and the watch icon plays the motif (Trace: sweeps once, Rewind: ticks backwards, Freeze: stops, Echo: a second hand follows).
* Selecting a locked ability through the wheel gives the `ability_locked` feedback (TLF-052); `ability_next` skips it silently.
* A newly unlocked ability is **auto-selected once** (so the first thing the player sees is the new state), except while a blocking dialogue is open.

## 4. Save

* New key `unlocked_abilities: Array[String]` in the save payload. `SaveStore.SAVE_VERSION` goes **2 → 3** (it is 2 today, v1→v2 added the playtest log).
* `default_save()["unlocked_abilities"] = []`.
* **Migration v2 → v3:** `data["unlocked_abilities"] = ["trace", "rewind", "freeze", "echo"]` (old saves unlock all four, Lead decision Q-10). Saves that already contain the key are untouched.
* `validate()` accepts only the four known ids (ignore unknown strings with a warning; never reject the save).
* The playtest log (TLF-048) records `ability_unlocked` with the tick and room (optional but recommended: it shows where players got stuck before the next unlock).

## 5. Solvability / sequence guards

| Puzzle | Abilities needed | Unlocked by the time the player can reach it |
|---|---|---|
| CH1-SO-01 (R1) | Trace | picked up in the same room, before the gate |
| CH1-PZ-001 (R2) | Trace, Rewind | Rewind needs the courier (`n05_courier`, flag `ch01.npc.n05.traced`). He stands in the **entry strip** west of the turnstile dividers at tile `(1,6)` px `(240,120)`, 17.9 px from the entry anchor `(256,112)`, so Rewind unlocks **before** the gate has to be rewound and without passing it |
| CH1-PZ-006 (R2) | Trace, Rewind | Rewind from PZ-001 |
| CH1-SO-02, PZ-002 (R3) | Freeze | `n11` is the first thing in the bay (stand spot on the plate side) |
| CH1-PZ-003 (R4) | Echo | the pedestal is 1 tile from the plate |
| CH1-PZ-004, 005 | all four | yes |

**Soft-lock check:** the turnstile dividers (`SegmentShape2D` from `(352,80)` to `(284,114)` and `(260,126)` to `(176,168)`, `concourse_west.tscn`) split the room at tile `x = 2.5`; the player's side is the entry strip `x <= 2`. The courier is inside the strip, in Trace range of the entry anchor and the nearest Trace candidate from `(256,112)` (17.9 px against 26.8 px for `turnstile_trace_anchor`). TEST-AU-08 pins this with the real colliders.

## 6. Acceptance tests (given / when / then)

* **TEST-AU-01 — new game has no abilities until the watch is picked up.** GIVEN a fresh session with the Chapter 1 start config; THEN `AbilityUnlocks.unlocked() == [&"trace"]`; WHEN `pocket_watch_pickup` is used; THEN the list is still `[&"trace"]` (idempotent), the selected ability is `&"trace"` and `UNLOCK_TRACE` was shown once.
* **TEST-AU-02 — a `TraceMemory` flag unlocks Rewind.** GIVEN Trace unlocked; WHEN the courier is Traced; THEN `is_unlocked(&"rewind")` and `ability_unlocked(&"rewind")` was emitted exactly once; a second Trace does not emit again.
* **TEST-AU-03 — locked abilities are not selectable.** GIVEN only Trace unlocked; WHEN `cycle_ability(1)` and `set_selected_ability(&"echo")`; THEN the selection stays `&"trace"` and `set_selected_ability` returns false.
* **TEST-AU-04 — the pedestal unlocks Echo.** GIVEN Trace, Rewind, Freeze; WHEN `request(&"player", …echo_recorder_pedestal, &"use")`; THEN `ch01.flag.echo_pedestal_used` is true and Echo is unlocked; a second `use` returns `&"already_open"`.
* **TEST-AU-05 — save round trip.** GIVEN Trace and Rewind unlocked; WHEN saved and loaded; THEN the same two are unlocked and no other.
* **TEST-AU-06 — migration.** GIVEN a v2 save without `unlocked_abilities`; WHEN `SaveStore.upgrade()`; THEN `save_version == 3` and all four abilities are unlocked.
* **TEST-AU-07 — flag re-derivation.** GIVEN a save with `unlocked_abilities = ["trace"]` but `ch01.npc.n05.traced = true`; WHEN applied; THEN Rewind is unlocked too.
* **TEST-AU-08 — the courier is reachable on the entry side (real colliders).** GIVEN the concourse is loaded, Trace unlocked, the turnstile still collapsed; WHEN the player stands at the entry anchor `(256,112)` and `PocketWatch.choose_watch_target(… &"trace")` runs; THEN the target is `n05_courier` (17.9 px); AND WHEN the player stands at `(264,116)` the target is `turnstile_trace_anchor` (17.9 px); AND the flood-fill from the entry anchor with the gate closed reaches both stand spots.
* **TEST-AU-09 — no hidden order.** GIVEN a fresh session; WHEN `ch01.npc.n11.traced` is set directly; THEN Freeze unlocks but Rewind does not; the room order (R2 before R3) is what prevents this in play. (Documents that the triggers do not enforce an order.)
* **TEST-AU-10 — wheel/HUD read-only.** GIVEN any unlock state; THEN the HUD slot list and the wheel only read `AbilityUnlocks` (no writes), pinned by a test that mocks the service.
