from placement_render import *

A = 'assets/environments/ch01/'
PR = 'assets/props/ch01/'
rooms = build_rooms()
L = []
w = L.append


def f(stem):
    return f'`{stem}.png`'


def pos_s(p):
    return '(%d, %d)' % (p[0], p[1])


w("# CH01 Placement Sheet — art kit → rooms 1–10 (`TLF-039`)")
w("")
w("**Author:** design-art agent (Claude Code, Sonnet 5.5, standing in for Argon) · **Audience:** Flash (integration task, `TLF-018`/follow-up) · **Inputs:** `design/ch01/ROOM_GRAPH.md` §1/§5/§7, `design/art/ART_BIBLE.md`, `design/art/ASSET_METADATA.md`, and the greybox `scenes/chapters/ch01/rooms/*.tscn` (read-only; every node position below is copied from those files by script, not typed).")
w("")
w("**Scope of this sheet:** every kit piece and puzzle prop delivered by TLF-039 and TLF-042 is placed room by room (state mapping quotes the real `scripts/puzzle/objects/*.gd` fields, §11). *(decor)* marks optional dressing with no `.tscn` node yet. Layer/sorting rules follow ADR-019 (free-standing = `YSort_Actors` 10, wall-mounted = `Wall_Fixtures` 7).")
w("")
w("Mockups (`640×360`, true scale, kit pieces only): `design/art/mockups/ch01_arrival_platform_mockup.png` (validation against the approved target sheet), `ch01_concourse_west_mockup.png`, `ch01_signal_control_mockup.png`.")
w("")
w("---")
w("")
w("## 0. Conventions (read once)")
w("")
w("### 0.1 Coordinates")
w("`px_x = 320 + (x - y) * 16`, `px_y = 64 + (x + y) * 8` (ROOM_GRAPH §1). A room `W × H` covers tiles `x ∈ [0, W-1]`, `y ∈ [0, H-1]`; **tile `(x, y)` has its top vertex at `px(x, y)` and its diamond centre at `px(x, y) + (0, 8)`**. All 10 rooms have even `W` and `H`.")
w("")
w("### 0.2 Floor — `TileMapLayer_Floor` (`z_index = 0`)")
w("- `tile_size = (32, 16)`, isometric, diamond-down. Set the layer `position = (320, 72)` so tile `(x, y)`'s centre lands on `px(x, y) + (0, 8)`. Each tile PNG is exactly one diamond; the pivot `(16, 8)` is the tile centre. The bevel/rim colours are authored to tile without seams (bible §5.1). Verify the offset in-engine against `design/art/mockups/ch01_arrival_platform_mockup.png`.")
w("- Each room section lists the floor as: **base tile** + **override areas** + **cracked tiles** (deterministic rule `(x*5 + y*3) % 11 == 0`, skipping override tiles; rooms 3, 4, 6 use the concrete base and get **no** cracked tiles because only the terrazzo family has a cracked variant).")
w("")
w("### 0.3 Wall modules (`YSort_Walls`, `z_index = 5`)")
w("A wall module is `32 × 64`, pivot `(16, 56)`, and spans **two tile edges**. Only the back walls are drawn (N and W), as in the approved target sheet; the S and E boundaries stay open (doorways there are free-standing archway frames).")
w("- **N wall** (`y = 0`), `wall_subterranean_n` (down-right slope): module `k = 0 .. W/2 - 1`, **pivot position = `(336 + 32k, 72 + 16k)`**.")
w("- **W wall** (`x = 0`), `wall_subterranean_w` (down-left slope): module `j = 0 .. H/2 - 1`, **pivot position = `(304 - 32j, 72 + 16j)`**.")
w("- Exact pivot lists per room are in each room section. Wall collision is **not** changed: keep `PerimeterWalls/CollisionPolygon2D`.")
w("")
w("### 0.4 Doorways (`YSort_Walls`, `z_index = 6`)")
w("- Sprite by wall slope: **W and E doorways → `archway_frame_e`** (down-left slope, batch 1, = §7.1 `wall_archway_frame_w`); **N and S doorways → `archway_frame_n`** (down-right slope, new, = §7.1 `wall_archway_frame_n`). See `ASSET_METADATA.md` §4.1.")
w("- **Position = the doorway node's `position`** (the `Archway*` `Sprite2D`s already do this). On N/W walls the archway **overdraws** the wall modules underneath; do **not** delete the modules (the archway is opaque over its 32×64 footprint, so even/odd door tiles both work).")
w("- The transom glyph (`[◁] [◇] [▲] [■]`) is a separate overlay owned by `DoorwayPresenter`; the frame ships with the neutral cyan glyph baked in.")
w("")
w("### 0.5 Layers and Y-sort (ADR-019)")
w("| Layer | `z_index` | Contents | Y-sort key |")
w("|---|---|---|---|")
w("| `TileMapLayer_Floor` | 0 | all `tile_*` | n/a |")
w("| `YSort_Walls` | 5 | wall modules, `wall_corner_pillar` (6 for archways) | node `position.y` (= pivot) |")
w("| `Wall_Fixtures` | 7 | **wall-mounted only**: clock, call box, PA horn, levers that stand at the foot of a drawn wall | node `position.y` |")
w("| `YSort_Props` | 8 | railing, clipboard, pocket watch, pressure switch, bridge deck | node `position.y` |")
w("| `YSort_Actors` | 10 | Elias and every **free-standing** object: bench, reset console, free-standing levers/breakers, route board, security gate, shutter, gear, capacitor, turnstile, dispatch terminal, transit car | node `position.y` (Elias draws behind them when he is north of them) |")
w("Every sprite's pivot is its base-line contact point (footprint centre for large pieces, appendix A.3 of the bible), so Godot's default Y-sort (by node `position.y`) is correct without extra offsets.")
w("")
w("### 0.6 Sprite placement rule")
w("**Sprite pivot = the interactable node's `position`** (child `Sprite2D` at `(0,0)` with `offset = -pivot`, `centered = false`); this keeps every ADR-015 distance in ROOM_GRAPH §5 untouched. Exceptions are written out in the tables (`+ (0, 8)` for the free-standing pillar; wall mounts).")
w("- **Wall mounts** (`mount` column): pivot = base midpoint of the named wall module (§0.3) `+ (0, -14)`; the node/trigger stays where the `.tscn` has it.")
w("- **Wall clock:** pivot = base midpoint of the named N-wall module `+ (0, -38)` (metadata 2.8, `y_offset = -38`). The greybox `Clock` at `(320, 50)` floats above the room apex and should move to this position.")
w("")
w("### 0.7 Flip rule")
w("Axis-run pieces (`wall_railing_iron`, `prop_station_bench`, `tile_cable_conduit_*`) are authored along the down-right (`+x`) axis. Down-left (`+y`) axis → `flip_h`. Conduit direction: `+x` as authored, `+y` = `flip_h`, `-y` = `flip_v`, `-x` = `flip_h + flip_v`. Baked light flips with the sprite (same compromise as bible §2.3 #4).")
w("")
w("### 0.8 Sprite index")
w("| Sprite file | Size | Pivot | Layer / `z` |")
w("|---|---|---|---|")
rows = [
    ('ch01_env_tile_terrazzo_dark_idle', '32×16', '(16,8)', 'floor 0'), ('ch01_env_tile_terrazzo_cracked_idle', '32×16', '(16,8)', 'floor 0'),
    ('ch01_env_tile_tactile_amber_idle', '32×16', '(16,8)', 'floor 0'), ('ch01_env_tile_industrial_grating_idle', '32×16', '(16,8)', 'floor 0'),
    ('ch01_env_tile_concrete_service_idle', '32×16', '(16,8)', 'floor 0'), ('ch01_env_tile_cable_conduit_off_idle', '32×16', '(16,8)', 'floor 0'),
    ('ch01_env_tile_cable_conduit_on_idle', '32×16', '(16,8)', 'floor 0'), ('ch01_env_tile_stone_step_wet_idle', '32×16', '(16,8)', 'floor 0'),
    ('ch01_env_wall_subterranean_n_idle', '32×64', '(16,56)', 'YSort_Walls 5'), ('ch01_env_wall_subterranean_w_idle', '32×64', '(16,56)', 'YSort_Walls 5'),
    ('ch01_env_wall_corner_pillar_idle', '32×64', '(16,56)', 'YSort_Walls 5'), ('ch01_env_archway_frame_e_idle', '32×64', '(16,56)', 'YSort_Walls 6'),
    ('ch01_env_archway_frame_n_idle', '32×64', '(16,56)', 'YSort_Walls 6'), ('ch01_env_wall_railing_iron_idle', '32×48', '(16,40)', 'YSort_Props 8'),
    ('ch01_prop_digital_clock_2359_idle', '32×24', '(16,20)', 'Wall_Fixtures 7'), ('ch01_prop_call_box_phone_idle / _ringing', '24×36', '(12,32)', 'Wall_Fixtures 7'),
    ('ch01_prop_lever_switch_off / _on', '24×32', '(12,28)', '10 free-standing / 7 wall-mounted (per object, ADR-019)'), ('ch01_prop_document_clipboard_idle', '16×16', '(8,12)', 'YSort_Props 8'),
    ('ch01_prop_reset_console_idle', '32×36', '(16,30)', 'YSort_Actors 10'), ('ch01_prop_station_bench_idle', '48×32', '(24,26)', 'YSort_Actors 10'),
    ('ch01_char_elias_base_sheet', '2560×48 (80 × 32×48)', '(16,44)', 'YSort_Actors 10'),
    ('ch01_prop_turnstile_gate_collapsed / _open', '32×40', '(16,34)', 'YSort_Actors 10'),
    ('ch01_prop_fire_shutter_closed / _raised', '64×64', '(32,56)', 'YSort_Actors 10'),
    ('ch01_prop_counterweight_gear_idle / _slipping / _frozen', '64×64', '(32,56)', 'YSort_Actors 10'),
    ('ch01_prop_surge_capacitor_discharged / _charged / _frozen_discharged / _frozen_charged', '64×64', '(32,56)', 'YSort_Actors 10'),
    ('ch01_prop_surge_capacitor_frozen (**deprecated**, TLF-044)', '64×64', '(32,56)', 'YSort_Actors 10'),
    ('ch01_prop_pressure_switch_released / _pressed', '32×20', '(16,12)', 'YSort_Props 8'),
    ('ch01_prop_route_board_state0 / _state1 / _state2', '48×56', '(24,50)', 'YSort_Actors 10'),
    ('ch01_prop_security_gate_closed / _open', '40×52', '(20,42)', 'YSort_Actors 10'),
    ('ch01_prop_bridge_platform_retracted / _extended', '48×32', '(24,18)', 'YSort_Props 8'),
    ('ch01_prop_transit_car_stalled_idle', '128×80', '(64,52)', 'YSort_Actors 10'),
    ('ch01_prop_dispatch_terminal_idle / _active', '64×64', '(32,56)', 'YSort_Actors 10'),
    ('ch01_prop_pocket_watch_idle', '16×16', '(8,12)', 'YSort_Props 8'),
    ('ch01_prop_lever_badge_a_idle / _b_idle', '5×7', '(2,3)', 'child of the lever (same z)'),
    ('ch01_prop_pa_speaker_idle', '16×16', '(8,12)', 'Wall_Fixtures 7'),
]
for a, b, c, d in rows:
    w(f'| `{a}` | {b} | {c} | {d} |')
