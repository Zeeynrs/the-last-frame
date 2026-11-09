# ART_BIBLE Appendix D / character study — CHANGES REQUIRED

Sol, 2026-11-10. Reviewed **`60352a0ec3cd8ae2d08ef256ddd9a32c18286968`**, `origin/lead/art-bible-appendix-d`, against its exact parent **`ca140a90f28b279bc6599cb76e71fa0258492b8f`**. Review only: no ART_BIBLE, reference, scene, asset or runtime edits. The proposed direction is sound; three current-contract conflicts need correction before approval. Locations below refer to ART_BIBLE at `60352a0`.

1. **Restore the settled Ch1 scarf/watch status.** C.5.3:482, C.5.5:514, D.5:636 and D.11:702–705 present decisions as pending/open. ADR-022 A3 (`docs/ADR_LOG.md:381`) already retains Elias v2, prohibits his red scarf and watch-check clip, and records the Operator scarf-hidden export. `ASSET_METADATA.md:868` confirms the populated `Scarf` layer is hidden in exports/proofs; `:1151` records the neutral side-view interaction. No visible shared scarf or matched Elias watch-check animation is shipped. Do not reopen those Ch1 decisions through new art guidance.

   Exact replacements:

   - Replace the C.5.3 Operator scarf bullet at line 482 with:

     > - **Ch1 scarf status (ADR-022 A3):** Elias v2 has no scarf; the Operator's scarf is hidden in the shipped Ch1 export. Keep the populated, removable `Scarf` source layer. A visible shared-scarf clue is deferred to a later owner-approved chapter decision.

   - Replace the first two sentences of the C.5.5 approval paragraph at line 514, retaining the following review/ownership sentences, with:

     > **Approval gate:** ADR-022 A3 already settles Chapter 1: retain Elias v2, add no red scarf or Elias watch-check clip, and keep the Operator's scarf hidden in the shipped export. Elias v3 and a visible shared-scarf clue are deferred; reopening them for a later chapter requires a new owner decision.

   - Replace D.5's closing paragraph at line 636 with:

     > All proposed character polishing goes through the existing acceptance and approval workflow. ADR-022 A3's Ch1 decisions remain binding: Elias v2 without a red scarf or watch-check clip; Operator scarf hidden in the shipped export, with its removable source layer preserved. The Operator's approved watch-check animation does not establish a matching Elias clip. Earlier Appendix C pending-decision wording is historical and is superseded by ADR-022 A3.

   - Replace D.11's Elias, scarf and watch-cadence bullets with these respective lines:

     > - **Elias v2 / v3:** Chapter 1 retention of v2 is resolved by ADR-022 A3; v3 is deferred, not awaiting a Ch1 production choice.
     > - **Scarf link:** no red scarf on Ch1 Elias; the Operator scarf is hidden in the shipped Ch1 export. Preserve its removable source layer. A visible shared-scarf clue is deferred to a later owner decision.
     > - **Watch-check cadence:** preserve the approved TLF-062 Operator animation. No Elias watch-check clip is authorized for Ch1; do not claim shared animation parity or add a clip to establish it.

2. **Preserve the approved Beat 06 Trace-memory exception.** The new blanket “broadcast only” wording conflicts with ADR-025 (`docs/ADR_LOG.md:420`), the approved multi-perspective spec V6, and `ROOM_GRAPH.md:37`, which already has Mira's Trace silhouette and `ch01.fragment.mira_departure`. C.4:386 explicitly preserves existing Trace/story content. The prohibition should cover new present-day physical encounters and unapproved Mira art, without cancelling the memory pilot or upgrading its placeholder into approved final Mira sprites.

   Exact replacements:

   - In C.5.1:454, replace `Mira remains a **silent, static broadcast image** in Ch1.` with:

     > Preserve Mira's **silent, static Beat 10 broadcast** and the already-authorized Beat 06 Trace-memory content, including the ADR-025 side-view pilot (`ch01.fragment.mira_departure`). This reference authorizes no additional Mira sprite, animation, dialogue or present-day physical encounter.

   - In C.5.3:488, replace only the first sentence with:

     > In Chapter 1, preserve the silent, static Beat 10 broadcast and the already-authorized Beat 06 Trace-memory content under ADR-025; this study grants no additional Mira appearance.

   - In C.5.4:500, replace `Mira only on the approved Beat 10 broadcast display.` with:

     > Mira proofs follow the delivery's existing authorization: the Beat 10 broadcast or the Beat 06 Trace-memory contract, including its placeholder limits; no new Mira asset is authorized here.

   - In C.5.5, replace Mira's Ch1-status cell at line 511 with `Static Beat 10 broadcast; approved Beat 06 Trace-memory content`; replace her unapproved-elements cell at line 512 with `New present-day encounter, Mira movement/playability, unapproved story text`.
   - In D.5:633, replace Mira's Keep cell with `Silent Beat 10 broadcast and existing Beat 06 Trace-memory content (ADR-025); modest lavender accent and small flower`; replace `Physical Ch1 appearance` in the final cell with `New present-day physical encounter`.

