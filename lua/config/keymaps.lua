-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local codex = require("config.codex")
local window_sizes = require("config.window_sizes")

codex.setup()
window_sizes.setup()

local function current_snacks_terminal()
  return type(vim.b.snacks_terminal) == "table" and vim.b.snacks_terminal or nil
end

local function leave_terminal_input()
  if vim.bo.buftype == "terminal" then
    pcall(vim.cmd.stopinsert)
  end
end

local function focus_numbered_terminal(count)
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
  local count = terminal and (tonumber(terminal.id) or 1) + 1 or 2
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
