"""TLF-081: 13 Concourse West face-specific variants, authored/checked by Sol.

Wall drawing primitives adapted from Argon's uncommitted 2026-11-10 draft;
validator, mount contract, unclipped proofs and checks authored by Sol.
No scenes, old frontal sources, palette, fallen conduit or narrative text change.
All wall layers (including shadows and ringing accents) share the same 2:1 map.
N: y=x//2+z. W: y=(width-1)//2-x//2+z.
Run gen_all.py --only <stem> --export; registry owns PNG/PXO production.
Proofs: python tools/art/gen/tlf081_concourse_wall_art.py
"""
import os
from PIL import Image
from lib import Layer, PAL, REPO
from props import Iso, fill_poly
from tlf068_shape_kit import _draw_text_img

O = 0
SH = 1
G0, G1, G2, G3, G4 = 11, 12, 13, 14, 15


# ============================================================================
# 0. 2:1 WALL-SLOPE PROJECTION HELPERS
# ============================================================================

def _y_n_wall_32(x, z):
    """Screen y on a 32px-wide N-wall fixture canvas (slope down-right, top-left pivot (0, 0)).
    For x in 0..31, (x // 2) is in 0..15."""
    return (x // 2) + z


def _y_w_wall_24(x, z):
    """Screen y on a 24px-wide W-wall fixture canvas (slope down-left, top-left pivot (0, 11)).
    For x in 0..23, 11 - (x // 2) is in 11..0."""
    return 11 - (x // 2) + z


def _y_w_wall_48(x, z):
    """Screen y on a 48px-wide W-wall fixture canvas (slope down-left, top-left pivot (0, 23)).
    For x in 0..47, 23 - (x // 2) is in 23..0."""
    return 23 - (x // 2) + z


def _y_w_wall_16(x, z):
    """Screen y on a 16px-wide W-wall fixture canvas (slope down-left, top-left pivot (0, 7)).
    For x in 0..15, 7 - (x // 2) is in 7..0."""
    return 7 - (x // 2) + z


def _project_layer(src_planar, dst_w, dst_h, y_fn):
    """Project a planar (x, z) Layer onto a sheared (dst_w, dst_h) Layer via y = y_fn(x, z)."""
    out = Layer(dst_w, dst_h, src_planar.name)
    for z in range(src_planar.h):
        row = src_planar.p[z]
        for x in range(src_planar.w):
            c = row[x]
            if c is not None:
                y = y_fn(x, z)
                if not (0 <= x < dst_w and 0 <= y < dst_h):
                    raise ValueError(f"Projection clips {src_planar.name} at {(x, y)}")
                out.put(x, y, c)
    return out


def _outline_planar(w, h, *layers):
    """Build 1px #0A0D14 outer silhouette outline in planar (x, z) coordinates before 2:1 shearing."""
    ol = Layer(w, h, 'Silhouette_Outline')
    mask = set()
    for L in layers:
        mask |= L.mask()
    for (x, z) in sorted(mask):
        for nx, nz in ((x - 1, z), (x + 1, z), (x, z - 1), (x, z + 1)):
            if (nx, nz) not in mask and 0 <= nx < w and 0 <= nz < h:
                ol.put(nx, nz, O)
    return ol


def _steel_panel_planar(L, x0, z0, x1, z1, bevel_light=G3, mid=G2, shad=G1, dark=G0):
    """Draw a top-left-lit beveled worn-steel rectangular housing in planar (x, z) space."""
    L.rect(x0, z0, x1, z1, mid)
    L.hline(x0, x1, z0, bevel_light)
    L.vline(x0, z0, z1, bevel_light)
    L.hline(x0, x1, z1, dark)
    L.vline(x1, z0, z1, shad)
    L.put(x0, z0, G4)
    for rx, rz in ((x0 + 1, z0 + 1), (x1 - 1, z0 + 1), (x0 + 1, z1 - 1), (x1 - 1, z1 - 1)):
        if x0 < rx < x1 and z0 < rz < z1:
            L.put(rx, rz, dark)


# ============================================================================
# 1. PZ-006 SPLIT-FLAP DIALS — N-WALL VARIANTS (6 assets, 32x48 px)
#    Stems: ch01_prop_flap_dial_{line,platform,time}_n_{idle,jammed}
#    Slope: N-wall down-right y_N(x, z) = (x // 2) + z
# ============================================================================

FLAP_DIAL_LAYERS = ['Cast_Shadow', 'Silhouette_Outline', 'Dial_Housing', 'Flap_And_Header_Glyph']


def build_flap_dial_n(kind, state):
    """Build sheared 2:1 N-wall split-flap dial (32x48 px).
    Planar coordinates z = y_frontal - 2 (z in 0..28):
      - Outline: x=2..29, z=0..26
      - Housing: x=3..28, z=1..25
      - Shadow:  x=4..29, z=2..28
    Preserves the exact header glyphs (LINE circle/diamond/triangle, PLATFORM I/II/III, TIME clock hand),
    clean split-flap recess (zero baked text), and jammed tilted-flap + diagonal seam gap of step1_props.py."""
    pw, ph = 32, 30
    dw, dh = 32, 48

    sh_p = Layer(pw, ph, 'Cast_Shadow')
    sh_p.rect(4, 2, 29, 28, SH)

    B_p = Layer(pw, ph, 'Dial_Housing')
    D_p = Layer(pw, ph, 'Flap_And_Header_Glyph')

    _steel_panel_planar(B_p, 3, 1, 28, 25)
    # Top header bar (x=4..27, z=2..8) with mechanical header glyph
    B_p.rect(4, 2, 27, 8, G1)
    B_p.hline(4, 27, 8, G0)

    if kind == 'line':
        # Circle at x=8..10, z=4..6
        D_p.rect(8, 4, 10, 6, G4)
        D_p.put(9, 5, G1)
        # Diamond at x=15..17, z=3..5
        D_p.put(16, 3, 26)
        D_p.hline(15, 17, 4, 25)
        D_p.put(16, 5, 25)
        # Triangle at x=20..24, z=4..6
        D_p.put(22, 4, G4)
        D_p.hline(21, 23, 5, G4)
        D_p.hline(20, 24, 6, G3)
    elif kind == 'platform':
        # 'I  II  III' platform tally bars at z=3..6
        D_p.vline(9, 3, 6, G4)
        D_p.vline(14, 3, 6, 26)
        D_p.vline(16, 3, 6, 26)
        D_p.vline(20, 3, 6, G3)
        D_p.vline(22, 3, 6, G3)
        D_p.vline(24, 3, 6, G3)
    elif kind == 'time':
        # Miniature clock dial with L-hands at x=13..18, z=3..7
        D_p.rect(13, 3, 18, 7, O)
        D_p.put(15, 4, 26)
        D_p.put(15, 5, 26)
        D_p.put(16, 5, 26)
        D_p.put(17, 5, 25)
        D_p.put(9, 5, G4)
        D_p.put(22, 5, G4)

    # Split-flap card recess (x=5..26, z=10..23) — clean of baked text
    B_p.rect(5, 10, 26, 23, O)
    if state == 'idle':
        # Level upper flap (z=11..16) and lower flap (z=18..22) separated by center seam at z=17
        D_p.rect(6, 11, 25, 16, 2)
        D_p.hline(6, 25, 11, 3)
        D_p.hline(5, 26, 17, O)
        D_p.rect(6, 18, 25, 22, 1)
        D_p.put(5, 17, G4)
        D_p.put(26, 17, G4)
        if kind == 'time':
            D_p.put(15, 14, G3)
            D_p.put(15, 20, G3)
    else:
        # JAMMED: upper flap cocked diagonally (tilts from z=12 on left to z=9 on right),
        # exposing diagonal metal seam gap and protruding right-hinge fault pin
        for x in range(6, 26):
            top_z = 12 - (x - 6) // 6
            bot_z = top_z + 5
            for z in range(top_z, bot_z + 1):
                D_p.put(x, z, 3 if z == top_z else 2)
            D_p.put(x, bot_z + 1, O)
            D_p.put(x, bot_z + 2, G3 if (x % 3 != 0) else 24)
        D_p.rect(6, 19, 25, 22, 1)
        D_p.rect(25, 15, 27, 17, 23)
        D_p.put(26, 15, 24)

    ol_p = _outline_planar(pw, ph, B_p, D_p)
    return [
        _project_layer(sh_p, dw, dh, _y_n_wall_32),
        _project_layer(ol_p, dw, dh, _y_n_wall_32),
        _project_layer(B_p, dw, dh, _y_n_wall_32),
        _project_layer(D_p, dw, dh, _y_n_wall_32),
    ]


# ============================================================================
# 2. CALL-BOX PHONE — W-WALL VARIANTS (2 assets, 24x48 px)
#    Stems: ch01_prop_call_box_phone_w_{idle,ringing}
#    Slope: W-wall down-left y_W24(x, z) = 11 - (x // 2) + z
# ============================================================================

CALL_BOX_W_LAYERS = ['Mount_Shadow', 'Casing', 'Handset_And_Lamp']


def build_call_box_phone_w(ringing=False):
    """Build sheared 2:1 W-wall call-box phone (24x48 px).
    Preserves the exact casing, speaker grille, handset cradle, keypad pips, status lamp,
    and 6 ringing strike marks of props.call_box(ringing), projected onto the 2:1 W wall plane
    with a flush wall-mount shadow."""
    pw, ph = 24, 36
    dw, dh = 24, 48

    sh_p = Layer(pw, ph, 'Mount_Shadow')
    sh_p.rect(3, 5, 22, 33, SH)

    L_p = Layer(pw, ph, 'Casing')
    D_p = Layer(pw, ph, 'Handset_And_Lamp')

    L_p.rect(2, 4, 21, 31, 13)            # casing body
    L_p.rect(2, 4, 21, 5, 15)             # top specular ridge
    L_p.rect(2, 6, 3, 31, 14)             # NW lit left bevel
    L_p.rect(20, 6, 21, 31, 12)           # shaded right bevel
    L_p.rect(2, 30, 21, 31, 11)           # base lip
    L_p.rect(5, 8, 18, 15, 11)            # speaker/grille recess
    for zz in (9, 11, 13):
        L_p.hline(6, 17, zz, 12)
    L_p.rect(5, 17, 12, 27, 12)           # handset cradle recess
    L_p.rect(14, 17, 18, 27, 12)          # keypad plate
    for i in range(3):
        for j in range(4):
            L_p.put(14 + i, 18 + j * 2, 14)

    # Handset & coiled cord
    D_p.rect(6, 18, 11, 19, 15)
    D_p.rect(6, 25, 11, 26, 15)
    D_p.rect(7, 20, 9, 24, 14)
    D_p.rect(9, 20, 10, 24, 13)
    D_p.put(12, 22, 11)
    D_p.put(13, 23, 11)

    # Status lamp + ringing strike marks (shape cue)
    if ringing:
        D_p.rect(16, 7, 18, 8, 25)
        D_p.put(17, 7, 26)
        for (rx, rz) in ((1, 2), (0, 4), (22, 2), (23, 4), (1, 0), (22, 0)):
            D_p.put(rx, rz, 26)
    else:
        D_p.rect(16, 7, 18, 8, 22)

    # 1px #0A0D14 outer outline in planar (x, z) space on Casing layer (matching props.call_box)
    mask = L_p.mask() | D_p.mask()
    for (x, z) in sorted(mask):
        for nx, nz in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
            if (nx, nz) not in mask and 0 <= nx < pw and 0 <= nz < ph and L_p.get(nx, nz) is None:
                L_p.put(nx, nz, O)

    return [
        _project_layer(sh_p, dw, dh, _y_w_wall_24),
        _project_layer(L_p, dw, dh, _y_w_wall_24),
        _project_layer(D_p, dw, dh, _y_w_wall_24),
    ]


# ============================================================================
# 3. PZ-001 OVERHEAD CONDUIT — W-WALL MOUNTED VARIANT (1 asset, 48x40 px)
#    Stem:  ch01_prop_conduit_w_mounted
#    Slope: W-wall down-left y_W48(x, z) = 23 - (x // 2) + z
# ============================================================================

CONDUIT_W_LAYERS = ['Cast_Shadow', 'Silhouette_Outline', 'Brackets_And_Pipe', 'Wires_And_Clamps']


def build_conduit_w_mounted():
    """Build sheared 2:1 W-wall mounted conduit (48x40 px).
    Planar coordinates z = y_frontal - 1 (z in 0..13):
      - Two wall brackets at x=8..13, z=1..8 and x=34..39, z=1..8
      - Straight conduit pipe bolted along the W wall slope at x=3..44, z=4..10
      - Three collar straps with brass bolts at cx=9, 22, 35, z=3..11
      - 1px #0A0D14 silhouette outline at x=2..45, z=0..12
      - Flush wall-mount shadow at x=4..46, z=2..13 (replacing the detached floor shadow)."""
    pw, ph = 48, 16
    dw, dh = 48, 40

    sh_p = Layer(pw, ph, 'Cast_Shadow')
    sh_p.rect(9, 2, 15, 10, SH)
    sh_p.rect(35, 2, 41, 10, SH)
    sh_p.rect(4, 5, 46, 13, SH)

    B_p = Layer(pw, ph, 'Brackets_And_Pipe')
    D_p = Layer(pw, ph, 'Wires_And_Clamps')

    # Two wall mounting brackets at x=8..13, z=1..8 and x=34..39, z=1..8
    _steel_panel_planar(B_p, 8, 1, 13, 8, bevel_light=G3, mid=G2, shad=G1, dark=G0)
    _steel_panel_planar(B_p, 34, 1, 39, 8, bevel_light=G3, mid=G2, shad=G1, dark=G0)

    # Straight conduit pipe bolted across x=3..44, z=4..10
    B_p.rect(3, 4, 44, 10, G2)
    B_p.hline(3, 44, 4, G4)
    B_p.hline(3, 44, 5, G3)
    B_p.hline(3, 44, 9, G1)
    B_p.hline(3, 44, 10, G0)

    # Intact collar straps over brackets + center coupling
    for cx in (9, 22, 35):
        D_p.rect(cx, 3, cx + 3, 11, G3)
        D_p.vline(cx, 3, 11, G4)
        D_p.vline(cx + 3, 3, 11, G0)
        D_p.put(cx + 1, 7, 25)

    ol_p = _outline_planar(pw, ph, B_p, D_p)
    return [
        _project_layer(sh_p, dw, dh, _y_w_wall_48),
        _project_layer(ol_p, dw, dh, _y_w_wall_48),
        _project_layer(B_p, dw, dh, _y_w_wall_48),
        _project_layer(D_p, dw, dh, _y_w_wall_48),
    ]


# ============================================================================
# 4. PZ-006 TICKET-TERMS NOTICE — W-WALL VARIANT (1 asset, 16x28 px)
#    Stem:  ch01_prop_ticket_terms_notice_w_idle
#    Slope: W-wall down-left y_W16(x, z) = 7 - (x // 2) + z
# ============================================================================

TICKET_TERMS_W_LAYERS = ['Cast_Shadow', 'Silhouette_Outline', 'Plaque_Back', 'Paper_Notice']


def build_ticket_terms_notice_w():
    """Build sheared 2:1 W-wall ticket-terms notice plaque (16x28 px).
    Planar coordinates z = y_frontal - 1 (z in 0..17):
      - Outline: x=1..14, z=0..16
      - Steel plaque backing: x=2..13, z=1..15
      - Paper sheet with dog-ear corner, header bar, 3 ruled lines, and crimson seal dot: x=4..11, z=3..13
      - Flush down-right wall shadow: x=3..15, z=2..17
      - Zero invented readable text."""
    pw, ph = 16, 19
    dw, dh = 16, 28

    sh_p = Layer(pw, ph, 'Cast_Shadow')
    sh_p.rect(3, 2, 15, 17, SH)

    B_p = Layer(pw, ph, 'Plaque_Back')
    D_p = Layer(pw, ph, 'Paper_Notice')

    _steel_panel_planar(B_p, 2, 1, 13, 15, bevel_light=G3, mid=G1, shad=G0, dark=O)
    # Pale paper sheet (x=4..11, z=3..13) with folded bottom-right corner
    D_p.rect(4, 3, 11, 13, 19)
    D_p.hline(4, 11, 3, G4)
    D_p.vline(4, 3, 13, G4)
    D_p.put(11, 13, G1)  # dog-ear corner
    # Header bar + 3 quiet ruled lines (no numbers or letters)
    D_p.hline(5, 10, 5, 17)
    D_p.hline(5, 10, 8, 18)
    D_p.hline(5, 10, 10, 18)
    D_p.hline(5, 8, 12, 18)
    # Subdued crimson transit seal dot at bottom-right
    D_p.put(10, 11, 23)

    ol_p = _outline_planar(pw, ph, B_p, D_p)
    return [
        _project_layer(sh_p, dw, dh, _y_w_wall_16),
        _project_layer(ol_p, dw, dh, _y_w_wall_16),
        _project_layer(B_p, dw, dh, _y_w_wall_16),
        _project_layer(D_p, dw, dh, _y_w_wall_16),
    ]


# ============================================================================
# 5. ASSET REGISTRY EXPORT (10 wall states + 3 freestanding validator states)
# ============================================================================

def assets():
    out = []
    # 1. 6 N-wall split-flap dials (32x48 px)
    for kind in ('line', 'platform', 'time'):
        for st in ('idle', 'jammed'):
            stem = f'ch01_prop_flap_dial_{kind}_n_{st}'
            out.append((
                stem,
                'props',
                32, 48,
                FLAP_DIAL_LAYERS,
                [build_flap_dial_n(kind, st)],
                1.0,
                None,
                'TLF-081',
            ))
    # 2. 2 W-wall call-box phones (24x48 px)
    for st, ringing in (('idle', False), ('ringing', True)):
        stem = f'ch01_prop_call_box_phone_w_{st}'
        out.append((
            stem,
            'props',
            24, 48,
            CALL_BOX_W_LAYERS,
            [build_call_box_phone_w(ringing)],
            1.0,
            None,
            'TLF-081',
        ))
    # 3. 1 W-wall mounted conduit (48x40 px)
    out.append((
        'ch01_prop_conduit_w_mounted',
        'props',
        48, 40,
        CONDUIT_W_LAYERS,
        [build_conduit_w_mounted()],
        1.0,
        None,
        'TLF-081',
    ))
    # 4. 1 W-wall ticket-terms notice plaque (16x28 px)
    out.append((
        'ch01_prop_ticket_terms_notice_w_idle',
        'props',
        16, 28,
        TICKET_TERMS_W_LAYERS,
        [build_ticket_terms_notice_w()],
        1.0,
        None,
        'TLF-081',
    ))
    for state in ('idle', 'rejecting', 'accepted'):
        out.append((f'ch01_prop_ticket_validator_n_{state}', 'props', 32, 48,
                    VALIDATOR_N_LAYERS, [build_ticket_validator_n(state)], 1.0, None,
                    'TLF-081'))
    return out


VALIDATOR_N_LAYERS = ['Floor_Contact_Shadow', 'Plinth_And_Cabinet_Volume',
                      'N_Working_Face', 'Glyph_And_Slot']
VALIDATOR_PIVOT = (16, 42)
VALIDATOR_COLLISION_SIZE = (16, 8)  # Existing Area2D rectangle; integration must not resize it.


def build_ticket_validator_n(state):
    """32x48 floor-standing cabinet, N-parallel front; NOT a projected wall plaque.

    Floor plinth is a 16x8 iso diamond centred on (16,42). The upper cabinet
    overhangs the plinth, as the old 24px-wide frontal housing overhangs its
    16x8 collider. Top and dark W return remain visible in every state.
    The front uses the existing idle dash / reject X / accept chevron pair,
    plus the ejected vs swallowed ticket edge from step1_props.py.
    """
    if state not in ('idle', 'rejecting', 'accepted'):
        raise ValueError(state)
    shadow = Layer(32, 48, VALIDATOR_N_LAYERS[0])
    fill_poly(shadow, [(7, 42), (16, 37), (26, 42), (17, 47)], lambda x, y: SH)
    body = Layer(32, 48, VALIDATOR_N_LAYERS[1])
    iso = Iso(body, VALIDATOR_PIVOT)
    iso.box(-.25, -.25, 0, .25, .25, 4, G2, G1, G0)
    iso.box(-.5, -.25, 4, .5, .25, 32, G3, G2, G1)
    # Two crisp top-plane edges distinguish a cabinet from a sheared poster.
    body.line(4, 8, 12, 4, G4)
    body.line(12, 4, 28, 12, G3)
    body.line(20, 16, 28, 12, G0)
    body.line(27, 14, 27, 38, G0)

    face = Layer(32, 30, VALIDATOR_N_LAYERS[2])
    glyph = Layer(32, 30, VALIDATOR_N_LAYERS[3])
    _steel_panel_planar(face, 5, 1, 19, 26)
    face.rect(7, 3, 17, 11, O)
    face.rect(8, 4, 16, 10, 2)
    if state == 'idle':
        glyph.hline(10, 13, 7, G3)
    elif state == 'rejecting':
        for i in range(5):
            glyph.put(9 + i, 5 + i, 24)
            glyph.put(13 - i, 5 + i, 24)
        glyph.put(11, 7, 26)
    else:
        # Preserve the original two drawn chevrons (metadata calls them >>>).
        for cx in (8, 12):
            for dx, z, c in ((0, 5, 26), (1, 6, 26), (2, 7, 26),
                              (1, 8, 25), (0, 9, 25)):
                glyph.put(cx + dx, z, c)
    _steel_panel_planar(face, 7, 14, 17, 21, bevel_light=G2, mid=G1, shad=G0, dark=O)
    glyph.rect(9, 16, 15, 17, O)
    if state == 'rejecting':
        glyph.rect(10, 17, 14, 23, G4)
        glyph.hline(10, 14, 23, 23)
    elif state == 'accepted':
        glyph.hline(10, 14, 16, 26)
    project_front = lambda x, z: x // 2 + 6 + z
    return [shadow, body, _project_layer(face, 32, 48, project_front),
            _project_layer(glyph, 32, 48, project_front)]


# Actual module-relative top-lefts, including all opaque shadows/accents.
# N module (32x64): face top y=x//2. W: y=15-x//2.
# The conduit spans two W modules at (0,16) and (32,0) in a 64x80 assembly.
WALL_MOUNTS = {
    'dial': dict(face='n', offset=(0, 6), pivot=(0, 0), modules=((0, 0),)),
    'phone': dict(face='w', offset=(4, 4), pivot=(0, 11), modules=((0, 0),)),
    'conduit': dict(face='w', offset=(8, 10), pivot=(0, 23), modules=((0, 16), (32, 0))),
    'terms': dict(face='w', offset=(8, 18), pivot=(0, 7), modules=((0, 0),)),
}


def mount_family(stem):
    if 'flap_dial_' in stem:
        return 'dial'
    if 'call_box_' in stem:
        return 'phone'
    if 'conduit_' in stem:
        return 'conduit'
    if 'terms_' in stem:
        return 'terms'
    return None  # Floor-standing validator has no wall mount.


PROOF_FILES = ('tlf081_modules_1x.png', 'tlf081_modules_x2.png',
               'tlf081_modules_greyscale_1x.png', 'tlf081_modules_greyscale_x2.png')
MOCKUP_FILES = PROOF_FILES


def mockup_path(fname, out_dir=None):
    return os.path.join(out_dir or os.path.join(REPO, 'docs', 'handoffs', 'TLF-081'), fname)


def _export(folder, stem):
    # Proofs deliberately load delivered PNGs, never a hidden generator fallback.
    with Image.open(os.path.join(REPO, 'assets', folder, 'ch01', stem + '.png')) as im:
        return im.convert('RGBA')


def wall_assembly(mount):
    wall = _export('environments', f'ch01_env_wall_subterranean_{mount["face"]}_idle')
    modules = mount['modules']
    im = Image.new('RGBA', (max(x for x, y in modules) + 32,
                            max(y for x, y in modules) + 64))
    for xy in modules:
        im.alpha_composite(wall, xy)
    return im


def build_module_proof():
    """960x540 native proof: every delivered state on production wall/floor modules.

    No rescale, clipping, crosshairs or overpainting on reviewed asset pixels.
    Labels live outside the module rectangles; the bank at bottom uses v2
    proposed real spacing, including the existing clock, bench and Elias.
    This is a source assembly, not a screenshot of an integrated TLF-080 room.
    """
    im = Image.new('RGBA', (960, 540), PAL[0] + (255,))

    def label(x, y, s, c=15):
        _draw_text_img(im, x, y, s, PAL[c], scale=1)

    label(24, 12, 'TLF-081 / 13 NEW STATES / NATIVE 960X540 / SOURCE MODULE PROOF')
    label(24, 26, 'N DOWN-RIGHT + W DOWN-LEFT / 2:1 / NO ROOM OR LIGHTING APPROVAL', 14)
    for row, state in enumerate(('idle', 'jammed')):
        for col, kind in enumerate(('line', 'platform', 'time')):
            pos = (32 + col * 112, 64 + row * 140)
            label(pos[0], pos[1] - 16, f'{kind.upper()} {state.upper()}')
            mount = WALL_MOUNTS['dial']
            im.alpha_composite(wall_assembly(mount), pos)
            im.alpha_composite(_export('props', f'ch01_prop_flap_dial_{kind}_n_{state}'),
                               (pos[0], pos[1] + 6))
    for col, state in enumerate(('idle', 'ringing')):
        pos = (392 + col * 112, 64)
        label(pos[0], 48, f'PHONE {state.upper()}')
        im.alpha_composite(wall_assembly(WALL_MOUNTS['phone']), pos)
        im.alpha_composite(_export('props', f'ch01_prop_call_box_phone_w_{state}'),
                           (pos[0] + 4, pos[1] + 4))
    for family, stem, pos in (
        ('conduit', 'ch01_prop_conduit_w_mounted', (392, 204)),
        ('terms', 'ch01_prop_ticket_terms_notice_w_idle', (504, 204)),
    ):
        label(pos[0], 188, family.upper())
        mount = WALL_MOUNTS[family]
        im.alpha_composite(wall_assembly(mount), pos)
        dx, dy = mount['offset']
        im.alpha_composite(_export('props', stem), (pos[0] + dx, pos[1] + dy))
    floor = _export('environments', 'ch01_env_tile_terrazzo_dark_idle')
    for col, state in enumerate(('idle', 'rejecting', 'accepted')):
        x = 632 + col * 104
        label(x, 48, state.upper())
        # Native floor tile centre (x+24,112) = cabinet's floor pivot.
        im.alpha_composite(floor, (x + 8, 104))
        im.alpha_composite(_export('props', f'ch01_prop_ticket_validator_n_{state}'), (x + 8, 70))
    label(632, 148, 'VALIDATOR: FLOOR-STANDING N FACE', 14)
    label(632, 164, 'TOP + W RETURN + 16X8 PLINTH', 14)
    label(632, 180, 'PIVOT (16,42); NO COLLIDER CHANGE', 14)
    label(632, 220, '10 WALL STATES + 3 CABINET STATES', 14)
    label(632, 236, 'OLD FRONTAL + FALLEN FILES RETAINED', 14)
    label(632, 252, 'NO NEW COLOURS OR NARRATIVE TEXT', 14)

    label(32, 322, 'N BANK / PROPOSED V2 SPACING / CLOCK + BENCH REUSED')
    # World (480,96) -> proof (32,356). N modules 5..10, unchanged exports.
    wall = _export('environments', 'ch01_env_wall_subterranean_n_idle')
    for k in range(6):
        im.alpha_composite(wall, (32 + k * 32, 356 + k * 16))
    im.alpha_composite(_export('props', 'ch01_prop_digital_clock_2359_n_idle'), (32, 359))
    for k, kind in enumerate(('line', 'platform', 'time')):
        im.alpha_composite(_export('props', f'ch01_prop_flap_dial_{kind}_n_idle'),
                           (96 + k * 32, 394 + k * 16))
    im.alpha_composite(_export('props', 'ch01_prop_station_bench_idle'), (24, 418))
    elias = _export('characters', 'ch01_char_elias_base_sheet').crop((30 * 32, 0, 31 * 32, 48))
    im.alpha_composite(elias, (80, 424))
    im.alpha_composite(floor, (192, 492))
    im.alpha_composite(_export('props', 'ch01_prop_ticket_validator_n_idle'), (192, 458))
    label(352, 362, 'DIAL PRESENTERS REQUIRE NEW MOUNTS', 14)
    label(352, 378, 'HUD OWNS DIAL VALUES; NO ANSWERS BAKED', 14)
    label(352, 410, 'PHONE: (4,4) ON W MODULE', 14)
    label(352, 426, 'CONDUIT: (8,10) ON TWO W MODULES', 14)
    label(352, 442, 'NOTICE: (8,18) ON W MODULE', 14)
    label(352, 474, 'TINY NATIVE GLYPHS ARE FAMILY/STATE CUES', 14)
    label(352, 490, 'FINAL ROOM / HUD / LIGHTING NEED INTEGRATION REVIEW', 14)
    return im


def write_mockups(out_dir=None):
    os.makedirs(out_dir or os.path.dirname(mockup_path(PROOF_FILES[0])), exist_ok=True)
    native = build_module_proof()
    grey = native.convert('L').convert('RGBA')
    for fname, im in zip(PROOF_FILES, (native, native.resize((1920, 1080), Image.Resampling.NEAREST),
                                     grey, grey.resize((1920, 1080), Image.Resampling.NEAREST))):
        im.save(mockup_path(fname, out_dir))


if __name__ == '__main__':
    write_mockups()
    print('TLF-081: native + nearest x2 colour/greyscale proofs written.')
