local M = {}

local palette_mod = require("themeforge.palette")
local color = require("themeforge.color")

-- Resolve a color reference: if it's a key in the colors table, return the color value; otherwise return as-is
local function resolve_color(ref, colors)
  if ref and colors[ref] then
    return colors[ref]
  end
  return ref
end

-- Contrast roles used to keep the sliders from destroying readability.
local CONTRAST_ROLE = {
  fg = "text", fg2 = "comment", comment = "comment",
  purple = "text", blue = "text", cyan = "text", green = "text",
  red = "text", orange = "text", yellow = "text",
}

--- Resolve the effective palette (overrides + blend sliders) for a theme.
--- Shared by apply, the panel and the doctor so every view shows the same numbers.
function M.palette(theme, mix, color_overrides)
  mix = mix or {}
  color_overrides = color_overrides or {}
  local base = {}
  for k, v in pairs(theme.colors) do
    base[k] = color_overrides[k] or v
  end
  for k, v in pairs(color_overrides) do
    if base[k] == nil then base[k] = v end
  end

  local background = base.bg
  local colors = {}
  for k, v in pairs(base) do
    if palette_mod.is_valid_hex(v) then
      colors[k] = palette_mod.apply_mix(v, mix, background, palette_mod.role_of(k))
    else
      colors[k] = v
    end
  end

  -- Sliders may tint and brighten, but never push a colour below the contrast
  -- it had before (or below the role minimum, whichever is lower). Explicit
  -- user colour overrides are respected as-is.
  if palette_mod.mix_is_active(mix) and palette_mod.is_valid_hex(colors.bg) then
    for key, role in pairs(CONTRAST_ROLE) do
      if not color_overrides[key] and palette_mod.is_valid_hex(colors[key]) and palette_mod.is_valid_hex(base[key]) then
        local before = color.wcag_ratio(base[key], base.bg)
        local floor = math.min(before, color.ROLE_MIN[role])
        colors[key] = color.ensure_contrast(colors[key], colors.bg, floor)
      end
    end
  end

  return colors
end

-- Groups introduced or re-linked by Neovim 0.10 – 0.12 (and important
-- treesitter / LSP captures). Themes that do not define them still get
-- on-palette values instead of falling back to off-theme defaults.
local function modern_defaults(c)
  local accent = c.blue or c.purple or c.fg
  local float_bg = c.bg2 or c.bg
  return {
    FloatBorder = { fg = c.bg3 or c.comment, bg = float_bg },
    FloatTitle = { fg = accent, bg = float_bg, bold = true },
    FloatFooter = { fg = c.comment, bg = float_bg },
    Pmenu = { fg = c.fg, bg = float_bg },
    PmenuSel = { bg = c.selection or c.bg3, bold = true },
    PmenuMatch = { fg = accent, bold = true },
    PmenuMatchSel = { fg = accent, bg = c.selection or c.bg3, bold = true },
    PmenuKind = { fg = c.purple or accent, bg = float_bg },
    PmenuExtra = { fg = c.comment, bg = float_bg },
    PmenuBorder = { fg = c.bg3 or c.comment, bg = float_bg },
    PmenuShadow = { bg = c.bg },
    ComplMatchIns = { fg = c.comment },
    SnippetTabstop = { bg = c.bg3 or c.selection },
    SnippetTabstopActive = { bg = c.selection or c.bg3, underline = true },
    LspReferenceText = { bg = c.bg3 or c.selection },
    LspReferenceRead = { bg = c.bg3 or c.selection },
    LspReferenceWrite = { bg = c.bg3 or c.selection, underline = true },
    LspReferenceTarget = { bg = c.selection or c.bg3, bold = true },
    LspInlayHint = { fg = c.comment, bg = c.bg2, italic = true },
    LspCodeLens = { fg = c.comment },
    LspSignatureActiveParameter = { fg = c.orange or accent, bold = true },
    DiagnosticUnnecessary = { fg = c.comment },
    DiagnosticDeprecated = { strikethrough = true, sp = c.comment },
    DiagnosticOk = { fg = c.green },
    DiagnosticVirtualTextInfo = { fg = c.blue, bg = c.bg2 },
    DiagnosticVirtualTextHint = { fg = c.cyan, bg = c.bg2 },
    DiffTextAdd = { bg = c.green and palette_mod.mix(c.bg, c.green, 0.35) or c.bg3 },
    OkMsg = { fg = c.green },
    StderrMsg = { fg = c.red },
    StdoutMsg = { fg = c.fg },
    StatusLineTerm = { fg = c.fg2 or c.fg, bg = c.bg2 },
    StatusLineTermNC = { fg = c.comment, bg = c.bg2 },
    WinBar = { fg = c.fg, bold = true },
    WinBarNC = { fg = c.comment },
    QuickFixLine = { bg = c.selection or c.bg3, bold = true },
    ["@variable.member"] = { fg = c.cyan or c.fg },
    ["@variable.parameter"] = { fg = c.orange or c.fg },
    ["@variable.builtin"] = { fg = c.red or c.purple },
    ["@keyword.return"] = { fg = c.purple, italic = false },
    ["@keyword.import"] = { fg = c.purple },
    ["@keyword.modifier"] = { fg = c.purple },
    ["@function.builtin"] = { fg = c.cyan or accent },
    ["@constant.builtin"] = { fg = c.orange },
    ["@markup.heading"] = { fg = accent, bold = true },
    ["@markup.link"] = { fg = c.cyan or accent, underline = true },
    ["@markup.raw"] = { fg = c.green },
    ["@markup.list"] = { fg = c.orange or accent },
    ["@diff.plus"] = { fg = c.green },
    ["@diff.minus"] = { fg = c.red },
    ["@diff.delta"] = { fg = c.yellow or c.orange },
    ["@comment.todo"] = { fg = c.bg, bg = c.yellow or accent, bold = true },
    ["@comment.note"] = { fg = c.bg, bg = c.cyan or accent, bold = true },
    ["@comment.warning"] = { fg = c.bg, bg = c.orange or c.yellow, bold = true },
    ["@comment.error"] = { fg = c.bg, bg = c.red, bold = true },
    -- Neovim still links @lsp.type.modifier to the removed @type.qualifier.
    ["@lsp.type.modifier"] = { link = "@keyword.modifier" },
    ["@type.qualifier"] = { link = "@keyword.modifier" },
  }
