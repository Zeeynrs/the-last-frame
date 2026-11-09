"""TLF-075 — Elias side-view sprites and Beat 06 side-view background/prop kit (ADR-025).

Deliverables (10 registered .pxo + .png assets + 1 960x540 assembled scene mockup + 1 colour/greyscale proof):
  1. ch01_char_elias_side_sheet (704x48, 22 frames of 32x48, pivot (16, 44)):
     - idle_e (2f @ 8 FPS, loop): breathing profile idle facing East (+x)
     - walk_e (6f @ 10 FPS, loop): 6-frame horizontal profile stride on ground line y=44
     - interact_e (3f @ 12 FPS, one-shot): neutral reach / short inspect hold / return gesture (watch chain stays at waist on costume per ADR-022 A3)
     - idle_w (2f), walk_w (6f), interact_w (3f): horizontal mirror (flip_h) of e (no separate drawing)
  2. ch01_env_side_bg_far_wall_arches_idle (960x360, pivot (0, 0), z=1):
     Far subterranean tunnel wall & 5 vaulted arch bays for the 960x360 active band (y=90..449 in 960x540).
  3. ch01_env_side_bg_near_wall_pillars_idle (960x360, pivot (0, 0), z=2):
     Near structural steel fascia girder, 4 foreground station pilasters & ceramic overlook mullions with transparent arch cutouts.
  4. ch01_env_side_platform_floor_strip_idle (960x72, pivot (0, 16) at walkable floor line y=394 / top-left (0, 378), z=3):
     Platform baseboard, dark terrazzo deck (walkable floor line at local y=16 -> screen y=394), tactile amber safety strip,
     riveted steel platform curb nose, and sunken Mag-Transit rail trench cross-section (local y=35..71 -> screen y=413..449).
  5. ch01_prop_side_station_bench_idle (64x32, pivot (32, 28), z=8):
     Side-view cast-iron and brushed-steel waiting lounge bench on the floor line.
  6. ch01_prop_side_luggage_trolley_idle (48x40, pivot (24, 36), z=8):
     Side-view wheeled station baggage trolley with stacked vintage suitcases on the floor line.
  7. ch01_prop_side_platform_pillar_idle (32x264, pivot (16, 260), z=6):
     Standalone full-height side-view riveted steel & ceramic station pillar on the floor line.
  8. ch01_prop_side_clock_2359_idle (40x28, pivot (20, 24), z=7):
     Side-view suspended station digital clock frozen at 23:59.
  9. ch01_prop_side_mira_memory_silhouette_idle (32x48, pivot (16, 44), z=9):
     Beat 06 frozen-person / Mira departure memory silhouette position marker in profile (32x48 cell, foot pivot (16, 44)).
  10. ch01_prop_side_voice_recorder_cup_idle (24x16, pivot (12, 14), z=9):
      Beat 06 personal audio recorder & overturned ceramic coffee cup prop (no text).
"""
import os
from PIL import Image
from lib import Layer, PAL, REPO, composite, to_image, sheet_image
import elias as iso_elias
from tlf068_shape_kit import FONT5X7, _draw_text_img

W_CELL, H_CELL = 32, 48
O, SH = 0, 1
TR_D, TR_L = 2, 3
CD, CS, CM, CL = 16, 17, 18, 19
BD, BM = 16, 17
SK_S, SK_L = 20, 21
BR, GOLD = 25, 26
HEM = 35

ELIAS_SIDE_LAYERS = ['Cast_Shadow', 'Boots_And_Coat', 'Head_Arms_And_Watch_Chain']


# ============================================================================
# 1. ELIAS SIDE-VIEW SPRITE SHEET (ch01_char_elias_side_sheet, 704x48, 22f)
# ============================================================================

def _side_shadow(layer, cx=16.5, cy=44.5, rx=6.5, ry=1.8):
    """Flat side-view contact shadow hugging the horizontal floor line y=44."""
    for y in range(43, 47):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                layer.put(x, y, SH)


