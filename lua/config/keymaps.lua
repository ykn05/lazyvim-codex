-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local codex = require("config.codex")

codex.setup()

local function focus_root_terminal()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end

vim.keymap.set({ "n", "i" }, "<M-h>", codex.toggle, { desc = "Toggle Codex agent" })
vim.keymap.set({ "n", "i" }, "<A-h>", codex.toggle, { desc = "Toggle Codex agent" })
vim.keymap.set("i", "<Esc>h", codex.toggle, { desc = "Toggle Codex agent" })

vim.keymap.set("i", "<C-/>", focus_root_terminal, { desc = "Terminal (Root Dir)" })
vim.keymap.set("i", "<C-_>", focus_root_terminal, { desc = "Terminal (Root Dir)" })
