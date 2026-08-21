param(
    [switch]$Ci
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoUrl = 'https://github.com/alsdmlals4-eng/Tetris.git'
$Branch = if ($env:POC_VALIDATION_BRANCH) { $env:POC_VALIDATION_BRANCH } else { 'impl/core-dual-board-poc' }
$GodotVersion = '4.7.1'
$GodotTag = '4.7.1-stable'
$GutVersion = '9.7.1'
$GodotArchiveName = "Godot_v$GodotVersion-stable_win64.exe.zip"
$GodotExeName = "Godot_v$GodotVersion-stable_win64.exe"
$GodotConsoleExeName = "Godot_v$GodotVersion-stable_win64_console.exe"
$GodotUrl = "https://github.com/godotengine/godot/releases/download/$GodotTag/$GodotArchiveName"
$GutUrl = "https://github.com/bitwes/Gut/archive/refs/tags/v$GutVersion.zip"

$Root = if ($env:POC_VALIDATION_ROOT) {
    [System.IO.Path]::GetFullPath($env:POC_VALIDATION_ROOT)
} else {
    Join-Path $env:LOCALAPPDATA 'TetrisCorePocValidation'
}
$ProjectDir = Join-Path $Root 'project'
$ToolDir = Join-Path $Root 'tools'
$GodotDir = Join-Path $ToolDir "godot-$GodotVersion"
$GutExtractDir = Join-Path $ToolDir "gut-$GutVersion"
$GodotZip = Join-Path $Root $GodotArchiveName
$GutZip = Join-Path $Root "Gut-v$GutVersion.zip"
$ImportLog = Join-Path $Root 'godot_import.log'
$GutLog = Join-Path $Root 'gut_full_suite.log'
$PreflightReport = Join-Path $Root 'local_preflight.json'
$ManualReport = Join-Path $Root 'manual_validation_report.json'
$FinalEvidence = Join-Path $Root 'local_validation_evidence.json'

function Write-Step([string]$Message) {
    Write-Host "`n============================================================"
    Write-Host "  $Message"
    Write-Host "============================================================"
}

function Invoke-Native([string]$Label, [scriptblock]$Command) {
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE."
    }
}

function Download-IfMissing([string]$Url, [string]$Destination) {
    if (Test-Path -LiteralPath $Destination) {
        return
    }
    Write-Host "Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
}

function Write-Json([object]$Value, [string]$Path) {
    $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
}

Write-Step 'Tetris Core POC - isolated Windows validation'
Write-Host "Validation root : $Root"
Write-Host "Source branch   : $Branch"
Write-Host "Godot pin       : $GodotVersion-stable"
Write-Host "GUT pin         : $GutVersion"
Write-Host 'Existing Godot installs, projects, and settings are not modified.'

if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    throw 'git.exe was not found. Install Git for Windows before running this validator.'
}
if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) {
    throw 'powershell.exe was not found.'
}

New-Item -ItemType Directory -Force -Path $Root, $ToolDir | Out-Null

Write-Step '1/6 Fresh project clone'
if (Test-Path -LiteralPath $ProjectDir) {
    Remove-Item -LiteralPath $ProjectDir -Recurse -Force
}
Invoke-Native 'git clone' {
    & git.exe clone --depth 1 --branch $Branch $RepoUrl $ProjectDir
}
$Commit = (& git.exe -C $ProjectDir rev-parse HEAD | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Commit)) {
    throw 'Could not resolve cloned commit SHA.'
}
Write-Host "Commit          : $Commit"

Write-Step '2/6 Install pinned Godot and GUT inside validation sandbox'
Download-IfMissing $GodotUrl $GodotZip
if (-not (Test-Path -LiteralPath $GodotDir)) {
    New-Item -ItemType Directory -Force -Path $GodotDir | Out-Null
    Expand-Archive -LiteralPath $GodotZip -DestinationPath $GodotDir -Force
}
$GodotExe = Join-Path $GodotDir $GodotExeName
$GodotConsoleExe = Join-Path $GodotDir $GodotConsoleExeName
if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Pinned Godot GUI executable not found after extraction: $GodotExe"
}
if (-not (Test-Path -LiteralPath $GodotConsoleExe)) {
    throw "Pinned Godot console executable not found after extraction: $GodotConsoleExe"
}

