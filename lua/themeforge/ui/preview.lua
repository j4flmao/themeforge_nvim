local M = {}

local state = require("themeforge.state")
local themes_mod = require("themeforge.themes")
local palette_mod = require("themeforge.palette")

local panel_ref = nil
local ns = vim.api.nvim_create_namespace("themeforge_preview")

-- Token roles map to highlight group names in theme.groups
-- We look up the actual color from the theme's group definitions
local ROLE = {
  keyword  = { "@keyword", "Keyword", "Statement" },
  func     = { "@function", "Function" },
  string   = { "@string", "String" },
  number   = { "@number", "Number", "Constant" },
  comment  = { "@comment", "Comment" },
  type     = { "@type", "Type" },
  variable = { "@variable", "Identifier" },
  operator = { "@operator", "Operator" },
  punct    = { "@punctuation", "Delimiter" },
  todo     = { "Todo" },
}

-- Each line: list of { text, role }
local preview_blocks = {
  -- ── Lua ──
  { { "-- Lua sample", "comment" } },
  { { "local ", "keyword" }, { "function ", "keyword" }, { "greet", "func" }, { "(", "punct" }, { "name", "variable" }, { ")", "punct" } },
  { { "  local ", "keyword" }, { "msg", "variable" }, { " = ", "operator" }, { '"Hello, "', "string" }, { " .. ", "operator" }, { "name", "variable" }, { " .. ", "operator" }, { '"!"', "string" } },
  { { "  local ", "keyword" }, { "count", "variable" }, { " = ", "operator" }, { "42", "number" } },
  { { "  local ", "keyword" }, { "enabled", "variable" }, { " = ", "operator" }, { "true", "number" } },
  { { "  if ", "keyword" }, { "enabled", "variable" }, { " then", "keyword" } },
  { { "    ", "variable" }, { "print", "func" }, { "(", "punct" }, { "msg", "variable" }, { ")", "punct" } },
  { { "  end", "keyword" } },
  { { "  return ", "keyword" }, { "count", "variable" } },
  { { "end", "keyword" } },
  {},
  { { "-- Table and loop", "comment" } },
  { { "local ", "keyword" }, { "colors", "variable" }, { " = {", "punct" } },
  { { '  red', "variable" }, { " = ", "operator" }, { '"#ff0000"', "string" }, { ",", "punct" } },
  { { '  green', "variable" }, { " = ", "operator" }, { '"#00ff00"', "string" }, { ",", "punct" } },
  { { "}", "punct" } },
  {},
  { { "for ", "keyword" }, { "key", "variable" }, { ", ", "punct" }, { "value", "variable" }, { " in ", "keyword" }, { "pairs", "func" }, { "(", "punct" }, { "colors", "variable" }, { ")", "punct" }, { " do", "keyword" } },
  { { "  vim.api.", "variable" }, { "nvim_set_hl", "func" }, { "(", "punct" }, { "0", "number" }, { ", ", "punct" }, { "key", "variable" }, { ", ", "punct" }, { "{ ", "punct" }, { "fg", "variable" }, { " = ", "operator" }, { "value", "variable" }, { " }", "punct" }, { ")", "punct" } },
  { { "end", "keyword" } },
  {},
  { { "-- TODO: Add more colors", "todo" } },
  { { "-- NOTE: This is a preview", "comment" } },
  {},
  -- ── Python ──
  { { "# Python sample", "comment" } },
  { { "def ", "keyword" }, { "calculate", "func" }, { "(", "punct" }, { "x", "variable" }, { ": ", "punct" }, { "int", "type" }, { ", ", "punct" }, { "y", "variable" }, { ": ", "punct" }, { "float", "type" }, { ")", "punct" }, { " -> ", "operator" }, { "float", "type" }, { ":", "punct" } },
  { { '    """Calculate the weighted sum."""', "string" } },
  { { "    result", "variable" }, { " = ", "operator" }, { "x", "variable" }, { " * ", "operator" }, { "3.14", "number" }, { " + ", "operator" }, { "y", "variable" } },
  { { "    values", "variable" }, { " = [", "punct" }, { "1", "number" }, { ", ", "punct" }, { "2", "number" }, { ", ", "punct" }, { "3", "number" }, { ", ", "punct" }, { "4", "number" }, { ", ", "punct" }, { "5", "number" }, { "]", "punct" } },
  {},
  { { "    for ", "keyword" }, { "item", "variable" }, { " in ", "keyword" }, { "values", "variable" }, { ":", "punct" } },
  { { "        if ", "keyword" }, { "item", "variable" }, { " > ", "operator" }, { "2", "number" }, { ":", "punct" } },
  { { "            ", "variable" }, { "print", "func" }, { "(", "punct" }, { 'f"Value: {item}"', "string" }, { ")", "punct" } },
  {},
  { { "    return ", "keyword" }, { "result", "variable" } },
  {},
  { { "class ", "keyword" }, { "ThemeManager", "type" }, { ":", "punct" } },
  { { "    name", "variable" }, { ": ", "punct" }, { "str", "type" }, { " = ", "operator" }, { '"default"', "string" } },
  { { "    count", "variable" }, { ": ", "punct" }, { "int", "type" }, { " = ", "operator" }, { "0", "number" } },
  {},
  -- ── TypeScript ──
  { { "// TypeScript sample", "comment" } },
  { { "interface ", "keyword" }, { "Theme", "type" }, { " {", "punct" } },
  { { "  name", "variable" }, { ": ", "punct" }, { "string", "type" }, { ";", "punct" } },
  { { "  variant", "variable" }, { ": ", "punct" }, { "'dark'", "string" }, { " | ", "operator" }, { "'light'", "string" }, { ";", "punct" } },
  { { "  colors", "variable" }, { ": ", "punct" }, { "Record", "type" }, { "<", "punct" }, { "string", "type" }, { ", ", "punct" }, { "string", "type" }, { ">", "punct" }, { ";", "punct" } },
  { { "}", "punct" } },
  {},
  { { "const ", "keyword" }, { "loadTheme", "func" }, { " = ", "operator" }, { "async ", "keyword" }, { "(", "punct" }, { "id", "variable" }, { ": ", "punct" }, { "string", "type" }, { ")", "punct" }, { " => {", "punct" } },
  { { "  const ", "keyword" }, { "response", "variable" }, { " = ", "operator" }, { "await ", "keyword" }, { "fetch", "func" }, { "(", "punct" }, { "`/api/themes/${id}`", "string" }, { ")", "punct" }, { ";", "punct" } },
  { { "  const ", "keyword" }, { "data", "variable" }, { ": ", "punct" }, { "Theme", "type" }, { " = ", "operator" }, { "await ", "keyword" }, { "response", "variable" }, { ".", "punct" }, { "json", "func" }, { "()", "punct" }, { ";", "punct" } },
  { { "  return ", "keyword" }, { "data", "variable" }, { ";", "punct" } },
  { { "};", "punct" } },
  {},
  { { "export ", "keyword" }, { "function ", "keyword" }, { "applyTheme", "func" }, { "(", "punct" }, { "theme", "variable" }, { ": ", "punct" }, { "Theme", "type" }, { ")", "punct" }, { ": ", "punct" }, { "void", "type" }, { " {", "punct" } },
  { { "  document", "variable" }, { ".", "punct" }, { "documentElement", "variable" }, { ".", "punct" }, { "style", "variable" }, { ".", "punct" }, { "setProperty", "func" }, { "(", "punct" } },
  { { "    ", "variable" }, { "'--bg-color'", "string" }, { ",", "punct" } },
  { { "    theme", "variable" }, { ".", "punct" }, { "colors", "variable" }, { ".", "punct" }, { "background", "variable" } },
  { { "  )", "punct" }, { ";", "punct" } },
  { { "}", "punct" } },
}

