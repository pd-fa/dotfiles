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
        c.bg = "#141021"
        c.bg_dark = "#0e0b17"
        c.bg_float = "#0e0b17"
        c.bg_highlight = "#1f1930"
        c.bg_popup = "#0e0b17"
        c.bg_sidebar = "#0e0b17"
        c.bg_statusline = "#1a1530"
        c.bg_visual = "#2c2246"
        c.bg_search = "#c93d80"

        c.fg = "#e9e2f8"
        c.fg_dark = "#c3b3e8"
        c.fg_float = "#e9e2f8"
        c.fg_sidebar = "#c3b3e8"
        c.fg_gutter = "#9c8cc4"
        c.comment = "#9c8cc4"

        c.blue = "#ff4fa3"
        c.blue1 = "#ff7ab8"
        c.blue5 = "#ff7ab8"
        c.blue6 = "#e9e2f8"
        c.blue7 = "#c93d80"
        c.border = "#2c2246"
        c.border_highlight = "#ff4fa3"

        c.magenta = "#c9aefc"
        c.magenta2 = "#ff7ab8"
        c.purple = "#ab8df3"
        c.cyan = "#8ce6ff"
        c.teal = "#85ecd6"
        c.green = "#a6dd70"
        c.yellow = "#e8bd76"
        c.orange = "#ffab77"
        c.red = "#ff8fa3"
        c.red1 = "#ef5f5f"
      end,
      -- The dashboard renders before any buffer, so it sets the first impression
      -- of the theme. Pink stays on the header alone; keys and icons take cyan,
      -- which is the highest-contrast slot in the palette and the fastest thing
      -- to scan a list by.
      on_highlights = function(hl, c)
        hl.SnacksDashboardHeader = { fg = "#ff4fa3" }
        hl.SnacksDashboardIcon = { fg = "#8ce6ff" }
        hl.SnacksDashboardKey = { fg = "#8ce6ff", bold = true }
        hl.SnacksDashboardDesc = { fg = "#e9e2f8" }
        hl.SnacksDashboardFile = { fg = "#e9e2f8" }
        hl.SnacksDashboardDir = { fg = "#9c8cc4" }
        hl.SnacksDashboardFooter = { fg = "#9c8cc4", italic = true }
        hl.SnacksDashboardSpecial = { fg = "#c9aefc" }
        hl.SnacksDashboardTitle = { fg = "#85ecd6" }
      end,
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } },
}
