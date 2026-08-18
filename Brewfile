tap "anomalyco/tap"
tap "fluxcd/tap"
tap "hashicorp/tap"
tap "libkrun/krun", trusted: { formulae: ["gvproxy", "libkrun", "libkrunfw", "virglrenderer"] }
# Improved shell history for zsh, bash, fish and nushell
# No restart_service: the formula's service runs `atuin daemon start`, but the
# daemon is opt-in and atuin/config.toml does not set [daemon] enabled = true,
# so the client writes to sqlite directly and the service would idle. Starting
# it also fails outright wherever ~/Library/LaunchAgents is root-owned.
brew "atuin"
# Secrets scanner built for configurability and speed
brew "betterleaks"
# Resource monitor. C++ version and continuation of bashtop and bpytop
brew "btop"
# Load/unload environment variables based on $PWD
brew "direnv"
# Modern, maintained replacement for ls
brew "eza"
# Enable transparent encryption/decryption of files in a git repo
brew "git-crypt"
# Quickly rewrite git repository history
brew "git-filter-repo"
# Package compiler and linker metadata toolkit
brew "pkgconf"
# Development framework for multimedia applications
brew "gstreamer"
# Postgres C API library
brew "libpq"
# Polyglot runtime manager (asdf rust clone)
brew "mise"
# Ambitious Vim-fork focused on extensibility and agility
brew "neovim"
# Tool for managing OCI containers and pods
brew "podman"
# Alternative to docker-compose using podman
brew "podman-compose"
# PDF rendering library (based on the xpdf-3.0 code base)
brew "poppler"
# Terminal multiplexer
brew "tmux"
# Fish-like fast/unobtrusive autosuggestions for zsh
brew "zsh-autosuggestions"
# Fish shell like syntax highlighting for zsh
brew "zsh-syntax-highlighting"
# Better and friendly vi(vim) mode plugin for ZSH
brew "zsh-vi-mode"
# The AI coding agent built for the terminal.
brew "anomalyco/tap/opencode", trusted: true
# CLI tool to start Linux KVM or macOS HVF VMs using the libkrun
# Required by podman: brew's podman formula ships gvproxy and vfkit but not
# krunkit, and podman defaults to the libkrun provider on Apple Silicon, so
# `podman machine start` fails without it. Not in homebrew-core because the
# binary needs a Hypervisor.framework codesigning entitlement.
brew "libkrun/krun/krunkit", trusted: true
# Command-line interface for 1Password
cask "1password-cli"
# Terminal-based AI coding assistant
cask "claude-code"
# Brings the power of Copilot coding agent directly to your terminal
cask "copilot-cli"
cask "font-zed-mono-nerd-font"
# Google Cloud CLI — gcloud, gsutil, bq. Cask is named gcloud-cli; the old
# google-cloud-sdk name is an alias. Required by the Phase 4 cloud runbook.
cask "gcloud-cli"
# Terminal emulator that uses platform-native UI and GPU acceleration
cask "ghostty"
# Native GUI tool for relational databases
cask "tableplus"
go "golang.org/x/tools/cmd/callgraph"
go "github.com/spf13/cobra-cli"
go "github.com/go-delve/delve/cmd/dlv"
go "github.com/davidrjenni/reftools/cmd/fillstruct"
go "github.com/davidrjenni/reftools/cmd/fillswitch"
go "github.com/onsi/ginkgo/v2/ginkgo"
go "github.com/abice/go-enum"
go "mvdan.cc/gofumpt"
go "golang.org/x/tools/cmd/goimports"
go "github.com/golangci/golangci-lint/cmd/golangci-lint"
go "github.com/segmentio/golines"
go "github.com/fatih/gomodifytags"
go "github.com/abenz1267/gomvp"
go "golang.org/x/tools/cmd/gonew"
go "golang.org/x/tools/gopls"
go "golang.org/x/tools/cmd/gorename"
go "github.com/cweill/gotests/gotests"
go "gotest.tools/gotestsum"
go "golang.org/x/vuln/cmd/govulncheck"
go "golang.org/x/tools/cmd/guru"
go "github.com/koron/iferr"
go "github.com/josharian/impl"
go "github.com/tmc/json-to-struct"
go "go.uber.org/mock/mockgen"
go "github.com/kyoh86/richgo"
go "github.com/caarlos0/svu"
npm "codex"
# corepack provides the yarn and pnpm shims and honours each repo's
# packageManager field, so yarn must not also be installed standalone — the two
# collide over /opt/homebrew/bin/yarn. Run `corepack enable` once after install.
npm "corepack"
npm "nx"
