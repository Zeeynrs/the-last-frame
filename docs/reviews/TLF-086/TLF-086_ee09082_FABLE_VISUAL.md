# TLF-086 Security Crossing v2 — stand-in visual review, `ee09082`

**Verdict: CHANGES REQUIRED.** Reviewer: Fable 5.2, run by the Lead as a read-only stand-in for Sol (owner-approved), 2026-11-12. The outline, door spacing and the rigid move of cluster P are right; two faults in how the dividers are drawn block visual approval. Evidence: `docs/handoffs/TLF-086/*_960x540.png`, the room scene at `ee09082`, the same scene on `origin/main`, and the sprite files. Files were read with `git show`; nothing was run in Godot or written to the repo.

## P1

**P1-a — the trench is paved over.**
- `TileMapLayer_Floor` has all 384 cells, including the 16 cells of column x = 13, all terrazzo (source 4). On `origin/main` the trench column (x = 9) has no floor tiles.
- `TrenchVisual` is at z −1, so the tiles cover it: 56 of its 4,160 px are visible, all in the south outset tip (screen 365..382, 366..375).
- The room now shows two railings with ordinary floor between them, so the bridge has nothing to cross.
- Fix: remove the cells (13, 0..15), by hand as on main or with `--holes` (PATTERN rule 2 names it for trenches; the layout doc said not to).

**P1-b — the barrier partition's gap is one tile north of the barrier.**
- Collision opening on x = 16 is y 4.25..5.75, with `staff_barrier_01` at (16,5). The art gap is y 3..5.
- `PartitionLowE_barrier_n1_half` ends at y = 3 and the barrier sprite starts at y = 4. That leaves a 16 px hole in the wall beside the closed barrier (screen x 608..624, `arrival_960x540.png`). It is solid in collision but reads as a way round: an invisible divider again.
- `PartitionLowE_barrier_s0_half` (y 5..6) sits at the barrier's own position (496,232), under its sprite.
- The eight positions are the maintenance bay's x = 16 line, where the opening is at y = 4.
- Fix: make `n1` a whole module at (528,216) covering y 2..4, and delete `s0_half`. No halves are needed here.

## P2

1. **Bridge mouth art is offset from the opening.** Collision opening on x = 13 is y 5.25..6.75. The railing gap and the tactile gap are both y 6..8 on both lines, so 0.75 tile of the passage runs under `Railing_2`/`Railing_7` and 1.25 tiles of apparent opening are solid. Same on main; it moved with the cluster.
2. **`bridge_960x540.png` does not show the gate open or the bridge extended.** Apart from Elias and the HUD marker it is pixel-identical to the other shots. The landing criteria ask for "bridge (gate open)". Re-shoot with the switch held, and add one with the staff barrier open.
3. **The transit pass has no visible pixel.** Its clipboard (screen 488..504 × 194..210) is entirely behind the guard statue (z 8 under z 10). It is the item the card reader needs. Same geometry on main; for TLF-086b (a desk, or the pass drawn in front).
4. **Card reader is not on the barrier plane.** It stands on the floor at (15,7), one tile west of the partition and two tiles south of the barrier, a 16 px wide box at the east end of the bridge stub, and reads as part of the bridge. Tracked for TLF-086b in layout §3.
5. **PA speaker is still the frontal 16×16 horn** on the N wall. Tracked for TLF-086b.

## P3

- **Bare halls.** Entry hall (64 cells) and exit hall (128 cells) hold no visible object besides the doors, and nothing sits south of y = 11 except the two divider lines. Spacious, not broken; decide dressing after the owner plays.
- **Landing reads as a strip.** The partition hides the x = 15 column, so the 2-wide landing shows only its orange tactile column.
- **Tactile band and lighting.** 476 px of the brightest ambers run wall to wall along the trench. For the lighting task: if those are the exempt indices, they will not dim.
- **Trench colour.** `TrenchVisual` is `0f141c`, not a palette colour. Use index 00 or 01 once the trench shows again.
- **East door** stands alone on the open E edge, half over the void, as in the other v2 rooms.
- **Unshot stand spot.** The gate stand spot (448,208) coincides with `Railing_2`'s origin; there is no shot there.
- **Handoff vs scene mismatches:**
  - Perimeter polygon: the handoff lists (656,144)…; the scene has (320,60), (712,256), (448,388), (56,192).
  - Size: "768 × 328 px" in the handoff; the floor is 640 × 320.
  - Stand-spot tiles: card reader "(15,8)" is (15,6); guard "(7,3)" is (8,4); gate "(13,4)" is (13,5).
  - Barrier opening: "y ≈ 5..6" in the handoff; collision is 4.25..5.75.

## Passes

- **Dividers run wall to wall.** Both railing lines reach the N wall and the S edge (new modules at y 13 and 15 on each line). The partition's south run is continuous from y 6 to 16.
- **Cluster P moved rigidly by (64,32).** All 16 rows of layout §2 match the scene node positions. The ten old railings, `PASpeakerSprite` ((336,38) → (400,70)), the trench polygon and segments, and the barrier segments match too.
- **Spawn, checkpoint and doors.** Door trigger centre (220,110) r 6 to spawn (256,128) is about 40 px, roughly 2.2 tiles. Checkpoint at (288,144) = (4,6). East door at (608,304) = (24,6), with its spawn at (22,6).
- **No leftovers.** Root `ArchwayWest`/`ArchwayEast` are gone; one frame per door. Grating, conduit and tactile cells are all at their shifted positions, none at the old ones.
- **Elias is whole in all five shots** (arrival, deck, bridge, landing at the reader stand spot, east door).
- **Props visible and upright.** Guard, guard log, alarm plate, pedestal, south plate and reset console are all visible and none is painted onto a wall. The staff barrier stands along its divider line.

## Lead decisions (2026-11-12)

Recorded in `design/ch01/rooms_v2/security_crossing.md` §7: trench column x = 13 becomes a hole (layout §1 corrected); the barrier partition gap is the barrier sprite's span (n1 whole, s0_half deleted); the railing and tactile gaps move to y 5..7 to contain the bridge opening; re-shoot bridge open, barrier open and gate stand spot; handoff numbers fixed; P2-3..5 go to TLF-086b.
