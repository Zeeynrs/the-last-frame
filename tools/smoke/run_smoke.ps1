# TLF-060: export the Windows Desktop preset from a commit and smoke-test the exported builds.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\smoke\run_smoke.ps1 `
#       -Sha <commit> -WorkDir <new scratch folder> -Godot <editor dir>\Godot_v4.7.2-stable_win64_console.exe
#
# Needs the official 4.7.2 Windows templates (release and debug); the "templates" check fails if
# one is missing or is a copy of an editor binary. To use them without touching
# %APPDATA%\Godot\export_templates: copy both editor exes into a folder holding an empty ._sc_ file
# (self-contained mode), extract the templates from Godot_v4.7.2-stable_export_templates.tpz into
# <that folder>\editor_data\export_templates\4.7.2.stable\ and pass that folder's console exe.
#
# 1. git archive <commit> into <WorkDir>\project. Only config/name changes in the copy, so the
#    builds write to app_userdata\TLF Smoke <sha7> (release) and \TLF Smoke <sha7> debug, never to
#    the player's app_userdata\The Last Frame. Nothing runs in the repository checkout.
# 2. --export-release to build\windows\ (the artifact) and --export-debug to build\windows-debug\.
# 3. Release build, played from outside with keys posted to its window (window_input.ps1; the
#    focus stays where it is) and window screenshots. release_plain ends through the game's Quit
#    menu item, every other run with WM_CLOSE (the window's X button):
#      release_plain     8 s on the title screen, then S (to Quit) and Enter: the game exits by
#                        itself.
#    The selected title row is read from the screenshot (yellow), and keys that must change the
#    screen are re-sent (at most 3 times, logged) if a posted key was lost.
#      release_new       Enter = New Game, E (Beat 01 / pocket watch), walk, back into the arrival
#                        checkpoint -> slot_0.json on disk with ch01.cp.arrival and the watch flag.
#      release_continue  Enter = Continue, walk out of and back into the checkpoint -> slot_0.json
#                        rewritten during this run, still with the watch flag.
#    Official templates (release and debug) have no -s, so the in-game checks run on the exported
#    debug PCK with the official editor binary (--main-pack <pck> -s <driver>):
#      pck_new / pck_continue   smoke_export_driver.gd: font, translation keys, flags, save and
#                        restore checked inside the game.
# 4. The player's saves\ and settings.cfg are listed (read only) before and after and must be
#    unchanged (its logs\ change whenever the editor runs, so they are not compared). If they
#    changed while the player's own game ran (e.g. F5 in the editor), the check passes only when
#    the player's save is not at ch01.cp.arrival, the one checkpoint the smoke reaches.
# Exit code 0 only if every step passed. Evidence lands in <WorkDir>\evidence.
param(
    [Parameter(Mandatory = $true)] [string]$Sha,
    [Parameter(Mandatory = $true)] [string]$WorkDir,
    [string]$Godot = $env:GODOT,
    [int]$TimeoutSec = 180
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'window_input.ps1')
$repo = (git rev-parse --show-toplevel).Trim()
$full = (git rev-parse --verify "$Sha^{commit}").Trim()
$short = $full.Substring(0, 7)
$names = @{ release = "TLF Smoke $short"; debug = "TLF Smoke $short debug" }
$appData = Join-Path $env:APPDATA 'Godot\app_userdata'
$realDir = Join-Path $appData 'The Last Frame'
$userDirs = @{ release = (Join-Path $appData $names.release); debug = (Join-Path $appData $names.debug) }
$results = [ordered]@{}

if (-not $Godot -or -not (Test-Path $Godot)) { throw "Godot executable not found: '$Godot' (pass -Godot)" }
if (Test-Path $WorkDir) { throw "WorkDir must not exist yet: $WorkDir" }
foreach ($dir in $userDirs.Values) {
    if (Test-Path $dir) { throw "Smoke user dir already exists (use a new commit or remove it yourself): $dir" }
}
$WorkDir = (New-Item -ItemType Directory -Path $WorkDir).FullName
$project = Join-Path $WorkDir 'project'
$evidence = New-Item -ItemType Directory -Path (Join-Path $WorkDir 'evidence')
$shots = New-Item -ItemType Directory -Path (Join-Path $evidence 'screenshots')
$exe = @{ release = (Join-Path $project 'build\windows\TheLastFrame.exe'); debug = (Join-Path $project 'build\windows-debug\TheLastFrame.exe') }

