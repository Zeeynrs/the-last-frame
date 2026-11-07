# Room v2 pattern (copied by the nine room tasks after the pilot)

Approved with the pilot layout, to be confirmed after the owner plays Arrival Platform v2 (ADR-023).

1. **Layout doc** `design/ch01/rooms_v2/<room>.md` by the Lead: outline (tile coordinates), size (target W+H 40..52 for main rooms), object table with tile and reason, door pairing, camera notes, landing criteria. Cut Ls on the S/E side (R2b); a N/W cut only with the hidden floor made unwalkable.
2. **Shape** as a JSON outline for `tools/content/build_room_from_shape.py`: `--outset 0.25`, `--tile-source` per room (4 for maintenance_bay, security_crossing, signal_control), `--holes` for trenches, `--edge-strip 2,S,E` for platform edges, `--door` only after Sol has reviewed a rebuilt N/W door.
3. **Build:** dry run first, review the diff, then `--write`. The builder writes floor, perimeter polygon, N/W wall modules and `metadata/room_shape`; low partitions, corners and end caps come from the TLF-068 mapping table (§10.2 recipe).
4. **Objects** keep their ids; only positions change. Stand spots follow the puzzle spec (17.9 px), apertures at least 1.5 tiles, statues off the walking line.
5. **Tests to update per room:** its segment of the real-input playthrough, its negatives, `test_ch01_sort_order.gd` rows, the collision baseline entry and any kit-complete test for that room, plus the capsule probes (door sweep, stand-spot reach).
6. **Review:** Opus technical review (reach, apertures, camera edges), Sol visual and facing/overlap review, the Lead validates the exact tree, the owner OKs the merge.
7. **Merge discipline:** one room per merge; full validate 0 failed; Python builder tests when `tools/content/` changes.
