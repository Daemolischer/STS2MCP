<#
.SYNOPSIS
    Starts Slay the Spire 2 in the background (no window) with the STS2_MCP mod and enables Instant Mode.

.DESCRIPTION
    Steam must be running. The game directory is found through the Steam library folders unless -GameDir
    is given. The script waits until the mod's API answers in the main menu, then enables Instant Mode
    for this game session. Use -Windowed to start with a normal game window instead.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\start-game.ps1
#>
param(
    [string]$GameDir,
    [switch]$Windowed,
    [int]$Port = 15526,
    [int]$TimeoutSeconds = 90
)

$ErrorActionPreference = 'Stop'
$AppId = '2868840'
$api = "http://localhost:$Port/api/v1/singleplayer"

function Find-GameDir {
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { throw 'Steam installation not found. Pass -GameDir.' }
    $libraries = @($steam)
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path $vdf) {
        $libraries += Select-String -Path $vdf -Pattern '"path"\s+"(.+)"' |
            ForEach-Object { $_.Matches[0].Groups[1].Value -replace '\\\\', '\' }
    }
    foreach ($lib in $libraries | Select-Object -Unique) {
        if (Test-Path (Join-Path $lib "steamapps\appmanifest_$AppId.acf")) {
            return Join-Path $lib 'steamapps\common\Slay the Spire 2'
        }
    }
    throw 'Slay the Spire 2 not found in any Steam library. Pass -GameDir.'
}

function Get-State {
    try { return (Invoke-WebRequest "$api`?format=json" -UseBasicParsing -TimeoutSec 3).Content | ConvertFrom-Json }
    catch { return $null }
}

if (Get-Process -Name SlayTheSpire2 -ErrorAction SilentlyContinue) {
    throw 'Slay the Spire 2 is already running. Stop it first (scripts\stop-game.ps1).'
}
if (-not (Get-Process -Name steam -ErrorAction SilentlyContinue)) {
    throw 'Steam is not running. Start Steam first.'
}
if (-not $GameDir) { $GameDir = Find-GameDir }
$exe = Join-Path $GameDir 'SlayTheSpire2.exe'
if (-not (Test-Path $exe)) { throw "Game executable not found: $exe" }

# Without these variables the game started outside Steam fails to initialize Steamworks and blocks on an error popup.
$env:SteamAppId = $AppId
$env:SteamGameId = $AppId
$arguments = if ($Windowed) { @() } else { @('--headless') }
if ($arguments.Count -gt 0) {
    $process = Start-Process $exe -ArgumentList $arguments -WorkingDirectory $GameDir -PassThru
} else {
    $process = Start-Process $exe -WorkingDirectory $GameDir -PassThru
}
Write-Output "Started Slay the Spire 2 (PID $($process.Id), $(if ($Windowed) { 'windowed' } else { 'headless' }))."

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$state = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
    if ($process.HasExited) { throw "The game exited during startup (exit code $($process.ExitCode)). See %APPDATA%\SlayTheSpire2\logs\godot.log." }
    $state = Get-State
    # The main menu is reported before its buttons exist, so wait until options are listed.
    if ($state -and $state.state_type -eq 'menu' -and $state.menu_screen -eq 'main' -and @($state.options).Count -gt 0) { break }
}
Start-Sleep -Seconds 2
$state = Get-State
if (-not $state -or $state.menu_screen -ne 'main') {
    throw "The mod did not reach the main menu within $TimeoutSeconds seconds. Is the STS2_MCP mod installed and enabled?"
}

$body = @{ action = 'menu_select'; option = 'instant_mode' } | ConvertTo-Json -Compress
$result = (Invoke-WebRequest $api -Method Post -Body $body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
Write-Output "Instant Mode: $($result.status) - $($result.message)"
Write-Output "Main menu options: $($state.options -join ', ')"
if ($state.blocked_options) {
    Write-Output "Blocked options: $(($state.blocked_options | ForEach-Object { "$($_.name) ($($_.reason))" }) -join ', ')"
}
