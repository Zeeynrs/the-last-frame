"""Step 1 frozen commuters ('statues'), prop overlays, Trace shimmer ring, time-stamp glyph, and static 'read' outlines (TLF-057).

Visual direction (Sol, Art Director, 2026-11-05):
- Arrested human gestures at 23:59, not carved stone monuments.
- Five existing greys from TLF-CH01-32 only:
    11 (#1B1E24 Cast Iron Dark)    - deepest crease / under-plane shadow
    12 (#2E333D Gunmetal Shadow)   - shaded SE/bottom-right body planes
    13 (#464E5C Brushed Steel Mid) - primary statue body mid-tone
    14 (#677385 Steel Bevel Light) - NW top-left key-lit planes
    15 (#94A2B8 Chrome Specular)   - sparse crown / NW shoulder peak
- 00 (#0A0D14) 1px outer silhouette outline on a separate/dedicated outline pass; 01 (#141A26) compact down-right floor shadow.
- Broad quiet grey planes: no skin tones (20/21), no white eyes (31), no icy crust, no glow fill, no stone cracks.
- One subdued accent per commuter confined to coat/bag/overlay (#8C2D19 idx 23, #594438 idx 18, #3B2D26 idx 17, #263545 idx 07, #364B5E idx 08, #4A1C14 idx 22, #16425B idx 27).
- Canvas: 16 x 40 px, foot pivot (8, 36), 12 x 8 px collider footprint.
- Trace VFX:
    - 24 x 12 px foot ellipse, 4 restrained stepped highlight frames (96 x 12 px strip @ 8 FPS), violet 30 + sparse gold 26.
    - 6 x 6 px clock-hand time-stamp glyph above the head (violet 30 + gold 26 hands over dark 00).
    - Static 'read' variant: 1px silhouette outline in violet 30 (with sparse gold 26 at NW crown), no animation (also used for reduced_effects).
"""
import os
from lib import *

W, H = 16, 40
PIVOT = (8, 36)

# Statue grey ramp (indices 11..15) + outline 0 + cast shadow 1
O = 0
SH = 1
G0, G1, G2, G3, G4 = 11, 12, 13, 14, 15


def _art(L, x0, y0, rows, cmap):
    """Stamp an ASCII pixel grid onto Layer L at (x0, y0)."""
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            c = cmap.get(ch)
            if c is not None:
                L.put(x0 + dx, y0 + dy, c)


def _shadow(cx=8, cy=36, rx=5, ry=2):
    """Compact down-right floor shadow ellipse at the feet (biased +1px X, +1px Y per top-left key light)."""
    S = Layer(W, H, 'Cast_Shadow')
    for y in range(H):
        for x in range(W):
            dx = (x - (cx + 0.5)) / float(rx)
            dy = (y - (cy + 0.5)) / float(ry)
            if dx * dx + dy * dy <= 1.0:
                S.put(x, y, SH)
    return S


def _outline_layer(mask, mode='idle'):
    """Build the 1px outer silhouette outline Layer around `mask`.
    mode='idle': 1px #0A0D14 (index 0) silhouette outline.
    mode='read': 1px static Trace-read silhouette outline (#9E7BFF index 30, with sparse #FFD166 index 26 on top-left crown)."""
    OL = Layer(W, H, 'Silhouette_Outline')
    if not mask:
        return OL
    min_y = min(y for (_, y) in mask)
    for (x, y) in sorted(mask):
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if (nx, ny) not in mask and 0 <= nx < W and 0 <= ny < H:
                if mode == 'read':
                    # Sparse gold 26 at the very top-left crown edge; violet 30 elsewhere
                    col = 26 if (ny <= min_y + 2 and nx <= 8) else 30
                else:
                    col = O
                OL.put(nx, ny, col)
    return OL


CMAP_STATUE = {
    '.': None,
    '0': G0,  # #1B1E24 deepest crease
    '1': G1,  # #2E333D shaded plane
    '2': G2,  # #464E5C mid plane
    '3': G3,  # #677385 NW key-lit plane
    '4': G4,  # #94A2B8 sparse specular peak
    # Subdued accents for specific poses / overlays
    'r': 22,  # #4A1C14 dark crimson shadow
    'R': 23,  # #8C2D19 subdued hazard crimson
    'o': 24,  # #CC4E1E muted sodium orange
    'a': 25,  # #EB8A28 brass / amber
    'g': 26,  # #FFD166 gold peak
    'b': 17,  # #3B2D26 dark leather / umber shadow
    'B': 18,  # #594438 weathered brown leather mid
    'l': 19,  # #7D614F warm tan / paper highlight
    's': 6,   # #19232E deep slate shadow
    'u': 7,   # #263545 subdued uniform dark slate
    'U': 8,   # #364B5E subdued uniform mid slate
    'c': 9,   # #4B667D ceramic slate light
    't': 27,  # #16425B deep temporal teal
}


# ==============================================================================
# 1. SIX BASE STATUE BODIES (3 builds x 2 poses) + FOUR SPECIFIC POSES
#    All 16 x 40 px, pivot (8, 36). Interior pixels fit x=1..14, y=3..36 so the
#    1px outer outline fits cleanly inside 0..15, 0..39 without clipping.
# ==============================================================================

