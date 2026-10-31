# Chapter 1 Puzzle Specifications — Index & Shared Contracts

**Task:** TLF-004  
**Owner:** Agent 2 (Argon — Narrative, Puzzle, Level Design & Art)  
**Source Beat Sheet:** `design/ch01/CH01_BEAT_SHEET.md` (merged `db09cc2`)  
**Architecture Baseline:** `docs/ADR_LOG.md` (SD-1, ADR-004 through ADR-014)  
**Template Standard:** `docs/PUZZLE_DESIGN.md` §2 & §5

---

## 1. Chapter 1 Puzzle Index

| Puzzle ID | Name | Beat | Room (`ADR-005` Prefix) | Primary Mechanics (`SD-1`) | Est. Time | Spec File |
|---|---|---|---|---|---|---|
| `CH1-PZ-001` | The Fractured Turnstile | Beat 02 | West Concourse (`ch01.concourse_west`) | **Taught:** Pocket Watch, `Trace`, `Rewind` (`initial_history`) | 4 min | `design/ch01/puzzles/CH1-PZ-001.md` |
| `CH1-PZ-002` | The Runaway Shutter | Beat 04 | Maintenance Bay (`ch01.maintenance_bay`) | **Taught:** `Freeze` · **Tested:** `Rewind` + `Freeze` (non-lethal) | 5 min | `design/ch01/puzzles/CH1-PZ-002.md` |
| `CH1-PZ-003` | The Delayed Platform | Beat 05 | Security Crossing (`ch01.security_crossing`) | **Taught:** `Echo` (record, replay, final-position occupancy, reset) | 6 min | `design/ch01/puzzles/CH1-PZ-003.md` |
| `CH1-PZ-004` | The Synchronized Substation | Beat 07 | Signal Control (`ch01.signal_control`) | **Tested:** Two-step `Rewind` + `Freeze` (Step 1) then `Echo` (Step 2) | 5 min | `design/ch01/puzzles/CH1-PZ-004.md` |
| `CH1-PZ-005` | The Displaced Corridor | Beat 08 | Upper Vestibule (`ch01.upper_vestibule`) | **Taught/Tested:** `Doorway Reassignment` (`SpatialGraph`) + `Trace` | 5 min | `design/ch01/puzzles/CH1-PZ-005.md` |

---

## 2. Shared Technical Conventions for Implementation (Flash / TLF-008 / TLF-009)

### 2.1 Simulation Clock (`ADR-004`)
- Physics tick rate is **60 Hz** (`1 tick = 1/60 s`, `60 ticks = 1.0 s`).
- All puzzle timers, echo event timestamps (`rel_tick`), and temporal state transitions are expressed in integer ticks.

### 2.2 Stable Identifier Scheme (`ADR-005`)
- Every object ID is a `StringName` matching `^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$`.
- Actor IDs:
  - Player: `&"player"`
  - Recorded Echo (Ch1 max 1): `&"echo.0"`
- Global tool ID: `&"global.pocket_watch"`.

### 2.3 Interaction Contract & Standard Failure Reasons (`ADR-006`, `ADR-007`)
All interactions route through `InteractionService.request(actor_id, target_id, interaction_id, payload) -> InteractionResult`:

| `interaction_id` | Source Action | Description |
|---|---|---|
| `&"use"` | `interact` (`E` / South Button) | Standard contextual physical interaction (pull lever, press button, read document, activate reset anchor). |
| `&"trace"` | `watch` (`Q` / LB) with `Trace` selected | Reveals residual temporal silhouettes, glyphs, or diagnostic clues on a supported target. |
| `&"rewind"` | `watch` (`Q` / LB) with `Rewind` selected | Steps a `TemporalComponent` (`REWIND` flag) back one entry in its history ring buffer. |
| `&"freeze"` | `watch` (`Q` / LB) with `Freeze` selected | Toggles `is_frozen` on a `TemporalComponent` (`FREEZE` flag), halting tick updates and rejecting state changes. |
| `&"reset"` | `interact` on a puzzle Reset Anchor | Restores the puzzle's dynamic objects to their initial tick-0 state and clears active echoes in that puzzle without touching permanent chapter progression. |

