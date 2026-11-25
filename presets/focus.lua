-- Focus preset: quiet UI with restrained color intensity.
require("themeforge").apply({
  theme = "tokyonight-night",
  mix = { saturation = 35, brightness = 48, opacity = 100 },
  ui = {
    cursorline = false,
    bold_functions = false,
    italic_keywords = false,
    transparency = false,
  },
})