POSE_GRIDS = {
    # Build A (slim adult, 33px tall with outline, y=5..35): Pose 1 standing at platform edge, looking SE
    'body_a_pose1': (8, 36, 5, 2, 1, 5, [
        '....4332....',  # y=5  crown
        '...433321...',  # y=6
        '...333221...',  # y=7  head (quiet broad grey planes, no eyes)
        '...332211...',  # y=8
        '....3221....',  # y=9  jaw
        '....2210....',  # y=10 neck
        '..4332211...',  # y=11 shoulders (NW lit on left)
        '..33322211..',  # y=12 upper chest
        '..33222211..',  # y=13
        '..33222111..',  # y=14 torso + slightly bent right forearm
        '..322221221.',  # y=15
        '..322221221.',  # y=16
        '..322210.21.',  # y=17 hand gesture in front
        '..322210....',  # y=18 waist
        '..332211....',  # y=19 coat skirt / hip
        '..332221....',  # y=20
        '..322221....',  # y=21
        '..322021....',  # y=22
        '..322021....',  # y=23
        '..321021....',  # y=24 coat hem
        '...32021....',  # y=25 upper legs
        '...32021....',  # y=26
        '...32021....',  # y=27
        '...32021....',  # y=28 knees
        '...32021....',  # y=29
        '...21021....',  # y=30 calves
        '...21021....',  # y=31
        '...21011....',  # y=32
        '...21011....',  # y=33 ankles
        '...21.21....',  # y=34 boots
        '...210110...',  # y=35 planted feet (1px outline sits at y=36 on shadow)
    ]),

    # Build A (slim adult, y=5..35): Pose 2 mid-action reaching/button-pressing (arm extended right)
    'body_a_pose2': (8, 36, 5, 2, 1, 5, [
        '....4332....',  # y=5
        '...433321...',  # y=6
        '...333221...',  # y=7
        '...332211...',  # y=8
        '....3221....',  # y=9
        '....2210....',  # y=10
        '..4332211...',  # y=11
        '..3332211332',  # y=12 reaching arm raised toward panel/button
        '..3322211321',  # y=13
        '..3322210...',  # y=14 clear gap under raised arm
        '..3222210...',  # y=15
        '..322211....',  # y=16
        '..322211....',  # y=17
        '..332210....',  # y=18
        '..332221....',  # y=19
        '..322221....',  # y=20
        '..322021....',  # y=21
        '..322021....',  # y=22
        '..321021....',  # y=23
        '..321021....',  # y=24
        '...32021....',  # y=25 stride legs
        '...32021....',  # y=26
        '...320.21...',  # y=27
        '...32..21...',  # y=28
        '..32...21...',  # y=29
        '..21...21...',  # y=30
        '..21...21...',  # y=31
        '..21...21...',  # y=32
        '..210..21...',  # y=33 back foot lifting, front foot planted
        '..210..210..',  # y=34
        '.......2110.',  # y=35 front sole at y=35 (outline at y=36)
    ]),

    # Build B (broad adult, heavy overcoat, wider shoulders, 34px tall with outline, y=4..35): Pose 1 standing checking wrist
    'body_b_pose1': (8, 36, 6, 2, 1, 4, [
        '....4332....',  # y=4
        '...433321...',  # y=5
        '...333221...',  # y=6
        '...332211...',  # y=7
        '....3221....',  # y=8
        '...322110...',  # y=9  thick collar
        '.433322211..',  # y=10 broad shoulders (10px wide)
        '.3333222111.',  # y=11
        '.3332222211.',  # y=12
        '.3332222211.',  # y=13
        '.3322332211.',  # y=14 left forearm angled across chest (checking wrist)
        '.3322333211.',  # y=15
        '.3222111211.',  # y=16
        '.3222221110.',  # y=17
        '.3322221110.',  # y=18 heavy coat waist
        '.332222211..',  # y=19
        '.332220211..',  # y=20
        '.322220211..',  # y=21
        '.322200211..',  # y=22
        '.322100211..',  # y=23
        '.322100211..',  # y=24 coat hem
        '..3210.211..',  # y=25
        '..3210.211..',  # y=26 trousers
        '..321..211..',  # y=27
        '..321..210..',  # y=28
        '..321..210..',  # y=29
        '..210..210..',  # y=30
        '..210..210..',  # y=31
        '..210..210..',  # y=32
        '..210..110..',  # y=33
        '..210..210..',  # y=34
        '..2110.2110.',  # y=35 heavy boots grounded at y=35 (outline at y=36)
    ]),

    # Build B (broad adult, y=4..35): Pose 2 leaning/reaching hand onto lever or breaker
    'body_b_pose2': (8, 36, 6, 2, 1, 4, [
        '.....4332...',  # y=4
        '....433321..',  # y=5
        '....333221..',  # y=6
        '....332211..',  # y=7
        '.....3221...',  # y=8
        '....322110..',  # y=9
        '..433322211.',  # y=10
        '.3333222111.',  # y=11
        '.33322221132',  # y=12 arm extended right toward lever/breaker
        '.33222221132',  # y=13
        '.33222211.21',  # y=14 hand gripping handle at right
        '.32222211...',  # y=15
        '.32222210...',  # y=16
        '.33222110...',  # y=17
        '.33222110...',  # y=18
        '..3322211...',  # y=19
        '..3222021...',  # y=20
        '..3221021...',  # y=21
        '..3221021...',  # y=22
        '..3221021...',  # y=23
        '..3210.211..',  # y=24
        '..321..211..',  # y=25
        '..321..211..',  # y=26
        '..321...21..',  # y=27
        '..210...21..',  # y=28
        '..210...21..',  # y=29
        '..210...210.',  # y=30
        '..210...210.',  # y=31
        '..210...210.',  # y=32
        '..210...110.',  # y=33
        '..2110..210.',  # y=34
        '..2110..2110',  # y=35 braced stride grounded at y=35
    ]),

    # Build C (small / shorter human, 26px tall with outline, y=12..35): Pose 1 standing turning
    # Reads clearly shorter than builds A/B (head at y=12..17, compact torso y=18..27, shorter legs y=28..35)
    'body_c_pose1': (8, 36, 4, 2, 1, 12, [
        '....4332....',  # y=12 crown (7-8px lower than adult builds!)
        '...433321...',  # y=13
        '...333221...',  # y=14 head
        '...332211...',  # y=15
        '....3221....',  # y=16 chin
        '....2210....',  # y=17 neck
        '..4332211...',  # y=18 narrow shoulders (7px wide)
        '..3322211...',  # y=19 hoodie/jacket torso
        '..33222211..',  # y=20
        '..32222211..',  # y=21 hands held at chest/waist level
        '..32233211..',  # y=22
        '..32222110..',  # y=23
        '..3322211...',  # y=24
        '..3322011...',  # y=25 jacket hem
        '...322021...',  # y=26
        '...320.21...',  # y=27 shorter legs
        '...320.21...',  # y=28
        '...32..21...',  # y=29
        '...32..21...',  # y=30
        '...21..21...',  # y=31
        '...21..21...',  # y=32
        '...21..11...',  # y=33
        '...210.21...',  # y=34
        '...210.210..',  # y=35 sneakers grounded at y=35 (outline at y=36)
    ]),

    # Build C (small / shorter human, 26px tall with outline, y=12..35): Pose 2 reaching thumb to stamp
    'body_c_pose2': (8, 36, 4, 2, 1, 12, [
        '....4332....',  # y=12
        '...433321...',  # y=13
        '...333221...',  # y=14
        '...332211...',  # y=15
        '....3221....',  # y=16
        '....2210....',  # y=17
        '..4332211...',  # y=18
        '..332221132.',  # y=19 arm reaching out to stamp
        '..3322211321',  # y=20 thumb on stamp
        '..3222210...',  # y=21
        '..3222110...',  # y=22
        '..332211....',  # y=23
        '..332221....',  # y=24
        '..332021....',  # y=25
        '...322021...',  # y=26
        '...320.21...',  # y=27
        '...32..21...',  # y=28
        '..32...21...',  # y=29
        '..32...21...',  # y=30
        '..21...21...',  # y=31
        '..21...21...',  # y=32
        '..210..11...',  # y=33
        '..210..21...',  # y=34
        '.......210..',  # y=35 planted front foot at y=35 (outline at y=36)
    ]),

    # Specific Pose 1: N-03 old man SEATED on the existing station bench (no second bench in sprite!)
    # Bench seat at (4,2) is 8..10px above pivot (y=26..28 in this 16x40 canvas), shoes grounded at y=35.
    'n03_old_man_seated': (8, 36, 4, 2, 1, 10, [
        '....4433....',  # y=10 stooped head / flat cap
        '...433321...',  # y=11
        '...333221...',  # y=12
        '...332211...',  # y=13
        '....3211....',  # y=14 chin tucked forward
        '..4332210...',  # y=15 hunched shoulders
        '.43322211...',  # y=16
        '.33322211...',  # y=17 rounded back leaning against bench backrest
        '.33222211...',  # y=18
        '.33222110...',  # y=19
        '.32222110...',  # y=20 forearms resting forward toward lap
        '.32223321...',  # y=21
        '.33223321...',  # y=22 lap / hands on knees
        '..33222211..',  # y=23 horizontal thighs seated on bench slab (y=24..26)
        '..333222211.',  # y=24
        '...11002221.',  # y=25 under-thigh crease on bench edge; knees at right
        '......32021.',  # y=26 lower legs dropping vertically in front of bench
        '......32021.',  # y=27
        '......32021.',  # y=28
        '......32021.',  # y=29
        '......21021.',  # y=30
        '......21021.',  # y=31
        '......21011.',  # y=32
        '......21011.',  # y=33
        '......21021.',  # y=34
        '......211211',  # y=35 planted shoes grounded at y=35
    ]),

    # Specific Pose 2: N-04 night cleaner mid-turn pushing trolley (body on left x=1..9 so trolley on right is separate)
    'n04_cleaner': (6, 36, 5, 2, 1, 5, [
        '..4332......',  # y=5  cap crown
        '.4333211....',  # y=6  cleaner cap visor
        '.333221.....',  # y=7  head turned SE
        '.332211.....',  # y=8
        '..3221......',  # y=9
        '..2210......',  # y=10
        '4332211.....',  # y=11 shoulders
        '33322211....',  # y=12 coverall torso
        '3322221332..',  # y=13 upper arm reaching to trolley handle
        '3322211.32..',  # y=14
        '3222210..21.',  # y=15 hands gripping trolley handle bar at x=9..10
        '322211332...',  # y=16 lower arm also reaching forward
        '3222110.....',  # y=17 waist
        '332211......',  # y=18
        '332221......',  # y=19
        '322021......',  # y=20
        '322021......',  # y=21
        '321021......',  # y=22
        '321021......',  # y=23
        '.32021......',  # y=24 coverall trousers
        '.32021......',  # y=25
        '.320.21.....',  # y=26
        '.32..21.....',  # y=27
        '.32..21.....',  # y=28
        '.21..21.....',  # y=29
        '.21..21.....',  # y=30
        '.21..11.....',  # y=31
        '.210.21.....',  # y=32
        '.210.21.....',  # y=33
        '.....210....',  # y=34
        '.....2110...',  # y=35 boots grounded at y=35
    ]),

    # Specific Pose 3: N-05 bike courier MID-VAULT (forward weight, one foot visibly lifted off floor)
    'n05_courier_vault': (10, 36, 4, 2, 1, 6, [
        '.......4332.',  # y=6  head pitched forward in sprint/vault
        '......433321',  # y=7
        '......333221',  # y=8
        '......332211',  # y=9
        '.......3221.',  # y=10
        '.....432210.',  # y=11 neck / forward shoulder
        '....4332211.',  # y=12
        '...433222133',  # y=13 forward-leaning torso + lead arm reaching out
        '...333222112',  # y=14
        '..33322211..',  # y=15
        '..33222110..',  # y=16
        '..3222210...',  # y=17
        '..332211....',  # y=18 waist angled forward
        '...332211...',  # y=19 hips
        '...322221...',  # y=20
        '..33210221..',  # y=21 split stride: trailing leg kicking back-left, lead leg driving down-right
        '.3321..321..',  # y=22
        '.321....321.',  # y=23
        '321.....321.',  # y=24
        '210.....321.',  # y=25 trailing shin high in air (y=25..27)!
        '210......21.',  # y=26
        '110......21.',  # y=27 trailing boot ends at y=27 (8px off the floor!)
        '.........21.',  # y=28 clear air gap under lifted left foot (x=1..4, y=28..36)
        '.........21.',  # y=29
        '.........210',  # y=30
        '.........210',  # y=31
        '.........210',  # y=32
        '.........110',  # y=33
        '........2110',  # y=34
        '........2110',  # y=35 planted right toe grounded at y=35
    ]),

    # Specific Pose 4: N-11 hatch tech LEANING BACK ON A CRANK (planted feet, torso leaning back left,
    # both hands engaged on right with a visible 3x5 transparent gap between the arms/chest)
    'n11_tech_crank': (7, 36, 6, 2, 1, 6, [
        '.4332.......',  # y=6  head tilted back-left pulling hard
        '433321......',  # y=7
        '333221......',  # y=8
        '332211......',  # y=9
        '.3221.......',  # y=10
        '.22110......',  # y=11 neck
        '4332211.....',  # y=12 shoulders leaning back-left (x=1..7)
        '33322133332.',  # y=13 UPPER ARM reaching right to crank handle
        '332221133221',  # y=14 upper arm gripping crank at x=11..12
        '332210......',  # y=15 <-- VISIBLE GAP (x=7..11 is empty!) between upper and lower arms
        '322210......',  # y=16 <-- VISIBLE GAP (3px tall x 5px wide)
        '322210......',  # y=17 <-- VISIBLE GAP
        '332211333221',  # y=18 LOWER ARM reaching right to crank handle
        '.3322113221.',  # y=19 lower arm grip
        '.3322211....',  # y=20 braced lower torso / belt angled down-right toward planted feet
        '..3322211...',  # y=21
        '..32220211..',  # y=22 hips
        '...3210.211.',  # y=23 wide braced legs
        '...321..321.',  # y=24
        '..321....321',  # y=25
        '..321....321',  # y=26
        '..321....321',  # y=27
        '..210....210',  # y=28
        '..210....210',  # y=29
        '..210....210',  # y=30
        '..210....210',  # y=31
        '..210....110',  # y=32
        '..2110...210',  # y=33
        '..2110..2110',  # y=34
        '..2110..2110',  # y=35 both boots planted firmly on floor at y=35
    ]),
}


