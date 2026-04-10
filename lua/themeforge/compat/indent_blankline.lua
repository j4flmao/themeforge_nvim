local M = {}

function M.groups(c)
  return {
    IblIndent     = { fg = c.bg3 },
    IblScope      = { fg = c.comment },
    IblWhitespace = { fg = c.bg3 },
    IndentBlanklineChar = { fg = c.bg3 },
    IndentBlanklineContextChar = { fg = c.comment },
    IndentBlanklineSpaceChar   = { fg = c.bg3 },
  }
end

return M
