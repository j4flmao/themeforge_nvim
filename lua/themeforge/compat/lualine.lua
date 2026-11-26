local M = {}

function M.groups(c)
  return {
    lualine_a_normal   = { fg = c.bg, bg = c.blue, bold = true },
    lualine_b_normal   = { fg = c.fg, bg = c.bg3 },
    lualine_c_normal   = { fg = c.fg2, bg = c.bg2 },
    lualine_a_insert   = { fg = c.bg, bg = c.green, bold = true },
    lualine_b_insert   = { fg = c.fg, bg = c.bg3 },
    lualine_c_insert   = { fg = c.fg2, bg = c.bg2 },
    lualine_a_visual   = { fg = c.bg, bg = c.purple, bold = true },
    lualine_b_visual   = { fg = c.fg, bg = c.bg3 },
    lualine_c_visual   = { fg = c.fg2, bg = c.bg2 },
    lualine_a_replace  = { fg = c.bg, bg = c.red, bold = true },
    lualine_b_replace  = { fg = c.fg, bg = c.bg3 },
    lualine_c_replace  = { fg = c.fg2, bg = c.bg2 },
    lualine_a_command  = { fg = c.bg, bg = c.yellow, bold = true },
    lualine_b_command  = { fg = c.fg, bg = c.bg3 },
    lualine_c_command  = { fg = c.fg2, bg = c.bg2 },
    lualine_a_inactive = { fg = c.comment, bg = c.bg2 },
    lualine_b_inactive = { fg = c.comment, bg = c.bg2 },
    lualine_c_inactive = { fg = c.comment, bg = c.bg2 },
  }
end

--- A lualine theme table built from the resolved palette. Shipped as
--- lua/lualine/themes/themeforge.lua, which lualine's "auto" theme loads
--- because ThemeForge sets vim.g.colors_name = "themeforge".
function M.theme(c)
  local bar = c.bg2 or c.bg
  local mid = c.bg3 or bar
  local function mode(accent)
    return {
      a = { fg = c.bg, bg = accent or c.blue, gui = "bold" },
      b = { fg = c.fg, bg = mid },
      c = { fg = c.fg2 or c.fg, bg = bar },
    }
  end
  return {
    normal = mode(c.blue),
    insert = mode(c.green),
    visual = mode(c.purple),
    replace = mode(c.red),
    command = mode(c.yellow or c.orange),
    terminal = mode(c.cyan),
    inactive = {
      a = { fg = c.comment, bg = bar, gui = "bold" },
      b = { fg = c.comment, bg = bar },
      c = { fg = c.comment, bg = bar },
    },
  }
end

return M