w("")
w("### 0.9 Greybox nodes that are replaced everywhere")
w("| Greybox node (all rooms) | Replaced by |")
w("|---|---|")
w("| `Floor`, `FloorAccent` (`Polygon2D`, `z_index = -1`) | `TileMapLayer_Floor` (section per room). Delete both polygons after the layer is in. |")
w("| `PerimeterWalls` (`StaticBody2D`) | **Kept** (collision only); wall modules are visual only. |")
w("| `Clock` (`Sprite2D`, `(320,50)`) | same texture, **reposition** per §0.6 (room sections list the module). |")
w("| `Archway*` (`Sprite2D`, rooms 1–4) | keep node, set texture by slope (§0.4); N/S doors in other rooms get a **new** `Sprite2D`. |")
w("")
w("### 0.10 Lever badges A / B (overlay, not variants)")
w("`ch01_prop_lever_badge_a_idle.png` / `_b_idle.png` are 5×7 overlays (gold glyph on a dark plate), pivot `(2, 3)`. Add each as a **child `Sprite2D` of the lever** at offset `(3, -8)` from the lever pivot, same `z_index`: `A` on `breaker_a` and `junction_lever_a`, `B` on `breaker_b` and `junction_lever_b`. Chosen over `prop_lever_switch_{a,b}_{off,on}` because it adds 2 files instead of 4 lever variants, never multiplies with the on/off state, and the same overlay can label future switches. The badge does not change with the lever state.")
w("")
w("---")
w("")

