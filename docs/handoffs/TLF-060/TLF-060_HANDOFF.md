# TLF-060 Handoff: Windows export preset + smoke test of the exported build

## Branch and SHAs

- Branch `agent/opus-core-tlf060`, started from `origin/main` `83574ca`.
- **`1b2de6d`**: the code commit. It adds:
  - `export_presets.cfg`;
  - `tools/smoke/run_smoke.ps1`, `tools/smoke/window_input.ps1`;
  - `tools/smoke/smoke_export_driver.gd` (+ `.uid`).
- The handoff commit on top adds only this file and the screenshots in `docs/handoffs/TLF-060/`.
- The smoke run (`run_smoke.ps1 -Sha 1b2de6d`) and the full validate both ran on **`1b2de6d`**, each from a `git archive` of that commit.
- I reused nothing from Flash's `7ca0470` as-is:
  - The preset was rewritten. Its texture keys `texture_format/bptc`, `/s3tc`, `/etc2` and `/vram_compression_etc2` are not Godot 4.7 option names. The 4.7.2 editor binary has only `texture_format/s3tc_bptc` and `texture_format/etc2_astc`.
  - Its driver called `activate()` and `return_to_title()` directly instead of using input.

## Status

| Check | Result on `1b2de6d` |
|---|---|
| `run_smoke.ps1` | `SMOKE: ALL PASSED`, exit 0, 13/13 results PASS (raw output below) |
| `validate.ps1` | `TESTS: 431 passed, 0 failed`, exit 0, 0 `SCRIPT ERROR` lines (complete raw output below) |
| Player's save folder (`app_userdata\The Last Frame\saves`, `settings.cfg`) | listed read only before and after: **UNCHANGED** |
| Project settings / game code | not changed (only the four new files under `tools/smoke/` and `export_presets.cfg`) |

## Finding 1 (blocker for real builds): the installed export templates are copies of the editor

`%APPDATA%\Godot\export_templates\4.7.2.stable\` was created on 2026-11-05 22:14. It holds two renamed copies of the editor binaries, not export templates:

| File in the templates folder | Size | SHA-256 | Identical to |
|---|---|---|---|
| `windows_release_x86_64.exe` | 180,858,888 | `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424` | `D:\Godot\Godot_v4.7.2-stable_win64.exe` (the editor) |
| `windows_debug_x86_64.exe` | 198,152 | `c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643` | `D:\Godot\Godot_v4.7.2-stable_win64_console.exe` (the editor's console wrapper) |

An export made with them is the 180 MB editor executable plus a PCK. It runs the game, but it reports `OS.is_debug_build() == true` and is not a release build. My first run (`b30e90f`, discarded) showed exactly this: `debug_build=true` on an `--export-release`. Flash's `7ca0470` was made the same way. His handoff reports `TheLastFrame.exe: 180,758,536 bytes`, byte for byte the size of my editor-copy export on `b30e90f`. A real release export of this tree is 109,168,640 bytes. The templates folder dates from 2026-11-05 22:14, and his commit from 23:08 the same evening.

**What I did:** I did **not** touch `%APPDATA%\Godot\export_templates`. I used the official package instead:
- Downloaded `Godot_v4.7.2-stable_export_templates.tpz` from the godotengine GitHub release, 1,281,349,702 bytes.
- Its SHA-512 `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079` matches the release's `SHA512-SUMS.txt`.
- Copied both editor exes to a scratch folder with an empty `._sc_` file (Godot self-contained mode).
- Extracted only the four `windows_*_x86_64*` templates and `version.txt` into that folder's `editor_data\export_templates\4.7.2.stable\`.
- Template hashes: release `d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562` (109,268,480 B), debug `51498b72b3a237f882ebd7d1787f06a4bc1eaf0572daab93837adcfd3cfdc107` (103,176,704 B).

**Recommendation for the owner:** replace the two renamed files with the official templates (Editor → Manage Export Templates → Download and Install, or install the `.tpz`). Until then, every export from this machine's default setup is the editor binary. `run_smoke.ps1` refuses such templates (`RESULT templates FAIL`).

## Finding 2: official templates have no `-s` / `--script`

Neither the official 4.7.2 release template nor the debug template lists `--script` in `--help`. A `-s <path>` is silently ignored and the game sits on an empty window. That is how the release run behaved on `9c93978` (discarded).

An in-game driver therefore cannot run inside an official exported exe. The smoke uses two complementary paths:

1. **The release exe itself (the artifact)** is played **from outside**:
   - **Input:** keys posted as `WM_KEYDOWN`/`WM_KEYUP` (with scan codes, which Godot maps to physical keycodes) to the game's window. The focus is never needed, so no keystroke can land in another app.
   - **Screenshots:** `PrintWindow(PW_RENDERFULLCONTENT)` window captures.
   - **Verification:** the selected title row is read from the screenshot (the menu's yellow). The save is checked **on disk**: `checkpoint_id` and the watch flag in the JSON. Exit codes come from the process.
2. **The exported PCK** (from `--export-debug` of the same tree, with its own user folder) runs with the official 4.7.2 editor binary: `--main-pack <pck> -s smoke_export_driver.gd`. Inside the game, the driver checks:
   - the font resource and its name;
   - every visible Label for untranslated keys;
   - the save root and user dir;
   - the flags after save and Continue.

## What is in `export_presets.cfg`

- **Platform:** one preset, `Windows Desktop`, `x86_64`, PCK next to the exe (`binary_format/embed_pck=false`).
- **Templates and textures:** the installed templates (no custom template paths); `texture_format/s3tc_bptc=true`, `etc2_astc=false`; the console wrapper only for debug exports.
- **Output:** `export_path="build/windows/TheLastFrame.exe"`. `/build/` is already in `.gitignore`, so `.gitignore` is unchanged.
- **Excluded from the build:** `exclude_filter="tests/*, tools/*"`. The test suite and the smoke tools are not shipped; the smoke driver is loaded from disk. A byte scan of the exported PCK finds no `tests/` or `tools/` path. It does contain `tlf_pixel_mono.ttf` (as `.fontdata`) and all three `.translation` files.
- **No Linux preset.** No Linux templates are installed on this machine (the two renamed Windows files above are all there is). Per the Lead, Linux stays out and is marked UNTESTED. The official `.tpz` does contain `linux_release.x86_64` and the other Linux templates, if the owner wants a Linux preset later.

## How to re-run (exact steps)

```
# one-time: editor copy in self-contained mode with the official templates (see Finding 1)
<dir>\Godot_v4.7.2-stable_win64.exe, <dir>\Godot_v4.7.2-stable_win64_console.exe, <dir>\._sc_
<dir>\editor_data\export_templates\4.7.2.stable\{version.txt, windows_release_x86_64.exe, windows_debug_x86_64.exe, ...}

powershell -NoProfile -ExecutionPolicy Bypass -File tools\smoke\run_smoke.ps1 `
    -Sha 1b2de6d -WorkDir <new scratch folder> -Godot <dir>\Godot_v4.7.2-stable_win64_console.exe
```

What `run_smoke.ps1` does:

1. **Copy the tree.** It runs `git archive <sha>` into `<WorkDir>\project` and changes only `config/name`:
   - `TLF Smoke <sha7>` for the release export;
   - `TLF Smoke <sha7> debug` for the debug export.

   The builds therefore write to their own `app_userdata` folders. It refuses to start if those folders already exist.
2. **Check templates, import, export.** It verifies that neither template is an editor copy, then imports and runs `--export-release` to `build\windows\` and `--export-debug` to `build\windows-debug\`.
3. **Release runs.** Each run waits for the window, then:
   - **`release_plain`:**
     - waits 8 s on the title and checks that New Game is selected;
     - presses S until Quit is selected, then Enter on Quit;
     - the game must exit **by itself** with code 0.
   - **`release_new`:**
     - checks that New Game is selected (fresh user dir), then presses Enter until Chapter 1 is drawn;
     - presses E 5 times (the pocket watch is the interact target at the spawn);
     - about 4 s of held keys in there-and-back pairs, ending out of the arrival checkpoint and back in;
     - checks on disk that `slot_0.json` holds `checkpoint_id = ch01.cp.arrival` and `ch01.flag.pocket_watch_acquired = true`;
     - closes the window with WM_CLOSE.
   - **`release_continue`:**
     - checks that Continue is selected (save found), then presses Enter until Chapter 1 is drawn;
     - the same walk;
     - `slot_0.json` must be rewritten during this run and still hold the watch flag;
     - closes with WM_CLOSE.
4. **PCK runs.** `pck_new` and `pck_continue` run the driver with the official editor binary on the debug export's PCK. Each prints `SMOKE READY_TO_CLOSE` and is then closed with WM_CLOSE.
5. **Folder checks.** It lists both smoke user dirs. It lists the player's `saves\` and `settings.cfg` read only before and after: unchanged → PASS. If they changed while another game process ran, the check passes only if that save is not at `ch01.cp.arrival`, the only checkpoint the smoke reaches; otherwise FAIL. It also lists all other Godot processes before and after.

Keys that must change the screen are re-sent at most 3 times, and every resend is logged. That is because one run (`5768953`, discarded) lost a posted `S` on the title. On `1b2de6d` every key worked on the first press.

## Smoke checklist (TLF-060 requirement → evidence on `1b2de6d`)

| Requirement | Release exe (official release template) | Exported PCK + in-game driver |
|---|---|---|
| title → New Game → Chapter 1 loads | `release_new`: New Game selected → 1 Enter → Chapter 1 drawn (`release_new_01_title.png`, `release_new_02_chapter1.png`) | `pck_new`: Enter → `Chapter01` loads, room `ch01.arrival_platform`, player at the spawn (352,160) |
| pixel font renders | all release screenshots (TLF Pixel Mono glyphs on title, HUD, dialogue) | title Label font `res://assets/ui/fonts/tlf_pixel_mono.ttf`, name `TLF Pixel Mono` |
| translations show text, not keys | screenshots: "THE LAST FRAME", "New Game", "Trace [Q] Watch [Z] Abilities [H] Hint", "Memory / [23:59] A hand sets this watch down…" | every visible Label scanned for `^[A-Z][A-Z0-9]*_[A-Z0-9_]+$` on title, chapter start, after the pickup, after Continue: none. HUD toast "Trace unlocked. Hold the watch up to anything that remembers." |
| a few seconds of real input, no crash | about 4 s of held movement keys + 5 E + Enter per run; exit 0, 0 ERROR lines in stdout/stderr | 5.9 s (new) and 4.9 s (continue) of key events from the exported InputMap (`InputEventKey`, physical keycodes); 464 px and 388 px walked; 0 ERROR lines |
| save written to the right `user://` folder | `app_userdata\TLF Smoke 1b2de6d\saves\slot_0.json`, checkpoint `ch01.cp.arrival`, watch flag true | `user_data_dir=…/TLF Smoke 1b2de6d debug`, `save_root=user://saves`, slot 0 read back with the flag |
| NOT the real save folder | player's `saves\slot_0.json` + `settings.cfg`: same hash, size and time before and after | same check |
| Continue works | `release_continue`: Continue preselected (screenshot), 1 Enter → Chapter 1; walking back into the checkpoint rewrote `slot_0.json` during the run, flag still true | `pck_continue`: Continue enabled and preselected, room restored, watch flag restored, Trace available, respawn at (352,160) |
| quit / clean exit | `release_plain`: **Quit menu item**, exit 0; `release_new`/`release_continue`: WM_CLOSE (the X button), exit 0 | WM_CLOSE, exit 0 |

The release save is 2.9 KB and the PCK-run save 11.8 KB. The only real difference is the `playtest` section (5,284 vs 34 bytes in the JSON): the PlaytestLog is on in debug builds only (`tlf/playtest_log=false`, `playtest_log.debug=true`).

## Exit codes (`1b2de6d`)

| Run | Build | How it ended | Exit code | Time | ERROR lines |
|---|---|---|---|---|---|
| import | official editor (self-contained) | - | 0 | - | 0 |
| export release | official release template | - | 0 | - | 0 |
| export debug | official debug template | - | 0 | - | 0 |
| release_plain | release exe | Quit menu item | 0 | 9.6 s | 0 |
| release_new | release exe | WM_CLOSE | 0 | 18.0 s | 0 |
| release_continue | release exe | WM_CLOSE | 0 | 14.4 s | 0 |
| pck_new | debug PCK + official editor exe | WM_CLOSE | 0 | 10.4 s | 0 |
| pck_continue | debug PCK + official editor exe | WM_CLOSE | 0 | 7.5 s | 0 |
| run_smoke.ps1 | - | - | 0 | - | - |

## Not tested

- **Linux:** UNTESTED. No preset, no Linux templates installed, and no Linux machine.
- **Windows arm64 / x86_32:** not in the preset, not tested.
- **The in-game driver inside an official exported exe:** not possible, because the templates have no `-s`. The release exe was checked from outside only, and the PCK with the editor binary.
- **Input methods:**
  - Controller, mouse and a physical keyboard were not tested.
  - The keys were posted window messages, not SendInput or hardware.
- **Not driven by the smoke:**
  - the ability wheel and pause;
  - any room beyond the arrival platform;
  - any puzzle.
- **Default `%APPDATA%` templates:** exporting with them is not tested on purpose (they are the editor binary; see Finding 1).
- **Installers, code signing, icon:** none in scope. `application/icon` is empty, so the exe has Godot's icon.

## Follow-up issues (not fixed; outside the allowed files)

1. **Export templates on this machine are editor copies** (Finding 1). This is an owner or environment action, not a code change.
2. **The pocket-watch Memory line never goes away by itself.**
   - `arrival_platform.tscn` `pocket_watch_pickup` is non-blocking and sets no `auto_advance_delay` (0.0).
   - `dialogue_box.gd:65-68` advances a non-blocking line only on `confirm` (Enter/Space/click), not on E and not on a timer.
   - In every run, "[23:59] A hand sets this watch down on the tiles, face up." was still on screen about 8 s after the pickup, through all the walking (`release_new_03_watch.png`, `release_new_04_checkpoint.png`).
   - The ability wheel refuses to open while any line is active (TLF-056 note), so a player who doesn't press Enter can't open the wheel.
   - It comes from scene and script data, so it is not export-specific. I did not run it in the editor.
3. **Window-posted keys can occasionally be lost.** One posted `S` on the title was lost in run `5768953`. On `1b2de6d` every key took effect on the first press. This is a property of the test harness, not the game; `run_smoke.ps1` re-sends and logs.

## Screenshots (`docs/handoffs/TLF-060/`)

- **`release_*.png`:** window captures of the **release exe**.
  - The window is 1920×1080, i.e. the 640×360 game at integer scale 3. The captures are stored downscaled 3:1 with nearest-neighbour, which I checked to be lossless: upscaling them back gives the capture exactly.
  - `release_new_02_chapter1_fullsize_1920x1080.png` is one capture at full size.
- **`pck_*.png`:** the in-game driver's viewport screenshots (640×360) from the exported PCK runs.

| File | Shows |
|---|---|
| `release_plain_01_title.png` | title, New Game selected, Continue greyed (no save) |
| `release_plain_02_quit_selected.png` | after S: Quit selected (then Enter quit the game, exit 0) |
| `release_new_01_title.png` | fresh title before New Game |
| `release_new_02_chapter1.png` | Chapter 1, arrival platform, Beat 01 line "Where... is this?" |
| `release_new_03_watch.png` | after E: Memory line of the watch pickup |
| `release_new_04_checkpoint.png` | after the walk, back in the arrival checkpoint (autosave written) |
| `release_continue_01_title.png` | second launch: Continue selected |
| `release_continue_02_chapter1.png` | Chapter 1 restored at the checkpoint |
| `release_continue_03_checkpoint.png` | after the walk (autosave rewritten) |
| `pck_new_01…04`, `pck_continue_01…03` | the same steps from inside the game |

## Raw evidence

### run_smoke.ps1 on 1b2de6d: complete console output (evidence/summary.txt; exit 0)

