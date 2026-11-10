# TLF-076 technical review: Beat 06 Mira memory in side view (Flash, `a94aee3`)

Opus, 2026-11-10. Read-only review of `origin/adityadaffa522/tlf-076-mira-memory-side` at `a94aee3`. The code is in `323992c`; `a94aee3` only adds the SHA to the handoff. The parent is main `fe4bfb1`. No Flash file was changed and nothing was merged. The Lead runs the official validate.

**Sources:**
- Spec: `design/ch01/side_view/mira_memory.md`, and `docs/tasks/TLF-076.md`.
- Handoff: `docs/handoffs/TLF-076/TLF-076_HANDOFF_REPORT.md`.

**Method:**
- **Reading:** I read the diff and its callers.
- **Scratch copies:** renamed `git archive` copies of `a94aee3` and `fe4bfb1` ("TLF Verify rev076-<sha>"), each imported headless.
- **Test runs (`a94aee3`):** Flash's test file, `test_ch01_narrative_beats` and `test_ch01_real_playthrough`.
- **Probes:** two of my own probe files, run on **both** trees with Chapter01, `ch01_real_input` (real input, test save root) and physics frames. They are in `a94aee3/probe_*.gd.txt`, with all output in `a94aee3/probe_output.txt`.
- **Real save:** not touched.

## Verdict: **CHANGES REQUIRED**

Most of the core works:
- The view switch, walking, camera, Rewind, Trace, exit and re-entry all work.
- I saw no ERROR and no SCRIPT ERROR.

Three things block it:
- **P1-1:** after the visit the autosave is left inside the memory room.
- **P1-2:** the tests do not cover the spec's real-input run and save/load path.
- **P2:** some scope changes should be reverted or decided by the Lead.

| # | Priority | Finding | Fix (smallest) |
|---|---|---|---|
| 1 | **P1** | The autosave points into the memory after Elias leaves it. | Write the lounge autosave on return, or drop the checkpoint (Lead decides). Add a test. |
| 2 | **P1** | The tests miss the spec's real-input run and the real save/load path. | Real-input entry, Trace and Rewind; Continue from disk; re-entry; camera clamp. |
| 3 | P2 | The first Trace on the bench now plays Beat 06; on main it does nothing. | Lead confirms that this is intended. |
| 4 | P2 | `DialogueTrigger._on_traced` is new, unneeded and outside the scope. | Revert. |
| 5 | P2 | The room is swapped synchronously inside the bench's own `interact()`. | Defer the entry the way the exit is deferred. The `pocket_watch.gd` patch can then go (harmless if kept). |
| 6 | P2 | The lounge line EL_B06_01 carries on through the memory and back. | Finish the line on entry. |
| 7 | P2 | The cup Rewind shows the ability name `Rewind` on the red refusal line. | Lead/Sol: no message, or an existing success key. |
| 8 | P3 | Small items: the `unsupported` reason after the Mira Trace, the cup taking the interact focus, the flag name, dead code, wrong numbers in the handoff. | See section 4. |

## 1. Bench (`trace_bench.gd` + `waiting_lounge.tscn`)

**What `TraceBench` does:** the lounge bench node now uses `TraceBench`, which extends `DialogueTrigger`. Its `trigger()` checks whether the B06 line was heard (`heard.ch01_b06_bench`) or the journal holds `JRN_CH1_TWO_SILHOUETTES`. If either is true it enters the memory; otherwise it calls `super.trigger()`.

**Probe A/B:** the same real-input steps on both trees. Elias walks to the bench stand spot (320, 160), and the bench is both the interact target and the watch target.

| Action | main `fe4bfb1` | branch `a94aee3` |
|---|---|---|
| first **Trace** (tap `watch`) | `watch_used ok=true`, then **nothing**: no dialogue, no `heard`, no journal | EL_B06_01 (`ch01_b06_bench`), `heard` true, JRN_CH1_TWO_SILHOUETTES ×1 |
| first **Use** (tap `interact`) | EL_B06_01, `heard` true, journal ×1 | **identical** |
| second Use | — | nothing (`_can_use`: one-shot, `unsupported`), as on main |
| second Trace | — | enters `ch01.side_mira_memory` |

