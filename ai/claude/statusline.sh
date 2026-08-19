#!/usr/bin/env bash
# Claude Code status line: model, context %, 5h session %, 7d weekly %.
# Payload schema: https://code.claude.com/docs/en/statusline
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=../lib/statusline-render.sh
source "${HOME}/.config/ai/lib/statusline-render.sh"

# Single jq pass: process spawns dominate cost on a line that re-renders
# constantly. "-" marks absent data; jq treats 0 as truthy so a real 0% survives.
IFS=$'\t' read -r model ctx five five_in seven seven_in <<<"$(
  jq -r '
    # resets_at is epoch seconds; jq owns "now" so no date(1) spawn is needed.
    def remain(t): if (t|type) == "number" then ((t - now) | floor) else "-" end;
    [
      (.model.display_name // "claude"),
      (.context_window.used_percentage // "-"),
      (.rate_limits.five_hour.used_percentage  // "-"),
      remain(.rate_limits.five_hour.resets_at),
      (.rate_limits.seven_day.used_percentage  // "-"),
      remain(.rate_limits.seven_day.resets_at)
    ] | @tsv' 2>/dev/null
)" || true

# rate_limits appears only for Pro/Max, and only after the first API response of
# a session; each window can be absent independently. sl_metric drops a segment
# entirely rather than rendering a misleading 0%.
sl_join \
  "${SL_CYAN}${SL_BOLD}${model:-claude}${SL_RESET}" \
  "$(sl_metric ctx "${ctx:--}" bar)" \
  "$(sl_metric ses "${five:--}"  '' "${five_in:--}")" \
  "$(sl_metric wk  "${seven:--}" '' "${seven_in:--}")"