def build_statue_pose(pose_key, mode='idle'):
    """Return [Cast_Shadow, Statue_Body, Silhouette_Outline] Layers for `pose_key` in `idle` or `read` mode."""
    cx, cy, rx, ry, x0, y0, rows = POSE_GRIDS[pose_key]
    sh = _shadow(cx, cy, rx, ry)
    body = Layer(W, H, 'Statue_Body')
    _art(body, x0, y0, rows, CMAP_STATUE)
    ol = _outline_layer(body.mask(), mode=mode)
    return [sh, body, ol]


# ==============================================================================
# 2. FOURTEEN PROP OVERLAYS (16 x 40 px, pivot (8, 36))
#    Subdued palette accents confined to the prop/coat overlay, plus 1px #0A0D14 outline.
# ==============================================================================

OVERLAY_SPECS = {
    # 1. Suitcase (at feet/side of N-21 on body_c_pose1, subdued brown leather 17/18 + gunmetal 12, grounded at y=35)
    'suitcase': (1, 28, [
        '..222...',
        '.bBBBb..',
        'bBBBBBb.',
        'bB333Bb.',
        'bBBBBBb.',
        'bBBBBBb.',
        'bbbbbbb.',
        '1bbbbbb.',
    ]),
    # 2. Paper bag (resting on N-03's seated knee at y=21..26, subdued brown 17/18 + grey highlight 14)
    'paper_bag': (7, 20, [
        '.33B3.',
        '3BBBB3',
        '3B33B3',
        '3BBBB3',
        'bBBBBb',
        '.bbbb.',
    ]),
    # 3. Whistle (conductor cap visor + epaulette in grey 11..14 + whistle/badge in single subdued brass/orange 24/25)
    'whistle': (3, 4, [
        '.33322....',  # y=4 conductor cap crown (grey ramp)
        '2333211...',  # y=5 cap band + visor
        '....2aa...',  # y=6 cap badge (subdued brass)
        '..........',  # y=7
        '......oa..',  # y=8 whistle in teeth (x=9..10)
        '..........',  # y=9
        '..........',  # y=10
        '233..221..',  # y=11 uniform shoulder epaulettes
    ]),
    # 4. Trolley (half-turned cleaner trolley at x=8..14, y=14..35; steel frame/handle 11..14 + single subdued slate 7/8 bucket)
    'trolley': (8, 14, [
        '....3..',  # y=14 upright mop handle stick (steel/grey)
        '....2..',
        '....2..',
        '....2..',
        '.3332..',  # y=18 angled push-bar handle gripped by cleaner
        '.2..2..',
        '.2..1..',
        '.2.uUU.',  # y=21 half-turned bucket rim (single subdued slate-blue 7/8)
        '.2uUUUu',
        '.2uUUUu',
        '.2uUUUu',
        '.2uUUu.',
        '.22uUu.',  # y=26 lower frame shelf
        '.23332.',
        '.21112.',
        '.2...2.',  # y=29 vertical trolley legs
        '.2...2.',
        '.2...2.',
        '.2...2.',
        '.21112.',  # y=33 lower axle bar
        '.1...1.',  # y=34 caster brackets
        '.0...0.',  # y=35 caster wheels grounded at y=35
    ]),
    # 5. Phone (held in N-02's hand at chest/face level on body_a_pose1, dark casing 11/12 + single subdued deep-teal 27)
    'phone': (10, 14, [
        '.03t0',
        '.0tt0',
        '.0tt0',
        '..00.',
    ]),
    # 6. Red coat (single subdued crimson 22/23 coat over body_a_pose1 torso + small grey transit card in hand)
    'red_coat': (3, 11, [
        'RRRrrr...',  # y=11 NW key-lit lapel in crimson 23, shadow 22
        'RRRRrr...',
        'RRRRrr...',
        'RRRRrr...',
        'RRRRrr34.',  # y=15 small transit card in hand (3/4 grey)
        'RRRRrr32.',
        'RRRrrr...',
        'RRRrr....',
        'RRRRr....',
        'RRRrr....',
        'RRrrr....',
        'RR.rr....',
        'rr.rr....',  # y=23 coat tails
    ]),
    # 7. Briefcase (carried in N-07's right hand + wrist watch strap on body_b_pose1, single subdued brown leather 17/18 + grey clasp)
    'briefcase': (6, 14, [
        'B........',  # y=14 leather watch strap at wrist (x=6, y=14)
        '.........',
        '.........',
        '.........',
        '.........',
        '.........',
        '.........',
        '.........',
        '.........',
        '.........',
        '....232..',  # y=24 briefcase handle
        '..bBBBBBb',  # y=25 briefcase body at x=8..14, y=25..30
        '..bB333Bb',
        '..bBB3BBb',  # steel clasp
        '..bBBBBBb',
        '..bbbbbbb',
    ]),
    # 8. Sleeping child (bundled small child resting head on N-08 father's left shoulder on body_b_pose1; single subdued slate 7/8)
    'sleeping_child': (1, 7, [
        '..332..',  # y=7 child's small head resting on shoulder
        '.33221.',
        '.32211.',
        '.uUUUu.',  # y=10 subdued slate-blue bundled child coat (7/8)
        'uUUUUu.',
        'uUUUuu.',
        'uUUuu..',
        '.uuu...',
        '.21....',  # y=15 dangling small boot
        '.10....',
    ]),
    # 9. Headphones (over-ear band + earcups on N-09 Build C head at y=11..15 in single subdued crimson 22/23)
    'headphones': (3, 11, [
        '.RRRR..',   # y=11 headband arc over Build C crown (y=12)
        'R....R.',   # y=12
        'RR..Rr.',   # y=13 earcups on sides of Build C head (y=13..14)
        'RR..Rr.',   # y=14
    ]),
    # 10. Hatch crank (heavy vertical crank column + wheel at x=11..14, preserving N-11's arm gap at x=7..11; single subdued crimson 22/23)
    'hatch_crank': (11, 13, [
        '.RR.',  # y=13 upper crank handle grip
        '.Rr.',  # y=14
        '.21.',  # y=15 vertical crank shaft (x=12..13, leaving x=7..11 open gap!)
        '3RR2',  # y=16 crank wheel hub
        '.21.',  # y=17
        '.Rr.',  # y=18 lower crank handle grip
        '.21.',  # y=19 lower column post to floor
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '.21.',
        '3211',  # y=35 floor flange base grounded at y=35
    ]),
    # 11. Gate lever (security booth control lever gripped by N-13 on body_b_pose2 + badge; single subdued crimson/rust 22/23)
    'gate_lever': (4, 12, [
        'R........R.',  # y=12 guard chest tab (x=4) + lever knob (x=13)
        '.........r.',  # y=13 lever handle
        '.........2.',  # y=14 lever rod
        '........21.',  # y=15
        '........21.',  # y=16
        '.......321.',  # y=17 lever switch box
        '.......321.',  # y=18
        '.......211.',  # y=19
    ]),
    # 12. Breaker handle (heavy substation breaker handle + engineer vest stripe on N-20 body_b_pose2; single subdued crimson 22/23)
    'breaker_handle': (4, 12, [
        'R.......RR.',  # y=12 vest safety tab + heavy insulated breaker grip
        'r.......Rr.',  # y=13
        '........21.',  # y=14 breaker arm
        '.......321.',  # y=15 breaker housing mount
        '.......211.',  # y=16
    ]),
    # 13. Map (unfolded station map held open across N-21 Build C hands at y=20..23; grey paper 13..15 + subdued brown 17/18 route line matching suitcase)
    'map': (7, 20, [
        '443443.',  # y=20 unfolded 3-panel paper map
        '4BBb33.',  # route diagram lines on map (same brown 17/18 family as N-21's suitcase)
        '33B432.',
        '333222.',
    ]),
    # 14. Courier bag (cross-body strap + swinging messenger bag trailing behind N-05's vault; single subdued brown leather 17/18 + steel buckle)
    'courier_bag': (1, 12, [
        '.....Bb..',  # y=12 strap over shoulder
        '....Bb...',  # y=13
        '...Bb....',  # y=14
        '..Bb.....',  # y=15
        '.3BBBb...',  # y=16 swinging messenger bag (angled back-left in mid-air)
        '3BBBBBb..',  # y=17
        'bBB3BBb..',  # y=18 steel buckle on flap
        'bBBBBb...',  # y=19
        '.bbbb....',  # y=20
    ]),
}


