-- Smaller integrations grouped in one module: trouble, noice, flash, fzf-lua.
local M = {}

function M.trouble(c)
  return {
    TroubleNormal = { fg = c.fg, bg = c.bg2 or c.bg },
    TroubleNormalNC = { fg = c.fg, bg = c.bg2 or c.bg },
    TroubleText = { fg = c.fg },
    TroubleCount = { fg = c.purple, bg = c.bg3, bold = true },
  }
end

function M.noice(c)
  local float = c.bg2 or c.bg
  return {
    NoiceCmdlinePopup = { fg = c.fg, bg = float },
    NoiceCmdlinePopupBorder = { fg = c.blue, bg = float },
    NoiceCmdlinePopupTitle = { fg = c.blue, bold = true },
    NoiceCmdlineIcon = { fg = c.cyan },
    NoicePopupBorder = { fg = c.bg3 or c.comment, bg = float },
    NoiceMini = { fg = c.fg2 or c.fg, bg = float },
  }
end

function M.flash(c)
  return {
    FlashLabel = { fg = c.bg, bg = c.red or c.orange, bold = true },
    FlashMatch = { fg = c.fg, bg = c.selection or c.bg3 },
    FlashCurrent = { fg = c.bg, bg = c.green, bold = true },
    FlashBackdrop = { fg = c.comment },
  }
end

function M.fzf_lua(c)
  local float = c.bg2 or c.bg
  return {
    FzfLuaNormal = { fg = c.fg, bg = float },
    FzfLuaBorder = { fg = c.bg3 or c.comment, bg = float },
    FzfLuaTitle = { fg = c.blue, bold = true },
    FzfLuaCursorLine = { bg = c.selection or c.bg3 },
    FzfLuaPreviewNormal = { fg = c.fg, bg = float },
    FzfLuaPreviewBorder = { fg = c.bg3 or c.comment, bg = float },
  }
end

return M
