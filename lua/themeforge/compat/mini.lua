local M = {}

function M.groups(c)
  local float = c.bg2 or c.bg
  local border = c.bg3 or c.comment
  return {
    MiniStatuslineModeNormal = { fg = c.bg, bg = c.blue, bold = true },
    MiniStatuslineModeInsert = { fg = c.bg, bg = c.green, bold = true },
    MiniStatuslineModeVisual = { fg = c.bg, bg = c.purple, bold = true },
    MiniStatuslineModeReplace = { fg = c.bg, bg = c.red, bold = true },
    MiniStatuslineModeCommand = { fg = c.bg, bg = c.yellow, bold = true },
    MiniStatuslineModeOther = { fg = c.bg, bg = c.cyan, bold = true },
    MiniStatuslineDevinfo = { fg = c.fg, bg = c.bg3 },
    MiniStatuslineFilename = { fg = c.fg2 or c.fg, bg = c.bg2 },
    MiniStatuslineFileinfo = { fg = c.fg, bg = c.bg3 },
    MiniStatuslineInactive = { fg = c.comment, bg = c.bg2 },
    MiniTablineCurrent = { fg = c.fg, bg = c.bg, bold = true },
    MiniTablineVisible = { fg = c.fg2 or c.fg, bg = c.bg2 },
    MiniTablineHidden = { fg = c.comment, bg = c.bg2 },
    MiniTablineModifiedCurrent = { fg = c.orange, bg = c.bg, bold = true },
    MiniTablineFill = { bg = c.bg2 },
    MiniPickNormal = { fg = c.fg, bg = float },
    MiniPickBorder = { fg = border, bg = float },
    MiniPickPrompt = { fg = c.purple or c.blue, bg = float },
    MiniPickMatchCurrent = { bg = c.selection or c.bg3 },
    MiniPickMatchRanges = { fg = c.blue, bold = true },
    MiniFilesNormal = { fg = c.fg, bg = float },
    MiniFilesBorder = { fg = border, bg = float },
    MiniFilesTitleFocused = { fg = c.blue, bold = true },
    MiniFilesDirectory = { fg = c.blue, bold = true },
    MiniIndentscopeSymbol = { fg = c.purple or c.blue },
    MiniCursorword = { underline = true },
    MiniCursorwordCurrent = { underline = true },
    MiniHipatternsTodo = { fg = c.bg, bg = c.yellow, bold = true },
    MiniHipatternsFixme = { fg = c.bg, bg = c.red, bold = true },
    MiniHipatternsHack = { fg = c.bg, bg = c.orange, bold = true },
    MiniHipatternsNote = { fg = c.bg, bg = c.cyan, bold = true },
    MiniDiffSignAdd = { fg = c.green },
    MiniDiffSignChange = { fg = c.yellow },
    MiniDiffSignDelete = { fg = c.red },
    MiniJump = { fg = c.bg, bg = c.orange },
    MiniClueTitle = { fg = c.blue, bold = true },
    MiniNotifyNormal = { fg = c.fg, bg = float },
    MiniNotifyBorder = { fg = border, bg = float },
  }
end

return M
