#!/usr/bin/env bash
# Bootstrap a new machine from this repo. Idempotent — safe to re-run.
#
# Prerequisites that cannot be scripted (see README Phase 1):
#   MDM enrolment, 1Password with the SSH agent enabled, xcode-select, Homebrew.
#
# Ordering rule: the cheap, always-available steps (symlinks, git config) run
# first so a network or package failure can never leave the shell unconfigured.
# Everything that reaches the network is non-fatal — it records a warning and
# the run continues, so re-running converges instead of restarting from zero.
set -euo pipefail

CONFIG="$HOME/.config"
step() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
skip() { printf '    \033[2m%s\033[0m\n' "$1"; }
warn() { printf '    \033[1;33m!\033[0m %s\n' "$1"; FAILED="${FAILED}  - $1"$'\n'; }
FAILED=""

# Per-person settings. This repo is shared, so nothing here names an individual;
# bootstrap.local is untracked and seeded from bootstrap.local.example.
# shellcheck source=/dev/null
[ -f "$CONFIG/bootstrap.local" ] && . "$CONFIG/bootstrap.local"
ATUIN_BACKUP_DOC="${ATUIN_BACKUP_DOC:-}"
ATUIN_BACKUP_VAULT="${ATUIN_BACKUP_VAULT:-Private}"

[ -d "$CONFIG/.git" ] || { echo "Run after cloning this repo to ~/.config" >&2; exit 1; }

step "Checking prerequisites"
for c in brew git; do
	command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }
done
skip "brew and git present"

step "Linking shell config into \$HOME"
ln -sfn "$CONFIG/zsh/.zshrc" "$HOME/.zshrc"
ln -sfn "$CONFIG/zsh/.zprofile" "$HOME/.zprofile"
ln -sfn "$CONFIG/zsh/.zshenv" "$HOME/.zshenv"
skip ".zshrc .zprofile .zshenv"

step "Linking agent instructions"
for f in AGENTS.md CLAUDE.md GEMINI.md; do
	ln -sfn "$CONFIG/ai/AGENTS.md" "$HOME/$f"
done
skip "AGENTS.md CLAUDE.md GEMINI.md -> ai/AGENTS.md"

