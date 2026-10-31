# CH01 Placement Sheet — art kit → rooms 1–10 (`TLF-039`)

**Author:** design-art agent (Claude Code, Sonnet 5.5, standing in for Argon) · **Audience:** Flash (integration task, `TLF-018`/follow-up) · **Inputs:** `design/ch01/ROOM_GRAPH.md` §1/§5/§7, `design/art/ART_BIBLE.md`, `design/art/ASSET_METADATA.md`, and the greybox `scenes/chapters/ch01/rooms/*.tscn` (read-only; every node position below is copied from those files by script, not typed).

**Scope of this sheet:** every kit piece and puzzle prop delivered by TLF-039 and TLF-042 is placed room by room (state mapping quotes the real `scripts/puzzle/objects/*.gd` fields, §11). *(decor)* marks optional dressing with no `.tscn` node yet. Layer/sorting rules follow ADR-019 (free-standing = `YSort_Actors` 10, wall-mounted = `Wall_Fixtures` 7).

Mockups (`640×360`, true scale, kit pieces only): `design/art/mockups/ch01_arrival_platform_mockup.png` (validation against the approved target sheet), `ch01_concourse_west_mockup.png`, `ch01_signal_control_mockup.png`.

---

## 0. Conventions (read once)

### 0.1 Coordinates
`px_x = 320 + (x - y) * 16`, `px_y = 64 + (x + y) * 8` (ROOM_GRAPH §1). A room `W × H` covers tiles `x ∈ [0, W-1]`, `y ∈ [0, H-1]`; **tile `(x, y)` has its top vertex at `px(x, y)` and its diamond centre at `px(x, y) + (0, 8)`**. All 10 rooms have even `W` and `H`.

### 0.2 Floor — `TileMapLayer_Floor` (`z_index = 0`)
- `tile_size = (32, 16)`, isometric, diamond-down. Set the layer `position = (320, 72)` so tile `(x, y)`'s centre lands on `px(x, y) + (0, 8)`. Each tile PNG is exactly one diamond; the pivot `(16, 8)` is the tile centre. The bevel/rim colours are authored to tile without seams (bible §5.1). Verify the offset in-engine against `design/art/mockups/ch01_arrival_platform_mockup.png`.
- Each room section lists the floor as: **base tile** + **override areas** + **cracked tiles** (deterministic rule `(x*5 + y*3) % 11 == 0`, skipping override tiles; rooms 3, 4, 6 use the concrete base and get **no** cracked tiles because only the terrazzo family has a cracked variant).

### 0.3 Wall modules (`YSort_Walls`, `z_index = 5`)
A wall module is `32 × 64`, pivot `(16, 56)`, and spans **two tile edges**. Only the back walls are drawn (N and W), as in the approved target sheet; the S and E boundaries stay open (doorways there are free-standing archway frames).
- **N wall** (`y = 0`), `wall_subterranean_n` (down-right slope): module `k = 0 .. W/2 - 1`, **pivot position = `(336 + 32k, 72 + 16k)`**.
- **W wall** (`x = 0`), `wall_subterranean_w` (down-left slope): module `j = 0 .. H/2 - 1`, **pivot position = `(304 - 32j, 72 + 16j)`**.
- Exact pivot lists per room are in each room section. Wall collision is **not** changed: keep `PerimeterWalls/CollisionPolygon2D`.

### 0.4 Doorways (`YSort_Walls`, `z_index = 6`)
- Sprite by wall slope: **W and E doorways → `archway_frame_e`** (down-left slope, batch 1, = §7.1 `wall_archway_frame_w`); **N and S doorways → `archway_frame_n`** (down-right slope, new, = §7.1 `wall_archway_frame_n`). See `ASSET_METADATA.md` §4.1.
- **Position = the doorway node's `position`** (the `Archway*` `Sprite2D`s already do this). On N/W walls the archway **overdraws** the wall modules underneath; do **not** delete the modules (the archway is opaque over its 32×64 footprint, so even/odd door tiles both work).
- The transom glyph (`[◁] [◇] [▲] [■]`) is a separate overlay owned by `DoorwayPresenter`; the frame ships with the neutral cyan glyph baked in.

### 0.5 Layers and Y-sort (ADR-019)
| Layer | `z_index` | Contents | Y-sort key |
|---|---|---|---|
| `TileMapLayer_Floor` | 0 | all `tile_*` | n/a |
| `YSort_Walls` | 5 | wall modules, `wall_corner_pillar` (6 for archways) | node `position.y` (= pivot) |
| `Wall_Fixtures` | 7 | **wall-mounted only**: clock, call box, PA horn, levers that stand at the foot of a drawn wall | node `position.y` |
| `YSort_Props` | 8 | railing, clipboard, pocket watch, pressure switch, bridge deck | node `position.y` |
| `YSort_Actors` | 10 | Elias and every **free-standing** object: bench, reset console, free-standing levers/breakers, route board, security gate, shutter, gear, capacitor, turnstile, dispatch terminal, transit car | node `position.y` (Elias draws behind them when he is north of them) |
Every sprite's pivot is its base-line contact point (footprint centre for large pieces, appendix A.3 of the bible), so Godot's default Y-sort (by node `position.y`) is correct without extra offsets.

### 0.6 Sprite placement rule
**Sprite pivot = the interactable node's `position`** (child `Sprite2D` at `(0,0)` with `offset = -pivot`, `centered = false`); this keeps every ADR-015 distance in ROOM_GRAPH §5 untouched. Exceptions are written out in the tables (`+ (0, 8)` for the free-standing pillar; wall mounts).
- **Wall mounts** (`mount` column): pivot = base midpoint of the named wall module (§0.3) `+ (0, -14)`; the node/trigger stays where the `.tscn` has it.
- **Wall clock:** pivot = base midpoint of the named N-wall module `+ (0, -38)` (metadata 2.8, `y_offset = -38`). The greybox `Clock` at `(320, 50)` floats above the room apex and should move to this position.