- **Finding 3 (P2, Lead decision):** the spec says "the first Trace … behaves exactly as today (EL_B06_01, journal entry)", but that is not what main does. On main a **Use** plays Beat 06, and a Trace succeeds silently: `Interactable.interact(trace)` only emits `traced`, and `DialogueTrigger` had no `_on_traced`. The existing Beat 06 test calls `trigger()` directly. The branch makes the Trace play Beat 06 too. This matches what the spec describes and is harmless for the main flow: after the line, the journal and the `heard` flag are identical whichever path the player takes, and the Use path is unchanged. Still, it is a behaviour change, and the handoff does not mention it. The Lead should confirm it.
- **Playthrough, journal and Beat 06 flags are intact:** `test_ch01_real_playthrough` passes 1/1 (it never traces the bench), and `test_ch01_narrative_beats` passes 13/13. Both have 0 ERROR.

## 2. Changes outside the scope

- **`chapter01.gd` `_on_flag_changed`: `not bool(value)` → `not value`. Safe, keep it.**
  - **Needed:** on main a non-bool flag crashes it. Probe H on `fe4bfb1`: `SCRIPT ERROR: Invalid call. Nonexistent 'bool' constructor. at Chapter01._on_flag_changed (chapter01.gd:159)`. On the branch the same probe runs clean.
  - **Same result for bool flags:** for bool, int, float and null, `not value` gives the same as `not bool(value)`. All existing flags are bool.
  - **Other listeners are safe:** `operator_sighting.gd:215` calls `bool(value)` only after `flag_id == …` has matched, and `ability_unlock_trigger.gd:71` already uses `value`.
  - **Root cause:** the new non-bool flag `mira_memory.return_target`, a StringName (see 4c).
- **`pocket_watch.gd`: `current_target` freed. Safe, but it only treats a symptom.**
  - **Why it exists:** the second Trace frees the whole lounge, including the bench, while `bench.interact()` is still on the call stack (finding 5). `activate_watch()` therefore reads `object_id` before the request and clears `current_target` when it is gone afterwards.
  - **No visible side effect:** the HUD and the player already check `is_instance_valid`. After the entry the probe shows `watch current_target valid false value <null>`, and the log has no errors.
  - **It can go:** once the entry is deferred (finding 5) this patch is no longer needed, though keeping it does no harm.
- **`dialogue_trigger.gd`: new `_on_traced` → `trigger()`. Not needed; revert (finding 4).**
  - **Dead for the bench:** `TraceBench` overrides `_on_traced` without calling `super`.
  - **No effect today:** no other `traceable` DialogueTrigger exists. On main, the eight others are the watch pickup, the call box and six clocks, none traceable; the memory bench and clock are not traceable either.
  - **It changes the base class for every later traceable DialogueTrigger:** a Trace would then run its line, journal entry and flag, which is the same change as finding 3, but silently.
  - **Same pattern of dead code:** `_can_watch` / `_on_watch` have no caller anywhere in `scripts/` (they already existed in DialogueTrigger), yet Flash copies them into `TraceBench` and `MiraMemorySilhouette`. `TraceBench._on_watch` even emits `traced(0)`, an int where the signal expects a StringName.

## 3. Entry, exit, save/load and second visit (probes C, D, E, L)

All real input after setup. Results:

- **Entry:**
  - The second Trace loads `ch01.side_mira_memory`, side mode, with Elias at the anchor (120, 394).
  - `view_mode_changed` fires `[side]`, and later `[side, iso]` on the way back.
  - No ERROR or SCRIPT ERROR.
- **Exit:**
  - **Deferral:** `SideMemoryExitMarker.on_trigger_enter` runs inside the physics callback of `area_entered`, so `enter_room.call_deferred(...)` is needed there and correct.
  - **Arrival:** Elias walks into x 1380 and arrives in the lounge, iso, at (338, 152), which is `safe_anchor_center` (336, 152) plus 2 px from the still-held input. The bench is the interact target from there. The camera goes back to the legacy bounds (0, 0, 640, 360) with `horizontal_only` false, and the selected ability is kept.
  - **Return anchor:** it comes from the flag and falls back to the exported anchor.
- **Second visit:**
  - **Cup:** the cup is still on the bench (540, 384), because RoomRouter's temporal cache keeps it, and a new Rewind gives `no_history`, so it is idempotent.
  - **Mira:** she can be traced once **per visit** (the spec says "stays used for the visit"). `_traced_used` resets with each new instance, but the fragment is collected only once (`has_fragment` guard) and the journal holds JRN_CH1_TWO_SILHOUETTES only once.
