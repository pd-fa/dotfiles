# Keybindings Cheatsheet

Quick reference for all terminal tools and their keybindings.

---

## Neovim

### Leader Key: `<Space>`

#### File/Project Management
- `<leader>fp` - Find projects (fzf)
- `<leader>ff` - Find files (fzf-lua)
- `<leader>fg` - Live grep (fzf-lua)
- `<leader>fb` - Find buffers (fzf-lua)
- `<leader>fo` - Recent files (fzf-lua)
- `<leader>e` - Open yazi file manager
- `<leader>E` - Open yazi in cwd

#### Git (fzf-lua)
- `<leader>gf` - Git files
- `<leader>gc` - Git commits
- `<leader>gb` - Git branches

#### LSP
- `<leader>fs` - Document symbols
- `<leader>fS` - Workspace symbols
- `<leader>fd` - Go to definition
- `<leader>fr` - References

#### Obsidian Notes
- `<leader>on` - New note
- `<leader>oo` - Search notes
- `<leader>os` - Quick switch notes
- `<leader>ob` - Show backlinks
- `<leader>ot` - Search by tags
- `<leader>od` - Today's note
- `<leader>oy` - Yesterday's note
- `<leader>ol` - Link selection (visual)
- `<leader>oln` - Link to new note (visual)
- `<leader>of` - Follow link
- `<leader>oi` - Paste image
- `<leader>or` - Rename note
- `<leader>ch` - Toggle checkbox
- `gf` - Follow wiki link
- `<Enter>` - Smart action (in markdown)

#### Tmux Integration
- `<leader>t*` - Tmux session commands (see extras)

#### Utility
- `<leader>fh` - Help tags
- `<leader>fc` - Commands
- `<leader>fk` - Keymaps
- `<leader>?` - Which-key help

---

## Tmux

### Prefix: `Ctrl+b`

#### Window Management
- `prefix + c` - New window
- `prefix + |` - Split horizontal
- `prefix + -` - Split vertical
- `prefix + h/j/k/l` - Navigate panes (vim-style)
- `prefix + H/J/K/L` - Resize panes
- `prefix + Ctrl+h/l` - Previous/next window

#### Session Management
- `prefix + s` - Session switcher (fzf)
- `prefix + F` - Find and switch to project (tmux-sessionizer)

#### Tools
- `prefix + g` - Open lazygit popup
- `prefix + e` - Open yazi file manager popup
- `prefix + T` - Toggle status bar

#### Copy Mode
- `prefix + Escape` - Enter copy mode
- `v` - Begin selection (in copy mode)
- `y` - Copy selection
- `prefix + p` - Paste

#### Plugins
- `prefix + I` - Install plugins (TPM)
- `prefix + U` - Update plugins
- `prefix + alt+u` - Uninstall removed plugins

---

## Yazi (File Manager)

### Navigation
- `h` - Go back/parent directory
- `l` - Enter directory
- `j/k` - Move down/up
- `H/L` - Go back/forward in history
- `g + h` - Go to home
- `g + c` - Go to ~/.config
- `g + d` - Go to ~/dev
- `g + v` - Go to ~/vault
- `g + D` - Go to Downloads

### File Operations
- `<Space>` - Toggle selection
- `v` - Visual mode
- `<C-a>` - Select all
- `y` - Copy (yank)
- `x` - Cut
- `p` - Paste
- `P` - Paste (overwrite)
- `d` - Move to trash
- `D` - Delete permanently
- `a` - Create file/directory
- `r` - Rename
- `o` or `<Enter>` - Open file
- `e` - Edit in nvim

### Search
- `/` - Find
- `n/N` - Next/previous match
- `s` - Search with fd
- `S` - Search with ripgrep
- `z + h` - Toggle hidden files

### Tabs
- `t` - New tab
- `<C-w>` - Close tab
- `1-5` - Switch to tab 1-5
- `[/]` - Previous/next tab

### Other
- `~` - Help
- `!` - Open shell

---

## Shell (Zsh)

### Project Navigation
- `fp` - Find projects (fzf + fd)
- `z <dir>` - Smart cd (zoxide)
- `zi` - Interactive directory picker (zoxide)
- `proj` - cd to ~/dev/personal/

