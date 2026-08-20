# Project Finder - fuzzy find and cd to project
fp() {
  local depth=${FZF_DEPTH:-3}
  local selected=$(fd . ~/dev --min-depth $depth --max-depth $depth --type d | \
    fzf --preview 'eza --tree --level=2 --color=always {} 2>/dev/null || ls -la {}' \
        --preview-window=right:60% \
        --header="Find Project (depth: $depth)")

  if [ -n "$selected" ]; then
    # Use builtin cd to bypass zoxide alias
    builtin cd "$selected"
  fi
}

function dbp() {
  case $1 in
  dev)
    PORT=6003
    ;;
  uat)
    PORT=6004
    ;;
  prod)
    PORT=6005
    ;;
  *)
    echo "Unknown stage"
    return 1
    ;;
  esac
  cloud-sql-proxy the-fa-api-"$1":europe-west2:pps --port "$PORT"
}

function corev2() {
  case $1 in
  sandbox)
    PORT=6000
    ;;
  helix-uat)
    PORT=6001
    ;;
  helix-prod)
    PORT=6002
    ;;
  *)
    echo "Unknown stage"
    return 1
    ;;
  esac
  cloud-sql-proxy the-fa-"$1":europe-west2:helix --port "$PORT"
}

function twf() {
  local workflow_file=$1
  shift

  if [[ "$workflow_file" == -* ]]; then
    # If the first argument is an option, use the default .env and treat all arguments as options
    act --container-architecture linux/amd64 --secret-file .env.secrets --env-file .env.vars "$@"
  else
    # If the first argument is not an option, treat it as the workflow file
    act --container-architecture linux/amd64 --secret-file .env.secrets --var-file .env.vars "$@" -W ".github/workflows/${workflow_file}"
  fi
}

function kp() {
  kill -9 $(lsof -ti :"$1")
}

function get_pod_logs() {
  if [ -z "$1" ]; then
    echo "Please provide a pod name filter."
    return 1
  fi

  pod_filter=$1
  kubectl get pods -n helix-obs | grep "$pod_filter" | awk '{print $1}' | xargs -I {} kubectl logs -n helix-obs {}
}

# Yazi wrapper function - changes directory on exit
function yy() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# --------------------------------------------------
# AeroSpace — window management from the shell
# --------------------------------------------------

## Tab-separated because window titles routinely contain |, - and :, and a
## delimiter that shows up inside a title silently shifts the window-id field.
function _aero_windows() {
  aerospace list-windows --all \
    --format '%{window-id}%{tab}%{app-name}%{tab}%{window-title}%{tab}%{workspace}'
}

## One picker covers both call styles: --select-1 resolves a unique match with
## no UI, so `wf teams` is instant while a bare `wf` is interactive. --exit-0
## keeps a query that matches nothing from hanging on an empty picker.
function _aero_pick() {
  local header=$1
  shift
  _aero_windows | fzf --query="$*" --select-1 --exit-0 --delimiter=$'\t' \
    --with-nth='2,3,4' --header="$header" --header-first
}

## Focus any window on any workspace or display. AeroSpace follows the window,
## so this reaches windows that no amount of alt-hjkl will get to.
function wf() {
  local sel
  sel=$(_aero_pick 'focus window' "$@") || return
  aerospace focus --window-id "${sel%%$'\t'*}"
}

## Focus the app if it is running, launch it if it is not. Substring on focus,
## exact on launch — LaunchServices needs a real application name to open one.
function wo() {
  local app=$1 id
  if [[ -z $app ]]; then
    print -u2 'usage: wo <app>'
    return 1
  fi
  id=$(_aero_windows | awk -F'\t' -v a="${app:l}" 'index(tolower($2), a) { print $1; exit }')
  if [[ -n $id ]]; then
    aerospace focus --window-id "$id"
  else
    open -a "$app" || print -u2 "wo: nothing running or installed matching '$app'"
  fi
}

## The inverse of wf: bring the window here rather than travelling to it. No
## keybinding can do this — they all act on the focused window, and the one you
## want is by definition not the focused one.
function wsum() {
  local sel
  sel=$(_aero_pick 'summon window to this workspace' "$@") || return
  aerospace move-node-to-workspace --window-id "${sel%%$'\t'*}" \
    --focus-follows-window "$(aerospace list-workspaces --focused)"
}

## Send the focused window to a workspace. Offers what exists rather than the
## persistent five: a workspace outside that list still exists while it holds
## windows, so typing a name blind is how windows get parked out of sight.
function wsend() {
  local ws=$1
  if [[ -z $ws ]]; then
    ws=$(aerospace list-workspaces --all |
      fzf --select-1 --exit-0 --header='send focused window to' --header-first) || return
  fi
  [[ -n $ws ]] && aerospace move-node-to-workspace --focus-follows-window "$ws"
}

## Move this entire workspace to another display — the one that matters when a
## monitor is unplugged, or a context built on the laptop belongs on the 4K.
function wmon() {
  local mon=$1
  if [[ -z $mon ]]; then
    mon=$(aerospace list-monitors --format '%{monitor-name}' |
      fzf --select-1 --exit-0 --header='move this workspace to display' --header-first) || return
  fi
  [[ -n $mon ]] && aerospace move-workspace-to-monitor "$mon"
}

## The opposite direction: pull a workspace onto the display you are looking at,
## instead of walking your eyes over to whichever display currently holds it.
function wpull() {
  local ws=$1
  if [[ -z $ws ]]; then
    ws=$(aerospace list-workspaces --all |
      fzf --select-1 --exit-0 --header='pull workspace to this display' --header-first) || return
  fi
  [[ -n $ws ]] && aerospace summon-workspace "$ws"
}

## What is where, across every display and workspace.
function ww() {
  aerospace list-windows --all \
    --format '%{workspace}%{tab}%{monitor-name}%{tab}%{app-name}%{tab}%{window-title}' |
    sort -t$'\t' -k1,1 -k3,3 |
    column -t -s$'\t'
}
