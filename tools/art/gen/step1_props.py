"""Step 1 puzzle & station props (TLF-057, ART_WISHLIST_STEP1.md Section B — 57 assets).

Visual direction (Sol, Art Director, 2026-11-05):
- One worn steel station hardware family (indices 11..15 + 00 1px outer silhouette outline + 01 compact down-right shadow).
- Mechanical geometry and glyphs carry state in greyscale:
  - Selector panel: LINE (circle / diamond / triangle), PLATFORM (1 / 2 / 3 bars), CAR (middle / rear / front window-position train silhouettes) + 3-position mechanical switch.
  - Release lever: idle (rest), buzzing (X glyph + jiggle ticks), accepted (>>> glyph + shifted handle).
  - Split-flap dials: keep LINE / PLATFORM / TIME frame header glyphs separate from font-rendered label window; jammed state shows tilted/misaligned flap + diagonal seam gap.
  - Ticket validator & card reader: reject/denied = X glyph; accepted = >>> chevron glyph.
  - Open doors (platform gate, staff door, service hatch, inner shutter, staff barrier): expose a clear transparent portal with shutter/bars retracted, not just a colour change. Shared 32x64 housing with distinct top-header plate marks.
  - Service hatch: frozen_open AND frozen_closed retain their actual aperture state (open portal vs closed slab) plus a brass [o] lock ring and Freeze corner brackets.
  - Conduit: fallen (sag/break across floor with severed wires) vs mounted (straight horizontal pipe bolted to top brackets).
  - Floor plates A & B: carry embossed A / B letters and clear 2px rim depression when pressed.
  - Standby plate: empty = hollow diamond/footprint; held = depressed + solid double footprint.
  - Alarm plate: bell glyph + radiating strike marks when ringing.
  - Bell icon: 8x8 bell silhouette; ringing adds outer strike marks.
  - Echo pedestal: used state adds persistent second clock-hand + paired twin mark on front apron.
  - Breaker C: intact lamp ring + upper/lower lever detent; browned_out has a visibly broken/split lamp ring + fault detent.
  - Dead relay C: visibly disconnected cable lug with air gap in both idle and shake states; shake adds tilted handle + shake ticks.
  - Ticket-terms notice: plaque + paper silhouette with ruled lines and no invented clue text.
"""
import os
from lib import *

O = 0
SH = 1
G0, G1, G2, G3, G4 = 11, 12, 13, 14, 15


def _shadow_rect(w, h, x0, y0, x1, y1):
    """Compact down-right floor shadow Layer biased +1px X, +1px Y."""
    S = Layer(w, h, 'Cast_Shadow')
    S.rect(min(w - 1, x0 + 1), min(h - 1, y0 + 1), min(w - 1, x1 + 1), min(h - 1, y1 + 1), SH)
    return S


def _outline_from(w, h, *layers):
    """Build 1px #0A0D14 outer silhouette outline around the union mask of `layers`."""
    OL = Layer(w, h, 'Silhouette_Outline')
    mask = set()
    for L in layers:
        mask |= L.mask()
    for (x, y) in sorted(mask):
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if (nx, ny) not in mask and 0 <= nx < w and 0 <= ny < h:
                OL.put(nx, ny, O)
    return OL


def _steel_panel(L, x0, y0, x1, y1, bevel_light=G3, mid=G2, shad=G1, dark=G0):
    """Draw a top-left-lit beveled worn-steel rectangular housing."""
    L.rect(x0, y0, x1, y1, mid)
    L.hline(x0, x1, y0, bevel_light)
    L.vline(x0, y0, y1, bevel_light)
    L.hline(x0, x1, y1, dark)
    L.vline(x1, y0, y1, shad)
    L.put(x0, y0, G4)
    # Corner rivets
    for rx, ry in ((x0 + 1, y0 + 1), (x1 - 1, y0 + 1), (x0 + 1, y1 - 1), (x1 - 1, y1 - 1)):
        if x0 < rx < x1 and y0 < ry < y1:
            L.put(rx, ry, dark)


# ==============================================================================
# 1. SO-01 SELECTOR PANELS (9 assets, 32 x 48 px, pivot (16, 40))
# ==============================================================================

def build_selector_panel(kind, pos):
    """kind in ('line', 'platform', 'car'), pos in (0, 1, 2). Size 32 x 48, pivot (16, 40)."""
    w, h = 32, 48
    sh = _shadow_rect(w, h, 5, 38, 26, 42)
    B = Layer(w, h, 'Housing_Base')
    D = Layer(w, h, 'Control_And_Glyph')

    # Main worn-steel cabinet (x=5..26, y=4..40)
    _steel_panel(B, 5, 4, 26, 40)
    # Plinth base (x=4..27, y=38..41)
    _steel_panel(B, 4, 38, 27, 41, bevel_light=G2, mid=G1, shad=G0, dark=O)
    # Header bar (x=6..25, y=5..8)
    B.rect(6, 5, 25, 8, G1)
    B.hline(6, 25, 8, G0)
    # Distinct control-index pips on top-left header (1 pip = LINE, 2 pips = PLATFORM, 3 pips = CAR)
    npips = {'line': 1, 'platform': 2, 'car': 3}[kind]
    for i in range(npips):
        D.put(8 + i * 2, 6, G4)
        D.put(8 + i * 2, 7, 25)

    # Recessed display window (x=7..24, y=10..22)
    B.rect(7, 10, 24, 22, O)
    B.rect(8, 11, 23, 21, 2)  # dark navy-slate display backing
    B.hline(7, 24, 10, G0)
    B.vline(7, 10, 22, G0)
    B.hline(7, 24, 22, G3)
    B.vline(24, 10, 22, G3)

    # Glyph inside display window (x=8..23, y=11..21)
    # Note (Sol Appendix B.3): all 3 positions use the identical value/colour hierarchy — do not bake the solution into a special highlight.
    if kind == 'line':
        if pos == 0:
            # Pos 0: CIRCLE glyph (Central Line)
            for x in range(13, 19):
                D.put(x, 12, G4); D.put(x, 20, G3)
            for y in range(14, 19):
                D.put(11, y, G4); D.put(20, y, G3)
            for (x, y) in ((12, 13), (19, 13), (12, 19), (19, 19)):
                D.put(x, y, G4)
        elif pos == 1:
            # Pos 1: DIAMOND glyph (Harbour Line — same G4/G3 hierarchy as pos 0 and pos 2)
            pts = [
                (15, 12), (16, 12),
                (14, 13), (17, 13),
                (13, 14), (18, 14),
                (12, 15), (19, 15),
                (11, 16), (20, 16),
                (12, 17), (19, 17),
                (13, 18), (18, 18),
                (14, 19), (17, 19),
                (15, 20), (16, 20),
            ]
            for (x, y) in pts:
                D.put(x, y, G4 if y <= 16 else G3)
        else:
            # Pos 2: TRIANGLE glyph (Ring Line)
            D.put(15, 12, G4); D.put(16, 12, G4)
            D.put(14, 13, G4); D.put(17, 13, G3)
            D.put(13, 14, G4); D.put(18, 14, G3)
            D.put(13, 15, G4); D.put(18, 15, G3)
            D.put(12, 16, G4); D.put(19, 16, G3)
            D.put(12, 17, G4); D.put(19, 17, G3)
            D.put(11, 18, G4); D.put(20, 18, G3)
            D.hline(11, 20, 19, G4)
            D.hline(11, 20, 20, G3)

    elif kind == 'platform':
        # 1 / 2 / 3 bold vertical platform bars with identical G4/G3 value hierarchy across all 3 positions
        count = pos + 1
        col_hi, col_lo = G4, G3
        if count == 1:
            D.rect(14, 13, 17, 19, col_hi)
            D.vline(17, 13, 19, col_lo)
        elif count == 2:
            D.rect(11, 13, 14, 19, col_hi)
            D.rect(17, 13, 20, 19, col_hi)
            D.vline(14, 13, 19, col_lo)
            D.vline(20, 13, 19, col_lo)
        else:
            for bx in (10, 15, 20):
                D.rect(bx, 13, bx + 1, 19, col_hi)
                D.vline(bx + 2, 13, 19, col_lo)

    elif kind == 'car':
        # 3-car train silhouette across x=9..22, y=13..19:
        # Three 4px car bays at x=9..12 (REAR), x=14..17 (MIDDLE), x=19..22 (FRONT)
        # Active car is raised 2px higher (y=12..18), bright G4 body with dark window cut-out & overhead pointer!
        D.hline(9, 22, 19, G2)  # track rail under train
        bays = [(9, 12, 1), (14, 17, 0), (19, 22, 2)]  # (x0, x1, pos_idx: rear=1, mid=0, front=2)
        for bx0, bx1, bpos in bays:
            active = (pos == bpos)
            top_y = 12 if active else 14
            col_body = G4 if active else G1
            col_win = O if active else 2
            D.rect(bx0, top_y, bx1, 18, col_body)
            if active:
                D.rect(bx0 + 1, top_y + 1, bx1 - 1, top_y + 3, col_win)
                D.hline(bx0 + 1, bx1 - 1, top_y - 1, 25)
        # Front nose bevel on right car (x=23, y=15..18)
        D.vline(23, 15, 18, G3 if pos == 2 else G2)

    # Lower mechanical 3-position control bezel (x=7..24, y=25..36)
    _steel_panel(B, 7, 25, 24, 36, bevel_light=G2, mid=G1, shad=G0, dark=O)
    # Three detent ticks at x=10 (pos0), x=15..16 (pos1), x=21 (pos2)
    det_x = [10, 15, 21]
    for i, dx in enumerate(det_x):
        c = 26 if i == pos else G0
        D.rect(dx, 26, dx + 1, 27, c)
    # Mechanical selector handle/knob shifted clearly to left (pos0), center (pos1), or right (pos2)
    kx = det_x[pos]
    D.rect(9, 30, 22, 32, O)  # horizontal slide/rotary slot
    D.rect(kx - 1, 28, kx + 2, 34, G3)
    D.hline(kx - 1, kx + 2, 28, G4)
    D.vline(kx + 2, 28, 34, G1)
    D.rect(kx, 30, kx + 1, 32, 25)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 2. SO-01 RELEASE LEVER (3 assets, 24 x 36 px, pivot (12, 32))
