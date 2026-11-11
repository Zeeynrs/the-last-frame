# TLF-085 round 2 — stand-in visual re-check (`1d01443`)

**Verdict: CHANGES REQUIRED** — one P1, a one-line scene fix. P1-a and P1-b are closed. Reviewer: Fable 5.2, run by the Lead as a read-only stand-in for Sol (owner-approved), 2026-11-11. Files were read with `git show`; nothing was run in Godot or written by the reviewer.

## P1 — a stray archway stands one tile inside the east door

- **What it looks like:** two archway frames sharing a post at the east end (`arrival_960x540.png`, screen x 720..741 and 736..767, y about 300..375). Both show amber threshold lamps, so it reads as a double door.
- **Cause:** the root node `ArchwayEast` is still at (656,296), tile (25,4). `door_exit_east` and `YSort_Walls/Archway_door_exit_east` moved to (672,304), tile (26,4).
- **Effect:** the old frame stands on the walking line, one tile inside the room.
- **Fix:** move `ArchwayEast` to (672,304), co-located with its twin as `ArchwayWest` is, or delete it. A re-shot `east_door_960x540.png` is enough to close this.

## Closed

**P1-a — bulkhead.**
- `Wall_bulkhead_s0..s5` are now the low partition; only `n0` stays tall.
- The hatch plate, chart and bell lie on the floor west of the rail. The plate's corner overlaps the rail top by 2–4 px, which reads as lying beside it.
- The entry hall and gear bay now read as one space.

**P1-b — pocket.**
- At `safe_anchor_east` Elias shows 525 changed px, the same as in the open (555 at the east door, 527 at the gear stand spot). In round 1 he was a 6 px strip.
- The 32×64 W-face shutters stand along their divider lines and fill the 2-tile art gap.
- `pocket_960x540.png` and `pocket_safe_anchor_east_960x540.png` are pixel-identical; one is redundant.

## P2 re-check

1. **Gear/shutter stack: improved, acceptable.** They still share a screen column, but the shutter now covers 188 of the gear's 1,926 px (10%, was 18%) and is half as wide, so they no longer read as one machine.
2. **Gear stand spot: fine.** In `gear_stand_spot_960x540.png` Elias is whole and covers about 10 of the gear's 37 columns. The HUD target marker sits over his face in that shot; that is HUD placement, not the room.
3. **Plaque on the rail: unchanged.** `doc_inner_shutter_plate` is still the floor clipboard at (608,224), the origin of `PartitionLowE_inner_n0`. Tracked for TLF-085b in layout §7.6.
4. **Technician: unchanged.** About 8 of the statue's 16 px columns show left of the hatch frame. Also tracked for TLF-085b.

## P3

- Both shutters now use the same art, so the fire shutter and inner shutter look identical. That is the Lead's decision; revisit if playtesters confuse them.
- The S and E edges are still open (no low partition). The south third remains bare apart from the grating and the rails.
