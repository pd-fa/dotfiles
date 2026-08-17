# dotfiles

Work machine config. macOS (Apple Silicon), zsh, Ghostty, Neovim.

Everything terminal-facing is themed **Tokyo Night**.

## Bootstrap

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

git clone git@github.com:pd-fa/dotfiles.git ~/.config
brew bundle --file=~/.config/Brewfile

ln -sf ~/.config/zsh/.zshrc    ~/.zshrc
ln -sf ~/.config/zsh/.zprofile ~/.zprofile
ln -sf ~/.config/zsh/.zshenv   ~/.zshenv
exec zsh -l
```

1Password must be installed with the **SSH agent enabled** before cloning — git auth and
commit signing both route through it (`~/.gitconfig` uses `op-ssh-sign`).

## Layout

| Path | What |
| --- | --- |
| `zsh/` | `.zshrc`, `.zprofile`, `.zshenv`, aliases, exports, functions |
| `nvim/` | LazyVim |
| `ghostty/`, `tmux/` | Terminal + multiplexer |
| `starship.toml` | Prompt |
| `git/hooks/` | Global hooks — enabled via `core.hooksPath` |
| `mise/` | Runtime versions (node, python, go) |
| `bat/`, `btop/`, `yazi/`, `k9s/`, `lazygit/` | Tool configs + themes |

## Conventions

- **Runtimes** are managed by `mise`, not nvm/asdf. Global defaults in `mise/config.toml`;
  per-project via `.mise.toml`.
- **Per-project env** via `direnv`.
- **Secrets never land in this repo.** `betterleaks` runs as a global pre-commit hook:

  ```bash
  git config --global core.hooksPath ~/.config/git/hooks
  ```

  Bypass with `--no-verify` only for confirmed false positives.
- `zsh/fzf-tab/` is an upstream clone, gitignored, and bootstrapped by `.zshrc` on first run.
- Machine-local state (`gcloud/`, `raycast/`, `github-copilot/`, `1Password/`) is gitignored.
