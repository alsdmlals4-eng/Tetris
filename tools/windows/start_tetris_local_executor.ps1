[CmdletBinding()]
param(
    [switch]$SkipCodex,
    [switch]$StaticSelfTest,
    [switch]$PortPreflightSelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# TETRIS_DEDICATED_LOCAL_EXECUTOR
# ASSUME_PREVIOUS_POWERSHELL_CLOSED
# PROJECT_DEDICATED_LOCAL_EXECUTION_ENVIRONMENT_FIRST
# BOOTSTRAP_ORCHESTRATION_ONLY

$Project = 'C:\Users\user\Documents\GitHub\Ninza\Tetris'
$ExpectedRemote = 'https://github.com/alsdmlals4-eng/Tetris.git'
$GodotDir = 'C:\Users\user\Tools\Godot-Tetris-4.7.1'
$GodotExeName = 'Godot_v4.7.1-stable_win64.exe'
$GodotExe = "$GodotDir\$GodotExeName"
$SelfContainedMarker = "$GodotDir\_sc_"
$EditorDataDir = "$GodotDir\editor_data"
$CodexHome = 'C:\Users\user\.codex-tetris'
$HttpPort = 8008
$WsPort = 9508
$ExpectedGodotVersion = '4.7.1'
$ExpectedGodotAiVersion = '3.2.0'
$GodotZipName = 'Godot_v4.7.1-stable_win64.exe.zip'
$OfficialGodotZip = 'https://github.com/godotengine/godot-builds/releases/download/4.7.1-stable/Godot_v4.7.1-stable_win64.exe.zip'
$ExpectedGodotZipSha256 = 'c7a289051eaefb460b0106b60e9cd5bee0ef55fd102dcb2bed1eb356cf3d90a1'
$ExpectedGodotExeSha256 = '323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a'
$ExpectedGodotAiVendorSha256 = 'df3856abf8ea3fd948dae66176f67cfe5e7cdd139a0815b253d640f405c0a3f6'
$ManagedCodexMarker = '# TETRIS_DEDICATED_PROFILE_MANAGED'
$ExpectedPidFileFragment = 'app_userdata/Tetris/godot_ai_server.pid'
$BootstrapWaitSeconds = 120

function Write-Step([string]$Message) {
    Write-Host "[Tetris bootstrap] $Message"
}

function Fail-Bootstrap([string]$Message) {
    throw "[Tetris bootstrap] $Message"
}

function Normalize-PathText([string]$PathText) {
    if ([string]::IsNullOrWhiteSpace($PathText)) { return '' }
    try {
        return [System.IO.Path]::GetFullPath($PathText).Replace('/', '\').TrimEnd('\').ToLowerInvariant()
    }
    catch {
        return $PathText.Replace('/', '\').TrimEnd('\').ToLowerInvariant()
    }
}

function Assert-FileSha256([string]$Path, [string]$Expected, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Fail-Bootstrap "$Label is missing: $Path"
    }
    $observed = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($observed -ne $Expected.ToLowerInvariant()) {
        Fail-Bootstrap "$Label SHA-256 mismatch. Expected $Expected, observed $observed at $Path"
    }
}

function Write-BigEndianUInt32([System.IO.Stream]$Stream, [uint32]$Value) {
    $bytes = [System.BitConverter]::GetBytes($Value)
    if ([System.BitConverter]::IsLittleEndian) { [System.Array]::Reverse($bytes) }
    $Stream.Write($bytes, 0, $bytes.Length)
}

function Write-BigEndianUInt64([System.IO.Stream]$Stream, [uint64]$Value) {
    $bytes = [System.BitConverter]::GetBytes($Value)
    if ([System.BitConverter]::IsLittleEndian) { [System.Array]::Reverse($bytes) }
    $Stream.Write($bytes, 0, $bytes.Length)
}

function ConvertTo-CanonicalGodotAiVendorBytes([string]$RelativePath, [byte[]]$Bytes) {
    $extension = [System.IO.Path]::GetExtension($RelativePath).ToLowerInvariant()
    $fileName = [System.IO.Path]::GetFileName($RelativePath)
    $isDeclaredText = @('.cfg', '.gd', '.md', '.uid') -contains $extension -or $fileName -eq 'LICENSE'
    if (-not $isDeclaredText) { return $Bytes }

    $canonical = New-Object System.IO.MemoryStream
    try {
        for ($index = 0; $index -lt $Bytes.Length; $index++) {
            if ($Bytes[$index] -eq 13) {
                if ($index + 1 -lt $Bytes.Length -and $Bytes[$index + 1] -eq 10) { continue }
                $canonical.WriteByte(13)
                continue
            }
            $canonical.WriteByte($Bytes[$index])
        }
        return $canonical.ToArray()
    }
    finally {
        $canonical.Dispose()
    }
}

function Get-GodotAiVendorDigest([string]$AddonRoot) {
    $root = (Resolve-Path -LiteralPath $AddonRoot).Path.TrimEnd([char[]]@('\', '/'))
    $pathMap = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $root -File -Recurse -Force)) {
        $relative = $file.FullName.Substring($root.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
        $pathMap[$relative] = $file.FullName
    }
    [string[]]$orderedPaths = @($pathMap.Keys)
    [System.Array]::Sort($orderedPaths, [System.StringComparer]::Ordinal)

    $payload = New-Object System.IO.MemoryStream
    try {
        foreach ($relative in $orderedPaths) {
            $relativeBytes = [System.Text.Encoding]::UTF8.GetBytes($relative)
            [byte[]]$fileBytes = ConvertTo-CanonicalGodotAiVendorBytes $relative ([System.IO.File]::ReadAllBytes([string]$pathMap[$relative]))
            Write-BigEndianUInt32 $payload ([uint32]$relativeBytes.Length)
            $payload.Write($relativeBytes, 0, $relativeBytes.Length)
            Write-BigEndianUInt64 $payload ([uint64]$fileBytes.Length)
            $payload.Write($fileBytes, 0, $fileBytes.Length)
        }
        $payload.Position = 0
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            return ([System.BitConverter]::ToString($sha.ComputeHash($payload))).Replace('-', '').ToLowerInvariant()
        }
        finally {
            $sha.Dispose()
        }
    }
    finally {
        $payload.Dispose()
    }
}

function Invoke-Capture([string]$File, [string[]]$CommandArgs, [string]$WorkingDirectory) {
    $previous = Get-Location
    $previousPreference = $ErrorActionPreference
    try {
        Set-Location -LiteralPath $WorkingDirectory
        $ErrorActionPreference = 'Continue'
        $global:LASTEXITCODE = 0
        $output = & $File @CommandArgs 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
        return [ordered]@{ exit_code = [int]$exitCode; output = $output.TrimEnd() }
    }
    catch {
        return [ordered]@{ exit_code = -1; output = $_.Exception.Message }
    }
    finally {
        $ErrorActionPreference = $previousPreference
        Set-Location -LiteralPath $previous.Path
    }
}

function Get-ProcessRecord([int]$ProcessId) {
    try {
        return Get-CimInstance Win32_Process -Filter "ProcessId=$ProcessId" -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Get-PortDiagnostics([int]$Port) {
    $listeners = @()
    try {
        foreach ($listener in @(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop)) {
            $listeners += [pscustomobject]@{
                PID = [int]$listener.OwningProcess
                LocalAddress = [string]$listener.LocalAddress
            }
        }
    }
    catch {
        $netstat = Get-Command 'netstat.exe' -ErrorAction SilentlyContinue
        if ($null -eq $netstat) {
            Fail-Bootstrap "PORT_OWNERSHIP_QUERY_UNAVAILABLE port=$Port"
        }
        foreach ($line in @(& $netstat.Source -ano -p tcp 2>$null)) {
            if ($line -match ("^\s*TCP\s+(\S+:" + $Port + ")\s+\S+\s+LISTENING\s+(\d+)\s*$")) {
                $localEndpoint = [string]$Matches[1]
                $localAddress = ($localEndpoint -replace ':\d+$', '').TrimStart('[').TrimEnd(']')
                $listeners += [pscustomobject]@{
                    PID = [int]$Matches[2]
                    LocalAddress = $localAddress
                }
            }
        }
    }
    $rows = @()
    foreach ($listener in @($listeners | Sort-Object PID, LocalAddress -Unique)) {
        $process = Get-ProcessRecord ([int]$listener.PID)
        $rows += [pscustomobject]@{
            Port = $Port
            PID = [int]$listener.PID
            LocalAddress = [string]$listener.LocalAddress
            Name = if ($process) { [string]$process.Name } else { '<unknown>' }
            ExecutablePath = if ($process) { [string]$process.ExecutablePath } else { '' }
            CommandLine = if ($process) { [string]$process.CommandLine } else { '' }
        }
    }
    return $rows
}

function Test-LoopbackListener($Row) {
    return ([string]$Row.LocalAddress) -in @('127.0.0.1', '::1')
}

function Test-CommandLineTargetsTetris([string]$CommandLine) {
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return $false }
    $normalized = $CommandLine.Replace('/', '\').ToLowerInvariant()
    return $normalized.Contains((Normalize-PathText $Project)) -and $CommandLine -match '(?i)(?:^|\s)--path(?:\s|=)'
}

function Get-TetrisGodotEditors {
    $matches = @()
    foreach ($process in @(Get-CimInstance Win32_Process -ErrorAction Stop)) {
        $name = ([string]$process.Name).ToLowerInvariant()
        if (-not ($name.StartsWith('godot') -and $name.EndsWith('.exe'))) { continue }
        if (Test-CommandLineTargetsTetris ([string]$process.CommandLine)) {
            $matches += $process
        }
    }
    return $matches
}

function Get-ExactDedicatedEditor {
    $expectedExecutable = Normalize-PathText $GodotExe
    $exact = @(Get-TetrisGodotEditors | Where-Object {
        $_.ExecutablePath -and (Normalize-PathText ([string]$_.ExecutablePath)) -eq $expectedExecutable
    })
    if ($exact.Count -gt 1) {
        Fail-Bootstrap "MULTIPLE_DEDICATED_TETRIS_EDITORS_FAIL_CLOSED pids=$($exact.ProcessId -join ',')"
    }
    if ($exact.Count -eq 1) { return $exact[0] }
    return $null
}

function Assert-NoEditorConflict {
    $expectedExecutable = Normalize-PathText $GodotExe
    $conflicts = @(Get-TetrisGodotEditors | Where-Object {
        -not $_.ExecutablePath -or (Normalize-PathText ([string]$_.ExecutablePath)) -ne $expectedExecutable
    })
    if ($conflicts.Count -gt 0) {
        Write-Host 'NON_DEDICATED_TETRIS_EDITOR_CONFLICT_FAIL_CLOSED'
        foreach ($process in $conflicts) {
            Write-Host ("PID {0} Executable={1}`n  CommandLine={2}" -f $process.ProcessId, $process.ExecutablePath, $process.CommandLine)
        }
        Fail-Bootstrap 'Close the non-dedicated Godot editor targeting Tetris and rerun. No process was terminated.'
    }
}

function Test-ExactGodotAiListener($Row) {
    $commandLine = ([string]$Row.CommandLine).ToLowerInvariant()
    $normalized = $commandLine.Replace('\', '/')
    $isBranded = $commandLine.Contains('godot-ai') -or $commandLine.Contains('godot_ai')
    $hasHttpPort = $commandLine -match '(?i)(?:^|\s)--port\s+8008(?:\s|$)'
    $hasWsPort = $commandLine -match '(?i)(?:^|\s)--ws-port\s+9508(?:\s|$)'
    $hasTetrisPidFile = $normalized.Contains($ExpectedPidFileFragment.ToLowerInvariant())
    return $isBranded -and $hasHttpPort -and $hasWsPort -and $hasTetrisPidFile
}

function Assert-PortState($ExactEditor) {
    $occupied = @(@(Get-PortDiagnostics $HttpPort) + @(Get-PortDiagnostics $WsPort))
    if ($occupied.Count -eq 0) { return }

    if ($null -ne $ExactEditor) {
        $invalid = @($occupied | Where-Object {
            -not (Test-LoopbackListener $_) -or -not (Test-ExactGodotAiListener $_)
        })
        if ($invalid.Count -eq 0) {
            Write-Step 'EXACT_TETRIS_EDITOR_REUSE: recognized Tetris Godot AI listeners found.'
            return
        }
    }

    Write-Host 'PORT_CONFLICT_FAIL_CLOSED'
    foreach ($row in $occupied) {
        Write-Host ("Port {0} Address={1} PID {2} Name={3}`n  Executable={4}`n  CommandLine={5}" -f $row.Port, $row.LocalAddress, $row.PID, $row.Name, $row.ExecutablePath, $row.CommandLine)
    }
    Fail-Bootstrap 'HTTP 8008 or WS 9508 has an unknown, partial, or foreign owner. No process was terminated and no alternate port was selected.'
}

function Invoke-PortPreflightSelfTest {
    function script:Get-PortDiagnostics([int]$Port) {
        return @()
    }
    Assert-PortState $null

    function script:Get-PortDiagnostics([int]$Port) {
        if ($Port -ne $HttpPort) { return @() }
        return [pscustomobject]@{
            Port = $Port
            PID = 4242
            LocalAddress = '127.0.0.1'
            Name = 'foreign-owner.exe'
            ExecutablePath = 'C:\\foreign-owner.exe'
            CommandLine = 'foreign-owner --port 8008'
        }
    }
    try {
        Assert-PortState $null
    }
    catch {
        if ($_.Exception.Message -notmatch 'unknown, partial, or foreign owner') { throw }
        Write-Host 'TETRIS_LAUNCHER_PORT_PREFLIGHT_SELF_TEST_PASS'
        return
    }
    Fail-Bootstrap 'PORT_PREFLIGHT_SELF_TEST_EXPECTED_FAIL_CLOSED_CONFLICT'
}

function Assert-ProjectIdentity {
    if (-not (Test-Path -LiteralPath $Project -PathType Container)) {
        Fail-Bootstrap "Project directory not found: $Project"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Project 'project.godot') -PathType Leaf)) {
        Fail-Bootstrap "project.godot not found: $Project"
    }
    $pluginConfig = Join-Path $Project 'addons\godot_ai\plugin.cfg'
    if (-not (Test-Path -LiteralPath $pluginConfig -PathType Leaf)) {
        Fail-Bootstrap 'Vendored addons/godot_ai/plugin.cfg is missing.'
    }
    $pluginText = Get-Content -LiteralPath $pluginConfig -Raw -Encoding UTF8
    if ($pluginText -notmatch ('(?m)^version="' + [regex]::Escape($ExpectedGodotAiVersion) + '"$')) {
        Fail-Bootstrap "Godot AI version mismatch. Expected $ExpectedGodotAiVersion."
    }
    $addonRoot = Join-Path $Project 'addons\godot_ai'
    $observedVendorDigest = Get-GodotAiVendorDigest $addonRoot
    if ($observedVendorDigest -ne $ExpectedGodotAiVendorSha256) {
        Fail-Bootstrap "Godot AI vendor content mismatch. Expected $ExpectedGodotAiVendorSha256, observed $observedVendorDigest."
    }
    $projectText = Get-Content -LiteralPath (Join-Path $Project 'project.godot') -Raw -Encoding UTF8
    if (-not $projectText.Contains('res://addons/godot_ai/plugin.cfg')) {
        Fail-Bootstrap 'Godot AI is not enabled in project.godot.'
    }

    $git = Get-Command 'git.exe' -ErrorAction SilentlyContinue
    if ($null -eq $git) { $git = Get-Command 'git' -ErrorAction SilentlyContinue }
    if ($null -eq $git) { Fail-Bootstrap 'Git is not available on PATH.' }
    $inside = Invoke-Capture $git.Source @('rev-parse', '--is-inside-work-tree') $Project
    if ($inside.exit_code -ne 0 -or $inside.output.Trim() -ne 'true') {
        Fail-Bootstrap 'The exact Tetris path is not a Git worktree.'
    }
    $remote = Invoke-Capture $git.Source @('remote', 'get-url', 'origin') $Project
    if ($remote.exit_code -ne 0) { Fail-Bootstrap 'Tetris origin URL could not be resolved.' }
    $observed = $remote.output.Trim().TrimEnd('/')
    $accepted = @(
        $ExpectedRemote,
        $ExpectedRemote.Substring(0, $ExpectedRemote.Length - 4),
        'git@github.com:alsdmlals4-eng/Tetris.git'
    )
    if ($accepted -notcontains $observed) {
        Fail-Bootstrap "Wrong Tetris origin: $observed"
    }
    Write-Step 'Exact Tetris repository and Godot AI 3.2.0 vendor verified.'
}

function Find-LocalGodotExecutable {
    $downloads = Join-Path $env:USERPROFILE 'Downloads'
    if (-not (Test-Path -LiteralPath $downloads -PathType Container)) { return $null }
    $candidate = Get-ChildItem -LiteralPath $downloads -Filter $GodotExeName -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) { return $candidate.FullName }
    return $null
}

function Find-LocalGodotArchive {
    $downloads = Join-Path $env:USERPROFILE 'Downloads'
    if (-not (Test-Path -LiteralPath $downloads -PathType Container)) { return $null }
    $candidate = Get-ChildItem -LiteralPath $downloads -Filter $GodotZipName -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) { return $candidate.FullName }
    return $null
}

function Find-HiGodotServerPrerequisite {
    foreach ($name in @('uvx.exe', 'uvx', 'godot-ai.exe', 'godot-ai')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            return [pscustomobject]@{ Path = $command.Source; Kind = $name }
        }
    }

    $directories = @()
    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        $directories += @(
            (Join-Path $env:USERPROFILE '.local\bin'),
            (Join-Path $env:USERPROFILE '.cargo\bin'),
            (Join-Path $env:USERPROFILE 'AppData\Local\Programs\uv')
        )
    }
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $directories += (Join-Path $env:LOCALAPPDATA 'Programs\uv')
    }
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $directories += (Join-Path $env:ProgramFiles 'uv')
    }
    foreach ($directory in $directories) {
        foreach ($name in @('uvx.exe', 'godot-ai.exe')) {
            $candidate = Join-Path $directory $name
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                return [pscustomobject]@{ Path = $candidate; Kind = $name }
            }
        }
    }
    return $null
}

