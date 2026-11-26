-- ThemeForge.nvim tests for LSP semantic token customization.
-- Run with:
-- nvim --headless -u NONE --cmd 'set rtp^=.' -c 'runtime plugin/themeforge.lua' -c 'luafile tests/lsp_tokens_spec.lua' -c 'qa!'

-- Never touch the real user config / data.
local SANDBOX = vim.fn.tempname()
for _, var in ipairs({ "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME" }) do
  vim.env[var] = SANDBOX .. "/" .. var:lower()
end

local tf = require("themeforge")
local state = require("themeforge.state")
local lsp = require("themeforge.lsp_tokens")
local themes = require("themeforge.themes")
local resolver = require("themeforge.resolver")

vim.notify = function() end
vim.o.columns, vim.o.lines = 170, 46
tf.setup({ restore_on_start = false, autosave_cache = false, cache_path = SANDBOX .. "/last.json" })

local failures = {}
local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then table.insert(failures, name .. ": " .. tostring(err)) end
end
local function hex(n) return n and string.format("#%06x", n) or nil end
local function get(group) return vim.api.nvim_get_hl(0, { name = group, link = false }) end

test("normalize group names", function()
  assert(lsp.normalize_group("@lsp.type.parameter") == "@lsp.type.parameter")
  assert(lsp.normalize_group("lsp.type.parameter") == "@lsp.type.parameter")
  assert(lsp.normalize_group("type.parameter") == "@lsp.type.parameter")
  assert(lsp.normalize_group("mod.deprecated") == "@lsp.mod.deprecated")
  assert(lsp.normalize_group("Normal") == nil)
end)

test("apply({ lsp_tokens }) with palette key, hex and styles", function()
  tf.apply({
    theme = "tokyonight-storm",
    lsp_tokens = {
      ["@lsp.type.parameter"] = { fg = "orange", italic = true },
      ["type.property"] = { fg = "#ff00aa", bold = true },
      ["@lsp.mod.deprecated"] = { strikethrough = true },
    },
  })
  local colors = resolver.palette(themes.get("tokyonight-storm"), state.current.palette_mix, state.current.color_overrides)
  local p = get("@lsp.type.parameter")
  assert(hex(p.fg) == colors.orange, "parameter should use the palette orange")
  assert(p.italic == true, "parameter should be italic")
  local prop = get("@lsp.type.property")
  assert(hex(prop.fg) == "#ff00aa" and prop.bold == true, "property hex + bold")
  local dep = get("@lsp.mod.deprecated")
  assert(dep.strikethrough == true and dep.fg == nil, "deprecated: style only, keeps token colour")
end)

test("palette keys follow the theme and blend sliders", function()
  tf.apply("gruvbox-dark")
  local colors = resolver.palette(themes.get("gruvbox-dark"), state.current.palette_mix, state.current.color_overrides)
  assert(hex(get("@lsp.type.parameter").fg) == colors.orange, "parameter colour must follow the new theme")
end)

test("style-only type token keeps its real colour", function()
  state.set_lsp_token("@lsp.type.class", nil)
  require("themeforge.apply").apply()
  local before = hex(get("@lsp.type.class").fg)
  assert(before, "class has no colour before customizing")
  state.set_lsp_token("@lsp.type.class", { italic = true })
  require("themeforge.apply").apply()
  local c = get("@lsp.type.class")
  assert(hex(c.fg) == before, ("colour changed: %s -> %s"):format(before, hex(c.fg)))
  assert(c.italic == true)
  -- and it follows the theme on switch
  tf.apply("rose-pine")
  state.set_lsp_token("@lsp.type.class", nil)
  require("themeforge.apply").apply()
  local rose = hex(get("@lsp.type.class").fg)
  state.set_lsp_token("@lsp.type.class", { italic = true })
  require("themeforge.apply").apply()
  assert(hex(get("@lsp.type.class").fg) == rose, "style-only token did not follow the new theme")
end)

