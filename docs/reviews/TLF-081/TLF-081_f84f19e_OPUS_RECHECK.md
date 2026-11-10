# TLF-081 re-check: the W-wall mount recipes at `f84f19e` (addendum to `TLF-081_4383725_OPUS_REVIEW.md`)

Opus, 2026-11-10. Read-only. Commit `f84f19e` (`origin/adityadaffa522/tlf-081-concourse-wall-art-sol`, on top of `4383725`). I checked it against the wall modules Flash actually built in TLF-080 `f44af6e` (`scenes/chapters/ch01/rooms/concourse_west.tscn`).

## Verdict: **P1 CLOSED. APPROVE for gates and metadata** (visual acceptance stays with the Lead/owner)

The 76 px conduit/notice overlap is gone. Both recipes match the Lead's spec `e3f7b76`: conduit at `(0.5,11.5)`, ticket-terms plaque at `(0.5,15)`. Both also match the actual `WallW_*` nodes in `f44af6e`. Asset bytes are unchanged.

## Check

**Inputs:**
- `mount_correction.json`: conduit on W5 + W6 (PNG top-left `(112,102)`), notice on W7 (`(72,146)`).
- The same rows in ASSET_METADATA §14.2.
- `f44af6e`'s `WallW_5`, `WallW_6` and `WallW_7` nodes, whose position + offset give image top-lefts `(128,96)`, `(96,112)` and `(64,128)`, exactly the modules the recipes assume. The call-box module `WallW_1` gives `(256,32)`. `WallN_7..9` give `(544,128)`, `(576,144)` and `(608,160)`, as the dial rows assume.

**Arithmetic:** `tile(x,y) = (320+16(x−y), 64+8(x+y))` and presenter local = PNG top-left + pivot − anchor.

| Fixture | Anchor | Expected anchor (from the tile) | PNG top-left | Presenter local | Check |
|---|---|---|---|---|---|
| Conduit | `(0.5,11.5)` | `(144,160)`, which is `conduit_01` in `f44af6e` | `(112,102)` | `(112,125) − (144,160) = (−32,−35)` | ✓ |
| Notice | `(0.5,15)` | `(88,188)`, which is `doc_ticket_terms` in `f44af6e` | `(72,146)` | `(72,153) − (88,188) = (−16,−35)` | ✓ |

**Pixels:** my own composite, drawing all eight `WallW_*` modules at their `f44af6e` transforms with the W module PNG.

| Check | Result |
|---|---|
| Conduit vs notice, opaque overlap | **0 px** (was 76) |
| Conduit opaque pixels outside the real W wall alpha | 0 of 536 |
| Notice opaque pixels outside the wall | 0 of 263 |
| Phone idle / ringing outside the wall | 0 of 677 / 0 of 699 |
| Wall-axis extent | conduit y 10.125–12.875; notice y 14.56–15.44 |
| Clearance from the door aperture (y 7–9) | ≥ 1.1 tiles (the spec asks for 1) |

**Gates on a `git archive` extract of `f84f19e`:**

| Gate | Result |
|---|---|
| `test_tlf081.py` | 7 tests OK (now including the corrected W pair) |
| `check_assets.py` | ALL PASS (314) |
| `verify_regen.py` | 321 ok, ALL REPRODUCIBLE |
| `git diff 4383725 f84f19e -- assets` | empty: no PNG/PXO changed |

**Metadata P3s from the first review:** §14.1 now has the `ch01.prop.*` asset-ID and frames columns. The dial pivot convention is spelled out against TLF-077's selectors. Rows 270–282 are unchanged.

**Still open for TLF-080 integration (not Sol's file):**
- **Not swapped yet:** `f44af6e` still uses the old frontal art for these fixtures.
- **Needed when the art is swapped:** an integration test that asserts the final PNG top-lefts and the module transforms, as `mount_correction.json` asks (`"builder_verified": false` there; this addendum verified it by hand against `f44af6e`).

Evidence: `TLF-081/f84f19e/recheck.txt`.