### 0.7 Flip rule
Axis-run pieces (`wall_railing_iron`, `prop_station_bench`, `tile_cable_conduit_*`) are authored along the down-right (`+x`) axis. Down-left (`+y`) axis → `flip_h`. Conduit direction: `+x` as authored, `+y` = `flip_h`, `-y` = `flip_v`, `-x` = `flip_h + flip_v`. Baked light flips with the sprite (same compromise as bible §2.3 #4).

### 0.8 Sprite index
| Sprite file | Size | Pivot | Layer / `z` |
|---|---|---|---|
| `ch01_env_tile_terrazzo_dark_idle` | 32×16 | (16,8) | floor 0 |
| `ch01_env_tile_terrazzo_cracked_idle` | 32×16 | (16,8) | floor 0 |
| `ch01_env_tile_tactile_amber_idle` | 32×16 | (16,8) | floor 0 |
| `ch01_env_tile_industrial_grating_idle` | 32×16 | (16,8) | floor 0 |
| `ch01_env_tile_concrete_service_idle` | 32×16 | (16,8) | floor 0 |
| `ch01_env_tile_cable_conduit_off_idle` | 32×16 | (16,8) | floor 0 |
| `ch01_env_tile_cable_conduit_on_idle` | 32×16 | (16,8) | floor 0 |
| `ch01_env_tile_stone_step_wet_idle` | 32×16 | (16,8) | floor 0 |
| `ch01_env_wall_subterranean_n_idle` | 32×64 | (16,56) | YSort_Walls 5 |
| `ch01_env_wall_subterranean_w_idle` | 32×64 | (16,56) | YSort_Walls 5 |
| `ch01_env_wall_corner_pillar_idle` | 32×64 | (16,56) | YSort_Walls 5 |
| `ch01_env_archway_frame_e_idle` | 32×64 | (16,56) | YSort_Walls 6 |
| `ch01_env_archway_frame_n_idle` | 32×64 | (16,56) | YSort_Walls 6 |
| `ch01_env_wall_railing_iron_idle` | 32×48 | (16,40) | YSort_Props 8 |
| `ch01_prop_digital_clock_2359_idle` | 32×24 | (16,20) | Wall_Fixtures 7 |
| `ch01_prop_call_box_phone_idle / _ringing` | 24×36 | (12,32) | Wall_Fixtures 7 |
| `ch01_prop_lever_switch_off / _on` | 24×32 | (12,28) | 10 free-standing / 7 wall-mounted (per object, ADR-019) |
| `ch01_prop_document_clipboard_idle` | 16×16 | (8,12) | YSort_Props 8 |
| `ch01_prop_reset_console_idle` | 32×36 | (16,30) | YSort_Actors 10 |
| `ch01_prop_station_bench_idle` | 48×32 | (24,26) | YSort_Actors 10 |
| `ch01_char_elias_base_sheet` | 2560×48 (80 × 32×48) | (16,44) | YSort_Actors 10 |
| `ch01_prop_turnstile_gate_collapsed / _open` | 32×40 | (16,34) | YSort_Actors 10 |
| `ch01_prop_fire_shutter_closed / _raised` | 64×64 | (32,56) | YSort_Actors 10 |
| `ch01_prop_counterweight_gear_idle / _slipping / _frozen` | 64×64 | (32,56) | YSort_Actors 10 |
| `ch01_prop_surge_capacitor_discharged / _charged / _frozen` | 64×64 | (32,56) | YSort_Actors 10 |
| `ch01_prop_pressure_switch_released / _pressed` | 32×20 | (16,12) | YSort_Props 8 |
| `ch01_prop_route_board_state0 / _state1 / _state2` | 48×56 | (24,50) | YSort_Actors 10 |
| `ch01_prop_security_gate_closed / _open` | 40×52 | (20,42) | YSort_Actors 10 |
| `ch01_prop_bridge_platform_retracted / _extended` | 48×32 | (24,18) | YSort_Props 8 |
| `ch01_prop_transit_car_stalled_idle` | 128×80 | (64,52) | YSort_Actors 10 |
| `ch01_prop_dispatch_terminal_idle / _active` | 64×64 | (32,56) | YSort_Actors 10 |
| `ch01_prop_pocket_watch_idle` | 16×16 | (8,12) | YSort_Props 8 |
| `ch01_prop_lever_badge_a_idle / _b_idle` | 5×7 | (2,3) | child of the lever (same z) |
| `ch01_prop_pa_speaker_idle` | 16×16 | (8,12) | Wall_Fixtures 7 |

### 0.9 Greybox nodes that are replaced everywhere
| Greybox node (all rooms) | Replaced by |
|---|---|
| `Floor`, `FloorAccent` (`Polygon2D`, `z_index = -1`) | `TileMapLayer_Floor` (section per room). Delete both polygons after the layer is in. |
| `PerimeterWalls` (`StaticBody2D`) | **Kept** (collision only); wall modules are visual only. |
| `Clock` (`Sprite2D`, `(320,50)`) | same texture, **reposition** per §0.6 (room sections list the module). |
| `Archway*` (`Sprite2D`, rooms 1–4) | keep node, set texture by slope (§0.4); N/S doors in other rooms get a **new** `Sprite2D`. |

### 0.10 Lever badges A / B (overlay, not variants)
`ch01_prop_lever_badge_a_idle.png` / `_b_idle.png` are 5×7 overlays (gold glyph on a dark plate), pivot `(2, 3)`. Add each as a **child `Sprite2D` of the lever** at offset `(3, -8)` from the lever pivot, same `z_index`: `A` on `breaker_a` and `junction_lever_a`, `B` on `breaker_b` and `junction_lever_b`. Chosen over `prop_lever_switch_{a,b}_{off,on}` because it adds 2 files instead of 4 lever variants, never multiplies with the on/off state, and the same overlay can label future switches. The badge does not change with the lever state.

---

## Room 1 — `ch01.arrival_platform` (14 × 10)

Footprint 14×10 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/arrival_platform.tscn`.

### 1.1 Floor
- **Base:** `ch01_env_tile_terrazzo_dark_idle.png` on every tile not listed below.
- **Platform edge, SW trench side (`y = 9`):** tiles (0,9), (1,9), (2,9), (3,9), (4,9), (5,9), (6,9), (7,9), (8,9), (9,9), (10,9), (11,9), (12,9), (13,9) → `ch01_env_tile_tactile_amber_idle.png`.
- **Platform edge, SE side (`x = 13`, door tile `(13,5)` excluded):** tiles (13,0), (13,1), (13,2), (13,3), (13,4), (13,6), (13,7), (13,8) → `ch01_env_tile_tactile_amber_idle.png`.
- **Cracked:** `ch01_env_tile_terrazzo_cracked_idle.png` on (0,0), (11,0), (6,1), (1,2), (12,2), (7,3), (2,4), (8,5), (3,6), (9,7), (4,8).

### 1.2 Walls
- **N wall:** 7 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)` `(432,120)` `(464,136)` `(496,152)` `(528,168)`
- **W wall:** 5 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)` `(208,120)` `(176,136)`
- **Clock(s):** `ch01_prop_digital_clock_2359_idle.png` on N-wall module(s) `k = 2` -> pivot `(400, 66)`, `k = 5` -> pivot `(496, 114)` (the greybox `Clock` / `digital_clock_2359` pair moves there).

### 1.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_exit_east` | E | `(448, 208)` ((13, 5)) | `ch01_env_archway_frame_e_idle.png` | free-standing frame (no wall on this edge) |

