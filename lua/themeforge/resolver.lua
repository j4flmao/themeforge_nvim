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
      colors[k] = palette_mod.apply_mix(v, mix)
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

  return highlights, colors
end

return M
