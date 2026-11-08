#!/usr/bin/env python3
"""Reproducibility check (ADR-019): regenerate every generated file into a temp folder and compare with the
committed files.

  python tools/art/gen/verify_regen.py                 # .pxo byte-for-byte, PNG pixel-for-pixel, mockups, sheet
  python tools/art/gen/verify_regen.py --pixelorama    # additionally re-export every .pxo with Pixelorama (temp
                                                       # copy) and compare the PNG bytes with the committed PNG

Exit code 0 only if everything matches. Files authored before TLF-039 (batch 1, by Argon) have no generator
here; they are listed as NOT COVERED so the gap is visible.
"""
import argparse, glob, hashlib, os, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import REPO, Image
import registry
import gen_all


def sha(b):
    return hashlib.sha256(b).hexdigest()


def read(p):
    with open(p, 'rb') as fh:
        return fh.read()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pixelorama', action='store_true')
    a = ap.parse_args()
    ok_all, covered_pxo = True, set()
    for asset in registry.all_assets():
        covered_pxo.add(asset.stem)
        pxo_p = os.path.join(REPO, asset.pxo_rel())
        png_p = os.path.join(REPO, asset.png_rel())
        res = []
        if not os.path.exists(pxo_p):
            print('FAIL %-48s committed .pxo missing' % asset.stem); ok_all = False; continue
        want = asset.pxo()
        got = read(pxo_p)
        pxo_ok = want == got
        res.append('pxo %s (%s)' % ('BYTE-IDENTICAL' if pxo_ok else 'DIFFERS', sha(want)[:12] if pxo_ok else sha(want)[:12] + ' vs ' + sha(got)[:12]))
        exp = asset.expected_png()
        have = Image.open(png_p).convert('RGBA') if os.path.exists(png_p) else None
        px_ok = have is not None and have.size == exp.size and have.tobytes() == exp.tobytes()
        res.append('png pixels %s' % ('IDENTICAL' if px_ok else 'DIFFER'))
        by_ok = True
        if a.pixelorama:
            with tempfile.TemporaryDirectory() as td:
                src_dir, work_dir = os.path.join(td, 'generated'), os.path.join(td, 'work')
                os.makedirs(src_dir); os.makedirs(work_dir)
                gp = os.path.join(src_dir, asset.stem + '.pxo')
                open(gp, 'wb').write(want)
                png, _, _ = gen_all.pixelorama_export(gp, work_dir)
                by_ok = png is not None and read(png) == read(png_p)
                res.append('pixelorama re-export png %s' % ('BYTE-IDENTICAL' if by_ok else 'DIFFERS'))
        good = pxo_ok and px_ok and by_ok
        ok_all &= good
        print('%s %-48s %s' % ('ok  ' if good else 'FAIL', asset.stem, '; '.join(res)), flush=True)

    # placement mockups + sheet
    import placement_render, placement_md
    with tempfile.TemporaryDirectory() as td:
        placement_render.write_mockups(td)
        for key, _ in placement_render.MOCKUPS:
            c = placement_render.mockup_path(key)
            t = placement_render.mockup_path(key, td)
            same = os.path.exists(c) and read(c) == read(t)
            if not same and os.path.exists(c):   # PNG encoder differences: fall back to pixels
                same = Image.open(c).convert('RGBA').tobytes() == Image.open(t).convert('RGBA').tobytes()
                tag = 'pixels IDENTICAL (bytes differ)' if same else 'DIFFER'
            else:
                tag = 'BYTE-IDENTICAL' if same else 'DIFFER'
            ok_all &= same
            print('%s mockup %-32s %s' % ('ok  ' if same else 'FAIL', os.path.basename(c), tag))
    import ui_wheel
    with tempfile.TemporaryDirectory() as td:
        ui_wheel.write_mockups(td)
        wheel_files = [(ui_wheel.mockup_path(k), ui_wheel.mockup_path(k, td)) for k, *_r in ui_wheel.STATES]
        wheel_files.append((ui_wheel.proof_path(), ui_wheel.proof_path(td)))
        for c, t in wheel_files:
            same = os.path.exists(c) and read(c) == read(t)
            tag = 'BYTE-IDENTICAL'
            if not same and os.path.exists(c):
                same = Image.open(c).convert('RGBA').tobytes() == Image.open(t).convert('RGBA').tobytes()
                tag = 'pixels IDENTICAL (bytes differ)' if same else 'DIFFER'
            elif not same:
                tag = 'DIFFER'
            ok_all &= same
            print('%s mockup %-44s %s' % ('ok  ' if same else 'FAIL', os.path.basename(c), tag))
    import step1_mockups
    with tempfile.TemporaryDirectory() as td:
        step1_mockups.write_mockups(td)
        for fname in step1_mockups.MOCKUP_FILES:
            c, t = step1_mockups.mockup_path(fname), step1_mockups.mockup_path(fname, td)
            same = os.path.exists(c) and read(c) == read(t)
            tag = 'BYTE-IDENTICAL'
            if not same and os.path.exists(c):
                same = Image.open(c).convert('RGBA').tobytes() == Image.open(t).convert('RGBA').tobytes()
                tag = 'pixels IDENTICAL (bytes differ)' if same else 'DIFFER'
            elif not same:
                tag = 'DIFFER'
            ok_all &= same
            print('%s mockup %-44s %s' % ('ok  ' if same else 'FAIL', os.path.basename(c), tag))
    import tlf063_story_props
    with tempfile.TemporaryDirectory() as td:
        tlf063_story_props.write_mockups(td)
        for fname in tlf063_story_props.MOCKUP_FILES:
            c, t = tlf063_story_props.mockup_path(fname), tlf063_story_props.mockup_path(fname, td)
            same = os.path.exists(c) and read(c) == read(t)
            tag = 'BYTE-IDENTICAL'
            if not same and os.path.exists(c):
                same = Image.open(c).convert('RGBA').tobytes() == Image.open(t).convert('RGBA').tobytes()
                tag = 'pixels IDENTICAL (bytes differ)' if same else 'DIFFER'
            elif not same:
                tag = 'DIFFER'
            ok_all &= same
            print('%s mockup %-44s %s' % ('ok  ' if same else 'FAIL', os.path.basename(c), tag))
    import tlf062_operator_city
    with tempfile.TemporaryDirectory() as td:
        tlf062_operator_city.write_mockups(td)
        for fname in tlf062_operator_city.MOCKUP_FILES:
            c, t = tlf062_operator_city.mockup_path(fname), tlf062_operator_city.mockup_path(fname, td)
            same = os.path.exists(c) and read(c) == read(t)
            tag = 'BYTE-IDENTICAL'
            if not same and os.path.exists(c):
                same = Image.open(c).convert('RGBA').tobytes() == Image.open(t).convert('RGBA').tobytes()
                tag = 'pixels IDENTICAL (bytes differ)' if same else 'DIFFER'
            elif not same:
                tag = 'DIFFER'
            ok_all &= same
            print('%s mockup %-44s %s' % ('ok  ' if same else 'FAIL', os.path.basename(c), tag))
    import tlf068_shape_kit
    with tempfile.TemporaryDirectory() as td:
        tlf068_shape_kit.write_mockups(td)
        for fname in tlf068_shape_kit.MOCKUP_FILES:
            c, t = tlf068_shape_kit.mockup_path(fname), tlf068_shape_kit.mockup_path(fname, td)
            same = os.path.exists(c) and read(c) == read(t)
            tag = 'BYTE-IDENTICAL'
            if not same and os.path.exists(c):
                same = Image.open(c).convert('RGBA').tobytes() == Image.open(t).convert('RGBA').tobytes()
                tag = 'pixels IDENTICAL (bytes differ)' if same else 'DIFFER'
            elif not same:
                tag = 'DIFFER'
            ok_all &= same
            print('%s mockup %-44s %s' % ('ok  ' if same else 'FAIL', os.path.basename(c), tag))
    import tlf073_wall_plaques
    with tempfile.TemporaryDirectory() as td:
        tlf073_wall_plaques.write_mockups(td)
        for fname in tlf073_wall_plaques.MOCKUP_FILES:
            c, t = tlf073_wall_plaques.mockup_path(fname), tlf073_wall_plaques.mockup_path(fname, td)
            same = os.path.exists(c) and read(c) == read(t)
            tag = 'BYTE-IDENTICAL'
            if not same and os.path.exists(c):
                same = Image.open(c).convert('RGBA').tobytes() == Image.open(t).convert('RGBA').tobytes()
                tag = 'pixels IDENTICAL (bytes differ)' if same else 'DIFFER'
            elif not same:
                tag = 'DIFFER'
            ok_all &= same
            print('%s mockup %-44s %s' % ('ok  ' if same else 'FAIL', os.path.basename(c), tag))
    cur = open(placement_md.SHEET_PATH, 'rb').read().replace(b'\r\n', b'\n')
    new = placement_md.SHEET_TEXT.encode('utf-8')
    same = cur == new
    ok_all &= same
    print('%s sheet  %-32s %s' % ('ok  ' if same else 'FAIL', 'CH01_PLACEMENT_SHEET.md', 'BYTE-IDENTICAL (LF)' if same else 'DIFFERS'))

    others = sorted(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(REPO, 'assets', 'source', 'ch01', '*.pxo'))
                    if os.path.basename(p)[:-4] not in covered_pxo)
    print('NOT COVERED (authored by Argon in batch 1, no generator in this repo): %s' % (', '.join(others) or 'none'))
    print('RESULT: %s' % ('ALL REPRODUCIBLE' if ok_all else 'MISMATCHES'))
    return 0 if ok_all else 1


if __name__ == '__main__':
    sys.exit(main())