## Godot processes that are not this smoke's: the editor, a game run from the editor, other probes.
## A change in the player's folder while one of them runs is theirs to explain, not ours to excuse.
function Foreign-Godot() {
    @(Get-CimInstance Win32_Process | Where-Object {
        ($_.Name -like 'Godot*' -or $_.Name -like 'TheLastFrame*') -and $_.CommandLine -notlike "*$project*" -and $_.ExecutablePath -notlike "$project*"
    } | ForEach-Object { "pid $($_.ProcessId) started $($_.CreationDate.ToString('HH:mm:ss')): $($_.CommandLine)" })
}

function Say([string]$line) { Write-Host $line; Add-Content -Path (Join-Path $evidence 'summary.txt') -Value $line }

## Lists `dir` (read only): hash prefix, size, write time, relative path. With `only`, just those
## entries (files or folders) under `dir`. Files another process holds open hash as "(locked)".
function Snapshot([string]$dir, [string[]]$only = @()) {
    if (-not (Test-Path $dir)) { return @("(missing) $dir") }
    $roots = if ($only.Count -gt 0) { $only | ForEach-Object { Join-Path $dir $_ } | Where-Object { Test-Path $_ } } else { @($dir) }
    $lines = @($roots | ForEach-Object { Get-ChildItem -Path $_ -Recurse -File -Force } | Sort-Object FullName | ForEach-Object {
        $hash = try { (Get-FileHash $_.FullName -Algorithm SHA256 -ErrorAction Stop).Hash.Substring(0, 16) } catch { '(locked)        ' }
        "{0}  {1,9}  {2:yyyy-MM-dd HH:mm:ss.fff}  {3}" -f $hash, $_.Length, $_.LastWriteTime, $_.FullName.Substring($dir.Length + 1)
    })
    if ($lines.Count -eq 0) { return @("(no files) $($only -join ', ')") }
    return $lines
}