# ==============================================================================

def build_release_lever(state):
    """state in ('idle', 'buzzing', 'accepted'). Size 24 x 36, pivot (12, 32)."""
    w, h = 24, 36
    sh = _shadow_rect(w, h, 4, 29, 19, 33)
    B = Layer(w, h, 'Pedestal_Base')
    D = Layer(w, h, 'Lever_And_Glyph')

    _steel_panel(B, 4, 5, 19, 31)
    _steel_panel(B, 3, 29, 20, 32, bevel_light=G2, mid=G1, shad=G0, dark=O)

    # Upper glyph status window (x=6..17, y=7..15)
    B.rect(6, 7, 17, 15, O)
    B.rect(7, 8, 16, 14, 2)
    if state == 'idle':
        # Neutral horizontal rest bar '-'
        D.hline(10, 13, 11, G3)
    elif state == 'buzzing':
        # Bold 'X' reject glyph (5x5 across x=9..13, y=9..13)
        for i in range(5):
            D.put(9 + i, 9 + i, 24)
            D.put(13 - i, 9 + i, 24)
        D.put(11, 11, 26)
        # Exterior buzz vibration ticks '<' and '>' flanking top housing
        for dy in (8, 11, 14):
            D.put(2, dy, 24); D.put(21, dy, 24)
    elif state == 'accepted':
        # Bold '>>>' chevron glyph across x=8..15, y=9..13
        for cx in (8, 12):
            D.put(cx, 9, 26); D.put(cx + 1, 10, 26); D.put(cx + 2, 11, 26)
            D.put(cx + 1, 12, 25); D.put(cx, 13, 25)

    # Lower vertical lever slot (x=10..13, y=17..27)
    B.rect(10, 17, 13, 27, O)
    B.vline(9, 17, 27, G0)
    B.vline(14, 17, 27, G3)

    if state == 'idle':
        # Handle UP at rest (y=16..20)
        D.rect(11, 20, 12, 23, G3)
        D.rect(7, 16, 16, 19, G3)
        D.hline(7, 16, 16, G4)
        D.hline(7, 16, 19, G1)
    elif state == 'buzzing':
        # Handle jiggling at MID-CANT (y=20..23, shifted +1px right with shake ticks)
        D.rect(11, 20, 12, 24, G2)
        D.rect(8, 20, 17, 23, 23)
        D.hline(8, 17, 20, 24)
        D.put(5, 21, G4); D.put(18, 22, G4)
    elif state == 'accepted':
        # Handle PULLED DOWN to bottom detent (y=25..28)
        D.rect(11, 21, 12, 25, G2)
        D.rect(7, 25, 16, 28, 25)
        D.hline(7, 16, 25, 26)
        D.hline(7, 16, 28, 23)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 3. SHARED 32 x 64 DOORWAY / GATE / HATCH / SHUTTER / BARRIER HOUSING HELPERS
# ==============================================================================

def _door_frame_32x64(plate_mark='diamond'):
    """Shared worn-steel 32 x 64 industrial portal frame (pivot (16, 56)).
    Left jamb x=2..6, right jamb x=25..29, top header x=2..29, y=2..14.
    Interior portal aperture is x=7..24, y=15..55 (18 x 41 px)."""
    w, h = 32, 64
    F = Layer(w, h, 'Portal_Frame')
    # Top lintel header
    _steel_panel(F, 2, 2, 29, 14)
    # Left & right vertical jamb columns
    _steel_panel(F, 2, 14, 6, 56)
    _steel_panel(F, 25, 14, 29, 56)
    # Jamb foot plinths
    F.rect(1, 54, 7, 57, G0)
    F.rect(24, 54, 30, 57, G0)

    # Distinct top-left header plate mark (x=5..11, y=5..11) for greyscale family identification
    F.rect(4, 4, 12, 12, G0)
    if plate_mark == 'diamond':  # Platform Gate (SO-01)
        for (x, y) in ((8, 5), (7, 6), (9, 6), (6, 7), (10, 7), (5, 8), (11, 8), (6, 9), (10, 9), (7, 10), (9, 10), (8, 11)):
            F.put(x, y, G4)
    elif plate_mark == 'staff_bars':  # Staff Door (PZ-006): '||' double vertical bar
        F.rect(6, 5, 7, 11, G4)
        F.rect(9, 5, 10, 11, G4)
    elif plate_mark == 'hatch_wheel':  # Service Hatch (SO-02): octagonal wheel mark
        F.rect(6, 6, 10, 10, G3)
        F.put(8, 5, G4); F.put(8, 11, G4); F.put(5, 8, G4); F.put(11, 8, G4)
        F.put(8, 8, O)
    elif plate_mark == 'shutter_louvre':  # Inner Shutter (PZ-002): '===' triple horizontal louvre
        for y in (5, 8, 11):
            F.hline(5, 11, y, G4)
    elif plate_mark == 'barrier_shield':  # Staff Barrier (PZ-003): '+' cross shield
        F.rect(7, 5, 9, 11, G4)
        F.rect(5, 7, 11, 9, G4)
    return F


def _header_status(L, open_state=False):
    """Draw right-side header status window (x=15..26, y=5..11) with '-' closed vs '>>>' open glyph."""
    L.rect(15, 5, 26, 11, O)
    L.rect(16, 6, 25, 10, 2)
    if open_state:
        for cx in (17, 21):
            L.put(cx, 6, 26); L.put(cx + 1, 7, 26); L.put(cx + 2, 8, 26)
            L.put(cx + 1, 9, 25); L.put(cx, 10, 25)
    else:
        L.rect(19, 7, 22, 9, 23)
        L.hline(19, 22, 7, 24)


def build_platform_gate(state):
    """state in ('closed', 'open'). Size 32 x 64, pivot (16, 56)."""
    w, h = 32, 64
    F = _door_frame_32x64('diamond')
    G = Layer(w, h, 'Gate_Shutter')
    _header_status(F, open_state=(state == 'open'))

    if state == 'closed':
        sh = _shadow_rect(w, h, 2, 54, 29, 58)
        # Heavy vertical security grille bars + middle cross-rail filling x=7..24, y=15..55
        G.rect(7, 15, 24, 18, G1)
        G.rect(7, 33, 24, 36, G2)
        G.hline(7, 24, 33, G3)
        G.rect(7, 52, 24, 55, G1)
        for bx in (8, 11, 14, 17, 20, 23):
            G.vline(bx, 15, 55, G3)
            G.vline(bx + 1, 15, 55, G1)
        # Central lock plate
        G.rect(13, 31, 18, 38, G2)
        G.rect(15, 34, 16, 35, 24)
    else:
        # Open: only jamb shadows; retracted bar tips at y=15..17; x=7..24, y=18..56 is CLEAR PORTAL!
        sh = _shadow_rect(w, h, 1, 54, 7, 58)
        sh.rect(24, 55, 30, 58, SH)
        G.rect(7, 15, 24, 16, G1)
        for bx in (8, 11, 14, 17, 20, 23):
            G.put(bx, 17, G3)

    ol = _outline_from(w, h, F, G)
    return [sh, ol, F, G]


