-- Small floating list picker used by the panel (profiles, blends).
-- Replaces vim.ui.select's command-line list, which needs a "Press ENTER".
local M = {}

--- @param items string[]|{label:string, detail?:string, value:any}[]
--- @param opts {title?:string}
--- @param on_choice fun(value:any|nil)
function M.open(items, opts, on_choice)
  opts = opts or {}
  if #items == 0 then
    on_choice(nil)
    return
  end
  local rows = {}
  for _, it in ipairs(items) do
    if type(it) == "table" then
      table.insert(rows, { label = it.label, detail = it.detail, value = it.value == nil and it.label or it.value })
    else
      table.insert(rows, { label = tostring(it), value = it })
    end
  end

  local width = vim.fn.strdisplaywidth(opts.title or "") + 6
  for _, r in ipairs(rows) do
    width = math.max(width, vim.fn.strdisplaywidth(r.label) + (r.detail and vim.fn.strdisplaywidth(r.detail) + 4 or 0) + 6)
  end
  width = math.min(width, vim.o.columns - 4)
  local height = math.min(#rows, vim.o.lines - 6)

  local lines = {}
  for _, r in ipairs(rows) do
    table.insert(lines, "  " .. r.label)
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local ns = vim.api.nvim_create_namespace("themeforge_picker")
  for i, r in ipairs(rows) do
    if r.detail then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        virt_text = { { r.detail .. " ", "ThemeForgeMuted" } },
        virt_text_pos = "right_align",
      })
    end
  end

  local config = {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    zindex = 80,
    title = " " .. (opts.title or "Select") .. " ",
    title_pos = "center",
  }
  if vim.fn.has("nvim-0.10") == 1 then
    config.footer = " ⏎ choose · q cancel "
    config.footer_pos = "center"
  end
  local win = vim.api.nvim_open_win(buf, true, config)
  vim.wo[win].cursorline = true
  vim.wo[win].winhighlight = "Normal:ThemeForgePanelNormal,FloatBorder:ThemeForgePanelBorder,FloatTitle:ThemeForgeTitle,FloatFooter:ThemeForgeMuted,CursorLine:ThemeForgePanelCursorLine"

  local done = false
  local function finish(value)
    if done then return end
    done = true
    pcall(vim.api.nvim_win_close, win, true)
    vim.schedule(function() on_choice(value) end)
  end
  local function map(key, fn)
    vim.keymap.set("n", key, fn, { buffer = buf, nowait = true, silent = true })
  end
  map("<CR>", function() finish(rows[vim.api.nvim_win_get_cursor(win)[1]].value) end)
  map("q", function() finish(nil) end)
  map("<Esc>", function() finish(nil) end)
  for i = 1, math.min(9, #rows) do
    map(tostring(i), function() finish(rows[i].value) end)
  end
  vim.api.nvim_create_autocmd("BufLeave", { buffer = buf, once = true, callback = function() finish(nil) end })
  return win
end

return M