test("style-only token without a default link inherits nothing it shouldn't", function()
  state.set_lsp_token("@lsp.type.lifetime", { italic = true })
  require("themeforge.apply").apply()
  local l = get("@lsp.type.lifetime")
  assert(l.italic == true)
  state.set_lsp_token("@lsp.type.lifetime", nil)
end)

test("panel rows add tokens used by running servers, skip syntax noise", function()
  local rows = lsp.panel_rows({
    clients = { "rust_analyzer" },
    legend = {},
    used = {
      ["@lsp.type.parameter"] = true, ["@lsp.type.lifetime"] = true, ["@lsp.type.selfKeyword"] = true,
      ["@lsp.mod.mutable"] = true, ["@lsp.type.punctuation"] = true, ["@lsp.type.comment"] = true,
      ["@lsp.typemod.variable.mutable"] = true,
    },
  })
  local by = {}
  for _, r in ipairs(rows) do by[r.group] = r end
  assert(by["@lsp.type.parameter"].used and not by["@lsp.type.parameter"].extra, "curated row not marked used")
  assert(by["@lsp.type.lifetime"] and by["@lsp.type.lifetime"].extra, "lifetime extra missing")
  assert(by["@lsp.mod.mutable"] and by["@lsp.mod.mutable"].modifier, "mutable modifier missing")
  assert(not by["@lsp.type.punctuation"] and not by["@lsp.type.comment"], "noise tokens should be hidden")
  assert(not by["@lsp.typemod.variable.mutable"], "typemod groups are not panel rows")
  assert(not by["@lsp.type.class"].used, "unused curated row marked used")
end)

test("token editor: toggle / reset apply for real", function()
  local ed = require("themeforge.ui.token_editor")
  local changed = 0
  ed.toggle_style("@lsp.type.lifetime", "italic", function() changed = changed + 1 require("themeforge.apply").apply() end)
  assert(state.current.lsp_tokens["@lsp.type.lifetime"].italic and get("@lsp.type.lifetime").italic, "italic not applied")
  ed.reset("@lsp.type.lifetime", function() changed = changed + 1 require("themeforge.apply").apply() end)
  assert(state.current.lsp_tokens["@lsp.type.lifetime"] == nil and changed == 2)
end)

test(":ThemeForge token without a token under the cursor warns", function()
  vim.cmd("enew")
  assert(require("themeforge.ui.token_editor").at_cursor() == false)
  assert(vim.fn.exists(":ThemeForge") == 2)
  assert(vim.tbl_contains(vim.fn.getcompletion("ThemeForge to", "cmdline"), "token"))
end)

test("interface / struct styles carry over to gopls equivalents", function()
  state.current.lsp_tokens = {}
  tf.apply({ lsp_tokens = { ["@lsp.type.interface"] = { fg = "yellow", underline = true } } })
  local go_iface = get("@lsp.typemod.type.interface")
  assert(go_iface.underline == true and go_iface.fg == get("@lsp.type.interface").fg, "alias not applied")
  -- an explicit customization of the alias wins
  tf.apply({ lsp_tokens = { ["@lsp.typemod.type.interface"] = { italic = true } } })
  assert(get("@lsp.typemod.type.interface").underline ~= true, "explicit alias spec should win")
  state.current.lsp_tokens = {}
end)

