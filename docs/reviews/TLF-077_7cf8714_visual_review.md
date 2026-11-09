# TLF-077 — APPROVE VISUAL

Reviewed **`7cf8714fd2bdb2776aad8e27d5192f310f211280`** on `adityadaffa522/tlf-077-sheared-wall-fixtures`, 2026-11-09. Fresh archive; all 49 delivery-file blobs match this SHA. Owner's TLF-078 rule applies. No assets or game files edited; no merge.

| Acceptance | Result |
|---|---|
| Follows wall slope | **PASS.** All 18 selector states and both clocks use exact N down-right / W down-left 2:1 projection. Independent inverse-shear comparison confirms that glyphs, digits and casing share the plane in all ten N/W pairs. Top-left bevel light is preserved. |
| Flush on wall face | **PASS at documented mounts.** Selector cabinet/lip/shadow reads seated against the ceramic course; clock rods attach below the cornice. Native and ×2 N/W module mockups show contact without floating frontal housings. |
| Inside wall silhouette | **PASS including shadows.** Independent committed-PNG alpha-mask test: each selector has 776/776 opaque pixels inside the wall at depth 4 (extent 4..34); each clock 602/602 at depth 3 (extent 3..25). Zero outside pixels for all 20 assets. |
| State frames and glyphs | **PASS.** Three distinct static files per selector family/face, stable silhouette. Circle/diamond/triangle, 1/2/3 bars, highlighted train car and detent positions remain distinguishable at native size and in luminance greyscale. Both clocks read 23:59; no mirrored text. |
| Palette / alpha | **PASS.** TLF-CH01-32, binary alpha. |

Inspected all three delivered 640×360 wall mockups and the colour/greyscale proof. Approve the supplied art and §11.1 mount contract. Flash must still swap the pilot's old textures and use these offsets; this approval does not certify the pilot's existing frontal exports. N selectors may use presenter `(0,-28)` for the upper ceramic course, or the documented `(0,-22)` contained placement. The N clock at wall anchor `(592,200)` uses top-left `(576,147)`; retaining its old `(-16,-20)` offset without the corresponding move is not the new contract.

Fresh gate output (exit 0 each):

```text
RESULT: ALL PASS (286 file(s))
RESULT: ALL REPRODUCIBLE
TOTAL pxo: 20, all identical: True
```

Pixelorama emits 160 nonfatal `custom_samplers` diagnostics; every size/export exit is 0 and every export byte-identical. Slim [raw summaries and per-state geometry](TLF-077/7cf8714/evidence.txt) retain the diagnostic text. No visual blockers remain at this SHA.
