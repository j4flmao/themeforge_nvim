local M = {}

local state = require("themeforge.state")

local START_MARKER = "-- [themeforge:start] --"
local END_MARKER = "-- [themeforge:end] --"

-- Resolve a user-provided filepath:
-- - "mytheme.lua"                    → <nvim config dir>/mytheme.lua
-- - "themeforge/config.lua"          → <nvim config dir>/themeforge/config.lua
-- - "~/somedir/file.lua"             → expanded absolute path
-- - "C:\Users\...\file.lua"          → absolute (Windows)
-- - "/home/user/.config/.../file.lua"→ absolute (Unix/macOS)
function M.resolve_path(input)
  if not input or input == "" then return nil end

  -- Expand ~ and env vars first
  local expanded = vim.fn.expand(input)

  -- After expansion, check if it's absolute
  -- vim.fn.fnamemodify(path, ":p") returns the absolute version;
  -- if expanding didn't change a ~ path, we check manually
  local is_abs
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    -- Windows: absolute = drive letter (C:\...) or UNC (\\server\...)
    is_abs = expanded:match("^%a:[/\\]") or expanded:match("^\\\\")
  else
    -- Unix/macOS: absolute = starts with /
    is_abs = expanded:match("^/")
  end

  -- If the original input started with ~ it was meant as absolute (home dir)
  if input:match("^~") then
    return vim.fn.fnamemodify(expanded, ":p")
  end

  -- If it's a real absolute path from the OS perspective, use as-is
  if is_abs then
    return vim.fn.fnamemodify(expanded, ":p")
  end

  -- Otherwise treat as relative to nvim config dir
  local config_dir = vim.fn.stdpath("config")
  local sep = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) and "\\" or "/"
  return config_dir .. sep .. expanded
end

-- Generate the config block content
function M.generate_block()
  local s = state.current
  local lines = {}
  table.insert(lines, START_MARKER)
  table.insert(lines, "-- Managed by ThemeForge.nvim. Do not edit this block manually.")
  table.insert(lines, 'require("themeforge").apply({')
  table.insert(lines, string.format('  theme = "%s",', s.active_theme or ""))

  -- Overrides
  if next(s.overrides) then
    table.insert(lines, "  overrides = {")
    for group, opts in pairs(s.overrides) do
      local parts = {}
      for k, v in pairs(opts) do
        if type(v) == "string" then
          table.insert(parts, string.format('%s = "%s"', k, v))
        elseif type(v) == "boolean" then
          table.insert(parts, string.format("%s = %s", k, tostring(v)))
        end
      end
      table.insert(lines, string.format("    %s = { %s },", group, table.concat(parts, ", ")))
    end
    table.insert(lines, "  },")
  end

  -- Blend sliders (palette_mix)
  if s.palette_mix then
    table.insert(lines, "  mix = {")
    for k, v in pairs(s.palette_mix) do
      if type(v) == "number" then
        table.insert(lines, string.format("    %s = %s,", k, tostring(v)))
      end
    end
    table.insert(lines, "  },")
  end

  -- UI options
  table.insert(lines, "  ui = {")
  for k, v in pairs(s.ui_options) do
    if type(v) == "string" then
      table.insert(lines, string.format('    %s = "%s",', k, v))
    elseif type(v) == "boolean" then
      table.insert(lines, string.format("    %s = %s,", k, tostring(v)))
    end
  end
  table.insert(lines, "  },")

  table.insert(lines, "})")
  table.insert(lines, END_MARKER)

  return lines
end

-- Generate a dofile reference line for init.lua when config is in a separate file
local REF_START = "-- [themeforge:ref:start] --"
local REF_END = "-- [themeforge:ref:end] --"

function M.generate_ref_block(theme_file_path)
  local lines = {}
  table.insert(lines, REF_START)
  table.insert(lines, "-- ThemeForge config loaded from external file. Do not edit this block manually.")
  table.insert(lines, string.format('dofile("%s")', theme_file_path:gsub("\\", "/")))
  table.insert(lines, REF_END)
  return lines
end