function Set-ProjectName([string]$name) {
    $file = Join-Path $project 'project.godot'
    $text = [IO.File]::ReadAllText($file) -replace 'config/name="[^"]*"', "config/name=`"$name`""
    [IO.File]::WriteAllText($file, $text, (New-Object Text.UTF8Encoding $false))
}

Say "TLF-060 smoke  commit $full"
Say "Godot $Godot"
Say "work dir $WorkDir"

# --- 1. exact tree --------------------------------------------------------------------------
New-Item -ItemType Directory -Path $project | Out-Null
$tar = Join-Path $WorkDir 'tree.tar'
git -C $repo archive --format=tar -o $tar $full
tar -xf $tar -C $project
Remove-Item $tar
$godotFile = Join-Path $project 'project.godot'
$original = [IO.File]::ReadAllText($godotFile)
if ($original -notmatch 'config/name="The Last Frame"') { throw 'config/name="The Last Frame" not found in project.godot' }
Set-ProjectName $names.release
$changed = Compare-Object ($original -split "`n") ([IO.File]::ReadAllText($godotFile) -split "`n") | ForEach-Object { "  $($_.SideIndicator) $($_.InputObject.TrimEnd())" }
Say "project.godot changes in the copy (only config/name may change; the debug export uses '$($names.debug)'):"
$changed | ForEach-Object { Say $_ }
$results['tree'] = ($changed.Count -eq 2)

$foreignBefore = Foreign-Godot
Say "other Godot processes before: $($foreignBefore.Count)"
$foreignBefore | ForEach-Object { Say "  $_" }
$realBefore = Snapshot $realDir @('saves', 'settings.cfg')
$realBefore | Set-Content -Path (Join-Path $evidence 'real_save_folder_before.txt') -Encoding utf8
Say "real save folder before: $($realBefore.Count) file(s)"

# --- 2. templates, import, export -----------------------------------------------------------
# The editor reads templates from <editor dir>\editor_data when a _sc_ / ._sc_ file sits next to it
# (self-contained mode), else from %APPDATA%\Godot. The console exe is a wrapper for the GUI exe.
$editorExe = $Godot -replace '_console\.exe$', '.exe'
$editorDir = Split-Path $editorExe
$selfContained = (Test-Path (Join-Path $editorDir '_sc_')) -or (Test-Path (Join-Path $editorDir '._sc_'))
$templateRoot = if ($selfContained) { Join-Path $editorDir 'editor_data\export_templates' } else { Join-Path $env:APPDATA 'Godot\export_templates' }
$editorHashes = @((Get-FileHash $editorExe -Algorithm SHA256).Hash, (Get-FileHash $Godot -Algorithm SHA256).Hash)
$results['templates'] = $true
foreach ($kind in 'release', 'debug') {
    $template = Join-Path $templateRoot "4.7.2.stable\windows_$($kind)_x86_64.exe"
    $hash = if (Test-Path $template) { (Get-FileHash $template -Algorithm SHA256).Hash } else { 'missing' }
    $ok = ($hash -ne 'missing' -and $editorHashes -notcontains $hash)
    Say "$kind template $template"
    Say "  sha256 $hash$(if (-not $ok) { '  NOT A TEMPLATE: missing or a copy of an editor binary' })"
    $results['templates'] = $results['templates'] -and $ok
}
Say "  (editor sha256 $($editorHashes[0]), console $($editorHashes[1]))"

& $Godot --headless --path $project --import *> (Join-Path $evidence 'import.log')
Say "import exit $LASTEXITCODE"
foreach ($kind in 'release', 'debug') {
    Set-ProjectName $names[$kind]
    New-Item -ItemType Directory -Path (Split-Path $exe[$kind]) | Out-Null
    & $Godot --headless --path $project "--export-$kind" 'Windows Desktop' $exe[$kind] *> (Join-Path $evidence "export_$kind.log")
    $code = $LASTEXITCODE
    Say "export $kind exit $code"
    Get-ChildItem (Split-Path $exe[$kind]) | ForEach-Object {
        Say ("  {0,-16} {1,-28} {2,11} bytes  sha256 {3}" -f $kind, $_.Name, $_.Length, (Get-FileHash $_.FullName -Algorithm SHA256).Hash)
    }
    $results["export_$kind"] = ($code -eq 0 -and (Test-Path $exe[$kind]) -and (Test-Path ([IO.Path]::ChangeExtension($exe[$kind], '.pck'))))
}
Set-ProjectName $names.release
if (-not ($results['export_release'] -and $results['export_debug'])) { Say 'EXPORT FAILED'; exit 2 }

# --- 3. runs --------------------------------------------------------------------------------

## Starts a build, calls `$play` (with the process and its window) once the window is up, then
## closes the window with WM_CLOSE (the X button). `$play` returns $true when the run may be
## closed, or 'quit' when its input should have made the game exit by itself.
function Run-Build([string]$name, [string]$exePath, [string[]]$arguments, [scriptblock]$play) {
    $out = Join-Path $evidence "run_$name.stdout.log"
    $err = Join-Path $evidence "run_$name.stderr.log"
    $start = Get-Date
    $launch = @{ FilePath = $exePath; WorkingDirectory = $WorkDir; PassThru = $true
                 RedirectStandardOutput = $out; RedirectStandardError = $err }
    if ($arguments.Count -gt 0) { $launch['ArgumentList'] = $arguments }
    $p = Start-Process @launch
    $null = $p.Handle   # keeps the handle so ExitCode is available after exit
    $hwnd = [IntPtr]::Zero
    while ($hwnd -eq [IntPtr]::Zero -and ((Get-Date) - $start).TotalSeconds -lt 30 -and -not $p.HasExited) {
        Start-Sleep -Milliseconds 250
        $p.Refresh()
        $hwnd = $p.MainWindowHandle
    }
    $state = 'no window'
    if ($hwnd -ne [IntPtr]::Zero) {
        $answer = & $play $p $hwnd $start $out
        # A string test first: in PowerShell `$true -eq 'quit'` is true.
        $state = if ($answer -is [string] -and $answer -eq 'quit') { 'quit' } elseif ($answer -eq $true) { 'ready' } elseif ($p.HasExited) { 'exited by itself' } else { 'timeout' }
    }
    if ($state -eq 'quit') {
        $state = if ($p.WaitForExit(20000)) { 'exited through the Quit menu item' } else { 'still running after Quit' }
    } elseif ($state -eq 'ready') {
        $closed = $p.CloseMainWindow()
        $state = if ($p.WaitForExit(20000)) { "closed with WM_CLOSE (sent=$closed)" } else { 'did not exit after WM_CLOSE' }
    }
    if (-not $p.HasExited) { $p.Kill() }
    $p.WaitForExit()
    $code = $p.ExitCode
    $seconds = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
    $text = "$(Get-Content $out -Raw -ErrorAction SilentlyContinue)"
    $errors = ([regex]::Matches("$text`n$(Get-Content $err -Raw -ErrorAction SilentlyContinue)", 'SCRIPT ERROR|ERROR:')).Count
    Say ("run {0,-17} {1}, exit code {2}, {3} s, {4} ERROR line(s)" -f $name, $state, $code, $seconds, $errors)
    $ended = $state -like 'closed*' -or $state -like 'exited through*'
    return [pscustomobject]@{ Ok = ($ended -and $code -eq 0 -and $errors -eq 0); Text = $text }
}

