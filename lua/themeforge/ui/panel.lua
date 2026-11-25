local M = {}

local sidebar = require("themeforge.ui.sidebar")
local preview = require("themeforge.ui.preview")
local controls = require("themeforge.ui.controls")
local state = require("themeforge.state")

M.wins = {}
M.bufs = {}
M.is_open = false
M.layout = nil

local PANE_HL = "Normal:ThemeForgePanelNormal,NormalNC:ThemeForgePanelNormal,NormalFloat:ThemeForgePanelNormal,FloatBorder:ThemeForgePanelBorder,FloatTitle:ThemeForgeTitle,CursorLine:ThemeForgePanelCursorLine"

-- Status shown in the action bar: "current" | "preview" | "applied" | "saved".
M.status = { kind = "current" }
local bar_ns = vim.api.nvim_create_namespace("themeforge_bar")

local ACTIONS = {
  { "a", "Apply" }, { "s", "Save" }, { "e", "Export" }, { "d", "Doctor" },
  { "u", "Undo" }, { "Tab", "Pane" }, { "?", "Help" }, { "q", "Close" },
}

--- Draw the bottom status / action bar of the frame.
function M.render_bar()
  local buf, win = M.bufs.main, M.wins.main
  if not (buf and win and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win)) then return end
  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  local lines = {}
  for i = 1, height do lines[i] = "" end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, bar_ns, 0, -1)

  local theme = state.current.active_theme and require("themeforge.themes").get(state.current.active_theme)
  local name = theme and theme.name or "no theme"
  local kind = M.status.kind
  local badge, hl, hint
  if kind == "preview" then
    badge, hl, hint = " PREVIEW ", "ThemeForgeBadgePreview", name .. " · not applied yet"
  elseif kind == "applied" then
    badge, hl, hint = " APPLIED ", "ThemeForgeBadgeApplied", name .. " · s saves it to your config"
  elseif kind == "saved" then
    badge, hl, hint = " SAVED ", "ThemeForgeBadgeSaved", name .. " → " .. vim.fn.fnamemodify(M.status.path or "", ":~")
  else
    badge, hl, hint = " ACTIVE ", "ThemeForgeBadgeApplied", name
  end

  local right, right_w = {}, 0
  for _, item in ipairs(ACTIONS) do
    local key, label = " " .. item[1] .. " ", " " .. item[2] .. "  "
    local w = vim.fn.strdisplaywidth(key .. label)
    if right_w + w > math.max(0, width - vim.fn.strdisplaywidth(badge) - 24) then break end
    table.insert(right, { key, "ThemeForgeKey" })
    table.insert(right, { label, "ThemeForgeKeyLabel" })
    right_w = right_w + w
  end
  local room = width - right_w - vim.fn.strdisplaywidth(badge) - 3
  if vim.fn.strdisplaywidth(hint) > room then
    hint = vim.fn.strcharpart(hint, 0, math.max(0, room - 1)) .. "…"
  end
  pcall(vim.api.nvim_buf_set_extmark, buf, bar_ns, height - 1, 0, {
    virt_text = { { " ", "ThemeForgeBar" }, { badge, hl }, { " " .. hint, "ThemeForgeBar" } },
    virt_text_pos = "overlay",
    line_hl_group = "ThemeForgeBar",
  })
  pcall(vim.api.nvim_buf_set_extmark, buf, bar_ns, height - 1, 0, {
    virt_text = right,
    virt_text_pos = "right_align",
  })
end

function M.set_status(kind, path)
  M.status = { kind = kind, path = path }
  M.render_bar()
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

--- Compute a layout that always fits the editor.
---   wide   (inner width >= 104): themes | preview | controls
---   medium (inner width >= 64):  themes | controls          (preview hidden)
---   narrow:                      themes stacked above controls
function M.calc_layout(columns, lines)
  columns = columns or vim.o.columns
  lines = lines or vim.o.lines
  local cfg = state.config.panel or {}
  local width_ratio = cfg.width_ratio or 0.82
  local height_ratio = cfg.height_ratio or 0.82
  local border = cfg.border or "rounded"

  -- Space actually available for the float, keeping its border, the
  -- statusline and the command line visible.
  local max_w = math.max(20, columns - 4)
  local max_h = math.max(8, lines - vim.o.cmdheight - 4)
  local inner_w = clamp(math.floor(columns * width_ratio), math.min(max_w, 60), max_w)
  local inner_h = clamp(math.floor(lines * height_ratio), math.min(max_h, 16), max_h)

  local l = {
    mode = "wide",
    border = border,
    inner_w = inner_w,
    inner_h = inner_h,
    row = math.max(0, math.floor((lines - vim.o.cmdheight - inner_h - 2) / 2)),
    col = math.max(0, math.floor((columns - inner_w - 2) / 2)),
    panes = {},
  }

  -- The last row of the frame is the status / action bar.
  local ch = inner_h - 1
  l.content_h = ch

  if inner_w >= 104 then
    local sw = clamp(math.floor(inner_w * 0.24), 28, 36)
    local cw = clamp(math.floor(inner_w * 0.30), 38, 46)
    local pw = inner_w - sw - cw - 3 -- preview border (2) + gap (1)
    l.panes.sidebar = { row = 0, col = 0, width = sw, height = ch }
    l.panes.preview = { row = 0, col = sw, width = pw, height = ch - 2, border = "single" }
    l.panes.controls = { row = 0, col = sw + pw + 3, width = cw, height = ch }
  elseif inner_w >= 64 then
    l.mode = "medium"
    local sw = clamp(math.floor(inner_w * 0.42), 26, 36)
    l.panes.sidebar = { row = 0, col = 0, width = sw, height = ch }
    l.panes.controls = { row = 0, col = sw + 1, width = inner_w - sw - 1, height = ch }
  else
    l.mode = "narrow"
    local sh = clamp(math.floor(ch * 0.42), 4, ch - 5)
    l.panes.sidebar = { row = 0, col = 0, width = inner_w, height = sh }
    l.panes.controls = { row = sh + 1, col = 0, width = inner_w, height = ch - sh - 1 }
  end
  return l
