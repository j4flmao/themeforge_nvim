local M = {}

function M.groups(c)
  return {
    CmpItemAbbr           = { fg = c.fg },
    CmpItemAbbrDeprecated = { fg = c.comment, strikethrough = true },
    CmpItemAbbrMatch      = { fg = c.blue, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = c.blue, bold = true },
    CmpItemKind           = { fg = c.purple },
    CmpItemKindFunction   = { fg = c.blue },
    CmpItemKindMethod     = { fg = c.blue },
    CmpItemKindVariable   = { fg = c.cyan },
    CmpItemKindField      = { fg = c.cyan },
    CmpItemKindProperty   = { fg = c.cyan },
    CmpItemKindClass      = { fg = c.yellow },
    CmpItemKindInterface  = { fg = c.yellow },
    CmpItemKindStruct     = { fg = c.yellow },
    CmpItemKindKeyword    = { fg = c.purple },
    CmpItemKindText       = { fg = c.fg2 },
    CmpItemKindSnippet    = { fg = c.green },
    CmpItemMenu           = { fg = c.comment },
    CmpDocumentation      = { fg = c.fg, bg = c.bg2 },
    CmpDocumentationBorder = { fg = c.comment, bg = c.bg2 },
  }
end

return M
