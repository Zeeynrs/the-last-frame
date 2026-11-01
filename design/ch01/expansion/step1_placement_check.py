"""Step 1 placement checker (TLF-047 phase 2). Run: python design/ch01/expansion/step1_placement_check.py > step1_placement_check.txt Tile -> px (ROOM_GRAPH 1): px_x = 320+(x-y)*16, px_y = 64+(x+y)*8.
Targeting rules mirrored from code:
  use  : Player.choose_best_interactable, radius 36, nearest TARGETABLE (use != unsupported, or any watch ability supported)
  watch: PocketWatch.choose_watch_target, radius 96, nearest candidate that supports the selected ability, else nearest targetable
"""
import math, sys


def px(t):
    x, y = t
    return (320 + (x - y) * 16, 64 + (x + y) * 8)


def d(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


class Obj:
    def __init__(self, name, tile=None, pxy=None, caps=''):
        self.name = name
        self.p = pxy if pxy is not None else px(tile)
        self.tile = tile
        self.caps = caps  # U use-targetable, T trace, R rewind, F freeze

    def targetable(self):
        return bool(self.caps)


def pick(objs, frm, action):
    """action: 'use' or watch ability 't','r','f'"""
    if action == 'use':
        pool = [o for o in objs if o.targetable() and d(frm, o.p) <= 36]
        pool = [o for o in pool]
        if not pool:
            return None, None
        o = min(pool, key=lambda o: (round(d(frm, o.p), 3), o.name))
        return o, d(frm, o.p)
    cap = action.upper()
    pool = [o for o in objs if o.targetable() and d(frm, o.p) <= 96]
    sup = [o for o in pool if cap in o.caps]
    pool = sup if sup else pool
    if not pool:
        return None, None
    o = min(pool, key=lambda o: (round(d(frm, o.p), 3), o.name))
    return o, d(frm, o.p)


def check(room, objs, stands, bad):
    print(f'--- {room}')
    for spot, action, expect in stands:
        is_tile = spot[0] < 40
        frm = px(spot) if is_tile else spot
        o, dist = pick(objs, frm, action)
        ok = (o is not None and o.name == expect)
        if not ok:
            bad.append((room, spot, action, expect, o.name if o else None))
        label = f"tile {spot}" if is_tile else "px"
        print(f"  stand {label:12s} {str(frm):12s} {action:4s} -> {o.name if o else None} ({dist if dist is None else round(dist, 1)}) expect {expect} {'OK' if ok else 'FAIL'}")


def spacing(room, objs, a_caps, b_caps=None, minimum=36):
    """pairs of objects closer than `minimum`"""
    out = []
    for i, a in enumerate(objs):
        for b in objs[i + 1:]:
            if a_caps and not (set(a.caps) & set(a_caps)) and not (b_caps and set(a.caps) & set(b_caps)):
                pass
            dd = d(a.p, b.p)
            if dd < minimum:
                out.append((a.name, b.name, round(dd, 1)))
    return out


bad = []

# ---------------- R1 Arrival Platform 14x10
R1 = [
    Obj('pocket_watch_pickup', pxy=(368, 168), caps='U'),
    Obj('selector_line', (7, 1), caps='U'), Obj('selector_platform', (9, 1), caps='U'), Obj('selector_car', (11, 1), caps='U'),
    Obj('release_lever', (13, 2), caps='U'),
    Obj('doc_last_service', (1, 3), caps='U'),
    Obj('n01_conductor', (10, 8), caps='T'), Obj('n02_student', (5, 8), caps='T'), Obj('n03_old_man', (4, 2), caps='T'),
    Obj('n04_cleaner', (12, 7), caps='T'),
]
check('R1 arrival_platform', R1, [
    ((7, 2), 'use', 'selector_line'), ((9, 2), 'use', 'selector_platform'), ((11, 2), 'use', 'selector_car'),
    ((13, 3), 'use', 'release_lever'),
    ((1, 4), 'use', 'doc_last_service'),
    ((10, 7), 't', 'n01_conductor'), ((5, 7), 't', 'n02_student'), ((4, 3), 't', 'n03_old_man'), ((12, 6), 't', 'n04_cleaner'),
    ((8, 6), 'use', 'pocket_watch_pickup'),
], bad)
print('  close pairs (<36):', spacing('R1', R1, None))

# ---------------- R2 Concourse West 16x12
R2 = [
    Obj('turnstile_gate', pxy=(272, 120), caps='UR'), Obj('turnstile_trace_anchor', pxy=(280, 124), caps='T'),
    Obj('n05_courier', (1, 6), caps='T'), Obj('conduit_01', (2, 8), caps='UR'),
    Obj('support_pillar_01', pxy=(384, 176), caps='U'), Obj('reset_anchor_01', pxy=(256, 144), caps='U'),
    Obj('call_box_09', pxy=(272, 96), caps='U'), Obj('doc_evac_notice', pxy=(352, 176), caps='U'),
    Obj('dial_line', (9, 1), caps='R'), Obj('dial_platform', (11, 1), caps='R'), Obj('dial_time', (13, 1), caps='R'),
    Obj('ticket_validator', (14, 2), caps='U'), Obj('reset_anchor_02', (8, 1), caps='U'),
    Obj('doc_ticket_terms', (9, 9), caps='U'),
    Obj('n06_red_coat', (13, 6), caps='T'), Obj('n07_briefcase', (13, 8), caps='T'), Obj('n08_father', (13, 10), caps='T'), Obj('n09_teen', (11, 9), caps='T'),
]
check('R2 concourse_west', R2, [
    ((256, 112), 'r', 'turnstile_gate'), ((256, 112), 't', 'n05_courier'),
    ((248, 116), 't', 'n05_courier'), ((264, 116), 't', 'turnstile_trace_anchor'),
    ((208, 136), 'r', 'conduit_01'), ((256, 112), 'r', 'turnstile_gate'),
    ((272, 104), 'use', 'call_box_09'),
    ((9, 2), 'r', 'dial_line'), ((11, 2), 'r', 'dial_platform'), ((13, 2), 'r', 'dial_time'),
    ((14, 3), 'use', 'ticket_validator'),
    ((8, 2), 'use', 'reset_anchor_02'),
    ((14, 6), 't', 'n06_red_coat'), ((14, 8), 't', 'n07_briefcase'), ((14, 10), 't', 'n08_father'), ((11, 10), 't', 'n09_teen'),
    ((9, 10), 'use', 'doc_ticket_terms'),
], bad)
print('  close pairs (<36):', spacing('R2', R2, None))

# ---------------- R3 Maintenance Bay 14x10
R3 = [
    Obj('fire_shutter', pxy=(384, 160), caps='UR'), Obj('counterweight_gear', pxy=(384, 112), caps='UF'),
    Obj('reset_anchor_01', pxy=(288, 144), caps='U'), Obj('doc_tech_log', pxy=(288, 192), caps='U'),
    Obj('hatch_01', (3, 3), caps='UF'), Obj('hatch_plate_01', (2, 6), caps=''), Obj('bell_plate_01', (1, 8), caps=''),
    Obj('hatch_residue', (2, 6), caps='T'),
    Obj('doc_hatch_chart', (2, 7), caps='U'), Obj('n11_hatch_tech', (2, 3), caps='T'),
    Obj('inner_shutter', (11, 4), caps='UR'), Obj('doc_inner_shutter_plate', (11, 1), caps='U'), Obj('gear_residue', (5, 2), caps='T'),
]
check('R3 maintenance_bay', R3, [
    ((256, 128), 'f', 'hatch_01'), ((256, 128), 't', 'hatch_residue'), ((2, 4), 't', 'n11_hatch_tech'),
    ((224, 128), 'use', 'doc_hatch_chart'), ((4, 7), 'use', 'reset_anchor_01'),
    ((6, 4), 'r', 'fire_shutter'), ((6, 4), 'f', 'counterweight_gear'),
    ((10, 4), 'r', 'inner_shutter'), ((10, 4), 'f', 'counterweight_gear'),
    ((9, 4), 'r', 'fire_shutter'), ((11, 2), 'use', 'doc_inner_shutter_plate'), ((6, 4), 't', 'gear_residue'),
], bad)
print('  close pairs (<36):', spacing('R3', R3, None))

# ---------------- R4 Security Crossing 16x12
R4 = [
    Obj('pressure_switch_01', pxy=(256, 176), caps='U'), Obj('echo_recorder_pedestal', (4, 8), caps='U'),
    Obj('security_gate_01', pxy=(416, 176), caps='U'), Obj('bridge_platform_01', pxy=(368, 184), caps='U'),
    Obj('transit_pass_pickup', pxy=(336, 104), caps='U'), Obj('reset_anchor_01', pxy=(336, 168), caps='U'),
    Obj('n13_guard', (4, 3), caps='T'), Obj('doc_guard_log', (2, 4), caps='U'),
    Obj('card_reader_01', (11, 7), caps='U'), Obj('staff_barrier_01', (12, 5), caps='U'),
]
check('R4 security_crossing', R4, [
    ((4, 9), 'use', 'echo_recorder_pedestal'),
    ((4, 4), 't', 'n13_guard'), ((3, 4), 'use', 'doc_guard_log'), ((3, 2), 'use', 'transit_pass_pickup'),
    ((11, 8), 'use', 'card_reader_01'),
], bad)
print('  close pairs (<36):', spacing('R4', R4, None))

# ---------------- R6 Signal Control 16x12
R6 = [
    Obj('surge_capacitor', pxy=(368, 168), caps='URF'), Obj('breaker_a', pxy=(160, 144), caps='U'), Obj('breaker_b', pxy=(544, 192), caps='U'),
    Obj('reset_anchor_01', pxy=(352, 192), caps='U'), Obj('intercom', pxy=(528, 154), caps='U'),
    Obj('breaker_c', (0, 6), caps='U'), Obj('doc_bus_chart', (0, 3), caps='U'), Obj('n20_engineer', (6, 7), caps='T'),
]
check('R6 signal_control', R6, [
    ((1, 6), 'use', 'breaker_c'), ((1, 3), 'use', 'doc_bus_chart'), ((6, 8), 't', 'n20_engineer'),
    ((1, 10), 'use', 'breaker_a'), ((8, 6), 'r', 'surge_capacitor'),
], bad)
print('  close pairs (<36):', spacing('R6', R6, None))

# ---------------- R7 Upper Vestibule 14x14
R7 = [
    Obj('route_board', pxy=(336, 168), caps='UT'), Obj('junction_lever_a', pxy=(256, 144), caps='U'), Obj('junction_lever_b', pxy=(384, 208), caps='U'),
    Obj('reset_anchor_01', pxy=(272, 200), caps='U'),
    Obj('standby_plate_01', (2, 11), caps=''), Obj('junction_lever_c', (6, 2), caps='U'), Obj('doc_relay_memo', (13, 3), caps='U'),
    Obj('n21_tourist', (5, 4), caps='T'),
]
check('R7 upper_vestibule', R7, [
    ((4, 7), 'use', 'junction_lever_a'), ((10, 7), 'use', 'junction_lever_b'), ((6, 3), 'use', 'junction_lever_c'),
    ((7, 7), 't', 'route_board'), ((5, 5), 't', 'n21_tourist'), ((12, 3), 'use', 'doc_relay_memo'),
], bad)
print('  close pairs (<36):', spacing('R7', R7, None))
print('\nFAILS:', bad)
for o in R1 + R2 + R3 + R4 + R6 + R7:
    if o.tile:
        print(f'{o.name:26s} tile {o.tile} px {o.p}')