function Shot([IntPtr]$hwnd, [string]$name, [double]$minLit) {
    $path = Join-Path $shots "$name.png"
    $lit = [TlfWindowInput]::Capture($hwnd, $path)
    $ok = $lit -ge $minLit
    Say ("  screenshot {0}.png  lit {1:P1} (min {2:P1}) {3}" -f $name, $lit, $minLit, $(if ($ok) { 'ok' } else { 'FAIL' }))
    return $ok
}

## Title menu rows as bands of the window height; the selected row is drawn in yellow.
$MenuRows = [ordered]@{ new_game = @(0.46, 0.515); continue = @(0.53, 0.58); quit = @(0.60, 0.645) }

function Selected-Row([string]$png) {
    $rows = @($MenuRows.Keys | Where-Object { [TlfWindowInput]::YellowShare($png, $MenuRows[$_][0], $MenuRows[$_][1]) -gt 0.02 })
    if ($rows.Count -eq 1) { return $rows[0] }
    return "none/several ($($rows -join ','))"
}

## A capture of the window that is not kept as evidence (polling between key presses).
function Probe([IntPtr]$hwnd) {
    $path = Join-Path $WorkDir 'probe.png'
    $lit = [TlfWindowInput]::Capture($hwnd, $path)
    return [pscustomobject]@{ Path = $path; Lit = $lit }
}

## Posted keys can get lost (seen once in 7 runs), so a key that must change the screen is pressed
## until `$done` holds, at most 3 times, and every resend is logged.
function Press-Until([IntPtr]$hwnd, [string]$key, [scriptblock]$done, [int]$waitMs, [string]$what) {
    for ($try = 1; $try -le 3; $try++) {
        Send-TlfKey $hwnd $key
        $deadline = (Get-Date).AddMilliseconds($waitMs)
        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 250
            if (& $done) {
                Say ("  {0}: {1} press(es) of {2}{3}" -f $what, $try, $key, $(if ($try -gt 1) { ' (an earlier press was lost)' } else { '' }))
                return $true
            }
        }
    }
    Say "  ${what}: no effect after 3 presses of $key"
    return $false
}

## slot_0.json of the release user dir: write time and whether it holds the checkpoint and the flag.
function Release-Save() {
    $file = Join-Path $userDirs.release 'saves\slot_0.json'
    if (-not (Test-Path $file)) { return [pscustomobject]@{ Exists = $false; Time = [datetime]::MinValue; Arrival = $false; Watch = $false } }
    $text = [IO.File]::ReadAllText($file)
    $item = Get-Item $file
    # SaveStore writes JSON.from_native: strings carry an "s:" prefix, a Dictionary is key, value, ...
    $arrival = $text -match '"s:checkpoint_id",\s*"s:ch01\.cp\.arrival"'
    $watch = $text -match '"s:ch01\.flag\.pocket_watch_acquired",\s*true'
    $info = [pscustomobject]@{ Exists = $true; Time = $item.LastWriteTime; Arrival = [bool]$arrival; Watch = [bool]$watch }
    Say ("  save {0}  {1} bytes  written {2:HH:mm:ss.fff}  checkpoint ch01.cp.arrival={3}  watch flag={4}" -f $file, $item.Length, $item.LastWriteTime, $info.Arrival, $info.Watch)
    return $info
}

## The walk both release runs use, from the spawn (inside the arrival checkpoint, 28 x 16): short
## there-and-back pairs onto open floor (W first would hit the bench north of the spawn), then out
## of the checkpoint and straight back in, which writes the autosave. About 4 s of held keys.
function Walk-Platform([IntPtr]$hwnd) {
    foreach ($pair in @(@('A', 'D', 400), @('S', 'W', 300), @('D', 'A', 400), @('A', 'D', 450))) {
        Hold-TlfKeys $hwnd @($pair[0]) $pair[2]
        Start-Sleep -Milliseconds 250
        Hold-TlfKeys $hwnd @($pair[1]) $pair[2]
        Start-Sleep -Milliseconds 250
    }
    Start-Sleep -Milliseconds 1500
}

