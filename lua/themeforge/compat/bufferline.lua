local M = {}

function M.groups(c)
  local ok, state = pcall(require, "themeforge.state")
  local transparent = ok and state.current.ui_options and state.current.ui_options.transparency
  -- The selected tab sits on the editor: transparent when the editor is.
  local sel = transparent and "NONE" or c.bg
  local fill = c.bg2 or c.bg
  return {
    BufferLineFill         = { bg = c.bg2 },
    BufferLineBackground   = { fg = c.comment, bg = c.bg2 },
    BufferLineBufferVisible = { fg = c.fg2, bg = c.bg2 },
    BufferLineBufferSelected = { fg = c.fg, bg = sel, bold = true },
    BufferLineTab          = { fg = c.comment, bg = c.bg2 },
    BufferLineTabSelected  = { fg = c.fg, bg = sel },
    BufferLineTabClose     = { fg = c.red, bg = c.bg2 },
    BufferLineIndicatorSelected = { fg = c.blue, bg = sel },
    BufferLineCloseButtonSelected = { fg = c.red, bg = sel },
    BufferLineDiagnosticSelected = { fg = c.fg2, bg = sel },
    BufferLineNumbersSelected = { fg = c.fg, bg = sel },
    BufferLineSeparator     = { fg = fill, bg = fill },
    BufferLineSeparatorVisible = { fg = fill, bg = fill },
    BufferLineSeparatorSelected = { fg = fill, bg = sel },
    BufferLineOffsetSeparator = { fg = c.bg3 or c.comment, bg = fill },
    BufferLineModified      = { fg = c.green },
    BufferLineModifiedVisible = { fg = c.green },
    BufferLineModifiedSelected = { fg = c.green, bg = sel },
    BufferLineDuplicate     = { fg = c.comment, bg = c.bg2, italic = true },
    BufferLineDuplicateVisible = { fg = c.comment, bg = c.bg2, italic = true },
    BufferLineDuplicateSelected = { fg = c.comment, bg = sel, italic = true },
  }
end

return M
