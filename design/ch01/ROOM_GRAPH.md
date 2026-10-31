# Chapter 1 Station Room Graph & Level Flow — "The Forgotten Station"

**Task:** TLF-005  
**Owner:** Agent 2 (Argon — Narrative, Puzzle, Level Design & Art)  
**Source Documents:** `design/ch01/CH01_BEAT_SHEET.md` (`db09cc2`), `design/ch01/puzzles/CH1-PZ-001.md` … `CH1-PZ-005.md` (`eed7c4e`)  
**Architecture Baseline:** `docs/ADR_LOG.md` (ADR-003, ADR-005, ADR-009, ADR-010, ADR-015, ADR-016)

---

## 1. Isometric Coordinate & Camera Standard (`ADR-003`)

- **Internal Canvas:** `640 × 360 px` (integer-scaled `×3` to `1920 × 1080`).
- **Tile Footprint:** `32 × 16 px` (2:1 dimetric isometric diamond). Character height ≈ `48 px`.
- **Tile-to-Pixel Mapping (Fixed-Camera Room Space):**
  - Each room grid of `W × H` tiles (`x ∈ [0 .. W-1]` running North-West to South-East, `y ∈ [0 .. H-1]` running North-East to South-West) has its top-north floor apex `(0, 0)` anchored at screen coordinate **`(320, 64)`** (leaving a `64 px` top margin for rear wall height and HUD):
    $$\text{px\_x}(x, y) = 320 + (x - y) \times 16, \qquad \text{px\_y}(x, y) = 64 + (x + y) \times 8$$
  - Total floor diamond pixel width = $(W + H) \times 16\text{ px}$; total floor diamond pixel height = $(W + H) \times 8\text{ px}$.
- **Camera Rule:** Every room in Chapter 1 is sized between `6 × 6` tiles (`192 × 96 px` floor) and `16 × 14` tiles (`480 × 240 px` floor + `64 px` north wall = `480 × 304 px`). **All 10 rooms fit completely inside a fixed `640 × 360` camera** with zero camera scrolling required.

---

## 2. Chapter 1 Room Table (10 Rooms)

