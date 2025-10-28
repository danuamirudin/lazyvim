-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Last Buffer
vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape from Insert mode" })
vim.keymap.del("n", "<leader><leader>")
vim.keymap.set("n", "<leader><leader>", "<C-^>", { desc = "Switch to last buffer" })
--[[ leader w to save  ]]
--[[ vim.keymap.set("n", "<leader>w", ":w<C-R>", { desc = "Save file" }) ]]
vim.opt.mouse = ""
-- vim.opt.clipboard = "unnamedplus"

-- make selection then cmd+c to copy to system clipboard
vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<D-v>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("v", "<D-v>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("i", "<D-v>", "<C-R>+", { desc = "Paste from system clipboard" })
-- disabme f + n
vim.keymap.set("n", "fn", "n", { desc = "Disabled f + n" })

-- Copy full path
vim.keymap.set("n", "<leader>yfp", function()
  local full_path = vim.fn.expand("%:p")
  vim.fn.setreg("+", full_path)
  print("Copied full path: " .. full_path)
end, { desc = "Copy full file path" })

-- Copy relative path
--[[ vim.keymap.set("n", "<leader>yrp", function()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  local file_path = vim.fn.expand("%:p")
  local relative_path = file_path:sub(#git_root + 2) -- remove git root + '/'
  vim.fn.setreg("+", relative_path)
  print("Copied relative path (git root): " .. relative_path)
end, { desc = "Copy relative file path from git root" }) ]]

vim.keymap.set("n", "<leader>yrp", function()
  local relative_path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
  vim.fn.setreg("+", relative_path)
  print("Copied relative path: " .. relative_path)
end, { desc = "Copy relative file path" })

-- Custom <Esc> behavior for dismissing Copilot/cmp suggestions without leaving insert mode
-- This was moved to lua/plugins/cmp.lua to ensure cmp is loaded.

-- Keymaps for commenting
vim.keymap.set("n", "<D-/>", function()
  vim.cmd("normal gcc")
end, { noremap = true, silent = true, desc = "Toggle line comment" })
vim.keymap.set("v", "<D-/>", function()
  vim.cmd("normal gc")
end, { noremap = true, silent = true, desc = "Toggle line comment" })