- **Save inside and load:**
  - **Autosave on entry:** the memory has a CheckpointZone exactly at the spawn point (120, 394), so **every entry writes the autosave**: `checkpoint_reached [ch01.cp.side_mira_memory, OK]`, saved room `ch01.side_mira_memory`.
  - **Continue:** reading that slot from disk (JSON) and restoring it into a fresh Chapter01 gives:
    - **Room and view:** the side room and mode, Elias at (120, 394), side sprites, camera at (480, 270) with bounds (0, 0, 1440, 540) and horizontal only.
    - **Return target:** survives the JSON round trip.
  - **Way out after Continue:** walking to the exit leads back to the lounge at (338, 152).
  - **Result:** the requirement "a save inside the memory stores the memory room plus the return target" is met.
- **Finding 1 (P1): the autosave stays inside the memory after leaving it.**
  - **Probe L:** after the exit, Elias is in the lounge but the autosave still holds room `ch01.side_mira_memory` and checkpoint `ch01.cp.side_mira_memory`.
  - **Why:** `safe_anchor_center` is outside the lounge's CheckpointZone at (256, 112).
  - **Consequence:** a player who visits the optional memory and quits anywhere before the next checkpoint will Continue **inside the memory**. The spec also lists the start as "checkpoint-free" (section 3) and promises an untouched main flow.
  - **Fix:**
    - **Option a, my recommendation:** keep the inside save (spec section 2) and have the exit call `room_router.reach_checkpoint(&"ch01.cp.waiting_lounge")` after arrival.
    - **Option b:** drop the memory checkpoint, so nothing is saved inside, and update the spec.
    - **Test:** either way, add a test for it.
- **Finding 5 (P2): the room changes synchronously inside the interaction.**
  - **What happens:** `TraceBench.trigger()` calls `enter_room()` from within `bench.interact()`. `RoomRouter._unload_current()` uses `free()` (not `queue_free()`), so the bench and the whole lounge are freed while `bench.interact()` is still on the stack.
  - **What follows:** `InteractionService.request()` then emits `interaction_applied` for an object that no longer exists. It works today, thanks to the `pocket_watch.gd` patch, but it is fragile.
  - **Fix:** defer the entry, either with `call_deferred` as the exit does or through RoomRouter's `_pending` queue.
- **Finding 6 (P2): the B06 line carries over.**
  - **What happens:** a second Trace while EL_B06_01 is still on screen (it is non-blocking with no auto-advance) enters the memory with the lounge line still showing. It stays through the visit and after the return (probe C: `dlg active true seq ch01_b06_bench` after the exit).
  - **Fix:** `finish_sequence()` on entry, or refuse the entry while the bench line plays.

## 4. Layers, z, clamp, camera and abilities

- **Scene positions:** start 120, pillar 300, bench 520, cup 600 (moving to 540, 384), Mira 780, trolley 1000, clock 1180 (sprite on the wall), exit 1380 (24 × 64). This matches the spec table. The handoff's own table is wrong; see below.
- **z:**
  - **Measured order:** walls 1–3 < pillar 6 < clock 7 < bench and trolley 8 < cup and Mira 9 < Elias 10 < letterbox 15 (its hairlines inherit 15). The values come from the instantiated tree; `Player` z 10 is ACTOR_Z, everything is `z_as_relative`, and RoomContainer and the room root are z 0.
  - **Result:** Elias passes in front of all props and stays under the letterbox bars, which fits a flat side scene, and DepthSort is skipped.
  - **For Sol:** the floor strip starts at y 378, 16 px above the floor line 394. Sol should judge it against the art.
- **Clamp and camera:**
  - **Clamp:** `SideView` uses `walk_margin` 16, so Elias walks from 16 to 1424, and the exit at 1380 is reached before 1424.
  - **Camera:** over a real walk from 120 to the exit, x ran 480 → 960 (clamped), y stayed fixed at 270, with 0 fractional frames, and the view stayed inside 0..1440.
