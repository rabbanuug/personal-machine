#!/usr/bin/env bash
# sync-claude.sh — sync ~/.claude tracked files to/from the dotfiles repo
#
# Usage:
#   sync-claude.sh link   — symlink repo dotfiles/claude/ into ~/.claude (default)
#   sync-claude.sh push   — copy ~/.claude tracked files back into repo (before committing)
#   sync-claude.sh pull   — git pull + re-link (idempotent)

set -euo pipefail

ACTION="${1:-link}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CLAUDE="$SCRIPT_DIR/../dotfiles/claude"
HOME_CLAUDE="$HOME/.claude"

# Individual files to track (symlinked directly)
TRACKED_FILES=(
    settings.json
    "plugins/known_marketplaces.json"
)

# Directories to track (symlinked as whole dirs)
TRACKED_DIRS=(
    commands
    hooks
)

_link_item() {
    local src="$1" dst="$2"
    local dst_dir
    dst_dir="$(dirname "$dst")"

    mkdir -p "$dst_dir"

    # Already correctly symlinked — skip
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        return
    fi

    # Real file/dir exists — back it up
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        local backup="${dst}.bak.$(date +%s)"
        mv "$dst" "$backup"
        echo "  Backed up: $dst -> $backup"
    fi

    # Remove stale symlink
    [[ -L "$dst" ]] && rm "$dst"

    ln -sf "$src" "$dst"
    echo "  Linked: $dst"
}

cmd_link() {
    echo "Linking .claude config from repo..."
    mkdir -p "$HOME_CLAUDE"

    for f in "${TRACKED_FILES[@]}"; do
        src="$(realpath "$REPO_CLAUDE/$f")"
        dst="$HOME_CLAUDE/$f"
        [[ -f "$src" ]] || continue
        _link_item "$src" "$dst"
    done

    for d in "${TRACKED_DIRS[@]}"; do
        src="$(realpath "$REPO_CLAUDE/$d")"
        dst="$HOME_CLAUDE/$d"
        [[ -d "$src" ]] || continue
        _link_item "$src" "$dst"
    done

    echo "Done. ~/.claude config is now linked from the repo."
}

cmd_push() {
    echo "Pushing ~/.claude tracked files to repo..."

    for f in "${TRACKED_FILES[@]}"; do
        src="$HOME_CLAUDE/$f"
        dst="$REPO_CLAUDE/$f"
        [[ -f "$src" ]] || continue
        # Skip if src is already a symlink pointing to dst (already linked — same file)
        if [[ -L "$src" ]]; then
            echo "  Skipped (symlinked): $f"
            continue
        fi
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "  Copied: $f"
    done

    for d in "${TRACKED_DIRS[@]}"; do
        src="$HOME_CLAUDE/$d"
        dst="$REPO_CLAUDE/$d"
        [[ -d "$src" ]] || continue
        if [[ -L "$src" ]]; then
            echo "  Skipped (symlinked): $d/"
            continue
        fi
        rsync -a --delete "$src/" "$dst/"
        echo "  Synced: $d/"
    done

    echo "Done. Run 'git add dotfiles/ && git commit' to save changes."
}

cmd_pull() {
    echo "Pulling latest from repo and re-linking..."
    local repo_root
    repo_root="$(realpath "$SCRIPT_DIR/..")"
    git -C "$repo_root" pull --ff-only
    cmd_link
}

case "$ACTION" in
    link) cmd_link ;;
    push) cmd_push ;;
    pull) cmd_pull ;;
    *)
        echo "Usage: $0 [link|push|pull]" >&2
        exit 1
        ;;
esac
