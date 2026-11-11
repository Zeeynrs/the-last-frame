# TLF-083 Part 2 visual review (stand-in for Sol): Concourse West lit, `2a1daa5`

Reviewer: Fable 5.2, run by the Lead as a read-only stand-in while Sol (art director) was offline, 2026-11-11. Owner approved the stand-in. Standard: `docs/reviews/TLF-082_art_direction.md`, ADR-026, Sol's TLF-083 reviews. Inputs: the proof pack `docs/handoffs/TLF-083/p2/` and `TLF-083_P2_HANDOFF.md` at `7f9d634`. Nothing was run in Godot or written to the repo by the reviewer; pixel statistics were computed in memory.

## Verdict: CHANGES REQUIRED (one narrow P1, not in the RoomLights)

The six RoomLights are accepted as placed.

**P1: the W-wall dado stays a full-length glowing amber line** (all `*_lit_nohud.png`, clearest in `arrival_lit_nohud.png`).
- 260 px of index 25 (`eb8a28`) run unshifted along the whole W wall (x 128..383), while the N/E dado drops to `4a1c14` (466 px).
- The same trim reads as an LED strip on one wall and dead paint on the other, and outweighs the clock's warm core (51 px) about 5:1.
- TLF-082 §2: dado and trim must be able to dim and must not form a glowing orange run along the perimeter.
- Smallest fix: repaint the W-face dado pigment 25 → 24 in the wall art; at A = 2 it lands on `4a1c14` like the N wall. No RoomLight change. (Lead check: `ch01_env_wall_subterranean_n_idle.png` has 32 px of index 24; `..._w_idle.png` and `ch01_env_wall_partition_low_e_idle.png` have 32 px of index 25. Owner chose the 25 → 24 swap.)

## P2
1. **Divider stripes** (about 250 px of index 25, two runs): tolerable, they converge on the gate; the same pigment fix dims them.
2. **Echo ghost loses its violet** (`echo_lit_nohud.png` vs `echo_unlit_nohud.png`): it snaps to steel blue (`3f4f6b`/`586c8f` in the pool, `2d394f` outside). Shape and position survive. Fix in the ghost (palette violet 30), not the room, before Echo ships in a lit room.
3. **Elias zone on walls** (`dials_lit_nohud.png`, `arrival_lit_x2.png`): 530 and 580 background px lifted, including N-wall brick and 11 dado px, a faint capsule on the wall. Sol's accepted default; flagged for Sol. If rejected, use an actor receiver, not a larger zone.

## P3
- **Floor:** fill `1f2838` collapses to 00 (77k px); the floor reads only through the 1 px grid and the S/E edge is unmarked. Dark and cold, at the limit; check on the owner's display, do not raise A.
- **Elias:** found in every view and in greyscale; legs nearly merge with the lifted floor; the back view in `dials_lit_nohud_greyscale.png` is the weakest.
- **East helper:** flat single-band disc, subordinate; the door is findable.
- **Small accents:** the evac paper (index 31, 22 px) is the brightest speck on screen; call box and ticket-terms plaque are dark but outlined; leaving them unlit is fine.

## Passes
- **Focal:** one dominant focal, the gate (post, reset console, fallen conduit/arm read in `gate_lit_x2.png`). The clock is a small warm accent with no pool and does not compete.
- **Spill:** none from room lights onto walls, caps or partitions (0 of ~27.9k).
- **Information:** dial glyphs and validator marks survive; accepted marks read in `solved_lit_nohud.png`.
- **Statues:** courier and commuters one step down, clean silhouettes, no band across a body.
- **States:** hard bands acceptable; the solved state reads (gate open, conduit mounted).
- **Targets:** all 14 rows in `targets_in_range.png` recognisable.
- **Log:** `capture.log` matches the handoff (mismatches 0, off-palette 0, spill 0, info 488/488/487/488/480/488, +0.076/0.075 ms). Setting off equals unlit byte for byte in all six views; every lit colour is in the unlit palette set.

## Round 2: re-check after the dado fix (`8c62cb7`, handoff `ac07f94`)

**Verdict: APPROVE VISUAL.** The round-1 P1 is closed.

- **P1 closed:** the W dado and both divider runs now dim like the N wall (`4a1c14` in the lit frames); no glowing perimeter run in any of the six views. Index 25 left in the lit gate frame: 72 px (was 530), all emissive cores (W archway threshold lamps 30, clock 18, E door lamps 12, dial marks 5, console button 3, evac clipboard 2, gate 2). The 13 dado px kept at 24 by the gate read as local light under the focal (TLF-082 §2).
- **Unlit rooms:** W and N faces stay separated by brick value; the dado now wraps the corner as one line. The only pixel pair changed in the six concourse unlit shots is `eb8a28` → `cc4e1e` (458–467 px); other rooms show the same single pair, plus 6 px on Elias's sprite in the atrium frame (animation timing).
- **Lit regression:** none; every difference is a dado pixel getting darker. Setting off still equals unlit byte for byte; `capture.log` 0 mismatches, 0 off-palette, 0 spill, all info pixels kept.
- **Notes:** P3, the dividers now rely on brick value alone (still readable in `arrival_lit_nohud_greyscale.png`). Carried: Echo ghost loses its violet (Echo task); Elias zone faint capsule on walls (for Sol).
