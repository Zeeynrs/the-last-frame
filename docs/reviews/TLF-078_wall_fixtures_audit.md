# TLF-078 wall-fixture audit and owner rule

2026-11-09. Main baseline: **`3948ec54d13e43791bff0c2d1612f3a00e134555`**, all ten Chapter 1 room scenes. Additional pilot: **`90da97014250b2ac89e41b38258e7b90f303c42c`**, Arrival Platform v2. Branch: `adityadaffa522/tlf-078-wall-fixture-audit`. No game, asset, generator or scene edits; no engine/game launch or real-save use.

The owner has withdrawn the frontal-fixture exception. ART_BIBLE A.3/A.4 now require **follows the slope; flush on the face; inside the wall silhouette**, with face-specific pivots/anchors and the same rule for text/state art. Previous compact-frontal acceptance in Sol's reviews is historical and does not exempt the pilot's selectors or clocks under this decision.

## Redo count, without repeated-placement inflation

**20 fixture designs are affected, comprising 40 distinct existing state PNGs.** They require **42 face/state variant slots across 21 face-specific design sets**: the shared phone needs both N and W versions. The CSV's `shared_art_key` is the original PNG stem, independent of room and face, so every identical shared source counts once. Target work is deduplicated by `(shared_art_key, wall_face)` separately.

**One of those slots is already supplied** by the approved TLF-073 N-face CLOSED TRACK variant at `ab9f75904962da3ccf7ad783064437893378ae9b`. Reuse it; do not redo Argon's finished plaque. Thus the complete family budget still to produce is **20 face-specific design sets / 41 state variants**. This is a work inventory, not permission to edit the assets in this task.

The full count includes declared support states: three jammed dials, ringing phone on both faces, denied card reader and engaged breaker C. These are not currently selected by their presenters, but are documented/preloaded family states and must obey the rule when supplied. Excluding those support-only states, currently selected art accounts for **34 original PNGs / 35 face-state slots**, of which **34 slots remain to produce** after reusing the TLF-073 notice. Both totals are stated so authoring and runtime budgets are not confused.

| Source design / family | Required face | State PNGs / target variants | Notes |
|---|---|---:|---|
| Digital clock 23:59 | N | 1 | Shared by every clock, including pilot's two and the enlarged atrium clock. |
| LINE selector | N | 3 | pos0/1/2; main and pilot share the same three sources. |
| PLATFORM selector | N | 3 | pos0/1/2. |
| CAR selector | N | 3 | pos0/1/2. |
| Release lever | N | 3 | Main's published wall-mount brief; idle/buzzing/accepted. Pilot makes this control freestanding instead and is excluded from wall redo. |
| Call-box phone | W | 2 | Concourse idle/ringing; ringing is declared support. |
| Same call-box phone | N | 2 | Signal intercom / street payphone share it; not two separate designs. |
| LINE flap dial | N | 2 | idle/jammed; jammed not selected by current presenter. |
| PLATFORM flap dial | N | 2 | idle/jammed. |
| TIME flap dial | N | 2 | idle/jammed. |
| Mounted conduit | W | 1 | Mounted state only; fallen ground state is not sheared. |
| Ticket-terms notice | W (proposed) | 1 | Current node is interior; W is an art-direction target, not a canon wall already there. Layout may choose N instead without changing the source/state count. |
| Counterweight gear | N | 3 | Already iso, but wall-fit housing needs revision: idle alpha spans 62 px in wall-normal depth versus a 48 px wall. Moving the existing image cannot contain it. |
| Fire shutter / inner shutter | W | 2 | Two apertures share the same closed/raised PNGs. Existing art runs N; divider runs W. Correct-facing iso variant, not a mandatory blind shear. |
| PA horn | N | 1 | Frontal horn and mount. |
| Card reader | W | 3 | idle/accepted/denied; denied is documented support, unbound at runtime. |
| Lever-switch housing (wall breaker A) | W | 2 | off/on; preserve freestanding uses of this shared art. |
| Badge A overlay on wall breaker A | W | 1 | Runtime-created Sprite2D child; must follow the control face too. |
| Breaker C | W | 3 | idle/browned_out/engaged; engaged preloaded but unselected. |
| Wall wiring chart | W | 1 | Signal bus chart uses a floor-diamond clipboard; needs a proper wall rendition, preserving floor pickups. |
| CLOSED TRACK notice | N | 1 | Pilot-only legacy flat art; TLF-073 projected replacement already approved. |
| **Total face/state slots** | | **42** | **40 shared source PNGs, 20 original designs; 1 target slot ready, 41 to produce.** |

