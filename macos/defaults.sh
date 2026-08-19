#!/usr/bin/env bash
# macOS system settings this repo depends on. Idempotent — safe to re-run.
#
# Deliberately narrow: only settings the Karabiner/AeroSpace input config needs
# to work. This is not a general macOS defaults sweep, and should not become one
# without a tracked issue.
set -euo pipefail

# AeroSpace switches workspaces by moving windows off the visible screen area
# rather than using native Spaces. With "Displays have separate Spaces" enabled
# macOS scopes that per display, which breaks focus on multi-monitor setups.
#
# The key is inverted relative to the UI: spans-displays = true means displays
# SHARE one space, i.e. the System Settings checkbox is OFF.
if [ "$(defaults read com.apple.spaces spans-displays 2>/dev/null || echo 0)" = "1" ]; then
	echo "    spans-displays already set"
else
	defaults write com.apple.spaces spans-displays -bool true
	echo "    spans-displays set — LOG OUT and back in to apply (killall is not enough)"
fi