function Assert-HiGodotServerPrerequisite {
    $prerequisite = Find-HiGodotServerPrerequisite
    if ($null -eq $prerequisite) {
        Fail-Bootstrap 'UV_OR_GODOT_AI_NOT_FOUND: install free uv from https://docs.astral.sh/uv/getting-started/installation/ and rerun.'
    }
    $probe = Invoke-Capture ([string]$prerequisite.Path) @('--version') $Project
    if ($probe.exit_code -ne 0) {
        Fail-Bootstrap "HiGodot server prerequisite failed: $($prerequisite.Path) --version; $($probe.output)"
    }
    Write-Step "HiGodot server prerequisite verified: $($prerequisite.Path) ($($probe.output))."
}

function Ensure-DedicatedGodot {
    New-Item -ItemType Directory -Force -Path $GodotDir | Out-Null
    if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
        $sourceExecutable = Find-LocalGodotExecutable
        if ($sourceExecutable) {
            Assert-FileSha256 $sourceExecutable $ExpectedGodotExeSha256 'Downloaded Godot 4.7.1 executable candidate'
            Write-Step "Copying exact Godot 4.7.1 executable from $sourceExecutable"
            Copy-Item -LiteralPath $sourceExecutable -Destination $GodotExe -Force
        }
        else {
            $sourceArchive = Find-LocalGodotArchive
            $temporaryArchive = $null
            $temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("tetris-godot-" + [guid]::NewGuid().ToString('N'))
            try {
                if (-not $sourceArchive) {
                    $temporaryArchive = Join-Path ([System.IO.Path]::GetTempPath()) ("tetris-godot-" + [guid]::NewGuid().ToString('N') + '.zip')
                    Write-Step 'Downloading official Godot 4.7.1 Windows archive.'
                    Invoke-WebRequest -Uri $OfficialGodotZip -OutFile $temporaryArchive -UseBasicParsing
                    $sourceArchive = $temporaryArchive
                }
                Assert-FileSha256 $sourceArchive $ExpectedGodotZipSha256 'Official Godot 4.7.1 archive'
                New-Item -ItemType Directory -Force -Path $temporaryDirectory | Out-Null
                Expand-Archive -LiteralPath $sourceArchive -DestinationPath $temporaryDirectory -Force
                $expanded = Get-ChildItem -LiteralPath $temporaryDirectory -Filter $GodotExeName -File -Recurse | Select-Object -First 1
                if (-not $expanded) { Fail-Bootstrap "Godot archive did not contain $GodotExeName" }
                Copy-Item -LiteralPath $expanded.FullName -Destination $GodotExe -Force
            }
            finally {
                if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
                if ($temporaryArchive -and (Test-Path -LiteralPath $temporaryArchive)) { Remove-Item -LiteralPath $temporaryArchive -Force }
            }
        }
    }

    if (-not (Test-Path -LiteralPath $SelfContainedMarker -PathType Leaf)) {
        New-Item -ItemType File -Path $SelfContainedMarker -Force | Out-Null
    }
    Assert-FileSha256 $GodotExe $ExpectedGodotExeSha256 'Dedicated Godot 4.7.1 executable'
    $version = Invoke-Capture $GodotExe @('--version') $Project
    if ($version.exit_code -ne 0 -or -not $version.output.Contains($ExpectedGodotVersion)) {
        Fail-Bootstrap "Dedicated Godot version mismatch: $($version.output)"
    }
    Write-Step "Dedicated self-contained Godot verified: $($version.output)"
}