test("UX: ]] reaches LSP TOKENS, picker preselects the current colour, help fits", function()
  state.current.lsp_tokens = {}
  tf.apply({ theme = "dracula", lsp_tokens = { ["@lsp.type.parameter"] = { fg = "orange" } } })
  tf.open()
  local panel = require("themeforge.ui.panel")
  local controls = require("themeforge.ui.controls")
  panel.focus("controls")
  vim.api.nvim_win_set_cursor(panel.wins.controls, { 1, 0 })
  local function feed(k) vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k, true, false, true), "xt", false) end
  local reached = false
  for _ = 1, 12 do
    feed("]]")
    local a = controls._line_actions[vim.api.nvim_win_get_cursor(panel.wins.controls)[1]]
    if a and a.type == "lsp" then reached = true break end
  end
  assert(reached, "]] never reached the LSP TOKENS section")
  feed("[[")
  local a = controls._line_actions[vim.api.nvim_win_get_cursor(panel.wins.controls)[1]]
  assert(not (a and a.type == "lsp"), "[[ did not leave the LSP section")

  -- colour picker opens on the current colour (orange)
  require("themeforge.ui.token_editor").pick_color("@lsp.type.parameter", "parameter", function() end)
  local pwin = vim.api.nvim_get_current_win()
  local line = vim.api.nvim_get_current_line()
  assert(line:find("orange", 1, true), "picker did not preselect orange: " .. line)
  feed("q")

  -- help is never cut off
  vim.o.columns = 120
  panel.show_help()
  local hwin = vim.api.nvim_get_current_win()
  local hbuf = vim.api.nvim_win_get_buf(hwin)
  local widest = 0
  for _, l in ipairs(vim.api.nvim_buf_get_lines(hbuf, 0, -1, false)) do widest = math.max(widest, vim.fn.strdisplaywidth(l)) end
  assert(vim.api.nvim_win_get_width(hwin) >= widest, "help is narrower than its content")
  pcall(vim.api.nvim_win_close, hwin, true)
  vim.o.columns = 170
  panel.close()
  state.current.lsp_tokens = {}
end)

test("source files contain no stray control characters", function()
  local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
  for _, f in ipairs(vim.fn.globpath(root, "lua/**/*.lua", false, true)) do
    local fh = assert(io.open(f, "rb"))
    local data = fh:read("*a")
    fh:close()
    local pos = data:find("[%z\1-\8\11\12\14-\31]") or data:find("\194[\128-\159]")
    assert(not pos, f .. ": control character at byte " .. tostring(pos))
  end
end)

-- Fake what Neovim's LSP client draws, so this runs without a language server.
local function fake_semantic_buffer()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "scale value", "Math.max(scale)" })
  local ns = vim.api.nvim_create_namespace("nvim.lsp.semantic_tokens:999")
  local function mark(row, col, end_col, group, prio)
    vim.api.nvim_buf_set_extmark(buf, ns, row, col, { end_col = end_col, hl_group = group, priority = prio })
  end
  mark(0, 0, 5, "@lsp.type.parameter.lua", 125)                 -- plain parameter
  mark(1, 9, 14, "@lsp.type.parameter.lua", 125)                -- parameter ...
  mark(1, 9, 14, "@lsp.typemod.parameter.special.lua", 127)     -- ... overridden here
  mark(1, 5, 8, "@lsp.type.method.lua", 125)
  return buf
end

test("verify(): counts positions drawn with the customized colour", function()
  state.current.lsp_tokens = {}
  vim.api.nvim_set_hl(0, "@lsp.typemod.parameter.special", { fg = "#ff0000" })
  tf.apply({ theme = "dracula", lsp_tokens = { ["@lsp.type.parameter"] = { fg = "orange" } } })
  local buf = fake_semantic_buffer()
  local r = lsp.verify(state.current.lsp_tokens)["@lsp.type.parameter"]
  assert(r and r.total == 2, "expected 2 parameter positions, got " .. vim.inspect(r))
  assert(r.ok == 1, "one position should show orange")
  assert(r.by["@lsp.typemod.parameter.special"] == 1, "override not attributed: " .. vim.inspect(r.by))
  assert(r.sample == "scale")

  local report = require("themeforge.doctor").report()
  local found = false
  for _, sec in ipairs(report.sections) do
    if sec.name:find("LSP tokens in your open buffers", 1, true) then
      for _, row in ipairs(sec.rows) do
        if row:find("type.parameter", 1, true) and row:find("OVERRIDDEN", 1, true) then found = true end
      end
    end
  end
  assert(found, "doctor did not report the override")

  -- samples come from the code
  local a = lsp.active()
  assert(a.samples["@lsp.type.parameter"] == "scale", "sample word: " .. tostring(a.samples["@lsp.type.parameter"]))
  assert(a.samples["@lsp.type.method"] == "max")
  vim.api.nvim_buf_delete(buf, { force = true })
  vim.api.nvim_set_hl(0, "@lsp.typemod.parameter.special", {})
  state.current.lsp_tokens = {}
end)

