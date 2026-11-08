# TLF-075 — CHANGES REQUIRED

Reviewed **`68b4f5b66108471df70a996c6ed15e34d047fbe1`**, `adityadaffa522/tlf-075-side-view-art`, 2026-11-09. Fresh archive; all 27 delivery-file blobs match the exact SHA. No merge or game/asset edits by Sol.

**P1 — The interaction clip conflicts with the retained Ch1 Elias decision.** `docs/ADR_LOG.md:381` (ADR-022 A3) says **“No Elias watch-check clip is made for Ch1.”** The delivered `interact_e` explicitly retrieves, holds/inspects and lowers the pocket watch; its middle frame extends the brass watch outside the coat. See `tools/art/gen/tlf075_side_view.py:159` and `:240`, metadata §11.1, and [the three committed frames at ×4](TLF-075/68b4f5b/interact_e_3frames_x4.png). Mirrored `interact_w` repeats it. TLF-075/ADR-025 requests a generic interaction and a readable pocket watch; it does not explicitly override that owner decision.

**Required fix:** replace these three interaction frames with a neutral reach/inspect gesture, retaining the readable watch-chain detail on the costume. Update mirrors, tags' descriptions, PXO, export, metadata and proofs consistently. Keep the finished idle/walk art and background kit. An explicit owner reversal of ADR-022 A3 would resolve the canon conflict instead; this review assumes the recorded decision remains binding.

Other visual acceptance checked:

- **Elias scale/costume: PASS.** Same 32×48 cell, `(16,44)` foot pivot, brown v2 trench coat, trousers/boots and exact 12-colour subset; no scarf or lab coat. Side profile matches the iso Elias comparison at native scale. Two breathing poses, six readable walk poses, planted/supporting feet, counter-swing and top-left highlights. All 11 W cells independently verified as exact E mirrors, as requested.
- **Composition/kit: PASS.** 960×540 mockup, 90 px framing bars, 960×360 active band, common floor y394. Two separate backdrop layers, floor strip and six props. The clock reads 23:59; props add no narrative text. Mira is a distinguishable frozen silhouette placeholder, not approval of a finished Mira side sprite. Technical labels/scale strips belong to the concept proof, not runtime bars.
- **Seams/readability: PASS visually.** Inspected the colour/greyscale proof and nearest-neighbour wrap strips of far wall, near piers and floor. No empty wrap gap or broken dado/rail line; native floor/wall/pillar contacts read correctly. This approves the side-view projection, not reuse as iso wall fixtures. Runtime movement, collision, occlusion and camera remain TLF-076 integration checks.

Fresh gates, exit 0 each:

```text
RESULT: ALL PASS (274 file(s))
RESULT: ALL REPRODUCIBLE
TOTAL pxo: 10, all identical: True
```

Pixelorama prints 80 nonfatal `custom_samplers` diagnostics; all size/export exits are 0, all ten exports byte-identical. [Slim raw gate summaries and source checks](TLF-075/68b4f5b/evidence.txt). The sole blocking finding is the watch-check interaction above. No full kit redraw requested.
