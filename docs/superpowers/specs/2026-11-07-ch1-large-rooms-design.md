# Chapter 1 large rooms, free-form room shapes, scrolling camera (design)

Date: 2026-11-07 · Author: Lead · Status: APPROVED by the owner (2026-11-07) · Decision record: ADR-023.

## 1. Intent and why

The owner wants Chapter 1 rooms to feel larger relative to Elias, and to stop being plain rectangles. Today every room is a W×H rectangular iso grid between 6×6 and 16×14 tiles. All of it fits inside one fixed 640×360 screen with no camera. Elias is 32×48 px, so in a 14×10 room he is about 1/14 of the floor width, and the room has no sense of place beyond "a box".

The owner also reported two defects that belong in the same pass:
* some object sprites face the wrong way for where they stand;
* some objects still draw through (overlap incorrectly with) the character.

What was decided by the owner (their words, translated):
* Start with Chapter 1, not Chapter 2.
* The camera may follow Elias. Full screen is fine; "a bit zoomed on Elias" is acceptable.
* Do it in phases, room by room (approach A below).
* Rooms should be L-shaped and similar, not only rectangles.

## 2. Goals, non-goals, anti-goals

Goals
* Rooms noticeably larger than today, with a follow camera, while the internal canvas stays 640×360 (integer-scaled).
* Non-rectangular rooms (L, T, dog-leg, cross hub, alcove) in Chapter 1.
* No object draws through Elias. Object facing is correct for the room position.
* Every room lands as its own mergeable, validated change. The chapter stays playable and green at every merge.

Non-goals
* No redraw of characters (32×48 stays).
* No change to the 640×360 internal canvas or integer scaling.
* No dynamic lighting, no free (non-iso) movement, no new puzzle mechanics.
* No rework of Chapters 2+ yet (they adopt the new standard when authored).

Anti-goals (failure even if tests pass)
* A puzzle that becomes easier, skippable, or unsolvable (Step 1 specs, shortcut tables and the TLF-056 negative tests stay authoritative).
* A big room that is just empty floor. Each new space needs a reason (a route, a sightline, an alcove with an object).
* Elias hidden behind a tall wall.
* A pop or jitter when the camera moves (no sub-pixel scroll).

## 3. Constraints (found in the project)

* ADR-003: 640×360, tile 32×16 (2:1 dimetric). Floor px width = (W+H)·16, height = (W+H)·8, plus a 64 px north margin. The room fits one screen today because W+H ≤ 30.
* There is no `Camera2D`. Rooms are placed at fixed screen coordinates.
* Only the north-east (N) and north-west (W) walls are drawn as sprites (`WallN_i`, `WallW_i` in `YSort_Walls`). The south-east and south-west edges are open. Perimeter collision is one `CollisionPolygon2D` (a diamond today). Floor is a `TileMapLayer`.
* Doors sit on boundary tiles of the four straight sides, and the "opposite side" transition convention assumes a rectangle (ROOM_GRAPH §1). Explicit door pairs and spawn markers already exist (ADR-009).
* All puzzle, NPC and object positions are pixel coordinates in the room scene. About 16 test files (of 107) hard-code pixel coordinates; the real-input playthrough (TLF-056) depends on stand spots, apertures (TLF-055 §G) and door triggers.
* Characters and objects are drawn and sorted by y (`YSort_Actors`), with foot pivots.
* Art: Pixelorama sources, TLF-CH01-32 palette, art gates (`check_assets.py`, `verify_regen.py`) must stay green; new tiles/walls go through Argon, Sol reviews.
* Merge discipline: validate the exact tree, one reviewed SHA per merge, owner OK before each merge.

Finding that shapes the design: because only the N and W faces are drawn, an L-shape creates concave corners whose inner walls face south or east. Those walls stand between the camera and Elias and would hide him. See rule R2.

## 4. Approaches considered

A. Phased, room by room (CHOSEN by the owner). Build the camera and room-shape system first, fix sorting and facing, then re-lay-out one room at a time, starting with the Arrival Platform. Trade-off: slower to finish the whole chapter, but each room is tested and merged alone and the owner can judge room 1 before the rest.

B. All ten rooms in one go. Rejected: one giant change touching puzzles, ~16 coordinate-coupled test files and fresh art at once. Hard to validate or roll back. If the layout feels wrong the whole chapter is redone.

C. Only zoom (smaller viewport) or enlarge sprites. Rejected: does not change the character/room ratio, and enlarging sprites means redrawing every character.

## 5. Design (the parts decided, and my calls)

Rules (these are my calls; the owner can overrule):

