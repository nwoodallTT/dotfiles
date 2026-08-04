#!/usr/bin/env bash
# Symlink the tracked dotfiles into $HOME and bootstrap tmux's plugin manager.
# Idempotent: re-running relinks cleanly and skips work already done.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%dT%H%M%S)"

# Files are stored at the same path they occupy under $HOME, so the repo
# layout is the source of truth for where each symlink lands.
FILES=(
  .tmux.conf
  .bashrc
  .profile
  .config/nvim/init.lua
  .config/nvim/lazy-lock.json
  .config/helix/config.toml
  .config/helix/languages.toml
)

link() {
  local rel="$1"
  local src="$DOTFILES/$rel"
  local dst="$HOME/$rel"

  mkdir -p "$(dirname "$dst")"

  # Already the correct symlink — nothing to do.
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok    $rel"
    return
  fi

  # A real file/dir is in the way: preserve it before clobbering.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$(dirname "$BACKUP/$rel")"
    mv "$dst" "$BACKUP/$rel"
    echo "backup $rel -> $BACKUP/$rel"
  fi

  ln -s "$src" "$dst"
  echo "link  $rel"
}

for f in "${FILES[@]}"; do
  link "$f"
done

# tmux-resurrect/continuum are managed by TPM, which must exist before the
# plugins can be fetched on a fresh machine.
TPM="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM" ]; then
  echo "cloning TPM"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
fi
if [ -x "$TPM/bin/install_plugins" ]; then
  "$TPM/bin/install_plugins" || true
fi

# Helix + its Python formatter. Non-fatal: a box without snap still gets the
# symlinked config, just no editor until installed by hand.
if ! command -v hx >/dev/null 2>&1; then
  if command -v snap >/dev/null 2>&1; then
    echo "installing helix"
    sudo snap install helix --classic || true
  else
    echo "skip  helix (no snap; install manually)"
  fi
fi
if ! command -v ruff >/dev/null 2>&1; then
  echo "installing ruff"
  curl -LsSf https://astral.sh/ruff/install.sh | sh || true
fi

echo
echo "Done. Open a new shell, then run 'tmux' (plugins auto-install/restore)."
echo "Neovim bootstraps lazy.nvim on first launch."