-- Inject or update a reference block in init.lua pointing to the theme file
function M.write_ref(theme_file_path)
  local init_path = vim.fn.stdpath("config") .. "/init.lua"
  if vim.fn.filereadable(init_path) == 0 then return end

  local existing = {}
  local f = io.open(init_path, "r")
  if f then
    for line in f:lines() do table.insert(existing, line) end
    f:close()
  end

  local ref_block = M.generate_ref_block(theme_file_path)

  -- Find existing ref markers
  local start_idx, end_idx
  for i, line in ipairs(existing) do
    if line:find(REF_START, 1, true) then start_idx = i end
    if line:find(REF_END, 1, true) then end_idx = i end
  end

  local result = {}
  if start_idx and end_idx and start_idx < end_idx then
    for i = 1, start_idx - 1 do table.insert(result, existing[i]) end
    for _, line in ipairs(ref_block) do table.insert(result, line) end
    for i = end_idx + 1, #existing do table.insert(result, existing[i]) end
  else
    result = existing
    if #result > 0 then table.insert(result, "") end
    for _, line in ipairs(ref_block) do table.insert(result, line) end
  end

  local wf = io.open(init_path, "w")
  if not wf then return end
  wf:write(table.concat(result, "\n") .. "\n")
  wf:close()
end

-- Write block to a file (inject or replace)
function M.write(filepath)
  if not filepath or filepath == "" then
    vim.notify("[ThemeForge] No file path specified", vim.log.levels.ERROR)
    return false
  end

  -- Resolve the path (relative → nvim config dir, absolute → as-is)
  filepath = M.resolve_path(filepath) or filepath

  -- Ensure parent directory exists
  local dir = vim.fn.fnamemodify(filepath, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  -- Read existing file
  local existing_lines = {}
  local f = io.open(filepath, "r")
  if f then
    for line in f:lines() do
      table.insert(existing_lines, line)
    end
    f:close()
  end

  local block = M.generate_block()

  -- Find markers
  local start_idx, end_idx
  for i, line in ipairs(existing_lines) do
    if line:find(START_MARKER, 1, true) then
      start_idx = i
    end
    if line:find(END_MARKER, 1, true) then
      end_idx = i
    end
  end

  local result_lines = {}

  if start_idx and end_idx and start_idx < end_idx then
    -- Replace existing block
    for i = 1, start_idx - 1 do
      table.insert(result_lines, existing_lines[i])
    end
    for _, line in ipairs(block) do
      table.insert(result_lines, line)
    end
    for i = end_idx + 1, #existing_lines do
      table.insert(result_lines, existing_lines[i])
    end
  elseif start_idx and not end_idx then
    vim.notify("[ThemeForge] Found start marker but no end marker. Aborting.", vim.log.levels.ERROR)
    return false
  elseif end_idx and not start_idx then
    vim.notify("[ThemeForge] Found end marker but no start marker. Aborting.", vim.log.levels.ERROR)
    return false
  else
    -- Append block
    result_lines = existing_lines
    if #result_lines > 0 then
      table.insert(result_lines, "")
    end
    for _, line in ipairs(block) do
      table.insert(result_lines, line)
    end
  end

  -- Atomic write: write to temp file, then rename
  local tmppath = filepath .. ".themeforge.tmp"
  local wf = io.open(tmppath, "w")
  if not wf then
    vim.notify("[ThemeForge] Cannot write to " .. tmppath, vim.log.levels.ERROR)
    return false
  end
  wf:write(table.concat(result_lines, "\n") .. "\n")
  wf:close()

  local ok = os.rename(tmppath, filepath)
  if not ok then
    -- Fallback: direct write
    wf = io.open(filepath, "w")
    if not wf then
      vim.notify("[ThemeForge] Cannot write to " .. filepath, vim.log.levels.ERROR)
      return false
    end
    wf:write(table.concat(result_lines, "\n") .. "\n")
    wf:close()
    os.remove(tmppath)
  end

  -- Find the line range of the block in the result
  local block_start, block_end
  for i, line in ipairs(result_lines) do
    if line:find(START_MARKER, 1, true) then block_start = i end
    if line:find(END_MARKER, 1, true) then block_end = i end
  end

  -- If writing to a file that is NOT init.lua, inject a dofile() reference in init.lua
  local init_path = vim.fn.stdpath("config") .. "/init.lua"
  local norm = function(p) return vim.fn.fnamemodify(p, ":p"):gsub("\\", "/"):gsub("/+$", "") end
  if norm(filepath) ~= norm(init_path) then
    M.write_ref(filepath)
    vim.notify(
      string.format("[ThemeForge] Saved to %s (line %d–%d) + ref in init.lua", filepath, block_start or 0, block_end or 0),
      vim.log.levels.INFO
    )
  else
    vim.notify(
      string.format("[ThemeForge] Saved to %s (line %d–%d)", filepath, block_start or 0, block_end or 0),
      vim.log.levels.INFO
    )
  end

  return true
end

return M
