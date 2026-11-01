# Spec: `TraceMemory` — Trace carries information (TLF-047 phase 2)

**Task:** TLF-047 phase 2 · **Author:** design agent (Claude Code, Sonnet 5.5), standing in for Argon · **Status:** spec for implementation (Opus impl; Flash wires scenes)
**Why:** `Interactable.interact(&"trace")` only emits `traced(object_id)` and calls an empty `_on_traced()` (`interactable.gd:125-126, 153`); nothing connects to it (Lead confirmed, ADR-020 amendment). Every Step 1 puzzle that claims "information from Trace" depends on this class (`CH01_EXPANSION.md` §0.1, rule R2).
**Contracts:** none changed. `TraceMemory` is a new `Interactable` subclass that overrides the existing `_on_traced` hook and `_can_use`.

---

## 1. Class

```
class_name TraceMemory
extends Interactable
```

| Export | Type | Default | Meaning |
|---|---|---|---|
| `lines` | `Array` | `[]` | 1-2 pairs `[speaker_key, text_key]`, shown in order (TLF-050 name). The **first text starts with a time stamp** `[hh:mm]` (see §5). Required. A commuter uses `SPK_MEM_N01`, a scene memory `SPK_MEMORY`. |
| `flag_id` | `StringName` | `&""` | Set (true) on the **first** Trace. Step 1 uses `ch01.npc.<id>.traced` (commuters), e.g. `ch01.npc.n05.traced`. |
| `journal_key` / `journal_category` | `String` | `""` / `"observation"` | Journal entry added on the first Trace (once). |
| `one_shot_dialogue` | `bool` | `false` | `false` in Step 1: a repeat Trace replays the lines (no new flag/journal). |
| `object_id` | `StringName` | (Interactable) | Registered as usual. Commuters: `ch01.<room>.<slug>`. |

Signal `memory_revealed(object_id)` is emitted on **every** Trace (first and repeat). The dialogue sequence id is `trace.<object_id>` (TLF-050 convention). Auto-advance is the project default for non-blocking lines (4 s).

`_ready()` forces `traceable = true`, `progression = false`, and fails loudly (`push_error`) if `lines` is empty or larger than 2, or the first line's text does not start with a time stamp (the check resolves the key through `tr()`). The node has a `CollisionShape2D` on layer 4 / mask 0 exactly like the other `Interactable`s in the rooms.

## 2. Behaviour

| Event | Result |
|---|---|
| `InteractionService.request(&"player", id, &"trace")` | `can_interact` = `&""` (the base class already allows it because `traceable` is true). `interact` emits `traced(object_id)` and calls `_on_traced(actor)`. |
| `_on_traced` (first time) | 1. Plays the lines as a **non-blocking** sequence: `DialogueBox.play_sequence(&"trace.<object_id>", lines, false, 4.0, one_shot_dialogue)`. 2. Sets `flag_id`. 3. Adds the journal observation (`journal_key`, `journal_category`, no-op if empty). 4. Emits `memory_revealed(object_id)`. |
| `_on_traced` (repeat) | Replays the same non-blocking lines (`one_shot_dialogue = false`). Does **not** touch the flag or the journal (both idempotent already). Emits `memory_revealed(object_id)`. |
| `_can_use(actor, &"use")` | returns `&"unsupported"` for every actor (a memory is looked at, not used). |
| Echo | Trace is a watch ability and is never recorded; nothing to define. |
| `rewind` / `freeze` / `fast_forward` | `&"unsupported"` (no `TemporalComponent`). |
| A blocking dialogue or document is open | the player is input-blocked already; no Trace can be issued. |
| Another non-blocking memory is playing | the new one replaces it (`play_sequence` restarts); the old one is not queued. |

**Targeting (ADR-015, mandatory placement rules P1/P2, checked by `design/ch01/expansion/step1_placement_check.py`):**
* `Player.is_targetable` counts any object that supports a watch ability, so a `TraceMemory` is also a candidate for the `E` (use) target even though its `use` is unsupported. To keep it from stealing `E` from a real use-object, every `use`-object must have its stand spot closer to it than to any `TraceMemory` (P1). The placement checker output is part of each spec.
* Two `TraceMemory` objects are separated by ≥ 2 tiles (35.8 px) and each has a stand spot 1 tile away (17.9 px) at which it is the nearest Trace candidate (P2). Stand spots are listed per commuter in `COMMUTERS_STEP1.md`.

## 3. Presentation

* **Line box:** the existing `DialogueBox`, non-blocking, speaker label and text from each `lines` pair. The time stamp is part of the first line's text.
* **Shimmer (art/VFX):** while the watch has Trace selected and the object is within 96 px, the statue shows a **shimmer ring + a small time-stamp glyph** (shape cue, rule R8). Once traced, the ring becomes a thin steady outline ("read"), restored from the flag after a load. `reduced_effects`: no animation, outline only.
* **Audio:** one soft chime on the first Trace, a quieter one on repeats; subtitles are the line text itself.

