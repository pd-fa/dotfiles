# Tokyo Night (Night) theme for zsh-syntax-highlighting
# Sourced from .zshrc after the brew-installed zsh-syntax-highlighting plugin.
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor)
typeset -gA ZSH_HIGHLIGHT_STYLES

# Main highlighter styling: https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md
#
## General
### Diffs
### Markup
## Classes
## Comments
ZSH_HIGHLIGHT_STYLES[comment]='fg=#9c8cc4'
## Constants
## Entitites
## Functions/methods
ZSH_HIGHLIGHT_STYLES[alias]='fg=#a6dd70'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#a6dd70'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#a6dd70'
ZSH_HIGHLIGHT_STYLES[function]='fg=#a6dd70'
ZSH_HIGHLIGHT_STYLES[command]='fg=#a6dd70'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#a6dd70,italic'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#ffab77,italic'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#ffab77'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#ffab77'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#c9aefc'
## Keywords
## Built ins
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#a6dd70'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#a6dd70'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#a6dd70'
## Punctuation
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#ff8fa3'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-unquoted]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=#ff8fa3'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#ff8fa3'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#ff8fa3'
## Serializable / Configuration Languages
## Storage
## Strings
ZSH_HIGHLIGHT_STYLES[command-substitution-quoted]='fg=#e8bd76'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-quoted]='fg=#e8bd76'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#e8bd76'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg=#ef5f5f'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#e8bd76'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg=#ef5f5f'
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#e8bd76'
## Variables
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]='fg=#ef5f5f'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#e9e2f8'
## No category relevant in spec
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ef5f5f'
ZSH_HIGHLIGHT_STYLES[path]='fg=#e9e2f8,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#ff8fa3,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#e9e2f8,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#ff8fa3,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#c9aefc'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]='fg=#ef5f5f'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[default]='fg=#e9e2f8'
ZSH_HIGHLIGHT_STYLES[cursor]='fg=#e9e2f8'