end

-- Build the full highlight table
--- @param lsp_tokens table|nil LSP semantic token customizations (see themeforge.lsp_tokens)
function M.resolve(theme, overrides, ui_options, mix, color_overrides, lsp_tokens)
  overrides = overrides or {}
  ui_options = ui_options or {}
  mix = mix or {}
  color_overrides = color_overrides or {}

  local colors = M.palette(theme, mix, color_overrides)

  -- Build base groups from theme definition
  local highlights = {}
  for group, def in pairs(theme.groups) do
    local hl = {}
    if def.fg then hl.fg = resolve_color(def.fg, colors) end
    if def.bg then hl.bg = resolve_color(def.bg, colors) end
    if def.bold ~= nil then hl.bold = def.bold end
    if def.italic ~= nil then hl.italic = def.italic end
    if def.underline ~= nil then hl.underline = def.underline end
    if def.undercurl ~= nil then hl.undercurl = def.undercurl end
    if def.strikethrough ~= nil then hl.strikethrough = def.strikethrough end
    if def.sp then hl.sp = resolve_color(def.sp, colors) end
    if def.link then hl.link = def.link end
    highlights[group] = hl
  end

  -- Fill in modern groups the theme does not define itself.
  for group, hl in pairs(modern_defaults(colors)) do
    if highlights[group] == nil then
      highlights[group] = hl
    end
  end

  -- Apply UI options
  if ui_options.italic_keywords then
    for _, g in ipairs({ "Keyword", "Statement", "Conditional", "@keyword" }) do
      highlights[g] = highlights[g] or {}
      highlights[g].italic = true
    end
  end

  if ui_options.bold_functions then
    for _, g in ipairs({ "Function", "@function" }) do
      highlights[g] = highlights[g] or {}
      highlights[g].bold = true
    end
  end

  if not ui_options.cursorline then
    highlights["CursorLine"] = { bg = "NONE" }
  end

  if ui_options.underline_diag then
    for _, g in ipairs({
      "DiagnosticUnderlineError", "DiagnosticUnderlineWarn",
      "DiagnosticUnderlineInfo", "DiagnosticUnderlineHint",
    }) do
      highlights[g] = highlights[g] or {}
      highlights[g].underline = true
    end
  end

  -- LSP semantic token customizations (above theme/defaults, below explicit overrides)
  -- Colour a group would have without the customization: follow links through
  -- this theme's highlights first, then the group's original (pre-ThemeForge)
  -- definition, e.g. @lsp.type.parameter -> @variable.parameter -> fg.
  local function base_fg(group)
    local name, hops = group, 0
    while name and hops < 12 do
      hops = hops + 1
      local def = highlights[name]
      if def == nil then
        local ok, apply = pcall(require, "themeforge.apply")
        def = ok and apply.original and apply.original(name) or nil
      end
      if not def then return nil end
      if def.link then
        name = def.link
      else
        local fg = def.fg
        if type(fg) == "number" then fg = string.format("#%06x", fg) end
        return fg
      end
    end
  end
  for group, hl in pairs(require("themeforge.lsp_tokens").resolve(lsp_tokens, colors, base_fg)) do
    highlights[group] = hl
  end

  -- Apply user overrides (highest priority)
  for group, opts in pairs(overrides) do
    if highlights[group] then
      highlights[group] = vim.tbl_extend("force", highlights[group], opts)
    else
      highlights[group] = opts
    end
  end

  -- Transparency pass
  if ui_options.transparency then
    local transparent_groups = {
      "Normal", "NormalFloat", "NormalNC", "SignColumn",
      "StatusLine", "StatusLineNC", "TabLine", "TabLineFill", "EndOfBuffer",
    }
    for _, g in ipairs(transparent_groups) do
      if highlights[g] then
        highlights[g].bg = "NONE"
      end
    end
  end

  -- ThemeForge is a multi-pane editor of its own. Keep its surfaces opaque
  -- so the user's global transparency preference cannot expose a contrasting
  -- editor background behind a light theme panel.
  highlights.ThemeForgePanelNormal = {
    fg = colors.fg,
    bg = colors.bg,
  }
  highlights.ThemeForgePanelBorder = {
    fg = colors.bg3 or colors.comment or colors.fg,
    bg = colors.bg,
  }
  highlights.ThemeForgePanelCursorLine = {
    bg = colors.selection or colors.bg3 or colors.bg2,
    bold = true,
  }
  -- Panel chrome follows the theme being previewed.
  local accent = colors.blue or colors.purple or colors.fg
  local surface = colors.bg3 or colors.bg2 or colors.bg
  for name, hl in pairs({
    ThemeForgeTitle = { fg = accent, bold = true },
    ThemeForgeAccent = { fg = colors.purple or accent, bold = true },
    ThemeForgeRule = { fg = surface },
    ThemeForgeMuted = { fg = colors.comment or colors.fg2 },
    ThemeForgeText = { fg = colors.fg },
    ThemeForgeOk = { fg = colors.green or accent, bold = true },
    ThemeForgeWarn = { fg = colors.yellow or colors.orange, bold = true },
    ThemeForgeBad = { fg = colors.red or colors.orange, bold = true },
    ThemeForgeFav = { fg = colors.yellow or colors.orange },
    ThemeForgeKey = { fg = colors.bg, bg = accent, bold = true },
    ThemeForgeKeyLabel = { fg = colors.fg2 or colors.fg, bg = colors.bg2 or colors.bg },
    ThemeForgeBar = { fg = colors.fg2 or colors.fg, bg = colors.bg2 or colors.bg },
    ThemeForgeBtnPrimary = { fg = colors.bg, bg = colors.green or accent, bold = true },
    ThemeForgeBtn = { fg = colors.fg, bg = surface, bold = true },
    ThemeForgeSliderFill = { fg = accent },
    ThemeForgeSliderTrack = { fg = surface },
    ThemeForgeBadgePreview = { fg = colors.bg, bg = colors.yellow or colors.orange, bold = true },
    ThemeForgeBadgeApplied = { fg = colors.bg, bg = colors.green or accent, bold = true },
    ThemeForgeBadgeSaved = { fg = colors.bg, bg = colors.cyan or accent, bold = true },
    ThemeForgeFlagOn = { fg = colors.bg, bg = colors.purple or accent, bold = true },
    ThemeForgeFlagOff = { fg = colors.comment or surface },
  }) do
    if not overrides[name] then highlights[name] = hl end
  end

  -- Ensure cursor/selection contrast when bold_cursor enabled
  if ui_options.bold_cursor ~= false then
    local cursor_groups = {
      "CursorLine",
      "CursorLineNr",
      "NvimTreeCursorLine",
      "NeoTreeCursorLine",
      "TelescopeSelection",
      "TelescopeNormal",
    }
    for _, g in ipairs(cursor_groups) do
      if highlights[g] then
        highlights[g].bold = true
      end
    end
  end

  -- Selected items always have visible colors
  local selected_groups = {
    "NvimTreeSelected",
    "NvimTreeLuckies", "NvimTreeFocused",
    "NeoTreeSelected", "NeoTreeFocused",
    "TelescopeSelection",
  }
  for _, g in ipairs(selected_groups) do
    if highlights[g] then
      highlights[g].bg = colors.selection or colors.bg2 or colors.bg
      highlights[g].fg = colors.fg
    end
  end

  -- Ensure Directory/Link groups are visible
  local dir_groups = {
    "Directory", "NvimTreeFolderName", "NvimTreeOpenedFolderName",
    "NeoTreeDirectoryName", "NeoTreeDirectoryIcon", "NeoTreeOpenedDirectoryName",
  }
  for _, g in ipairs(dir_groups) do
    if highlights[g] and not highlights[g].bold then
      highlights[g].bold = true
    end
  end

  -- Keep low-priority UI information readable. Several explorers and tab
  -- components use these names directly instead of exposing their own theme
  -- adapter hooks.
  local function set_default(group, value)
    if not overrides[group] then
      highlights[group] = value
    end
  end

  set_default("LineNr", { fg = colors.fg2 or colors.fg })
  set_default("StatusLineNC", { fg = colors.fg2 or colors.fg, bg = colors.bg2 or colors.bg })
  set_default("TabLine", { fg = colors.fg2 or colors.fg, bg = colors.bg2 or colors.bg })
  set_default("TabLineFill", { bg = colors.bg2 or colors.bg })
  set_default("TabLineSel", { fg = colors.fg, bg = colors.bg, bold = true })

  local git_groups = {
    "GitSignsUntracked", "GitSignsCurrentLineBlame",
    "NvimTreeGitNew", "NvimTreeGitNewIcon", "NvimTreeGitStaged",
    "NeoTreeGitUntracked", "NeoTreeGitAdded", "NeoTreeGitStaged",
    "SnacksExplorerGitUntracked", "SnacksPickerGitUntracked",
    "SnacksPickerGitStatus", "SnacksPickerGitStatusUntracked",
    "SnacksPickerGitStatusAdded", "SnacksPickerGitStatusModified",
    "SnacksPickerGitStatusStaged", "SnacksPickerGitStatusCopied",
    "SnacksPickerGitStatusRenamed", "ExplorerGitUntracked", "ExplorerGitNew",
  }
  for _, g in ipairs(git_groups) do
    set_default(g, { fg = colors.green or colors.blue or colors.fg, bold = true })
  end

  local dim_groups = {
    "NvimTreeLineNr", "NvimTreeDimText", "NeoTreeDimText",
    "SnacksExplorerDimmed", "SnacksPickerDimmed",
    "ExplorerDimmed", "ExplorerLineNr",
  }
  for _, g in ipairs(dim_groups) do
    set_default(g, { fg = colors.fg or colors.fg2 })
  end

  -- Snacks uses NonText for hidden paths and counters by default. That is too
  -- faint for an explorer, and PathHidden can otherwise override git status
  -- extmarks on untracked files.
  set_default("SnacksPickerPathHidden", { fg = colors.fg })
  set_default("SnacksPickerTotals", { fg = colors.fg, bold = true })
  set_default("SnacksPickerIdx", { fg = colors.fg2 or colors.fg })

  -- Snacks Explorer (and Explorer-like pickers) use these groups for the
  -- actual row, file, directory and counter text. Keep them readable even
  -- when a theme's comment color is intentionally subdued.
  local explorer_groups = {
    SnacksPickerFile = { fg = colors.fg },
    SnacksPickerDir = { fg = colors.blue or colors.fg, bold = true },
    SnacksPickerRow = { fg = colors.fg },
    SnacksPickerCol = { fg = colors.fg },
    SnacksPickerTree = { fg = colors.fg2 or colors.fg },
    SnacksPickerMatch = { fg = colors.yellow or colors.blue, bold = true },
    ExplorerFile = { fg = colors.fg },
    ExplorerDir = { fg = colors.blue or colors.fg, bold = true },
    ExplorerRow = { fg = colors.fg },
    ExplorerCol = { fg = colors.fg },
  }
  for g, value in pairs(explorer_groups) do
    set_default(g, value)
  end

  return highlights, colors
end

return M
