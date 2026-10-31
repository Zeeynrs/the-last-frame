"""Placement data model for the 10 Ch1 rooms -> CH01_PLACEMENT_SHEET.md + mockups (one source of truth)."""
import re, os, sys
from lib import *

ROOMS_DIR = os.path.join(REPO, 'scenes', 'chapters', 'ch01', 'rooms')


def px(x, y):
    return (320 + (x - y) * 16, 64 + (x + y) * 8)


def tile_of(p):
    dx, dy = (p[0] - 320) / 16.0, (p[1] - 64) / 8.0
    return ((dx + dy) / 2.0, (dy - dx) / 2.0)


def fmt_t(t):
    f = lambda v: ('%d' % v) if abs(v - round(v)) < 1e-6 else ('%.1f' % v)
    return '(%s, %s)' % (f(t[0]), f(t[1]))


def parse_tscn(name):
    pos = {}
    cur = None
    for l in open(os.path.join(ROOMS_DIR, name + '.tscn'), encoding='utf-8'):
        m = re.match(r'\[node name="([^"]+)"(?: type="([^"]+)")?(?: parent="([^"]*)")?', l)
        if m:
            cur = m.group(1) if m.group(3) == '.' else None
            continue
        m = re.match(r'position = Vector2\(([-\d.]+), ([-\d.]+)\)', l)
        if m and cur and cur not in pos:
            pos[cur] = (float(m.group(1)), float(m.group(2)))
    return pos


T = {  # tile sprite stems
    'dark': 'ch01_env_tile_terrazzo_dark_idle', 'cracked': 'ch01_env_tile_terrazzo_cracked_idle',
    'amber': 'ch01_env_tile_tactile_amber_idle', 'grating': 'ch01_env_tile_industrial_grating_idle',
    'concrete': 'ch01_env_tile_concrete_service_idle', 'conduit_off': 'ch01_env_tile_cable_conduit_off_idle',
    'conduit_on': 'ch01_env_tile_cable_conduit_on_idle', 'step': 'ch01_env_tile_stone_step_wet_idle',
}
SP = {  # sprite stems: (stem, pivot, size, z, layer)
    'clock': ('ch01_prop_digital_clock_2359_idle', (16, 20), (32, 24), 7, 'Wall_Fixtures'),
    'callbox': ('ch01_prop_call_box_phone_idle', (12, 32), (24, 36), 7, 'Wall_Fixtures'),
    'callbox_ring': ('ch01_prop_call_box_phone_ringing', (12, 32), (24, 36), 7, 'Wall_Fixtures'),
    'console': ('ch01_prop_reset_console_idle', (16, 30), (32, 36), 10, 'YSort_Actors'),
    'lever_off': ('ch01_prop_lever_switch_off', (12, 28), (24, 32), 7, 'Wall_Fixtures'),
    'lever_on': ('ch01_prop_lever_switch_on', (12, 28), (24, 32), 7, 'Wall_Fixtures'),
    'clip': ('ch01_prop_document_clipboard_idle', (8, 12), (16, 16), 8, 'YSort_Props'),
    'bench': ('ch01_prop_station_bench_idle', (24, 26), (48, 32), 10, 'YSort_Actors'),
    'pillar': ('ch01_env_wall_corner_pillar_idle', (16, 56), (32, 64), 5, 'YSort_Walls'),
    'rail': ('ch01_env_wall_railing_iron_idle', (16, 40), (32, 48), 8, 'YSort_Props'),
    'arch_e': ('ch01_env_archway_frame_e_idle', (16, 56), (32, 64), 6, 'YSort_Walls'),
    'arch_n': ('ch01_env_archway_frame_n_idle', (16, 56), (32, 64), 6, 'YSort_Walls'),
    'turnstile': ('ch01_prop_turnstile_gate_collapsed', (16, 34), (32, 40), 10, 'YSort_Actors'),
    'shutter': ('ch01_prop_fire_shutter_closed', (32, 56), (64, 64), 10, 'YSort_Actors'),
    'gear': ('ch01_prop_counterweight_gear_idle', (32, 56), (64, 64), 10, 'YSort_Actors'),
    'capacitor': ('ch01_prop_surge_capacitor_discharged', (32, 56), (64, 64), 10, 'YSort_Actors'),
    'pswitch': ('ch01_prop_pressure_switch_released', (16, 12), (32, 20), 8, 'YSort_Props'),
    'routeboard': ('ch01_prop_route_board_state0', (24, 50), (48, 56), 10, 'YSort_Actors'),
    'secgate': ('ch01_prop_security_gate_closed', (20, 42), (40, 52), 10, 'YSort_Actors'),
    'bridge': ('ch01_prop_bridge_platform_retracted', (24, 18), (48, 32), 8, 'YSort_Props'),
    'car': ('ch01_prop_transit_car_stalled_idle', (64, 52), (128, 80), 10, 'YSort_Actors'),
    'dispatch': ('ch01_prop_dispatch_terminal_idle', (32, 56), (64, 64), 10, 'YSort_Actors'),
    'watch': ('ch01_prop_pocket_watch_idle', (8, 12), (16, 16), 8, 'YSort_Props'),
    'horn': ('ch01_prop_pa_speaker_idle', (8, 12), (16, 16), 7, 'Wall_Fixtures'),
    'wall_n': ('ch01_env_wall_subterranean_n_idle', (16, 56), (32, 64), 5, 'YSort_Walls'),
    'wall_w': ('ch01_env_wall_subterranean_w_idle', (16, 56), (32, 64), 5, 'YSort_Walls'),
}