def build_staff_door(state):
    """state in ('closed', 'open'). Size 32 x 64, pivot (16, 56)."""
    w, h = 32, 64
    F = _door_frame_32x64('staff_bars')
    D = Layer(w, h, 'Door_Leaf')
    _header_status(F, open_state=(state == 'open'))

    if state == 'closed':
        sh = _shadow_rect(w, h, 2, 54, 29, 58)
        _steel_panel(D, 7, 15, 24, 55, bevel_light=G3, mid=G2, shad=G1, dark=G0)
        # Upper reinforced wire-glass vision slit (x=10..21, y=19..27)
        D.rect(10, 19, 21, 27, O)
        D.rect(11, 20, 20, 26, 6)
        D.line(12, 25, 19, 20, 8)
        # Lower recessed kick panel + heavy latch handle on right
        D.rect(10, 34, 21, 50, G1)
        D.hline(10, 21, 34, G0)
        D.hline(10, 21, 50, G3)
        D.rect(20, 30, 23, 32, 25)
    else:
        # Open: door leaf slid into left jamb pocket (only 2px edge at x=7..8); x=9..24, y=15..56 is CLEAR PORTAL!
        sh = _shadow_rect(w, h, 1, 54, 8, 58)
        sh.rect(24, 55, 30, 58, SH)
        D.vline(7, 15, 55, G2)
        D.vline(8, 15, 55, G3)
        D.rect(7, 30, 9, 32, 25)

    ol = _outline_from(w, h, F, D)
    return [sh, ol, F, D]


def build_service_hatch(state):
    """state in ('closed', 'open', 'frozen_open', 'frozen_closed'). Size 32 x 64, pivot (16, 56).
    Sol direction: frozen_open AND frozen_closed retain their actual aperture state (open portal vs closed slab)
    plus a brass [o] lock ring and Freeze corner brackets; clearly distinct from ordinary open/closed."""
    w, h = 32, 64
    F = _door_frame_32x64('hatch_wheel')
    H_slab = Layer(w, h, 'Hatch_Slab')
    FZ = Layer(w, h, 'Freeze_Lock_Ring')

    is_open = state in ('open', 'frozen_open')
    is_frozen = state in ('frozen_open', 'frozen_closed')
    _header_status(F, open_state=is_open)

    if not is_open:
        # CLOSED aperture: heavy ribbed steel slab across x=7..24, y=15..55
        sh = _shadow_rect(w, h, 2, 54, 29, 58)
        _steel_panel(H_slab, 7, 15, 24, 55, bevel_light=G3, mid=G2, shad=G1, dark=G0)
        for ry in (21, 28, 42, 49):
            H_slab.hline(8, 23, ry, G0)
            H_slab.hline(8, 23, ry + 1, G3)
        # Central dog-wheel hub at (15..16, 34..35)
        H_slab.rect(12, 31, 19, 38, G1)
        H_slab.rect(13, 32, 18, 37, G3)
        H_slab.rect(15, 34, 16, 35, G0)
    else:
        # OPEN aperture: slab retracted into header (bottom teeth at y=15..18); x=7..24, y=19..56 is CLEAR PORTAL!
        sh = _shadow_rect(w, h, 1, 54, 7, 58)
        sh.rect(24, 55, 30, 58, SH)
        H_slab.rect(7, 15, 24, 18, G2)
        H_slab.hline(7, 24, 18, G3)
        for tx in (9, 13, 18, 22):
            H_slab.rect(tx, 17, tx + 1, 19, G1)

    if is_frozen:
        # Corner Freeze L-brackets on the portal frame corners (amber/cyan-teal 28/29 + brass 25/26)
        # Top-left (4..9, 15..20), Top-right (22..27, 15..20), Bottom-left (4..9, 50..55), Bottom-right (22..27, 50..55)
        for (bx, by, sx, sy) in ((4, 15, 1, 1), (27, 15, -1, 1), (4, 54, 1, -1), (27, 54, -1, -1)):
            for i in range(6):
                FZ.put(bx + sx * i, by, 29)
                FZ.put(bx + sx * i, by + sy, 28)
                FZ.put(bx, by + sy * i, 29)
                FZ.put(bx + sx, by + sy * i, 28)
        # Prominent brass '[o]' lock ring (9x9 octagonal ring with hollow center):
        # Placed at y=14..22 (clamping the raised slab to the header) when frozen_open,
        # or at y=30..38 (clamping the center wheel hub) when frozen_closed!
        ry0 = 14 if is_open else 30
        rx0 = 11
        # Dark backing plate behind ring so the hollow 'o' ring reads crisply in greyscale
        FZ.rect(rx0, ry0, rx0 + 9, ry0 + 8, O)
        # Outer brass ring (10x9) with 4x3 hollow center
        for dy in range(9):
            for dx in range(10):
                if (dx in (0, 9) and dy in (0, 8)):
                    continue
                if 3 <= dx <= 6 and 3 <= dy <= 5:
                    continue  # hollow 'o' center!
                col = 26 if (dx + dy <= 7) else 25
                FZ.put(rx0 + dx, ry0 + dy, col)
        # Side clamp bars locking the ring to the jambs
        FZ.rect(6, ry0 + 3, rx0 - 1, ry0 + 5, 25)
        FZ.rect(rx0 + 10, ry0 + 3, 25, ry0 + 5, 25)
        FZ.hline(6, rx0 - 1, ry0 + 3, 26)
        FZ.hline(rx0 + 10, 25, ry0 + 3, 26)

    ol = _outline_from(w, h, F, H_slab, FZ)
    return [sh, ol, F, H_slab, FZ]


def build_bulkhead_module():
    """ch01_env_wall_bulkhead_module_idle (32 x 64 px, pivot (16, 56), category 'environments').
    Sol Appendix B.3: Same 2:1 isometric planar hierarchy as existing N/W walls (dy = x // 2 across x=0..31),
    stronger structural seam; shared left/right edges tile cleanly without a heavy outline cage."""
    w, h = 32, 64
    sh = Layer(w, h, 'Cast_Shadow')
    ol = Layer(w, h, 'Silhouette_Outline')
    B = Layer(w, h, 'Bulkhead_Wall')
    D = Layer(w, h, 'Ribs_And_Conduit')

    for x in range(w):
        y_top = x // 2
        y_bot = 48 + x // 2
        # Top cap bevel (4px thick: y_top .. y_top + 3) matching subterranean_n planar hierarchy
        B.put(x, y_top, G3)
        B.put(x, y_top + 1, 8)
        B.put(x, y_top + 2, 7)
        B.put(x, y_top + 3, G0)
        # Main bulkhead steel plates (y_top + 4 .. y_bot - 12)
        for y in range(y_top + 4, y_bot - 11):
            B.put(x, y, G2 if (x not in (0, 31)) else G1)
        # Recessed structural bays on either side of the central vertical I-beam seam
        if 3 <= x <= 12 or 19 <= x <= 28:
            for y in range(y_top + 7, y_bot - 14):
                B.put(x, y, G1)
            B.put(x, y_top + 7, G0)
            B.put(x, y_bot - 14, G3)
        # Horizontal conduit pipe & safety stripe at y_bot - 12 .. y_bot - 10
        D.put(x, y_bot - 13, G3)
        D.put(x, y_bot - 12, 24)
        D.put(x, y_bot - 11, G0)
        # Lower kickplate (y_bot - 10 .. y_bot - 2)
        for y in range(y_bot - 10, y_bot - 1):
            B.put(x, y, 7 if y < y_bot - 4 else G0)
        # Base ground contact line (no left/right vertical outline cage so modules tile seamlessly!)
        ol.put(x, y_bot - 1, O)
        if y_bot < h:
            sh.put(x, y_bot, SH)
        # Strong central vertical structural bulkhead seam & I-beam rib at x=14..17
        if x == 14:
            for y in range(y_top + 4, y_bot - 1):
                D.put(x, y, G3)
        elif x in (15, 16):
            for y in range(y_top + 4, y_bot - 1):
                D.put(x, y, G0 if x == 15 else G2)
        elif x == 17:
            for y in range(y_top + 4, y_bot - 1):
                D.put(x, y, G1)
        # Rivet pairs along the central structural seam and shared edges
        if x in (2, 13, 18, 29):
            for ry in (y_top + 9, y_top + 18, y_top + 27):
                D.put(x, ry, G3)
    return [sh, ol, B, D]


