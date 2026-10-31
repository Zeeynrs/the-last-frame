param(
    [string]$Godot = $env:GODOT
)

# Pass/fail comes only from Godot's exit codes and ERROR: lines in its output (TLF-028).
# Godot runs under cmd.exe, which merges stderr into stdout at the OS level, so PowerShell
# never sees native stderr and cannot turn it into NativeCommandError (Windows PowerShell 5.1).
# cmd.exe also waits for the GUI build, which PowerShell's call operator does not.
$ErrorActionPreference = "Stop"

if (-not $Godot) {
    Write-Error "Godot executable not specified. Please set the GODOT environment variable or pass -Godot <path>."
    exit 1
}

if (-not (Test-Path $Godot)) {
    Write-Error "Godot executable not found at specified path: $Godot"
    exit 1
}

$Godot = (Resolve-Path $Godot).Path
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# Runs Godot with the given arguments, echoes every output line as it arrives and returns
# @{ ExitCode; Lines }.
function Invoke-Godot([string[]]$Arguments, [switch]$Quiet) {
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $env:ComSpec
    $info.Arguments = '/d /s /c ""{0}" --path "{1}" {2} 2>&1"' -f $Godot, $ProjectRoot, ($Arguments -join ' ')
    $info.WorkingDirectory = $ProjectRoot
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.StandardOutputEncoding = New-Object System.Text.UTF8Encoding($false)

    $process = [System.Diagnostics.Process]::Start($info)
    $lines = New-Object System.Collections.Generic.List[string]
    while ($null -ne ($line = $process.StandardOutput.ReadLine())) {
        if (-not $Quiet) { Write-Host $line }
        $lines.Add($line)
    }
    $process.WaitForExit()
    return @{ ExitCode = $process.ExitCode; Lines = $lines }
}

function Get-ErrorLines($Lines) {
    # Godot may colour its output; strip ANSI escapes before matching line starts.
    return @($Lines | Where-Object { ($_ -replace "\x1b\[[0-9;]*m", "") -match "^(SCRIPT )?ERROR:" })
}

# Leak messages Godot prints at exit (verified on 4.7.2, TLF-035), e.g.
#   WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
#   ERROR: 2 resources still in use at exit (run with --verbose for details).
#   ERROR: 1 RID allocations of type 'P11GodotBody2D' were leaked at exit.
# Matched on the message text, not the WARNING:/ERROR: prefix, so the ERROR: lines that negative
# tests log on purpose never count. ("Orphan StringName" only appears with --verbose.)
$LeakPattern = "leaked at exit|still in use at exit"

function Get-LeakLines($Lines) {
    return @($Lines | Where-Object { ($_ -replace "\x1b\[[0-9;]*m", "") -match $LeakPattern })
}

# Fails the step if Godot reported leaks at exit; reruns it with --verbose to show what leaked.
function Assert-NoLeaks([string]$Step, $Result, [string[]]$Arguments) {
    $leakLines = Get-LeakLines $Result.Lines
    if ($leakLines.Count -eq 0) {
        Write-Host "Leak check: clean ($Step)"
        return
    }
    Write-Host "`nVALIDATION FAILED: $Step leaked at exit:"
    $leakLines | ForEach-Object { Write-Host "  $_" }
    Write-Host "`nRe-running $Step with --verbose for leak details..."
    $verbose = Invoke-Godot (@("--verbose") + $Arguments) -Quiet
    $details = @($verbose.Lines | Where-Object {
        ($_ -replace "\x1b\[[0-9;]*m", "") -match "^(Leaked instance|Resource still in use|Orphan StringName)|$LeakPattern"
    })
    $details | Select-Object -First 40 | ForEach-Object { Write-Host "  $_" }
    if ($details.Count -gt 40) { Write-Host "  ... ($($details.Count - 40) more)" }
    exit 1
}

Write-Host "=== Validating The Last Frame Project ==="
Write-Host "Using Godot executable: $Godot"
Write-Host "Project root: $ProjectRoot"

# Step 1: Headless import check
Write-Host "`n[1/3] Running headless import check..."
$import = Invoke-Godot @("--headless", "--import")

if ($import.ExitCode -ne 0) {
    Write-Host "`nVALIDATION FAILED: import exited with code $($import.ExitCode)."
    exit $(if ($import.ExitCode -gt 0) { $import.ExitCode } else { 1 })
}

$errorLines = Get-ErrorLines $import.Lines
if ($errorLines.Count -gt 0) {
    Write-Host "`nVALIDATION FAILED: import printed $($errorLines.Count) ERROR line(s):"
    $errorLines | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "Import check passed with zero errors."

# Step 2: Script parse check. --import does not compile GDScript, so a parse error would only
# surface (or hang) inside the test runner. A throwaway checker outside the project loads
# every res:// script once; nothing is written into the repository.
Write-Host "`n[2/3] Checking that every GDScript parses..."
$checker = @'
extends SceneTree

func _init() -> void:
	var files: Array[String] = []
	_collect("res://", files)
	var bad := 0
	for path in files:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			bad += 1
			printerr("ERROR: script does not compile: %s" % path)
	print("Script check: %d scripts, %d failed." % [files.size(), bad])
	quit(1 if bad > 0 else 0)

func _collect(dir_path: String, out: Array[String]) -> void:
	for d in DirAccess.get_directories_at(dir_path):
		if not d.begins_with("."):
			_collect(dir_path.path_join(d), out)
	for f in DirAccess.get_files_at(dir_path):
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
'@
$checkerPath = Join-Path ([System.IO.Path]::GetTempPath()) ("tlf_validate_check_{0}.gd" -f [guid]::NewGuid().ToString("N"))
[System.IO.File]::WriteAllText($checkerPath, $checker, (New-Object System.Text.UTF8Encoding($false)))
try {
    $checkArgs = @("--headless", "-s", "`"$checkerPath`"")
    $check = Invoke-Godot $checkArgs

    $errorLines = Get-ErrorLines $check.Lines
    if ($check.ExitCode -ne 0 -or $errorLines.Count -gt 0) {
        Write-Host "`nVALIDATION FAILED: script check exited with code $($check.ExitCode) and printed $($errorLines.Count) ERROR line(s):"
        $errorLines | ForEach-Object { Write-Host "  $_" }
        exit 1
    }
    Assert-NoLeaks "script check" $check $checkArgs
} finally {
    Remove-Item -LiteralPath $checkerPath -Force -ErrorAction SilentlyContinue
}

# Step 3: Headless test runner (exit code = failure count; tests may log expected ERROR: lines)
Write-Host "`n[3/3] Running headless automated test suite..."
$testArgs = @("--headless", "-s", "res://tests/run_tests.gd")
$tests = Invoke-Godot $testArgs

if ($tests.ExitCode -ne 0) {
    Write-Host "`nVALIDATION FAILED: test suite exited with code $($tests.ExitCode)."
    $leakLines = Get-LeakLines $tests.Lines
    if ($leakLines.Count -gt 0) {
        Write-Host "The test suite also leaked at exit:"
        $leakLines | ForEach-Object { Write-Host "  $_" }
    }
    exit $(if ($tests.ExitCode -gt 0) { $tests.ExitCode } else { 1 })
}
Assert-NoLeaks "test suite" $tests $testArgs

Write-Host "`n=== All validation checks passed successfully! ==="
exit 0
