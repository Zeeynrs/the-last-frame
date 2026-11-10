# Room v2 pattern (copied by the nine room tasks after the pilot)

Approved with the pilot layout, to be confirmed after the owner plays Arrival Platform v2 (ADR-023).

1. **Layout doc** `design/ch01/rooms_v2/<room>.md` by the Lead: outline (tile coordinates), size (target W+H 40..52 for main rooms), object table with tile and reason, door pairing, camera notes, landing criteria. Cut Ls on the S/E side (R2b); a N/W cut only with the hidden floor made unwalkable.
2. **Shape** as a JSON outline for `tools/content/build_room_from_shape.py`: `--outset 0.25`, `--tile-source` per room (4 for maintenance_bay, security_crossing, signal_control), `--holes` for trenches, `--edge-strip 2,S,E` for platform edges, `--door` only after Sol has reviewed a rebuilt N/W door.
3. **Build:** dry run first, review the diff, then `--write`. The builder writes floor, perimeter polygon, N/W wall modules and `metadata/room_shape`; low partitions, corners and end caps come from the TLF-068 mapping table (§10.2 recipe).
4. **Objects** keep their ids; only positions change. Stand spots follow the puzzle spec (17.9 px), apertures at least 1.5 tiles, statues off the walking line.
5. **Tests to update per room:** its segment of the real-input playthrough, its negatives, `test_ch01_sort_order.gd` rows, the collision baseline entry and any kit-complete test for that room, plus the capsule probes (door sweep, stand-spot reach).
6. **Review:** Opus technical review (reach, apertures, camera edges), Sol visual and facing/overlap review, the Lead validates the exact tree, the owner OKs the merge.
7. **Merge discipline:** one room per merge; full validate 0 failed; Python builder tests when `tools/content/` changes.

## Rules added after the owner's concourse feedback (2026-11-10, apply to every room from now on)

8. **Space check before dressing.** Lead measures every old room before its layout: if it feels full or narrow, the room is widened (target W+H 40..52, at least 18 floor cells per object, every route between interactive things at least 3 tiles wide, at least 2 free tiles around the arrival and each checkpoint). Widening needs no extra owner approval; the owner sees the result in play and can ask for more.
9. **Props face the wall, not the screen.** A fixture mounted on a wall uses the sheared variant for that face (TLF-078). A freestanding prop within 1.5 tiles of a wall faces into the room, parallel to the wall (an iso facing variant); frontal art is allowed only in open floor. A prop is never placed in front of a doorway, on the line between two doors, or inside another prop's footprint. Every new prop is checked against this rule before it is placed; a frontal asset blocks the room until its variant exists.
10. **Spawn and doors.** No door trigger within 2 tiles of a spawn or checkpoint (3 where the layout allows); the door trigger is the thin aperture only; the test suite sweeps a held left/up/down press from the arrival for 3 s and the door must not trigger.
11. **Lighting from room 2 on (owner, 2026-11-10).** Every rebuilt room gets its lighting pass with the model from TLF-082 (ADR-026) and the Appendix D mood table; light motivates focal points (gate, clock, the next traversal decision), never every prop.
12. **Facing audit per room.** Before a room is built, Sol lists every prop in it as wall fixture / freestanding-against-wall / open floor, frontal or iso, and the variants needed; Argon (fallback Sol) draws only what is listed; Flash builds geometry in parallel and swaps the art in when it lands (as in the pilot).

