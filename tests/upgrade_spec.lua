-- ThemeForge.nvim tests for the colour core, responsive panel, doctor and export.
-- Run with:
-- nvim --headless -u NONE --cmd 'set rtp^=.' -c 'runtime plugin/themeforge.lua' -c 'luafile tests/upgrade_spec.lua' -c 'qa!'

local color = require("themeforge.color")
local palette = require("themeforge.palette")
local themes = require("themeforge.themes")
local resolver = require("themeforge.resolver")
local state = require("themeforge.state")
local tf = require("themeforge")

local failures = {}
local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then table.insert(failures, name .. ": " .. tostring(err)) end
end
local function near(a, b, eps, msg)
  assert(math.abs(a - b) <= (eps or 1e-3), string.format("%s: expected %s, got %s", msg or "value", b, a))
end

vim.notify = function() end
state.config = { autosave_cache = false, compat = "auto" }

-- ── colour core ────────────────────────────────────────────────────────────
test("oklab reference values", function()
  local L, a, b = color.hex_to_oklab("#ffffff")
  near(L, 1, 1e-3, "white L"); near(a, 0, 1e-3); near(b, 0, 1e-3)
  L = color.hex_to_oklab("#000000")
  near(L, 0, 1e-6, "black L")
  local Lr, Cr, hr = color.hex_to_oklch("#ff0000")
  near(Lr, 0.628, 2e-3, "red L"); near(Cr, 0.2577, 2e-3, "red C"); near(hr, 29.23, 0.2, "red h")
end)

test("oklch round trip", function()
  for _, hex in ipairs({ "#7aa2f7", "#9ece6a", "#24283b", "#f7768e", "#e0af68", "#123456" }) do
    local L, C, h = color.hex_to_oklch(hex)
    assert(color.oklch_to_hex(L, C, h) == hex, "round trip " .. hex)
  end
end)

test("gamut mapping stays in sRGB and keeps hue", function()
  local out = color.oklch_to_hex(0.7, 0.4, 145)
  assert(color.is_hex(out))
  local _, _, h = color.hex_to_oklch(out)
  near(h, 145, 4, "hue preserved")
end)

test("wcag and apca reference values", function()
  near(color.wcag_ratio("#000000", "#ffffff"), 21, 1e-6, "wcag black/white")
  near(color.apca_lc("#000000", "#ffffff"), 106.04, 0.5, "apca black on white")
  near(color.apca_lc("#ffffff", "#000000"), -107.88, 0.5, "apca white on black")
end)

test("role grading shared by panel and doctor", function()
  assert(select(2, color.grade(3.8, "comment")) == true)
  assert(select(2, color.grade(3.8, "text")) == false)
  assert(color.grade(7.5, "text") == "AAA")
end)

test("cvd simulation flags red/green for deuteranopes", function()
  local normal = color.delta_eok("#e06c75", "#98c379")
  local d = color.delta_eok(color.simulate_cvd("#e06c75", "deutan"), color.simulate_cvd("#98c379", "deutan"))
  assert(d < normal, "deutan should reduce red/green distance")
  local worst, kind = color.min_cvd_distance("#ff0000", "#00ff00")
  assert(worst < normal and kind ~= "normal")
end)

-- ── blend sliders ──────────────────────────────────────────────────────────
test("brightness protects the background", function()
  local theme = themes.get("tokyonight-storm")
  local base = resolver.palette(theme, {}, {})
  local bright = resolver.palette(theme, { brightness = 80 }, {})
  local bg_shift = color.delta_eok(base.bg, bright.bg)
  local fg_ratio_before = color.wcag_ratio(base.fg, base.bg)
  local fg_ratio_after = color.wcag_ratio(bright.fg, bright.bg)
  assert(bg_shift < 0.03, "background moved too much: " .. bg_shift)
  assert(fg_ratio_after >= fg_ratio_before - 0.05, "text contrast dropped")
end)

