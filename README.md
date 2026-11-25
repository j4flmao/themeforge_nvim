<h1 align="center">ThemeForge.nvim</h1>

<p align="center">
  <b>A visual theme workbench for Neovim</b><br>
  Preview, tune, check readability, and save 15 bundled dark themes, all from one panel.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Neovim-%E2%89%A5_0.9.0-57A143?style=flat&logo=neovim&logoColor=white" alt="Neovim >= 0.9">
  <img src="https://img.shields.io/badge/Made_with-Lua-2C2D72?style=flat&logo=lua&logoColor=white" alt="Lua">
  <a href="https://github.com/j4flmao/themeforge_nvim/actions/workflows/ci.yml">
    <img src="https://github.com/j4flmao/themeforge_nvim/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
  <a href="https://github.com/j4flmao/themeforge_nvim/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/j4flmao/themeforge_nvim?style=flat" alt="License">
  </a>
  <a href="https://buymeacoffee.com/j4flmaon">
    <img src="https://img.shields.io/badge/Buy_me_a_coffee-FFDD00?style=flat&logo=buymeacoffee&logoColor=black" alt="Buy me a coffee">
  </a>
</p>


---

## Contents

- [Features](#features)
- [Demo](#demo)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Commands](#commands)
- [Keybindings](#keybindings)
- [Configuration](#configuration)
- [API & events](#api--events)
- [Bundled themes](#bundled-themes)
- [Plugin integrations](#plugin-integrations)
- [Development](#development)
- [Support](#support)
- [License](#license)

## Features

**Theme workbench**
- 15 bundled dark themes, no downloads required
- Live preview across the whole editor: browse with `j`/`k`, preview with `Enter`
- Favorites, recent themes, search by name or mood tag, and a surprise theme
- Responsive panel: three columns on wide screens, two on medium, stacked on narrow, rebuilt automatically on resize
- Always-visible action bar with a `PREVIEW → APPLIED → SAVED` status badge

**Color tuning**
- Blend sliders: Purple, Blue, Green, Cyan, Pink, Orange, Warm, Saturation, Brightness, Opacity
- Perceptual **OKLCH** color engine: the background is protected from washing out, and text never drops below its original contrast
- Edit any semantic color (keyword, function, string, …) by typing a hex code
- UI options: transparency, italic keywords, bold functions, cursorline, diagnostics underline, statusline and signcolumn styles
- Undo / redo for every change, named blends, and quick profiles (focus, high-contrast, low-distraction, monochrome)

**Readability doctor**
- WCAG 2 contrast per role (pass/fail) with APCA Lc as an advisory number
- Color-blind safety check (protan / deutan / tritan) for diff and diagnostic colors
- Detects broken highlight links

**Output**
- **Save** writes a managed config block into your Neovim config
- **Export** creates a standalone `colors/<name>.lua` that works with `:colorscheme`
- Defines the highlight groups added in Neovim 0.10 – 0.12 and key treesitter captures
- Sets `terminal_color_0..15` and refreshes lualine automatically

## Demo

https://github.com/user-attachments/assets/4b297170-ea7b-45ef-8cc7-998fbc2cd829

The video walks through every feature: help, live preview, favorites, search,
surprise theme, blend sliders with undo, UI toggles, custom hex colors,
**Apply** → **Save to config**, the doctor, blends, profiles and export.

### Preview → Apply → Save

| Step | Key | What happens | Status bar |
|------|-----|--------------|------------|
| Preview | `Enter`, sliders, toggles | The whole editor changes live, nothing is kept yet | `PREVIEW` |
| Apply | `a` or **✔ Apply theme** | Becomes the active theme and is restored on the next start | `APPLIED` |
| Save | `s` or **⤓ Save to config** | Writes a managed `require("themeforge").apply({...})` block into your config | `SAVED` |
| Export | `e` or **⇪ Export colorscheme** | Writes a standalone `colors/<name>.lua` | |

Closing the panel with `q` without applying restores the previous theme.

## Requirements

- Neovim **0.9.0** or newer (0.10+ recommended)
- A terminal with true-color support (`termguicolors`)
- No external dependencies: pure Lua

## Installation

Tagged releases are packaged automatically by GitHub Actions. The `main` branch
contains the latest development version.

### lazy.nvim

```lua
-- lua/plugins/themeforge.lua
return {
  "j4flmao/themeforge_nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("themeforge").setup({
      default_theme = "tokyonight-storm",
    })
  end,
}
```

### packer.nvim

```lua
use({
  "j4flmao/themeforge_nvim",
  config = function()
    require("themeforge").setup({ default_theme = "tokyonight-storm" })
  end,
})
```

### Manual

```bash
git clone https://github.com/j4flmao/themeforge_nvim \
  ~/.local/share/nvim/site/pack/vendor/start/themeforge_nvim
```

Then add to your `init.lua`:

```lua
require("themeforge").setup({ default_theme = "tokyonight-storm" })
```

## Quick start

```vim
:ThemeForge
```

1. Move through the theme list with `j` / `k` and press `Enter` to preview.
2. Press `Tab` to reach the controls: tune sliders with `h` / `l`, toggle options with `Enter`.
3. Press `a` to apply, then `s` to save it to your config.
4. Press `d` at any time to check readability.

Press `?` inside the panel for every shortcut.

## Commands

| Command | Description |
|---------|-------------|
| `:ThemeForge` / `:ThemeForge open` | Open the theme panel |
| `:ThemeForge close` | Close the panel |
| `:ThemeForge apply [theme]` | Apply a theme directly |
| `:ThemeForge save [file]` | Save the configuration to a file |
| `:ThemeForge copy` | Copy the configuration to the clipboard |
| `:ThemeForge export [name]` | Write a standalone `colors/<name>.lua` |
| `:ThemeForge reset` | Reset all overrides |
| `:ThemeForge list` | List bundled themes |
| `:ThemeForge status` | Show the active theme |
| `:ThemeForge save-blend [name]` | Save the current palette blend |
| `:ThemeForge load-blend [name]` | Load a saved blend |
| `:ThemeForge list-blends` | List saved blends |
| `:ThemeForge profile [name]` | Apply a built-in profile |
| `:ThemeForge random` | Apply a random theme |
| `:ThemeForge compat [auto\|all\|none]` | Set the plugin compatibility mode |
| `:ThemeForge doctor` | Contrast, color-blind safety, broken links, integrations |

## Keybindings

Inside the panel:

| Key | Action |
|-----|--------|
| `Tab` / `S-Tab` | Next / previous pane |
| `j` / `k` | Move (theme list skips headers) |
| `Enter` | Preview theme, toggle option, edit color, press button |
| `Space` | Toggle option |
| `h` / `l` | Slider −5 / +5 |
| `H` / `L` | Slider −10 / +10 |
| `0` | Reset slider |
| `a` | Apply theme |
| `s` | Save to config |
| `e` | Export colorscheme |
| `d` | Run the doctor |
| `u` / `Ctrl-r` | Undo / redo |
| `r` | Reset overrides |
| `/` | Search themes |
| `f` | Toggle favorite |
| `n` | Surprise theme |
| `b` / `p` | Save / load a blend |
| `P` | Apply a profile |
| `y` | Copy configuration |
| `i` | Show theme details |
| `c` | Cycle plugin compatibility mode |
| `?` | Help |
| `q` / `Esc` | Close the panel |

## Configuration

Defaults:

```lua
require("themeforge").setup({
  default_theme    = "tokyonight-storm",
  restore_on_start = true,
  compat           = "auto",       -- "auto" | "all" | "none" | { "telescope", ... }
  export_dir       = nil,          -- defaults to stdpath("config") .. "/colors"

  panel = {
    width_ratio  = 0.82,
    height_ratio = 0.82,
    border       = "rounded",
  },

  ui = {
    transparency    = false,
    italic_keywords = false,
    bold_functions  = false,
    cursorline      = true,
    underline_diag  = true,
    bold_cursor     = true,
    signcolumn      = "yes",       -- "yes" | "number" | "no"
    statusline      = "full",      -- "minimal" | "full" | "arrow"
  },
})
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `default_theme` | string | `"tokyonight-storm"` | Theme used on first start |
| `restore_on_start` | boolean | `true` | Restore the last applied theme |
| `compat` | string \| table | `"auto"` | Plugin integrations to theme |
| `export_dir` | string | `stdpath("config")/colors` | Where `:ThemeForge export` writes |
| `panel.width_ratio` | number | `0.82` | Panel width (0–1) |
| `panel.height_ratio` | number | `0.82` | Panel height (0–1) |
| `panel.border` | string | `"rounded"` | Border style |
| `ui.transparency` | boolean | `false` | Transparent backgrounds |
| `ui.italic_keywords` | boolean | `false` | Italic keywords |
| `ui.bold_functions` | boolean | `false` | Bold functions |
| `ui.cursorline` | boolean | `true` | Highlight the cursor line |
| `ui.underline_diag` | boolean | `true` | Underline diagnostics |
| `ui.bold_cursor` | boolean | `true` | Bold cursor line and selection |
| `ui.signcolumn` | string | `"yes"` | Signcolumn style |
| `ui.statusline` | string | `"full"` | Statusline style |

Ready-to-copy configurations live in [`presets/`](presets/):
[`focus.lua`](presets/focus.lua), [`high-contrast.lua`](presets/high-contrast.lua)
and [`monochrome.lua`](presets/monochrome.lua).

## API & events

```lua
local tf = require("themeforge")

tf.open()
tf.close()

tf.apply("tokyonight-night")
tf.apply({ theme = "github-dark", ui = { bold_cursor = true } })
tf.apply({ theme = "github-dark", colors = { purple = "#cba6f7" } })
tf.apply({ theme = "nord", mix = { warm = 20, brightness = 60 } })

tf.apply_profile("high-contrast")
tf.save("~/.config/nvim/lua/theme.lua")
tf.export("my-theme")            -- writes colors/my-theme.lua
tf.reset()
tf.doctor()
```

```lua
-- Fired after every apply or preview
vim.api.nvim_create_autocmd("User", {
  pattern = "ThemeForgeApplied",
  callback = function(ev)
    -- ev.data.theme, ev.data.colors (resolved palette), ev.data.preview
  end,
})

-- Fired after the configuration is saved to a file
vim.api.nvim_create_autocmd("User", {
  pattern = "ThemeForgeSaved",
  callback = function(ev) print("saved to " .. ev.data.path) end,
})
```

## Bundled themes

| ID | Name | ID | Name |
|----|------|----|------|
| `tokyonight-storm` | TokyoNight Storm | `onedark` | One Dark Pro |
| `tokyonight-night` | TokyoNight Night | `solarized-dark` | Solarized Dark |
| `catppuccin-mocha` | Catppuccin Mocha | `nightfox` | Nightfox |
| `gruvbox-dark` | Gruvbox Dark | `everforest` | Everforest Dark |
| `nord` | Nord | `material-darker` | Material Darker |
| `rose-pine` | Rosé Pine | `oxocarbon` | Oxocarbon |
| `kanagawa-wave` | Kanagawa Wave | `github-dark` | GitHub Dark |
| `dracula` | Dracula | | |

## Plugin integrations

Highlights are applied automatically for plugins that are loaded or installed
(detected through lazy.nvim, `vim.pack`, or the runtimepath):

| Completion | Navigation | UI | Editing |
|------------|------------|----|---------|
| nvim-cmp | nvim-tree / neo-tree | lualine / bufferline | gitsigns |
| blink.cmp | telescope | snacks.nvim | indent-blankline |
| | fzf-lua | noice / which-key | flash |
| | trouble | mini.nvim | render-markdown |

Use `:ThemeForge compat all` to force every integration, or `none` to disable them.

## Development

Run the test suites headlessly:

```bash
nvim --headless -u NONE --cmd 'set rtp^=.' \
  -c 'runtime plugin/themeforge.lua' \
  -c 'luafile tests/smoke.lua' -c 'qa!'

nvim --headless -u NONE --cmd 'set rtp^=.' \
  -c 'runtime plugin/themeforge.lua' \
  -c 'luafile tests/upgrade_spec.lua' -c 'qa!'
```

CI runs both suites plus a Lua syntax check on every push and pull request.
See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution workflow.

## Support

If ThemeForge makes your editor nicer to look at, you can support its development:

<a href="https://buymeacoffee.com/j4flmaon">
  <img src="https://img.shields.io/badge/Buy_me_a_coffee-j4flmao-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black" alt="Buy me a coffee">
</a>

Bug reports and feature ideas are welcome in [Issues](https://github.com/j4flmao/themeforge_nvim/issues).

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/j4flmao">j4flmao</a>
</p>