### 1.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.arrival_platform.(decor) platform bench` | `ch01_prop_station_bench_idle.png` | idle | `(352, 120)` ((4.5, 2.5)) | YSort_Actors / 10 | none (new) | ROOM_GRAPH/target sheet: bench at tile `(4,2)` (cell centre); no greybox node, add `StaticBody2D` footprint 40×12 |
| `ch01.arrival_platform.global.pocket_watch (`pocket_watch_pickup`)` | `ch01_prop_pocket_watch_idle.png` | present -> hidden on pickup | `(368, 168)` ((8, 5)) | YSort_Props / 8 | none | 16x16 micro pickup; node position = pivot (bible 1.3 micro prop) |
| `ch01.arrival_platform.(set-piece) stalled Mag-Transit car` | `ch01_prop_transit_car_stalled_idle.png` | idle (static) | `(251, 210)` ((7.0, 11.3)) | YSort_Actors / 10 | none (new) | tile-space centre `(7, 10.65)`: body in the SW trench just beyond the amber lip (`y = 10 .. 11.3`), long axis along `+x`; **pivot = footprint centre**, not (W/2,H-8) (appendix A.3). No node/collision (set dressing; add a `StaticBody2D` only if the lip is ever walkable) |

**Other greybox nodes:** Near edges (S, E) carry the amber lip and no wall, as in the approved target sheet. The stalled car (Tier 2) sits on the SW trench side.

## Room 2 — `ch01.concourse_west` (16 × 12)

Footprint 16×12 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/concourse_west.tscn`.

### 2.1 Floor
- **Base:** `ch01_env_tile_terrazzo_dark_idle.png` on every tile not listed below.
- **Turnstile approach lane (amber cue):** tiles (3,4), (3,5), (3,6) → `ch01_env_tile_tactile_amber_idle.png`.
- **Cracked:** `ch01_env_tile_terrazzo_cracked_idle.png` on (0,0), (11,0), (6,1), (1,2), (12,2), (7,3), (2,4), (13,4), (8,5), (14,6), (9,7), (4,8), (15,8), (10,9), (5,10), (0,11), (11,11).

### 2.2 Walls
- **N wall:** 8 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)` `(432,120)` `(464,136)` `(496,152)` `(528,168)` `(560,184)`
- **W wall:** 6 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)` `(208,120)` `(176,136)` `(144,152)`
- **Clock(s):** `ch01_prop_digital_clock_2359_idle.png` on N-wall module(s) `k = 3` -> pivot `(432, 82)` (the greybox `Clock` / `digital_clock_2359` pair moves there).

### 2.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_entry_west` | W | `(240, 104)` ((0, 5)) | `ch01_env_archway_frame_e_idle.png` | overdraws wall modules |
| `door_exit_east` | E | `(480, 224)` ((15, 5)) | `ch01_env_archway_frame_e_idle.png` | free-standing frame (no wall on this edge) |

### 2.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.concourse_west.turnstile_gate` | `ch01_prop_turnstile_gate_collapsed.png` / `ch01_prop_turnstile_gate_open.png` | collapsed / open | `(272, 120)` ((2, 5)) | YSort_Actors / 10 | none | `prop_turnstile_gate` (Tier 2, delivered); pedestal footprint centred on the node; Area2D + `Blocker` stay |
| `ch01.concourse_west.support_pillar_01` | `ch01_env_wall_corner_pillar_idle.png` | idle | `(384, 184)` (node `(384, 176)` + `(0, 8)`) | YSort_Walls / 5 | none (collision already in `PillarCollision`) | free-standing column; **sprite pivot = node position + (0, 8)** so the 0.75-tile footprint centres on the cell |
| `ch01.concourse_west.reset_anchor_01` | `ch01_prop_reset_console_idle.png` | idle | `(256, 144)` ((3, 7)) | YSort_Actors / 10 | none | sole state; the `[E]` prompt provides feedback |
| `ch01.concourse_west.call_box_09` | `ch01_prop_call_box_phone_idle.png` (+ `_ringing`) | idle -> ringing during Beat 03 call | `(272, 74)` (mount; node stays `(272, 96)`) | Wall_Fixtures / 7 | none | wall fixture on the W wall: module `j = 1` (y 2..3), mount offset (0, -14) |
| `ch01.concourse_west.doc_evac_notice` | `ch01_prop_document_clipboard_idle.png` | idle (hide when read, per interactable) | `(352, 176)` ((8, 6)) | YSort_Props / 8 | none |  |
| `ch01.concourse_west.(decor) concourse bench` | `ch01_prop_station_bench_idle.png` | idle | `(448, 184)` ((11.5, 3.5)) | YSort_Actors / 10 | none (new) | tile `(11,3)` cell centre; optional dressing |

**Other greybox nodes:** Greybox `TurnstileDividers/DividerNorth|DividerSouth` stay as collision. `exit_trigger_concourse`, `turnstile_footprint`, `turnstile_trace_anchor` are invisible triggers.

## Room 3 — `ch01.maintenance_bay` (14 × 10)