Download-IfMissing $GutUrl $GutZip
if (Test-Path -LiteralPath $GutExtractDir) {
    Remove-Item -LiteralPath $GutExtractDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $GutExtractDir | Out-Null
Expand-Archive -LiteralPath $GutZip -DestinationPath $GutExtractDir -Force
$GutSource = Join-Path $GutExtractDir "Gut-$GutVersion\addons\gut"
if (-not (Test-Path -LiteralPath $GutSource)) {
    throw "Pinned GUT addon not found after extraction: $GutSource"
}
$ProjectAddons = Join-Path $ProjectDir 'addons'
$ProjectGut = Join-Path $ProjectAddons 'gut'
New-Item -ItemType Directory -Force -Path $ProjectAddons | Out-Null
if (Test-Path -LiteralPath $ProjectGut) {
    Remove-Item -LiteralPath $ProjectGut -Recurse -Force
}
Copy-Item -LiteralPath $GutSource -Destination $ProjectGut -Recurse -Force

$GodotVersionOutput = (& $GodotConsoleExe --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or -not $GodotVersionOutput.StartsWith("$GodotVersion.stable")) {
    throw "Godot version mismatch. Observed: $GodotVersionOutput"
}
$GutPluginConfig = Join-Path $ProjectGut 'plugin.cfg'
$GutPluginText = Get-Content -LiteralPath $GutPluginConfig -Raw
if ($GutPluginText -notmatch ('version="' + [regex]::Escape($GutVersion) + '"')) {
    throw "GUT version mismatch in $GutPluginConfig"
}
Write-Host "Godot observed  : $GodotVersionOutput"
Write-Host "GUT observed    : $GutVersion"

Write-Step '3/6 Godot import / parse'
& $GodotConsoleExe --headless --path $ProjectDir --editor --quit *> $ImportLog
$ImportExit = $LASTEXITCODE
Get-Content -LiteralPath $ImportLog
if ($ImportExit -ne 0) {
    throw "Godot import/parse failed. See $ImportLog"
}
Write-Host '[LOCAL_IMPORT] PASS'

Write-Step '4/6 Full GUT suite + strict collection guard'
& $GodotConsoleExe --headless --path $ProjectDir -s 'addons/gut/gut_cmdln.gd' '-gdir=res://tests' '-ginclude_subdirs' '-gexit' *> $GutLog
$GutExit = $LASTEXITCODE
Get-Content -LiteralPath $GutLog
$BadPatterns = @(
    'SCRIPT ERROR: Parse Error:',
    'ERROR: Failed to load script',
    '[GUT WARNING]:  Ignoring script'
)
$StrictFailure = $false
foreach ($Pattern in $BadPatterns) {
    if (Select-String -LiteralPath $GutLog -SimpleMatch -Pattern $Pattern -Quiet) {
        Write-Host "[STRICT_GUT] detected: $Pattern" -ForegroundColor Red
        $StrictFailure = $true
    }
}
if ($StrictFailure) {
    throw "Strict GUT collection guard failed. See $GutLog"
}
if ($GutExit -ne 0) {
    throw "GUT suite failed with exit code $GutExit. See $GutLog"
}
if (-not (Select-String -LiteralPath $GutLog -SimpleMatch -Pattern 'All tests passed!' -Quiet)) {
    throw "GUT did not emit the expected all-pass marker. See $GutLog"
}
Write-Host '[LOCAL_GUT] PASS'

$Preflight = [ordered]@{
    verdict = 'PASS'
    platform = 'Windows'
    source_branch = $Branch
    commit = $Commit
    godot_version = $GodotVersionOutput
    gut_version = $GutVersion
    import_parse = 'PASS'
    gut_suite = 'PASS'
    strict_gut_guard = 'PASS'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
}
Write-Json $Preflight $PreflightReport
Write-Host "Preflight report : $PreflightReport"

if ($Ci) {
    Write-Step '5/6 CI smoke mode - interactive play intentionally skipped'
    Write-Host '[WINDOWS_LOCAL_VALIDATOR_SMOKE] PASS'
    Write-Host "Commit: $Commit"
    exit 0
}

Write-Step '5/6 Human-operated 45-second validation'
Remove-Item -LiteralPath $ManualReport -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $FinalEvidence -Force -ErrorAction SilentlyContinue
$env:POC_MANUAL_VALIDATION = '1'
$env:POC_VALIDATION_REPORT_PATH = $ManualReport.Replace('\', '/')
$env:POC_VALIDATION_GUT_VERSION = $GutVersion
$env:POC_VALIDATION_COMMIT = $Commit

Write-Host 'The POC window will open now.'
Write-Host 'Follow the on-screen NEXT instruction in order.'
Write-Host 'Do not close the POC until the status shows: PASS | EVIDENCE SAVED'
$Process = Start-Process -FilePath $GodotExe -ArgumentList @('--path', ('"{0}"' -f $ProjectDir)) -PassThru -Wait
if ($Process.ExitCode -ne 0) {
    throw "Interactive Godot process exited with code $($Process.ExitCode)."
}
if (-not (Test-Path -LiteralPath $ManualReport)) {
    throw "Manual validation evidence was not created. Re-run and complete all 10 steps plus 45 seconds before closing the POC."
}
$Manual = Get-Content -LiteralPath $ManualReport -Raw | ConvertFrom-Json
if ($Manual.verdict -ne 'PASS') {
    throw "Manual validation verdict is not PASS: $($Manual.verdict)"
}
if ([int]$Manual.completed_steps -ne 10 -or [double]$Manual.elapsed_seconds -lt 45.0) {
    throw 'Manual validation report does not contain all 10 ordered steps and >=45 seconds.'
}
if ($Manual.commit -ne $Commit) {
    throw "Manual report commit mismatch. Expected $Commit, observed $($Manual.commit)."
}
if ($Manual.gut_version -ne $GutVersion) {
    throw "Manual report GUT mismatch. Expected $GutVersion, observed $($Manual.gut_version)."
}
if (-not ([string]$Manual.godot_version).StartsWith("$GodotVersion.stable")) {
    throw "Manual report Godot mismatch. Observed $($Manual.godot_version)."
}

Write-Step '6/6 Final local evidence'
$Final = [ordered]@{
    verdict = 'PASS'
    platform = 'Windows'
    source_branch = $Branch
    commit = $Commit
    godot_version = $Manual.godot_version
    gut_version = $GutVersion
    local_import_parse = 'PASS'
    local_gut_suite = 'PASS'
    strict_gut_guard = 'PASS'
    human_operated_45_second_encounter = 'PASS'
    manual = $Manual
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
}
Write-Json $Final $FinalEvidence
Write-Host '[LOCAL_VALIDATION] PASS' -ForegroundColor Green
Write-Host "Final evidence    : $FinalEvidence"
Write-Host "Manual report     : $ManualReport"
Write-Host "Validation sandbox: $Root"
Write-Host 'Rollback: delete the validation sandbox directory above. Existing projects/installations were not modified.'
