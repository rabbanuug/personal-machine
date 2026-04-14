#Requires -Version 5.1
# sync-claude.ps1 — sync ~/.claude tracked files to/from the dotfiles repo (Windows)
#
# Usage:
#   .\sync-claude.ps1 -Action link   — copy/junction repo dotfiles/claude/ into %USERPROFILE%\.claude
#   .\sync-claude.ps1 -Action push   — copy %USERPROFILE%\.claude tracked files back into repo
#   .\sync-claude.ps1 -Action pull   — git pull + re-link

param(
    [ValidateSet('link', 'push', 'pull')]
    [string]$Action = 'link'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoDir   = Split-Path $PSScriptRoot -Parent
$RepoClaude = Join-Path $RepoDir 'dotfiles\claude'
$HomeClaude = Join-Path $env:USERPROFILE '.claude'

$TrackedFiles = @(
    'settings.json',
    'plugins\known_marketplaces.json'
)

$TrackedDirs = @(
    'commands',
    'hooks'
)

function Backup-IfExists([string]$Path) {
    if (Test-Path $Path) {
        $backup = "$Path.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Rename-Item $Path $backup
        Write-Host "  Backed up: $Path"
    }
}

function Invoke-Link {
    Write-Host "Linking .claude config from repo..."
    if (-not (Test-Path $HomeClaude)) { New-Item -ItemType Directory -Path $HomeClaude -Force | Out-Null }

    foreach ($f in $TrackedFiles) {
        $src = Join-Path $RepoClaude $f
        $dst = Join-Path $HomeClaude $f
        if (-not (Test-Path $src)) { continue }

        $dstDir = Split-Path $dst
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

        if (Test-Path $dst) {
            $srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
            $dstHash = (Get-FileHash $dst -Algorithm SHA256).Hash
            if ($srcHash -eq $dstHash) { continue }
            Backup-IfExists $dst
        }
        Copy-Item $src $dst -Force
        Write-Host "  Copied: $f"
    }

    foreach ($d in $TrackedDirs) {
        $src = Join-Path $RepoClaude $d
        $dst = Join-Path $HomeClaude $d
        if (-not (Test-Path $src)) { continue }

        $item = if (Test-Path $dst) { Get-Item $dst -Force } else { $null }
        if ($item -and $item.LinkType -eq 'Junction' -and $item.Target -eq $src) { continue }

        Backup-IfExists $dst
        cmd /c mklink /J `"$dst`" `"$src`" | Out-Null
        Write-Host "  Junction: $dst -> $src"
    }

    Write-Host "Done."
}

function Invoke-Push {
    Write-Host "Pushing .claude tracked files to repo..."

    foreach ($f in $TrackedFiles) {
        $src = Join-Path $HomeClaude $f
        $dst = Join-Path $RepoClaude $f
        if (-not (Test-Path $src)) { continue }

        $dstDir = Split-Path $dst
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

        $srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
        $dstHash = if (Test-Path $dst) { (Get-FileHash $dst -Algorithm SHA256).Hash } else { '' }
        if ($srcHash -eq $dstHash) { continue }

        Copy-Item $src $dst -Force
        Write-Host "  Copied: $f"
    }

    foreach ($d in $TrackedDirs) {
        $src = Join-Path $HomeClaude $d
        $dst = Join-Path $RepoClaude $d
        if (-not (Test-Path $src)) { continue }

        # If src is a junction pointing to dst, nothing to copy
        $item = Get-Item $src -Force
        if ($item.LinkType -eq 'Junction' -and $item.Target -eq $dst) {
            Write-Host "  Skipped (junction): $d\"
            continue
        }

        robocopy $src $dst /MIR /NJH /NJS /NFL /NDL | Out-Null
        Write-Host "  Synced: $d\"
    }

    Write-Host "Done. Run 'git add dotfiles/ && git commit' to save changes."
}

function Invoke-Pull {
    Write-Host "Pulling latest from repo and re-linking..."
    git -C $RepoDir pull --ff-only
    Invoke-Link
}

switch ($Action) {
    'link' { Invoke-Link }
    'push' { Invoke-Push }
    'pull' { Invoke-Pull }
}
