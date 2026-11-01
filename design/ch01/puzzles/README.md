# Chapter 1 Puzzle Specifications — Index & Shared Contracts

**Task:** TLF-004  
**Owner:** Agent 2 (Argon — Narrative, Puzzle, Level Design & Art)  
**Source Beat Sheet:** `design/ch01/CH01_BEAT_SHEET.md` (merged `db09cc2`)  
**Architecture Baseline:** `docs/ADR_LOG.md` (SD-1, ADR-004 through ADR-016)  
**Template Standard:** `docs/PUZZLE_DESIGN.md` §2 & §5

---

## 1. Chapter 1 Puzzle Index

| Puzzle ID | Name | Beat | Room (`ADR-005` Prefix) | Primary Mechanics (`SD-1`) | Est. Time | Spec File |
|---|---|---|---|---|---|---|
| `CH1-PZ-001` | The Fractured Turnstile | Beat 02 | West Concourse (`ch01.concourse_west`) | **Taught:** Pocket Watch, `Trace`, `Rewind` (`initial_history`) | 4 min | `design/ch01/puzzles/CH1-PZ-001.md` |
| `CH1-PZ-002` | The Runaway Shutter | Beat 04 | Maintenance Bay (`ch01.maintenance_bay`) | **Taught:** `Freeze` · **Tested:** `Rewind` + `Freeze` (non-lethal) | 5 min | `design/ch01/puzzles/CH1-PZ-002.md` |
| `CH1-PZ-003` | The Delayed Platform | Beat 05 | Security Crossing (`ch01.security_crossing`) | **Taught:** `Echo` (record, replay, final-position occupancy, reset) | 6 min | `design/ch01/puzzles/CH1-PZ-003.md` |
| `CH1-PZ-004` | The Synchronized Substation | Beat 07 | Signal Control (`ch01.signal_control`) | **Tested:** Two-step `Rewind` + `Freeze` (Step 1) then `Echo` (Step 2) | 5 min | `design/ch01/puzzles/CH1-PZ-004.md` |
| `CH1-PZ-005` | The Displaced Corridor | Beat 08 | Upper Vestibule (`ch01.upper_vestibule` + `ch01.vestibule_niche`) | **Taught/Tested:** `Doorway Reassignment` (`SpatialGraph`) + `Trace` | 5 min | `design/ch01/puzzles/CH1-PZ-005.md` |

---

## 2. Shared Technical Conventions for Implementation (Flash / TLF-008 / TLF-009)

### 2.1 Simulation Clock (`ADR-004`)
- Physics tick rate is **60 Hz** (`1 tick = 1/60 s`, `60 ticks = 1.0 s`).
- All puzzle timers, echo event timestamps (`rel_tick`), and temporal state transitions are expressed in integer ticks.

### 2.2 Stable Identifier Scheme (`ADR-005`, `ADR-009`)
- Every registered node ID is a `StringName` matching `^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$`.
- Doorway IDs in `SpatialGraph` are room-local keys `(room_id, door_id)` (written `room_id:door_id` in prose) and are not registered in `IdRegistry` (doorway presenter nodes are).
- Actor IDs:
  - Player: `&"player"`
  - Recorded Echo (Ch1 max 1): `&"echo.0"`
- Global tool ID: `&"global.pocket_watch"`.

### 2.3 Interaction Contract, Targeting & Failure Reasons (`ADR-006`, `ADR-007`, `ADR-015`)
- State-changing interactions and pocket-watch abilities route through `InteractionService.request(actor_id, target_id, interaction_id, payload) -> InteractionResult`.
- `InteractionService.trigger_enter(actor_id, trigger_id)` and `trigger_exit(actor_id, trigger_id)` return `void` and carry no failure reasons; each trigger handler decides per actor what happens, and puzzle completion triggers simply ignore `echo.*` actors (`ADR-006`, `ADR-016`).
- Pocket-watch targeting (`ADR-015`): candidates are `Interactable`s within the watch radius (default `96 px`), preferring the nearest candidate that supports the selected ability, or falling back to the nearest overall so `&"unsupported"` feedback remains teachable.

