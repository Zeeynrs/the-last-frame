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
function Invoke-Godot([string[]]$Arguments) {
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
        Write-Host $line
        $lines.Add($line)
    }
    $process.WaitForExit()
    return @{ ExitCode = $process.ExitCode; Lines = $lines }
}

function Get-ErrorLines($Lines) {
    # Godot may colour its output; strip ANSI escapes before matching line starts.
    return @($Lines | Where-Object { ($_ -replace "\x1b\[[0-9;]*m", "") -match "^(SCRIPT )?ERROR:" })
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
    $check = Invoke-Godot @("--headless", "-s", "`"$checkerPath`"")
} finally {
    Remove-Item -LiteralPath $checkerPath -Force -ErrorAction SilentlyContinue
}

$errorLines = Get-ErrorLines $check.Lines
if ($check.ExitCode -ne 0 -or $errorLines.Count -gt 0) {
    Write-Host "`nVALIDATION FAILED: script check exited with code $($check.ExitCode) and printed $($errorLines.Count) ERROR line(s):"
    $errorLines | ForEach-Object { Write-Host "  $_" }
    exit 1
}

# Step 3: Headless test runner (exit code = failure count; tests may log expected ERROR: lines)
Write-Host "`n[3/3] Running headless automated test suite..."
$tests = Invoke-Godot @("--headless", "-s", "res://tests/run_tests.gd")

if ($tests.ExitCode -ne 0) {
    Write-Host "`nVALIDATION FAILED: test suite exited with code $($tests.ExitCode)."
    exit $(if ($tests.ExitCode -gt 0) { $tests.ExitCode } else { 1 })
}

Write-Host "`n=== All validation checks passed successfully! ==="
exit 0