-- Resolve the actual fg color for a role from theme groups
local function resolve_role_color(role, theme_groups, colors, mix)
  local group_names = ROLE[role]
  if not group_names then return nil end

  for _, gname in ipairs(group_names) do
    local gdef = theme_groups[gname]
    if gdef and gdef.fg then
      -- gdef.fg is a color key like "purple", "pink", "iris" etc.
      local hex = colors[gdef.fg] or gdef.fg
      if palette_mod.is_valid_hex(hex) then
        return hex
      end
    end
  end
  return nil
end

-- Build resolved color map { role -> hex } from current theme
local function get_role_colors()
  local theme_id = state.current.active_theme
  if not theme_id then return nil end
  local theme = themes_mod.get(theme_id)
  if not theme then return nil end

  local mix = state.current.palette_mix or {}

  -- Same palette as the editor: overrides, OKLCH blend and contrast floor.
  local colors = require("themeforge.resolver").palette(theme, mix, state.current.color_overrides)

  local role_colors = {}
  for role, _ in pairs(ROLE) do
    role_colors[role] = resolve_role_color(role, theme.groups, colors, mix)
  end

  -- Fallback: if role didn't resolve, use a sensible default from colors
  role_colors.keyword  = role_colors.keyword  or colors.purple
  role_colors.func     = role_colors.func     or colors.blue
  role_colors.string   = role_colors.string   or colors.green
  role_colors.number   = role_colors.number   or colors.orange
  role_colors.comment  = role_colors.comment  or colors.comment
  role_colors.type     = role_colors.type     or colors.cyan
  role_colors.variable = role_colors.variable or colors.fg
  role_colors.operator = role_colors.operator or colors.fg2
  role_colors.punct    = role_colors.punct    or colors.fg2
  role_colors.todo     = role_colors.todo     or colors.yellow

  -- Also keep bg/fg for line numbers
  role_colors._linenr = colors.comment or colors.fg2
  role_colors._bg2 = colors.bg2

  return role_colors
