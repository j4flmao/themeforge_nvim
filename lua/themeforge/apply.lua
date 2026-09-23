local M = {}

local state = require("themeforge.state")
local resolver = require("themeforge.resolver")
local themes = require("themeforge.themes")
local compat = require("themeforge.compat")
local managed_groups = {}

local function clear_managed_groups()
  for group, _ in pairs(managed_groups) do
    pcall(vim.api.nvim_set_hl, 0, group, {})
  end
  managed_groups = {}
end

function M.apply(opts)
  local theme_id, overrides, ui_options, mix

  if type(opts) == "string" then
    theme_id = opts
    overrides = state.current.overrides
    ui_options = state.current.ui_options
    mix = state.current.palette_mix
  elseif type(opts) == "table" then
    theme_id = opts.theme or state.current.active_theme
    overrides = opts.overrides or state.current.overrides
    ui_options = opts.ui and vim.tbl_extend("force", state.current.ui_options, opts.ui) or state.current.ui_options
    mix = opts.mix or state.current.palette_mix
  else
    theme_id = state.current.active_theme
    overrides = state.current.overrides
    ui_options = state.current.ui_options
    mix = state.current.palette_mix
  end

  if not theme_id then
    vim.notify("[ThemeForge] No theme selected", vim.log.levels.WARN)
    return false
  end

  local theme = themes.get(theme_id)
  if not theme then
    vim.notify("[ThemeForge] Theme not found: " .. theme_id, vim.log.levels.ERROR)
    return false
  end

  local highlights, colors = resolver.resolve(theme, overrides, ui_options, mix)

  -- Clear only highlights owned by ThemeForge. A global highlight clear also
  -- destroys unrelated user and plugin customization.
  clear_managed_groups()

  -- Apply all highlight groups
  for group, hl in pairs(highlights) do
    local ok, err = pcall(vim.api.nvim_set_hl, 0, group, hl)
    if not ok then
      -- silently skip invalid groups
    else
      managed_groups[group] = true
    end
  end

  -- Apply compat modules
  for group, _ in pairs(compat.apply(colors, state.config.compat or "auto")) do
    managed_groups[group] = true
  end

  -- Update state
  state.current.active_theme = theme_id
  if type(opts) == "table" and opts.overrides then
    state.current.overrides = opts.overrides
  end
  if type(opts) == "table" and opts.ui then
    state.current.ui_options = vim.tbl_extend("force", state.current.ui_options, opts.ui)
  end

  -- Save cache if enabled
  if state.config.autosave_cache ~= false then
    state.save_cache()
  end

  return true
end

-- Apply for preview (does not update state or cache)
function M.preview(theme_id, overrides, ui_options, mix)
  local theme = themes.get(theme_id)
  if not theme then return false end

  local highlights, colors = resolver.resolve(theme, overrides or {}, ui_options or state.current.ui_options, mix or {})

  clear_managed_groups()
  for group, hl in pairs(highlights) do
    pcall(vim.api.nvim_set_hl, 0, group, hl)
    managed_groups[group] = true
  end

  for group, _ in pairs(compat.apply(colors, state.config.compat or "auto")) do
    managed_groups[group] = true
  end

  return true
end

return M
