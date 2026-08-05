# dotfiles

Personal config for tmux, Helix, and bash. Stored at the same path each file
occupies under `$HOME`; `install.sh` symlinks them into place.

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
| `.config/helix/config.toml`, `languages.toml` | Helix (clangd, pyright, ruff) |
| `.config/lazygit/config.yml` | lazygit (opens files in Helix) |
| `.bashrc`, `.profile` | bash |

## Notes

- **tmux:** plugins are TPM-managed. `install.sh` clones TPM and fetches them.
  Session state auto-saves every 15 min and restores on a fresh tmux server.
- **helix:** `install.sh` installs `hx` via snap and `ruff` via the astral
  script when missing. Go-to-definition needs a language server on `PATH`
  (`clangd` for C/C++, `pyright` for Python); C/C++ also wants a
  `compile_commands.json` in the project root. Browse themes live with
  `:theme <name>`.
- **lazygit:** `install.sh` fetches the prebuilt binary into `~/.local/bin`
  (needs `gh`). Configured to open files in Helix (`e` in the Files panel).
- **bash:** `.bashrc`/`.profile` may carry machine-specific `PATH`/env. Review
  after pulling onto a new box.