for r in rooms:
    n, wl = wall_pivots(r)
    fm = floor_map(r)
    cr = cracked_tiles(r)
    base_name = {'dark': 'terrazzo_dark', 'concrete': 'concrete_service'}[r.base]
    w(f"## Room {r.num} — `{r.id}` ({r.W} × {r.H})")
    w("")
    w(f"Footprint {r.W}×{r.H} tiles · apex `(320, 64)` · scene `scenes/chapters/ch01/rooms/{r.key}.tscn`.")
    w("")
    w(f"### {r.num}.1 Floor")
    w(f"- **Base:** `{T[r.base]}.png` on every tile not listed below.")
    for label, tiles, t in r.areas:
        if not tiles: continue
        lst = ', '.join('(%d,%d)' % q for q in tiles)
        if t is None:
            w(f"- **{label}:** tiles {lst} → **no tile** (leave empty; keep `TrenchVisual` as the black backing).")
        else:
            w(f"- **{label}:** tiles {lst} → `{T[t]}.png`" + (" (`+x` run; swap to `" + T['conduit_on'] + ".png` when powered)" if t == 'conduit_off' else '') + ".")
    if r.cracked and r.base == 'dark':
        w(f"- **Cracked:** `{T['cracked']}.png` on " + ', '.join('(%d,%d)' % q for q in cr) + '.')
    w("")
    w(f"### {r.num}.2 Walls")
    w(f"- **N wall:** {len(n)} × `ch01_env_wall_subterranean_n_idle.png`, pivots: " + ' '.join('`(%d,%d)`' % b for b in n))
    w(f"- **W wall:** {len(wl)} × `ch01_env_wall_subterranean_w_idle.png`, pivots: " + ' '.join('`(%d,%d)`' % b for b in wl))
    if r.clocks:
        w("- **Clock(s):** `ch01_prop_digital_clock_2359_idle.png` on N-wall module(s) " + ', '.join(f'`k = {k}` -> pivot `({n[k][0]}, {n[k][1]-38})`' for k in r.clocks) + " (the greybox `Clock` / `digital_clock_2359` pair moves there).")
    elif r.key == 'station_atrium':
        w("- **Clock:** master clock, see props (2x scale).")
    if r.rails:
        mods = rail_modules(r)
        w(f"- **Railings** (`ch01_env_wall_railing_iron_idle.png`, `YSort_Props` 8; `flip_h` for `y`-axis runs): " + ' '.join('`%s(%d,%d)`' % (('flipped ' if a == 'y' else ''), c[0], c[1]) for a, c in mods))
    w("")
    w(f"### {r.num}.3 Doorways")
    w("| door_id | Side | Node position (tile) | Sprite | Note |")
    w("|---|---|---|---|---|")
    for door_id, side in r.doors:
        d = r.pos[door_id]
        spr = 'ch01_env_archway_frame_e_idle.png' if side in 'WE' else 'ch01_env_archway_frame_n_idle.png'
        note = 'overdraws wall modules' if side in 'NW' else 'free-standing frame (no wall on this edge)'
        if r.key == 'vestibule_niche' and door_id == 'door_out':
            note += '; iron grille overlay, see props'
        w(f"| `{door_id}` | {side} | `{pos_s(d)}` ({fmt_t(tile_of(d))}) | `{spr}` | {note} |")
    w("")
    w(f"### {r.num}.4 Props, fixtures and state mapping")
    w("| Object ID | Sprite (file) | State → sprite state | Pivot position | Layer / `z` | Replaces greybox | Note |")
    w("|---|---|---|---|---|---|---|")
    for pr in r.props:
        if pr['sprite']:
            stem, piv, size, z, layer = SP[pr['sprite']]
            if pr.get('zlayer'): z, layer = pr['zlayer']
            if pr.get('ov'): z, layer = 9, 'YSort_Props (overlay, above archway)'
            pos = pr['pos']
            if pr.get('mount'):
                mp = mount_pivot(r, pr['mount']); ps = f"`{pos_s(mp)}` (mount; node stays `{pos_s(pos)}`)"
            elif pr.get('off'):
                ps = f"`{pos_s((pos[0] + pr['off'][0], pos[1] + pr['off'][1]))}` (node `{pos_s(pos)}` + `{pr['off']}`)"
            else:
                ps = f"`{pos_s(pos)}` ({fmt_t(tile_of(pos))})"
            states = pr['state']
            sprite_s = f"`{stem}.png`" + (' (+ `_ringing`)' if 'ringing' in states else '') + (' (+ `_on`)' if pr['sprite'] == 'lever_off' else '')
            if pr.get('files'):
                sprite_s = ' / '.join(f'`{x}.png`' for x in pr['files'])
            w(f"| `{r.id}.{pr['obj']}` | {sprite_s} | {states} | {ps} | {layer} / {z} | {pr['repl']} | {pr['note']} |")
        else:
            w(f"| `{r.id}.{pr['obj']}` | *(none in this batch)* | {pr['state']} | " + (f"`{pos_s(pr['pos'])}`" if pr['pos'] else '-') + f" | - | {pr['repl']} | {pr['note']} |")
    w("")
    extra = {
        'concourse_west': "Greybox `TurnstileDividers/DividerNorth|DividerSouth` stay as collision. `exit_trigger_concourse`, `turnstile_footprint`, `turnstile_trace_anchor` are invisible triggers.",
        'maintenance_bay': "`ShutterDividers/DividerNorth|DividerSouth` stay as collision. `shutter_threshold_trigger`, `exit_trigger_east` are invisible.",
        'security_crossing': "`TrenchVisual` (`Polygon2D`, tiles x=9) is **kept** as the void backing under the empty trench tile; `TrenchBarriers/*` stay as collision. ROOM_GRAPH §5.3 lists `echo_recorder_pedestal` at `(4,8)`, but the greybox scene has no such node (OQ-8).",
        'signal_control': "`SouthRailingVisual`, `NorthRailingVisual` (`Line2D`) → railing modules above; `NorthBarrierVisual` (`Polygon2D`, tiles x 10..14, y 5..) → keep until a barrier sprite exists; `substation_grid` has no position/visual.",
        'upper_vestibule': "`spatial_resetter` has no position/visual. Door sprites follow the **declared** door side (`door_south`/`door_north` → `archway_frame_n`; `door_west`/`door_east` → `archway_frame_e`) regardless of the dynamic graph state.",
        'vestibule_niche': "`GrilleBlocker` stays. The grille = `archway_frame_n` + one `wall_railing_iron` module (flipped `y`-axis not needed, `x`-axis as authored) at the same pivot with `z_index = 9`.",
        'station_atrium': "`Clock` at `(352,120)` is the master clock, drawn at 2× scale; the extra `digital_clock_2359` Area2D at `(320,50)` is the interactable (leave).",
        'street_exit': "`StairsAccent` (`Polygon2D`) → the 4×2 `stone_step_wet` block above; `trigger_outro` stays invisible.",
        'arrival_platform': "Near edges (S, E) carry the amber lip and no wall, as in the approved target sheet. The stalled car (Tier 2) sits on the SW trench side.",
        'waiting_lounge': "`checkpoint` and `safe_anchor_center` are invisible.",
    }
    if r.key in extra:
        w(f"**Other greybox nodes:** {extra[r.key]}")
        w("")

