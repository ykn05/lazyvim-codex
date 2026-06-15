local M = {}

local state = {
  bufnr = nil,
  winid = nil,
  job_id = nil,
  last_code_winid = nil,
  opening_codex = false,
  checktime_timer = nil,
}

local function valid_buf(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function valid_win(winid)
  return winid and vim.api.nvim_win_is_valid(winid)
end

local function valid_codex_win(winid)
  return valid_win(winid) and valid_buf(state.bufnr) and vim.api.nvim_win_get_buf(winid) == state.bufnr
end

local function valid_code_win(winid)
  if not valid_win(winid) or valid_codex_win(winid) then
    return false
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  return vim.bo[bufnr].buftype ~= "terminal"
end

local function valid_job(job_id)
  return type(job_id) == "number" and job_id > 0
end

local function stop_checktime_timer()
  if state.checktime_timer then
    state.checktime_timer:stop()
    state.checktime_timer:close()
    state.checktime_timer = nil
  end
end

local function check_external_changes()
  if not valid_buf(state.bufnr) or not valid_job(state.job_id) then
    stop_checktime_timer()
    return
  end

  if vim.o.buftype == "nofile" then
    return
  end

  vim.cmd("silent! checktime")
end

local function start_checktime_timer()
  if state.checktime_timer then
    return
  end

  state.checktime_timer = vim.uv.new_timer()
  state.checktime_timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      check_external_changes()
    end)
  )
end

local function project_root()
  if _G.LazyVim and LazyVim.root then
    if type(LazyVim.root.cwd) == "function" then
      return LazyVim.root.cwd()
    end
    if type(LazyVim.root.get) == "function" then
      return LazyVim.root.get()
    end
  end

  local ok, lazyvim = pcall(require, "lazyvim.util")
  if ok and lazyvim.root then
    if type(lazyvim.root.cwd) == "function" then
      return lazyvim.root.cwd()
    end
    if type(lazyvim.root.get) == "function" then
      return lazyvim.root.get()
    end
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  local start = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()
  local marker = vim.fs.find({ ".git", "lua", "package.json", "pyproject.toml", "Cargo.toml", "go.mod" }, {
    upward = true,
    path = start,
  })[1]

  return marker and vim.fs.dirname(marker) or vim.uv.cwd()
end

local function remember_code_window()
  if state.opening_codex then
    return
  end

  local winid = vim.api.nvim_get_current_win()
  local buftype = vim.bo.buftype
  if buftype ~= "terminal" and not valid_codex_win(winid) then
    state.last_code_winid = winid
  end
end

local function find_codex_window()
  if valid_codex_win(state.winid) then
    return state.winid
  end

  if not valid_buf(state.bufnr) then
    return nil
  end

  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      if valid_codex_win(winid) then
        state.winid = winid
        return winid
      end
    end
  end

  return nil
end

local function enter_terminal()
  vim.schedule(function()
    if valid_buf(state.bufnr) and vim.api.nvim_get_current_buf() == state.bufnr then
      vim.cmd.startinsert()
    end
  end)
end

local function restore_codex_window(winid)
  if not valid_win(winid) or not valid_buf(state.bufnr) or not valid_job(state.job_id) then
    return false
  end

  state.winid = winid
  vim.api.nvim_set_current_win(winid)
  vim.api.nvim_win_set_buf(winid, state.bufnr)
  vim.api.nvim_win_set_width(winid, math.floor(vim.o.columns * 0.3))
  enter_terminal()
  return true
end

local function focus_code_window(insert)
  if valid_code_win(state.last_code_winid) then
    vim.api.nvim_set_current_win(state.last_code_winid)
  else
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if valid_code_win(winid) then
        vim.api.nvim_set_current_win(winid)
        break
      end
    end

    if valid_codex_win(vim.api.nvim_get_current_win()) then
      vim.cmd.wincmd("h")
    end
  end

  if insert and vim.bo.buftype ~= "terminal" then
    vim.schedule(function()
      if vim.bo.buftype ~= "terminal" then
        vim.cmd.startinsert()
      end
    end)
  end
end

local function terminal_to_code()
  pcall(vim.cmd.stopinsert)

  vim.schedule(function()
    if valid_buf(state.bufnr) then
      M.focus_code_insert()
    end
  end)
end

local function set_terminal_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true, desc = "Focus code window" }

  vim.keymap.set("t", "<M-h>", terminal_to_code, opts)
  vim.keymap.set("t", "<A-h>", terminal_to_code, opts)
  vim.keymap.set("t", "<Esc>h", terminal_to_code, opts)
  vim.keymap.set("t", "<Esc><Esc>", function()
    pcall(vim.cmd.stopinsert)
  end, { buffer = bufnr, silent = true, desc = "Terminal normal mode" })

  vim.keymap.set("n", "<M-h>", function()
    M.focus_code_insert()
  end, opts)
  vim.keymap.set("n", "<A-h>", function()
    M.focus_code_insert()
  end, opts)
end

local function start_codex()
  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, state.bufnr)
  vim.bo[state.bufnr].bufhidden = "hide"
  vim.bo[state.bufnr].filetype = "codex"
  vim.api.nvim_buf_set_name(state.bufnr, "Codex Agent")

  state.job_id = vim.fn.termopen({ "codex" }, {
    cwd = project_root(),
    on_exit = function()
      state.job_id = nil
      stop_checktime_timer()
    end,
  })

  if not valid_job(state.job_id) then
    vim.notify("Failed to start codex", vim.log.levels.ERROR)
    return
  end

  set_terminal_keymaps(state.bufnr)
  start_checktime_timer()
end

local function open_window()
  remember_code_window()
  state.opening_codex = true
  vim.cmd("botright vertical split")
  state.winid = vim.api.nvim_get_current_win()
  state.opening_codex = false
  vim.api.nvim_win_set_width(state.winid, math.floor(vim.o.columns * 0.3))
end

function M.focus_code()
  focus_code_window(false)
end

function M.focus_code_insert()
  focus_code_window(true)
end

function M.toggle()
  local codex_winid = find_codex_window()
  if codex_winid then
    local current = vim.api.nvim_get_current_win()
    if current == codex_winid then
      focus_code_window(true)
    else
      remember_code_window()
      vim.api.nvim_set_current_win(codex_winid)
      enter_terminal()
    end
    return
  end

  if valid_win(state.winid) and valid_buf(state.bufnr) and valid_job(state.job_id) then
    restore_codex_window(state.winid)
    return
  else
    open_window()
  end

  if valid_buf(state.bufnr) and valid_job(state.job_id) then
    vim.api.nvim_win_set_buf(0, state.bufnr)
    start_checktime_timer()
  else
    if valid_buf(state.bufnr) then
      vim.api.nvim_buf_delete(state.bufnr, { force = true })
    end
    start_codex()
  end

  enter_terminal()
end

function M.setup()
  local group = vim.api.nvim_create_augroup("codex_agent_terminal", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = group,
    callback = function()
      local winid = vim.api.nvim_get_current_win()
      if valid_codex_win(winid) then
        state.winid = winid
        enter_terminal()
      elseif winid == state.winid and valid_buf(state.bufnr) and valid_job(state.job_id) then
        restore_codex_window(winid)
      else
        remember_code_window()
        check_external_changes()
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = stop_checktime_timer,
  })
end

return M
