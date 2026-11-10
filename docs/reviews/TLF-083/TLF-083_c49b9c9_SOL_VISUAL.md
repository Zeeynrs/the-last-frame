# TLF-083 round 2 — Sol visual re-check

**Verdict: APPROVE VISUAL** on **`c49b9c99af196fe26e67f839285bc2f139dda1fe`**, `origin/agent/opus-core-tlf083`; handoff supplement **`aa1b69a`**. Sol, 2026-11-11. **The visible Elias-spotlight P1 from `b71c0a9` is closed.**

Reviewed the updated native spawn/gate shots and all three motion sheets in `docs/handoffs/TLF-083/`: `elias_motion_lit.png`, `elias_motion_unlit.png`, `elias_motion_lit_greyscale.png`. Each sheet is 384x768: eight facings (S, SE, E, NE, N, NW, W, SW), four native 96x96 samples per row (idle 0, walk 1/3/5), with position changes between columns.

- **Oval:** the conspicuous blue capsule from round 1 no longer reads as a following spotlight in the full frames or sampled poses. A small local value lift remains, as intended; this is not a claim of mathematically zero background influence. It no longer competes with the scene's motivated light accents.
- **Body:** head/face, shoulders, coat mass, trousers and the walking leg separation remain readable across all eight facings. Rear views and boots are the weakest/darkest areas, but the contour and step changes remain discernible in greyscale. Do not enlarge or strengthen the zone to recover unlit-sheet brightness.
- **Values:** source confirms radius `(18,28)`, offset `(0,-20)`, inner `0.85`, lift `1/0`. Accept this default for A2 and the stated A1 use. An actor/silhouette receiver is not required to close this P1 on the supplied evidence. Maintenance A3 retains its separate whole-body/stress-proof requirement.
- **Fallback:** independently checked setting-off PNG bytes equal unlit for both spawn and gate. The previous board/dado/clock/train findings are unchanged; no new pass-wide visual defect is evident in this re-check.

This approves the **Part 1 pass/default-zone correction**, not Arrival's final lighting or Concourse's yet-to-be-authored composition. Part 2 retains its normal D.7 room/target/state/active-VFX and spill checks; those are not new blockers added by this review.

Scope: sampled motion-sheet/native-image inspection and source verification only; no engine run, save access, scene/asset edit or merge. Technical validation remains with Opus/Lead. Earlier review file preserved.
