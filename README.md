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

> **Gotcha:** MDM-pushed installers (the Xerox print client is one) can create
> `~/Library/LaunchAgents` owned by **root**, which makes any `brew services`
> start fail with `Permission denied @ rb_sysopen`. Nothing in the Brewfile
> registers a service today, so the bootstrap only notes it. If you ever add a
> formula with `restart_service:`, the fix is:
>
> ```bash
> sudo chown "$(id -un)" ~/Library/LaunchAgents
> ```

### Phase 2 — Run the bootstrap

```bash
~/.config/bootstrap.sh
```

> **This repo is shared.** Nothing tracked in it names an individual. Your own
> identity and machine-local settings live in two untracked files, which the
> bootstrap seeds from their `.example` siblings on first run:
>
> | File | Holds |
> |------|-------|
> | `git/config.local` | `user.name`, `user.email`, `user.signingkey` — included last by `git/config` |
> | `bootstrap.local` | `ATUIN_BACKUP_DOC` / `ATUIN_BACKUP_VAULT` for your own history restore |
>
> Fill in `git/config.local` before your first commit, or signing fails and the
> bootstrap exits non-zero telling you so. Add your public key to
> `git/allowed_signers` (tracked) so colleagues can verify your commits.
>
> `gh/hosts.yml` is untracked too — run `gh auth login` to write your own.
>
> **If you cloned before this change** you inherited the previous owner's
> `git/config` identity and `gh/hosts.yml`. Both are fixed by pulling: the
> identity is replaced by the genericised `git/config`, and `hosts.yml` is
> deleted outright because this commit removes it from the repo. Then re-run the
> bootstrap and fill in `git/config.local`. To drop a stale account gh still
> remembers: `gh auth logout -u <name>`.

Idempotent, so re-run it any time — the `bootstrap` alias runs it and reloads the shell in
one go, which is the normal way to pick up a change to this repo. It installs the Brewfile
(CLI tools, casks and the
**Nerd Font** — without which every glyph renders as tofu), links shell and agent config
into `$HOME`, wires the git hooks, installs runtimes via mise, builds the bat theme cache,
brings up the podman machine, renders the MCP configs, and restores atuin history from
1Password if it isn't already there.

Phase 1 is deliberately not scripted — MDM, the 1Password GUI and Xcode CLT are all
interactive.

> **Gotcha:** Homebrew's `podman` formula ships `gvproxy` and `vfkit` but **not**
> `krunkit`, and podman defaults to the `libkrun` provider on Apple Silicon — so a
> CLI-only install dies at `podman machine start` with *"There is a problem finding
> the 'krunkit' binary"*. The Brewfile pins the `libkrun/krun` tap and trusts its
> formulae, so the bootstrap covers it. `krunkit` is absent from homebrew-core
> because the binary needs a `Hypervisor.framework` codesigning entitlement.

Apps not in the Brewfile:

```bash
brew install --cask podman-desktop dia obsidian raycast
gcloud components install gke-gcloud-auth-plugin
```

Teams, Defender, FortiClient and LucidLink arrive via Jamf — don't brew them.

### Phase 3 — First launches

```bash
exec zsh -l
```

- `nvim` — LazyVim installs plugins, then `:Mason` for LSPs (slowest step, start it early)
- `tmux` — tpm self-bootstraps and installs plugins on first run
- `zsh/fzf-tab/` is an upstream clone, gitignored, cloned by `.zshrc` on first run

**Sign into 1Password CLI (`op signin`) before the bootstrap** if you want atuin history
restored automatically — the script skips that step when `op` isn't authenticated, and
restoring after atuin has created an empty db is messier.

### Phase 4 — Cloud access

```bash
gh auth login                    # your own work GitHub account
gcloud init                      # your own @thefa.com account / the-fa-api-prod

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

- **Runtimes and CLI tooling** via `mise`, not nvm/asdf/rustup or a manual Go install.
  `mise/config.toml` declares node, python, go and rust alongside the CLI tools;
  `mise install` provisions the lot. Per-project overrides via `.mise.toml`.
- **The Brewfile keeps what mise cannot.** System libraries (`libpq`, `poppler`,
  `gstreamer`, `pkgconf`), zsh plugins that are sourced from brew's `share/`, podman and
  `krunkit`, the hook and daemon tools (`atuin`, `direnv`, `betterleaks`), `mise` itself,
  and `btop`, whose mise package is Linux-only.
- **Do not run `brew bundle cleanup --force`.** `GOBIN` points inside mise's go install, and
  brew's `go` extension owns whatever `GOBIN` names — so cleanup reads go's own binary as an
  untracked `go install` and deletes it. The bootstrap reports the drift instead.
- **Per-project env** via `direnv`.
- **Secrets never land in this repo.** `betterleaks` runs as a global pre-commit hook.
  Bypass with `--no-verify` only for confirmed false positives.
- **Machine-local state** (`gcloud/`, `raycast/`, `github-copilot/`, `1Password/`) is gitignored.
- `DOCKER_HOST` derives from `$TMPDIR` — never hardcode the `/var/folders` ID, it differs per
  machine. The socket is named after the podman machine (`podman-machine-default-api.sock`),
  so renaming the machine breaks it silently.

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