def build_inner_shutter(state):
    """state in ('closed', 'raised'). Size 32 x 64, pivot (16, 56)."""
    w, h = 32, 64
    F = _door_frame_32x64('shutter_louvre')
    S = Layer(w, h, 'Shutter_Slats')
    _header_status(F, open_state=(state == 'raised'))

    if state == 'closed':
        sh = _shadow_rect(w, h, 2, 54, 29, 58)
        S.rect(7, 15, 24, 55, G2)
        for y in range(16, 52, 4):
            S.hline(7, 24, y, G3)
            S.hline(7, 24, y + 2, G1)
            S.hline(7, 24, y + 3, G0)
        # Bottom hazard lock bar (y=52..55)
        S.rect(7, 52, 24, 55, G1)
        for x in range(8, 24, 4):
            S.rect(x, 52, x + 1, 54, 25)
    else:
        # Raised: coiled shutter roll at y=15..18; x=7..24, y=19..56 is CLEAR PORTAL!
        sh = _shadow_rect(w, h, 1, 54, 7, 58)
        sh.rect(24, 55, 30, 58, SH)
        S.rect(7, 15, 24, 18, G1)
        S.hline(7, 24, 16, G3)
        S.hline(7, 24, 18, G0)

    ol = _outline_from(w, h, F, S)
    return [sh, ol, F, S]


def build_staff_barrier(state):
    """state in ('closed', 'open'). Size 32 x 64, pivot (16, 56)."""
    w, h = 32, 64
    F = _door_frame_32x64('barrier_shield')
    B = Layer(w, h, 'Barrier_Arms')
    _header_status(F, open_state=(state == 'open'))

    if state == 'closed':
        sh = _shadow_rect(w, h, 2, 54, 29, 58)
        # Twin horizontal security turnstile bars across x=7..24 at y=26..30 and y=38..42 + center lock post
        B.rect(7, 26, 24, 30, G3)
        B.hline(7, 24, 26, G4)
        B.hline(7, 24, 30, G0)
        B.rect(7, 38, 24, 42, G3)
        B.hline(7, 24, 38, G4)
        B.hline(7, 24, 42, G0)
        # Warning stripes on upper bar + central vertical lock post
        for x in (9, 19):
            B.rect(x, 27, x + 2, 29, 23)
        B.rect(14, 24, 17, 45, G2)
        B.rect(15, 32, 16, 35, 24)
    else:
        # Open: barrier arms folded vertically into side jambs (x=7..8 and x=23..24); center x=9..22 is CLEAR PORTAL!
        sh = _shadow_rect(w, h, 1, 54, 7, 58)
        sh.rect(24, 55, 30, 58, SH)
        B.rect(7, 24, 8, 44, G3)
        B.rect(23, 24, 24, 44, G2)

    ol = _outline_from(w, h, F, B)
    return [sh, ol, F, B]


# ==============================================================================
# 4. PZ-001 CONDUIT (2 assets, 48 x 32 px, pivot (24, 26))
# ==============================================================================

def build_conduit(state):
    """state in ('fallen', 'mounted'). Size 48 x 32, pivot (24, 26)."""
    w, h = 48, 32
    B = Layer(w, h, 'Brackets_And_Pipe')
    D = Layer(w, h, 'Wires_And_Clamps')

    # Two top wall/ceiling mounting brackets at x=8..13 and x=34..39
    _steel_panel(B, 8, 2, 13, 9, bevel_light=G3, mid=G2, shad=G1, dark=G0)
    _steel_panel(B, 34, 2, 39, 9, bevel_light=G3, mid=G2, shad=G1, dark=G0)

    if state == 'mounted':
        sh = _shadow_rect(w, h, 6, 25, 41, 27)
        # Straight horizontal conduit pipe bolted cleanly across y=5..11 (x=3..44)
        B.rect(3, 5, 44, 11, G2)
        B.hline(3, 44, 5, G4)
        B.hline(3, 44, 6, G3)
        B.hline(3, 44, 10, G1)
        B.hline(3, 44, 11, G0)
        # Intact collar straps over brackets + center coupling
        for cx in (9, 22, 35):
            D.rect(cx, 4, cx + 3, 12, G3)
            D.vline(cx, 4, 12, G4)
            D.vline(cx + 3, 4, 12, G0)
            D.put(cx + 1, 8, 25)
    else:
        # FALLEN: snapped bracket stubs at top; V-sagged broken pipe collapsed onto floor (y=14..27)
        sh = _shadow_rect(w, h, 4, 23, 43, 28)
        # Snapped dark bracket jaws at y=9..11
        D.rect(9, 9, 12, 11, G0)
        D.rect(35, 9, 38, 11, G0)
        # Left sagging pipe section (angled down from x=3, y=14 to break at x=21, y=24)
        for x in range(3, 22):
            y0 = 14 + (x - 3) // 2
            B.put(x, y0, G4)
            B.put(x, y0 + 1, G3)
            B.put(x, y0 + 2, G2)
            B.put(x, y0 + 3, G1)
            B.put(x, y0 + 4, G0)
        # Right sagging pipe section (angled down from x=44, y=14 to break at x=26, y=24)
        for x in range(26, 45):
            y0 = 14 + (44 - x) // 2
            B.put(x, y0, G4)
            B.put(x, y0 + 1, G3)
            B.put(x, y0 + 2, G2)
            B.put(x, y0 + 3, G1)
            B.put(x, y0 + 4, G0)
        # Jagged break gap at x=22..25, y=21..27 with spilled severed wires (23/24/25)
        for (wx, wy, wc) in (
            (21, 24, 24), (22, 25, 25), (23, 26, 26),
            (25, 24, 23), (24, 25, 24), (24, 27, 25),
            (22, 23, G0), (25, 23, G0),
        ):
            D.put(wx, wy, wc)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 5. PZ-006 SPLIT-FLAP DIALS (6 assets, 32 x 32 px, pivot (16, 28))
# ==============================================================================

def build_flap_dial(kind, state):
    """kind in ('line', 'platform', 'time'), state in ('idle', 'jammed'). Size 32 x 32, pivot (16, 28)."""
    w, h = 32, 32
    sh = _shadow_rect(w, h, 3, 26, 28, 29)
    B = Layer(w, h, 'Dial_Housing')
    D = Layer(w, h, 'Flap_And_Header_Glyph')

    _steel_panel(B, 3, 3, 28, 27)
    # Top header bar (x=4..27, y=4..10) with separate mechanical header glyph
    B.rect(4, 4, 27, 10, G1)
    B.hline(4, 27, 10, G0)

    if kind == 'line':
        # Header glyph: Circle - Diamond - Triangle miniature icons
        # Circle at x=8..10
        D.rect(8, 6, 10, 8, G4); D.put(9, 7, G1)
        # Diamond at x=15..17
        D.put(16, 5, 26); D.hline(15, 17, 6, 25); D.put(16, 7, 25)
        # Triangle at x=21..23
        D.put(22, 6, G4); D.hline(21, 23, 7, G4); D.hline(20, 24, 8, G3)
    elif kind == 'platform':
        # Header glyph: 'I  II  III' platform tally bars
        D.vline(9, 5, 8, G4)
        D.vline(14, 5, 8, 26); D.vline(16, 5, 8, 26)
        D.vline(20, 5, 8, G3); D.vline(22, 5, 8, G3); D.vline(24, 5, 8, G3)
    elif kind == 'time':
        # Header glyph: miniature clock dial with L-hands at x=13..18, y=5..9
        D.rect(13, 5, 18, 9, O)
        D.put(15, 6, 26); D.put(15, 7, 26); D.put(16, 7, 26); D.put(17, 7, 25)
        D.put(9, 7, G4); D.put(22, 7, G4)

    # Split-flap card recess (x=5..26, y=12..25) — kept clean of baked text so runtime labels render cleanly
    B.rect(5, 12, 26, 25, O)
    if state == 'idle':
        # Level upper flap (y=13..18) and lower flap (y=20..24) separated by straight 1px center seam at y=19
        D.rect(6, 13, 25, 18, 2)
        D.hline(6, 25, 13, 3)
        D.hline(5, 26, 19, O)  # straight center split-flap seam
        D.rect(6, 20, 25, 24, 1)
        # Left & right hinge pins at y=19
        D.put(5, 19, G4); D.put(26, 19, G4)
        if kind == 'time':
            D.put(15, 16, G3); D.put(15, 22, G3)
    else:
        # JAMMED: upper flap cocked/tilted diagonally (left side dropped to y=15, right side jammed up at y=11),
        # exposing a diagonal metal seam gap and protruding corner tab + red/orange fault pin!
        for x in range(6, 26):
            top_y = 14 - (x - 6) // 6  # tilts upward from y=14 on left to y=11 on right
            bot_y = top_y + 5
            for y in range(top_y, bot_y + 1):
                D.put(x, y, 3 if y == top_y else 2)
            # Exposed bright steel backing strip in the jammed diagonal seam gap below bot_y
            D.put(x, bot_y + 1, O)
            D.put(x, bot_y + 2, G3 if (x % 3 != 0) else 24)
        # Lower flap skewed at y=21..24
        D.rect(6, 21, 25, 24, 1)
        # Jammed red/orange fault indicator pin on right hinge
        D.rect(25, 17, 27, 19, 23)
        D.put(26, 17, 24)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 6. PZ-006 TICKET VALIDATOR (3 assets, 24 x 36 px, pivot (12, 30))
