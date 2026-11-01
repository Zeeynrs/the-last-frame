# Art wish list — Chapter 1 Step 1 (TLF-047 phase 2)

**For:** a later design-art task (not part of phase 2). **Source:** the Step 1 specs in `design/ch01/puzzles/`, `TRACE_MEMORY.md`, `COMMUTERS_STEP1.md`. **Style:** TLF-CH01-32 palette, binary alpha, 2:1 isometric, light from the top-left, generated and reproducible through `tools/art/gen/` (ADR-019). Only what serves the story or a puzzle state.

## A. Frozen commuters ("statues")

User decision: **desaturated grey statues with a shimmer**.

| Item | Spec | Notes |
|---|---|---|
| Bodies | **3 base bodies × 2 poses** = 6 sprites, ~16 × 40 px each (Elias is ~16 × 48) | build A (slim), B (broad), C (child/small); pose 1 standing, pose 2 mid-action (running start / reaching / leaning) |
| Palette | a 5-step grey ramp taken from the existing 32 colours (no new colours); one accent per statue from the 32 (coat, bag) at **reduced** brightness | "frozen" must read against the living Elias at ×3 |
| Props | ~14 small overlays: suitcase, paper bag, whistle, trolley, phone, red coat, briefcase, sleeping child, headphones, hatch crank, gate lever, breaker handle, map, courier bag | palette-swap/overlay, not new bodies |
| Shimmer ring | 4-frame loop, 24 × 12 px ellipse at the feet, plus a 6 × 6 **time-stamp glyph** (clock hand) above the head | shown only while Trace is selected and the statue is within 96 px (rule R8: a shape cue, not only colour) |
| "Read" outline | static 1 px outline variant | shown after the first Trace (`ch01.npc.<id>.traced`); `reduced_effects`: no animation, outline only |
| Specific poses | N-05 courier **mid-vault** (one foot off the floor), N-11 hatch tech **leaning back on a crank**, N-04 cleaner with trolley, N-03 old man **seated** on the existing bench | the courier and the tech are the two unlock moments |
| Footprint | 12 × 8 px collision, pivot at the feet `(8, 36)` | per `COMMUTERS_STEP1.md` |

## B. New props (by puzzle)

| Puzzle | Prop | States | Size (suggested) | Reuse |
|---|---|---|---|---|
| SO-01 | **Selector panel** (3 selectors, wall-mounted) | 3 positions each, each with a **shape glyph**: LINE circle/diamond/triangle, PLATFORM 1-3 pips, CAR 3 car silhouettes | 32 × 48 module | wall module + `prop_lever_switch` badges |
| SO-01 | **Release lever** + panel status lamp | idle / buzzing (X glyph, 6 s) / accepted (`[>>>]`) | 24 × 36 | `prop_lever_switch` |
| SO-01 | **Platform gate** (security shutter in the east archway) | closed / open | 32 × 64 | `prop_fire_shutter` style |
| PZ-001 | **Fallen conduit** / **mounted conduit** | `fallen` (across the south lane), `mounted` (ceiling bracket) | 48 × 32 | cable-conduit tiles |
| PZ-006 | **Split-flap dial** (wall panel) ×3 (LINE / PLATFORM / TIME) | 6 label states are text (font-rendered), frame art is one sprite; "jammed" shake frame | 32 × 32 | |
| PZ-006 | **Ticket validator console** | idle / rejecting (X glyph) / accepted | 24 × 36 | `prop_reset_console` |
| PZ-006 | **Staff door** (east archway shutter) | closed / open | 32 × 64 | shared with the platform gate |
| PZ-006 | Ticket-terms notice | plaque | 16 × 20 | `prop_document_clipboard` |
| SO-02 | **Service hatch** (bulkhead door) | closed / open / **frozen open** (brass lock ring `[o]`, a shape) / frozen closed | 32 × 64 | shutter family |
| SO-02 | **Bulkhead wall module** | wall piece, N-S run | 32 × 64 | `wall_tiled_subterranean_n/w` |
| SO-02 | **Floor plates A (brass) and B (green)** | empty / pressed; each carries a letter | 32 × 16 | `pressure_switch` |
| SO-02 | Bell icon (decoy) | idle / ringing | 8 × 8 | |
| PZ-002 | **Inner shutter** | closed / raised (same sprite as the first shutter, recoloured plate) | 32 × 64 | `prop_fire_shutter` |
| PZ-003 | **Echo pedestal** | idle / used | 24 × 36 | `prop_reset_console` |
| PZ-003 | **Card reader** + **staff barrier** | reader: idle / denied (X) / accepted; barrier: closed / open | 16 × 24 / 32 × 64 | |
| PZ-003 | **Alarm plate** | idle / ringing (red lamp + bell glyph) | 32 × 16 | |
| PZ-004 | **Breaker C** with lamp-ring icon | idle / engaged / browned-out | 24 × 36 | `prop_lever_switch` badge "lamp ring" |
| PZ-005 | **Standby plate** (SW corner) | empty / held (echo) | 32 × 16 | |
| PZ-005 | **Dead relay lever C** | idle / "never wired" shake | 24 × 36 | `prop_lever_switch` |

## C. HUD and watch (also feeds TLF-053 / TLF-052)

* Watch-face motifs for the four unlocks: Trace (single sweep), Rewind (hand ticks backwards), Freeze (hand stops), Echo (a second hand follows). 4 short animations or 4 static frames each; the ability icons themselves are TLF-053.
* Unlock toast frame (reuses the HUD feedback panel).

## D. Dressing (story of the room, only what serves it)

R1 conductor's whistle and chalk platform numbers; R2 split-flap ticket wall, queue lamp; R3 steam haze at the hatch, hatch chart; R4 red alarm lamp on the north plate, guard booth log; R6 labelled breaker bank A/B/C; R7 relay box with a standby plate. All reuse existing tiles and wall modules; no new floor tile is needed.

## E. Accessibility checklist for the art task

Every state above is distinguishable **without colour** (glyph or shape): selector positions, plate letters, hatch lock ring, X/accepted glyphs, shimmer's clock glyph; greyscale proof PNG per prop family as in TLF-044.
