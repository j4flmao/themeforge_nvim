local M = {}

local state = require("themeforge.state")
local themes = require("themeforge.themes")
local resolver = require("themeforge.resolver")
local palette = require("themeforge.palette")

local function check(lines, label, fg, bg, minimum)
  if not palette.is_valid_hex(fg) or not palette.is_valid_hex(bg) then
    table.insert(lines, string.format("  %-18s missing colors", label))
    return
  end
  local ratio = palette.contrast_ratio(fg, bg)
  local mark = ratio >= minimum and "OK" or "LOW"
  table.insert(lines, string.format("  %-18s %4.1fx  %s", label, ratio, mark))
end

function M.run()
  local theme = state.current.active_theme and themes.get(state.current.active_theme)
  if not theme then
    vim.notify("[ThemeForge Doctor] No active theme", vim.log.levels.WARN)
    return false
  end

  local _, colors = resolver.resolve(theme, state.current.overrides, state.current.ui_options, state.current.palette_mix)
  local lines = { "ThemeForge Doctor — " .. (theme.name or theme.id), "", "Contrast" }
  check(lines, "Text", colors.fg, colors.bg, 4.5)
  check(lines, "Comment", colors.comment, colors.bg, 3)
  check(lines, "Line numbers", colors.fg2 or colors.fg, colors.bg, 3)
  check(lines, "Git untracked", colors.green, colors.bg, 3)
  check(lines, "Explorer counter", colors.fg, colors.bg2 or colors.bg, 3)
  table.insert(lines, "")
  table.insert(lines, "Managed integrations")
  local groups = vim.api.nvim_get_hl(0, { name = "SnacksPickerGitStatusUntracked", link = false })
  table.insert(lines, string.format("  Snacks Explorer    %s", groups.fg and "ready" or "fallback"))
  local bufferline = vim.api.nvim_get_hl(0, { name = "BufferLineSeparator", link = false })
  table.insert(lines, string.format("  Bufferline          %s", bufferline.fg and "ready" or "fallback"))
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  return true
end

return M
