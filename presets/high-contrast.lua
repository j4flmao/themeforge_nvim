-- High-contrast preset: clear code and UI separation.
require("themeforge").apply({
  theme = "github-dark",
  colors = { fg = "#f2f4f8", fg2 = "#c5cfdf", comment = "#9aa8bd" },
  ui = { bold_functions = true, bold_cursor = true, transparency = false },
})
