local M = {}

local state = require("themeforge.state")
local themes_mod = require("themeforge.themes")
local palette_mod = require("themeforge.palette")

local panel_ref = nil

-- Color token keys displayed in the editor
local token_keys = {
  { key = "purple",    label = "keyword" },
  { key = "blue",      label = "function" },
  { key = "green",     label = "string" },
  { key = "orange",    label = "number" },
  { key = "comment",   label = "comment" },
  { key = "cyan",      label = "type" },
  { key = "fg",        label = "variable" },
  { key = "fg2",       label = "operator" },
  { key = "bg",        label = "background" },
  { key = "fg",        label = "foreground" },
  { key = "selection", label = "selection" },
  { key = "bg3",       label = "cursor line" },
  { key = "comment",   label = "line number" },
  { key = "bg2",       label = "statusline" },
  { key = "bg3",       label = "border" },
}

-- Slider definitions
local sliders = {
  { key = "purple",     label = "Purple" },
  { key = "blue",      label = "Blue" },
  { key = "green",     label = "Green" },
  { key = "cyan",      label = "Cyan" },
  { key = "pink",      label = "Pink" },
  { key = "orange",    label = "Orange" },
  { key = "warm",      label = "Warm" },
  { key = "saturation", label = "Saturation" },
  { key = "brightness", label = "Brightness" },
  { key = "opacity",   label = "Opacity" },
}

-- UI toggle definitions
local toggles = {
  { key = "transparency",    label = "TRANSPARENCY" },
  { key = "italic_keywords", label = "Italic kw" },
  { key = "bold_functions",  label = "Bold fn" },
  { key = "cursorline",      label = "Cursorline" },
  { key = "underline_diag",  label = "Underline diag" },
  { key = "bold_cursor",     label = "Bold cursor" },
}

-- Cycle options
local cycle_opts = {
  { key = "statusline", label = "Statusline", values = { "minimal", "full", "arrow" } },
  { key = "signcolumn", label = "Signcolumn", values = { "yes", "number", "no" } },
}

-- Color tokens are display-only (no editing)

-- Line mapping for interactive elements
M._line_actions = {}

function M.init(panel)
  panel_ref = panel
  M.render()
  M.setup_keymaps()
end

local function make_slider_bar(value, width)
  width = width or 14
  local filled = math.floor(value / 100 * width + 0.5)
  local empty = width - filled
  return string.rep("█", filled) .. string.rep("░", empty)
end

-- Live preview helper: apply changes instantly
local function live_preview()
  if state.current.active_theme then
    local apply = require("themeforge.apply")
    apply.preview(
      state.current.active_theme,
      state.current.overrides,
      state.current.ui_options,
      state.current.palette_mix
    )
  end
end