`needs_sheared_variant(y/n)=y` means **a compliant wall variant is needed**, either shear or correctly facing/wall-fit iso art as the owner permits. It is intentionally `y` for the N-facing shutters used on W dividers, the floor-style breaker housing, the floor-paper chart and the oversized iso gear even though their `currently_frontal` value is `n`. A flip is usable only if facing, light and all three A.3 tests pass.

## CSV scope and reading

[TLF-078_wall_fixtures.csv](TLF-078_wall_fixtures.csv) contains **103 state/use rows across 67 source-use records**, covering all ten main rooms plus the pilot. Six of the use records are older root archway copies at the exact same placement as canonical frames: both node paths are inventoried, but their shared PNG is counted once. There are 61 logical use groups after those duplicate copies are consolidated.

The eight headers retain the requested annotations literally: `room,object_id,sprite,wall_face(N|W),currently_frontal(y/n),needs_sheared_variant(y/n),shared_art_key,notes`. One row is one placement **and state image**, not one commissioned design. `visual:<path>` identifies a drawable without a unique canonical object ID, such as a second clock. Real interactable IDs stay unchanged.

`ch01.arrival_platform@pilot90da970` is a snapshot label, not a new runtime room ID; the main Arrival rows remain separate. Notes pin every row to its source SHA and node path. No absent pilot departure-board row is fabricated: it was deliberately removed. The approved TLF-073 W board and catalog-only R&D sign/door/sector-mark props are not instantiated in either audited snapshot and are not included in this current-use redo count.

`wall_face` names the **required rendered plane**, not compass exit direction: E/W door openings use the W/down-left plane, N/S openings use N/down-right. Main clocks are N; concourse phone is W; signal intercom/street phone N; security card reader W; signal wall breakers W. The ticket-terms W target and mounted-conduit W target are explicitly inferred from intended mount/placement and remain layout choices.

Already correctly oriented iso architectural frames, platform/staff doors, hatch states, staff barrier and niche grille are listed with `n/n`. That means **no new plane-specific source art is identified**; it does not certify every current anchor or future aperture as flush. Integration must still apply all three new tests. Ordinary wall modules/corners are structure rather than attached fixtures and are not multiplied into the CSV.

## Boundary decisions and completeness

- Inspected all scene Sprite2Ds, referenced Texture2Ds, default presenter preloads/state maps, and runtime-created Badge A. Used current per-object placement/puzzle evidence when generic older prose conflicted with the scene.
- Included gear because `CH1-PZ-002.md` explicitly calls it north-wall-mounted. Included bus chart because expansion explicitly calls it a wiring chart **on the wall**. Included wall-intended legacy controls that currently sit on the floor; notes call out missing/incorrect mount rather than assuming z=7 proves compliance.
- Excluded reset consoles in rooms 2/3/4/6/7: current per-object placement and iso console art put them in YSort_Actors, despite older ROOM_GRAPH wall-box/valve wording. Invisible `reset_anchor_02` has no art to redo.
- Excluded floor-standing validator console, turnstile, security lane gate, capacitor, reset pedestals, upper route board, junction levers A/B, dead relay C and signal breaker B/badge B. Their current per-object placement/presenter rules are freestanding. Interior trench railings are guards; the separate niche doorway grille is included as architecture.
- Excluded generic floor/inspect clipboard pickups (`doc_evac_notice`, `doc_tech_log`, `transit_pass_pickup`, `audio_mira_01`, `doc_index_plaque`, last-service document and hatch/log documents). A name containing *plaque/chart* alone does not make a floor pickup a wall fixture. Upper relay memo is pinned to a relay **box**, not explicitly a wall; its floor-diamond art on the undrawn E side is excluded with that ambiguity. If layout changes these roles, add wall variants rather than altering all shared pickup art.
- The fallen conduit remains a floor pose. State art should be added as face-specific variants; do not shear shared masters in place and break their floor uses.

Source trail and dedupe evidence: [fixture-families.json](TLF-078/fixture-families.json), [counts.json](TLF-078/counts.json), [verification](TLF-078/verification.txt). Source inspection used the exact main archive, scene/presenter code, `CH01_PLACEMENT_SHEET.md`, ROOM_GRAPH, the Step 1 mockup mount brief, puzzle/expansion specifications and the native PNGs. Room subsets were independently inventoried in parallel, then reconciled by Sol; no game or asset files were changed.

**Handoff:** the new Bible rule is effective for all wall fixtures, including previously accepted compact frontal ones. Commission plane-specific variants by shared source/target face, reuse finished TLF-073 art, and verify mount/silhouette again in each rebuilt room. Sol does not merge.
