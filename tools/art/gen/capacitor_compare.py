#!/usr/bin/env python3
"""TLF-044: side-by-side of the four surge-capacitor states (discharged, charged, frozen_discharged, frozen_charged),
in colour and in greyscale (the no-colour readability check). Reads the committed PNGs, writes two review images:
  design/art/mockups/TLF-044_capacitor_states.png
  design/art/mockups/TLF-044_capacitor_states_grey.png
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import REPO, Image

STATES = ['discharged', 'charged', 'frozen_discharged', 'frozen_charged']
ZOOM, PAD, BG = 4, 8, (10, 13, 20, 255)


def main():
    ims = [Image.open(os.path.join(REPO, 'assets', 'props', 'ch01', 'ch01_prop_surge_capacitor_%s.png' % s)).convert('RGBA') for s in STATES]
    w = len(ims) * (64 * ZOOM + PAD) + PAD
    sheet = Image.new('RGBA', (w, 64 * ZOOM + 2 * PAD), BG)
    for i, im in enumerate(ims):
        sheet.alpha_composite(im.resize((64 * ZOOM, 64 * ZOOM), Image.NEAREST), (PAD + i * (64 * ZOOM + PAD), PAD))
    out = os.path.join(REPO, 'design', 'art', 'mockups')
    sheet.convert('RGB').save(os.path.join(out, 'TLF-044_capacitor_states.png'))
    sheet.convert('L').save(os.path.join(out, 'TLF-044_capacitor_states_grey.png'))
    print('wrote', out)


if __name__ == '__main__':
    main()
