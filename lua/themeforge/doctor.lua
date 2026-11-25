local M = {}

local state = require("themeforge.state")
local themes = require("themeforge.themes")
local resolver = require("themeforge.resolver")
local color = require("themeforge.color")

-- Distinguishability threshold in deltaEOK under simulated colour-vision
-- deficiency. Heuristic: below ~0.08 two small glyph colours blur together.
local CVD_MIN = 0.08

--- Contrast checks: { label, fg key, bg key, role }.
local CONTRAST_CHECKS = {
  { "Text", "fg", "bg", "text" },
  { "Comment", "comment", "bg", "comment" },
  { "Secondary text", "fg2", "bg", "comment" },
  { "Text on selection", "fg", "selection", "text" },
  { "Text on float", "fg", "bg2", "text" },
  { "Keyword", "purple", "bg", "text" },
  { "Function", "blue", "bg", "text" },
  { "String", "green", "bg", "text" },
  { "Error", "red", "bg", "text" },
  { "Warning", "yellow", "bg", "text" },
}

--- Colour pairs that must stay distinguishable, also for colour-blind users.
local CVD_PAIRS = {
  { "Diff add / delete", "green", "red" },
  { "Error / warning", "red", "yellow" },
  { "Error / info", "red", "blue" },
  { "Warning / hint", "yellow", "cyan" },
  { "String / keyword", "green", "purple" },
}

--- A group resolves if it, or a dotted parent ("@function.method" ->
--- "@function"), is defined: Neovim falls back the same way.
local function resolves(name)
  while name and name ~= "" do
    if not vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = name })) then return true end
    name = name:match("^(.+)%.[^.]+$")
  end
  return false
end

--- Highlight links that point to groups which do not exist.
local function broken_links()
  local broken = {}
  local ok, all = pcall(vim.api.nvim_get_hl, 0, {})
  if not ok then return broken end
  for name, def in pairs(all) do
    if def.link and not resolves(def.link) then
      table.insert(broken, name .. " -> " .. def.link)
    end
  end
  table.sort(broken)
  return broken
end

--- Build the doctor report. Returns { title, sections = { { name, rows } }, issues }.
function M.report()
  local theme = state.current.active_theme and themes.get(state.current.active_theme)
  if not theme then return nil end

  local colors = resolver.palette(theme, state.current.palette_mix, state.current.color_overrides)
  local issues = 0
  local report = { title = "ThemeForge Doctor — " .. (theme.name or theme.id), sections = {} }

  local contrast = {}
  for _, chk in ipairs(CONTRAST_CHECKS) do
    local label, fk, bk, role = chk[1], chk[2], chk[3], chk[4]
    local fg, bg = colors[fk], colors[bk]
    if color.is_hex(fg) and color.is_hex(bg) then
      local ratio = color.wcag_ratio(fg, bg)
      local grade, ok = color.grade(ratio, role)
      if not ok then issues = issues + 1 end
      table.insert(contrast, string.format("%-18s %5.1f:1  %-4s  APCA Lc %3.0f", label, ratio, grade, math.abs(color.apca_lc(fg, bg))))
    end
  end
  table.insert(report.sections, { name = "Contrast (WCAG 2 pass/fail, APCA advisory)", rows = contrast })

  local cvd = {}
  for _, pair in ipairs(CVD_PAIRS) do
    local a, b = colors[pair[2]], colors[pair[3]]
    if color.is_hex(a) and color.is_hex(b) then
      local d, kind = color.min_cvd_distance(a, b)
      local ok = d >= CVD_MIN
      if not ok then issues = issues + 1 end
      table.insert(cvd, string.format("%-18s ΔE %.3f  %s%s", pair[1], d, ok and "OK" or "CLOSE", ok and "" or (" (" .. kind .. ")")))
    end
  end
  table.insert(report.sections, { name = "Colour-blind safety (protan / deutan / tritan)", rows = cvd })

  local notes = {}
  if state.current.ui_options and state.current.ui_options.transparency then
    table.insert(notes, "Transparency is on: contrast depends on your terminal background.")
  end
  local links = broken_links()
  for i = 1, math.min(#links, 8) do
    table.insert(notes, "Broken link: " .. links[i])
  end
  if #links > 8 then table.insert(notes, string.format("... and %d more broken links", #links - 8)) end
  issues = issues + #links
  if #notes == 0 then notes = { "No broken highlight links." } end
  table.insert(report.sections, { name = "Highlights", rows = notes })

  local integrations = {}
  for _, row in ipairs(require("themeforge.compat").status(state.config.compat or "auto")) do
    if row.enabled then table.insert(integrations, "✓ " .. row.label) end
  end
  table.insert(report.sections, {
    name = "Integrations",
    rows = { #integrations > 0 and table.concat(integrations, "  ") or "none detected (compat mode: " .. tostring(state.config.compat or "auto") .. ")" },
  })

  report.issues = issues
  return report
end

local function to_lines(report)
  local lines = { report.title, string.rep("─", vim.fn.strdisplaywidth(report.title)) }
  for _, section in ipairs(report.sections) do
    table.insert(lines, "")
    table.insert(lines, section.name)
    for _, row in ipairs(section.rows) do table.insert(lines, "  " .. row) end
  end
  table.insert(lines, "")
  table.insert(lines, report.issues == 0 and "No issues found." or string.format("%d issue(s) found.", report.issues))
  return lines
end

local function show_float(lines)
  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  width = math.min(width + 2, math.max(20, vim.o.columns - 4))
  local height = math.min(#lines, math.max(5, vim.o.lines - 4))
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", style = "minimal", border = "rounded",
    width = width, height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    title = " Doctor ", title_pos = "center", zindex = 70,
  })
  vim.wo[win].wrap = false
  for _, key in ipairs({ "q", "<Esc>", "<CR>" }) do
    vim.keymap.set("n", key, function() pcall(vim.api.nvim_win_close, win, true) end, { buffer = buf, nowait = true })
  end
  local ns = vim.api.nvim_create_namespace("themeforge_doctor")
  for i, line in ipairs(lines) do
    local s = line:find("LOW") or line:find("CLOSE") or line:find("Broken link")
    if s then vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticWarn", i - 1, 0, -1)
    elseif line:find("  OK") or line:find(" AAA") or line:find(" AA ") or line:find("^No issues") then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticOk", i - 1, 0, -1)
    elseif i == 1 or (line ~= "" and not line:find("^  ")) then
      vim.api.nvim_buf_add_highlight(buf, ns, "Title", i - 1, 0, -1)
    end
  end
  return win
end

function M.run(opts)
  opts = opts or {}
  local report = M.report()
  if not report then
    vim.notify("[ThemeForge Doctor] No active theme", vim.log.levels.WARN)
    return false
  end
  local lines = to_lines(report)
  if opts.float ~= false and #vim.api.nvim_list_uis() > 0 then
    show_float(lines)
  else
    vim.notify(table.concat(lines, "\n"), report.issues == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
  end
  return report
end

return M