OVERLAY_TARGET_POSE = {
    'whistle':        ('body_a_pose2',       []),
    'phone':          ('body_a_pose1',       []),
    'paper_bag':      ('n03_old_man_seated', []),
    'trolley':        ('n04_cleaner',        []),
    'courier_bag':    ('n05_courier_vault',  []),
    'red_coat':       ('body_a_pose1',       []),
    'briefcase':      ('body_b_pose1',       []),
    'sleeping_child': ('body_b_pose1',       []),
    'headphones':     ('body_c_pose2',       []),
    'hatch_crank':    ('n11_tech_crank',     []),
    'gate_lever':     ('body_b_pose2',       []),
    'breaker_handle': ('body_b_pose2',       []),
    'map':            ('body_c_pose1',       []),
    'suitcase':       ('body_c_pose1',       ['map']),
}


def _raw_overlay_prop(ov_key):
    x0, y0, rows = OVERLAY_SPECS[ov_key]
    P = Layer(W, H, 'Overlay_Prop')
    _art(P, x0, y0, rows, CMAP_STATUE)
    return P


def build_overlay(ov_key, mode='idle'):
    """Return [Overlay_Outline, Overlay_Prop] Layers (16 x 40 px, pivot (8, 36)) in `idle` or `read` mode.
    The outline layer is computed against the target pose so that alpha-compositing
    `ch01_char_statue_<pose>_<mode>.png` + `ch01_prop_statue_ov_<ov>_<mode>.png` reproduces
    `assemble_commuter(pose, ovs, mode)` with 0 differing pixels."""
    P = _raw_overlay_prop(ov_key)
    pose_key, prev_ovs = OVERLAY_TARGET_POSE[ov_key]
    _, body, body_ol = build_statue_pose(pose_key, mode=mode)
    base_mask = set(body.mask())
    base_comp = Layer(W, H, 'Base_Comp')
    base_comp.blit(body_ol)
    base_comp.blit(body)
    for pov in prev_ovs:
        pp = _raw_overlay_prop(pov)
        base_mask |= pp.mask()

    comb_mask = base_mask | P.mask()
    comb_ol = _outline_layer(comb_mask, mode=mode)

    OL = Layer(W, H, 'Overlay_Outline')
    for (x, y) in comb_ol.mask():
        if (x, y) not in P.mask():
            c_target = comb_ol.get(x, y)
            if base_comp.get(x, y) != c_target:
                OL.put(x, y, c_target)
    return [OL, P]


