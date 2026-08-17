# dotfiles

Work machine config. macOS (Apple Silicon), zsh, Ghostty, Neovim.
Everything terminal-facing is themed **Tokyo Night**.

---

## New machine runbook

### Phase 1 — The unlock chain

Order is load-bearing. Each step gates the next: git auth *and* commit signing both route
through the 1Password SSH agent, so **no clone happens until step 3**.

| # | Step | Unlocks |
|---|------|---------|
| 1 | macOS setup, Apple ID, **FileVault on** | — |
| 2 | MDM / Jamf enrolment — Self Service, Defender, FortiClient VPN, Teams, LucidLink | Company apps + network |
| 3 | 1Password → **enable SSH agent** (Settings → Developer) + browser extension | SSH + commit signing |
| 4 | `xcode-select --install` | git, compilers |
| 5 | Homebrew | everything below |
| 6 | `git clone git@github.com:pd-fa/dotfiles.git ~/.config` | shell, nvim, ghostty |

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
git clone git@github.com:pd-fa/dotfiles.git ~/.config
```

> **Gotcha:** without the 1Password SSH agent enabled, `git clone` fails with
> `Permission denied (publickey)` and commits fail to sign. Do **not** copy
> `~/.ssh/id_ed25519` from the old machine — the key lives in 1Password.

### Phase 2 — Tooling

```bash
brew bundle --file=~/.config/Brewfile
```

Installs everything CLI-side: neovim, ghostty, mise, starship, direnv, bat, btop, yazi,
k9s, act, atuin, eza, fd, fzf, zoxide, lazygit, tmux, gh, 1password-cli, betterleaks.

Apps not in the Brewfile:

```bash
brew install --cask google-cloud-sdk podman-desktop tableplus dia obsidian raycast
brew install --cask claude-code copilot-cli
gcloud components install gke-gcloud-auth-plugin
podman machine init && podman machine start
```

Teams, Defender, FortiClient and LucidLink arrive via Jamf — don't brew them.

### Phase 3 — Shell

```bash
ln -sf ~/.config/zsh/.zshrc    ~/.zshrc
ln -sf ~/.config/zsh/.zprofile ~/.zprofile
ln -sf ~/.config/zsh/.zshenv   ~/.zshenv
ln -sf ~/.config/ai/AGENTS.md  ~/AGENTS.md
ln -sf ~/.config/ai/AGENTS.md  ~/CLAUDE.md
ln -sf ~/.config/ai/AGENTS.md  ~/GEMINI.md
ln -sf ~/.config/ai/claude/settings.json ~/.claude/settings.json
git config --global core.hooksPath ~/.config/git/hooks
exec zsh -l
```

Then:

- `mise install` — picks up node 22 from `mise/config.toml`
- `nvim` — LazyVim installs plugins, then `:Mason` for LSPs (slowest step, start it early)
- **atuin history** — not synced to a server. Restore from the 1Password document:

  ```bash
  op document get "atuin history backup 2026-08-17" --vault Work --output /tmp/atuin.tar.gz
  mkdir -p ~/.local/share && tar xzf /tmp/atuin.tar.gz -C ~/.local/share && rm /tmp/atuin.tar.gz
  ```

  Restore **before** first launching atuin, so it doesn't create an empty db first.
- `bat cache --build` — registers the Tokyo Night theme

`zsh/fzf-tab/` is an upstream clone, gitignored, and bootstrapped by `.zshrc` on first run.

### Phase 4 — Cloud access

```bash
gh auth login                    # pd-fa account
gcloud init                      # paul.dolden@thefa.com / the-fa-api-prod

gcloud container clusters get-credentials helix-monitoring \
  --zone europe-west2-a --project the-fa-helix-infra
gcloud container clusters get-credentials helix-obs-infra-cluster \
  --zone europe-west2-a --project the-fa-helix-infra
gcloud container clusters get-credentials the-fa-sandbox-helix-obs-infra-cluster \
  --zone europe-west2-a --project the-fa-sandbox
```

`dbp()` and `corev2()` in `zsh/functions.zsh` need `cloud-sql-proxy` in `~/`.

---

## Layout

| Path | What |
| --- | --- |
| `zsh/` | `.zshrc`, `.zprofile`, `.zshenv`, aliases, exports, functions |
| `nvim/` | LazyVim |
| `ghostty/`, `tmux/` | Terminal + multiplexer |
| `starship.toml` | Prompt |
| `git/hooks/` | Global hooks — enabled via `core.hooksPath` |
| `mise/` | Runtime versions |
| `bat/`, `btop/`, `yazi/`, `k9s/`, `lazygit/` | Tool configs + themes |

## Conventions

- **Runtimes** via `mise`, not nvm/asdf. Global defaults in `mise/config.toml`, per-project
  via `.mise.toml`.
- **Per-project env** via `direnv`.
- **Secrets never land in this repo.** `betterleaks` runs as a global pre-commit hook.
  Bypass with `--no-verify` only for confirmed false positives.
- **Machine-local state** (`gcloud/`, `raycast/`, `github-copilot/`, `1Password/`) is gitignored.
- `DOCKER_HOST` derives from `$TMPDIR` — never hardcode the `/var/folders` ID, it differs per machine.

## AI tooling

One instruction file, one MCP source of truth, no tokens on disk.

| Path | What |
| --- | --- |
| `ai/AGENTS.md` | Single instruction file. `~/AGENTS.md` and `~/CLAUDE.md` both symlink to it |
| `ai/mcp-servers.json` | Canonical MCP server definitions — 1Password `op://` refs, no literal secrets |
| `ai/sync-mcp.py` | Renders the tool-specific configs from canonical |
| `ai/claude/settings.json` | Claude Code plugins + permissions |
| `ai/skills/` | Hand-written Claude skills. Symlink each into `~/.claude/skills/` |

```bash
mkdir -p ~/.claude/skills
for s in ~/.config/ai/skills/*/; do ln -sfn "$s" ~/.claude/skills/"$(basename "$s")"; done
```

Skills provided by plugins live in `~/.agents/skills` and are reproduced by reinstalling
the plugins — only hand-written ones are tracked here.

```bash
python3 ~/.config/ai/sync-mcp.py     # after editing mcp-servers.json
```

Writes `~/.claude.json` (merged in place — it is a mutable state file) and
`~/.copilot/mcp-config.json` (overwritten).

**Secrets.** MCP servers that need a credential are spawned via `op run`, which resolves
`op://` references at launch. Nothing is stored in the config:

```json
"command": "op",
"args": ["run", "--", "podman", "run", ...],
"env": { "SONARQUBE_TOKEN": "op://Work/SonarCloud MCP/credential" }
```

**Use `podman`, never `docker`.** `docker` is a shell alias here — MCP servers spawn
without a shell, so a `docker` command silently fails to start.

`targets` in `mcp-servers.json` selects which tool gets which server. Claude Code already
gets atlassian/github/playwright from its plugin marketplace, so those are Copilot-only.

## Not managed here

Not reproducible from this repo — carry these by hand when moving machines:

| Path | Why |
| --- | --- |
| `~/.local/share/atuin/` | Shell history + encryption key. Stored as a 1Password document (Work vault) |
| `~/.gnupg` | GPG keys, separate from the 1Password SSH key that signs commits |

`~/.gitconfig` is now `git/config` in this repo, read natively by git via XDG.
