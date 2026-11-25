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

local metadata = {
  ["tokyonight-storm"] = { "blue", "calm", "balanced" },
  ["tokyonight-night"] = { "blue", "calm", "minimal" },
  ["catppuccin-mocha"] = { "pastel", "soft", "warm" },
  ["gruvbox-dark"] = { "warm", "retro", "earthy" },
  ["nord"] = { "blue", "minimal", "cool" },
  ["rose-pine"] = { "purple", "soft", "low-distraction" },
  ["kanagawa-wave"] = { "warm", "cinematic", "balanced" },
  ["dracula"] = { "purple", "vivid", "high-contrast" },
  ["onedark"] = { "balanced", "classic", "low-distraction" },
  ["solarized-dark"] = { "low-contrast", "warm", "minimal" },
  ["nightfox"] = { "blue", "vivid", "balanced" },
  ["everforest"] = { "green", "soft", "nature" },
  ["material-darker"] = { "high-contrast", "vivid", "classic" },
  ["oxocarbon"] = { "monochrome", "minimal", "high-contrast" },
  ["github-dark"] = { "blue", "classic", "low-distraction" },
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
        tags = metadata[id] or {},
      })
    end
  end
  return result
end

function M.ids()
  return vim.deepcopy(registry)
end

return M
