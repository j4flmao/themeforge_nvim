local M = {}

function M.groups(c)
  return {
    NvimTreeNormal       = { fg = c.fg, bg = c.bg2 },
    NvimTreeNormalNC     = { fg = c.fg, bg = c.bg2 },
    NvimTreeRootFolder   = { fg = c.purple, bold = true },
    NvimTreeFolderName   = { fg = c.blue },
    NvimTreeFolderIcon   = { fg = c.blue },
    NvimTreeOpenedFolderName = { fg = c.blue, bold = true },
    NvimTreeEmptyFolderName  = { fg = c.comment },
    NvimTreeFileIcon     = { fg = c.fg2 },
    NvimTreeSpecialFile  = { fg = c.yellow, bold = true },
    NvimTreeIndentMarker = { fg = c.bg3 },
    NvimTreeGitDirty     = { fg = c.orange },
    NvimTreeGitNew       = { fg = c.green, bold = true },
    NvimTreeGitDeleted   = { fg = c.red },
    NvimTreeGitRenamed   = { fg = c.purple },
    NvimTreeGitStaged    = { fg = c.green },
    NvimTreeGitMerge     = { fg = c.cyan },
    NvimTreeWindowPicker = { fg = c.bg, bg = c.blue, bold = true },
    NvimTreeCursorLine   = { bg = c.bg3 },
    NvimTreeWinSeparator = { fg = c.bg2, bg = c.bg2 },
  }
end

return M
