-- ThemeForge.nvim — plugin registration
-- This file is auto-loaded by Neovim's plugin system

if vim.g.loaded_themeforge then
  return
end
vim.g.loaded_themeforge = true

-- Register user commands
vim.api.nvim_create_user_command("ThemeForge", function(opts)
  local args = opts.fargs
  local subcmd = args[1]

  if not subcmd or subcmd == "open" then
    require("themeforge").open()

  elseif subcmd == "close" then
    require("themeforge").close()

  elseif subcmd == "apply" then
    local theme_id = args[2]
    if theme_id then
      require("themeforge").apply(theme_id)
    else
      require("themeforge").apply()
    end

  elseif subcmd == "save" then
    local filepath = args[2]
    if filepath then
      require("themeforge").save(filepath)
    else
      require("themeforge").save()
    end

  elseif subcmd == "copy" then
    require("themeforge").copy()

  elseif subcmd == "reset" then
    require("themeforge").reset()

  elseif subcmd == "save-blend" then
    local name = args[2]
    require("themeforge").save_blend(name)

  elseif subcmd == "load-blend" then
    local name = args[2]
    require("themeforge").load_blend(name)

  elseif subcmd == "list-blends" then
    require("themeforge").list_blends()

  elseif subcmd == "profile" then
    require("themeforge").apply_profile(args[2])

  elseif subcmd == "random" then
    require("themeforge").random_theme()

  elseif subcmd == "compat" then
    require("themeforge").set_compat(args[2] or "auto")

  elseif subcmd == "token" then
    require("themeforge.ui.token_editor").at_cursor()

  elseif subcmd == "export" then
    require("themeforge").export(args[2])

  elseif subcmd == "doctor" then
    require("themeforge").doctor()

  elseif subcmd == "list" then
    local themes = require("themeforge.themes")
    local list = themes.list()
    local lines = {}
    for _, t in ipairs(list) do
      table.insert(lines, string.format("  %s  %-24s [%s]", t.dot and "●" or "○", t.id, t.variant))
    end
    vim.notify("ThemeForge bundled themes:\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)

  elseif subcmd == "status" then
    local state = require("themeforge.state")
    local msg = "Active theme: " .. (state.current.active_theme or "(none)")
    vim.notify("[ThemeForge] " .. msg, vim.log.levels.INFO)

  else
    vim.notify("[ThemeForge] Unknown command: " .. subcmd, vim.log.levels.ERROR)
  end
end, {
  nargs = "*",
  complete = function(arglead, cmdline, cursorpos)
    local subcmds = { "open", "close", "apply", "save", "copy", "reset", "save-blend", "load-blend", "list-blends", "profile", "random", "compat", "doctor", "export", "token", "list", "status" }
    local parts = vim.split(cmdline, "%s+")
    if #parts <= 2 then
      return vim.tbl_filter(function(s)
        return s:find(arglead, 1, true) == 1
      end, subcmds)
    end
    if parts[2] == "apply" then
      local themes = require("themeforge.themes")
      local ids = themes.ids()
      return vim.tbl_filter(function(s)
        return s:find(arglead, 1, true) == 1
      end, ids)
    end
    if parts[2] == "load-blend" then
      return require("themeforge").list_blends({ silent = true })
    end
    if parts[2] == "profile" then
      return require("themeforge").list_profiles()
    end
    if parts[2] == "compat" then
      return { "auto", "all", "none" }
    end
    return {}
  end,
})
