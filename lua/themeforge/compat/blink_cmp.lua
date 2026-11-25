local M = {}

local KINDS = {
  Text = "fg2", Method = "blue", Function = "blue", Constructor = "yellow", Field = "cyan",
  Variable = "cyan", Class = "yellow", Interface = "yellow", Module = "orange", Property = "cyan",
  Unit = "orange", Value = "orange", Enum = "yellow", Keyword = "purple", Snippet = "green",
  Color = "red", File = "fg", Reference = "red", Folder = "blue", EnumMember = "orange",
  Constant = "orange", Struct = "yellow", Event = "purple", Operator = "fg2", TypeParameter = "yellow",
}

function M.groups(c)
  local float = c.bg2 or c.bg
  local border = c.bg3 or c.comment
  local g = {
    BlinkCmpMenu = { fg = c.fg, bg = float },
    BlinkCmpMenuBorder = { fg = border, bg = float },
    BlinkCmpMenuSelection = { bg = c.selection or c.bg3, bold = true },
    BlinkCmpScrollBarThumb = { bg = border },
    BlinkCmpScrollBarGutter = { bg = float },
    BlinkCmpLabel = { fg = c.fg },
    BlinkCmpLabelDeprecated = { fg = c.comment, strikethrough = true },
    BlinkCmpLabelMatch = { fg = c.blue, bold = true },
    BlinkCmpLabelDetail = { fg = c.comment },
    BlinkCmpLabelDescription = { fg = c.comment },
    BlinkCmpKind = { fg = c.purple },
    BlinkCmpSource = { fg = c.comment },
    BlinkCmpGhostText = { fg = c.comment, italic = true },
    BlinkCmpDoc = { fg = c.fg, bg = float },
    BlinkCmpDocBorder = { fg = border, bg = float },
    BlinkCmpDocSeparator = { fg = border, bg = float },
    BlinkCmpDocCursorLine = { bg = c.bg3 },
    BlinkCmpSignatureHelp = { fg = c.fg, bg = float },
    BlinkCmpSignatureHelpBorder = { fg = border, bg = float },
    BlinkCmpSignatureHelpActiveParameter = { fg = c.orange, bold = true },
  }
  for kind, key in pairs(KINDS) do
    g["BlinkCmpKind" .. kind] = { fg = c[key] or c.fg }
  end
  return g
end

return M
