-- Jump Ray module
local win, buf
local M = {}

-- Create JumpRay commands
local function create_commands()
  vim.cmd("command! -bang -nargs=0 JumpRayShow :lua require('jump-ray').show()")
  vim.cmd("command! -bang -nargs=0 JumpRayClose :lua require('jump-ray').close_window()")
  vim.cmd("command! -bang -nargs=0 JumpRayStart :lua require('jump-ray').ray_start()")
  vim.cmd("command! -bang -nargs=0 JumpRayStop :lua require('jump-ray').ray_stop()")
end

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

local function parse_jumps(tmp)
  local result = {}
  local line = 0
  local current_jump = 0
  local header = "  LINE  FILE/TEXT"

  table.insert(result, header)
  for s in tmp:gmatch("[^\n]+") do
    if starts_with(s, ">") then
      current_jump = line
      break
    end
    line = line + 1
  end

  if current_jump == 0 then 
    current_jump = line - 3
  end
  line = 0
  for s in tmp:gmatch("[^\n]+") do
    if line >= current_jump - 3
      and line <= current_jump + 1
      and line > 0
      then table.insert(result, string.sub(s, 0, 1) .. string.sub(s, 6, 10) .. string.sub(s, 16))
    end
    line = line + 1
  end
  table.insert(result,"")
  table.insert(result,"")

  return result

end

local function create_window()
    local w = vim.fn.nvim_win_get_width(0)
    -- local h = vim.fn.nvim_win_get_height(0)

    local width = 40
    local row = 1
    local col = w - width
    local config = {
      style="minimal",
      relative='editor',
      focusable=false,
      row=row,
      col=col,
      width=width,
      height=6
    }

    buf = vim.fn.nvim_create_buf(false, true)
    win = vim.api.nvim_open_win(buf, false, config)

    -- kill buffer on close
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_win_set_option(win, "winblend", 80)
end

function M.close_window()
  if win then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
  buf = nil
end

function M.show()
    if not win then
      create_window()
    end
    local cmd = "jumps"
    -- Vim EX command
    vim.api.nvim_set_var('__redir_exec_cmd', cmd)
    vim.cmd([[
      redir => g:__redir_exec_output
        silent! execute g:__redir_exec_cmd
      redir END
    ]])

  local tmp = vim.api.nvim_get_var('__redir_exec_output')

  local result = parse_jumps(tmp)
  vim.fn.nvim_buf_set_lines(buf, 0, 5, false, result)
end

function M.ray_start()
  vim.cmd('augroup Jump-Ray')
  vim.cmd('autocmd!')
  vim.cmd("autocmd CursorMoved * :lua require'jump-ray'.show()")
  vim.cmd('augroup END')
  M.show()
end

function M.ray_stop()
  vim.cmd('autocmd! Jump-Ray')
  M.close_window()
end

function M.init()
  create_commands()
end

return M