$checks = [ordered]@{}

$plain = Run-Build 'release_plain' $exe.release @() {
    param($p, $hwnd, $start, $out)
    Start-Sleep -Seconds 8
    $checks['plain: title drawn'] = Shot $hwnd 'release_plain_01_title' 0.005
    $checks['plain: New Game selected (no save yet)'] = (Selected-Row (Join-Path $shots 'release_plain_01_title.png')) -eq 'new_game'
    # S: New Game -> Quit (Continue is disabled without a save and skipped).
    $checks['plain: S selects Quit'] = Press-Until $hwnd 'S' { (Selected-Row (Probe $hwnd).Path) -eq 'quit' } 1500 'plain: S to Quit'
    $null = Shot $hwnd 'release_plain_02_quit_selected' 0.005
    if (-not $checks['plain: S selects Quit']) { return $true }   # never Enter on another item
    $checks['plain: Enter on Quit ends the game'] = Press-Until $hwnd 'Enter' { $p.HasExited } 5000 'plain: Enter on Quit'
    return 'quit'
}
$results['release_plain'] = $plain.Ok

$new = Run-Build 'release_new' $exe.release @() {
    param($p, $hwnd, $start, $out)
    Start-Sleep -Seconds 4
    $checks['new: title drawn'] = Shot $hwnd 'release_new_01_title' 0.005
    $checks['new: New Game selected (no save yet)'] = (Selected-Row (Join-Path $shots 'release_new_01_title.png')) -eq 'new_game'
    if (-not $checks['new: New Game selected (no save yet)']) { return $true }
    $checks['new: Enter starts chapter 1'] = Press-Until $hwnd 'Enter' { (Probe $hwnd).Lit -ge 0.3 } 6000 'new: Enter on New Game'
    Start-Sleep -Seconds 2
    $checks['new: chapter 1 drawn'] = Shot $hwnd 'release_new_02_chapter1' 0.3
    # E advances Beat 01 if it blocks and picks up the pocket watch (the interact target at the spawn).
    for ($i = 0; $i -lt 5; $i++) { Send-TlfKey $hwnd 'E'; Start-Sleep -Milliseconds 600 }
    $checks['new: after E'] = Shot $hwnd 'release_new_03_watch' 0.3
    Walk-Platform $hwnd
    $checks['new: after the walk'] = Shot $hwnd 'release_new_04_checkpoint' 0.3
    $save = Release-Save
    $checks['new: slot_0.json at ch01.cp.arrival with the watch flag'] = $save.Exists -and $save.Arrival -and $save.Watch
    return -not $p.HasExited
}
$results['release_new'] = $new.Ok

$saveBefore = Release-Save
$cont = Run-Build 'release_continue' $exe.release @() {
    param($p, $hwnd, $start, $out)
    Start-Sleep -Seconds 4
    $checks['continue: title drawn'] = Shot $hwnd 'release_continue_01_title' 0.005
    $checks['continue: Continue selected (save found)'] = (Selected-Row (Join-Path $shots 'release_continue_01_title.png')) -eq 'continue'
    if (-not $checks['continue: Continue selected (save found)']) { return $true }
    $checks['continue: Enter loads chapter 1'] = Press-Until $hwnd 'Enter' { (Probe $hwnd).Lit -ge 0.3 } 6000 'continue: Enter on Continue'
    Start-Sleep -Seconds 2
    $checks['continue: chapter 1 drawn'] = Shot $hwnd 'release_continue_02_chapter1' 0.3
    Walk-Platform $hwnd
    $checks['continue: after the walk'] = Shot $hwnd 'release_continue_03_checkpoint' 0.3
    $save = Release-Save
    $checks['continue: slot_0.json rewritten in this run, still with the watch flag'] = $save.Exists -and $save.Time -gt $saveBefore.Time -and $save.Arrival -and $save.Watch
    return -not $p.HasExited
}
$results['release_continue'] = $cont.Ok
$checks.GetEnumerator() | ForEach-Object { Say ("  check {0,-72} {1}" -f $_.Key, $(if ($_.Value) { 'ok' } else { 'FAIL' })) }
$results['release_checks'] = -not ($checks.Values -contains $false)