### File Browsing
- `y` - Launch yazi
- `yy` - Launch yazi and cd on exit
- `ls` - List (eza with icons)
- `ll` - List long (eza)
- `lt` - List tree (eza)

### Git
- `lg` - Launch lazygit

### Kubernetes
- `k` / `kc` - kubectl
- `k9` - Launch k9s

### Notes
- `notes` / `vault` - Open vault in nvim
- `today` - Open today's daily note

### Editors
- `v` / `vi` / `vim` / `nv` - nvim
- `dot` - cd to ~/.config and open nvim

### System
- `mon` - Launch btop (system monitor)
- `kp <port>` - Kill process on port
- `rf` / `refresh` - Reload shell
- `q` / `quit` - Exit shell

---

## K9s (Kubernetes TUI)

### Navigation
- `j/k` - Move down/up
- `h/l` - Previous/next column
- `g/G` - Top/bottom
- `<Enter>` - View details
- `Esc` - Back/exit

### Resource Management
- `d` - Describe
- `e` - Edit
- `l` - Logs
- `y` - YAML
- `ctrl-d` - Delete

### Views
- `:pod` - View pods
- `:svc` - View services
- `:deploy` - View deployments
- `:ns` - View namespaces
- `0-9` - Switch context

### Other
- `/` - Filter
- `?` - Help
- `ctrl-a` - Toggle all namespaces

---

## Lazygit

### Navigation
- `h/j/k/l` - Navigate panels
- `[/]` - Previous/next tab
- `1-5` - Switch to tab

### Actions
- `<Space>` - Stage/unstage
- `a` - Stage all
- `c` - Commit
- `P` - Push
- `p` - Pull
- `+` - New branch
- `d` - Delete/drop
- `e` - Edit file
- `o` - Open file

### Other
- `/` - Search/filter
- `?` - Help
- `q` - Quit
- `x` - Open command menu

---

## FZF (Fuzzy Finder)

### Universal Keybindings
- `Ctrl+/` - Toggle preview
- `Ctrl+u/d` - Scroll preview up/down
- `Ctrl+j/k` - Move down/up (alternative to arrows)
- `Enter` - Select
- `Esc` - Cancel
- `Tab` - Multi-select (where available)

---

## BTTop (System Monitor)

### Navigation
- `j/k` - Move down/up
- `h/l` - Previous/next view
- `g/G` - Top/bottom

### Views
- `1` - CPU view
- `2` - Memory view
- `3` - Network view
- `4` - Process view

### Process Management
- `t` - Tree view
- `k` - Kill process
- `/` - Filter processes
- `+/-` - Increase/decrease update speed

### Other
- `m` - Menu
- `q` - Quit

---

## Global Shell Shortcuts

### FZF Triggers
- `Ctrl+t` - File picker
- `Ctrl+r` - History search (Atuin)
- `Alt+c` - Directory picker

### Zoxide
- `cd` is aliased to `z` (smart cd)
- `cdi` - Interactive directory picker

---

## FindProjects Actions (Nvim)

When using `<leader>fp`:
- `Enter` - cd + close buffers + open explorer (clean switch)
- `Ctrl+v` - cd but keep buffers
- `Ctrl+t` - Create/switch tmux session
- `Ctrl+s` - Open in split

---

## Quick Reference

### Start Your Day
1. `tmux` - Start tmux
2. `prefix + F` - Find project (Shift+F)
3. Opens tmux session with nvim
4. `<leader>od` - Open today's daily note

### Common Workflows

**Browse and edit project:**
```
fp (shell) or <leader>fp (nvim) → navigate → edit
```

**Git workflow:**
```
prefix + g (in tmux) → lazygit → stage/commit/push
```

**Find and edit file:**
```
<leader>ff → type filename → enter
```

**Search in project:**
```
<leader>fg → type search term → enter
```

**Switch projects:**
```
prefix + F (tmux) or fp (shell) → select project
```

---

## Tips

- Use `<leader>?` in nvim to see available keybindings
- Press `?` in most TUIs (k9s, lazygit, yazi) for help
- Use `z` (zoxide) instead of `cd` - it learns your habits
- `yy` in shell changes directory when you exit yazi
- All pickers support preview with `Ctrl+/` to toggle
- Tmux prefix can be changed in ~/.config/tmux/tmux.conf
- All configs use TokyoNight color scheme for consistency

---

Last updated: 2025-12-18
