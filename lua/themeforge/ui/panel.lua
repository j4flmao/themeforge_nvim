local M = {}

local sidebar = require("themeforge.ui.sidebar")
local preview = require("themeforge.ui.preview")
local controls = require("themeforge.ui.controls")
local state = require("themeforge.state")

M.wins = {}
M.bufs = {}
M.is_open = false

local function calc_layout()
  local width_ratio = (state.config.panel and state.config.panel.width_ratio) or 0.82
  local height_ratio = (state.config.panel and state.config.panel.height_ratio) or 0.82
  local border = (state.config.panel and state.config.panel.border) or "rounded"

  local total_w = math.floor(vim.o.columns * width_ratio)
  local total_h = math.floor(vim.o.lines * height_ratio)

  -- Minimum total width to fit all 3 panels
  local min_w = 40 + 42 + 20 + 4 -- sidebar + controls + min_preview + gaps
  total_w = math.max(total_w, min_w)

  local row = math.floor((vim.o.lines - total_h) / 2)
  local col = math.floor((vim.o.columns - total_w) / 2)

  local sidebar_w = 40
  local controls_w = 42
  local preview_w = math.max(20, total_w - sidebar_w - controls_w - 4)

  local content_h = total_h - 4

  return {
    total_w = total_w,
    total_h = total_h,
    row = row,
    col = col,
    sidebar_w = sidebar_w,
    preview_w = preview_w,
    controls_w = controls_w,
    content_h = content_h,
    border = border,
  }
end

local function create_buf(name, listed)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  return buf
end

function M.open()
  if M.is_open then return end

  state.begin_preview()
  local layout = calc_layout()

  -- Create the main background float
  local main_buf = create_buf("themeforge_main")
  local main_win = vim.api.nvim_open_win(main_buf, true, {
    relative = "editor",
    style = "minimal",
    border = layout.border,
    width = layout.total_w,
    height = layout.total_h,
    row = layout.row,
    col = layout.col,
    zindex = 50,
    title = " ThemeForge.nvim ",
    title_pos = "center",
  })
  vim.api.nvim_win_set_option(main_win, "winblend", 0)
  vim.api.nvim_win_set_option(main_win, "winhighlight", "Normal:ThemeForgePanelNormal,NormalNC:ThemeForgePanelNormal,NormalFloat:ThemeForgePanelNormal,FloatBorder:ThemeForgePanelBorder")

  M.wins.main = main_win
  M.bufs.main = main_buf

  -- Sidebar window (left)
  local sidebar_buf = create_buf("themeforge_sidebar")
  local sidebar_win = vim.api.nvim_open_win(sidebar_buf, false, {
    relative = "win",
    win = main_win,
    style = "minimal",
    border = "none",
    width = layout.sidebar_w,
    height = layout.content_h,
    row = 1,
    col = 1,
    zindex = 51,
  })
  vim.api.nvim_win_set_option(sidebar_win, "winhighlight", "Normal:ThemeForgePanelNormal,NormalNC:ThemeForgePanelNormal,NormalFloat:ThemeForgePanelNormal")

  M.wins.sidebar = sidebar_win
  M.bufs.sidebar = sidebar_buf

  -- Preview window (center)
  local preview_buf = create_buf("themeforge_preview")
  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = "win",
    win = main_win,
    style = "minimal",
    border = "single",
    width = layout.preview_w,
    height = layout.content_h,
    row = 1,
    col = layout.sidebar_w + 2,
    zindex = 51,
  })
  vim.api.nvim_win_set_option(preview_win, "winhighlight", "Normal:ThemeForgePanelNormal,NormalNC:ThemeForgePanelNormal,NormalFloat:ThemeForgePanelNormal,FloatBorder:ThemeForgePanelBorder")

  M.wins.preview = preview_win
  M.bufs.preview = preview_buf

  -- Controls window (right)
  local controls_buf = create_buf("themeforge_controls")
  local controls_win = vim.api.nvim_open_win(controls_buf, false, {
    relative = "win",
    win = main_win,
    style = "minimal",
    border = "none",
    width = layout.controls_w,
    height = layout.content_h,
    row = 1,
    col = layout.sidebar_w + layout.preview_w + 4,
    zindex = 51,
  })
  vim.api.nvim_win_set_option(controls_win, "winhighlight", "Normal:ThemeForgePanelNormal,NormalNC:ThemeForgePanelNormal,NormalFloat:ThemeForgePanelNormal")

  M.wins.controls = controls_win
  M.bufs.controls = controls_buf

  M.is_open = true

  -- Enable mouse in all panel windows
  for _, win in pairs(M.wins) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_option(win, "cursorline", true)
    end
  end

  -- Initialize child panels
  sidebar.init(M)
  preview.init(M)
  controls.init(M)

  -- Set up keymaps on main window
  M.setup_keymaps()

  -- Focus sidebar
  vim.api.nvim_set_current_win(sidebar_win)

  -- Auto-refresh on VimResized
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if M.is_open then
        M.refresh()
      end
    end,
  })