end

local function create_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  return buf
end

local function pane_config(main_win, pane)
  return {
    relative = "win",
    win = main_win,
    style = "minimal",
    border = pane.border or "none",
    width = math.max(1, pane.width),
    height = math.max(1, pane.height),
    row = pane.row,
    col = pane.col,
    zindex = 51,
  }
end

M.focus_order = {}

local function open_windows(focus)
  local layout = M.calc_layout()
  M.layout = layout

  local main_buf = create_buf()
  local main_win = vim.api.nvim_open_win(main_buf, true, {
    relative = "editor",
    style = "minimal",
    border = layout.border,
    width = layout.inner_w,
    height = layout.inner_h,
    row = layout.row,
    col = layout.col,
    zindex = 50,
    title = " ThemeForge.nvim ",
    title_pos = "center",
  })
  vim.wo[main_win].winhighlight = PANE_HL
  vim.wo[main_win].cursorline = false
  M.wins.main, M.bufs.main = main_win, main_buf

  M.focus_order = {}
  for _, name in ipairs({ "sidebar", "preview", "controls" }) do
    local pane = layout.panes[name]
    if pane then
      local buf = create_buf()
      local win = vim.api.nvim_open_win(buf, false, pane_config(main_win, pane))
      vim.wo[win].winhighlight = PANE_HL
      vim.wo[win].cursorline = name ~= "preview"
      vim.wo[win].wrap = false
      M.wins[name], M.bufs[name] = win, buf
      table.insert(M.focus_order, name)
    end
  end

  M.is_open = true
  M.render_bar()
  sidebar.init(M)
  if M.wins.preview then preview.init(M) end
  controls.init(M)
  M.setup_keymaps()

  local target = (focus and M.wins[focus]) and focus or "sidebar"
  vim.api.nvim_set_current_win(M.wins[target])
end

local function close_windows()
  for _, win in pairs(M.wins) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  M.wins, M.bufs = {}, {}
  M.is_open = false
end

local function current_pane()
  local cur = vim.api.nvim_get_current_win()
  for name, win in pairs(M.wins) do
    if win == cur then return name end
  end
end

function M.open()
  if M.is_open then return end
  state.begin_preview()
  M.status = { kind = "current" }
  open_windows()

  local group = vim.api.nvim_create_augroup("ThemeForgePanel", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "ThemeForgeSaved",
    callback = function(ev)
      if M.is_open then M.set_status("saved", ev.data and ev.data.path) end
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      if M.is_open then vim.schedule(M.refresh) end
    end,
  })
end

--- Rebuild the panel for the current editor size, keeping state and focus.
function M.refresh()
  if not M.is_open then return end
  local focus = current_pane()
  local cursors = {}
  for name, win in pairs(M.wins) do
    if vim.api.nvim_win_is_valid(win) then cursors[name] = vim.api.nvim_win_get_cursor(win) end
  end
  close_windows()
  open_windows(focus)
  for name, pos in pairs(cursors) do
    local win, buf = M.wins[name], M.bufs[name]
    if win and buf and name ~= "sidebar" then
      pcall(vim.api.nvim_win_set_cursor, win, { math.min(pos[1], vim.api.nvim_buf_line_count(buf)), 0 })
    end
  end
end

function M.close()
  if not M.is_open then return end

  M.closing = true
  if state.cancel_preview() and state.current.active_theme then
    require("themeforge.apply").apply()
  end
  M.closing = false

  close_windows()
  pcall(vim.api.nvim_del_augroup_by_name, "ThemeForgePanel")
end

function M.render_all()
  sidebar.render()
  if M.wins.preview then preview.render() end
  controls.render()
end

