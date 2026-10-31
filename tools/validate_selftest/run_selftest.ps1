param(
    [string]$Godot = $env:GODOT,
    [switch]$Keep
)

# Self-test for tools/validate.ps1 leak detection (TLF-035).
# Copies the working tree (without .godot/.git) to a temp folder, renames config/name so the
# copy never touches the real project's user:// folder (and the player's saves), then runs
# validate.ps1 there once clean and once per planted fixture, checking the exit code and the
# expected lines. Fixtures live in ./fixtures as *.gd.txt so the real project never loads them.
# Exit code = number of scenarios that did not behave as expected.
$ErrorActionPreference = "Stop"

if (-not $Godot -or -not (Test-Path $Godot)) {
    Write-Error "Godot executable not found. Set GODOT or pass -Godot <path>."
    exit 1
}
$Godot = (Resolve-Path $Godot).Path
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Fixtures = Join-Path $PSScriptRoot "fixtures"
$Work = Join-Path ([System.IO.Path]::GetTempPath()) ("tlf_validate_selftest_{0}" -f [guid]::NewGuid().ToString("N"))

$Scenarios = @(
    @{ Name = "clean tree"; From = ""; To = ""; ExpectExit0 = $true
       Expect = @("Leak check: clean (script check)", "Leak check: clean (test suite)", "All validation checks passed") },
    @{ Name = "expected ERROR line only (negative-test style)"; ExpectExit0 = $true
       From = "test_zz_selftest_expected_error.gd.txt"; To = "tests\test_zz_selftest_expected_error.gd"
       Expect = @("Selftest: expected error", "Leak check: clean (test suite)", "All validation checks passed") },
    @{ Name = "test leaks a Node"; ExpectExit0 = $false
       From = "test_zz_selftest_leak_node.gd.txt"; To = "tests\test_zz_selftest_leak_node.gd"
       Expect = @("VALIDATION FAILED: test suite leaked at exit:", "ObjectDB instance", "Leaked instance") },
    @{ Name = "test leaks a resource"; ExpectExit0 = $false
       From = "test_zz_selftest_leak_resource.gd.txt"; To = "tests\test_zz_selftest_leak_resource.gd"
       Expect = @("VALIDATION FAILED: test suite leaked at exit:", "resources still in use at exit") },
    @{ Name = "test leaks a RID"; ExpectExit0 = $false
       From = "test_zz_selftest_leak_rid.gd.txt"; To = "tests\test_zz_selftest_leak_rid.gd"
       Expect = @("VALIDATION FAILED: test suite leaked at exit:", "RID allocations of type") },
    @{ Name = "script check leaks (static initializer)"; ExpectExit0 = $false
       From = "selftest_static_leak.gd.txt"; To = "selftest_fixture\selftest_static_leak.gd"
       Expect = @("VALIDATION FAILED: script check leaked at exit:", "ObjectDB instance") }
)

# Lines echoed from each run (the full output goes to a log file per scenario).
$Echo = "^\[\d/3\]|Script check:|Leak check|VALIDATION FAILED|leaked at exit|still in use at exit|^\s+Leaked instance|^\s+Resource still in use|^TESTS:|All validation|Selftest: expected"

Write-Host "=== validate.ps1 self-test ==="
Write-Host "Copying $RepoRoot -> $Work"
& robocopy $RepoRoot $Work /E /XD .godot .git /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { Write-Error "robocopy failed ($LASTEXITCODE)"; exit 1 }
$projectFile = Join-Path $Work "project.godot"
$project = [System.IO.File]::ReadAllText($projectFile)
$project = $project -replace '(?m)^config/name=.*$', 'config/name="TLF Validate Selftest"'
[System.IO.File]::WriteAllText($projectFile, $project, (New-Object System.Text.UTF8Encoding($false)))

$failures = 0
$index = 0
try {
    foreach ($scenario in $Scenarios) {
        $index++
        Write-Host "`n--- [$index/$($Scenarios.Count)] $($scenario.Name)"
        $planted = $null
        if ($scenario.From) {
            $planted = Join-Path $Work $scenario.To
            New-Item -ItemType Directory -Force (Split-Path -Parent $planted) | Out-Null
            Copy-Item (Join-Path $Fixtures $scenario.From) $planted
        }
        $log = Join-Path $Work ("selftest_{0}.log" -f $index)
        $prev = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Work "tools\validate.ps1") -Godot $Godot 2>&1 | ForEach-Object { "$_" }
            $code = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $prev
        }
        [System.IO.File]::WriteAllLines($log, [string[]]$out)
        $out | Where-Object { $_ -match $Echo } | ForEach-Object { Write-Host "    $_" }

        $ok = ($code -eq 0) -eq $scenario.ExpectExit0
        $missing = @($scenario.Expect | Where-Object { $needle = $_; -not ($out | Where-Object { $_.Contains($needle) }) })
        if ($missing.Count -gt 0) { $ok = $false }
        if ($ok) {
            Write-Host "  SELFTEST PASS: exit=$code as expected"
        } else {
            $failures++
            Write-Host "  SELFTEST FAIL: exit=$code (expected $(if ($scenario.ExpectExit0) { '0' } else { 'non-zero' })); missing lines: $($missing -join ' | ')"
            Write-Host "  full log: $log"
        }
        if ($planted) { Remove-Item -LiteralPath $planted -Force }
    }
} finally {
    if (-not $Keep -and $failures -eq 0) {
        Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "`nWork copy kept: $Work"
    }
}

Write-Host "`n=== validate.ps1 self-test: $($Scenarios.Count - $failures)/$($Scenarios.Count) scenarios as expected ==="
exit $failures
