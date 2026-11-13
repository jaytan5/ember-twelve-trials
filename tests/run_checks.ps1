param([switch]$Rendered)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$enginePath = Join-Path (Split-Path -Parent $projectRoot) 'Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) { throw "Godot engine missing: $enginePath" }
$testOutput = Join-Path $projectRoot 'test-results'
$testRoaming = Join-Path $projectRoot '.test_profile\Roaming'
$testLocal = Join-Path $projectRoot '.test_profile\Local'
New-Item -ItemType Directory -Force $testOutput,$testRoaming,$testLocal | Out-Null
$previousAppData = $env:APPDATA
$previousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $testRoaming
    $env:LOCALAPPDATA = $testLocal
    foreach ($testScript in @('test_rules','test_combat_revision','test_relic_retry','test_balance_nov10','test_card_expansion_nov12','test_hand_interaction','ui_smoke','ui_feedback','test_talent_ui','test_settings_cursor','ui_card_expansion_nov12','test_adventure_map_art','test_card_art')) {
        $logPath = Join-Path $testOutput ($testScript + '.log')
        $engineArgs = @('--path',$projectRoot,'--script',"res://tests/$testScript.gd",'--log-file',$logPath,'--audio-driver','Dummy')
        if (-not $Rendered -or $testScript -notin @('test_hand_interaction','ui_smoke','ui_feedback','test_talent_ui','test_settings_cursor','ui_card_expansion_nov12','test_adventure_map_art','test_card_art')) { $engineArgs += '--headless' }
        & $enginePath @engineArgs
        if ($LASTEXITCODE -ne 0) { throw "$testScript failed ($LASTEXITCODE)" }
        $content = Get-Content -LiteralPath $logPath -Raw
        if ($content -match 'SCRIPT ERROR|FAIL:|OVERFLOW:|Parse Error') { throw "$testScript logged a failure" }
        $unexpectedErrors = Get-Content -LiteralPath $logPath | Where-Object { $_ -match '^ERROR:' -and $_ -notmatch 'Failed to read the root certificate store' }
        if ($unexpectedErrors) { throw "$testScript logged an engine error: $unexpectedErrors" }
    }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalData
}
