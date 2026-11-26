-- LSP semantic token customization.
--
-- Users customize `@lsp.type.*` / `@lsp.mod.*` highlight groups with a palette
-- key ("orange") or a hex colour, plus bold / italic / underline / strikethrough:
--
--   require("themeforge").apply({
--     lsp_tokens = {
--       ["@lsp.type.parameter"] = { fg = "orange", italic = true },
--       ["@lsp.mod.deprecated"] = { strikethrough = true },
--     },
--   })
--
-- Palette keys follow the active theme and its blend sliders; hex values are
-- used as-is. Tokens that are not customized keep the theme / Neovim defaults.
local M = {}

M.STYLES = { "bold", "italic", "underline", "strikethrough" }

--- Tokens shown in the panel. `default` is the palette key used when only a
--- style is customized (types); modifiers have no default colour, so a style-only
--- modifier (e.g. strikethrough on deprecated) keeps the token's own colour.
M.TOKENS = {
  { group = "@lsp.type.class", label = "class", default = "yellow" },
  { group = "@lsp.type.interface", label = "interface", default = "yellow" },
  { group = "@lsp.type.struct", label = "struct", default = "yellow" },
  { group = "@lsp.type.enum", label = "enum", default = "yellow" },
  { group = "@lsp.type.enumMember", label = "enumMember", default = "orange" },
  { group = "@lsp.type.type", label = "type", default = "cyan" },
  { group = "@lsp.type.typeParameter", label = "typeParameter", default = "cyan" },
  { group = "@lsp.type.namespace", label = "namespace", default = "cyan" },
  { group = "@lsp.type.parameter", label = "parameter", default = "orange" },
  { group = "@lsp.type.variable", label = "variable", default = "fg" },
  { group = "@lsp.type.property", label = "property", default = "cyan" },
  { group = "@lsp.type.function", label = "function", default = "blue" },
  { group = "@lsp.type.method", label = "method", default = "blue" },
  { group = "@lsp.type.macro", label = "macro", default = "purple" },
  { group = "@lsp.type.decorator", label = "decorator", default = "orange" },
  { group = "@lsp.mod.readonly", label = "readonly", modifier = true },
  { group = "@lsp.mod.static", label = "static", modifier = true },
  { group = "@lsp.mod.async", label = "async", modifier = true },
  { group = "@lsp.mod.deprecated", label = "deprecated", modifier = true },
  { group = "@lsp.mod.defaultLibrary", label = "defaultLibrary", modifier = true },
}

local by_group = {}
for _, t in ipairs(M.TOKENS) do by_group[t.group] = t end

--- Token metadata for a group (nil for groups outside the curated list).
function M.info(group)
  return by_group[group]
end

--- Palette keys offered by the colour picker.
M.PALETTE_KEYS = { "purple", "blue", "cyan", "green", "yellow", "orange", "red", "fg", "fg2", "comment" }

local function is_hex(v)
  return type(v) == "string" and v:match("^#%x%x%x%x%x%x$") ~= nil
end

--- Accept "@lsp.type.x", "lsp.type.x" or "type.x" and return "@lsp.type.x".
function M.normalize_group(name)
  if type(name) ~= "string" or name == "" then return nil end
  if name:sub(1, 1) == "@" then return name end
  if name:sub(1, 4) == "lsp." then return "@" .. name end
  if name:match("^type%.") or name:match("^mod%.") or name:match("^typemod%.") then return "@lsp." .. name end
  return nil
end

--- Validate and clean a user spec. Returns nil when nothing remains.
function M.clean(spec)
  if type(spec) ~= "table" then return nil end
  local out = {}
  if type(spec.fg) == "string" and spec.fg ~= "" then out.fg = spec.fg end
  for _, s in ipairs(M.STYLES) do
    if spec[s] ~= nil then out[s] = spec[s] == true end
  end
  if next(out) == nil then return nil end
  return out
end

--- Kind of a group: "type" | "mod" | "typemod" | nil.
function M.kind(group)
  return group and group:match("^@lsp%.(%a+)%.") or nil
end

--- Drop a language suffix: "@lsp.type.parameter.rust" -> "@lsp.type.parameter",
--- "@lsp.typemod.variable.mutable.rust" -> "@lsp.typemod.variable.mutable".
function M.strip_lang(group)
  local parts = vim.split(group, ".", { plain = true })
  local want = parts[2] == "typemod" and 4 or 3
  if #parts > want then
    return table.concat(parts, ".", 1, want)
  end
  return group
end

