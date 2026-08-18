if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
  export TERM=xterm-256color
fi

# --------------------------------------------------
# Source configuration files
# --------------------------------------------------
source ~/.config/zsh/aliases.zsh
source ~/.config/zsh/exports.zsh
source ~/.config/zsh/functions.zsh

# --------------------------------------------------
# PATH Management (Centralised + Deduplicated)
# --------------------------------------------------
typeset -U path PATH

# Base system paths
path=(
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
)

# Google Cloud SDK (eager PATH, lazy completions)
# The gcloud-cli cask symlinks gcloud/bq/gsutil straight into $HOMEBREW_PREFIX/bin,
# which is already on PATH — this line only covers a manual tarball install.
[[ -d "$HOME/google-cloud-sdk/bin" ]] && path+=("$HOME/google-cloud-sdk/bin")

# User tool paths
path+=(
  $HOME/.local/bin
  $HOME/.cargo/bin
  $HOME/.bun/bin
  $HOME/Library/pnpm
  $HOME/go/bin
  $HOME/vault/scripts
)

# --------------------------------------------------
# Completion Setup (Cached Daily)
# --------------------------------------------------
autoload -Uz compinit
setopt EXTENDEDGLOB

local zcompdump="$HOME/.zcompdump"

if [[ -n $zcompdump(#qNmh-24) ]]; then
  compinit -C -d "$zcompdump"
else
  compinit -d "$zcompdump"
fi

unsetopt EXTENDEDGLOB

# --------------------------------------------------
# Completion Styling
# --------------------------------------------------

# Case-insensitive + partial-word + substring matching
zstyle ':completion:*' matcher-list \
  'm:{a-z}={A-Z}' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Group completions by type with descriptions
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'

# Colored completions using LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Include . and .. in directory completions
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true

# Disable default menu — fzf-tab handles it
zstyle ':completion:*' menu no

# fzf-tab: directory previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'eza --tree --level=2 --color=always $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview \
  'eza --tree --level=2 --color=always $realpath 2>/dev/null'

# fzf-tab: file previews
zstyle ':fzf-tab:complete:nvim:*' fzf-preview \
  'bat --color=always --style=numbers --line-range=:100 $realpath 2>/dev/null'

# fzf-tab: switch between completion groups with < and >
zstyle ':fzf-tab:*' switch-group '<' '>'

# kubectl completions (cached — regenerate by deleting ~/.kubectl_zsh_completion)
if (( $+commands[kubectl] )); then
  local _kubectl_comp_cache="$HOME/.kubectl_zsh_completion"
  if [[ ! -f "$_kubectl_comp_cache" ]]; then
    kubectl completion zsh >! "$_kubectl_comp_cache" 2>/dev/null
  fi
  source "$_kubectl_comp_cache"
  compdef k=kubectl
  compdef kc=kubectl
fi

# --------------------------------------------------
# Plugins & Tools
# --------------------------------------------------

source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# fzf-tab is an upstream clone, not a brew formula — bootstrap it on a fresh machine
[[ -d ~/.config/zsh/fzf-tab ]] || \
  git clone -q --depth 1 https://github.com/Aloxaf/fzf-tab ~/.config/zsh/fzf-tab

# fzf-tab must load after compinit; use hook so zsh-vi-mode doesn't clobber its Tab binding
function zvm_after_init() {
  source ~/.config/zsh/fzf-tab/fzf-tab.plugin.zsh
}

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.config/zsh/zsh-syntax-highlighting/theme.zsh

export COREPACK_ENABLE_AUTO_PIN=0

# --------------------------------------------------
# Runtime versions (node, python, go, rust — replaces nvm/asdf)
# --------------------------------------------------
eval "$(mise activate zsh)"

# --------------------------------------------------
# Per-project environment
# --------------------------------------------------
eval "$(direnv hook zsh)"

# --------------------------------------------------
# Lazy Load Google Cloud SDK (completions only, PATH set above)
# --------------------------------------------------
# Checks the gcloud-cli cask location first, then a manual tarball install.
lazy_load_gcloud_completions() {
  local inc
  for inc in \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.zsh.inc" \
    "$HOME/google-cloud-sdk/completion.zsh.inc"
  do
    [[ -f "$inc" ]] && { . "$inc"; return }
  done
}

gcloud() {
  unset -f gcloud gsutil
  lazy_load_gcloud_completions
  gcloud "$@"
}

gsutil() {
  unset -f gcloud gsutil
  lazy_load_gcloud_completions
  gsutil "$@"
}

# --------------------------------------------------
# Atuin
# --------------------------------------------------
eval "$(atuin init zsh)"

# --------------------------------------------------
# FZF Configuration
# --------------------------------------------------
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --highlight-line \
  --info=inline-right \
  --ansi \
  --layout=reverse \
  --border=none \
  --height=80% \
  --preview-window=right:60% \
  --bind='ctrl-/:toggle-preview' \
  --bind='ctrl-u:preview-half-page-up' \
  --bind='ctrl-d:preview-half-page-down' \
  --color=bg+:#283457 \
  --color=bg:#16161e \
  --color=border:#27a1b9 \
  --color=fg:#c0caf5 \
  --color=gutter:#16161e \
  --color=header:#ff9e64 \
  --color=hl+:#2ac3de \
  --color=hl:#2ac3de \
  --color=info:#545c7e \
  --color=marker:#ff007c \
  --color=pointer:#ff007c \
  --color=prompt:#2ac3de \
  --color=query:#c0caf5:regular \
  --color=scrollbar:#27a1b9 \
  --color=separator:#ff9e64 \
  --color=spinner:#ff007c \
"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

export FZF_CTRL_T_OPTS="
  --preview 'bat --style=numbers --color=always --line-range :500 {}'
  --bind 'ctrl-/:toggle-preview'
"

export FZF_ALT_C_OPTS="
  --preview 'eza --tree --level=2 --color=always {} 2>/dev/null || ls -la {}'
"

# --------------------------------------------------
# Prompt + Navigation
# --------------------------------------------------
eval "$(starship init zsh)"

# --------------------------------------------------
# Bun
# --------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --------------------------------------------------
# pnpm
# --------------------------------------------------
(( $+commands[pnpm] )) && source <(pnpm completion zsh 2>/dev/null)

# --------------------------------------------------
# Local environment loader (if exists)
# --------------------------------------------------
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# --------------------------------------------------
# Zoxide (must be last)
# --------------------------------------------------
eval "$(zoxide init zsh)"
