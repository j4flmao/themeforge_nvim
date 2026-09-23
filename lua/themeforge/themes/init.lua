local M = {}

local registry = {
  "tokyonight-storm", "tokyonight-night",
  "catppuccin-mocha",
  "gruvbox-dark",
  "nord",
  "rose-pine",
  "kanagawa-wave",
  "dracula",
  "onedark",
  "solarized-dark",
  "nightfox",
  "everforest",
  "material-darker",
  "oxocarbon",
  "github-dark",
}

-- Map id to module name (replace - with _)
local function id_to_module(id)
  return id:gsub("%-", "_")
end

local cache = {}
function M.get(id)
  if cache[id] then return cache[id] end
  local mod_name = id_to_module(id)
  local ok, theme = pcall(require, "themeforge.themes." .. mod_name)
  if ok then
    cache[id] = theme
    return theme
  end
  return nil
end

function M.list()
  local result = {}
  for _, id in ipairs(registry) do
    local theme = M.get(id)
    if theme then
      table.insert(result, {
        id = theme.id,
        name = theme.name,
        variant = theme.variant,
        dot = theme.dot,
      })
    end
  end
  return result
end

function M.ids()
  return vim.deepcopy(registry)
end

return M
