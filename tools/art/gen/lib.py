"""TLF art authoring helpers. Pillow + stdlib only.
Pixels hold palette indices (0..31) or None (transparent). Output: layered .pxo in
Pixelorama 1.2.3 format (pxo_version 7: zip of data.json + raw RGBA cels).
The zip is written with fixed timestamps so the same input always gives the same bytes."""
import json, zipfile, copy, os, re, tempfile
from PIL import Image

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
SCR = os.environ.get('TLF_ART_SCRATCH') or os.path.join(tempfile.gettempdir(), 'tlf_art_gen_preview')   # scratch for optional previews only
ZIP_DATE = (2026, 10, 31, 0, 0, 0)
AUTHOR = 'TLF design-art agent (Claude Code, Sonnet 5.5)'


def load_pal():
    pal = {}
    for l in open(os.path.join(REPO, 'assets/source/ch01/ch01_palette_elysium09.gpl')):
        m = re.match(r'\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d\d)\s', l)
        if m:
            pal[int(m.group(4))] = tuple(int(m.group(i)) for i in (1, 2, 3))
    assert len(pal) == 32
    return pal


PAL = load_pal()
RGB2IDX = {v: k for k, v in PAL.items()}


class Layer:
    def __init__(self, w, h, name, visible=True):
        self.w, self.h, self.name = w, h, name
        self.visible = visible
        self.p = [[None] * w for _ in range(h)]

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.p[y][x] = c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.p[y][x]
        return None

    def rect(self, x0, y0, x1, y1, c):  # inclusive
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, c)

    def hline(self, x0, x1, y, c):
        self.rect(x0, y, x1, y, c)

    def vline(self, x, y0, y1, c):
        self.rect(x, y0, x, y1, c)

    def line(self, x0, y0, x1, y1, c):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.put(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy; x0 += sx
            if e2 <= dx:
                err += dx; y0 += sy

    def blit(self, other, ox=0, oy=0, skip=None):
        for y in range(other.h):
            for x in range(other.w):
                c = other.p[y][x]
                if c is not None and c != skip:
                    self.put(x + ox, y + oy, c)

    def mask(self):
        return {(x, y) for y in range(self.h) for x in range(self.w) if self.p[y][x] is not None}

    def clear(self):
        self.p = [[None] * self.w for _ in range(self.h)]

    def flip_h(self):
        n = Layer(self.w, self.h, self.name, visible=self.visible)
        n.p = [list(reversed(r)) for r in self.p]
        return n

    def copy(self):
        n = Layer(self.w, self.h, self.name, visible=self.visible)
        n.p = [list(r) for r in self.p]
        return n

    def rgba(self):
        out = bytearray()
        for y in range(self.h):
            for x in range(self.w):
                c = self.p[y][x]
                if c is None:
                    out += b'\x00\x00\x00\x00'
                else:
                    r, g, b = PAL[c]
                    out += bytes((r, g, b, 255))
        return bytes(out)


def composite(layers):
    w, h = layers[0].w, layers[0].h
    c = Layer(w, h, 'final')
    for l in layers:  # layer 0 = bottom
        if getattr(l, 'visible', True):
            c.blit(l)
    return c


def outline_mask(mask, col_outline, target, w, h, diag=False):
    """Paint 1px outline (4-neighbour) around mask into target layer where target is empty."""
    for (x, y) in mask:
        nbrs = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
        if diag:
            nbrs += [(x + 1, y + 1), (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1)]
        for nx, ny in nbrs:
            if (nx, ny) not in mask and 0 <= nx < w and 0 <= ny < h and target.p[ny][nx] is None:
                target.p[ny][nx] = col_outline


def to_image(layer):
    im = Image.new('RGBA', (layer.w, layer.h), (0, 0, 0, 0))
    for y in range(layer.h):
        for x in range(layer.w):
            c = layer.p[y][x]
            if c is not None:
                im.putpixel((x, y), PAL[c] + (255,))
    return im


def sheet_image(frames):
    """frames: list of Layer (composited), horizontal strip."""
    w, h = frames[0].w, frames[0].h
    im = Image.new('RGBA', (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        im.paste(to_image(f), (i * w, 0))
    return im


_LAYER = {"animated_params": "Dictionary[String, Dictionary]({\n\"opacity\": {}\n})", "blend_mode": 0,
          "clipping_mask": False, "effects": [], "locked": False, "metadata": {}, "name": "", "new_cels_linked": False,
          "opacity": 1.0, "parent": -1, "type": 0, "ui_color": "(0.0, 0.0, 0.0, 0.0)", "visible": True}
_CEL = {"metadata": {}, "opacity": 1.0, "ui_color": "(0.0, 0.0, 0.0, 0.0)", "z_index": 0}


def _template():
    """data.json skeleton of a Pixelorama 1.2.3 project (same fields as the batch-1 files)."""
    return {"author_company": "The Last Frame Team", "author_contact": "", "author_display_name": AUTHOR,
            "author_real_name": "", "brushes": [], "color_mode": 5, "current_frame": 0, "current_layer": 0,
            "fps": 1.0, "frames": [], "guides": [], "layers": [], "license": "CC0-1.0 / Original Production Asset",
            "metadata": {}, "next_keyframe_id": 0, "palettes": [], "pixelorama_version": "v1.2.3-stable",
            "project_current_palette_name": "TLF-CH01-32", "pxo_version": 7, "reference_images": [],
            "size_x": 32, "size_y": 16, "symmetry_points": [32.0, 16.0], "tags": [], "tile_mode_x_basis_x": 32,
            "tile_mode_x_basis_y": 0, "tile_mode_y_basis_x": 0, "tile_mode_y_basis_y": 16, "tilesets": [],
            "user_data": "", "vanishing_points": []}


def _zwrite(zf, name, data):
    zi = zipfile.ZipInfo(name, date_time=ZIP_DATE)
    zi.compress_type = zipfile.ZIP_DEFLATED
    zi.external_attr = 0o644 << 16
    zf.writestr(zi, data)


def pxo_bytes(w, h, layer_names, frames, fps=1.0, tags=None, user_data='TLF-039', durations=None):
    """frames: list of list[Layer] (one Layer per layer name, bottom->top). Returns the .pxo file bytes."""
    import io
    d = _template()
    d['layers'] = []
    for li_idx, n in enumerate(layer_names):
        l = copy.deepcopy(_LAYER); l['name'] = n
        if frames and li_idx < len(frames[0]) and not getattr(frames[0][li_idx], 'visible', True):
            l['visible'] = False
        d['layers'].append(l)
    d['frames'] = [{'cels': [copy.deepcopy(_CEL) for _ in layer_names],
                    'duration': float(durations[idx]) if durations else 1.0, 'metadata': {}}
                   for idx, _ in enumerate(frames)]
    d['size_x'], d['size_y'] = w, h
    d['symmetry_points'] = [float(w), float(h)]
    d['tile_mode_x_basis_x'] = w
    d['tile_mode_y_basis_y'] = h
    d['fps'] = float(fps)
    d['tags'] = tags or []
    d['user_data'] = user_data
    buf = io.BytesIO()
    zf = zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED)
    _zwrite(zf, 'mimetype', 'application/x-pixelorama')
    _zwrite(zf, 'data.json', json.dumps(d))
    for fi, layers in enumerate(frames, start=1):
        assert len(layers) == len(layer_names)
        for li, l in enumerate(layers, start=1):
            assert (l.w, l.h) == (w, h)
            _zwrite(zf, f'image_data/frames/{fi}/layer_{li}', l.rgba())
        _zwrite(zf, f'image_data/final_images/{fi}', composite(layers).rgba())
    zf.close()
    return buf.getvalue()


def write_pxo(path, w, h, layer_names, frames, fps=1.0, tags=None, user_data='TLF-039'):
    open(path, 'wb').write(pxo_bytes(w, h, layer_names, frames, fps, tags, user_data))


def preview(layers_or_images, path, zoom=6, bg=(70, 70, 80), pad=8):
    ims = []
    for x in layers_or_images:
        ims.append(to_image(x) if isinstance(x, Layer) else x)
    W = sum(i.width * zoom + pad for i in ims) + pad
    H = max(i.height * zoom for i in ims) + 2 * pad
    sh = Image.new('RGBA', (W, H), bg + (255,))
    x = pad
    for i in ims:
        sh.alpha_composite(i.resize((i.width * zoom, i.height * zoom), Image.NEAREST), (x, pad))
        x += i.width * zoom + pad
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sh.save(path)
