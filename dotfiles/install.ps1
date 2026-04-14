#Requires -Version 5.1
# dotfiles/install.ps1 — idempotent dotfiles installer for Windows
# Uses directory junctions (no elevation needed) for dirs, copies for files.

param(
    [string]$RepoDir = (Split-Path $PSScriptRoot -Parent)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-Dotfile {
    param([string]$Src, [string]$Dst)

    $dstDir = Split-Path $Dst
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    if (Test-Path $Dst) {
        $srcHash = (Get-FileHash $Src -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash $Dst -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) { return }  # already up to date

        $backup = "$Dst.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $Dst $backup
        Write-Host "  Backed up: $Dst"
    }

    Copy-Item $Src $Dst -Force
    Write-Host "  Installed: $Dst"
}

function Install-Junction {
    param([string]$Src, [string]$Dst)

    if (Test-Path $Dst) {
        $item = Get-Item $Dst -Force
        # Already a junction pointing to the right place
        if ($item.LinkType -eq 'Junction' -and $item.Target -eq $Src) { return }

        $backup = "$Dst.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Rename-Item $Dst $backup
        Write-Host "  Backed up: $Dst"
    }

    cmd /c mklink /J `"$Dst`" `"$Src`" | Out-Null
    Write-Host "  Junction: $Dst -> $Src"
}

$d = "$RepoDir\dotfiles"

Write-Host "Installing dotfiles..."
Install-Dotfile "$d\bash\.bashrc"    "$env:USERPROFILE\.bashrc"
Install-Dotfile "$d\shell\.profile"  "$env:USERPROFILE\.profile"

Write-Host "Syncing .claude config..."
& "$RepoDir\scripts\sync-claude.ps1" -Action link

Write-Host ""
Write-Host "Dotfiles installed."