| # | Room ID (`ADR-005`) | Beat(s) | Purpose | Footprint (`W×H` Tiles / Floor Px) | Camera | Doorways (`door_id`, Wall Side, Tile `(x,y)`) | Puzzle(s) | Checkpoint (`checkpoint_id`) | Safe Anchors (`object_id` @ Tile `(x,y)` / Px) |
|---|---|---|---|---|---|---|---|---|---|
| **1** | `ch01.arrival_platform` | Beat 01 | Awakening, movement & inspect tutorial, pocket watch pickup (`global.pocket_watch`) | `14 × 10`<br>(`384 × 192 px`) | Fixed `640×360` | • `door_exit_west` (W, `(0, 5)`) | — | **Yes**<br>`ch01.cp.arrival` | • `ch01.arrival_platform.safe_anchor_spawn` @ `(7, 5)` `(352, 160)` |
| **2** | `ch01.concourse_west` | Beat 02,<br>Beat 03 | Pocket-watch tutorial (`Trace` + `Rewind`) at East Turnstile; Call Box 09 dialogue with The Operator | `16 × 12`<br>(`448 × 224 px`) | Fixed `640×360` | • `door_entry_east` (E, `(0, 5)`)<br>• `door_exit_north` (N, `(8, 0)`) | `CH1-PZ-001` | **Yes**<br>`ch01.cp.concourse_west` | • `ch01.concourse_west.safe_anchor_east` @ `(1, 5)` `(256, 112)`<br>• `ch01.concourse_west.safe_anchor_west` @ `(4, 5)` `(304, 136)` |
| **3** | `ch01.maintenance_bay` | Beat 04 | Teach `Freeze`; test `Rewind` + `Freeze` on dropped fire shutter & counterweight gear | `14 × 10`<br>(`384 × 192 px`) | Fixed `640×360` | • `door_entry_west` (W, `(2, 5)`)<br>• `door_exit_east` (E, `(13, 4)`) | `CH1-PZ-002` | **Yes**<br>`ch01.cp.maintenance_bay` | • `ch01.maintenance_bay.safe_anchor_west` @ `(5, 4)` `(336, 136)`<br>• `ch01.maintenance_bay.safe_anchor_east` @ `(10, 4)` `(416, 176)` |
| **4** | `ch01.security_crossing` | Beat 05 | Teach `Echo` record/replay/reset and persistent trigger occupancy on pressure switch | `16 × 12`<br>(`448 × 224 px`) | Fixed `640×360` | • `door_entry_west` (W, `(1, 6)`)<br>• `door_exit_east` (E, `(15, 6)`) | `CH1-PZ-003` | **Yes**<br>`ch01.cp.security_crossing` | • `ch01.security_crossing.safe_anchor_west` @ `(6, 6)` `(320, 160)`<br>• `ch01.security_crossing.safe_anchor_east` @ `(13, 6)` `(432, 216)` |
| **5** | `ch01.waiting_lounge` | Beat 06 | Recorded character presence (Mira `Trace` silhouette, audio log, memory fragment `ch01.fragment.mira_departure`) | `12 × 10`<br>(`352 × 176 px`) | Fixed `640×360` | • `door_entry_south` (S, `(6, 9)`)<br>• `door_exit_north` (N, `(6, 0)`) | — | **Yes**<br>`ch01.cp.waiting_lounge` | • `ch01.waiting_lounge.safe_anchor_center` @ `(6, 5)` `(336, 152)` |
| **6** | `ch01.signal_control` | Beat 07 | Two-step synthesis puzzle (`Rewind`+`Freeze` on capacitor, then `Echo` on dual breakers); Operator intercom warning | `16 × 12`<br>(`448 × 224 px`) | Fixed `640×360` | • `door_entry_south` (S, `(8, 11)`)<br>• `door_exit_north` (N, `(8, 0)`) | `CH1-PZ-004` | **Yes**<br>`ch01.cp.signal_control` | • `ch01.signal_control.safe_anchor_center` @ `(8, 6)` `(352, 176)` |
| **7** | `ch01.upper_vestibule` | Beat 08 | Spatial foreshadow hub (`SpatialGraph` doorway reassignment via two junction relay levers + `Trace`) | `14 × 14`<br>(`448 × 224 px`) | Fixed `640×360` | • `door_south` (S, `(7, 13)`)<br>• `door_west` (W, `(0, 7)`)<br>• `door_east` (E, `(13, 7)`)<br>• `door_north` (N, `(7, 0)`) | `CH1-PZ-005` | **Yes**<br>`ch01.cp.upper_vestibule` | • `ch01.upper_vestibule.safe_anchor_center` @ `(7, 7)` `(320, 176)` |
| **8** | `ch01.vestibule_niche` | Beat 08 *(Sub-room)* | Side inspection alcove for `CH1-PZ-005` (`door_out` has physical iron grille, `traversable = false`) | `6 × 6`<br>(`192 × 96 px`) | Fixed `640×360` | • `door_in` (W, `(0, 3)`)<br>• `door_out` (N, `(3, 0)`, *grille*) | *(Part of `CH1-PZ-005`)* | No *(uses `ch01.cp.upper_vestibule`)* | • `ch01.vestibule_niche.safe_anchor_niche` @ `(3, 3)` `(320, 112)` *(relocates to `upper_vestibule.safe_anchor_center` on graph change)* |
| **9** | `ch01.station_atrium` | Beat 09 | Grand concourse under the `23:59` master clock; Central Dispatch Recorder **Major Revelation** | `16 × 14`<br>(`480 × 240 px`) | Fixed `640×360` | • `door_entry_south` (S, `(8, 13)`)<br>• `door_exit_north` (N, `(8, 0)`) | — | **Yes**<br>`ch01.cp.station_atrium` | • `ch01.station_atrium.safe_anchor_south` @ `(8, 11)` `(272, 216)` |
| **10** | `ch01.street_exit` | Beat 10 | Surface stairs overlook, street payphone call, **Cinematic Beat** & **Exit Hook into Chapter 2** | `12 × 10`<br>(`352 × 176 px`) | Fixed `640×360` *(scripted pan on outro)* | • `door_entry_south` (S, `(6, 9)`) | — | **Yes**<br>`ch01.cp.street_exit` | • `ch01.street_exit.safe_anchor_stairs` @ `(6, 8)` `(288, 176)` |

---

## 3. Complete Chapter 1 Doorway Graph (`ADR-009`)

### 3.1 Visual Room & Doorway Topology

```mermaid
flowchart TD
    R1["1. ch01.arrival_platform<br/>(Beat 01 · 14x10)"]
    R2["2. ch01.concourse_west<br/>(Beats 02-03 · CH1-PZ-001 · 16x12)"]
    R3["3. ch01.maintenance_bay<br/>(Beat 04 · CH1-PZ-002 · 14x10)"]
    R4["4. ch01.security_crossing<br/>(Beat 05 · CH1-PZ-003 · 16x12)"]
    R5["5. ch01.waiting_lounge<br/>(Beat 06 · Mira Trace · 12x10)"]
    R6["6. ch01.signal_control<br/>(Beat 07 · CH1-PZ-004 · 16x12)"]
    R7["7. ch01.upper_vestibule<br/>(Beat 08 · CH1-PZ-005 · 14x14)"]
    R8["8. ch01.vestibule_niche<br/>(Beat 08 Alcove · 6x6)"]
    R9["9. ch01.station_atrium<br/>(Beat 09 · Ledger 23:59 · 16x14)"]
    R10["10. ch01.street_exit<br/>(Beat 10 · Cinematic Outro · 12x10)"]

    R1 -- "door_exit_west <-> door_entry_east<br/>(Static E1)" --> R2
    R2 -- "door_exit_north <-> door_entry_west<br/>(Static E2 · Gated by PZ-001)" --> R3
    R3 -- "door_exit_east <-> door_entry_west<br/>(Static E3 · Gated by PZ-002)" --> R4
    R4 -- "door_exit_east <-> door_entry_south<br/>(Static E4 · Gated by PZ-003)" --> R5
    R5 -- "door_exit_north <-> door_entry_south<br/>(Static E5)" --> R6
    R6 -- "door_exit_north <-> door_south<br/>(Static E6 · Gated by PZ-004)" --> R7

    R7 -. "State 0: door_north <-> door_west (Loop)<br/>State 0: door_east <-> niche:door_in" .-> R8
    R8 -. "State 0/1: niche:door_out <-> door_entry_south<br/>(traversable = false · Iron Grille)" .-> R9
    R7 == "State 2 (Solved PZ-005):<br/>door_north <-> door_entry_south" ==> R9

    R9 -- "door_exit_north <-> door_entry_south<br/>(Static E7 · Gated by Beat 09 Terminal)" --> R10
```