class Room:
    pass


def rect(x0, y0, x1, y1):
    return [(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)]


def build_rooms():
    R = []

    def mk(num, key, W, H, base, cracked=True):
        r = Room(); r.num, r.key, r.W, r.H, r.base, r.cracked = num, key, W, H, base, cracked
        r.id = 'ch01.' + key; r.pos = parse_tscn(key)
        r.areas = []     # (label, [(x,y)], tile)
        r.doors = []     # (door_id, side)
        r.props = []     # dict(obj, sprite, state, pos, note, replaces)
        r.rails = []     # (axis 'x'|'y', fixed, start, end)  module count derived
        r.clocks = []    # N wall module indices
        r.notes = []
        r.void = []
        R.append(r)
        return r

    # ---------------------------------------------------------------- 1 arrival_platform
    r = mk(1, 'arrival_platform', 14, 10, 'dark')
    r.areas = [('Platform edge, SW trench side (`y = 9`)', rect(0, 9, 13, 9), 'amber'),
               ('Platform edge, SE side (`x = 13`, door tile `(13,5)` excluded)', [p for p in rect(13, 0, 13, 8) if p != (13, 5)], 'amber')]
    r.doors = [('door_exit_east', 'E')]
    r.clocks = [2, 5]
    r.props = [
        dict(obj='(decor) platform bench', sprite='bench', state='idle', pos=(352, 120), note='ROOM_GRAPH/target sheet: bench at tile `(4,2)` (cell centre); no greybox node, add `StaticBody2D` footprint 40×12', repl='none (new)'),
        dict(obj='global.pocket_watch (`pocket_watch_pickup`)', sprite='watch', files=['ch01_prop_pocket_watch_idle'], state='present -> hidden on pickup', pos=r.pos['pocket_watch_pickup'], note='16x16 micro pickup; node position = pivot (bible 1.3 micro prop)', repl='none'),
        dict(obj='(set-piece) stalled Mag-Transit car', sprite='car', files=['ch01_prop_transit_car_stalled_idle'], state='idle (static)', pos=(251, 210), note='tile-space centre `(7, 10.65)`: body in the SW trench just beyond the amber lip (`y = 10 .. 11.3`), long axis along `+x`; **pivot = footprint centre**, not (W/2,H-8) (appendix A.3). No node/collision (set dressing; add a `StaticBody2D` only if the lip is ever walkable)', repl='none (new)'),
    ]

    # ---------------------------------------------------------------- 2 concourse_west
    r = mk(2, 'concourse_west', 16, 12, 'dark')
    r.areas = [('Turnstile approach lane (amber cue)', rect(3, 4, 3, 6), 'amber')]
    r.doors = [('door_entry_west', 'W'), ('door_exit_east', 'E')]
    r.clocks = [3]
    p = r.pos
    r.props = [
        dict(obj='turnstile_gate', sprite='turnstile', files=['ch01_prop_turnstile_gate_collapsed', 'ch01_prop_turnstile_gate_open'], state='collapsed / open', pos=p['turnstile_gate'], note='`prop_turnstile_gate` (Tier 2, delivered); pedestal footprint centred on the node; Area2D + `Blocker` stay', repl='none'),
        dict(obj='support_pillar_01', sprite='pillar', state='idle', pos=p['support_pillar_01'], note='free-standing column; **sprite pivot = node position + (0, 8)** so the 0.75-tile footprint centres on the cell', repl='none (collision already in `PillarCollision`)', off=(0, 8)),
        dict(obj='reset_anchor_01', sprite='console', state='idle', pos=p['reset_anchor_01'], note='sole state; the `[E]` prompt provides feedback', repl='none'),
        dict(obj='call_box_09', sprite='callbox', state='idle -> ringing during Beat 03 call', pos=p['call_box_09'], note='wall fixture on the W wall: module `j = 1` (y 2..3), mount offset (0, -14)', repl='none', mount=('W', 1)),
        dict(obj='doc_evac_notice', sprite='clip', state='idle (hide when read, per interactable)', pos=p['doc_evac_notice'], note='', repl='none'),
        dict(obj='(decor) concourse bench', sprite='bench', state='idle', pos=(448, 184), note='tile `(11,3)` cell centre; optional dressing', repl='none (new)'),
    ]

    # ---------------------------------------------------------------- 3 maintenance_bay
    r = mk(3, 'maintenance_bay', 14, 10, 'concrete')
    r.areas = [('Shutter drain lane', rect(7, 0, 9, 9), 'grating'),
               ('Power feed to the shutter (`+x` run; **off** until `CH1-PZ-002` SOLVED, then **on**)', rect(2, 4, 6, 4), 'conduit_off')]
    r.doors = [('door_entry_west', 'W'), ('door_exit_east', 'E')]
    p = r.pos
    r.props = [
        dict(obj='fire_shutter', sprite='shutter', files=['ch01_prop_fire_shutter_closed', 'ch01_prop_fire_shutter_raised'], state='closed / raised', pos=p['fire_shutter'], note='Tier 2 `prop_fire_shutter` (64×64)', repl='none'),
        dict(obj='counterweight_gear', sprite='gear', files=['ch01_prop_counterweight_gear_idle', 'ch01_prop_counterweight_gear_slipping', 'ch01_prop_counterweight_gear_frozen'], state='idle / slipping / frozen', pos=p['counterweight_gear'], note='Tier 2 `prop_counterweight_gear`', repl='none'),
        dict(obj='reset_anchor_01', sprite='console', state='idle', pos=p['reset_anchor_01'], note='', repl='none'),
        dict(obj='doc_tech_log', sprite='clip', state='idle', pos=p['doc_tech_log'], note='workbench pickup', repl='none'),
    ]

    # ---------------------------------------------------------------- 4 security_crossing
    r = mk(4, 'security_crossing', 16, 12, 'concrete')
    r.areas = [('Trench (void, **no tile**; black `#0A0D14` backing)', rect(9, 0, 9, 11), None),
               ('Trench edge, west lip (`x = 8`, bridge rows `y = 6..7` excluded)', [q for q in rect(8, 0, 8, 11) if q[1] not in (6, 7)], 'amber'),
               ('Trench edge, east lip (`x = 10`, bridge rows `y = 6..7` excluded)', [q for q in rect(10, 0, 10, 11) if q[1] not in (6, 7)], 'amber'),
               ('Echo-recorder deck', rect(4, 8, 6, 10), 'grating'),
               ('Pressure-switch power feed (**off**; **on** while `pressure_switch_01` is held / PZ-003 latched)', rect(6, 9, 8, 9), 'conduit_off')]
    r.doors = [('door_entry_west', 'W'), ('door_exit_east', 'E')]
    r.rails = [('y', 9, 0, 6), ('y', 9, 8, 12), ('y', 10, 0, 6), ('y', 10, 8, 12)]
    p = r.pos
    r.props = [
        dict(obj='pressure_switch_01', sprite='pswitch', files=['ch01_prop_pressure_switch_released', 'ch01_prop_pressure_switch_pressed'], state='released / pressed', pos=p['pressure_switch_01'], note='Tier 2 `prop_pressure_switch`', repl='none'),
        dict(obj='security_gate_01', sprite='secgate', files=['ch01_prop_security_gate_closed', 'ch01_prop_security_gate_open'], state="`gate_state` &\"closed\" -> `ch01_prop_security_gate_closed`; &\"open\" -> `_open` (`passage_blocked` mirrors it)", pos=p['security_gate_01'], note='barrier spans the lane along the `y` axis (the lane runs `+x`); pivot = node position', repl='none'),
        dict(obj='bridge_platform_01', sprite='bridge', files=['ch01_prop_bridge_platform_retracted', 'ch01_prop_bridge_platform_extended'], state="`platform_state` &\"retracted\" -> `_retracted`; &\"extended\" -> `_extended` (`walkable` mirrors it)", pos=p['bridge_platform_01'], off=(0, 8), note='spans the trench tile `(9,6)` along `+x` (deck 2 tiles long, 1 wide); pivot = node + (0, 8) = cell centre; `TrenchVisual` stays as the void backing; Elias (z 10) draws above the deck (z 8)', repl='`TrenchVisual` stays as the void backing'),
        dict(obj='transit_pass_pickup', sprite='clip', state='idle', pos=p['transit_pass_pickup'], note='security desk pickup (progression)', repl='none'),
        dict(obj='reset_anchor_01', sprite='console', state='idle', pos=p['reset_anchor_01'], note='', repl='none'),
        dict(obj='pa_speaker', sprite='horn', files=['ch01_prop_pa_speaker_idle'], state='idle (audio emitter only)', pos=p['pa_speaker'], mount=('N', 0, -34), note='wall horn on N-wall module `k = 0`, offset (0, -34); the node at `(320,60)` stays', repl='none'),
    ]

    # ---------------------------------------------------------------- 5 waiting_lounge
    r = mk(5, 'waiting_lounge', 12, 10, 'dark')
    r.areas = [('Platform-window edge (`y = 9`)', rect(0, 9, 11, 9), 'amber')]
    r.doors = [('door_entry_west', 'W'), ('door_exit_north', 'N')]
    r.clocks = [2]
    p = r.pos
    r.props = [
        dict(obj='trace_bench', sprite='bench', state='idle', pos=p['trace_bench'], note='Mira `Trace` anchor bench; collision/`Interactable` unchanged', repl='none'),
        dict(obj='audio_mira_01', sprite='clip', state='idle', pos=p['audio_mira_01'], note='audio-log pickup', repl='none'),
    ]

    # ---------------------------------------------------------------- 6 signal_control
    r = mk(6, 'signal_control', 16, 12, 'concrete')
    r.areas = [('Capacitor island', rect(6, 4, 10, 7), 'grating'),
               ('Bus feed east of the island (`+x` run; **off** until `bus_powered = true`)', rect(11, 6, 14, 6), 'conduit_off')]
    r.doors = [('door_entry_south', 'S'), ('door_exit_north', 'N')]
    r.clocks = [1]
    r.rails = [('x', 8, 0, 12), ('x', 3, [3, 5, 7, 9, 11, 13, 14])]
    p = r.pos
    r.props = [
        dict(obj='surge_capacitor', sprite='capacitor', files=['ch01_prop_surge_capacitor_discharged', 'ch01_prop_surge_capacitor_charged', 'ch01_prop_surge_capacitor_frozen_discharged', 'ch01_prop_surge_capacitor_frozen_charged'], state='`(charge_state, is_frozen())`: (`&"discharged"`, false) -> `_discharged`; (`&"charged"`, false) -> `_charged`; (`&"discharged"`, true) -> `_frozen_discharged`; (`&"charged"`, true) -> `_frozen_charged` (= `is_stabilized()` while `bus_powered`)', pos=p['surge_capacitor'], note='`prop_surge_capacitor` (64×64). The old single `_frozen` file is deprecated (kept until TLF-041 has switched, do not use for new work)', repl='none'),
        dict(obj='breaker_a', sprite='lever_off', state="`lever_state` `&\"open\"` -> `_off`; `&\"engaged\"` -> `_on` (auto-releases after 180 ticks)", pos=p['breaker_a'], note='stands at the foot of the W wall (`x = 0`): **wall-mounted, `Wall_Fixtures` 7**; badge A child at (3, -8)', repl='none', badge='a', zlayer=(7, 'Wall_Fixtures')),
        dict(obj='breaker_b', sprite='lever_off', state="`lever_state` `&\"open\"` -> `_off`; `&\"engaged\"` -> `_on`", pos=p['breaker_b'], note='free-standing at the E edge (`x = 15`, no wall drawn): **`YSort_Actors` 10** (ADR-019); badge B child at (3, -8)', repl='none', badge='b', zlayer=(10, 'YSort_Actors')),
        dict(obj='intercom', sprite='callbox', state='idle', pos=p['intercom'], note='Operator intercom (shares `prop_call_box_phone`); node sits at the capacitor lane, so the sprite mounts on the N wall, module `k = 6`, offset (0, -14) (OQ-4)', repl='none', mount=('N', 6)),
        dict(obj='reset_anchor_01', sprite='console', state='idle', pos=p['reset_anchor_01'], note='', repl='none'),
        dict(obj='vestibule_door (`door_exit_north`)', sprite='arch_n', state='locked / open -> `[■]` / `[▲]` transom glyph', pos=p['vestibule_door'], note='archway is the visual of the door; keep `Blocker` collision', repl='`Archway` n/a (greybox has none)'),
    ]

    # ---------------------------------------------------------------- 7 upper_vestibule
    r = mk(7, 'upper_vestibule', 14, 14, 'dark')
    r.areas = [('Lever A feed (`+x`; **on** once `junction_lever_a` pulled)', rect(4, 7, 6, 7), 'conduit_off'),
               ('Lever B feed (**on** once `junction_lever_b` pulled; `-x` = flip_h + flip_v)', rect(8, 7, 10, 7), 'conduit_off')]
    r.doors = [('door_south', 'S'), ('door_west', 'W'), ('door_east', 'E'), ('door_north', 'N')]
    r.clocks = [3]
    p = r.pos
    r.props = [
        dict(obj='route_board', sprite='routeboard', files=['ch01_prop_route_board_state0', 'ch01_prop_route_board_state1', 'ch01_prop_route_board_state2'], state="derived from the two levers' `relay_state`: A `&\"loop\"` + B `&\"niche\"` -> `_state0`; A `&\"uncoupled\"` + B `&\"niche\"` -> `_state1`; A `&\"uncoupled\"` + B `&\"atrium\"` -> `_state2`", pos=p['route_board'], note='`route_board` is a plain `Interactable` (no state of its own); free-standing, board faces SW', repl='none'),
        dict(obj='junction_lever_a', sprite='lever_off', state="`relay_state` `&\"loop\"` (= `state_a`) -> `_off`; `&\"uncoupled\"` (= `state_b`) -> `_on`", pos=p['junction_lever_a'], note='free-standing: **`YSort_Actors` 10** (ADR-019); badge A child at (3, -8)', repl='none', badge='a', zlayer=(10, 'YSort_Actors')),
        dict(obj='junction_lever_b', sprite='lever_off', state="`relay_state` `&\"niche\"` (= `state_a`) -> `_off`; `&\"atrium\"` (= `state_b`) -> `_on`", pos=p['junction_lever_b'], note='free-standing: **`YSort_Actors` 10**; badge B child at (3, -8)', repl='none', badge='b', zlayer=(10, 'YSort_Actors')),
        dict(obj='reset_anchor_01', sprite='console', state='idle', pos=p['reset_anchor_01'], note='spatial reset pedestal', repl='none'),
    ]

    # ---------------------------------------------------------------- 8 vestibule_niche
    r = mk(8, 'vestibule_niche', 6, 6, 'dark', cracked=False)
    r.doors = [('door_in', 'W'), ('door_out', 'N')]
    p = r.pos
    r.props = [
        dict(obj='door_out grille', sprite='rail', state='idle', pos=p['door_out'], note='iron grille = `wall_railing_iron` laid over `archway_frame_n` (`traversable = false`); keep `GrilleBlocker`', repl='none', ov=True),
        dict(obj='doc_index_plaque', sprite='clip', state='idle', pos=p['doc_index_plaque'], note='ELYSIUM indexing plaque pickup', repl='none'),
    ]

    # ---------------------------------------------------------------- 9 station_atrium
    r = mk(9, 'station_atrium', 16, 14, 'dark')
    r.areas = [('Dais steps under the north exit', rect(6, 1, 10, 1) + rect(7, 2, 9, 2), 'step')]
    r.doors = [('door_entry_south', 'S'), ('door_exit_north', 'N')]
    r.clocks = [3]
    p = r.pos
    r.props = [
        dict(obj='Clock (master clock)', sprite='clock', state='idle', pos=p['Clock'], note='render **2×** integer scale (64×48) for the monumental atrium clock (metadata 2.8)', repl='existing `Clock` Sprite2D', scale2=True),
        dict(obj='dispatch_terminal', sprite='dispatch', files=['ch01_prop_dispatch_terminal_idle', 'ch01_prop_dispatch_terminal_active'], state="the node is a `ReadableDocument` with no state field; `_idle` until narrative flag `ch01.flag.ledger_2359_revealed` is true (set at the Beat 09 revelation, page 2 read), then `_active`", pos=p['dispatch_terminal'], note='pivot = node position; the 2x master clock above it is the existing clock sprite scaled 2x (no separate sprite)', repl='none'),
        dict(obj='(decor) atrium bench W', sprite='bench', state='idle', pos=(240, 176), note='tile `(4,9)` cell centre; optional dressing', repl='none (new)'),
        dict(obj='(decor) atrium bench E', sprite='bench', state='idle', pos=(432, 208), note='tile `(12,5)` cell centre; optional dressing', repl='none (new)'),
    ]

    # ---------------------------------------------------------------- 10 street_exit
    r = mk(10, 'street_exit', 12, 10, 'dark')
    r.areas = [('Surface stairs (`StairsAccent` polygon = tiles x 4..7, y 2..3)', rect(4, 2, 7, 3), 'step')]
    r.doors = [('door_entry_south', 'S')]
    p = r.pos
    r.props = [
        dict(obj='plaza_payphone', sprite='callbox', state='idle -> ringing at `trigger_outro`', pos=p['plaza_payphone'], note='Beat 10 payphone (shares `prop_call_box_phone`)', repl='none'),
    ]
    return R


def cracked_tiles(r):
    taken = set()
    for _, tiles, t in r.areas:
        if t: taken |= set(tiles)
    if r.key == 'security_crossing':
        taken |= set(rect(9, 0, 9, 11))
    out = []
    if r.cracked and r.base == 'dark':
        for y in range(r.H):
            for x in range(r.W):
                if (x * 5 + y * 3) % 11 == 0 and (x, y) not in taken:
                    out.append((x, y))
    return out


def wall_pivots(r):
    n = [(336 + 32 * k, 72 + 16 * k) for k in range(r.W // 2)]
    w = [(304 - 32 * j, 72 + 16 * j) for j in range(r.H // 2)]
    return n, w


def rail_modules(r):
    out = []
    for axis, fixed, *rest in r.rails:
        if isinstance(rest[0], list):
            starts = rest[0]
        else:
            a, b = rest
            starts = [a + 2 * k for k in range(int(round((b - a) / 2.0)))]
        for s in starts:
            if axis == 'x':
                p0 = px(s, fixed); out.append((axis, (p0[0] + 16, p0[1] + 8)))
            else:
                p0 = px(fixed, s); out.append((axis, (p0[0] - 16, p0[1] + 8)))
    return out
