#!/usr/bin/env bash
# Shared presentation for agent CLI status lines. Sourced, never executed.
# Callers supply values; this file owns colour, meters and joining only.

# shellcheck source=/dev/null  # rendered from theme/palette.toml at sync time
source "${HOME}/.config/ai/lib/statusline-colors.sh"

# Percentages arrive as floats (23.5); bash arithmetic needs the integer part.
# Empty output signals "absent", which callers use to drop the whole segment.
sl_int() { local v=${1%%.*}; [[ $v =~ ^[0-9]+$ ]] && printf '%s' "$v" || printf ''; }

sl_heat() {
  local n=$1
  if   (( n >= 80 )); then printf '%s' "$SL_RED"
  elif (( n >= 50 )); then printf '%s' "$SL_AMBER"
  else                     printf '%s' "$SL_GREEN"; fi
}

sl_bar() {
  local n=$1 filled i out=''
  filled=$(( (n + 5) / 10 )); (( filled > 10 )) && filled=10
  for (( i = 0; i < 10; i++ )); do
    (( i < filled )) && out+='▓' || out+='░'
  done
  printf '%s' "$out"
}

# Compact countdown. Windows can be days out, so scale the unit to the magnitude
# and drop the tail once it stops mattering. A stale resets_at goes negative.
sl_dur() {
  local s=$1 d h m
  (( s <= 0 )) && { printf 'now'; return 0; }
  (( s < 60 )) && { printf '<1m'; return 0; }
  d=$(( s / 86400 )); h=$(( (s % 86400) / 3600 )); m=$(( (s % 3600) / 60 ))
  if   (( d > 0 )); then printf '%dd%dh' "$d" "$h"
  elif (( h > 0 )); then printf '%dh%dm' "$h" "$m"
  else                   printf '%dm' "$m"; fi
}

# A labelled percentage, with optional meter and optional reset countdown.
# Prints nothing when the percentage is absent, so callers can drop the segment.
sl_metric() {
  local label=$1 raw=$2 with_bar=${3:-} reset=${4:-} n c out
  n=$(sl_int "$raw"); [[ -z $n ]] && return 0
  c=$(sl_heat "$n")
  if [[ $with_bar == bar ]]; then
    out=$(printf '%s%s%s %s%s%s %s%s%%%s' "$SL_DIM" "$label" "$SL_RESET" "$c" "$(sl_bar "$n")" "$SL_RESET" "$c" "$n" "$SL_RESET")
  else
    out=$(printf '%s%s%s %s%s%%%s' "$SL_DIM" "$label" "$SL_RESET" "$c" "$n" "$SL_RESET")
  fi
  # Negatives are valid here (window already elapsed), so sl_int is the wrong
  # validator -- it rejects them by design.
  if [[ $reset =~ ^-?[0-9]+$ ]]; then
    out+=$(printf ' %s\u21bb%s%s' "$SL_DIM" "$(sl_dur "$reset")" "$SL_RESET")
  fi
  printf '%s' "$out"
}

sl_join() {
  local sep="${SL_DIM} │ ${SL_RESET}" out='' s
  for s in "$@"; do
    [[ -z $s ]] && continue
    [[ -n $out ]] && out+="$sep"
    out+="$s"
  done
  printf '%s' "$out"
}