def _render_elias_side_e(pose):
    """Render one 32x48 East-facing profile frame of Elias across the 3 canonical layers.
    Matches Iso Elias (elias.py) in cell (32x48), pivot (16, 44), 12-colour palette, costume, and top-left light."""
    sh = Layer(W_CELL, H_CELL, 'Cast_Shadow')
    bc = Layer(W_CELL, H_CELL, 'Boots_And_Coat')
    ha = Layer(W_CELL, H_CELL, 'Head_Arms_And_Watch_Chain')

    b = pose.get('bob', 0)
    b_head = pose.get('bob_head', b)
    fl = pose.get('fl', 0)
    chest_exp = pose.get('chest_exp', 0)
    (dxN, sN), (dxF, sF) = pose['near'], pose['far']
    aN, aF = pose.get('arm_near', 0), pose.get('arm_far', 0)
    interact_step = pose.get('interact', 0)

    _side_shadow(sh, cx=16.5, cy=44.5, rx=6.8 if abs(dxN - dxF) >= 4 else 6.0, ry=1.8)

    hx = 15
    far_leg = iso_elias.leg_side(hx, HEM + b, hx + dxF, sF, far=True, boot_len=5)
    near_leg = iso_elias.leg_side(hx, HEM + b, hx + dxN, sN, far=False, boot_len=5)
    farm = iso_elias.arm_pix(15, 15 + b, 15 + aF, 25 + b - abs(aF) // 2, far=True, hand_lit=False)
    iso_elias.part(bc, farm)
    # Draw lifted or far leg first so near planted leg overlaps cleanly
    if sF < sN:
        iso_elias.part(bc, far_leg)
        iso_elias.part(bc, near_leg)
    elif sN < sF:
        iso_elias.part(bc, near_leg)
        iso_elias.part(bc, far_leg)
    else:
        iso_elias.part(bc, far_leg)
        iso_elias.part(bc, near_leg)

    # Trench coat profile body (y = 14+b .. 35+b)
    rows = [(14 + b, 12, 19)]
    for y in range(15, 27):
        r_right = 20 + (1 if (chest_exp and 16 <= y <= 21) else 0)
        rows.append((y + b, 11, r_right))
    back_edge = [11, 11, 10, 10, 10, 9, 9, 9, 9]
    front_edge = [20, 20, 20, 20, 21, 21, 21, 21, 21]
    for k, y in enumerate(range(27, 36)):
        t = k / 8.0
        rows.append((y + b, back_edge[k] - round(fl * t), front_edge[k]))
    coat = iso_elias.rows_to_pix(rows, iso_elias.coat_col)
    for x in range(11, 21):
        coat[(x, 25 + b)] = CD if x > 12 else CS
    iso_elias._hem_line(coat, rows, b)
    for y in range(16 + b, 23 + b):
        coat[(19 + (1 if (chest_exp and 16 <= y - b <= 21) else 0), y)] = CS
    for x in range(15, 18):
        coat[(x, 28 + b)] = CS
    for y in range(29 + b, HEM + b):
        coat[(rows[-1][1] + 2, y)] = CS
    coat.pop((21, HEM + b), None)
    coat.pop((20, HEM + b), None)
    # Dark slate collar (02)
    for x in range(15, 19):
        coat[(x, 14 + b)] = TR_D
    coat[(17, 15 + b)] = TR_D
    coat[(18, 15 + b)] = TR_D
    iso_elias._top_plane(coat, b, 12, 19)
    iso_elias.part(bc, coat)

    # Near arm + costume brass pocket-watch chain at waist (25/26; stays on costume per ADR-022 A3)
    if interact_step == 0:
        narm = iso_elias.arm_pix(14, 15 + b, 14 + aN, 25 + b - abs(aN) // 2, hand_lit=True)
        iso_elias.part(ha, narm)
    elif interact_step == 1:
        # F1 of interact_e: neutral reach forward toward an object
        arm_p = {}
        for y in range(15 + b, 21 + b):
            arm_p[(14, y)] = CL
            arm_p[(15, y)] = CM
        for x in range(15, 21):
            arm_p[(x, 20 + b)] = CL
            arm_p[(x, 21 + b)] = CM
        arm_p[(20, 21 + b)] = CS  # sleeve cuff
        # Empty hand reaching forward at (21..22, 20..21+b)
        arm_p[(21, 20 + b)] = SK_L
        arm_p[(22, 20 + b)] = SK_L
        arm_p[(21, 21 + b)] = SK_S
        arm_p[(22, 21 + b)] = SK_S
        iso_elias.part(ha, arm_p)
    elif interact_step == 2:
        # F2 of interact_e: short hold / inspect gesture with forearm & empty hand extended forward
        arm_p = {}
        for y in range(15 + b, 20 + b):
            arm_p[(14, y)] = CL
            arm_p[(15, y)] = CM
        for x in range(15, 22):
            arm_p[(x, 19 + b)] = CL
            arm_p[(x, 20 + b)] = CM
        arm_p[(21, 20 + b)] = CS  # sleeve cuff
        # Empty hand extended forward at x=22..24, y=19..20+b (outside coat contour x<=20)
        arm_p[(22, 19 + b)] = SK_L
        arm_p[(23, 19 + b)] = SK_L
        arm_p[(24, 19 + b)] = SK_L
        arm_p[(22, 20 + b)] = SK_S
        arm_p[(23, 20 + b)] = SK_S
        iso_elias.part(ha, arm_p)
    elif interact_step == 3:
        # F3 of interact_e: return arm back toward side
        arm_p = {}
        for y in range(15 + b, 23 + b):
            arm_p[(14, y)] = CL
            arm_p[(15, y)] = CM
        for x in range(15, 20):
            arm_p[(x, 22 + b)] = CL
            arm_p[(x, 23 + b)] = CM
        arm_p[(19, 23 + b)] = CS  # sleeve cuff
        arm_p[(20, 22 + b)] = SK_L
        arm_p[(21, 22 + b)] = SK_L
        arm_p[(20, 23 + b)] = SK_S
        iso_elias.part(ha, arm_p)

    # Readable pocket-watch fob + chain glint stays at front waist/pocket on costume (x=18..20, y=25..26+b)
    w_dx = 1 if (interact_step == 0 and aN > 1) else 0
    ha.put(18 + w_dx, 25 + b, BR)
    ha.put(19 + w_dx, 25 + b, GOLD)
    ha.put(18 + w_dx, 26 + b, GOLD)
    ha.put(19 + w_dx, 26 + b, BR)
    ha.put(20 + w_dx, 26 + b, GOLD)

    # Stamp profile head ('e')
    iso_elias.stamp_head(ha, 'e', 11, 3 + b_head)
    iso_elias.finish(sh, bc, ha)
    return [sh, bc, ha]


def build_elias_side_e_frames():
    """Return the 11 authored East-facing frames: 2 idle_e + 6 walk_e + 3 interact_e."""
    frames = []
    # 1. idle_e (2 frames, breathing): both feet planted on side-view floor line y=44
    frames.append(_render_elias_side_e(dict(
        bob=0, near=(0, 44), far=(1, 44), fl=0, chest_exp=0, arm_near=0, arm_far=0, interact=0
    )))
    frames.append(_render_elias_side_e(dict(
        bob=1, near=(0, 44), far=(1, 44), fl=1, chest_exp=1, arm_near=0, arm_far=0, interact=0
    )))

    # 2. walk_e (6 frames @ 10 FPS): horizontal profile stride along ground line y=44
    s = 4
    walk_specs = [
        dict(bob=1, near=(s - 1, 44), far=(-s, 44), fl=1, arm_near=-3, arm_far=3, interact=0),
        dict(bob=1, near=(1, 44), far=(-2, 44), fl=0, arm_near=-1, arm_far=1, interact=0),
        dict(bob=0, near=(0, 44), far=(2, 41), fl=0, arm_near=0, arm_far=0, interact=0),
        dict(bob=1, near=(-s, 44), far=(s - 1, 44), fl=1, arm_near=3, arm_far=-3, interact=0),
        dict(bob=1, near=(-2, 44), far=(1, 44), fl=0, arm_near=1, arm_far=-1, interact=0),
        dict(bob=0, near=(2, 41), far=(0, 44), fl=0, arm_near=0, arm_far=0, interact=0),
    ]
    for spec in walk_specs:
        frames.append(_render_elias_side_e(spec))

    # 3. interact_e (3 frames @ 12 FPS): neutral reach forward -> short inspect hold -> return arm
    frames.append(_render_elias_side_e(dict(
        bob=0, bob_head=0, near=(0, 44), far=(1, 44), fl=0, arm_near=0, arm_far=0, interact=1
    )))
    frames.append(_render_elias_side_e(dict(
        bob=0, bob_head=1, near=(0, 44), far=(1, 44), fl=0, arm_near=0, arm_far=0, interact=2
    )))
    frames.append(_render_elias_side_e(dict(
        bob=0, bob_head=0, near=(0, 44), far=(1, 44), fl=0, arm_near=0, arm_far=0, interact=3
    )))

    assert len(frames) == 11
    return frames


def build_elias_side_sheet_frames():
    """Return all 22 frames in sheet order: 11 authored East frames (0..10) + 11 mirrored West frames (11..21) via flip_h."""
    e_frames = build_elias_side_e_frames()
    w_frames = [[layer.flip_h() for layer in fr] for fr in e_frames]
    return e_frames + w_frames


def elias_side_tags():
    """Pixelorama animation tags (1-based) for idle_e (1..2), walk_e (3..8), interact_e (9..11) and mirrored w (12..22)."""
    return [
        {"color": "4ce0d2ff", "from": 1, "name": "idle_e", "to": 2, "user_data": "8fps_loop"},
        {"color": "eb8a28ff", "from": 3, "name": "walk_e", "to": 8, "user_data": "10fps_loop"},
        {"color": "ffd166ff", "from": 9, "name": "interact_e", "to": 11, "user_data": "12fps_oneshot"},
        {"color": "4ce0d2ff", "from": 12, "name": "idle_w", "to": 13, "user_data": "8fps_loop"},
        {"color": "eb8a28ff", "from": 14, "name": "walk_w", "to": 19, "user_data": "10fps_loop"},
        {"color": "ffd166ff", "from": 20, "name": "interact_w", "to": 22, "user_data": "12fps_oneshot"},
    ]


# ============================================================================
# 2. SIDE-VIEW BACKGROUND KIT FOR BEAT 06 (960x360 active band + 960x72 floor)
#    In the 960x540 canvas:
#      - Top letterbox bar:    y = 0..89   (90 px)
#      - Active scene band:    y = 90..449 (960x360 px)
#        - Far wall & arches:  960x360 at screen (0, 90)
#        - Near wall/pillars:  960x360 at screen (0, 90)
#        - Floor strip:        960x72  at screen (0, 378) (local y=288..359 of the 960x360 band)
#          Walkable floor line: local y=16 in floor strip = local y=304 in 960x360 band = screen y=394
#      - Bottom letterbox bar: y = 450..539 (90 px)
# ============================================================================

ARCH_CENTERS = (120, 360, 600, 840)  # 4 symmetrical 240px bays across the 960px span
NEAR_PILLAR_XS = (222, 462, 702)     # 36px-wide pilasters centered at x=240, 480, 720 (+ 18px half-pilasters at x=0..17 and x=942..959)


def build_side_bg_far_wall_arches():
    """Layer 1 (Far Background): ch01_env_side_bg_far_wall_arches_idle (960x360, pivot (0, 0), z=1).
    Subterranean station far tunnel wall, 4 vaulted arch bays (x=120, 360, 600, 840), catwalk girder, ceramic courses, and amber dado."""
    w, h = 960, 360
    void_l = Layer(w, h, 'Tunnel_Void_And_Arches')
    masonry = Layer(w, h, 'Ceramic_Wall_Courses')
    lighting = Layer(w, h, 'Dado_And_Luminaires')

    # Fill upper wall & arch zone (y=0..292; y=288..359 is covered by the 960x72 floor strip with 4px overlap)
    void_l.rect(0, 0, w - 1, 292, 6)
    masonry.rect(0, 40, w - 1, 260, 7)

    # Subtle horizontal ceramic ashlar courses & vertical mortar joints on the far wall (32px period -> seamless at x=0/959)
    for y in range(44, 260, 12):
        masonry.hline(0, w - 1, y, 6)
        masonry.hline(0, w - 1, y + 1, 8 if y < 140 else 7)
        row_idx = (y - 44) // 12
        offset = 16 if (row_idx % 2) else 0
        for x in range(offset, w, 32):
            masonry.vline(x, y + 1, min(259, y + 11), 6)

    # Upper tunnel crown shadow & Distant service catwalk beam (y=0..44)
    void_l.rect(0, 0, w - 1, 39, 1)
    void_l.hline(0, w - 1, 40, 0)
    void_l.rect(0, 41, w - 1, 45, 11)
    void_l.hline(0, w - 1, 46, 13)

    # 4 Recessed Subterranean Vaulted Arch Bays (centered at x = 120, 360, 600, 840)
    # Each arch bay is 136 px wide (cx - 68 .. cx + 67), rising from y=256 to crown y=64
    for cx in ARCH_CENTERS:
        rx = 68
        arch_top_y = 64
        spring_y = 128
        for y in range(arch_top_y - 4, 258):
            if y < spring_y:
                dy = spring_y - y
                max_dx_sq = (rx * rx) * (1.0 - (dy / 64.0) ** 2)
                if max_dx_sq < 0:
                    continue
                hw = int(max_dx_sq ** 0.5)
            else:
                hw = rx
            x0, x1 = cx - hw, cx + hw - 1
            for x in range(x0, x1 + 1):
                masonry.put(x, y, None)
                dist_edge = min(x - x0, x1 - x)
                if y < spring_y and dy > 54:
                    dist_edge = min(dist_edge, 64 - dy)
                if dist_edge == 0:
                    void_l.put(x, y, 0)
                elif dist_edge in (1, 2):
                    void_l.put(x, y, 14 if (x < cx and y < 180) else 12)
                elif dist_edge == 3:
                    void_l.put(x, y, 11)
                else:
                    void_l.put(x, y, 1 if y > 152 else 0)

        # Horizontal steel transom bar & distant tunnel track/catwalk silhouette inside each arch bay
        void_l.rect(cx - rx + 4, 126, cx + rx - 5, 130, 11)
        void_l.hline(cx - rx + 4, cx + rx - 5, 126, 13)
        void_l.hline(cx - rx + 4, cx + rx - 5, 131, 0)
        # Vertical mullion rods inside the arch window
        for mx in (cx - 24, cx + 23):
            void_l.vline(mx, arch_top_y + 10, 255, 11)
            void_l.vline(mx + 1, arch_top_y + 10, 255, 12)
        # Distant tunnel ribs & conduit lines inside the dark arch recess
        for ty in (164, 196, 228):
            void_l.hline(cx - rx + 6, cx + rx - 7, ty, 2)
            void_l.hline(cx - rx + 6, cx + rx - 7, ty + 1, 1)
        # Suspended luminaire fixture inside each arch crown
        lighting.rect(cx - 16, 86, cx + 15, 89, 12)
        lighting.hline(cx - 14, cx + 13, 86, 14)
        lighting.vline(cx - 11, 70, 85, 11)
        lighting.vline(cx + 10, 70, 85, 11)
        lighting.hline(cx - 13, cx + 12, 90, 25)
        lighting.hline(cx - 10, cx + 9, 91, 26)
        lighting.hline(cx - 18, cx + 17, 92, 22)
        for ly in range(134, 248, 16):
            lighting.hline(cx - 18, cx + 17, ly, 2)

    # Continuous Subterranean Amber Safety Dado & Lower Baseboard along the far wall (y=256..292)
    lighting.hline(0, w - 1, 256, 0)
    lighting.hline(0, w - 1, 257, 13)
    lighting.hline(0, w - 1, 258, 24)
    lighting.hline(0, w - 1, 259, 25)
    lighting.hline(0, w - 1, 260, 24)
    lighting.hline(0, w - 1, 261, 0)
    lighting.rect(0, 262, w - 1, 292, 11)
    lighting.hline(0, w - 1, 262, 12)
    for x in range(12, w, 24):
        lighting.put(x, 266, 13)
        lighting.put(x, 282, 13)

    return [void_l, masonry, lighting]


def _paint_near_pilaster(pillars, px0, px1, w):
    """Paint a foreground pilaster spanning [px0..px1] (clipped to 0..w-1 for seamless edge piers)."""
    def put_c(x, y, c):
        if 0 <= x < w:
            pillars.put(x, y, c)

    def rect_c(x0, y0, x1, y1, c):
        for yy in range(y0, y1 + 1):
            for xx in range(max(0, x0), min(w - 1, x1) + 1):
                pillars.put(xx, yy, c)

    def hline_c(x0, x1, y, c):
        rect_c(x0, y, x1, y, c)

    def vline_c(x, y0, y1, c):
        rect_c(x, y0, x, y1, c)

    vline_c(px0, 38, 288, 0)
    vline_c(px1, 38, 288, 0)
    rect_c(px0 + 1, 43, px0 + 2, 288, 15)
    rect_c(px0 + 3, 43, px0 + 5, 288, 14)
    vline_c(px0 + 6, 43, 288, 0)
    vline_c(px1 - 6, 43, 288, 0)
    rect_c(px1 - 5, 43, px1 - 3, 288, 12)
    rect_c(px1 - 2, 43, px1 - 1, 288, 11)
    rect_c(px0 + 7, 43, px1 - 7, 288, 8)
    rect_c(px0 + 7, 43, px0 + 11, 288, 9)
    vline_c(px0 + 7, 43, 288, 10)
    rect_c(px1 - 11, 43, px1 - 7, 288, 7)
    for y in range(60, 250, 24):
        hline_c(px0 + 7, px1 - 7, y, 6)
        hline_c(px0 + 7, px1 - 7, y + 1, 9)
        put_c(px0 + 4, y, 15)
        put_c(px1 - 4, y, 13)
    # Pilaster capital (y = 38..48)
    rect_c(px0 - 2, 38, px1 + 2, 48, 13)
    hline_c(px0 - 2, px1 + 2, 38, 0)
    hline_c(px0 - 1, px1 + 1, 39, 15)
    hline_c(px0 - 1, px1 + 1, 40, 14)
    hline_c(px0 - 2, px1 + 2, 48, 0)
    vline_c(px0 - 2, 38, 48, 0)
    vline_c(px1 + 2, 38, 48, 0)
    # Amber safety dado band wrapping across the pilaster (y = 256..261)
    hline_c(px0 + 1, px1 - 1, 256, 0)
    hline_c(px0 + 1, px1 - 1, 257, 14)
    hline_c(px0 + 1, px1 - 1, 258, 25)
    hline_c(px0 + 1, px1 - 1, 259, 26)
    hline_c(px0 + 1, px1 - 1, 260, 24)
    hline_c(px0 + 1, px1 - 1, 261, 0)
    # Heavy cast-iron pilaster plinth base (y = 262..288)
    rect_c(px0 - 2, 262, px1 + 2, 288, 12)
    hline_c(px0 - 2, px1 + 2, 262, 0)
    hline_c(px0 - 1, px1 + 1, 263, 14)
    rect_c(px0 - 1, 264, px0 + 4, 288, 13)
    rect_c(px1 - 4, 264, px1 + 1, 288, 11)
    vline_c(px0 - 2, 262, 288, 0)
    vline_c(px1 + 2, 262, 288, 0)


def build_side_bg_near_wall_pillars():
    """Layer 2 (Near Background): ch01_env_side_bg_near_wall_pillars_idle (960x360, pivot (0, 0), z=2).
    Foreground riveted steel station box-girder header, structural pilasters between the 4 arch bays,
    and low ceramic/steel platform overlook rail with transparent cutouts revealing Layer 1."""
    w, h = 960, 360
    header = Layer(w, h, 'Upper_Steel_Girder')
    pillars = Layer(w, h, 'Foreground_Pilasters')
    overlook = Layer(w, h, 'Overlook_Rail_And_Trim')

    # 1. Upper riveted steel station box-girder header (y=0..42)
    header.rect(0, 0, w - 1, 42, 11)
    header.rect(0, 2, w - 1, 12, 12)
    header.hline(0, w - 1, 1, 14)
    header.hline(0, w - 1, 13, 0)
    # Recessed ceramic & steel soffit panels along the girder (y=15..35, 60px period -> seamless at x=0/959)
    header.rect(0, 14, w - 1, 36, 7)
    header.hline(0, w - 1, 14, 9)
    header.hline(0, w - 1, 37, 13)
    header.hline(0, w - 1, 38, 14)
    header.hline(0, w - 1, 42, 0)
    for x in range(0, w, 60):
        header.rect(x, 14, min(w - 1, x + 5), 36, 12)
        header.vline(x, 14, 36, 14)
        if x + 5 < w:
            header.vline(x + 5, 14, 36, 0)
    for x in range(8, w, 16):
        header.put(x, 6, 14)
        header.put(x + 1, 7, 0)
        header.put(x, 39, 15)
        header.put(x + 1, 40, 0)

    # Arch bay corbel brackets under the girder flanking each pilaster
    for cx in ARCH_CENTERS:
        for side in (-1, 1):
            bx = cx + side * 88
            for dy in range(14):
                span = 14 - dy
                x0 = bx if side == -1 else bx - span
                x1 = bx + span if side == -1 else bx
                header.hline(max(0, x0), min(w - 1, x1), 43 + dy, 12 if side == 1 else 13)
                header.put(max(0, min(w - 1, x1 if side == -1 else x0)), 43 + dy, 0)

    # 2. Foreground Structural Station Pilasters at x=222..257, 462..497, 702..737 + seamless wrap piers at -18..17 and 942..977
    for px0 in (-18, 222, 462, 702, 942):
        _paint_near_pilaster(pillars, px0, px0 + 35, w)

    # 3. Foreground low iron guardrail between the pilasters along the platform back wall (y=232..255)
    overlook.hline(0, w - 1, 232, 0)
    overlook.hline(0, w - 1, 233, 15)
    overlook.hline(0, w - 1, 234, 13)
    overlook.hline(0, w - 1, 235, 0)
    for x in range(28, w, 20):
        if any(px0 - 3 <= x <= px0 + 38 for px0 in (-18, 222, 462, 702, 942)):
            continue
        overlook.vline(x, 236, 255, 0)
        overlook.vline(x + 1, 236, 255, 13)
        overlook.vline(x + 2, 236, 255, 11)
        overlook.vline(x + 3, 236, 255, 0)

    return [header, overlook, pillars]


def build_side_platform_floor_strip():
    """Floor Strip: ch01_env_side_platform_floor_strip_idle (960x72, pivot (0, 16), z=3).
    Placed at (0, 378) in the 960x540 canvas (bottom 72 px of the 960x360 active band y=90..449).
    Walkable floor line is at local y=16 (screen y=394)."""
    w, h = 960, 72
    deck = Layer(w, h, 'Terrazzo_Platform_Deck')
    curb = Layer(w, h, 'Tactile_Strip_And_Curb')
    trench = Layer(w, h, 'SubLine_Rail_Trench')

    # 1. Rear steel skirting transition (local y = 0..3 -> screen y = 378..381)
    deck.hline(0, w - 1, 0, 0)
    deck.hline(0, w - 1, 1, 14)
    deck.hline(0, w - 1, 2, 12)
    deck.hline(0, w - 1, 3, 0)

    # 2. Walkable dark terrazzo platform slab (local y = 4..23 -> screen y = 382..401; floor line at local y = 16 -> screen y = 394)
    deck.rect(0, 4, w - 1, 23, 2)
    deck.hline(0, w - 1, 4, 4)   # Top-lit rear floor bevel
    deck.hline(0, w - 1, 5, 3)
    deck.hline(0, w - 1, 15, 3)  # Subtle guide seam just above walkable floor line y=16
    deck.hline(0, w - 1, 16, 2)
    # Perspective-foreshortened transverse terrazzo slab joints every 32 px
    for x in range(0, w, 32):
        for dy in range(4, 24):
            sx = (x + (dy - 4) // 2) % w
            deck.put(sx, dy, 1)
            if sx + 1 < w:
                deck.put(sx + 1, dy, 3 if dy < 16 else 4)
    # Sparse mineral terrazzo flecks (solid 2x1 clusters)
    for x in range(10, w - 4, 24):
        deck.put(x, 9, 3); deck.put(x + 1, 9, 3)
        deck.put(x + 8, 19, 3); deck.put(x + 9, 19, 3)

    # 3. Tactile Amber Safety Blister Strip along the platform edge (local y = 24..28 -> screen y = 402..406)
    curb.hline(0, w - 1, 24, 0)
    curb.rect(0, 25, w - 1, 27, 24)
    curb.hline(0, w - 1, 25, 25)
    for x in range(2, w - 2, 6):
        curb.put(x, 25, 26)
        curb.put(x + 1, 25, 26)
        curb.put(x, 26, 25)
        curb.put(x + 1, 26, 25)
        curb.put(x + 2, 27, 22)
    curb.hline(0, w - 1, 28, 22)

    # 4. Heavy Riveted Steel Platform Curb Nose (local y = 29..35 -> screen y = 407..413)
    curb.hline(0, w - 1, 29, 0)
    curb.hline(0, w - 1, 30, 15)
    curb.hline(0, w - 1, 31, 14)
    curb.rect(0, 32, w - 1, 34, 12)
    curb.hline(0, w - 1, 35, 0)
    for x in range(6, w, 16):
        curb.put(x, 33, 14)
        curb.put(x + 1, 33, 0)

    # 5. Sunken Mag-Transit Rail Trench Cross-Section (local y = 36..71 -> screen y = 414..449)
    trench.rect(0, 36, w - 1, 71, 0)
    # Recessed concrete under-platform shadow wall (y = 36..49)
    trench.rect(0, 37, w - 1, 48, 1)
    for x in range(0, w, 48):
        trench.rect(x, 37, min(w - 1, x + 5), 52, 11)
        trench.vline(x, 37, 52, 12)
    # Concrete track sleepers in the trench bed (y = 54..69)
    for x in range(8, w - 16, 24):
        trench.rect(x, 58, x + 11, 67, 2)
        trench.hline(x, x + 11, 58, 3)
        trench.hline(x, x + 11, 68, 0)
        # Rail chairs / clips
        trench.rect(x + 3, 52, x + 7, 57, 11)
        trench.put(x + 4, 52, 13)
    # Continuous horizontal steel running rail (y = 49..54)
    trench.hline(0, w - 1, 49, 0)
    trench.hline(0, w - 1, 50, 15)
    trench.hline(0, w - 1, 51, 13)
    trench.hline(0, w - 1, 52, 11)
    trench.hline(0, w - 1, 53, 12)
    trench.hline(0, w - 1, 54, 0)
    # Foreground third-rail conductor & ceramic insulators (y = 61..66)
    trench.hline(0, w - 1, 61, 0)
    trench.hline(0, w - 1, 62, 14)
    trench.hline(0, w - 1, 63, 12)
    trench.hline(0, w - 1, 64, 11)
    trench.hline(0, w - 1, 65, 0)
    for x in range(20, w, 48):
        trench.rect(x, 59, min(w - 1, x + 3), 66, 24)
        trench.hline(x, min(w - 1, x + 3), 59, 25)

    return [trench, deck, curb]


# ============================================================================
# 3. SIDE-VIEW FLOOR-LINE & WALL PROPS (6 Props, Zero New Text)
# ============================================================================

def build_side_station_bench():
    """Prop 1: ch01_prop_side_station_bench_idle (64x32, pivot (32, 28), z=8).
    Side-view subterranean station waiting bench with cast-iron legs and brushed steel seat/backrest."""
    w, h = 64, 32
    sh = Layer(w, h, 'Contact_Shadow')
    frame = Layer(w, h, 'Cast_Iron_Frame')
    seat = Layer(w, h, 'Steel_Slats_And_Rivets')

    # Floor contact shadow along y = 28..29
    sh.rect(4, 28, 59, 29, 1)
    sh.hline(6, 57, 30, 0)

    # Backrest (x = 6..57, y = 5..16)
    seat.rect(6, 5, 57, 16, 0)
    seat.rect(7, 6, 56, 15, 13)
    seat.hline(7, 56, 6, 15)    # Top specular rail
    seat.hline(7, 56, 7, 14)    # Key-lit upper slat
    seat.hline(7, 56, 10, 11)   # Slat gap
    seat.hline(7, 56, 11, 14)   # Lower slat highlight
    seat.hline(7, 56, 14, 12)
    seat.hline(7, 56, 15, 11)
    seat.vline(7, 6, 15, 15)    # Left key-lit edge
    seat.vline(56, 6, 15, 11)

    # Vertical backrest support struts at x = 11..13, 31..32, 50..52 (y = 16..18)
    for sx in (11, 31, 50):
        frame.rect(sx, 16, sx + 2, 18, 0)
        frame.vline(sx + 1, 16, 18, 12)

    # Horizontal bench seat plane (x = 4..59, y = 18..22)
    seat.rect(4, 18, 59, 22, 0)
    seat.hline(5, 58, 19, 15)   # Bright top seat plane (Step +1)
    seat.hline(5, 58, 20, 14)
    seat.hline(5, 58, 21, 12)
    # Warm brass rivet accents on seat & backrest
    for rx in (12, 32, 51):
        seat.put(rx, 8, 25)
        seat.put(rx, 13, 25)
        seat.put(rx, 20, 26)

    # Side armrests (x = 5..8 and x = 55..58, y = 12..18)
    for ax in (5, 55):
        frame.rect(ax, 12, ax + 3, 18, 0)
        frame.hline(ax + 1, ax + 2, 13, 15)
        frame.vline(ax + 1, 14, 17, 13)
        frame.vline(ax + 2, 14, 17, 11)

    # Cast-iron bench legs planting on floor line y = 28 (at x = 8..12, 30..33, 51..55)
    for lx in (8, 30, 51):
        frame.rect(lx, 22, lx + 3, 28, 0)
        frame.vline(lx + 1, 22, 27, 13)
        frame.vline(lx + 2, 22, 27, 11)
        # Flanged foot pad at y = 27..28
        frame.rect(lx - 1, 27, lx + 4, 28, 0)
        frame.hline(lx, lx + 3, 27, 14)
    # Under-seat stretcher bar (y = 25)
    frame.hline(12, 51, 24, 0)
    frame.hline(12, 51, 25, 11)
    frame.hline(12, 51, 26, 0)

    return [sh, frame, seat]


def build_side_luggage_trolley():
    """Prop 2: ch01_prop_side_luggage_trolley_idle (48x40, pivot (24, 36), z=8).
    Side-view wheeled station baggage trolley with two stacked vintage suitcases on the floor line y=36."""
    w, h = 48, 40
    sh = Layer(w, h, 'Contact_Shadow')
    cart = Layer(w, h, 'Steel_Trolley_And_Wheels')
    bags = Layer(w, h, 'Stacked_Suitcases')

    # Floor contact shadow at y = 36..37
    sh.rect(5, 36, 43, 37, 1)
    sh.hline(7, 41, 38, 0)

    # Left tubular steel push-handle (x = 5..9, y = 7..29)
    cart.rect(4, 6, 9, 9, 0)
    cart.hline(5, 8, 7, 25)     # Warm brass/amber grip bar
    cart.hline(5, 8, 8, 24)
    cart.rect(6, 9, 9, 29, 0)
    cart.vline(7, 9, 28, 15)    # Key-lit left tube
    cart.vline(8, 9, 28, 13)
    # Right low end-stop rail (x = 40..43, y = 22..29)
    cart.rect(40, 22, 43, 29, 0)
    cart.vline(41, 23, 28, 14)
    cart.vline(42, 23, 28, 12)

    # Flat steel trolley bed (x = 5..44, y = 28..32) with amber safety bumper
    cart.rect(5, 28, 44, 32, 0)
    cart.hline(6, 43, 29, 15)
    cart.hline(6, 43, 30, 13)
    cart.hline(6, 43, 31, 24)   # Amber bumper stripe
    cart.put(7, 31, 25); cart.put(8, 31, 25); cart.put(41, 31, 25); cart.put(42, 31, 25)

    # Two spoked trolley wheels resting at y = 36 (centers at x = 13 and x = 36, y = 32..36)
    for wx in (10, 33):
        cart.rect(wx, 31, wx + 6, 36, 0)
        cart.rect(wx + 1, 32, wx + 5, 35, 11)
        cart.hline(wx + 2, wx + 4, 32, 14)
        cart.put(wx + 3, 33, 15)  # Wheel axle hub
        cart.put(wx + 3, 34, 13)

    # Bottom large weathered brown leather trunk (x = 11..39, y = 18..28)
    bags.rect(11, 18, 39, 28, 0)
    bags.rect(12, 19, 38, 27, 18)
    bags.hline(12, 38, 19, 19)  # Key-lit top lid
    bags.vline(12, 19, 27, 19)  # Key-lit left side
    bags.rect(12, 25, 38, 27, 17)
    bags.vline(38, 20, 27, 16)
    bags.hline(12, 38, 23, 16)  # Trunk lid seam
    # Leather straps & brass clasps at x = 17..18 and x = 32..33
    for sx in (17, 32):
        bags.vline(sx, 19, 27, 16)
        bags.vline(sx + 1, 19, 27, 17)
        bags.put(sx, 22, 26)
        bags.put(sx + 1, 22, 25)
        bags.put(sx, 23, 25)

    # Top smaller slate-ceramic hardshell case (x = 15..35, y = 10..18)
    bags.rect(15, 10, 35, 18, 0)
    bags.rect(16, 11, 34, 17, 8)
    bags.hline(16, 34, 11, 10)  # Specular top edge
    bags.hline(16, 34, 12, 9)
    bags.vline(16, 11, 17, 9)
    bags.rect(16, 16, 34, 17, 7)
    bags.hline(16, 34, 14, 6)   # Case seam
    # Top handle & brass latches
    bags.rect(23, 8, 27, 10, 0)
    bags.hline(24, 26, 9, 14)
    bags.put(20, 14, 26)
    bags.put(30, 14, 25)

    return [sh, cart, bags]


def build_side_platform_pillar():
    """Prop 3: ch01_prop_side_platform_pillar_idle (32x264, pivot (16, 260), z=6).
    Standalone full-height side-view riveted steel & glazed ceramic station column planting on the platform floor
    (pivot y=260 -> screen y=392) and reaching up to the overhead box-girder soffit (y=0 -> screen y=132)."""
    w, h = 32, 264
    sh = Layer(w, h, 'Contact_Shadow')
    shaft = Layer(w, h, 'Steel_And_Ceramic_Shaft')
    trim = Layer(w, h, 'Capital_Plinth_And_Dado')

    # Floor contact shadow at y = 260..262
    sh.rect(1, 260, 30, 261, 1)
    sh.hline(3, 28, 262, 0)

    # Main column shaft (x = 4..27, y = 16..240)
    shaft.rect(4, 16, 27, 240, 0)
    # Left key-lit steel flange (x = 5..8)
    shaft.vline(5, 16, 240, 15)
    shaft.rect(6, 16, 7, 240, 14)
    shaft.vline(8, 16, 240, 0)
    # Right shaded steel flange (x = 23..26)
    shaft.vline(23, 16, 240, 0)
    shaft.rect(24, 16, 25, 240, 12)
    shaft.vline(26, 16, 240, 11)
    # Center glazed ceramic fluted core (x = 9..22)
    shaft.rect(9, 16, 22, 240, 8)
    shaft.rect(9, 16, 12, 240, 9)
    shaft.vline(9, 16, 240, 10)
    shaft.rect(19, 16, 22, 240, 7)
    shaft.vline(15, 16, 240, 7)
    shaft.vline(16, 16, 240, 6)
    for y in range(28, 232, 16):
        shaft.hline(9, 22, y, 6)
        shaft.hline(9, 22, y + 1, 9)
        shaft.put(6, y, 15)
        shaft.put(25, y, 13)

    # Flared riveted steel capital bracket at top (x = 1..30, y = 0..17)
    trim.rect(1, 0, 30, 8, 0)
    trim.rect(2, 1, 29, 7, 13)
    trim.hline(2, 29, 1, 15)
    trim.hline(2, 29, 2, 14)
    trim.rect(2, 6, 29, 7, 11)
    trim.rect(3, 8, 28, 17, 0)
    trim.rect(4, 9, 27, 16, 12)
    trim.hline(4, 27, 9, 14)
    trim.vline(4, 9, 16, 15)
    trim.vline(27, 9, 16, 11)
    for rx in (6, 12, 19, 25):
        trim.put(rx, 4, 15)
        trim.put(rx, 12, 14)

    # Upper structural tie-collar aligned with wall arch spring-line (y = 100..106 -> screen y = 232..238)
    trim.rect(3, 100, 28, 106, 0)
    trim.rect(4, 101, 27, 105, 13)
    trim.hline(4, 27, 101, 15)
    trim.hline(4, 27, 105, 11)
    for rx in (6, 15, 25):
        trim.put(rx, 103, 14)

    # Subterranean amber safety dado collar (y = 215..221 -> screen y = 347..353, aligned with wall dado!)
    trim.rect(3, 215, 28, 221, 0)
    trim.hline(4, 27, 216, 14)
    trim.hline(4, 27, 217, 25)
    trim.hline(4, 27, 218, 26)
    trim.hline(4, 27, 219, 24)
    trim.hline(4, 27, 220, 12)

    # Heavy stepped cast-iron plinth base planting on y = 260 (y = 240..260)
    trim.rect(2, 240, 29, 253, 0)
    trim.rect(3, 241, 28, 252, 12)
    trim.hline(3, 28, 241, 15)
    trim.hline(3, 28, 242, 14)
    trim.rect(3, 243, 7, 252, 13)
    trim.rect(24, 243, 28, 252, 11)
    # Foot pad (x = 0..31, y = 253..260)
    trim.rect(0, 253, 31, 260, 0)
    trim.rect(1, 254, 30, 259, 11)
    trim.hline(1, 30, 254, 14)
    trim.hline(1, 30, 255, 13)
    trim.rect(1, 256, 6, 259, 12)
    for rx in (5, 12, 19, 26):
        trim.put(rx, 247, 14)
        trim.put(rx, 257, 13)

    return [sh, shaft, trim]


def build_side_clock_2359():
    """Prop 4: ch01_prop_side_clock_2359_idle (40x28, pivot (20, 24), z=7).
    Side-view suspended station digital clock showing 23:59 (canonical Ch1 frozen time, no new text)."""
    w, h = 40, 28
    sh = Layer(w, h, 'Mount_Shadow')
    casing = Layer(w, h, 'Steel_Housing_And_Rods')
    digits = Layer(w, h, 'LED_Digits_2359')

    # Down-right wall shadow
    sh.rect(4, 8, 38, 26, 1)

    # Twin steel suspension rods (x = 9..11 and x = 28..30, y = 0..6)
    for rx in (9, 28):
        casing.rect(rx, 0, rx + 2, 6, 0)
        casing.vline(rx + 1, 0, 6, 14)
        casing.put(rx + 1, 0, 15)

    # Outer brushed-steel clock housing (x = 2..36, y = 6..24)
    casing.rect(2, 6, 36, 24, 0)
    casing.rect(3, 7, 35, 23, 13)
    casing.hline(3, 35, 7, 15)    # Top specular ridge
    casing.hline(3, 35, 8, 14)
    casing.vline(3, 7, 23, 15)    # Left key-lit bevel
    casing.vline(4, 8, 22, 14)
    casing.hline(3, 35, 22, 12)
    casing.hline(3, 35, 23, 11)
    casing.vline(35, 8, 23, 11)

    # Recessed LED cavity (x = 6..32, y = 10..20)
    casing.rect(5, 9, 33, 21, 11)
    casing.hline(5, 33, 21, 14)
    casing.rect(6, 10, 32, 20, 0)
    # Unlit 7-segment bed (22)
    for dx0 in (8, 14, 22, 28):
        digits.rect(dx0, 12, dx0 + 3, 18, 22)

    # 23:59 seven-segment pixel digits (4x7 each: '2' at x=8, '3' at x=14, ':' at x=19..20, '5' at x=22, '9' at x=28)
    glyphs = {
        '2': ["1111", "0001", "0001", "1111", "1000", "1000", "1111"],
        '3': ["1111", "0001", "0001", "1111", "0001", "0001", "1111"],
        '5': ["1111", "1000", "1000", "1111", "0001", "0001", "1111"],
        '9': ["1111", "1001", "1001", "1111", "0001", "0001", "1111"],
    }
    for ch, x0 in (('2', 8), ('3', 14), ('5', 22), ('9', 28)):
        for ry, row in enumerate(glyphs[ch]):
            col = 26 if ry == 0 else (25 if ry < 4 else 24)
            for rx, bit in enumerate(row):
                if bit == '1':
                    digits.put(x0 + rx, 12 + ry, col)
    # Colon ':' at x = 19, y = 14 and y = 17
    digits.put(19, 14, 26); digits.put(19, 15, 25)
    digits.put(19, 17, 26); digits.put(19, 18, 25)

    return [sh, casing, digits]


def build_side_mira_memory_silhouette():
    """Prop 5: ch01_prop_side_mira_memory_silhouette_idle (32x48, pivot (16, 44), z=9).
    Beat 06 frozen-person / Mira departure memory silhouette position marker in profile (32x48 cell, foot pivot (16, 44)).
    Follows ART_BIBLE.md §C.4/§C.5 silhouette study (shoulder-length hair with 3x3 temple flower mark, short fitted jacket,
    narrow waist, short flared skirt, exposed lower legs) in monochrome stone-slate + Trace 30/26 shimmer contour."""
    w, h = 32, 48
    ring = Layer(w, h, 'Trace_Shimmer_Ring')
    body = Layer(w, h, 'Frozen_Memory_Silhouette')
    accent = Layer(w, h, 'Trace_Contour_And_Flower')

    # Side-view ground Trace shimmer ellipse at y = 43..46 around foot pivot (16, 44)
    _side_shadow(ring, cx=16.0, cy=44.5, rx=7.5, ry=1.8)
    for x in range(8, 25):
        ring.put(x, 44, 30 if (x % 2 == 0) else 1)
    ring.put(8, 44, 26); ring.put(24, 44, 26)
    ring.put(12, 43, 30); ring.put(20, 43, 30)
    ring.put(12, 46, 30); ring.put(20, 46, 30)

    # Profile silhouette mask (facing West / looking back toward the bench, or East along platform:
    # let's face her West toward Elias / the bench so when Elias walks right to interact, they face each other!)
    # Wait: let's check! If Elias walks from left to right (facing East 'e') and interacts with Mira's memory
    # silhouette, having her face West (toward the bench/Elias) OR East (looking toward the train track / departure)
    # with her head slightly inclined creates an unmistakable profile silhouette!
    # Let's check ART_BIBLE.md §C.4/§C.5: shoulder-length hair with side flower, inward waist, short flared skirt,
    # exposed lower legs planting at y = 44.
    pix = {}
    # Boots & exposed lower legs (y = 35..44, planting at y = 44)
    # Near leg (x = 13..14) and far leg (x = 17..18) with a clean 2px gap (x = 15..16) so both legs read in profile
    for y in range(35, 42):
        pix[(13, y)] = 15 if y < 39 else 14
        pix[(14, y)] = 13
        pix[(17, y)] = 12
        pix[(18, y)] = 11
    for y in range(42, 45):
        # Ankle boots planted on y = 44
        for x in range(12, 16):
            pix[(x, y)] = 13 if y == 42 else 11
        for x in range(17, 21):
            pix[(x, y)] = 12 if y == 42 else 11

    # Short flared A-line skirt (y = 26..34: waist x = 13..18 flaring out to x = 9..22 at y = 34)
    for y in range(26, 35):
        flare = (y - 25) // 2
        x0, x1 = 13 - flare, 18 + flare
        for x in range(x0, x1 + 1):
            if y == 34:
                pix[(x, y)] = 11  # Crisp bottom skirt hem shadow
            elif x == x0:
                pix[(x, y)] = 15  # Top-left key-lit skirt edge
            elif x <= x0 + 2:
                pix[(x, y)] = 14
            elif x < (x0 + x1) // 2 + 1:
                pix[(x, y)] = 13
            elif x < x1 - 1:
                pix[(x, y)] = 12
            else:
                pix[(x, y)] = 11
        if y >= 28:
            pix[(14, y)] = 12  # Pleat shadow line
            pix[(17, y)] = 11

    # Narrow cinched waist (y = 23..25, x = 13..18) & short fitted jacket (y = 15..22, x = 11..20)
    torso_rows = [
        (15, 11, 19), (16, 10, 20), (17, 10, 20), (18, 10, 20),
        (19, 10, 20), (20, 11, 20), (21, 11, 19), (22, 12, 18),
        (23, 13, 18), (24, 13, 18), (25, 13, 18),
    ]
    for (y, x0, x1) in torso_rows:
        for x in range(x0, x1 + 1):
            if y in (23, 24):
                # Waist belt / cinch shadow
                pix[(x, y)] = 13 if x <= 14 else (12 if x <= 16 else 11)
            else:
                pix[(x, y)] = 15 if x == x0 else (14 if x <= x0 + 2 else (13 if x <= x1 - 2 else 11))
    # Fitted jacket collar dark separation at y = 15 & clasped forearm in profile
    for x in range(12, 19):
        pix[(x, 15)] = 11 if x >= 15 else 14
    for y in range(17, 22):
        pix[(15, y)] = 11  # Arm separation crease
        pix[(16, y)] = 14
        pix[(17, y)] = 15
    pix[(18, 20)] = 15; pix[(19, 20)] = 14  # Clasped hand in profile

    # Slender neck (y = 13..14, x = 13..16) + shoulder-length hair lock on left (x = 10..12, y = 12..15)
    for y in (13, 14):
        pix[(10, y)] = 14; pix[(11, y)] = 13; pix[(12, y)] = 11  # Shoulder-length hair lock
        pix[(14, y)] = 13; pix[(15, y)] = 12; pix[(16, y)] = 11  # Slender neck

    # Head & shoulder-length hair in profile (y = 4..12)
    head_rows = [
        (4, 12, 18),
        (5, 11, 19),
        (6, 10, 19),
        (7, 10, 20),
        (8, 10, 21),   # Profile nose bridge
        (9, 10, 20),
        (10, 10, 20),  # Profile chin
        (11, 10, 19),
        (12, 10, 16),  # Jawline under chin steps in cleanly!
    ]
    for (y, x0, x1) in head_rows:
        for x in range(x0, x1 + 1):
            # Hair mass on back/crown (x <= 15 or y <= 6) vs profile face (x = 16..21, y = 7..11)
            if y in (7, 8, 9, 10, 11) and x >= 16:
                pix[(x, y)] = 15 if x <= 18 else 14
            else:
                pix[(x, y)] = 15 if (y <= 5 and x <= 14) else (14 if x <= 12 else (13 if x <= 14 else 11))
    # Subtle dark eye & hair-face border in profile
    pix[(18, 8)] = 11
    for y in range(7, 12):
        pix[(15, y)] = 11

    # Paint 1px #0A0D14 (00) outer outline + Trace violet (30) rim highlights on the silhouette
    iso_elias.part(body, pix, outline=True)

    # 3x3 stepped temple flower mark in 30/31 with 25 centre (ART_BIBLE.md §C.4) at (14..16, 6..8)
    accent.put(15, 6, 31)
    accent.put(14, 7, 30)
    accent.put(15, 7, 25)
    accent.put(16, 7, 31)
    accent.put(15, 8, 30)
    # Restrained Trace memory rim glints (30/26) along the top-left contour
    for (tx, ty) in ((12, 4), (10, 7), (11, 16), (11, 30), (10, 34)):
        accent.put(tx, ty, 30)
    accent.put(15, 3, 26)

    return [ring, body, accent]


def build_side_voice_recorder_cup():
    """Prop 6: ch01_prop_side_voice_recorder_cup_idle (24x16, pivot (12, 14), z=9).
    Beat 06 personal micro-cassette voice recorder (ch01.waiting_lounge.audio_mira_01) and overturned coffee cup."""
    w, h = 24, 16
    sh = Layer(w, h, 'Contact_Shadow')
    props_l = Layer(w, h, 'Recorder_And_Spilled_Cup')

    sh.rect(2, 13, 21, 14, 1)

    # Left: personal voice recorder (x = 2..12, y = 7..13)
    props_l.rect(2, 7, 12, 13, 0)
    props_l.rect(3, 8, 11, 12, 13)
    props_l.hline(3, 11, 8, 15)    # Specular top bevel
    props_l.vline(3, 8, 12, 14)
    # Tape window & twin micro-reels
    props_l.rect(4, 9, 9, 11, 11)
    props_l.put(5, 10, 15)
    props_l.put(8, 10, 15)
    # Warm amber record/play indicator LED & brass corner glint
    props_l.put(10, 9, 26)
    props_l.put(10, 10, 24)
    props_l.put(11, 11, 25)

    # Right: overturned ceramic coffee cup on its side (x = 14..21, y = 7..13)
    props_l.rect(14, 7, 21, 13, 0)
    props_l.rect(15, 8, 19, 12, 9)
    props_l.hline(15, 19, 8, 10)   # Glazed ceramic highlight
    props_l.hline(15, 19, 12, 7)
    props_l.vline(20, 8, 12, 1)    # Dark hollow cup mouth facing right
    props_l.vline(19, 9, 11, 6)
    # Tiny handle loop on top-left of cup
    props_l.rect(15, 5, 18, 7, 0)
    props_l.hline(16, 17, 6, 10)

    return [sh, props_l]


# ============================================================================
# 4. ASSET REGISTRY EXPORT
# ============================================================================

def assets():
    """Return list of (stem, cat, w, h, layer_names, frames, fps, tags, meta) for tools/art/gen/registry.py."""
    return [
        (
            'ch01_char_elias_side_sheet',
            'characters',
            32, 48,
            ELIAS_SIDE_LAYERS,
            build_elias_side_sheet_frames(),
            10.0,
            elias_side_tags(),
            'TLF-075',
        ),
        (
            'ch01_env_side_bg_far_wall_arches_idle',
            'environments',
            960, 360,
            ['Tunnel_Void_And_Arches', 'Ceramic_Wall_Courses', 'Dado_And_Luminaires'],
            [build_side_bg_far_wall_arches()],
            1.0,
            None,
            'TLF-075',
        ),
        (
            'ch01_env_side_bg_near_wall_pillars_idle',
            'environments',
            960, 360,
            ['Upper_Steel_Girder', 'Overlook_Rail_And_Trim', 'Foreground_Pilasters'],
            [build_side_bg_near_wall_pillars()],
            1.0,
            None,
            'TLF-075',
        ),
        (
            'ch01_env_side_platform_floor_strip_idle',
            'environments',
            960, 72,
            ['SubLine_Rail_Trench', 'Terrazzo_Platform_Deck', 'Tactile_Strip_And_Curb'],
            [build_side_platform_floor_strip()],
            1.0,
            None,
            'TLF-075',
        ),
        (
            'ch01_prop_side_station_bench_idle',
            'props',
            64, 32,
            ['Contact_Shadow', 'Cast_Iron_Frame', 'Steel_Slats_And_Rivets'],
            [build_side_station_bench()],
            1.0,
            None,
            'TLF-075',
        ),
        (
            'ch01_prop_side_luggage_trolley_idle',
            'props',
            48, 40,
            ['Contact_Shadow', 'Steel_Trolley_And_Wheels', 'Stacked_Suitcases'],
            [build_side_luggage_trolley()],
            1.0,
            None,
            'TLF-075',
        ),
        (
            'ch01_prop_side_platform_pillar_idle',
            'props',
            32, 264,
            ['Contact_Shadow', 'Steel_And_Ceramic_Shaft', 'Capital_Plinth_And_Dado'],
            [build_side_platform_pillar()],
            1.0,
            None,
            'TLF-075',
        ),
        (
            'ch01_prop_side_clock_2359_idle',
            'props',
            40, 28,
            ['Mount_Shadow', 'Steel_Housing_And_Rods', 'LED_Digits_2359'],
            [build_side_clock_2359()],
            1.0,
            None,
            'TLF-075',
        ),
        (
            'ch01_prop_side_mira_memory_silhouette_idle',
            'props',
            32, 48,
            ['Trace_Shimmer_Ring', 'Frozen_Memory_Silhouette', 'Trace_Contour_And_Flower'],
            [build_side_mira_memory_silhouette()],
            1.0,
            None,
            'TLF-075',
        ),
        (
            'ch01_prop_side_voice_recorder_cup_idle',
            'props',
            24, 16,
            ['Contact_Shadow', 'Recorder_And_Spilled_Cup'],
            [build_side_voice_recorder_cup()],
            1.0,
            None,
            'TLF-075',
        ),
    ]


# ============================================================================
# 5. MOCKUPS (960x540 Assembled Beat 06 Scene + Colour/Greyscale Proof Sheet)
# ============================================================================

def _png_or_build(cat, stem, builder_fn):
    p = os.path.join(REPO, 'assets', cat, 'ch01', stem + '.png')
    if os.path.exists(p):
        return Image.open(p).convert('RGBA')
    return to_image(composite(builder_fn()))


def _elias_side_sheet_img():
    p = os.path.join(REPO, 'assets', 'characters', 'ch01', 'ch01_char_elias_side_sheet.png')
    if os.path.exists(p):
        return Image.open(p).convert('RGBA')
    return sheet_image([composite(f) for f in build_elias_side_sheet_frames()])


def mockup_path(name, out_dir=None):
    base = out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups')
    return os.path.join(base, name)


def _draw_crosshair(im, cx, cy, col_idx=26):
    col = PAL[col_idx] + (255,)
    outline = PAL[0] + (255,)
    w, h = im.size
    for dx, dy in ((-2, 0), (-1, 0), (1, 0), (2, 0), (0, -2), (0, -1), (0, 1), (0, 2)):
        if 0 <= cx + dx < w and 0 <= cy + dy < h:
            im.putpixel((cx + dx, cy + dy), col)
    if 0 <= cx < w and 0 <= cy < h:
        im.putpixel((cx, cy), outline)


def build_side_view_beat06_mockup():
    """960x540 mockup of the assembled Beat 06 side-view memory scene with 90 px letterbox bars,
    background layers, floor strip, 6 props, and Elias at three positions (idle, walk, interact)."""
    W, H = 960, 540
    Y_BAND = 90        # Active 960x360 composition area: y = 90..449
    Y_FLOOR_STRIP = 378  # Floor strip (960x72) top-left at y = 378 (local y = 288 in 960x360 band)
    Y_FLOOR_LINE = 394   # Walkable floor line (local y = 16 in floor strip, local y = 304 in 960x360 band)

    im = Image.new('RGBA', (W, H), PAL[0] + (255,))

    far_bg = _png_or_build('environments', 'ch01_env_side_bg_far_wall_arches_idle', build_side_bg_far_wall_arches)
    near_bg = _png_or_build('environments', 'ch01_env_side_bg_near_wall_pillars_idle', build_side_bg_near_wall_pillars)
    floor_strip = _png_or_build('environments', 'ch01_env_side_platform_floor_strip_idle', build_side_platform_floor_strip)

    bench = _png_or_build('props', 'ch01_prop_side_station_bench_idle', build_side_station_bench)
    trolley = _png_or_build('props', 'ch01_prop_side_luggage_trolley_idle', build_side_luggage_trolley)
    pillar = _png_or_build('props', 'ch01_prop_side_platform_pillar_idle', build_side_platform_pillar)
    clock = _png_or_build('props', 'ch01_prop_side_clock_2359_idle', build_side_clock_2359)
    mira_sil = _png_or_build('props', 'ch01_prop_side_mira_memory_silhouette_idle', build_side_mira_memory_silhouette)
    recorder = _png_or_build('props', 'ch01_prop_side_voice_recorder_cup_idle', build_side_voice_recorder_cup)

    side_sheet = _elias_side_sheet_img()
    iso_sheet = Image.open(os.path.join(REPO, 'assets', 'characters', 'ch01', 'ch01_char_elias_base_sheet.png')).convert('RGBA')

    # 1. Composite 2 background layers (960x360 at y=90) + floor strip (960x72 at y=378)
    im.alpha_composite(far_bg, (0, Y_BAND))
    im.alpha_composite(near_bg, (0, Y_BAND))
    im.alpha_composite(floor_strip, (0, Y_FLOOR_STRIP))

    # 2. Place standalone floor-line & wall props on Y_FLOOR_LINE = 394:
    #    - Standalone full-height platform pillars (32x264, pivot (16, 260)) at x = 240 and x = 720 on y = 392
    im.alpha_composite(pillar, (240 - 16, 392 - 260))
    im.alpha_composite(pillar, (720 - 16, 392 - 260))
    #    - Suspended 23:59 clock (pivot (20, 24)) mounted under upper girder at (480, 156)
    im.alpha_composite(clock, (480 - 20, 156 - 24))
    #    - Luggage trolley (pivot (24, 36)) at (292, Y_FLOOR_LINE)
    im.alpha_composite(trolley, (292 - 24, Y_FLOOR_LINE - 36))
    #    - Station waiting bench (pivot (32, 28)) at (588, Y_FLOOR_LINE)
    im.alpha_composite(bench, (588 - 32, Y_FLOOR_LINE - 28))
    #    - Voice recorder + spilled coffee cup (pivot (12, 14)) resting on the right half of the bench seat at (602, Y_FLOOR_LINE - 10)
    im.alpha_composite(recorder, (602 - 12, (Y_FLOOR_LINE - 10) - 14))
    #    - Mira departure frozen silhouette marker (pivot (16, 44)) at (664, Y_FLOOR_LINE)
    im.alpha_composite(mira_sil, (664 - 16, Y_FLOOR_LINE - 44))

    # 3. Place Side-View Elias (pivot (16, 44)) at THREE positions on Y_FLOOR_LINE = 394:
    #    Position 1 (Left, x=144):   idle_e F1 (frame 0)
    #    Position 2 (Center, x=388): walk_e F1 (frame 2)
    #    Position 3 (Right, x=528):  interact_e F2 (frame 9, neutral reach/inspect gesture toward bench & recorder)
    elias_idle_e = side_sheet.crop((0 * 32, 0, 1 * 32, 48))
    elias_walk_e = side_sheet.crop((2 * 32, 0, 3 * 32, 48))
    elias_inter_e = side_sheet.crop((9 * 32, 0, 10 * 32, 48))
    elias_walk_w = side_sheet.crop((13 * 32, 0, 14 * 32, 48))

    im.alpha_composite(elias_idle_e, (144 - 16, Y_FLOOR_LINE - 44))
    im.alpha_composite(elias_walk_e, (388 - 16, Y_FLOOR_LINE - 44))
    im.alpha_composite(elias_inter_e, (528 - 16, Y_FLOOR_LINE - 44))
    # Also show mirrored walk_w on the far right (x=828) to demonstrate W mirror in context
    im.alpha_composite(elias_walk_w, (828 - 16, Y_FLOOR_LINE - 44))

    # Subtle pivot markers on the 3 Elias positions + Mira silhouette
    for px in (144, 388, 528, 664, 828):
        _draw_crosshair(im, px, Y_FLOOR_LINE, 26)

    # 4. Letterbox Bars (top y=0..89, bottom y=450..539) with subtle border hairlines & technical legend
    for x in range(W):
        im.putpixel((x, 89), PAL[12] + (255,))
        im.putpixel((x, 450), PAL[12] + (255,))

    # Top letterbox bar: title & layer/coord summary + 1x native strip of all 11 e frames + Iso comparison
    _draw_text_img(im, 16, 12, "TLF-075: BEAT 06 SIDE-VIEW MEMORY SCENE MOCKUP (960X540 CANVAS, 90PX LETTERBOX BARS)", PAL[15], scale=1)
    _draw_text_img(im, 16, 26, "ACTIVE BAND: 960X360 (Y=90..449)  FLOOR STRIP: 960X72 (Y=378..449)  FLOOR LINE: Y=394", PAL[25], scale=1)
    _draw_text_img(im, 16, 40, "ELIAS POSITIONS ON Y=394:  1. IDLE_E (X=144)   2. WALK_E (X=388)   3. INTERACT_E (X=528)   [+ WALK_W MIRROR X=828]", PAL[14], scale=1)
    _draw_text_img(im, 16, 54, "PROPS: PILLAR (X=240,720)  TROLLEY (X=292)  CLOCK 23:59 (X=480,Y=156)  BENCH (X=588)  RECORDER (X=602)  MIRA SILHOUETTE (X=664)", PAL[29], scale=1)

    # Bottom letterbox bar (y=454..536): 1x scale check of Iso Elias (s, se, e) vs Side Elias (idle_e 2f, walk_e 6f, interact_e 3f) + Mira
    _draw_text_img(im, 16, 458, "1X SCALE & SILHOUETTE CHECK ON FLOOR 02 (ISO ELIAS S/SE/E VS SIDE ELIAS IDLE_E 2F / WALK_E 6F / INTERACT_E 3F + MIRA):", PAL[15], scale=1)
    strip_bg = Image.new('RGBA', (620, 56), PAL[2] + (255,))
    # Floor line y=48 inside strip_bg
    for x in range(620):
        strip_bg.putpixel((x, 48), PAL[4] + (255,))
    # Paste Iso s (0), se (10), e (20)
    for i, idx in enumerate((0, 10, 20)):
        fr = iso_sheet.crop((idx * 32, 0, (idx + 1) * 32, 48))
        strip_bg.alpha_composite(fr, (8 + i * 36, 4))
    # Divider line
    for y in range(4, 52):
        strip_bg.putpixel((120, y), PAL[13] + (255,))
    # Paste all 11 authored side e frames (0..10)
    for i in range(11):
        fr = side_sheet.crop((i * 32, 0, (i + 1) * 32, 48))
        strip_bg.alpha_composite(fr, (128 + i * 38, 4))
    # Paste Mira silhouette at end of strip
    strip_bg.alpha_composite(mira_sil, (128 + 11 * 38 + 8, 4))
    im.alpha_composite(strip_bg, (16, 474))

    _draw_text_img(im, 652, 476, "CELL: 32X48 PX", PAL[15], scale=1)
    _draw_text_img(im, 652, 488, "PIVOT: (16, 44)", PAL[26], scale=1)
    _draw_text_img(im, 652, 500, "PALETTE: 12/32", PAL[14], scale=1)
    _draw_text_img(im, 652, 512, "W = FLIP_H(E)", PAL[29], scale=1)

    return im


def build_side_view_greyscale_proof():
    """1960x1240 colour + luminance greyscale proof sheet for TLF-075:
    - Top row: 960x540 Beat 06 mockup in COLOUR (left) and LUMINANCE GREYSCALE .convert('L') (right)
    - Middle panel (colour) + Bottom panel (luminance greyscale):
      x3 nearest-neighbour zoom of Iso Elias (s, se, e) vs Side Elias (idle_e 2f, walk_e 6f, interact_e 3f, plus w mirrors)
      and all 6 side-view props on Floor 02 & Wall 08."""
    W, H = 1960, 1240
    canvas = Image.new('RGBA', (W, H), PAL[0] + (255,))

    mockup = build_side_view_beat06_mockup()
    side_sheet = _elias_side_sheet_img()
    iso_sheet = Image.open(os.path.join(REPO, 'assets', 'characters', 'ch01', 'ch01_char_elias_base_sheet.png')).convert('RGBA')
    bench = _png_or_build('props', 'ch01_prop_side_station_bench_idle', build_side_station_bench)
    trolley = _png_or_build('props', 'ch01_prop_side_luggage_trolley_idle', build_side_luggage_trolley)
    pillar = _png_or_build('props', 'ch01_prop_side_platform_pillar_idle', build_side_platform_pillar)
    clock = _png_or_build('props', 'ch01_prop_side_clock_2359_idle', build_side_clock_2359)
    mira_sil = _png_or_build('props', 'ch01_prop_side_mira_memory_silhouette_idle', build_side_mira_memory_silhouette)
    recorder = _png_or_build('props', 'ch01_prop_side_voice_recorder_cup_idle', build_side_voice_recorder_cup)

    _draw_text_img(canvas, 16, 10, "TLF-075 SIDE-VIEW ELIAS & BEAT 06 BACKGROUND KIT — COLOUR (LEFT / MIDDLE) & LUMINANCE GREYSCALE PROOF (RIGHT / BOTTOM)", PAL[15], scale=2)
    canvas.alpha_composite(mockup, (16, 36))
    canvas.alpha_composite(mockup.convert('L').convert('RGBA'), (984, 36))

    # Build a 1928x310 detail comparison band (rendered once in colour, then duplicated in .convert('L') below)
    band = Image.new('RGBA', (1928, 310), PAL[2] + (255,))
    # Upper half of band has Wall 08 backdrop (y=28..164) so characters & props are tested against both Wall 08 and Floor 02
    wall_strip = Image.new('RGBA', (1928, 110), PAL[8] + (255,))
    band.alpha_composite(wall_strip, (0, 28))

    _draw_text_img(band, 12, 8, "X3 ZOOM: ISO ELIAS (S/SE/E) VS SIDE ELIAS (IDLE_E 2F, WALK_E 6F, INTERACT_E 3F, W MIRRORS) + MIRA SILHOUETTE & PROPS", PAL[26], scale=1)

    # Paste x3 characters (96x144 each) along y=34..178 (so upper body is on Wall 08 and lower body/feet are on Floor 02!)
    char_list = [
        ("ISO S", iso_sheet.crop((0 * 32, 0, 1 * 32, 48))),
        ("ISO SE", iso_sheet.crop((10 * 32, 0, 11 * 32, 48))),
        ("ISO E", iso_sheet.crop((20 * 32, 0, 21 * 32, 48))),
        ("IDLE_E 1", side_sheet.crop((0 * 32, 0, 1 * 32, 48))),
        ("IDLE_E 2", side_sheet.crop((1 * 32, 0, 2 * 32, 48))),
        ("WALK_E 1", side_sheet.crop((2 * 32, 0, 3 * 32, 48))),
        ("WALK_E 2", side_sheet.crop((3 * 32, 0, 4 * 32, 48))),
        ("WALK_E 3", side_sheet.crop((4 * 32, 0, 5 * 32, 48))),
        ("WALK_E 4", side_sheet.crop((5 * 32, 0, 6 * 32, 48))),
        ("WALK_E 5", side_sheet.crop((6 * 32, 0, 7 * 32, 48))),
        ("WALK_E 6", side_sheet.crop((7 * 32, 0, 8 * 32, 48))),
        ("INTER_E 1", side_sheet.crop((8 * 32, 0, 9 * 32, 48))),
        ("INTER_E 2", side_sheet.crop((9 * 32, 0, 10 * 32, 48))),
        ("INTER_E 3", side_sheet.crop((10 * 32, 0, 11 * 32, 48))),
        ("INTER_W 2", side_sheet.crop((20 * 32, 0, 21 * 32, 48))),
        ("MIRA SIL", mira_sil),
    ]
    for idx, (lbl, spr) in enumerate(char_list):
        cx = 10 + idx * 118
        z3 = spr.resize((96, 144), Image.NEAREST)
        band.alpha_composite(z3, (cx, 34))
        _draw_crosshair(band, cx + 16 * 3, 34 + 44 * 3, 26)
        _draw_text_img(band, cx + 8, 184, lbl, PAL[15], scale=1)

    # Bottom sub-strip of band (y=202..304): x2 zoomed props + full 22-frame 1x sheet
    _draw_text_img(band, 12, 204, "1X FULL 22-FRAME SHEET (704X48) + X2 SIDE-VIEW PROPS (BENCH, TROLLEY, CLOCK 23:59, RECORDER/CUP, PILLAR):", PAL[25], scale=1)
    band.alpha_composite(side_sheet, (12, 224))
    band.alpha_composite(bench.resize((128, 64), Image.NEAREST), (740, 224))
    band.alpha_composite(trolley.resize((96, 80), Image.NEAREST), (890, 216))
    band.alpha_composite(clock.resize((80, 56), Image.NEAREST), (1010, 228))
    band.alpha_composite(recorder.resize((72, 48), Image.NEAREST), (1114, 236))
    band.alpha_composite(pillar.crop((0, 0, 32, 96)), (1210, 208))
    band.alpha_composite(pillar.crop((0, 168, 32, 264)), (1250, 208))

    canvas.alpha_composite(band, (16, 588))
    canvas.alpha_composite(band.convert('L').convert('RGBA'), (16, 912))

    return canvas


MOCKUP_FILES = (
    'ch01_tlf075_side_view_beat06_mockup.png',
    'ch01_tlf075_side_view_greyscale_proof.png',
)


def write_mockups(out_dir=None):
    os.makedirs(out_dir if out_dir is not None else os.path.join(REPO, 'design', 'art', 'mockups'), exist_ok=True)
    m1 = build_side_view_beat06_mockup()
    m1.save(mockup_path('ch01_tlf075_side_view_beat06_mockup.png', out_dir))
    m2 = build_side_view_greyscale_proof()
    m2.save(mockup_path('ch01_tlf075_side_view_greyscale_proof.png', out_dir))


if __name__ == '__main__':
    write_mockups()
    print('TLF-075 mockups written.')