test("panel LSP section: types/modifiers groups, used first, sample + style badges", function()
  state.current.lsp_tokens = {}
  tf.apply({ theme = "dracula", lsp_tokens = { ["@lsp.type.parameter"] = { fg = "orange", italic = true } } })
  local buf = fake_semantic_buffer()
  tf.open()
  local panel = require("themeforge.ui.panel")
  local controls = require("themeforge.ui.controls")
  local lines = vim.api.nvim_buf_get_lines(panel.bufs.controls, 0, -1, false)
  local types_at, mods_at, param_row, first_lsp
  for i, l in ipairs(lines) do
    if l == "  TYPES" then types_at = i end
    if l:find("^  MODIFIERS") then mods_at = i end
    local a = controls._line_actions[i]
    if a and a.type == "lsp" then
      first_lsp = first_lsp or i
      if a.group == "@lsp.type.parameter" then param_row = i end
    end
  end
  assert(types_at and mods_at and types_at < mods_at, "TYPES / MODIFIERS headings missing")
  assert(param_row and param_row < mods_at, "parameter should be listed under TYPES")
  -- used tokens come first: parameter and method are the used ones
  local first = controls._line_actions[first_lsp].group
  assert(first == "@lsp.type.parameter" or first == "@lsp.type.method", "used tokens not first: " .. first)
  local line = lines[param_row]
  assert(line:find("scale", 1, true), "sample word missing: " .. line)
  assert(line:find("B I U S", 1, true) and line:find(" *", 1, true), "style badges / edit mark missing: " .. line)
  -- the customized-count badge
  local ns = vim.api.nvim_create_namespace("themeforge_controls")
  local found = false
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(panel.bufs.controls, ns, 0, -1, { details = true })) do
    local vt = m[4].virt_text
    if vt and vt[1][1]:find("1 customized", 1, true) then found = true end
  end
  assert(found, "customized count badge missing")
  panel.close()
  vim.api.nvim_buf_delete(buf, { force = true })
  state.current.lsp_tokens = {}
end)

test("LSP rows never overflow the controls pane", function()
  state.current.lsp_tokens = {}
  local panel = require("themeforge.ui.panel")
  local controls = require("themeforge.ui.controls")
  for _, size in ipairs({ { 220, 60 }, { 170, 46 }, { 130, 40 }, { 100, 34 }, { 80, 40 } }) do
    vim.o.columns, vim.o.lines = size[1], size[2]
    tf.apply({ theme = "dracula", lsp_tokens = { ["@lsp.type.parameter"] = { fg = "orange", italic = true } } })
    tf.open()
    local w = vim.api.nvim_win_get_width(panel.wins.controls)
    for i, l in ipairs(vim.api.nvim_buf_get_lines(panel.bufs.controls, 0, -1, false)) do
      local a = controls._line_actions[i]
      if a and a.type == "lsp" then
        assert(vim.fn.strdisplaywidth(l) <= w, ("row overflows at %dx%d: %d > %d"):format(size[1], size[2], vim.fn.strdisplaywidth(l), w))
      end
    end
    panel.close()
  end
  vim.o.columns, vim.o.lines = 170, 46
  state.current.lsp_tokens = {}
end)

test("strip_lang / kind", function()
  assert(lsp.strip_lang("@lsp.type.parameter.rust") == "@lsp.type.parameter")
  assert(lsp.strip_lang("@lsp.typemod.variable.mutable.rust") == "@lsp.typemod.variable.mutable")
  assert(lsp.strip_lang("@lsp.mod.readonly") == "@lsp.mod.readonly")
  assert(lsp.kind("@lsp.typemod.function.defaultLibrary") == "typemod")
end)

test("reset restores Neovim's default link", function()
  vim.api.nvim_set_hl(0, "@lsp.type.macro", { link = "@constant.macro" })
  state.set_lsp_token("@lsp.type.macro", { fg = "red" })
  require("themeforge.apply").apply()
  assert(get("@lsp.type.macro").fg ~= nil)
  state.set_lsp_token("@lsp.type.macro", nil)
  require("themeforge.apply").apply()
  local raw = vim.api.nvim_get_hl(0, { name = "@lsp.type.macro" })
  assert(raw.link == "@constant.macro", "default link was lost: " .. vim.inspect(raw))
end)

