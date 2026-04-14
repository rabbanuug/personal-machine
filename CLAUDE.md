# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Automated machine bootstrap for a DevOps engineer who switches between Linux (Ubuntu/Debian) and Windows machines. One command provisions a new machine: installs tools, applies dotfiles, and restores `.claude` config.

## Bootstrap Commands

**Linux (fresh machine):**
```bash
curl -fsSL https://raw.githubusercontent.com/rabbanuug/personal-machine/main/bootstrap.sh | bash
```

**Windows (fresh machine, PowerShell):**
```powershell
irm https://raw.githubusercontent.com/rabbanuug/personal-machine/main/bootstrap.ps1 | iex
```

**Windows fallback (no PowerShell — CMD only):**
```cmd
curl -fsSL -o install.cmd https://raw.githubusercontent.com/rabbanuug/personal-machine/main/install.cmd && install.cmd
```

## Day-to-Day Workflow

After making changes to settings, commands, or hooks on any machine:
```bash
dotpush          # syncs ~/.claude tracked files to repo + stages dotfiles/
git -C ~/projects/personal-machine commit -m "chore: update dotfiles"
git -C ~/projects/personal-machine push
```

To pull updates on another machine:
```bash
dotpull          # git pull + re-links dotfiles (symlinks auto-update on Linux)
```

## Structure

```
bootstrap.sh / bootstrap.ps1   — entry points; idempotent
install.cmd                    — Windows CMD fallback for Claude Code only
linux/packages.txt             — apt packages installed by bootstrap.sh
windows/packages.txt           — winget packages installed by bootstrap.ps1
dotfiles/
  install.sh / install.ps1     — symlinks dotfiles into ~/
  bash/.bashrc                 — tracked shell config
  bash/.bash_aliases           — dotpush/dotpull aliases
  shell/.profile               — login shell config
  claude/
    settings.json              — Claude Code preferences
    commands/                  — custom slash commands (skills)
    hooks/                     — Claude Code event hooks
    plugins/known_marketplaces.json  — marketplace registry
scripts/
  sync-claude.sh / sync-claude.ps1  — sync ~/.claude to/from repo
```

## How .claude Sync Works

`scripts/sync-claude.sh` has three modes:
- **`link`** — symlinks `dotfiles/claude/` files into `~/.claude/` (run on new machine)
- **`push`** — copies `~/.claude/` tracked files back into repo (run before committing)
- **`pull`** — `git pull` + re-link

On Linux, symlinks mean edits to `~/.claude/settings.json` or adding a new command in `~/.claude/commands/` are instantly in the repo. On Windows, `push` is needed to copy changes back.

## What Is NOT Tracked

`~/.claude/.credentials.json`, session data, history, cache, plans, project-specific state. See `.gitignore` for the full exclusion list.

Per-project memory lives at `~/.claude/projects/<encoded-path>/memory/` — managed per-project, not synced here.

## Key Details

- `install.cmd` accepts `stable`, `latest`, or a semver string; defaults to `latest`
- Windows installer targets `win32-x64` or `win32-arm64` automatically; 32-bit Windows not supported
- `dotfiles/install.sh` backs up any existing real files before symlinking (suffix `.bak.<timestamp>`)
