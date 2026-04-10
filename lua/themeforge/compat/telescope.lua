local M = {}

function M.groups(c)
  return {
    TelescopeNormal        = { fg = c.fg, bg = c.bg2 },
    TelescopeBorder        = { fg = c.comment, bg = c.bg2 },
    TelescopeTitle         = { fg = c.blue, bold = true },
    TelescopePromptNormal  = { fg = c.fg, bg = c.bg3 },
    TelescopePromptBorder  = { fg = c.bg3, bg = c.bg3 },
    TelescopePromptTitle   = { fg = c.bg, bg = c.blue, bold = true },
    TelescopePromptPrefix  = { fg = c.blue },
    TelescopeResultsNormal = { fg = c.fg, bg = c.bg2 },
    TelescopeResultsBorder = { fg = c.bg2, bg = c.bg2 },
    TelescopePreviewNormal = { fg = c.fg, bg = c.bg },
    TelescopePreviewBorder = { fg = c.bg, bg = c.bg },
    TelescopePreviewTitle  = { fg = c.bg, bg = c.green, bold = true },
    TelescopeSelection     = { fg = c.fg, bg = c.bg3 },
    TelescopeSelectionCaret = { fg = c.blue },
    TelescopeMatching      = { fg = c.orange, bold = true },
    TelescopeMultiSelection = { fg = c.purple },
    TelescopeMultiIcon     = { fg = c.blue },
  }
end

return M