## 4. Save and load

`TraceMemory` has **no state of its own**. What it caused is already saved by existing services:
* the flag `flag_id` (`narrative_flags`, e.g. `ch01.npc.n01.traced`),
* the journal observation (`journal`).

On load the node reads its flag in `_ready()` to show the "read" outline. No save-schema change belongs to this class. (The unlock of an ability by a flag is in `ABILITY_UNLOCKS.md`.)

## 5. Text rules (checked by the generator and by tests)

* ASCII only; each memory line ≤ 120 characters; `JRN_MEM_*` ≤ 120 characters (`gen_ch01_text.py` already enforces the `JRN_` limit and ASCII).
* `MEM_<ID>_1` begins with `[hh:mm] ` where `hh:mm` is between `23:00` and `23:59`; `MEM_<ID>_2` is optional.
* Key families: `SPK_MEM_<ID>` (speaker), `MEM_<ID>_1/_2` (lines), `JRN_MEM_<ID>` (journal). `SPK_MEMORY` is the generic speaker for scene memories (e.g. `MEM_ANCHOR_TURNSTILE_*`).

## 6. Acceptance tests (given / when / then)

* **TEST-TM-01 — first Trace shows the lines, sets the flag, adds the journal entry.**
  GIVEN a `TraceMemory` with `object_id = ch01.arrival_platform.n01_conductor`, two `lines`, `flag_id = ch01.npc.n01.traced`, `journal_key = "JRN_MEM_N01"` and the flag unset; WHEN `InteractionService.request(&"player", id, &"trace")` is called; THEN `ok == true`, the dialogue box is active with `current_sequence_id == &"trace.ch01.arrival_platform.n01_conductor"` and `is_blocking == false`, `NarrativeState.get_flag(&"ch01.npc.n01.traced")` is true, and the journal contains `JRN_MEM_N01` as `"observation"`.
* **TEST-TM-02 — repeat Trace replays but changes nothing.**
  GIVEN TEST-TM-01 has run; WHEN the same request is made again; THEN `ok == true`, the sequence plays again, the journal still holds exactly one `JRN_MEM_N01`, and `memory_revealed` was emitted twice.
* **TEST-TM-03 — `use` is unsupported.**
  GIVEN any `TraceMemory`; WHEN `request(&"player", id, &"use")`; THEN `ok == false`, `reason == &"unsupported"`.
* **TEST-TM-04 — other abilities are unsupported.**
  GIVEN any `TraceMemory`; WHEN `request(…, &"rewind")`, `&"freeze"`, `&"fast_forward"`; THEN `reason == &"unsupported"` each time.
* **TEST-TM-05 — echoes cannot Trace.**
  GIVEN a recorded echo that includes a `trace` request; THEN `EchoService.get_events()` contains no `trace` event (watch abilities are never recorded; existing behaviour pinned for this class).
* **TEST-TM-06 — save/load keeps "read".**
  GIVEN the flag is set and the game is saved and loaded; WHEN the room is entered; THEN the node shows the "read" outline and the journal entry is still present; WHEN Traced again; THEN no duplicate journal entry exists.
* **TEST-TM-07 — placement: Trace picks the intended statue (real colliders).**
  GIVEN the room scene is loaded and the player stands on each listed stand spot with Trace selected; WHEN `PocketWatch.choose_watch_target` runs over the room's interactables; THEN the target is the commuter listed for that spot (table in `COMMUTERS_STEP1.md`).
* **TEST-TM-08 — placement: `E` is not stolen.**
  GIVEN the player on each `use`-object stand spot of the Step 1 specs; WHEN `Player.choose_best_interactable` runs; THEN the target is that use-object (not a `TraceMemory`).
* **TEST-TM-09 — text rules.**
  GIVEN `localization/ch01_text.csv`; WHEN every `MEM_*_1` is read; THEN each matches `^\[(23):[0-5][0-9]\] ` and every `MEM_*` line has ≤ 120 characters.
* **TEST-TM-10 — configuration errors are loud.**
  GIVEN a `TraceMemory` with no lines, or 3 lines, or a first line without a time stamp; WHEN `_ready()` runs; THEN `push_error` is reported (the test runner treats it as a failure unless the test expects it).

## 7. Alignment with TLF-050 and open points

* Names follow `docs/tasks/TLF-050.md` (`lines`, `flag_id`, `journal_key`, `journal_category`, `one_shot_dialogue`, `memory_revealed`, sequence id `trace.<object_id>`). This document adds the content rules (§5), the placement rules and the tests; it adds no behaviour that TLF-050 does not already require.
* With `one_shot_dialogue = false`, `DialogueBox` does not set the `heard.*` flag for memories, so repeats replay.
* The shimmer/outline art is a design-art/Flash item (`design/ch01/expansion/ART_WISHLIST_STEP1.md`).