end

function M.init(panel)
  panel_ref = panel
  M.render()
end

function M.render()
  -- The preview pane is hidden on narrow layouts.
  if not panel_ref or not panel_ref.bufs then return end
  local buf = panel_ref.bufs.preview
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local role_colors = get_role_colors()

  -- Create hl groups for each role
  if role_colors then
    for role, hex in pairs(role_colors) do
      if hex and palette_mod.is_valid_hex(hex) then
        vim.api.nvim_set_hl(0, "ThemeForgeP_" .. role, { fg = hex })
      end
    end
    if role_colors._linenr then
      vim.api.nvim_set_hl(0, "ThemeForgeP_linenr", { fg = role_colors._linenr })
    end
  end

  -- Build lines
  local lines = {}
  for i, block in ipairs(preview_blocks) do
    local text = ""
    for _, token in ipairs(block) do
      text = text .. token[1]
    end
    table.insert(lines, string.format(" %3d  %s", i, text))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Apply extmark highlights
  if role_colors then
    for i, block in ipairs(preview_blocks) do
      local col_offset = 6 -- " NNN  " prefix
      for _, token in ipairs(block) do
        local text = token[1]
        local role = token[2]
        if role and role_colors[role] then
          pcall(vim.api.nvim_buf_set_extmark, buf, ns, i - 1, col_offset, {
            end_col = col_offset + #text,
            hl_group = "ThemeForgeP_" .. role,
          })
        end
        col_offset = col_offset + #text
      end

      -- Line number highlight
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, i - 1, 0, {
        end_col = 6,
        hl_group = "ThemeForgeP_linenr",
      })
    end
  end

  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local win = panel_ref.wins.preview
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_option(win, "number", false)
    vim.api.nvim_win_set_option(win, "relativenumber", false)
    vim.api.nvim_win_set_option(win, "cursorline", false)
    vim.api.nvim_win_set_option(win, "wrap", false)
  end
end

return M
