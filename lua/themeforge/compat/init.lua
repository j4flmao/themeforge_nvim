local M = {}

-- name: module under themeforge.compat (optionally "module.fn")
-- check: Lua module prefix the plugin exposes once loaded
-- plugin: plugin (repository) name used by lazy.nvim / vim.pack
M.modules = {
  { name = "lualine",          label = "Lualine",         check = "lualine",         plugin = "lualine.nvim" },
  { name = "nvim_tree",        label = "nvim-tree",       check = "nvim-tree",       plugin = "nvim-tree.lua" },
  { name = "neo_tree",         label = "Neo-tree",        check = "neo-tree",        plugin = "neo-tree.nvim" },
  { name = "telescope",        label = "Telescope",       check = "telescope",       plugin = "telescope.nvim" },
  { name = "nvim_cmp",         label = "nvim-cmp",        check = "cmp",             plugin = "nvim-cmp" },
  { name = "blink_cmp",        label = "blink.cmp",       check = "blink.cmp",       plugin = "blink.cmp" },
  { name = "gitsigns",         label = "Gitsigns",        check = "gitsigns",        plugin = "gitsigns.nvim" },
  { name = "bufferline",       label = "Bufferline",      check = "bufferline",      plugin = "bufferline.nvim" },
  { name = "indent_blankline", label = "indent-blankline", check = "ibl",            plugin = "indent-blankline.nvim" },
  { name = "which_key",        label = "which-key",       check = "which-key",       plugin = "which-key.nvim" },
  { name = "snacks",           label = "Snacks",          check = "snacks",          plugin = "snacks.nvim" },
  { name = "mini",             label = "mini.nvim",       check = "mini.",           plugin = "mini.nvim" },
  { name = "render_markdown",  label = "render-markdown", check = "render-markdown", plugin = "render-markdown.nvim" },
  { name = "extras.trouble",   label = "Trouble",         check = "trouble",         plugin = "trouble.nvim" },
  { name = "extras.noice",     label = "Noice",           check = "noice",           plugin = "noice.nvim" },
  { name = "extras.flash",     label = "Flash",           check = "flash",           plugin = "flash.nvim" },
  { name = "extras.fzf_lua",   label = "fzf-lua",         check = "fzf-lua",         plugin = "fzf-lua" },
}

local function loaded(check)
  for key, _ in pairs(package.loaded) do
    if key == check or key:sub(1, #check + 1) == check .. "." or (check:sub(-1) == "." and key:sub(1, #check) == check) then
      return true
    end
  end
  return false
end

-- Installed plugins known to the plugin manager (lazy.nvim, vim.pack), so
-- lazy-loaded plugins get highlights before they are first required.
local installed_cache
local function installed()
  if installed_cache then return installed_cache end
  local names = {}
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if ok and type(lazy_config.plugins) == "table" then
    for name, _ in pairs(lazy_config.plugins) do names[name] = true end
  end
  if vim.pack and vim.pack.get then
    local okp, packs = pcall(vim.pack.get)
    if okp and type(packs) == "table" then
      for _, p in ipairs(packs) do
        local name = p.spec and p.spec.name or p.name
        if name then names[name] = true end
      end
    end
  end
  installed_cache = names
  return names
end

local enabled_cache = {}

function M.reset_cache()
  installed_cache = nil
  enabled_cache = {}
end

local function on_runtimepath(check)
  local path = "lua/" .. check:gsub("%.$", ""):gsub("%.", "/")
  return #vim.api.nvim_get_runtime_file(path, false) > 0 or #vim.api.nvim_get_runtime_file(path .. ".lua", false) > 0
end

--- Whether a compat module should load for the given mode.
function M.is_enabled(mod, mode)
  mode = mode or "auto"
  if mode == "all" then return true end
  if type(mode) == "table" then
    for _, name in ipairs(mode) do
      if name == mod.name or name == mod.check or name == mod.plugin then return true end
    end
    return false
  end
  if enabled_cache[mod.name] == nil then
    enabled_cache[mod.name] = loaded(mod.check) or installed()[mod.plugin] == true or on_runtimepath(mod.check)
  end
  return enabled_cache[mod.name]
end

local function groups_for(mod, colors)
  local module_name, fn = mod.name:match("^([^.]+)%.(.+)$")
  local ok, compat_mod = pcall(require, "themeforge.compat." .. (module_name or mod.name))
  if not ok then return nil end
  if fn then
    return type(compat_mod[fn]) == "function" and compat_mod[fn](colors) or nil
  end
  return compat_mod.groups and compat_mod.groups(colors) or nil
end

--- All compat highlight groups for the enabled integrations (not applied).
function M.collect(colors, mode)
  local out = {}
  for _, mod in ipairs(M.modules) do
    if M.is_enabled(mod, mode) then
      for group, hl in pairs(groups_for(mod, colors) or {}) do
        out[group] = hl
      end
    end
  end
  return out
end

function M.apply(colors, mode)
  local applied = {}
  for group, hl in pairs(M.collect(colors, mode)) do
    if pcall(vim.api.nvim_set_hl, 0, group, hl) then
      applied[group] = true
    end
  end
  return applied
end

--- Status rows for the panel and doctor: { label, enabled }.
function M.status(mode)
  local rows = {}
  for _, mod in ipairs(M.modules) do
    table.insert(rows, { label = mod.label, enabled = M.is_enabled(mod, mode) })
  end
  return rows
end

return M
