"""Single registry of every asset the generators produce (TLF-039 / TLF-042).
Each entry knows its .pxo stem, runtime PNG folder, canvas, layers and frames."""
from lib import *
import tiles, props, t2, t3, elias_build, ui_wheel


class Asset:
    def __init__(self, stem, cat, w, h, layer_names, frames, fps=1.0, tags=None, user_data='TLF-039', png_dir=None):
        self.stem, self.cat, self.w, self.h = stem, cat, w, h
        self.png_dir = png_dir
        self.layer_names, self.frames, self.fps, self.tags, self.user_data = layer_names, frames, fps, tags, user_data

    def pxo(self):
        return pxo_bytes(self.w, self.h, self.layer_names, self.frames, self.fps, self.tags, self.user_data)

    def expected_png(self):
        return sheet_image([composite(f) for f in self.frames])

    def pxo_rel(self):
        return 'assets/source/ch01/%s.pxo' % self.stem

    def png_rel(self):
        if self.png_dir:
            return 'assets/%s/%s.png' % (self.png_dir, self.stem)
        return 'assets/%s/ch01/%s.png' % (self.cat, self.stem)


def all_assets():
    out = []
    fr = elias_build.sheet_frames(elias_build.build_all())
    out.append(Asset('ch01_char_elias_base_sheet', 'characters', 32, 48,
                     ['Cast_Shadow', 'Boots_And_Coat', 'Head_Arms_And_Watch_Chain'], fr, fps=10.0,
                     tags=elias_build.elias_tags(), user_data='TLF-039'))
    for n, (fn, names) in tiles.TILES.items():
        out.append(Asset('ch01_env_%s_idle' % n, 'environments', 32, 16, names, [fn()]))
    for key, (fn, names, w, h, cat, st) in props.ASSETS.items():
        base = key.split('#')[0]
        stem = 'ch01_env_%s_%s' % (base, st) if cat == 'environments' else 'ch01_%s_%s' % (base, st)
        out.append(Asset(stem, cat, w, h, names, [fn()]))
    for key, (fn, names, w, h, cat, st) in t2.T2.items():
        out.append(Asset('ch01_%s_%s' % (key.split('#')[0], st), cat, w, h, names, [fn()]))
    for key, (fn, names, w, h, cat, st) in t3.T3.items():
        out.append(Asset('ch01_%s_%s' % (key.split('#')[0], st), cat, w, h, names, [fn()], user_data='TLF-042'))
    for (stem, w, h, names, layers, _m) in ui_wheel.assets():
        out.append(Asset(stem, 'ui', w, h, names, [layers], user_data='TLF-053', png_dir='ui/ability_wheel'))
    return out