# ==============================================================================
# 3. TRACE SHIMMER RING (4 frames of 24 x 12 px @ 8 FPS) & 6 x 6 TIMESTAMP GLYPH
# ==============================================================================

def build_shimmer_ring_frames():
    """Return 4 frames of [Ring_Base, Stepped_Highlight] Layers, each 24 x 12 px, pivot (12, 6).
    Isometric 2:1 ellipse with diamond reticle ticks; violet 30 + sparse stepped gold 26 highlight."""
    fw, fh = 24, 12
    cx, cy = 11.5, 5.5
    rx, ry = 10.5, 4.8
    # 4 quadrant angle windows (in degrees) for the stepped clockwise highlight
    quads = [(-135, -45), (-45, 45), (45, 135), (135, 225)]
    import math
    frames = []
    for fi in range(4):
        B = Layer(fw, fh, 'Ring_Base')
        H_lay = Layer(fw, fh, 'Stepped_Highlight')
        ring_pts = set()
        for y in range(fh):
            for x in range(fw):
                dx = (x - cx) / rx
                dy = (y - cy) / ry
                d = math.hypot(dx, dy)
                if 0.72 <= d <= 1.0:
                    ring_pts.add((x, y))
        # Cardinal diamond reticle ticks (N, S, E, W) per Bible §7 Trace language
        for pt in ((11, 0), (12, 0), (11, 11), (12, 11), (0, 5), (0, 6), (23, 5), (23, 6)):
            ring_pts.add(pt)
        # 1px dark #0A0D14 backing outline around the ring
        for (x, y) in sorted(ring_pts):
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if (nx, ny) not in ring_pts and 0 <= nx < fw and 0 <= ny < fh:
                    B.put(nx, ny, O)
        # Base violet 30 ring
        q0, q1 = quads[fi]
        for (x, y) in sorted(ring_pts):
            B.put(x, y, 30)
            ang = math.degrees(math.atan2(y - cy, x - cx))
            if q0 == 135:
                in_q = (ang >= 135 or ang < -135)
            else:
                in_q = (q0 <= ang < q1)
            if in_q:
                # Sparse stepped gold 26 highlight (2-3 pixels at the quadrant peak)
                H_lay.put(x, y, 26)
        frames.append([B, H_lay])
    return frames


