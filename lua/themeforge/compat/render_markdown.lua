local M = {}

function M.groups(c)
  local palette = require("themeforge.palette")
  local heads = { "blue", "purple", "green", "orange", "cyan", "red" }
  local g = {
    RenderMarkdownCode = { bg = c.bg2 },
    RenderMarkdownCodeInline = { fg = c.green, bg = c.bg2 },
    RenderMarkdownBullet = { fg = c.orange },
    RenderMarkdownQuote = { fg = c.comment, italic = true },
    RenderMarkdownDash = { fg = c.bg3 or c.comment },
    RenderMarkdownTableHead = { fg = c.blue, bold = true },
    RenderMarkdownTableRow = { fg = c.fg2 or c.fg },
    RenderMarkdownLink = { fg = c.cyan, underline = true },
  }
  for i, key in ipairs(heads) do
    local fg = c[key] or c.fg
    g["RenderMarkdownH" .. i] = { fg = fg, bold = true }
    g["RenderMarkdownH" .. i .. "Bg"] = { fg = fg, bg = palette.mix(c.bg, fg, 0.16), bold = true }
  end
  return g
end

return M