# ==============================================================================

def build_ticket_validator(state):
    """state in ('idle', 'rejecting', 'accepted'). Size 24 x 36, pivot (12, 30)."""
    w, h = 24, 36
    sh = _shadow_rect(w, h, 4, 28, 19, 32)
    B = Layer(w, h, 'Validator_Body')
    D = Layer(w, h, 'Glyph_And_Slot')

    _steel_panel(B, 4, 4, 19, 30)
    _steel_panel(B, 3, 28, 20, 31, bevel_light=G2, mid=G1, shad=G0, dark=O)

    # Upper glyph window (x=6..17, y=6..14)
    B.rect(6, 6, 17, 14, O)
    B.rect(7, 7, 16, 13, 2)
    if state == 'idle':
        D.hline(10, 13, 10, G3)
    elif state == 'rejecting':
        # Bold 'X' reject glyph
        for i in range(5):
            D.put(9 + i, 8 + i, 24)
            D.put(13 - i, 8 + i, 24)
        D.put(11, 10, 26)
    elif state == 'accepted':
        # Bold '>>>' accept chevron glyph
        for cx in (8, 12):
            D.put(cx, 8, 26); D.put(cx + 1, 9, 26); D.put(cx + 2, 10, 26)
            D.put(cx + 1, 11, 25); D.put(cx, 12, 25)

    # Ticket insertion mouth bezel (x=6..17, y=17..23)
    _steel_panel(B, 6, 17, 17, 23, bevel_light=G2, mid=G1, shad=G0, dark=O)
    D.rect(8, 19, 15, 20, O)  # ticket slot opening
    if state == 'rejecting':
        # Ejected ticket stub sticking out of slot with angled corner
        D.rect(9, 20, 14, 25, G4)
        D.hline(9, 14, 25, 23)
    elif state == 'accepted':
        # Swallowed ticket edge flush inside slot + amber guide bar
        D.hline(9, 14, 19, 26)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 7. PZ-006 TICKET-TERMS NOTICE (1 asset, 16 x 20 px, pivot (8, 16))
# ==============================================================================

def build_ticket_terms_notice():
    """ch01_prop_ticket_terms_notice_idle (16 x 20 px, pivot (8, 16)).
    Plaque + paper silhouette with horizontal rule lines, no invented clue text."""
    w, h = 16, 20
    sh = _shadow_rect(w, h, 2, 15, 13, 17)
    B = Layer(w, h, 'Plaque_Back')
    D = Layer(w, h, 'Paper_Notice')

    _steel_panel(B, 2, 2, 13, 16, bevel_light=G3, mid=G1, shad=G0, dark=O)
    # Pale paper sheet (x=4..11, y=4..14) with folded bottom-right corner
    D.rect(4, 4, 11, 14, 19)
    D.hline(4, 11, 4, G4)
    D.vline(4, 4, 14, G4)
    D.put(11, 14, G1)  # dog-ear corner
    # Header bar + 3 quiet ruled lines (no numbers or letters)
    D.hline(5, 10, 6, 17)
    D.hline(5, 10, 9, 18)
    D.hline(5, 10, 11, 18)
    D.hline(5, 8, 13, 18)
    # Subdued crimson transit seal dot at bottom-right
    D.put(10, 12, 23)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 8. FLOOR PLATES: SO-02 PLATES A & B, PZ-003 ALARM PLATE, PZ-005 STANDBY PLATE
#    All 32 x 16 px, pivot (16, 8), sorting layer YSort_Props (z_index = 1, floor-flush)
# ==============================================================================

def _floor_plate_frame(pressed=False, accent_hi=G3, accent_lo=G1):
    """Base 32 x 16 floor plate housing. When `pressed=True`, the top plate is visibly
    depressed 2px into a dark recessed perimeter trench with engaged side lock tabs."""
    w, h = 32, 16
    B = Layer(w, h, 'Plate_Frame')
    # Outer floor bevel housing (x=2..29, y=2..13)
    B.rect(2, 2, 29, 13, G1)
    B.hline(2, 29, 2, G3)
    B.vline(2, 2, 13, G3)
    B.hline(2, 29, 13, G0)
    B.vline(29, 2, 13, G0)

    if not pressed:
        # Raised top plate at x=4..27, y=3..11 (standing proud)
        B.rect(4, 3, 27, 11, G2)
        B.hline(4, 27, 3, G4)
        B.vline(4, 3, 11, G3)
        B.hline(4, 27, 11, G0)
        # Corner accent strips
        B.rect(5, 4, 7, 5, accent_hi)
        B.rect(24, 4, 26, 5, accent_lo)
    else:
        # Pressed: dark 2px recessed trench around top & left (y=3..4, x=4..5), top surface shifted down to y=5..12
        B.rect(4, 3, 27, 12, O)
        B.rect(5, 5, 26, 12, G1)
        B.hline(5, 26, 5, G2)
        # Engaged side mechanical lock tabs protruding at x=1..3 and x=28..30, y=6..9
        B.rect(1, 6, 3, 9, accent_hi)
        B.rect(28, 6, 30, 9, accent_hi)
        B.rect(6, 6, 8, 7, accent_hi)
        B.rect(23, 6, 25, 7, accent_lo)
    return B


def build_floor_plate_ab(letter, pressed):
    """letter in ('a', 'b'), pressed in (False, True). Size 32 x 16, pivot (16, 8)."""
    w, h = 32, 16
    sh = _shadow_rect(w, h, 2, 12, 29, 14)
    if letter == 'a':
        ahi, alo = (26, 25) if pressed else (25, 24)
    else:
        ahi, alo = (29, 28) if pressed else (9, 27)
    B = _floor_plate_frame(pressed=pressed, accent_hi=ahi, accent_lo=alo)
    D = Layer(w, h, 'Plate_Glyph')

    gy = 6 if pressed else 4
    gc = ahi if pressed else G4
    # Dark backing behind letter so 'A' / 'B' reads with high contrast in greyscale
    D.rect(12, gy, 19, gy + 5, O)
    if letter == 'a':
        # Embossed 'A' glyph (6x5 across x=13..18, y=gy..gy+4)
        D.hline(14, 17, gy, gc)
        D.put(13, gy + 1, gc); D.put(18, gy + 1, gc)
        D.hline(13, 18, gy + 2, gc)
        D.put(13, gy + 3, gc); D.put(18, gy + 3, gc)
        D.put(13, gy + 4, gc); D.put(18, gy + 4, gc)
    else:
        # Embossed 'B' glyph (6x5 across x=13..18, y=gy..gy+4)
        D.vline(13, gy, gy + 4, gc)
        D.hline(13, 17, gy, gc)
        D.hline(13, 17, gy + 2, gc)
        D.hline(13, 17, gy + 4, gc)
        D.put(18, gy + 1, gc)
        D.put(18, gy + 3, gc)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