3. **Limit the legacy fallback to isometric rooms.** D.7:653 says every room without `metadata/room_shape` uses a 640×360 fallback. ADR-025 side-view scenes deliberately have no `RoomShape` and use a 960×540 composition with their own floor line/letterbox and fixed or horizontal camera (spec V4). Replace D.7's opening paragraph with:

   > For each high-impact room or asset family under review, Argon (fallback Sol) provides a compact proof set using actual current in-project backgrounds, not invented mock rooms. Shoot each proof in the room's view mode (ADR-025) with its actual fixed, centred or scrolling camera framing. Legacy isometric rooms without `metadata/room_shape` retain their 640 × 360 fallback frame centred inside the 960 × 540 view (ADR-023 addendum 4). Side-view scenes use their approved 960 × 540 composition, floor line, letterbox and fixed or horizontal camera; the absence of `RoomShape` does not impose the legacy isometric fallback:

**D.11 scale decision: align now, in this docs correction, rather than defer.** This is a small consistency edit, not an additional blocker or asset-redraw request. There are **five proof-scale occurrences across four sections**: B.1:273 and :280; B.4:322; C.3:378; C.5:446. Replace only their review magnification `×3` with **`×2 (1080p)`**. Preserve native 1× inspection. Do not replace the three-dial count, 3×3/2×3 dimensions or other unrelated uses of 3. Leave **C.8's historical verification record unchanged**. Replace D.11's “Older ×3 review views” bullet with:

> - **Current review output:** native 1× and nearest ×2 (1080p) are the current proof views under ADR-023 addenda 3–4. Optional ×3 detail views are supplementary. C.8 retains its historical verification record as run.

The other requested checks pass:

- **Sections 1–8 / Appendix B/C:** existing text and the 48-row, three-column 32×48 schematic are unchanged. The new palette, binary-alpha, nearest-scaling, clusters, material hierarchy, state-shape and effects-hidden requirements preserve the production contracts. The proposed scorecard does not replace pipeline tests. No proof package or redesign is commissioned by this review.
- **D.2 versus §4 / C.6:** compatible. The explicit stylized top-left shading exception preserves §4's planar hierarchy; sparse practical lights do not authorize flattening the W/N value separation or hiding gameplay cues. Cool Ch1 ramps, sparse local amber, the 32-colour palette and C.6's ban on global warm repaint/purple ambience remain. All ten D.2 room IDs match the real Ch1 room table. No numeric lamp budget, new lighting technology or blanket dark filter is approved.
- **TLF-078:** D.4 explicitly references A.3's slope, flush mount and whole-silhouette containment tests. No frontal-signage exception is introduced. Text/state variants and opaque mount shadows remain covered by A.3.
- **Concept-only boundary:** sufficient as a reference, after the canon corrections above. I inspected the actual 1063×1263 image. It contains precisely the tempting white/gold robe, scarf/lab-coat/goggles, hourglasses, Mira timepiece, ornate props and chibi proportions that the text excludes. The filename, link caption, README row and repeated no-production-approval statements make its status clear. It is linked, not embedded, under the existing parent `design/art/reference/.gdignore`; it is not a palette-compliant runtime asset or a manifest. No need to redraw the reference or add it to export gates.
- **P0 audit:** the PROPOSED status, read-only-first scope and separate implementation authorization are clear. Reviewing this proposal does not launch the representative-scene audit or authorize art/code changes.

Verification: fetched first; exact parent/SHA checked; three-file diff reviewed; original Sections 1–8 and Appendix A/B/C text compared byte-for-byte outside the insertions; schematic dimensions/content checked; reference link and parent `.gdignore` checked. Default `git diff --check ca140a9 60352a0` reports four intentional Markdown two-space line breaks; the check passes with only end-of-line whitespace checking disabled. Those hard breaks are not a visual blocker. No Godot/gameplay/asset-generation tests were needed or run for this document-and-concept review. Lead applies fixes and merges; this verdict does not transfer approval to an unreviewed corrected SHA.