Footprint 14×10 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/maintenance_bay.tscn`.

### 3.1 Floor
- **Base:** `ch01_env_tile_concrete_service_idle.png` on every tile not listed below.
- **Shutter drain lane:** tiles (7,0), (8,0), (9,0), (7,1), (8,1), (9,1), (7,2), (8,2), (9,2), (7,3), (8,3), (9,3), (7,4), (8,4), (9,4), (7,5), (8,5), (9,5), (7,6), (8,6), (9,6), (7,7), (8,7), (9,7), (7,8), (8,8), (9,8), (7,9), (8,9), (9,9) → `ch01_env_tile_industrial_grating_idle.png`.
- **Power feed to the shutter (`+x` run; **off** until `CH1-PZ-002` SOLVED, then **on**):** tiles (2,4), (3,4), (4,4), (5,4), (6,4) → `ch01_env_tile_cable_conduit_off_idle.png` (`+x` run; swap to `ch01_env_tile_cable_conduit_on_idle.png` when powered).

### 3.2 Walls
- **N wall:** 7 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)` `(432,120)` `(464,136)` `(496,152)` `(528,168)`
- **W wall:** 5 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)` `(208,120)` `(176,136)`

### 3.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_entry_west` | W | `(240, 104)` ((0, 5)) | `ch01_env_archway_frame_e_idle.png` | overdraws wall modules |
| `door_exit_east` | E | `(464, 200)` ((13, 4)) | `ch01_env_archway_frame_e_idle.png` | free-standing frame (no wall on this edge) |

### 3.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.maintenance_bay.fire_shutter` | `ch01_prop_fire_shutter_closed.png` / `ch01_prop_fire_shutter_raised.png` | closed / raised | `(384, 160)` ((8, 4)) | YSort_Actors / 10 | none | Tier 2 `prop_fire_shutter` (64×64) |
| `ch01.maintenance_bay.counterweight_gear` | `ch01_prop_counterweight_gear_idle.png` / `ch01_prop_counterweight_gear_slipping.png` / `ch01_prop_counterweight_gear_frozen.png` | idle / slipping / frozen | `(384, 112)` ((5, 1)) | YSort_Actors / 10 | none | Tier 2 `prop_counterweight_gear` |
| `ch01.maintenance_bay.reset_anchor_01` | `ch01_prop_reset_console_idle.png` | idle | `(288, 144)` ((4, 6)) | YSort_Actors / 10 | none |  |
| `ch01.maintenance_bay.doc_tech_log` | `ch01_prop_document_clipboard_idle.png` | idle | `(288, 192)` ((7, 9)) | YSort_Props / 8 | none | workbench pickup |

**Other greybox nodes:** `ShutterDividers/DividerNorth|DividerSouth` stay as collision. `shutter_threshold_trigger`, `exit_trigger_east` are invisible.

## Room 4 — `ch01.security_crossing` (16 × 12)

Footprint 16×12 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/security_crossing.tscn`.

### 4.1 Floor
- **Base:** `ch01_env_tile_concrete_service_idle.png` on every tile not listed below.
- **Trench (void, **no tile**; black `#0A0D14` backing):** tiles (9,0), (9,1), (9,2), (9,3), (9,4), (9,5), (9,6), (9,7), (9,8), (9,9), (9,10), (9,11) → **no tile** (leave empty; keep `TrenchVisual` as the black backing).
- **Trench edge, west lip (`x = 8`, bridge rows `y = 6..7` excluded):** tiles (8,0), (8,1), (8,2), (8,3), (8,4), (8,5), (8,8), (8,9), (8,10), (8,11) → `ch01_env_tile_tactile_amber_idle.png`.
- **Trench edge, east lip (`x = 10`, bridge rows `y = 6..7` excluded):** tiles (10,0), (10,1), (10,2), (10,3), (10,4), (10,5), (10,8), (10,9), (10,10), (10,11) → `ch01_env_tile_tactile_amber_idle.png`.
- **Echo-recorder deck:** tiles (4,8), (5,8), (6,8), (4,9), (5,9), (6,9), (4,10), (5,10), (6,10) → `ch01_env_tile_industrial_grating_idle.png`.
- **Pressure-switch power feed (**off**; **on** while `pressure_switch_01` is held / PZ-003 latched):** tiles (6,9), (7,9), (8,9) → `ch01_env_tile_cable_conduit_off_idle.png` (`+x` run; swap to `ch01_env_tile_cable_conduit_on_idle.png` when powered).

### 4.2 Walls
- **N wall:** 8 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)` `(432,120)` `(464,136)` `(496,152)` `(528,168)` `(560,184)`
- **W wall:** 6 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)` `(208,120)` `(176,136)` `(144,152)`
- **Railings** (`ch01_env_wall_railing_iron_idle.png`, `YSort_Props` 8; `flip_h` for `y`-axis runs): `flipped (448,144)` `flipped (416,160)` `flipped (384,176)` `flipped (320,208)` `flipped (288,224)` `flipped (464,152)` `flipped (432,168)` `flipped (400,184)` `flipped (336,216)` `flipped (304,232)`

### 4.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_entry_west` | W | `(224, 112)` ((0, 6)) | `ch01_env_archway_frame_e_idle.png` | overdraws wall modules |
| `door_exit_east` | E | `(464, 232)` ((15, 6)) | `ch01_env_archway_frame_e_idle.png` | free-standing frame (no wall on this edge) |

### 4.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.security_crossing.pressure_switch_01` | `ch01_prop_pressure_switch_released.png` / `ch01_prop_pressure_switch_pressed.png` | released / pressed | `(256, 176)` ((5, 9)) | YSort_Props / 8 | none | Tier 2 `prop_pressure_switch` |
| `ch01.security_crossing.security_gate_01` | `ch01_prop_security_gate_closed.png` / `ch01_prop_security_gate_open.png` | `gate_state` &"closed" -> `ch01_prop_security_gate_closed`; &"open" -> `_open` (`passage_blocked` mirrors it) | `(416, 176)` ((10, 4)) | YSort_Actors / 10 | none | barrier spans the lane along the `y` axis (the lane runs `+x`); pivot = node position |
| `ch01.security_crossing.bridge_platform_01` | `ch01_prop_bridge_platform_retracted.png` / `ch01_prop_bridge_platform_extended.png` | `platform_state` &"retracted" -> `_retracted`; &"extended" -> `_extended` (`walkable` mirrors it) | `(368, 192)` (node `(368, 184)` + `(0, 8)`) | YSort_Props / 8 | `TrenchVisual` stays as the void backing | spans the trench tile `(9,6)` along `+x` (deck 2 tiles long, 1 wide); pivot = node + (0, 8) = cell centre; `TrenchVisual` stays as the void backing; Elias (z 10) draws above the deck (z 8) |
| `ch01.security_crossing.transit_pass_pickup` | `ch01_prop_document_clipboard_idle.png` | idle | `(336, 104)` ((3, 2)) | YSort_Props / 8 | none | security desk pickup (progression) |
| `ch01.security_crossing.reset_anchor_01` | `ch01_prop_reset_console_idle.png` | idle | `(336, 168)` ((7, 6)) | YSort_Actors / 10 | none |  |
| `ch01.security_crossing.pa_speaker` | `ch01_prop_pa_speaker_idle.png` | idle (audio emitter only) | `(336, 38)` (mount; node stays `(320, 60)`) | Wall_Fixtures / 7 | none | wall horn on N-wall module `k = 0`, offset (0, -34); the node at `(320,60)` stays |