$driver = Join-Path $project 'tools\smoke\smoke_export_driver.gd'
$driverReady = {
    param($p, $hwnd, $start, $out)
    while (((Get-Date) - $start).TotalSeconds -lt $TimeoutSec -and -not $p.HasExited) {
        Start-Sleep -Milliseconds 250
        if ("$(Get-Content $out -Raw -ErrorAction SilentlyContinue)" -match 'SMOKE READY_TO_CLOSE') { return $true }
    }
    return $false
}
$pck = [IO.Path]::ChangeExtension($exe.debug, '.pck')
$pckNew = Run-Build 'pck_new' $editorExe @('--main-pack', "`"$pck`"", '-s', "`"$driver`"", '--', '--phase=new', "`"--out=$shots`"") $driverReady
$results['pck_new'] = $pckNew.Ok -and $pckNew.Text -match 'SMOKE PASS phase=new'
$pckCont = Run-Build 'pck_continue' $editorExe @('--main-pack', "`"$pck`"", '-s', "`"$driver`"", '--', '--phase=continue', "`"--out=$shots`"") $driverReady
$results['pck_continue'] = $pckCont.Ok -and $pckCont.Text -match 'SMOKE PASS phase=continue'

# --- 4. user folders ------------------------------------------------------------------------
foreach ($kind in 'release', 'debug') {
    $files = Snapshot $userDirs[$kind] | Where-Object { $_ -notmatch 'shader_cache' }
    $files | Set-Content -Path (Join-Path $evidence "user_dir_$kind.txt") -Encoding utf8
    Say "$kind user dir $($userDirs[$kind]) (shader_cache not listed)"
    $files | ForEach-Object { Say "  $_" }
    $logs = Join-Path $userDirs[$kind] 'logs'
    if (Test-Path $logs) { Copy-Item $logs (Join-Path $evidence "user_logs_$kind") -Recurse }
    $results["save_in_$($kind)_user_dir"] = Test-Path (Join-Path $userDirs[$kind] 'saves\slot_0.json')
}

$realAfter = Snapshot $realDir @('saves', 'settings.cfg')
$realAfter | Set-Content -Path (Join-Path $evidence 'real_save_folder_after.txt') -Encoding utf8
$foreignAfter = Foreign-Godot
Say "other Godot processes after: $($foreignAfter.Count)"
$foreignAfter | ForEach-Object { Say "  $_" }
$realDiff = Compare-Object $realBefore $realAfter
Say "real save folder after: $($realAfter.Count) file(s), $(if ($null -eq $realDiff) { 'UNCHANGED' } else { 'CHANGED' })"
$realDiff | ForEach-Object { Say "  $($_.SideIndicator) $($_.InputObject)" }
if ($null -eq $realDiff) {
    $results['real_folder_untouched'] = $true
} else {
    # Not ours only if a game outside this smoke ran (a run from the editor: --editor-pid; not
    # headless) and the player's save is not at the one checkpoint the smoke reaches.
    $games = @($foreignBefore + $foreignAfter | Where-Object { $_ -notmatch '--headless' -and ($_ -match '--editor-pid' -or $_ -notmatch '--editor') } | Sort-Object -Unique)
    $realSave = Join-Path $realDir 'saves\slot_0.json'
    $checkpoints = @(if (Test-Path $realSave) { [regex]::Matches([IO.File]::ReadAllText($realSave), 'ch01\.cp\.[a-z_]+') | ForEach-Object { $_.Value } | Sort-Object -Unique })
    Say "  the player's save now holds checkpoint(s): $($checkpoints -join ', '); the smoke only reaches ch01.cp.arrival"
    Say "  other game processes during the smoke: $($games.Count)"
    $results['real_folder_untouched'] = ($games.Count -gt 0 -and $checkpoints.Count -gt 0 -and -not ($checkpoints -contains 'ch01.cp.arrival'))
    if ($results['real_folder_untouched']) { Say '  -> changed by the other game process, not by the smoke builds' }
}

Get-ChildItem $shots | ForEach-Object { Say "  screenshot file $($_.Name) $($_.Length) bytes" }
$results.GetEnumerator() | ForEach-Object { Say ("RESULT {0,-24} {1}" -f $_.Key, $(if ($_.Value) { 'PASS' } else { 'FAIL' })) }
if ($results.Values -contains $false) { Say 'SMOKE: FAILED'; exit 1 }
Say 'SMOKE: ALL PASSED'
exit 0
