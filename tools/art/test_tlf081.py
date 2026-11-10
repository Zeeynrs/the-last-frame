"""Acceptance checks for the exact TLF-081 delivery, independent of scene integration."""
import sys
import unittest
import json
import zipfile
from pathlib import Path
from PIL import Image, ImageChops

sys.path.insert(0, str(Path(__file__).parent / 'gen'))
import registry
from lib import REPO

EXPECTED = {
    *(f'ch01_prop_flap_dial_{kind}_n_{state}'
      for kind in ('line', 'platform', 'time') for state in ('idle', 'jammed')),
    'ch01_prop_call_box_phone_w_idle', 'ch01_prop_call_box_phone_w_ringing',
    'ch01_prop_conduit_w_mounted', 'ch01_prop_ticket_terms_notice_w_idle',
    *(f'ch01_prop_ticket_validator_n_{state}' for state in ('idle', 'rejecting', 'accepted')),
}


class Delivery(unittest.TestCase):
    def test_exact_registered_delivery(self):
        found = {a.stem for a in registry.all_assets() if a.user_data == 'TLF-081'}
        self.assertEqual(EXPECTED, found)

    def test_authorship_in_editable_sources(self):
        for stem in EXPECTED:
            with zipfile.ZipFile(Path(REPO) / 'assets/source/ch01' / (stem + '.pxo')) as z:
                meta = json.loads(z.read('data.json'))
            self.assertEqual('Sol (Codex), TLF-081; wall primitives adapted from Argon draft',
                             meta['author_display_name'])

    def test_all_wall_pixels_fit_production_module_alpha(self):
        # Independent assembly contract: evaluate delivered pixels, including
        # shadows/ringing marks, against the real production wall PNGs.
        contracts = {
            'flap_dial': ('n', (0, 6), ((0, 0),)),
            'call_box': ('w', (4, 4), ((0, 0),)),
            'conduit': ('w', (8, 10), ((0, 16), (32, 0))),
            'ticket_terms': ('w', (8, 18), ((0, 0),)),
        }
        for stem in sorted(EXPECTED):
            if 'validator' in stem:
                continue
            with self.subTest(stem=stem):
                key = next(k for k in contracts if k in stem)
                face, (dx, dy), modules = contracts[key]
                wall = self.png('environments', f'ch01_env_wall_subterranean_{face}_idle')
                mask = set()
                for mx, my in modules:
                    mask.update((mx + x, my + y) for y in range(wall.height)
                                for x in range(wall.width) if wall.getpixel((x, y))[3])
                sprite = self.png('props', stem)
                outside = [(x, y) for y in range(sprite.height) for x in range(sprite.width)
                           if sprite.getpixel((x, y))[3] and (x + dx, y + dy) not in mask]
                self.assertEqual([], outside, 'opaque fixture pixels escape the wall silhouette')

    def test_phone_features_follow_w_plane_without_repainting(self):
        # Preserve every pre-existing opaque phone/glyph pixel through the W
        # projection. The new flush mount shadow can add pixels behind them.
        for state in ('idle', 'ringing'):
            with self.subTest(state=state):
                old = self.png('props', f'ch01_prop_call_box_phone_{state}')
                new = self.png('props', f'ch01_prop_call_box_phone_w_{state}')
                for y in range(old.height):
                    for x in range(old.width):
                        pixel = old.getpixel((x, y))
                        if pixel[3]:
                            self.assertEqual(pixel, new.getpixel((x, y + 11 - x // 2)))

    def test_states_differ_in_greyscale_and_bank_has_no_overlap(self):
        for family in ('flap_dial_line_n', 'flap_dial_platform_n', 'flap_dial_time_n',
                       'call_box_phone_w', 'ticket_validator_n'):
            stems = sorted(s for s in EXPECTED if f'ch01_prop_{family}_' in s)
            images = [self.png('props', s).convert('L') for s in stems]
            for i, a in enumerate(images):
                for b in images[i + 1:]:
                    self.assertIsNotNone(ImageChops.difference(a, b).getbbox(), family)
        for state in ('idle', 'jammed'):
            dial = self.png('props', 'ch01_prop_flap_dial_time_n_' + state)
            validator = self.png('props', 'ch01_prop_ticket_validator_n_rejecting')
            # Actual v2 top-lefts (608,166) and (608,198); no masking by either.
            hits = [(x, y) for y in range(32, dial.height) for x in range(32)
                    if dial.getpixel((x, y))[3] and validator.getpixel((x, y - 32))[3]]
            self.assertEqual([], hits)

    @staticmethod
    def png(folder, stem):
        with Image.open(Path(REPO) / 'assets' / folder / 'ch01' / (stem + '.png')) as im:
            return im.convert('RGBA')


if __name__ == '__main__':
    unittest.main()