def build_alarm_plate(state):
    """state in ('idle', 'ringing'). Size 32 x 16, pivot (16, 8)."""
    w, h = 32, 16
    pressed = (state == 'ringing')
    sh = _shadow_rect(w, h, 2, 12, 29, 14)
    B = _floor_plate_frame(pressed=pressed, accent_hi=24 if pressed else 23, accent_lo=23 if pressed else 22)
    D = Layer(w, h, 'Bell_And_Strikes')

    gy = 6 if pressed else 4
    bc = 26 if pressed else G4
    D.rect(10, gy, 21, gy + 5, O)
    # Central bell glyph (x=14..17, y=gy..gy+4)
    D.hline(15, 16, gy, bc)
    D.hline(14, 17, gy + 1, bc)
    D.hline(14, 17, gy + 2, bc)
    D.hline(13, 18, gy + 3, bc)
    D.put(15, gy + 4, 24 if pressed else G3)

    if pressed:
        # Radiating strike marks '((  ))' on both sides of the bell glyph (x=10..12 and x=19..21)
        for dy in (gy, gy + 2, gy + 4):
            D.put(11, dy, 26); D.put(20, dy, 26)
        D.put(10, gy + 1, 24); D.put(10, gy + 3, 24)
        D.put(21, gy + 1, 24); D.put(21, gy + 3, 24)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


def build_standby_plate(state):
    """state in ('empty', 'held'). Size 32 x 16, pivot (16, 8).
    Sol direction: empty = hollow footprint/diamond outline; held = depressed + solid double footprint."""
    w, h = 32, 16
    pressed = (state == 'held')
    sh = _shadow_rect(w, h, 2, 12, 29, 14)
    B = _floor_plate_frame(pressed=pressed, accent_hi=26 if pressed else G3, accent_lo=25 if pressed else G2)
    D = Layer(w, h, 'Footprint_Glyph')

    gy = 6 if pressed else 4
    D.rect(10, gy, 21, gy + 5, O)
    if not pressed:
        # EMPTY: hollow rectangular/diamond outline (center is dark empty O)
        D.hline(13, 18, gy, G4)
        D.hline(13, 18, gy + 4, G3)
        D.vline(12, gy + 1, gy + 3, G4)
        D.vline(19, gy + 1, gy + 3, G3)
    else:
        # HELD: solid filled DOUBLE FOOTPRINT blocks (left boot x=11..14, right boot x=17..20)
        D.rect(11, gy, 14, gy + 4, 26)
        D.rect(17, gy, 20, gy + 4, 26)
        D.hline(11, 14, gy + 3, 25)
        D.hline(17, 20, gy + 3, 25)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 9. SO-02 BELL ICON (2 assets, 8 x 8 px, pivot (4, 4))
# ==============================================================================

def build_bell_icon(state):
    """state in ('idle', 'ringing'). Size 8 x 8, pivot (4, 4)."""
    w, h = 8, 8
    B = Layer(w, h, 'Bell_Backing')
    D = Layer(w, h, 'Bell_And_Strikes')

    if state == 'idle':
        # Quiet steel bell silhouette in center x=2..5, y=1..6 (outer cols x=0,7 empty)
        D.hline(3, 4, 1, G4)
        D.hline(2, 5, 2, G3)
        D.hline(2, 5, 3, G3)
        D.hline(2, 5, 4, G2)
        D.hline(1, 6, 5, G4)
        D.put(3, 6, G3); D.put(4, 6, G1)
        ol = _outline_from(w, h, D)
    else:
        # RINGING: bright brass/gold bell + radiating outer strike marks at x=0 and x=7!
        B.rect(1, 0, 6, 7, O)
        D.hline(3, 4, 1, 26)
        D.hline(2, 5, 2, 26)
        D.hline(2, 5, 3, 25)
        D.hline(2, 5, 4, 25)
        D.hline(1, 6, 5, 26)
        D.put(4, 6, 24)
        # Outer strike marks at left (x=0) and right (x=7)
        for sy in (1, 3, 5):
            D.put(0, sy, 26)
            D.put(7, sy, 26)
        ol = B
    return [ol, D]


# ==============================================================================
# 10. PZ-003 ECHO PEDESTAL (2 assets, 24 x 36 px, pivot (12, 30))
# ==============================================================================

def build_echo_pedestal(state):
    """state in ('idle', 'used'). Size 24 x 36, pivot (12, 30).
    Sol direction: used adds persistent second clock-hand + paired twin mark on front apron."""
    w, h = 24, 36
    sh = _shadow_rect(w, h, 4, 28, 19, 32)
    B = Layer(w, h, 'Pedestal_Body')
    D = Layer(w, h, 'Dial_And_Twin_Marks')

    _steel_panel(B, 5, 4, 18, 30)
    _steel_panel(B, 3, 28, 20, 31, bevel_light=G2, mid=G1, shad=G0, dark=O)

    # Upper octagonal clock-dial recess (x=7..16, y=6..15)
    B.rect(7, 6, 16, 15, O)
    B.rect(8, 7, 15, 14, 2)
    # Primary vertical 12-o'clock hand (present in both states)
    D.vline(11, 7, 11, G4)
    D.put(11, 11, 26 if state == 'used' else G4)

    # Lower front apron plate (x=7..16, y=18..25)
    B.rect(7, 18, 16, 25, G1)
    B.hline(7, 16, 18, G0)
    B.hline(7, 16, 25, G3)

    if state == 'idle':
        # Single center pip on apron
        D.rect(11, 21, 12, 22, G3)
    else:
        # USED: persistent SECOND clock hand extending down-right (x=12..15, y=11..13) + bezel ring ticks
        D.put(12, 11, 26); D.put(13, 12, 26); D.put(14, 13, 25); D.put(15, 13, 25)
        D.put(7, 6, 30); D.put(16, 6, 30); D.put(7, 15, 30); D.put(16, 15, 30)
        # Paired twin mark ('|| / <> <>' double vertical bars) on front apron
        D.rect(8, 19, 15, 24, O)
        D.rect(9, 20, 10, 23, 26)
        D.rect(13, 20, 14, 23, 30)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 11. PZ-003 CARD READER (3 assets, 16 x 24 px, pivot (8, 20))
# ==============================================================================

def build_card_reader(state):
    """state in ('idle', 'denied', 'accepted'). Size 16 x 24, pivot (8, 20)."""
    w, h = 16, 24
    sh = _shadow_rect(w, h, 2, 19, 13, 21)
    B = Layer(w, h, 'Reader_Housing')
    D = Layer(w, h, 'Status_Glyph')

    _steel_panel(B, 2, 2, 13, 20)
    # Right-side vertical card swipe slot (x=11..12, y=3..19)
    B.vline(11, 3, 19, O)
    B.vline(12, 3, 19, G0)

    # Left status window (x=4..9, y=4..12)
    B.rect(4, 4, 9, 12, O)
    B.rect(4, 5, 9, 11, 2)
    if state == 'idle':
        D.hline(5, 8, 8, G3)
    elif state == 'denied':
        # 5x5 'X' glyph across x=4..8, y=6..10
        for i in range(5):
            D.put(4 + i, 6 + i, 24)
            D.put(8 - i, 6 + i, 24)
        D.put(6, 8, 26)
    elif state == 'accepted':
        # '>>' chevron glyph across x=4..9, y=6..10
        for cx in (4, 7):
            D.put(cx, 6, 26); D.put(cx + 1, 7, 26); D.put(cx + 2, 8, 26)
            D.put(cx + 1, 9, 25); D.put(cx, 10, 25)

    # Lower keypad pips
    for ky in (15, 17):
        for kx in (5, 7, 9):
            D.put(kx, ky, G3)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 12. PZ-004 BREAKER C (3 assets, 24 x 36 px, pivot (12, 32))
# ==============================================================================

