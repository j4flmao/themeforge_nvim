-- lualine theme for ThemeForge.nvim.
-- lualine's "auto" theme loads lua/lualine/themes/<colors_name>.lua, and
-- ThemeForge sets vim.g.colors_name = "themeforge", so this file is picked up
-- automatically. It follows the active theme, blend sliders and colour edits.
local state = require("themeforge.state")
local themes = require("themeforge.themes")
local theme = themes.get(state.current.active_theme or "") or themes.get("tokyonight-storm")
local colors = require("themeforge.resolver").palette(theme, state.current.palette_mix, state.current.color_overrides)
return require("themeforge.compat.lualine").theme(colors)