step "Linking Claude Code config"
mkdir -p "$HOME/.claude/skills"
ln -sfn "$CONFIG/ai/claude/settings.json" "$HOME/.claude/settings.json"
for s in "$CONFIG"/ai/skills/*/; do
	ln -sfn "${s%/}" "$HOME/.claude/skills/$(basename "$s")"
done
skip "settings.json + $(find "$CONFIG/ai/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ') skills"

# Rendered files are committed, so a fresh clone is already themed; this only
# does work when palette.local.toml overrides the house palette. Non-fatal —
# an unthemed shell is better than an abandoned bootstrap.
step "Rendering themed configs"
if python3 "$CONFIG/theme/sync-theme.py" >/dev/null 2>&1; then
	skip "$(find "$CONFIG/theme/templates" "$CONFIG/theme/upstream" -type f | wc -l | tr -d ' ') configs from theme/palette.toml"
else
	warn "theme render failed - configs keep their committed colours"
fi

step "Linking Hammerspoon config"
# Hammerspoon reads ~/.hammerspoon, not XDG, so this is the one input config
# that needs a link. The directory stays real — Spoons and its own state live
# there and do not belong in this repo.
mkdir -p "$HOME/.hammerspoon"
ln -sfn "$CONFIG/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
skip "init.lua -> hammerspoon/init.lua"

step "Configuring git hooks"
# Set as a tilde path rather than "$CONFIG" so the value committed to git/config
# stays portable — home directory names differ from one machine to the next.
# Git expands ~ in core.hooksPath, as it does for excludesfile.
# shellcheck disable=SC2088  # literal ~ is deliberate: git expands it, not the shell
git config --global core.hooksPath '~/.config/git/hooks'
chmod +x "$CONFIG/git/hooks/"* 2>/dev/null || true
skip "core.hooksPath -> git/hooks (betterleaks pre-commit)"

step "Seeding per-person git identity"
# git/config is shared and carries no name or email; identity lives in the
# untracked config.local, which git/config includes last.
if [ ! -f "$CONFIG/git/config.local" ]; then
	cp "$CONFIG/git/config.local.example" "$CONFIG/git/config.local"
	warn "git/config.local created — fill in your name, email and signingkey"
fi
email=$(git config --get user.email || true)
if [ -z "$email" ] || [ "${email##*@}" = "example.com" ]; then
	warn "git identity is unset or still the example — edit git/config.local before committing"
else
	skip "identity: $email"
fi

step "Applying macOS defaults"
# Narrow by design: only the system settings the Hammerspoon/AeroSpace input
# config depends on. Not a general defaults sweep. Cheap and always available,
# so it runs before anything that reaches the network.
"$CONFIG/macos/defaults.sh"

step "Checking ~/Library/LaunchAgents is writable"
# Some MDM-pushed installers (the Xerox print client, for one) create this
# directory as root, which makes every `brew services` start fail with an
# opaque "Permission denied @ rb_sysopen". Nothing in the Brewfile currently
# registers a service, so this is a note rather than a warning — it does not
# fail the run. It matters the moment a formula with `restart_service:` is added.
if [ -d "$HOME/Library/LaunchAgents" ] && [ ! -w "$HOME/Library/LaunchAgents" ]; then
	# shellcheck disable=SC2088  # literal ~ is deliberate: this is a message to copy-paste
	skip "owned by $(stat -f %Su "$HOME/Library/LaunchAgents"), not you — harmless today, but brew services would fail; fix with: sudo chown $(id -un) ~/Library/LaunchAgents"
else
	skip "writable"
fi

step "Installing packages (brew bundle)"
# Non-fatal: one unavailable package must not abandon the rest of the bootstrap.
# brew bundle is itself idempotent, so re-running picks up whatever was missed.
if brew bundle --file="$CONFIG/Brewfile"; then
	skip "Brewfile satisfied"
else
	warn "brew bundle failed — re-run after resolving; see 'brew bundle check --verbose'"
fi

step "Wiring Firefox"
# Firefox profile directories carry a random prefix, so unlike every other
# config here the destination cannot be declared — it has to be discovered.
# sync-theme.py renders to a fixed path in the repo and this step owns the one
# variable hop, which keeps the renderer unaware of the profile layout.
ff_profile=$(find "$HOME/Library/Application Support/Firefox/Profiles" \
	-maxdepth 1 -type d -name '*.default-release' 2>/dev/null | head -1)
if [ ! -d /Applications/Firefox.app ]; then
	warn "Firefox not installed (brew bundle incomplete) — skipping profile wiring"
elif [ -z "$ff_profile" ]; then
	warn "no Firefox profile yet — launch Firefox once to create one, then re-run"
elif [ -d "$ff_profile/chrome" ] && [ ! -L "$ff_profile/chrome" ]; then
	# Never deleted: ln -sfn onto a real directory silently nests the link
	# inside it, and the contents are the user's, not this repo's.
	warn "$ff_profile/chrome is a real directory — move it aside, then re-run"
else
	ln -sfn "$CONFIG/firefox/user.js" "$ff_profile/user.js"
	ln -sfn "$CONFIG/firefox/chrome" "$ff_profile/chrome"
	skip "user.js + chrome/ -> ${ff_profile##*/}"
fi

step "Installing Firefox policies"
# Auto-installs Sidebery on first launch. This lives inside the
# app bundle, which is the only path Firefox reads on macOS — so a cask upgrade
# replaces the bundle and drops it. Re-running restores it; the telemetry prefs
# in user.js are what hold the line in between. Writing there is TCC-gated:
# macOS will not let one app modify another's signed bundle without the grant.
ff_dist="/Applications/Firefox.app/Contents/Resources/distribution"
if [ ! -d /Applications/Firefox.app ]; then
	skip "Firefox not installed — skipping policies"
elif mkdir -p "$ff_dist" && cp "$CONFIG/firefox/policies.json" "$ff_dist/policies.json"; then
	skip "Sidebery auto-install, telemetry off"
else
	warn "could not write policies.json into Firefox.app — grant your terminal App Management in System Settings > Privacy & Security > App Management"
fi