**Other greybox nodes:** `TrenchVisual` (`Polygon2D`, tiles x=9) is **kept** as the void backing under the empty trench tile; `TrenchBarriers/*` stay as collision. ROOM_GRAPH §5.3 lists `echo_recorder_pedestal` at `(4,8)`, but the greybox scene has no such node (OQ-8).

## Room 5 — `ch01.waiting_lounge` (12 × 10)

Footprint 12×10 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/waiting_lounge.tscn`.

### 5.1 Floor
- **Base:** `ch01_env_tile_terrazzo_dark_idle.png` on every tile not listed below.
- **Platform-window edge (`y = 9`):** tiles (0,9), (1,9), (2,9), (3,9), (4,9), (5,9), (6,9), (7,9), (8,9), (9,9), (10,9), (11,9) → `ch01_env_tile_tactile_amber_idle.png`.
- **Cracked:** `ch01_env_tile_terrazzo_cracked_idle.png` on (0,0), (11,0), (6,1), (1,2), (7,3), (2,4), (8,5), (3,6), (9,7), (4,8).

### 5.2 Walls
- **N wall:** 6 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)` `(432,120)` `(464,136)` `(496,152)`
- **W wall:** 5 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)` `(208,120)` `(176,136)`
- **Clock(s):** `ch01_prop_digital_clock_2359_idle.png` on N-wall module(s) `k = 2` -> pivot `(400, 66)` (the greybox `Clock` / `digital_clock_2359` pair moves there).

### 5.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_entry_west` | W | `(240, 104)` ((0, 5)) | `ch01_env_archway_frame_e_idle.png` | overdraws wall modules |
| `door_exit_north` | N | `(416, 112)` ((6, 0)) | `ch01_env_archway_frame_n_idle.png` | overdraws wall modules |

### 5.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.waiting_lounge.trace_bench` | `ch01_prop_station_bench_idle.png` | idle | `(304, 144)` ((4.5, 5.5)) | YSort_Actors / 10 | none | Mira `Trace` anchor bench; collision/`Interactable` unchanged |
| `ch01.waiting_lounge.audio_mira_01` | `ch01_prop_document_clipboard_idle.png` | idle | `(352, 144)` ((6, 4)) | YSort_Props / 8 | none | audio-log pickup |

**Other greybox nodes:** `checkpoint` and `safe_anchor_center` are invisible.

## Room 6 — `ch01.signal_control` (16 × 12)

Footprint 16×12 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/signal_control.tscn`.

### 6.1 Floor
- **Base:** `ch01_env_tile_concrete_service_idle.png` on every tile not listed below.
- **Capacitor island:** tiles (6,4), (7,4), (8,4), (9,4), (10,4), (6,5), (7,5), (8,5), (9,5), (10,5), (6,6), (7,6), (8,6), (9,6), (10,6), (6,7), (7,7), (8,7), (9,7), (10,7) → `ch01_env_tile_industrial_grating_idle.png`.
- **Bus feed east of the island (`+x` run; **off** until `bus_powered = true`):** tiles (11,6), (12,6), (13,6), (14,6) → `ch01_env_tile_cable_conduit_off_idle.png` (`+x` run; swap to `ch01_env_tile_cable_conduit_on_idle.png` when powered).

### 6.2 Walls
- **N wall:** 8 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)` `(432,120)` `(464,136)` `(496,152)` `(528,168)` `(560,184)`
- **W wall:** 6 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)` `(208,120)` `(176,136)` `(144,152)`
- **Clock(s):** `ch01_prop_digital_clock_2359_idle.png` on N-wall module(s) `k = 1` -> pivot `(368, 50)` (the greybox `Clock` / `digital_clock_2359` pair moves there).
- **Railings** (`ch01_env_wall_railing_iron_idle.png`, `YSort_Props` 8; `flip_h` for `y`-axis runs): `(208,136)` `(240,152)` `(272,168)` `(304,184)` `(336,200)` `(368,216)` `(336,120)` `(368,136)` `(400,152)` `(432,168)` `(464,184)` `(496,200)` `(512,208)`

### 6.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_entry_south` | S | `(272, 216)` ((8, 11)) | `ch01_env_archway_frame_n_idle.png` | free-standing frame (no wall on this edge) |
| `door_exit_north` | N | `(448, 128)` ((8, 0)) | `ch01_env_archway_frame_n_idle.png` | overdraws wall modules |

### 6.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.signal_control.surge_capacitor` | `ch01_prop_surge_capacitor_discharged.png` / `ch01_prop_surge_capacitor_charged.png` / `ch01_prop_surge_capacitor_frozen.png` | discharged / charged / frozen | `(368, 168)` ((8, 5)) | YSort_Actors / 10 | none | Tier 2 `prop_surge_capacitor` (64×64) |
| `ch01.signal_control.breaker_a` | `ch01_prop_lever_switch_off.png` (+ `_on`) | `lever_state` `&"open"` -> `_off`; `&"engaged"` -> `_on` (auto-releases after 180 ticks) | `(160, 144)` ((0, 10)) | Wall_Fixtures / 7 | none | stands at the foot of the W wall (`x = 0`): **wall-mounted, `Wall_Fixtures` 7**; badge A child at (3, -8) |
| `ch01.signal_control.breaker_b` | `ch01_prop_lever_switch_off.png` (+ `_on`) | `lever_state` `&"open"` -> `_off`; `&"engaged"` -> `_on` | `(544, 192)` ((15, 1)) | YSort_Actors / 10 | none | free-standing at the E edge (`x = 15`, no wall drawn): **`YSort_Actors` 10** (ADR-019); badge B child at (3, -8) |
| `ch01.signal_control.intercom` | `ch01_prop_call_box_phone_idle.png` | idle | `(528, 154)` (mount; node stays `(352, 160)`) | Wall_Fixtures / 7 | none | Operator intercom (shares `prop_call_box_phone`); node sits at the capacitor lane, so the sprite mounts on the N wall, module `k = 6`, offset (0, -14) (OQ-4) |
| `ch01.signal_control.reset_anchor_01` | `ch01_prop_reset_console_idle.png` | idle | `(352, 192)` ((9, 7)) | YSort_Actors / 10 | none |  |
| `ch01.signal_control.vestibule_door (`door_exit_north`)` | `ch01_env_archway_frame_n_idle.png` | locked / open -> `[■]` / `[▲]` transom glyph | `(448, 128)` ((8, 0)) | YSort_Walls / 6 | `Archway` n/a (greybox has none) | archway is the visual of the door; keep `Blocker` collision |

