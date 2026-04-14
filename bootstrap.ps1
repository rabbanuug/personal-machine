#Requires -Version 5.1
# bootstrap.ps1 — idempotent machine setup for Windows
#
# Usage on a fresh machine (in PowerShell):
#   irm https://raw.githubusercontent.com/rabbanuug/personal-machine/main/bootstrap.ps1 | iex
#
# Or if the repo is already cloned:
#   .\bootstrap.ps1

[CmdletBinding()]
param(
    [string]$RepoDir = "$env:USERPROFILE\Desktop\projects\personal-machine"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/rabbanuug/personal-machine.git'

function info($msg)    { Write-Host "[bootstrap] $msg" }
function success($msg) { Write-Host "[bootstrap] v $msg" }
function skip($msg)    { Write-Host "[bootstrap] - $msg (already installed)" }
function has($cmd)     { $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue) }

# ── 1. Clone or update the repo ───────────────────────────────────────────────

if (Test-Path "$RepoDir\.git") {
    info "Updating repo at $RepoDir..."
    git -C $RepoDir pull --ff-only
} else {
    info "Cloning repo to $RepoDir..."
    $parent = Split-Path $RepoDir
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    git clone $RepoUrl $RepoDir
}

# ── 2. Claude Code ────────────────────────────────────────────────────────────

if (has 'claude') {
    skip 'Claude Code'
} else {
    info 'Installing Claude Code...'
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
    success 'Claude Code installed'
}

# ── 3. Winget packages ────────────────────────────────────────────────────────

if (has 'winget') {
    $packages = Get-Content "$RepoDir\windows\packages.txt" |
        Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' }

    foreach ($pkg in $packages) {
        $result = winget list --id $pkg --exact --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            skip $pkg
        } else {
            info "Installing $pkg..."
            winget install --id $pkg --exact --silent `
                --accept-package-agreements --accept-source-agreements
            success "$pkg installed"
        }
    }
} else {
    Write-Warning 'winget not found — skipping package installs. Install App Installer from the Microsoft Store.'
}

# ── 4. Dotfiles ───────────────────────────────────────────────────────────────

info 'Installing dotfiles...'
& "$RepoDir\dotfiles\install.ps1" -RepoDir $RepoDir
success 'Dotfiles installed'

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Bootstrap complete! Restart your terminal to apply changes."