step "Bringing up the macOS input stack"
# Hammerspoon and AeroSpace are installed by the Brewfile above; this starts
# them and reports the grants a script is not allowed to make. Accessibility
# and Input Monitoring are gated by TCC, which exists precisely so that no
# privileged process can grant them on the user's behalf — only a Jamf PPPC
# profile could, and that is not ours to push. So: detect and instruct.
# Non-fatal throughout; a missing grant must not abandon the run.
if [ -d "/Applications/AeroSpace.app" ]; then
	pgrep -x AeroSpace >/dev/null 2>&1 || open -a AeroSpace
	if aerospace list-workspaces --focused >/dev/null 2>&1; then
		skip "AeroSpace running and responding"
	else
		warn "AeroSpace not responding — grant Accessibility in System Settings > Privacy & Security > Accessibility"
	fi
else
	warn "AeroSpace not installed — brew bundle incomplete"
fi

if [ -d "/Applications/Hammerspoon.app" ]; then
	pgrep -x Hammerspoon >/dev/null 2>&1 || open -a Hammerspoon
	# A running process is not a working one: without Accessibility the event taps
	# start and then silently never fire. hs.ipc in init.lua exposes this check.
	if [ "$(hs -c "hs.accessibilityState()" 2>/dev/null)" = "true" ]; then
		skip "Hammerspoon running with Accessibility"
	else
		warn "Hammerspoon needs Accessibility — System Settings > Privacy & Security > Accessibility"
	fi
else
	warn "Hammerspoon not installed — brew bundle incomplete"
fi

step "Starting the podman machine"
# The Linux VM that actually runs containers is machine-local state, so brew
# cannot create it. krunkit is the hypervisor binary for podman's default
# libkrun provider on Apple Silicon and is missing from brew's podman formula,
# which is why the Brewfile pins the libkrun/krun tap — without it, init fails.
if ! command -v podman >/dev/null; then
	warn "podman not installed (brew bundle incomplete) — skipping machine init"
elif ! podman machine inspect podman-machine-default >/dev/null 2>&1; then
	if podman machine init --now; then
		skip "podman-machine-default created and started"
	else
		warn "podman machine init failed — check krunkit installed: brew list krunkit"
	fi
elif [ "$(podman machine inspect podman-machine-default --format '{{.State}}' 2>/dev/null)" = "running" ]; then
	skip "podman-machine-default already running"
elif podman machine start; then
	skip "podman-machine-default started"
else
	warn "podman machine start failed — check krunkit installed: brew list krunkit"
fi

step "Wiring the docker compose plugin"
# `docker compose` finds Homebrew's plugin only when config.json names its
# directory. Without it the hyphenated docker-compose still works and the space
# form does not, which reads as a broken install rather than a missing setting.
# Merged in place, not written: the same file gains registry auth on
# `docker login`, which is why it cannot simply be tracked in this repo.
if ! command -v docker >/dev/null; then
	warn "docker not installed (brew bundle incomplete) — skipping compose plugin"
elif python3 -c '
import json, pathlib, sys
p = pathlib.Path.home() / ".docker" / "config.json"
cfg = json.loads(p.read_text()) if p.exists() else {}
dirs = cfg.setdefault("cliPluginsExtraDirs", [])
if sys.argv[1] in dirs:
    raise SystemExit(0)
dirs.append(sys.argv[1])
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(cfg, indent=2) + "\n")
' "$(brew --prefix)/lib/docker/cli-plugins"; then
	skip "cliPluginsExtraDirs -> $(brew --prefix)/lib/docker/cli-plugins"
else
	warn "could not merge ~/.docker/config.json — 'docker compose' will not find the plugin"
fi

step "Ensuring rustup is present"
# mise's rust plugin drives rustup rather than shipping a toolchain, and its
# install dir is a symlink to ~/.cargo/bin — so rustup must exist first.
if command -v rustup >/dev/null || [ -x "$HOME/.cargo/bin/rustup" ]; then
	skip "rustup already installed"
elif curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path; then
	skip "rustup installed"
else
	warn "rustup install failed — 'mise install' will not be able to build rust"
fi

step "Installing language runtimes (mise)"
if ! command -v mise >/dev/null; then
	warn "mise not installed (brew bundle incomplete) — skipping runtimes"
elif mise install; then
	# Everything below runs in this bash process, which never sourced the shell
	# config — without this the mise-managed tools are simply absent and later
	# checks silently report them missing.
	PATH="$(mise bin-paths | tr '\n' ':')$PATH"
	skip "runtimes and CLI tooling"
else
	warn "mise install failed — re-run once its prerequisites are present"