test("undo / redo cover LSP tokens", function()
  state.history = { undo = {}, redo = {} }
  state.checkpoint()
  state.set_lsp_token("@lsp.type.method", { fg = "red" })
  assert(state.undo() and state.current.lsp_tokens["@lsp.type.method"] == nil, "undo")
  assert(state.redo() and state.current.lsp_tokens["@lsp.type.method"].fg == "red", "redo")
end)

test("panel keys: B / I / U / S / X on an LSP row", function()
  tf.apply("nord")
  state.current.lsp_tokens = {}
  tf.open()
  local panel = require("themeforge.ui.panel")
  local controls = require("themeforge.ui.controls")
  panel.focus("controls")
  local row
  for r, a in pairs(controls._line_actions) do
    if a.type == "lsp" and a.group == "@lsp.type.function" then row = r end
  end
  assert(row, "no LSP TOKENS row for function")
  vim.api.nvim_win_set_cursor(panel.wins.controls, { row, 0 })
  local function feed(k) vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k, true, false, true), "xt", false) end
  feed("B"); feed("I")
  local spec = state.current.lsp_tokens["@lsp.type.function"]
  assert(spec and spec.bold and spec.italic, "B/I did not toggle")
  assert(get("@lsp.type.function").italic == true, "live preview not applied")
  feed("I")
  assert(not state.current.lsp_tokens["@lsp.type.function"].italic, "I did not toggle off")
  feed("X")
  assert(state.current.lsp_tokens["@lsp.type.function"] == nil, "X did not reset")
  -- keys do nothing on non-LSP rows
  for r, a in pairs(controls._line_actions) do
    if a.type == "slider" then vim.api.nvim_win_set_cursor(panel.wins.controls, { r, 0 }) break end
  end
  feed("B")
  assert(next(state.current.lsp_tokens) == nil, "B changed something on a slider row")
  panel.close()
end)

test("save writes lsp_tokens and the block round-trips", function()
  state.current.lsp_tokens = {}
  tf.apply({ theme = "dracula", lsp_tokens = { ["@lsp.type.parameter"] = { fg = "orange", italic = true } } })
  local block = table.concat(require("themeforge.writer").generate_block(), "\n")
  assert(block:find('["@lsp.type.parameter"] = { fg = "orange", italic = true }', 1, true), block)
  state.current.lsp_tokens = {}
  local chunk = assert(load(block:gsub("%-%- %[themeforge:%a+%] %-%-", "")))
  chunk()
  assert(state.current.lsp_tokens["@lsp.type.parameter"].italic == true, "block did not restore lsp_tokens")
end)

test("export includes customized LSP tokens", function()
  local dir = vim.fn.tempname()
  local path = tf.export("tf-lsp", dir)
  local text = table.concat(vim.fn.readfile(path), "\n")
  assert(text:find('"@lsp.type.parameter"', 1, true), "export missing @lsp.type.parameter")
end)

test("blends keep LSP tokens", function()
  tf.save_blend("lsp-test")
  state.current.lsp_tokens = {}
  assert(tf.load_blend("lsp-test"))
  assert(state.current.lsp_tokens["@lsp.type.parameter"], "blend lost lsp_tokens")
end)

test("doctor checks customized token contrast", function()
  state.set_lsp_token("@lsp.type.parameter", { fg = "#2b2b2b" })
  require("themeforge.apply").apply()
  local report = require("themeforge.doctor").report()
  local found = false
  for _, row in ipairs(report.sections[1].rows) do
    if row:find("type.parameter", 1, true) and row:find("LOW", 1, true) then found = true end
  end
  assert(found, "doctor did not flag a low-contrast LSP token")
end)

if #failures > 0 then
  print("FAILED:\n  " .. table.concat(failures, "\n  "))
  vim.cmd("cquit 1")
else
  print("ThemeForge LSP token tests passed")
end
