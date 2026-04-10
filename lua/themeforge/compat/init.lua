local M = {}

local modules = {
  { name = "lualine",           check = "lualine" },
  { name = "nvim_tree",         check = "nvim-tree" },
  { name = "neo_tree",          check = "neo-tree" },
  { name = "telescope",         check = "telescope" },
  { name = "nvim_cmp",          check = "cmp" },
  { name = "gitsigns",          check = "gitsigns" },
  { name = "bufferline",        check = "bufferline" },
  { name = "indent_blankline",  check = "ibl" },
  { name = "which_key",         check = "which-key" },
}

local function is_loaded(check)
  for key, _ in pairs(package.loaded) do
    if key:find(check, 1, true) then
      return true
    end
  end
  return false
end

function M.apply(colors, mode)
  mode = mode or "auto"

  for _, mod in ipairs(modules) do
    local should_load = false
    if mode == "all" then
      should_load = true
    elseif mode == "auto" then
      should_load = is_loaded(mod.check)
    elseif type(mode) == "table" then
      for _, name in ipairs(mode) do
        if name == mod.name or name == mod.check then
          should_load = true
          break
        end
      end
    end

    if should_load then
      local ok, compat_mod = pcall(require, "themeforge.compat." .. mod.name)
      if ok and compat_mod.groups then
        local groups = compat_mod.groups(colors)
        for group, hl in pairs(groups) do
          pcall(vim.api.nvim_set_hl, 0, group, hl)
        end
      end
    end
  end
end

return M
