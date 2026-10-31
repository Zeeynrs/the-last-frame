from elias import *
import sys

DIRS = ['s', 'se', 'e', 'ne', 'n']


def idle_poses(view):
    bobs = [0, 0, 1, 1]
    out = []
    for i in range(4):
        if view in ('s', 'n'):
            p = dict(bob=bobs[i], L=44, R=44, fl=[(0, 0), (1, 0), (0, 0), (0, 1)][i], arms=(0, 0))
        else:
            p = dict(bob=bobs[i], near=(0, 44), far=(0, 44), fl=[0, 1, 0, 0][i], arm_near=0, arm_far=0)
        out.append(p)
    return out


def walk_poses(view):
    P = []
    if view in ('s', 'n'):
        fw = 45 if view == 's' else 43   # forward foot sole row (toward camera is lower on screen)
        bk = 43 if view == 's' else 45
        # contact A (left fwd), recoil, passing; then mirrored
        P.append(dict(bob=1, L=fw, R=bk, fl=(1, 0), arms=(-1, 1)))
        P.append(dict(bob=1, L=44, R=43, fl=(0, 0), arms=(0, 0)))
        P.append(dict(bob=0, L=44, R=41, fl=(0, 1), arms=(0, 0)))
        P.append(dict(bob=1, L=bk, R=fw, fl=(0, 1), arms=(1, -1)))
        P.append(dict(bob=1, L=43, R=44, fl=(0, 0), arms=(0, 0)))
        P.append(dict(bob=0, L=41, R=44, fl=(1, 0), arms=(0, 0)))
    else:
        s = 4 if view == 'e' else 3
        fw = 44
        bk = 43
        fs = {'e': (44, 43), 'se': (45, 43), 'ne': (43, 45)}[view]
        P.append(dict(bob=1, near=(s - 1, fs[0]), far=(-s, fs[1]), fl=1, arm_near=-3, arm_far=3))
        P.append(dict(bob=1, near=(1, 44), far=(-2, 43), fl=0, arm_near=-1, arm_far=1))
        P.append(dict(bob=0, near=(0, 44), far=(2, 41), fl=0, arm_near=0, arm_far=0))
        P.append(dict(bob=1, near=(-s, fs[1]), far=(s - 1, fs[0]), fl=1, arm_near=3, arm_far=-3))
        P.append(dict(bob=1, near=(-2, 43), far=(1, 44), fl=0, arm_near=1, arm_far=-1))
        P.append(dict(bob=0, near=(2, 41), far=(0, 44), fl=0, arm_near=0, arm_far=0))
    return P


def build_all():
    frames = {}  # (dir, kind, i) -> [shadow, body, head]
    for d in DIRS:
        for i, p in enumerate(idle_poses(d)):
            frames[(d, 'idle', i)] = list(render(d, p))
        for i, p in enumerate(walk_poses(d)):
            frames[(d, 'walk', i)] = list(render(d, p))
    return frames


MIRROR = {'nw': 'ne', 'w': 'e', 'sw': 'se'}
ORDER = ['s', 'se', 'e', 'ne', 'n', 'nw', 'w', 'sw']


def sheet_frames(frames):
    out = []  # list of [3 layers] in sheet order (80)
    for d in ORDER:
        for kind, n in (('idle', 4), ('walk', 6)):
            for i in range(n):
                if d in MIRROR:
                    src = frames[(MIRROR[d], kind, i)]
                    out.append([l.flip_h() for l in src])
                else:
                    out.append(frames[(d, kind, i)])
    assert len(out) == 80
    return out


def elias_tags():
    """16 Pixelorama tags: idle_<dir> 4 frames @8fps, walk_<dir> 6 frames @10fps, 1-based, in sheet order."""
    tags, n = [], 1
    for d in ORDER:
        tags.append({"color": "4ce0d2ff", "from": n, "name": "idle_" + d, "to": n + 3, "user_data": "8fps_loop"}); n += 4
        tags.append({"color": "eb8a28ff", "from": n, "name": "walk_" + d, "to": n + 5, "user_data": "10fps_loop"}); n += 6
    return tags


if __name__ == '__main__':
    frames = build_all()
    # preview contact sheet: rows = dirs, cols = 4 idle + 6 walk
    Z = 4
    sheet = Image.new('RGBA', (10 * 32 * Z + 9 * 4, 5 * 48 * Z + 4 * 4), (60, 60, 70, 255))
    for r, d in enumerate(DIRS):
        for c in range(10):
            key = (d, 'idle', c) if c < 4 else (d, 'walk', c - 4)
            fr = composite(frames[key])
            im = to_image(fr).resize((32 * Z, 48 * Z), Image.NEAREST)
            sheet.alpha_composite(im, (c * (32 * Z + 4), r * (48 * Z + 4)))
    sheet.save(SCR + r'\elias_after.png')
    print('ok')
