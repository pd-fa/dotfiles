## Refresh
alias refresh='exec zsh -l'
alias rf='exec zsh -l'
## Bootstrap — install/refresh all tooling, then reload the shell. Idempotent.
## Sequenced with ; not && because bootstrap.sh exits non-zero on warnings by
## design, and those are routine — && would skip the reload exactly when the
## new state is what you want to see.
alias bootstrap='~/.config/bootstrap.sh; exec zsh -l'
## Quit
alias q='exit'
alias quit='exit'
alias quite='exit'
## Git
alias lg='lazygit'
## Tmux — attach to the most recent session, or start one if there is none.
## Bare `tmux` always creates a fresh session, which is how 0/1/2… pile up.
alias tmx='tmux attach 2>/dev/null || tmux new -s main'
## Neovim
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias nv='nvim'
## Zsh
alias zshrc='nvim ~/.config/zsh/.zshrc'
alias zshenv='nvim ~/.zshenv'
alias zprofile='nvim ~/.config/zsh/.zprofile'
## Dotfiles
alias dot='cd ~/.config/ && nvim'
alias dotup='cd ~/.config/ && git pull'
alias appsup='cd ~/Library/Application\ Support/ && nvim'
## Printenv
alias pe='printenv'
# Projects
alias proj='cd ~/dev/work/'
# Docker & Kubernetes
alias dpull='docker pull --platform linux/amd64'
alias kc='kubectl'
alias k='kubectl'
alias k9='k9s'
# System monitoring
alias mon='btop'
# File listing
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --icons'
# Notes (Obsidian vault)
alias notes='cd ~/vault && nvim'
alias vault='cd ~/vault && nvim'
alias today='nvim ~/vault/Daily\ Notes/$(date +%Y-%m-%d).md'
# File management
alias y='yazi'
# Zoxide (smart cd)
alias cd='z'
alias cdi='zi'  # Interactive selection
alias c='claude'
alias cc='claude --continue'
# Nx
## `nx run <project>:<target>` errors loudly on a bad name and suggests the real
## one; `nx run-many -t <typo>` prints "No tasks were run" and exits 0.
alias nxr='nx run'