```
TLF-060 smoke  commit 1b2de6d8cd3f630e13adf88ab04ee9dfd5cfd22a
Godot C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\godot_sc\Godot_v4.7.2-stable_win64_console.exe
work dir C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d
project.godot changes in the copy (only config/name may change; the debug export uses 'TLF Smoke 1b2de6d debug'):
  => config/name="TLF Smoke 1b2de6d"
  <= config/name="The Last Frame"
other Godot processes before: 3
  pid 22216 started 07:24:53: D:\Godot\Godot_v4.7.2-stable_win64.exe --path D:/TheLastFrame/the-last-frame --editor
  pid 29100 started 11:09:35: "D:\Godot\Godot_v4.7.2-stable_win64_console.exe" --path C:\Users\adity\orca\workspaces\the-last-frame\tlf-implementation-qa --headless -s res://scratch/run_one.gd
  pid 12956 started 11:09:35: D:\Godot\Godot_v4.7.2-stable_win64.exe --path C:\Users\adity\orca\workspaces\the-last-frame\tlf-implementation-qa --headless -s res://scratch/run_one.gd
real save folder before: 1 file(s)
release template C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\godot_sc\editor_data\export_templates\4.7.2.stable\windows_release_x86_64.exe
  sha256 D34D36F3BE1A6C49C56525AE86469B92E4F417DDF0B43CF00DD80C385C4B0562
debug template C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\godot_sc\editor_data\export_templates\4.7.2.stable\windows_debug_x86_64.exe
  sha256 51498B72B3A237F882EBD7D1787F06A4BC1EAF0572DAAB93837ADCFD3CFDC107
  (editor sha256 AB1824F85BFD8E0E4128182C000C4003A3E042245B2967848D089B2A04B22424, console C8F0A6BC45A19B33541501E57F6F7CD972AB18453743266339D495CBBE846643)
import exit 0
export release exit 0
  release          TheLastFrame.exe               109168640 bytes  sha256 3AA032DC0C99B399FC05DBA7811189DE3CF5540E28DA8EF5F30D1BCBD861F9BF
  release          TheLastFrame.pck                 1094444 bytes  sha256 9A5D1CF215BF358FC6A3A78DAA861F5957668F3E5E9CB5269BC9CC91318A08C3
export debug exit 0
  debug            TheLastFrame.console.exe           91136 bytes  sha256 FABBDACBDE1FA0DA5ECA26E7A9238F6C4237A21122102CBE2F9E77556824995B
  debug            TheLastFrame.exe               103076864 bytes  sha256 343C37092DE6961C7B3D084B43A3C76C748EE286937C698DC3555DE5552F88CB
  debug            TheLastFrame.pck                 1094444 bytes  sha256 A9D79888B16B05D18E1971F37D613E0A015AC12B10B6F2340EC59CABB6E03E23
  screenshot release_plain_01_title.png  lit 1.5% (min 0.5%) ok
  plain: S to Quit: 1 press(es) of S
  screenshot release_plain_02_quit_selected.png  lit 1.5% (min 0.5%) ok
  plain: Enter on Quit: 1 press(es) of Enter
run release_plain     exited through the Quit menu item, exit code 0, 9.6 s, 0 ERROR line(s)
  screenshot release_new_01_title.png  lit 1.5% (min 0.5%) ok
  new: Enter on New Game: 1 press(es) of Enter
  screenshot release_new_02_chapter1.png  lit 71.5% (min 30.0%) ok
  screenshot release_new_03_watch.png  lit 71.7% (min 30.0%) ok
  screenshot release_new_04_checkpoint.png  lit 71.8% (min 30.0%) ok
  save C:\Users\adity\AppData\Roaming\Godot\app_userdata\TLF Smoke 1b2de6d\saves\slot_0.json  2978 bytes  written 12:00:55.090  checkpoint ch01.cp.arrival=True  watch flag=True
run release_new       closed with WM_CLOSE (sent=True), exit code 0, 18 s, 0 ERROR line(s)
  save C:\Users\adity\AppData\Roaming\Godot\app_userdata\TLF Smoke 1b2de6d\saves\slot_0.json  2978 bytes  written 12:00:55.090  checkpoint ch01.cp.arrival=True  watch flag=True
  screenshot release_continue_01_title.png  lit 1.5% (min 0.5%) ok
  continue: Enter on Continue: 1 press(es) of Enter
  screenshot release_continue_02_chapter1.png  lit 95.0% (min 30.0%) ok
  screenshot release_continue_03_checkpoint.png  lit 95.0% (min 30.0%) ok
  save C:\Users\adity\AppData\Roaming\Godot\app_userdata\TLF Smoke 1b2de6d\saves\slot_0.json  2978 bytes  written 12:01:09.558  checkpoint ch01.cp.arrival=True  watch flag=True
run release_continue  closed with WM_CLOSE (sent=True), exit code 0, 14.4 s, 0 ERROR line(s)
  check plain: title drawn                                                       ok
  check plain: New Game selected (no save yet)                                   ok
  check plain: S selects Quit                                                    ok
  check plain: Enter on Quit ends the game                                       ok
  check new: title drawn                                                         ok
  check new: New Game selected (no save yet)                                     ok
  check new: Enter starts chapter 1                                              ok
  check new: chapter 1 drawn                                                     ok
  check new: after E                                                             ok
  check new: after the walk                                                      ok
  check new: slot_0.json at ch01.cp.arrival with the watch flag                  ok
  check continue: title drawn                                                    ok
  check continue: Continue selected (save found)                                 ok
  check continue: Enter loads chapter 1                                          ok
  check continue: chapter 1 drawn                                                ok
  check continue: after the walk                                                 ok
  check continue: slot_0.json rewritten in this run, still with the watch flag   ok
run pck_new           closed with WM_CLOSE (sent=True), exit code 0, 10.4 s, 0 ERROR line(s)
run pck_continue      closed with WM_CLOSE (sent=True), exit code 0, 7.5 s, 0 ERROR line(s)
release user dir C:\Users\adity\AppData\Roaming\Godot\app_userdata\TLF Smoke 1b2de6d (shader_cache not listed)
  C14CA618CC318519        147  2026-11-07 12:01:11.650  logs\godot.log
  C14CA618CC318519        147  2026-11-07 12:00:39.297  logs\godot2026-11-07T12.00.39.log
  C14CA618CC318519        147  2026-11-07 12:00:57.322  logs\godot2026-11-07T12.00.57.log
  00C816A43AB9DB0A       2978  2026-11-07 12:01:09.558  saves\slot_0.json
debug user dir C:\Users\adity\AppData\Roaming\Godot\app_userdata\TLF Smoke 1b2de6d debug (shader_cache not listed)
  40314CC3782A8F62       3028  2026-11-07 12:01:29.465  logs\godot.log
  19681A18A84164DD       4094  2026-11-07 12:01:22.268  logs\godot2026-11-07T12.01.22.log
  4461E62C9BD6FD76      11821  2026-11-07 12:01:29.220  saves\slot_0.json
other Godot processes after: 3
  pid 22216 started 07:24:53: D:\Godot\Godot_v4.7.2-stable_win64.exe --path D:/TheLastFrame/the-last-frame --editor
  pid 29100 started 11:09:35: "D:\Godot\Godot_v4.7.2-stable_win64_console.exe" --path C:\Users\adity\orca\workspaces\the-last-frame\tlf-implementation-qa --headless -s res://scratch/run_one.gd
  pid 12956 started 11:09:35: D:\Godot\Godot_v4.7.2-stable_win64.exe --path C:\Users\adity\orca\workspaces\the-last-frame\tlf-implementation-qa --headless -s res://scratch/run_one.gd
real save folder after: 1 file(s), UNCHANGED
  screenshot file continue_01_title_continue.png 2481 bytes
  screenshot file continue_02_ch01_continued.png 16020 bytes
  screenshot file continue_03_ch01_continue_walk.png 15995 bytes
  screenshot file new_01_title_new_game.png 2481 bytes
  screenshot file new_02_ch01_new_game.png 15738 bytes
  screenshot file new_03_ch01_watch_pickup.png 16635 bytes
  screenshot file new_04_ch01_checkpoint_saved.png 16720 bytes
  screenshot file release_continue_01_title.png 24216 bytes
  screenshot file release_continue_02_chapter1.png 123835 bytes
  screenshot file release_continue_03_checkpoint.png 123239 bytes
  screenshot file release_new_01_title.png 24212 bytes
  screenshot file release_new_02_chapter1.png 126795 bytes
  screenshot file release_new_03_watch.png 130131 bytes
  screenshot file release_new_04_checkpoint.png 128840 bytes
  screenshot file release_plain_01_title.png 24212 bytes
  screenshot file release_plain_02_quit_selected.png 24216 bytes
RESULT tree                     PASS
RESULT templates                PASS
RESULT export_release           PASS
RESULT export_debug             PASS
RESULT release_plain            PASS
RESULT release_new              PASS
RESULT release_continue         PASS
RESULT release_checks           PASS
RESULT pck_new                  PASS
RESULT pck_continue             PASS
RESULT save_in_release_user_dir PASS
RESULT save_in_debug_user_dir   PASS
RESULT real_folder_untouched    PASS
SMOKE: ALL PASSED
```

### stdout of pck_new (stderr: empty)

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5060

SMOKE phase=new out=C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d\evidence\screenshots
SMOKE executable=C:/Users/adity/AppData/Local/Temp/claude/D--TheLastFrame-wt-opus-core/582a2292-05b9-4d18-8e5b-fea1d2cfbcc9/scratchpad/godot_sc/Godot_v4.7.2-stable_win64.exe
SMOKE version=4.7.2-stable (official) debug_build=true display=Windows renderer=d3d12
SMOKE user_data_dir=C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Smoke 1b2de6d debug
SMOKE CHECK ok   user dir is not the real 'The Last Frame' folder
SMOKE CHECK ok   user dir belongs to the renamed smoke project
SMOKE save_root=user://saves -> C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Smoke 1b2de6d debug/saves
SMOKE CHECK ok   the exported game uses the player save root user://saves
SMOKE title text 'THE LAST FRAME', menu '> New Game <' / 'Continue' / 'Quit'
SMOKE CHECK ok   the title is translated
SMOKE title font res://assets/ui/fonts/tlf_pixel_mono.ttf name='TLF Pixel Mono'
SMOKE CHECK ok   the title uses the pixel font res://assets/ui/fonts/tlf_pixel_mono.ttf
SMOKE title: 5 visible labels checked for translation keys
SMOKE CHECK ok   fresh user dir: no save in slot 0
SMOKE CHECK ok   Continue disabled without a save
SMOKE CHECK ok   New Game selected
SMOKE screenshot C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d\evidence\screenshots/new_01_title_new_game.png size=(640, 360) error=0
SMOKE CHECK ok   screenshot title_new_game saved
SMOKE key Enter (confirm)
SMOKE CHECK ok   New Game loads Chapter01
SMOKE CHECK ok   new game starts on the arrival platform (ch01.arrival_platform)
SMOKE player at (352.0, 160.0)
SMOKE chapter 1 start: 6 visible labels checked for translation keys
SMOKE screenshot C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d\evidence\screenshots/new_02_ch01_new_game.png size=(640, 360) error=0
SMOKE CHECK ok   screenshot ch01_new_game saved
SMOKE walked out of the checkpoint: (318.0119, 141.0059)
SMOKE checkpoint_reached ch01.cp.arrival error=0
SMOKE walked to the pocket watch: (352.0, 174.0)
SMOKE CHECK ok   the pocket watch is the interact target
SMOKE key E (interact)
SMOKE CHECK ok   E on the watch picks it up
SMOKE HUD feedback 'Trace unlocked. Hold the watch up to anything that remembers.', dialogue '[23:59] A hand sets this watch down on the tiles, face up.'
SMOKE after the watch pickup: 7 visible labels checked for translation keys
SMOKE screenshot C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d\evidence\screenshots/new_03_ch01_watch_pickup.png size=(640, 360) error=0
SMOKE CHECK ok   screenshot ch01_watch_pickup saved
SMOKE checkpoint_reached ch01.cp.arrival error=0
SMOKE checkpoint_reached ch01.cp.arrival error=0
SMOKE wandered 6 legs, 464 px, now at (364.2168, 175.1056)
SMOKE CHECK ok   the keys move the player (464 px)
SMOKE walked out of the checkpoint again: (319.4956, 140.745)
SMOKE checkpoint_reached ch01.cp.arrival error=0
SMOKE walked into the checkpoint: (351.6949, 158.8446)
SMOKE real input for 5.9 s
SMOKE CHECK ok   walking into ch01.cp.arrival writes the autosave
SMOKE CHECK ok   slot 0 reads back ()
SMOKE CHECK ok   the save's checkpoint is ch01.cp.arrival
SMOKE CHECK ok   the save holds the watch flag
SMOKE save file C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Smoke 1b2de6d debug/saves/slot_0.json exists=true
SMOKE screenshot C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d\evidence\screenshots/new_04_ch01_checkpoint_saved.png size=(640, 360) error=0
SMOKE CHECK ok   screenshot ch01_checkpoint_saved saved
SMOKE PASS phase=new
SMOKE READY_TO_CLOSE
```

### stdout of pck_continue (stderr: empty)

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5060

SMOKE phase=continue out=C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d\evidence\screenshots
SMOKE executable=C:/Users/adity/AppData/Local/Temp/claude/D--TheLastFrame-wt-opus-core/582a2292-05b9-4d18-8e5b-fea1d2cfbcc9/scratchpad/godot_sc/Godot_v4.7.2-stable_win64.exe
SMOKE version=4.7.2-stable (official) debug_build=true display=Windows renderer=d3d12
SMOKE user_data_dir=C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Smoke 1b2de6d debug
SMOKE CHECK ok   user dir is not the real 'The Last Frame' folder
SMOKE CHECK ok   user dir belongs to the renamed smoke project
SMOKE save_root=user://saves -> C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Smoke 1b2de6d debug/saves
SMOKE CHECK ok   the exported game uses the player save root user://saves
SMOKE title text 'THE LAST FRAME', menu 'New Game' / '> Continue <' / 'Quit'
SMOKE CHECK ok   the title is translated
SMOKE title font res://assets/ui/fonts/tlf_pixel_mono.ttf name='TLF Pixel Mono'
SMOKE CHECK ok   the title uses the pixel font res://assets/ui/fonts/tlf_pixel_mono.ttf
SMOKE title: 5 visible labels checked for translation keys
SMOKE CHECK ok   the save from the new-game run is in slot 0
SMOKE CHECK ok   Continue enabled
SMOKE CHECK ok   Continue selected by default
SMOKE screenshot C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d\evidence\screenshots/continue_01_title_continue.png size=(640, 360) error=0
SMOKE CHECK ok   screenshot title_continue saved
SMOKE key Enter (confirm)
SMOKE CHECK ok   Continue loads Chapter01
SMOKE CHECK ok   Continue restores the arrival platform (ch01.arrival_platform)
SMOKE CHECK ok   Continue restores the watch flag
SMOKE CHECK ok   Trace available after Continue
SMOKE player at (352.0, 160.0) (checkpoint (352.0, 160.0))
SMOKE CHECK ok   respawn at the checkpoint
SMOKE after Continue: 4 visible labels checked for translation keys
SMOKE screenshot C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d\evidence\screenshots/continue_02_ch01_continued.png size=(640, 360) error=0
SMOKE CHECK ok   screenshot ch01_continued saved
SMOKE wandered 6 legs, 388 px, now at (360.3273, 105.9252)
SMOKE CHECK ok   the keys move the player (388 px)
SMOKE walked away from the checkpoint: (319.6195, 139.3508)
SMOKE walked back to the checkpoint: (351.8188, 157.4505)
SMOKE real input for 4.9 s
SMOKE screenshot C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\smoke_1b2de6d\evidence\screenshots/continue_03_ch01_continue_walk.png size=(640, 360) error=0
SMOKE CHECK ok   screenshot ch01_continue_walk saved
SMOKE PASS phase=continue
SMOKE READY_TO_CLOSE
```

### stdout of release_plain (stderr: empty)

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5060
```

### stdout of release_new (stderr: empty)

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5060
```

### stdout of release_continue (stderr: empty)

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5060
```

The export and import logs (836 / 836 / 970 lines) contain only the Godot banner and the progress bar; no line matches `error` or `warning`.

## Complete raw validate output (`1b2de6d`, `git archive` copy, `config/name="TLF Verify 1b2de6d"`, no BOM; exit 0)

ANSI colour codes and the UTF-8 BOM are stripped; nothing else is changed. The original log (1717 lines) has sha256 `ce25755ff6090334bc52ae3e8c5e517c0e6a0c7d1e59b10dba834cee73096b7c`.

```
=== Validating The Last Frame Project ===
Using Godot executable: D:\Godot\Godot_v4.7.2-stable_win64_console.exe
Project root: C:\Users\adity\AppData\Local\Temp\claude\D--TheLastFrame-wt-opus-core\582a2292-05b9-4d18-8e5b-fea1d2cfbcc9\scratchpad\verify_1b2de6d

[1/3] Running headless import check...
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started Project initialization (5 steps)
[   0% ] first_scan_filesystem | Scanning file structure...
[  16% ] first_scan_filesystem | Loading global class names...
[  33% ] first_scan_filesystem | Verifying GDExtensions...
[  50% ] first_scan_filesystem | Creating autoload scripts...
[  66% ] first_scan_filesystem | Initializing plugins...
[  83% ] first_scan_filesystem | Starting file scan...
[ DONE ] first_scan_filesystem

