import sys, os
from placement import *

IMG = {}
BADGE_OFF = (3, -8)   # child offset of the lever badge from the lever pivot (see placement sheet 0.9)


def img(stem):
    if stem not in IMG:
        d = 'environments' if stem.startswith('ch01_env') else 'props'
        IMG[stem] = Image.open(os.path.join(REPO, 'assets', d, 'ch01', stem + '.png')).convert('RGBA')
    return IMG[stem]


def floor_map(r):
    m = {}
    for y in range(r.H):
        for x in range(r.W):
            m[(x, y)] = r.base_tile if hasattr(r, 'base_tile') else ('dark' if r.base == 'dark' else 'concrete')
    for x, y in cracked_tiles(r):
        m[(x, y)] = 'cracked'
    for label, tiles, t in r.areas:
        for q in tiles:
            if t is None: m.pop(q, None)
            else: m[q] = t
    return m


def door_pos(r, door_id):
    return r.pos[door_id]


def mount_pivot(r, mount, dy=-14):
    side, k = mount[0], mount[1]
    if len(mount) > 2:
        dy = mount[2]
    n, w = wall_pivots(r)
    b = n[k] if side == 'N' else w[k]
    return (b[0], b[1] + dy)


def pieces(r, anchor=None):
    P = []   # (z, y, image, origin)
    fm = floor_map(r)
    for (x, y), t in fm.items():
        p = px(x, y)
        P.append((0, x + y, img(T[t]), (p[0] - 16, p[1])))
    n, w = wall_pivots(r)
    for b in n:
        P.append((5, b[1], img(SP['wall_n'][0]), (b[0] - 16, b[1] - 56)))
    for b in w:
        P.append((5, b[1], img(SP['wall_w'][0]), (b[0] - 16, b[1] - 56)))
    for k in r.clocks:
        b = n[k]
        P.append((7, b[1], img(SP['clock'][0]), (b[0] - 16, b[1] - 38 - 20)))
    for door_id, side in r.doors:
        d = r.pos[door_id]
        s = SP['arch_e'] if side in 'WE' else SP['arch_n']
        P.append((s[3], d[1], img(s[0]), (d[0] - 16, d[1] - 56)))
    for axis, c in rail_modules(r):
        im = img(SP['rail'][0])
        if axis == 'y': im = im.transpose(Image.FLIP_LEFT_RIGHT)
        P.append((8, c[1], im, (c[0] - 16, c[1] - 40)))
    for pr in r.props:
        if not pr['sprite']: continue
        key = pr['sprite']
        stem, piv, size, z, layer = SP[key]
        if pr.get('zlayer'): z, layer = pr['zlayer']
        pos = pr['pos']
        if pr.get('mount'):
            pos = mount_pivot(r, pr['mount'])
        elif pr.get('off'):
            pos = (pos[0] + pr['off'][0], pos[1] + pr['off'][1])
        im = img(stem)
        if pr.get('scale2'):
            im = im.resize((im.width * 2, im.height * 2), Image.NEAREST); piv = (piv[0] * 2, piv[1] * 2)
        zz = z
        if pr.get('ov'): zz = 9
        P.append((zz, pos[1], im, (int(pos[0] - piv[0]), int(pos[1] - piv[1]))))
        if pr.get('badge'):
            bim = img('ch01_prop_lever_badge_%s_idle' % pr['badge'])
            P.append((zz, pos[1] + 0.1, bim, (int(pos[0] + BADGE_OFF[0] - 2), int(pos[1] + BADGE_OFF[1] - 3))))
    if anchor is not None:
        sheet = Image.open(os.path.join(REPO, 'assets', 'characters', 'ch01', 'ch01_char_elias_base_sheet.png')).convert('RGBA')
        fr = sheet.crop((10 * 32, 0, 11 * 32, 48))   # idle_se frame 1
        P.append((10, anchor[1], fr, (anchor[0] - 16, anchor[1] - 44)))
    return P


def render_mockup(r, path, anchor=None):
    bg = PAL[0] + (255,)
    cv = Image.new('RGBA', (640, 360), bg)
    for z, y, im, o in sorted(pieces(r, anchor), key=lambda t: (t[0], t[1])):
        cv.alpha_composite(im, (int(o[0]), int(o[1]))) if 0 <= o[0] and 0 <= o[1] and o[0] + im.width <= 640 and o[1] + im.height <= 360 else paste_clip(cv, im, o)
    cv.save(path)


def paste_clip(cv, im, o):
    tmp = Image.new('RGBA', cv.size, (0, 0, 0, 0))
    tmp.paste(im, (int(o[0]), int(o[1])))
    cv.alpha_composite(tmp)


MOCKUPS = [('arrival_platform', None), ('concourse_west', 'safe_anchor_west'), ('signal_control', 'safe_anchor_center'),
           ('security_crossing', 'safe_anchor_west')]


def mockup_path(key, outd=None):
    return os.path.join(outd or os.path.join(REPO, 'design', 'art', 'mockups'), 'ch01_%s_mockup.png' % key)


def write_mockups(outd=None):
    rooms = build_rooms()
    by = {r.key: r for r in rooms}
    outd = outd or os.path.join(REPO, 'design', 'art', 'mockups')
    os.makedirs(outd, exist_ok=True)
    for key, anchor_name in MOCKUPS:
        r = by[key]
        anchor = (352, 168) if anchor_name is None else r.pos[anchor_name]
        render_mockup(r, mockup_path(key, outd), anchor=anchor)


if __name__ == '__main__':
    write_mockups()
    print('mockups ok')