**Other greybox nodes:** `SouthRailingVisual`, `NorthRailingVisual` (`Line2D`) → railing modules above; `NorthBarrierVisual` (`Polygon2D`, tiles x 10..14, y 5..) → keep until a barrier sprite exists; `substation_grid` has no position/visual.

## Room 7 — `ch01.upper_vestibule` (14 × 14)

Footprint 14×14 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/upper_vestibule.tscn`.

### 7.1 Floor
- **Base:** `ch01_env_tile_terrazzo_dark_idle.png` on every tile not listed below.
- **Lever A feed (`+x`; **on** once `junction_lever_a` pulled):** tiles (4,7), (5,7), (6,7) → `ch01_env_tile_cable_conduit_off_idle.png` (`+x` run; swap to `ch01_env_tile_cable_conduit_on_idle.png` when powered).
- **Lever B feed (**on** once `junction_lever_b` pulled; `-x` = flip_h + flip_v):** tiles (8,7), (9,7), (10,7) → `ch01_env_tile_cable_conduit_off_idle.png` (`+x` run; swap to `ch01_env_tile_cable_conduit_on_idle.png` when powered).
- **Cracked:** `ch01_env_tile_terrazzo_cracked_idle.png` on (0,0), (11,0), (6,1), (1,2), (12,2), (7,3), (2,4), (13,4), (8,5), (3,6), (4,8), (10,9), (5,10), (0,11), (11,11), (6,12), (1,13), (12,13).

### 7.2 Walls
- **N wall:** 7 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)` `(432,120)` `(464,136)` `(496,152)` `(528,168)`
- **W wall:** 7 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)` `(208,120)` `(176,136)` `(144,152)` `(112,168)`
- **Clock(s):** `ch01_prop_digital_clock_2359_idle.png` on N-wall module(s) `k = 3` -> pivot `(432, 82)` (the greybox `Clock` / `digital_clock_2359` pair moves there).

### 7.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_south` | S | `(224, 224)` ((7, 13)) | `ch01_env_archway_frame_n_idle.png` | free-standing frame (no wall on this edge) |
| `door_west` | W | `(208, 120)` ((0, 7)) | `ch01_env_archway_frame_e_idle.png` | overdraws wall modules |
| `door_east` | E | `(416, 224)` ((13, 7)) | `ch01_env_archway_frame_e_idle.png` | free-standing frame (no wall on this edge) |
| `door_north` | N | `(432, 120)` ((7, 0)) | `ch01_env_archway_frame_n_idle.png` | overdraws wall modules |

### 7.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.upper_vestibule.route_board` | `ch01_prop_route_board_state0.png` / `ch01_prop_route_board_state1.png` / `ch01_prop_route_board_state2.png` | derived from the two levers' `relay_state`: A `&"loop"` + B `&"niche"` -> `_state0`; A `&"uncoupled"` + B `&"niche"` -> `_state1`; A `&"uncoupled"` + B `&"atrium"` -> `_state2` | `(336, 168)` ((7, 6)) | YSort_Actors / 10 | none | `route_board` is a plain `Interactable` (no state of its own); free-standing, board faces SW |
| `ch01.upper_vestibule.junction_lever_a` | `ch01_prop_lever_switch_off.png` (+ `_on`) | `relay_state` `&"loop"` (= `state_a`) -> `_off`; `&"uncoupled"` (= `state_b`) -> `_on` | `(256, 144)` ((3, 7)) | YSort_Actors / 10 | none | free-standing: **`YSort_Actors` 10** (ADR-019); badge A child at (3, -8) |
| `ch01.upper_vestibule.junction_lever_b` | `ch01_prop_lever_switch_off.png` (+ `_on`) | `relay_state` `&"niche"` (= `state_a`) -> `_off`; `&"atrium"` (= `state_b`) -> `_on` | `(384, 208)` ((11, 7)) | YSort_Actors / 10 | none | free-standing: **`YSort_Actors` 10**; badge B child at (3, -8) |
| `ch01.upper_vestibule.reset_anchor_01` | `ch01_prop_reset_console_idle.png` | idle | `(272, 200)` ((7, 10)) | YSort_Actors / 10 | none | spatial reset pedestal |

**Other greybox nodes:** `spatial_resetter` has no position/visual. Door sprites follow the **declared** door side (`door_south`/`door_north` → `archway_frame_n`; `door_west`/`door_east` → `archway_frame_e`) regardless of the dynamic graph state.

## Room 8 — `ch01.vestibule_niche` (6 × 6)

Footprint 6×6 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/vestibule_niche.tscn`.

### 8.1 Floor
- **Base:** `ch01_env_tile_terrazzo_dark_idle.png` on every tile not listed below.

### 8.2 Walls
- **N wall:** 3 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)`
- **W wall:** 3 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)`

### 8.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_in` | W | `(272, 88)` ((0, 3)) | `ch01_env_archway_frame_e_idle.png` | overdraws wall modules |
| `door_out` | N | `(368, 88)` ((3, 0)) | `ch01_env_archway_frame_n_idle.png` | overdraws wall modules; iron grille overlay, see props |

### 8.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.vestibule_niche.door_out grille` | `ch01_env_wall_railing_iron_idle.png` | idle | `(368, 88)` ((3, 0)) | YSort_Props (overlay, above archway) / 9 | none | iron grille = `wall_railing_iron` laid over `archway_frame_n` (`traversable = false`); keep `GrilleBlocker` |
| `ch01.vestibule_niche.doc_index_plaque` | `ch01_prop_document_clipboard_idle.png` | idle | `(336, 104)` ((3, 2)) | YSort_Props / 8 | none | ELYSIUM indexing plaque pickup |

