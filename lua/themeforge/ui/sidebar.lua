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
  search_mode = false
  search_query = ""

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
  M.focus_theme(state.current.active_theme)
end

local function theme_rows()
  local rows = {}
  for row, _ in pairs(M._line_map or {}) do table.insert(rows, row) end
  table.sort(rows)
  return rows
end

--- Put the cursor on a theme row (the catalog entry, not Recent/Favorites).
function M.focus_theme(id)
  local win = panel_ref and panel_ref.wins.sidebar
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  local rows = theme_rows()
  local target = rows[1]
  for _, row in ipairs(rows) do
    if M._line_map[row].id == id then target = row end
  end
  if target then pcall(vim.api.nvim_win_set_cursor, win, { target, 0 }) end
end

--- Move to the next/previous theme row, skipping headers and blank lines.
function M.step(dir, count)
  local win = panel_ref and panel_ref.wins.sidebar
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  local rows = theme_rows()
  if #rows == 0 then return end
  local cur = vim.api.nvim_win_get_cursor(win)[1]
  for _ = 1, math.max(1, count or 1) do
    local nxt
    if dir > 0 then
      for _, row in ipairs(rows) do if row > cur then nxt = row break end end
      nxt = nxt or rows[#rows]
    else
      for i = #rows, 1, -1 do if rows[i] < cur then nxt = rows[i] break end end
      nxt = nxt or rows[1]
    end
    cur = nxt
  end
  vim.api.nvim_win_set_cursor(win, { cur, 0 })
end

function M.render()
  local buf = panel_ref.bufs.sidebar
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  vim.bo[buf].modifiable = true

  local width = 30
  local win = panel_ref.wins.sidebar
  if win and vim.api.nvim_win_is_valid(win) then width = vim.api.nvim_win_get_width(win) end

  local lines, marks, swatches = {}, {}, {}
  local function add(text, hl)
    table.insert(lines, text)
    if hl then table.insert(marks, { #lines, 0, -1, hl }) end
    return #lines
  end

  -- ThemeForge currently ships a focused dark-only catalog.
  local dark_themes = {}
  for _, t in ipairs(filtered_list) do
    if t.variant == "dark" then table.insert(dark_themes, t) end
  end

  local title = search_query ~= "" and (" THEMES  / " .. search_query) or " THEMES"
  local r = add(title, "ThemeForgeTitle")
  local count = string.format("%d ", #dark_themes)
  table.insert(swatches, { r, { { count, "ThemeForgeMuted" } } })
  add(" " .. string.rep("─", math.max(4, width - 2)), "ThemeForgeRule")

  -- Track line -> theme mapping. Keeping the object here makes sections such
  -- as Favorites and Recent independent from the filtered catalog indexes.
  local line_map = {}
  local by_id = {}
  for _, t in ipairs(theme_list) do by_id[t.id] = t end
  local show_swatch = width >= 30

  local function add_section(name, list)
    if #list == 0 then return end
    add("")
    add("  " .. name:upper(), "ThemeForgeAccent")
    for _, t in ipairs(list) do
      local active = (state.current.active_theme == t.id)
      local favorite = state.is_favorite(t.id)
      local marker = active and " ● " or (favorite and " ★ " or "   ")
      local row = add(marker .. t.name)
      line_map[row] = t
      if active then
        table.insert(marks, { row, 0, -1, "ThemeForgeOk" })
      elseif favorite then
        table.insert(marks, { row, 0, 4, "ThemeForgeFav" })
      end
      if show_swatch then
        local theme = themes.get(t.id)
        local chunks = {}
        for _, key in ipairs({ "bg", "purple", "blue", "green", "orange", "red" }) do
          local hex = theme and theme.colors[key]
          if hex and hex:match("^#%x%x%x%x%x%x$") then
            local group = "ThemeForgeSwatch_" .. hex:sub(2)
            pcall(vim.api.nvim_set_hl, 0, group, { fg = hex })
            table.insert(chunks, { "●", group })
          end
        end
        table.insert(chunks, { " ", "ThemeForgePanelNormal" })
        table.insert(swatches, { row, chunks })
      end
    end
  end

  if search_query == "" then
    local favorites, recent = {}, {}
    for _, id in ipairs(state.current.favorite_themes or {}) do
      if by_id[id] then table.insert(favorites, by_id[id]) end
    end
    for _, id in ipairs(state.current.recent_themes or {}) do
      if by_id[id] then table.insert(recent, by_id[id]) end
    end
    add_section("★ Favorites", favorites)
    add_section("Recent", recent)
  end
  add_section(search_query ~= "" and "Results" or "All themes", dark_themes)
  if #dark_themes == 0 then add("   no match — press / to search again", "ThemeForgeMuted") end

  add("")
  add(" " .. string.rep("─", math.max(4, width - 2)), "ThemeForgeRule")
  if search_mode then
    add(" / " .. search_query .. "▏", "ThemeForgeAccent")
  else
    local hints = width >= 34
      and { { "⏎", "preview" }, { "f", "fav" }, { "/", "search" }, { "n", "random" }, { "P", "profile" }, { "b", "blend" }, { "p", "load" } }
      or { { "⏎", "preview" }, { "f", "fav" }, { "/", "search" }, { "P", "profile" } }
    local line, spans = " ", {}
    for _, h in ipairs(hints) do
      local piece = " " .. h[1] .. " "
      if vim.fn.strdisplaywidth(line .. piece .. h[2]) > width - 1 then
        add(line)
        for _, sp in ipairs(spans) do table.insert(marks, { #lines, sp[1], sp[2], "ThemeForgeKey" }) end
        line, spans = " ", {}
      end
      table.insert(spans, { #line, #line + #piece })
      line = line .. piece .. h[2] .. " "
    end
    add(line)
    for _, sp in ipairs(spans) do table.insert(marks, { #lines, sp[1], sp[2], "ThemeForgeKey" }) end
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

  local ns = vim.api.nvim_create_namespace("themeforge_sidebar")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    local len = #(lines[m[1]] or "")
    local e = (m[3] == -1 or m[3] > len) and len or m[3]
    if m[2] < e then
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, m[1] - 1, m[2], { end_col = e, hl_group = m[4], priority = 200 })
    end
  end
  for _, sw in ipairs(swatches) do
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, sw[1] - 1, 0, { virt_text = sw[2], virt_text_pos = "right_align" })
  end

  -- Store line_map for navigation
  M._line_map = line_map
  M._lines = lines
end

function M.get_theme_at_cursor()
  local win = panel_ref.wins.sidebar
  if not win or not vim.api.nvim_win_is_valid(win) then return nil end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  return M._line_map and M._line_map[row] or nil
end

function M.select_theme(theme_info)
  if not theme_info then return end
  state.checkpoint()
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
      local tags = table.concat(t.tags or {}, " ")
      if t.name:lower():find(q, 1, true) or t.id:lower():find(q, 1, true) or tags:find(q, 1, true) then
        table.insert(filtered_list, t)
      end
    end
  end
  cursor_pos = 1
  M.render()
  M.focus_theme(nil)
end

function M.setup_keymaps()
  local buf = panel_ref.bufs.sidebar
  if not buf then return end

  local function map(key, action)
    vim.keymap.set("n", key, action, { buffer = buf, nowait = true, silent = true })
  end

  map("j", function() M.step(1, vim.v.count1) end)
  map("k", function() M.step(-1, vim.v.count1) end)
  map("<Down>", function() M.step(1, vim.v.count1) end)
  map("<Up>", function() M.step(-1, vim.v.count1) end)
  map("gg", function() M.step(-1, 999) end)
  map("G", function() M.step(1, 999) end)

  map("<CR>", function()
    local theme = M.get_theme_at_cursor()
    if theme then
      M.select_theme(theme)
    end
  end)

  map("f", function()
    local theme = M.get_theme_at_cursor()
    if not theme then return end
    local favorite = state.toggle_favorite(theme.id)
    M.render()
    vim.notify(string.format("[ThemeForge] %s %s", favorite and "★ Added" or "Removed", theme.name), vim.log.levels.INFO)
  end)

  map("b", function()
    vim.ui.input({ prompt = "Save blend as: " }, function(name)
      if name and vim.trim(name) ~= "" then
        require("themeforge").save_blend(vim.trim(name))
      end
    end)
  end)

  map("p", function()
    local names = require("themeforge").list_blends({ silent = true })
    if #names == 0 then return end
    require("themeforge.ui.picker").open(names, { title = "Load blend" }, function(name)
      if name then require("themeforge").load_blend(name); M.render() end
    end)
  end)

  map("P", function()
    local details = {
      focus = "calm, low saturation",
      ["high-contrast"] = "brighter text, bold",
      ["low-distraction"] = "muted, no cursorline",
      monochrome = "greyscale accents",
    }
    local items = {}
    for _, name in ipairs(require("themeforge").list_profiles()) do
      table.insert(items, { label = name, detail = details[name], value = name })
    end
    require("themeforge.ui.picker").open(items, { title = "Apply profile" }, function(name)
      if name then require("themeforge").apply_profile(name); M.render() end
    end)
  end)

  map("y", function()
    require("themeforge").copy()
  end)

  map("d", function()
    require("themeforge").doctor()
  end)

  map("i", function()
    local theme = M.get_theme_at_cursor()
    if not theme then return end
    local tags = #(theme.tags or {}) > 0 and table.concat(theme.tags, ", ") or "none"
    local favorite = state.is_favorite(theme.id) and "yes" or "no"
    vim.notify(string.format(
      "ThemeForge — %s\nID: %s\nTags: %s\nFavorite: %s",
      theme.name, theme.id, tags, favorite
    ), vim.log.levels.INFO)
  end)

  map("n", function()
    require("themeforge").random_theme()
    M.render()
  end)

  map("c", function()
    local modes = { "auto", "all", "none" }
    local current = require("themeforge").compat_status()
    local idx = 1
    for i, mode in ipairs(modes) do if mode == current then idx = i end end
    require("themeforge").set_compat(modes[idx % #modes + 1])
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