--- Highlight definition for one customized token.
--- @param group string
--- @param spec table {fg?, bold?, italic?, underline?, strikethrough?}
--- @param colors table resolved palette
--- @param base fun(group: string): string|nil colour the group would have without the
---   customization (theme + Neovim default links); keeps style-only edits on the real colour
function M.highlight(group, spec, colors, base)
  local hl = {}
  local fg = spec.fg
  local kind = M.kind(group)
  if fg then
    fg = colors[fg] or (is_hex(fg) and fg) or nil
  elseif kind ~= "mod" then
    -- Modifiers without a colour stay style-only so they inherit the token's colour.
    fg = base and base(group)
    if not fg and kind == "typemod" and base then
      fg = base("@lsp.type." .. (group:match("^@lsp%.typemod%.([^.]+)") or ""))
    end
    local info = by_group[group]
    if not fg and info and info.default then fg = colors[info.default] end
  end
  if fg then hl.fg = fg end
  for _, s in ipairs(M.STYLES) do
    if spec[s] ~= nil then hl[s] = spec[s] end
  end
  return hl
end

--- Servers name the same concept differently. gopls, for example, sends an
--- interface as type "type" + modifier "interface". Styling the curated token
--- also styles these equivalents, unless they are customized themselves.
M.ALIASES = {
  ["@lsp.type.interface"] = { "@lsp.typemod.type.interface" },
  ["@lsp.type.struct"] = { "@lsp.typemod.type.struct" },
}

--- All highlight definitions for a set of token customizations.
function M.resolve(tokens, colors, base)
  local out = {}
  for name, spec in pairs(tokens or {}) do
    local group = M.normalize_group(name)
    local clean = M.clean(spec)
    if group and clean then out[group] = M.highlight(group, clean, colors, base) end
  end
  for src, aliases in pairs(M.ALIASES) do
    if out[src] then
      for _, alias in ipairs(aliases) do
        if out[alias] == nil then out[alias] = vim.deepcopy(out[src]) end
      end
    end
  end
  return out
end

-- ── What the running language servers actually use ─────────────────────────

local function legend_of(client)
  local p = client.server_capabilities and client.server_capabilities.semanticTokensProvider
  if p and p.legend then return p.legend end
  local ok, regs = pcall(function()
    return client.dynamic_capabilities:get("textDocument/semanticTokens", {})
  end)
  if ok and type(regs) == "table" and regs[1] and regs[1].registerOptions then
    return regs[1].registerOptions.legend
  end
end

--- Semantic token highlight extmarks in loaded buffers:
--- calls fn(buf, row, col, end_col, raw_group, priority) for each one.
local function each_mark(fn)
  local namespaces = {}
  for name, id in pairs(vim.api.nvim_get_namespaces()) do
    if name:find("semantic_tokens", 1, true) then table.insert(namespaces, id) end
  end
  if #namespaces == 0 then return end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      for _, ns in ipairs(namespaces) do
        local ok, marks = pcall(vim.api.nvim_buf_get_extmarks, buf, ns, 0, -1, { details = true, limit = 20000 })
        for _, m in ipairs(ok and marks or {}) do
          local d = m[4] or {}
          local g = d.hl_group
          if type(g) == "string" and g:sub(1, 5) == "@lsp." then
            local end_col = (d.end_row == nil or d.end_row == m[2]) and d.end_col or nil
            fn(buf, m[2], m[3], end_col, g, d.priority or 0)
          end
        end
      end
    end
  end
end
M._each_mark = each_mark

--- Language servers with semantic tokens, and the token groups currently drawn.
--- @return {clients: string[], used: table<string, boolean>, legend: table<string, boolean>, samples: table<string, string>}
function M.active()
  local res = { clients = {}, used = {}, legend = {}, samples = {} }
  local seen_client = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    local legend = legend_of(client)
    if legend and not seen_client[client.name] then
      seen_client[client.name] = true
      table.insert(res.clients, client.name)
      for _, t in ipairs(legend.tokenTypes or {}) do res.legend["@lsp.type." .. t] = true end
      for _, m in ipairs(legend.tokenModifiers or {}) do res.legend["@lsp.mod." .. m] = true end
    end
  end
  table.sort(res.clients)
  -- Groups actually drawn, with a sample word from your code for each.
  each_mark(function(buf, row, col, end_col, raw)
    local group = M.strip_lang(raw)
    res.used[group] = true
    if not res.samples[group] and end_col and end_col > col then
      local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
      local text = vim.trim(line:sub(col + 1, end_col))
      if text:match("^[%w_'@$]+$") then res.samples[group] = text end
    end
  end)
  return res
end

-- fg a highlight group really renders with: Neovim falls back from
-- "@lsp.type.parameter.rust" to "@lsp.type.parameter" when the first is undefined.
local function render_fg(group)
  local name = group
  while name and name ~= "" do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl and next(hl) then
      return hl.fg
    end
    name = name:match("^(.+)%.[^.]+$")
  end
end

