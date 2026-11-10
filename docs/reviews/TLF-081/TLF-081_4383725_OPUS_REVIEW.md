# TLF-081 independent gate and metadata review (Sol's art, `4383725`)

Opus, 2026-11-10. Read-only review of `origin/adityadaffa522/tlf-081-concourse-wall-art-sol` at `4383725` (parent main `f21aef6`).

**Why an independent check:** Sol is both the author and the visual reviewer, so this report checks the gates and metadata independently; visual acceptance stays with the Lead/owner.

**Reference:** Sol's audit `docs/reviews/TLF-081_concourse_facing_audit.md` and `TLF-081/f21aef6/required_variants.csv` at `5096ef8`.

**How it was checked:** in a `git archive` extract of `4383725`. No file on Sol's branch was changed, and nothing was merged. Evidence is in `TLF-081/4383725/`.

## Verdict: **CHANGES REQUIRED, metadata only** (the art and all gates pass)

The 13 PNG/PXO pairs are exactly the audited list. They pass palette, alpha, size and colour-count checks. The shared generator changes are additive, and a full regeneration reproduces every asset. One P1: the documented mount recipes for the **mounted conduit** and the **ticket-terms notice** overlap by **76 opaque pixels** on wall module W6. The notice is the PZ-006 clue document, and the conduit stays in its mounted state for the rest of the chapter after PZ-001. Fix the recipe or the TLF-080 target **before Flash integrates**. No art change is needed if one of the two moves.

## 1. Delivery against the audit

| Check | Result |
|---|---|
| **Files vs `required_variants.csv`** (13 rows) | **Exact match.** 13 new `assets/props/ch01/*.png` and 13 `assets/source/ch01/*.pxo` with the required basenames. No other asset file is added or changed (`git diff --stat f21aef6 4383725`). |
| **Old frontal exports, fallen conduit, N clock, bench, reset console, scenes** | Untouched; no scene or presenter file is in the diff. |
| **Palette / binary alpha** (my own check, against `ch01_palette_elysium09.gpl`) | All 13: **0 off-palette opaque pixels**, alpha exactly {0, 255}. |
| **Canvas and colour count vs ASSET_METADATA §14.1** | All 13 match: dials 32×48 (10–13 colours), phone 24×48 (8/9), conduit 48×40 (8), notice 16×28 (10), validator 32×48 (8/11/10). |
| **PXO** | Each PXO's canvas matches its PNG, with 3–4 named layers. `author_display_name` credits Sol and Argon's adapted primitives. |
| `python tools/art/test_tlf081.py` | `Ran 5 tests … OK` |
| `python tools/art/check_assets.py` | `RESULT: ALL PASS (314 file(s))` |
| `python tools/art/gen/verify_regen.py` (full, all assets) | 321 `ok` lines, `RESULT: ALL REPRODUCIBLE`. The only non-ok line is the pre-existing "NOT COVERED (authored by Argon in batch 1 …)" list, unchanged from main. |

## 2. Shared generator changes: safe

**Every change is additive:**
- **`lib.py`:** `pxo_bytes(..., author=None)` writes `author_display_name` only when an author is given, so every older asset's PXO keeps its bytes. The full `verify_regen.py` run confirms that (it regenerates every registered asset and compares).
- **`registry.py`:** a new import, an `author` field defaulting to `None`, and one append loop for `tlf081_concourse_wall_art.assets()` with `user_data='TLF-081'` at the end of `all_assets()`. Order and stems of earlier assets are unchanged.
- **`gen_all.py` / `verify_pxo.py`:**
  - **`--task`:** an optional exact `user_data` filter; behaviour without it is unchanged.
  - **`gen_all.py --sheet`:** also writes the TLF-081 proofs, into `docs/handoffs/TLF-081/` only.
- **`verify_regen.py`:** one extra block that regenerates the TLF-081 proofs in a temp directory and compares their pixels. It only adds checks.

No other asset moves (verified by the full regeneration, not just by reading the diff).

## 3. ASSET_METADATA §14