[   0% ] update_scripts_classes | Started Registering global classes... (153 steps)
[   0% ] update_scripts_classes | BreakerCPresenter
[   0% ] update_scripts_classes | CableConduitPresenter
[   1% ] update_scripts_classes | CardReaderPresenter
[   1% ] update_scripts_classes | CommuterStatuePresenter
[   2% ] update_scripts_classes | ConduitPropPresenter
[   3% ] update_scripts_classes | CounterweightGearPresenter
[   3% ] update_scripts_classes | DeadRelayPresenter
[   4% ] update_scripts_classes | DispatchTerminalPresenter
[   5% ] update_scripts_classes | EchoPedestalPresenter
[   5% ] update_scripts_classes | FireShutterPresenter
[   6% ] update_scripts_classes | HistoryDialPresenter
[   7% ] update_scripts_classes | LeverPresenter
[   7% ] update_scripts_classes | PressureSwitchPresenter
[   8% ] update_scripts_classes | ReleaseLeverPresenter
[   9% ] update_scripts_classes | RetractableBridgePresenter
[   9% ] update_scripts_classes | RoomVisuals
[  10% ] update_scripts_classes | RouteBoardPresenter
[  11% ] update_scripts_classes | SecurityGatePresenter
[  11% ] update_scripts_classes | SelectorSwitchPresenter
[  12% ] update_scripts_classes | ServiceHatchPresenter
[  12% ] update_scripts_classes | SurgeCapacitorPresenter
[  13% ] update_scripts_classes | TicketValidatorPresenter
[  14% ] update_scripts_classes | TurnstilePresenter
[  14% ] update_scripts_classes | Chapter01
[  15% ] update_scripts_classes | OperatorSighting
[  16% ] update_scripts_classes | SignalControlIntercom
[  16% ] update_scripts_classes | 
[  17% ] update_scripts_classes | 
[  18% ] update_scripts_classes | EchoService
[  18% ] update_scripts_classes | Interactable
[  19% ] update_scripts_classes | Lever
[  20% ] update_scripts_classes | TriggerZone
[  20% ] update_scripts_classes | AbilityUnlocks
[  21% ] update_scripts_classes | DocumentDef
[  22% ] update_scripts_classes | NarrativeState
[  22% ] update_scripts_classes | ReadableDocument
[  23% ] update_scripts_classes | TraceMemory
[  24% ] update_scripts_classes | Player
[  24% ] update_scripts_classes | PocketWatch
[  25% ] update_scripts_classes | CardReader
[  25% ] update_scripts_classes | CodeLock
[  26% ] update_scripts_classes | ConduitProp
[  27% ] update_scripts_classes | CounterweightGear
[  27% ] update_scripts_classes | DeadRelay
[  28% ] update_scripts_classes | DecoyPlate
[  29% ] update_scripts_classes | FireShutter
[  29% ] update_scripts_classes | HistoryDial
[  30% ] update_scripts_classes | JunctionLever
[  31% ] update_scripts_classes | LampRingBreaker
[  31% ] update_scripts_classes | PlateLinkedGate
[  32% ] update_scripts_classes | PoweredDoor
[  33% ] update_scripts_classes | ProgressionPickup
[  33% ] update_scripts_classes | PuzzleObject
[  34% ] update_scripts_classes | ReleaseLever
[  35% ] update_scripts_classes | RetractableBridge
[  35% ] update_scripts_classes | SelectorSwitch
[  36% ] update_scripts_classes | SpatialStateResetter
[  37% ] update_scripts_classes | SubstationGrid
[  37% ] update_scripts_classes | SurgeCapacitor
[  38% ] update_scripts_classes | TicketValidator
[  38% ] update_scripts_classes | TimedBreaker
[  39% ] update_scripts_classes | TurnstileGate
[  40% ] update_scripts_classes | AbilityUnlockTrigger
[  40% ] update_scripts_classes | HintService
[  41% ] update_scripts_classes | PuzzleCompletionZone
[  42% ] update_scripts_classes | PuzzleDef
[  42% ] update_scripts_classes | PuzzleService
[  43% ] update_scripts_classes | ResetAnchor
[  44% ] update_scripts_classes | CheckpointZone
[  44% ] update_scripts_classes | RoomRouter
[  45% ] update_scripts_classes | SafeAnchor
[  46% ] update_scripts_classes | SaveStore
[  46% ] update_scripts_classes | GameSession
[  47% ] update_scripts_classes | IdRegistry
[  48% ] update_scripts_classes | InteractionResult
[  48% ] update_scripts_classes | InteractionService
[  49% ] update_scripts_classes | SimClock
[  50% ] update_scripts_classes | 
[  50% ] update_scripts_classes | ChapterGraphDef
[  51% ] update_scripts_classes | DoorwayPresenter
[  51% ] update_scripts_classes | SpatialGraph
[  52% ] update_scripts_classes | SpatialService
[  53% ] update_scripts_classes | PlaytestLog
[  53% ] update_scripts_classes | TemporalComponent
[  54% ] update_scripts_classes | TemporalTestGate
[  55% ] update_scripts_classes | TemporalTestGear
[  55% ] update_scripts_classes | TemporalTestShutter
[  56% ] update_scripts_classes | AbilityWheel
[  57% ] update_scripts_classes | ChapterCompleteOverlay
[  57% ] update_scripts_classes | DialogueBox
[  58% ] update_scripts_classes | DialogueTrigger
[  59% ] update_scripts_classes | DocumentViewer
[  59% ] update_scripts_classes | HUD
[  60% ] update_scripts_classes | InputPrompts
[  61% ] update_scripts_classes | JournalScreen
[  61% ] update_scripts_classes | 
[  62% ] update_scripts_classes | UIFeedback
[  62% ] update_scripts_classes | UITheme
[  63% ] update_scripts_classes | 
[  64% ] update_scripts_classes | 
[  64% ] update_scripts_classes | 
[  65% ] update_scripts_classes | 
[  66% ] update_scripts_classes | 
[  66% ] update_scripts_classes | 
[  67% ] update_scripts_classes | 
[  68% ] update_scripts_classes | 
[  68% ] update_scripts_classes | 
[  69% ] update_scripts_classes | 
[  70% ] update_scripts_classes | 
[  70% ] update_scripts_classes | 
[  71% ] update_scripts_classes | 
[  72% ] update_scripts_classes | 
[  72% ] update_scripts_classes | 
[  73% ] update_scripts_classes | 
[  74% ] update_scripts_classes | 
[  74% ] update_scripts_classes | 
[  75% ] update_scripts_classes | 
[  75% ] update_scripts_classes | 
[  76% ] update_scripts_classes | 
[  77% ] update_scripts_classes | 
[  77% ] update_scripts_classes | 
[  78% ] update_scripts_classes | 
[  79% ] update_scripts_classes | 
[  79% ] update_scripts_classes | 
[  80% ] update_scripts_classes | 
[  81% ] update_scripts_classes | 
[  81% ] update_scripts_classes | 
[  82% ] update_scripts_classes | 
[  83% ] update_scripts_classes | 
[  83% ] update_scripts_classes | 
[  84% ] update_scripts_classes | 
[  85% ] update_scripts_classes | 
[  85% ] update_scripts_classes | 
[  86% ] update_scripts_classes | 
[  87% ] update_scripts_classes | 
[  87% ] update_scripts_classes | 
[  88% ] update_scripts_classes | 
[  88% ] update_scripts_classes | 
[  89% ] update_scripts_classes | 
[  90% ] update_scripts_classes | 
[  90% ] update_scripts_classes | 
[  91% ] update_scripts_classes | 
[  92% ] update_scripts_classes | 
[  92% ] update_scripts_classes | 
[  93% ] update_scripts_classes | 
[  94% ] update_scripts_classes | 
[  94% ] update_scripts_classes | 
[  95% ] update_scripts_classes | 
[  96% ] update_scripts_classes | 
[  96% ] update_scripts_classes | 
[  97% ] update_scripts_classes | 
[  98% ] update_scripts_classes | 
[  98% ] update_scripts_classes | 
[ DONE ] update_scripts_classes