**Other greybox nodes:** `GrilleBlocker` stays. The grille = `archway_frame_n` + one `wall_railing_iron` module (flipped `y`-axis not needed, `x`-axis as authored) at the same pivot with `z_index = 9`.

## Room 9 — `ch01.station_atrium` (16 × 14)

Footprint 16×14 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/station_atrium.tscn`.

### 9.1 Floor
- **Base:** `ch01_env_tile_terrazzo_dark_idle.png` on every tile not listed below.
- **Dais steps under the north exit:** tiles (6,1), (7,1), (8,1), (9,1), (10,1), (7,2), (8,2), (9,2) → `ch01_env_tile_stone_step_wet_idle.png`.
- **Cracked:** `ch01_env_tile_terrazzo_cracked_idle.png` on (0,0), (11,0), (1,2), (12,2), (7,3), (2,4), (13,4), (8,5), (3,6), (14,6), (9,7), (4,8), (15,8), (10,9), (5,10), (0,11), (11,11), (6,12), (1,13), (12,13).

### 9.2 Walls
- **N wall:** 8 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)` `(432,120)` `(464,136)` `(496,152)` `(528,168)` `(560,184)`
- **W wall:** 7 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)` `(208,120)` `(176,136)` `(144,152)` `(112,168)`
- **Clock(s):** `ch01_prop_digital_clock_2359_idle.png` on N-wall module(s) `k = 3` -> pivot `(432, 82)` (the greybox `Clock` / `digital_clock_2359` pair moves there).

### 9.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_entry_south` | S | `(240, 232)` ((8, 13)) | `ch01_env_archway_frame_n_idle.png` | free-standing frame (no wall on this edge) |
| `door_exit_north` | N | `(448, 128)` ((8, 0)) | `ch01_env_archway_frame_n_idle.png` | overdraws wall modules |

### 9.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.station_atrium.Clock (master clock)` | `ch01_prop_digital_clock_2359_idle.png` | idle | `(352, 120)` ((4.5, 2.5)) | Wall_Fixtures / 7 | existing `Clock` Sprite2D | render **2×** integer scale (64×48) for the monumental atrium clock (metadata 2.8) |
| `ch01.station_atrium.dispatch_terminal` | `ch01_prop_dispatch_terminal_idle.png` / `ch01_prop_dispatch_terminal_active.png` | the node is a `ReadableDocument` with no state field; `_idle` until narrative flag `ch01.flag.ledger_2359_revealed` is true (set at the Beat 09 revelation, page 2 read), then `_active` | `(352, 176)` ((8, 6)) | YSort_Actors / 10 | none | pivot = node position; the 2x master clock above it is the existing clock sprite scaled 2x (no separate sprite) |
| `ch01.station_atrium.(decor) atrium bench W` | `ch01_prop_station_bench_idle.png` | idle | `(240, 176)` ((4.5, 9.5)) | YSort_Actors / 10 | none (new) | tile `(4,9)` cell centre; optional dressing |
| `ch01.station_atrium.(decor) atrium bench E` | `ch01_prop_station_bench_idle.png` | idle | `(432, 208)` ((12.5, 5.5)) | YSort_Actors / 10 | none (new) | tile `(12,5)` cell centre; optional dressing |

**Other greybox nodes:** `Clock` at `(352,120)` is the master clock, drawn at 2× scale; the extra `digital_clock_2359` Area2D at `(320,50)` is the interactable (leave).

## Room 10 — `ch01.street_exit` (12 × 10)

