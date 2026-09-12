[CmdletBinding()]
param(
    [string]$GodotExe = 'C:\Users\user\Tools\Godot-Tetris-4.7.1\Godot_v4.7.1-stable_win64.exe',
    [string]$OutputDirectory = '',
    [switch]$VerifyPackageOnly,
    [switch]$VerifyProjectPreservationOnly,
    [string]$ProjectSettingsPath = '',
    [string]$ExpectedProjectSha256 = '',
    [switch]$VerifyExportDiagnosticsOnly,
    [string]$ExportStdoutPath = '',
    [string]$ExportStderrPath = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$PresetName = 'Windows R2 Local Trial'
$ExecutableName = 'TetrisR2LocalTrial.exe'
$PackName = 'TetrisR2LocalTrial.pck'
$LauncherName = 'START_R2_LOCAL_TRIAL.cmd'
$ReadmeName = 'README_LOCAL_TRIAL.txt'
$SmokeName = 'r2-package-smoke.json'
$ProbeName = 'r2-export-probe.json'
$ManifestName = 'BUILD_MANIFEST.json'
$IcuName = 'icudt_godot.dat'
$RawAssetDirectoryName = 'r2-source-assets'
$EntryScene = 'res://scenes/replanned_r2/main.tscn'
$ProductionMainScene = 'res://scenes/production/battle_briefing.tscn'
$PackageKind = 'TETRIS_R2_LOCAL_TRIAL_NOT_FOR_RELEASE'
$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Fail-Build([string]$Message) {
    throw "R2 local trial build failed: $Message"
}

function Write-Utf8([string]$Path, [string]$Content) {
    [IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Get-Sha256([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash($stream)
        return -join ($bytes | ForEach-Object { $_.ToString('x2') })
    } finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Get-RelativeSafePath([string]$Root, [string]$RelativePath) {
    if ([IO.Path]::IsPathRooted($RelativePath) -or $RelativePath.Contains('..')) {
        Fail-Build "Unsafe manifest artifact path: $RelativePath"
    }
    $separator = [IO.Path]::DirectorySeparatorChar
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd($separator, [IO.Path]::AltDirectorySeparatorChar) + $separator
    $candidate = [IO.Path]::GetFullPath((Join-Path $Root $RelativePath))
    if (-not $candidate.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
        Fail-Build "Manifest artifact escapes package directory: $RelativePath"
    }
    return $candidate
}

function Get-RootBoundedRelativePath([string]$Root, [string]$Path) {
    $separator = [IO.Path]::DirectorySeparatorChar
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd($separator, [IO.Path]::AltDirectorySeparatorChar) + $separator
    $pathFull = [IO.Path]::GetFullPath($Path)
    if (-not $pathFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
        Fail-Build "Package file escapes package directory: $pathFull"
    }
    return $pathFull.Substring($rootFull.Length).Replace('\', '/')
}

function Assert-OutsideRepository([string]$Path) {
    $separator = [IO.Path]::DirectorySeparatorChar
    $repoPrefix = $RepoRoot.TrimEnd($separator, [IO.Path]::AltDirectorySeparatorChar) + $separator
    $candidate = [IO.Path]::GetFullPath($Path).TrimEnd($separator, [IO.Path]::AltDirectorySeparatorChar) + $separator
    if ($candidate.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        Fail-Build 'OutputDirectory must be outside the repository.'
    }
}

function Assert-R2ProjectPreserved([string]$Path, [string]$ExpectedSha256) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Fail-Build "project.godot preservation failure: file is missing: $Path"
    }
    $actualHash = Get-Sha256 $Path
    if ($actualHash -ne $ExpectedSha256.ToLowerInvariant()) {
        Fail-Build "project.godot preservation failure: on-disk SHA-256 changed (expected $ExpectedSha256, actual $actualHash)."
    }
    $projectText = [IO.File]::ReadAllText($Path)
    $expectedMainSetting = 'run/main_scene="' + $ProductionMainScene + '"'
    if (-not $projectText.Contains($expectedMainSetting)) {
        Fail-Build "project.godot preservation failure: production main scene is not $ProductionMainScene."
    }
}

function Verify-ExportDiagnostics([string]$StdoutPath, [string]$StderrPath) {
    if (-not (Test-Path -LiteralPath $StdoutPath -PathType Leaf) -or -not (Test-Path -LiteralPath $StderrPath -PathType Leaf)) {
        Fail-Build 'Export diagnostic validation requires both original stdout and stderr logs.'
    }
    $stdoutText = Get-Content -Raw -LiteralPath $StdoutPath -ErrorAction Stop
    $expectedEngineBanner = 'Godot Engine v4.7.1.stable.official.a13da4feb'
    $expectedDiagnostics = @(
        "ERROR: 6 RID allocations of type 'N16RendererViewport8ViewportE' were leaked at exit.",
        "ERROR: 9 RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit.",
        "ERROR: 1 RID allocations of type 'N17RendererSceneCull8ScenarioE' were leaked at exit.",
        "ERROR: 83 RID allocations of type 'PN18TextServerAdvanced22ShapedTextDataAdvancedE' were leaked at exit.",
        "ERROR: 1 RID allocations of type 'PN18TextServerAdvanced12FontAdvancedE' were leaked at exit.",
        'WARNING: 6 RIDs of type "Canvas" were leaked.',
        'WARNING: 36 RIDs of type "CanvasItem" were leaked.',
        'WARNING: 209 ObjectDB instances were leaked at exit (run with `--verbose` for details).'
    )
    $observedDiagnostics = @(
        @(Get-Content -LiteralPath $StdoutPath -ErrorAction Stop) +
        @(Get-Content -LiteralPath $StderrPath -ErrorAction Stop) |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -match '^(ERROR|WARNING|SCRIPT ERROR):' }
    )
    if ($observedDiagnostics.Count -eq 0) {
        return [ordered]@{ state = 'NONE'; lines = @() }
    }
    if (-not $stdoutText.Contains($expectedEngineBanner)) {
        Fail-Build 'Unexpected export warning/error: known lifecycle warnings are allowed only for exact Godot 4.7.1 stable official a13da4feb.'
    }
    $expectedSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $observedSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($line in $expectedDiagnostics) { [void]$expectedSet.Add($line) }
    foreach ($line in $observedDiagnostics) {
        if (-not $observedSet.Add($line) -or -not $expectedSet.Contains($line)) {
            Fail-Build "Unexpected export warning/error: $line"
        }
    }
    if ($observedDiagnostics.Count -ne $expectedDiagnostics.Count) {
        $missing = @($expectedDiagnostics | Where-Object { -not $observedSet.Contains($_) })
        Fail-Build "Unexpected export warning/error set: missing exact known lifecycle line(s): $($missing -join ' | ')"
    }
    return [ordered]@{ state = 'KNOWN_TOOLING_WARNING'; lines = $observedDiagnostics }
}

function Verify-Package([string]$PackageDirectory) {
    $root = [IO.Path]::GetFullPath($PackageDirectory)
    $manifestPath = Join-Path $root $ManifestName
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        Fail-Build "Missing $ManifestName in $root"
    }
    $manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json
    if ([int]$manifest.schema_version -ne 1) { Fail-Build 'Unsupported package manifest schema.' }
    if ([string]$manifest.package_kind -ne $PackageKind) { Fail-Build 'Wrong package kind.' }
    if ([string]$manifest.repository_head -notmatch '^[0-9a-f]{40}$') { Fail-Build 'Invalid repository_head.' }
    if ([string]$manifest.entry_scene -ne $EntryScene) { Fail-Build 'Wrong R2 entry scene.' }
    if ([string]$manifest.launcher -ne $LauncherName) { Fail-Build 'Wrong launcher name.' }
    $requiredArtifacts = @(
        $ExecutableName, $PackName, $LauncherName, $ReadmeName, $SmokeName, $ProbeName, $IcuName,
        'export.stdout.log', 'export.stderr.log', 'smoke.stdout.log', 'smoke.stderr.log',
        'probe.stdout.log', 'probe.stderr.log'
    )
    $manifestPaths = @($manifest.artifacts | ForEach-Object { ([string]$_.path).Replace('\', '/') })
    $manifestExact = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $manifestIgnoreCase = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($relative in $manifestPaths) {
        [void](Get-RelativeSafePath $root $relative)
        if (-not $manifestIgnoreCase.Add($relative)) {
            if ($manifestExact.Contains($relative)) {
                Fail-Build "Duplicate manifest artifact path: $relative"
            }
            Fail-Build "Case-colliding manifest artifact path: $relative"
        }
        [void]$manifestExact.Add($relative)
    }
    $assetManifestPath = Join-Path $RepoRoot 'docs\design\r2-complete-session.json'
    $assetManifest = Get-Content -Raw -LiteralPath $assetManifestPath -Encoding UTF8 | ConvertFrom-Json
    $assetEntries = @($assetManifest.assets.PSObject.Properties)
    if ($assetEntries.Count -ne 5) { Fail-Build 'R2 asset manifest must contain exactly five atlases.' }
    $requiredRawArtifacts = @()
    foreach ($assetProperty in $assetEntries) {
        $relativeAssetPath = [string]$assetProperty.Value.path
        $rawRelativePath = ($RawAssetDirectoryName + '/' + $relativeAssetPath.Replace('\', '/'))
        $requiredRawArtifacts += $rawRelativePath
        $rawArtifact = @($manifest.artifacts | Where-Object { [string]$_.path -eq $rawRelativePath })
        if ($rawArtifact.Count -ne 1) {
            Fail-Build "Missing required raw atlas artifact entry: $rawRelativePath"
        }
        if (([string]$rawArtifact[0].sha256).ToLowerInvariant() -ne ([string]$assetProperty.Value.sha256).ToLowerInvariant()) {
            Fail-Build "Raw atlas manifest hash differs from approved metadata: $rawRelativePath"
        }
    }
    $expectedArtifactPaths = @($requiredArtifacts) + @($requiredRawArtifacts)
    foreach ($requiredArtifact in $expectedArtifactPaths) {
        if (-not $manifestExact.Contains($requiredArtifact)) {
            Fail-Build "Missing required artifact entry: $requiredArtifact"
        }
    }
    if ($manifestPaths.Count -ne $expectedArtifactPaths.Count) {
        $unexpected = @($manifestPaths | Where-Object { $expectedArtifactPaths -cnotcontains $_ })
        Fail-Build "Unlisted or unexpected manifest artifact entry count; unexpected: $($unexpected -join ', ')"
    }
    $actualPaths = @(
        Get-ChildItem -LiteralPath $root -File -Recurse -Force |
            Where-Object { -not $_.FullName.Equals($manifestPath, [StringComparison]::OrdinalIgnoreCase) } |
            ForEach-Object { Get-RootBoundedRelativePath $root $_.FullName }
    )
    $actualExact = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($actualPath in $actualPaths) { [void]$actualExact.Add($actualPath) }
    foreach ($actualPath in $actualPaths) {
        if (-not $manifestExact.Contains($actualPath)) {
            Fail-Build "Unlisted package file: $actualPath"
        }
    }
    foreach ($manifestArtifactPath in $manifestPaths) {
        if (-not $actualExact.Contains($manifestArtifactPath)) {
            Fail-Build "Manifest path case or disk file mismatch: $manifestArtifactPath"
        }
    }
    foreach ($artifact in @($manifest.artifacts)) {
        $relative = [string]$artifact.path
        $path = Get-RelativeSafePath $root $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Fail-Build "Missing artifact: $relative"
        }
        $actual = Get-Sha256 $path
        $expected = ([string]$artifact.sha256).ToLowerInvariant()
        if ($actual -ne $expected) {
            Fail-Build "SHA-256 mismatch: $relative"
        }
    }
    Write-Output 'R2_LOCAL_TRIAL_PACKAGE_VERIFIED'
}

if ($VerifyProjectPreservationOnly) {
    if ([string]::IsNullOrWhiteSpace($ProjectSettingsPath) -or $ExpectedProjectSha256 -notmatch '^[0-9a-fA-F]{64}$') {
        Fail-Build 'Project preservation verification requires a fixture path and 64-character expected SHA-256.'
    }
    Assert-R2ProjectPreserved $ProjectSettingsPath $ExpectedProjectSha256
    Write-Output 'R2_PROJECT_SETTINGS_PRESERVED'
    exit 0
}

if ($VerifyExportDiagnosticsOnly) {
    $diagnosticResult = Verify-ExportDiagnostics $ExportStdoutPath $ExportStderrPath
    Write-Output $diagnosticResult.state
    exit 0
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $documents = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
    $shortHead = (& git -C $RepoRoot rev-parse --short=12 HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { Fail-Build 'Cannot read repository HEAD.' }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $OutputDirectory = Join-Path $documents "Tetris R2 Local Trial\Builds\$shortHead-$stamp"
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
Assert-OutsideRepository $OutputDirectory

if ($VerifyPackageOnly) {
    Verify-Package $OutputDirectory
    exit 0
}

if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    Fail-Build "Godot executable not found: $GodotExe"
}
if (Test-Path -LiteralPath $OutputDirectory) {
    if (@(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count -gt 0) {
        Fail-Build 'OutputDirectory is not empty; no existing package is overwritten or deleted.'
    }
} else {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$head = (& git -C $RepoRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $head -notmatch '^[0-9a-f]{40}$') {
    Fail-Build 'Cannot resolve the exact repository HEAD.'
}
$projectSettingsPath = Join-Path $RepoRoot 'project.godot'
$projectHash = Get-Sha256 $projectSettingsPath
$trackedDirty = @(& git -C $RepoRoot diff --name-only)

$exportStdout = Join-Path $OutputDirectory 'export.stdout.log'
$exportStderr = Join-Path $OutputDirectory 'export.stderr.log'
$exePath = Join-Path $OutputDirectory $ExecutableName
$pckPath = Join-Path $OutputDirectory $PackName
$templateDirectory = Join-Path $env:APPDATA 'Godot\export_templates\4.7.1.stable'
$releaseTemplate = Join-Path $templateDirectory 'windows_release_x86_64.exe'
$icuSource = Join-Path $templateDirectory $IcuName
if (-not (Test-Path -LiteralPath $releaseTemplate -PathType Leaf)) {
    Fail-Build "Installed Godot 4.7.1 Windows release template not found: $releaseTemplate"
}
if (-not (Test-Path -LiteralPath $icuSource -PathType Leaf)) {
    Fail-Build "Installed Godot ICU data not found: $icuSource"
}
$exportArgs = @(
    '--headless',
    '--path', ('"' + $RepoRoot + '"'),
    '--editor',
    '--script', 'res://tools/windows/r2_export_driver.gd',
    '--export-pack', ('"' + $PresetName + '"'), ('"' + $pckPath + '"')
)
$exportExitCode = $null
try {
    $exportProcess = Start-Process -FilePath $GodotExe -ArgumentList $exportArgs -WorkingDirectory $RepoRoot -WindowStyle Hidden -RedirectStandardOutput $exportStdout -RedirectStandardError $exportStderr -PassThru
    $exportProcess.WaitForExit()
    $exportExitCode = $exportProcess.ExitCode
} finally {
    Assert-R2ProjectPreserved $projectSettingsPath $projectHash
}
if ($null -eq $exportExitCode -or $exportExitCode -ne 0) {
    Fail-Build "Godot export exited $exportExitCode. See export logs."
}
$exportDiagnosticResult = Verify-ExportDiagnostics $exportStdout $exportStderr
if (-not (Test-Path -LiteralPath $pckPath -PathType Leaf)) { Fail-Build "Export did not create $PackName" }
Copy-Item -LiteralPath $releaseTemplate -Destination $exePath
Copy-Item -LiteralPath $icuSource -Destination (Join-Path $OutputDirectory $IcuName)
if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) { Fail-Build "Native template assembly did not create $ExecutableName" }

$assetManifestPath = Join-Path $RepoRoot 'docs\design\r2-complete-session.json'
$assetManifest = Get-Content -Raw -LiteralPath $assetManifestPath -Encoding UTF8 | ConvertFrom-Json
$assetEntries = @($assetManifest.assets.PSObject.Properties)
if ($assetEntries.Count -ne 5) { Fail-Build 'R2 asset manifest must contain exactly five atlases.' }
$rawArtifactNames = @()
foreach ($assetProperty in $assetEntries) {
    $relativeAssetPath = [string]$assetProperty.Value.path
    $sourceAssetPath = Get-RelativeSafePath $RepoRoot $relativeAssetPath
    if (-not (Test-Path -LiteralPath $sourceAssetPath -PathType Leaf)) {
        Fail-Build "Original atlas source is missing: $relativeAssetPath"
    }
    $sourceHash = Get-Sha256 $sourceAssetPath
    if ($sourceHash -ne ([string]$assetProperty.Value.sha256).ToLowerInvariant()) {
        Fail-Build "Original atlas source hash mismatch: $relativeAssetPath"
    }
    $rawRelativePath = ($RawAssetDirectoryName + '/' + $relativeAssetPath.Replace('\', '/'))
    $rawDestinationPath = Get-RelativeSafePath $OutputDirectory $rawRelativePath
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($rawDestinationPath)) | Out-Null
    Copy-Item -LiteralPath $sourceAssetPath -Destination $rawDestinationPath
    $rawArtifactNames += $rawRelativePath
}

$launcher = @"
@echo off
setlocal
cd /d "%~dp0"
"%~dp0$ExecutableName"
exit /b %ERRORLEVEL%
"@
Write-Utf8 (Join-Path $OutputDirectory $LauncherName) $launcher

$readme = @"
Tetris R2 Local Trial (NOT FOR RELEASE)

이 폴더는 R2 후보를 로컬 Windows에서 검토하기 위한 체험판입니다.
공개 배포물, 최종 아트 승인본, Human/접근성/출시 승인 증거가 아닙니다.

실행: $LauncherName
진입 장면: $EntryScene
빌드 Git SHA: $head

원본 프로젝트의 production main 장면은 바꾸지 않았습니다.
R2 저장은 user://replanned_r2 아래의 별도 경로를 사용합니다.
$RawAssetDirectoryName 폴더에는 승인 metadata의 SHA-256을 실행 시 다시 확인할 원본 atlas bytes가 들어 있습니다.
파일 무결성은 ${ManifestName}의 SHA-256으로 확인할 수 있습니다.
"@
Write-Utf8 (Join-Path $OutputDirectory $ReadmeName) $readme

$smokeStdout = Join-Path $OutputDirectory 'smoke.stdout.log'
$smokeStderr = Join-Path $OutputDirectory 'smoke.stderr.log'
$smokeArgs = @('--headless', '--quit-after', '3')
$smokeProcess = Start-Process -FilePath $exePath -ArgumentList $smokeArgs -WorkingDirectory $OutputDirectory -WindowStyle Hidden -RedirectStandardOutput $smokeStdout -RedirectStandardError $smokeStderr -PassThru
$smokeProcess.WaitForExit()
$smokeOutput = (Get-Content -Raw -LiteralPath $smokeStdout -ErrorAction SilentlyContinue) + "`n" + (Get-Content -Raw -LiteralPath $smokeStderr -ErrorAction SilentlyContinue)
$forbiddenOutput = @('SCRIPT ERROR:', 'Failed to load', 'Asset hash mismatch:', 'Asset missing or wrong size:', 'Failed to instantiate an autoload')
$observedForbidden = @($forbiddenOutput | Where-Object { $smokeOutput.Contains($_) })
if ($smokeProcess.ExitCode -ne 0 -or $observedForbidden.Count -gt 0) {
    Fail-Build "Exported scene smoke failed (exit $($smokeProcess.ExitCode)); inspect smoke logs."
}

$smoke = [ordered]@{
    schema_version = 1
    ok = $true
    exit_code = $smokeProcess.ExitCode
    entry_scene = $EntryScene
    forbidden_output_hits = $observedForbidden
    note = 'Headless exported-scene smoke; native visual and Human acceptance remain separate.'
}
Write-Utf8 (Join-Path $OutputDirectory $SmokeName) (($smoke | ConvertTo-Json -Depth 6) + "`n")

$probeStdout = Join-Path $OutputDirectory 'probe.stdout.log'
$probeStderr = Join-Path $OutputDirectory 'probe.stderr.log'
$probeResult = Join-Path $OutputDirectory $ProbeName
$probeScript = Join-Path $RepoRoot 'tools\windows\r2_export_probe.gd'
$probeArgs = @(
    '--headless',
    '--main-pack', ('"' + $pckPath + '"'),
    '--script', ('"' + $probeScript + '"'),
    '--', ('"--report=' + $probeResult + '"')
)
$rawAssetRoot = Join-Path $OutputDirectory $RawAssetDirectoryName
$previousRawAssetRoot = [Environment]::GetEnvironmentVariable('TETRIS_R2_SOURCE_ASSET_ROOT', 'Process')
try {
    [Environment]::SetEnvironmentVariable('TETRIS_R2_SOURCE_ASSET_ROOT', $rawAssetRoot, 'Process')
    $probeProcess = Start-Process -FilePath $GodotExe -ArgumentList $probeArgs -WorkingDirectory $OutputDirectory -WindowStyle Hidden -RedirectStandardOutput $probeStdout -RedirectStandardError $probeStderr -PassThru
    $probeProcess.WaitForExit()
} finally {
    [Environment]::SetEnvironmentVariable('TETRIS_R2_SOURCE_ASSET_ROOT', $previousRawAssetRoot, 'Process')
}
if ($probeProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $probeResult -PathType Leaf)) {
    Fail-Build "Exported resource probe failed (exit $($probeProcess.ExitCode)); inspect probe logs."
}
$probeData = Get-Content -Raw -LiteralPath $probeResult -Encoding UTF8 | ConvertFrom-Json
if (-not [bool]$probeData.ok) {
    Fail-Build 'Exported resource probe reported a failed contract.'
}

$artifactNames = @(
    $ExecutableName,
    $PackName,
    $LauncherName,
    $ReadmeName,
    $SmokeName,
    $ProbeName,
    $IcuName,
    'export.stdout.log',
    'export.stderr.log',
    'smoke.stdout.log',
    'smoke.stderr.log',
    'probe.stdout.log',
    'probe.stderr.log'
)
$artifactNames += $rawArtifactNames
$artifacts = @()
foreach ($name in $artifactNames) {
    $path = Join-Path $OutputDirectory $name
    $artifacts += [ordered]@{
        path = $name
        sha256 = Get-Sha256 $path
        bytes = (Get-Item -LiteralPath $path).Length
    }
}
$manifest = [ordered]@{
    schema_version = 1
    package_kind = $PackageKind
    repository_head = $head
    project_godot_sha256 = $projectHash
    tracked_worktree_dirty_paths_preserved = $trackedDirty
    preset = $PresetName
    entry_scene = $EntryScene
    launcher = $LauncherName
    generated_at_utc = [DateTime]::UtcNow.ToString('o')
    evidence_ceiling = @('EXPORT_CORRECTNESS', 'HEADLESS_EXPORTED_SCENE_SMOKE', $exportDiagnosticResult.state)
    tooling_warning_state = $exportDiagnosticResult.state
    tooling_warning_lines = $exportDiagnosticResult.lines
    not_claimed = @('HUMAN_APPROVAL', 'ART_APPROVAL', 'RIGHTS_APPROVAL', 'PUBLIC_RELEASE_READINESS')
    artifacts = $artifacts
}
Write-Utf8 (Join-Path $OutputDirectory $ManifestName) (($manifest | ConvertTo-Json -Depth 10) + "`n")
Verify-Package $OutputDirectory
Write-Output "R2_LOCAL_TRIAL_OUTPUT=$OutputDirectory"
