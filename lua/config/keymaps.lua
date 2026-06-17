-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local codex = require("config.codex")
local window_sizes = require("config.window_sizes")

local MIN_TERMINAL_WIDTH = 40
local MAX_TERMINALS = 3

codex.setup()
window_sizes.setup()

local function current_snacks_terminal()
  return type(vim.b.snacks_terminal) == "table" and vim.b.snacks_terminal or nil
end

local function terminal_count(count)
  count = math.floor(tonumber(count) or 1)
  return ((count - 1) % MAX_TERMINALS) + 1
end

local function numbered_terminal(count, cwd)
  count = terminal_count(count)
  for _, terminal in ipairs(Snacks.terminal.list()) do
    local info = terminal.buf and vim.b[terminal.buf].snacks_terminal
    if type(info) == "table" and tostring(info.id) == tostring(count) and (not cwd or info.cwd == cwd) then
      return terminal
    end
  end
end

local function visible_terminal_infos()
  local infos = {}
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local info = vim.b[bufnr].snacks_terminal
    local snacks_win = vim.w[winid].snacks_win
    if
      type(info) == "table"
      and type(snacks_win) == "table"
      and snacks_win.position == "bottom"
      and vim.api.nvim_win_get_config(winid).relative == ""
    then
      infos[#infos + 1] = info
    end
  end
  return infos
end

local function first_visible_terminal_count()
  local first = nil
  for _, info in ipairs(visible_terminal_infos()) do
    local id = tonumber(info.id)
    if id and (not first or id < first) then
      first = id
    end
  end
  return first or 1
end

local function has_room_for_new_terminal()
  return math.floor(vim.o.columns / (#visible_terminal_infos() + 1)) >= MIN_TERMINAL_WIDTH
end

local function leave_terminal_input()
  if vim.bo.buftype == "terminal" then
    pcall(vim.cmd.stopinsert)
  end
end

local function focus_numbered_terminal(count)
  count = terminal_count(count)
  local terminal = current_snacks_terminal()
  local cwd = terminal and terminal.cwd or nil
  leave_terminal_input()

  if vim.bo.filetype == "codex" then
    codex.focus_code()
  end

  vim.schedule(function()
    Snacks.terminal.focus(nil, { cwd = cwd or LazyVim.root(), count = count })
    vim.cmd("redraw!")
  end)
end

local function toggle_current_terminal()
  local terminal = current_snacks_terminal()
  if terminal then
    focus_numbered_terminal(terminal.id)
  else
    focus_numbered_terminal(1)
  end
end

local function focus_next_root_terminal()
  local terminal = current_snacks_terminal()
  local cwd = terminal and terminal.cwd or LazyVim.root()
  local count = terminal_count((terminal and tonumber(terminal.id) or 1) + 1)
  local target = numbered_terminal(count, cwd)
  if not (target and target.win and vim.api.nvim_win_is_valid(target.win)) and not has_room_for_new_terminal() then
    count = first_visible_terminal_count()
  end
  focus_numbered_terminal(count)
end

local function insert_left()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if vim.bo.buftype ~= "" or col > 0 then
    return "<Left>"
  end

  return row > 1 and "<Up><End>" or ""
end

vim.keymap.set({ "n", "i" }, "<M-h>", codex.toggle, { desc = "Toggle Codex agent" })
vim.keymap.set({ "n", "i" }, "<A-h>", codex.toggle, { desc = "Toggle Codex agent" })
vim.keymap.set("i", "<Esc>h", codex.toggle, { desc = "Toggle Codex agent" })

vim.keymap.set({ "n", "i", "t" }, "<C-/>", toggle_current_terminal, { desc = "Toggle Current Terminal" })
vim.keymap.set({ "n", "i", "t" }, "<C-_>", toggle_current_terminal, { desc = "Toggle Current Terminal" })
vim.keymap.set({ "n", "i", "t" }, "<M-1>", function()
  focus_numbered_terminal(1)
end, { desc = "Terminal 1 (Root Dir)" })
vim.keymap.set({ "n", "i", "t" }, "<M-2>", function()
  focus_numbered_terminal(2)
end, { desc = "Terminal 2 (Root Dir)" })
vim.keymap.set({ "n", "i", "t" }, "<M-3>", function()
  focus_numbered_terminal(3)
end, { desc = "Terminal 3 (Root Dir)" })
vim.keymap.set({ "n", "i", "t" }, "<A-1>", function()
  focus_numbered_terminal(1)
end, { desc = "Terminal 1 (Root Dir)" })
vim.keymap.set({ "n", "i", "t" }, "<A-2>", function()
  focus_numbered_terminal(2)
end, { desc = "Terminal 2 (Root Dir)" })
vim.keymap.set({ "n", "i", "t" }, "<A-3>", function()
  focus_numbered_terminal(3)
end, { desc = "Terminal 3 (Root Dir)" })
vim.keymap.set({ "n", "i", "t" }, "<M-/>", focus_next_root_terminal, { desc = "Next Terminal (Root Dir)" })
vim.keymap.set({ "n", "i", "t" }, "<A-/>", focus_next_root_terminal, { desc = "Next Terminal (Root Dir)" })
vim.keymap.set("i", "<Left>", insert_left, { expr = true, replace_keycodes = true, desc = "Move left across lines" })
