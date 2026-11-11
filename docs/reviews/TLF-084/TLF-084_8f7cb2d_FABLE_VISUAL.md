# TLF-084 Part 2 — stand-in visual review (shadows + floor fill, ADR-027), `8f7cb2d`

**Verdict: APPROVE VISUAL, with ADD as the fill rule.** Reviewer: Fable 5.2, run by the Lead as a read-only stand-in for Sol (owner-approved), 2026-11-11. Standard: TLF-082 art direction, ADR-026, ADR-027. Evidence: `docs/handoffs/TLF-084/p2/`. Pixel statistics were computed in memory; nothing was run in Godot or written by the reviewer.

## Fill rule: ADD reads better than CLEAR 1.5

Measured on floor-fill pixels in the gate frame (k = ramp steps below authored):

| | Gate core / band | Helper core | Open floor | Gate box ÷ open floor (mean lum) |
|---|---|---|---|---:|
| ADR-026 | k0 / k1 | k1 | k2 | 2.12 |
| **ADD** | k0 / k0 | k0 | k1 | **1.47** |
| CLEAR 1.5 | k0 / k1 | k1 | k1, ring k2 | 1.22 |

- **CLEAR 1.5 is rejected.** The band equals the open floor, so the pool shrinks to its core, and 5,445 px of k2 ring surround it (`gate_clear15_lit_shadows.png`).
- **The helper inverts under CLEAR.** Its core equals the floor and about 7,100 px around it go to k2, so the exit reads as a 192×96 dark hole (east box ÷ open floor 0.82, `east_clear15_lit_shadows.png`). These are unmotivated discs, which TLF-082 §5 rejects.
- **ADD keeps the focal as the focus.** The gate is the largest lit shape (2,629 px at k0 against the helper's 1,347), with authored-value steel and the amber console.
- **The clock** stays a small warm accent in both modes.
- **Mood holds.** The frame is still darker than unlit (mean lum 17.6 vs 23.1), walls stay at k2, and the floor edge now separates from the void, which closes the TLF-083 P3.

## Shadows

- **Depth without hiding anything.** AO strips run along the N/W walls and both dividers; contacts sit under the post, console, bench, validator and statues; casts fall down-right from the pillar and statues.
- **Coverage:** 8,328 floor px sit one step under the fill.
- **Clues and Elias are untouched.** The largest changes between `*_lit_adr026` and `*_lit_shadows` are all on floor-ramp colours; the evac paper, dials and Elias's body are unchanged.
- **Elias's contact shadow** reads at arrival, dials and east (`*_x2_adr026_vs_shadows.png`).
- **Greyscale** stays readable in all four concourse views.

## Findings

**P2-1 — the focal core swallows strength-1 shadows under ADD.**
- In the gate core, CLEAR shows 176 shaded px and ADD shows 3.
- Elias, the courier, the post and the console therefore lose their contact and cast shadows exactly at the focal. The same happens in the helper core (about 60 px, `east_x2_adr026_vs_shadows.png`).
- Smallest fix: cap the lift at A before adding shade, `k = clamp(max(A − lift, 0) + shade, 0, 3)`. `test_shade_is_added_after_the_lift` pins the current behaviour and would change with it.

**P2-2 — focal and helper floors now have the same value.**
- Both sit one step above the fill; the hierarchy is area only.
- If the owner wants more separation, shrink the `EastHelper` core (`inner` 0.55 → about 0.35). No pass change is needed.

**P2-3 — the fill is by palette index, not by floor geometry.**
- In `side_lit_shadows.png`, 45,832 of the 72,758 lifted px (63%) are above the deck (arch windows, wall darks).
- At A 1, fill 1 returns every 00–05 pixel to its unlit value, leaving no step for a pool.
- Decide this before lounge, street exit or side memory are lit; `test_every_lit_ch01_room_has_shadows_and_the_fill` would force it on them. It does not block Concourse.

**P3**
- **Solved-state gate:** the gate-post contact stays until re-entry (handoff open point 4). Wire the rebake when a blocker toggles.
- **Carried from TLF-083:** the Elias wall capsule remains (about 145 wall px at arrival, 200 at dials; the floor part is gone), and the Echo ghost still loses its violet.
- **ADR text:** the ADR-027 fill bullet needs the one-line ADD rewording.