R1 Camera. One `Camera2D` per room scene, following Elias, with position snapped to whole pixels (no smoothing blur), clamped to the bounding box of the room shape. A room that fits one screen gets a fixed camera exactly as today. Doors, checkpoints and the `Beat 10` overlay cinematic keep working (the overlay is a `CanvasLayer`, unaffected).

R2 No tall wall in front of the play space. Any wall face that would stand between the camera (south/east side) and walkable floor must be a low element (railing, partition, console row; at most about 20 px tall) so Elias is never hidden. Concave corners therefore use low partitions on their south/east faces. This avoids a cut-away or fade-through-wall system.

R3 Room shape is data. A `RoomShape` resource holds the floor outline as a polygon in tile coordinates. The tools build from it: floor tiles, the perimeter collision polygon, the list of N/W wall segments (including inner and outer corner pieces), and the camera bounds. Rooms are authored as shape plus objects, not by hand-placing wall sprites.

R4 Doors may be on any straight N/W boundary segment or on a south/east low-opening segment, paired explicitly (ADR-009). The "always the opposite side" convention is dropped. Room ids, door ids, checkpoint ids and safe-anchor ids do not change.

R5 Size target (my proposal, tuned on the pilot). Main rooms roughly 1.6-2× larger on each side than today: for example W+H around 40-52 (floor 640-830 px wide), so a room is about 1-1.5 screens wide and 1-1.3 screens tall, and the camera scrolls. Small rooms (the vestibule niche) stay small on purpose, for contrast. The measure of success is the ratio: Elias's floor-contact width and height versus the room's floor extent, not the tile count.

R6 Shape plan (proposals; the Lead and Argon finalise with the puzzle specs):

| Room | Shape |
|---|---|
| 1 Arrival Platform | L: platform plus a stair nook |
| 2 Concourse West | wide hall with a side alcove (T-ish) |
| 3 Maintenance Bay | L |
| 4 Security Crossing | dog-leg (Z) corridor |
| 5 Waiting Lounge | rectangle with a cut corner |
| 6 Signal Control | T |
| 7 Upper Vestibule | cross hub (four doors) |
| 8 Vestibule Niche | stays a small rectangle |
| 9 Station Atrium | large hall with an inner low-wall void |
| 10 Street Exit | L |

R7 Sorting and facing are fixed first, once, by rule. Sol audits every Chapter 1 room's objects from windowed screenshots (facing vs position, overlap with Elias at all four sides). Fixes are either sprite/pivot/z data or an art change by Argon. The audit list becomes a regression test where possible (sort order vs a probe actor).

R8 Puzzle preservation. A re-laid-out room keeps its puzzle spec relationships (what must be reachable from what, apertures at least 1.5 tiles wide per TLF-055 §G, rewind stand spots reachable, door triggers not overlapped). Each room's landing criteria: its real-input playthrough segment and its negative tests pass with the new layout (coordinates in tests are updated by the room's own task).

R9 Saves. Ids are stable; pixel positions are not. Pre-release dev saves made on the old Chapter 1 may be invalid after the pilot. The game is unreleased, so this is accepted.

R10 What fills the extra space (my call). Larger rooms are filled with existing set dressing and the TLF-063 environmental-story props (departure board, closed-track notice, pillar mark, sign, sealed door; their placement task is folded into the room tasks) plus routes and sightlines. No new puzzles and no new narrative text without the Lead. Any text on a prop is written by the Lead first.

## 6. Phases and owners (proposed)

P0 Technology (Opus): Camera2D follow with integer snap and clamping, `RoomShape` resource and builder tool, tests (camera never shows outside bounds, integer positions, door and checkpoint still work, collision matches shape), ADR-023 with the ADR-003 amendment.
P1 Audit (Sol): facing and overlap audit of all Chapter 1 rooms, list with screenshots.
P2 Sort/pivot/facing fixes (Opus for z/pivot data and tests; Argon for art that must change), driven by P1.
P3 Shape art kit (Argon, reviewed by Sol): inner/outer corner wall pieces for N/W, low partition pieces, new floor edge tiles, via the generator and Pixelorama, gates green.
P4 Pilot: Arrival Platform re-laid-out (Lead layout, Flash wiring, Opus review). Owner plays it and approves or changes the R5 size and shapes before P5.
P5 Rooms 2-10, one task each, in beat order, each merged and validated alone.
Running in parallel and unaffected: TLF-059, TLF-060, TLF-064. The Step 1 playtest gate moves to after P4 or after P5 (the owner decides then).

## 7. Left to the builder

Camera implementation details (limits vs script clamp, how transitions hand the camera over), the file format of `RoomShape`, how wall pieces are batched, exact tile counts per room within R5, naming, test structure.

## 8. Open items

* Exact room dimensions and shapes are tuned on the pilot (R5, R6).
* Whether the Step 1 playtest happens after the pilot or after all rooms.
