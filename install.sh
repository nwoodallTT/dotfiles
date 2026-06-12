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

# pyright is a Node app; the system node on older Ubuntu is v12, whose parser
# rejects the optional-chaining in pyright's bundle and the server exits before
# attaching. Pin a modern node under ~/.local (already first on PATH via
# .bashrc) so pyright runs without touching the system node.
NODE_VERSION="v20.18.1"
have_node_18() {
  command -v node >/dev/null 2>&1 || return 1
  [ "$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)" -ge 18 ]
}
if have_node_18; then
  echo "ok    node $(node --version)"
else
  case "$(uname -m)" in
    x86_64) NARCH=x64 ;;
    aarch64) NARCH=arm64 ;;
    *) echo "skip  node: unsupported arch $(uname -m)"; NARCH="" ;;
  esac
  if [ -n "$NARCH" ]; then
    echo "fetch node $NODE_VERSION"
    NTMP="$(mktemp -d)"
    NTARBALL="node-$NODE_VERSION-linux-$NARCH"
    curl -fsSL "https://nodejs.org/dist/$NODE_VERSION/$NTARBALL.tar.xz" -o "$NTMP/node.tar.xz"
    tar -xJf "$NTMP/node.tar.xz" -C "$NTMP"
    mkdir -p "$HOME/.local"
    cp -a "$NTMP/$NTARBALL/." "$HOME/.local/"
    rm -rf "$NTMP"
    echo "link  node -> $HOME/.local/bin/node ($("$HOME/.local/bin/node" --version))"
  fi
fi

echo
echo "Done. Open a new shell, then run 'tmux' (plugins auto-install/restore)."
echo "Neovim bootstraps lazy.nvim on first launch."
