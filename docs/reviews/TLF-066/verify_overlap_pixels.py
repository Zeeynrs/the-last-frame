"""Read-only evidence check. Requires Pillow/numpy and scratch capture comparators.

python verify_overlap_pixels.py <scratch>/audit_output
The capture harness creates the uncommitted baseline/no-target images there.
"""
from pathlib import Path
import argparse
import json

import numpy as np
from PIL import Image

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("captures", type=Path)
args = parser.parse_args()
manifest = json.loads(Path(__file__).with_name("render_manifest.json").read_text())
checked = 0


def rgb(path):
    with Image.open(path) as image:
        assert image.size == (640, 360), path
        return np.array(image.convert("RGB"))


for room in manifest["rooms"]:
    folder = args.captures / room["room"]
    baseline = rgb(folder / "baseline.png")
    for obj in room["objects"]:
        prefix = f"{obj['index']:03d}"
        neither = rgb(folder / f"{prefix}_no_target_no_player.png")
        object_mask = np.any(baseline != neither, axis=2)
        groups = [(obj["samples"], obj["pixels"])]
        if "centerline" in obj:
            groups.append((obj["centerline"], obj["centerline_pixels"]))
        for samples, recorded in groups:
            for side in samples:
                actual = rgb(folder / f"{prefix}_{side}.png")
                no_target = rgb(folder / f"{prefix}_{side}_no_target.png")
                mask = (object_mask & np.any(no_target != neither, axis=2)
                        & np.any(baseline != no_target, axis=2))
                measured = {
                    "intersection": int(mask.sum()),
                    "object_front": int((mask & np.all(actual == baseline, axis=2)).sum()),
                    "player_front": int((mask & np.all(actual == no_target, axis=2)).sum()),
                }
                assert measured == recorded[side], (room["room"], prefix, side, measured, recorded[side])
                published = Path(__file__).parent / room["room"] / f"{prefix}_{side}.png"
                assert np.array_equal(rgb(published), actual), published
                checked += 1
print(f"PASS: {checked} published 640x360 captures equal scratch frames; all overlap pixel counts reproduced")
