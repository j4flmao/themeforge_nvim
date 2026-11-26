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
  -- Start on the first slider rather than a section header.
  local win = panel.wins.controls
  if win and vim.api.nvim_win_is_valid(win) then
    local first
    for row, action in pairs(M._line_actions) do
      if action.type == "slider" and (not first or row < first) then first = row end
    end
    if first then pcall(vim.api.nvim_win_set_cursor, win, { first, 0 }) end
  end
end

local function make_slider_bar(value, width)
  width = width or 14
  local filled = math.floor(value / 100 * width + 0.5)
  local empty = width - filled
  return string.rep("━", filled) .. string.rep("─", empty), filled, empty
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
  require("themeforge.ui.preview").render()
end

function M.render()
  if not panel_ref or not panel_ref.bufs then return end
  local buf = panel_ref.bufs.controls
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  local win = panel_ref.wins.controls
  local width = (win and vim.api.nvim_win_is_valid(win)) and vim.api.nvim_win_get_width(win) or 42
  local rule_w = math.max(6, math.min(width - 2, 44))
  -- " %-10s ◄bar► %3d%%" needs 19 columns plus the bar.
  local bar_w = math.max(4, math.min(16, width - 20))

  vim.bo[buf].modifiable = true

  local lines = {}
  local marks = {} -- { row, col_start, col_end, hl } (byte columns, col_end -1 = eol)
  local virt = {} -- { row, chunks } right-aligned virtual text
  M._line_actions = {}

  local function add(text, hl)
    table.insert(lines, text)
    if hl then table.insert(marks, { #lines, 0, -1, hl }) end
    return #lines
  end
  local function header(text)
    add("")
    add(" " .. text, "ThemeForgeTitle")
    add(" " .. string.rep("─", rule_w), "ThemeForgeRule")
  end

  local theme = state.current.active_theme and themes_mod.get(state.current.active_theme)
  local colors = theme and require("themeforge.resolver").palette(theme, state.current.palette_mix, state.current.color_overrides)
  local color = require("themeforge.color")

  -- ── ACTIONS: always first, so Apply / Save are one keypress away ──
  local function button(label, key, action, hl)
    local text = string.format("  %-22s %s ", label, key)
    local row = add(" " .. text)
    table.insert(marks, { row, 1, 1 + #text, hl })
    M._line_actions[row] = { type = "button", action = action }
  end
  add(" ACTIONS", "ThemeForgeTitle")
  add(" " .. string.rep("─", rule_w), "ThemeForgeRule")
  button("✔ Apply theme", "a", "apply", "ThemeForgeBtnPrimary")
  button("⤓ Save to config", "s", "save", "ThemeForgeBtn")
  button("⇪ Export colorscheme", "e", "export", "ThemeForgeBtn")

  -- ── READABILITY (same thresholds as :ThemeForge doctor) ──
  if colors then
    header("READABILITY")
    local function row(label, fg, bg, role)
      if not (color.is_hex(fg) and color.is_hex(bg)) then return end
      local ratio = color.wcag_ratio(fg, bg)
      local grade, ok = color.grade(ratio, role)
      local text = string.format("  %-9s %5.1f:1  %s", label, ratio, grade)
      local r = add(text)
      table.insert(marks, { r, #text - #grade, -1, ok and "ThemeForgeOk" or "ThemeForgeWarn" })
    end
    row("Text", colors.fg, colors.bg, "text")
    row("Comment", colors.comment, colors.bg, "comment")
    row("Selected", colors.fg, colors.selection, "text")
  end

  -- ── BLEND SLIDERS ──
  header(width >= 30 and "BLEND SLIDERS   h/l  H/L  0" or "BLEND  h/l")
  for _, sl in ipairs(sliders) do
    local val = state.current.palette_mix and state.current.palette_mix[sl.key]
    if val == nil then
      val = (sl.key == "saturation" or sl.key == "brightness") and 50 or (sl.key == "opacity" and 100 or 0)
    end
    local bar, filled = make_slider_bar(val, bar_w)
    local r = add(string.format(" %-10s ◄%s► %3d%%", sl.label, bar, val))
    M._line_actions[r] = { type = "slider", key = sl.key }
    -- " " + 10-col label + " " = 12 bytes, then "◄" (3 bytes); bar glyphs are 3 bytes each.
    local start = 15
    local mid = start + filled * 3
    table.insert(marks, { r, start, mid, "ThemeForgeSliderFill" })
    table.insert(marks, { r, mid, start + bar_w * 3, "ThemeForgeSliderTrack" })
    table.insert(marks, { r, start + bar_w * 3 + 3, -1, val ~= ((sl.key == "saturation" or sl.key == "brightness") and 50 or (sl.key == "opacity" and 100 or 0)) and "ThemeForgeAccent" or "ThemeForgeMuted" })
  end

  -- ── UI OPTIONS ──
  header(width >= 30 and "UI OPTIONS   ⏎ toggle" or "UI  ⏎")
  for _, tg in ipairs(toggles) do
    local val = state.current.ui_options[tg.key]
    local r = add(string.format("  %s %-15s %s", val and "●" or "○", tg.label, val and "ON" or "off"))
    M._line_actions[r] = { type = "toggle", key = tg.key }
    table.insert(marks, { r, 2, 5, val and "ThemeForgeOk" or "ThemeForgeMuted" })
    table.insert(marks, { r, #lines[r] - (val and 2 or 3), -1, val and "ThemeForgeOk" or "ThemeForgeMuted" })
  end
  for _, cy in ipairs(cycle_opts) do
    local val = state.current.ui_options[cy.key] or cy.values[1]
    local text = string.format("  %-11s", cy.label)
    local spans = {}
    for _, v in ipairs(cy.values) do
      local s = #text + 1
      text = text .. " " .. v
      table.insert(spans, { s + 1, #text, v == val })
    end
    local r = add(text)
    M._line_actions[r] = { type = "cycle", key = cy.key, values = cy.values }
    for _, sp in ipairs(spans) do
      table.insert(marks, { r, sp[1] - 1, sp[2], sp[3] and "ThemeForgeOk" or "ThemeForgeMuted" })
    end
  end

  -- ── COLOR TOKENS (Enter to edit) ──
  header("COLOR TOKENS   ⏎ edit hex")
  if colors then
    for _, tk in ipairs(token_keys) do
      local hex = colors[tk.key] or "-"
      local edited = state.current.color_overrides and state.current.color_overrides[tk.key]
      local r = add(string.format(" ██ %-12s %s%s", tk.label, hex, edited and "  *" or ""))
      M._line_actions[r] = { type = "color", key = tk.key, label = tk.label }
      if color.is_hex(hex) then
        local group = "ThemeForgeSwatch_" .. hex:sub(2)
        pcall(vim.api.nvim_set_hl, 0, group, { fg = hex })
        table.insert(marks, { r, 1, 7, group })
      end
      if edited then table.insert(marks, { r, #lines[r] - 1, -1, "ThemeForgeWarn" }) end
    end
  else
    add(" (no theme selected)", "ThemeForgeMuted")
  end

  -- ── LSP SEMANTIC TOKENS ──
  local lsp = require("themeforge.lsp_tokens")
  local custom = state.current.lsp_tokens or {}
  local n_custom = 0
  for _ in pairs(custom) do n_custom = n_custom + 1 end
  header("LSP TOKENS")
  if n_custom > 0 then
    table.insert(virt, { #lines - 1, { { n_custom .. " customized ", "ThemeForgeAccent" } } })
  end
  local active = lsp.active()
  do
    local servers = #active.clients > 0 and table.concat(active.clients, " · ") or "no LSP running"
    local legend = #active.clients > 0 and "  ● in your code" or ""
    local room = math.max(8, width - 3 - vim.fn.strdisplaywidth(legend))
    if vim.fn.strdisplaywidth(servers) > room then
      servers = vim.fn.strcharpart(servers, 0, room - 1) .. "…"
    end
    local r = add("  " .. servers .. legend, "ThemeForgeMuted")
    if legend ~= "" then table.insert(marks, { r, 2 + #servers + 2, 2 + #servers + 2 + #"●", "ThemeForgeOk" }) end
    -- key hints, with the keys drawn as badges
    local hint = width >= 40 and { { "⏎", " colour  " }, { "B I U S", " style  " }, { "X", " reset" } }
      or { { "⏎", " " }, { "BIUS", " " }, { "X", "" } }
    local text, spans = "  ", {}
    for _, h in ipairs(hint) do
      table.insert(spans, { #text, #text + #h[1] })
      text = text .. h[1] .. h[2]
    end
    r = add(text, "ThemeForgeMuted")
    for _, sp in ipairs(spans) do table.insert(marks, { r, sp[1], sp[2], "ThemeForgeTitle" }) end
  end

  -- Column layout: " ██ ● label… sample… B I U S *"
  -- (no ✎: terminals draw it wider than one cell and it overlaps the badges)
  local show_sample = width >= 40
  local label_w = width >= 46 and 15 or (width >= 40 and 14 or 13)
  -- 6 (swatch + dot) + label + 1 + sample + 1 + 7 (B I U S) + 2 (" *") must fit the pane
  local sample_w = show_sample and math.max(6, math.min(12, width - label_w - 17)) or 0
  local function clip(text, w)
    if vim.fn.strdisplaywidth(text) <= w then return text .. string.rep(" ", w - vim.fn.strdisplaywidth(text)) end
    return vim.fn.strcharpart(text, 0, w - 1) .. "…"
  end
  local STYLE_KEYS = { { "bold", "B" }, { "italic", "I" }, { "underline", "U" }, { "strikethrough", "S" } }

  local function row_for(row)
    local spec = custom[row.group]
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = row.group, link = false })
    local fg = ok and hl.fg and string.format("#%06x", hl.fg) or nil
    local swatch = fg and "██" or "░░"
    local dot = row.used and "●" or " "
    local label = clip(row.label, label_w)
    local sample = show_sample and clip(active.samples[row.group] or "", sample_w) or ""
    local sample_len = #(sample:gsub("%s+$", ""))
    local flags = {}
    for _, s in ipairs(STYLE_KEYS) do table.insert(flags, s[2]) end
    local text = " " .. swatch .. " " .. dot .. " " .. label .. " " .. (show_sample and (sample .. " ") or "")
      .. table.concat(flags, " ") .. (spec and " *" or "")
    local r = add(text)
    M._line_actions[r] = { type = "lsp", group = row.group, label = row.label }

    -- byte offsets
    local c = 1
    local sw_end = c + #swatch
    if fg then
      local group = "ThemeForgeSwatch_" .. fg:sub(2)
      pcall(vim.api.nvim_set_hl, 0, group, { fg = fg })
      table.insert(marks, { r, c, sw_end, group })
    else
      table.insert(marks, { r, c, sw_end, "ThemeForgeMuted" })
    end
    c = sw_end + 1
    if row.used then table.insert(marks, { r, c, c + #dot, "ThemeForgeOk" }) end
    c = c + #dot + 1
    -- the token name: muted when the server does not use it, normal otherwise
    table.insert(marks, { r, c, c + #label, (spec and "ThemeForgeAccent") or (row.used and "ThemeForgeText" or "ThemeForgeMuted") })
    c = c + #label + 1
    if show_sample then
      -- the sample word is drawn with the token's own highlight: what you see is what you get
      table.insert(marks, { r, c, c + sample_len, row.group })
      c = c + #sample + 1
    end
    for i, s in ipairs(STYLE_KEYS) do
      local on = spec and spec[s[1]]
      table.insert(marks, { r, c, c + 1, on and "ThemeForgeFlagOn" or "ThemeForgeFlagOff" })
      c = c + 1 + (i < #STYLE_KEYS and 1 or 0)
    end
    if spec then table.insert(marks, { r, c, -1, "ThemeForgeWarn" }) end
  end

  local rows = lsp.panel_rows(active)
  local function group_rows(want_modifier)
    local used, unused = {}, {}
    for _, row in ipairs(rows) do
      if (row.modifier and true or false) == want_modifier then
        table.insert(row.used and used or unused, row)
      end
    end
    return vim.list_extend(used, unused)
  end
  add("  TYPES", "ThemeForgeAccent")
  for _, row in ipairs(group_rows(false)) do row_for(row) end
  add("  MODIFIERS  style only", "ThemeForgeAccent")
  for _, row in ipairs(group_rows(true)) do row_for(row) end

  -- ── INTEGRATIONS ──
  local mode = require("themeforge").compat_status()
  header("PLUGINS   c: mode " .. mode)
  local rows = require("themeforge.compat").status(state.config.compat or "auto")
  local per_line = width >= 40 and 2 or 1
  local cell_w = math.floor((width - 2) / per_line)
  for i = 1, #rows, per_line do
    local text, spans = "  ", {}
    for j = i, math.min(i + per_line - 1, #rows) do
      local r = rows[j]
      local cell = (r.enabled and "✓ " or "· ") .. r.label
      local s = #text
      text = text .. cell
      table.insert(spans, { s, s + 3, r.enabled })
      local pad = cell_w - vim.fn.strdisplaywidth(cell)
      if j < i + per_line - 1 and pad > 0 then text = text .. string.rep(" ", pad) end
    end
    local r = add(text)
    for _, sp in ipairs(spans) do
      table.insert(marks, { r, sp[1], sp[2], sp[3] and "ThemeForgeOk" or "ThemeForgeMuted" })
    end
  end

  -- Replacing every line resets the view of a non-current window; keep the
  -- scroll position and cursor where the user left them.
  local view = (win and vim.api.nvim_win_is_valid(win)) and vim.api.nvim_win_call(win, vim.fn.winsaveview) or nil
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  if view then
    view.lnum = math.min(view.lnum, #lines)
    pcall(vim.api.nvim_win_call, win, function() vim.fn.winrestview(view) end)
  end

  local ns = vim.api.nvim_create_namespace("themeforge_controls")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, v in ipairs(virt) do
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, v[1] - 1, 0, { virt_text = v[2], virt_text_pos = "right_align" })
  end
  for _, m in ipairs(marks) do
    local row, s, e, hl = m[1], m[2], m[3], m[4]
    local len = #(lines[row] or "")
    e = (e == -1 or e > len) and len or e
    if s < e then
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, row - 1, s, { end_col = e, hl_group = hl, priority = 200 })
    end
  end

  if win and vim.api.nvim_win_is_valid(win) then
    local cursor = vim.api.nvim_win_get_cursor(win)
    if cursor[1] > #lines then
      pcall(vim.api.nvim_win_set_cursor, win, { #lines, 0 })
    end
  end
end

local function slider_default(key)
  if key == "saturation" or key == "brightness" then return 50 end
  if key == "opacity" then return 100 end
  return 0
end

local adjust_slider

function M.handle_action_at_cursor()
  local win = panel_ref.wins.controls
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  local action = M._line_actions[row]
  if not action then return end

  if action.type == "toggle" then
    -- Instant toggle ON/OFF
    state.checkpoint()
    local cur = state.current.ui_options[action.key]
    state.set_ui_option(action.key, not cur)
    M.render()
    live_preview()

  elseif action.type == "cycle" then
    -- Cycle to next value
    state.checkpoint()
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

  elseif action.type == "color" then
    local theme = state.current.active_theme and themes_mod.get(state.current.active_theme)
    if not theme then return end
    local current = (state.current.color_overrides and state.current.color_overrides[action.key]) or theme.colors[action.key]
    vim.ui.input({
      prompt = string.format("%s color (#RRGGBB, or clear): ", action.label),
      default = current or "",
    }, function(input)
      if input == nil then return end
      input = vim.trim(input):lower()
      state.checkpoint()
      if input == "clear" or input == "" then
        state.set_color_override(action.key, nil)
      elseif palette_mod.is_valid_hex(input) then
        state.set_color_override(action.key, input)
      else
        vim.notify("[ThemeForge] Use a hex color like #89b4fa", vim.log.levels.ERROR)
        return
      end
      M.render()
      live_preview()
      require("themeforge.ui.preview").render()
    end)

  elseif action.type == "lsp" then
    M.pick_lsp_color(action)

  elseif action.type == "button" then
    if action.action == "apply" then
      panel_ref.apply()
    elseif action.action == "save" then
      local filepicker = require("themeforge.ui.filepicker")
      filepicker.open()
    elseif action.action == "export" then
      panel_ref.export_prompt()
    end
  end
end

-- ── LSP token editing ────────────────────────────────────────────────────────

local function lsp_action_at_cursor()
  local win = panel_ref and panel_ref.wins.controls
  if not win or not vim.api.nvim_win_is_valid(win) then return nil end
  local action = M._line_actions[vim.api.nvim_win_get_cursor(win)[1]]
  return action and action.type == "lsp" and action or nil
end

local function lsp_changed()
  live_preview() -- first, so the rows read the new effective colours
  M.render()
end

--- Choose the colour of an LSP token: a palette key, a custom hex, or the default.
function M.pick_lsp_color(action)
  require("themeforge.ui.token_editor").pick_color(action.group, action.label, lsp_changed)
end

--- Toggle bold / italic / underline / strikethrough on the LSP token under the cursor.
function M.toggle_lsp_style(style)
  local action = lsp_action_at_cursor()
  if not action then return false end
  require("themeforge.ui.token_editor").toggle_style(action.group, style, lsp_changed)
  return true
end

--- Reset the LSP token under the cursor to the theme / Neovim default.
function M.reset_lsp_token()
  local action = lsp_action_at_cursor()
  if not action then return false end
  require("themeforge.ui.token_editor").reset(action.group, lsp_changed)
  return true
end

-- Adjust slider: delta can be positive or negative
adjust_slider = function(delta)
  local win = panel_ref.wins.controls
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  local action = M._line_actions[row]
  if not action then return false end

  if action.type == "slider" then
    state.checkpoint()
    local cur = (state.current.palette_mix and state.current.palette_mix[action.key])
    local default = slider_default(action.key)
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

  -- ]] / [[ jump between sections (ACTIONS, READABILITY, ..., LSP TOKENS)
  local function jump(dir)
    local win = panel_ref.wins.controls
    if not win or not vim.api.nvim_win_is_valid(win) then return end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local headers = {}
    for i, l in ipairs(lines) do
      if l:match("^ %u[%u ]+") and not M._line_actions[i] then table.insert(headers, i) end
    end
    local target
    if dir > 0 then
      for _, h in ipairs(headers) do if h > row then target = h break end end
    else
      local current_header
      for i = #headers, 1, -1 do if headers[i] <= row then current_header = headers[i] break end end
      for i = #headers, 1, -1 do if headers[i] < (current_header or row) then target = headers[i] break end end
    end
    if target then
      local header = target
      -- land on the first actionable row of the section
      for r = target, math.min(#lines, target + 5) do
        if M._line_actions[r] then target = r break end
      end
      vim.api.nvim_win_set_cursor(win, { target, 0 })
      vim.api.nvim_win_call(win, function() vim.fn.winrestview({ topline = math.max(1, header - 1) }) end)
    end
  end
  map("n", "]]", function() jump(1) end)
  map("n", "[[", function() jump(-1) end)

  -- LSP token styles (only act on LSP TOKENS rows)
  map("n", "B", function() M.toggle_lsp_style("bold") end)
  map("n", "I", function() M.toggle_lsp_style("italic") end)
  map("n", "U", function() M.toggle_lsp_style("underline") end)
  map("n", "S", function() M.toggle_lsp_style("strikethrough") end)
  map("n", "X", function() M.reset_lsp_token() end)

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
      state.checkpoint()
      state.set_mix(action.key, slider_default(action.key))
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
