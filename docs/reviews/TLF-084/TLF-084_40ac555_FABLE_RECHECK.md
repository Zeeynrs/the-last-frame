# TLF-084 round 2 — stand-in visual re-check (`40ac555`)

**Verdict: APPROVE VISUAL.** Reviewer: Fable 5.2, run by the Lead as a read-only stand-in for Sol (owner-approved), 2026-11-11. P2-1, P2-3 and the rebake P3 are closed; nothing regressed. Evidence: `docs/handoffs/TLF-084/r2/`. Files were read with `git show`; nothing was run in Godot or written by the reviewer.

## P2-1 — shadows read in the gate core: closed

- **Shadow now shows.** In the gate core, floor-fill pixels at shadow value went from 3 to 152 of 558; the band is unchanged at 270.
- **What reads:** the post's contact and cast, the console's contact and Elias's foot contact (`gate_core_x4_r1_vs_r2.png`).
- **The focal is not muddied.**
  - Gate box mean luminance: 42.4 → 41.9.
  - Pool area at full value: 2,629 → 2,480 px, still 1.8 times the helper's 1,347.
  - No steel, console or body pixel changed.
- **Greyscale** still shows the gate as the largest lit shape (`gate_lit_shadows_greyscale.png`).

## P2-3 — fill only on the floor: closed

- **Side view, A 1:** `side_lit_shadows.png` is now the ADR-026 look plus 2,872 shade pixels, all on deck rows 382..401. Nothing changes above the deck or below the strip, so the arches and wall darks are dark again and the Mira pool keeps its step.
- **Concourse:** the only fill change is the 280 px of the west-door opening going back to its ADR-026 value.

## Regression check

- **Round 1 → round 2:** 516 px changed in `gate`, 511 in each of `arrival`, `dials` and `east`. All are darker and all sit on floor-ramp colours.
- **Logs:** all seven shots report 0 shader mismatches, 0 off-palette and setting-off equal to unlit.
- **Rebake:** `gate_closed_vs_open_x3.png` shows the wide bar contact gone and the post keeping its own. That is correct, since the post still stands in the open art.

## On the "about 60 px in the helper core"

No disagreement. The round-1 figure was the count of shadow pixels already showing in the helper core, on fill-colour pixels only; Opus's 76 of 76 is the same observation over all receiver colours. It was cited as the contrast to the gate core, not as something round 2 should change.

## Still open, not blocking

- **Focal and helper floors share one value** (earlier P2-2). Owner's call; the fix is shrinking the `EastHelper` core.
- **Carried from TLF-083:** the Elias wall capsule and the Echo ghost losing its violet.