### 3.2 Complete Doorway Pairing Table (20 Declared Doorways = 10 Undirected Pairs)

Every declared doorway across all 10 rooms is paired **exactly once** in every valid graph state (`State 0`, `State 1`, `State 2`):

| Edge ID | Kind | Endpoint A (`room_id:door_id`) | Endpoint B (`room_id:door_id`) | `traversable` | Gate / Condition |
|---|---|---|---|---|---|
| **E1** | Static | `ch01.arrival_platform:door_exit_west` | `ch01.concourse_west:door_entry_east` | `true` | Requires picking up `global.pocket_watch` in Beat 01. |
| **E2** | Static | `ch01.concourse_west:door_exit_north` | `ch01.maintenance_bay:door_entry_west` | `true` | Reachable after opening `turnstile_gate` (`CH1-PZ-001`) and answering `call_box_09` + inspecting `doc_evac_notice` (Beat 03). |
| **E3** | Static | `ch01.maintenance_bay:door_exit_east` | `ch01.security_crossing:door_entry_west` | `true` | Gated inside room by `fire_shutter` (`CH1-PZ-002`). |
| **E4** | Static | `ch01.security_crossing:door_exit_east` | `ch01.waiting_lounge:door_entry_south` | `true` | Gated inside room by `security_gate_01` + `bridge_platform_01` (`CH1-PZ-003`). |
| **E5** | Static | `ch01.waiting_lounge:door_exit_north` | `ch01.signal_control:door_entry_south` | `true` | Unlocked after inspecting Mira's `Trace` / audio log in Beat 06. |
| **E6** | Static | `ch01.signal_control:door_exit_north` | `ch01.upper_vestibule:door_south` | `true` | Gated by `vestibule_door` (`CH1-PZ-004`). Preserved as Edge 1 in `CH1-PZ-005` `SpatialGraph`. |
| **E7** | Static | `ch01.station_atrium:door_exit_north` | `ch01.street_exit:door_entry_south` | `true` | Gated by `dispatch_terminal` `Trace` interaction in Beat 09. |
| **D1–D3** | Dynamic (`CH1-PZ-005`) | **6 switchable doorways** across `ch01.upper_vestibule` (`door_north`, `door_west`, `door_east`), `ch01.vestibule_niche` (`door_in`, `door_out`), and `ch01.station_atrium` (`door_entry_south`) | **See `design/ch01/puzzles/CH1-PZ-005.md` §4.2** for exact State 0, State 1, and State 2 pairings (referenced without redefinition). | `true` for all except any edge landing on `ch01.vestibule_niche:door_out`, which has `traversable = false` (physical iron grille). | Controlled by `junction_lever_a` and `junction_lever_b` (`CH1-PZ-005`). |

---

## 4. Critical Path, Optional Routes & Backtracking Verification

### 4.1 Ordered Critical Path (`ch01.arrival_platform` → `ch01.street_exit`)