w("---")
w("")
w("## 11. Puzzle state → sprite state (master table, quoted from the code)")
w("")
w("Source: `scripts/puzzle/objects/*.gd` (read-only). Per ADR-019 a presenter in `scripts/chapters/ch01/visuals/` reads these public fields every frame; **no visual code in `scripts/puzzle/**`**.")
w("")
w("| Object (class) | Code state (field = values) | Sprite file | Note |")
w("|---|---|---|---|")
tbl = [
    ("`turnstile_gate` (`TurnstileGate`)", "`capture_state()` = `{\"arm_state\": &\"collapsed\"\\|&\"open\", \"passage_blocked\": bool}`", "`prop_turnstile_gate_collapsed` / `_open`", "`arm_state` is the key; `passage_blocked` always follows it"),
    ("`fire_shutter` (`FireShutter`)", "`capture_state()` = `{\"shutter_state\": &\"closed\"\\|&\"raised\", \"hold_ticks\": int, \"passage_blocked\": bool}`", "`prop_fire_shutter_closed` / `_raised`", "`raised` is transient (counts down `hold_ticks`)"),
    ("`counterweight_gear` (`CounterweightGear`)", "`capture_state()` = `{}`; presentation field `gear_state` = `&\"idle\"\\|&\"slipping\"\\|&\"locked\"`", "`_idle` / `_slipping` / `_frozen`", "**code name `locked` = sprite `_frozen`** (also true whenever `is_frozen()`); no rename"),
    ("`surge_capacitor` (`SurgeCapacitor`)", "`capture_state()` = `{\"charge_state\": &\"discharged\"\\|&\"charged\", \"decay_ticks\": int, \"bus_powered\": bool}` plus `is_frozen()`", "4 sprites by `(charge_state, is_frozen())`: (`discharged`,false) `_discharged`; (`charged`,false) `_charged`; (`discharged`,true) `_frozen_discharged`; (`charged`,true) `_frozen_charged`", "frozen is a flag over `charge_state`. The frozen pair is readable **without colour**: frost-white fill rising in all three cells + solid crystal hexagon + rigid bridge bar = charged (stabilised when `bus_powered`); empty dark tubes + hollow hexagon + no bridge = discharged. Old `_frozen` is deprecated."),
    ("`pressure_switch_01` (`TriggerZone`)", "`is_occupied()` (signal `occupancy_changed(occupied: bool)`)", "`prop_pressure_switch_released` / `_pressed`", "plate is a `TriggerZone`, not a PuzzleObject"),
    ("`security_gate_01` (`PlateLinkedGate`)", "`gate_state` = `&\"closed\"\\|&\"open\"`; `passage_blocked` = not open; no `TemporalComponent` (chrono-shielded)", "`prop_security_gate_closed` / `_open`", "latched `open` once PZ-003 is solved"),
    ("`bridge_platform_01` (`RetractableBridge`)", "`platform_state` = `&\"retracted\"\\|&\"extended\"`; `walkable` = extended", "`prop_bridge_platform_retracted` / `_extended`", "latched `extended` once solved"),
    ("`junction_lever_a/b` (`JunctionLever`)", "`relay_state` (signal `relay_changed(relay_state)`); A: `state_a = &\"loop\"`, `state_b = &\"uncoupled\"`; B: `state_a = &\"niche\"`, `state_b = &\"atrium\"`", "`prop_lever_switch_off` when `relay_state == state_a`, `_on` when `== state_b`", "toggles both ways until latched solved"),
    ("`route_board` (`Interactable`)", "no state of its own; derive from both levers: (`loop`,`niche`) = 0, (`uncoupled`,`niche`) = 1, (`uncoupled`,`atrium`) = 2", "`prop_route_board_state0` / `_state1` / `_state2`", "(`loop`,`atrium`) cannot occur: lever B before A is refused by the graph"),
    ("`breaker_a/b` (`TimedBreaker`)", "`lever_state` = `&\"open\"\\|&\"engaged\"` (`is_engaged()`, signal `engaged_changed(engaged)`); auto-releases after `engage_ticks_base` = 180 ticks", "`prop_lever_switch_off` when `open`, `_on` when `engaged`", "the lever returns to `_off` on release (timed breaker); unpowered pulls are refused with `&\"unpowered\"`"),
    ("`vestibule_door` (`PoweredDoor`)", "opens permanently when its grid goes online", "`archway_frame_n` + `DoorwayPresenter` glyph", "no extra sprite"),
    ("`dispatch_terminal` (`ReadableDocument`)", "no state field; narrative flag `ch01.flag.ledger_2359_revealed` (ROOM_GRAPH §6.2)", "`prop_dispatch_terminal_idle` -> `_active`", "code has no state, so the presenter keys off the flag (finding F-2)"),
    ("`stalled transit car`", "static dressing", "`prop_transit_car_stalled_idle`", "single state"),
    ("conduit feeds (Rooms 3, 4, 6, 7)", "follow the object named in each room table: `FireShutter` solved / plate `is_occupied()` / `bus_powered` / lever `relay_state == state_b`", "`tile_cable_conduit_off` -> `_on`", "swap the tile in the `TileMapLayer`"),
    ("`call_box_09`, `intercom`, `plaza_payphone`", "dialogue pending (no state field)", "`prop_call_box_phone_idle` -> `_ringing`", "presenter-driven"),
    ("pickups (`doc_*`, `transit_pass_pickup`, `audio_mira_01`, `global.pocket_watch`)", "present -> collected", "`prop_document_clipboard_idle` / `prop_pocket_watch_idle`", "hide the node on collect"),
]
for a_, b_, c_, d_ in tbl:
    w(f"| {a_} | {b_} | {c_} | {d_} |")