function Find-DedicatedEditorSettings {
    if (-not (Test-Path -LiteralPath $EditorDataDir -PathType Container)) { return $null }
    return Get-ChildItem -LiteralPath $EditorDataDir -Filter 'editor_settings-4*.tres' -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
}

function Get-ExpectedEditorSettingPairs {
    return [ordered]@{
        'godot_ai/http_port' = '8008'
        'godot_ai/ws_port' = '9508'
        'godot_ai/keep_server_on_exit' = 'false'
        'godot_ai/allow_remote_hosts' = '""'
        'godot_ai/telemetry_enabled' = 'false'
    }
}

function Assert-EditorSettingsText([string]$Raw, [string]$SettingsPath) {
    foreach ($key in (Get-ExpectedEditorSettingPairs).Keys) {
        $value = (Get-ExpectedEditorSettingPairs)[$key]
        if ($Raw -notmatch ("(?m)^" + [regex]::Escape($key) + "\s*=\s*" + [regex]::Escape($value) + "\s*$")) {
            Fail-Bootstrap "Dedicated EditorSettings mismatch for $key in $SettingsPath. Close the Tetris editor and rerun."
        }
    }
}

function Ensure-DedicatedEditorSettings([bool]$EditorAlreadyRunning) {
    $settings = Find-DedicatedEditorSettings
    if (-not $settings -and -not $EditorAlreadyRunning) {
        Write-Step 'Initializing self-contained editor_data in recovery mode.'
        $initialization = Invoke-Capture $GodotExe @('--headless', '--editor', '--recovery-mode', '--path', $Project, '--quit-after', '2') $Project
        if ($initialization.exit_code -ne 0) {
            Fail-Bootstrap "Dedicated EditorSettings initialization failed: $($initialization.output)"
        }
        $settings = Find-DedicatedEditorSettings
    }
    if (-not $settings) {
        Fail-Bootstrap "Dedicated EditorSettings were not found below $EditorDataDir"
    }

    $settingsPath = $settings.FullName
    $raw = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
    if ($EditorAlreadyRunning) {
        Assert-EditorSettingsText $raw $settingsPath
        Write-Step 'Exact running editor has the assigned HTTP 8008 / WS 9508 settings.'
        return
    }

    $backup = "$settingsPath.tetris-bootstrap-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
    Copy-Item -LiteralPath $settingsPath -Destination $backup -Force
    foreach ($key in (Get-ExpectedEditorSettingPairs).Keys) {
        $value = (Get-ExpectedEditorSettingPairs)[$key]
        $line = "$key = $value"
        if ($raw -match ("(?m)^" + [regex]::Escape($key) + "\s*=")) {
            $raw = [regex]::Replace($raw, ("(?m)^" + [regex]::Escape($key) + "\s*=.*$"), $line)
        }
        else {
            $raw = $raw.TrimEnd() + "`r`n$line`r`n"
        }
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($settingsPath, $raw, $utf8NoBom)
    Assert-EditorSettingsText (Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8) $settingsPath
    Write-Step "Dedicated EditorSettings assigned to HTTP 8008 / WS 9508. Backup: $backup"
}

function Ensure-DedicatedCodexHome {
    New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
    $env:CODEX_HOME = $CodexHome
    $configPath = Join-Path $CodexHome 'config.toml'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $existing = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
        if (-not $existing.Contains($ManagedCodexMarker)) {
            Fail-Bootstrap "UNMANAGED_CODEX_CONFIG_FAIL_CLOSED: review or move $configPath before rerunning."
        }
    }
    $configLines = @(
        $ManagedCodexMarker,
        'approval_policy = "never"',
        'sandbox_mode = "workspace-write"',
        '',
        '[sandbox_workspace_write]',
        'network_access = true',
        '',
        '[mcp_servers.godot-ai]',
        'url = "http://127.0.0.1:8008/mcp"',
        'enabled = true',
        'required = true',
        'startup_timeout_sec = 60',
        'tool_timeout_sec = 360'
    )
    $config = [string]::Join("`n", $configLines) + "`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($configPath, $config, $utf8NoBom)
    Write-Step "Dedicated Codex profile ready: $CodexHome"
}

