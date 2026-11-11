# TLF-085 Maintenance Bay v2 — stand-in visual review (unlit build, placeholder art), `71bb9ea`

**Verdict: CHANGES REQUIRED.** Reviewer: Fable 5.2, run by the Lead as a read-only stand-in for Sol (owner-approved), 2026-11-11. The geometry, spacing and route are right; two readability faults block visual approval. Evidence: `docs/handoffs/TLF-085/*_960x540.png`, the room scene and the sprite files.

## P1

**P1-a — the bulkhead (x = 7) is full wall height and hides the SO-02 floor.**
- `ch01_env_wall_bulkhead_module_idle.png` has a 49 px opaque column, the same profile as the W wall. It hides a 3-tile strip west of it for its whole length: about 42 of band A's 112 cells (38%).
- The hatch plate (6,6), hatch chart (6,7) and bell plate (5,8) lie in that strip. Because they are z 8 over walls at z 5, they are painted on the bulkhead's east face (`arrival_960x540.png` near (408,226), (392,234), (360,234)).
- Elias (z 10) will draw over the wall the same way when he stands on the plate.
- The layout's fallback (low partition for y 10..16 only) is not enough, because the objects sit at y 6..8.
- Smallest fix: swap `Wall_bulkhead_s0..s5` to the low partition (17 px column, same positions, offset (−16,−24)). `Wall_bulkhead_n0` can stay tall beside the hatch.

**P1-b — Elias is about 35% visible in the pocket.**
- In `pocket_960x540.png` (Elias at `safe_anchor_east`) only a 6 px wide strip of him shows (x 625..630), with about 2 px of face.
- The cause is the frontal 64×64 placeholder shutters: the 48 px wide pocket shows as a 14 px slot between the two sprites.
- This closes with a W-face shutter variant; PATTERN rule 9 blocks the room on that art anyway. Re-shoot the pocket and both shutter stand spots after the swap.
- The scene's `inner_shutter` presenter uses the default fire-shutter texture; the 32×64 `ch01_prop_inner_shutter_*` pair is referenced by no scene or script.

## P2

1. **Gear behind the fire shutter.** Both sit at world x 512, so they share a screen column. The shutter covers 351 of the gear's 1,926 px (18%) in both states, so the puzzle is not hidden, but the two read as one stacked machine. Re-check with the 085b art.
2. **Gear stand spot not shot.** `gear_bay_960x540.png` places Elias on the gear position (512,176), not the stand spot (496,184). By geometry, at the stand spot he covers the gear's left half and the shutter covers his lower 16 rows. Re-shoot there.
3. **`doc_inner_shutter_plate` sits on the divider.** Its position (608,224) is exactly the origin of `PartitionLowE_inner_n0`, so the floor clipboard is drawn on the x = 19 rail. The handoff calls it an N-wall plaque; it needs an N-face plaque variant (rules 9 and 12). It is not in the TLF-078 audit.
4. **`n11_hatch_tech` is about half hidden.** Roughly 7 of the statue's 16 px columns show left of the hatch frame, and it is the Trace target that unlocks Freeze.

## P3

- **South third is empty.** y 10..16 holds 150 cells (37.5%) with no object, and the pocket's south lane is a 3×11 dead end. The room reads spacious, with the south third as bare lanes; decide dressing after the owner plays.
- **East door stands alone** on the open E edge (no low_E modules).
- **Doc mismatches:**
  - The checkpoint is at (272,120) = tile (2,5) in the scene; the layout says (5,5) and handoff §9 says (320,144).
  - The partitions are 1 whole + ½ (north) and ½ + 5 whole (south) per line, not "3 + ½".
  - The handoff's `door_exit_east` position is the spawn; the door is at (656,296).

## Passes

- **Dividers visible.** The bulkhead and both low-partition lines read in all five shots, with halves at the openings (a 2-tile art gap around the 1.5-tile opening).
- **Spawn and door spacing.** Trigger centre (236,102) r 6 to spawn (272,120) is about 40 px, roughly 2.2 tiles, with open floor on every side.
- **Route.** Hatch → fire shutter → inner shutter → east door reads as one diagonal along the north side.
- **Facing.** The hatch is correctly W-sheared. Gear and shutters are the known TLF-078 rows awaiting 085b; in the shots both shutters stand across their divider line instead of along it.

## Lead note (2026-11-11)

The 32×64 `ch01_prop_inner_shutter_closed/raised` pair is already a 2:1 W-face doorway aligned with the archway frame (ASSET_METADATA row 209, §B note). The fix round tries it for **both** shutters before any new art is drawn; Sol/Fable re-check.