| `interaction_id` | Source Action | Description |
|---|---|---|
| `&"use"` | `interact` (`E` / South Button) | Standard contextual physical interaction (pull lever, press button, read document, collect pickup). |
| `&"trace"` | `watch` (`Q` / LB) with `Trace` selected | Reveals residual temporal silhouettes, glyphs, or diagnostic clues on a supported target. |
| `&"rewind"` | `watch` (`Q` / LB) with `Rewind` selected | Steps a `TemporalComponent` (`REWIND` flag) back one snapshot in its history (`cursor -= 1`). |
| `&"freeze"` | `watch` (`Q` / LB) with `Freeze` selected | Toggles `TemporalComponent.is_frozen` on a supported target (`FREEZE` flag), halting tick updates and rejecting state changes while frozen. |
| `&"reset"` | `interact` on a puzzle Reset Anchor | While `UNSOLVED`, restores the puzzle's dynamic objects to their initial tick-0 state and clears `&"echo.0"`. After `SOLVED` (`ADR-016`), never re-blocks the solved passage. |

#### Standard Failure `reason` Codes (`StringName`)

| `reason` (`StringName`) | Condition | UI Feedback Key (`tr()`) | Default English String |
|---|---|---|---|
| `&""` | Valid interaction (`ok = true`) | — | — |
| `&"missing_target"` | `target_id` not registered in `IdRegistry` | `UI_FB_MISSING_TARGET` | *"Target is no longer present."* |
| `&"echo_forbidden"` | `progression == true` on a `request()` interaction and `actor_id` begins with `"echo."` | `UI_FB_ECHO_FORBIDDEN` | *"An echo cannot claim permanent items or records."* |
| `&"unsupported"` | Target lacks the requested capability (`REWIND`, `FREEZE`, `FAST_FORWARD`, or `trace`) | `UI_FB_UNSUPPORTED` | *"The pocket watch cannot affect this object."* (or object-specific override) |
| `&"frozen"` | Target (or its coupled mechanism) is frozen when a state-changing interaction (`&"use"`, `&"rewind"`) is requested | `UI_FB_FROZEN` | *"Object is locked in time—unfreeze it first."* |
| `&"no_history"` | Target supports `REWIND` but its history `cursor == 0` | `UI_FB_NO_HISTORY` | *"No earlier temporal state recorded for this object."* |
| `&"already_open"` | Target is already in its open/solved state | `UI_FB_ALREADY_OPEN` | *"Already open."* |
| `&"unpowered"` | Target requires upstream electrical/bus power before it can operate | `UI_FB_UNPOWERED` | *"No power to this mechanism."* |
| `&"invalid_graph"` | `SpatialGraph.apply(transform)` rejected a doorway reassignment due to duplicate/dangling edges | `UI_FB_INVALID_GRAPH` | *"Route conflict—clear the active loop on the paired junction first."* |
| `&"critical_path_unreachable"` | `SpatialGraph.apply(transform)` would sever the entry anchor | `UI_FB_CRITICAL_PATH` | *"Safety interlock—cannot sever main entry route."* |

### 2.4 Temporal Component, History Cursor & Freeze Ownership (`ADR-007` + Amendments 1 & 2)
- Each temporal object declares `capabilities` (`REWIND`, `FREEZE`), `schema_version = 1`, `state_fields: PackedStringArray`, and `initial_history: Array[Dictionary]` (oldest first, seeded before the tick-0 snapshot with `cursor` starting on the tick-0 entry).
- **Discrete Commit Rule (`ADR-007` Amendment 2):** `commit_history()` is called only on a **discrete state transition** (e.g., `raised → closed`), never on per-tick counter decrements (`hold_ticks`, `decay_ticks`, `engage_ticks`). Rewinding decrements `cursor` by 1 and restores that snapshot (including its full counter value).
- **Freeze Flag Ownership (`ADR-007` Amendment 2):** `is_frozen: bool` is owned by `TemporalComponent` itself (toggled by `&"freeze"`), and is **never** part of `state_fields` or `initial_history`.

