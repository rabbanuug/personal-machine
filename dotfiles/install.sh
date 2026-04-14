#!/usr/bin/env bash
# dotfiles/install.sh — idempotent symlinker for Linux dotfiles
# Creates symlinks from ~/ into the repo. Backs up any existing real files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$1" dst="$2"

    # Already correctly symlinked — skip
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        return
    fi

    # Real file exists — back it up
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

echo "Installing dotfiles..."

link "$SCRIPT_DIR/bash/.bashrc"       "$HOME/.bashrc"
link "$SCRIPT_DIR/bash/.bash_aliases" "$HOME/.bash_aliases"
link "$SCRIPT_DIR/shell/.profile"     "$HOME/.profile"

echo "Syncing .claude config..."
bash "$(dirname "$SCRIPT_DIR")/scripts/sync-claude.sh" link

echo ""
echo "Dotfiles installed. Run 'source ~/.bashrc' to apply shell changes."