[   0% ] _update_scan_actions | Started Scanning actions... (262 steps)
[   0% ] _update_scan_actions | ch01_char_elias_base_sheet.png
[   0% ] _update_scan_actions | ch01_char_operator_sighting_ne_sheet.png
[   0% ] _update_scan_actions | ch01_char_statue_body_a_pose1_idle.png
[   1% ] _update_scan_actions | ch01_char_statue_body_a_pose1_read.png
[   1% ] _update_scan_actions | ch01_char_statue_body_a_pose2_idle.png
[   1% ] _update_scan_actions | ch01_char_statue_body_a_pose2_read.png
[   2% ] _update_scan_actions | ch01_char_statue_body_b_pose1_idle.png
[   2% ] _update_scan_actions | ch01_char_statue_body_b_pose1_read.png
[   3% ] _update_scan_actions | ch01_char_statue_body_b_pose2_idle.png
[   3% ] _update_scan_actions | ch01_char_statue_body_b_pose2_read.png
[   3% ] _update_scan_actions | ch01_char_statue_body_c_pose1_idle.png
[   4% ] _update_scan_actions | ch01_char_statue_body_c_pose1_read.png
[   4% ] _update_scan_actions | ch01_char_statue_body_c_pose2_idle.png
[   4% ] _update_scan_actions | ch01_char_statue_body_c_pose2_read.png
[   5% ] _update_scan_actions | ch01_char_statue_commuter_n01_conductor_idle.png
[   5% ] _update_scan_actions | ch01_char_statue_commuter_n01_conductor_read.png
[   6% ] _update_scan_actions | ch01_char_statue_commuter_n02_student_idle.png
[   6% ] _update_scan_actions | ch01_char_statue_commuter_n02_student_read.png
[   6% ] _update_scan_actions | ch01_char_statue_commuter_n03_old_man_idle.png
[   7% ] _update_scan_actions | ch01_char_statue_commuter_n03_old_man_read.png
[   7% ] _update_scan_actions | ch01_char_statue_commuter_n04_cleaner_idle.png
[   7% ] _update_scan_actions | ch01_char_statue_commuter_n04_cleaner_read.png
[   8% ] _update_scan_actions | ch01_char_statue_commuter_n05_courier_idle.png
[   8% ] _update_scan_actions | ch01_char_statue_commuter_n05_courier_read.png
[   9% ] _update_scan_actions | ch01_char_statue_commuter_n06_red_coat_idle.png
[   9% ] _update_scan_actions | ch01_char_statue_commuter_n06_red_coat_read.png
[   9% ] _update_scan_actions | ch01_char_statue_commuter_n07_briefcase_idle.png
[  10% ] _update_scan_actions | ch01_char_statue_commuter_n07_briefcase_read.png
[  10% ] _update_scan_actions | ch01_char_statue_commuter_n08_father_idle.png
[  11% ] _update_scan_actions | ch01_char_statue_commuter_n08_father_read.png
[  11% ] _update_scan_actions | ch01_char_statue_commuter_n09_teen_idle.png
[  11% ] _update_scan_actions | ch01_char_statue_commuter_n09_teen_read.png
[  12% ] _update_scan_actions | ch01_char_statue_commuter_n11_hatch_tech_idle.png
[  12% ] _update_scan_actions | ch01_char_statue_commuter_n11_hatch_tech_read.png
[  12% ] _update_scan_actions | ch01_char_statue_commuter_n13_guard_idle.png
[  13% ] _update_scan_actions | ch01_char_statue_commuter_n13_guard_read.png
[  13% ] _update_scan_actions | ch01_char_statue_commuter_n20_engineer_idle.png
[  14% ] _update_scan_actions | ch01_char_statue_commuter_n20_engineer_read.png
[  14% ] _update_scan_actions | ch01_char_statue_commuter_n21_tourist_idle.png
[  14% ] _update_scan_actions | ch01_char_statue_commuter_n21_tourist_read.png
[  15% ] _update_scan_actions | ch01_char_statue_n03_old_man_seated_idle.png
[  15% ] _update_scan_actions | ch01_char_statue_n03_old_man_seated_read.png
[  15% ] _update_scan_actions | ch01_char_statue_n04_cleaner_idle.png
[  16% ] _update_scan_actions | ch01_char_statue_n04_cleaner_read.png
[  16% ] _update_scan_actions | ch01_char_statue_n05_courier_vault_idle.png
[  17% ] _update_scan_actions | ch01_char_statue_n05_courier_vault_read.png
[  17% ] _update_scan_actions | ch01_char_statue_n11_tech_crank_idle.png
[  17% ] _update_scan_actions | ch01_char_statue_n11_tech_crank_read.png
[  18% ] _update_scan_actions | ch01_env_archway_frame_e_idle.png
[  18% ] _update_scan_actions | ch01_env_archway_frame_n_idle.png
[  19% ] _update_scan_actions | ch01_env_arrival_platform_target_sheet.png
[  19% ] _update_scan_actions | ch01_env_beat10_city_backdrop_idle.png
[  19% ] _update_scan_actions | ch01_env_beat10_city_plate_idle.png
[  20% ] _update_scan_actions | ch01_env_beat10_suspended_rain_idle.png
[  20% ] _update_scan_actions | ch01_env_tile_cable_conduit_off_idle.png
[  20% ] _update_scan_actions | ch01_env_tile_cable_conduit_on_idle.png
[  21% ] _update_scan_actions | ch01_env_tile_concrete_service_idle.png
[  21% ] _update_scan_actions | ch01_env_tile_industrial_grating_idle.png
[  22% ] _update_scan_actions | ch01_env_tile_stone_step_wet_idle.png
[  22% ] _update_scan_actions | ch01_env_tile_tactile_amber_idle.png
[  22% ] _update_scan_actions | ch01_env_tile_terrazzo_cracked_idle.png
[  23% ] _update_scan_actions | ch01_env_tile_terrazzo_dark_idle.png
[  23% ] _update_scan_actions | ch01_env_wall_bulkhead_module_idle.png
[  23% ] _update_scan_actions | ch01_env_wall_corner_pillar_idle.png
[  24% ] _update_scan_actions | ch01_env_wall_railing_iron_idle.png
[  24% ] _update_scan_actions | ch01_env_wall_subterranean_n_idle.png
[  25% ] _update_scan_actions | ch01_env_wall_subterranean_w_idle.png
[  25% ] _update_scan_actions | ch01_fx_operator_sighting_trace_ring_idle.png
[  25% ] _update_scan_actions | ch01_prop_alarm_plate_idle.png
[  26% ] _update_scan_actions | ch01_prop_alarm_plate_ringing.png
[  26% ] _update_scan_actions | ch01_prop_bell_icon_idle.png
[  26% ] _update_scan_actions | ch01_prop_bell_icon_ringing.png
[  27% ] _update_scan_actions | ch01_prop_breaker_c_browned_out.png
[  27% ] _update_scan_actions | ch01_prop_breaker_c_engaged.png
[  28% ] _update_scan_actions | ch01_prop_breaker_c_idle.png
[  28% ] _update_scan_actions | ch01_prop_bridge_platform_extended.png
[  28% ] _update_scan_actions | ch01_prop_bridge_platform_retracted.png
[  29% ] _update_scan_actions | ch01_prop_call_box_phone_idle.png
[  29% ] _update_scan_actions | ch01_prop_call_box_phone_ringing.png
[  30% ] _update_scan_actions | ch01_prop_card_reader_accepted.png
[  30% ] _update_scan_actions | ch01_prop_card_reader_denied.png
[  30% ] _update_scan_actions | ch01_prop_card_reader_idle.png
[  31% ] _update_scan_actions | ch01_prop_conduit_fallen.png
[  31% ] _update_scan_actions | ch01_prop_conduit_mounted.png
[  31% ] _update_scan_actions | ch01_prop_counterweight_gear_frozen.png
[  32% ] _update_scan_actions | ch01_prop_counterweight_gear_idle.png
[  32% ] _update_scan_actions | ch01_prop_counterweight_gear_slipping.png
[  33% ] _update_scan_actions | ch01_prop_dead_relay_c_idle.png
[  33% ] _update_scan_actions | ch01_prop_dead_relay_c_shake.png
[  33% ] _update_scan_actions | ch01_prop_departure_board_nowhere_idle.png
[  34% ] _update_scan_actions | ch01_prop_digital_clock_2359_idle.png
[  34% ] _update_scan_actions | ch01_prop_dispatch_terminal_active.png
[  34% ] _update_scan_actions | ch01_prop_dispatch_terminal_idle.png
[  35% ] _update_scan_actions | ch01_prop_document_clipboard_idle.png
[  35% ] _update_scan_actions | ch01_prop_door_rd_access_sealed_idle.png
[  36% ] _update_scan_actions | ch01_prop_echo_pedestal_idle.png
[  36% ] _update_scan_actions | ch01_prop_echo_pedestal_used.png
[  36% ] _update_scan_actions | ch01_prop_fire_shutter_closed.png
[  37% ] _update_scan_actions | ch01_prop_fire_shutter_raised.png
[  37% ] _update_scan_actions | ch01_prop_flap_dial_line_idle.png
[  38% ] _update_scan_actions | ch01_prop_flap_dial_line_jammed.png
[  38% ] _update_scan_actions | ch01_prop_flap_dial_platform_idle.png
[  38% ] _update_scan_actions | ch01_prop_flap_dial_platform_jammed.png
[  39% ] _update_scan_actions | ch01_prop_flap_dial_time_idle.png
[  39% ] _update_scan_actions | ch01_prop_flap_dial_time_jammed.png
[  39% ] _update_scan_actions | ch01_prop_floor_plate_a_empty.png
[  40% ] _update_scan_actions | ch01_prop_floor_plate_a_pressed.png
[  40% ] _update_scan_actions | ch01_prop_floor_plate_b_empty.png
[  41% ] _update_scan_actions | ch01_prop_floor_plate_b_pressed.png
[  41% ] _update_scan_actions | ch01_prop_inner_shutter_closed.png
[  41% ] _update_scan_actions | ch01_prop_inner_shutter_raised.png
[  42% ] _update_scan_actions | ch01_prop_lever_badge_a_idle.png
[  42% ] _update_scan_actions | ch01_prop_lever_badge_b_idle.png
[  42% ] _update_scan_actions | ch01_prop_lever_switch_off.png
[  43% ] _update_scan_actions | ch01_prop_lever_switch_on.png
[  43% ] _update_scan_actions | ch01_prop_notice_closed_track_idle.png
[  44% ] _update_scan_actions | ch01_prop_pa_speaker_idle.png
[  44% ] _update_scan_actions | ch01_prop_pillar_mark_sector_a_idle.png
[  44% ] _update_scan_actions | ch01_prop_platform_gate_closed.png
[  45% ] _update_scan_actions | ch01_prop_platform_gate_open.png
[  45% ] _update_scan_actions | ch01_prop_pocket_watch_idle.png
[  46% ] _update_scan_actions | ch01_prop_pressure_switch_pressed.png
[  46% ] _update_scan_actions | ch01_prop_pressure_switch_released.png
[  46% ] _update_scan_actions | ch01_prop_release_lever_accepted.png
[  47% ] _update_scan_actions | ch01_prop_release_lever_buzzing.png
[  47% ] _update_scan_actions | ch01_prop_release_lever_idle.png
[  47% ] _update_scan_actions | ch01_prop_reset_console_idle.png
[  48% ] _update_scan_actions | ch01_prop_route_board_state0.png
[  48% ] _update_scan_actions | ch01_prop_route_board_state1.png
[  49% ] _update_scan_actions | ch01_prop_route_board_state2.png
[  49% ] _update_scan_actions | ch01_prop_security_gate_closed.png
[  49% ] _update_scan_actions | ch01_prop_security_gate_open.png
[  50% ] _update_scan_actions | ch01_prop_selector_car_pos0.png
[  50% ] _update_scan_actions | ch01_prop_selector_car_pos1.png
[  50% ] _update_scan_actions | ch01_prop_selector_car_pos2.png
[  51% ] _update_scan_actions | ch01_prop_selector_line_pos0.png
[  51% ] _update_scan_actions | ch01_prop_selector_line_pos1.png
[  52% ] _update_scan_actions | ch01_prop_selector_line_pos2.png
[  52% ] _update_scan_actions | ch01_prop_selector_platform_pos0.png
[  52% ] _update_scan_actions | ch01_prop_selector_platform_pos1.png
[  53% ] _update_scan_actions | ch01_prop_selector_platform_pos2.png
[  53% ] _update_scan_actions | ch01_prop_service_hatch_closed.png
[  53% ] _update_scan_actions | ch01_prop_service_hatch_frozen_closed.png
[  54% ] _update_scan_actions | ch01_prop_service_hatch_frozen_open.png
[  54% ] _update_scan_actions | ch01_prop_service_hatch_open.png
[  55% ] _update_scan_actions | ch01_prop_sign_a1_research_idle.png
[  55% ] _update_scan_actions | ch01_prop_staff_barrier_closed.png
[  55% ] _update_scan_actions | ch01_prop_staff_barrier_open.png
[  56% ] _update_scan_actions | ch01_prop_staff_door_closed.png
[  56% ] _update_scan_actions | ch01_prop_staff_door_open.png
[  57% ] _update_scan_actions | ch01_prop_standby_plate_empty.png
[  57% ] _update_scan_actions | ch01_prop_standby_plate_held.png
[  57% ] _update_scan_actions | ch01_prop_station_bench_idle.png
[  58% ] _update_scan_actions | ch01_prop_statue_ov_breaker_handle_idle.png
[  58% ] _update_scan_actions | ch01_prop_statue_ov_breaker_handle_read.png
[  58% ] _update_scan_actions | ch01_prop_statue_ov_briefcase_idle.png
[  59% ] _update_scan_actions | ch01_prop_statue_ov_briefcase_read.png
[  59% ] _update_scan_actions | ch01_prop_statue_ov_courier_bag_idle.png
[  60% ] _update_scan_actions | ch01_prop_statue_ov_courier_bag_read.png
[  60% ] _update_scan_actions | ch01_prop_statue_ov_gate_lever_idle.png
[  60% ] _update_scan_actions | ch01_prop_statue_ov_gate_lever_read.png
[  61% ] _update_scan_actions | ch01_prop_statue_ov_hatch_crank_idle.png
[  61% ] _update_scan_actions | ch01_prop_statue_ov_hatch_crank_read.png
[  61% ] _update_scan_actions | ch01_prop_statue_ov_headphones_idle.png
[  62% ] _update_scan_actions | ch01_prop_statue_ov_headphones_read.png
[  62% ] _update_scan_actions | ch01_prop_statue_ov_map_idle.png
[  63% ] _update_scan_actions | ch01_prop_statue_ov_map_read.png
[  63% ] _update_scan_actions | ch01_prop_statue_ov_paper_bag_idle.png
[  63% ] _update_scan_actions | ch01_prop_statue_ov_paper_bag_read.png
[  64% ] _update_scan_actions | ch01_prop_statue_ov_phone_idle.png
[  64% ] _update_scan_actions | ch01_prop_statue_ov_phone_read.png
[  65% ] _update_scan_actions | ch01_prop_statue_ov_red_coat_idle.png
[  65% ] _update_scan_actions | ch01_prop_statue_ov_red_coat_read.png
[  65% ] _update_scan_actions | ch01_prop_statue_ov_sleeping_child_idle.png
[  66% ] _update_scan_actions | ch01_prop_statue_ov_sleeping_child_read.png
[  66% ] _update_scan_actions | ch01_prop_statue_ov_suitcase_idle.png
[  66% ] _update_scan_actions | ch01_prop_statue_ov_suitcase_read.png
[  67% ] _update_scan_actions | ch01_prop_statue_ov_trolley_idle.png
[  67% ] _update_scan_actions | ch01_prop_statue_ov_trolley_read.png
[  68% ] _update_scan_actions | ch01_prop_statue_ov_whistle_idle.png
[  68% ] _update_scan_actions | ch01_prop_statue_ov_whistle_read.png
[  68% ] _update_scan_actions | ch01_prop_surge_capacitor_charged.png
[  69% ] _update_scan_actions | ch01_prop_surge_capacitor_discharged.png
[  69% ] _update_scan_actions | ch01_prop_surge_capacitor_frozen.png
[  69% ] _update_scan_actions | ch01_prop_surge_capacitor_frozen_charged.png
[  70% ] _update_scan_actions | ch01_prop_surge_capacitor_frozen_discharged.png
[  70% ] _update_scan_actions | ch01_prop_ticket_terms_notice_idle.png
[  71% ] _update_scan_actions | ch01_prop_ticket_validator_accepted.png
[  71% ] _update_scan_actions | ch01_prop_ticket_validator_idle.png
[  71% ] _update_scan_actions | ch01_prop_ticket_validator_rejecting.png
[  72% ] _update_scan_actions | ch01_prop_trace_shimmer_ring_loop.png
[  72% ] _update_scan_actions | ch01_prop_trace_timestamp_glyph_idle.png
[  73% ] _update_scan_actions | ch01_prop_transit_car_stalled_idle.png
[  73% ] _update_scan_actions | ch01_prop_turnstile_gate_collapsed.png
[  73% ] _update_scan_actions | ch01_prop_turnstile_gate_open.png
[  74% ] _update_scan_actions | ch01_ui_icon_echo.png
[  74% ] _update_scan_actions | ch01_ui_icon_echo_locked.png
[  74% ] _update_scan_actions | ch01_ui_icon_fast_forward.png
[  75% ] _update_scan_actions | ch01_ui_icon_fast_forward_locked.png
[  75% ] _update_scan_actions | ch01_ui_icon_freeze.png
[  76% ] _update_scan_actions | ch01_ui_icon_freeze_locked.png
[  76% ] _update_scan_actions | ch01_ui_icon_rewind.png
[  76% ] _update_scan_actions | ch01_ui_icon_rewind_locked.png
[  77% ] _update_scan_actions | ch01_ui_icon_trace.png
[  77% ] _update_scan_actions | ch01_ui_icon_trace_locked.png
[  77% ] _update_scan_actions | ch01_ui_icon_unknown.png
[  78% ] _update_scan_actions | ch01_ui_icon_unknown_locked.png
[  78% ] _update_scan_actions | ch01_ui_lock_glyph.png
[  79% ] _update_scan_actions | ch01_ui_wheel_face.png
[  79% ] _update_scan_actions | ch01_ui_wheel_pointer_0.png
[  79% ] _update_scan_actions | ch01_ui_wheel_pointer_1.png
[  80% ] _update_scan_actions | ch01_ui_wheel_pointer_2.png
[  80% ] _update_scan_actions | ch01_ui_wheel_pointer_3.png
[  80% ] _update_scan_actions | ch01_ui_wheel_pointer_4.png
[  81% ] _update_scan_actions | ch01_ui_wheel_pointer_5.png
[  81% ] _update_scan_actions | ch01_ui_wheel_pointer_rest.png
[  82% ] _update_scan_actions | ch01_ui_wheel_seg0_locked.png
[  82% ] _update_scan_actions | ch01_ui_wheel_seg0_normal.png
[  82% ] _update_scan_actions | ch01_ui_wheel_seg0_selected.png
[  83% ] _update_scan_actions | ch01_ui_wheel_seg1_locked.png
[  83% ] _update_scan_actions | ch01_ui_wheel_seg1_normal.png
[  84% ] _update_scan_actions | ch01_ui_wheel_seg1_selected.png
[  84% ] _update_scan_actions | ch01_ui_wheel_seg2_locked.png
[  84% ] _update_scan_actions | ch01_ui_wheel_seg2_normal.png
[  85% ] _update_scan_actions | ch01_ui_wheel_seg2_selected.png
[  85% ] _update_scan_actions | ch01_ui_wheel_seg3_locked.png
[  85% ] _update_scan_actions | ch01_ui_wheel_seg3_normal.png
[  86% ] _update_scan_actions | ch01_ui_wheel_seg3_selected.png
[  86% ] _update_scan_actions | ch01_ui_wheel_seg4_locked.png
[  87% ] _update_scan_actions | ch01_ui_wheel_seg4_normal.png
[  87% ] _update_scan_actions | ch01_ui_wheel_seg4_selected.png
[  87% ] _update_scan_actions | ch01_ui_wheel_seg5_locked.png
[  88% ] _update_scan_actions | ch01_ui_wheel_seg5_normal.png
[  88% ] _update_scan_actions | ch01_ui_wheel_seg5_selected.png
[  88% ] _update_scan_actions | ch01_ui_mira_broadcast_portrait_idle.png
[  89% ] _update_scan_actions | tlf_pixel_mono.ttf
[  89% ] _update_scan_actions | ch01_ability_wheel_a_trace_only_mockup.png
[  90% ] _update_scan_actions | ch01_ability_wheel_b_all_four_mockup.png
[  90% ] _update_scan_actions | ch01_ability_wheel_c_rewind_selected_mockup.png
[  90% ] _update_scan_actions | ch01_ability_wheel_greyscale_proof.png
[  91% ] _update_scan_actions | ch01_arrival_platform_mockup.png
[  91% ] _update_scan_actions | ch01_beat10_city_pan_end_640x360_mockup.png
[  92% ] _update_scan_actions | ch01_beat10_city_pan_start_640x360_mockup.png
[  92% ] _update_scan_actions | ch01_beat10_city_plate_greyscale_proof.png
[  92% ] _update_scan_actions | ch01_concourse_west_mockup.png
[  93% ] _update_scan_actions | ch01_operator_cast_silhouette_greyscale_proof.png
[  93% ] _update_scan_actions | ch01_operator_sighting_platform_mockup.png
[  93% ] _update_scan_actions | ch01_security_crossing_mockup.png
[  94% ] _update_scan_actions | ch01_signal_control_mockup.png
[  94% ] _update_scan_actions | ch01_step1_props_greyscale_proof.png
[  95% ] _update_scan_actions | ch01_step1_room_statues_greyscale_proof.png
[  95% ] _update_scan_actions | ch01_step1_room_statues_mockup.png
[  95% ] _update_scan_actions | ch01_step1_room_statues_x3_proof.png
[  96% ] _update_scan_actions | ch01_step1_statues_all13_greyscale_proof.png
[  96% ] _update_scan_actions | ch01_tlf063_story_props_greyscale_proof.png
[  96% ] _update_scan_actions | ch01_tlf063_story_props_room_mockup.png
[  97% ] _update_scan_actions | TLF-044_capacitor_states.png
[  97% ] _update_scan_actions | TLF-044_capacitor_states_grey.png
[  98% ] _update_scan_actions | ch01_puzzles.csv
[  98% ] _update_scan_actions | ch01_text.csv
[  98% ] _update_scan_actions | ui_feedback.csv
[  99% ] _update_scan_actions | icon.svg
[ DONE ] _update_scan_actions