1. **`ch01.arrival_platform` (Beat 01):** Inspect stalled train/bench → pick up `global.pocket_watch` → exit via `door_exit_west` (`E1`).
2. **`ch01.concourse_west` (Beat 02 — `CH1-PZ-001`):** At East Turnstile threshold, use `Trace` on `turnstile_trace_anchor` and `Rewind` on `turnstile_gate` → cross `exit_trigger_concourse` (`CH1-PZ-001` = `SOLVED`, turnstile permanently latched open per `ADR-016`).
3. **`ch01.concourse_west` (Beat 03):** Answer `call_box_09` (The Operator) and read `doc_evac_notice` → exit via `door_exit_north` (`E2`).
4. **`ch01.maintenance_bay` (Beat 04 — `CH1-PZ-002`):** `Rewind` `fire_shutter` and `Freeze` `counterweight_gear` → walk under shutter into `exit_trigger_east` (`CH1-PZ-002` = `SOLVED`, shutter permanently latched open per `ADR-016`) → exit via `door_exit_east` (`E3`).
5. **`ch01.security_crossing` (Beat 05 — `CH1-PZ-003`):** Record `Echo` (`&"echo.0"`) stepping onto `pressure_switch_01`, stop while on switch, replay `Echo` to hold gate/bridge, walk across `bridge_platform_01` into `exit_trigger_lounge` (`CH1-PZ-003` = `SOLVED`, gate/bridge permanently locked open per `ADR-016`) → exit via `door_exit_east` (`E4`).
6. **`ch01.waiting_lounge` (Beat 06):** Use `Trace` on the bench window distortion and play `audio_mira_01` (logs memory fragment `ch01.fragment.mira_departure`) → exit via `door_exit_north` (`E5`).
7. **`ch01.signal_control` (Beat 07 — `CH1-PZ-004`):** Step 1: `Rewind` + `Freeze` `surge_capacitor` (`bus_powered = true`). Step 2: Record `Echo` pulling `breaker_a`, replay while pulling `breaker_b` within 180 ticks → unlocks `vestibule_door` → enter `exit_trigger_vestibule` (`CH1-PZ-004` = `SOLVED`, door permanently open per `ADR-016`) → exit via `door_exit_north` (`E6`).
8. **`ch01.upper_vestibule` (Beat 08 — `CH1-PZ-005`):** Use `Trace` on `route_board` → pull `junction_lever_a` (`State 0 → State 1`) → pull `junction_lever_b` (`State 1 → State 2`) → walk through `door_north` into `ch01.station_atrium:door_entry_south` (`CH1-PZ-005` = `SOLVED`, State 2 permanently locked per `ADR-016`).
9. **`ch01.station_atrium` (Beat 09):** Inspect `dispatch_terminal` and apply `Trace` to biometric seal (delivers Chapter 1's single major revelation + unlocks street blast doors) → exit via `door_exit_north` (`E7`).
10. **`ch01.street_exit` (Beat 10):** Ascend stairs across `trigger_outro` → street payphone (`plaza_payphone`) rings with The Operator's line + cinematic pullback to the frozen city at `23:59` → transition to Chapter 2.

### 4.2 Optional Routes & Discoveries
- **Maintenance Bay Clipboard (`Beat 04`):** `ch01.maintenance_bay.doc_tech_log` on the workbench `(3, 2)` in `ch01.maintenance_bay`.
- **Security Booth Pickup (`Beat 05`):** `ch01.security_crossing.transit_pass_pickup` (`progression = true`) on the side desk `(3, 2)` in `ch01.security_crossing`.
- **Vestibule Inspection Niche (`Beat 08`):** Entering `ch01.vestibule_niche` via `door_east` (in `State 0`) or `door_north` (in `State 1`) before completing `CH1-PZ-005` lets the player read the ELYSIUM threshold-indexing plaque (`ch01.vestibule_niche.doc_index_plaque`) and peer through the barred iron grille (`door_out`, `traversable = false`) into the Station Atrium.

### 4.3 Backtracking Verification (`ch01.station_atrium` → `ch01.arrival_platform`)
- **Zero One-Way Traps:** Every static edge `E1`–`E7` is bidirectional (`traversable = true`).
- **Paper Backtrack Check from `ch01.station_atrium` to `ch01.arrival_platform`:**
  1. From `ch01.station_atrium:door_entry_south`, walk south through `D3` (locked in `State 2` per `ADR-016`) into `ch01.upper_vestibule:door_north`.
  2. Walk south through `ch01.upper_vestibule:door_south` (`E6`) into `ch01.signal_control:door_exit_north` (`vestibule_door` remains permanently open after `CH1-PZ-004` `SOLVED`).
  3. Walk south through `ch01.signal_control:door_entry_south` (`E5`) into `ch01.waiting_lounge:door_exit_north`.
  4. Walk south through `ch01.waiting_lounge:door_entry_south` (`E4`) onto `ch01.security_crossing:door_exit_east` (`bridge_platform_01` and `security_gate_01` remain permanently open after `CH1-PZ-003` `SOLVED`).
  5. Walk west through `ch01.security_crossing:door_entry_west` (`E3`) into `ch01.maintenance_bay:door_exit_east` (`fire_shutter` remains permanently raised after `CH1-PZ-002` `SOLVED`).
  6. Walk west through `ch01.maintenance_bay:door_entry_west` (`E2`) into `ch01.concourse_west:door_exit_north` (`turnstile_gate` remains permanently open after `CH1-PZ-001` `SOLVED`).
  7. Walk east through `ch01.concourse_west:door_entry_east` (`E1`) back to `ch01.arrival_platform:door_exit_west`.
  - **Result:** Complete end-to-end backtracking is guaranteed with zero ability re-execution required.

---

## 5. Puzzle Placement Constraints & `ADR-015` 96 px Targeting Verification

Per `ADR-015`:
- Physical `interact` (`&"use"`) radius = **`36 px`**.
- Pocket-watch (`&"trace"`, `&"rewind"`, `&"freeze"`) radius = **`96 px`** (automatically prefers the nearest candidate inside `96 px` that supports the selected ability, falling back to the nearest overall so `&"unsupported"` remains teachable).

Below are the exact tile and pixel coordinates for every puzzle object and intended player standing spot, confirming **all supported targets sit well within `≤ 96 px`** and resolving any nearest-target ambiguity:

### 5.1 `CH1-PZ-001` — *The Fractured Turnstile* (`ch01.concourse_west`, `16 × 12`)

| Object / Spot | Tile `(x, y)` | Pixel `(px_x, px_y)` | Distance from Gate Spot `(3, 5)` `(288, 128)` | Distance from Pillar Spot `(8, 5)` `(368, 168)` | Targeting Behavior (`ADR-015`) |
|---|---|---|---|---|---|
| **Player Spot A (Gate Approach)** | `(3, 5)` | `(288, 128)` | `0.0 px` | `89.4 px` | Main tutorial spot in front of the turnstile. |
| `ch01.concourse_west.turnstile_trace_anchor` (`traceable`) | `(2.5, 5)` | `(280, 124)` | **`8.9 px`** (`≤ 96 px` ✅) | `98.4 px` (`> 96 px`) | From Spot A with `Trace` selected: sole `traceable` object in range (`8.9 px`). |
| `ch01.concourse_west.turnstile_gate` (`REWIND`) | `(2, 5)` | `(272, 120)` | **`17.9 px`** (`≤ 96 px` ✅, `≤ 36 px` ✅) | `107.3 px` (`> 96 px`) | From Spot A with `Rewind` selected: capability-preferred (`17.9 px`), even though `turnstile_trace_anchor` (`8.9 px`) is closer. |
| **Player Spot B (Pillar Side)** | `(8, 5)` | `(368, 168)` | `89.4 px` | `0.0 px` | Spot beside the structural column in the concourse. |
| `ch01.concourse_west.support_pillar_01` (`NONE`) | `(9, 5)` | `(384, 176)` | `107.3 px` (`> 96 px`) | **`17.9 px`** (`≤ 96 px` ✅) | Separated by `125.2 px` from `turnstile_gate` (`> 96 px`). From Spot B, `turnstile_gate` is outside the `96 px` radius (`107.3 px`), so testing `Rewind` at Spot B targets `support_pillar_01` (`17.9 px`) and teaches `&"unsupported"`. |
| `ch01.concourse_west.reset_anchor_01` (`&"reset"`) | `(3, 7)` | `(256, 144)` | **`35.8 px`** (`≤ 36 px` ✅) | `114.6 px` | Wall diagnostic box `2` tiles south of Spot A. |

### 5.2 `CH1-PZ-002` — *The Runaway Shutter* (`ch01.maintenance_bay`, `14 × 10`)

| Object / Spot | Tile `(x, y)` | Pixel `(px_x, px_y)` | Distance from Main Spot `(6, 4)` `(352, 144)` | Targeting & Disambiguation (`ADR-015`) |
|---|---|---|---|---|
| **Player Main Casting Spot** | `(6, 4)` | `(352, 144)` | `0.0 px` | Player can execute both `Rewind` and `Freeze` from this single tile without moving. |
| `ch01.maintenance_bay.fire_shutter` (`REWIND`) | `(8, 4)` | `(384, 160)` | **`35.8 px`** (`≤ 96 px` ✅, `≤ 36 px` ✅) | With `Rewind` selected at `(6, 4)`: auto-targets `fire_shutter` (only `REWIND` candidate). |
| `ch01.maintenance_bay.counterweight_gear` (`FREEZE`) | `(5, 1)` | `(384, 112)` | **`45.3 px`** (`≤ 96 px` ✅) | With `Freeze` selected at `(6, 4)`: auto-targets `counterweight_gear` (only `FREEZE` candidate), even though `fire_shutter` (`35.8 px`) is closer! |
| **North Wall Spot `(1, 0)`** *(for `unsupported` test on gear)* | `(1, 0)` | `(336, 72)` | — | Distance to `counterweight_gear` = **`62.5 px`** (`≤ 96 px` ✅); distance to `fire_shutter` = **`100.2 px`** (`> 96 px`). Using `Rewind` here targets `counterweight_gear` and teaches `&"unsupported"`. |
| **South Pipe Spot `(11, 8)`** *(for `unsupported` test on shutter)* | `(11, 8)` | `(368, 216)` | — | Distance to `fire_shutter` = **`58.2 px`** (`≤ 96 px` ✅); distance to `counterweight_gear` = **`105.2 px`** (`> 96 px`). Using `Freeze` here targets `fire_shutter` and teaches `&"unsupported"`. |
| `ch01.maintenance_bay.reset_anchor_01` (`&"reset"`) | `(4, 6)` | `(288, 144)` | `64.0 px` (`0 px` when approached at `(4, 5)`) | Pneumatic release valve on west wall. |

### 5.3 `CH1-PZ-003` — *The Delayed Platform* (`ch01.security_crossing`, `16 × 12`)

| Object / Spot | Tile `(x, y)` | Pixel `(px_x, px_y)` | Distance from Switch `(5, 9)` `(256, 176)` | Targeting & Disambiguation (`ADR-015`) |
|---|---|---|---|---|
| `ch01.security_crossing.echo_recorder_pedestal` | `(4, 8)` | `(256, 160)` | `16.0 px` (`≤ 36 px` ✅) | Adjacent to the south pressure switch deck. |
| `ch01.security_crossing.pressure_switch_01` (`Area2D`) | `(5, 9)` | `(256, 176)` | `0.0 px` (step-on plate) | `160.0 px` from `security_gate_01` (`1.33 s` / `80 ticks` walk at `120 px/s`). |
| `ch01.security_crossing.security_gate_01` (`NONE`) | `(10, 4)` | `(416, 176)` | `160.0 px` (`> 96 px`) | Standing at `(9, 4)` `(400, 168)` puts `security_gate_01` at **`17.9 px`** (`≤ 36 px` ✅, `≤ 96 px` ✅) for testing `&"locked"` / `&"unsupported"`. |
| `ch01.security_crossing.transit_pass_pickup` (`progression`) | `(3, 2)` | `(336, 104)` | `107.3 px` | Isolated on north-west security desk (`d = 17.9 px` from `(3, 3)`). |
| `ch01.security_crossing.reset_anchor_01` (`&"reset"`) | `(7, 6)` | `(336, 168)` | `80.4 px` | Central west-deck console (`d = 17.9 px` from `(6, 6)`). |

### 5.4 `CH1-PZ-004` — *The Synchronized Substation* (`ch01.signal_control`, `16 × 12`)

| Object / Spot | Tile `(x, y)` | Pixel `(px_x, px_y)` | Distance from Spot | Targeting & Disambiguation (`ADR-015`) |
|---|---|---|---|---|
| **Step 1 Standing Spot (Center Console)** | `(8, 6)` | `(352, 176)` | `0.0 px` | Directly in front of the central surge capacitor. |
| `ch01.signal_control.surge_capacitor` (`REWIND \| FREEZE`) | `(8, 5)` | `(368, 168)` | **`17.9 px`** from `(8, 6)` (`≤ 96 px` ✅) | Sole temporal object in `ch01.signal_control`; both `Rewind` and `Freeze` target it at `17.9 px`. |
| `ch01.signal_control.reset_anchor_01` (`&"reset"`) | `(9, 7)` | `(352, 192)` | **`16.0 px`** from `(8, 6)` (`≤ 36 px` ✅) | Master reset switch on south edge of center console (`surge_capacitor` is preferred for watch abilities; `reset_anchor_01` is closer by `1.9 px` for physical `&"use"` at `(9, 7)`). |
| **Step 2 West Spot (Breaker A)** | `(3, 8)` | `(240, 152)` | `0.0 px` | `134.2 px` (`> 96 px`) from `surge_capacitor`, so no cross-targeting. |
| `ch01.signal_control.breaker_a` (`&"use"`) | `(2, 8)` | `(224, 144)` | **`17.9 px`** from `(3, 8)` (`≤ 36 px` ✅) | West mezzanine breaker (`256 px` walk from `breaker_b` around central console = `~210 ticks` / `3.5 s`). |
| **Step 2 East Spot (Breaker B)** | `(13, 4)` | `(464, 200)` | `0.0 px` | `101.2 px` (`> 96 px`) from `surge_capacitor`. |
| `ch01.signal_control.breaker_b` (`&"use"`) | `(14, 4)` | `(480, 208)` | **`17.9 px`** from `(13, 4)` (`≤ 36 px` ✅) | East mezzanine breaker. |

### 5.5 `CH1-PZ-005` — *The Displaced Corridor* (`ch01.upper_vestibule`, `14 × 14`)

| Object / Spot | Tile `(x, y)` | Pixel `(px_x, px_y)` | Distance from Center `(7, 7)` `(320, 176)` | Targeting & Disambiguation (`ADR-015`) |
|---|---|---|---|---|
| **Center Hub Spot (`safe_anchor_center`)** | `(7, 7)` | `(320, 176)` | `0.0 px` | Central standing spot in front of the spatial index board. |
| `ch01.upper_vestibule.route_board` (`traceable`) | `(7, 6)` | `(336, 168)` | **`17.9 px`** (`≤ 96 px` ✅, `≤ 36 px` ✅) | Sole `traceable` object in the vestibule; `Trace` targets it from anywhere within `96 px` of center. |
| `ch01.upper_vestibule.junction_lever_a` (`&"use"`) | `(3, 7)` | `(256, 144)` | `71.6 px` (**`17.9 px`** from `(4, 7)` `≤ 36 px` ✅) | West Junction Relay Lever (`128 px` away from `junction_lever_b`, zero targeting overlap). |
| `ch01.upper_vestibule.junction_lever_b` (`&"use"`) | `(11, 7)` | `(384, 208)` | `71.6 px` (**`17.9 px`** from `(10, 7)` `≤ 36 px` ✅) | East Junction Relay Lever. |
| `ch01.upper_vestibule.reset_anchor_01` (`&"reset"`) | `(7, 10)` | `(272, 200)` | `53.7 px` (**`17.9 px`** from `(7, 9)` `≤ 36 px` ✅) | Spatial reset pedestal on the south-center approach. |

---

## 6. Checkpoints & Save Data Specification (`ADR-010`)

### 6.1 Checkpoint Trigger Placement

Every puzzle room entrance (plus chapter start and outro) has an auto-save checkpoint trigger (`Area2D`) placed `1` tile inside the entry doorway:

| `checkpoint_id` (`StringName`) | Room ID | Trigger Tile `(x, y)` | Spawn Anchor on Load (`object_id`) | Trigger Condition |
|---|---|---|---|---|
| `&"ch01.cp.arrival"` | `ch01.arrival_platform` | `(7, 5)` | `&"ch01.arrival_platform.safe_anchor_spawn"` | Initial chapter start (`tick = 0`) and on picking up `global.pocket_watch`. |
| `&"ch01.cp.concourse_west"` | `ch01.concourse_west` | `(1, 5)` | `&"ch01.concourse_west.safe_anchor_east"` | Entering `ch01.concourse_west` (`CH1-PZ-001` entrance) and again upon `CH1-PZ-001` `SOLVED`. |
| `&"ch01.cp.maintenance_bay"` | `ch01.maintenance_bay` | `(3, 5)` | `&"ch01.maintenance_bay.safe_anchor_west"` | Entering `ch01.maintenance_bay` (`CH1-PZ-002` entrance) and upon `CH1-PZ-002` `SOLVED`. |
| `&"ch01.cp.security_crossing"` | `ch01.security_crossing` | `(2, 6)` | `&"ch01.security_crossing.safe_anchor_west"` | Entering `ch01.security_crossing` (`CH1-PZ-003` entrance) and upon `CH1-PZ-003` `SOLVED`. |
| `&"ch01.cp.waiting_lounge"` | `ch01.waiting_lounge` | `(6, 8)` | `&"ch01.waiting_lounge.safe_anchor_center"` | Entering `ch01.waiting_lounge` and upon collecting `ch01.fragment.mira_departure`. |
| `&"ch01.cp.signal_control"` | `ch01.signal_control` | `(8, 10)` | `&"ch01.signal_control.safe_anchor_center"` | Entering `ch01.signal_control` (`CH1-PZ-004` entrance) and upon `CH1-PZ-004` `SOLVED`. |
| `&"ch01.cp.upper_vestibule"` | `ch01.upper_vestibule` | `(7, 12)` | `&"ch01.upper_vestibule.safe_anchor_center"` | Entering `ch01.upper_vestibule` (`CH1-PZ-005` entrance) and upon `CH1-PZ-005` `SOLVED`. |
| `&"ch01.cp.station_atrium"` | `ch01.station_atrium` | `(8, 12)` | `&"ch01.station_atrium.safe_anchor_south"` | Entering `ch01.station_atrium` and upon completing the Beat 09 `dispatch_terminal` revelation. |
| `&"ch01.cp.street_exit"` | `ch01.street_exit` | `(6, 8)` | `&"ch01.street_exit.safe_anchor_stairs"` | Entering `ch01.street_exit` prior to the Beat 10 outro transition. |

### 6.2 Captured Save Payload (`ADR-010`, `ADR-007` Am. 1 & 2, `ADR-016`)

Saves store **IDs and primitives only** (no node paths or live references):

```json
{
  "save_version": 1,
  "chapter": "ch01",
  "checkpoint_id": "ch01.cp.maintenance_bay",
  "puzzles": {
    "CH1-PZ-001": "SOLVED",
    "CH1-PZ-002": "UNSOLVED",
    "CH1-PZ-003": "UNSOLVED",
    "CH1-PZ-004": "UNSOLVED",
    "CH1-PZ-005": "UNSOLVED"
  },
  "narrative_flags": {
    "ch01.flag.watch_acquired": true,
    "ch01.flag.operator_call_01": true,
    "ch01.flag.mira_trace_seen": false,
    "ch01.flag.operator_substation_warn": false,
    "ch01.flag.ledger_2359_revealed": false
  },
  "fragments": [],
  "temporal": {
    "ch01.concourse_west.turnstile_gate": {
      "schema_version": 1,
      "state": {"arm_state": "open", "passage_blocked": false},
      "history_cursor": 0,
      "is_frozen": false
    }
  },
  "settings_ref": "user://settings.cfg"
}
```

---

## 7. Modular Station Art Kit (`TLF-010` Scoping)

To keep all 10 rooms producible within the vertical slice, ~85% of the environment visuals are built from **one shared Elysium-09 Modular Station Kit** (`32 × 16 px` isometric tileset + reusable props), with only **7 unique hero set-piece sprites**:

### 7.1 Shared Modular Tileset (`assets/environments/ch01/station_tileset.png`)
1. **Floor Tiles (`32 × 16 px`, 8 variants):**
   - `tile_platform_terrazzo_dark`, `tile_platform_terrazzo_cracked` (Rooms 1, 2, 5, 7, 8, 9)
   - `tile_tactile_warning_amber` (Platform/trench edges in Rooms 1, 4, 5)
   - `tile_industrial_grating`, `tile_concrete_service` (Rooms 3, 4, 6)
   - `tile_cable_conduit_off`, `tile_cable_conduit_on` (`[>>>]` chevron pattern for Rooms 3, 4, 6, 7)
   - `tile_stone_step_wet` (Rooms 9, 10)
2. **Wall & Structural Modules (`32 × 64 px` & `32 × 48 px`, 6 variants):**
   - `wall_tiled_subterranean_n`, `wall_tiled_subterranean_w`, `wall_corner_pillar` (all 10 rooms)
   - `wall_archway_frame_n`, `wall_archway_frame_w` (standard doorway frames reused for all 20 doorways, paired with dynamic transom glyph overlay `[◁]`, `[◇]`, `[▲]`, `[■]`)
   - `wall_railing_iron` (trench/mezzanine safety rails in Rooms 1, 4, 5, 6, 8)

### 7.2 Shared Reusable Props (`assets/props/ch01/`)
- **Station Furniture & Fixtures (reused across 6+ rooms):**
  - `prop_station_bench` (Rooms 1, 2, 5, 9)
  - `prop_digital_clock_2359` (wall/suspended `23:59` clock reused in Rooms 1, 2, 5, 7, 9, 10)
  - `prop_call_box_phone` (reused for `call_box_09` in Room 2, intercom in Room 6, and `plaza_payphone` in Room 10)
  - `prop_reset_console` (shared base sprite for `reset_anchor_01` in Rooms 2, 3, 4, 6, 7)
  - `prop_lever_switch` (shared lever sprite for `breaker_a`/`b` in Room 6 and `junction_lever_a`/`b` in Room 7, differentiated by diegetic badge icons)
  - `prop_document_clipboard` (shared pickup/inspect sprite for `doc_evac_notice`, `doc_tech_log`, `transit_pass_pickup`, `audio_mira_01`, `doc_index_plaque`)

### 7.3 Unique Hero Set-Pieces (Only 7 Custom Props Required)
1. **Stalled Transit Car Front (`Room 1`):** `prop_transit_car_stalled` (background edge piece on `ch01.arrival_platform`).
2. **Turnstile Gate (`Room 2`, `CH1-PZ-001`):** `prop_turnstile_gate` (2 states: `collapsed`, `open`).
3. **Fire Shutter & Counterweight Gear (`Room 3`, `CH1-PZ-002`):** `prop_fire_shutter` (`closed`, `raised`) + `prop_counterweight_gear` (`idle`, `slipping`, `frozen`).
4. **Pressure Switch, Security Gate & Bridge (`Room 4`, `CH1-PZ-003`):** `prop_pressure_switch`, `prop_security_gate`, `prop_bridge_platform`.
5. **Surge Capacitor Bank (`Room 6`, `CH1-PZ-004`):** `prop_surge_capacitor` (`discharged`, `charged`, `frozen`).
6. **Spatial Route Board (`Room 7`, `CH1-PZ-005`):** `prop_route_board` (displays `State 0`, `State 1`, `State 2` index lines).
7. **Central Dispatch Recorder & Master Clock (`Room 9`, Beat 09):** `prop_dispatch_terminal` beneath the scaled `23:59` Atrium clock.

---

## 8. Deltas (Non-Breaking Alignment Notes)

1. **Chapter-Level Doorways on Boundary Rooms (`ch01.signal_control` and `ch01.station_atrium`):**
   - `design/ch01/puzzles/CH1-PZ-005.md` §4.1 listed only the doorways participating in the local Beat 08 spatial puzzle subgraph (`ch01.signal_control:door_exit_north` and `ch01.station_atrium:door_entry_south`).
   - In the full Chapter 1 station graph (§2 & §3.2 above), `ch01.signal_control` also declares `door_entry_south` (paired with `ch01.waiting_lounge:door_exit_north` via static edge **E5**), and `ch01.station_atrium` also declares `door_exit_north` (paired with `ch01.street_exit:door_entry_south` via static edge **E7**). No edges or rules in `CH1-PZ-005.md` are altered.
2. **Room Count Footer in `CH01_BEAT_SHEET.md`:**
   - The summary row of `design/ch01/CH01_BEAT_SHEET.md` §1 read *"8 Interconnected Station Rooms"* while its rows listed 9 distinct room IDs; together with the accepted `ch01.vestibule_niche` alcove (`CH1-PZ-005`), the canonical Chapter 1 room count is **10 rooms** (§2 above).

---

## 9. Open Questions

**None blocking.** Every room footprint fits the fixed `640 × 360` viewport (`ADR-003`), all 20 doorways are paired 1-to-1 (`ADR-009`), and all puzzle targets satisfy the `96 px` watch radius and `36 px` interact radius (`ADR-015`).
