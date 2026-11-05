# Chapter 1 Safe Plan (Safe Enhancement Directive, deliverables 3 and 6)

**Date:** 2026-11-05 · **Lead:** Agent 1 · **Basis:** `docs/CHAPTER1_AUDIT.md`, `docs/reviews/2026-11-05_STORY_BIBLE_V2_AUDIT.md`
**Rule:** P0 finishes and stabilises the playable slice. P1 runs only after the owner approves each item (section 3). Every task is a small diff on its own branch, with tests and a rollback (revert the merge commit).

Effort: **S** ≈ under one agent day · **M** ≈ 1-3 days · **L** ≈ more.

## 1. P0 — finish and stabilise Chapter 1

| # | Item | Owner | Depends on | Risk | Effort | Test / done when |
|---|---|---|---|---|---|---|
| P0-1 | **Step 1 already in flight** (approved 2026-11-01): TLF-052 wheel, TLF-054 puzzle logic (incl. the RISK-020 fix), TLF-057 art, then TLF-055 rooms, then TLF-056 real-input proofs | Flash / Opus impl / Argon (Sol directs) | — | Medium (biggest change to the slice) | L (in progress) | `validate.ps1` green; real-input playthrough with unlocks; a negative test per puzzle; TLF-049 green |
| P0-2 | **Story text per Story Bible v2:** Beat 10 voice line → "You are late. Again."; Beat 09 per D1; watch-pickup flash (audit C12); PZ-004 title → "The Forgotten Sequence" | Writer per D5 (recommended: Opus Lead) | D1, D2, D5; the PZ-004 title after TLF-054 | Low (text keys only) | S | Generators run; `test_ch01_text.gd`; the Operator mystery check (Story Bible §10.5) |
| P0-3 | **Operator sighting** (Story Bible Ch1 event 7) at the place chosen in D3: a silhouette checks a pocket watch at the end of the corridor and is gone when Elias walks closer. One-shot flag, saved; never blocks the path | Scene: Flash (after TLF-055). Silhouette sprite + gesture: Argon, directed by Sol | D3, K6 (Operator look) | Low-Medium (new scripted moment) | M | Plays once, survives save/load, no input lock left behind; screenshot; mystery check (no face) |
| P0-4 | **Beat 10 cinematic:** short scripted camera move, the frozen city plate, suspended rain, the voice line, the optional silent Mira image (D2), then the chapter-complete overlay | Flash (scene), Opus (contract for scripted camera/sequence), Argon (city plate) | P0-2, D2 | Medium (first cinematic system) | M | Skippable; no input during it; ends in the existing overlay; the framing is documented so Ending 3 can mirror it |
| P0-5 | **Export preset + smoke test:** Windows build (Linux if the toolchain allows); theme font, translations, saves, title → chapter → complete | Flash (`export_presets.cfg`) | — | Low | S | Build launches outside the editor; the report says what was **not** tested |
| P0-6 | **Save/load during and after The Forgotten Sequence:** save with the echo recorded / playing / after SOLVED → load → still solvable or still solved | Opus impl (extends TLF-056) | P0-1 | Low | S | New real-input tests |
| P0-7 | **Readability pass + playtest #3:** sprite scale, interaction cues, walkable space, UI; then your playtest with telemetry (target ≥ 15 min) | Sol (visual review), Flash (fixes), owner (playtest) | P0-1…P0-4 | — | S + playtest | The directive's P0 gate: a new player finishes Ch1 without a softlock or an Operator spoiler |
| P0-8 | Physical controller spot-check (ISSUE-011) | Owner | — | — | S | Checklist in `docs/handoffs/TLF-017/` |

## 2. P1 — low-risk enhancements (each needs your approval)

| # | Item | Player benefit | Owner | Effort | Notes |
|---|---|---|---|---|---|
| P1-1 | Journal foundation | — | — | none | **Already exists** (audit F08). Only the Step 1 entries are added, inside P0-1 |
| P1-2 | **Environmental storytelling pass** from your map references: "DESTINATION: NOWHERE - 23:59" board, "A1 → Research" / "R&D Access" door, Sector A pillar marks, "CLOSED TRACK" notice. Each one ties to a later reveal (the station served the research facility) | Rewards looking; seeds the ELYSIUM link | Argon (props, Sol directs), Flash (placement, no collision change) | S-M | Decorative, new files only, no new mechanics |
| P1-3 | Hint tiers for The Forgotten Sequence | — | — | none | **Already exist** (3 hints for PZ-004); only re-checked after the title change |
| P1-4 | **Operator motif:** a quiet second tick in the watch sound whenever the voice speaks, and a handset left swinging after each call | Lets the mystery build without words | Flash + audio (P1-5) | S | No identity information |
| P1-5 | **Audio affordance pass:** one distinct SFX per ability (Trace / Rewind / Freeze / Echo record / Echo play / refused) and the 23:59 clock tick, played from the existing `watch_used` and `ability_locked` signals and the existing buses | The game is currently **silent** | Flash (wiring), source: **your decision** (CC0 packs or made sounds) | M | No dynamic music system |
| P1-6 | **Character references → art direction:** Sol turns `elias_ref` / `mira_ref` / `operator_ref` into a direction note inside the 32×48 / TLF-palette constraints (audit K4-K8); Argon makes it only after your approval | A consistent cast; the Operator–Elias visual link Ending 3 needs | Sol, then Argon | M (note) + L (Elias v3 sheet, if approved) | Elias v3 replaces a finished asset: approval required |

## 3. Approval request (your answers decide what starts)

**Still open from the Story Bible audit** (recommendations in brackets):
- **D1** Beat 09: [a question, not a fact]
- **D2** Mira's image in Beat 10: [keep it, silent]
- **D3** where the Operator is first seen: [Arrival Platform]
- **D4** Elias-0: [drop]
- **D5** who writes story canon and dialogue: [Opus]
- **D6** language of the six story docs: [English]

**New from this audit:**
- **A1** Keep Step 1 (P0-1) as the path to a full-length Ch1? [yes]
- **A2** Map reference: use it as structure/mood reference, keep the built layout and the street exit, and file the extra rooms (Station Office / Power Room / Baggage Storage) as candidates for the two Step 2 rooms? [yes]. And confirm that "unfreeze time" in the map's clock puzzle is **not** canon? [not canon]
- **A3** Elias v3 per `elias_ref` (lab coat, red scarf, goggles), replacing the finished brown-coat Elias v2? [let Sol write the direction note first (P1-6), then decide]
- **A4** Operator look: hood + mask, but with Elias's pocket watch, gesture and scarf colour; no attack animations? [yes]
- **A5** Approve P1-2, P1-4, P1-5, P1-6? For P1-5: where should the sounds come from?
- **A6** May I commit `ref/` to `design/art/reference/ch01/` so Sol and Argon can use it? [yes]