[   0% ] reimport | Started (Re)Importing Assets (262 steps)
[   0% ] reimport | Preparing files to reimport...
[   0% ] reimport | Preparing files to reimport...
[   0% ] reimport | Preparing files to reimport...
[   1% ] reimport | Preparing files to reimport...
[   1% ] reimport | Preparing files to reimport...
[   1% ] reimport | Preparing files to reimport...
[   2% ] reimport | Preparing files to reimport...
[   2% ] reimport | Preparing files to reimport...
[   3% ] reimport | Preparing files to reimport...
[   3% ] reimport | Preparing files to reimport...
[   3% ] reimport | Preparing files to reimport...
[   4% ] reimport | Preparing files to reimport...
[   4% ] reimport | Preparing files to reimport...
[   4% ] reimport | Preparing files to reimport...
[   5% ] reimport | Preparing files to reimport...
[   5% ] reimport | Preparing files to reimport...
[   6% ] reimport | Preparing files to reimport...
[   6% ] reimport | Preparing files to reimport...
[   6% ] reimport | Preparing files to reimport...
[   7% ] reimport | Preparing files to reimport...
[   7% ] reimport | Preparing files to reimport...
[   7% ] reimport | Preparing files to reimport...
[   8% ] reimport | Preparing files to reimport...
[   8% ] reimport | Preparing files to reimport...
[   9% ] reimport | Preparing files to reimport...
[   9% ] reimport | Preparing files to reimport...
[   9% ] reimport | Preparing files to reimport...
[  10% ] reimport | Preparing files to reimport...
[  10% ] reimport | Preparing files to reimport...
[  11% ] reimport | Preparing files to reimport...
[  11% ] reimport | Preparing files to reimport...
[  11% ] reimport | Preparing files to reimport...
[  12% ] reimport | Preparing files to reimport...
[  12% ] reimport | Preparing files to reimport...
[  12% ] reimport | Preparing files to reimport...
[  13% ] reimport | Preparing files to reimport...
[  13% ] reimport | Preparing files to reimport...
[  14% ] reimport | Preparing files to reimport...
[  14% ] reimport | Preparing files to reimport...
[  14% ] reimport | Preparing files to reimport...
[  15% ] reimport | Preparing files to reimport...
[  15% ] reimport | Preparing files to reimport...
[  15% ] reimport | Preparing files to reimport...
[  16% ] reimport | Preparing files to reimport...
[  16% ] reimport | Preparing files to reimport...
[  17% ] reimport | Preparing files to reimport...
[  17% ] reimport | Preparing files to reimport...
[  17% ] reimport | Preparing files to reimport...
[  18% ] reimport | Preparing files to reimport...
[  18% ] reimport | Preparing files to reimport...
[  19% ] reimport | Preparing files to reimport...
[  19% ] reimport | Preparing files to reimport...
[  19% ] reimport | Preparing files to reimport...
[  20% ] reimport | Preparing files to reimport...
[  20% ] reimport | Preparing files to reimport...
[  20% ] reimport | Preparing files to reimport...
[  21% ] reimport | Preparing files to reimport...
[  21% ] reimport | Preparing files to reimport...
[  22% ] reimport | Preparing files to reimport...
[  22% ] reimport | Preparing files to reimport...
[  22% ] reimport | Preparing files to reimport...
[  23% ] reimport | Preparing files to reimport...
[  23% ] reimport | Preparing files to reimport...
[  23% ] reimport | Preparing files to reimport...
[  24% ] reimport | Preparing files to reimport...
[  24% ] reimport | Preparing files to reimport...
[  25% ] reimport | Preparing files to reimport...
[  25% ] reimport | Preparing files to reimport...
[  25% ] reimport | Preparing files to reimport...
[  26% ] reimport | Preparing files to reimport...
[  26% ] reimport | Preparing files to reimport...
[  26% ] reimport | Preparing files to reimport...
[  27% ] reimport | Preparing files to reimport...
[  27% ] reimport | Preparing files to reimport...
[  28% ] reimport | Preparing files to reimport...
[  28% ] reimport | Preparing files to reimport...
[  28% ] reimport | Preparing files to reimport...
[  29% ] reimport | Preparing files to reimport...
[  29% ] reimport | Preparing files to reimport...
[  30% ] reimport | Preparing files to reimport...
[  30% ] reimport | Preparing files to reimport...
[  30% ] reimport | Preparing files to reimport...
[  31% ] reimport | Preparing files to reimport...
[  31% ] reimport | Preparing files to reimport...
[  31% ] reimport | Preparing files to reimport...
[  32% ] reimport | Preparing files to reimport...
[  32% ] reimport | Preparing files to reimport...
[  33% ] reimport | Preparing files to reimport...
[  33% ] reimport | Preparing files to reimport...
[  33% ] reimport | Preparing files to reimport...
[  34% ] reimport | Preparing files to reimport...
[  34% ] reimport | Preparing files to reimport...
[  34% ] reimport | Preparing files to reimport...
[  35% ] reimport | Preparing files to reimport...
[  35% ] reimport | Preparing files to reimport...
[  36% ] reimport | Preparing files to reimport...
[  36% ] reimport | Preparing files to reimport...
[  36% ] reimport | Preparing files to reimport...
[  37% ] reimport | Preparing files to reimport...
[  37% ] reimport | Preparing files to reimport...
[  38% ] reimport | Preparing files to reimport...
[  38% ] reimport | Preparing files to reimport...
[  38% ] reimport | Preparing files to reimport...
[  39% ] reimport | Preparing files to reimport...
[  39% ] reimport | Preparing files to reimport...
[  39% ] reimport | Preparing files to reimport...
[  40% ] reimport | Preparing files to reimport...
[  40% ] reimport | Preparing files to reimport...
[  41% ] reimport | Preparing files to reimport...
[  41% ] reimport | Preparing files to reimport...
[  41% ] reimport | Preparing files to reimport...
[  42% ] reimport | Preparing files to reimport...
[  42% ] reimport | Preparing files to reimport...
[  42% ] reimport | Preparing files to reimport...
[  43% ] reimport | Preparing files to reimport...
[  43% ] reimport | Preparing files to reimport...
[  44% ] reimport | Preparing files to reimport...
[  44% ] reimport | Preparing files to reimport...
[  44% ] reimport | Preparing files to reimport...
[  45% ] reimport | Preparing files to reimport...
[  45% ] reimport | Preparing files to reimport...
[  46% ] reimport | Preparing files to reimport...
[  46% ] reimport | Preparing files to reimport...
[  46% ] reimport | Preparing files to reimport...
[  47% ] reimport | Preparing files to reimport...
[  47% ] reimport | Preparing files to reimport...
[  47% ] reimport | Preparing files to reimport...
[  48% ] reimport | Preparing files to reimport...
[  48% ] reimport | Preparing files to reimport...
[  49% ] reimport | Preparing files to reimport...
[  49% ] reimport | Preparing files to reimport...
[  49% ] reimport | Preparing files to reimport...
[  50% ] reimport | Preparing files to reimport...
[  50% ] reimport | Preparing files to reimport...
[  50% ] reimport | Preparing files to reimport...
[  51% ] reimport | Preparing files to reimport...
[  51% ] reimport | Preparing files to reimport...
[  52% ] reimport | Preparing files to reimport...
[  52% ] reimport | Preparing files to reimport...
[  52% ] reimport | Preparing files to reimport...
[  53% ] reimport | Preparing files to reimport...
[  53% ] reimport | Preparing files to reimport...
[  53% ] reimport | Preparing files to reimport...
[  54% ] reimport | Preparing files to reimport...
[  54% ] reimport | Preparing files to reimport...
[  55% ] reimport | Preparing files to reimport...
[  55% ] reimport | Preparing files to reimport...
[  55% ] reimport | Preparing files to reimport...
[  56% ] reimport | Preparing files to reimport...
[  56% ] reimport | Preparing files to reimport...
[  57% ] reimport | Preparing files to reimport...
[  57% ] reimport | Preparing files to reimport...
[  57% ] reimport | Preparing files to reimport...
[  58% ] reimport | Preparing files to reimport...
[  58% ] reimport | Preparing files to reimport...
[  58% ] reimport | Preparing files to reimport...
[  59% ] reimport | Preparing files to reimport...
[  59% ] reimport | Preparing files to reimport...
[  60% ] reimport | Preparing files to reimport...
[  60% ] reimport | Preparing files to reimport...
[  60% ] reimport | Preparing files to reimport...
[  61% ] reimport | Preparing files to reimport...
[  61% ] reimport | Preparing files to reimport...
[  61% ] reimport | Preparing files to reimport...
[  62% ] reimport | Preparing files to reimport...
[  62% ] reimport | Preparing files to reimport...
[  63% ] reimport | Preparing files to reimport...
[  63% ] reimport | Preparing files to reimport...
[  63% ] reimport | Preparing files to reimport...
[  64% ] reimport | Preparing files to reimport...
[  64% ] reimport | Preparing files to reimport...
[  65% ] reimport | Preparing files to reimport...
[  65% ] reimport | Preparing files to reimport...
[  65% ] reimport | Preparing files to reimport...
[  66% ] reimport | Preparing files to reimport...
[  66% ] reimport | Preparing files to reimport...
[  66% ] reimport | Preparing files to reimport...
[  67% ] reimport | Preparing files to reimport...
[  67% ] reimport | Preparing files to reimport...
[  68% ] reimport | Preparing files to reimport...
[  68% ] reimport | Preparing files to reimport...
[  68% ] reimport | Preparing files to reimport...
[  69% ] reimport | Preparing files to reimport...
[  69% ] reimport | Preparing files to reimport...
[  69% ] reimport | Preparing files to reimport...
[  70% ] reimport | Preparing files to reimport...
[  70% ] reimport | Preparing files to reimport...
[  71% ] reimport | Preparing files to reimport...
[  71% ] reimport | Preparing files to reimport...
[  71% ] reimport | Preparing files to reimport...
[  72% ] reimport | Preparing files to reimport...
[  72% ] reimport | Preparing files to reimport...
[  73% ] reimport | Preparing files to reimport...
[  73% ] reimport | Preparing files to reimport...
[  73% ] reimport | Preparing files to reimport...
[  74% ] reimport | Preparing files to reimport...
[  74% ] reimport | Preparing files to reimport...
[  74% ] reimport | Preparing files to reimport...
[  75% ] reimport | Preparing files to reimport...
[  75% ] reimport | Preparing files to reimport...
[  76% ] reimport | Preparing files to reimport...
[  76% ] reimport | Preparing files to reimport...
[  76% ] reimport | Preparing files to reimport...
[  77% ] reimport | Preparing files to reimport...
[  77% ] reimport | Preparing files to reimport...
[  77% ] reimport | Preparing files to reimport...
[  78% ] reimport | Preparing files to reimport...
[  78% ] reimport | Preparing files to reimport...
[  79% ] reimport | Preparing files to reimport...
[  79% ] reimport | Preparing files to reimport...
[  79% ] reimport | Preparing files to reimport...
[  80% ] reimport | Preparing files to reimport...
[  80% ] reimport | Preparing files to reimport...
[  80% ] reimport | Preparing files to reimport...
[  81% ] reimport | Preparing files to reimport...
[  81% ] reimport | Preparing files to reimport...
[  82% ] reimport | Preparing files to reimport...
[  82% ] reimport | Preparing files to reimport...
[  82% ] reimport | Preparing files to reimport...
[  83% ] reimport | Preparing files to reimport...
[  83% ] reimport | Preparing files to reimport...
[  84% ] reimport | Preparing files to reimport...
[  84% ] reimport | Preparing files to reimport...
[  84% ] reimport | Preparing files to reimport...
[  85% ] reimport | Preparing files to reimport...
[  85% ] reimport | Preparing files to reimport...
[  85% ] reimport | Preparing files to reimport...
[  86% ] reimport | Preparing files to reimport...
[  86% ] reimport | Preparing files to reimport...
[  87% ] reimport | Preparing files to reimport...
[  87% ] reimport | Preparing files to reimport...
[  87% ] reimport | Preparing files to reimport...
[  88% ] reimport | Preparing files to reimport...
[  88% ] reimport | Preparing files to reimport...
[  88% ] reimport | Preparing files to reimport...
[  89% ] reimport | Preparing files to reimport...
[  89% ] reimport | Preparing files to reimport...
[  90% ] reimport | Preparing files to reimport...
[  90% ] reimport | Preparing files to reimport...
[  90% ] reimport | Preparing files to reimport...
[  91% ] reimport | Preparing files to reimport...
[  91% ] reimport | Preparing files to reimport...
[  92% ] reimport | Preparing files to reimport...
[  92% ] reimport | Preparing files to reimport...
[  92% ] reimport | Preparing files to reimport...
[  93% ] reimport | Preparing files to reimport...
[  93% ] reimport | Preparing files to reimport...
[  93% ] reimport | Preparing files to reimport...
[  94% ] reimport | Preparing files to reimport...
[  94% ] reimport | Preparing files to reimport...
[  95% ] reimport | Preparing files to reimport...
[  95% ] reimport | Preparing files to reimport...
[  95% ] reimport | Preparing files to reimport...
[  96% ] reimport | Preparing files to reimport...
[  96% ] reimport | Preparing files to reimport...
[  96% ] reimport | Preparing files to reimport...
[  97% ] reimport | Preparing files to reimport...
[  97% ] reimport | Preparing files to reimport...
[  98% ] reimport | Preparing files to reimport...
[  98% ] reimport | Preparing files to reimport...
[  98% ] reimport | Preparing files to reimport...
[  99% ] reimport | Preparing files to reimport...
[   0% ] reimport | Executing pre-reimport operations...
[   0% ] reimport | ui_feedback.csv
[   0% ] reimport | ch01_text.csv
[   0% ] reimport | ch01_puzzles.csv
[   1% ] reimport | tlf_pixel_mono.ttf
[   1% ] reimport | ui_feedback.csv
[   1% ] reimport | ch01_text.csv
[   2% ] reimport | ch01_puzzles.csv
[   2% ] reimport | tlf_pixel_mono.ttf
[   3% ] reimport | ch01_prop_statue_ov_trolley_idle.png
[   3% ] reimport | ch01_prop_statue_ov_suitcase_read.png
[   3% ] reimport | ch01_prop_statue_ov_suitcase_idle.png
[   4% ] reimport | ch01_prop_statue_ov_sleeping_child_read.png
[   4% ] reimport | ch01_prop_statue_ov_sleeping_child_idle.png
[   4% ] reimport | ch01_prop_statue_ov_red_coat_read.png
[   5% ] reimport | ch01_prop_statue_ov_red_coat_idle.png
[   5% ] reimport | ch01_prop_statue_ov_phone_read.png
[   6% ] reimport | ch01_prop_statue_ov_phone_idle.png
[   6% ] reimport | ch01_prop_statue_ov_paper_bag_read.png
[   6% ] reimport | ch01_prop_statue_ov_paper_bag_idle.png
[   7% ] reimport | ch01_prop_statue_ov_map_read.png
[   7% ] reimport | ch01_prop_statue_ov_map_idle.png
[   7% ] reimport | ch01_prop_statue_ov_headphones_read.png
[   8% ] reimport | ch01_prop_statue_ov_headphones_idle.png
[   8% ] reimport | ch01_prop_statue_ov_trolley_read.png
[   9% ] reimport | ch01_prop_statue_ov_whistle_idle.png
[   9% ] reimport | ch01_prop_statue_ov_whistle_read.png
[   9% ] reimport | ch01_prop_surge_capacitor_charged.png
[  10% ] reimport | ch01_prop_surge_capacitor_discharged.png
[  10% ] reimport | ch01_prop_surge_capacitor_frozen.png
[  11% ] reimport | ch01_prop_surge_capacitor_frozen_charged.png
[  11% ] reimport | ch01_prop_surge_capacitor_frozen_discharged.png
[  11% ] reimport | ch01_prop_ticket_terms_notice_idle.png
[  12% ] reimport | ch01_prop_ticket_validator_accepted.png
[  12% ] reimport | ch01_prop_ticket_validator_idle.png
[  12% ] reimport | ch01_prop_ticket_validator_rejecting.png
[  13% ] reimport | ch01_prop_trace_shimmer_ring_loop.png
[  13% ] reimport | ch01_prop_trace_timestamp_glyph_idle.png
[  14% ] reimport | ch01_prop_transit_car_stalled_idle.png
[  14% ] reimport | ch01_prop_turnstile_gate_collapsed.png
[  14% ] reimport | ch01_prop_security_gate_open.png
[  15% ] reimport | ch01_prop_selector_car_pos0.png
[  15% ] reimport | ch01_prop_selector_car_pos1.png
[  15% ] reimport | ch01_prop_selector_car_pos2.png
[  16% ] reimport | ch01_prop_selector_line_pos0.png
[  16% ] reimport | ch01_prop_selector_line_pos1.png
[  17% ] reimport | ch01_prop_selector_line_pos2.png
[  17% ] reimport | ch01_prop_selector_platform_pos0.png
[  17% ] reimport | ch01_prop_selector_platform_pos1.png
[  18% ] reimport | ch01_prop_selector_platform_pos2.png
[  18% ] reimport | ch01_prop_service_hatch_closed.png
[  19% ] reimport | ch01_prop_service_hatch_frozen_closed.png
[  19% ] reimport | ch01_prop_service_hatch_frozen_open.png
[  19% ] reimport | ch01_prop_service_hatch_open.png
[  20% ] reimport | ch01_prop_sign_a1_research_idle.png
[  20% ] reimport | ch01_prop_staff_barrier_closed.png
[  20% ] reimport | ch01_prop_staff_barrier_open.png
[  21% ] reimport | ch01_prop_staff_door_closed.png
[  21% ] reimport | ch01_prop_staff_door_open.png
[  22% ] reimport | ch01_prop_standby_plate_empty.png
[  22% ] reimport | ch01_prop_standby_plate_held.png
[  22% ] reimport | ch01_prop_station_bench_idle.png
[  23% ] reimport | ch01_prop_statue_ov_breaker_handle_idle.png
[  23% ] reimport | ch01_prop_statue_ov_breaker_handle_read.png
[  23% ] reimport | ch01_prop_statue_ov_briefcase_idle.png
[  24% ] reimport | ch01_prop_statue_ov_briefcase_read.png
[  24% ] reimport | ch01_prop_statue_ov_courier_bag_idle.png
[  25% ] reimport | ch01_prop_statue_ov_courier_bag_read.png
[  25% ] reimport | ch01_prop_statue_ov_gate_lever_idle.png
[  25% ] reimport | ch01_prop_statue_ov_gate_lever_read.png
[  26% ] reimport | ch01_prop_statue_ov_hatch_crank_idle.png
[  26% ] reimport | ch01_prop_statue_ov_hatch_crank_read.png
[  26% ] reimport | ch01_ui_wheel_seg3_normal.png
[  27% ] reimport | ch01_ui_wheel_seg3_selected.png
[  27% ] reimport | ch01_ui_wheel_seg4_locked.png
[  28% ] reimport | ch01_ui_wheel_seg4_normal.png
[  28% ] reimport | ch01_ui_wheel_seg4_selected.png
[  28% ] reimport | ch01_ui_wheel_seg5_locked.png
[  29% ] reimport | ch01_ui_wheel_seg5_normal.png
[  29% ] reimport | ch01_ui_wheel_seg5_selected.png
[  30% ] reimport | ch01_ui_mira_broadcast_portrait_idle.png
[  30% ] reimport | ch01_ability_wheel_a_trace_only_mockup.png
[  30% ] reimport | ch01_ability_wheel_b_all_four_mockup.png
[  31% ] reimport | ch01_ability_wheel_c_rewind_selected_mockup.png
[  31% ] reimport | ch01_ability_wheel_greyscale_proof.png
[  31% ] reimport | ch01_arrival_platform_mockup.png
[  32% ] reimport | ch01_beat10_city_pan_end_640x360_mockup.png
[  32% ] reimport | ch01_beat10_city_pan_start_640x360_mockup.png
[  33% ] reimport | ch01_beat10_city_plate_greyscale_proof.png
[  33% ] reimport | ch01_concourse_west_mockup.png
[  33% ] reimport | ch01_operator_cast_silhouette_greyscale_proof.png
[  34% ] reimport | ch01_operator_sighting_platform_mockup.png
[  34% ] reimport | ch01_security_crossing_mockup.png
[  34% ] reimport | ch01_signal_control_mockup.png
[  35% ] reimport | ch01_step1_props_greyscale_proof.png
[  35% ] reimport | ch01_step1_room_statues_greyscale_proof.png
[  36% ] reimport | ch01_step1_room_statues_mockup.png
[  36% ] reimport | ch01_step1_room_statues_x3_proof.png
[  36% ] reimport | ch01_step1_statues_all13_greyscale_proof.png
[  37% ] reimport | ch01_tlf063_story_props_greyscale_proof.png
[  37% ] reimport | ch01_tlf063_story_props_room_mockup.png
[  38% ] reimport | TLF-044_capacitor_states.png
[  38% ] reimport | TLF-044_capacitor_states_grey.png
[  38% ] reimport | icon.svg
[  39% ] reimport | ch01_prop_turnstile_gate_open.png
[  39% ] reimport | ch01_ui_icon_echo.png
[  39% ] reimport | ch01_ui_icon_echo_locked.png
[  40% ] reimport | ch01_ui_icon_fast_forward.png
[  40% ] reimport | ch01_ui_icon_fast_forward_locked.png
[  41% ] reimport | ch01_ui_icon_freeze.png
[  41% ] reimport | ch01_ui_icon_freeze_locked.png
[  41% ] reimport | ch01_ui_icon_rewind.png
[  42% ] reimport | ch01_ui_icon_rewind_locked.png
[  42% ] reimport | ch01_ui_icon_trace.png
[  42% ] reimport | ch01_ui_icon_trace_locked.png
[  43% ] reimport | ch01_ui_icon_unknown.png
[  43% ] reimport | ch01_ui_icon_unknown_locked.png
[  44% ] reimport | ch01_ui_lock_glyph.png
[  44% ] reimport | ch01_ui_wheel_face.png
[  44% ] reimport | ch01_ui_wheel_pointer_0.png
[  45% ] reimport | ch01_ui_wheel_pointer_1.png
[  45% ] reimport | ch01_ui_wheel_pointer_2.png
[  46% ] reimport | ch01_ui_wheel_pointer_3.png
[  46% ] reimport | ch01_ui_wheel_pointer_4.png
[  46% ] reimport | ch01_ui_wheel_pointer_5.png
[  47% ] reimport | ch01_ui_wheel_pointer_rest.png
[  47% ] reimport | ch01_ui_wheel_seg0_locked.png
[  47% ] reimport | ch01_ui_wheel_seg0_normal.png
[  48% ] reimport | ch01_ui_wheel_seg0_selected.png
[  48% ] reimport | ch01_ui_wheel_seg1_locked.png
[  49% ] reimport | ch01_ui_wheel_seg1_normal.png
[  49% ] reimport | ch01_ui_wheel_seg1_selected.png
[  49% ] reimport | ch01_ui_wheel_seg2_locked.png
[  50% ] reimport | ch01_ui_wheel_seg2_normal.png
[  50% ] reimport | ch01_ui_wheel_seg2_selected.png
[  50% ] reimport | ch01_ui_wheel_seg3_locked.png
[  51% ] reimport | ch01_char_statue_commuter_n11_hatch_tech_read.png
[  51% ] reimport | ch01_char_statue_commuter_n13_guard_idle.png
[  52% ] reimport | ch01_char_statue_commuter_n13_guard_read.png
[  52% ] reimport | ch01_char_statue_commuter_n20_engineer_idle.png
[  52% ] reimport | ch01_char_statue_commuter_n20_engineer_read.png
[  53% ] reimport | ch01_char_statue_commuter_n21_tourist_idle.png
[  53% ] reimport | ch01_char_statue_commuter_n21_tourist_read.png
[  53% ] reimport | ch01_char_statue_n03_old_man_seated_idle.png
[  54% ] reimport | ch01_char_statue_n03_old_man_seated_read.png
[  54% ] reimport | ch01_char_statue_n04_cleaner_idle.png
[  55% ] reimport | ch01_char_statue_n04_cleaner_read.png
[  55% ] reimport | ch01_char_statue_n05_courier_vault_idle.png
[  55% ] reimport | ch01_char_statue_n05_courier_vault_read.png
[  56% ] reimport | ch01_char_statue_n11_tech_crank_idle.png
[  56% ] reimport | ch01_char_statue_n11_tech_crank_read.png
[  57% ] reimport | ch01_env_archway_frame_e_idle.png
[  57% ] reimport | ch01_env_archway_frame_n_idle.png
[  57% ] reimport | ch01_env_arrival_platform_target_sheet.png
[  58% ] reimport | ch01_env_beat10_city_backdrop_idle.png
[  58% ] reimport | ch01_env_beat10_city_plate_idle.png
[  58% ] reimport | ch01_env_beat10_suspended_rain_idle.png
[  59% ] reimport | ch01_env_tile_cable_conduit_off_idle.png
[  59% ] reimport | ch01_env_tile_cable_conduit_on_idle.png
[  60% ] reimport | ch01_env_tile_concrete_service_idle.png
[  60% ] reimport | ch01_env_tile_industrial_grating_idle.png
[  60% ] reimport | ch01_env_tile_stone_step_wet_idle.png
[  61% ] reimport | ch01_env_tile_tactile_amber_idle.png
[  61% ] reimport | ch01_env_tile_terrazzo_cracked_idle.png
[  61% ] reimport | ch01_env_tile_terrazzo_dark_idle.png
[  62% ] reimport | ch01_env_wall_bulkhead_module_idle.png
[  62% ] reimport | ch01_env_wall_corner_pillar_idle.png
[  63% ] reimport | ch01_env_wall_railing_iron_idle.png
[  63% ] reimport | ch01_char_elias_base_sheet.png
[  63% ] reimport | ch01_char_operator_sighting_ne_sheet.png
[  64% ] reimport | ch01_char_statue_body_a_pose1_idle.png
[  64% ] reimport | ch01_char_statue_body_a_pose1_read.png
[  65% ] reimport | ch01_char_statue_body_a_pose2_idle.png
[  65% ] reimport | ch01_char_statue_body_a_pose2_read.png
[  65% ] reimport | ch01_char_statue_body_b_pose1_idle.png
[  66% ] reimport | ch01_char_statue_body_b_pose1_read.png
[  66% ] reimport | ch01_char_statue_body_b_pose2_idle.png
[  66% ] reimport | ch01_char_statue_body_b_pose2_read.png
[  67% ] reimport | ch01_char_statue_body_c_pose1_idle.png
[  67% ] reimport | ch01_char_statue_body_c_pose1_read.png
[  68% ] reimport | ch01_char_statue_body_c_pose2_idle.png
[  68% ] reimport | ch01_char_statue_body_c_pose2_read.png
[  68% ] reimport | ch01_char_statue_commuter_n01_conductor_idle.png
[  69% ] reimport | ch01_char_statue_commuter_n01_conductor_read.png
[  69% ] reimport | ch01_char_statue_commuter_n11_hatch_tech_idle.png
[  69% ] reimport | ch01_char_statue_commuter_n09_teen_read.png
[  70% ] reimport | ch01_char_statue_commuter_n09_teen_idle.png
[  70% ] reimport | ch01_char_statue_commuter_n08_father_read.png
[  71% ] reimport | ch01_char_statue_commuter_n08_father_idle.png
[  71% ] reimport | ch01_char_statue_commuter_n07_briefcase_read.png
[  71% ] reimport | ch01_char_statue_commuter_n07_briefcase_idle.png
[  72% ] reimport | ch01_char_statue_commuter_n06_red_coat_read.png
[  72% ] reimport | ch01_char_statue_commuter_n06_red_coat_idle.png
[  73% ] reimport | ch01_char_statue_commuter_n05_courier_read.png
[  73% ] reimport | ch01_char_statue_commuter_n05_courier_idle.png
[  73% ] reimport | ch01_char_statue_commuter_n04_cleaner_read.png
[  74% ] reimport | ch01_char_statue_commuter_n04_cleaner_idle.png
[  74% ] reimport | ch01_char_statue_commuter_n03_old_man_read.png
[  74% ] reimport | ch01_char_statue_commuter_n03_old_man_idle.png
[  75% ] reimport | ch01_char_statue_commuter_n02_student_read.png
[  75% ] reimport | ch01_char_statue_commuter_n02_student_idle.png
[  76% ] reimport | ch01_prop_fire_shutter_raised.png
[  76% ] reimport | ch01_prop_flap_dial_line_idle.png
[  76% ] reimport | ch01_prop_flap_dial_line_jammed.png
[  77% ] reimport | ch01_prop_flap_dial_platform_idle.png
[  77% ] reimport | ch01_prop_flap_dial_platform_jammed.png
[  77% ] reimport | ch01_prop_flap_dial_time_idle.png
[  78% ] reimport | ch01_prop_flap_dial_time_jammed.png
[  78% ] reimport | ch01_prop_floor_plate_a_empty.png
[  79% ] reimport | ch01_prop_floor_plate_a_pressed.png
[  79% ] reimport | ch01_prop_floor_plate_b_empty.png
[  79% ] reimport | ch01_prop_floor_plate_b_pressed.png
[  80% ] reimport | ch01_prop_inner_shutter_closed.png
[  80% ] reimport | ch01_prop_inner_shutter_raised.png
[  80% ] reimport | ch01_prop_lever_badge_a_idle.png
[  81% ] reimport | ch01_prop_lever_badge_b_idle.png
[  81% ] reimport | ch01_prop_lever_switch_off.png
[  82% ] reimport | ch01_prop_security_gate_closed.png
[  82% ] reimport | ch01_prop_route_board_state2.png
[  82% ] reimport | ch01_prop_route_board_state1.png
[  83% ] reimport | ch01_prop_route_board_state0.png
[  83% ] reimport | ch01_prop_reset_console_idle.png
[  84% ] reimport | ch01_prop_release_lever_idle.png
[  84% ] reimport | ch01_prop_release_lever_buzzing.png
[  84% ] reimport | ch01_prop_release_lever_accepted.png
[  85% ] reimport | ch01_prop_pressure_switch_released.png
[  85% ] reimport | ch01_prop_pressure_switch_pressed.png
[  85% ] reimport | ch01_prop_pocket_watch_idle.png
[  86% ] reimport | ch01_prop_platform_gate_open.png
[  86% ] reimport | ch01_prop_platform_gate_closed.png
[  87% ] reimport | ch01_prop_pillar_mark_sector_a_idle.png
[  87% ] reimport | ch01_prop_pa_speaker_idle.png
[  87% ] reimport | ch01_prop_notice_closed_track_idle.png
[  88% ] reimport | ch01_prop_lever_switch_on.png
[  88% ] reimport | ch01_env_wall_subterranean_n_idle.png
[  88% ] reimport | ch01_env_wall_subterranean_w_idle.png
[  89% ] reimport | ch01_fx_operator_sighting_trace_ring_idle.png
[  89% ] reimport | ch01_prop_alarm_plate_idle.png
[  90% ] reimport | ch01_prop_alarm_plate_ringing.png
[  90% ] reimport | ch01_prop_bell_icon_idle.png
[  90% ] reimport | ch01_prop_bell_icon_ringing.png
[  91% ] reimport | ch01_prop_breaker_c_browned_out.png
[  91% ] reimport | ch01_prop_breaker_c_engaged.png
[  92% ] reimport | ch01_prop_breaker_c_idle.png
[  92% ] reimport | ch01_prop_bridge_platform_extended.png
[  92% ] reimport | ch01_prop_bridge_platform_retracted.png
[  93% ] reimport | ch01_prop_call_box_phone_idle.png
[  93% ] reimport | ch01_prop_call_box_phone_ringing.png
[  93% ] reimport | ch01_prop_card_reader_accepted.png
[  94% ] reimport | ch01_prop_card_reader_denied.png
[  94% ] reimport | ch01_prop_fire_shutter_closed.png
[  95% ] reimport | ch01_prop_echo_pedestal_used.png
[  95% ] reimport | ch01_prop_echo_pedestal_idle.png
[  95% ] reimport | ch01_prop_door_rd_access_sealed_idle.png
[  96% ] reimport | ch01_prop_document_clipboard_idle.png
[  96% ] reimport | ch01_prop_dispatch_terminal_idle.png
[  96% ] reimport | ch01_prop_dispatch_terminal_active.png
[  97% ] reimport | ch01_prop_digital_clock_2359_idle.png
[  97% ] reimport | ch01_prop_departure_board_nowhere_idle.png
[  98% ] reimport | ch01_prop_dead_relay_c_shake.png
[  98% ] reimport | ch01_prop_dead_relay_c_idle.png
[  98% ] reimport | ch01_prop_counterweight_gear_slipping.png
[  99% ] reimport | ch01_prop_counterweight_gear_idle.png
[  99% ] reimport | Finalizing Asset Import...
[ DONE ] reimport

