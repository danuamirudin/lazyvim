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

-- Navigate to symbols (like Cmd+Shift+O in VSCode)
vim.keymap.set("n", "<D-S-o>", function()
  require("snacks.picker").lsp_symbols()
end, { desc = "Go to Symbol" })

-- PHP-specific keybinding: - to add semicolon at end of line
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    vim.keymap.set("n", "-", "A;<Esc>", { buffer = true, desc = "Add semicolon at end of line" })
  end,
})

-- Theme Selector (like NvChad)
vim.keymap.set("n", "<leader>th", function()
  require("config.themes").theme_selector_simple()
end, { desc = "Theme Selector" })

-- Insert mode navigation with Ctrl+hjkl
vim.keymap.set("i", "<C-h>", "<Left>", { desc = "Move left in insert mode" })
vim.keymap.set("i", "<C-l>", "<Right>", { desc = "Move right in insert mode" })
vim.keymap.set("i", "<C-j>", "<Down>", { desc = "Move down in insert mode" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "Move up in insert mode" })

-- Visual mode keymaps
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent and reselect" })
vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Unindent and reselect" })
vim.keymap.set("v", "y", "ygv<Esc>", { desc = "Yank and reselect" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Normal mode keymaps
vim.keymap.set("n", "<leader>h", "^", { desc = "Go to first non-blank character" })
vim.keymap.set("n", "<leader>l", "$", { desc = "Go to end of line" })
vim.keymap.set("n", "J", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "K", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })

-- Override K mapping after LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.keymap.set("n", "K", ":m .-2<CR>==", { buffer = args.buf, noremap = true, silent = true, desc = "Move line up" })
  end,
})
