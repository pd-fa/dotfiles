#!/usr/bin/env bash
# Bootstrap a new machine from this repo. Idempotent — safe to re-run.
#
# Prerequisites that cannot be scripted (see README Phase 1):
#   MDM enrolment, 1Password with the SSH agent enabled, xcode-select, Homebrew.
set -euo pipefail

CONFIG="$HOME/.config"
step() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
skip() { printf '    \033[2m%s\033[0m\n' "$1"; }

[ -d "$CONFIG/.git" ] || { echo "Run after cloning this repo to ~/.config" >&2; exit 1; }

step "Checking prerequisites"
for c in brew git; do
	command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }
done
skip "brew and git present"

step "Installing packages (brew bundle)"
brew bundle --file="$CONFIG/Brewfile"

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
	ln -sfn "$s" "$HOME/.claude/skills/$(basename "$s")"
done
skip "settings.json + $(find "$CONFIG/ai/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ') skills"

step "Configuring git hooks"
git config --global core.hooksPath "$CONFIG/git/hooks"
chmod +x "$CONFIG/git/hooks/"* 2>/dev/null || true
skip "core.hooksPath -> git/hooks (betterleaks pre-commit)"

step "Installing language runtimes (mise)"
mise install

step "Building bat theme cache"
bat cache --build >/dev/null
skip "Tokyo Night registered"

step "Rendering MCP configs"
python3 "$CONFIG/ai/sync-mcp.py"

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