[   0% ] reimport | Started (Re)Importing Assets (262 steps)
[   0% ] reimport | Executing post-reimport operations...
[ DONE ] reimport

[   0% ] loading_editor_layout | Started Loading editor (5 steps)
[   0% ] loading_editor_layout | Loading editor layout...
[  16% ] loading_editor_layout | Loading docks...
[ DONE ] loading_editor_layout

Import check passed with zero errors.

[2/3] Checking that every GDScript parses...
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Script check: 153 scripts, 0 failed.
Settings: headless, path = user://headless/settings.cfg (C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Verify 1b2de6d/headless/settings.cfg)
SaveStore: headless, root = user://headless/saves (C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Verify 1b2de6d/headless/saves)
Leak check: clean (script check)

[3/3] Running headless automated test suite...
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Settings: headless, path = user://headless/settings.cfg (C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Verify 1b2de6d/headless/settings.cfg)
SaveStore: headless, root = user://headless/saves (C:/Users/adity/AppData/Roaming/Godot/app_userdata/TLF Verify 1b2de6d/headless/saves)
--- Running Test Suite ---
Test file: res://tests/chapters/ch01/test_ch01_art_integration.gd
  PASS: test_collision_freeze_all_10_rooms
  PASS: test_intercom_reach_walkable
  PASS: test_no_greybox_nodes_remain_across_all_rooms
  PASS: test_puzzle_prop_presenter_state_mappings
  PASS: test_real_save_unmodified
  PASS: test_room1_arrival_platform_kit_complete
Test file: res://tests/chapters/ch01/test_ch01_narrative_beats.gd
  PASS: test_all_narrative_text_keys_localized_and_ascii
  PASS: test_beat01_platform_awakening_and_watch_pickup
  PASS: test_beat01_player_moves_immediately_and_dialogue_auto_advances
  PASS: test_beat03_call_box_09
  PASS: test_beat05_security_crossing_pa_speaker_echo
  PASS: test_beat06_waiting_lounge_trace_bench_and_mira_audio
  PASS: test_beat07_signal_control_intercom_warning_once
  PASS: test_beat08_upper_vestibule_loop_detection
  PASS: test_beat09_dispatch_terminal_revelation
  PASS: test_beat10_outro_and_chapter_complete
  PASS: test_clocks_2359_are_reusable
  PASS: test_movement_hint_lifecycle
Test file: res://tests/chapters/ch01/test_ch01_playthrough.gd
  PASS: test_chapter01_scene_initialization_and_graph_validation
  PASS: test_doorways_match_chapter_graph_def
  PASS: test_every_door_has_spawn_outside_presenter_shape
  PASS: test_gate_blockers_cover_door_triggers_from_all_approach_vectors
  PASS: test_intercom_adds_operator_warning_after_pz004
  PASS: test_interior_apertures_walkable_with_real_player_capsule
  PASS: test_object_specific_feedback_deferred_flow
  PASS: test_passage_blockers_toggle_with_puzzle_state
  PASS: test_puzzle_objects_configured_with_correct_exports
  PASS: test_pz004_route_is_at_least_600_px
  PASS: test_pz005_levers_and_resetter_configuration
  PASS: test_readables_apply_flags_fragments_and_journal
  PASS: test_room_object_ids_are_valid_and_unique
  PASS: test_room_scenes_exist_and_instantiate
  PASS: test_safe_anchors_and_checkpoints_match_specs
  PASS: test_scripted_playthrough_full_chapter_rooms_1_to_10
  PASS: test_scripted_playthrough_rooms_1_to_4
  PASS: test_street_exit_trigger_outro_completes_chapter
  PASS: test_watch_pickup_shows_unlock_trace_toast_without_regrant
Test file: res://tests/chapters/ch01/test_ch01_pz002_negative.gd
  INFO: PZ-002 no-Freeze run (assist off, window 180 ticks): Rewind from (384.7212, 145.9502); gap passed after 14 ticks at (384.7212, 167.9502); exit trigger (SOLVED) after never; shutter closed after 180 ticks; left east after never; player now (448.9129, 171.761) in ch01.maintenance_bay
  PASS: test_pz002_cannot_be_solved_without_freeze_assist_off
  INFO: PZ-002 no-Freeze run (assist on, window 300 ticks): Rewind from (384.7212, 145.9502); gap passed after 14 ticks at (384.7212, 167.9502); exit trigger (SOLVED) after never; shutter closed after 300 ticks; left east after never; player now (448.9129, 171.761) in ch01.maintenance_bay
  PASS: test_pz002_cannot_be_solved_without_freeze_assist_on
Test file: res://tests/chapters/ch01/test_ch01_pz004_layout.gd
  PASS: test_breaker_b_unreachable_from_south_of_north_railing
  PASS: test_exit_trigger_unskippable_on_path_to_door_exit_north
  PASS: test_north_barrier_visual_and_collision_match
  PASS: test_railings_physically_seal_lanes_at_walls
  PASS: test_shortest_walkable_path_between_breakers_exceeds_600_px
Test file: res://tests/chapters/ch01/test_ch01_pz004_saveload.gd
  PASS: test_f1_save_with_a_recorded_echo
  PASS: test_f2_save_while_the_echo_replays
  PASS: test_f3_save_after_a_brownout
  PASS: test_f4_save_after_solved
Test file: res://tests/chapters/ch01/test_ch01_real_playthrough.gd
  INFO: playthrough | 1 arrival (SO-01)                     590 frames (9.83 s)
  INFO: playthrough | 2a concourse PZ-001                   159 frames (2.65 s)
  INFO: playthrough | 2b concourse PZ-006                   365 frames (6.08 s)
  INFO: playthrough | 3a bay SO-02                           87 frames (1.45 s)
  INFO: playthrough | 3b bay PZ-002                         138 frames (2.30 s)
  INFO: playthrough | 4 crossing PZ-003                     304 frames (5.07 s)
  INFO: playthrough | 5 lounge (audio log, exit)             91 frames (1.52 s)
  INFO: playthrough | 6a PZ-004 step 1 (Rewind+Freeze)      214 frames (3.57 s)
  INFO: playthrough | 6b PZ-004 step 2 (Echo + Z-route)     440 frames (7.33 s)
  INFO: playthrough | 6c PZ-004 exit                         62 frames (1.03 s)
  INFO: playthrough | 7 vestibule PZ-005 (levers)           357 frames (5.95 s)
  INFO: playthrough | 9 atrium terminal (Beat 09)           133 frames (2.22 s)
  INFO: playthrough | 10 street exit outro (Beat 10)         54 frames (0.90 s)
  INFO: real-input playthrough took 2994 physics frames (49.9 s game time, 49.91 s wall)
  INFO: SOLVED ticks [[&"CH1-SO-01", 570], [&"CH1-PZ-001", 749], [&"CH1-PZ-006", 1084], [&"CH1-SO-02", 1196], [&"CH1-PZ-002", 1320], [&"CH1-PZ-003", 1621], [&"CH1-PZ-004", 2432], [&"CH1-PZ-005", 2798]]
  INFO: unlock ticks [[&"rewind", 593], [&"freeze", 1132], [&"echo", 1340]]
  INFO: PlaytestLog | Playtest: 0:49 played, 0:01 paused
  INFO: PlaytestLog | PZ-001 0:03   PZ-002 0:04   PZ-003 0:05
  INFO: PlaytestLog | PZ-004 0:12   PZ-005 0:06   PZ-006 0:08
  INFO: PlaytestLog | SO-01 0:10   SO-02 0:01
  INFO: PlaytestLog | Log: user://headless/playtest/ch01_20261107_120357.json
  PASS: test_real_input_new_game_to_chapter_complete
