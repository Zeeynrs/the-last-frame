"""usage: python mutate071.py python|NAME OUTDIR  -- run Python tests per mutation, or write the mutated builder."""
import subprocess, sys, os
F = "tools/content/build_room_from_shape.py"
good = open("../builder_good.py", encoding="utf-8").read()
MUTS = {
 "M1": ("default outset 0", [('ap.add_argument("--outset", type=float, default=0.25', 'ap.add_argument("--outset", type=float, default=0.0'), ('def build(text, poly, outset=0.25', 'def build(text, poly, outset=0.0')]),
 "M2": ("no room_shape metadata", [('    text = set_room_shape_meta(text, poly)\n', '')]),
 "M3": ("holes ignored", [('        if c not in holes:\n            new_cells[c]', '        if True:\n            new_cells[c]')]),
 "M4": ("new tiles always source 0", [('ROOM_TILE_SOURCE.get(os.path.splitext(os.path.basename(room_path))[0], DEFAULT_TILE_SOURCE)', 'DEFAULT_TILE_SOURCE')]),
 "M5": ("old strip not cleared", [('        for c in cleared:\n            new_cells[c] = (base, 0, 0, 0)\n', '')]),
 "M6": ("strip paints door tiles", [("    return cells - set(holes) - {t for _, t in doors}", "    return cells - set(holes)")]),
 "M7": ("module under archway kept", [("        if i not in skip:", "        if True:")]),
 "M8": ("trench neighbours count as edge", [("    around = set(old) | set(holes)", "    around = set(old)")]),
}
def mutated(key):
    s = good
    for a, b in MUTS[key][1]:
        assert a in s, key
        s = s.replace(a, b)
    return s
if sys.argv[1] == "python":
    try:
        for key, (name, _) in MUTS.items():
            open(F, "w", encoding="utf-8", newline="\n").write(mutated(key))
            r = subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "tools/content", "-p", "test_*.py"], capture_output=True, text=True)
            fails = sorted({l.split(" (")[0].split(": ", 1)[1] for l in r.stderr.splitlines() if l.startswith(("FAIL:", "ERROR:"))})
            print("%s %s -> %s | %s" % (key, name, r.stderr.strip().splitlines()[-1], ", ".join(fails)))
    finally:
        open(F, "w", encoding="utf-8", newline="\n").write(good)
else:
    open(sys.argv[2], "w", encoding="utf-8", newline="\n").write(mutated(sys.argv[1]))