#### Standard Failure `reason` Codes (`StringName`)

| `reason` (`StringName`) | Condition | UI Feedback Key (`tr()`) | Default English String |
|---|---|---|---|
| `&""` | Valid interaction (`ok = true`) | — | — |
| `&"missing_target"` | `target_id` not registered in `IdRegistry` | `UI_FB_MISSING_TARGET` | *"Target is no longer present."* |
| `&"echo_forbidden"` | `progression == true` and `actor_id` begins with `"echo."` | `UI_FB_ECHO_FORBIDDEN` | *"An echo cannot claim permanent items or records."* |
| `&"unsupported"` | Target lacks the requested capability (`REWIND`, `FREEZE`, `FAST_FORWARD`, or `trace`) | `UI_FB_UNSUPPORTED` | *"The pocket watch cannot affect this object."* (or object-specific override) |
| `&"frozen"` | Target has `is_frozen == true` when a state-changing interaction (`&"use"`, `&"rewind"`) is requested | `UI_FB_FROZEN` | *"Object is locked in time—unfreeze it first."* |
| `&"no_history"` | Target supports `REWIND` but its history cursor is at the oldest entry | `UI_FB_NO_HISTORY` | *"No earlier temporal state recorded for this object."* |
| `&"already_open"` | Target is already in its open/solved state | `UI_FB_ALREADY_OPEN` | *"Already open."* |
| `&"unpowered"` | Target requires upstream electrical/bus power before it can operate | `UI_FB_UNPOWERED` | *"No power to this mechanism."* |
| `&"invalid_graph"` | `SpatialGraph.apply(transform)` rejected a doorway reassignment due to duplicate/dangling edges | `UI_FB_INVALID_GRAPH` | *"Route conflict—clear the active loop on the paired junction first."* |
| `&"critical_path_unreachable"` | `SpatialGraph.apply(transform)` would sever the entry anchor | `UI_FB_CRITICAL_PATH` | *"Safety interlock—cannot sever main entry route."* |

### 2.4 Temporal Component & Pre-History (`ADR-007` + Amendment)
- Each temporal object declares:
  - `capabilities`: subset of `{REWIND, FREEZE}` (`FAST_FORWARD` is unused in baseline Ch1 specs).
  - `schema_version`: `1` (int).
  - `state_fields`: `PackedStringArray` of serialized keys.
  - `initial_history`: `Array[Dictionary]` (oldest first), seeded into the history ring buffer at negative ticks (`-N … -1`) before the initial state at `tick 0`.
- When an object is rewound to an earlier state and subsequently changes state again during play (e.g. a rewound shutter slipping shut after `180` ticks), the new state transition is appended to the ring buffer, preserving the earlier state in history so the player can always `Rewind` it again without exhausting pre-history.

### 2.5 Echo Recording & Occupancy (`ADR-008`)
- Chapter 1 limits: **max 1 active echo (`&"echo.0"`)**, **max recording length 1200 ticks (20.0 s)**. All Ch1 echo puzzles are designed so the intended solution completes well inside **≤ 900 ticks (15.0 s)** (actual intended recordings are `60–240` ticks).
- Logic track records `[rel_tick, kind, target_id, interaction_id, payload]` where `kind ∈ {&"interact", &"trigger_enter", &"trigger_exit"}`.
- Upon reaching the final recorded tick, `&"echo.0"` remains at its final position and **maintains its trigger occupancy** until the echo is reset, deleted, or replaced.

---

## 3. Beat Sheet Deltas

**None.** All five puzzle specifications (`CH1-PZ-001` through `CH1-PZ-005`) match the locations, puzzle IDs, mechanics, narrative purposes, and pacing in `design/ch01/CH01_BEAT_SHEET.md` with zero modifications required.
