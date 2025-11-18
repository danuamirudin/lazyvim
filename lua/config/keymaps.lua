-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Last Buffer
vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape from Insert mode" })
vim.keymap.del("n", "<leader><leader>")
vim.keymap.set("n", "<leader><leader>", "<C-^>", { desc = "Switch to last buffer" })
-- select all
vim.keymap.set("n", "<D-a>", "gg<S-v>G", { desc = "Select all" })
--[[ leader w to save  ]]
--[[ vim.keymap.set("n", "<leader>w", ":w<C-R>", { desc = "Save file" }) ]]
vim.opt.mouse = ""
-- vim.opt.clipboard = "unnamedplus"

-- Custom save function that suppresses messages
local function save_file()
  vim.cmd("silent! write")
  vim.api.nvim_command("redraw")
end

-- Cmd+S to save
vim.keymap.set("n", "<D-s>", save_file, { desc = "Save file" })
vim.keymap.set("i", "<D-s>", function()
  save_file()
end, { desc = "Save file" })
vim.keymap.set("v", "<D-s>", function()
  vim.cmd("normal! gv")
  save_file()
end, { desc = "Save file and restore selection" })

-- make selection then cmd+c to copy to system clipboard
vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<D-v>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("v", "<D-v>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("i", "<D-v>", "<C-R>+", { desc = "Paste from system clipboard" })

-- Copy full path
vim.keymap.set("n", "<leader>yfp", function()
  local full_path = vim.fn.expand("%:p")
  vim.fn.setreg("+", full_path)
  vim.notify("Copied full path: " .. full_path)
end, { desc = "Copy full file path" })

-- Copy relative path
--[[ vim.keymap.set("n", "<leader>yrp", function()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  local file_path = vim.fn.expand("%:p")
  local relative_path = file_path:sub(#git_root + 2) -- remove git root + '/'
  vim.fn.setreg("+", relative_path)
  vim.notify("Copied relative path (git root): " .. relative_path)
end, { desc = "Copy relative file path from git root" }) ]]

vim.keymap.set("n", "<leader>yrp", function()
  local relative_path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
  vim.fn.setreg("+", relative_path)
  vim.notify("Copied relative path: " .. relative_path)
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
-- vim.keymap.set("n", "<leader>h", "^", { desc = "Go to first non-blank character" })
-- vim.keymap.set("n", "<leader>l", "$", { desc = "Go to end of line" })
vim.keymap.set("n", "J", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "K", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })

-- Override K mapping after LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.keymap.set(
      "n",
      "K",
      ":m .-2<CR>==",
      { buffer = args.buf, noremap = true, silent = true, desc = "Move line up" }
    )
  end,
})

-- SFTP Commands
local sftp = require("config.sftp")

-- Leader f -> Upload folder (with prompt)
vim.keymap.set("n", "<leader>fU", function()
  sftp.upload_folder_prompt()
end, { desc = "SFTP: Upload Folder" })

-- Leader d -> Download current buffer
vim.keymap.set("n", "<leader>fd", function()
  sftp.download_current_buffer()
end, { desc = "SFTP: Download Current File" })

-- Leader D -> Download folder (with prompt)
vim.keymap.set("n", "<leader>fD", function()
  sftp.download_folder_prompt()
end, { desc = "SFTP: Download Folder" })

-- SFTP Listener Controls
vim.keymap.set("n", "<leader>fs", function()
  sftp.start()
end, { desc = "SFTP: Start Listener" })

vim.keymap.set("n", "<leader>fS", function()
  sftp.stop()
end, { desc = "SFTP: Stop Listener" })

vim.keymap.set("n", "<leader>ft", function()
  if sftp.is_running() then
    sftp.stop()
    vim.notify("SFTP Listener is running. Stopping it now.")
  else
    sftp.start()
    vim.notify("SFTP Listener is not running. Starting it now.")
  end
end, { desc = "SFTP: Toggle Listener" })

-- Ctrl+Q to toggle hover (editor.action.showHover in VSCode)
vim.keymap.set("n", "<C-q>", function()
  -- Check if there's a floating window open (hover)
  local has_float = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    -- Use pcall to safely check window config
    local ok, config = pcall(vim.api.nvim_win_get_config, win)
    if ok and config.relative ~= "" then
      has_float = true
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
  
  -- If no float was open, show hover
  if not has_float then
    vim.lsp.buf.hover()
  end
end, { desc = "Toggle hover (editor.action.showHover)" })

-- Clear highlight
vim.keymap.set("n", "<leader>Q", function()
  vim.cmd("match none")
end, { desc = "Clear word highlight" })

-- Cmd+X to cut line
vim.keymap.set("n", "<D-x>", '"+dd', { desc = "Cut line to system clipboard" })
vim.keymap.set("v", "<D-x>", '"+d', { desc = "Cut selection to system clipboard" })

-- Visual Multi: Add cursors at start of each selected line
vim.keymap.set("v", "<leader>gC", function()
  vim.cmd([[execute "normal! \<Plug>(VM-Visual-Cursors)"]])
  vim.cmd([[execute "normal! I"]])
end, { desc = "Add cursors at start of lines" })

-- Option+Delete (Alt+Backspace) - Delete word backward (token by token)
vim.keymap.set("i", "<M-BS>", "<C-w>", { desc = "Delete word backward" })
vim.keymap.set("i", "<A-BS>", "<C-w>", { desc = "Delete word backward" })
vim.keymap.set("i", "<D-BS>", "<C-o>d0", { desc = "Delete word backward" })

-- Noice Telescope Picker
vim.keymap.set("n", "<leader>n", function()
  require("noice").cmd("telescope")
end, { desc = "Noice Picker (Telescope)" })