Test file: res://tests/chapters/ch01/test_ch01_step1_negatives.gd
  PASS: test_pz001_gate_pinned_and_turnstile_holds
  PASS: test_pz002_inner_shutter_needs_the_gear_frozen
  PASS: test_pz003_bridge_cannot_be_crossed_without_echo
  PASS: test_pz003_reader_without_the_pass
  INFO: no-Echo run: B pulled 418 ticks after A from (516.3919, 181.4689); grid_online=false
  PASS: test_pz004_cannot_be_solved_without_echo
  PASS: test_pz005_levers_need_an_echo_on_the_plate
  PASS: test_pz006_staff_door_holds_300_ticks
  PASS: test_so01_closed_gate_holds_300_ticks
  PASS: test_so01_lockout_holds_until_it_ends
  PASS: test_so02_bell_decoy_and_checkpoint_spawn
  PASS: test_so02_bulkhead_sealed
  PASS: test_so02_hatch_closes_without_freeze
Test file: res://tests/chapters/ch01/test_ch01_unlock_guards.gd
  PASS: test_load_in_bay_before_the_technician_keeps_freeze_locked
  PASS: test_load_in_concourse_before_the_courier_keeps_rewind_locked
  PASS: test_load_rederives_unlocks_from_the_flags
  PASS: test_new_game_selects_nothing_but_trace
Test file: res://tests/chapters/ch01/test_operator_sighting.gd
  PASS: test_operator_mystery_guidelines_invariants
  PASS: test_operator_sighting_animation_cadence
  PASS: test_operator_sighting_dormant_before_pickup_and_appears_on_watch
  PASS: test_operator_sighting_node_and_visual_properties
  PASS: test_operator_sighting_reduced_effects_mode
  PASS: test_operator_sighting_save_load_lifecycle
  PASS: test_operator_sighting_vanishes_on_approach
Test file: res://tests/core/test_scene_router.gd
  PASS: test_boot_routes_to_the_title_screen
  PASS: test_confirm_after_chapter_complete_returns_to_title
  PASS: test_router_is_an_autoload_without_class_name
  PASS: test_start_chapter_remembers_the_restore_slot_once
Test file: res://tests/echo/test_echo_service.gd
  PASS: test_completion_trigger_ignores_echo
  PASS: test_determinism_chunked_and_per_tick_playback_match
  PASS: test_ghost_follows_samples_and_holds_final_position
  PASS: test_missing_target_is_skipped_and_playback_continues
  PASS: test_pz003_02_echo_keeps_holding_switch_after_playback
  PASS: test_pz003_03_reset_releases_occupancy
  PASS: test_pz003_04_echo_cannot_take_progression_items
  PASS: test_pz004_04_echo_pull_lands_on_its_recorded_offset
  PASS: test_pz004_05_unpowered_replay_fails_gracefully
  PASS: test_recording_auto_stops_at_max_length
  PASS: test_recording_captures_player_events_with_relative_ticks
  PASS: test_restarting_playback_releases_then_reacquires_occupancy
  PASS: test_room_change_stops_recording
  PASS: test_state_machine_guards
  PASS: test_triggers_occupied_at_record_start_are_seeded_at_rel_zero
  PASS: test_watch_abilities_and_non_player_actors_are_not_recorded
