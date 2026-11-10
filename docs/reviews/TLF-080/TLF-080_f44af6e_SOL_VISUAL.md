# TLF-080 Concourse West v2 — Sol visual review

**Verdict: CHANGES REQUIRED** on **`f44af6ec1f9d7b1300669a2cff52267c0f9012f5`**, `origin/adityadaffa522/tlf-080-concourse-v2`. Sol, 2026-11-10. Spec: `origin/lead/tlf-080-spec` **`e3f7b76`**. Read all four `docs/handoffs/TLF-080/{arrival,gate,dial,east_door}_960x540.png` at native size and the exact scene/source. Pending TLF-081 frontal art is explicitly exempt: **its facing/temporary floor-level presentation is not counted as a defect**. No game run, scene/asset edit or save access; this is one review document only.

## Required fixes

1. **P1 — Make the x=8 barrier visible.** In all four shots the hall looks continuously walkable around the small turnstile. `TurnstileDividers` actually blocks `(448,128)..(336,184)` and `(304,200)..(192,256)`, i.e. x=8, y=0..7 / 9..16. **Yes: use existing `ch01_env_wall_partition_low_e_idle.png`** along those exact segments. It follows the down-left plane, has 16px height and avoids turning the entry hall into a tall enclosure. Exact recipe below. Keep the existing two-tile aperture, colliders and puzzle cluster unchanged.
2. **P1 — Separate the evacuation paper from the pillar.** `doc_evac_notice` is `(416,272)`, its `DocSprite` offset `(-8,-12)` gives PNG TL `(408,260)`. `PillarSprite` is `(416,296)`, offset `(-16,-56)`, TL `(400,240)`. **All 132 opaque clipboard pixels intersect the pillar's opaque silhouette.** Depending on sorting, it becomes hidden or looks pasted onto the pillar, rather than a floor pickup. Small safe layout proposal for Lead: move the document to tile **`(15,11)` = `(384,272)`**, preserving its art/offset, TL `(376,260)`; source-mask overlap is **0** there. Update its stand spot/reach evidence. A move merely to `(16,11)` still leaves 37 overlapping pixels. This is existing floor art, not a frontal placeholder defect.
3. **P2 — Remove the stranded amber patch.** Decoding the actual floor data gives **448 cells: 428 dark, 17 cracked, 3 tactile/amber**. All **192 original cells retain their original values**. Amber cells remain **`(3,4)`, `(3,5)`, `(3,6)`** in the TileMap, matching the bright patch near spawn in every screenshot. Replace those three source-2 entries with source **0**. **Do not move this old three-cell stripe to x=8 by default:** it would imply a route through the new solid divider. The turnstile/opening and low partitions provide the necessary cue. Any later tactile threshold should be confined to the real gate approach, not the entire divider or a new puzzle-answer marking.

## Divider placement — exact reuse, no new art

Use `T(x,y)=(320+16(x-y),64+8(x+y))`, `centered=false`, **offset = negative pivot**. Whole module: 32x32, pivot **`(16,24)`**. Each run is **seven** tiles long, so use three whole modules and one half at the gate end. Do not put a whole two-tile module at y=7 or y=9: that intrudes into y=7..9 and narrows the aperture.

| Run / virtual tile anchor | Node position, world px | Source region (`Rect2`, px) | Pivot |
|---|---|---|---|
| North `(8,1)` | `(432,136)` | whole 32x32 | `(16,24)` |
| North `(8,3)` | `(400,152)` | whole | `(16,24)` |
| North `(8,5)` | `(368,168)` | whole | `(16,24)` |
| North gate-end `(8,7)` | `(336,184)` | **right half** `(16,0,16,32)` | **`(0,24)`** |
| South gate-end `(8,9)` | `(304,200)` | **left half** `(0,0,16,32)` | `(16,24)` |
| South `(8,11)` | `(272,216)` | whole | `(16,24)` |
| South `(8,13)` | `(240,232)` | whole | `(16,24)` |
| South `(8,15)` | `(208,248)` | whole | `(16,24)` |

For halves enable Sprite2D regions; the changed right-half pivot compensates for the removed 16 source columns. These are virtual whole-module anchors, not the half-run midpoints. Preserve nearest filtering and the existing wall sorting convention. Show both sides of the gate/console/courier cluster after dressing: caps must meet the collision endpoints and must not conceal the opening, controls or approach feet. No new collision is requested.

