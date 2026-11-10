# TLF-081 Concourse facing art implementation plan

> **For agentic workers:** Use `superpowers:executing-plans` for this owner-authorized inline asset task. Lead assigns the independent metadata/gate review to Opus; Lead and owner judge the proof. Do not merge.

**Goal:** Deliver the 13 PNG/PXO variants ordered by the accepted Part 1 audit.

**Architecture:** Deterministic palette-indexed layers in `tools/art/gen/tlf081_concourse_wall_art.py`, registered in the existing generator pipeline. Reuse Argon's ten wall designs only after inspection. Author the three freestanding validator states. Mount proofs use the actual existing N/W wall exports, not substitute rectangles.

**Tech stack:** Python, Pillow, Pixelorama 1.2.3, Godot 4.7.2, PowerShell validation.

**Spec:** Accepted audit `5096ef8`; main baseline `f21aef6`; TLF-081/PATTERN from `origin/lead/tlf-080-spec` `085b554` and the owner's Part 2 instruction. No scenes, old frontal art, fallen conduit, palette or story text changes.

- [x] Add and run a failing acceptance check for the exact 13 registered variants.
- [x] Inspect/adapt wall generator; author grounded N-parallel validator; document pivots and exact mount coordinates.
- [x] Register/export all 13 via Pixelorama, add metadata, generate uncropped 960x540 module proofs and nearest x2.
- [x] Check exported pixels against actual wall alpha, state differences, projection, fixed 16x8 validator footprint and preserved legacy files. Inspect colour/greyscale proof visually.
- [x] Run all four requested gates; retain raw logs. Run engine validation in a renamed isolated scratch copy with a custom save directory.
- [x] Write honest handoff and review full diff. Delivery action: commit/push this branch only; report SHA after remote verification.

## Execution ledger

- Branch starts at `origin/main` `f21aef6899d183e5101db9dc369811bd10a18455` in Sol's already-isolated worktree. Argon's worktree is read-only.
- Inspection: Argon's 890-line script contains ten wall variants, no validator, and 640x360 cropped/composite proof layouts. Keep inspected drawing primitives; replace proof layouts and ambiguous mount comments. The accepted audit already supplies the design authorization; no repeated design approval is needed.

- RED: exact-delivery test failed with all 13 stems absent. GREEN after registry/export; actual-wall-alpha, phone-feature projection and greyscale/bank checks pass. Added a separate RED/GREEN provenance check because the old PXO template incorrectly credits Claude by default. Optional per-asset author metadata preserves every legacy byte while correcting only these 13 sources.
- Ruling: replace the draft's cropped 640x360 pseudo-room mockups with four uncropped 960x540 / nearest-x2 colour/greyscale source-module proofs. This proves wall fit and proposed bank spacing; final TLF-080 composition/lighting remains an independent integration gate.
- Native self-review: panel slopes and cabinet volume are readable, states differ without hue; fine glyphs remain small category/state cues. The validator cabinet overhangs its 16x8 plinth; retain the existing collision rectangle. Owner/Lead judge that volume and final room fit.
- Ruling: the production PXO gate is `verify_pxo.py --task TLF-081`, covering all 13 delivered sources after the author-header correction. The redundant broad legacy scan was stopped without claiming a result. Full metadata checks and generator reproducibility still run globally; all 560 existing PNG/PXO bytes match baseline Git blobs. This keeps validation proportional to the asset-only change.
- Completed gates: 314 PNG checks; global regeneration and four proof checks; 13/13 task-scoped Pixelorama size/export/byte checks; scratch import, 182 script parses, 503 tests / 0 failed / 0 SCRIPT ERROR / clean leaks. All final engine inputs match scratch. Real save inventory (140 files) unchanged.
