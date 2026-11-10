# TLF-080 fix round — Sol visual re-review

**Verdict: CHANGES REQUIRED** on **`db7efcf13db385a883bf55bdda99d131567c5dbc`**, `origin/adityadaffa522/tlf-080-concourse-v2`. Sol, 2026-11-10. Four native `docs/handoffs/TLF-080/{arrival,gate,dial,east_door}_960x540.png` and exact scene/presenter source inspected. **Divider and TLF-081 placement are visually accepted; one P1 remains: the fallen conduit does not visually pin the gate.**

## Closed findings / art swap

- **Divider:** all eight full/half sprites match the previous table, including right-half pivot `(0,24)` at `(336,184)` and left half at `(304,200)`. Caps stop at y=7/9; the two-tile opening reads clearly. The console and courier remain identifiable; no cap hides the control face. This now explains the collision boundary without making the hall feel cramped.
- **Floor:** the orange patch is gone. Evacuation paper is visible on the floor at `(15,11)`, clear of the pillar. Both prior findings are closed.
- **Facing:** phone and ticket notice now follow W; dials follow N; validator has a grounded iso body. No remaining screen-frontal wall fixture is evident. Bench, reset console, turnstile, pillar and staff door keep their appropriate existing iso forms. The fallen pipe is floor art, not a missing W-facing variant.
- **Actual mounts:** phone PNG TL `(260,36)`; dial TLs `(544,134)`, `(576,150)`, `(608,166)`; validator `(608,198)`; mounted conduit `(112,102)`; notice `(72,146)`. Presenter code now preserves dial zero-offset and the validator's `(-16,-42)` floor pivot; conduit uses separate mounted/fallen transforms. These match section 14.2 and the actual WallN/WallW rectangles. One N `23:59` clock remains at `(480,99)`.
- **Source-mask check:** all six dial states and both phone states fit their wall masks; mounted conduit/notice have 0 overflow and 0 mutual overlap; TIME versus all three validator states has 0 overlap. Thus all **13 authored variants** pass the prescribed source geometry. The four screenshots do **not** demonstrate every state: ringing is not referenced by the static phone Sprite, and the validator presenter selects idle/accepted, with rejecting retained as a support export. Those support-state limits are not a new blocker or a claim of thirteen runtime captures.

## P1 — Fallen conduit: smallest coherent correction

**Not fine at the current position.** Its floor pivot remains `(144,160)` beside the W wall, about 179 screen pixels from gate `(320,192)`. In every shot it resembles a second bench. `ConduitProp.is_pinning()` and PZ-001's clue describe it pinning the turnstile, but no visible contact connects the objects. The new divider makes that separation clearer.

**Placement proposal, no redraw:** start the fallen state's existing sprite at floor pivot **`(328,184)`**, tile **`(7.75,7.25)`**, on the entry side of the gate. With unchanged fallen pivot `(24,26)`, its PNG TL is **`(304,158)`**. The bent bundle then contacts the turnstile arm instead of dressing the distant wall. Source-mask projection at this candidate has **0 overlap with the courier and reset console**, and intentional contact with the gate. Show the gate identity/control glyph clearly in the final native proof; fine-tune within this local contact area if needed.

**Do not implement this as a distant sprite offset alone.** The fallen state's Rewind target/selection point and reachable stand spot must follow the visible fallen object. Keep the same object ID, history, pin/reset/solve rules and existing art; mounted state must still return to W-wall PNG TL **`(112,102)`**. Flash/Opus should choose the smallest state-derived target/transform implementation. This review does not approve a new interaction architecture or invisible target left at the wall.

The proposed target is 24px from entry safe anchor `(304,184)`, versus courier distance 17.89px, so it does not obviously steal that nearest-candidate relationship by distance alone. **Still re-run TEST-AU-08 and the actual capsule/selection checks**; source distances are not a gameplay proof. Re-prove Rewind conduit -> mounted, gate still requiring its own Rewind, reset and solved latch, plus native before/after shots. Keep hint 2; repair its visible causal relationship rather than rewriting it to excuse the layout.

**Scope:** one short additional review file; previous review preserved. No engine/validate run, scene/asset edit or save access. Static geometry is accepted as stated; interaction reach and active-state visual proof remain Flash/Opus gates. No merge.
