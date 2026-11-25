-- ThemeForge.nvim integration smoke tests.
-- Run with:
-- nvim --headless -u NONE --cmd 'set rtp^=.' -c 'runtime plugin/themeforge.lua' -c 'luafile tests/smoke.lua' -c 'qa!'

local themeforge = require("themeforge")
local state = require("themeforge.state")
local themes = require("themeforge.themes")
local resolver = require("themeforge.resolver")
local writer = require("themeforge.writer")

state.config = { autosave_cache = false }

assert(#themes.ids() == 15, "expected 15 bundled themes")
assert(vim.fn.exists(":ThemeForge") == 2, "ThemeForge command is missing")

assert(themeforge.apply("tokyonight-storm"), "base theme should apply")
assert(themeforge.apply({ colors = { purple = "#cba6f7" } }), "color override should apply")
assert(state.current.color_overrides.purple == "#cba6f7")

local theme = themes.get("tokyonight-storm")
local highlights = resolver.resolve(theme, {}, state.current.ui_options, state.current.palette_mix, state.current.color_overrides)
assert(highlights.Keyword.fg == "#cba6f7", "semantic color override was not resolved")

local block = table.concat(writer.generate_block(), "\n")
assert(block:find("colors =", 1, true), "export should include color overrides")
assert(block:find("#cba6f7", 1, true), "export should include the selected color")

state.current.active_theme = "tokyonight-storm"
state.current.palette_mix.blue = 0
state.checkpoint()
state.set_mix("blue", 40)
assert(state.undo() and state.current.palette_mix.blue == 0, "undo failed")
assert(state.redo() and state.current.palette_mix.blue == 40, "redo failed")

assert(themeforge.apply_profile("high-contrast"), "high-contrast profile should apply")
assert(state.current.color_overrides.fg == "#f2f4f8")
assert(#themeforge.list_profiles() == 4, "expected four built-in profiles")

local tagged = false
for _, item in ipairs(themes.list()) do
  for _, tag in ipairs(item.tags or {}) do
    if tag == "calm" then tagged = true end
  end
end
assert(tagged, "theme metadata tags are missing")

print("ThemeForge smoke tests passed")