function M.setup_keymaps()
  local function map(buf, key, action)
    vim.keymap.set("n", key, action, { buffer = buf, nowait = true, silent = true })
  end

  for _, buf in pairs(M.bufs) do
    map(buf, "q", function() M.close() end)
    map(buf, "<Esc>", function() M.close() end)
    map(buf, "a", function() M.apply() end)
    map(buf, "e", function() M.export_prompt() end)
    map(buf, "d", function() require("themeforge").doctor() end)
    map(buf, "s", function()
      require("themeforge.ui.filepicker").open()
    end)
    map(buf, "<Tab>", function() M.focus_next() end)
    map(buf, "<S-Tab>", function() M.focus_prev() end)
    map(buf, "r", function()
      state.checkpoint()
      state.reset()
      if state.current.active_theme then
        require("themeforge.apply").preview(state.current.active_theme)
      end
      M.render_all()
      vim.notify("[ThemeForge] Overrides reset", vim.log.levels.INFO)
    end)
    map(buf, "?", function() M.show_help() end)
    map(buf, "u", function() M.history_action("undo") end)
    map(buf, "<C-r>", function() M.history_action("redo") end)
  end
end

--- Apply the previewed theme for real (persisted to the session cache).
function M.apply()
  require("themeforge.apply").apply()
  state.commit_preview()
  -- A new preview session starts so Esc after Apply keeps the applied theme.
  state.begin_preview()
  state.record_recent(state.current.active_theme)
  M.set_status("applied")
  M.render_all()
  vim.notify("[ThemeForge] ✓ Theme applied — press s to save it to your config", vim.log.levels.INFO)
end

function M.export_prompt()
  vim.ui.input({ prompt = "Export colorscheme as: ", default = "themeforge-" .. (state.current.active_theme or "custom") }, function(name)
    if name and name ~= "" then require("themeforge").export(name) end
  end)
end

function M.history_action(action)
  local changed = action == "undo" and state.undo() or state.redo()
  if not changed then
    vim.notify("[ThemeForge] Nothing to " .. action, vim.log.levels.INFO)
    return
  end
  if state.current.active_theme then
    require("themeforge.apply").preview(state.current.active_theme, state.current.overrides, state.current.ui_options, state.current.palette_mix)
  end
  M.render_all()
  vim.notify("[ThemeForge] " .. (action == "undo" and "Undid" or "Redid") .. " last change", vim.log.levels.INFO)
end

local function focus_step(step)
  local order = M.focus_order
  if #order == 0 then return end
  local idx = 1
  local cur = current_pane()
  for i, name in ipairs(order) do
    if name == cur then idx = i end
  end
  idx = (idx - 1 + step) % #order + 1
  local win = M.wins[order[idx]]
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end

function M.focus_next() focus_step(1) end
function M.focus_prev() focus_step(-1) end

--- Focus a pane by name ("sidebar", "preview", "controls").
function M.focus(name)
  local win = M.wins[name]
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    return true
  end
  return false
end

local HELP = {
  { "NAVIGATION" },
  { "Tab / S-Tab", "Next / previous pane" },
  { "j / k", "Move (skips headers)" },
  { "Enter", "Preview theme / activate" },
  { "" },
  { "CONTROLS" },
  { "Enter / Space", "Toggle, cycle, press" },
  { "Enter on color", "Edit #RRGGBB" },
  { "h / l", "Slider -5 / +5" },
  { "H / L", "Slider -10 / +10" },
  { "0", "Reset slider" },
  { "" },
  { "ACTIONS" },
  { "a", "Apply theme (live, session)" },
  { "u / Ctrl-r", "Undo / redo" },
  { "b / p", "Save / load blend" },
  { "P", "Apply profile" },
  { "y", "Copy configuration" },
  { "e", "Export colorscheme" },
  { "d", "Run doctor" },
  { "n", "Surprise theme" },
  { "f", "Toggle favorite" },
  { "c", "Cycle plugin mode" },
  { "s", "Save to config file" },
  { "r", "Reset overrides" },
  { "/", "Search themes" },
  { "q / Esc", "Close panel" },
}

function M.show_help()
  local lines = {}
  for _, row in ipairs(HELP) do
    if row[2] then
      table.insert(lines, string.format("  %-16s %s", row[1], row[2]))
    else
      table.insert(lines, row[1] ~= "" and (" " .. row[1]) or "")
    end
  end
  table.insert(lines, "")
  table.insert(lines, " Press q or Esc to close")
  local w = math.min(44, vim.o.columns - 4)
  local h = math.min(#lines, vim.o.lines - 4)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = w,
    height = h,
    row = math.max(0, math.floor((vim.o.lines - h) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - w) / 2)),
    zindex = 60,
    title = " Help ",
    title_pos = "center",
  })
  vim.wo[win].winhighlight = PANE_HL
  for _, key in ipairs({ "q", "<Esc>", "?" }) do
    vim.keymap.set("n", key, function() pcall(vim.api.nvim_win_close, win, true) end, { buffer = buf, nowait = true })
  end
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = function() pcall(vim.api.nvim_win_close, win, true) end,
  })
end

return M
