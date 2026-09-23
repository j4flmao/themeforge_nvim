local M = {}

local palette_mod = require("themeforge.palette")

-- Resolve a color reference: if it's a key in the colors table, return the color value; otherwise return as-is
local function resolve_color(ref, colors)
  if ref and colors[ref] then
    return colors[ref]
  end
  return ref
end

-- Build the full highlight table
function M.resolve(theme, overrides, ui_options, mix)
  overrides = overrides or {}
  ui_options = ui_options or {}
  mix = mix or {}

  -- First, apply mix to the colors
  local colors = {}
  for k, v in pairs(theme.colors) do
    if palette_mod.is_valid_hex(v) then
      colors[k] = palette_mod.apply_mix(v, mix, theme.colors.bg)
    else
      colors[k] = v
    end
  end

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
