#!/bin/sh
# TLF-069 review probe runner (Opus). Never run it in a worktree: it needs a renamed scratch copy.
#
# usage: run_probe.sh <repo> <sha> <scratch dir> [scene.tscn]
#   <repo>        a git checkout that has <sha>
#   <scratch dir> created here: git archive of <sha>, config/name renamed to "TLF Verify <sha>"
#   [scene.tscn]  optional: installed as arrival_platform.tscn first (e.g. make_ref_scene.py output)
# env: GODOT (default D:/Godot/Godot_v4.7.2-stable_win64_console.exe)
#      TLF_PROBE_STANDS="release_lever=28,2;n04_cleaner=25,6" declared stand spots (tiles)
# Output: <scratch dir>/probe.log; the PROBE lines are printed. "PROBE FAIL" marks a broken rule.
set -e
REPO=$1; SHA=$2; DEV=$3; SCENE=$4
GODOT=${GODOT:-D:/Godot/Godot_v4.7.2-stable_win64_console.exe}
HERE=$(cd "$(dirname "$0")" && pwd)
if [ ! -d "$DEV" ]; then
  mkdir -p "$DEV"
  git -C "$REPO" archive "$SHA" | tar -x -C "$DEV"
  sed -i "s/^config\/name=.*/config\/name=\"TLF Verify $SHA\"/" "$DEV/project.godot"
  sed 's/if file_name.begins_with("test_") and file_name.ends_with(".gd"):/if file_name.begins_with("test_") and file_name.ends_with(".gd") and (OS.get_environment("TLF_ONLY") == "" or file_name.contains(OS.get_environment("TLF_ONLY"))):/' \
    "$DEV/tests/run_tests.gd" > "$DEV/tests/run_some.gd"
fi
grep '^config/name' "$DEV/project.godot"
[ -n "$SCENE" ] && cp "$SCENE" "$DEV/scenes/chapters/ch01/rooms/arrival_platform.tscn"
cp "$HERE/test_zprobe_arrival_v2.gd.txt" "$DEV/tests/chapters/ch01/test_zprobe_arrival_v2.gd"
cd "$DEV"
[ -d .godot ] || "$GODOT" --headless --path . --import > import.log 2>&1 || true
set +e
TLF_ONLY=zprobe_arrival_v2 "$GODOT" --headless --path . -s tests/run_some.gd > probe.log 2>&1
echo "exit $?"
grep -aE "PROBE|PASS|FAIL|TESTS|Parse Error" probe.log
echo "SCRIPT ERROR lines: $(grep -ac 'SCRIPT ERROR' probe.log)"
