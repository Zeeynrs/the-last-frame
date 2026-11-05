"""Generate Ch1 PuzzleDef .tres files and the hint translation CSV from the merged puzzle specs.

Source of truth: design/ch01/puzzles/CH1-PZ-00N.md (Argon, reviewed + merged). Text is copied verbatim
from the spec lines '- **Name:**' and '- **Hint N (...):** *"..."*'; nothing is re-typed by hand.
"""
import csv
import io
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SPECS = os.path.join(ROOT, "design/ch01/puzzles")
OUT_DATA = os.path.join(ROOT, "data/puzzles/ch01")
OUT_CSV = os.path.join(ROOT, "localization/ch01_puzzles.csv")

os.makedirs(OUT_DATA, exist_ok=True)
rows = []
# TLF-047 phase 2: Step 1 adds CH1-SO-01, CH1-SO-02 and CH1-PZ-006 (key prefix = id without dashes: SO001, SO002, PZ006)
PUZZLES = [f"CH1-PZ-00{n}" for n in range(1, 6)] + ["CH1-SO-01", "CH1-SO-02", "CH1-PZ-006"]
# TLF-054: play order (beats 01b, 02, 03b, 04b, 04, 05, 07, 08). Two rooms hold two puzzles, and the
# room hint must pick the one the player meets first (SO-02 before PZ-002, PZ-001 before PZ-006).
PLAY_ORDER = ["CH1-SO-01", "CH1-PZ-001", "CH1-PZ-006", "CH1-SO-02", "CH1-PZ-002", "CH1-PZ-003", "CH1-PZ-004", "CH1-PZ-005"]
for pid in PUZZLES:
    text = io.open(os.path.join(SPECS, f"{pid}.md"), encoding="utf-8").read()
    name = re.search(r"^- \*\*Name:\*\* (.+)$", text, re.M).group(1).strip()
    room = re.search(r"^- \*\*Chapter / Room:\*\*.*?\(`(ch01\.[a-z0-9_]+)`", text, re.M).group(1)
    hints = []
    for level in (1, 2, 3):
        m = re.search(r"^- \*\*Hint %d \([^)]*\):\*\* \*\"(.+)\"\*\s*$" % level, text, re.M)
        if m is None:
            raise SystemExit(f"{pid}: hint {level} not found")
        hints.append(m.group(1).strip())
    kind, num = pid.split("-")[1], pid.split("-")[2]
    prefix = f"{kind}{int(num):03d}"
    rows.append((f"{prefix}_TITLE", name))
    for level, hint in enumerate(hints, 1):
        rows.append((f"{prefix}_HINT_{level}", hint))
    tres = (
        '[gd_resource type="Resource" script_class="PuzzleDef" load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" path="res://scripts/puzzle/puzzle_def.gd" id="1_def"]\n\n'
        "[resource]\n"
        'script = ExtResource("1_def")\n'
        f'puzzle_id = &"{pid}"\n'
        f'room_id = &"{room}"\n'
        f'title_key = "{prefix}_TITLE"\n'
        f'hint_keys = PackedStringArray("{prefix}_HINT_1", "{prefix}_HINT_2", "{prefix}_HINT_3")\n'
        f"order = {PLAY_ORDER.index(pid) + 1}\n"
    )
    io.open(os.path.join(OUT_DATA, f"{pid}.tres"), "w", encoding="utf-8", newline="\n").write(tres)
    print(pid, room, "|", name)

os.makedirs(os.path.dirname(OUT_CSV), exist_ok=True)
with io.open(OUT_CSV, "w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
    writer.writerow(["keys", "en"])
    writer.writerows(rows)
print("csv rows:", len(rows))
