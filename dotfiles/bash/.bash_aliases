# Dotfiles management
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Desktop/projects/personal-machine}"

dotpush() {
    "$DOTFILES_DIR/scripts/sync-claude.sh" push && \
    git -C "$DOTFILES_DIR" add dotfiles/ && \
    echo "Staged. Run: git -C $DOTFILES_DIR commit -m 'chore: update dotfiles'"
}

dotpull() {
    git -C "$DOTFILES_DIR" pull --ff-only && \
    "$DOTFILES_DIR/dotfiles/install.sh"
}
