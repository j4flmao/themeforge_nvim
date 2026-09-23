local M = {}

function M.groups(c)
  return {
    BufferLineFill         = { bg = c.bg2 },
    BufferLineBackground   = { fg = c.comment, bg = c.bg2 },
    BufferLineBufferVisible = { fg = c.fg2, bg = c.bg2 },
    BufferLineBufferSelected = { fg = c.fg, bg = c.bg, bold = true },
    BufferLineTab          = { fg = c.comment, bg = c.bg2 },
    BufferLineTabSelected  = { fg = c.fg, bg = c.bg },
    BufferLineTabClose     = { fg = c.red, bg = c.bg2 },
    BufferLineIndicatorSelected = { fg = c.blue, bg = c.bg },
    BufferLineSeparator     = { fg = c.bg3 or c.fg2, bg = c.bg2 },
    BufferLineSeparatorVisible = { fg = c.bg3 or c.fg2, bg = c.bg2 },
    BufferLineSeparatorSelected = { fg = c.bg3 or c.fg2, bg = c.bg },
    BufferLineModified      = { fg = c.green },
    BufferLineModifiedVisible = { fg = c.green },
    BufferLineModifiedSelected = { fg = c.green },
    BufferLineDuplicate     = { fg = c.comment, bg = c.bg2, italic = true },
    BufferLineDuplicateVisible = { fg = c.comment, bg = c.bg2, italic = true },
    BufferLineDuplicateSelected = { fg = c.comment, bg = c.bg, italic = true },
  }
end

return M
