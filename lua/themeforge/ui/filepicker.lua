local M = {}

local state = require("themeforge.state")
local writer = require("themeforge.writer")

function M.open()
  -- If default_save_path is set, skip modal
  if state.config.default_save_path then
    writer.write(state.config.default_save_path)
    return
  end

  -- Build file list
  local files = {}
  if state.config.config_paths and #state.config.config_paths > 0 then
    for _, path in ipairs(state.config.config_paths) do
      table.insert(files, path)
    end
  else
    -- Auto-detect
    local config_dir = vim.fn.stdpath("config")
    local init_path = config_dir .. "/init.lua"
    if vim.fn.filereadable(init_path) == 1 then
      table.insert(files, init_path)
    end
    -- Scan for lua files at depth 1-2
    local lua_dir = config_dir .. "/lua"
    if vim.fn.isdirectory(lua_dir) == 1 then
      local found = vim.fn.glob(lua_dir .. "/*.lua", false, true)
      for _, f in ipairs(found) do
        table.insert(files, f)
      end
      local found2 = vim.fn.glob(lua_dir .. "/*/*.lua", false, true)
      for _, f in ipairs(found2) do
        table.insert(files, f)
      end
    end
  end

  -- Add custom path option
  table.insert(files, "<Custom path...>")

  -- Build display lines
  local lines = {
    " Save theme config to:",
    "",
  }

  local file_start = #lines + 1

  for i, f in ipairs(files) do
    local marker = (i == 1) and " ● " or " ○ "
    if f == "<Custom path...>" then
      table.insert(lines, marker .. f)
    else
      -- Show shortened path
      local short = vim.fn.fnamemodify(f, ":~")
      local name = vim.fn.fnamemodify(f, ":t")
      table.insert(lines, string.format("%s%-18s %s", marker, name, short))
    end
  end

  table.insert(lines, "")
  table.insert(lines, "  [Confirm]   [Cancel]")

  -- Create modal
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  local w = 60
  local h = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = w,
    height = h,
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    zindex = 60,
    title = " Save to Config ",
    title_pos = "center",
  })

  -- Set cursor to first file
  pcall(vim.api.nvim_win_set_cursor, win, { file_start, 0 })

  local function close_modal()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- Keymaps
  vim.keymap.set("n", "<CR>", function()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local idx = row - file_start + 1
    close_modal()
    if idx >= 1 and idx <= #files then
      local selected = files[idx]
      if selected == "<Custom path...>" then
        vim.ui.input({
          prompt = "Save to (filename = nvim config dir, full path = exact location): ",
          completion = "file",
        }, function(input)
          if input and input ~= "" then
            local resolved = writer.resolve_path(input)
            if resolved then
              writer.write(resolved)
            end
          end
        end)
      else
        writer.write(selected)
      end
    end
  end, { buffer = buf, nowait = true, silent = true })

  vim.keymap.set("n", "q", close_modal, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", close_modal, { buffer = buf, nowait = true, silent = true })
end

return M