Test file: res://tests/interaction/test_interactable_lifecycle.gd
ERROR: IdRegistry: Duplicate ID 'ch01.test_lever' already registered to OriginalLever:<Area2D#2223199226692>.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:40)
       [1] _register_with_session (res://scripts/interaction/interactable.gd:75)
       [2] _ready (res://scripts/interaction/interactable.gd:39)
       [3] test_duplicate_interactable_removal_preserves_original (res://tests/interaction/test_interactable_lifecycle.gd:61)
       [4] run_test (res://tests/run_tests.gd:158)
       [5] _run_all (res://tests/run_tests.gd:131)
       [6] run_test (res://tests/run_tests.gd:183)
  PASS: test_duplicate_interactable_removal_preserves_original
ERROR: Interactable 'EmptyIdLever' has an empty object_id.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/interaction/interactable.gd:37)
       [1] test_empty_id_interactable_does_not_register (res://tests/interaction/test_interactable_lifecycle.gd:102)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_empty_id_interactable_does_not_register
ERROR: Interactable 'OrphanLever' (ch01.orphan_lever) could not find GameSession with IdRegistry.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _register_with_session (res://scripts/interaction/interactable.gd:73)
       [1] _ready (res://scripts/interaction/interactable.gd:39)
       [2] test_interactable_handles_missing_game_session (res://tests/interaction/test_interactable_lifecycle.gd:125)
       [3] run_test (res://tests/run_tests.gd:158)
       [4] _run_all (res://tests/run_tests.gd:131)
       [5] run_test (res://tests/run_tests.gd:183)
  PASS: test_interactable_handles_missing_game_session
Test file: res://tests/interaction/test_targeting.gd
  PASS: test_targeting_nearest_interactable
  PASS: test_targeting_tie_break_lexicographical
Test file: res://tests/narrative/test_ch01_text.gd
  PASS: test_documents_reference_existing_keys_and_load
  PASS: test_every_feedback_key_in_the_specs_has_text
  PASS: test_multiline_pages_survive_godot_import
  PASS: test_revelation_document_applies_its_effects
  PASS: test_text_is_ascii_and_within_limits
Test file: res://tests/narrative/test_documents_journal.gd
  PASS: test_echo_cannot_read_documents
  PASS: test_invalid_document_is_refused
  PASS: test_journal_categories_and_promotion
  PASS: test_journal_survives_save_and_load
  PASS: test_reading_applies_flag_fragment_and_journal_once
Test file: res://tests/narrative/test_trace_memory.gd
  PASS: test_one_shot_dialogue_and_use_rules
  PASS: test_revealed_state_survives_a_save
  PASS: test_trace_with_real_input_reveals_the_memory_once
Test file: res://tests/player/test_ability_unlocks.gd
  PASS: test_continue_restores_unlocks
  PASS: test_default_start_keeps_all_four_abilities
  PASS: test_locked_selected_ability_falls_back_when_the_set_shrinks
  PASS: test_trace_only_start_and_locked_feedback
WARNING: AbilityUnlocks: unknown ability 'teleport'.
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] unlock (res://scripts/narrative/ability_unlocks.gd:43)
       [1] test_unlock_triggers_flag_pickup_and_puzzle_solved (res://tests/player/test_ability_unlocks.gd:163)
       [2] physics_frames (res://tests/support/base_test.gd:38)
  PASS: test_unlock_triggers_flag_pickup_and_puzzle_solved
Test file: res://tests/player/test_player_movement.gd
  PASS: test_cardinal_movement_vectors
  PASS: test_diagonal_movement_vectors_2_to_1
  PASS: test_zero_movement_on_no_input
Test file: res://tests/player/test_pocket_watch.gd
  PASS: test_ability_cycling_order_and_wrap
  PASS: test_echo_watch_state_machine_and_reset
  PASS: test_ghost_node_freed_on_watch_cleanup_no_leaks
  PASS: test_player_interact_failure_shows_hud_feedback
  PASS: test_targeting_echo_clears_target
  PASS: test_targeting_fallback_to_nearest
  PASS: test_targeting_out_of_radius_rejected
  PASS: test_targeting_preference_for_supporting_object
  PASS: test_targeting_tie_break_lexicographical
  PASS: test_watch_dispatches_correct_interaction_id
Test file: res://tests/player/test_spawn_targeting.gd
  PASS: test_spawn_targeting_ignores_checkpoint_and_picks_up_watch
Test file: res://tests/player/test_targeting_selection.gd
  PASS: test_adr006_tie_break_unchanged
  PASS: test_blocked_but_supported_use_stays_targetable
  PASS: test_fallback_pool_contains_no_trigger
  PASS: test_trigger_and_checkpoint_only_returns_null
  PASS: test_trigger_closer_than_usable_picks_usable
Test file: res://tests/puzzle/test_ch01_puzzles.gd
  PASS: test_pz001_01_use_on_collapsed_turnstile_is_jammed
  PASS: test_pz001_02_pillar_rewind_unsupported
  PASS: test_pz001_03_rewind_restores_open_at_tick_10
  PASS: test_pz001_04_second_rewind_no_history
  PASS: test_pz001_05_exit_trigger_solves
  PASS: test_pz001_adr016_reset_after_solve_keeps_passage_open
  PASS: test_pz001_reset_collapses_and_relocates_player_in_footprint
  PASS: test_pz001_solved_before_load_latches_open_on_ready
  PASS: test_pz002_01_raised_for_180_ticks_then_closes
  PASS: test_pz002_02_freezing_gear_halts_countdown
  PASS: test_pz002_03_frozen_gear_blocks_rewind
  PASS: test_pz002_04_safety_clutch_relocates_player
  PASS: test_pz002_05_rewind_again_after_slipping
  PASS: test_pz002_accessibility_assist_extends_window_to_300
  PASS: test_pz002_reset_and_solved_latch
  PASS: test_pz003_01_plate_toggles_gate_and_bridge_on_the_same_tick
  PASS: test_pz003_02_echo_holds_the_plate_after_playback
  PASS: test_pz003_03_reset_releases_echo_and_relocates_player_on_bridge
  PASS: test_pz003_04_echo_cannot_take_the_transit_pass
  PASS: test_pz003_05_gate_is_chrono_shielded
  PASS: test_pz003_solved_bridge_survives_echo_reset
  PASS: test_pz004_01_breakers_unpowered_before_step_1
  PASS: test_pz004_02_rewind_then_freeze_locks_the_bus
  PASS: test_pz004_03_single_breaker_expires_after_180
  PASS: test_pz004_04_echo_a_plus_player_b_brings_the_grid_online
  PASS: test_pz004_04b_echo_window_equals_player_window
  PASS: test_pz004_05_unpowered_replay_fails_with_reason
  PASS: test_pz004_06_exit_trigger_solves
  PASS: test_pz004_rewinding_frozen_capacitor_is_refused_and_reset_restores
  PASS: test_pz005_01_state0_north_loops_to_west
  PASS: test_pz005_02_lever_b_first_is_invalid_graph
  PASS: test_pz005_03_lever_a_then_b_routes_north_to_atrium
  PASS: test_pz005_04_severing_the_entry_is_critical_path_unreachable
  PASS: test_pz005_05_player_in_niche_is_relocated_when_sealed
  PASS: test_pz005_06_atrium_entry_solves_and_latches_levers
  PASS: test_pz005_levers_and_route_board_abilities
  PASS: test_pz005_reset_restores_state0_atomically
Test file: res://tests/puzzle/test_hint_service.gd
  PASS: test_ch01_puzzle_data_is_complete_and_translated
  PASS: test_hint_levels_survive_save_and_load
  PASS: test_hints_escalate_after_cooldown_and_stop_at_level_three
  PASS: test_hints_refused_for_unknown_or_solved_puzzles
ERROR: HintService: invalid PuzzleDef 'CH1-PZ-T01'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register_def (res://scripts/puzzle/hint_service.gd:31)
       [1] test_invalid_defs_are_rejected (res://tests/puzzle/test_hint_service.gd:74)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: HintService: invalid PuzzleDef '<null>'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register_def (res://scripts/puzzle/hint_service.gd:31)
       [1] test_invalid_defs_are_rejected (res://tests/puzzle/test_hint_service.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_invalid_defs_are_rejected
  PASS: test_room_hint_follows_play_order_in_shared_rooms
  PASS: test_room_hint_targets_first_unsolved_puzzle
Test file: res://tests/puzzle/test_puzzle_service.gd
  PASS: test_completion_zone_solves_for_player_only
WARNING: PuzzleService: ignoring invalid state 'BANANA' for 'CH1-PZ-004'.
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] import_state (res://scripts/puzzle/puzzle_service.gd:90)
       [1] test_export_import_never_downgrades_and_ignores_garbage (res://tests/puzzle/test_puzzle_service.gd:48)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_export_import_never_downgrades_and_ignores_garbage
  PASS: test_reset_anchor_resets_its_puzzle_through_the_contract
  PASS: test_reset_clears_echo_and_tells_members_whether_solved
  PASS: test_unknown_puzzles_are_unsolved_and_solving_is_idempotent
  PASS: test_watch_focus_hook_emits_once_per_change
Test file: res://tests/puzzle/test_step1_r1_deltas.gd
  PASS: test_pz001_r01_the_courier_unlocks_rewind
  PASS: test_pz001_r02_anchor_memory_journals_once
  PASS: test_pz001_r03_fallen_conduit_pins_the_turnstile
  PASS: test_pz001_r04_conduit_rewinds_once
  PASS: test_pz001_r05_full_solution_and_latch
  PASS: test_pz001_r06_order_independence
  PASS: test_pz001_r08_empty_pinned_by_is_the_base_turnstile
  PASS: test_pz001_r09_reset_while_unsolved
  PASS: test_pz002_r01_inner_shutter_is_unanchored_while_the_gear_is_free
  PASS: test_pz002_r02_anchored_inner_shutter_holds
  PASS: test_pz002_r03_freeze_is_required_assist_off
  PASS: test_pz002_r03_freeze_is_required_assist_on
  PASS: test_pz002_r04_late_freeze_from_the_pocket_solves
  PASS: test_pz002_r05_full_solution_survives_save_and_load
  PASS: test_pz002_r07_clutch_when_the_gear_is_unfrozen_later
  PASS: test_pz002_r08_base_shutter_rule_unchanged
  PASS: test_pz002_r09_old_trigger_is_inert
  PASS: test_pz002_r10_reset_closes_both_and_unfreezes
  PASS: test_pz003_r01_pedestal_unlocks_echo
  PASS: test_pz003_r02_guard_memory_journals_once
  PASS: test_pz003_r03_echo_cannot_take_the_pass
  PASS: test_pz003_r04_reader_without_the_pass
  PASS: test_pz003_r05_reader_with_the_pass_latches
  PASS: test_pz003_r06_alarm_plate_does_not_open_the_gate
  PASS: test_pz003_r09_full_solution_survives_save_and_load
  PASS: test_pz004_r01_breaker_c_browns_the_capacitor_out
  PASS: test_pz004_r02_dead_bus
  PASS: test_pz004_r03_c_is_not_an_input
  PASS: test_pz004_r04_brownout_is_recoverable
  PASS: test_pz004_r05_c_does_nothing_once_the_grid_is_online
  PASS: test_pz004_r06_engineer_and_chart_name_c_as_the_lamp_ring
  PASS: test_pz005_r01_dead_relay_without_the_standby_plate
  PASS: test_pz005_r02_echo_on_the_plate_powers_the_relays
  PASS: test_pz005_r02_relay_is_checked_at_pull_time
  PASS: test_pz005_r04_order_rule_unchanged
  PASS: test_pz005_r05_lever_c_is_a_dead_relay
  PASS: test_pz005_r06_echo_reset_keeps_state_2
  PASS: test_pz005_r07_empty_requires_plate_is_the_base_lever
  PASS: test_pz005_r08_memo_and_tourist_do_not_state_the_lever_order
Test file: res://tests/puzzle/test_step1_solo_and_ticket.gd
  PASS: test_pz006_01_correct_ticket_solves
  PASS: test_pz006_02_rewind_steps_the_dial_back
  PASS: test_pz006_03_use_on_a_dial_is_jammed
  PASS: test_pz006_04_initial_state_is_wrong
  PASS: test_pz006_05_every_wrong_triple_gives_the_same_answer
  PASS: test_pz006_06_no_constant_triple_and_tickets_match_the_memories
  PASS: test_pz006_07_the_fathers_ticket_is_rejected
  PASS: test_pz006_08_ticket_values_live_only_in_trace_memories
  PASS: test_pz006_10_reset_restores_index_5_and_the_history
  PASS: test_pz006_11_latch_after_solved_survives_save_and_load
  PASS: test_pz006_12_save_keeps_the_dial_history
  PASS: test_pz006_13_no_hidden_prerequisite
  PASS: test_pz006_14_rewind_needs_the_unlock
  PASS: test_so01_01_correct_code_opens_the_gate_and_solves
  PASS: test_so01_02_initial_position_is_wrong
  PASS: test_so01_03_every_wrong_code_gives_the_same_answer
  PASS: test_so01_04_lockout_360_ticks_assist_off
  PASS: test_so01_04_lockout_600_ticks_assist_on
  PASS: test_so01_06_answer_lives_only_in_trace_memories_and_labels
  PASS: test_so01_07_latest_statement_per_field_is_the_answer
  PASS: test_so01_08_statues_are_trace_only
  PASS: test_so01_09_latch_after_solved_survives_save_and_load
  PASS: test_so01_lockout_is_not_saved
  PASS: test_so01_lockout_is_not_started_by_prompt_queries
  PASS: test_so02_01_tracing_the_technician_unlocks_freeze
  PASS: test_so02_02_plate_opens_and_closes_the_hatch_on_the_same_tick
  PASS: test_so02_03_freeze_holds_the_hatch_open
  PASS: test_so02_06_other_abilities_are_unsupported
  PASS: test_so02_07_bell_plate_is_a_decoy
  PASS: test_so02_09_freeze_closed_is_recoverable
  PASS: test_so02_10_clutch_moves_the_player_before_closing
  PASS: test_so02_11_latch_after_solved_survives_save_and_load
  PASS: test_so02_12_security_crossing_gate_defaults_unchanged
  PASS: test_so02_frozen_open_state_survives_save_and_load_unsolved
  PASS: test_so02_unfreeze_on_an_occupied_plate_stays_open
Test file: res://tests/rooms/test_room_router.gd
  PASS: test_arrival_grace_ignores_immediate_traversal
  PASS: test_checkpoint_autosave_and_restore_into_fresh_session
  PASS: test_doorway_moves_player_to_other_room_and_unloads_old_one
ERROR: RoomRouter: unknown room 'ch01.nowhere'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] enter_room (res://scripts/rooms/room_router.gd:91)
       [1] test_enter_room_loads_scene_registers_objects_and_places_player (res://tests/rooms/test_room_router.gd:130)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_enter_room_loads_scene_registers_objects_and_places_player
  PASS: test_relocation_to_anchor_in_another_room_loads_that_room
  PASS: test_restore_places_player_at_checkpoint_spawn_anchor
  PASS: test_restore_with_unknown_room_is_refused
  PASS: test_room_change_resets_echo
  PASS: test_same_room_loop_repositions_without_reload
  PASS: test_world_memory_keeps_consumed_rewind_across_rooms
Test file: res://tests/save/test_headless_save_root.gd
  PASS: test_env_override_resolves_to_real_root
  PASS: test_headless_resolves_to_headless_root
  PASS: test_new_store_uses_the_resolved_root_and_assignment_wins
  PASS: test_this_headless_run_never_targets_the_real_saves
  PASS: test_windowed_resolves_to_real_root
Test file: res://tests/save/test_save_service.gd
  PASS: test_capture_and_apply_round_trip_ability_unlocks
  PASS: test_capture_contains_every_section_and_temporal_history
  PASS: test_disk_round_trip_preserves_types_and_leaves_no_temp_file
  PASS: test_full_loop_consumed_pre_history_stays_consumed_after_load
ERROR: SaveService: refusing to write invalid save (invalid).
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] write_slot (res://scripts/save/save_service.gd:145)
       [1] test_invalid_structure_is_refused_for_read_and_write (res://tests/save/test_save_service.gd:235)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_invalid_structure_is_refused_for_read_and_write
  PASS: test_migrations_run_in_order_up_to_current_version
ERROR: Parse JSON failed. Error at line 0: Expected key
   at: parse_string (core/io/json.cpp:629)
   GDScript backtrace (most recent call first):
       [0] read_slot (res://scripts/save/save_service.gd:172)
       [1] test_missing_and_corrupt_files_fail_gracefully (res://tests/save/test_save_service.gd:121)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_missing_and_corrupt_files_fail_gracefully
  PASS: test_missing_optional_fields_get_defaults
  PASS: test_newer_version_is_rejected
  PASS: test_unknown_temporal_ids_are_skipped_not_fatal
  PASS: test_v1_save_migrates_to_v2_with_an_empty_playtest_log
  PASS: test_v2_save_migrates_to_v3_with_all_four_abilities
Test file: res://tests/session/test_id_registry.gd
ERROR: IdRegistry: Duplicate ID 'ch01.test_node' already registered to <Node#2633150499501>.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:40)
       [1] test_duplicate_id_rejected (res://tests/session/test_id_registry.gd:90)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_duplicate_id_rejected
ERROR: IdRegistry: Cannot register node with empty ID.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:32)
       [1] test_empty_id_rejected (res://tests/session/test_id_registry.gd:51)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_empty_id_rejected
ERROR: IdRegistry: ID 'ch1.gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'platform.gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'ch01.' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'ch01..gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'CH01.gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'global.Gate' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'global.pocket-watch' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
ERROR: IdRegistry: ID 'global' does not match ADR-005 pattern '^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$'.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] register (res://scripts/session/id_registry.gd:36)
       [1] test_malformed_ids_rejected (res://tests/session/test_id_registry.gd:75)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_malformed_ids_rejected
  PASS: test_unregister_and_resolve
  PASS: test_unregister_requires_matching_node
  PASS: test_valid_id_registration
Test file: res://tests/session/test_interaction_service.gd
  PASS: test_interaction_can_interact_rejection
  PASS: test_interaction_echo_forbidden_on_progression
  PASS: test_interaction_missing_target
  PASS: test_interaction_success_and_signal
  PASS: test_trigger_signals
Test file: res://tests/session/test_sim_clock.gd
  PASS: test_sim_clock_pause
  PASS: test_sim_clock_step
Test file: res://tests/settings/test_headless_settings_path.gd
  PASS: test_env_override_resolves_to_real_settings
  PASS: test_headless_resolves_to_headless_settings
  PASS: test_new_settings_use_the_resolved_path_and_assignment_wins
  PASS: test_this_headless_run_never_targets_the_real_settings
  PASS: test_windowed_resolves_to_real_settings
Test file: res://tests/settings/test_settings.gd
  PASS: test_ability_wheel_remap_and_conflict
  PASS: test_bus_volumes_applied
ERROR: ConfigFile parse error at user://test_settings_corrupt.cfg:0: Unexpected EOF while parsing simple tag.
   at: _parse (core/io/config_file.cpp:293)
   GDScript backtrace (most recent call first):
       [0] load_settings (res://scripts/settings/settings.gd:177)
       [1] test_corrupt_file_handling (res://tests/settings/test_settings.gd:167)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
WARNING: Settings file 'user://test_settings_corrupt.cfg' exists but failed to parse (error 43). Resetting to defaults.
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] load_settings (res://scripts/settings/settings.gd:180)
       [1] test_corrupt_file_handling (res://tests/settings/test_settings.gd:167)
       [2] run_test (res://tests/run_tests.gd:158)
       [3] _run_all (res://tests/run_tests.gd:131)
       [4] run_test (res://tests/run_tests.gd:183)
  PASS: test_corrupt_file_handling
  PASS: test_default_settings
  PASS: test_echo_reset_present_and_no_conflicts
  PASS: test_joypad_device_minus_one_preserved
  PASS: test_remap_allow_list_interact_confirm
  PASS: test_remap_conflict_rejected
  PASS: test_remap_persisted_and_reapplied
  PASS: test_remap_success
  PASS: test_reset_action
  PASS: test_save_load_round_trip
  PASS: test_timing_window_assist
  PASS: test_unknown_action_and_invalid_event
  PASS: test_value_clamping
Test file: res://tests/spatial/test_ch01_graph.gd
  PASS: test_apply_to_configures_the_session_and_relocates_from_the_sealed_niche
  PASS: test_cutting_the_start_off_the_vestibule_is_refused
  PASS: test_definition_builds_a_valid_graph
  PASS: test_every_door_sits_on_its_boundary_wall
  PASS: test_every_room_fits_the_fixed_camera
  PASS: test_relocation_anchors_are_declared_safe_anchors
  PASS: test_solving_pz005_opens_the_rest_of_the_chapter_and_backtracking_works
  PASS: test_state0_reachability_and_the_grille
  PASS: test_static_edges_connect_opposite_sides
Test file: res://tests/spatial/test_spatial_graph.gd
  PASS: test_doorway_presenter_reports_destination_and_blocks_grille
  PASS: test_i2_relooping_while_routed_to_atrium_is_rejected
  PASS: test_i3_unknown_duplicate_and_dangling_are_invalid
  PASS: test_levers_reverse_back_to_state0
  PASS: test_player_in_vestibule_is_not_relocated
  PASS: test_pz005_01_state0_north_loops_to_west
  PASS: test_pz005_02_lever_b_first_is_rejected_without_side_effects
  PASS: test_pz005_03_lever_a_then_b_reaches_atrium
  PASS: test_pz005_04_severing_the_entry_is_critical_path_unreachable
  PASS: test_pz005_05_player_stranded_in_niche_is_relocated
  PASS: test_reachability_respects_non_traversable_edges
  PASS: test_spatial_state_survives_save_and_load
Test file: res://tests/support/test_test_runner_async.gd
  PASS: test_async_failure_is_reported
  PASS: test_async_pass_steps_physics_frames
  PASS: test_async_timeout_fails_with_clear_message_and_detaches
  PASS: test_input_released_after_failing_async_test
  PASS: test_input_released_when_sync_test_fails_before_flush
  NOTE: case_leaves_node_and_hangs left 1 node(s) under the root; freed them.
  PASS: test_nodes_left_by_timed_out_test_are_freed
Test file: res://tests/telemetry/test_playtest_log.gd
  PASS: test_chapter_complete_writes_json_to_the_headless_folder_and_shows_a_summary
  PASS: test_continue_from_a_v1_save_marks_solved_puzzles_untracked
  PASS: test_flag_defaults_on_in_debug_off_in_export_and_output_paths
  PASS: test_flag_off_means_no_log_no_file_no_summary
  PASS: test_hints_resets_and_failures_are_counted_per_puzzle
  PASS: test_pauses_are_counted_separately_not_as_puzzle_time
  INFO: playtest log of the TLF-030 route: total 15.33 s active, 0 dialogue ticks; CH1-PZ-001 1.45 s (87 ticks); CH1-PZ-002 3.55 s (213 ticks); CH1-PZ-003 4.82 s (289 ticks); ch01.arrival_platform 2.05 s; ch01.concourse_west 4.43 s; ch01.maintenance_bay 3.75 s; ch01.security_crossing 5.07 s; ch01.waiting_lounge 0.03 s
  PASS: test_real_input_rooms_1_to_4_times_match_the_sim_clock
  PASS: test_save_and_continue_keep_the_log
Test file: res://tests/temporal/test_temporal_abilities.gd
  PASS: test_determinism_step_chunking_is_irrelevant
  PASS: test_echo_actor_may_use_abilities_on_non_progression_objects
  PASS: test_frozen_object_rejects_use_until_unfrozen
  PASS: test_pz001_01_use_on_collapsed_gate_is_jammed
  PASS: test_pz001_02_static_pillar_rejects_every_ability
  PASS: test_pz001_03_rewind_restores_pre_arrival_open_state_and_signals_tick
  PASS: test_pz001_04_second_rewind_reports_no_history
  PASS: test_pz002_01_rewound_shutter_holds_180_ticks_then_closes
  PASS: test_pz002_02_freezing_gear_halts_countdown
  PASS: test_pz002_03_frozen_gear_blocks_shutter_rewind
  PASS: test_pz002_05_shutter_can_be_rewound_again_after_slipping
  PASS: test_trace_on_traceable_object_emits_traced
  PASS: test_wrong_ability_on_coupled_objects_is_unsupported
Test file: res://tests/temporal/test_temporal_component.gd
  PASS: test_commit_after_rewind_truncates_future
  PASS: test_counter_changes_do_not_commit
  PASS: test_export_import_round_trip
  PASS: test_fast_forward_calls_parent_advance
  PASS: test_freeze_is_a_toggle_and_blocks_rewind
  PASS: test_initial_history_seeds_before_current_state
ERROR: TemporalComponent on '@Node@777': capture_state() keys ["phase", "counter"] do not match state_fields ["phase"].
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _is_valid_snapshot (res://scripts/temporal/temporal_component.gd:234)
       [1] commit_history (res://scripts/temporal/temporal_component.gd:89)
       [2] test_invalid_snapshot_is_rejected (res://tests/temporal/test_temporal_component.gd:119)
       [3] run_test (res://tests/run_tests.gd:158)
       [4] _run_all (res://tests/run_tests.gd:131)
       [5] run_test (res://tests/run_tests.gd:183)
  PASS: test_invalid_snapshot_is_rejected
  PASS: test_missing_capabilities_are_unsupported
  PASS: test_reset_to_initial_restores_tick0_and_history
  PASS: test_rewind_steps_back_then_reports_no_history
  PASS: test_ring_capacity_evicts_oldest
  PASS: test_sim_clock_step_emits_every_tick
Test file: res://tests/test_project_settings.gd
  PASS: test_autoloads
  PASS: test_controller_device_configuration
  PASS: test_custom_theme_registered
  PASS: test_input_actions
  PASS: test_main_scene
  PASS: test_no_input_binding_conflicts
  PASS: test_viewport_and_display_settings
Test file: res://tests/ui/test_ability_wheel.gd
  PASS: test_aiming_locked_segment_refused_no_change
  PASS: test_controller_lt_axis_and_stick_selection
  PASS: test_hold_z_aim_right_down_selects_freeze
  PASS: test_issue_041_hud_elements_hidden_during_chapter_complete
  PASS: test_modal_priority_blocks_wheel_opening
  PASS: test_reduced_effects_prevents_pulse
  PASS: test_release_does_not_trigger_watch_action
  PASS: test_release_in_dead_zone_no_change
  PASS: test_segment_positions_stay_identical_after_unlock
  PASS: test_toggle_mode_open_confirm_cancel
Test file: res://tests/ui/test_chapter_complete_overlay.gd
  PASS: test_overlay_compat_title_label
  PASS: test_overlay_layout_and_safe_margins
  PASS: test_overlay_text_scale_2
  PASS: test_overlay_without_summary
Test file: res://tests/ui/test_dialogue_box.gd
  PASS: test_blocking_dialogue_continue_cue_and_reduced_effects
  NOTE: test_dialogue_box_advance_does_not_trigger_interactable left 1 node(s) under the root; freed them.
  PASS: test_dialogue_box_advance_does_not_trigger_interactable
  PASS: test_dialogue_box_auto_advance
  PASS: test_dialogue_box_blocking_stops_player_movement
  PASS: test_dialogue_box_sequencing_and_advancement
  PASS: test_dialogue_one_shot_flag_and_save_load
  NOTE: test_non_blocking_dialogue_does_not_consume_interact left 1 node(s) under the root; freed them.
  PASS: test_non_blocking_dialogue_does_not_consume_interact
Test file: res://tests/ui/test_document_viewer.gd
  NOTE: test_document_viewer_interact_does_not_reopen_on_close left 1 node(s) under the root; freed them.
  PASS: test_document_viewer_interact_does_not_reopen_on_close
  PASS: test_document_viewer_multipage_paging_and_beat09_journal
  PASS: test_document_viewer_single_page_and_simclock_pause
Test file: res://tests/ui/test_hint_ui.gd
  PASS: test_hint_action_binding
  PASS: test_hint_hud_request_and_escalation
Test file: res://tests/ui/test_hud_feedback.gd
  PASS: test_feedback_text_resolves_all_standard_reasons
  PASS: test_hud_feedback_toast_display_and_dismissal
  PASS: test_prompt_glyphs_keyboard_vs_joypad
ERROR: Interactable '@Area2D@911' (ch01.test_target) could not find GameSession with IdRegistry.
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _register_with_session (res://scripts/interaction/interactable.gd:73)
       [1] _ready (res://scripts/interaction/interactable.gd:39)
       [2] test_target_marker_camera_offset_conversion (res://tests/ui/test_hud_feedback.gd:114)
       [3] run_test (res://tests/run_tests.gd:158)
       [4] _run_all (res://tests/run_tests.gd:131)
       [5] run_test (res://tests/run_tests.gd:183)
  PASS: test_target_marker_camera_offset_conversion
  PASS: test_translations_registered_in_project_settings
  PASS: test_use_vs_watch_unsupported_feedback
Test file: res://tests/ui/test_journal_screen.gd
  PASS: test_journal_screen_empty_state
  PASS: test_journal_screen_grouping_by_category
Test file: res://tests/ui/test_title_screen.gd
ERROR: Parse JSON failed. Error at line 0: Expected key
   at: parse_string (core/io/json.cpp:629)
   GDScript backtrace (most recent call first):
       [0] read_slot (res://scripts/save/save_service.gd:172)
       [1] _ready (res://scripts/chapters/ch01/chapter01.gd:66)
  PASS: test_broken_save_starts_fresh_with_feedback
  PASS: test_continue_disabled_without_a_save
  PASS: test_continue_enabled_with_a_save_and_menu_navigation
  PASS: test_continue_restores_the_signal_control_checkpoint
  PASS: test_new_game_starts_chapter_1_in_the_arrival_platform
  PASS: test_new_game_with_a_save_asks_once
  PASS: test_title_text_is_translated_ascii
Test file: res://tests/ui/test_ui_theme.gd
  PASS: test_action_glyph_first_key_and_confirm
  PASS: test_font_scan_ui_and_chapter01
  PASS: test_panel_clipping_dialogue_and_documents
  PASS: test_static_scene_font_size_overrides
WARNING: UITheme: TLF Pixel Mono not available, using default font
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _setup_font (res://scripts/ui/ui_theme.gd:74)
       [1] _setup_theme (res://scripts/ui/ui_theme.gd:50)
       [2] _init (res://scripts/ui/ui_theme.gd:25)
       [3] test_theme_fallback_when_font_unavailable (res://tests/ui/test_ui_theme.gd:273)
       [4] run_test (res://tests/run_tests.gd:158)
       [5] _run_all (res://tests/run_tests.gd:131)
       [6] run_test (res://tests/run_tests.gd:183)
  PASS: test_theme_fallback_when_font_unavailable
---------------------------
TESTS: 431 passed, 0 failed
Leak check: clean (test suite)

=== All validation checks passed successfully! ===
```
