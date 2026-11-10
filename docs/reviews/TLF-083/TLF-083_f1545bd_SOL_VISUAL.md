# TLF-083 Part 1 — Sol visual review

**Verdict: CHANGES REQUIRED** on **`f1545bd821016d0c2c084aadfcfdb24c0671c811`** (`origin/agent/opus-core-tlf083`). Sol, 2026-11-10. Handoff/evidence supplement: **`70ba0e9`**. Palette-space model and information protection accepted; **change the Elias-zone default before the first lit room**. Arrival here is a runtime demonstration, not its final lighting approval.

Reviewed spawn/gate lit, unlit and greyscale PNGs in `docs/handoffs/TLF-083/`, plus the pass/resource/capture source. Independently compared setting-off PNG bytes with unlit: **identical at both positions**. No engine run, project edit or save access.

## 1. Elias — smaller and lower-lift, not a moving spotlight

**The present oval is not accepted.** At both positions the 30x45-radius zone, offset `(0,-20)`, inner 0.8 and lifts 2/1 visibly restores a blue patch around Elias. Greyscale still shows the oval, so this is a value/receiver problem, not blue tint. Its outer dimensions are 60x90 around a 32x48 sprite; reducing it from the first spike was insufficient. Do not change it to **2/2**: that fills the ring and leaves a stronger hard-edged patch.

**Concrete next default for A=2:** radius **`(18,28)`**, offset **`(0,-20)`**, inner **`0.85`**, lifts **`1/0`**. This revises my provisional TLF-082 personal-zone 2/1 value after seeing the runtime proof. Keep hard bands and dither off. This leaves the body one ramp step down rather than restoring it fully, with a much smaller, weaker floor footprint. Analytical coverage of the existing 80-frame iso sheet puts every non-outline/non-shadow body pixel inside this proposed inner ellipse (maximum normalized distance approximately 0.813 < 0.85). That is a source-coverage check, **not a rendered readability approval of the new values**.

Use this one restrained tuning pass in the Concourse proof. Acceptance: face/coat/trousers/feet readable at native size, no conspicuous oval during idle/walk/turn, and no floor beacon moving independently of a motivated source. **If it still reads as a spotlight or the darker body fails, use an actor/silhouette receiver rather than enlarging or strengthening the ellipse again.** Palette-index masking alone cannot separate trousers from terrazzo; actor identity/visible sprite coverage can. A rectangular background patch is not the solution either. No new sprite painting, dither, bloom or full-bright actor exemption is requested.

For A=1 rooms use 1/0; do not blindly copy the weaker A2 setting to maintenance A=3, whose whole-body readability still needs lift 2 and its own stress proof per TLF-082. Room values remain data, not one universal brightness preset.

## 2. Train car — darkened correctly, with a shared-index caveat

It **is not bypassing the pass**. In the train crop `(494,362)..(594,438)` at both positions, I measured **1,598 roof pixels 15 -> 13**, **952 pixels 13 -> 11**, and **587 pixels 12 -> 01**. The roof sample `(540,380)` changes from Chrome Specular 15 to Brushed Steel Mid 13. It remains lighter than the nearly-black floor because its authored steel starts higher in its ramp. That planar/material separation is correct; do not raise room ambient or add a special train light to make everything equally black.

The cyan windows **27/28 remain 27/28** under the global exemption (for example `(550,411)` stays 27). Thus some decorative accents really are unchanged, as with the side-memory shared-index issue. They must not be mistaken for new ability targets or rival the focal clock in the eventual Arrival composition. If that composition needs them quieter, use a scoped non-emissive receiver override or a limited pigment correction; a lift-only region cannot darken exempt indices. **Do not change the global threshold away from 25.** This train-specific room treatment is not a Part 1 blocker and is not a request to relight Arrival now.

## 3. Board, dado, clock — accepted pass behavior

- **Board:** accept the index-24-only QUAD protection. The glyphs remain legible without recovering a bright casing/wall patch. Opus's capture log reports **234/234** kept at both positions, with **1,957 other pixels inside the board face still darkened**; the source restriction matches that result. This follows TLF-082's information-preservation rule.
- **Dado:** accept threshold 25 and the visible reduction of the long orange perimeter. The log reports 1,148/1,112 index-24 pixels darkened outside the board. Local restoration near a real source is allowed; exempting all 24 globally is not.
- **Clock:** `23:59` retains the small hot amber core and reads as the main warm light accent. The gate helper is subordinate; there is no additive bloom or violet architectural wash. Board text remains information rather than a broad light pool. Final focal placement/receiver clipping belongs to each room's proof.
- **HUD/fallback:** HUD and target marker remain above the pass. Setting off restores the baseline exactly in the supplied captures; no dimmed UI defect is visible.

## 4. Before Concourse becomes the first lit room

1. Apply the smaller/lower-lift Elias default above and show it moving, with native + greyscale proof; the current following spotlight is the **P1** requiring this verdict.
2. Keep **A2**, one dominant clock/decision focal, one lower navigation helper, threshold **25**, dither off, and no light summation/bloom. Information regions are narrow exceptions, not more decorative lamps.
3. Prove caps, N/W faces and exits do not receive unexplained circular spill. Use bounded QUAD/receiver regions where placement/radius cannot avoid it; an actual failing composition needs masking before acceptance, not a promise after merge. No blanket painted-mask requirement for every room.
4. Include real in-range targets without the HUD marker, puzzle states, lighting on/off and active Trace/Echo/Rewind/Freeze. Idle PNGs do not establish semi-transparent VFX/target readability after nearest-palette snapping. Keep technical performance, official whole-suite/leak and router gates with Opus/Lead; this visual review does not certify them.

Scope: one docs-only review from `origin/main` `f21aef6`, no merge. The new Elias values require the next rendered proof; all other room-specific observations above are bounded to this demo.
