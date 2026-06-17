-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local codex = require("config.codex")
local window_sizes = require("config.window_sizes")

codex.setup()
window_sizes.setup()

local function focus_root_terminal()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
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

vim.keymap.set("i", "<C-/>", focus_root_terminal, { desc = "Terminal (Root Dir)" })
vim.keymap.set("i", "<C-_>", focus_root_terminal, { desc = "Terminal (Root Dir)" })
vim.keymap.set("i", "<Left>", insert_left, { expr = true, replace_keycodes = true, desc = "Move left across lines" })
