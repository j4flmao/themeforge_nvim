local M = {}

function M.groups(c)
  return {
    WhichKey          = { fg = c.cyan },
    WhichKeyGroup     = { fg = c.blue },
    WhichKeySeparator = { fg = c.comment },
    WhichKeyDesc      = { fg = c.purple },
    WhichKeyFloat     = { bg = c.bg2 },
    WhichKeyBorder    = { fg = c.comment, bg = c.bg2 },
    WhichKeyValue     = { fg = c.fg2 },
  }
end

return M