def build_timestamp_glyph():
    """Return [Glyph_Backing, Clock_Hands] Layers (6 x 6 px, pivot (3, 3)).
    6 x 6 clock-hand glyph above the head: dark 00 backing, violet 30 bezel ticks, gold 26 L-hands."""
    B = Layer(6, 6, 'Glyph_Backing')
    C = Layer(6, 6, 'Clock_Hands')
    # Circular/octagonal 6x6 dial
    for y in range(6):
        for x in range(6):
            if (x in (0, 5) and y in (0, 5)):
                continue
            B.put(x, y, O)
    # Violet 30 bezel points at 12, 3, 6, 9 o'clock + corners
    for (x, y) in ((2, 0), (3, 0), (0, 2), (0, 3), (5, 2), (5, 3), (2, 5), (3, 5)):
        C.put(x, y, 30)
    # Gold 26 clock hands (vertical minute hand at x=2, y=1..3; horizontal hour hand at x=3..4, y=3)
    for (x, y) in ((2, 1), (2, 2), (2, 3), (3, 3), (4, 3)):
        C.put(x, y, 26)
    return [B, C]


# ==============================================================================
# 4. ALL 13 STEP 1 COMMUTER ASSEMBLIES (COMMUTERS_STEP1.md mapping)
# ==============================================================================

