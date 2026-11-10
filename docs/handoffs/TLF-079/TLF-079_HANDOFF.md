# TLF-079 handoff: history dial current-value readout (Appendix D P0, D-P0-01)

Opus, branch `agent/opus-core-tlf079` from `origin/main` `fe4bfb1`. Not merged.

## Decision implemented

**The finding:** Sol's audit (`docs/reviews/AppendixD_P0_audit.md`, D-P0-01) found that the three Concourse West history dials (`dial_line`, `dial_platform`, `dial_time`) never show their current value. `HistoryDialPresenter` never uses `label_key()` or `index_changed`.

**The fix:** the Lead chose the HUD readout. It shows the **existing** localized label of the focused dial and updates after every Rewind or index change. It adds no wording, does not highlight the correct combination, never covers refusal feedback, and wraps long labels inside its panel.

## What changed

| Area | Change |
|---|---|
| `scenes/ui/HUD.tscn` | **New node:** `ReadoutPanel` (PanelContainer > Margin > `ReadoutLabel`). It is built like `FeedbackPanel`: 320 px wide, anchored bottom-centre, 8/4 margins, centred text, word wrap, `grow_vertical` upwards. **Position:** its bottom edge is 64 px above the bottom of the view, 4 px above the feedback line's slot, so it sits at (320, 444, 320, 32). **Colour:** the theme's normal text colour, while feedback stays red. It is placed before `FeedbackPanel` in the tree, so the feedback line always draws on top. Hidden by default. |
| `scripts/ui/hud.gd` | **Focused dial:** `focused_dial()` returns the PocketWatch target if it is a `HistoryDial`, since that is what a Rewind acts on. Otherwise it returns the player's interact target if that is a `HistoryDial`. It returns null while a **blocking** dialogue, a document or the journal is open. **Binding:** `_process` binds the readout to that dial: it connects `index_changed`, disconnects it from the previous dial, and shows `tr(dial.label_key())`. `_on_readout_index_changed` refreshes the text on the same signal, so a Rewind updates it at once and does not wait for a frame. **Blur:** with no focused dial the readout is hidden and unbound. **Layout:** each frame the readout's bottom is kept above the feedback panel's top. That holds when a long feedback line wraps and grows upwards, and the readout also moves above a non-blocking dialogue panel. A long value wraps, the panel grows upwards, and a later short value shrinks it back to one line. **Chapter complete:** hidden there, as the rest of the HUD is. |
| `tests/ui/test_dial_readout.gd` (new, 3 tests) | See below. |
| `tools/capture_tlf079.gd` (new) | Windowed capture script. Run it in a renamed scratch copy only. |
| `docs/handoffs/TLF-079/` | This handoff, the screenshots 01–04 and `capture.log`. |

**Not changed:**
- **Code:** `HistoryDial`, `HistoryDialPresenter`, the concourse scene, localization (no new keys), the selector switches (SO-01 in the arrival platform; the readout only reacts to `HistoryDial`), and the playthrough tests.
- **Docs:** ART_BIBLE and ADR_LOG are not touched.

**Two notes for review:**
1. **Interact target at the stand spot:** at the playthrough's `dial_line` spot (432, 152), the interact target is `reset_anchor_02`, not the dial. The watch target is the dial, which is why the watch target comes first.
2. **Non-blocking dialogue:** Beat 01 and the device voices are non-blocking and stay active while Elias walks (about 700 frames at boot). Hiding the readout for every dialogue would therefore hide it for long stretches, so the readout stacks above a non-blocking line and hides only for a blocking one.

## Tests: `tests/ui/test_dial_readout.gd`, 3 tests

1. **`test_readout_follows_focus_and_rewind`** (real input, Chapter01 in Concourse West):
   - No readout at the west door or by the turnstile.
   - When `dial_line` becomes the watch target, the readout shows `HILL ROAD` (index 5).
   - A real Rewind takes the dial 5 → 4. A listener connected after the HUD sees `[4, "HOLLOW QUAY", true]`, which proves the text is updated on `index_changed` itself.
   - Walking on, the readout shows `PLAT 5` at `dial_platform` and `23:57` at `dial_time`, each `tr(label_key())`.
   - Walking away (blur) hides it.
2. **`test_readout_does_not_hide_feedback`** (real input):
   - At `dial_platform`, Elias Rewinds the dial to index 0 and once more. The `no_history` refusal shows on the feedback line, and the readout shows `PLAT 6` above it, with no overlap and both inside the view.
   - Inside the toast's 2 s he walks to `dial_line` (readout `HILL ROAD`) and Rewinds it (readout `HOLLOW QUAY`). The feedback line keeps its text and its place, 28 px above the bottom.
3. **`test_label_keys_exist_and_long_values_wrap`** (HUD with a test session and dial):
   - **Keys:** all 18 `label_keys` of the three dials are read from `concourse_west.tscn`. Each is in `localization/ch01_text.csv` and translates.
   - **Fit:** the readout shows each value exactly, inside its 320 px panel and the view, above the feedback slot.
   - **Long value:** an existing long key (`JRN_PZ006_SOLVED`) wraps, and the panel grows upwards with the same bottom edge. With a two-line feedback line (`invalid_graph`) it stays above the feedback. Going back to a short value shrinks it to its slot.
   - **Dialogue:** a non-blocking dialogue moves the readout above the dialogue panel, and a blocking dialogue hides it; afterwards it is back in its slot.
   - **Blur:** hides the readout and disconnects `index_changed`.

**RED check:** in the dev copy, with `_update_dial_readout()` stubbed out (scene and fields kept), the run gives `TESTS: 0 passed, 3 failed`. The real code gives `TESTS: 3 passed, 0 failed` with no `ERROR` lines.

## Screenshots (windowed, 960 × 540 viewport, D3D12 Forward+)

Made with `tools/capture_tlf079.gd` in a renamed scratch copy. **Setup:** SO-01 and PZ-001 are marked SOLVED, Rewind is unlocked, Elias is placed on the `dial_line` stand spot and the setup's "Rewind unlocked." toast is hidden. **Rewind:** done through `PocketWatch.activate_watch()`. Numbers are in `capture.log`.

| Shot | Content |
|---|---|
| `shot_01_dial_line_index5.png` | `dial_line` focused at index 5: readout `HILL ROAD` at (320, 444, 320, 32). |
| `shot_02_dial_line_index4.png` | After one Rewind, index 4: readout `HOLLOW QUAY`. |
| `shot_03_readout_with_feedback.png` | The `no_history` refusal (two lines, 320 × 35 at y 477) under the readout, which has moved up to y 441. In `capture.log` the "WITH FEEDBACK" line was printed before that layout pass and still shows 444; the moved rect appears in the "BLUR" line. |
| `shot_04_blur_no_readout.png` | Elias by the turnstile: no readout. |

## Validate

The raw lines are in the Lead message. `tools/content` is unchanged, so the Python tests are not required; they were run anyway.
