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
- [Usage guide](#usage-guide)
- [Commands](#commands)
- [Keybindings](#keybindings)
- [Configuration](#configuration)
- [LSP semantic tokens](#lsp-semantic-tokens)
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
- **Custom LSP semantic tokens**: give `parameter`, `property`, `method`, `interface`, `enumMember`, `readonly`, `deprecated`, … their own color (palette key or hex) and bold / italic / underline / strikethrough, previewed live
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



https://github.com/user-attachments/assets/e14748e9-213f-4f9e-8297-e66412f68102



The video walks through every feature: help, live preview, favorites, search,
surprise theme, blend sliders with undo, UI toggles, custom hex colors,
**custom LSP semantic tokens**, **Apply** → **Save to config**, the doctor,
blends, profiles and export.

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

## Usage guide

### 1. Open the workbench

```vim
:ThemeForge
```

The panel has three panes. Move between them with `Tab` / `S-Tab`:

| Pane | What it is for |
|------|----------------|
| **Themes** (left) | Favorites, recent themes and the full list, each with a palette swatch |
| **Preview** (middle) | Code samples (including LSP tokens) drawn with the current settings |
| **Controls** (right) | Actions, readability, blend sliders, UI options, colors, LSP tokens, plugins |

The bar at the bottom shows the status (`PREVIEW` / `APPLIED` / `SAVED`) and the main keys.
Press `?` for every shortcut, `q` to close.

### 2. Pick a theme

- `j` / `k` move, `Enter` previews the theme over your whole editor.
- `/` searches by name or mood tag (`calm`, `warm`, `high-contrast`…), `n` picks a surprise theme.
- `f` adds the theme under the cursor to **Favorites**.

Nothing is kept until you apply: closing with `q` restores the previous theme.

### 3. Tune it

In the Controls pane (`]]` / `[[` jump between its sections):

- **Blend sliders**: `h` / `l` (±5), `H` / `L` (±10), `0` resets. Tint toward a hue, warm it up,
  change saturation or brightness. The background is protected and text never loses contrast.
- **UI options**: `Enter` toggles italic keywords, bold functions, transparency, cursorline…
- **Color tokens**: `Enter` on a row, type a hex code (`#ff79c6`), or `clear` to reset it.
- **LSP tokens**: see [LSP semantic tokens](#lsp-semantic-tokens).
- `u` / `Ctrl-r` undo and redo any change.

### 4. Apply, save, export

| Key | Result |
|-----|--------|
| `a` | **Apply**: makes it your active theme, restored on the next start |
| `s` | **Save to config**: writes a `require("themeforge").apply({...})` block into a config file you choose |
| `e` | **Export**: writes `colors/<name>.lua`, a standalone scheme for `:colorscheme <name>` |
| `b` / `p` | Save / load a named blend to reuse later |
| `P` | Apply a quick profile (focus, high-contrast, low-distraction, monochrome) |

### 5. Check readability

Press `d` (or run `:ThemeForge doctor`). It reports:

- contrast for text, comments, selection and every customized LSP token (WCAG 2, plus APCA as a hint);
- color-blind safety of diff and diagnostic colors;
- whether your customized LSP token colors are really what is drawn in your open buffers;
- broken highlight links.

### Recommended keymaps

```lua
vim.keymap.set("n", "<leader>Tt", "<cmd>ThemeForge<cr>",        { desc = "ThemeForge: open" })
vim.keymap.set("n", "<leader>Tk", "<cmd>ThemeForge token<cr>",  { desc = "ThemeForge: style LSP token under cursor" })
vim.keymap.set("n", "<leader>Td", "<cmd>ThemeForge doctor<cr>", { desc = "ThemeForge: doctor" })
vim.keymap.set("n", "<leader>Ts", "<cmd>ThemeForge save<cr>",   { desc = "ThemeForge: save to config" })
```

### Troubleshooting

| Problem | Fix |
|---------|-----|
| Colors look wrong or washed out | Your terminal needs true color: `vim.o.termguicolors = true` |
| My theme is gone after restart | You previewed but did not apply: press `a` (or `s` to save it in your config) |
| An LSP token color does not change | Run `:ThemeForge doctor`; if it says *OVERRIDDEN*, put the cursor on that word and run `:ThemeForge token` to style the exact group |
| No LSP TOKENS marked ● | The server sends no semantic tokens (pyright) or they are off (gopls: `semanticTokens = true`) |
| A plugin keeps old colors | `:ThemeForge compat all`, or check the **PLUGINS** list in the panel |

## Commands

| Command | Description |
|---------|-------------|
| `:ThemeForge` / `:ThemeForge open` | Open the theme panel |
| `:ThemeForge close` | Close the panel |
| `:ThemeForge apply [theme]` | Apply a theme directly |
| `:ThemeForge save [file]` | Save the configuration to a file |
| `:ThemeForge copy` | Copy the configuration to the clipboard |
| `:ThemeForge export [name]` | Write a standalone `colors/<name>.lua` |
| `:ThemeForge token` | Style the LSP semantic token under the cursor |
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
| `B` / `I` / `U` / `S` | LSP token: toggle bold / italic / underline / strikethrough |
| `X` | LSP token: reset to the theme default |
| `]]` / `[[` | Jump to the next / previous section (e.g. straight to LSP TOKENS) |
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

## LSP semantic tokens

Language servers tag code with semantic tokens (`@lsp.type.parameter`,
`@lsp.type.property`, `@lsp.mod.readonly`, …). ThemeForge lets you style them on
top of any theme.

**In the panel:** press `]]` in the Controls pane until you reach **LSP TOKENS**.

```
 LSP TOKENS                         5 customized
 rust_analyzer · gopls   ● in your code
 ⏎ colour  B I U S style  X reset
 TYPES
 ██ ● parameter     shapes       B [I] U S *
 ██ ● struct        HashMap     [B] I  U S *
 ██ ● interface     Shape        B  I [U]S *
 ...
 MODIFIERS  style only
 ░░ ● deprecated    old_total    B  I  U[S]*
```

- The swatch is the token's current color; **●** means the token appears in your open code.
- The second column is a **real word from your code**, drawn exactly as it will look.
- `B I U S` badges show which styles are on; `*` and a highlighted name mark a customized token.
- Tokens used by your servers come first, followed by the server-specific ones
  (rust-analyzer: `lifetime`, `selfKeyword`, `builtinType`, `mutable`, `trait`…).

| Key | Action |
|-----|--------|
| `Enter` | Pick a color: a palette key (follows the theme and blend sliders) or a custom `#hex`; the current one is marked ● |
| `B` / `I` / `U` / `S` | Toggle bold / italic / underline / strikethrough |
| `X` | Reset the token to the theme default |

The preview pane has an LSP sample that uses the real token groups, so every change shows immediately.
Customizations are part of undo/redo, **Apply**, **Save to config**, **Export** and blends.

**Check that the colors are applied:** `:ThemeForge doctor` has a section
*LSP tokens in your open buffers*. For every customized token it counts the places in your
code drawn with your color, e.g. `type.parameter 34/34 OK`. When a more specific group wins
somewhere it says `OVERRIDDEN by @lsp.typemod… (e.g. "max")`; style that word with
`:ThemeForge token`. Only lines that have been on screen are counted.

**From your code:** put the cursor on any word and run `:ThemeForge token`.
It lists the semantic tokens under the cursor, most specific first
(`@lsp.typemod.parameter.declaration`, `@lsp.mod.declaration`,
`@lsp.type.parameter`), and opens a menu to set the color, toggle styles or
reset. Changes apply immediately; run `:ThemeForge save` to keep them.

```lua
vim.keymap.set("n", "<leader>Tk", "<cmd>ThemeForge token<cr>", { desc = "ThemeForge: style token under cursor" })
```

**In code:**

```lua
require("themeforge").apply({
  lsp_tokens = {
    ["@lsp.type.parameter"]  = { fg = "orange", italic = true },  -- palette key
    ["@lsp.type.interface"]  = { fg = "#7dcfff", bold = true },   -- hex
    ["@lsp.type.property"]   = { underline = true },              -- style only
    ["@lsp.mod.deprecated"]  = { strikethrough = true },
    ["@lsp.mod.readonly"]    = { italic = true },
  },
})
```

- `fg`: a palette key (`purple`, `blue`, `cyan`, `green`, `yellow`, `orange`, `red`, `fg`, `fg2`, `comment`) or `#rrggbb`
- `bold`, `italic`, `underline`, `strikethrough`: booleans
- Names can be written as `"@lsp.type.parameter"`, `"lsp.type.parameter"` or `"type.parameter"`
- Token types without `fg` keep a sensible default color; modifiers without `fg` only add the style
- Customizations are kept when you switch themes; palette keys re-resolve to the new theme's colors

Panel tokens: `class`, `interface`, `struct`, `enum`, `enumMember`, `type`, `typeParameter`,
`namespace`, `parameter`, `variable`, `property`, `function`, `method`, `macro`, `decorator`,
and the modifiers `readonly`, `static`, `async`, `deprecated`, `defaultLibrary`, plus whatever
your running servers use. Any other `@lsp.*` group (including `@lsp.typemod.*` and
language-specific ones like `@lsp.type.parameter.rust`) can be set through `lsp_tokens` in code.

**Good to know**

- Each server sends its own tokens. Tested with rust-analyzer, gopls, vtsls, clangd and
  lua-language-server: every customized token was drawn with its color (195/195 positions). pyright sends no semantic tokens (basedpyright does), and gopls needs
  `settings = { gopls = { semanticTokens = true } }`.
- More specific groups win: `@lsp.typemod.function.defaultLibrary` (priority 127) beats
  `@lsp.mod.*` (126), which beats `@lsp.type.function` (125). Neovim links some `typemod`
  groups by default (for example built-in functions to `@function.builtin`), so styling
  `function` does not change `Math.max`. Use `:ThemeForge token` on that word to style the exact group.
- A token with only a style (say, just italic) keeps the color it already had in the current theme.
- Servers name some concepts differently: gopls sends interfaces and structs as `type` +
  modifier (`@lsp.typemod.type.interface`). Styling `interface` / `struct` also styles those
  equivalents unless you customize them yourself.

## API & events

```lua
local tf = require("themeforge")

tf.open()
tf.close()

tf.apply("tokyonight-night")
tf.apply({ theme = "github-dark", ui = { bold_cursor = true } })
tf.apply({ theme = "github-dark", colors = { purple = "#cba6f7" } })
tf.apply({ theme = "nord", mix = { warm = 20, brightness = 60 } })
tf.apply({ lsp_tokens = { ["@lsp.type.parameter"] = { fg = "orange", italic = true } } })

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

nvim --headless -u NONE --cmd 'set rtp^=.' \
  -c 'runtime plugin/themeforge.lua' \
  -c 'luafile tests/lsp_tokens_spec.lua' -c 'qa!'
```

CI runs all three suites plus a Lua syntax check on every push and pull request.
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
