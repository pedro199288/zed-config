[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

if ($DryRun -eq $Apply) {
    throw "Specify exactly one of -DryRun or -Apply."
}

if (-not $env:APPDATA) {
    throw "APPDATA is not defined; cannot locate the Zed configuration directory."
}

$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../../../.."))
$CommonRoot = Join-Path $RepoRoot "config/common"
$PlatformRoot = Join-Path $RepoRoot "config/windows"
$TargetRoot = Join-Path $env:APPDATA "Zed"
$BackupBase = if ($env:LOCALAPPDATA) {
    Join-Path $env:LOCALAPPDATA "zed-config/backups"
} else {
    Join-Path $HOME "AppData/Local/zed-config/backups"
}
$BackupRoot = Join-Path $BackupBase ((Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ") + "-" + $PID)
$BackupCreated = $false

if (-not (Test-Path -LiteralPath $CommonRoot -PathType Container) -or
    -not (Test-Path -LiteralPath $PlatformRoot -PathType Container)) {
    throw "Expected configuration directories are missing under $RepoRoot/config."
}

$Entries = @{}
foreach ($Root in @($CommonRoot, $PlatformRoot)) {
    Get-ChildItem -LiteralPath $Root -Force | ForEach-Object {
        $Entries[$_.Name] = $_.FullName
    }
}

foreach ($Name in ($Entries.Keys | Sort-Object)) {
    $SourcePath = [IO.Path]::GetFullPath($Entries[$Name])
    $DestinationPath = Join-Path $TargetRoot $Name
    $Existing = Get-Item -LiteralPath $DestinationPath -Force -ErrorAction SilentlyContinue

    if ($null -ne $Existing -and $Existing.LinkType -eq "SymbolicLink") {
        try {
            $ResolvedDestination = (Resolve-Path -LiteralPath $DestinationPath).Path
            $ResolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
            if ($ResolvedDestination -eq $ResolvedSource) {
                Write-Host "ok      $DestinationPath -> $SourcePath"
                continue
            }
        } catch {
            # A broken or inaccessible link is treated as a conflict below.
        }
    }

    if ($DryRun) {
        if ($null -ne $Existing) {
            Write-Host "backup  $DestinationPath"
        }
        Write-Host "link    $DestinationPath -> $SourcePath"
        continue
    }

    New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
    $BackupPath = Join-Path $BackupRoot $Name
    $MovedExisting = $false

    if ($null -ne $Existing) {
        New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
        Move-Item -LiteralPath $DestinationPath -Destination $BackupPath
        $MovedExisting = $true
        $BackupCreated = $true
        Write-Host "backed up $DestinationPath -> $BackupPath"
    }

    try {
        New-Item -ItemType SymbolicLink -Path $DestinationPath -Target $SourcePath | Out-Null
        Write-Host "linked    $DestinationPath -> $SourcePath"
    } catch {
        if ($MovedExisting) {
            Move-Item -LiteralPath $BackupPath -Destination $DestinationPath
            Write-Warning "Restored $DestinationPath after link creation failed."
        }
        throw "Could not create $DestinationPath. Enable Windows Developer Mode or run PowerShell with sufficient privileges. $($_.Exception.Message)"
    }
}

if ($DryRun) {
    Write-Host "Dry run only. Re-run with -Apply to make these changes."
} elseif ($BackupCreated) {
    Write-Host "Backup: $BackupRoot"
}