COMMUTER_ASSEMBLIES = [
    # (id, slug, room, tile, px_pos, pose_key, overlays, time_str, role_note)
    ('N-01', 'n01_conductor',  'R1', (10, 8), (352, 208), 'body_a_pose2',       ['whistle'],              '23:57', 'SO-01 LINE+CAR'),
    ('N-02', 'n02_student',    'R1', (5, 8),  (272, 168), 'body_a_pose1',       ['phone'],                '23:41', 'SO-01 decoy'),
    ('N-03', 'n03_old_man',    'R1', (4, 2),  (352, 112), 'n03_old_man_seated', ['paper_bag'],            '23:30', 'SO-01 seated on bench'),
    ('N-04', 'n04_cleaner',    'R1', (12, 7), (400, 216), 'n04_cleaner',        ['trolley'],              '23:58', 'SO-01 PLATFORM'),
    ('N-05', 'n05_courier',    'R2', (1, 6),  (240, 120), 'n05_courier_vault',  ['courier_bag'],          '23:59', 'PZ-001 Rewind unlock'),
    ('N-06', 'n06_red_coat',   'R2', (13, 6), (432, 216), 'body_a_pose1',       ['red_coat'],             '23:41', 'PZ-006 decoy'),
    ('N-07', 'n07_briefcase',  'R2', (13, 8), (400, 232), 'body_b_pose1',       ['briefcase'],            '23:49', 'PZ-006 decoy'),
    ('N-08', 'n08_father',     'R2', (13, 10),(368, 248), 'body_b_pose1',       ['sleeping_child'],       '23:53', 'PZ-006 decoy 23:53'),
    ('N-09', 'n09_teen',       'R2', (11, 9), (352, 224), 'body_c_pose2',       ['headphones'],           '23:55', 'PZ-006 target ticket'),
    ('N-11', 'n11_hatch_tech', 'R3', (2, 3),  (304, 104), 'n11_tech_crank',     ['hatch_crank'],          '23:58', 'SO-02 Freeze unlock'),
    ('N-13', 'n13_guard',      'R4', (4, 3),  (336, 120), 'body_b_pose2',       ['gate_lever'],           '23:57', 'PZ-003 south plate clue'),
    ('N-20', 'n20_engineer',   'R6', (6, 7),  (304, 168), 'body_b_pose2',       ['breaker_handle'],       '23:56', 'PZ-004 breaker C warning'),
    ('N-21', 'n21_tourist',    'R7', (5, 4),  (336, 136), 'body_c_pose1',       ['map', 'suitcase'],      '23:55', 'PZ-005 loop clue'),
]


def build_commuter_layers(pose_key, overlays, mode='idle'):
    """Return 4 Layers [Cast_Shadow, Silhouette_Outline, Statue_Body, Prop_Overlay] for an assembled commuter."""
    sh, body, _ = build_statue_pose(pose_key, mode='idle')
    prop = Layer(W, H, 'Prop_Overlay')
    for ov in overlays:
        prop.blit(_raw_overlay_prop(ov))
    comb_mask = body.mask() | prop.mask()
    ol = _outline_layer(comb_mask, mode=mode)
    return [sh, ol, body, prop]


def assemble_commuter(pose_key, overlays, mode='idle'):
    """Composite a statue pose + its overlays into a 16 x 40 Layer.
    In `read` mode, the outer 1px silhouette outline around the combined (body + overlay) is violet 30 + sparse gold 26."""
    return composite(build_commuter_layers(pose_key, overlays, mode=mode))


# ==============================================================================
# 5. REGISTRY EXPORT FOR `registry.py`
# ==============================================================================