**Numbering:**
- **Section:** `## 14.` is new, and its subsections 14.1–14.4 are unique. It follows §13 (TLF-075).
- **Rows:** 270–282 are new and continue after TLF-077's last row, 269. No new collision.
- **Earlier collisions are not from this commit:** rows 250–251 appear three times (TLF-073 §11.2, TLF-077 §12 table, TLF-075 §13.3), and 252–259 twice (TLF-077 and TLF-075). §12's own subsections are still numbered `11.1–11.3`. Those cleanups stay open from earlier tasks.

**Mount recipes (§14.2): all seven are arithmetically consistent.** I re-derived each with `tile(x,y) = (320+16(x−y), 64+8(x+y))`, module image top-left = module position − (16, 56), and `Sprite2D` position = PNG top-left + pivot (offset = −pivot):

| Target | Logical | Module(s) assumed | PNG top-left | Presenter local | Check |
|---|---|---|---|---|---|
| LINE | (560,192) | N7 at tile (15,0) → TL (544,128) | (544,134) | (−16,−58) | ✓ |
| PLATFORM | (592,208) | N8 at (17,0) → (576,144) | (576,150) | (−16,−58) | ✓ |
| TIME | (624,224) | N9 at (19,0) → (608,160) | (608,166) | (−16,−58) | ✓ |
| Phone | (280,92) | W1 at (0,3) → (256,32) | (260,36) | (−20,−45) | ✓ |
| Conduit | (136,164) | W6 at (0,13) → (96,112) + W5 at (0,11) → (128,96) | (104,106) | (−32,−35) | ✓ |
| Notice | (104,180) | W6 → (96,112) | (104,130) | (0,−43) | ✓ |
| Validator | (624,240) | floor-standing | (608,198) | (0,0), offset (−16,−42) | ✓ |

**P1, conduit vs notice:** with these recipes, both sit on **W6**.
- **Bounding boxes:** the conduit's PNG covers x 104–151, y 106–145; the notice's covers x 104–119, y 130–157.
- **Overlap:** **76 opaque pixels**. The conduit's left bracket and pipe end cover the notice's upper frame (or the notice covers the pipe, depending on tree order; both are `Wall_Fixtures`, z 7).
- **Image:** `TLF-081/4383725/w6_conduit_notice_overlap_x4.png`, at ×4 on the real W modules, shows the conduit alone, the notice alone, then both in each draw order.
- **Why it matters:** the conduit is mounted from PZ-001 onwards (Rewind), and the notice is the ticket-terms clue for PZ-006, so in normal play both are on screen together.
- **Not covered by Sol's proof:** the proof bank checks TIME vs the validator only; I confirm that pair has 0 overlap.
- **Fix:** any one of these:
  - **(a)** the Lead moves the notice target along W (e.g. to `(0.5,16)` on W7);
  - **(b)** the conduit assembly moves one module north (W5 + W4);
  - **(c)** Sol re-derives the notice's in-module anchor so it clears the conduit.

  Then add the pair to `test_tlf081.py`'s overlap check.

**P2/P3 notes for Flash (TLF-080):**
- **Assumed module layout (P2):** the recipes assume N modules at x = 2k+1 and W modules at y = 2k+1. If the TLF-080 builder places modules differently, the recipes have to be recomputed; an integration test should assert the final PNG top-lefts.
- **Pivot convention (P3):** the N dials use a top-left face-space pivot `(0,0)`, unlike TLF-077's N selectors `(16,40)`. That is documented and internally consistent, but Flash must not carry TLF-077's convention over.
- **§14.1 table format (P3):** it uses a shorter layout than §§7–13 (no asset-ID column `ch01.prop.*`, no frames column). The information is complete, but the format is inconsistent.
- **Validator (P3):** the 24 px housing overhangs the 16×8 plinth and collider; this is documented as intended volume. Reach and occlusion are checked at integration.

## Evidence

Files are in `TLF-081/4383725/`.

- `gates.txt`: raw output of `test_tlf081.py`, `verify_regen.py` (count plus non-ok lines) and `check_assets.py`.
- `w6_conduit_notice_overlap_x4.png`: the overlap proof.
- **My own checks:** the palette, alpha, size, colour-count and overlap scripts were run against the extract; their results are in the tables above.
- **Not done:** no Godot run (no scene uses the files yet), no validate, no visual judgement.
