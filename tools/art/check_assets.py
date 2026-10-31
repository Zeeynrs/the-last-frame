#!/usr/bin/env python3
"""TLF art QA check (TLF-039). Stdlib + Pillow only.

For every PNG checked:
  1. size == the size in design/art/ASSET_METADATA.md (row with that export path)
  2. every opaque pixel colour is in the TLF-CH01-32 palette (exceptions listed)
  3. alpha is binary (0 or 255 only)
For ch01_char_elias_base_sheet.png additionally:
  4. size is exactly 2560x48 (80 frames of 32x48)
  5. mirrored directions (nw, w, sw) are exact flip_h copies of (ne, e, se): pixel diff 0

Usage (from the repo root):
  python tools/art/check_assets.py                 # every PNG listed in the metadata
  python tools/art/check_assets.py FILE.png ...    # only these files
  python tools/art/check_assets.py --metadata P --palette P2 FILE.png ...
Exit code 0 = all checks pass, 1 = at least one failure.
"""
import argparse
import os
import re
import sys

from PIL import Image

ELIAS = "ch01_char_elias_base_sheet.png"
FRAME_W, FRAME_H, FRAMES_PER_DIR = 32, 48, 10  # 4 idle + 6 walk per direction
DIR_ORDER = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
MIRRORS = {"nw": "ne", "w": "e", "sw": "se"}


def repo_root():
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.normpath(os.path.join(here, "..", ".."))


def load_palette(path):
    pal = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            m = re.match(r"\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d\d)\s", line)
            if m:
                pal[tuple(int(m.group(i)) for i in (1, 2, 3))] = int(m.group(4))
    if len(pal) != 32:
        raise SystemExit("palette %s: expected 32 colours, found %d" % (path, len(pal)))
    return pal


def load_metadata_sizes(path):
    """Map export path -> (w, h) from every markdown table row that names a .png under assets/ or design/."""
    sizes = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if not line.lstrip().startswith("|"):
                continue
            for pm in re.finditer(r"(?:assets|design)/[\w/.\-]+\.png", line):
                tail = line[pm.end():]
                sm = re.search(r"(\d+)\s*[×x]\s*(\d+)\s*px", tail)
                if sm:
                    sizes.setdefault(pm.group(0), (int(sm.group(1)), int(sm.group(2))))
    return sizes


def check_png(root, rel, pal, sizes):
    """Return (ok, [lines])."""
    lines, ok = [], True
    path = os.path.join(root, rel)
    im = Image.open(path)
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()

    exp = sizes.get(rel)
    if exp is None:
        lines.append("  FAIL size: no metadata row for %s" % rel)
        ok = False
    elif exp != (w, h):
        lines.append("  FAIL size: file %dx%d != metadata %dx%d" % (w, h, exp[0], exp[1]))
        ok = False
    else:
        lines.append("  ok   size: %dx%d == metadata" % (w, h))

    semi, off, colours = 0, {}, set()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a not in (0, 255):
                semi += 1
            if a != 0:
                colours.add((r, g, b))
                if (r, g, b) not in pal:
                    off[(r, g, b)] = off.get((r, g, b), 0) + 1
    if semi:
        lines.append("  FAIL alpha: %d semi-transparent pixels" % semi)
        ok = False
    else:
        lines.append("  ok   alpha: binary (0/255 only)")
    if off:
        lines.append("  FAIL palette: %d off-palette colours: %s" % (
            len(off), ", ".join("#%02X%02X%02X x%d" % (c + (n,)) for c, n in sorted(off.items()))))
        ok = False
    else:
        used = sorted(pal[c] for c in colours)
        lines.append("  ok   palette: %d unique colours, all in TLF-CH01-32 (indices %s)" % (
            len(colours), ",".join("%02d" % i for i in used)))

    if os.path.basename(rel) == ELIAS:
        e_ok, e_lines = check_elias(im)
        lines += e_lines
        ok = ok and e_ok
    return ok, lines


def check_elias(im):
    lines, ok = [], True
    w, h = im.size
    if (w, h) != (2560, 48):
        lines.append("  FAIL elias layout: %dx%d != 2560x48" % (w, h))
        return False, lines
    lines.append("  ok   elias layout: 2560x48 = 80 frames of 32x48")
    px = im.load()

    def frame(idx):
        return [[px[idx * FRAME_W + x, y] for x in range(FRAME_W)] for y in range(FRAME_H)]

    total = 0
    for mdir, sdir in MIRRORS.items():
        diff = 0
        for k in range(FRAMES_PER_DIR):
            m = frame(DIR_ORDER.index(mdir) * FRAMES_PER_DIR + k)
            s = frame(DIR_ORDER.index(sdir) * FRAMES_PER_DIR + k)
            for y in range(FRAME_H):
                for x in range(FRAME_W):
                    a, b = m[y][x], s[y][FRAME_W - 1 - x]
                    if a != b and not (a[3] == 0 and b[3] == 0):
                        diff += 1
        lines.append("  %s elias mirror %-2s == flip_h(%-2s): pixel diff %d (10 frames)" % (
            "ok  " if diff == 0 else "FAIL", mdir, sdir, diff))
        total += diff
    if total:
        ok = False
    return ok, lines


def main():
    root = repo_root()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="*", help="PNG paths (repo-relative or absolute); default: all in metadata")
    ap.add_argument("--metadata", default=os.path.join(root, "design", "art", "ASSET_METADATA.md"))
    ap.add_argument("--palette", default=os.path.join(root, "assets", "source", "ch01", "ch01_palette_elysium09.gpl"))
    args = ap.parse_args()

    pal = load_palette(args.palette)
    sizes = load_metadata_sizes(args.metadata)
    files = args.files or sorted(sizes)
    all_ok = True
    for f in files:
        rel = os.path.relpath(os.path.abspath(f if os.path.isabs(f) else os.path.join(root, f)), root).replace(os.sep, "/")
        if not os.path.exists(os.path.join(root, rel)):
            print("%s\n  FAIL missing file" % rel)
            all_ok = False
            continue
        ok, lines = check_png(root, rel, pal, sizes)
        print("%s  [%s]" % (rel, "PASS" if ok else "FAIL"))
        print("\n".join(lines))
        all_ok = all_ok and ok
    print("RESULT: %s (%d file(s))" % ("ALL PASS" if all_ok else "FAILURES", len(files)))
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
