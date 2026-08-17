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
  ~/cloud-sql-proxy the-fa-api-"$1":europe-west2:pps --port "$PORT"
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
  ~/cloud-sql-proxy the-fa-"$1":europe-west2:helix --port "$PORT"
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
