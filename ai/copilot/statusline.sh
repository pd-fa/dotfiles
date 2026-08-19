#!/usr/bin/env bash
# GitHub Copilot CLI status line: model, context %, session credits, plan quota.
# Configured via `statusLine` in ~/.copilot/config.json (see `copilot help config`).
#
# Copilot's stdin payload is undocumented, so field paths are probed rather than
# assumed. Run `statusline.sh --dump` as the configured command for one session
# to capture the real payload to $SL_DUMP, then tighten the paths below.
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=../lib/statusline-render.sh
source "${HOME}/.config/ai/lib/statusline-render.sh"

SL_DUMP="${SL_DUMP:-${HOME}/.cache/copilot-statusline-payload.json}"

payload=$(cat)

if [[ ${1:-} == --dump ]]; then
  mkdir -p "$(dirname "$SL_DUMP")"
  printf '%s\n' "$payload" >"$SL_DUMP"
fi

# Copilot bills AI credits against a plan quota; it has no 5h/7d windows, so the
# honest analogues are session credits used and quota consumed. Percentages are
# derived from used/limit pairs when no pre-computed field is present.
IFS=$'\t' read -r model ctx ses quota quota_in <<<"$(
  printf '%s' "$payload" | jq -r '
    def pct(used; limit):
      if (used|type) == "number" and (limit|type) == "number" and limit > 0
      then (used / limit * 100) else "-" end;

    # Reset may be epoch seconds or an ISO string; tolerate both. The trailing
    # // "-" is load-bearing: an element yielding empty would shorten the array
    # and silently shift every later field in the TSV.
    def remain(t):
      (t | if   type == "number" then (. - now | floor)
           elif type == "string" then
             ((fromdateiso8601? // null)
              | if . == null then "-" else (. - now | floor) end)
           else "-" end) // "-";

    [ ((.model | objects | (.display_name // .name // .id))
       // (.model | strings)
       // "copilot"),

      (.context_window.used_percentage?
       // .contextWindow.usedPercentage?
       // pct(.context_window.current_context_tokens?;
              .context_window.displayed_context_limit?)
       // pct(.context_window.total_input_tokens?;
              .context_window.context_window_size?)
       // "-"),

      (.session.ai_credits_used_percentage?
       // pct(.cost.ai_credits_used?; .cost.ai_credits_limit?)
       // pct(.session.ai_credits_used?; .session.max_ai_credits?)
       // "-"),

      (.quota.used_percentage?
       // .usage.quota.used_percentage?
       // pct(.quota.used?; .quota.limit?)
       // pct(.quota.premium_requests_used?; .quota.premium_requests_limit?)
       // "-"),

      remain(.quota.resets_at? // .quota.reset_at? // .quota.reset_date?
             // .usage.quota.resets_at?)
    ] | @tsv' 2>/dev/null
)" || true

sl_join \
  "${SL_CYAN}${SL_BOLD}${model:-copilot}${SL_RESET}" \
  "$(sl_metric ctx "${ctx:--}" bar)" \
  "$(sl_metric ses "${ses:--}")" \
  "$(sl_metric quota "${quota:--}" '' "${quota_in:--}")"
