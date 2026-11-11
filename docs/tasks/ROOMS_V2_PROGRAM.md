# Chapter 1 rooms v2 program (owner direction 2026-11-11)

Owner: rebuild the remaining 8 rooms first, then improve all UI (HUD top-left, dialogue box: the owner gives the design when we get there, the Lead asks first), and from now on every room gets **lighting and shadows** for atmosphere and depth.

## Order and pipeline
Done: 1 `arrival_platform` (TLF-069), 2 `concourse_west` (TLF-080, lit TLF-083).

| # | Room | Today | Puzzle / beat | Task |
|---|---|---|---|---|
| 3 | `maintenance_bay` | 14 × 10 | CH1-PZ-002 + SO-02 (hatch, bell), Beat 04 | TLF-085 |
| 4 | `security_crossing` | 16 × 12 | CH1-PZ-003 (Echo), Beat 05 | TLF-086 |
| 5 | `waiting_lounge` | 12 × 10 | Beat 06 (Mira Trace, side memory entry) | TLF-087 |
| 6 | `signal_control` | 16 × 12 | CH1-PZ-004, Beat 07 | TLF-088 |
| 7 | `upper_vestibule` | 14 × 14 | CH1-PZ-005, Beat 08 | TLF-089 |
| 8 | `vestibule_niche` | 6 × 6 | part of CH1-PZ-005, Beat 08 (small by design: check, light, no widening unless cramped) | TLF-090 |
| 9 | `station_atrium` | 16 × 14 | Beat 09 | TLF-091 |
| 10 | `street_exit` | 12 × 10 | Beat 10 outro | TLF-092 |

Per room, in this order, pipelined so several rooms are in flight:
1. **Lead:** layout `design/ch01/rooms_v2/<room>.md` (+ `.json` outline) by PATTERN rules 1-12; puzzle clusters move as rigid blocks; no new text.
2. **Sol** (or Argon after his quota returns, Fable stand-in for review only): facing audit of the old room (PATTERN rule 12) and the missing N/W wall variants from the TLF-078 audit rows.
3. **Flash:** build with `build_room_from_shape.py`, room tests, door sweep, stand spots, manifests (edit in place), WIP pushes, hard timeouts.
4. **Opus:** technical review (mutations), then the room's lighting and shadows (ADR-026, ADR-027 once accepted) with a D.7 proof pack.
5. **Sol/Fable:** visual review. **Lead:** validates the exact merged tree, asks the owner for "Ya".

Lighting and shadows are part of every room's acceptance from now on (PATTERN rule 11, extended by TLF-084).
