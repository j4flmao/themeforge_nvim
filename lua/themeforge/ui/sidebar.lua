local M = {}

local themes = require("themeforge.themes")
local state = require("themeforge.state")

local panel_ref = nil
local theme_list = {}
local filtered_list = {}
local cursor_pos = 1
local search_mode = false
local search_query = ""

function M.init(panel)
  panel_ref = panel
  theme_list = themes.list()
  filtered_list = theme_list
  cursor_pos = 1

  -- Find current theme position
  if state.current.active_theme then
    for i, t in ipairs(filtered_list) do
      if t.id == state.current.active_theme then
        cursor_pos = i
        break
      end
    end
  end

  M.render()
  M.setup_keymaps()
end

function M.render()
  local buf = panel_ref.bufs.sidebar
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  local lines = {}
  local highlights = {}

  -- Header
  table.insert(lines, " THEMES")
  table.insert(lines, " ───────────────────")
  table.insert(lines, "")

  -- ThemeForge currently ships a focused dark-only catalog.
  local dark_themes = {}
  for _, t in ipairs(filtered_list) do
    if t.variant == "dark" then
      table.insert(dark_themes, t)
    end
  end

  -- Track line -> theme index mapping
  local line_map = {}

  table.insert(lines, "  Dark")
  table.insert(lines, "  ────")

  for i, t in ipairs(dark_themes) do
    local active = (state.current.active_theme == t.id)
    local marker = active and " ● " or " ○ "
    local display = marker .. t.name
    table.insert(lines, display)
    for j, ft in ipairs(filtered_list) do
      if ft.id == t.id then
        line_map[#lines] = j
        break
      end
    end
  end

  -- Search indicator at bottom
  table.insert(lines, "")
  table.insert(lines, " ──────────────────────")
  if search_mode then
    table.insert(lines, " / " .. search_query .. "▏")
  else
    table.insert(lines, " [/] search")
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Store line_map for navigation
  M._line_map = line_map
  M._lines = lines
end

function M.get_theme_at_cursor()
  local win = panel_ref.wins.sidebar
  if not win or not vim.api.nvim_win_is_valid(win) then return nil end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  local idx = M._line_map and M._line_map[row]
  if idx and filtered_list[idx] then
    return filtered_list[idx]
  end
  return nil
end

function M.select_theme(theme_info)
  if not theme_info then return end
  state.set_theme(theme_info.id)

  -- Live preview
  local apply = require("themeforge.apply")
  apply.preview(theme_info.id, {}, state.current.ui_options, state.current.palette_mix)

  -- Update controls
  local controls = require("themeforge.ui.controls")
  controls.render()

  -- Update preview
  local preview_mod = require("themeforge.ui.preview")
  preview_mod.render()

  -- Re-render sidebar
  M.render()
end

function M.filter(query)
  search_query = query
  if query == "" then
    filtered_list = theme_list
  else
    filtered_list = {}
    local q = query:lower()
    for _, t in ipairs(theme_list) do
      if t.name:lower():find(q, 1, true) or t.id:lower():find(q, 1, true) then
        table.insert(filtered_list, t)
      end
    end
  end
  cursor_pos = 1
  M.render()
end

function M.setup_keymaps()
  local buf = panel_ref.bufs.sidebar
  if not buf then return end

  local function map(key, action)
    vim.keymap.set("n", key, action, { buffer = buf, nowait = true, silent = true })
  end

  map("<CR>", function()
    local theme = M.get_theme_at_cursor()
    if theme then
      M.select_theme(theme)
    end
  end)

  map("/", function()
    search_mode = true
    search_query = ""
    M.render()
    vim.defer_fn(function()
      local input = vim.fn.input("Search: ")
      search_mode = false
      M.filter(input ~= "" and input or "")
    end, 10)
  end)
end

return M