def assets():
    """Return list of (stem, cat, w, h, layer_names, frames, fps, tags, meta) for all 76 Section A assets
    (12 base body files + 8 specific pose files + 28 overlay files + 26 assembled commuter files + 2 Trace effect files)."""
    out = []
    pose_order = [
        ('body_a_pose1',       'Base body A (slim), pose 1 standing'),
        ('body_a_pose2',       'Base body A (slim), pose 2 reaching/stepping'),
        ('body_b_pose1',       'Base body B (broad), pose 1 standing'),
        ('body_b_pose2',       'Base body B (broad), pose 2 leaning/reaching'),
        ('body_c_pose1',       'Base body C (small/shorter), pose 1 standing'),
        ('body_c_pose2',       'Base body C (small/shorter), pose 2 reaching/stepping'),
        ('n03_old_man_seated', 'Specific pose N-03: old man seated on existing bench'),
        ('n04_cleaner',        'Specific pose N-04: night cleaner mid-turn'),
        ('n05_courier_vault',  'Specific pose N-05: bike courier mid-vault, one foot lifted'),
        ('n11_tech_crank',     'Specific pose N-11: hatch tech leaning back on crank, arm gap'),
    ]
    for key, desc in pose_order:
        layers_idle = build_statue_pose(key, mode='idle')
        out.append((
            f'ch01_char_statue_{key}_idle', 'characters', W, H,
            ['Cast_Shadow', 'Statue_Body', 'Silhouette_Outline'],
            [layers_idle], 1.0, None,
            dict(pivot=PIVOT, z='YSort_Actors (z_index = 10)', desc=desc)
        ))
        layers_read = build_statue_pose(key, mode='read')
        out.append((
            f'ch01_char_statue_{key}_read', 'characters', W, H,
            ['Cast_Shadow', 'Statue_Body', 'Silhouette_Outline'],
            [layers_read], 1.0, None,
            dict(pivot=PIVOT, z='YSort_Actors (z_index = 10)', desc=desc + ' (static 1px read outline)')
        ))

    ov_order = [
        ('suitcase',       'Suitcase overlay (N-21)'),
        ('paper_bag',      'Paper bag on knee overlay (N-03)'),
        ('whistle',        'Conductor whistle + cap overlay (N-01)'),
        ('trolley',        'Half-turned cleaner trolley overlay (N-04)'),
        ('phone',          'Commuter phone in hand overlay (N-02)'),
        ('red_coat',       'Subdued red coat + card overlay (N-06)'),
        ('briefcase',      'Leather briefcase + watch glint overlay (N-07)'),
        ('sleeping_child', 'Sleeping child on shoulder overlay (N-08)'),
        ('headphones',     'Over-ear headphones overlay (N-09)'),
        ('hatch_crank',    'Hatch crank column + wheel overlay (N-11)'),
        ('gate_lever',     'Security booth gate lever + badge overlay (N-13)'),
        ('breaker_handle', 'Substation breaker handle + vest overlay (N-20)'),
        ('map',            'Open unfolded station map overlay (N-21)'),
        ('courier_bag',    'Swinging cross-body courier bag overlay (N-05)'),
    ]
    for key, desc in ov_order:
        layers_ov_idle = build_overlay(key, mode='idle')
        out.append((
            f'ch01_prop_statue_ov_{key}_idle', 'props', W, H,
            ['Overlay_Outline', 'Overlay_Prop'],
            [layers_ov_idle], 1.0, None,
            dict(pivot=PIVOT, z='child of statue in YSort_Actors (z_index = 10)', desc=desc)
        ))
        layers_ov_read = build_overlay(key, mode='read')
        out.append((
            f'ch01_prop_statue_ov_{key}_read', 'props', W, H,
            ['Overlay_Outline', 'Overlay_Prop'],
            [layers_ov_read], 1.0, None,
            dict(pivot=PIVOT, z='child of statue in YSort_Actors (z_index = 10)', desc=desc + ' (static 1px read outline)')
        ))

    for (cid, slug, rm, tile, px_pos, pk, ovs, tstr, role) in COMMUTER_ASSEMBLIES:
        c_desc = f'Assembled commuter {cid} ({slug}, {rm} {tile}): {pk} + {"+".join(ovs)}'
        layers_c_idle = build_commuter_layers(pk, ovs, mode='idle')
        out.append((
            f'ch01_char_statue_commuter_{slug}_idle', 'characters', W, H,
            ['Cast_Shadow', 'Silhouette_Outline', 'Statue_Body', 'Prop_Overlay'],
            [layers_c_idle], 1.0, None,
            dict(pivot=PIVOT, z='YSort_Actors (z_index = 10)', desc=c_desc)
        ))
        layers_c_read = build_commuter_layers(pk, ovs, mode='read')
        out.append((
            f'ch01_char_statue_commuter_{slug}_read', 'characters', W, H,
            ['Cast_Shadow', 'Silhouette_Outline', 'Statue_Body', 'Prop_Overlay'],
            [layers_c_read], 1.0, None,
            dict(pivot=PIVOT, z='YSort_Actors (z_index = 10)', desc=c_desc + ' (static 1px read outline)')
        ))

    shimmer_frames = build_shimmer_ring_frames()
    shimmer_tags = [{"color": "9e7bffff", "from": 1, "name": "loop", "to": 4, "user_data": "8fps_loop"}]
    out.append((
        'ch01_prop_trace_shimmer_ring_loop', 'props', 24, 12,
        ['Ring_Base', 'Stepped_Highlight'],
        shimmer_frames, 8.0, shimmer_tags,
        dict(pivot=(12, 6), z='YSort_Props (z_index = 8, under statue feet)', desc='4-frame 24x12 Trace shimmer foot ellipse')
    ))

    glyph_layers = build_timestamp_glyph()
    out.append((
        'ch01_prop_trace_timestamp_glyph_idle', 'props', 6, 6,
        ['Glyph_Backing', 'Clock_Hands'],
        [glyph_layers], 1.0, None,
        dict(pivot=(3, 3), z='child of statue in YSort_Actors (z_index = 10)', desc='6x6 clock-hand time-stamp glyph above statue head')
    ))
    return out


if __name__ == '__main__':
    ims = [to_image(assemble_commuter(pk, ovs, 'idle')) for (_, _, _, _, _, pk, ovs, _, _) in COMMUTER_ASSEMBLIES]
    preview(ims, os.path.join(SCR, 'step1_statues_prev.png'), zoom=4)
    print('statues ok:', len(assets()))
