# TLF-072 — APPROVE VISUAL

Reviewed **`8384d0f7b9b77afd9c2cb2c74b3f6610cb15f023`**, branch `agent/opus-core-tlf072`, 2026-11-10. **Approve the 960×540 canvas and requested layouts at 1920×1080 integer ×2.** The small-text tradeoff accepted in ADR-023 addendum 3 is visible; the UI/text-scale follow-up below is warranted.

Read the handoff and inspected every committed `shot_*.png`. There are **13 supplied screenshots**, not 14; none shows “You are late.” Independently rendered the same SHA in a renamed, isolated-user-data archive, including that missing frame, “Again.” and automatic chapter completion. The actual window measured 1920×1080, logical view 960×540, final transform exactly ×2 with zero translation.

| Requested check | Result |
|---|---|
| Dialogue box | **PASS.** Centre-bottom 600×92 panel at `(180,436)`, 12 px above the bottom. Arrival and all sampled Beat 10 lines fit; speaker/body/prompt stay inside the panel. |
| Feedback line | **PASS.** Bottom-centred, above the edge. The `no_history` message wraps to two complete lines without clipping (`shot_06`). |
| Wheel | **PASS.** Centred at `(480,270)`; all six sectors, watch, symbols and labels are inside the view (`shot_05`). Mouse-centre and panel-centre checks pass. |
| Document viewer | **PASS.** Centred 440×256 panel; heading, six body lines and close hint are visible, without clipping or collision (`shot_07`). |
| Title / chapter complete | **PASS.** Title/menu and chapter-complete block are centred, bottom hints remain inside the safe area (`shot_01`, `shot_11`). The large empty area around the short playtest summary is sparse but not a new overflow/layout failure. |
| Pilot whole on screen | **PASS.** Spawn and gate frames retain the whole room, fixtures and low perimeter. Independent camera: bounds `(16,0,800,384)`, centre `(416,192)`, view `(-64,-78,960,540)`; no follow crop between these positions. |
| Old rooms / dark margin | **PASS for both supplied examples.** Maintenance Bay and Signal Control keep their original 640×360 coordinate frame centred: camera `(320,180)`, view `(-160,-90,960,540)`, hence 160/90 px margins around that frame. Sampled unobstructed margin pixels are exactly **RGB `(10,13,20)` / `#0A0D14`**, not grey. This does not claim recapture of all nine old rooms. |
| Beat 10 | **PASS.** Unscaled 1280×360 plate at y=90, with 90 px black bars behind the UI. Independent “You are late.” frame at pan −169; “Again.” at exactly **−320**, right edge aligned. Both appear without input, followed by automatic completion after the hold. The portrait remains silent; text is crisp and inside the bottom panel. |

**Text-size judgement:** I can decipher every sampled essential line at actual 1080p ×2; none is unreadable there. The native 8 px font cell becomes 16 physical px (the 5×7 glyph becomes about 10×14), compared with the previous 24 px cell / 15×21 glyph. This is visibly small, rather than generous or equally comfortable to the old presentation. I inspected nearest-neighbour crops at exactly those physical dimensions, not only magnified full-screen proofs.

- **Smallest / priority for a larger-text option:** document body and close hint (`shot_07`), HUD shortcuts (`shot_02`–`08`), muted wheel `Locked` labels (`shot_05`), title control hint (`shot_01`), cinematic skip/continue prompts (`shot_09`/`10` and independent “You are late.”), and chapter-complete diagnostic text / return hint (`shot_11`). All are legible at ×2; the document is the main sustained-reading concern. Title/menu and chapter-complete headings are comfortably readable.
- **Dialogue and feedback:** body text in `shot_02`, `shot_06`, `shot_09` and `shot_10` is small but readable at ×2; no missing glyphs, blurred interpolation or clipped words in these English samples.
- **1280×720 is a real comfort problem:** `shot_12` uses integer ×1 with 160/90 px black window borders. Its title control hint is only a 5×7 physical glyph and is **too small for comfortable normal-distance reading**. The 960×540 ×1 images also show how tiny the document, dialogue, feedback and HUD would be at that scale; their ×1 windowed gameplay was not separately captured. I would not present ×1 as an equally readable alternative to 1080p ×2.

**UI/text scale is warranted as a follow-up**, especially for sub-1080p windows, longer document reading and accessibility. Start by auditing the existing `Settings.text_scale` / `UITheme.apply_scale_multiplier()` path, with panel wrapping and fixed-label coverage; this review does not certify the Large setting or a new whole-UI scale. It is not a blocker for this SHA's owner-accepted canvas change at 1080p.

Fresh verification: import exit 0; Windows D3D12 Forward+ capture exit 0; **28 focused tests passed, 0 failed** (UI layout, RoomCamera, project settings, Ch01Outro). No engine/script errors in those logs. Real save/settings inventory, hashes, sizes and mtimes unchanged (139 files). No product files edited on the review branch; no merge.

Evidence: [“You are late.”](TLF-072/8384d0f/you_are_late.png), [“Again.”](TLF-072/8384d0f/again.png), [document at 1080p physical ×2](TLF-072/8384d0f/document_physical_x2.png), [dialogue at physical ×2](TLF-072/8384d0f/dialogue_physical_x2.png), [title hint at physical ×2](TLF-072/8384d0f/title_hint_physical_x2.png), [raw capture and focused test log / source checks](TLF-072/8384d0f/evidence.txt).

Separate requested docs correction: **`c69cacbb0747f18bed5c772b9366ccffb366ad24`**, pushed to `adityadaffa522/tlf-072-art-bible`, directly from `origin/main` `a46a06ba0f0bd462a91efaf0761b412897ea43a5`. Only `design/art/ART_BIBLE.md` changes: canvas, ×2 output and integer-output table, about-9% character-frame height, safe-area/edge-relative coordinates and stale canvas/proof references. Verified arithmetic, absence of stale 640×360 canvas references and `git diff --check`; no gameplay validation needed for that docs-only commit. ADR_LOG's historical decisions remain intact.
