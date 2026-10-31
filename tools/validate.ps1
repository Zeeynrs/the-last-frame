param(
    [string]$Godot = $env:GODOT
)

$ErrorActionPreference = "Stop"

if (-not $Godot) {
    if (Test-Path "D:\Godot\Godot_v4.7.2-stable_win64_console.exe") {
        $Godot = "D:\Godot\Godot_v4.7.2-stable_win64_console.exe"
    } else {
        Write-Error "Godot executable not found. Specify -Godot <path> or set `$env:GODOT."
        exit 1
    }
}

Write-Host "=== Validating The Last Frame Project ==="
Write-Host "Using Godot executable: $Godot"

# Step 1: Headless import check
Write-Host "`n[1/2] Running headless import check..."
$importOutput = & $Godot --headless --path . --import 2>&1
$importExitCode = $LASTEXITCODE

$importOutput | ForEach-Object { Write-Host $_ }

if ($importExitCode -ne 0) {
    Write-Error "Import failed with exit code $importExitCode"
    exit $importExitCode
}

# Check for ERROR lines in import output
$errorLines = $importOutput | Where-Object { $_ -match "^ERROR:" }
if ($errorLines) {
    Write-Error "Import check failed: ERROR lines detected in output.`n$errorLines"
    exit 1
}

Write-Host "Import check passed with zero errors."

# Step 2: Headless test runner
Write-Host "`n[2/2] Running headless automated test suite..."
& $Godot --headless --path . -s res://tests/run_tests.gd
$testExitCode = $LASTEXITCODE

if ($testExitCode -ne 0) {
    Write-Error "Test suite failed with exit code $testExitCode"
    exit $testExitCode
}

Write-Host "`n=== All validation checks passed successfully! ==="
exit 0