test("sliders never push text below its original contrast", function()
  for _, id in ipairs(themes.ids()) do
    local theme = themes.get(id)
    local base = resolver.palette(theme, {}, {})
    for _, mix in ipairs({ { brightness = 0 }, { brightness = 100 }, { saturation = 0 }, { opacity = 30 }, { purple = 100, warm = 100 } }) do
      local c = resolver.palette(theme, mix, {})
      local floor = math.min(color.wcag_ratio(base.fg, base.bg), 4.5)
      assert(color.wcag_ratio(c.fg, c.bg) >= floor - 0.01, id .. " fg contrast with " .. vim.inspect(mix))
    end
  end
end)

test("tints actually move hue", function()
  local before = select(3, color.hex_to_oklch("#7aa2f7"))
  local after = select(3, color.hex_to_oklch(palette.apply_mix("#7aa2f7", { purple = 100 }, "#24283b", "accent")))
  assert(math.abs(after - before) > 10, "purple tint did not rotate hue")
end)

test("neutral mix is a no-op", function()
  assert(palette.apply_mix("#7aa2f7", { saturation = 50, brightness = 50, opacity = 100 }, "#24283b") == "#7aa2f7")
end)

-- ── responsive panel ───────────────────────────────────────────────────────
local panel = require("themeforge.ui.panel")
local sizes = { { 220, 60 }, { 160, 45 }, { 120, 36 }, { 100, 30 }, { 80, 24 }, { 60, 20 } }

test("layout fits every editor size", function()
  for _, size in ipairs(sizes) do
    local cols, lines = size[1], size[2]
    local l = panel.calc_layout(cols, lines)
    assert(l.col + l.inner_w + 2 <= cols, ("main too wide at %dx%d"):format(cols, lines))
    assert(l.row + l.inner_h + 2 <= lines - vim.o.cmdheight, ("main too tall at %dx%d"):format(cols, lines))
    for name, p in pairs(l.panes) do
      local extra = p.border and 2 or 0
      assert(p.col + p.width + extra <= l.inner_w, ("%s overflows at %dx%d"):format(name, cols, lines))
      assert(p.row + p.height + extra <= l.inner_h, ("%s too tall at %dx%d"):format(name, cols, lines))
      assert(p.width >= 20, ("%s too narrow at %dx%d"):format(name, cols, lines))
    end
  end
  assert(panel.calc_layout(160, 45).mode == "wide")
  assert(panel.calc_layout(100, 30).mode == "medium")
  assert(panel.calc_layout(60, 20).mode == "narrow")
end)

