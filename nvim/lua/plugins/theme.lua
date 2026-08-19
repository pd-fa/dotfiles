-- Generated from theme/palette.toml by theme/sync-theme.py -- do not edit.
--
-- tokyonight.nvim does not read colours from disk, so the palette is injected
-- through its on_colors hook instead of forking the colourscheme.

return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      on_colors = function(c)
        c.bg = "#1c1420"
        c.bg_dark = "#150e18"
        c.bg_float = "#150e18"
        c.bg_highlight = "#2a1c2b"
        c.bg_popup = "#150e18"
        c.bg_sidebar = "#150e18"
        c.bg_statusline = "#4d1f3d"
        c.bg_visual = "#412a3d"
        c.bg_search = "#c93d80"

        c.fg = "#ffd6ec"
        c.fg_dark = "#c99ab4"
        c.fg_float = "#ffd6ec"
        c.fg_sidebar = "#c99ab4"
        c.fg_gutter = "#8a6b7d"
        c.comment = "#8a6b7d"

        c.blue = "#ff4fa3"
        c.blue1 = "#ff7ab8"
        c.blue5 = "#ff7ab8"
        c.blue6 = "#ffd6ec"
        c.blue7 = "#c93d80"
        c.border = "#412a3d"
        c.border_highlight = "#ff4fa3"

        c.magenta = "#bb9af7"
        c.magenta2 = "#ff7ab8"
        c.purple = "#9d7cd8"
        c.cyan = "#7dcfff"
        c.teal = "#73daca"
        c.green = "#9ece6a"
        c.yellow = "#e0af68"
        c.orange = "#ff9e64"
        c.red = "#f7768e"
        c.red1 = "#db4b4b"
      end,
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } },
}