def build_breaker_c(state):
    """state in ('idle', 'engaged', 'browned_out'). Size 24 x 36, pivot (12, 32).
    Sol direction: lamp ring + lever detent; browned_out has a visibly broken/split lamp ring + fault detent."""
    w, h = 24, 36
    sh = _shadow_rect(w, h, 4, 29, 19, 33)
    B = Layer(w, h, 'Breaker_Box')
    D = Layer(w, h, 'Lamp_Ring_And_Lever')

    _steel_panel(B, 4, 4, 19, 31)
    _steel_panel(B, 3, 29, 20, 32, bevel_light=G2, mid=G1, shad=G0, dark=O)

    # Upper lamp-ring recess (x=6..17, y=6..16)
    B.rect(6, 6, 17, 16, O)
    # 7x7 circular/octagonal lamp ring centered at (11..12, 11)
    ring_pts = [
        (10, 8), (11, 8), (12, 8), (13, 8),
        (9, 9), (14, 9),
        (8, 10), (15, 10),
        (8, 11), (15, 11),
        (8, 12), (15, 12),
        (9, 13), (14, 13),
        (10, 14), (11, 14), (12, 14), (13, 14),
    ]
    if state == 'idle':
        for (rx, ry) in ring_pts:
            D.put(rx, ry, G3)
    elif state == 'engaged':
        for (rx, ry) in ring_pts:
            D.put(rx, ry, 26)
        # Lit center core + 4 cardinal ray ticks
        D.rect(10, 10, 13, 12, 25)
        D.put(11, 11, 26); D.put(12, 11, 26)
        for (tx, ty) in ((11, 6), (12, 6), (11, 16), (12, 16), (6, 11), (17, 11)):
            D.put(tx, ty, 26)
    elif state == 'browned_out':
        # BROKEN / SPLIT lamp ring: top-right (x>=12, y<=10) and bottom-left (x<=11, y>=12) ring arcs are missing/shattered,
        # with a diagonal fault slash across the middle!
        for (rx, ry) in ring_pts:
            if (rx >= 12 and ry <= 10) or (rx <= 11 and ry >= 12):
                continue  # broken gap in ring!
            D.put(rx, ry, G2)
        # Diagonal crack/fault slash across the broken ring
        for i in range(5):
            D.put(10 + i, 13 - i, 23 if i % 2 == 0 else G4)

    # Lower 3-detent lever slot (x=11..14, y=18..28)
    B.rect(11, 18, 14, 28, O)
    # Persistent 'C' identity glyph stamped on lower-left bezel (x=5..7, y=21..25) + detent ticks on right (x=16..17)
    D.hline(5, 7, 21, G4)
    D.vline(5, 21, 25, G4)
    D.hline(5, 7, 25, G4)
    for dy in (19, 23, 27):
        B.hline(16, 17, dy, G3)

    if state == 'idle':
        # Handle at UPPER detent (y=18..20)
        D.rect(9, 18, 15, 20, G3)
        D.hline(9, 15, 18, G4)
    elif state == 'engaged':
        # Handle at LOWER detent (y=26..28)
        D.rect(12, 21, 13, 26, G2)
        D.rect(9, 26, 15, 28, 25)
        D.hline(9, 15, 26, 26)
    elif state == 'browned_out':
        # Handle tripped/canted at MIDDLE fault detent (y=22..24, tilted)
        D.rect(9, 22, 12, 24, 23)
        D.rect(12, 23, 15, 25, G2)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 13. PZ-005 DEAD RELAY LEVER C (2 assets, 24 x 36 px, pivot (12, 32))
# ==============================================================================

def build_dead_relay_c(state):
    """state in ('idle', 'shake'). Size 24 x 36, pivot (12, 32).
    Sol direction: visibly disconnected cable lug in BOTH idle and shake states; shake adds tilted handle + shake ticks."""
    w, h = 24, 36
    sh = _shadow_rect(w, h, 3, 29, 17, 33)
    B = Layer(w, h, 'Relay_Housing')
    D = Layer(w, h, 'Lever_And_Disconnected_Lug')

    # Narrower left-shifted relay box (x=3..16, y=5..31) so the right-side x=17..22 shows the disconnected cable & lug clearly!
    _steel_panel(B, 3, 5, 16, 31)
    _steel_panel(B, 2, 29, 17, 32, bevel_light=G2, mid=G1, shad=G0, dark=O)

    # Dark dead status window at top (x=5..14, y=7..12) with persistent 'C' mark at left (x=6..8, y=8..11)
    B.rect(5, 7, 14, 12, O)
    B.rect(6, 8, 13, 11, G0)
    D.hline(6, 8, 8, G3)
    D.vline(6, 8, 11, G3)
    D.hline(6, 8, 11, G3)

    # Upper right terminal post protruding from box at x=17..20, y=11..14
    D.rect(17, 11, 20, 14, G3)
    D.put(19, 12, 25)  # empty terminal stud
    # CLEAR 5px AIR GAP at y=15..19 between terminal stud (y=14) and dangling cable lug (y=20)!

    # Dangling disconnected U-fork cable lug at x=18..22, y=20..23 + heavy cable dropping to floor at y=24..31
    lug_dx = 1 if state == 'shake' else 0
    lx = 18 + lug_dx
    # U-shaped fork lug jaws open upward toward the empty terminal stud
    D.vline(lx, 20, 22, G4)
    D.vline(lx + 3, 20, 22, G3)
    D.rect(lx, 22, lx + 3, 24, 24)  # copper/orange crimp collar
    D.rect(lx + 1, 25, lx + 2, 31, G1)  # dangling heavy cable

    # Lever slot (x=8..11, y=15..26)
    B.rect(8, 15, 11, 26, O)
    if state == 'idle':
        D.rect(6, 16, 13, 19, G3)
        D.hline(6, 13, 16, G4)
    else:
        # SHAKE: tilted lever handle + lateral shake tick marks '< >' around lever and lug!
        D.rect(5, 18, 9, 20, G4)
        D.rect(9, 19, 13, 21, G2)
        for dy in (16, 19, 22):
            D.put(1, dy, G4)
            D.put(15, dy, G4)
        D.put(22, 18, 26)

    ol = _outline_from(w, h, B, D)
    return [sh, ol, B, D]


# ==============================================================================
# 14. REGISTRY EXPORT FOR `registry.py` (57 Section B assets)
# ==============================================================================

