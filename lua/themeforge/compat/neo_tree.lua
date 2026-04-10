local M = {}

local palette = require("themeforge.palette")

local function boost(hex, sat_delta, light_delta)
  if not hex or not palette.is_valid_hex(hex) then return hex end
  return palette.adjust_lightness(palette.adjust_saturation(hex, sat_delta), light_delta)
end

function M.groups(c)
  local dir_color = boost(c.blue, 20, 10)
  local root_color = boost(c.purple, 15, 8)

  return {
    NeoTreeNormal            = { fg = c.fg, bg = c.bg2 },
    NeoTreeNormalNC          = { fg = c.fg, bg = c.bg2 },
    NeoTreeRootName          = { fg = root_color, bold = true },
    NeoTreeDirectoryName     = { fg = dir_color, bold = true },
    NeoTreeDirectoryIcon     = { fg = dir_color, bold = true },
    NeoTreeOpenedDirectoryName = { fg = dir_color, bold = true },
    NeoTreeFileName          = { fg = c.fg },
    NeoTreeFileIcon          = { fg = c.fg2 },
    NeoTreeSpecialFile       = { fg = c.yellow, bold = true },
    NeoTreeIndentMarker      = { fg = c.bg3 },
    -- Git: theme colors + style cues to differentiate status
    NeoTreeGitModified       = { fg = c.orange, italic = true },
    NeoTreeGitAdded          = { fg = c.green, bold = true },
    NeoTreeGitUntracked   = { fg = c.green, bold = true },
    NeoTreeGitDeleted        = { fg = c.red, strikethrough = true },
    NeoTreeGitRenamed        = { fg = c.purple, italic = true },
    NeoTreeGitStaged         = { fg = c.green },
    NeoTreeGitConflict       = { fg = c.red, bold = true, undercurl = true },
    NeoTreeCursorLine        = { bg = c.bg3, bold = true },
    NeoTreeWinSeparator      = { fg = c.bg2, bg = c.bg2 },
    NeoTreeFloatBorder       = { fg = c.blue, bg = c.bg2 },
    NeoTreeFloatTitle        = { fg = c.blue, bold = true },
    NeoTreeTitleBar          = { fg = c.bg, bg = c.blue, bold = true },
  }
end

return M