### 2.5 Echo Recording, Controls & Completion/Reset Policy (`ADR-008`, `ADR-015`, `ADR-016`)
- Chapter 1 limits: **max 1 active echo (`&"echo.0"`)**, **max recording length 1200 ticks (20.0 s)**, design target **≤ 900 ticks (15.0 s)**.
- Logic track records only non-watch `interact` events (`&"use"`) plus `trigger_enter` and `trigger_exit` (triggers already occupied at recording start are seeded at `rel_tick = 0`). Echoes are controlled via `watch` (`IDLE → RECORDING → READY → PLAYING`) and cleared from any state via `echo_reset` (`R` / Joypad Y, `ADR-015`).
- **Post-Solve Reset Policy (`ADR-016`):** Once a puzzle reaches `SOLVED` in `PuzzleService`, its solved passage remains permanently open—reset anchors, unfreezing, and `echo_reset` never re-block a solved route.

---

## 3. Beat Sheet Deltas

1. **Sub-Room Addition in Beat 08 (`ch01.vestibule_niche`, Accepted by Lead):**
   - `CH1-PZ-005` adds a small dead-end inspection alcove (`ch01.vestibule_niche`, with doorways `door_in` and `door_out`) adjacent to `ch01.upper_vestibule`.
   - **Rationale:** Ensures all 8 doorway endpoints in `SpatialGraph` are paired 1-to-1 across every valid graph state (`State 0`, `State 1`, `State 2`) with zero dangling doorways (`ADR-009`), while letting the player visually glimpse the Station Atrium through a barred masonry grille (`traversable = false`) and inspect an optional ELYSIUM threshold-indexing plaque. No beat order, timing, or narrative changes are needed.

---

## 4. Step 1 additions (TLF-047 phase 2)

| Puzzle ID | Name | Beat | Room | Primary mechanics | Est. time (design / floor) | Spec |
|---|---|---|---|---|---|---|
| `CH1-SO-01` | Last Departure | 01b | `ch01.arrival_platform` | **Trace solo**: four frozen witnesses, latest statement wins | 2.7 / 1.6 min | `CH1-SO-01.md` |
| `CH1-SO-02` | Held Open | 04b | `ch01.maintenance_bay` | **Freeze solo**: hold a plate-operated hatch open | 2.1 / 1.3 min | `CH1-SO-02.md` |
| `CH1-PZ-006` | Last Ticket | 03b | `ch01.concourse_west` | **Trace + Rewind**: find the one valid ticket, rewind three dials to it | 4.3 / 2.6 min | `CH1-PZ-006.md` |

`CH1-PZ-001…005` keep their IDs and base specs; each file ends with a section **R1 Revision 1 (TLF-047 Step 1)** listing the deltas, new objects, tests and the revised estimate (the three hint lines in section 1 are the revised ones; the superseded ones are quoted in R1). The estimates in the table of section 1 above are the *beat-sheet* figures and are superseded by the modelled ones in `CH01_BEAT_SHEET.md` §7.2. New shared specs: `design/ch01/TRACE_MEMORY.md`, `design/ch01/ABILITY_UNLOCKS.md`, `design/ch01/COMMUTERS_STEP1.md`. New failure reasons introduced in Step 1: `wrong_code`, `locked_out` (SO-01), `invalid_ticket` (PZ-006), `pinned` (PZ-001), `unanchored` (PZ-002), `no_pass` (PZ-003), `dead_relay` (PZ-005); the existing `unpowered` is reused by PZ-004 breaker C and the PZ-005 relays.