function Resolve-CodexCommand {
    foreach ($name in @('codex.cmd', 'codex')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $command) { return $command }
    }
    return $null
}

function Ensure-CodexLogin($CodexCommand) {
    $status = Invoke-Capture $CodexCommand.Source @('login', 'status') $Project
    if ($status.exit_code -eq 0) {
        Write-Step 'Dedicated Codex login is ready.'
        return
    }
    if ($status.output -notmatch '(?i)not\s+logged\s+in') {
        Fail-Bootstrap "Codex login status failed: $($status.output)"
    }
    Write-Step 'Starting the official Codex login for the dedicated Tetris profile.'
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $CodexCommand.Source login
        $loginExit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($null -ne $loginExit -and $loginExit -ne 0) {
        Fail-Bootstrap "Codex login failed with exit code $loginExit"
    }
    $verified = Invoke-Capture $CodexCommand.Source @('login', 'status') $Project
    if ($verified.exit_code -ne 0) {
        Fail-Bootstrap "Codex login is not ready after login: $($verified.output)"
    }
}

function Wait-ForDedicatedListeners {
    $deadline = (Get-Date).AddSeconds($BootstrapWaitSeconds)
    do {
        $http = @(Get-PortDiagnostics $HttpPort)
        $ws = @(Get-PortDiagnostics $WsPort)
        if ($http.Count -eq 1 -and $ws.Count -eq 1 -and $http[0].PID -eq $ws[0].PID) {
            $bothLoopback = (Test-LoopbackListener $http[0]) -and (Test-LoopbackListener $ws[0])
            $bothExact = (Test-ExactGodotAiListener $http[0]) -and (Test-ExactGodotAiListener $ws[0])
            if ($bothLoopback -and $bothExact) {
                return [int]$http[0].PID
            }
            Write-Host 'PORT_CONFLICT_FAIL_CLOSED'
            Fail-Bootstrap 'Assigned ports are listening, but their command line does not prove the exact Tetris Godot AI identity.'
        }
        if ($http.Count -gt 1 -or $ws.Count -gt 1) {
            Write-Host 'PORT_CONFLICT_FAIL_CLOSED'
            Fail-Bootstrap 'Multiple listener owners were observed on an assigned Tetris port.'
        }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    Fail-Bootstrap "HTTP 8008 / WS 9508 did not become ready within $BootstrapWaitSeconds seconds. Verify that uv/uvx is installed and inspect the Godot AI dock."
}

function Wait-ForExactHiGodotStatus {
    $deadline = (Get-Date).AddSeconds($BootstrapWaitSeconds)
    $statusUri = "http://127.0.0.1:$HttpPort/godot-ai/status"
    $lastError = ''
    do {
        $status = $null
        try {
            $status = Invoke-RestMethod -Uri $statusUri -Method Get -TimeoutSec 3
        }
        catch {
            $lastError = $_.Exception.Message
        }
        if ($null -ne $status) {
            $propertyNames = @($status.PSObject.Properties.Name)
            $name = if ($propertyNames -contains 'name') { [string]$status.name } else { '' }
            $version = if ($propertyNames -contains 'server_version') {
                [string]$status.server_version
            }
            elseif ($propertyNames -contains 'version') {
                [string]$status.version
            }
            else {
                ''
            }
            $observedWsPort = if ($propertyNames -contains 'ws_port') { [int]$status.ws_port } else { 0 }
            if ($name -ne 'godot-ai' -or $version -ne $ExpectedGodotAiVersion -or $observedWsPort -ne $WsPort) {
                Fail-Bootstrap "HIGODOT_STATUS_IDENTITY_MISMATCH name=$name version=$version ws_port=$observedWsPort"
            }
            Write-Step "Exact live status verified: name=$name version=$version ws_port=$observedWsPort."
            return
        }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    Fail-Bootstrap "HiGodot status endpoint did not verify within $BootstrapWaitSeconds seconds: $lastError"
}

if ($StaticSelfTest) {
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $addonRoot = Join-Path $repositoryRoot 'addons/godot_ai'
    $observedVendorDigest = Get-GodotAiVendorDigest $addonRoot
    if ($observedVendorDigest -ne $ExpectedGodotAiVendorSha256) {
        Fail-Bootstrap "STATIC_SELF_TEST_VENDOR_MISMATCH expected=$ExpectedGodotAiVendorSha256 observed=$observedVendorDigest"
    }
    Write-Host "TETRIS_LAUNCHER_STATIC_SELF_TEST_PASS vendor_sha256=$observedVendorDigest"
    exit 0
}

if ($PortPreflightSelfTest) {
    Invoke-PortPreflightSelfTest
    exit 0
}

$bootstrapLockPath = Join-Path ([System.IO.Path]::GetTempPath()) 'tetris-higodot-slot8-bootstrap.lock'
try {
    $bootstrapLock = [System.IO.File]::Open(
        $bootstrapLockPath,
        [System.IO.FileMode]::OpenOrCreate,
        [System.IO.FileAccess]::ReadWrite,
        [System.IO.FileShare]::None
    )
}
catch {
    Fail-Bootstrap 'CONCURRENT_BOOTSTRAP_FAIL_CLOSED: another Tetris slot 8 launcher is active. No process was terminated.'
}

Write-Host 'ASSUME_PREVIOUS_POWERSHELL_CLOSED'
Write-Host 'PROJECT_DEDICATED_LOCAL_EXECUTION_ENVIRONMENT_FIRST'
Write-Step 'Starting the bounded slot 8 bootstrap.'

Assert-ProjectIdentity
Assert-HiGodotServerPrerequisite
Ensure-DedicatedGodot
Assert-NoEditorConflict
$exactEditor = Get-ExactDedicatedEditor
Assert-PortState $exactEditor
Ensure-DedicatedEditorSettings ($null -ne $exactEditor)

$env:GODOT_AI_DISABLE_TELEMETRY = 'true'
$env:DISABLE_TELEMETRY = 'true'

if ($null -eq $exactEditor) {
    Write-Step "Launching dedicated Tetris Godot: $GodotExe"
    Start-Process -FilePath $GodotExe -ArgumentList @('--path', $Project, '--editor') -WorkingDirectory $Project | Out-Null
}
else {
    Write-Step "Reusing exact dedicated Tetris editor PID $($exactEditor.ProcessId)."
}

$serverPid = Wait-ForDedicatedListeners
Write-Step "Startup identity verified: Godot AI PID $serverPid, HTTP 8008, WS 9508."
Wait-ForExactHiGodotStatus
Write-Host 'POST_BOOTSTRAP_LIVE_READINESS_NOT_PROVEN'
Write-Host 'FRESH_HIGODOT_READINESS_REQUIRED_BEFORE_MUTATION'

if ($SkipCodex) {
    Write-Step 'Godot/HiGodot startup completed without launching a local MCP client (-SkipCodex).'
    $bootstrapLock.Dispose()
    exit 0
}

Ensure-DedicatedCodexHome
$codexCommand = Resolve-CodexCommand
if ($null -eq $codexCommand) {
    Fail-Bootstrap 'Codex CLI was not found. Godot/HiGodot is running, but a local MCP client is still required because cloud ChatGPT cannot dial this PC localhost.'
}
Ensure-CodexLogin $codexCommand

Write-Step "Launching Codex from $Project with CODEX_HOME=$CodexHome"
Write-Step 'First action in Codex: obtain a fresh exact Tetris project/session/version/readiness receipt before any persistent Godot mutation.'
Set-Location -LiteralPath $Project
& $codexCommand.Source -C $Project
$codexExit = $LASTEXITCODE
if ($null -ne $codexExit -and $codexExit -ne 0) {
    Fail-Bootstrap "Codex exited with code $codexExit"
}
$bootstrapLock.Dispose()
