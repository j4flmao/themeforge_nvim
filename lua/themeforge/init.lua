local M = {}

local state = require("themeforge.state")

function M.setup(opts)
  opts = opts or {}

  -- Store config
  state.config = {
    default_theme = opts.default_theme or "tokyonight-storm",
    restore_on_start = opts.restore_on_start ~= false,
    config_paths = opts.config_paths or {},
    default_save_path = opts.default_save_path,
    panel = vim.tbl_extend("force", {
      width_ratio = 0.82,
      height_ratio = 0.82,
      border = "rounded",
    }, opts.panel or {}),
    compat = opts.compat or "auto",
    cache_path = opts.cache_path or (vim.fn.stdpath("data") .. "/themeforge/last.json"),
    autosave_cache = opts.autosave_cache ~= false,
  }

  -- Apply default UI options
  if opts.ui then
    state.current.ui_options = vim.tbl_extend("force", state.current.ui_options, opts.ui)
  end

  -- Restore on start
  if state.config.restore_on_start then
    -- Try session cache first
    local restored = state.load_cache()
    if restored and state.current.active_theme then
      vim.schedule(function()
        local apply = require("themeforge.apply")
        apply.apply()
      end)
    else
      -- Apply default theme
      vim.schedule(function()
        local apply = require("themeforge.apply")
        apply.apply(state.config.default_theme)
      end)
    end
  end
end

function M.open()
  local panel = require("themeforge.ui.panel")
  panel.open()
end

function M.close()
  local panel = require("themeforge.ui.panel")
  panel.close()
end

function M.apply(opts)
  local apply = require("themeforge.apply")
  if type(opts) == "string" then
    state.set_theme(opts)
    return apply.apply(opts)
  elseif type(opts) == "table" then
    if opts.theme then
      state.set_theme(opts.theme)
    end
    if opts.overrides then
      for group, hl in pairs(opts.overrides) do
        state.set_override(group, hl)
      end
    end
    if opts.mix then
      for k, v in pairs(opts.mix) do
        state.set_mix(k, v)
      end
    end
    if opts.ui then
      for k, v in pairs(opts.ui) do
        state.set_ui_option(k, v)
      end
    end
    return apply.apply(opts)
  else
    return apply.apply()
  end
end

function M.doctor()
  return require("themeforge.doctor").run()
end

function M.save(filepath)
  if filepath then
    local writer = require("themeforge.writer")
    return writer.write(filepath)
  else
    local filepicker = require("themeforge.ui.filepicker")
    filepicker.open()
  end
end

function M.reset()
  state.reset()
  if state.current.active_theme then
    local apply = require("themeforge.apply")
    apply.apply()
  end
end

function M.save_blend(name)
  if not name or name == "" then
    vim.notify("[ThemeForge] Blend name required", vim.log.levels.ERROR)
    return
  end

  local blend_path = vim.fn.stdpath("data") .. "/themeforge/blends.json"
  local dir = vim.fn.fnamemodify(blend_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  -- Load existing blends
  local blends = {}
  local f = io.open(blend_path, "r")
  if f then
    local raw = f:read("*a")
    f:close()
    local ok, data = pcall(vim.fn.json_decode, raw)
    if ok and data then
      blends = data
    end
  end

  -- Save current state as a blend
  blends[name] = {
    base_theme = state.current.active_theme,
    overrides = vim.deepcopy(state.current.overrides),
    palette_mix = vim.deepcopy(state.current.palette_mix),
    ui_options = vim.deepcopy(state.current.ui_options),
  }

  local wf = io.open(blend_path, "w")
  if wf then
    wf:write(vim.fn.json_encode(blends))
    wf:close()
    vim.notify("[ThemeForge] Blend saved: " .. name, vim.log.levels.INFO)
  end
end

return M