def assets():
    """Return list of (stem, cat, w, h, layer_names, frames, fps, tags, meta) for all 57 Section B assets."""
    out = []

    # 1. SO-01 Selector panels (9)
    for kind in ('line', 'platform', 'car'):
        for pos in (0, 1, 2):
            out.append((
                f'ch01_prop_selector_{kind}_pos{pos}', 'props', 32, 48,
                ['Cast_Shadow', 'Silhouette_Outline', 'Housing_Base', 'Control_And_Glyph'],
                [build_selector_panel(kind, pos)], 1.0, None,
                dict(pivot=(16, 40), z='YSort_Props (z_index = 10)', desc=f'SO-01 {kind.upper()} selector panel pos {pos}')
            ))

    # 2. SO-01 Release lever (3)
    for st in ('idle', 'buzzing', 'accepted'):
        out.append((
            f'ch01_prop_release_lever_{st}', 'props', 24, 36,
            ['Cast_Shadow', 'Silhouette_Outline', 'Pedestal_Base', 'Lever_And_Glyph'],
            [build_release_lever(st)], 1.0, None,
            dict(pivot=(12, 32), z='YSort_Props (z_index = 10)', desc=f'SO-01 release lever ({st})')
        ))

    # 3. SO-01 Platform gate (2)
    for st in ('closed', 'open'):
        out.append((
            f'ch01_prop_platform_gate_{st}', 'props', 32, 64,
            ['Cast_Shadow', 'Silhouette_Outline', 'Portal_Frame', 'Gate_Shutter'],
            [build_platform_gate(st)], 1.0, None,
            dict(pivot=(16, 56), z='YSort_Props (z_index = 10)', desc=f'SO-01 platform gate ({st})')
        ))

    # 4. PZ-001 Conduit (2)
    for st in ('fallen', 'mounted'):
        out.append((
            f'ch01_prop_conduit_{st}', 'props', 48, 32,
            ['Cast_Shadow', 'Silhouette_Outline', 'Brackets_And_Pipe', 'Wires_And_Clamps'],
            [build_conduit(st)], 1.0, None,
            dict(pivot=(24, 26), z='YSort_Props (z_index = 10)', desc=f'PZ-001 overhead conduit ({st})')
        ))

    # 5. PZ-006 Split-flap dials (6)
    for kind in ('line', 'platform', 'time'):
        for st in ('idle', 'jammed'):
            out.append((
                f'ch01_prop_flap_dial_{kind}_{st}', 'props', 32, 32,
                ['Cast_Shadow', 'Silhouette_Outline', 'Dial_Housing', 'Flap_And_Header_Glyph'],
                [build_flap_dial(kind, st)], 1.0, None,
                dict(pivot=(16, 28), z='YSort_Props (z_index = 10)', desc=f'PZ-006 split-flap {kind} dial ({st})')
            ))

    # 6. PZ-006 Ticket validator (3)
    for st in ('idle', 'rejecting', 'accepted'):
        out.append((
            f'ch01_prop_ticket_validator_{st}', 'props', 24, 36,
            ['Cast_Shadow', 'Silhouette_Outline', 'Validator_Body', 'Glyph_And_Slot'],
            [build_ticket_validator(st)], 1.0, None,
            dict(pivot=(12, 30), z='YSort_Props (z_index = 10)', desc=f'PZ-006 ticket validator ({st})')
        ))

    # 7. PZ-006 Staff door (2)
    for st in ('closed', 'open'):
        out.append((
            f'ch01_prop_staff_door_{st}', 'props', 32, 64,
            ['Cast_Shadow', 'Silhouette_Outline', 'Portal_Frame', 'Door_Leaf'],
            [build_staff_door(st)], 1.0, None,
            dict(pivot=(16, 56), z='YSort_Props (z_index = 10)', desc=f'PZ-006 staff door ({st})')
        ))

    # 8. PZ-006 Ticket-terms notice (1)
    out.append((
        'ch01_prop_ticket_terms_notice_idle', 'props', 16, 20,
        ['Cast_Shadow', 'Silhouette_Outline', 'Plaque_Back', 'Paper_Notice'],
        [build_ticket_terms_notice()], 1.0, None,
        dict(pivot=(8, 16), z='YSort_Props (z_index = 10)', desc='PZ-006 wall ticket-terms notice plaque')
    ))

    # 9. SO-02 Service hatch (4)
    for st in ('closed', 'open', 'frozen_open', 'frozen_closed'):
        out.append((
            f'ch01_prop_service_hatch_{st}', 'props', 32, 64,
            ['Cast_Shadow', 'Silhouette_Outline', 'Portal_Frame', 'Hatch_Slab', 'Freeze_Lock_Ring'],
            [build_service_hatch(st)], 1.0, None,
            dict(pivot=(16, 56), z='YSort_Props (z_index = 10)', desc=f'SO-02 service hatch ({st})')
        ))

    # 10. SO-02 Bulkhead wall module (1)
    out.append((
        'ch01_env_wall_bulkhead_module_idle', 'environments', 32, 64,
        ['Cast_Shadow', 'Silhouette_Outline', 'Bulkhead_Wall', 'Ribs_And_Conduit'],
        [build_bulkhead_module()], 1.0, None,
        dict(pivot=(16, 56), z='YSort_Props (z_index = 10)', desc='SO-02 bulkhead wall module')
    ))

    # 11. SO-02 Floor plates A & B (4)
    for ltr in ('a', 'b'):
        for st_name, pressed in (('empty', False), ('pressed', True)):
            out.append((
                f'ch01_prop_floor_plate_{ltr}_{st_name}', 'props', 32, 16,
                ['Cast_Shadow', 'Silhouette_Outline', 'Plate_Frame', 'Plate_Glyph'],
                [build_floor_plate_ab(ltr, pressed)], 1.0, None,
                dict(pivot=(16, 8), z='YSort_Props (z_index = 1, floor-flush)', desc=f'SO-02 floor plate {ltr.upper()} ({st_name})')
            ))

    # 12. SO-02 Bell icon (2)
    for st in ('idle', 'ringing'):
        out.append((
            f'ch01_prop_bell_icon_{st}', 'props', 8, 8,
            ['Bell_Backing', 'Bell_And_Strikes'],
            [build_bell_icon(st)], 1.0, None,
            dict(pivot=(4, 4), z='YSort_Props +1 (overhead icon)', desc=f'SO-02 8x8 bell icon ({st})')
        ))

    # 13. PZ-002 Inner shutter (2)
    for st in ('closed', 'raised'):
        out.append((
            f'ch01_prop_inner_shutter_{st}', 'props', 32, 64,
            ['Cast_Shadow', 'Silhouette_Outline', 'Portal_Frame', 'Shutter_Slats'],
            [build_inner_shutter(st)], 1.0, None,
            dict(pivot=(16, 56), z='YSort_Props (z_index = 10)', desc=f'PZ-002 inner shutter ({st})')
        ))

    # 14. PZ-003 Echo pedestal (2)
    for st in ('idle', 'used'):
        out.append((
            f'ch01_prop_echo_pedestal_{st}', 'props', 24, 36,
            ['Cast_Shadow', 'Silhouette_Outline', 'Pedestal_Body', 'Dial_And_Twin_Marks'],
            [build_echo_pedestal(st)], 1.0, None,
            dict(pivot=(12, 30), z='YSort_Props (z_index = 10)', desc=f'PZ-003 Echo pedestal ({st})')
        ))

    # 15. PZ-003 Card reader (3)
    for st in ('idle', 'denied', 'accepted'):
        out.append((
            f'ch01_prop_card_reader_{st}', 'props', 16, 24,
            ['Cast_Shadow', 'Silhouette_Outline', 'Reader_Housing', 'Status_Glyph'],
            [build_card_reader(st)], 1.0, None,
            dict(pivot=(8, 20), z='YSort_Props (z_index = 10)', desc=f'PZ-003 security card reader ({st})')
        ))

    # 16. PZ-003 Staff barrier (2)
    for st in ('closed', 'open'):
        out.append((
            f'ch01_prop_staff_barrier_{st}', 'props', 32, 64,
            ['Cast_Shadow', 'Silhouette_Outline', 'Portal_Frame', 'Barrier_Arms'],
            [build_staff_barrier(st)], 1.0, None,
            dict(pivot=(16, 56), z='YSort_Props (z_index = 10)', desc=f'PZ-003 staff barrier ({st})')
        ))

    # 17. PZ-003 Alarm plate (2)
    for st in ('idle', 'ringing'):
        out.append((
            f'ch01_prop_alarm_plate_{st}', 'props', 32, 16,
            ['Cast_Shadow', 'Silhouette_Outline', 'Plate_Frame', 'Bell_And_Strikes'],
            [build_alarm_plate(st)], 1.0, None,
            dict(pivot=(16, 8), z='YSort_Props (z_index = 1, floor-flush)', desc=f'PZ-003 alarm floor plate ({st})')
        ))

    # 18. PZ-004 Breaker C (3)
    for st in ('idle', 'engaged', 'browned_out'):
        out.append((
            f'ch01_prop_breaker_c_{st}', 'props', 24, 36,
            ['Cast_Shadow', 'Silhouette_Outline', 'Breaker_Box', 'Lamp_Ring_And_Lever'],
            [build_breaker_c(st)], 1.0, None,
            dict(pivot=(12, 32), z='YSort_Props (z_index = 10)', desc=f'PZ-004 substation breaker C ({st})')
        ))

    # 19. PZ-005 Standby plate (2)
    for st in ('empty', 'held'):
        out.append((
            f'ch01_prop_standby_plate_{st}', 'props', 32, 16,
            ['Cast_Shadow', 'Silhouette_Outline', 'Plate_Frame', 'Footprint_Glyph'],
            [build_standby_plate(st)], 1.0, None,
            dict(pivot=(16, 8), z='YSort_Props (z_index = 1, floor-flush)', desc=f'PZ-005 standby floor plate ({st})')
        ))

    # 20. PZ-005 Dead relay lever C (2)
    for st in ('idle', 'shake'):
        out.append((
            f'ch01_prop_dead_relay_c_{st}', 'props', 24, 36,
            ['Cast_Shadow', 'Silhouette_Outline', 'Relay_Housing', 'Lever_And_Disconnected_Lug'],
            [build_dead_relay_c(st)], 1.0, None,
            dict(pivot=(12, 32), z='YSort_Props (z_index = 10)', desc=f'PZ-005 dead relay lever C ({st})')
        ))

    return out


if __name__ == '__main__':
    all_a = assets()
    ims = [to_image(composite(frames[0])) for (_, _, _, _, _, frames, _, _, _) in all_a]
    preview(ims, os.path.join(SCR, 'step1_props_prev.png'), zoom=2)
    print('props ok:', len(all_a))
