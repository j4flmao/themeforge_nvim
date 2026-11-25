local M = {}

-- Default state shape
local default_state = {
  active_theme = nil,
  favorite_themes = {},
  recent_themes = {},
  color_overrides = {},
  overrides = {},
  palette_mix = { purple = 0, blue = 0, green = 0, pink = 0, orange = 0, cyan = 0, warm = 0, saturation = 50, brightness = 50, opacity = 100 },
  ui_options = {
    transparency = false,
    italic_keywords = false,
    bold_functions = false,
    cursorline = true,
    underline_diag = true,
    bold_cursor = true,
    signcolumn = "yes",
    statusline = "full",
  },
}

M.current = vim.deepcopy(default_state)
M.config = {} -- populated by setup()
M.preview_snapshot = nil
M.history = { undo = {}, redo = {} }

local function editable_snapshot()
  return {
    active_theme = M.current.active_theme,
    overrides = vim.deepcopy(M.current.overrides),
    color_overrides = vim.deepcopy(M.current.color_overrides),
    palette_mix = vim.deepcopy(M.current.palette_mix),
    ui_options = vim.deepcopy(M.current.ui_options),
  }
end

local function restore_snapshot(snapshot)
  M.current.active_theme = snapshot.active_theme
  M.current.overrides = vim.deepcopy(snapshot.overrides or {})
  M.current.color_overrides = vim.deepcopy(snapshot.color_overrides or {})
  M.current.palette_mix = vim.deepcopy(snapshot.palette_mix or {})
  M.current.ui_options = vim.deepcopy(snapshot.ui_options or {})
end

function M.begin_preview()
  if not M.preview_snapshot then
    M.preview_snapshot = vim.deepcopy(M.current)
    M.history = { undo = {}, redo = {} }
  end
end

function M.commit_preview()
  M.preview_snapshot = nil
end

function M.cancel_preview()
  if not M.preview_snapshot then return false end
  M.current = M.preview_snapshot
  M.preview_snapshot = nil
  M.history = { undo = {}, redo = {} }
  return true
end

function M.checkpoint()
  local snapshot = editable_snapshot()
  local previous = M.history.undo[#M.history.undo]
  if previous and vim.deep_equal(previous, snapshot) then return end
  table.insert(M.history.undo, snapshot)
  while #M.history.undo > 50 do table.remove(M.history.undo, 1) end
  M.history.redo = {}
end

function M.undo()
  local snapshot = table.remove(M.history.undo)
  if not snapshot then return false end
  table.insert(M.history.redo, editable_snapshot())
  restore_snapshot(snapshot)
  return true
end

function M.redo()
  local snapshot = table.remove(M.history.redo)
  if not snapshot then return false end
  table.insert(M.history.undo, editable_snapshot())
  restore_snapshot(snapshot)
  return true
end

function M.set_theme(theme_id)
  M.current.active_theme = theme_id
  M.current.overrides = {}
  M.current.color_overrides = {}
  M.current.palette_mix = { purple = 0, blue = 0, green = 0, pink = 0, orange = 0, cyan = 0, warm = 0, saturation = 50, brightness = 50, opacity = 100 }
end

function M.is_favorite(theme_id)
  for _, id in ipairs(M.current.favorite_themes or {}) do
    if id == theme_id then return true end
  end
  return false
end

function M.toggle_favorite(theme_id)
  if not theme_id then return false end
  local favorites = M.current.favorite_themes or {}
  for i, id in ipairs(favorites) do
    if id == theme_id then
      table.remove(favorites, i)
      M.current.favorite_themes = favorites
      if M.config.autosave_cache ~= false then M.save_cache() end
      return false
    end
  end
  table.insert(favorites, theme_id)
  M.current.favorite_themes = favorites
  if M.config.autosave_cache ~= false then M.save_cache() end
  return true
end

function M.record_recent(theme_id)
  if not theme_id then return end
  local recent = {}
  for _, id in ipairs(M.current.recent_themes or {}) do
    if id ~= theme_id then table.insert(recent, id) end
  end
  table.insert(recent, 1, theme_id)
  while #recent > 5 do table.remove(recent) end
  M.current.recent_themes = recent
  if M.config.autosave_cache ~= false then M.save_cache() end
end

function M.set_override(group, opts)
  M.current.overrides[group] = opts
end

function M.set_color_override(key, value)
  if value == nil then
    M.current.color_overrides[key] = nil
  else
    M.current.color_overrides[key] = value
  end
end

function M.set_mix(key, value)
  M.current.palette_mix[key] = value
end

function M.set_ui_option(key, value)
  M.current.ui_options[key] = value
end

function M.reset()
  M.current.overrides = {}
  M.current.color_overrides = {}
  M.current.palette_mix = { purple = 0, blue = 0, green = 0, pink = 0, orange = 0, cyan = 0, warm = 0, saturation = 50, brightness = 50, opacity = 100 }
end

function M.get_cache_path()
  return M.config.cache_path or (vim.fn.stdpath("data") .. "/themeforge/last.json")
end

function M.save_cache()
  local path = M.get_cache_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    local ok = pcall(vim.fn.mkdir, dir, "p")
    if not ok or vim.fn.isdirectory(dir) == 0 then
      return false
    end
  end
  local data = vim.fn.json_encode(M.current)
  local f = io.open(path, "w")
  if f then
    f:write(data)
    f:close()
    return true
  end
  return false
end

function M.load_cache()
  local path = M.get_cache_path()
  local f = io.open(path, "r")
  if not f then return false end
  local raw = f:read("*a")
  f:close()
  local ok, data = pcall(vim.fn.json_decode, raw)
  if ok and data and data.active_theme then
    M.current.active_theme = data.active_theme
    M.current.favorite_themes = data.favorite_themes or {}
    M.current.recent_themes = data.recent_themes or {}
    M.current.overrides = data.overrides or {}
    M.current.color_overrides = data.color_overrides or {}
    M.current.palette_mix = data.palette_mix or vim.deepcopy(default_state.palette_mix)
    M.current.ui_options = vim.tbl_extend("force", M.current.ui_options, data.ui_options or {})
    return true
  end
  return false
end

return M
