local M = {}

function M.groups(c)
  local float = c.bg2 or c.bg
  local border = c.bg3 or c.comment
  local g = {
    SnacksNormal = { fg = c.fg, bg = float },
    SnacksWinBar = { fg = c.fg, bold = true },
    SnacksBackdrop = { bg = c.bg },
    SnacksDashboardHeader = { fg = c.blue },
    SnacksDashboardKey = { fg = c.orange, bold = true },
    SnacksDashboardDesc = { fg = c.fg },
    SnacksDashboardIcon = { fg = c.cyan },
    SnacksDashboardFooter = { fg = c.comment },
    SnacksDashboardSpecial = { fg = c.purple },
    SnacksIndent = { fg = c.bg3 or c.comment },
    SnacksIndentScope = { fg = c.purple or c.blue },
    SnacksInputNormal = { fg = c.fg, bg = float },
    SnacksInputBorder = { fg = c.blue or border, bg = float },
    SnacksInputTitle = { fg = c.blue, bold = true },
    SnacksPickerBorder = { fg = border, bg = float },
    SnacksPickerTitle = { fg = c.blue, bold = true },
    SnacksPickerPrompt = { fg = c.purple or c.blue },
    SnacksPickerListCursorLine = { bg = c.selection or c.bg3 },
  }
  local levels = { Info = "blue", Warn = "yellow", Error = "red", Debug = "comment", Trace = "purple" }
  for level, key in pairs(levels) do
    g["SnacksNotifier" .. level] = { fg = c.fg, bg = float }
    g["SnacksNotifierBorder" .. level] = { fg = c[key] or border, bg = float }
    g["SnacksNotifierTitle" .. level] = { fg = c[key] or c.fg, bold = true }
    g["SnacksNotifierIcon" .. level] = { fg = c[key] or c.fg }
  end
  local rainbow = { "red", "orange", "yellow", "green", "cyan", "blue", "purple", "fg2" }
  for i, key in ipairs(rainbow) do
    g["SnacksIndent" .. i] = { fg = c[key] or c.comment }
  end
  return g
end

return M