--- Check that customized colours are what is actually drawn in the open buffers.
--- For every position where a customized token appears, the colour on screen is
--- the highest-priority semantic group that sets a colour; a more specific group
--- (e.g. @lsp.typemod.function.defaultLibrary) can win over the customized one.
--- @return table<string, {total: integer, ok: integer, by: table<string, integer>, sample: string?}>
function M.verify(tokens)
  tokens = tokens or {}
  local want = {}
  for name, spec in pairs(tokens) do
    local group = M.normalize_group(name)
    if group and type(spec) == "table" and spec.fg then want[group] = true end
  end
  local results = {}
  if next(want) == nil then return results end

  local positions = {}
  each_mark(function(buf, row, col, end_col, raw, priority)
    local key = buf .. ":" .. row .. ":" .. col
    positions[key] = positions[key] or { buf = buf, row = row, col = col, end_col = end_col, marks = {} }
    table.insert(positions[key].marks, { raw = raw, group = M.strip_lang(raw), priority = priority })
  end)

  for _, pos in pairs(positions) do
    table.sort(pos.marks, function(a, b) return a.priority > b.priority end)
    local winner
    for _, m in ipairs(pos.marks) do
      if render_fg(m.raw) then winner = m break end
    end
    for _, m in ipairs(pos.marks) do
      if want[m.group] then
        local r = results[m.group] or { total = 0, ok = 0, by = {} }
        results[m.group] = r
        r.total = r.total + 1
        local expected = render_fg(m.raw)
        local shown = winner and render_fg(winner.raw)
        if expected and shown == expected then
          r.ok = r.ok + 1
        else
          local by = winner and winner.group or "(no colour)"
          r.by[by] = (r.by[by] or 0) + 1
          if not r.sample and pos.end_col then
            local line = vim.api.nvim_buf_get_lines(pos.buf, pos.row, pos.row + 1, false)[1] or ""
            r.sample = line:sub(pos.col + 1, pos.end_col)
          end
        end
      end
    end
  end
  return results
end

-- Purely syntactic token types: not useful to customize from the panel.
local NOISE = {
  angle = true, arithmetic = true, attributeBracket = true, bitwise = true, brace = true, bracket = true,
  colon = true, comma = true, comparison = true, dot = true, logical = true, parenthesis = true,
  punctuation = true, semicolon = true, negation = true, operator = true, comment = true, string = true,
  number = true, keyword = true, unknown = true, documentation = true, declaration = true, definition = true,
  injected = true,
}

--- Rows for the panel: the curated list plus type / modifier tokens used by the
--- running language servers that are not in it.
--- @return table[] rows {group, label, modifier, used, extra}
function M.panel_rows(active)
  active = active or M.active()
  local rows = {}
  for _, t in ipairs(M.TOKENS) do
    table.insert(rows, {
      group = t.group, label = t.label, modifier = t.modifier,
      used = active.used[t.group] == true,
    })
  end
  local extras = {}
  for group in pairs(active.used) do
    local kind, name = group:match("^@lsp%.(%a+)%.([%w_]+)$")
    if (kind == "type" or kind == "mod") and not by_group[group] and not NOISE[name] then
      table.insert(extras, { group = group, label = name, modifier = kind == "mod", used = true, extra = true })
    end
  end
  table.sort(extras, function(a, b)
    if a.modifier ~= b.modifier then return not a.modifier end
    return a.label < b.label
  end)
  vim.list_extend(rows, extras)
  return rows
end

--- Semantic token groups under a position (most specific first, language suffix removed).
function M.at_pos(buf, row, col)
  local ok, info = pcall(vim.inspect_pos, buf, row, col, {
    semantic_tokens = true, syntax = false, treesitter = false, extmarks = false,
  })
  local items, seen = {}, {}
  for _, st in ipairs(ok and info.semantic_tokens or {}) do
    local raw = st.opts and st.opts.hl_group
    if type(raw) == "string" then
      local group = M.strip_lang(raw)
      if not seen[group] then
        seen[group] = true
        table.insert(items, { group = group, priority = st.opts.priority or 0 })
      end
    end
  end
  -- Highlight extmarks only exist for lines that have been drawn. Fall back to
  -- the token data itself (type + modifiers) so the lookup works anywhere.
  if #items == 0 and vim.lsp.semantic_tokens and vim.lsp.semantic_tokens.get_at_pos then
    local ok2, toks = pcall(vim.lsp.semantic_tokens.get_at_pos, buf, row, col)
    for _, tok in ipairs(ok2 and toks or {}) do
      local mods = {}
      for m, on in pairs(tok.modifiers or {}) do
        if on then table.insert(mods, m) end
      end
      table.sort(mods)
      local function push(group, priority)
        if not seen[group] then
          seen[group] = true
          table.insert(items, { group = group, priority = priority })
        end
      end
      for _, m in ipairs(mods) do push("@lsp.typemod." .. tok.type .. "." .. m, 127) end
      for _, m in ipairs(mods) do push("@lsp.mod." .. m, 126) end
      push("@lsp.type." .. tok.type, 125)
    end
  end
  table.sort(items, function(a, b)
    if a.priority ~= b.priority then return a.priority > b.priority end
    return a.group < b.group
  end)
  return items
end

--- Human readable summary of a spec for the panel ("orange italic").
function M.describe(spec)
  if not spec then return "default" end
  local parts = {}
  if spec.fg then table.insert(parts, spec.fg) end
  for _, s in ipairs(M.STYLES) do
    if spec[s] then table.insert(parts, s) end
  end
  return #parts > 0 and table.concat(parts, " ") or "default"
end

return M
