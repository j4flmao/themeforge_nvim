# ThemeForge.nvim

A visual theme workbench for Neovim — discover, tune, check readability, and save 15 bundled dark themes.

---

## Features

- 15 bundled dark themes (no internet required)
- Live preview with color blending sliders
- UI customization (transparency, bold, italic, cursor styling)
- Readability feedback for text and comments while tuning a palette
- Generate a custom dark theme from an image
- Diagnose contrast and plugin highlight coverage
- Save/load theme configurations
- Compatible with popular plugins (nvim-tree, telescope, lualine, etc.)

---

## Requirements

- Neovim >= 0.9.0
- Pure Lua core with no external image-processing dependency

---

## Installation

### lazy.nvim

```lua
{
  "yourhandle/themeforge.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("themeforge").setup({
      default_theme = "tokyonight-storm",
    })
  end,
}
```

---

## Configuration

```lua
require("themeforge").setup({
  default_theme    = "tokyonight-storm",
  restore_on_start = true,
  config_paths     = {},
  default_save_path = nil,
  panel = {
    width_ratio  = 0.82,
    height_ratio = 0.82,
    border     = "rounded",
  },
  compat          = "auto",
  cache_path      = vim.fn.stdpath("data") .. "/themeforge/last.json",
  autosave_cache  = true,
  ui = {
    transparency    = false,
    italic_keywords = false,
    bold_functions = false,
    cursorline     = true,
    underline_diag = true,
    bold_cursor   = true,
    signcolumn    = "yes",
    statusline   = "full",
  },
})
```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `default_theme` | string | `"tokyonight-storm"` | Theme to use on startup |
| `restore_on_start` | boolean | `true` | Restore last used theme on startup |
| `panel.width_ratio` | number | `0.82` | Panel width (0-1) |
| `panel.height_ratio` | number | `0.82` | Panel height (0-1) |
| `panel.border` | string | `"rounded"` | Window border style |
| `ui.transparency` | boolean | `false` | Enable transparent backgrounds |
| `ui.italic_keywords` | boolean | `false` | Italic for keywords |
| `ui.bold_functions` | boolean | `false` | Bold for functions |
| `ui.cursorline` | boolean | `true` | Show cursor line |
| `ui.underline_diag` | boolean | `true` | Underline diagnostics |
| `ui.bold_cursor` | boolean | `true` | Bold cursor/selection |
| `ui.signcolumn` | string | `"yes"` | Signcolumn: yes/number/no |
| `ui.statusline` | string | `"full"` | Statusline style |

---

## Commands

| Command | Description |
|---------|------------|
| `:ThemeForge` | Open UI panel |
| `:ThemeForge open` | Open UI panel |
| `:ThemeForge close` | Close panel |
| `:ThemeForge apply [theme]` | Apply theme to session |
| `:ThemeForge save [file]` | Save to config file |
| `:ThemeForge reset` | Reset all overrides |
| `:ThemeForge list` | List bundled themes |
| `:ThemeForge status` | Show active theme |
| `:ThemeForge save-blend [name]` | Save the current palette blend |
| `:ThemeForge doctor` | Check contrast and integrations |

---

## Keybindings

Inside the ThemeForge panel:

| Key | Action |
|-----|-------|
| `Tab` | Focus next region |
| `S-Tab` | Focus previous region |
| `j` / `k` | Navigate list |
| `Enter` | Select / confirm |
| `Space` | Toggle option |
| `h` / `l` | Slider adjust (5%) |
| `H` / `L` | Slider adjust (10%) |
| `0` | Reset slider to 0 |
| `a` | Apply theme |
| `s` | Save to config |
| `r` | Reset overrides |
| `/` | Search themes |
| `q` / `Esc` | Close panel |
| `?` | Show help |

Theme changes are previewed live. Press `a` or Apply Theme to commit them; closing the panel without applying restores the previous theme.

---

## Bundled Themes (15)

| ID | Name |
|----|------|
| `tokyonight-storm` | TokyoNight Storm |
| `tokyonight-night` | TokyoNight Night |
| `catppuccin-mocha` | Catppuccin Mocha |
| `gruvbox-dark` | Gruvbox Dark |
| `nord` | Nord |
| `rose-pine` | Rosé Pine |
| `kanagawa-wave` | Kanagawa Wave |
| `dracula` | Dracula |
| `onedark` | One Dark Pro |
| `solarized-dark` | Solarized Dark |
| `nightfox` | Nightfox |
| `everforest` | Everforest Dark |
| `material-darker` | Material Darker |
| `oxocarbon` | Oxocarbon |
| `github-dark` | GitHub Dark |

---

## API

```lua
local tf = require("themeforge")

-- Initialize
tf.setup({ default_theme = "tokyonight-storm" })

-- Open UI
tf.open()
tf.close()

-- Apply theme
tf.apply("tokyonight-night")
tf.apply({ theme = "github-dark", ui = { bold_cursor = true } })

-- Save/load
tf.save("~/.config/nvim/themes.lua")
tf.reset()
tf.doctor()
```


---

## Compatible Plugins

ThemeForge auto-applies highlights for:

- nvim-cmp
- nvim-tree / neo-tree
- telescope
- gitsigns
- indent-blankline
- which-key
- lualine
- bufferline