test("panel opens, resizes and keeps windows inside the frame", function()
  tf.apply("tokyonight-storm")
  for _, size in ipairs(sizes) do
    vim.o.columns, vim.o.lines = size[1], size[2]
    if panel.is_open then panel.refresh() else tf.open() end
    local main = vim.api.nvim_win_get_position(panel.wins.main)
    local mw = vim.api.nvim_win_get_width(panel.wins.main)
    for name, win in pairs(panel.wins) do
      if name ~= "main" then
        local pos = vim.api.nvim_win_get_position(win)
        local cfg = vim.api.nvim_win_get_config(win)
        local extra = (cfg.border and cfg.border ~= "none" and type(cfg.border) == "table" and #cfg.border > 0) and 2 or 0
        assert(pos[2] + vim.api.nvim_win_get_width(win) + extra <= main[2] + mw + 2,
          ("%s pane overflows at %dx%d"):format(name, size[1], size[2]))
      end
    end
    -- the sidebar cursor sits on the active theme, not a header
    local row = vim.api.nvim_win_get_cursor(panel.wins.sidebar)[1]
    local item = require("themeforge.ui.sidebar")._line_map[row]
    assert(item and item.id == "tokyonight-storm", "sidebar cursor not on active theme")
  end
  panel.close()
  vim.o.columns, vim.o.lines = 160, 45
end)

test("sidebar j/k skip headers", function()
  tf.open()
  local sidebar = require("themeforge.ui.sidebar")
  for _ = 1, 20 do
    sidebar.step(1)
    assert(sidebar._line_map[vim.api.nvim_win_get_cursor(panel.wins.sidebar)[1]], "landed on a header")
  end
  panel.close()
end)

test("panel keys: sliders, reset, toggle, apply button, status bar", function()
  local function feed(keys)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
  end
  tf.apply("tokyonight-storm")
  tf.open()
  local controls = require("themeforge.ui.controls")
  panel.focus("controls")
  local function goto_ctl(kind, key)
    for row, a in pairs(controls._line_actions) do
      if a.type == kind and (a.key == key or a.action == key) then
        vim.api.nvim_win_set_cursor(panel.wins.controls, { row, 0 })
        return
      end
    end
    error("no control " .. kind .. ":" .. key)
  end
  goto_ctl("slider", "purple"); feed("ll")
  assert(state.current.palette_mix.purple == 10, "l did not move slider")
  feed("<CR>")
  assert(state.current.palette_mix.purple == 15, "Enter on slider failed")
  assert(panel.status.kind == "preview", "status should be preview")
  goto_ctl("slider", "opacity"); feed("h0")
  assert(state.current.palette_mix.opacity == 100, "0 must reset opacity to 100")
  goto_ctl("toggle", "italic_keywords"); feed("<CR>")
  assert(state.current.ui_options.italic_keywords == true)
  goto_ctl("button", "apply"); feed("<CR>")
  assert(panel.status.kind == "applied", "apply button did not apply")
  feed("q")
  assert(not panel.is_open)
  assert(state.current.palette_mix.purple == 15, "applied changes must survive closing")
end)

test("profile applied inside the panel survives closing", function()
  tf.apply("nord")
  tf.open()
  tf.apply_profile("monochrome")
  panel.close()
  assert(state.current.palette_mix.saturation == 0, "profile was reverted on close")
  tf.reset()
end)

test("save writes config and marks the bar as saved", function()
  local path = vim.fn.tempname() .. ".lua"
  tf.open()
  require("themeforge.writer").write(path)
  assert(vim.fn.filereadable(path) == 1)
  assert(panel.status.kind == "saved" and panel.status.path == path)
  panel.close()
end)

-- ── doctor / export / event ────────────────────────────────────────────────
test("doctor report has contrast, cvd and highlight sections", function()
  tf.apply("gruvbox-dark")
  local report = require("themeforge.doctor").report()
  assert(#report.sections >= 4)
  assert(report.sections[1].rows[1]:find("APCA"), "missing APCA column")
end)

test("export writes a loadable standalone colorscheme", function()
  local dir = vim.fn.tempname()
  tf.apply("nord")
  local path = tf.export("tf-test", dir)
  assert(path and vim.fn.filereadable(path) == 1)
  vim.cmd("highlight clear")
  dofile(path)
  assert(vim.g.colors_name == "tf-test")
  assert(vim.api.nvim_get_hl(0, { name = "Normal" }).bg ~= nil)
end)

test("User ThemeForgeApplied fires with theme data", function()
  local got
  vim.api.nvim_create_autocmd("User", { pattern = "ThemeForgeApplied", once = true, callback = function(ev) got = ev.data end })
  tf.apply("dracula")
  assert(got and got.theme == "dracula" and got.colors.bg)
  assert(vim.g.terminal_color_1 ~= nil)
end)

test("modern highlight groups are defined", function()
  tf.apply("onedark")
  for _, g in ipairs({ "FloatTitle", "PmenuMatch", "ComplMatchIns", "SnippetTabstop", "LspReferenceTarget", "OkMsg", "@lsp.type.modifier" }) do
    assert(not vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = g })), g .. " missing")
  end
end)

if #failures > 0 then
  print("FAILED:\n  " .. table.concat(failures, "\n  "))
  vim.cmd("cquit 1")
else
  print("ThemeForge upgrade tests passed")
end