Footprint 12×10 tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/street_exit.tscn`.

### 10.1 Floor
- **Base:** `ch01_env_tile_terrazzo_dark_idle.png` on every tile not listed below.
- **Surface stairs (`StairsAccent` polygon = tiles x 4..7, y 2..3):** tiles (4,2), (5,2), (6,2), (7,2), (4,3), (5,3), (6,3), (7,3) → `ch01_env_tile_stone_step_wet_idle.png`.
- **Cracked:** `ch01_env_tile_terrazzo_cracked_idle.png` on (0,0), (11,0), (6,1), (1,2), (2,4), (8,5), (3,6), (9,7), (4,8), (10,9).

### 10.2 Walls
- **N wall:** 6 × `ch01_env_wall_subterranean_n_idle.png`, pivots: `(336,72)` `(368,88)` `(400,104)` `(432,120)` `(464,136)` `(496,152)`
- **W wall:** 5 × `ch01_env_wall_subterranean_w_idle.png`, pivots: `(304,72)` `(272,88)` `(240,104)` `(208,120)` `(176,136)`

### 10.3 Doorways
| door_id | Side | Node position (tile) | Sprite | Note |
|---|---|---|---|---|
| `door_entry_south` | S | `(272, 184)` ((6, 9)) | `ch01_env_archway_frame_n_idle.png` | free-standing frame (no wall on this edge) |

### 10.4 Props, fixtures and state mapping
| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |
|---|---|---|---|---|---|---|
| `ch01.street_exit.plaza_payphone` | `ch01_prop_call_box_phone_idle.png` (+ `_ringing`) | idle -> ringing at `trigger_outro` | `(400, 136)` ((7, 2)) | Wall_Fixtures / 7 | none | Beat 10 payphone (shares `prop_call_box_phone`) |

**Other greybox nodes:** `StairsAccent` (`Polygon2D`) → the 4×2 `stone_step_wet` block above; `trigger_outro` stays invisible.

---

## 11. Puzzle state → sprite state (master table, quoted from the code)

Source: `scripts/puzzle/objects/*.gd` (read-only). Per ADR-019 a presenter in `scripts/chapters/ch01/visuals/` reads these public fields every frame; **no visual code in `scripts/puzzle/**`**.

| Object (class) | Code state (field = values) | Sprite file | Note |
|---|---|---|---|
| `turnstile_gate` (`TurnstileGate`) | `capture_state()` = `{"arm_state": &"collapsed"\|&"open", "passage_blocked": bool}` | `prop_turnstile_gate_collapsed` / `_open` | `arm_state` is the key; `passage_blocked` always follows it |
| `fire_shutter` (`FireShutter`) | `capture_state()` = `{"shutter_state": &"closed"\|&"raised", "hold_ticks": int, "passage_blocked": bool}` | `prop_fire_shutter_closed` / `_raised` | `raised` is transient (counts down `hold_ticks`) |
| `counterweight_gear` (`CounterweightGear`) | `capture_state()` = `{}`; presentation field `gear_state` = `&"idle"\|&"slipping"\|&"locked"` | `_idle` / `_slipping` / `_frozen` | **code name `locked` = sprite `_frozen`** (also true whenever `is_frozen()`); no rename |
| `surge_capacitor` (`SurgeCapacitor`) | `capture_state()` = `{"charge_state": &"discharged"\|&"charged", "decay_ticks": int, "bus_powered": bool}` plus `is_frozen()` | `_discharged` / `_charged`; `_frozen` while `is_frozen()` | **frozen is a flag over `charge_state`, not a third value**: the `_frozen` sprite hides the charge colour, so a frozen charged vs frozen discharged capacitor look the same (see finding F-1) |
| `pressure_switch_01` (`TriggerZone`) | `is_occupied()` (signal `occupancy_changed(occupied: bool)`) | `prop_pressure_switch_released` / `_pressed` | plate is a `TriggerZone`, not a PuzzleObject |
| `security_gate_01` (`PlateLinkedGate`) | `gate_state` = `&"closed"\|&"open"`; `passage_blocked` = not open; no `TemporalComponent` (chrono-shielded) | `prop_security_gate_closed` / `_open` | latched `open` once PZ-003 is solved |
| `bridge_platform_01` (`RetractableBridge`) | `platform_state` = `&"retracted"\|&"extended"`; `walkable` = extended | `prop_bridge_platform_retracted` / `_extended` | latched `extended` once solved |
| `junction_lever_a/b` (`JunctionLever`) | `relay_state` (signal `relay_changed(relay_state)`); A: `state_a = &"loop"`, `state_b = &"uncoupled"`; B: `state_a = &"niche"`, `state_b = &"atrium"` | `prop_lever_switch_off` when `relay_state == state_a`, `_on` when `== state_b` | toggles both ways until latched solved |
| `route_board` (`Interactable`) | no state of its own; derive from both levers: (`loop`,`niche`) = 0, (`uncoupled`,`niche`) = 1, (`uncoupled`,`atrium`) = 2 | `prop_route_board_state0` / `_state1` / `_state2` | (`loop`,`atrium`) cannot occur: lever B before A is refused by the graph |
| `breaker_a/b` (`TimedBreaker`) | `lever_state` = `&"open"\|&"engaged"` (`is_engaged()`, signal `engaged_changed(engaged)`); auto-releases after `engage_ticks_base` = 180 ticks | `prop_lever_switch_off` when `open`, `_on` when `engaged` | the lever returns to `_off` on release (timed breaker); unpowered pulls are refused with `&"unpowered"` |
| `vestibule_door` (`PoweredDoor`) | opens permanently when its grid goes online | `archway_frame_n` + `DoorwayPresenter` glyph | no extra sprite |
| `dispatch_terminal` (`ReadableDocument`) | no state field; narrative flag `ch01.flag.ledger_2359_revealed` (ROOM_GRAPH §6.2) | `prop_dispatch_terminal_idle` -> `_active` | code has no state, so the presenter keys off the flag (finding F-2) |
| `stalled transit car` | static dressing | `prop_transit_car_stalled_idle` | single state |
| conduit feeds (Rooms 3, 4, 6, 7) | follow the object named in each room table: `FireShutter` solved / plate `is_occupied()` / `bus_powered` / lever `relay_state == state_b` | `tile_cable_conduit_off` -> `_on` | swap the tile in the `TileMapLayer` |
| `call_box_09`, `intercom`, `plaza_payphone` | dialogue pending (no state field) | `prop_call_box_phone_idle` -> `_ringing` | presenter-driven |
| pickups (`doc_*`, `transit_pass_pickup`, `audio_mira_01`, `global.pocket_watch`) | present -> collected | `prop_document_clipboard_idle` / `prop_pocket_watch_idle` | hide the node on collect |

---

## 12. Coverage

All ROOM_GRAPH §7.3 hero set-pieces now have sprites: turnstile, fire shutter, counterweight gear, pressure switch, security gate, bridge platform, surge capacitor, route board, dispatch terminal, stalled transit car. The §7.3 'scaled `23:59` Atrium clock' is **not** a separate sprite: it is `prop_digital_clock_2359_idle` drawn at 2× integer scale (64×48, pivot `(32,40)`), as metadata 2.8 already allowed. Optional extras shipped: `prop_pa_speaker_idle`. Pivot rule for large pieces: footprint centre (bible appendix A.3).

---

## 13. Resolved questions (ADR-019) and findings

| ID | Topic | Decision / status |
|---|---|---|
| OQ-1 | Typo `(448,160)` in metadata 2.9 | Fixed to `(448, 208)`. |
| OQ-2 | Free-standing levers/consoles/benches `z` | `YSort_Actors` 10; wall-mounted 7 (§0.5, per-object `Layer / z` column). Bible appendix A.1. |
| OQ-3 | Lever badges A/B | Delivered as overlays (§0.10). |
| OQ-4 | Intercom mount | Node moves to the N-wall mount (Flash, TLF-041); sheet unchanged. |
| OQ-5 | Pocket-watch pickup | `prop_pocket_watch_idle` delivered (Room 1). |
| OQ-6 | PA speaker | `prop_pa_speaker_idle` delivered (optional wall horn, Room 4). |
| OQ-7 | Rails in rooms 1/5 | Accepted: none there. |
| OQ-8 | Echo recorder pedestal | Not built (ADR-019). |
| OQ-9 | Greybox `Clock` nodes | Clocks go on wall modules (§0.6); Flash places them. |
| OQ-10 | Archway naming | Accepted, no rename. |

**Findings from reading the puzzle code (code is authoritative):**
- **F-1** `SurgeCapacitor`: ROOM_GRAPH §7.3 lists `discharged / charged / frozen` as three states; the code has two `charge_state` values and a separate `is_frozen()` flag. The art keeps three sprites; the presenter shows `_frozen` whenever `is_frozen()` is true. A frozen-charged vs frozen-discharged distinction (`is_stabilized()`) would need two more sprites if the design wants it visible.
- **F-2** `dispatch_terminal` is a `ReadableDocument`; there is no code state for the `_active` sprite, so it needs a narrative-flag presenter (or can ship as `_idle` only).
- **F-3** `CounterweightGear.gear_state` uses `locked`; the sprite file keeps `frozen` (§11).