- **Abilities:**
  - **Rewind on the cup:** (600, 394) → (540, 384); a second Rewind gives `no_history` with the existing text.
  - **Trace on Mira:** OK. A repeat Trace gives `unsupported`, i.e. "The pocket watch cannot affect this object.", which reads oddly right after a successful Trace (P3; an existing key that fits better would be nicer).
  - **Freeze:** targets the cup and is refused as `unsupported` (existing key).
  - **Echo:** records and plays back without a crash (Flash's test 5).
- **Finding 7 (P2): the cup Rewind message.** `VoiceRecorderCup._on_rewound` shows `tr("ABILITY_REWIND")` ("Rewind") through `hud.show_message`. That is the ability's name used as a message, and it appears on the **red** refusal line. The spec asks for "short feedback with an existing key". Lead/Sol should choose: no message, or an existing success key.
- **P3 items:**
  - **(a) Cup takes the interact focus:** after the Rewind, the cup (at 540) is the interact target at x 540–550, and E there does nothing (`_can_use` returns `unsupported`). The bench stays reachable from 500–530.
  - **(b) Dead code:** `_can_watch` / `_on_watch` in `TraceBench` and `MiraMemorySilhouette`. Also, Mira's `add_journal_entry(JRN_CH1_TWO_SILHOUETTES)` in practice never adds anything, because entering the memory already requires that entry or the `heard` flag that comes with it.
  - **(c) Flag `mira_memory.return_target`:** it is not namespaced (other flags are `ch01.flag.*`, `ch01.npc.*`, `heard.*`) and it holds a StringName; `ch01.flag.mira_memory_return` would be better. It works through JSON (verified).
  - **(d) Handoff text does not match the code:**
    - **Object table:** start 80, pillar 360, bench 540, Mira 720, trolley 1160, clock (1280, 280).
    - **Scene description:** "walk 40..1400" (actually 16..1424); "3 slices at 0/480/960" (actually 2, at 0/960); "Rewind smoothly interpolating" (it jumps).
    - **Abilities:** "Freeze & Echo refused" (Echo works).
  - **(e) Test file:** declares `const ViewMode` / `const SideView` preloads that shadow the global class names (no warning in the log).

## 5. Test quality (`tests/chapters/ch01/test_ch01_mira_memory_side.gd`, 6 tests)

All 6 pass with 0 ERROR. None of them passes no matter what: each asserts the state it claims (room, mode, position, `ok`/`reason`). But they do not test what spec section 6 asks for. **Finding 2 (P1):**

- **Not real input where it matters:**
  - **Entry:** both bench Traces teleport Elias onto the bench and call `watch.activate_watch()`.
  - **Abilities:** Rewind on the cup and Trace on Mira are also `activate_watch()` calls, and abilities are chosen with `set_selected_ability()` instead of `ability_next`.
  - **Dialogue:** advanced with `diag.advance_line()`.
  - **What is real:** only the walking and the `interact` taps.
- **First Trace:** checks only the sequence id, not the journal entry or the `heard` flag, and nothing compares it with the Use path.
- **Save/load:**
  - `capture_save()` is passed in memory, so there is no JSON or disk and no checkpoint path, although the real autosave is written on entry.
  - The return-target flag is never set (the room is entered through `router.enter_room`), and there is no walk out after the load and no cup state.
  - Finding 1 is therefore not covered.
- **Not tested at all:**
  - **Re-entry:** a second visit (cup idempotent, fragment once).
  - **Camera:** no camera position or clamp assertion, only `bounds` and `horizontal_only`.
  - **Autosave after the exit:** (finding 1).
- **Reach "from both sides":** teleports to x ± 24 and checks targeting. That is acceptable as a reach check, but nothing walks there.
- **Leak test:** only `router.enter_room` round trips, not bench → memory → exit, and no signal check.
- **Wanted:**
  - one real-input run (`ch01_real_input`: walk, `select_ability`, `tap(&"watch")`) from the lounge through the bench, cup and Mira to the exit;
  - Continue from the autosave on disk, then walk out;
  - after the exit, an assertion on the autosave's room;
  - a second visit;
  - the camera's x range during the walk.

## Evidence

- **`a94aee3`:**
  - `test_ch01_mira_memory_side` 6/0.
  - `test_ch01_narrative_beats` 13/0.
  - `test_ch01_real_playthrough` 1/0.
  - Each with 0 SCRIPT ERROR / 0 ERROR.
- **Probes:**
  - **Files:** `probe_visit.gd.txt` (A–E) and `probe_focus_autosave.gd.txt` (F, H, L).
  - **Runs:** `fe4bfb1` 4/0 + 2/0 (expected, since the memory steps skip there), and `a94aee3` 4/0 + 2/0.
  - **Errors:** the only SCRIPT ERROR is probe H on main, which is intended.
  - **Output:** the raw PROBE lines are in `a94aee3/probe_output.txt`.
- **Not done:** the full validate (the Lead runs it), and screenshots; the composition is Sol's review.
