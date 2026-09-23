local M = {}

function M.groups(c)
  return {
    GitSignsAdd          = { fg = c.green },
    GitSignsChange       = { fg = c.yellow },
    GitSignsDelete       = { fg = c.red },
    GitSignsTopdelete    = { fg = c.red },
    GitSignsChangedelete = { fg = c.orange },
    GitSignsUntracked    = { fg = c.green, bold = true },
    GitSignsAddNr        = { fg = c.green },
    GitSignsChangeNr     = { fg = c.yellow },
    GitSignsDeleteNr     = { fg = c.red },
    GitSignsAddLn        = { bg = c.bg2 },
    GitSignsChangeLn     = { bg = c.bg2 },
    GitSignsDeleteLn     = { bg = c.bg2 },
    GitSignsCurrentLineBlame = { fg = c.fg2, italic = true },
  }
end

return M