fi

step "Checking gh account"
# gh/hosts.yml is untracked, so pulling the commit that removed it deletes any
# inherited copy — that is what actually clears someone else's account. This
# step only reports, and deliberately does not delete: an unauthenticated
# hosts.yml usually means an expired token, which is routine, and throwing the
# file away over it would cost you your account list for no reason.
if [ ! -f "$CONFIG/gh/hosts.yml" ]; then
	skip "no gh/hosts.yml — gh auth login will create one"
elif ! command -v gh >/dev/null; then
	skip "gh not installed — skipping check"
elif gh auth status >/dev/null 2>&1; then
	skip "authenticated as $(gh api user --jq .login 2>/dev/null || echo 'unknown')"
else
	warn "gh/hosts.yml has no valid token — run 'gh auth login' (or 'gh auth logout -u <name>' to drop an account that is not yours)"
fi

step "Checking brew for packages the Brewfile dropped"
# A tool that moves to mise leaves its formula behind, and the stale copy keeps
# answering wherever mise activation does not reach — scripts run with a plain
# PATH, GUI launches, MCP servers spawned without a shell. A fresh machine never
# accumulates this; only one that predates a move does. Reported rather than
# removed, because --force would equally take anything installed deliberately
# outside the Brewfile.
if ! command -v brew >/dev/null; then
	skip "brew missing — skipping drift check"
else
	# cleanup exits 1 whenever it finds anything to remove, and it always finds
	# cmd/go — see the GOBIN note in the README — so without the guard errexit
	# would abort the run here, skipping every step below.
	stale=$(brew bundle cleanup --file="$CONFIG/Brewfile" 2>/dev/null |
		awk '/^Would uninstall (formulae|casks):/{f=1;next} /^Would |^Run /{f=0} f&&NF{c++} END{print c+0}' || true)
	if [ "$stale" -eq 0 ]; then
		skip "brew matches the Brewfile"
	else
		warn "$stale brew packages are not in the Brewfile — review 'brew bundle cleanup --file=$CONFIG/Brewfile', then re-run it with --force"
	fi
fi

step "Building bat theme cache"
if ! command -v bat >/dev/null; then
	warn "bat not installed (brew bundle incomplete) — skipping theme cache"
elif bat cache --build >/dev/null; then
	skip "Tokyo Night registered"
else
	warn "bat cache --build failed"
fi

step "Rendering MCP configs"
if ! python3 "$CONFIG/ai/sync-mcp.py"; then
	warn "sync-mcp.py failed — MCP servers not rendered"
fi

step "Restoring atuin history"
# Shell history is personal: the backup document is named in the untracked
# bootstrap.local, never here, so a colleague's run cannot pull someone else's.
if [ -f "$HOME/.local/share/atuin/history.db" ]; then
	skip "history.db already present — leaving it alone"
elif [ -z "$ATUIN_BACKUP_DOC" ]; then
	skip "no ATUIN_BACKUP_DOC set in bootstrap.local — starting with empty history"
elif command -v op >/dev/null && op account list >/dev/null 2>&1; then
	mkdir -p "$HOME/.local/share"
	tmp=$(mktemp -d)
	if op document get "$ATUIN_BACKUP_DOC" --vault "$ATUIN_BACKUP_VAULT" \
		--output "$tmp/atuin.tar.gz" >/dev/null 2>&1; then
		tar xzf "$tmp/atuin.tar.gz" -C "$HOME/.local/share"
		skip "restored from 1Password"
	else
		skip "backup document not found — skipping"
	fi
	rm -rf "$tmp"
else
	skip "1Password CLI not signed in — run 'op signin' and re-run"
fi

step "Done"
cat <<'EOF'
    Remaining manual steps:
      exec zsh -l          reload the shell
      nvim                 LazyVim installs plugins, then :Mason
      tmux                 tpm self-bootstraps and installs plugins
      gh auth login        your own work GitHub account
      gcloud init          your own @thefa.com account / the-fa-api-prod

    Check git/config.local holds your name, email and signing key.
EOF

if [ -n "$FAILED" ]; then
	printf '\n\033[1;33m==>\033[0m Completed with warnings — shell config is linked, but:\n%s' "$FAILED"
	printf '    Fix the above and re-run ./bootstrap.sh; it is idempotent.\n'
	exit 1
fi