## Actual walls versus TLF-081 section 14.2

The real `WallN_0..13` anchors are `(336+32k,72+16k)` and `WallW_0..7` anchors `(304-32k,72+16k)`, all `centered=false`, offset `(-16,-56)`. **They match the assumptions in the corrected `f84f19e` recipes.** The pending swap is of **prop textures and presenter transforms, not wall-module textures** (the handoff §6 wording should be corrected).

| Fixture / body | Actual module image TL | Required final prop PNG TL / check |
|---|---|---|
| Existing N `23:59` clock | **N5 `(480,96)`** | Current `(480,99)` is correct; opaque overflow **0**. Handoff's N4 label is wrong. One clock draw. |
| W phone | W1 `(256,32)` | `(260,36)`; logical anchor `(280,92)` is correct. Handoff's `(5,5)` / N-wall note is stale. |
| LINE / PLATFORM / TIME | N7 `(544,128)`, N8 `(576,144)`, N9 `(608,160)` | `(544,134)`, `(576,150)`, `(608,166)`; use dial face pivot `(0,0)`, not selector `(16,40)`. |
| Mounted conduit | W6 `(96,112)` + W5 `(128,96)` | `(112,102)`; logical `(144,160)` matches Lead. |
| Ticket notice | W7 `(64,128)` | `(72,146)`; logical `(88,188)` matches Lead. |
| N-facing freestanding validator | Floor anchor `(624,240)` | `(608,198)`, pivot `(16,42)`, retain 16x8 collider. |

Using the unchanged TLF-081 PNGs against these actual wall rectangles, corrected conduit/notice overflow and mutual overlap are **0/0/0**. Door clearance remains 1.125 tiles. This is a **source-geometry check of the pending swap**, not a claim that the final art already runs in `f44af6e`.

Before final art acceptance, apply the runtime recipes: the dial presenter currently resets offset to `(-16,-28)`, validator to `(-12,-30)`, conduit to `(-24,-26)`. A scene offset alone can be overwritten in `_ready()`. Conduit mounted/fallen require separate transforms; preserve the fallen floor file. Recheck all supplied states after wiring, especially TIME/validator and the two W fixtures together. These are swap requirements, not extra placeholder defects.

## Remaining prop/space check

| Visible family | Rule 9 / overlap judgement |
|---|---|
| Bench `(496,184)` | Existing iso, N-parallel, open-floor placement; reuse unflipped. No facing redraw. |
| Reset console `(304,216)` and turnstile `(320,192)` | Existing iso bodies; compact approved puzzle cluster. No new facing defect. Keep their rigid offsets; check their silhouettes again with the divider art. `reset_anchor_02` is invisible logic, not another cabinet. |
| Pillar `(416,296)` | Existing iso; paper intersection is the local crowding defect above. Its visual foot is 8px below its logical collider anchor, retained from baseline; this review does not re-baseline collisions. |
| Staff door / aperture at `(640,352)` | Existing W-plane art and offset `(-16,-56)` fit the east opening. Both west/east archways have root/canonical duplicate draws at the same rectangles: two openings, not four props; cleanup is secondary. |
| Five commuter statues | Existing poses, not wall cabinets; courier and four-person group match the specified translated layout. No new visible footprint crowding requiring a redraw. |
| Fallen conduit, paper, floor | Fallen conduit remains floor art; ticket terms is a W fixture pending swap; evacuation paper must move as above. No unidentified extra cabinet family. |

**Overall:** the enlarged hall reads substantially less cramped in all four views. Do not widen it further or add filler now. The remaining problems are the invisible divider, a misleading inherited floor patch and the paper/pillar collision. The gate cluster needs a close re-proof after divider dressing; the larger empty hall is not itself a defect.

**Verification/scope:** inspected four native PNGs and exact scene/presenter source, decoded TileMap data, computed the stated opaque-mask intersections and checked actual module coordinates. Source-pixel footprints of all eight full/half partition placements stay within y=0..7 or 9..16, with no aperture intrusion. No engine/validate run or full gameplay sign-off; Flash/Opus retain reach, sweep, sorting and final swap tests. One docs-only commit from `origin/main` `f21aef6`; real save untouched; no merge.
