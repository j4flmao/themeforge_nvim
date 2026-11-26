local M = {}

local state = require("themeforge.state")
local resolver = require("themeforge.resolver")
local themes = require("themeforge.themes")
local compat = require("themeforge.compat")
local managed_groups = {}
-- Definition each group had before ThemeForge first touched it (false = none).
-- Restored instead of clearing, so Neovim's default links (e.g.
-- @lsp.type.parameter -> @variable.parameter) survive a reset.
local originals = {}

local function remember(group)
  if originals[group] == nil then
    local ok, def = pcall(vim.api.nvim_get_hl, 0, { name = group, create = false })
    originals[group] = (ok and def and next(def)) and def or false
  end
end

--- Definition a group had before ThemeForge touched it (or its current one if
--- ThemeForge never managed it). Used to keep style-only LSP edits on the real colour.
function M.original(group)
  if originals[group] ~= nil then
    return originals[group] or nil
  end
  local ok, def = pcall(vim.api.nvim_get_hl, 0, { name = group, create = false })
  return (ok and def and next(def)) and def or nil
end

local function set_managed(group, hl)
  remember(group)
  local ok = pcall(vim.api.nvim_set_hl, 0, group, hl)
  if ok then managed_groups[group] = true end
  return ok
end

-- 16 ANSI colours for :terminal buffers, taken from the resolved palette.
local function set_terminal_colors(c)
  local order = {
    c.bg2 or c.bg, c.red, c.green, c.yellow, c.blue, c.purple, c.cyan, c.fg2 or c.fg,
    c.comment, c.red, c.green, c.yellow, c.blue, c.purple, c.cyan, c.fg,
  }
  for i, hex in ipairs(order) do
    if hex then vim.g["terminal_color_" .. (i - 1)] = hex end
  end
end

-- Let statuslines and user config react to a theme change. Lualine caches
-- its colours, so it gets an explicit refresh when it is loaded.
-- lualine builds its section colours (and per-component groups) when it is set
-- up; re-run its setup so it reloads lua/lualine/themes/themeforge.lua.
-- Debounced: preview can fire on every slider step.
local lualine_timer
local function reload_lualine()
  if not package.loaded["lualine"] then return end
  lualine_timer = lualine_timer or vim.uv.new_timer()
  lualine_timer:stop()
  lualine_timer:start(80, 0, vim.schedule_wrap(function()
    pcall(function() require("lualine").setup() end)
  end))
end

local firing_colorscheme = false
--- Fire ColorScheme like a real colorscheme, so plugins (bufferline, lualine,
--- devicons…) rebuild their highlights, then put ThemeForge's own groups back
--- on top of whatever they derived.
local function fire_colorscheme(colors)
  if firing_colorscheme then return end
  firing_colorscheme = true
  pcall(vim.api.nvim_exec_autocmds, "ColorScheme", { pattern = "themeforge", modeline = false })
  firing_colorscheme = false
  for group, _ in pairs(compat.apply(colors, state.config.compat or "auto")) do
    managed_groups[group] = true
  end
end

local function notify_applied(theme_id, colors, preview)
  set_terminal_colors(colors)
  if not preview then fire_colorscheme(colors) end
  reload_lualine()
  pcall(vim.api.nvim_exec_autocmds, "User", {
    pattern = "ThemeForgeApplied",
    modeline = false,
    data = { theme = theme_id, colors = colors, preview = preview == true },
  })
end

local function clear_managed_groups()
  for group, _ in pairs(managed_groups) do
    pcall(vim.api.nvim_set_hl, 0, group, originals[group] or {})
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

  local highlights, colors = resolver.resolve(theme, overrides, ui_options, mix, state.current.color_overrides, state.current.lsp_tokens)

  -- Clear only highlights owned by ThemeForge. A global highlight clear also
  -- destroys unrelated user and plugin customization.
  clear_managed_groups()

  -- Apply all highlight groups
  for group, hl in pairs(highlights) do
    set_managed(group, hl) -- invalid groups are skipped silently
  end

  -- Apply compat modules
  for group, _ in pairs(compat.apply(colors, state.config.compat or "auto")) do
    managed_groups[group] = true
  end

  vim.g.colors_name = "themeforge"
  notify_applied(theme_id, colors, false)

  -- Profiles, random themes and blends apply for real: reflect that in the panel.
  local panel = package.loaded["themeforge.ui.panel"]
  if panel and panel.is_open and not panel.closing then
    state.current.active_theme = theme_id
    state.commit_preview()
    state.begin_preview()
    panel.set_status("applied")
    vim.schedule(function() if panel.is_open then panel.render_all() end end)
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

  local highlights, colors = resolver.resolve(theme, overrides or {}, ui_options or state.current.ui_options, mix or {}, state.current.color_overrides, state.current.lsp_tokens)

  clear_managed_groups()
  for group, hl in pairs(highlights) do
    set_managed(group, hl)
  end

  for group, _ in pairs(compat.apply(colors, state.config.compat or "auto")) do
    managed_groups[group] = true
  end

  notify_applied(theme_id, colors, true)
  local panel = package.loaded["themeforge.ui.panel"]
  if panel and panel.is_open then panel.set_status("preview") end
  return true
end

return M
