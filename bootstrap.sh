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

step "Configuring git hooks"
# Set as a tilde path rather than "$CONFIG" so the value committed to git/config
# stays portable — home directories differ between machines (PDolden vs
# Paul.Dolden). Git expands ~ in core.hooksPath, as it does for excludesfile.
# shellcheck disable=SC2088  # literal ~ is deliberate: git expands it, not the shell
git config --global core.hooksPath '~/.config/git/hooks'
chmod +x "$CONFIG/git/hooks/"* 2>/dev/null || true
skip "core.hooksPath -> git/hooks (betterleaks pre-commit)"

step "Installing packages (brew bundle)"
# Non-fatal: one unavailable package must not abandon the rest of the bootstrap.
# brew bundle is itself idempotent, so re-running picks up whatever was missed.
if brew bundle --file="$CONFIG/Brewfile"; then
	skip "Brewfile satisfied"
else
	warn "brew bundle failed — re-run after resolving; see 'brew bundle check --verbose'"
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
	skip "node python go rust"
else
	warn "mise install failed — re-run once its prerequisites are present"
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
if [ -f "$HOME/.local/share/atuin/history.db" ]; then
	skip "history.db already present — leaving it alone"
elif command -v op >/dev/null && op account list >/dev/null 2>&1; then
	mkdir -p "$HOME/.local/share"
	tmp=$(mktemp -d)
	if op document get "atuin history backup 2026-08-17" --vault Work \
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
      gh auth login        pd-fa account
      gcloud init          paul.dolden@thefa.com / the-fa-api-prod
EOF

if [ -n "$FAILED" ]; then
	printf '\n\033[1;33m==>\033[0m Completed with warnings — shell config is linked, but:\n%s' "$FAILED"
	printf '    Fix the above and re-run ./bootstrap.sh; it is idempotent.\n'
	exit 1
fi