w("")
w("---")
w("")
w("## 12. Coverage")
w("")
w("All ROOM_GRAPH §7.3 hero set-pieces now have sprites: turnstile, fire shutter, counterweight gear, pressure switch, security gate, bridge platform, surge capacitor, route board, dispatch terminal, stalled transit car. The §7.3 'scaled `23:59` Atrium clock' is **not** a separate sprite: it is `prop_digital_clock_2359_idle` drawn at 2× integer scale (64×48, pivot `(32,40)`), as metadata 2.8 already allowed. Optional extras shipped: `prop_pa_speaker_idle`. Pivot rule for large pieces: footprint centre (bible appendix A.3).")
w("")
w("---")
w("")
w("## 13. Resolved questions (ADR-019) and findings")
w("")
w("| ID | Topic | Decision / status |")
w("|---|---|---|")
w("| OQ-1 | Typo `(448,160)` in metadata 2.9 | Fixed to `(448, 208)`. |")
w("| OQ-2 | Free-standing levers/consoles/benches `z` | `YSort_Actors` 10; wall-mounted 7 (§0.5, per-object `Layer / z` column). Bible appendix A.1. |")
w("| OQ-3 | Lever badges A/B | Delivered as overlays (§0.10). |")
w("| OQ-4 | Intercom mount | Node moves to the N-wall mount (Flash, TLF-041); sheet unchanged. |")
w("| OQ-5 | Pocket-watch pickup | `prop_pocket_watch_idle` delivered (Room 1). |")
w("| OQ-6 | PA speaker | `prop_pa_speaker_idle` delivered (optional wall horn, Room 4). |")
w("| OQ-7 | Rails in rooms 1/5 | Accepted: none there. |")
w("| OQ-8 | Echo recorder pedestal | Not built (ADR-019). |")
w("| OQ-9 | Greybox `Clock` nodes | Clocks go on wall modules (§0.6); Flash places them. |")
w("| OQ-10 | Archway naming | Accepted, no rename. |")
w("")
w("**Findings from reading the puzzle code (code is authoritative):**")
w("- **F-1** `SurgeCapacitor`: ROOM_GRAPH §7.3 lists `discharged / charged / frozen` as three states; the code has two `charge_state` values and a separate `is_frozen()` flag. **Resolved in TLF-044 (ADR-019 amendment):** four sprites keyed by `(charge_state, is_frozen())`; `prop_surge_capacitor_frozen` is deprecated and stays until TLF-041 has switched over.")
w("- **F-2** `dispatch_terminal` is a `ReadableDocument`; there is no code state for the `_active` sprite, so it needs a narrative-flag presenter (or can ship as `_idle` only).")
w("- **F-3** `CounterweightGear.gear_state` uses `locked`; the sprite file keeps `frozen` (§11).")
w("")
SHEET_PATH = os.path.join(REPO, 'design', 'art', 'CH01_PLACEMENT_SHEET.md')
SHEET_TEXT = '\n'.join(L) + '\n'
if __name__ == '__main__':
    with open(SHEET_PATH, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(SHEET_TEXT)
    print('sheet written', len(SHEET_TEXT))
