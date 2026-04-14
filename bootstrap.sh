#!/usr/bin/env bash
# bootstrap.sh — idempotent machine setup for Ubuntu/Debian
#
# Usage on a fresh machine:
#   curl -fsSL https://raw.githubusercontent.com/rabbanuug/personal-machine/main/bootstrap.sh | bash
#
# Or if the repo is already cloned:
#   bash ~/projects/personal-machine/bootstrap.sh

set -euo pipefail

REPO_URL="https://github.com/rabbanuug/personal-machine.git"
REPO_DIR="${REPO_DIR:-$HOME/Desktop/projects/personal-machine}"

# ── Helpers ───────────────────────────────────────────────────────────────────

info()    { echo "[bootstrap] $*"; }
success() { echo "[bootstrap] ✓ $*"; }
skip()    { echo "[bootstrap] - $* (already installed)"; }

has() { command -v "$1" &>/dev/null; }

# ── 1. Platform check ─────────────────────────────────────────────────────────

if [[ ! -f /etc/debian_version ]]; then
    echo "ERROR: This script targets Ubuntu/Debian only." >&2
    exit 1
fi

# ── 2. Base packages ──────────────────────────────────────────────────────────

info "Updating apt..."
sudo apt-get update -qq

# Minimal set needed before we can clone the repo
sudo apt-get install -y git curl

# ── 3. Clone or update the repo ───────────────────────────────────────────────

if [[ -d "$REPO_DIR/.git" ]]; then
    info "Updating repo at $REPO_DIR..."
    git -C "$REPO_DIR" pull --ff-only
else
    info "Cloning repo to $REPO_DIR..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
fi

# ── 4. Install packages from packages.txt ────────────────────────────────────

PACKAGES=()
while IFS= read -r line; do
    # Strip comments and blank lines
    line="${line%%#*}"
    line="${line// /}"
    [[ -n "$line" ]] && PACKAGES+=("$line")
done < "$REPO_DIR/linux/packages.txt"

info "Installing packages: ${PACKAGES[*]}"
sudo apt-get install -y "${PACKAGES[@]}"
success "System packages installed"

# ── 5. Claude Code ────────────────────────────────────────────────────────────

if has claude; then
    skip "Claude Code"
else
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    success "Claude Code installed"
fi

# ── 6. Qwen Code ─────────────────────────────────────────────────────────────

if has qwen; then
    skip "Qwen Code"
else
    info "Installing Qwen Code..."
    bash -c "$(curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen.sh)" -s --source qwenchat
    success "Qwen Code installed"
fi

# ── 7. Dotfiles ───────────────────────────────────────────────────────────────

info "Installing dotfiles..."
bash "$REPO_DIR/dotfiles/install.sh"
success "Dotfiles installed"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "Bootstrap complete! Open a new terminal or run: source ~/.bashrc"
