#!/usr/bin/env python3
"""Raw Pixelorama verification log for every .pxo in assets/source/ch01.

For each .pxo: `Pixelorama --headless --quit -- --size` and `-- --export --spritesheet` run on a TEMP COPY (Pixelorama 1.2.3
ignores --output and writes <name>.png next to the .pxo), then sha256 of the re-export vs the committed PNG. Output is raw
tool output (nothing paraphrased) and is also written to --log if given.

  python tools/art/gen/verify_pxo.py --log design/art/TLF-042_VERIFICATION.txt
"""
import argparse, glob, hashlib, os, shutil, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import REPO
from gen_all import PIXELORAMA


def sha(p):
    return hashlib.sha256(open(p, 'rb').read()).hexdigest()


def run(args):
    r = subprocess.run(args, capture_output=True, text=True, timeout=180)
    return r.returncode, (r.stdout + r.stderr).rstrip('\n')


def png_for(stem):
    if stem.startswith('ch01_ui_'):
        return os.path.join(REPO, 'assets', 'ui', 'ability_wheel', stem + '.png')
    if stem.startswith('ch01_char'):
        return os.path.join(REPO, 'assets', 'characters', 'ch01', stem + '.png')
    if stem.startswith('ch01_env'):
        return os.path.join(REPO, 'assets', 'environments', 'ch01', stem + '.png')
    if stem.startswith('ch01_prop'):
        return os.path.join(REPO, 'assets', 'props', 'ch01', stem + '.png')
    return os.path.join(REPO, 'assets', 'source', 'ch01', stem + '.png')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--log')
    ap.add_argument('--only', help='substring filter on the .pxo stem (e.g. ch01_ui_)')
    a = ap.parse_args()
    out = []
    w = out.append
    head = subprocess.run(['git', '-C', REPO, 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip()
    w('Pixelorama verification log (raw tool output, nothing paraphrased)')
    w('git HEAD at run time: ' + head)
    w('Pixelorama: ' + PIXELORAMA)
    w('')
    summary = []
    for pxo in sorted(glob.glob(os.path.join(REPO, 'assets', 'source', 'ch01', '*.pxo'))):
        stem = os.path.basename(pxo)[:-4]
        if a.only and a.only not in stem:
            continue
        with tempfile.TemporaryDirectory() as td:
            tmp = os.path.join(td, stem + '.pxo')
            shutil.copyfile(pxo, tmp)
            w('=' * 100)
            w('FILE: assets/source/ch01/%s.pxo   (run on a temp copy)' % stem)
            w('$ Pixelorama.exe --headless --quit -- --size %s.pxo' % stem)
            rc1, o1 = run([PIXELORAMA, '--headless', '--quit', '--', '--size', tmp]); w(o1); w('exit=%d' % rc1)
            w('$ Pixelorama.exe --headless --quit -- --export --spritesheet --output %s.png %s.pxo' % (stem, stem))
            rc2, o2 = run([PIXELORAMA, '--headless', '--quit', '--', '--export', '--spritesheet', '--output', tmp[:-4] + '.png', tmp]); w(o2); w('exit=%d' % rc2)
            exp, com = tmp[:-4] + '.png', png_for(stem)
            if os.path.exists(exp) and os.path.exists(com):
                x, y = sha(exp), sha(com)
                w('sha256 re-export : ' + x); w('sha256 committed  : ' + y); w('BYTE-IDENTICAL: ' + ('YES' if x == y else 'NO'))
                summary.append((stem, rc1, rc2, x == y))
            else:
                w('MISSING export or committed png'); summary.append((stem, rc1, rc2, False))
    w('=' * 100)
    w('SUMMARY (size-exit, export-exit, byte-identical)')
    for s in summary:
        w('%-52s %d %d %s' % (s[0], s[1], s[2], 'YES' if s[3] else 'NO'))
    w('TOTAL pxo: %d, all identical: %s' % (len(summary), all(x[1] == 0 and x[2] == 0 and x[3] for x in summary)))
    text = '\n'.join(out) + '\n'
    if a.log:
        with open(a.log if os.path.isabs(a.log) else os.path.join(REPO, a.log), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(text)
    print(out[-1])
    return 0 if all(x[1] == 0 and x[2] == 0 and x[3] for x in summary) else 1


if __name__ == '__main__':
    sys.exit(main())
