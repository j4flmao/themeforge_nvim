-- Editing LSP semantic tokens: shared by the panel (LSP TOKENS rows) and
-- `:ThemeForge token` (the token under the cursor in a code buffer).
local M = {}

local state = require("themeforge.state")
local lsp = require("themeforge.lsp_tokens")
local picker = require("themeforge.ui.picker")

local function palette()
  local theme = state.current.active_theme and require("themeforge.themes").get(state.current.active_theme)
  if not theme then return {} end
  return require("themeforge.resolver").palette(theme, state.current.palette_mix, state.current.color_overrides)
end

local function current(group)
  return vim.deepcopy((state.current.lsp_tokens or {})[group] or {})
end

local function commit(group, spec, on_change)
  state.checkpoint()
  state.set_lsp_token(group, spec)
  if on_change then on_change() end
end

--- Pick a colour for `group`: a palette key, a custom hex, or the default.
function M.pick_color(group, label, on_change)
  local colors = palette()
  local cur = current(group).fg
  local items = {}
  for _, key in ipairs(lsp.PALETTE_KEYS) do
    if colors[key] then
      table.insert(items, { label = key, detail = colors[key], value = key, color = colors[key], selected = cur == key })
    end
  end
  local is_hex = cur and cur:match("^#%x%x%x%x%x%x$")
  table.insert(items, {
    label = is_hex and ("custom " .. cur) or "custom #hex…", value = "__hex",
    color = is_hex and cur or nil, selected = is_hex and true or false,
  })
  table.insert(items, { label = "theme default", detail = "remove colour", value = "__default", selected = cur == nil })
  picker.open(items, { title = (label or group) .. " colour" }, function(choice)
    if not choice then return end
    local spec = current(group)
    if choice == "__hex" then
      local default = spec.fg and spec.fg:match("^#") and spec.fg or "#"
      vim.ui.input({ prompt = (label or group) .. " colour (#RRGGBB): ", default = default }, function(input)
        input = input and vim.trim(input):lower()
        if not input or input == "" then return end
        if not input:match("^#%x%x%x%x%x%x$") then
          vim.notify("[ThemeForge] Use a hex color like #89b4fa", vim.log.levels.ERROR)
          return
        end
        spec.fg = input
        commit(group, spec, on_change)
      end)
    elseif choice == "__default" then
      spec.fg = nil
      commit(group, spec, on_change)
    else
      spec.fg = choice
      commit(group, spec, on_change)
    end
  end)
end

function M.toggle_style(group, style, on_change)
  local spec = current(group)
  if spec[style] then spec[style] = nil else spec[style] = true end
  commit(group, spec, on_change)
end

function M.reset(group, on_change)
  commit(group, nil, on_change)
end

--- Apply for real (outside the panel) and keep it for the next start.
local function apply_now()
  require("themeforge.apply").apply()
  local panel = package.loaded["themeforge.ui.panel"]
  if panel and panel.is_open then panel.render_all() end
end

--- Action menu for one group; reopens after each change until cancelled.
function M.edit(group, on_change, word)
  on_change = on_change or apply_now
  local spec = current(group)
  local function mark(on) return on and "on" or "off" end
  local items = {
    { label = "colour…", detail = spec.fg or "default", value = "color",
      color = (function()
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
        return ok and hl.fg and string.format("#%06x", hl.fg) or nil
      end)() },
    { label = "bold", detail = mark(spec.bold), value = "bold" },
    { label = "italic", detail = mark(spec.italic), value = "italic" },
    { label = "underline", detail = mark(spec.underline), value = "underline" },
    { label = "strikethrough", detail = mark(spec.strikethrough), value = "strikethrough" },
    { label = "reset to default", value = "reset" },
  }
  local title = word and (group .. "  ·  " .. word) or group
  picker.open(items, { title = title }, function(choice)
    if not choice then return end
    local again = function()
      on_change()
      vim.schedule(function() M.edit(group, on_change, word) end)
    end
    if choice == "color" then
      M.pick_color(group, group:gsub("^@lsp%.", ""), again)
    elseif choice == "reset" then
      M.reset(group, again)
    else
      M.toggle_style(group, choice, again)
    end
  end)
end

--- `:ThemeForge token`: customize the semantic token under the cursor.
function M.at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local items = lsp.at_pos(buf, pos[1] - 1, pos[2])
  if #items == 0 then
    vim.notify("[ThemeForge] No LSP semantic token under the cursor", vim.log.levels.WARN)
    return false
  end
  if not state.current.active_theme then
    vim.notify("[ThemeForge] No active theme", vim.log.levels.WARN)
    return false
  end
  local word = vim.fn.expand("<cword>")
  word = word ~= "" and ('"' .. word .. '"') or nil
  local choices = {}
  for _, it in ipairs(items) do
    local spec = (state.current.lsp_tokens or {})[it.group]
    table.insert(choices, { label = it.group, detail = spec and lsp.describe(spec) or "default", value = it.group })
  end
  if #choices == 1 then
    M.edit(choices[1].value, nil, word)
  else
    local title = "Tokens on " .. (word or "cursor") .. " (most specific first)"
    picker.open(choices, { title = title }, function(group)
      if group then M.edit(group, nil, word) end
    end)
  end
  return true
end

return M