end

function M.refresh()
  if not M.is_open then return end
  local layout = calc_layout()

  if M.wins.main and vim.api.nvim_win_is_valid(M.wins.main) then
    vim.api.nvim_win_set_width(M.wins.main, layout.total_w)
    vim.api.nvim_win_set_height(M.wins.main, layout.total_h)
  end
  if M.wins.sidebar and vim.api.nvim_win_is_valid(M.wins.sidebar) then
    vim.api.nvim_win_set_width(M.wins.sidebar, layout.sidebar_w)
  end
  if M.wins.preview and vim.api.nvim_win_is_valid(M.wins.preview) then
    vim.api.nvim_win_set_width(M.wins.preview, layout.preview_w)
  end
  if M.wins.controls and vim.api.nvim_win_is_valid(M.wins.controls) then
    vim.api.nvim_win_set_width(M.wins.controls, layout.controls_w)
  end

  sidebar.render()
  preview.render()
  controls.render()
end

function M.close()
  if not M.is_open then return end

  if state.cancel_preview() and state.current.active_theme then
    local apply = require("themeforge.apply")
    apply.apply()
  end

  for name, win in pairs(M.wins) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  M.wins = {}
  M.bufs = {}
  M.is_open = false
end

function M.setup_keymaps()
  local function map(buf, key, action)
    vim.keymap.set("n", key, action, { buffer = buf, nowait = true, silent = true })
  end

  -- Apply keymaps to all buffers
  for _, buf in pairs(M.bufs) do
    map(buf, "q", function() M.close() end)
    map(buf, "<Esc>", function() M.close() end)
    map(buf, "a", function()
      local apply = require("themeforge.apply")
      apply.apply()
      state.commit_preview()
      vim.notify("[ThemeForge] Theme applied!", vim.log.levels.INFO)
    end)
    map(buf, "s", function()
      local filepicker = require("themeforge.ui.filepicker")
      filepicker.open()
    end)
    map(buf, "<Tab>", function() M.focus_next() end)
    map(buf, "<S-Tab>", function() M.focus_prev() end)
    map(buf, "r", function()
      state.reset()
      if state.current.active_theme then
        local apply = require("themeforge.apply")
        apply.preview(state.current.active_theme)
      end
      controls.render()
      vim.notify("[ThemeForge] Overrides reset", vim.log.levels.INFO)
    end)
    map(buf, "?", function() M.show_help() end)
  end
end

local focus_order = { "sidebar", "preview", "controls" }
local focus_idx = 1

function M.focus_next()
  focus_idx = focus_idx % #focus_order + 1
  local name = focus_order[focus_idx]
  if M.wins[name] and vim.api.nvim_win_is_valid(M.wins[name]) then
    vim.api.nvim_set_current_win(M.wins[name])
  end
end

function M.focus_prev()
  focus_idx = (focus_idx - 2) % #focus_order + 1
  local name = focus_order[focus_idx]
  if M.wins[name] and vim.api.nvim_win_is_valid(M.wins[name]) then
    vim.api.nvim_set_current_win(M.wins[name])
  end
end

function M.show_help()
  local lines = {
    " ╔══════════════════════════════════════╗",
    " ║     ThemeForge Keybindings           ║",
    " ╠══════════════════════════════════════╣",
    " ║                                      ║",
    " ║  NAVIGATION                          ║",
    " ║  Tab / S-Tab    Next / prev panel    ║",
    " ║  j / k          Navigate list        ║",
    " ║  Mouse click    Select item          ║",
    " ║                                      ║",
    " ║  CONTROLS                            ║",
    " ║  Enter / Space  Toggle ON/OFF        ║",
    " ║  Enter / Space  Cycle options        ║",
    " ║  Enter / Click  Press buttons        ║",
    " ║  h / ←          Slider −5            ║",
    " ║  l / →          Slider +5            ║",
    " ║  H / S-←        Slider −10 (fast)    ║",
    " ║  L / S-→        Slider +10 (fast)    ║",
    " ║  Scroll wheel   Adjust slider        ║",
    " ║  0              Reset slider to 0    ║",
    " ║                                      ║",
    " ║  ACTIONS                             ║",
    " ║  a              Apply theme          ║",
    " ║  s              Save to config       ║",
    " ║  r              Reset overrides      ║",
    " ║  /              Search themes        ║",
    " ║  q / Esc        Close panel          ║",
    " ║                                      ║",
    " ╚══════════════════════════════════════╝",
    "",
    "     Press <Esc> to close this help",
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  local w = 44
  local h = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = w,
    height = h,
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    zindex = 60,
    title = " Help ",
    title_pos = "center",
  })
  -- Close on any key
  vim.keymap.set("n", "<Esc>", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf })
  -- Close on any other key press after a moment
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = function()
      pcall(vim.api.nvim_win_close, win, true)
    end,
  })
end

return M
