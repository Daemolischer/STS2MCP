<#
.SYNOPSIS
    Quits Slay the Spire 2 cleanly through the main menu, or force-stops it with -Force.

.DESCRIPTION
    A clean quit only works from the main menu. During a run the script refuses unless -Force is given;
    the game saves when entering a room, so a forced stop can lose progress made in the current room.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\stop-game.ps1
#>
param(
    [switch]$Force,
    [int]$Port = 15526
)

$ErrorActionPreference = 'Stop'
$api = "http://localhost:$Port/api/v1/singleplayer"

function Send-Menu([string]$option) {
    $body = @{ action = 'menu_select'; option = $option } | ConvertTo-Json -Compress
    return (Invoke-WebRequest $api -Method Post -Body $body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
}

function Wait-Exit([int]$seconds) {
    $deadline = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $deadline) {
        if (-not (Get-Process -Name SlayTheSpire2 -ErrorAction SilentlyContinue)) { return $true }
        Start-Sleep -Seconds 1
    }
    return $false
}

if (-not (Get-Process -Name SlayTheSpire2 -ErrorAction SilentlyContinue)) {
    Write-Output 'Slay the Spire 2 is not running.'
    exit 0
}

$state = $null
try { $state = (Invoke-WebRequest "$api`?format=json" -UseBasicParsing -TimeoutSec 3).Content | ConvertFrom-Json } catch { }

if ($state -and $state.state_type -eq 'menu' -and $state.menu_screen -eq 'main') {
    $null = Send-Menu 'quit'
    Start-Sleep -Seconds 2
    $popup = (Invoke-WebRequest "$api`?format=json" -UseBasicParsing -TimeoutSec 3).Content | ConvertFrom-Json
    $confirm = $popup.options | Where-Object { $_.name -in @('ja', 'yes') } | Select-Object -First 1
    if ($confirm) { $null = Send-Menu $confirm.name }
    if (Wait-Exit 20) { Write-Output 'Slay the Spire 2 quit cleanly.'; exit 0 }
    Write-Output 'The game did not exit after quitting from the main menu.'
} elseif (-not $Force) {
    $where = if ($state) { "state '$($state.state_type)'" } else { 'an unreachable API' }
    throw "The game is not in the main menu ($where). Return to the main menu first, or run with -Force to stop the process."
}

if ($Force) {
    Get-Process -Name SlayTheSpire2 -ErrorAction SilentlyContinue | Stop-Process -Force
    if (Wait-Exit 10) { Write-Output 'Slay the Spire 2 was force-stopped.'; exit 0 }
    throw 'Could not stop Slay the Spire 2.'
}
exit 1