function M.render()
  local buf = panel_ref.bufs.controls
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  local lines = {}
  M._line_actions = {}

  -- Get current theme colors
  local theme = nil
  if state.current.active_theme then
    theme = themes_mod.get(state.current.active_theme)
  end

  -- ── COLOR TOKENS ──────────────────────
  table.insert(lines, " COLOR TOKENS")
  table.insert(lines, " ───────────────────────────")

  if theme then
    for _, tk in ipairs(token_keys) do
      local color = theme.colors[tk.key] or "#000000"
      color = palette_mod.apply_mix(color, state.current.palette_mix or {}, theme.colors.bg)
      local display = string.format(" ■ %-14s %s", tk.label, color)
      table.insert(lines, display)
      -- Display only, no action
    end
  else
    table.insert(lines, " (no theme selected)")
  end

  -- A compact, actionable readability signal makes the palette editor useful
  -- beyond visual preference alone.
  if theme then
    local bg = palette_mod.apply_mix(theme.colors.bg, state.current.palette_mix or {}, theme.colors.bg)
    local fg = palette_mod.apply_mix(theme.colors.fg, state.current.palette_mix or {}, theme.colors.bg)
    local comment = palette_mod.apply_mix(theme.colors.comment, state.current.palette_mix or {}, theme.colors.bg)
    local fg_ratio = palette_mod.contrast_ratio(fg, bg)
    local comment_ratio = palette_mod.contrast_ratio(comment, bg)
    local function grade(ratio)
      if ratio >= 7 then return "AAA" end
      if ratio >= 4.5 then return "AA" end
      if ratio >= 3 then return "large text" end
      return "low"
    end
    table.insert(lines, "")
    table.insert(lines, " READABILITY")
    table.insert(lines, string.format("  Text     %4.1fx  %s", fg_ratio, grade(fg_ratio)))
    table.insert(lines, string.format("  Comment  %4.1fx  %s", comment_ratio, grade(comment_ratio)))
  end

  table.insert(lines, "")

  -- ── BLEND SLIDERS ─────────────────────
  table.insert(lines, " BLEND SLIDERS  ◄ h/l ►")
  table.insert(lines, " ───────────────────────────")

  for _, sl in ipairs(sliders) do
    local val = (state.current.palette_mix and state.current.palette_mix[sl.key])
    if val == nil then
      if sl.key == "saturation" or sl.key == "brightness" then
        val = 50
      else
        val = 0
      end
    end
    local bar = make_slider_bar(val, 12)
    local display = string.format(" %-10s ◄%s► %3d%%", sl.label, bar, val)
    table.insert(lines, display)
    M._line_actions[#lines] = { type = "slider", key = sl.key }
  end

  table.insert(lines, "")

  -- ── UI OPTIONS ────────────────────────
  table.insert(lines, " UI OPTIONS  ⏎/Space toggle")
  table.insert(lines, " ───────────────────────────")

  for _, tg in ipairs(toggles) do
    local val = state.current.ui_options[tg.key]
    local icon = val and "✓" or "✗"
    local label_text = val and " ON " or " OFF"
    local display = string.format("  %s %-15s [%s]", icon, tg.label, label_text)
    table.insert(lines, display)
    M._line_actions[#lines] = { type = "toggle", key = tg.key }
  end

  table.insert(lines, "")

  for _, cy in ipairs(cycle_opts) do
    local val = state.current.ui_options[cy.key] or cy.values[1]
    -- Build indicator showing all values with current highlighted
    local parts = {}
    for _, v in ipairs(cy.values) do
      if v == val then
        table.insert(parts, "●" .. v)
      else
        table.insert(parts, "○" .. v)
      end
    end
    local display = string.format("  %-14s %s", cy.label, table.concat(parts, " "))
    table.insert(lines, display)
    M._line_actions[#lines] = { type = "cycle", key = cy.key, values = cy.values }
  end

  table.insert(lines, "")
  table.insert(lines, " ═══════════════════════════")
  table.insert(lines, "")

  -- ── ACTION BUTTONS ────────────────────
  table.insert(lines, "  ┌─────────────────────┐")
  table.insert(lines, "  │   ⏎  Apply Theme    │")
  M._line_actions[#lines] = { type = "button", action = "apply" }
  table.insert(lines, "  └─────────────────────┘")

  table.insert(lines, "  ┌─────────────────────┐")
  table.insert(lines, "  │   ⏎  Save to Config │")
  M._line_actions[#lines] = { type = "button", action = "save" }
  table.insert(lines, "  └─────────────────────┘")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Restore cursor position within bounds
  local win = panel_ref.wins.controls
  if win and vim.api.nvim_win_is_valid(win) then
    local cursor = vim.api.nvim_win_get_cursor(win)
    if cursor[1] > #lines then
      pcall(vim.api.nvim_win_set_cursor, win, { #lines, 0 })
    end
  end
end

function M.handle_action_at_cursor()
  local win = panel_ref.wins.controls
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  local action = M._line_actions[row]
  if not action then return end

  if action.type == "toggle" then
    -- Instant toggle ON/OFF
    local cur = state.current.ui_options[action.key]
    state.set_ui_option(action.key, not cur)
    M.render()
    live_preview()

  elseif action.type == "cycle" then
    -- Cycle to next value
    local cur = state.current.ui_options[action.key]
    local idx = 1
    for i, v in ipairs(action.values) do
      if v == cur then idx = i; break end
    end
    idx = idx % #action.values + 1
    state.set_ui_option(action.key, action.values[idx])
    M.render()
    live_preview()

  elseif action.type == "slider" then
    -- Enter/Space on slider → increase by 5 (use h/l to adjust)
    adjust_slider(5)
    return

  elseif action.type == "button" then
    if action.action == "apply" then
      local apply = require("themeforge.apply")
      apply.apply()
      state.commit_preview()
      vim.notify("[ThemeForge] ✓ Theme applied!", vim.log.levels.INFO)
    elseif action.action == "save" then
      local filepicker = require("themeforge.ui.filepicker")
      filepicker.open()
    end
  end
end

-- Adjust slider: delta can be positive or negative
local function adjust_slider(delta)
  local win = panel_ref.wins.controls
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  local action = M._line_actions[row]
  if not action then return false end

  if action.type == "slider" then
    local cur = (state.current.palette_mix and state.current.palette_mix[action.key])
    local default = (action.key == "saturation" or action.key == "brightness") and 50 or 0
    local new_val = math.max(0, math.min(100, (cur or default) + delta))
    state.set_mix(action.key, new_val)
    M.render()
    -- Keep cursor on same row
    pcall(vim.api.nvim_win_set_cursor, win, { row, 0 })
    live_preview()
    return true
  end
  return false
end

function M.setup_keymaps()
  local buf = panel_ref.bufs.controls
  if not buf then return end

  local function map(mode, key, action)
    vim.keymap.set(mode, key, action, { buffer = buf, nowait = true, silent = true })
  end

  -- Enter / Space → toggle, cycle, confirm button, edit color/slider
  map("n", "<CR>", function() M.handle_action_at_cursor() end)
  map("n", "<Space>", function() M.handle_action_at_cursor() end)

  -- h / Left → decrease slider by 5
  map("n", "h", function()
    if not adjust_slider(-5) then
      -- Not on a slider, do nothing special
    end
  end)
  map("n", "<Left>", function() adjust_slider(-5) end)

  -- l / Right → increase slider by 5
  map("n", "l", function()
    if not adjust_slider(5) then
      -- Not on a slider, do nothing special
    end
  end)
  map("n", "<Right>", function() adjust_slider(5) end)

  -- H / Shift+Left → decrease slider by 10 (fast adjust)
  map("n", "H", function() adjust_slider(-10) end)
  map("n", "<S-Left>", function() adjust_slider(-10) end)

  -- L / Shift+Right → increase slider by 10 (fast adjust)
  map("n", "L", function() adjust_slider(10) end)
  map("n", "<S-Right>", function() adjust_slider(10) end)

  -- 0 → reset slider to 0 (or 50 for saturation/brightness)
  map("n", "0", function()
    local win = panel_ref.wins.controls
    if not win then return end
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local action = M._line_actions[row]
    if action and action.type == "slider" then
      local default = (action.key == "saturation" or action.key == "brightness") and 50 or 0
      state.set_mix(action.key, default)
      M.render()
      pcall(vim.api.nvim_win_set_cursor, win, { row, 0 })
      live_preview()
    end
  end)

  -- Scroll wheel on sliders
  map("n", "<ScrollWheelUp>", function() adjust_slider(5) end)
  map("n", "<ScrollWheelDown>", function() adjust_slider(-5) end)
end

return M
