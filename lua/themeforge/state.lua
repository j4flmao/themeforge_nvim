local M = {}

-- Default state shape
local default_state = {
  active_theme = nil,
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

function M.set_theme(theme_id)
  M.current.active_theme = theme_id
  M.current.overrides = {}
  M.current.palette_mix = { purple = 0, blue = 0, green = 0, pink = 0, orange = 0, cyan = 0, warm = 0, saturation = 50, brightness = 50, opacity = 100 }
end

function M.set_override(group, opts)
  M.current.overrides[group] = opts
end

function M.set_mix(key, value)
  M.current.palette_mix[key] = value
end

function M.set_ui_option(key, value)
  M.current.ui_options[key] = value
end

function M.reset()
  M.current.overrides = {}
  M.current.palette_mix = { purple = 0, blue = 0, green = 0, pink = 0, orange = 0, cyan = 0, warm = 0, saturation = 50, brightness = 50, opacity = 100 }
end

function M.get_cache_path()
  return M.config.cache_path or (vim.fn.stdpath("data") .. "/themeforge/last.json")
end

function M.save_cache()
  local path = M.get_cache_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  local data = vim.fn.json_encode(M.current)
  local f = io.open(path, "w")
  if f then
    f:write(data)
    f:close()
  end
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
    M.current.overrides = data.overrides or {}
    M.current.palette_mix = data.palette_mix or vim.deepcopy(default_state.palette_mix)
    M.current.ui_options = vim.tbl_extend("force", M.current.ui_options, data.ui_options or {})
    return true
  end
  return false
end

return M
