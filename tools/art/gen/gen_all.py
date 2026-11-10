#!/usr/bin/env python3
"""Regenerate every generated asset (.pxo, optionally the PNG exports through Pixelorama) and the
placement-sheet mockups/markdown.

  python tools/art/gen/gen_all.py                       # rewrite the .pxo files in assets/source/ch01
  python tools/art/gen/gen_all.py --out DIR             # write .pxo into DIR instead (for checks)
  python tools/art/gen/gen_all.py --export              # also run Pixelorama and replace the runtime PNGs
  python tools/art/gen/gen_all.py --sheet               # also rewrite design/art/CH01_PLACEMENT_SHEET.md + mockups (+ ability wheel mockups)

Pixelorama path: env TLF_PIXELORAMA or D:/Pixelorama/Pixelorama-Windows-64bit/Pixelorama.exe.
Pixelorama 1.2.3 ignores the --output file name and writes <name>.png next to the .pxo, so exports run in a temp copy.
"""
import argparse, os, shutil, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import REPO
import registry

PIXELORAMA = os.environ.get('TLF_PIXELORAMA', r'D:\Pixelorama\Pixelorama-Windows-64bit\Pixelorama.exe')


def pixelorama_export(pxo_path, workdir):
    """Copy the .pxo into workdir, run --size and --export there; return (png_path, size_log, export_log)."""
    tmp_pxo = os.path.join(workdir, os.path.basename(pxo_path))
    shutil.copyfile(pxo_path, tmp_pxo)
    r1 = subprocess.run([PIXELORAMA, '--headless', '--quit', '--', '--size', tmp_pxo], capture_output=True, text=True, timeout=180)
    r2 = subprocess.run([PIXELORAMA, '--headless', '--quit', '--', '--export', '--spritesheet', '--output', tmp_pxo[:-4] + '.png', tmp_pxo],
                        capture_output=True, text=True, timeout=180)
    png = tmp_pxo[:-4] + '.png'
    ok = r1.returncode == 0 and r2.returncode == 0 and os.path.exists(png)
    return (png if ok else None), r1.stdout + r1.stderr, r2.stdout + r2.stderr


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out', default=os.path.join(REPO, 'assets', 'source', 'ch01'))
    ap.add_argument('--export', action='store_true')
    ap.add_argument('--sheet', action='store_true')
    ap.add_argument('--only', help='substring filter on the asset stem')
    ap.add_argument('--task', help='exact registry user_data filter (e.g. TLF-081)')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for asset in registry.all_assets():
        if a.only and a.only not in asset.stem:
            continue
        if a.task and a.task != asset.user_data:
            continue
        path = os.path.join(a.out, asset.stem + '.pxo')
        open(path, 'wb').write(asset.pxo())
        line = 'wrote %s' % path
        if a.export:
            with tempfile.TemporaryDirectory() as td:
                png, _, _ = pixelorama_export(path, td)
                if png is None:
                    print('FAIL pixelorama on', asset.stem); sys.exit(1)
                os.makedirs(os.path.dirname(os.path.join(REPO, asset.png_rel())), exist_ok=True)
                shutil.copyfile(png, os.path.join(REPO, asset.png_rel()))
                line += ' + exported ' + asset.png_rel()
        print(line)
    if a.sheet:
        import placement_render, placement_md
        placement_render.write_mockups()
        import ui_wheel
        ui_wheel.write_mockups()
        import step1_mockups
        step1_mockups.write_mockups()
        import tlf063_story_props
        tlf063_story_props.write_mockups()
        import tlf062_operator_city
        tlf062_operator_city.write_mockups()
        import tlf068_shape_kit
        tlf068_shape_kit.write_mockups()
        import tlf073_wall_plaques
        tlf073_wall_plaques.write_mockups()
        import tlf077_wall_fixtures
        tlf077_wall_fixtures.write_mockups()
        import tlf075_side_view
        tlf075_side_view.write_mockups()
        import tlf081_concourse_wall_art
        tlf081_concourse_wall_art.write_mockups()
        with open(placement_md.SHEET_PATH, 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(placement_md.SHEET_TEXT)
        print('wrote sheet + mockups (incl. the ability wheel and Step 1 mockups and greyscale proofs)')


if __name__ == '__main__':
    main()
