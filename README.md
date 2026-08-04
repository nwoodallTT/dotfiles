# dotfiles

Personal config for tmux, Neovim, Helix, and bash. Stored at the same path each
file occupies under `$HOME`; `install.sh` symlinks them into place.

## New machine

```sh
git clone https://github.com/<you>/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is idempotent. Existing files are moved to
`~/.dotfiles-backup/<timestamp>/` before a symlink replaces them.

## What's tracked

| Path | Tool |
|---|---|
| `.tmux.conf` | tmux + TPM (resurrect, continuum) |
| `.config/nvim/init.lua`, `lazy-lock.json` | Neovim (lazy.nvim) |
| `.config/helix/config.toml`, `languages.toml` | Helix (clangd, pyright, ruff) |
| `.bashrc`, `.profile` | bash |

## Notes

- **tmux:** plugins are TPM-managed. `install.sh` clones TPM and fetches them.
  Session state auto-saves every 15 min and restores on a fresh tmux server.
- **nvim:** `init.lua` bootstraps lazy.nvim on first launch. `lazy-lock.json`
  pins plugin versions — commit it after `:Lazy update` to keep machines in sync.
- **helix:** `install.sh` installs `hx` via snap and `ruff` via the astral
  script when missing. Go-to-definition needs a language server on `PATH`
  (`clangd` for C/C++, `pyright` for Python); C/C++ also wants a
  `compile_commands.json` in the project root. Browse themes live with
  `:theme <name>`.
- **bash:** `.bashrc`/`.profile` may carry machine-specific `PATH`/env. Review
  after pulling onto a new box.
